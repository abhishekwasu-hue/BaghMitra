"""Knowledge-base publishing and licence rules (addendum v1.3 §5-§6), as pure functions.

Kept free of the database so every rule is unit-tested in isolation; the admin API and
importers call these before changing card status.
"""

from __future__ import annotations

import calendar
import re
import uuid
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import datetime
from typing import Literal

AllowedUse = Literal["copy", "summarise_cite", "cite_only", "internal_only"]
ReviewDecision = Literal["approve", "edit", "reject"]


@dataclass(frozen=True, slots=True)
class SourceFacts:
    id: uuid.UUID
    allowed_use: AllowedUse


@dataclass(frozen=True, slots=True)
class CardFacts:
    version: int
    has_english: bool
    source_ids: Sequence[uuid.UUID]
    has_chemical_options: bool


@dataclass(frozen=True, slots=True)
class ReviewFacts:
    card_version: int
    decision: ReviewDecision
    reviewer_id: uuid.UUID
    reviewed_at: datetime
    expires_at: datetime


def publish_blockers(
    card: CardFacts,
    reviews: Sequence[ReviewFacts],
    sources: Mapping[uuid.UUID, SourceFacts],
    now: datetime,
) -> list[str]:
    """Reasons a card cannot be published; empty means it may be published."""
    blockers: list[str] = []
    if not card.has_english:
        blockers.append("no_english")
    if not card.source_ids:
        blockers.append("no_sources")
    for source_id in card.source_ids:
        source = sources.get(source_id)
        if source is None:
            blockers.append("unknown_source")
        elif source.allowed_use == "internal_only":
            blockers.append("internal_only_source")
    valid = [
        r
        for r in reviews
        if r.card_version == card.version and r.decision == "approve" and r.expires_at > now
    ]
    if not valid:
        blockers.append("no_valid_review")
    return blockers


def _add_months(value: datetime, months: int) -> datetime:
    month_index = value.month - 1 + months
    year, month = value.year + month_index // 12, month_index % 12 + 1
    day = min(value.day, calendar.monthrange(year, month)[1])
    return value.replace(year=year, month=month, day=day)


def review_expiry(
    reviewed_at: datetime, *, chemical: bool, months_default: int, months_chemical: int
) -> datetime:
    """Review validity: shorter for cards that carry chemical options (config-driven)."""
    return _add_months(reviewed_at, months_chemical if chemical else months_default)


_WORD = re.compile(r"[\w]+", re.UNICODE)


def _words(text: str) -> list[str]:
    return [w.lower() for w in _WORD.findall(text)]


def verbatim_violations(
    text: str, source_text: str, allowed_use: AllowedUse, *, max_words: int
) -> list[str]:
    """Spans of more than `max_words` consecutive words copied from a no-copy source.

    `copy` sources may be quoted; `internal_only` sources may never reach growers at all.
    """
    if allowed_use == "copy":
        return []
    if allowed_use == "internal_only":
        return ["internal_only"]
    size = max_words + 1
    src = _words(source_text)
    grams = {tuple(src[i : i + size]) for i in range(len(src) - size + 1)}
    words = _words(text)
    spans: list[str] = []
    i = 0
    while i <= len(words) - size:
        if tuple(words[i : i + size]) not in grams:
            i += 1
            continue
        end = i + size
        while end < len(words) and tuple(words[end - size + 1 : end + 1]) in grams:
            end += 1
        spans.append(" ".join(words[i:end]))
        i = end
    return spans
