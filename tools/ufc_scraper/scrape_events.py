"""Scrape UFC events (list + detail) into events_raw.json + hero cover images."""
import json
import os
import re
import sys
import time
from patchright.sync_api import sync_playwright
from scrapling.parser import Selector

OUT = "output"
HERO_DIR = os.path.join(OUT, "heroes")
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")


def _clean(s):
    return re.sub(r"\s+", " ", (s or "")).strip()


def _txt(root, css):
    r = root.css(css)
    return _clean(r[0].get_all_text()) if r else ""


def parse_event(html, slug):
    s = Selector(html)
    title = _txt(s, "title")
    # "UFC Fight Night: Du Plessis vs Usman | UFC Oklahoma City"
    city = ""
    if "|" in title:
        right = title.split("|", 1)[1].strip()
        city = re.sub(r"^UFC\s+", "", right).strip()

    prefix = _txt(s, ".c-hero__headline-prefix")
    headline = _txt(s, ".c-hero__headline")

    ts = re.findall(r"data-timestamp=.(\d+).", html)
    timestamp = int(ts[0]) if ts else 0

    hero = re.findall(
        r"(https://ufc\.com/images/styles/background_image_xl_2x/[^\"' ]+\.jpg)",
        html)
    hero_url = hero[0].replace("&amp;", "&") if hero else ""

    bouts = []
    for fight in s.css(".c-listing-fight"):
        red = _txt(fight, ".c-listing-fight__corner-name--red")
        blue = _txt(fight, ".c-listing-fight__corner-name--blue")
        wc = _txt(fight, ".c-listing-fight__class-text")
        # Per-corner athlete slugs (first link = red, second = blue).
        slugs = []
        for a in fight.css('a[href*="/athlete/"]'):
            m = re.search(r"/athlete/([a-z0-9-]+)", a.attrib.get("href", "") or "")
            if m and m.group(1) not in slugs:
                slugs.append(m.group(1))
        if red or blue:
            bouts.append({
                "red": red,
                "blue": blue,
                "weightClass": wc,
                "redSlug": slugs[0] if len(slugs) > 0 else "",
                "blueSlug": slugs[1] if len(slugs) > 1 else "",
            })

    return {
        "slug": slug,
        "eventType": prefix,       # "UFC Fight Night" / "UFC 328"
        "mainEvent": headline,     # "Du Plessis vs Usman"
        "city": city,
        "timestamp": timestamp,
        "heroUrl": hero_url,
        "bouts": bouts,
    }


def valid_slug(slug):
    return slug.startswith("ufc-") and slug != "ufc" and len(slug) > 5


def main():
    os.makedirs(HERO_DIR, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(viewport={"width": 1400, "height": 2400},
                                  user_agent=UA)
        page = ctx.new_page()

        # List page -> slugs
        page.goto("https://www.ufc.com/events", wait_until="domcontentloaded",
                  timeout=60000)
        try:
            page.wait_for_load_state("networkidle", timeout=10000)
        except Exception:
            pass
        list_html = page.content()
        slugs = sorted({m for m in re.findall(r"/event/([a-z0-9-]+)", list_html)
                        if valid_slug(m)})
        print(f"{len(slugs)} event slugs", flush=True)

        events = []
        for i, slug in enumerate(slugs, 1):
            url = f"https://www.ufc.com/event/{slug}"
            try:
                page.goto(url, wait_until="domcontentloaded", timeout=45000)
                try:
                    page.wait_for_load_state("networkidle", timeout=8000)
                except Exception:
                    pass
                ev = parse_event(page.content(), slug)
                # download hero
                ev["heroFile"] = ""
                if ev["heroUrl"]:
                    try:
                        r = ctx.request.get(ev["heroUrl"], timeout=30000)
                        if r.ok:
                            fn = f"{slug}.jpg"
                            with open(os.path.join(HERO_DIR, fn), "wb") as fh:
                                fh.write(r.body())
                            ev["heroFile"] = fn
                    except Exception as e:
                        print(f"  hero fail {slug}: {e}", flush=True)
                events.append(ev)
                print(f"[{i}/{len(slugs)}] {slug} :: {ev['eventType']} | "
                      f"{ev['mainEvent']} | bouts={len(ev['bouts'])} "
                      f"hero={'y' if ev['heroFile'] else 'n'}", flush=True)
            except Exception as e:
                print(f"[{i}/{len(slugs)}] {slug} FAIL {str(e)[:70]}", flush=True)
            time.sleep(0.8)

        browser.close()

    with open(os.path.join(OUT, "events_raw.json"), "w") as f:
        json.dump(events, f, indent=2, ensure_ascii=False)
    print(f"DONE events={len(events)}", flush=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--offline":
        html = open("event_detail.html").read()
        print(json.dumps(parse_event(html, "ufc-fight-night-july-18-2026"),
                         indent=2, ensure_ascii=False)[:1500])
    else:
        main()
