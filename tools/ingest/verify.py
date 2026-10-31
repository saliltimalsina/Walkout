#!/usr/bin/env python3
"""
Post-ingest health check. Reads Firestore the way the app does (public REST,
no credentials) and fails if any doc would break the app's parser. Also
reports image / fight-card coverage so gaps show up in the Actions summary
instead of as blank screens.

  python tools/ingest/verify.py          # exit 1 on broken docs
"""
import json
import os
import sys
import time
import urllib.request
from datetime import datetime

PROJECT = "walkout-69"
BASE = (f"https://firestore.googleapis.com/v1/projects/{PROJECT}"
        "/databases/(default)/documents/")
# Upcoming events this close should have their card announced.
CARD_EXPECTED_DAYS = 21
# The app's WeightClass enum values (lib/shared/models/weight_class.dart).
WEIGHT_CLASSES = {
    "flyweight", "bantamweight", "featherweight", "lightweight",
    "welterweight", "middleweight", "lightHeavyweight", "heavyweight",
    "womenStrawweight", "womenFlyweight", "womenBantamweight"}
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _value(v):
    """Firestore REST typed value -> plain Python."""
    (kind, x), = v.items()
    if kind == "mapValue":
        return {k: _value(y) for k, y in x.get("fields", {}).items()}
    if kind == "arrayValue":
        return [_value(y) for y in x.get("values", [])]
    if kind == "integerValue":
        return int(x)
    if kind == "nullValue":
        return None
    return x


def fetch_all(coll):
    docs, token = [], ""
    while True:
        url = BASE + coll + "?pageSize=300" + (f"&pageToken={token}" if token else "")
        with urllib.request.urlopen(url, timeout=30) as r:
            d = json.load(r)
        for x in d.get("documents", []):
            docs.append((x["name"].split("/")[-1],
                         {k: _value(v) for k, v in x.get("fields", {}).items()}))
        token = d.get("nextPageToken")
        if not token:
            return docs


def _str(doc, k):
    return isinstance(doc.get(k), str) and bool(doc.get(k))


def _epoch(iso):
    try:
        return datetime.fromisoformat(iso.replace("Z", "+00:00")).timestamp()
    except Exception:
        return None


def check():
    broken, warn = [], []
    fighters = dict(fetch_all("fighters"))
    events = fetch_all("events")
    rankings = fetch_all("rankings")

    # ── Parser contract (mirrors the non-defaulted casts in *.g.dart) ──
    for fid, f in fighters.items():
        for k in ("id", "name"):
            if not _str(f, k):
                broken.append(f"fighters/{fid}: missing {k}")
        if f.get("weightClass") not in WEIGHT_CLASSES:
            broken.append(f"fighters/{fid}: bad weightClass {f.get('weightClass')!r}")
    for eid, e in events:
        for k in ("id", "name", "date"):
            if not _str(e, k):
                broken.append(f"events/{eid}: missing {k}")
        for b in (e.get("mainCard") or []) + (e.get("prelims") or []):
            if not _str(b, "id"):
                broken.append(f"events/{eid}: bout without id")
    for rid, r in rankings:
        if r.get("weightClass") not in WEIGHT_CLASSES:
            broken.append(f"rankings/{rid}: bad weightClass {r.get('weightClass')!r}")
        if not isinstance(r.get("championId"), str):
            broken.append(f"rankings/{rid}: championId not a string")
        for c in r.get("contenders") or []:
            if not _str(c, "fighterId"):
                broken.append(f"rankings/{rid}: contender without fighterId")

    # ── Coverage ──
    now = time.time()
    upcoming = [(eid, e) for eid, e in events
                if (_epoch(e.get("date", "")) or 0) > now]
    no_art = [eid for eid, e in upcoming if not e.get("heroImage")]
    no_card = [eid for eid, e in upcoming
               if _epoch(e["date"]) < now + CARD_EXPECTED_DAYS * 86400
               and not (e.get("mainCard") or e.get("prelims"))]
    past_no_art = [eid for eid, e in events
                   if (eid, e) not in upcoming and not e.get("heroImage")]

    def has_image(f):
        img = f.get("imageUrl") or ""
        if img.startswith("assets/") and os.path.exists(os.path.join(REPO, img)):
            return True
        return bool(f.get("photoUrl")) or img.startswith("http")

    no_photo = sorted(fid for fid, f in fighters.items() if not has_image(f))
    card_ids = {b.get(k) for _, e in upcoming
                for b in (e.get("mainCard") or []) + (e.get("prelims") or [])
                for k in ("redCornerId", "blueCornerId") if b.get(k)}
    card_unknown = sorted(i for i in card_ids if i not in fighters)
    card_no_photo = sorted(i for i in card_ids
                           if i in fighters and not has_image(fighters[i]))

    if no_card:
        warn.append(f"upcoming within {CARD_EXPECTED_DAYS}d without a card: {no_card}")
    if card_unknown:
        warn.append(f"card fighters with no fighter doc: {card_unknown}")

    lines = [
        "## Walkout data health",
        f"- fighters: {len(fighters)} · events: {len(events)} "
        f"({len(upcoming)} upcoming) · rankings: {len(rankings)}",
        f"- broken docs (would fail the app parser): **{len(broken)}**",
        f"- upcoming events with poster: {len(upcoming) - len(no_art)}/{len(upcoming)}",
        f"- past events with poster: "
        f"{len(events) - len(upcoming) - len(past_no_art)}/{len(events) - len(upcoming)}",
        f"- upcoming events within {CARD_EXPECTED_DAYS}d with a card: "
        f"{sum(1 for eid, e in upcoming if _epoch(e['date']) < now + CARD_EXPECTED_DAYS * 86400) - len(no_card)}"
        f"/{sum(1 for eid, e in upcoming if _epoch(e['date']) < now + CARD_EXPECTED_DAYS * 86400)}",
        f"- fighters with a photo: {len(fighters) - len(no_photo)}/{len(fighters)}",
        f"- fighters on upcoming cards: {len(card_ids)} "
        f"(no doc: {len(card_unknown)}, no photo: {len(card_no_photo)})",
    ]
    if broken:
        lines += ["", "### Broken", *[f"- {b}" for b in broken[:50]]]
    if warn:
        lines += ["", "### Warnings", *[f"- {w}" for w in warn]]
    report = "\n".join(lines)
    print(report)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a") as fh:
            fh.write(report + "\n")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(check())
