from __future__ import annotations

from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta

import httpx
import pytest
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import MarketPrice
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market.agmarknet import MandiPrice, MarketUnavailableError
from bagmitra_api.market.service import get_market_provider
from bagmitra_api.weather.service import get_clock

NOW = datetime(2026, 10, 26, 6, 0, tzinfo=UTC)


def price(market: str, day: date, modal: int, *, variety: str | None = "Nagpuri") -> MandiPrice:
    return MandiPrice(
        market=market,
        district="Nagpur",
        commodity="Orange",
        variety=variety,
        grade=None,
        day=day,
        min_rs_per_quintal=modal - 800,
        max_rs_per_quintal=modal + 600,
        modal_rs_per_quintal=modal,
    )


class FakeMarket:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []
        self.fail = False

    async def prices(
        self, *, state: str, commodity: str, market: str | None = None
    ) -> list[MandiPrice]:
        assert market is None, "one call per commodity; markets are filtered here"
        self.calls.append((state, commodity))
        if self.fail:
            raise MarketUnavailableError("no API key configured (MARKET_API_KEY)")
        return [
            price("Kalamna", date(2026, 10, 25), 3600),
            price("Kalamna", date(2026, 10, 24), 3400),
            price("Warud", date(2026, 10, 25), 3300, variety=None),
            price("Pune", date(2026, 10, 25), 5000),  # not in the configured markets
        ]


@pytest.fixture
def market() -> FakeMarket:
    return FakeMarket()


@pytest.fixture
async def api(
    settings: Settings, engine: AsyncEngine, market: FakeMarket
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_market_provider] = lambda: market
    app.dependency_overrides[get_clock] = lambda: (lambda: NOW)
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c


async def test_prices_for_a_crop_are_pulled_once_stored_and_filtered(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    market: FakeMarket,
    auth_headers: dict[str, str],
) -> None:
    r = await api.get("/v1/market/prices?crop=santra", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["stale"] is False
    rows = body["prices"]
    assert [(p["market"], p["day"], p["modal_rs_per_quintal"]) for p in rows] == [
        ("Kalamna", "2026-10-25", 3600),
        ("Warud", "2026-10-25", 3300),
        ("Kalamna", "2026-10-24", 3400),
    ]
    assert rows[1]["variety"] is None
    assert rows[0]["source"] == "agmarknet"

    again = await api.get("/v1/market/prices?crop=santra", headers=auth_headers)
    assert again.json()["prices"] == rows
    assert market.calls == [("Maharashtra", "Orange")], "fresh prices come from storage"

    async with async_sessionmaker(engine)() as s:
        assert len((await s.scalars(select(MarketPrice))).all()) == 3


async def test_source_down_serves_stored_prices_as_stale_or_an_empty_list(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    market: FakeMarket,
    auth_headers: dict[str, str],
) -> None:
    market.fail = True
    empty = await api.get("/v1/market/prices?crop=santra", headers=auth_headers)
    assert empty.status_code == 200
    assert empty.json() == {
        "prices": [],
        "stale": True,
        "reason": "no API key configured (MARKET_API_KEY)",
    }

    market.fail = False
    await api.get("/v1/market/prices?crop=santra", headers=auth_headers)
    async with async_sessionmaker(engine)() as s:
        await s.execute(update(MarketPrice).values(fetched_at=NOW - timedelta(days=2)))
        await s.commit()
    market.fail = True
    stale = (await api.get("/v1/market/prices?crop=santra", headers=auth_headers)).json()
    assert stale["stale"] is True
    assert len(stale["prices"]) == 3


async def test_unknown_crop_and_no_token_are_refused(
    api: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    r = await api.get("/v1/market/prices?crop=banana", headers=auth_headers)
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "crop_not_priced"
    assert (await api.get("/v1/market/prices?crop=santra")).status_code == 401
