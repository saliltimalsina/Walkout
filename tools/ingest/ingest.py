#!/usr/bin/env python3
"""
Free ingest — runs on GitHub Actions cron (no Cloud Functions / Blaze).

  fetch ufc.com (plain HTTPS, browser UA — pages are server-rendered, no JS)
    -> parse rankings + events with regex
    -> write Firestore (merge; respects per-doc `locked`; never wipes bouts)
    -> send one FCM data-push so phones refresh their widgets

Deliberately dependency-light: only firebase-admin. ufc.com returns full HTML
to a normal GET, so no headless browser is needed (that's what broke the CI
run before). A failed fetch/parse leaves existing Firestore data untouched.

Local test:  GOOGLE_APPLICATION_CREDENTIALS=sa.json python ingest.py --dry-run
"""
import argparse
import hashlib
import html as htmllib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore, messaging

FCM_TOPIC = "walkout_data"
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

WC_MAP = {
    "Flyweight": "flyweight", "Bantamweight": "bantamweight",
    "Featherweight": "featherweight", "Lightweight": "lightweight",
    "Welterweight": "welterweight", "Middleweight": "middleweight",
    "Light Heavyweight": "lightHeavyweight", "Heavyweight": "heavyweight",
    "Women's Strawweight": "womenStrawweight",
    "Women's Flyweight": "womenFlyweight",
    "Women's Bantamweight": "womenBantamweight",
}


def db():
    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(os.environ["GOOGLE_APPLICATION_CREDENTIALS"]))
    return firestore.client()


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=45) as r:
        return r.read().decode("utf-8", "ignore")


def _slug(href):
    return href.rstrip("/").split("/")[-1]


# ── Rankings ────────────────────────────────────────────────────────────────
# One table row: rank cell, athlete link, then the movement cell. The movement
# cell is empty for most rows and carries either a rank-increase/rank-decrease
# span plus a magnitude, or an `NR` badge for a fighter entering the top 15.
_RANK_ROW = re.compile(
    r'views-field-weight-class-rank">\s*(\d+)\s*</td>.*?'
    r'href="(/athlete/[^"]+)".*?'
    r'views-field-weight-class-rank-change">(.*?)</td>', re.S)


def _rank_change(cell):
    """(change, isNew) from a movement cell. Positive climbs, negative drops."""
    if "not-ranked" in cell:
        return 0, True
    m = re.search(r'rank-(increase|decrease)">[^<]*</span>\s*(\d+)', cell)
    if not m:
        return 0, False
    n = int(m.group(2))
    return (n if m.group(1) == "increase" else -n), False


def scrape_rankings():
    page = fetch("https://www.ufc.com/rankings")
    flat = re.sub(r"\s+", " ", page)
    # Split into division blocks by their header; keep first copy of each
    # division (the page renders the list twice).
    heads = list(re.finditer(r'view-grouping-header">\s*([^<]+?)\s*<', flat))
    out, seen = [], set()
    for i, h in enumerate(heads):
        name = htmllib.unescape(h.group(1)).strip()
        wc = WC_MAP.get(name)
        if not wc or wc in seen:
            continue
        block = flat[h.end(): heads[i + 1].start() if i + 1 < len(heads) else len(flat)]
        champ = re.search(
            r'rankings--athlete--champion.*?href="(/athlete/[^"]+)"', block, re.S)
        rows = _RANK_ROW.findall(block)
        if not champ and not rows:
            continue
        seen.add(wc)
        contenders = []
        for rank, href, cell in rows[:15]:
            change, is_new = _rank_change(cell)
            contenders.append({
                "fighterId": _slug(href),
                "position": int(rank),
                "change": change,
                "isNew": is_new,
            })
        out.append({
            "weightClass": wc,
            "championId": _slug(champ.group(1)) if champ else "",
            "contenders": contenders,
        })
    return out


# ── Events ──────────────────────────────────────────────────────────────────
def _iso(epoch):
    """UTC with the Z — the app anchors every countdown/live window on this
    instant; a naive string would parse as device-local."""
    return time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime(epoch))


