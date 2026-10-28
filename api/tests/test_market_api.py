from __future__ import annotations

import uuid
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
from tests.conftest import make_token

NOW = datetime(2026, 10, 26, 6, 0, tzinfo=UTC)
NO_KEY = "no API key configured (MARKET_API_KEY)"


def price(
    market: str,
    state: str,
    day: date,
    modal: int,
    *,
    variety: str | None = "Nagpuri",
) -> MandiPrice:
    return MandiPrice(
        market=market,
        state=state,
        district=market,
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
        self.calls: list[tuple[str, str | None]] = []
        self.fail = False

    async def prices(
        self, *, commodity: str, state: str | None = None, market: str | None = None
    ) -> list[MandiPrice]:
        assert market is None, "one India-wide call per commodity"
        self.calls.append((commodity, state))
        if self.fail:
            raise MarketUnavailableError(NO_KEY)
        return [
            price("Kalamna", "Maharashtra", date(2026, 10, 25), 3600),
            price("Kalamna", "Maharashtra", date(2026, 10, 24), 3400),  # older: not latest
            price("Warud", "Maharashtra", date(2026, 10, 25), 3300, variety=None),
            price("Azadpur", "NCT of Delhi", date(2026, 10, 25), 5200),
            price("Siliguri", "West Bengal", date(2026, 10, 23), 4100),
            price("Bathinda", "Punjab", date(2026, 10, 1), 3000),  # outside the window
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


async def test_latest_price_at_every_mandi_in_india_local_then_major_first(
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
    assert [(p["market"], p["state"], p["day"], p["modal_rs_per_quintal"]) for p in rows] == [
        ("Kalamna", "Maharashtra", "2026-10-25", 3600),
        ("Warud", "Maharashtra", "2026-10-25", 3300),
        ("Azadpur", "NCT of Delhi", "2026-10-25", 5200),
        ("Siliguri", "West Bengal", "2026-10-23", 4100),
    ]
    assert [(p["is_local"], p["is_major"]) for p in rows] == [
        (True, False),
        (True, False),
        (False, True),
        (False, False),
    ]
    assert rows[1]["variety"] is None
    assert rows[0]["source"] == "agmarknet"
    assert market.calls == [("Orange", None)], "India-wide: no state filter"

    again = await api.get("/v1/market/prices?crop=santra", headers=auth_headers)
    assert again.json()["prices"] == rows
    assert len(market.calls) == 1, "fresh prices come from storage"

    major = await api.get("/v1/market/prices?crop=santra&scope=major", headers=auth_headers)
    assert [p["market"] for p in major.json()["prices"]] == ["Azadpur"]
    local = await api.get("/v1/market/prices?crop=santra&scope=local", headers=auth_headers)
    assert [p["market"] for p in local.json()["prices"]] == ["Kalamna", "Warud"]

    async with async_sessionmaker(engine)() as s:
        assert len((await s.scalars(select(MarketPrice))).all()) == 6


async def test_source_down_serves_stored_prices_as_stale_or_an_empty_list(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    market: FakeMarket,
    auth_headers: dict[str, str],
) -> None:
    market.fail = True
    empty = await api.get("/v1/market/prices?crop=santra", headers=auth_headers)
    assert empty.status_code == 200
    assert empty.json() == {"prices": [], "stale": True, "reason": NO_KEY}

    market.fail = False
    await api.get("/v1/market/prices?crop=santra", headers=auth_headers)
    async with async_sessionmaker(engine)() as s:
        await s.execute(update(MarketPrice).values(fetched_at=NOW - timedelta(days=2)))
        await s.commit()
    market.fail = True
    stale = (await api.get("/v1/market/prices?crop=santra", headers=auth_headers)).json()
    assert stale["stale"] is True
    assert stale["reason"] == NO_KEY
    assert len(stale["prices"]) == 4


async def test_unknown_crop_bad_scope_and_no_token_are_refused(
    api: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    r = await api.get("/v1/market/prices?crop=banana", headers=auth_headers)
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "crop_not_priced"
    bad = await api.get("/v1/market/prices?crop=santra&scope=world", headers=auth_headers)
    assert bad.status_code == 422
    assert (await api.get("/v1/market/prices?crop=santra")).status_code == 401


def admin(*roles: str) -> dict[str, str]:
    meta = {"roles": list(roles)}
    return {"Authorization": f"Bearer {make_token(uuid.uuid4(), app_metadata=meta)}"}


def manual_row(market: str, day: str, modal: int, **extra: object) -> dict[str, object]:
    row: dict[str, object] = {
        "day": day,
        "market": market,
        "state": "Maharashtra",
        "district": "Nagpur",
        "commodity": "Orange",
        "variety": "Nagpuri",
        "min_rs_per_quintal": modal - 500,
        "max_rs_per_quintal": modal + 500,
        "modal_rs_per_quintal": modal,
    }
    row.update(extra)
    return row


async def test_manual_upload_fills_in_when_the_source_is_down_and_yields_to_agmarknet(
    api: httpx.AsyncClient, market: FakeMarket, auth_headers: dict[str, str]
) -> None:
    rows = [manual_row("Kalamna", "2026-10-25", 3500), manual_row("Katol", "2026-10-25", 3100)]
    r = await api.post(
        "/v1/admin/market/prices", json={"prices": rows}, headers=admin("market_admin")
    )
    assert r.status_code == 200, r.text
    assert r.json() == {"stored": 2}

    market.fail = True
    down = (await api.get("/v1/market/prices?crop=santra", headers=auth_headers)).json()
    assert down["stale"] is True
    assert [(p["market"], p["modal_rs_per_quintal"], p["source"]) for p in down["prices"]] == [
        ("Kalamna", 3500, "manual"),
        ("Katol", 3100, "manual"),
    ]

    market.fail = False
    up = (await api.get("/v1/market/prices?crop=santra", headers=auth_headers)).json()
    kalamna = [p for p in up["prices"] if p["market"] == "Kalamna"]
    assert [(p["modal_rs_per_quintal"], p["source"]) for p in kalamna] == [(3600, "agmarknet")]
    assert any(p["market"] == "Katol" and p["source"] == "manual" for p in up["prices"])


async def test_manual_upload_is_validated_and_needs_the_market_admin_role(
    api: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    url = "/v1/admin/market/prices"
    ok = {"prices": [manual_row("Kalamna", "2026-10-25", 3500)]}
    assert (await api.post(url, json=ok, headers=auth_headers)).status_code == 403
    assert (await api.post(url, json=ok, headers=admin("kb_admin"))).status_code == 403
    assert (await api.post(url, json=ok)).status_code == 401

    bad_cases = [
        manual_row("Kalamna", "2026-10-25", 3500, commodity="Banana"),
        manual_row("Kalamna", "2026-10-27", 3500),  # after today (NOW is 2026-10-26)
        manual_row("Kalamna", "2026-10-25", 3500, min_rs_per_quintal=3600),
        manual_row("Kalamna", "2026-10-25", 3500, max_rs_per_quintal=3400),
        manual_row("Kalamna", "2026-10-25", 0),
        manual_row("", "2026-10-25", 3500),
    ]
    for bad in bad_cases:
        r = await api.post(url, json={"prices": [bad]}, headers=admin("market_admin"))
        assert r.status_code == 422, bad
    empty = await api.post(url, json={"prices": []}, headers=admin("market_admin"))
    assert empty.status_code == 422


async def test_manual_upload_takes_todays_india_date_before_utc_midnight(
    settings: Settings, engine: AsyncEngine
) -> None:
    """01:30 in Nagpur is still the previous day in UTC: today's rate list is not 'future'."""
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_clock] = lambda: (
        lambda: datetime(2026, 10, 26, 20, 0, tzinfo=UTC)  # 27 Oct 01:30 IST
    )
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        url = "/v1/admin/market/prices"
        today = {"prices": [manual_row("Kalamna", "2026-10-27", 3500)]}
        r = await c.post(url, json=today, headers=admin("market_admin"))
        assert r.status_code == 200, r.text
        later = {"prices": [manual_row("Kalamna", "2026-10-28", 3500)]}
        r = await c.post(url, json=later, headers=admin("market_admin"))
        assert r.status_code == 422
