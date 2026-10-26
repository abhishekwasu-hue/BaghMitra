from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta

import httpx
import pytest
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import Plot, WeatherDaily
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.weather.open_meteo import DailyWeather, WeatherUnavailableError
from bagmitra_api.weather.service import cell_for, get_clock, get_weather_provider

TODAY = date(2026, 3, 14)
NOW = datetime(2026, 3, 14, 6, 0, tzinfo=UTC)


class FakeProvider:
    def __init__(self, *, fail: bool = False) -> None:
        self.calls: list[tuple[float, float]] = []
        self.fail = fail

    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]:
        assert (past_days, forecast_days) == (7, 7)
        self.calls.append((lat, lon))
        if self.fail:
            raise WeatherUnavailableError("HTTP 503")
        return [
            DailyWeather(TODAY + timedelta(days=i), 30 + 3 * i, 18, 0.0, 40, 20) for i in range(3)
        ]


@pytest.fixture
def provider() -> FakeProvider:
    return FakeProvider()


@pytest.fixture
async def api(
    settings: Settings, engine: AsyncEngine, provider: FakeProvider
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_weather_provider] = lambda: provider
    app.dependency_overrides[get_clock] = lambda: (lambda: NOW)
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c


async def add_plot(
    engine: AsyncEngine, owner: uuid.UUID, *, lat: float | None = 21.2468, lon: float = 77.7512
) -> uuid.UUID:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    plot_id = uuid.uuid4()
    async with maker() as s:
        s.add(
            Plot(
                id=plot_id,
                owner_id=owner,
                name="बाग १",
                crop="santra",
                area_sq_m=4000,
                centroid_lat=lat,
                centroid_lon=lon,
                client_updated_at=NOW,
                last_seq=1,
            )
        )
        await s.commit()
    return plot_id


def test_cell_rounds_so_neighbours_share_one_pull() -> None:
    assert cell_for(21.2468, 77.7512, 2) == (21.25, 77.75)
    assert cell_for(21.2449, 77.7549, 2) == (21.24, 77.75)


async def test_plot_weather_pulls_once_stores_and_returns_alerts(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    plot_id = await add_plot(engine, user_id)
    r = await api.get(f"/v1/plots/{plot_id}/weather?lang=mr", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert [d["day"] for d in body["days"]] == ["2026-03-14", "2026-03-15", "2026-03-16"]
    assert body["stale"] is False
    heat = next(a for a in body["alerts"] if a["rule_key"] == "heat_fruit_drop")
    assert (heat["first_day"], heat["value"]) == ("2026-03-16", 36)
    assert "फळगळ" in heat["text"]
    assert heat["status"] == "draft"
    assert heat["source"]

    again = await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    assert again.json()["days"] == body["days"]
    assert provider.calls == [(21.25, 77.75)], "fresh data is served from storage"

    maker = async_sessionmaker(engine)
    async with maker() as s:
        rows = (await s.execute(select(WeatherDaily))).all()
    assert len(rows) == 3


async def test_provider_down_serves_stored_days_as_stale(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    plot_id = await add_plot(engine, user_id)
    provider.fail = True
    empty = await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    assert empty.status_code == 503
    assert empty.json()["error"]["code"] == "weather_unavailable"

    provider.fail = False
    await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    maker = async_sessionmaker(engine)
    async with maker() as s:
        await s.execute(update(WeatherDaily).values(fetched_at=NOW - timedelta(days=2)))
        await s.commit()
    provider.fail = True
    stale = await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    assert stale.status_code == 200
    assert stale.json()["stale"] is True
    assert len(stale.json()["days"]) == 3


async def test_other_owner_and_missing_location_are_refused(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    other = await add_plot(engine, uuid.uuid4())
    r = await api.get(f"/v1/plots/{other}/weather", headers=auth_headers)
    assert r.status_code == 404
    no_gps = await add_plot(engine, user_id, lat=None)
    r = await api.get(f"/v1/plots/{no_gps}/weather", headers=auth_headers)
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "plot_location_missing"
    assert (await api.get(f"/v1/plots/{no_gps}/weather")).status_code == 401
