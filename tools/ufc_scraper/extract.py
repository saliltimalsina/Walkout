"""Parse a UFC athlete page (HTML string) into a structured dict using Scrapling."""
import re
from scrapling.parser import Selector


def _clean(s):
    return re.sub(r"\s+", " ", (s or "")).strip()


def _first_text(root, css):
    r = root.css(css)
    return _clean(r[0].get_all_text()) if r else ""


def _all_text(root, css):
    return [t for t in (_clean(e.get_all_text()) for e in root.css(css)) if t]


def parse_athlete(html: str, url: str = "") -> dict:
    sel = Selector(html)
    data = {"url": url}

    # ── Hero ──────────────────────────────────────────────
    data["name"] = _first_text(sel, ".hero-profile__name")
    data["nickname"] = _first_text(sel, ".hero-profile__nickname").strip('"“”')
    data["division"] = _first_text(sel, ".hero-profile__division-title")
    data["record_raw"] = _first_text(sel, ".hero-profile__division-body")
    data["tags"] = _all_text(sel, ".hero-profile__tag")

    # Hero image: the full-body athlete portrait (skip icons/logos).
    data["image"] = ""
    for im in sel.css("img"):
        src = im.attrib.get("src", "") or ""
        if "athlete_bio" in src or "/styles/athlete" in src:
            data["image"] = src
            break

    # Hero headline stats (wins by KO, first-round finishes, etc.)
    hero_stats = {}
    for group in sel.css(".hero-profile__stat"):
        num = _first_text(group, ".hero-profile__stat-numb")
        label = _first_text(group, ".hero-profile__stat-text")
        if label:
            hero_stats[label] = num
    data["hero_stats"] = hero_stats

    # ── Accuracy circles (striking, takedown) ──
    data["accuracy_percents"] = _all_text(sel, ".e-chart-circle__percent")

    # ── Landed / attempted pairs (paired globally in DOM order) ──
    texts = _all_text(sel, ".c-overlap__stats-text")
    values = [_clean(e.get_all_text()) for e in sel.css(".c-overlap__stats-value")]
    landed = {}
    for i, k in enumerate(texts):
        landed[k] = values[i] if i < len(values) else ""
        if landed[k] == "":
            landed[k] = "0"
    data["landed"] = landed

    # ── Compare stats (per-min values, defense %, etc.) ──
    compare = {}
    for grp in sel.css(".c-stat-compare__group"):
        num = _first_text(grp, ".c-stat-compare__number")
        label = _first_text(grp, ".c-stat-compare__label")
        if label:
            compare[label] = num.replace(" %", "%")
    data["compare"] = compare

    # ── 3-bar groups (sig str by position, win by method) ──
    bars = {}
    for grp in sel.css(".c-stat-3bar__group"):
        label = _first_text(grp, ".c-stat-3bar__label")
        value = _first_text(grp, ".c-stat-3bar__value")
        if label:
            bars[label] = value
    data["bars"] = bars

    # ── Body target (head/body/leg) — SVG text nodes, best effort ──
    body = sel.css(".c-stat-body__diagram")
    data["body_target"] = _clean(body[0].get_all_text()) if body else ""

    # ── Bio fields ──
    bio = {}
    for field in sel.css(".c-bio__field"):
        label = _first_text(field, ".c-bio__label")
        value = _first_text(field, ".c-bio__text")
        if label:
            bio[label] = value
    data["bio"] = bio

    return data


if __name__ == "__main__":
    import json
    import sys
    path = sys.argv[1] if len(sys.argv) > 1 else "nariman.html"
    with open(path, encoding="utf-8") as f:
        html = f.read()
    print(json.dumps(parse_athlete(html), indent=2, ensure_ascii=False))
