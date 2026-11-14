"""Guard: input names yes, doses no (owner decision 2026-11-14, OPEN_QUESTIONS Q160).

Over every grower-facing text bundled with the app (its config assets, the offline Q&A asset,
its screen strings) and the API's grower texts (knowledge-card grower view, risk alerts, stage
and task seeds): no dose, quantity, rate or concentration of an input in any language; every
line that recommends an input ends with the expert-advice note in its own language; and no
ingredient banned, or restricted for santra / mosambi, is ever named.
"""

from __future__ import annotations

import gzip
import json
from collections.abc import Iterator
from importlib import resources
from pathlib import Path
from typing import Any

import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.kb import dose_rules
from bagmitra_api.kb.grower_view import grower_text
from bagmitra_api.kb.seed import knowledge_seeds

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "app" / "assets" / "config"
ARB = ROOT / "app" / "lib" / "l10n"
API = ROOT / "api" / "src" / "bagmitra_api"
LANGS = ("en", "mr", "hi")
# Keys that hold no grower text: notes for maintainers, source records, ids and search keys
# (a Q&A entry's paraphrases "p" only build its search keys; the app never shows them).
_NOT_TEXT = frozenset(
    {"_note", "note", "source", "source_keys", "sources", "src", "evidence", "url", "quote",
     "read", "checked", "id", "k", "p", "t", "sec", "s", "key", "slug", "figure", "kb_topic",
     "label_target", "preparation", "publisher", "title_en"}
)  # fmt: skip


def _strings(node: Any, path: str = "") -> Iterator[tuple[str, str]]:
    if isinstance(node, dict):
        for k, v in node.items():
            if k not in _NOT_TEXT:
                yield from _strings(v, f"{path}.{k}")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from _strings(v, f"{path}[{i}]")
    elif isinstance(node, str):
        yield path, node


def _load(path: Path) -> Any:
    raw = gzip.decompress(path.read_bytes()) if path.suffix == ".gz" else path.read_bytes()
    return json.loads(raw)


def _bundled() -> Iterator[tuple[str, str]]:
    for path in sorted(CONFIG.iterdir()):
        if path.suffix in {".json", ".gz"}:
            yield from ((f"{path.name}{p}", s) for p, s in _strings(_load(path)))
    for lang in LANGS:
        arb = json.loads((ARB / f"app_{lang}.arb").read_text("utf-8"))
        yield from ((f"app_{lang}.arb.{k}", v) for k, v in arb.items() if not k.startswith("@"))
    for name in ("risk/rules.json",):
        yield from ((f"{name}{p}", s) for p, s in _strings(_load(API / name)))
    seeds = resources.files("bagmitra_api.bahar.seed_data")
    for entry in seeds.iterdir():
        if entry.name.endswith(".json"):
            data = json.loads(entry.read_text("utf-8"))
            yield from ((f"bahar/{entry.name}{p}", s) for p, s in _strings(data))
    for card in knowledge_seeds().cards:
        for lang, fields in grower_text(card.content).items():
            for field, text in fields.items():
                yield f"knowledge:{card.topic}:{card.crop}.{lang}.{field}", text


def _banned() -> frozenset[str]:
    settings = Settings(environment="test")
    rows = json.loads(
        resources.files("bagmitra_api.kb.seed_data").joinpath("restrictions.json").read_text()
    )["restrictions"]
    out: set[str] = set()
    for crop in ("santra", "mosambi"):
        out |= dose_rules.banned_names(
            rows, settings.kb_crop_label_aliases[crop], settings.kb_crop_groups[crop]
        )
    return frozenset(out)


def test_no_dose_anywhere_a_grower_reads() -> None:
    texts = list(_bundled())
    assert len(texts) > 10_000  # the walk really covers the assets
    found = [(where, dose_rules.dose_spans(text)) for where, text in texts]
    assert [f for f in found if f[1]] == []


def test_no_banned_or_crop_restricted_ingredient_is_named() -> None:
    banned = _banned()
    assert {"dicofol", "dichlorvos", "chlorpyrifos", "dimethoate", "phorate"} <= banned
    named = [(where, dose_rules.names_banned(text, banned)) for where, text in _bundled()]
    assert [n for n in named if n[1]] == []


def _practice_lines() -> Iterator[tuple[str, dict[str, str]]]:
    cards = _load(CONFIG / "practice_cards.json")
    for s in cards["sections"]:
        for item in s.get("items", []):
            yield f"item {item['id']}", item["labels"]
        profile = s.get("profile") or {}
        for part in ("symptoms", "when", "scouting", "action_level"):
            if part in profile:
                yield f"{s['key']}.{part}", profile[part]["labels"]
        for bio in profile.get("bio", []):
            yield f"bio {bio['id']}", bio["labels"]
    for key, prep in cards["preparations"].items():
        yield f"preparation {key}", prep["labels"]


