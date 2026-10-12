"""Post-generation output filter (addendum v1.3 §7).

Scans any grower-facing text (AI answer, alert, notification, voice script) for chemical
names and drops every sentence that mentions one which may not be shown:
- trade/brand names are always dropped (never show brand names, §4);
- a generic active ingredient survives only if it is not banned/restricted for the crop
  and has at least one label claim for the crop (free text carries no target, so this is
  the strictest check possible; card-level advice goes through `gate.evaluate`).
"""

from __future__ import annotations

import re
from collections.abc import Iterable
from dataclasses import dataclass

from bagmitra_api.kb.gate import GateContext, crop_claims, restriction_reasons

_SENTENCE = re.compile(r"[^.!?।]+[.!?।]?\s*")


@dataclass(frozen=True, slots=True)
class FilterResult:
    text: str
    removed: list[str]


def _mentions(sentence: str, names: Iterable[str]) -> list[str]:
    lowered = sentence.lower()
    return [n for n in names if re.search(rf"(?<!\w){re.escape(n)}(?!\w)", lowered)]


def filter_text(
    text: str,
    ctx: GateContext,
    *,
    known_ingredients: Iterable[str],
) -> FilterResult:
    synonyms = {k.strip().lower(): v.strip().lower() for k, v in ctx.synonyms.items()}
    generics = {n.strip().lower() for n in known_ingredients} | set(synonyms.values())
    kept: list[str] = []
    removed: list[str] = []
    for sentence in _SENTENCE.findall(text):
        brands = _mentions(sentence, synonyms)
        blocked = [synonyms[b] for b in brands]
        for ai in _mentions(sentence, generics):
            if restriction_reasons(ai, ctx) or not crop_claims(ai, ctx):
                blocked.append(ai)
        if blocked:
            removed.extend(b for b in blocked if b not in removed)
        else:
            kept.append(sentence)
    return FilterResult(text="".join(kept).strip(), removed=removed)
