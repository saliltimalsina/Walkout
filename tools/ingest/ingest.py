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
import html as htmllib
import os
import re
import sys
import time
import urllib.request

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
            date_iso = time.strftime("%Y-%m-%dT%H:%M:%S.000", time.gmtime(epoch))
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
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    client = None if args.dry_run else db()
    errors, results = [], {}

    for name, fn, id_key in [("rankings", scrape_rankings, "weightClass"),
                             ("events", scrape_events, "id")]:
        try:
            docs = fn()
        except Exception as e:
            errors.append(f"{name}: {e}")
            docs = []
        results[name] = len(docs)
        if docs and not args.dry_run:
            upsert(client, name, docs, id_key)

    print("ingest:", results, "errors:", errors)
    if args.dry_run:
        return

    client.collection("meta").document("ingest").set(
        {"lastRunAt": firestore.SERVER_TIMESTAMP, "source": "github-actions",
         "errors": errors}, merge=True)
    try:
        messaging.send(messaging.Message(
            topic=FCM_TOPIC, data={"type": "data_changed"},
            android=messaging.AndroidConfig(priority="high")))
    except Exception as e:
        print("fcm send failed:", e, file=sys.stderr)


if __name__ == "__main__":
    main()
