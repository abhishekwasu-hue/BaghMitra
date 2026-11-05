"""BG-04: the scheduled market pull fetches every configured commodity, stores the rows and
records each outcome; a second run never overlaps a running one. HTTP is mocked: no request
leaves the test."""

from __future__ import annotations

import json
import os
from datetime import UTC, datetime
from typing import Any

import httpx
import pytest
from pydantic import SecretStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker, create_async_engine

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import MarketPrice, MarketPull
from bagmitra_api.market.agmarknet import (
    PAGE_LIMIT,
    REASON_BAD_RESPONSE,
    MandiPrice,
    MarketUnavailableError,
)
from bagmitra_api.market.pull_job import (
    SKIPPED_LOCKED,
    SKIPPED_NO_KEY,
    configured_commodities,
    market_http,
    pull_lock,
    run_locked,
    run_market_pull,
)
from bagmitra_api.market.service import market_client

NOW = datetime(2026, 11, 5, 4, 35, tzinfo=UTC)


def keyed(**extra: Any) -> Settings:
    return Settings(market_api_key=SecretStr("market-test-key"), **extra)


class Provider:
    def __init__(self, failing: set[str] | None = None) -> None:
        self.failing = failing or set()
        self.calls: list[str] = []

    async def prices(
        self, *, commodity: str, state: str | None = None, market: str | None = None
    ) -> list[MandiPrice]:
        del state, market
        self.calls.append(commodity)
        if commodity in self.failing:
            raise MarketUnavailableError("odd payload", code=REASON_BAD_RESPONSE)
        return [
            MandiPrice(
                market="Kalamna",
                state="Maharashtra",
                district="Nagpur",
                commodity=commodity,
                variety=None,
                grade=None,
                day=NOW.date(),
                min_rs_per_quintal=3000,
                max_rs_per_quintal=4000,
                modal_rs_per_quintal=3500,
            )
        ]


def test_every_commodity_is_listed_once() -> None:
    settings = Settings(market_commodities={"a": ["Orange", "X"], "b": ["Orange"]})
    assert configured_commodities(settings) == ["Orange", "X"]


async def test_a_failing_commodity_is_recorded_and_the_others_still_run(
    engine: AsyncEngine,
) -> None:
    provider = Provider(failing={"Mousambi(Sweet Lime)"})
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        summary = await run_market_pull(session, provider, keyed(), NOW)
    assert provider.calls == ["Mousambi(Sweet Lime)", "Orange"]
    assert summary.failed == 1
    body = json.loads(summary.to_json())
    assert body["failed"] == 1
    assert body["skipped_reason"] is None
    assert [(c["commodity"], c["rows"], c["error"]) for c in body["commodities"]] == [
        ("Mousambi(Sweet Lime)", 0, REASON_BAD_RESPONSE),
        ("Orange", 1, None),
    ]
    async with maker() as session:
        pulls = {p.commodity: p for p in await session.scalars(select(MarketPull))}
        assert pulls["Orange"].last_success_at is not None
        assert pulls["Orange"].last_error is None
        assert pulls["Mousambi(Sweet Lime)"].last_success_at is None
        assert pulls["Mousambi(Sweet Lime)"].last_error == REASON_BAD_RESPONSE
        prices = (await session.scalars(select(MarketPrice))).all()
        assert [p.commodity for p in prices] == ["Orange"]


async def test_a_failure_after_a_success_keeps_the_last_success(engine: AsyncEngine) -> None:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        await run_market_pull(session, Provider(), keyed(), NOW)
        later = NOW.replace(hour=10)
        await run_market_pull(session, Provider(failing={"Orange"}), keyed(), later)
    async with maker() as session:
        orange = await session.get(MarketPull, "Orange")
        assert orange is not None
        assert orange.last_error == REASON_BAD_RESPONSE
        assert orange.last_rows == 1
        assert orange.last_success_at is not None
        assert orange.last_success_at.replace(tzinfo=UTC) == NOW


async def test_without_a_key_the_run_does_nothing(engine: AsyncEngine) -> None:
    provider = Provider()
    async with async_sessionmaker(engine)() as session:
        summary = await run_market_pull(session, provider, Settings(), NOW)
        assert summary.skipped_reason == SKIPPED_NO_KEY
        assert (await session.scalars(select(MarketPull))).all() == []
    assert provider.calls == []


async def test_one_run_respects_max_pages_and_the_timeout(engine: AsyncEngine) -> None:
    """Full pages keep coming; the run stops after MARKET_MAX_PAGES requests per commodity."""
    requests: list[httpx.Request] = []
    row = {
        "state": "Maharashtra",
        "district": "Nagpur",
        "market": "Kalamna",
        "commodity": "Orange",
        "variety": "Nagpuri",
        "grade": "FAQ",
        "arrival_date": "05/11/2026",
        "min_price": "3000",
        "max_price": "4000",
        "modal_price": "3500",
    }

    def handler(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        return httpx.Response(200, json={"records": [row] * PAGE_LIMIT})

    settings = keyed(
        market_max_pages=3, market_timeout_seconds=7.5, market_commodities={"santra": ["Orange"]}
    )
    async with market_http(settings, httpx.MockTransport(handler)) as http:
        assert http.timeout == httpx.Timeout(7.5)
        async with async_sessionmaker(engine, expire_on_commit=False)() as session:
            summary = await run_market_pull(session, market_client(http, settings), settings, NOW)
    assert len(requests) == 3
    assert [r.url.params["offset"] for r in requests] == ["0", "500", "1000"]
    assert summary.commodities[0].rows == 3 * PAGE_LIMIT
    assert summary.failed == 0


async def test_sqlite_runs_without_a_lock(engine: AsyncEngine) -> None:
    async with pull_lock(engine) as held:
        assert held is True
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        summary = await run_locked(engine, session, Provider(), keyed(), NOW)
    assert summary.skipped_reason is None
    assert summary.failed == 0


@pytest.mark.postgres
@pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL")
async def test_postgres_a_second_run_is_skipped_while_one_holds_the_lock() -> None:
    eng = create_async_engine(os.environ["POSTGRES_TEST_URL"])
    try:
        async with pull_lock(eng) as first:
            assert first is True
            async with pull_lock(eng) as second:
                assert second is False
            provider = Provider()
            async with async_sessionmaker(eng)() as session:
                skipped = await run_locked(eng, session, provider, keyed(), NOW)
            assert skipped.skipped_reason == SKIPPED_LOCKED
            assert provider.calls == []
        async with pull_lock(eng) as again:
            assert again is True, "the lock is released when the run ends"
    finally:
        await eng.dispose()
