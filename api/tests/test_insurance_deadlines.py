"""Crop insurance enrolment deadlines come only from published official feed items (the
reviewed GR / notice dates in feed_deadlines). Nothing matches => nothing is shown: the API
never makes up a date."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import (
    FeedDeadline,
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedSource,
    Plot,
)
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.seed import seed_feed_sources
from bagmitra_api.insurance.deadlines import is_insurance_text, season_of
from bagmitra_api.main import create_app
from bagmitra_api.weather.service import get_clock

NOW = datetime(2026, 10, 28, 6, 0, tzinfo=UTC)
TODAY = NOW.date()
PATH = "/v1/insurance/deadlines"


@pytest.fixture
async def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    m = async_sessionmaker(engine, expire_on_commit=False)
    async with m() as s:
        await seed_feed_sources(s)
        await s.commit()
    return m


@pytest.fixture
async def api(
    settings: Settings, maker: async_sessionmaker[AsyncSession]
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_clock] = lambda: (lambda: NOW)
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c


async def add_item(
    maker: async_sessionmaker[AsyncSession],
    *,
    title: str = "Weather Based Crop Insurance (RWBCIS) Ambia bahar 2027",
    title_mr: str | None = None,
    source: str = "mh_gr_portal",
    due_in: int | None = 20,
    kind: str = "apply_by",
    status: str = "published",
    trust: str = "official",
    crop: str | None = None,
) -> uuid.UUID:
    async with maker() as s:
        source_id = await s.scalar(select(FeedSource.id).where(FeedSource.key == source))
        assert source_id is not None
        item = FeedItem(
            id=uuid.uuid4(),
            type="scheme",
            source_id=source_id,
            published_at=NOW - timedelta(days=3),
            url="https://example.org/notice.pdf",
            status=status,
            trust_level=trust,
            deadline=TODAY + timedelta(days=due_in) if due_in is not None else None,
            check_issues=[],
        )
        s.add(item)
        s.add(FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="en", title=title))
        if title_mr:
            s.add(FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="mr", title=title_mr))
        if crop:
            s.add(FeedItemTarget(id=uuid.uuid4(), item_id=item.id, crop=crop))
        if due_in is not None:
            s.add(
                FeedDeadline(
                    id=uuid.uuid4(),
                    item_id=item.id,
                    kind=kind,
                    due_date=TODAY + timedelta(days=due_in),
                )
            )
        await s.commit()
        return item.id


async def add_plot(maker: async_sessionmaker[AsyncSession], owner: uuid.UUID, crop: str) -> None:
    async with maker() as s:
        s.add(
            Plot(
                id=uuid.uuid4(),
                owner_id=owner,
                name="बाग",
                crop=crop,
                area_sq_m=4000,
                client_updated_at=NOW,
                last_seq=1,
            )
        )
        await s.commit()


def test_insurance_text_and_season_are_read_from_wording_only() -> None:
    assert is_insurance_text("पुनर्रचित हवामान आधारित फळपीक विमा योजना")
    assert is_insurance_text("PMFBY enrolment")
    assert is_insurance_text("प्रधानमंत्री फसल बीमा योजना")
    assert not is_insurance_text("आरोग्य विमा योजना")
    assert not is_insurance_text("Fruit planting subsidy")
    assert season_of("फळपीक विमा आंबिया बहार") == "ambia"
    assert season_of("RWBCIS Mrig bahar") == "mrig"
    assert season_of("RWBCIS ambia and mrig") is None
    assert season_of("RWBCIS 2027") is None


async def test_only_published_official_future_insurance_deadlines(
    api: httpx.AsyncClient, maker: async_sessionmaker[AsyncSession], auth_headers: dict[str, str]
) -> None:
    wanted = await add_item(maker, title_mr="हवामान आधारित फळपीक विमा आंबिया बहार")
    from_pmfby = await add_item(maker, title="Notice on enrolment", source="pmfby", due_in=5)
    await add_item(maker, title="Fruit planting subsidy")  # not insurance
    await add_item(maker, due_in=-1)  # passed
    await add_item(maker, due_in=None)  # no date published
    await add_item(maker, kind="payment")  # not an enrolment date
    await add_item(maker, status="in_review")  # not reviewed yet
    await add_item(maker, trust="news", source="pib_agriculture_news")  # press, not official
    resp = await api.get(PATH, params={"lang": "mr"}, headers=auth_headers)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert [i["item_id"] for i in body["items"]] == [str(from_pmfby), str(wanted)]
    first, second = body["items"]
    assert first["due_date"] == (TODAY + timedelta(days=5)).isoformat()
    assert first["season"] is None
    assert second["title"] == "हवामान आधारित फळपीक विमा आंबिया बहार"
    assert second["season"] == "ambia"
    assert second["url"] == "https://example.org/notice.pdf"
    assert body["footer"]


async def test_crop_targets_must_fit_the_growers_plots(
    api: httpx.AsyncClient,
    maker: async_sessionmaker[AsyncSession],
    auth_headers: dict[str, str],
    user_id: uuid.UUID,
) -> None:
    await add_plot(maker, user_id, "santra")
    mine = await add_item(maker, crop="santra")
    await add_item(maker, crop="cotton")
    resp = await api.get(PATH, headers=auth_headers)
    assert [i["item_id"] for i in resp.json()["items"]] == [str(mine)]


async def test_nothing_published_means_nothing_shown(
    api: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    resp = await api.get(PATH, headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["items"] == []
    assert (await api.get(PATH)).status_code == 401
