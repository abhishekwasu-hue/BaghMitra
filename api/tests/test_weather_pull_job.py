from __future__ import annotations

import json
import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.logging import configure_logging
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import Plot, PlotRiskAlert
from bagmitra_api.risk.engine import load_rules, parse_rules
from bagmitra_api.weather.open_meteo import DailyWeather, WeatherUnavailableError
from bagmitra_api.weather.pull_job import (
    CellFailure,
    PullSummary,
    report_failures,
    run_daily_pull,
)

TODAY = date(2026, 3, 14)
NOW = datetime(2026, 3, 14, 0, 0, tzinfo=UTC)
CELL_A = (21.25, 77.75)
CELL_B = (20.93, 77.78)


class FakeProvider:
    def __init__(self, *, failing: set[tuple[float, float]] | None = None) -> None:
        self.calls: list[tuple[float, float]] = []
        self.failing = failing or set()

    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]:
        assert (past_days, forecast_days) == (7, 15)
        self.calls.append((lat, lon))
        if (lat, lon) in self.failing:
            raise WeatherUnavailableError("HTTP 503")
        return [
            DailyWeather(TODAY + timedelta(days=i), 30 + 3 * i, 18, 0.0, 40, 20) for i in range(3)
        ]


@pytest.fixture
def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def add_plot(
    maker: async_sessionmaker[AsyncSession],
    *,
    lat: float | None,
    lon: float | None,
    deleted: bool = False,
) -> Plot:
    plot = Plot(
        id=uuid.uuid4(),
        owner_id=uuid.uuid4(),
        name="बाग",
        crop="santra",
        area_sq_m=4000,
        centroid_lat=lat,
        centroid_lon=lon,
        deleted_at=NOW if deleted else None,
        client_updated_at=NOW,
        last_seq=1,
    )
    async with maker() as s:
        s.add(plot)
        await s.commit()
    return plot


async def alerts(maker: async_sessionmaker[AsyncSession]) -> list[PlotRiskAlert]:
    async with maker() as s:
        return list((await s.scalars(select(PlotRiskAlert))).all())


HEAT = [r for r in load_rules() if r.key == "heat_fruit_drop"]


async def test_one_call_per_cell_and_heat_alert_stored_per_plot(
    maker: async_sessionmaker[AsyncSession], settings: Settings
) -> None:
    a1 = await add_plot(maker, lat=21.2468, lon=77.7512)
    a2 = await add_plot(maker, lat=21.2471, lon=77.7489)
    b = await add_plot(maker, lat=20.9312, lon=77.7801)
    provider = FakeProvider()

    async with maker() as s:
        summary = await run_daily_pull(s, provider, settings, NOW)

    assert sorted(provider.calls) == sorted([CELL_A, CELL_B])
    assert (summary.cells, summary.plots, summary.failed_cells) == (2, 3, 0)
    rows = await alerts(maker)
    heat = {r.plot_id: r for r in rows if r.rule_key == "heat_fruit_drop"}
    assert set(heat) == {a1.id, a2.id, b.id}
    assert heat[a1.id].owner_id == a1.owner_id
    assert (heat[a1.id].first_day, heat[a1.id].value) == (TODAY + timedelta(days=2), 36)
    assert all(r.notified_at is None for r in rows)
    assert summary.new_alerts == len(rows)
    assert json.loads(summary.to_json())["new_alerts"] == len(rows)


async def test_running_twice_stores_no_duplicates(
    maker: async_sessionmaker[AsyncSession], settings: Settings
) -> None:
    await add_plot(maker, lat=21.2468, lon=77.7512)
    await add_plot(maker, lat=21.2471, lon=77.7489)
    provider = FakeProvider()
    async with maker() as s:
        first = await run_daily_pull(s, provider, settings, NOW, rules=HEAT)
    async with maker() as s:
        again = await run_daily_pull(s, provider, settings, NOW + timedelta(hours=1), rules=HEAT)
    async with maker() as s:
        next_day = await run_daily_pull(s, provider, settings, NOW + timedelta(days=1), rules=HEAT)

    assert first.new_alerts == 2
    assert again.new_alerts == 0
    assert next_day.new_alerts == 0
    assert len(provider.calls) == 2, "fresh stored days are reused, a day later it pulls again"
    assert len(await alerts(maker)) == 2


