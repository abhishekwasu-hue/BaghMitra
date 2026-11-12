"""Emoji reactions after reading (owner 2026-11-12, Q146): targets, counts and the admin lists.

A target key is a feed item id (UUID) or `qa:<id>` for a Q&A answer bundled in the app (the
server has no list of those ids, so any id of the allowed shape is taken). One reaction per
reader and target. Counts are sums across readers; no reader identity ever leaves here.
"""

from __future__ import annotations

import re
import uuid
from collections import Counter
from collections.abc import Iterable
from dataclasses import dataclass

from sqlalchemy import ColumnElement, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.feed.models import REACTIONS, FeedReaction

QA_PREFIX = "qa:"
QA_ID = r"[A-Za-z0-9_-]{1,64}"
UUID_KEY = r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
TARGET_PATTERN = f"^({UUID_KEY}|{QA_PREFIX}{QA_ID})$"
_TARGET = re.compile(TARGET_PATTERN)
# Reactions that say the text helped, and the one that says it did not (admin lists).
HELPFUL = ("useful", "thanks", "liked")
UNCLEAR = "unclear"


@dataclass(frozen=True, slots=True)
class Target:
    """A parsed target key: exactly one of the two is set."""

    item_id: uuid.UUID | None = None
    qa_id: str | None = None

    @property
    def key(self) -> str:
        return str(self.item_id) if self.item_id is not None else f"{QA_PREFIX}{self.qa_id}"


def parse_target(key: str) -> Target | None:
    """The target for a key, or None when the key has neither allowed shape."""
    if not _TARGET.match(key):
        return None
    if key.startswith(QA_PREFIX):
        return Target(qa_id=key.removeprefix(QA_PREFIX))
    return Target(item_id=uuid.UUID(key))


def _where(target: Target) -> ColumnElement[bool]:
    if target.item_id is not None:
        return FeedReaction.item_id == target.item_id
    return FeedReaction.qa_id == target.qa_id


async def own(session: AsyncSession, owner: uuid.UUID, target: Target) -> FeedReaction | None:
    row: FeedReaction | None = await session.scalar(
        select(FeedReaction).where(FeedReaction.owner_id == owner, _where(target))
    )
    return row


async def counts(session: AsyncSession, targets: Iterable[Target]) -> dict[str, Counter[str]]:
    """Reaction counts per target key (targets without reactions are left out)."""
    wanted = list(targets)
    items = [t.item_id for t in wanted if t.item_id is not None]
    qas = [t.qa_id for t in wanted if t.qa_id is not None]
    out: dict[str, Counter[str]] = {}
    if items:
        rows = await session.execute(
            select(FeedReaction.item_id, FeedReaction.reaction, func.count())
            .where(FeedReaction.item_id.in_(items))
            .group_by(FeedReaction.item_id, FeedReaction.reaction)
        )
        for item_id, reaction, n in rows.tuples():
            out.setdefault(str(item_id), Counter())[reaction] += int(n)
    if qas:
        rows = await session.execute(
            select(FeedReaction.qa_id, FeedReaction.reaction, func.count())
            .where(FeedReaction.qa_id.in_(qas))
            .group_by(FeedReaction.qa_id, FeedReaction.reaction)
        )
        for qa_id, reaction, n in rows.tuples():
            out.setdefault(f"{QA_PREFIX}{qa_id}", Counter())[reaction] += int(n)
    return out


async def mine(
    session: AsyncSession, owner: uuid.UUID, targets: Iterable[Target]
) -> dict[str, str]:
    """The caller's own reaction per target key."""
    wanted = list(targets)
    items = [t.item_id for t in wanted if t.item_id is not None]
    qas = [t.qa_id for t in wanted if t.qa_id is not None]
    out: dict[str, str] = {}
    for column, values in ((FeedReaction.item_id, items), (FeedReaction.qa_id, qas)):
        if not values:
            continue
        for row in await session.scalars(
            select(FeedReaction).where(FeedReaction.owner_id == owner, column.in_(values))
        ):
            out[Target(row.item_id, row.qa_id).key] = row.reaction
    return out


async def all_counts(session: AsyncSession) -> dict[str, Counter[str]]:
    """Counts of every target that has at least one reaction (admin view)."""
    out: dict[str, Counter[str]] = {}
    rows = await session.execute(
        select(
            FeedReaction.item_id, FeedReaction.qa_id, FeedReaction.reaction, func.count()
        ).group_by(FeedReaction.item_id, FeedReaction.qa_id, FeedReaction.reaction)
    )
    for item_id, qa_id, reaction, n in rows.tuples():
        out.setdefault(Target(item_id, qa_id).key, Counter())[reaction] += int(n)
    return out


def helpful(c: Counter[str]) -> int:
    return sum(c[r] for r in HELPFUL)


def most_helpful_order(c: Counter[str]) -> tuple[int, int, int]:
    """Sort key, smallest first: most helpful reactions, then fewest "unclear", then most."""
    return (-helpful(c), c[UNCLEAR], -sum(c.values()))


def least_helpful_order(c: Counter[str]) -> tuple[int, int, int]:
    """Sort key, smallest first: most "unclear", then fewest helpful, then most reactions."""
    return (-c[UNCLEAR], helpful(c), -sum(c.values()))


def ordered(c: Counter[str] | None) -> list[tuple[str, int]]:
    """Every reaction with its count, in the app's order (zeros included)."""
    return [(r, (c or Counter())[r]) for r in REACTIONS]