def scrape_events():
    page = fetch("https://www.ufc.com/events")
    # Split on the OUTER card wrapper only (class followed by space/quote), not
    # the child `c-card-event--result__*` classes.
    cards = re.split(r'c-card-event--result(?=[\s"])', page)
    out = []
    for c in cards[1:]:
        m = re.search(r'__headline">\s*<a href="(/event/[^"]+)"[^>]*>(.*?)</a>', c, re.S)
        if not m:
            continue
        eid = _slug(m.group(1))
        subtitle = htmllib.unescape(re.sub(r"\s+", " ", m.group(2))).strip()
        ts = re.search(r'data-main-card-timestamp="(\d+)"', c)
        venue = re.search(r'taxonomy-term-title[^>]*>\s*(?:<h5[^>]*>)?\s*([^<]+)', c)
        num = re.match(r"ufc-(\d+)$", eid)
        doc = {
            "id": eid,
            "name": f"UFC {num.group(1)}" if num else "UFC Fight Night",
            "eventType": f"UFC {num.group(1)}" if num else "UFC Fight Night",
            "subtitle": subtitle,
            "date": "",
            "venue": htmllib.unescape(venue.group(1)).strip() if venue else "",
            "status": "upcoming",
        }
        if ts:
            epoch = int(ts.group(1))
            doc["date"] = _iso(epoch)
            doc["status"] = "past" if epoch < time.time() else "upcoming"
        # Real broadcast starts, so the app stops assuming a fixed 4h prelim
        # lead. Both are optional on the page (Fight Nights often list only the
        # main card), so only write what's actually there.
        for attr, field in (("data-prelims-card-timestamp", "prelimsAt"),
                            ("data-early-card-timestamp", "earlyPrelimsAt")):
            pm = re.search(attr + r'="(\d+)"', c)
            if pm:
                doc[field] = _iso(int(pm.group(1)))
        # "Las Vegas, NV, United States" — the microformat next to the venue.
        # Some rows carry an airport-style city code instead of a name ("BG" for
        # Belgrade); a bare code reads as noise, so drop it and keep the country.
        city = re.search(r'locality">([^<]*)', c)
        region = re.search(r'administrative-area">([^<]*)', c)
        country = re.search(r'country">([^<]*)', c)
        parts = [htmllib.unescape(x.group(1)).strip() if x else ""
                 for x in (city, region, country)]
        if len(parts[0]) <= 2 and parts[0].isupper():
            parts[0] = ""
        loc = ", ".join(p for p in parts if p)
        if loc:
            doc["location"] = loc
        # mainCard/prelims/heroImage are deliberately absent so merge() keeps
        # the seeded bout data + posters; sync_cards fills empty cards instead.
        out.append(doc)
    return out


# ── Fight cards (event pages, before a card has run) ────────────────────────
# UFC only labels "Main Card"/"Prelims" on an event page once broadcast is set,
# so a card built from scratch splits at the standard main-card size with the
# main event first (that's the order ufc.com lists them in).
CARD_MAIN_SIZE = 5
# Event pages fetched per run — keeps the 30-min job quick and polite.
CARD_SYNC_LIMIT = 8
# Only look this far ahead; distant cards are mostly unannounced anyway.
CARD_HORIZON_DAYS = 120


def _division_label(label):
    """"Heavyweight Interim Title Bout Pres. by X" -> "Heavyweight". The app
    adds its own "Bout" / "Title Bout" suffix (title-ness is isTitleFight)."""
    s = re.sub(r"\s*Pres\..*$", "", label, flags=re.I)
    s = re.sub(r"\s*(?:Interim\s+)?(?:Title\s+)?Bout\s*$", "", s, flags=re.I)
    s = re.sub(r"\s*(?:Interim\s+)?Title\s*$", "", s, flags=re.I)
    return s.strip()


def _wc_from_label(label):
    """"Welterweight Title Bout" -> "welterweight". Empty for catchweight and
    anything else outside the model's divisions."""
    base = re.sub(r"\s*(?:Interim\s*)?(?:Title\s*)?Bout\s*$", "", label,
                  flags=re.I).strip()
    return WC_MAP.get(base, "")


