from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

import httpx
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.db.models import CropStageTemplate

STAGES: list[dict[str, Any]] = [
    {
        "key": "stress_start",
        "labels": {"en": "Stress", "mr": "ताण"},
        "anchor": "season_start",
        "offset_days_min": 0,
        "offset_days_max": 0,
        "source_ids": ["S2b"],
    },
    {
        "key": "flowering",
        "labels": {"en": "Flowering", "mr": "फुलोरा"},
        "anchor": "stress_start",
        "offset_days_min": 30,
        "offset_days_max": 45,
        "source_ids": ["S8"],
    },
]


async def add_template(engine: AsyncEngine, *, status: str, crop: str = "santra") -> uuid.UUID:
    template_id = uuid.uuid4()
    async with async_sessionmaker(engine)() as session:
        session.add(
            CropStageTemplate(
                id=template_id,
                crop=crop,
                bahar="mrig",
                version=1,
                labels={"en": "Mrig bahar", "mr": "मृग बहार"},
                stages=STAGES,
                sources={"S8": "Jhade et al. 2021, J. Agric. Ecol. 12(2): 80-87"},
                status=status,
                updated_at=datetime(2026, 10, 12, tzinfo=UTC),
            )
        )
        await session.commit()
    return template_id


async def test_requires_auth(client: httpx.AsyncClient) -> None:
    resp = await client.get("/v1/reference/stage-templates")
    assert resp.status_code == 401


async def test_empty_until_templates_are_published(
    client: httpx.AsyncClient, auth_headers: dict[str, str], engine: AsyncEngine
) -> None:
    await add_template(engine, status="draft")
    resp = await client.get("/v1/reference/stage-templates", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == {"templates": []}


async def test_returns_published_templates_filtered_by_crop(
    client: httpx.AsyncClient, auth_headers: dict[str, str], engine: AsyncEngine
) -> None:
    santra = await add_template(engine, status="published")
    await add_template(engine, status="published", crop="mosambi")
    resp = await client.get(
        "/v1/reference/stage-templates", params={"crop": "santra"}, headers=auth_headers
    )
    [template] = resp.json()["templates"]
    assert template["id"] == str(santra)
    assert template["bahar"] == "mrig"
    assert template["labels"]["mr"] == "मृग बहार"
    assert [s["key"] for s in template["stages"]] == ["stress_start", "flowering"]
    assert template["stages"][1]["offset_days_max"] == 45
    assert template["sources"]["S8"].startswith("Jhade")
