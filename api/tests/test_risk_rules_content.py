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


def test_alert_texts_are_calm_and_send_no_one_to_an_expert() -> None:
    """Owner 2026-11-10: no alarming words and no "confirm with an expert" line; the alert says
    what may happen and what to look at (the app's own notes went the same way in #331)."""
    import json  # noqa: PLC0415
    from pathlib import Path  # noqa: PLC0415

    import bagmitra_api.risk as risk_pkg  # noqa: PLC0415

    data = json.loads((Path(risk_pkg.__file__).parent / "rules.json").read_text("utf-8"))
    rules = data if isinstance(data, list) else data["rules"]
    alarming = {
        "en": ("risk", "verify with your local expert", "danger"),
        "mr": ("धोका", "तज्ज्ञांकडून खात्री"),
        "hi": ("जोखिम", "खतरा", "विशेषज्ञ से पुष्टि"),
    }
    for rule in rules:
        for lang, words in alarming.items():
            text = rule["labels"][lang].lower()
            assert not [w for w in words if w in text], (rule["key"], lang, text)