def _corner(block, corner):
    """(slug, display name) for one corner, or None when absent."""
    m = re.search(r'corner-name--' + corner + r'"(.*?)</div>', block, re.S)
    if not m:
        return None
    href = re.search(r'/athlete/([^"]+)"', m.group(1))
    name = re.sub(r"\s+", " ",
                  htmllib.unescape(re.sub(r"<[^>]+>", " ", m.group(1))))
    return (_slug(href.group(1)) if href else "", name.strip(" >").strip())


def _www(url):
    """ufc.com image URLs 301 to www — store the final host so the app skips
    the redirect on every load."""
    return re.sub(r"^https://ufc\.com/", "https://www.ufc.com/", url)


def parse_event_art(page):
    """Poster art from an event page, or "" when the page only carries the
    generic placeholder background (unannounced cards) — those get retried on
    a later run once real art is up."""
    m = re.search(
        r"""(https://(?:www\.)?ufc\.com/images/styles/background_image_lg/[^"'()\s]+)""",
        page)
    if not m:
        return ""
    url = _www(htmllib.unescape(m.group(1)))
    if re.search(r"/BACKGROUND[^/]*$", url.split("?")[0], re.I):
        return ""
    return url


def scrape_event_page(eid):
    """(bouts, art) from one fetch of the event page."""
    page = fetch(f"https://www.ufc.com/event/{eid}")
    return parse_event_card(page, eid), parse_event_art(page)


def scrape_event_card(eid):
    return scrape_event_page(eid)[0]


def parse_event_card(page, eid):
    """Ordered bouts on an event page, main event first. Unlike
    [scrape_event_results] this works before the card has run, which is what
    gives newly-announced events a fight card at all."""
    flat = re.sub(r"\s+", " ", page)
    out = []
    for b in re.split(r'class="c-listing-fight"', flat)[1:]:
        red, blue = _corner(b, "red"), _corner(b, "blue")
        if not red or not blue or not (red[1] and blue[1]):
            continue
        lm = re.search(r'c-listing-fight__class-text">\s*([^<]+)', b)
        label = htmllib.unescape(lm.group(1)).strip() if lm else ""
        fmid = re.search(r'data-fmid="(\d+)"', b)
        is_title = bool(re.search(r"\bTitle\b", label, re.I))
        bout = {
            "id": f"{eid}-{fmid.group(1)}" if fmid else f"{eid}-{len(out) + 1}",
            "redCornerId": red[0], "blueCornerId": blue[0],
            "redName": red[1], "blueName": blue[1],
            "weightLabel": _division_label(label),
            "isTitleFight": is_title,
            "isMainEvent": False,
            "rounds": 5 if is_title else 3,
        }
        wc = _wc_from_label(label)
        if wc:
            bout["weightClass"] = wc
        out.append(bout)
    if out:
        out[0]["isMainEvent"] = True
        out[0]["rounds"] = 5  # main events go five rounds, title or not
    return out


def _bout_key(b):
    """Corner pair, order-insensitive — the only stable identity across a
    scrape and the stored doc (fmid is absent from seeded bouts)."""
    return frozenset((b.get("redCornerId") or b.get("redName", ""),
                      b.get("blueCornerId") or b.get("blueName", "")))


