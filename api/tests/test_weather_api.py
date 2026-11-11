from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta
from pathlib import Path

import httpx
import pytest
from alembic import command
from sqlalchemy import create_engine, inspect, select, update
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import Plot, WeatherDaily
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.weather.open_meteo import CurrentWeather, DailyWeather, WeatherUnavailableError
from bagmitra_api.weather.service import (
    CurrentWeatherCache,
    cell_for,
    get_clock,
    get_current_cache,
    get_weather_provider,
)
from tests.test_migrations import _config, _sync_url

TODAY = date(2026, 3, 14)
NOW = datetime(2026, 3, 14, 6, 0, tzinfo=UTC)
OBSERVED = datetime(2026, 3, 14, 5, 45, tzinfo=UTC)


class FakeProvider:
    def __init__(self, *, fail: bool = False) -> None:
        self.calls: list[tuple[float, float]] = []
        self.current_calls: list[tuple[float, float]] = []
        self.fail = fail
        self.current_fail = False
        self.storm = False
        self.current_temp = 21.4

    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]:
        assert (past_days, forecast_days) == (7, 15)
        self.calls.append((lat, lon))
        if self.fail:
            raise WeatherUnavailableError("HTTP 503")
        code = 95.0 if self.storm else 3.0
        return [
            DailyWeather(TODAY + timedelta(days=i), 30 + 3 * i, 18, 0.0, 40, 20, code, 20.0 * i)
            for i in range(3)
        ]

    async def current(self, lat: float, lon: float) -> CurrentWeather:
        self.current_calls.append((lat, lon))
        if self.current_fail:
            raise WeatherUnavailableError("HTTP 503")
        return CurrentWeather(OBSERVED, self.current_temp, 0.0, False)


@pytest.fixture
def provider() -> FakeProvider:
    return FakeProvider()


@pytest.fixture
def clock() -> list[datetime]:
    return [NOW]


@pytest.fixture
async def api(
    settings: Settings, engine: AsyncEngine, provider: FakeProvider, clock: list[datetime]
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    current_cache = CurrentWeatherCache()
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_weather_provider] = lambda: provider
    app.dependency_overrides[get_clock] = lambda: (lambda: clock[0])
    app.dependency_overrides[get_current_cache] = lambda: current_cache
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
    assert [d["rain_prob_pct"] for d in body["days"]] == [0, 20, 40]
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
        rows = (await s.scalars(select(WeatherDaily).order_by(WeatherDaily.day))).all()
    assert len(rows) == 3
    assert [r.rain_prob_pct for r in rows] == [0, 20, 40]


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
    assert "HTTP" not in empty.json()["error"]["message"]  # provider detail stays in the log

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


async def test_storm_alert_links_to_the_claim_kit_and_code_is_stored(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    provider.storm = True
    plot_id = await add_plot(engine, user_id)
    body = (await api.get(f"/v1/plots/{plot_id}/weather?lang=mr", headers=auth_headers)).json()
    storm = next(a for a in body["alerts"] if a["rule_key"] == "hail_thunderstorm")
    assert storm["action"] == "claim_kit"
    assert "फोटो" in storm["text"]
    heat = next(a for a in body["alerts"] if a["rule_key"] == "heat_fruit_drop")
    assert heat["action"] is None
    assert body["days"][0]["weather_code"] == 95
    # Served again from storage: the stored code still triggers the same alert.
    again = (await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)).json()
    assert any(a["rule_key"] == "hail_thunderstorm" for a in again["alerts"])
    assert provider.calls == [(21.25, 77.75)]


