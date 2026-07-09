"""Scrape full athlete detail pages for every slug in roster.json.

Reuses one stealth Chromium session, extracts stats via extract.parse_athlete,
downloads each portrait, and writes output/athletes.json + output/images/<slug>.png.
"""
import json
import os
import time
from patchright.sync_api import sync_playwright

from extract import parse_athlete

OUT_DIR = "output"
IMG_DIR = os.path.join(OUT_DIR, "images")
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)


def main():
    os.makedirs(IMG_DIR, exist_ok=True)
    with open("roster.json", encoding="utf-8") as f:
        roster = json.load(f)

    athletes_meta = roster["athletes"]  # slug -> {name, division, rank, isChampion}
    slugs = list(athletes_meta.keys())
    print(f"Scraping {len(slugs)} athletes…", flush=True)

    results = []
    failures = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(viewport={"width": 1400, "height": 2200}, user_agent=UA)
        page = ctx.new_page()

        for i, slug in enumerate(slugs, 1):
            url = f"https://www.ufc.com/athlete/{slug}"
            try:
                resp = page.goto(url, wait_until="domcontentloaded", timeout=45000)
                try:
                    page.wait_for_load_state("networkidle", timeout=8000)
                except Exception:
                    pass
                data = parse_athlete(page.content(), url)
                data["slug"] = slug
                data["ranking_meta"] = athletes_meta[slug]

                # Download portrait via the browser's request context.
                img_url = data.get("image", "")
                img_path = ""
                if img_url:
                    try:
                        r = ctx.request.get(img_url, timeout=30000)
                        if r.ok:
                            img_path = os.path.join(IMG_DIR, f"{slug}.png")
                            with open(img_path, "wb") as fh:
                                fh.write(r.body())
                    except Exception as e:
                        print(f"  img fail {slug}: {e}", flush=True)
                data["image_file"] = os.path.basename(img_path) if img_path else ""

                results.append(data)
                status = resp.status if resp else "?"
                print(f"[{i}/{len(slugs)}] {slug} ({status}) "
                      f"name={data['name'][:28]!r} img={'y' if img_path else 'n'}",
                      flush=True)
            except Exception as e:
                failures.append({"slug": slug, "error": str(e)[:120]})
                print(f"[{i}/{len(slugs)}] {slug} FAILED: {str(e)[:80]}", flush=True)

            time.sleep(1.0)  # be polite

        browser.close()

    with open(os.path.join(OUT_DIR, "athletes.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    with open(os.path.join(OUT_DIR, "failures.json"), "w", encoding="utf-8") as f:
        json.dump(failures, f, indent=2, ensure_ascii=False)

    print(f"DONE. ok={len(results)} failed={len(failures)} "
          f"-> {OUT_DIR}/athletes.json", flush=True)


if __name__ == "__main__":
    main()
