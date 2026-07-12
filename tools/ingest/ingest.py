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
def scrape_rankings():
    page = fetch("https://www.ufc.com/rankings")
    # Split into division blocks by their header; keep first copy of each
    # division (the page renders the list twice).
    heads = list(re.finditer(r'view-grouping-header">\s*([^<]+?)\s*<', page))
    out, seen = [], set()
    for i, h in enumerate(heads):
        name = htmllib.unescape(h.group(1)).strip()
        wc = WC_MAP.get(name)
        if not wc or wc in seen:
            continue
        block = page[h.end(): heads[i + 1].start() if i + 1 < len(heads) else len(page)]
        champ = re.search(r'rankings--athlete--champion.*?href="(/athlete/[^"]+)"', block, re.S)
        pairs = re.findall(r'weight-class-rank">\s*(\d+).*?href="(/athlete/[^"]+)"', block, re.S)
        if not champ and not pairs:
            continue
        seen.add(wc)
        out.append({
            "weightClass": wc,
            "championId": _slug(champ.group(1)) if champ else "",
            "contenders": [
                {"fighterId": _slug(href), "position": int(rank), "change": 0}
                for rank, href in pairs[:15]
            ],
        })
    return out


# ── Events ──────────────────────────────────────────────────────────────────
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
        date_iso = ""
        status = "upcoming"
        if ts:
            epoch = int(ts.group(1))
            # UTC with the Z — the app anchors every countdown/live window on
            # this instant; a naive string would parse as device-local.
            date_iso = time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime(epoch))
            status = "past" if epoch < time.time() else "upcoming"
        # Only fields we actually scraped — omit mainCard/prelims/heroImage so
        # merge() preserves the seeded bout data + posters.
        out.append({
            "id": eid,
            "name": f"UFC {num.group(1)}" if num else "UFC Fight Night",
            "eventType": f"UFC {num.group(1)}" if num else "UFC Fight Night",
            "subtitle": subtitle,
            "date": date_iso,
            "venue": htmllib.unescape(venue.group(1)).strip() if venue else "",
            "status": status,
        })
    return out


# ── Results (event pages, once a card has run) ──────────────────────────────
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
    # CDN full-body cutout — stored as photoUrl (widgets keep bundled imageUrl;
    # in-app screens can adopt this later without a widget rewrite).
    photo = re.search(
        r'(https://ufc\.com/images/styles/athlete_bio_full_body/[^"\s]+\.(?:png|jpg|jpeg|webp))',
        page)
    if photo:
        doc["photoUrl"] = photo.group(1)
    return doc


def scrape_fighters():
    slugs = _ranked_slugs(scrape_rankings())
    out = []
    for s in slugs:
        try:
            d = scrape_fighter(s)
            if d:
                out.append(d)
        except Exception:
            pass  # one bad athlete page must not sink the batch
    return out


# ── Firestore write (merge, respect locked) ──────────────────────────────────
def upsert(client, coll, docs, id_key):
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
        merged["locked"] = locked
        merged["updatedAt"] = firestore.SERVER_TIMESTAMP
        ref.set(merged, merge=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["feed", "fighters"], default="feed",
                    help="feed = rankings+events (30-min cron); "
                         "fighters = athlete detail for ranked set (daily cron)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    client = None if args.dry_run else db()
    errors, results = [], {}

    if args.mode == "fighters":
        jobs = [("fighters", scrape_fighters, "id")]
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
        if docs and not args.dry_run:
            upsert(client, name, docs, id_key)

    # Feed runs also grade recently-finished cards (Pick'Em scoring, past-event
    # results, Living Widget result state). Needs Firestore, so skipped on
    # --dry-run.
    if args.mode == "feed" and not args.dry_run:
        try:
            graded = apply_results(client)
        except Exception as e:
            errors.append(f"results: {e}")
            graded = []
        results["graded"] = len(graded)
        scraped["graded"] = graded

    print("ingest:", results, "errors:", errors)
    if args.dry_run:
        return

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
        return
    try:
        messaging.send(messaging.Message(
            topic=FCM_TOPIC, data={"type": "data_changed"},
            android=messaging.AndroidConfig(priority="high")))
    except Exception as e:
        print("fcm send failed:", e, file=sys.stderr)


if __name__ == "__main__":
    main()