def _qa_lines() -> Iterator[tuple[str, dict[str, str]]]:
    for e in _load(CONFIG / "qa_kb.json.gz")["entries"]:
        if str(e["t"]).startswith(("howto:", "fco")):
            continue  # the app's own screens and a schedule list: not advice
        for i in range(len(e["a"]["en"])):
            yield f"{e['id']}[{i}]", {lang: e["a"][lang][i] for lang in LANGS}


@pytest.mark.parametrize("lines", [_practice_lines, _qa_lines], ids=["practice", "qa"])
def test_every_input_recommendation_carries_the_note(lines: Any) -> None:
    missing = []
    noted = 0
    for where, labels in lines():
        if not dose_rules.names_input(labels["en"]):
            continue
        noted += 1
        for lang in LANGS:
            if not labels[lang].rstrip().endswith(dose_rules.NOTE[lang]):
                missing.append((where, lang, labels[lang]))
    assert noted > 20
    assert missing == []


def test_every_bio_option_and_preparation_is_noted() -> None:
    """The organic / bio list and the home preparations are recommendations by definition."""
    cards = _load(CONFIG / "practice_cards.json")
    labels = [
        b["labels"] for s in cards["sections"] for b in (s.get("profile") or {}).get("bio", [])
    ]
    labels += [p["labels"] for p in cards["preparations"].values()]
    assert labels
    for entry in labels:
        for lang in LANGS:
            assert entry[lang].endswith(dose_rules.NOTE[lang]), entry["en"]


def test_the_api_seed_copy_of_the_practice_cards_is_the_app_file() -> None:
    seed = API / "kb" / "seed_data" / "practice_cards.json"
    assert seed.read_bytes() == (CONFIG / "practice_cards.json").read_bytes()


@pytest.mark.parametrize(
    ("text", "dose"),
    [
        ("Neem oil 1 % on the new flush.", True),
        ("NSKE 5 % against psylla.", True),
        ("Urea 500 g per tree in November.", True),
        ("Hang yellow sticky traps (30/acre).", True),
        ("Release Cryptolaemus at 10 beetles per tree.", True),
        ("The dose printed is 2.5 per ha (a.i. 1.25).", True),
        ("Spray Streptocycline as a 50 to 100 ppm solution.", True),
        ("Give 300 g N + 150 g P per plant.", True),
        ("एकरी ३० पिवळे चिकट सापळे लावा.", True),
        ("१ % निंबोळी तेल फवारा.", True),
        ("नीम तेल प्रति लीटर 10 मि.ली.।", True),
        ("About one third of the recommended nitrogen dose through FYM.", True),
        # Not a dose: water, weather, soil tests, timings, results and product names.
        ("100–120 litres of water per tree per day.", False),
        ("Humidity above 80 % favours powdery mildew.", False),
        ("Plant santra only where CaCO3 is below 6 %.", False),
        ("Azadirachtin twice, 15 days apart (MPKV).", False),
        ("Imidacloprid 17.80% SL: for leaf miner, PHI 15 days.", False),
        ("Neem oil; in MPKV trials it cut fruit drop by 10–24 %.", False),
        ("Keep a 15-day interval between doses.", False),
        ("Mono Ammonium Phosphate 12:61:0 (100% water soluble).", False),
        ("पहचान और पते का प्रमाण (आधार, पैन आदि)", False),
    ],
)
def test_dose_rules(text: str, dose: bool) -> None:
    assert dose_rules.has_dose(text) is dose, dose_rules.dose_spans(text)


def test_the_note_is_added_once_in_each_language() -> None:
    assert dose_rules.with_note("Use neem oil.", "en") == "Use neem oil. (follow expert advice)"
    once = dose_rules.with_note("निंबोळी तेल वापरा.", "mr")
    assert once == "निंबोळी तेल वापरा. (तज्ज्ञांच्या सल्ल्याने करावे)"
    assert dose_rules.with_note(once, "mr") == once
    assert dose_rules.with_note("नीम तेल।", "hi").endswith("(विशेषज्ञ की सलाह से करें)")
    assert dose_rules.names_input("Use neem oil.")
    assert not dose_rules.names_input("Conserve ladybird beetles and lacewings.")
    assert not dose_rules.names_input("Cover the stem with a used fertiliser bag strip.")


def test_article_sections_get_the_note() -> None:
    noted = dose_rules.note_sections(
        {
            "en": (("What to do", "Use neem oil."), ("When", "In June.")),
            "mr": (("काय करावे", "निंबोळी तेल वापरा."), ("केव्हा", "जूनमध्ये.")),
            "hi": (("क्या करें", "नीम तेल लें।"),),
        }
    )
    assert noted["en"][0][1].endswith(dose_rules.NOTE["en"])
    assert noted["en"][1][1] == "In June."
    assert noted["mr"][0][1].endswith(dose_rules.NOTE["mr"])
    # A language with a different section count gets the note once, at its end.
    assert noted["hi"][-1][1].endswith(dose_rules.NOTE["hi"])