def sync_cards(client, dry_run=False, limit=CARD_SYNC_LIMIT):
    """Give upcoming events their fight card.

    An event with no bouts gets the whole scraped card. An event that already
    has bouts only gains the ones announced since — seeded ordering, posters and
    graded results are never rewritten, and `locked` is always respected.
    """
    now = time.time()
    synced = []
    for snap in client.collection("events").stream():
        if len(synced) >= limit:
            break
        doc = snap.to_dict() or {}
        epoch = _event_epoch(doc.get("date", ""))
        if epoch is None or not (now < epoch < now + CARD_HORIZON_DAYS * 86400):
            continue
        locked = doc.get("locked", [])
        main, prelims = doc.get("mainCard", []), doc.get("prelims", [])
        if not main and not prelims:
            card_ok = "mainCard" not in locked and "prelims" not in locked
        else:
            card_ok = "prelims" not in locked
        art_ok = not doc.get("heroImage") and "heroImage" not in locked
        if not card_ok and not art_ok:
            continue
        try:
            scraped, art = scrape_event_page(snap.id)
        except Exception as e:
            print(f"card {snap.id} fetch failed: {e}", file=sys.stderr)
            continue

        update, added = {}, 0
        if card_ok and scraped:
            if not main and not prelims:
                update = {"mainCard": scraped[:CARD_MAIN_SIZE],
                          "prelims": scraped[CARD_MAIN_SIZE:]}
                added = len(scraped)
            else:
                known = {_bout_key(b) for b in list(main) + list(prelims)}
                extra = [b for b in scraped if _bout_key(b) not in known]
                if extra:
                    update = {"prelims": list(prelims) + extra}
                    added = len(extra)
        if art_ok and art:
            update["heroImage"] = art
        if not update:
            continue

        synced.append({"event": snap.id, "bouts": added,
                       "art": bool(update.get("heroImage"))})
        if not dry_run:
            update["updatedAt"] = firestore.SERVER_TIMESTAMP
            snap.reference.set(update, merge=True)
    return synced


# ── Results (event pages, once a card has run) ──────────────────────────────
# Event pages fetched per run for poster backfill (past events, mostly a
# one-off catch-up; afterwards sync_cards sets art as events are announced).
ART_BACKFILL_LIMIT = 10


def sync_art(client, dry_run=False, limit=ART_BACKFILL_LIMIT):
    """Poster art for any event still without one (past events, and upcoming
    ones beyond the card horizon). Upcoming events get it via sync_cards."""
    filled = []
    for snap in client.collection("events").stream():
        if len(filled) >= limit:
            break
        doc = snap.to_dict() or {}
        if doc.get("heroImage") or "heroImage" in doc.get("locked", []):
            continue
        try:
            art = parse_event_art(fetch(f"https://www.ufc.com/event/{snap.id}"))
        except Exception as e:
            print(f"art {snap.id} fetch failed: {e}", file=sys.stderr)
            continue
        if not art:
            continue
        filled.append(snap.id)
        if not dry_run:
            snap.reference.set({"heroImage": art,
                                "updatedAt": firestore.SERVER_TIMESTAMP},
                               merge=True)
    return filled


def url_ok(url):
    """False only when the server says the image is gone (4xx). Network
    blips count as fine so a flaky run never wipes good links."""
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=20):
            return True
    except urllib.error.HTTPError as e:
        return not (400 <= e.code < 500)
    except Exception:
        return True


def prune_dead_images(client, coll, field, dry_run=False):
    """Clear remote image links that now 404 so the next run re-scrapes them.
    Bundled asset paths are never touched."""
    pruned = []
    for snap in client.collection(coll).stream():
        doc = snap.to_dict() or {}
        url = doc.get(field) or ""
        if not url.startswith("http") or field in doc.get("locked", []):
            continue
        if url_ok(url):
            continue
        pruned.append(snap.id)
        if not dry_run:
            snap.reference.set({field: "",
                                "updatedAt": firestore.SERVER_TIMESTAMP},
                               merge=True)
    return pruned


def scrape_event_results(eid):
    """Finished bouts on an event page: red/blue athlete slugs, the winner,
    method and finish round. Unfinished bouts are skipped."""
    page = fetch(f"https://www.ufc.com/event/{eid}")
    out = []
    for b in re.split(r'class="c-listing-fight"', page)[1:]:
        red = re.search(
            r'corner-name--red.*?href="[^"]*/athlete/([^"]+)"', b, re.S)
        blue = re.search(
            r'corner-name--blue.*?href="[^"]*/athlete/([^"]+)"', b, re.S)
        if not red or not blue:
            continue
        # Outcomes appear corner-order: first belongs to red, second to blue.
        outs = re.findall(r'c-listing-fight__outcome--(win|loss)', b)
        if len(outs) < 2 or "win" not in outs[:2]:
            continue  # bout not finished (or no result markup yet)
        method = re.search(r'result-text method">([^<]*)<', b)
        rnd = re.search(r'result-text round">([^<]*)<', b)
        out.append({
            "red": _slug(red.group(1)),
            "blue": _slug(blue.group(1)),
            "winnerId": _slug(red.group(1)) if outs[0] == "win"
            else _slug(blue.group(1)),
            "method": (method.group(1) if method else "").strip(),
            "finishRound": (rnd.group(1) if rnd else "").strip(),
        })
    return out


