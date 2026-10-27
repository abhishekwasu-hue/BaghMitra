"""Rule-based matching of feed items to a farmer (addendum v1.4 §4.7). No AI guesses.

An item's targets say who it is for (district, crop, land size in hectares); empty fields
mean "any", several targets mean "any of them", an item without targets is for everyone.
A target matches only when every field it sets is satisfied by data the farmer actually has:
missing profile data never counts as a match. The reasons are shown as "You may be eligible
because ..." (never "you will receive"); the farmer must still check the official GR.
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from dataclasses import dataclass

SQ_M_PER_HECTARE = 10_000

_REASONS: dict[str, dict[str, str]] = {
    "district": {
        "en": "You may be eligible because your farm is in {district} district.",
        "mr": "तुमचे शेत {district} जिल्ह्यात असल्याने तुम्ही पात्र असू शकता.",
        "hi": "आपका खेत {district} जिले में है, इसलिए आप पात्र हो सकते हैं।",
    },
    "crop": {
        "en": "You may be eligible because you grow {crop}.",
        "mr": "तुम्ही {crop} पिकवत असल्याने तुम्ही पात्र असू शकता.",
        "hi": "आप {crop} उगाते हैं, इसलिए आप पात्र हो सकते हैं।",
    },
    "land": {
        "en": "You may be eligible because your recorded land ({ha} ha) is {range}.",
        "mr": "तुमची नोंदवलेली जमीन ({ha} हे.) {range} असल्याने तुम्ही पात्र असू शकता.",
        "hi": "आपकी दर्ज ज़मीन ({ha} हे.) {range} है, इसलिए आप पात्र हो सकते हैं।",
    },
}
_RANGE: dict[str, dict[str, str]] = {
    "between": {
        "en": "within {lo}–{hi} ha",
        "mr": "{lo}–{hi} हे. दरम्यान",
        "hi": "{lo}–{hi} हे. के बीच",
    },
    "min": {"en": "at least {lo} ha", "mr": "किमान {lo} हे.", "hi": "कम से कम {lo} हे."},
    "max": {"en": "at most {hi} ha", "mr": "जास्तीत जास्त {hi} हे.", "hi": "अधिकतम {hi} हे."},
}


@dataclass(frozen=True, slots=True)
class Profile:
    district: str | None
    crops: frozenset[str]
    land_ha: float | None


@dataclass(frozen=True, slots=True)
class Target:
    district: str | None = None
    crop: str | None = None
    min_ha: float | None = None
    max_ha: float | None = None


def _key(value: str | None) -> str:
    return " ".join((value or "").split()).casefold()


def profile_from(district: str | None, plots: Iterable[tuple[str, float | None]]) -> Profile:
    """Profile from the farmer's district and their (crop, area_sq_m) plots; land is the sum
    of plot areas, unknown when no plot has an area."""
    rows = list(plots)
    areas = [a for _, a in rows if a is not None and a > 0]
    return Profile(
        district=district.strip() if district and district.strip() else None,
        crops=frozenset(_key(c) for c, _ in rows if c),
        land_ha=round(sum(areas) / SQ_M_PER_HECTARE, 2) if areas else None,
    )


def _land_ok(target: Target, land_ha: float | None) -> bool:
    if target.min_ha is None and target.max_ha is None:
        return True
    if land_ha is None:
        return False
    return (target.min_ha is None or land_ha >= target.min_ha) and (
        target.max_ha is None or land_ha <= target.max_ha
    )


def target_matches(target: Target, profile: Profile) -> bool:
    if target.district and _key(target.district) != _key(profile.district):
        return False
    if target.crop and _key(target.crop) not in profile.crops:
        return False
    return _land_ok(target, profile.land_ha)


def _num(value: float) -> str:
    return f"{value:g}"


def _range_text(target: Target, lang: str) -> str:
    if target.min_ha is not None and target.max_ha is not None:
        kind = "between"
    elif target.min_ha is not None:
        kind = "min"
    else:
        kind = "max"
    template = _RANGE[kind].get(lang, _RANGE[kind]["en"])
    return template.format(lo=_num(target.min_ha or 0), hi=_num(target.max_ha or 0))


def _reason(kind: str, lang: str, **values: str) -> str:
    return _REASONS[kind].get(lang, _REASONS[kind]["en"]).format(**values)


def eligibility_reasons(targets: Sequence[Target], profile: Profile, lang: str = "en") -> list[str]:
    """Reasons from every matching target, in order and without repeats. Empty when nothing
    matches or the item has no targets (it is then for everyone, no personal reason)."""
    reasons: list[str] = []
    for target in targets:
        if not target_matches(target, profile):
            continue
        if target.district:
            reasons.append(_reason("district", lang, district=target.district))
        if target.crop:
            reasons.append(_reason("crop", lang, crop=target.crop))
        if target.min_ha is not None or target.max_ha is not None:
            ha = _num(profile.land_ha or 0)
            reasons.append(_reason("land", lang, ha=ha, range=_range_text(target, lang)))
    return list(dict.fromkeys(reasons))


def passes_filter(targets: Sequence[Target], *, district: str | None, crop: str | None) -> bool:
    """List filter: an item passes when it is for everyone or one target allows both the
    requested district and crop (an unset target field allows any value)."""
    if not targets or (not district and not crop):
        return True
    return any(
        (not district or not t.district or _key(t.district) == _key(district))
        and (not crop or not t.crop or _key(t.crop) == _key(crop))
        for t in targets
    )
