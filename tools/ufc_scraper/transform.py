"""Transform scraped athletes.json + roster.json into app-schema JSON assets and
compressed portrait images bundled into the Flutter project.

Outputs:
  assets/data/fighters.json   (list of Fighter, ready for Fighter.fromJson)
  assets/data/rankings.json   (list of DivisionRanking)
  assets/data/events.json     (a few hand-authored events referencing real ids)
  assets/fighters/<slug>.png  (resized portraits, alpha preserved)
"""
import json
import os
import re
from PIL import Image

HERE = os.path.dirname(__file__)
APP = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA_OUT = os.path.join(APP, "assets", "data")
IMG_OUT = os.path.join(APP, "assets", "fighters")
SRC_IMG = os.path.join(HERE, "output", "images")

DIVISION_TO_ENUM = {
    "Flyweight": "flyweight",
    "Bantamweight": "bantamweight",
    "Featherweight": "featherweight",
    "Lightweight": "lightweight",
    "Welterweight": "welterweight",
    "Middleweight": "middleweight",
    "Light Heavyweight": "lightHeavyweight",
    "Heavyweight": "heavyweight",
    "Women's Strawweight": "womenStrawweight",
    "Women's Flyweight": "womenFlyweight",
    "Women's Bantamweight": "womenBantamweight",
}

COUNTRY_FLAG = {
    "United States": "🇺🇸", "USA": "🇺🇸", "Brazil": "🇧🇷", "Russia": "🇷🇺",
    "Russian Federation": "🇷🇺", "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "United Kingdom": "🇬🇧",
    "Ireland": "🇮🇪", "Australia": "🇦🇺", "Nigeria": "🇳🇬", "New Zealand": "🇳🇿",
    "Kazakhstan": "🇰🇿", "Georgia": "🇬🇪", "Armenia": "🇦🇲", "Mexico": "🇲🇽",
    "Canada": "🇨🇦", "Poland": "🇵🇱", "France": "🇫🇷", "Spain": "🇪🇸",
    "China": "🇨🇳", "Japan": "🇯🇵", "South Korea": "🇰🇷", "Korea": "🇰🇷",
    "Cuba": "🇨🇺", "Dagestan": "🇷🇺", "Ecuador": "🇪🇨", "Chile": "🇨🇱",
    "South Africa": "🇿🇦", "Cameroon": "🇨🇲", "Germany": "🇩🇪", "Sweden": "🇸🇪",
    "Netherlands": "🇳🇱", "Kyrgyzstan": "🇰🇬", "Tajikistan": "🇹🇯", "Iran": "🇮🇷",
    "Italy": "🇮🇹", "Scotland": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "Suriname": "🇸🇷", "Argentina": "🇦🇷",
    "Peru": "🇵🇪", "Venezuela": "🇻🇪", "UAE": "🇦🇪", "Moldova": "🇲🇩",
    "Norway": "🇳🇴", "Croatia": "🇭🇷", "Czech Republic": "🇨🇿", "Belarus": "🇧🇾",
    "Ukraine": "🇺🇦", "Azerbaijan": "🇦🇿", "Turkey": "🇹🇷", "Thailand": "🇹🇭",
    "Philippines": "🇵🇭", "Panama": "🇵🇦", "Colombia": "🇨🇴", "Uzbekistan": "🇺🇿",
}


def _num(s, default=0.0):
    if not s:
        return default
    m = re.search(r"-?\d+(\.\d+)?", str(s).replace(",", ""))
    return float(m.group()) if m else default


def _int(s, default=0):
    return int(round(_num(s, default)))


def _pct(s):
    return _num(s)  # strips the % via regex


def _flag(place):
    if not place:
        return ""
    country = place.split(",")[-1].strip()
    return COUNTRY_FLAG.get(country, "")


def _lead_int(bar_value):
    # "16 (67%)" -> 16
    m = re.match(r"\s*(\d+)", bar_value or "")
    return int(m.group(1)) if m else 0


