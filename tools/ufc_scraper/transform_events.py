"""Transform events_raw.json -> assets/data/events.json (app schema) and resize
hero covers to assets/events/<slug>.webp. Matches bout corner names to the
bundled fighter roster so cards link where possible."""
import json
import os
import re
import unicodedata
from datetime import datetime, timezone
from PIL import Image

HERE = os.path.dirname(__file__)
APP = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA_OUT = os.path.join(APP, "assets", "data")
EV_IMG_OUT = os.path.join(APP, "assets", "events")
SRC_HERO = os.path.join(HERE, "output", "heroes")

# Events on/after this date are "upcoming" (app's current date).
NOW = datetime(2026, 7, 7, tzinfo=timezone.utc)

DIV_MAP = {
    "Flyweight": "flyweight", "Bantamweight": "bantamweight",
    "Featherweight": "featherweight", "Lightweight": "lightweight",
    "Welterweight": "welterweight", "Middleweight": "middleweight",
    "Light Heavyweight": "lightHeavyweight", "Heavyweight": "heavyweight",
    "Women's Strawweight": "womenStrawweight",
    "Women's Flyweight": "womenFlyweight",
    "Women's Bantamweight": "womenBantamweight",
    "Women's Featherweight": "womenBantamweight",
}


def norm(s):
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", s.lower())


def main():
    os.makedirs(DATA_OUT, exist_ok=True)
    os.makedirs(EV_IMG_OUT, exist_ok=True)

    fighters = json.load(open(os.path.join(DATA_OUT, "fighters.json")))
    name_to_id = {norm(f["name"]): f["id"] for f in fighters}

    raw = json.load(open(os.path.join(HERE, "output", "events_raw.json")))

    events = []
    for e in raw:
        if not e.get("timestamp"):
            continue
        dt = datetime.fromtimestamp(e["timestamp"], tz=timezone.utc)
        status = "upcoming" if dt >= NOW else "past"

        # Hero image -> webp
        hero_asset = ""
        if e.get("heroFile"):
            src = os.path.join(SRC_HERO, e["heroFile"])
            if os.path.exists(src):
                try:
                    im = Image.open(src).convert("RGB")
                    w, h = im.size
                    if w > 1080:
                        im = im.resize((1080, int(h * 1080 / w)), Image.LANCZOS)
                    out = os.path.join(EV_IMG_OUT, f"{e['slug']}.webp")
                    im.save(out, format="WEBP", quality=82, method=5)
                    hero_asset = f"assets/events/{e['slug']}.webp"
                except Exception as ex:
                    print(f"  hero resize fail {e['slug']}: {ex}")

        valid_ids = {f["id"] for f in fighters}
        bouts = []
        for i, b in enumerate(e["bouts"]):
            label = re.sub(r"\s*Bout$", "", b.get("weightClass", "")).strip()
            enum = DIV_MAP.get(label, "lightweight")
            # Prefer the scraped athlete slug; fall back to name match.
            rid = b.get("redSlug", "") if b.get("redSlug", "") in valid_ids \
                else name_to_id.get(norm(b.get("red", "")), "")
            bid = b.get("blueSlug", "") if b.get("blueSlug", "") in valid_ids \
                else name_to_id.get(norm(b.get("blue", "")), "")
            bouts.append({
                "id": f"{e['slug']}_b{i}",
                "redCornerId": rid,
                "blueCornerId": bid,
                "redName": b.get("red", ""),
                "blueName": b.get("blue", ""),
                "weightClass": enum,
                "weightLabel": label,
                "isMainEvent": i == 0,
                "isTitleFight": i == 0 and e["eventType"].startswith("UFC ")
                and e["eventType"][4:5].isdigit(),
                "rounds": 5 if i == 0 else 3,
            })

        main_card = bouts[:5]
        prelims = bouts[5:]

        events.append({
            "id": e["slug"],
            "name": e["eventType"] or "UFC",
            "subtitle": e["mainEvent"],
            "eventType": e["eventType"],
            "date": dt.strftime("%Y-%m-%dT%H:%M:%S.000"),
            "venue": "",
            "location": e["city"],
            "heroImage": hero_asset,
            "status": status,
            "mainCard": main_card,
            "prelims": prelims,
        })

    events.sort(key=lambda x: x["date"])
    json.dump(events, open(os.path.join(DATA_OUT, "events.json"), "w"),
              ensure_ascii=False, indent=2)

    up = sum(1 for e in events if e["status"] == "upcoming")
    linked = sum(1 for e in events for b in e["mainCard"]
                 if b["redCornerId"] or b["blueCornerId"])
    print(f"events={len(events)} upcoming={up} withHero="
          f"{sum(1 for e in events if e['heroImage'])} linkedMainBouts={linked}")


if __name__ == "__main__":
    main()