async def test_failing_cell_is_reported_and_others_processed(
    maker: async_sessionmaker[AsyncSession], settings: Settings
) -> None:
    await add_plot(maker, lat=21.2468, lon=77.7512)
    ok = await add_plot(maker, lat=20.9312, lon=77.7801)
    provider = FakeProvider(failing={CELL_A})

    async with maker() as s:
        summary = await run_daily_pull(s, provider, settings, NOW, rules=HEAT)

    assert summary.failed_cells == 1
    assert summary.failures[0].cell == CELL_A
    assert "503" in summary.failures[0].error
    assert summary.new_alerts == 1
    assert [r.plot_id for r in await alerts(maker)] == [ok.id]
    assert json.loads(summary.to_json())["failures"][0]["cell"] == list(CELL_A)


async def test_deleted_and_unlocated_plots_are_skipped(
    maker: async_sessionmaker[AsyncSession], settings: Settings
) -> None:
    await add_plot(maker, lat=21.2468, lon=77.7512, deleted=True)
    await add_plot(maker, lat=None, lon=None)
    await add_plot(maker, lat=21.2468, lon=None)
    provider = FakeProvider()

    async with maker() as s:
        summary = await run_daily_pull(s, provider, settings, NOW, rules=HEAT)

    assert provider.calls == []
    assert (summary.cells, summary.plots, summary.new_alerts) == (0, 0, 0)
    assert await alerts(maker) == []


class RollingProvider(FakeProvider):
    """Each pull starts the days at `start`, so a degree-day rule's first day moves forward."""

    start = TODAY

    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]:
        assert (past_days, forecast_days) == (7, 15)
        self.calls.append((lat, lon))
        return [DailyWeather(self.start + timedelta(days=i), 30, 20, 0.0, 40, 20) for i in range(3)]


async def test_rolling_degree_day_alert_is_stored_once_per_window(
    maker: async_sessionmaker[AsyncSession], settings: Settings
) -> None:
    await add_plot(maker, lat=21.2468, lon=77.7512)
    psylla = parse_rules(
        {
            "rules": [
                {
                    "key": "psylla_degree_days",
                    "kind": "degree_days",
                    "base_c": 11.11,
                    "upper_c": 32,
                    "per_unit": 580,
                    "source": "test",
                    "labels": {"en": "Warm", "mr": "उबदार", "hi": "गर्म"},
                }
            ]
        }
    )
    provider = RollingProvider()
    async with maker() as s:
        first = await run_daily_pull(s, provider, settings, NOW, rules=psylla)
    provider.start = TODAY + timedelta(days=1)
    async with maker() as s:
        next_day = await run_daily_pull(
            s, provider, settings, NOW + timedelta(days=1), rules=psylla
        )

    assert first.new_alerts == 1
    assert next_day.new_alerts == 0, "same rule, same plot, still inside the window"
    assert len(await alerts(maker)) == 1


def test_failed_cells_reach_the_log_and_sentry_with_counts_only(
    monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    """BG-05: a pull with failed cells exits 1, writes one `job_failed` error line and, when
    reporting is on, sends one Sentry event; no cell location or provider message."""
    configure_logging("INFO")
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(
        "sentry_sdk.capture_message", lambda message, level=None: sent.append((message, level))
    )
    failed = PullSummary(cells=3, plots=5, failed_cells=1)
    failed.failures.append(CellFailure(CELL_A, "HTTP 503 https://x?apikey=secret"))
    assert report_failures(failed, reporting=False) == 1
    assert sent == []
    line = json.loads(capsys.readouterr().out.strip().splitlines()[-1])
    assert line["event"] == "job_failed"
    assert line["level"] == "error"
    assert (line["job"], line["cells"], line["failed_cells"]) == ("weather_pull", 3, 1)
    assert report_failures(failed, reporting=True) == 1
    assert sent == [("scheduled job failed: weather_pull", "error")]
    out = capsys.readouterr().out
    assert "secret" not in out
    assert str(CELL_A[0]) not in out
    assert report_failures(PullSummary(cells=3), reporting=True) == 0
    assert len(sent) == 1


class FifteenDayProvider(FakeProvider):
    """The full 15-day forecast, with heat only from day 8 onward."""

    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]:
        assert (past_days, forecast_days) == (7, 15)
        self.calls.append((lat, lon))
        return [
            DailyWeather(TODAY + timedelta(days=i), 40 if i >= 8 else 30, 18, 0.0, 40, 20)
            for i in range(forecast_days)
        ]


async def test_alerts_keep_the_seven_forecast_day_window(
    maker: async_sessionmaker[AsyncSession], settings: Settings
) -> None:
    await add_plot(maker, lat=21.2468, lon=77.7512)
    async with maker() as s:
        summary = await run_daily_pull(s, FifteenDayProvider(), settings, NOW, rules=HEAT)
    assert summary.new_alerts == 0
    assert await alerts(maker) == []
