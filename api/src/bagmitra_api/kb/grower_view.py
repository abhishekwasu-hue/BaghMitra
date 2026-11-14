"""The grower view of a knowledge card (owner decisions Q57 and Q160).

Owner 2026-11-14 (Q160): fertilisers, pesticides and organic / bio inputs may be named, but no
dose, quantity, rate or concentration reaches a grower, and each sentence that recommends an
input ends with the expert-advice note. So a sentence is left out when it carries a dose
(`kb/dose_rules.py`) or names an ingredient banned, or restricted for the card's crop; a
sentence that names an input keeps it and gets the note (warnings say what NOT to do, so they
get no note). A card's chemical options and its `organic` text (written as rates, English only)
stay out. The screen runs on the English text; Marathi and Hindi are written sentence for
sentence, so the same sentences are left out there too, and a translation whose sentences do
not line up with the English is not shown.
"""

from __future__ import annotations

import re
from collections.abc import Iterable, Mapping

from bagmitra_api.kb.dose_rules import has_dose, names_banned, names_input, with_note

# The fields a grower may see. `organic` is never one of them: it is written as rates.
FIELDS = ("title", "summary", "cultural", "warnings", "when_to_call_expert")
# Fields whose input-naming sentences are recommendations (and get the note).
_ADVICE_FIELDS = frozenset({"summary", "cultural", "when_to_call_expert"})
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


def _blocked(sentence: str, own: str, banned: Iterable[str]) -> bool:
    return any(has_dose(t) or names_banned(t, banned) for t in (sentence, own))


def grower_text(
    content: Mapping[str, Mapping[str, str]], banned: Iterable[str] = ()
) -> dict[str, dict[str, str]]:
    """Per language, the card fields a grower may see; a field with nothing left is dropped.
    `banned`: lower-cased ingredient names banned or restricted for the card's crop."""
    banned = frozenset(banned)
    english = content.get("en", {})
    out: dict[str, dict[str, str]] = {}
    for lang, fields in content.items():
        kept_fields: dict[str, str] = {}
        for field in FIELDS:
            en = sentences(english.get(field, ""))
            own = sentences(fields.get(field, ""))
            if not en or len(own) != len(en):
                continue
            kept = [
                with_note(s, lang) if field in _ADVICE_FIELDS and names_input(e) else s
                for s, e in zip(own, en, strict=True)
                if not _blocked(e, s, banned)
            ]
            if kept:
                kept_fields[field] = " ".join(kept)
        if kept_fields:
            out[lang] = kept_fields
    return out