def _event_epoch(date_iso):
    if not date_iso:
        return None
    try:
        d = datetime.fromisoformat(date_iso.replace("Z", "+00:00"))
        if d.tzinfo is None:
            d = d.replace(tzinfo=timezone.utc)  # legacy naive strings are UTC
        return d.timestamp()
    except ValueError:
        return None


def apply_results(client, dry_run=False):
    """For events that ran within the last 5 days and still have bouts with
    no winner, scrape the event page and merge results into the stored
    mainCard/prelims (matched by corner-slug pair). Feeds Pick'Em scoring,
    the past-event cards, and the Living Widget's result/aftermath states."""
    now = time.time()
    graded = []
    for snap in client.collection("events").stream():
        doc = snap.to_dict() or {}
        epoch = _event_epoch(doc.get("date", ""))
        if epoch is None or not (now - 5 * 86400 < epoch < now):
            continue
        locked = doc.get("locked", [])
        if "mainCard" in locked and "prelims" in locked:
            continue
        bouts = [b for k in ("mainCard", "prelims") if k not in locked
                 for b in doc.get(k, [])]
        if not bouts or all(b.get("winnerId") for b in bouts):
            continue
        try:
            results = scrape_event_results(snap.id)
        except Exception as e:
            print(f"results {snap.id} fetch failed: {e}", file=sys.stderr)
            continue
        if not results:
            continue
        by_pair = {frozenset((r["red"], r["blue"])): r for r in results}
        update = {}
        for key in ("mainCard", "prelims"):
            if key in locked:
                continue
            arr = doc.get(key, [])
            changed = False
            for bout in arr:
                if bout.get("winnerId"):
                    continue
                r = by_pair.get(frozenset(
                    (bout.get("redCornerId", ""), bout.get("blueCornerId", ""))))
                if not r:
                    continue
                bout["winnerId"] = r["winnerId"]
                bout["method"] = r["method"]
                bout["finishRound"] = r["finishRound"]
                changed = True
            if changed:
                update[key] = arr
        if update:
            graded.append({"event": snap.id, "bouts": sorted(
                b["winnerId"] for k in update.values() for b in k
                if b.get("winnerId"))})
            if not dry_run:
                update["updatedAt"] = firestore.SERVER_TIMESTAMP
                snap.reference.set(update, merge=True)
    return graded


# ── Fighters (detail pages for the visible set) ──────────────────────────────
def _ranked_slugs(rankings):
    s = set()
    for r in rankings:
        if r["championId"]:
            s.add(r["championId"])
        for c in r["contenders"]:
            s.add(c["fighterId"])
    return sorted(s)


def _stat_num(page, label):
    j = page.find(label)
    if j < 0:
        return 0
    m = re.search(r'hero-profile__stat-numb[^>]*>\s*(\d+)',
                  re.sub(r"\s+", " ", page[max(0, j - 180):j]))
    return int(m.group(1)) if m else 0


def _bio_field(flat, label):
    """A `c-bio__label` / `c-bio__text` pair, e.g. Age, Height, Reach."""
    m = re.search(
        r'c-bio__label">' + re.escape(label) +
        r'</div> <div class="c-bio__text[^"]*">\s*(?:<div[^>]*>)?\s*([^<]{0,80})',
        flat)
    return htmllib.unescape(m.group(1)).strip() if m else ""


def _num(text):
    m = re.search(r"[\d.]+", text or "")
    return float(m.group(0)) if m else 0.0


