"""Scrape detail pages for the delta athletes (bout fighters not already in the
roster) and MERGE them into output/athletes.json + output/images."""
import json
import os
import time
from patchright.sync_api import sync_playwright

from extract import parse_athlete

OUT = "output"
IMG_DIR = os.path.join(OUT, "images")
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")


def main():
    os.makedirs(IMG_DIR, exist_ok=True)
    delta = json.load(open("delta_slugs.json"))
    existing = json.load(open(os.path.join(OUT, "athletes.json")))
    have = {a["slug"] for a in existing}
    todo = [s for s in delta if s not in have]
    print(f"delta to scrape: {len(todo)}", flush=True)

    added = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(viewport={"width": 1400, "height": 2200},
                                  user_agent=UA)
        page = ctx.new_page()
        for i, slug in enumerate(todo, 1):
            url = f"https://www.ufc.com/athlete/{slug}"
            try:
                page.goto(url, wait_until="domcontentloaded", timeout=45000)
                try:
                    page.wait_for_load_state("networkidle", timeout=6000)
                except Exception:
                    pass
                data = parse_athlete(page.content(), url)
                data["slug"] = slug
                div = (data.get("division", "") or "").replace(" Division", "").strip()
                data["ranking_meta"] = {
                    "name": data.get("name", ""),
                    "division": div,
                    "rank": 0,
                    "isChampion": False,
                }
                img_file = ""
                if data.get("image"):
                    try:
                        r = ctx.request.get(data["image"], timeout=30000)
                        if r.ok:
                            img_file = f"{slug}.png"
                            with open(os.path.join(IMG_DIR, img_file), "wb") as fh:
                                fh.write(r.body())
                    except Exception:
                        pass
                data["image_file"] = img_file
                added.append(data)
                if i % 20 == 0 or i == len(todo):
                    print(f"[{i}/{len(todo)}] {slug} img={'y' if img_file else 'n'}",
                          flush=True)
            except Exception as e:
                print(f"[{i}/{len(todo)}] {slug} FAIL {str(e)[:60]}", flush=True)
            time.sleep(0.6)
        browser.close()

    merged = existing + added
    json.dump(merged, open(os.path.join(OUT, "athletes.json"), "w"),
              indent=2, ensure_ascii=False)
    print(f"DONE added={len(added)} total={len(merged)}", flush=True)


if __name__ == "__main__":
    main()
