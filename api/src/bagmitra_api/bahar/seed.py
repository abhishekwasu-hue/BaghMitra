"""Idempotent seeding of the bahar stage templates shipped with the code (owner decision Q57).

Usage: python -m bagmitra_api.bahar.seed (also run by `python -m bagmitra_api.kb.seed`).
Upserts by (crop, bahar, version), so editing the JSON and re-running updates the rows in
place. The same file is bundled in the app as `assets/config/stage_templates.json`.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from importlib import resources
from typing import Any, Literal

from pydantic import BaseModel, HttpUrl, model_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.models import CropStageTemplate
from bagmitra_api.db.session import get_sessionmaker

LANGS = {"en", "mr", "hi"}


class TemplateSourceSeed(BaseModel):
    name: str
    title: str
    publisher: str
    url: HttpUrl
    read: str
    seen: str

    def line(self) -> str:
        """The `sources` value the API serves: "name | title | url | read YYYY-MM-DD"."""
        return f"{self.name} | {self.title} | {self.url} | read {self.read}"


class StageSeed(BaseModel):
    key: Literal["stress_start", "irrigation_restart", "flowering", "fruit_set", "harvest"]
    labels: dict[str, str]
    anchor: str
    offset_days_min: int
    offset_days_max: int
    source_ids: list[str]

    @model_validator(mode="after")
    def _check(self) -> StageSeed:
        if set(self.labels) != LANGS:
            raise ValueError(f"{self.key}: labels need en, mr and hi")
        if self.offset_days_min > self.offset_days_max:
            raise ValueError(f"{self.key}: min offset after max offset")
        if not self.source_ids:
            raise ValueError(f"{self.key}: every stage names a source")
        return self


class TemplateSeed(BaseModel):
    crop: Literal["santra", "mosambi"]
    bahar: Literal["ambia", "mrig", "hasta"]
    version: int
    status: Literal["draft", "published"]
    labels: dict[str, str]
    stages: list[StageSeed]

    @model_validator(mode="after")
    def _anchors(self) -> TemplateSeed:
        seen: set[str] = set()
        for stage in self.stages:
            if stage.anchor != "season_start" and stage.anchor not in seen:
                raise ValueError(f"{self.crop}/{self.bahar}: {stage.key} anchors on a later stage")
            seen.add(stage.key)
        return self


class StageTemplateSeeds(BaseModel):
    sources: dict[str, TemplateSourceSeed]
    templates: list[TemplateSeed]

    @model_validator(mode="after")
    def _sources_known(self) -> StageTemplateSeeds:
        for t in self.templates:
            for s in t.stages:
                missing = set(s.source_ids) - set(self.sources)
                if missing:
                    raise ValueError(f"{t.crop}/{t.bahar}/{s.key}: unknown sources {missing}")
        return self


def stage_template_seeds() -> StageTemplateSeeds:
    text = (
        resources.files("bagmitra_api.bahar.seed_data")
        .joinpath("stage_templates.json")
        .read_text("utf-8")
    )
    data: dict[str, Any] = json.loads(text)
    return StageTemplateSeeds.model_validate(data)


async def seed_stage_templates(session: AsyncSession) -> int:
    """Creates or refreshes every template in the file; returns how many rows it wrote."""
    data = stage_template_seeds()
    existing = {
        (t.crop, t.bahar, t.version): t for t in await session.scalars(select(CropStageTemplate))
    }
    for seed in data.templates:
        row = existing.get((seed.crop, seed.bahar, seed.version)) or CropStageTemplate(
            id=uuid.uuid4(), crop=seed.crop, bahar=seed.bahar, version=seed.version
        )
        used = sorted({k for s in seed.stages for k in s.source_ids})
        row.labels = seed.labels
        row.stages = [s.model_dump() for s in seed.stages]
        row.sources = {k: data.sources[k].line() for k in used}
        row.status = seed.status
        session.add(row)
    await session.flush()
    return len(data.templates)


async def main() -> None:  # pragma: no cover - thin CLI wrapper
    async with get_sessionmaker()() as session:
        await seed_stage_templates(session)
        await session.commit()


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