def test_migration_0023_adds_and_drops_the_weather_code(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'w.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))
    command.upgrade(cfg, "0023")
    with engine.connect() as conn:
        assert "weather_code" in {c["name"] for c in inspect(conn).get_columns("weather_daily")}
    command.downgrade(cfg, "0022")
    with engine.connect() as conn:
        assert "weather_code" not in {c["name"] for c in inspect(conn).get_columns("weather_daily")}
    engine.dispose()


async def test_day_stored_before_0042_is_served_without_rain_probability(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    plot_id = await add_plot(engine, user_id)
    maker = async_sessionmaker(engine)
    async with maker() as s:
        s.add(
            WeatherDaily(
                cell_lat=21.25,
                cell_lon=77.75,
                day=TODAY,
                t_max_c=31,
                t_min_c=19,
                precip_mm=2.0,
                rh_mean_pct=60,
                wind_gust_kmh=15,
                fetched_at=NOW,
            )
        )
        await s.commit()
    r = await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    assert r.status_code == 200, r.text
    day = r.json()["days"][0]
    assert (day["precip_mm"], day["rain_prob_pct"]) == (2.0, None)
    assert provider.calls == [], "served from storage"


async def test_alerts_use_seven_forecast_days_of_the_fifteen_served(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    """The forecast screen shows 15 days; the risk rules keep their 7-day window (Q134)."""
    plot_id = await add_plot(engine, user_id)
    maker = async_sessionmaker(engine)
    async with maker() as s:
        s.add_all(
            WeatherDaily(
                cell_lat=21.25,
                cell_lon=77.75,
                day=TODAY + timedelta(days=i),
                # Heat only on day 8 onward: outside the alert window.
                t_max_c=40 if i >= 8 else 30,
                t_min_c=10,
                precip_mm=0.0,
                rh_mean_pct=40,
                wind_gust_kmh=10,
                rain_prob_pct=5,
                fetched_at=NOW,
            )
            for i in range(15)
        )
        await s.commit()
    body = (await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)).json()
    assert len(body["days"]) == 15
    assert body["days"][9]["t_max_c"] == 40
    assert all(a["rule_key"] != "heat_fruit_drop" for a in body["alerts"])


def test_migration_0042_adds_and_drops_the_rain_probability(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'w.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))

    def columns() -> set[str]:
        with engine.connect() as conn:
            return {c["name"] for c in inspect(conn).get_columns("weather_daily")}

    command.upgrade(cfg, "0042")
    assert "rain_prob_pct" in columns()
    command.downgrade(cfg, "0041")
    assert "rain_prob_pct" not in columns()
    assert "weather_code" in columns()
    engine.dispose()


async def test_plot_weather_carries_the_current_reading_with_its_time(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    """Owner Q140: the header shows the temperature now, not today's max, at night too."""
    plot_id = await add_plot(engine, user_id)
    body = (await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)).json()
    assert body["current"] == {
        "temperature_c": 21.4,
        "weather_code": 0,
        "is_day": False,
        "observed_at": "2026-03-14T05:45:00Z",
    }
    assert provider.current_calls == [(21.25, 77.75)]


async def test_nearby_plots_share_one_current_call_within_the_cache_window(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    clock: list[datetime],
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    mine = await add_plot(engine, user_id)
    neighbour = await add_plot(engine, user_id, lat=21.2471, lon=77.7509)  # same cell
    await api.get(f"/v1/plots/{mine}/weather", headers=auth_headers)
    clock[0] = NOW + timedelta(minutes=29)
    await api.get(f"/v1/plots/{neighbour}/weather", headers=auth_headers)
    assert provider.current_calls == [(21.25, 77.75)], "one call serves the cell for 30 min"

    clock[0] = NOW + timedelta(minutes=30)
    provider.current_temp = 19.0
    body = (await api.get(f"/v1/plots/{mine}/weather", headers=auth_headers)).json()
    assert len(provider.current_calls) == 2
    assert body["current"]["temperature_c"] == 19.0


async def test_current_failure_serves_the_last_reading_with_its_own_time(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    clock: list[datetime],
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    plot_id = await add_plot(engine, user_id)
    await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    clock[0] = NOW + timedelta(hours=2)
    provider.current_fail = True
    r = await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    assert r.status_code == 200
    # The old reading keeps its own observation time, so the phone can tell its age.
    assert r.json()["current"]["observed_at"] == "2026-03-14T05:45:00Z"
    assert r.json()["days"], "the days are served as before"


async def test_current_failure_without_a_reading_returns_none_never_a_made_up_value(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    provider: FakeProvider,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    plot_id = await add_plot(engine, user_id)
    provider.current_fail = True
    r = await api.get(f"/v1/plots/{plot_id}/weather", headers=auth_headers)
    assert r.status_code == 200
    assert r.json()["current"] is None
    assert len(r.json()["days"]) == 3


async def test_cache_keeps_cells_apart_and_retries_after_a_failure() -> None:
    provider = FakeProvider()
    cache = CurrentWeatherCache()
    window = timedelta(minutes=30)
    a = await cache.get(provider, (21.25, 77.75), NOW, window)
    b = await cache.get(provider, (21.3, 77.75), NOW, window)
    assert a is not None
    assert b is not None
    assert provider.current_calls == [(21.25, 77.75), (21.3, 77.75)]
    provider.current_fail = True
    late = NOW + window
    assert await cache.get(provider, (21.25, 77.75), late, window) == a
    provider.current_fail = False
    await cache.get(provider, (21.25, 77.75), late, window)
    assert len(provider.current_calls) == 4, "a failure is not cached as fresh"