def parse_record(raw):
    # "24-6-0 (W-L-D)" -> wins,losses,draws
    m = re.match(r"\s*(\d+)-(\d+)-(\d+)", raw or "")
    if not m:
        return {"wins": 0, "losses": 0, "draws": 0}
    return {"wins": int(m[1]), "losses": int(m[2]), "draws": int(m[3])}


def to_fighter(a):
    meta = a.get("ranking_meta", {})
    division = meta.get("division", "")
    # Ranked fighters always map cleanly; delta/unranked fighters may have an
    # empty/odd division — default them to lightweight so they still get a
    # Fighter (and a photo) for fight-card matching.
    enum = DIVISION_TO_ENUM.get(division, "lightweight")
    bio = a.get("bio", {})
    compare = a.get("compare", {})
    bars = a.get("bars", {})
    acc = a.get("accuracy_percents", [])
    is_champ = bool(meta.get("isChampion"))

    fighter = {
        "id": a["slug"],
        "name": a.get("name", "").strip(),
        "nickname": (a.get("nickname") or "").strip(),
        "weightClass": enum,
        "country": (bio.get("Place of Birth", "").split(",")[-1].strip()),
        "flag": _flag(bio.get("Place of Birth", "")),
        "record": parse_record(a.get("record_raw", "")),
        "isChampion": is_champ,
        "imageUrl": f"assets/fighters/{a['slug']}.webp" if a.get("image_file") else "",
        "heightCm": _int(_num(bio.get("Height")) * 2.54) if bio.get("Height") else 0,
        "reachCm": _int(_num(bio.get("Reach")) * 2.54) if bio.get("Reach") else 0,
        "age": _int(bio.get("Age")),
        "winsByKo": _lead_int(bars.get("KO/TKO", "")),
        "winsBySub": _lead_int(bars.get("SUB", "")),
        "winsByDec": _lead_int(bars.get("DEC", "")),
        "stats": {
            "sigStrikesPerMin": _num(compare.get("Sig. Str. Landed")),
            "strikingAccuracy": _pct(acc[0]) if len(acc) > 0 else 0.0,
            "sigStrikesAbsorbedPerMin": _num(compare.get("Sig. Str. Absorbed")),
            "strikingDefense": _pct(compare.get("Sig. Str. Defense")),
            "takedownAvg": _num(compare.get("Takedown avg")),
            "takedownAccuracy": _pct(acc[1]) if len(acc) > 1 else 0.0,
            "takedownDefense": _pct(compare.get("Takedown Defense")),
            "submissionAvg": _num(compare.get("Submission avg")),
        },
    }
    if not is_champ and meta.get("rank"):
        fighter["rankingPosition"] = int(meta["rank"])
    return fighter


def resize_images(slugs):
    os.makedirs(IMG_OUT, exist_ok=True)
    count = 0
    for slug in slugs:
        src = os.path.join(SRC_IMG, f"{slug}.png")
        if not os.path.exists(src):
            continue
        try:
            im = Image.open(src).convert("RGBA")
            w, h = im.size
            target = 384
            if w > target:
                im = im.resize((target, int(h * target / w)), Image.LANCZOS)
            im.save(os.path.join(IMG_OUT, f"{slug}.webp"), format="WEBP",
                    quality=80, method=4)
            count += 1
        except Exception as e:
            print(f"  resize fail {slug}: {e}")
    return count


def build_rankings(roster, valid_ids):
    seen_div = set()
    out = []
    for d in roster["divisions"]:
        div = d["division"]
        enum = DIVISION_TO_ENUM.get(div)
        if not enum or enum in seen_div:
            continue
        seen_div.add(enum)
        champ = d.get("champion")
        champ_id = champ["slug"] if champ and champ["slug"] in valid_ids else ""
        contenders = [
            {"fighterId": c["slug"], "position": c["rank"], "change": 0}
            for c in d["contenders"] if c["slug"] in valid_ids
        ]
        if champ_id:
            out.append({
                "weightClass": enum,
                "championId": champ_id,
                "contenders": contenders,
            })
    return out


