"""Phones cache the ban / restriction list so spray warnings work offline (M2)."""

from __future__ import annotations

import uuid

import httpx
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.models import KbSynonym
from bagmitra_api.kb.seed import seed_restrictions, seed_sources


async def test_requires_auth(client: httpx.AsyncClient) -> None:
    assert (await client.get("/v1/reference/restrictions")).status_code == 401


async def test_lists_restrictions_and_trade_names(
    client: httpx.AsyncClient, auth_headers: dict[str, str], engine: AsyncEngine
) -> None:
    assert (await client.get("/v1/reference/restrictions", headers=auth_headers)).json() == {
        "restrictions": [],
        "synonyms": [],
    }
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await seed_restrictions(session)

        session.add(KbSynonym(id=uuid.uuid4(), name="Nuvan", active_ingredient="dichlorvos"))
        await session.commit()
    body = (await client.get("/v1/reference/restrictions", headers=auth_headers)).json()
    by_ai = {r["active_ingredient"]: r for r in body["restrictions"]}
    assert by_ai["dicofol"]["kind"] == "banned"
    assert by_ai["chlorpyrifos"]["kind"] == "restricted"
    assert "citrus" in by_ai["chlorpyrifos"]["crops"]
    assert by_ai["dicofol"]["notification"]
    assert body["synonyms"] == [{"name": "Nuvan", "active_ingredient": "dichlorvos"}]
