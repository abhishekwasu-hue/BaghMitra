"""Crop insurance enrolment deadlines, read only from the reviewed govt feed.

An item counts as a crop insurance notice when it comes from the PMFBY source or its
reviewed title / summary uses one of the scheme names below. Its enrolment date is the
reviewed `apply_by` date in `feed_deadlines`; nothing is guessed. When no published item
matches, the app shows no deadline (OPEN_QUESTIONS Q39). The phrases are wording only, no
numbers; they may need more spellings as real notices arrive.
"""

from __future__ import annotations

import uuid
from collections import defaultdict
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date
from typing import Literal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.feed.models import (
    FeedDeadline,
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedSource,
)

PMFBY_SOURCE = "pmfby"
# Scheme names as they appear in Maharashtra GRs, PMFBY notices and the press
# (sources: pmfby.gov.in; Maharashtra agriculture GRs on fruit crop insurance, RWBCIS).
INSURANCE_PHRASES = (
    "pmfby",
    "rwbcis",
    "crop insurance",
    "fasal bima",
    "पीक विमा",
    "फळपीक विमा",
    "फळ पीक विमा",
    "पिक विमा",
    "फसल बीमा",
    "फल फसल बीमा",
    "weather based crop insurance",
    "हवामान आधारित",
)
SEASON_PHRASES: dict[str, tuple[str, ...]] = {
    "ambia": ("ambia", "ambiya", "आंबिया", "अंबिया", "अम्बिया"),
    "mrig": ("mrig", "mriga", "मृग"),
}
Season = Literal["ambia", "mrig"]


@dataclass(frozen=True, slots=True)
class InsuranceDeadline:
    item_id: uuid.UUID
    title: str
    due_date: date
    url: str
    season: Season | None


def _fold(text: str) -> str:
    return " ".join(text.split()).casefold()


def is_insurance_text(text: str) -> bool:
    folded = _fold(text)
    return any(p in folded for p in INSURANCE_PHRASES)


def season_of(text: str) -> Season | None:
    """The bahar a notice names, or None when it names both or neither."""
    folded = _fold(text)
    found = [s for s, words in SEASON_PHRASES.items() if any(w in folded for w in words)]
    if len(found) == 1:
        return "ambia" if found[0] == "ambia" else "mrig"
    return None


def _fits(targets: list[FeedItemTarget], district: str | None, crops: set[str]) -> bool:
    """Shown unless the item is known not to apply: every target names another district the
    grower set, or a crop the grower does not grow."""
    if not targets:
        return True
    for t in targets:
        district_ok = not t.district or not district or _fold(t.district) == _fold(district)
        crop_ok = not t.crop or _fold(t.crop) in crops
        if district_ok and crop_ok:
            return True
    return False


def _pick(texts: dict[str, FeedItemI18n], lang: str) -> FeedItemI18n | None:
    for key in (lang, "en", "mr", "hi"):
        if key in texts:
            return texts[key]
    return None


async def insurance_deadlines(
    session: AsyncSession,
    *,
    today: date,
    lang: str,
    district: str | None,
    crops: Iterable[str],
) -> list[InsuranceDeadline]:
    """Published official insurance notices with an enrolment date today or later, soonest
    first."""
    rows = (
        await session.execute(
            select(FeedItem, FeedDeadline.due_date, FeedSource.key)
            .join(FeedDeadline, FeedDeadline.item_id == FeedItem.id)
            .join(FeedSource, FeedSource.id == FeedItem.source_id)
            .where(
                FeedItem.status == "published",
                FeedItem.trust_level == "official",
                FeedDeadline.kind == "apply_by",
                FeedDeadline.due_date >= today,
            )
            .order_by(FeedDeadline.due_date, FeedItem.published_at.desc())
        )
    ).all()
    ids = [item.id for item, _, _ in rows]
    texts: dict[uuid.UUID, dict[str, FeedItemI18n]] = defaultdict(dict)
    for t in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id.in_(ids))):
        texts[t.item_id][t.lang] = t
    targets: dict[uuid.UUID, list[FeedItemTarget]] = defaultdict(list)
    for g in await session.scalars(select(FeedItemTarget).where(FeedItemTarget.item_id.in_(ids))):
        targets[g.item_id].append(g)
    grown = {_fold(c) for c in crops if c}

    out: list[InsuranceDeadline] = []
    for item, due, source_key in rows:
        shown = _pick(texts[item.id], lang)
        if shown is None:
            continue
        wording = " ".join(f"{t.title} {t.summary or ''}" for t in texts[item.id].values())
        if source_key != PMFBY_SOURCE and not is_insurance_text(wording):
            continue
        if not _fits(targets[item.id], district, grown):
            continue
        out.append(InsuranceDeadline(item.id, shown.title, due, item.url, season_of(wording)))
    return out
