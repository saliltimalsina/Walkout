#!/usr/bin/env python3
"""Parser tests for ingest.py, run against captured ufc.com markup.

The scrapers are regex over someone else's HTML, so the failure mode that
matters is a silent one: a layout tweak makes a pattern miss and the field goes
quietly empty or, worse, picks up a neighbouring value. These fixtures pin the
shapes each parser depends on.

    python tools/ingest/test_parsers.py
"""
import sys
import types
import unittest
from pathlib import Path

# ingest.py imports firebase_admin at module scope; the parsers never touch it.
_fa = types.ModuleType("firebase_admin")
_fa._apps = {}
sys.modules["firebase_admin"] = _fa
for _n in ("credentials", "firestore", "messaging"):
    _m = types.ModuleType(f"firebase_admin.{_n}")
    setattr(_fa, _n, _m)
    sys.modules[f"firebase_admin.{_n}"] = _m
_fa.firestore.SERVER_TIMESTAMP = "TS"

sys.path.insert(0, str(Path(__file__).parent))
import ingest  # noqa: E402


class RankChange(unittest.TestCase):
    def test_climb(self):
        cell = ('<span class="athlete-rankings--rank-change '
                'athlete-rankings--rank-increase">Rank increased by</span> 3')
        self.assertEqual(ingest._rank_change(cell), (3, False))

    def test_drop_is_negative(self):
        cell = ('<span class="athlete-rankings--rank-change '
                'athlete-rankings--rank-decrease">Rank decreased by</span> 2')
        self.assertEqual(ingest._rank_change(cell), (-2, False))

    def test_new_entry(self):
        cell = ('<span class="athlete-rankings--attribute '
                'athlete-rankings--not-ranked">NR</span>')
        self.assertEqual(ingest._rank_change(cell), (0, True))

    def test_no_movement(self):
        self.assertEqual(ingest._rank_change(" "), (0, False))


class WeightClassLabel(unittest.TestCase):
    def test_plain_bout(self):
        self.assertEqual(ingest._wc_from_label("Middleweight Bout"),
                         "middleweight")

    def test_title_bout(self):
        self.assertEqual(ingest._wc_from_label("Welterweight Title Bout"),
                         "welterweight")

    def test_womens_division(self):
        self.assertEqual(
            ingest._wc_from_label("Women's Strawweight Title Bout"),
            "womenStrawweight")

    def test_interim_title(self):
        self.assertEqual(ingest._wc_from_label("Lightweight Interim Title Bout"),
                         "lightweight")

    def test_catchweight_has_no_division(self):
        self.assertEqual(ingest._wc_from_label("Catchweight Bout"), "")


class Conversions(unittest.TestCase):
    def test_inches_to_cm(self):
        self.assertEqual(ingest._in_to_cm("70.50"), 179)
        self.assertEqual(ingest._in_to_cm(""), 0)

    def test_iso_is_utc_with_z(self):
        # Must render in UTC regardless of the runner's TZ — a naive string
        # would be reparsed as device-local on the phone.
        self.assertEqual(ingest._iso(1786842000),
                         "2026-08-16T01:00:00.000Z")


class BoutKey(unittest.TestCase):
    def test_corner_order_does_not_matter(self):
        a = {"redCornerId": "x", "blueCornerId": "y"}
        b = {"redCornerId": "y", "blueCornerId": "x"}
        self.assertEqual(ingest._bout_key(a), ingest._bout_key(b))

    def test_falls_back_to_names_when_unrostered(self):
        a = {"redCornerId": "", "redName": "A B", "blueCornerId": "",
             "blueName": "C D"}
        self.assertEqual(ingest._bout_key(a), frozenset(("A B", "C D")))

    def test_distinct_pairs_differ(self):
        a = {"redCornerId": "x", "blueCornerId": "y"}
        c = {"redCornerId": "x", "blueCornerId": "z"}
        self.assertNotEqual(ingest._bout_key(a), ingest._bout_key(c))


class RankIndex(unittest.TestCase):
    def test_champion_has_no_position(self):
        idx = ingest._rank_index([{
            "weightClass": "lightweight",
            "championId": "champ",
            "contenders": [{"fighterId": "one", "position": 1, "change": 0,
                            "isNew": False}],
        }])
        self.assertEqual(idx["champ"], (None, True))
        self.assertEqual(idx["one"], (1, False))

    def test_champion_of_one_division_outranks_a_contender_slot(self):
        # A champ who also appears in another division's top 15 stays a champ.
        idx = ingest._rank_index([
            {"weightClass": "lightweight", "championId": "dual",
             "contenders": []},
            {"weightClass": "welterweight", "championId": "other",
             "contenders": [{"fighterId": "dual", "position": 4,
                             "change": 0, "isNew": False}]},
        ])
        self.assertEqual(idx["dual"], (None, True))


class EventArt(unittest.TestCase):
    ART = ('<div style="background-image:url(https://ufc.com/images/styles/'
           'background_image_lg/s3/2026-10/103126-ufc-fight-night-moicano-vs-'
           'nolan-EVENT-ART.jpg?h=d1cb525d&amp;itok=aaK1fus3)">')

    def test_picks_poster_and_normalizes(self):
        self.assertEqual(
            ingest.parse_event_art(self.ART),
            "https://www.ufc.com/images/styles/background_image_lg/s3/2026-10/"
            "103126-ufc-fight-night-moicano-vs-nolan-EVENT-ART.jpg"
            "?h=d1cb525d&itok=aaK1fus3")

    def test_generic_placeholder_is_skipped(self):
        page = ('<img src="https://ufc.com/images/styles/background_image_lg/'
                's3/image/2023-11/BACKGROUND%204.jpg?h=d1cb525d&amp;itok=x">')
        self.assertEqual(ingest.parse_event_art(page), "")

    def test_no_art(self):
        self.assertEqual(ingest.parse_event_art("<html></html>"), "")


class FighterName(unittest.TestCase):

    def test_name_from_hero(self):
        page = ('<h1 class="hero-profile__name">Sumudaerji</h1>'
                '<p class="hero-profile__division-title">Flyweight Division</p>'
                '<p>15-6-0 (W-L-D)</p>')
        ingest.fetch, orig = (lambda url: page), ingest.fetch
        try:
            doc = ingest.scrape_fighter("su-mudaerji")
        finally:
            ingest.fetch = orig
        self.assertEqual(doc["name"], "Sumudaerji")
        self.assertEqual(doc["record"]["wins"], 15)


class RequiredFields(unittest.TestCase):

    def test_nameless_fighter_is_flagged(self):
        self.assertEqual(
            ingest.missing_fields("fighters", {"id": "x", "weightClass": "flyweight"}),
            ["name"])

    def test_unknown_weight_class_is_flagged(self):
        self.assertEqual(ingest.missing_fields(
            "fighters", {"id": "x", "name": "X", "weightClass": "catchweight"}),
            ["weightClass"])

    def test_complete_event_passes(self):
        self.assertEqual(ingest.missing_fields(
            "events", {"id": "a", "name": "UFC 1", "date": "2026-01-01"}), [])

    def test_empty_string_counts_as_missing(self):
        self.assertEqual(ingest.missing_fields(
            "events", {"id": "a", "name": "UFC 1", "date": ""}), ["date"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
