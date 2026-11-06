"""The grower view of a knowledge card: general information only (owner decision Q57).

A card's chemical options, its `organic` text (which carries rates) and any sentence that names a
pesticide, fertiliser or other product, or carries a dose, are left out. The screen runs on the
English text; Marathi and Hindi are written sentence for sentence, so the same sentences are left
out there too, and a translation whose sentences do not line up with the English is not shown.
"""

from __future__ import annotations

import re
from collections.abc import Mapping

# The fields a grower may see. `organic` is never one of them: it carries rates.
FIELDS = ("title", "summary", "cultural", "warnings", "when_to_call_expert")

# Product, fertiliser and remedy words: a sentence naming one is left out of every field.
_PRODUCTS = (
    "abamectin",
    "ammonium",
    "antibiotic",
    "azadirachtin",
    "bacillus",
    "bio-nematicide",
    "borax",
    "bordeaux",
    "copper",
    "fertigation",
    "muriate",
    "neem",
    "nitrogen",
    "novaluron",
    "permanganate",
    "phosphate",
    "potash",
    "pseudomonas",
    "sulfate",
    "sulfur",
    "sulphate",
    "sulphur",
    "superphosphate",
    "trichoderma",
    "urea",
    "verticillium",
)
# Advice words: left out of the practice fields. Warnings may use them, because a warning says
# what is NOT shown or not legal ("older advisories list sprays that are no longer legal").
_ADVICE = (
    "chemical",
    "fungicide",
    "insecticide",
    "pesticide",
    "regulator",
    "reviewer",
    "spray",
    "spraying",
)
_DOSE = re.compile(r"\b\d+(?:\.\d+)?\s*(?:g|kg|mg|ml|ppm)\b|\bper litre\b", re.IGNORECASE)
# Abbreviations whose full stop does not end a sentence.
_ABBREVIATIONS = ("सें.मी.", "मि.मी.", "कि.मी.", " मी.", "डॉ.", "Dr.", "e.g.", "i.e.")
_END = re.compile(r"(?<=[.!?।])\s+")
_HOLD = "⁣"  # invisible separator, stands in for a protected full stop


def sentences(text: str) -> list[str]:
    """Split on a full stop (or ! ? ।) followed by a space, keeping abbreviations whole."""
    held = text.strip()
    for abbreviation in _ABBREVIATIONS:
        held = held.replace(abbreviation, abbreviation.replace(".", _HOLD))
    return [s.replace(_HOLD, ".") for s in _END.split(held) if s.strip()]


def _blocked(sentence: str, field: str) -> bool:
    lowered = sentence.lower()
    words = _PRODUCTS if field == "warnings" else _PRODUCTS + _ADVICE
    if any(re.search(rf"(?<![a-z]){re.escape(w)}", lowered) for w in words):
        return True
    return _DOSE.search(sentence) is not None


def grower_text(content: Mapping[str, Mapping[str, str]]) -> dict[str, dict[str, str]]:
    """Per language, the card fields a grower may see; a field with nothing left is dropped."""
    english = content.get("en", {})
    out: dict[str, dict[str, str]] = {}
    for lang, fields in content.items():
        kept_fields: dict[str, str] = {}
        for field in FIELDS:
            en = sentences(english.get(field, ""))
            own = sentences(fields.get(field, ""))
            if not en or len(own) != len(en):
                continue
            kept = [s for s, e in zip(own, en, strict=True) if not _blocked(e, field)]
            if kept:
                kept_fields[field] = " ".join(kept)
        if kept_fields:
            out[lang] = kept_fields
    return out
