"""Idempotent seeding of reference data shipped with the code (addendum v1.3 §2, §3.8).

Usage: python -m bagmitra_api.kb.seed
Upserts by natural key, so re-running after editing the JSON updates rows in place. The
PPQS/CIB&RC importers (K1b) supersede the restriction seed once they run.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from datetime import UTC, datetime
from importlib import resources
from typing import Any, Literal

from pydantic import BaseModel, HttpUrl
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.kb.models import KbCard, KbConflict, KbRestriction, KbSource, KbTopic


class SourceSeed(BaseModel):
    key: str
    title: str
    publisher: str
    url: HttpUrl
    tier: Literal["tier1", "tier2", "tier1_intl", "tier3", "tier4"]
    licence: str
    allowed_use: Literal["copy", "summarise_cite", "cite_only", "internal_only"]
    verification: Literal["V", "S", "UV"]
    notes: str | None = None


class RestrictionSeed(BaseModel):
    active_ingredient: str
    kind: Literal["banned", "withdrawn", "refused", "restricted"]
    crops: list[str]
    crop_groups: list[str]
    notification: str
    effective_from: datetime


class TopicSeed(BaseModel):
    key: str
    kind: str
    labels: dict[str, str]


class CardSourceSeed(BaseModel):
    source: str
    locator: str


class CardSeed(BaseModel):
    topic: str
    crop: str
    content: dict[str, dict[str, str]]
    chemical_options: list[dict[str, str]]
    sources: list[CardSourceSeed]


class ConflictValueSeed(BaseModel):
    source: str
    value: str


class ConflictSeed(BaseModel):
    topic: str | None
    description: str
    values: list[ConflictValueSeed]


class KnowledgeSeeds(BaseModel):
    topics: list[TopicSeed]
    cards: list[CardSeed]
    conflicts: list[ConflictSeed]


def _load(name: str) -> dict[str, Any]:
    text = resources.files("bagmitra_api.kb.seed_data").joinpath(name).read_text("utf-8")
    data: dict[str, Any] = json.loads(text)
    return data


def source_seeds() -> list[SourceSeed]:
    return [SourceSeed.model_validate(s) for s in _load("sources.json")["sources"]]


def restriction_seeds() -> tuple[str, list[RestrictionSeed]]:
    data = _load("restrictions.json")
    return data["source_key"], [RestrictionSeed.model_validate(r) for r in data["restrictions"]]


def knowledge_seeds() -> KnowledgeSeeds:
    return KnowledgeSeeds.model_validate(_load("knowledge.json"))


async def seed_knowledge(session: AsyncSession) -> None:
    """Draft cards from addendum v1.3 §3. A card a reviewer has touched (anything but `draft`)
    is never overwritten; a still-draft card is refreshed from the file."""
    data = knowledge_seeds()
    sources = {s.key: s.id for s in await session.scalars(select(KbSource))}
    topics = {t.key: t for t in await session.scalars(select(KbTopic))}
    for seed in data.topics:
        topic = topics.get(seed.key) or KbTopic(id=uuid.uuid4(), key=seed.key)
        topic.kind, topic.labels = seed.kind, seed.labels
        session.add(topic)
        topics[seed.key] = topic
    await session.flush()
    existing = {(c.topic_id, c.crop, c.version): c for c in await session.scalars(select(KbCard))}
    for card in data.cards:
        topic = topics[card.topic]
        row = existing.get((topic.id, card.crop, 1))
        if row is not None and row.status != "draft":
            continue
        row = row or KbCard(id=uuid.uuid4(), topic_id=topic.id, crop=card.crop, version=1)
        row.content = card.content
        row.reviewed_languages = []
        row.chemical_options = card.chemical_options
        row.sources = [
            {"source_id": str(sources[ref.source]), "locator": ref.locator} for ref in card.sources
        ]
        row.status = "draft"
        session.add(row)
    known = {c.description for c in await session.scalars(select(KbConflict))}
    for conflict in data.conflicts:
        if conflict.description in known:
            continue
        session.add(
            KbConflict(
                id=uuid.uuid4(),
                topic_id=topics[conflict.topic].id if conflict.topic else None,
                description=conflict.description,
                values=[v.model_dump() for v in conflict.values],
                status="open",
            )
        )
    await session.flush()


async def seed_sources(session: AsyncSession) -> int:
    existing = {s.key: s for s in await session.scalars(select(KbSource))}
    for seed in source_seeds():
        row = existing.get(seed.key) or KbSource(id=uuid.uuid4(), key=seed.key)
        for field, value in seed.model_dump(exclude={"key"}).items():
            setattr(row, field, str(value) if field == "url" else value)
        session.add(row)
    await session.flush()
    return len(existing)


async def seed_restrictions(session: AsyncSession) -> None:
    source_key, seeds = restriction_seeds()
    source = await session.scalar(select(KbSource).where(KbSource.key == source_key))
    if source is None:
        raise LookupError(f"seed sources first: {source_key} missing")
    existing = {
        (r.active_ingredient, r.kind): r
        for r in await session.scalars(
            select(KbRestriction).where(KbRestriction.source_id == source.id)
        )
    }
    for seed in seeds:
        row = existing.get((seed.active_ingredient, seed.kind)) or KbRestriction(id=uuid.uuid4())
        for field, value in seed.model_dump().items():
            setattr(row, field, value)
        if row.effective_from.tzinfo is None:
            row.effective_from = row.effective_from.replace(tzinfo=UTC)
        row.source_id = source.id
        session.add(row)
    await session.flush()


async def main() -> None:  # pragma: no cover - thin CLI wrapper
    async with get_sessionmaker()() as session:
        await seed_sources(session)
        await seed_restrictions(session)
        await seed_knowledge(session)
        await session.commit()


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