def _in_to_cm(text):
    """ufc.com lists height and reach in inches ("70.50")."""
    v = _num(text)
    return round(v * 2.54) if v else 0


def _compare_stats(flat):
    """The `c-stat-compare` grid: per-minute rates and the two defense
    percentages. Label text is the key, so a layout reshuffle can't mis-assign
    values the way positional parsing would."""
    out = {}
    for m in re.finditer(r'c-stat-compare__number">\s*([\d.]+)', flat):
        win = flat[m.end():m.end() + 260]
        lm = re.search(r'c-stat-compare__label">\s*([^<]+)', win)
        if lm:
            out[htmllib.unescape(lm.group(1)).strip()] = float(m.group(1))
    return out


def _accuracy(flat, title):
    """Accuracy donuts are rendered as SVG `<title>Striking accuracy 58%</title>`."""
    m = re.search(r"<title>" + re.escape(title) + r"\s*(\d+)%</title>", flat, re.I)
    return float(m.group(1)) if m else 0.0


def scrape_fighter(slug):
    page = fetch(f"https://www.ufc.com/athlete/{slug}")
    flat = re.sub(r"\s+", " ", page)
    rec = re.search(r"(\d+)-(\d+)-(\d+)\s*\(W-L-D\)", flat)
    if not rec:
        return None
    wins, losses, draws = (int(x) for x in rec.groups())
    ko = _stat_num(page, "Wins by Knockout")
    sub = _stat_num(page, "Wins by Submission")
    dec = max(0, wins - ko - sub)
    doc = {
        "id": slug,
        "record": {"wins": wins, "losses": losses, "draws": draws},
        "winsByKo": ko, "winsBySub": sub, "winsByDec": dec,
    }
    # Name is required by the app. upsert only fills it when the doc has none,
    # so athletes first created by this pass don't land nameless.
    name = re.search(r'hero-profile__name">\s*([^<]+)', flat)
    if name:
        doc["name"] = htmllib.unescape(name.group(1)).strip()

    # ── Tale of the tape ──
    age = _bio_field(flat, "Age")
    if age:
        doc["age"] = int(_num(age))
    for label, field in (("Height", "heightCm"), ("Reach", "reachCm")):
        cm = _in_to_cm(_bio_field(flat, label))
        if cm:
            doc[field] = cm
    # "Dagestan Republic, Russia" -> country only; the app renders it as origin.
    birthplace = _bio_field(flat, "Place of Birth")
    if birthplace:
        doc["country"] = birthplace.split(",")[-1].strip()

    # Division moves are real roster changes (Makhachev to welterweight), so
    # follow the page rather than pinning whatever the seed captured.
    div = re.search(r'hero-profile__division-title">\s*([^<]+)', flat)
    if div:
        wc = WC_MAP.get(
            re.sub(r"\s*Division\s*$", "", htmllib.unescape(div.group(1)).strip()))
        if wc:
            doc["weightClass"] = wc

    # ── Fight stats: every field the app models, none of which was populated ──
    cmp_ = _compare_stats(flat)
    stats = {
        "sigStrikesPerMin": cmp_.get("Sig. Str. Landed", 0.0),
        "sigStrikesAbsorbedPerMin": cmp_.get("Sig. Str. Absorbed", 0.0),
        "takedownAvg": cmp_.get("Takedown avg", 0.0),
        "submissionAvg": cmp_.get("Submission avg", 0.0),
        "strikingDefense": cmp_.get("Sig. Str. Defense", 0.0),
        "takedownDefense": cmp_.get("Takedown Defense", 0.0),
        "strikingAccuracy": _accuracy(flat, "Striking accuracy"),
        "takedownAccuracy": _accuracy(flat, "Takedown Accuracy"),
    }
    if any(stats.values()):
        doc["stats"] = stats

    # CDN full-body cutout — stored as photoUrl (widgets keep bundled imageUrl;
    # in-app screens can adopt this later without a widget rewrite).
    photo = re.search(
        r'(https://ufc\.com/images/styles/athlete_bio_full_body/[^"\s]+\.(?:png|jpg|jpeg|webp))',
        page)
    if photo:
        doc["photoUrl"] = _www(photo.group(1))
    return doc


