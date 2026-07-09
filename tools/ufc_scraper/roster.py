"""Parse the UFC rankings page into divisions -> champion + ranked contenders."""
import json
import re
import sys
from scrapling.parser import Selector


def _clean(s):
    return re.sub(r"\s+", " ", (s or "")).strip()


def _slug(href):
    m = re.search(r"/athlete/([a-z0-9-]+)", href or "")
    return m.group(1) if m else ""


def parse_roster(html: str) -> dict:
    sel = Selector(html)
    divisions = []
    seen_global = {}

    for group in sel.css(".view-grouping"):
        header = _clean(group.css(".view-grouping-header")[0].get_all_text()) \
            if group.css(".view-grouping-header") else ""
        if not header or "Pound-for-Pound" in header:
            continue  # skip P4P for division mapping (still captured elsewhere)

        # Champion
        champ = None
        champ_block = group.css(".rankings--athlete--champion")
        if champ_block:
            links = champ_block[0].css('a[href*="/athlete/"]')
            if links:
                champ = {
                    "slug": _slug(links[0].attrib.get("href")),
                    "name": _clean(links[0].get_all_text()),
                    "rank": 0,
                    "isChampion": True,
                }

        # Contenders (table rows)
        contenders = []
        for title in group.css(".views-field-title a[href*='/athlete/']"):
            slug = _slug(title.attrib.get("href"))
            name = _clean(title.get_all_text())
            if not slug:
                continue
            contenders.append({"slug": slug, "name": name})

        # Attach ranks in order (1..N)
        ranks = [
            _clean(r.get_all_text())
            for r in group.css(".views-field-weight-class-rank")
        ]
        for i, c in enumerate(contenders):
            rk = ranks[i] if i < len(ranks) else ""
            m = re.search(r"\d+", rk)
            c["rank"] = int(m.group()) if m else i + 1
            c["isChampion"] = False

        div = {"division": header, "champion": champ, "contenders": contenders}
        divisions.append(div)

        # Track global slug set with best (division, rank) info.
        if champ:
            seen_global.setdefault(champ["slug"],
                                   {"name": champ["name"], "division": header,
                                    "rank": 0, "isChampion": True})
        for c in contenders:
            seen_global.setdefault(c["slug"],
                                   {"name": c["name"], "division": header,
                                    "rank": c["rank"], "isChampion": False})

    return {"divisions": divisions, "athletes": seen_global}


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "rankings.html"
    with open(path, encoding="utf-8") as f:
        html = f.read()
    roster = parse_roster(html)
    with open("roster.json", "w", encoding="utf-8") as f:
        json.dump(roster, f, indent=2, ensure_ascii=False)
    print(f"divisions: {len(roster['divisions'])}, unique athletes: {len(roster['athletes'])}")
    for d in roster["divisions"]:
        champ = d["champion"]["name"] if d["champion"] else "—"
        print(f"  {d['division']:26s} champ={champ:22s} contenders={len(d['contenders'])}")
