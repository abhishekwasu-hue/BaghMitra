"""Seed the draft rating tags (spec v1.5 §3A, Q66) shipped with the code.

Usage: python -m bagmitra_api.market_link.seed. Adds only tags whose key is missing, always
as `draft`: once a tag exists the admin owns it (labels, status), so a re-run never
overwrites an admin edit.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from importlib import resources
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.market_link.models import RatingTag


class RatingTagSeed(BaseModel):
    model_config = ConfigDict(extra="forbid")

    key: str = Field(pattern=r"^[a-z][a-z0-9_]{0,63}$")
    question_key: str
    polarity: Literal["positive", "negative"]
    label_en: str = Field(min_length=1, max_length=120)
    label_mr: str = Field(min_length=1, max_length=120)
    label_hi: str = Field(min_length=1, max_length=120)
    sort_order: int


class RatingTagSeeds(BaseModel):
    note: str = Field(alias="_note")
    # Rated role -> its question keys (spec §3A).
    questions: dict[Literal["trader", "broker", "grower"], list[str]]
    tags: list[RatingTagSeed]

    @model_validator(mode="after")
    def _both_polarities_per_question(self) -> RatingTagSeeds:
        asked = {q for qs in self.questions.values() for q in qs}
        for q in asked:
            if {t.polarity for t in self.tags if t.question_key == q} != {"positive", "negative"}:
                raise ValueError(f"{q}: needs one positive and one negative tag")
        unknown = {t.question_key for t in self.tags} - asked
        if unknown:
            raise ValueError(f"tags for unknown questions: {sorted(unknown)}")
        return self


def rating_tag_seeds() -> RatingTagSeeds:
    text = (
        resources.files("bagmitra_api.market_link.seed_data")
        .joinpath("rating_tags.json")
        .read_text("utf-8")
    )
    return RatingTagSeeds.model_validate(json.loads(text))


async def seed_rating_tags(session: AsyncSession) -> int:
    """Adds the missing draft tags; returns how many it added."""
    have = set(await session.scalars(select(RatingTag.key)))
    added = 0
    for seed in rating_tag_seeds().tags:
        if seed.key in have:
            continue
        session.add(RatingTag(id=uuid.uuid4(), status="draft", **seed.model_dump()))
        added += 1
    await session.flush()
    return added


async def main() -> None:  # pragma: no cover - thin CLI wrapper
    async with get_sessionmaker()() as session:
        await seed_rating_tags(session)
        await session.commit()


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