def _rank_index(rankings):
    """{slug: (rankingPosition, isChampion)} for the current top 15 + champions."""
    idx = {}
    for r in rankings:
        if r["championId"]:
            idx[r["championId"]] = (None, True)
        for c in r["contenders"]:
            idx.setdefault(c["fighterId"], (c["position"], False))
    return idx


def card_slugs(client):
    """Fighters on upcoming cards — mostly unranked, so the ranked-set pass
    alone leaves undercard athletes without records or photos."""
    now = time.time()
    out = set()
    for snap in client.collection("events").stream():
        doc = snap.to_dict() or {}
        epoch = _event_epoch(doc.get("date", ""))
        if epoch is None or epoch < now - 86400:
            continue
        for b in list(doc.get("mainCard", [])) + list(doc.get("prelims", [])):
            for k in ("redCornerId", "blueCornerId"):
                if b.get(k):
                    out.add(b[k])
    return out


def broken_fighter_slugs(client):
    """Fighter docs the app can't parse (e.g. created nameless by an older
    run) — re-scraped every day until they're whole, ranked or not."""
    return {snap.id for snap in client.collection("fighters").stream()
            if missing_fields("fighters", snap.to_dict() or {})}


def scrape_fighters(extra_slugs=()):
    rankings = scrape_rankings()
    idx = _rank_index(rankings)
    out = []
    for s in sorted(set(_ranked_slugs(rankings)) | set(extra_slugs)):
        try:
            d = scrape_fighter(s)
        except Exception:
            continue  # one bad athlete page must not sink the batch
        if not d:
            continue
        # Rank and title status live in the rankings collection, but the app also
        # reads them off the fighter (RankBadge, championsProvider), so keep the
        # copy in step or a title change never shows up there.
        position, is_champ = idx.get(s, (None, False))
        d["rankingPosition"] = position
        d["isChampion"] = is_champ
        out.append(d)
    return out


def sync_unranked(client, ranked_index, dry_run=False):
    """Clear rank/title flags on fighters who dropped out of the top 15.

    [scrape_fighters] only visits ranked athletes, so without this pass a former
    champion or contender keeps their badge forever.
    """
    cleared = []
    for snap in client.collection("fighters").stream():
        if snap.id in ranked_index:
            continue
        doc = snap.to_dict() or {}
        locked = doc.get("locked", [])
        update = {}
        if doc.get("rankingPosition") is not None \
                and "rankingPosition" not in locked:
            update["rankingPosition"] = None
        if doc.get("isChampion") and "isChampion" not in locked:
            update["isChampion"] = False
        if not update:
            continue
        cleared.append(snap.id)
        if not dry_run:
            update["updatedAt"] = firestore.SERVER_TIMESTAMP
            snap.reference.set(update, merge=True)
    return cleared


# ── Firestore write (merge, respect locked) ──────────────────────────────────
# Written only when the stored doc lacks them — keeps curated seed names.
FILL_ONLY = ("name",)


# Fields the app's models cast without a default — a doc missing one makes
# the app's parser throw. Mirrors lib/shared/models/*.g.dart.
REQUIRED = {"fighters": ("id", "name", "weightClass"),
            "events": ("id", "name", "date"),
            "rankings": ("weightClass",)}
WEIGHT_CLASSES = set(WC_MAP.values())


def missing_fields(coll, doc):
    miss = [f for f in REQUIRED.get(coll, ())
            if not isinstance(doc.get(f), str) or not doc.get(f)]
    if "weightClass" in REQUIRED.get(coll, ()) and "weightClass" not in miss \
            and doc["weightClass"] not in WEIGHT_CLASSES:
        miss.append("weightClass")
    return miss


