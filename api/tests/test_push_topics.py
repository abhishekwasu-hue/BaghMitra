"""Q147: the grower's update-push switches (Settings -> सूचना), stored per user on the server."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from tests.conftest import make_token

PATH = "/v1/me/push-topics"
ALL_ON = {"articles": True, "market": True, "weather_change": True}


async def test_defaults_then_saved_per_user(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    assert (await client.get(PATH)).status_code == 401
    assert (await client.get(PATH, headers=auth_headers)).json() == ALL_ON
    body = {"articles": False, "market": True, "weather_change": False}
    res = await client.put(PATH, json=body, headers=auth_headers)
    assert res.status_code == 200, res.text
    assert res.json() == body
    again = await client.put(PATH, json=body, headers=auth_headers)
    assert again.json() == body, "a repeated offline retry is harmless"
    assert (await client.get(PATH, headers=auth_headers)).json() == body
    other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    assert (await client.get(PATH, headers=other)).json() == ALL_ON, "owner-scoped"
    for bad in ({"articles": "maybe"}, {}):
        res = await client.put(PATH, json=(body | bad) if bad else {}, headers=auth_headers)
        assert res.status_code == 422, bad


@pytest.fixture
async def admin_defaults_client(
    settings: Settings, engine: AsyncEngine
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings.model_copy(update={"push_topic_market_default": False}))
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c


async def test_admin_default_applies_until_the_grower_chooses(
    admin_defaults_client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    res = await admin_defaults_client.get(PATH, headers=auth_headers)
    assert res.json() == ALL_ON | {"market": False}
