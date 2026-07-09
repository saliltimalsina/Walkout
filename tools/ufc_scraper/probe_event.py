import re
import sys
from scrapling.parser import Selector

html = open(sys.argv[1] if len(sys.argv) > 1 else "event_detail.html").read()
s = Selector(html)


def t(css):
    return [re.sub(r"\s+", " ", e.get_all_text()).strip() for e in s.css(css)]


print("TITLE:", (t("title") or [""])[0])
print("prefix:", [x for x in t(".c-hero__headline-prefix") if x][:2])
print("headline:", [x for x in t(".c-hero__headline") if x][:2])
names = [n for n in t(".c-listing-fight__corner-name") if n]
print("corner names:", len(names), "first8:", names[:8])
wc = [w for w in t(".c-listing-fight__class-text") if w]
print("weightclasses:", wc[:8])
m = re.findall(r"(https://ufc\.com/images/styles/background_image_xl_2x/[^\"' ]+\.jpg)", html)
print("hero:", m[0][:100] if m else "NONE")
ts = re.findall(r"data-timestamp=.(\d+).", html)
print("timestamp:", ts[:2])
