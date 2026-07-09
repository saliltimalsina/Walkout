"""Fetch one UFC athlete page with patchright (stealth Chromium) and dump HTML."""
import sys
from patchright.sync_api import sync_playwright

url = sys.argv[1] if len(sys.argv) > 1 else "https://www.ufc.com/athlete/nariman-abbassov"

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    ctx = browser.new_context(
        viewport={"width": 1400, "height": 2200},
        user_agent=(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/131.0.0.0 Safari/537.36"
        ),
    )
    page = ctx.new_page()
    resp = page.goto(url, wait_until="domcontentloaded", timeout=60000)
    try:
        page.wait_for_load_state("networkidle", timeout=15000)
    except Exception:
        pass
    html = page.content()
    print("STATUS:", resp.status if resp else "?")
    print("HTML_LEN:", len(html))
    print("TITLE:", page.title())
    with open("nariman.html", "w", encoding="utf-8") as f:
        f.write(html)
    print("saved nariman.html")
    browser.close()
