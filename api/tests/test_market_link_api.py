"""Market linkage legal gate (decision j): flag off -> every /v1/market-link/* path is 404."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import RatingTag
from bagmitra_api.market_link.seed import seed_rating_tags
from tests.conftest import make_token

PATH = "/v1/market-link/rating-tags"


def test_flag_is_off_by_default() -> None:
    assert Settings(environment="production").market_link_enabled is False


async def test_flag_off_answers_404_before_auth(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    for headers in (auth_headers, {}):
        response = await client.get(PATH, headers=headers)
        assert response.status_code == 404, response.text
        assert response.json()["error"]["code"] == "not_found"
    assert (await client.get("/v1/market-link/anything", headers=auth_headers)).status_code == 404


@pytest.fixture
async def enabled_client(
    settings: Settings, engine: AsyncEngine
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings.model_copy(update={"market_link_enabled": True}))
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    async with maker() as session:
        await seed_rating_tags(session)
        tag = await session.get(RatingTag, await _tag_id(session, "trader_on_date_no"))
        assert tag is not None
        tag.status = "active"
        await session.commit()
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


async def _tag_id(session: AsyncSession, key: str) -> uuid.UUID:
    found = await session.scalar(select(RatingTag.id).where(RatingTag.key == key))
    assert found is not None
    return found


async def test_flag_on_serves_active_tags_only(enabled_client: httpx.AsyncClient) -> None:
    headers = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    response = await enabled_client.get(PATH, headers=headers)
    assert response.status_code == 200, response.text
    tags = response.json()["tags"]
    assert [t["key"] for t in tags] == ["trader_on_date_no"]
    assert tags[0]["polarity"] == "negative"
    assert set(tags[0]) == {
        "id",
        "key",
        "question_key",
        "polarity",
        "label_mr",
        "label_hi",
        "label_en",
        "sort_order",
    }
    assert (await enabled_client.get(PATH)).status_code == 401
