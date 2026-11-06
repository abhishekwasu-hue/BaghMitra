from __future__ import annotations

import json
from pathlib import Path

import httpx
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.bahar.seed import seed_stage_templates, stage_template_seeds
from bagmitra_api.db.models import CropStageTemplate

ROOT = Path(__file__).resolve().parents[2]
SEED = ROOT / "api/src/bagmitra_api/bahar/seed_data/stage_templates.json"
APP_COPY = ROOT / "app/assets/config/stage_templates.json"


def test_six_crop_bahar_templates_each_stage_sourced() -> None:
    data = stage_template_seeds()
    pairs = {(t.crop, t.bahar) for t in data.templates}
    assert pairs == {(c, b) for c in ("santra", "mosambi") for b in ("ambia", "mrig", "hasta")}
    for t in data.templates:
        assert t.stages, (t.crop, t.bahar)
        for s in t.stages:
            assert set(s.source_ids) <= set(data.sources)
    assert all(s.read for s in data.sources.values())


def test_no_chemical_or_dose_content() -> None:
    text = SEED.read_text("utf-8").lower()
    for word in ("spray", "ppm", "chlormequat", "cycocel", "fungicide", "insecticide", "kg/"):
        assert word not in text, word


def test_app_bundles_the_same_file() -> None:
    if not APP_COPY.exists():  # the API image is built without the app folder
        return
    assert json.loads(APP_COPY.read_text("utf-8")) == json.loads(SEED.read_text("utf-8"))


async def test_seed_is_idempotent_and_served(
    engine: AsyncEngine, client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    async with async_sessionmaker(engine)() as session:
        assert await seed_stage_templates(session) == 6
        await seed_stage_templates(session)
        await session.commit()
        count = await session.scalar(select(func.count()).select_from(CropStageTemplate))
    assert count == 6
    resp = await client.get(
        "/v1/reference/stage-templates", params={"crop": "santra"}, headers=auth_headers
    )
    assert resp.status_code == 200
    templates = {t["bahar"]: t for t in resp.json()["templates"]}
    assert set(templates) == {"ambia", "mrig", "hasta"}
    ambia = templates["ambia"]
    keys = [s["key"] for s in ambia["stages"]]
    assert keys == ["stress_start", "irrigation_restart", "flowering", "harvest"]
    restart = ambia["stages"][1]
    assert (restart["anchor"], restart["offset_days_min"], restart["offset_days_max"]) == (
        "stress_start",
        35,
        75,
    )
    for stage in ambia["stages"]:
        for sid in stage["source_ids"]:
            name, title, url, read = ambia["sources"][sid].split(" | ")
            assert name
            assert title
            assert url.startswith("https://")
            assert read.startswith("read 20")
    # Mandarin hasta: only the flowering month is published.
    assert [s["key"] for s in templates["hasta"]["stages"]] == ["flowering"]