def build_events(fighters_by_div):
    """Hand-authored events referencing real champion/contender ids so the
    events + home screens have live content."""
    def pick(div, i=0):
        lst = fighters_by_div.get(div, [])
        return lst[i]["id"] if len(lst) > i else ""

    events = []
    lw = fighters_by_div.get("lightweight", [])
    hw = fighters_by_div.get("heavyweight", [])
    mw = fighters_by_div.get("middleweight", [])
    ww = fighters_by_div.get("welterweight", [])

    def bout(bid, a, b, wc, title=False, main=False, rounds=5):
        return {
            "id": bid, "redCornerId": a, "blueCornerId": b, "weightClass": wc,
            "isTitleFight": title, "isMainEvent": main, "rounds": rounds,
        }

    if len(lw) >= 2 and len(ww) >= 2:
        events.append({
            "id": "e_320", "name": "UFC 320",
            "subtitle": f"{lw[0]['name'].split()[-1]} vs {lw[1]['name'].split()[-1]}",
            "date": "2026-08-15T22:00:00.000", "venue": "T-Mobile Arena",
            "location": "Las Vegas, NV", "status": "upcoming",
            "mainCard": [
                bout("b_320_1", lw[0]["id"], lw[1]["id"], "lightweight", True, True),
                bout("b_320_2", ww[0]["id"], ww[1]["id"], "welterweight", True, False),
            ],
            "prelims": [],
        })
    if len(hw) >= 2 and len(mw) >= 2:
        events.append({
            "id": "e_321", "name": "UFC 321",
            "subtitle": f"{hw[0]['name'].split()[-1]} vs {hw[1]['name'].split()[-1]}",
            "date": "2026-09-12T22:00:00.000", "venue": "Etihad Arena",
            "location": "Abu Dhabi, UAE", "status": "upcoming",
            "mainCard": [
                bout("b_321_1", hw[0]["id"], hw[1]["id"], "heavyweight", True, True),
                bout("b_321_2", mw[0]["id"], mw[1]["id"], "middleweight", True, False),
            ],
            "prelims": [],
        })
    if len(mw) >= 3:
        events.append({
            "id": "e_319", "name": "UFC 319",
            "subtitle": f"{mw[0]['name'].split()[-1]} vs {mw[2]['name'].split()[-1]}",
            "date": "2026-06-07T22:00:00.000", "venue": "Kaseya Center",
            "location": "Miami, FL", "status": "past",
            "mainCard": [
                {**bout("b_319_1", mw[0]["id"], mw[2]["id"], "middleweight", True, True),
                 "winnerId": mw[0]["id"], "method": "Decision", "finishRound": "R5"},
            ],
            "prelims": [],
        })
    return events


def main():
    os.makedirs(DATA_OUT, exist_ok=True)
    athletes = json.load(open(os.path.join(HERE, "output", "athletes.json")))
    roster = json.load(open(os.path.join(HERE, "roster.json")))

    fighters = [f for f in (to_fighter(a) for a in athletes) if f]
    valid_ids = {f["id"] for f in fighters}

    # Group by division for event authoring (champion first, then by rank).
    by_div = {}
    for f in fighters:
        by_div.setdefault(f["weightClass"], []).append(f)
    for lst in by_div.values():
        lst.sort(key=lambda x: (not x["isChampion"], x.get("rankingPosition", 999)))

    rankings = build_rankings(roster, valid_ids)
    events = build_events(by_div)

    json.dump(fighters, open(os.path.join(DATA_OUT, "fighters.json"), "w"),
              ensure_ascii=False, indent=2)
    json.dump(rankings, open(os.path.join(DATA_OUT, "rankings.json"), "w"),
              ensure_ascii=False, indent=2)
    json.dump(events, open(os.path.join(DATA_OUT, "events.json"), "w"),
              ensure_ascii=False, indent=2)

    n_img = resize_images(valid_ids)
    print(f"fighters={len(fighters)} rankings={len(rankings)} "
          f"events={len(events)} images={n_img}")
    print(f"-> {DATA_OUT}")


if __name__ == "__main__":
    main()
