#!/usr/bin/env python3
"""
Free ingest — runs on GitHub Actions cron (no Cloud Functions / Blaze needed).

  scrape ufc.com (Scrapling)  ->  normalize to the app schema
       ->  write Firestore (respecting per-doc `locked` fields)
       ->  send one FCM data-push so phones refresh their widgets

Credentials: set env GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON
(the Action writes the FIREBASE_SA secret to a file and points here).

Selectors marked TODO must be tuned against the live pages — ufc.com is heavy
and changes; the pipeline degrades gracefully (a failed scrape leaves existing
Firestore data untouched rather than wiping it). The dashboard's manual
edit/lock is the human safety net.

Run locally:  GOOGLE_APPLICATION_CREDENTIALS=sa.json python ingest.py --limit 20
"""
import argparse
import os
import sys
import traceback

import firebase_admin
from firebase_admin import credentials, firestore, messaging

FCM_TOPIC = "walkout_data"


def db():
    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(os.environ["GOOGLE_APPLICATION_CREDENTIALS"])
        )
    return firestore.client()


# ── Scrapers (Scrapling) ────────────────────────────────────────────────────
# Each returns a list of dicts shaped like assets/data/*.json, or [] on failure.

def _fetch(url):
    """Fetch a page with Scrapling's stealthy, JS-capable fetcher."""
    from scrapling.fetchers import StealthyFetcher
    return StealthyFetcher.fetch(url, headless=True, network_idle=True)


def scrape_rankings(limit=None):
    try:
        page = _fetch("https://www.ufc.com/rankings")
        out = []
        # TODO: tune selectors against live DOM. Each division block on the
        # rankings page has a champion + a numbered contender list.
        for group in page.css(".view-grouping"):
            wc = group.css_first(".view-grouping-header::text")
            champ = group.css_first(".rankings--athlete--champion .views-field a::text")
            contenders = []
            for i, row in enumerate(group.css("tbody tr"), start=1):
                name = row.css_first("a::text")
                if name:
                    contenders.append({"fighterId": slugify(name.clean()), "position": i, "change": 0})
            if wc:
                out.append({
                    "weightClass": normalize_wc(wc.clean()),
                    "championId": slugify(champ.clean()) if champ else "",
                    "contenders": contenders[: (limit or 15)],
                })
        return out
    except Exception:
        traceback.print_exc()
        return []


def scrape_events(limit=None):
    try:
        page = _fetch("https://www.ufc.com/events")
        out = []
        # TODO: tune. Upcoming + recent event cards on the events index.
        for i, card in enumerate(page.css(".c-card-event--result")):
            if limit and i >= limit:
                break
            title = card.css_first("h3 a::text")
            date = card.css_first(".c-card-event--result__date::attr(data-main-card-timestamp)")
            headline = card.css_first(".c-card-event--result__headline::text")
            if not title:
                continue
            out.append({
                "id": slugify(title.clean()),
                "name": title.clean(),
                "subtitle": headline.clean() if headline else "",
                "eventType": "UFC",
                "date": iso_from_ts(date.clean()) if date else "",
                "venue": "",
                "location": "",
                "heroImage": "",
                "status": "upcoming",
                "mainCard": [],
                "prelims": [],
            })
        return out
    except Exception:
        traceback.print_exc()
        return []


def scrape_fighters(limit=None):
    # Fighters change slowly and are already seeded; leave as an opt-in pass.
    # TODO: iterate ufc.com/athletes (paged) → athlete pages for record/photo.
    return []


# ── Helpers ─────────────────────────────────────────────────────────────────
def slugify(name: str) -> str:
    return "-".join(name.strip().lower().split())


def normalize_wc(s: str) -> str:
    return s.replace("Division", "").strip()


def iso_from_ts(ts: str) -> str:
    try:
        from datetime import datetime, timezone
        return datetime.fromtimestamp(int(ts), tz=timezone.utc).isoformat()
    except Exception:
        return ts


# ── Firestore write (respect locked) ─────────────────────────────────────────
def upsert(client, coll, docs, id_key):
    n = 0
    for d in docs:
        doc_id = d.get(id_key)
        if not doc_id:
            continue
        ref = client.collection(coll).document(str(doc_id))
        snap = ref.get()
        existing = snap.to_dict() or {}
        locked = existing.get("locked", [])
        merged = dict(d)
        for f in locked:
            if f in existing:
                merged[f] = existing[f]
        merged["locked"] = locked
        merged["updatedAt"] = firestore.SERVER_TIMESTAMP
        ref.set(merged, merge=True)
        n += 1
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    client = db()
    errors = []
    results = {}

    for name, fn, id_key in [
        ("rankings", scrape_rankings, "weightClass"),
        ("events", scrape_events, "id"),
        ("fighters", scrape_fighters, "id"),
    ]:
        docs = fn(args.limit)
        results[name] = len(docs)
        if not docs:
            errors.append(f"{name}: no rows (source empty or selectors need tuning)")
            continue
        if args.dry_run:
            print(f"[dry-run] {name}: {len(docs)} rows")
            continue
        upsert(client, name, docs, id_key)

    print("ingest:", results, "errors:", errors)

    if args.dry_run:
        return

    # Stamp meta + push once so phones refresh.
    client.collection("meta").document("ingest").set(
        {"lastRunAt": firestore.SERVER_TIMESTAMP, "source": "github-actions", "errors": errors},
        merge=True,
    )
    try:
        messaging.send(messaging.Message(
            topic=FCM_TOPIC,
            data={"type": "data_changed"},
            android=messaging.AndroidConfig(priority="high"),
        ))
    except Exception as e:
        print("fcm send failed:", e, file=sys.stderr)


if __name__ == "__main__":
    main()