def upsert(client, coll, docs, id_key):
    """Merge-write docs; returns the ids skipped for missing required fields."""
    skipped = []
    for d in docs:
        doc_id = str(d.get(id_key, "")).strip()
        if not doc_id:
            continue
        ref = client.collection(coll).document(doc_id)
        existing = ref.get().to_dict() or {}
        locked = existing.get("locked", [])
        merged = dict(d)
        for f in locked:
            if f in existing:
                merged[f] = existing[f]
        for f in FILL_ONLY:
            if existing.get(f):
                merged.pop(f, None)
        miss = missing_fields(coll, {**existing, **merged})
        if miss:
            skipped.append(f"{coll}/{doc_id} missing {','.join(miss)}")
            continue
        merged["locked"] = locked
        merged["updatedAt"] = firestore.SERVER_TIMESTAMP
        ref.set(merged, merge=True)
    return skipped


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["feed", "fighters"], default="feed",
                    help="feed = rankings+events (30-min cron); "
                         "fighters = athlete detail for ranked set (daily cron)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    client = None if args.dry_run else db()
    errors, results, fatal = [], {}, []

    if args.mode == "fighters":
        extra = set()
        if not args.dry_run:
            try:
                extra = card_slugs(client) | broken_fighter_slugs(client)
            except Exception as e:
                errors.append(f"card_slugs: {e}")
        jobs = [("fighters", lambda: scrape_fighters(extra), "id")]
    else:
        jobs = [("rankings", scrape_rankings, "weightClass"),
                ("events", scrape_events, "id")]

    scraped = {}
    for name, fn, id_key in jobs:
        try:
            docs = fn()
        except Exception as e:
            errors.append(f"{name}: {e}")
            docs = []
        results[name] = len(docs)
        scraped[name] = docs
        if not docs:
            # An empty core scrape means ufc.com changed its markup — fail the
            # run loudly rather than quietly serving stale data.
            fatal.append(f"{name}: scraper returned nothing")
        if docs and not args.dry_run:
            errors.extend(upsert(client, name, docs, id_key))

    # Passes that need to read Firestore first, so they're skipped on --dry-run.
    # feed: fill fight cards for upcoming events, then grade the finished ones
    # (Pick'Em scoring, past-event results, Living Widget result state).
    # fighters: strip stale rank/title badges off athletes who fell out.
    if not args.dry_run:
        passes = [("cards", sync_cards), ("art", sync_art),
                  ("graded", apply_results),
                  ("deadArt", lambda c: prune_dead_images(
                      c, "events", "heroImage"))] \
            if args.mode == "feed" else \
            [("unranked", lambda c: sync_unranked(
                c, _rank_index(scrape_rankings()))),
             ("deadPhotos", lambda c: prune_dead_images(
                 c, "fighters", "photoUrl"))]
        for name, fn in passes:
            try:
                got = fn(client)
            except Exception as e:
                errors.append(f"{name}: {e}")
                got = []
            results[name] = len(got)
            scraped[name] = got

    print("ingest:", results, "errors:", errors + fatal)
    if args.dry_run:
        sys.exit(1 if fatal else 0)
    errors += fatal

    # Only wake every phone when the scraped content actually changed.
    # A status flip (upcoming -> past) changes the hash, so devices get a
    # push right at the boundary — free precision — while identical runs
    # stay silent instead of firing 48 high-priority pushes a day.
    digest = hashlib.sha256(
        json.dumps(scraped, sort_keys=True).encode()).hexdigest()
    meta_ref = client.collection("meta").document("ingest")
    prev = (meta_ref.get().to_dict() or {}).get(f"dataHash_{args.mode}")
    meta_ref.set(
        {"lastRunAt": firestore.SERVER_TIMESTAMP, "source": "github-actions",
         f"dataHash_{args.mode}": digest, "errors": errors}, merge=True)
    if digest == prev and not errors:
        print("no content change; skipping fcm push")
        return 1 if fatal else 0
    try:
        messaging.send(messaging.Message(
            topic=FCM_TOPIC, data={"type": "data_changed"},
            android=messaging.AndroidConfig(priority="high")))
    except Exception as e:
        print("fcm send failed:", e, file=sys.stderr)
    return 1 if fatal else 0


if __name__ == "__main__":
    sys.exit(main())
