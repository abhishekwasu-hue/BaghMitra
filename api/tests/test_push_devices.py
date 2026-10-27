from __future__ import annotations

import uuid

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.db.models import PushDevice
from tests.conftest import make_token


async def devices(engine: AsyncEngine) -> list[PushDevice]:
    async with async_sessionmaker(engine)() as s:
        return list((await s.scalars(select(PushDevice))).all())


async def test_register_is_idempotent_and_moves_a_token_to_the_new_owner(
    client: httpx.AsyncClient, engine: AsyncEngine, user_id: uuid.UUID, auth_headers: dict[str, str]
) -> None:
    body = {"token": "tok-1", "platform": "android"}
    assert (await client.post("/v1/me/devices", json=body, headers=auth_headers)).status_code == 204
    assert (await client.post("/v1/me/devices", json=body, headers=auth_headers)).status_code == 204
    rows = await devices(engine)
    assert [(d.owner_id, d.token, d.platform) for d in rows] == [(user_id, "tok-1", "android")]

    other = uuid.uuid4()
    headers = {"Authorization": f"Bearer {make_token(other)}"}
    assert (await client.post("/v1/me/devices", json=body, headers=headers)).status_code == 204
    assert [d.owner_id for d in await devices(engine)] == [other], "one phone, its current account"


async def test_unregister_removes_only_own_token(
    client: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    await client.post(
        "/v1/me/devices", json={"token": "tok-2", "platform": "android"}, headers=auth_headers
    )
    stranger = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    r = await client.request("DELETE", "/v1/me/devices", json={"token": "tok-2"}, headers=stranger)
    assert r.status_code == 204
    assert len(await devices(engine)) == 1
    r = await client.request(
        "DELETE", "/v1/me/devices", json={"token": "tok-2"}, headers=auth_headers
    )
    assert r.status_code == 204
    assert await devices(engine) == []


async def test_bad_platform_empty_token_and_no_auth_are_refused(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    bad = await client.post(
        "/v1/me/devices", json={"token": "t", "platform": "pager"}, headers=auth_headers
    )
    assert bad.status_code == 422
    empty = await client.post(
        "/v1/me/devices", json={"token": "", "platform": "android"}, headers=auth_headers
    )
    assert empty.status_code == 422
    r = await client.post("/v1/me/devices", json={"token": "t", "platform": "android"})
    assert r.status_code == 401
