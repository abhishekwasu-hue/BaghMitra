"""Legal & safety gate (addendum v1.3 §4): decides whether a chemical may be shown.

Pure and data-driven: label claims, restrictions and synonyms come from the CIB&RC / gazette
importers; crop aliases and groups come from config. A failing check suppresses the chemical;
callers then show cultural/organic options plus "consult your local expert/KVK".
"""

from __future__ import annotations

import re
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Literal

RestrictionKind = Literal["banned", "withdrawn", "refused", "restricted"]


@dataclass(frozen=True, slots=True)
class Restriction:
    active_ingredient: str
    kind: RestrictionKind
    # For "restricted": crops and crop groups the restriction applies to.
    crops: tuple[str, ...]
    crop_groups: tuple[str, ...]
    notification: str


@dataclass(frozen=True, slots=True)
class LabelClaim:
    active_ingredient: str
    formulation: str
    crop: str
    target: str
    dose: str
    interval_days: int | None
    phi_days: int | None
    max_sprays: int | None
    source_key: str


@dataclass(frozen=True, slots=True)
class ChemicalOption:
    active_ingredient: str
    formulation: str
    target: str


@dataclass(frozen=True, slots=True)
class GateContext:
    crop_aliases: frozenset[str]  # label crop names covering this crop, e.g. citrus, mandarin
    crop_groups: frozenset[str]  # e.g. fruit_eaten_raw
    claims: Sequence[LabelClaim]
    restrictions: Sequence[Restriction]
    synonyms: Mapping[str, str]  # trade/brand/abbreviation -> active ingredient


@dataclass(frozen=True, slots=True)
class GateResult:
    allowed: bool
    reasons: list[str] = field(default_factory=list)
    claim: LabelClaim | None = None


_SPACES = re.compile(r"\s+")


def _key(text: str) -> str:
    return _SPACES.sub(" ", text.strip().lower())


def normalise_ai(name: str, synonyms: Mapping[str, str]) -> str:
    key = _key(name)
    lowered = {_key(k): _key(v) for k, v in synonyms.items()}
    return lowered.get(key, key)


def restriction_reasons(active_ingredient: str, ctx: GateContext) -> list[str]:
    reasons: list[str] = []
    for r in ctx.restrictions:
        if _key(r.active_ingredient) != active_ingredient:
            continue
        if r.kind != "restricted":
            reasons.append("banned")
        elif ctx.crop_aliases & set(map(_key, r.crops)) or ctx.crop_groups & set(r.crop_groups):
            reasons.append("restricted_for_crop")
    return sorted(set(reasons))


def crop_claims(active_ingredient: str, ctx: GateContext) -> list[LabelClaim]:
    return [
        c
        for c in ctx.claims
        if _key(c.active_ingredient) == active_ingredient and _key(c.crop) in ctx.crop_aliases
    ]


def evaluate(
    option: ChemicalOption, ctx: GateContext, *, today: date, planned_harvest: date | None
) -> GateResult:
    ai = normalise_ai(option.active_ingredient, ctx.synonyms)
    blocked = restriction_reasons(ai, ctx)
    if blocked:
        return GateResult(allowed=False, reasons=blocked)
    claim = next(
        (
            c
            for c in crop_claims(ai, ctx)
            if _key(c.formulation) == _key(option.formulation)
            and _key(c.target) == _key(option.target)
        ),
        None,
    )
    if claim is None:
        return GateResult(allowed=False, reasons=["no_label_claim"])
    if (
        planned_harvest is not None
        and claim.phi_days is not None
        and today + timedelta(days=claim.phi_days) > planned_harvest
    ):
        return GateResult(allowed=False, reasons=["phi_conflict"], claim=claim)
    return GateResult(allowed=True, claim=claim)
