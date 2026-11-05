"""Alert texts in rules.json: same numbers in every language, Marathi glossary (audit C3, C6)."""

from __future__ import annotations

import re

from bagmitra_api.risk.engine import load_rules

_DEVANAGARI = str.maketrans("०१२३४५६७८९", "0123456789")

# Variant -> glossary term (docs/agronomy/GLOSSARY_mr.md).
_MR_VARIANTS = {
    "पालवी": "नवती",
    "सिल्ला": "सायला",
    "काढणी": "तोडणी",
    "मिमी": "मि.मी.",
    "किमी": "कि.मी.",
}


def _numbers(text: str) -> set[str]:
    return set(re.findall(r"\d+(?:\.\d+)?", text.translate(_DEVANAGARI)))


def test_every_english_number_is_in_marathi_and_hindi() -> None:
    for r in load_rules():
        en = _numbers(r.labels["en"])
        for lang in ("mr", "hi"):
            assert en <= _numbers(r.labels[lang]), (r.key, lang)


def test_marathi_alerts_use_the_glossary_terms() -> None:
    for r in load_rules():
        for variant, term in _MR_VARIANTS.items():
            assert variant not in r.labels["mr"], (r.key, variant, term)


def test_number_check_sees_devanagari_digits() -> None:
    assert _numbers("६४.५ मि.मी. व ३५ °C") == {"64.5", "35"}
