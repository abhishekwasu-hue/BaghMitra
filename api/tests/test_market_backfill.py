"""Q130: one-off 90-day backfill of mandi prices from the data.gov.in "Variety-wise Daily
Market Prices" archive. Only mandis already known from the current feed are stored (an archive
name is never mapped by guess), existing days are never overwritten. HTTP is mocked: no request
leaves the test."""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta
from typing import Any

import httpx
import pytest
from pydantic import SecretStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import MarketPrice, MarketPull
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market import backfill
from bagmitra_api.market.agmarknet import (
    REASON_BAD_RESPONSE,
    REASON_NOT_CONFIGURED,
    REASON_UNREACHABLE,
    MandiPrice,
    MarketUnavailableError,
)
from bagmitra_api.market.backfill import (
    ARCHIVE_PAGE_LIMIT,
    ArchiveClient,
    archive_client,
    main,
    run_backfill,
)
from bagmitra_api.market.pull_job import market_http
from bagmitra_api.market.service import AGMARKNET, MANUAL, store_prices
from bagmitra_api.weather.service import get_clock

NOW = datetime(2026, 11, 9, 6, 0, tzinfo=UTC)
TODAY = NOW.date()


def keyed(settings: Settings, **extra: Any) -> Settings:
    extra.setdefault("market_commodities", {"santra": ["Orange"]})
    return settings.model_copy(update={"market_api_key": SecretStr("market-test-key"), **extra})


def current(market: str, day: date, modal: int, **extra: Any) -> MandiPrice:
    fields: dict[str, Any] = {
        "market": market,
        "state": "Maharashtra",
        "district": "Nagpur",
        "commodity": "Orange",
        "variety": "Nagpuri",
        "grade": "FAQ",
        "day": day,
        "min_rs_per_quintal": modal - 500,
        "max_rs_per_quintal": modal + 500,
        "modal_rs_per_quintal": modal,
    }
    fields.update(extra)
    return MandiPrice(**fields)


def archive_row(market: str, day: date, modal: object, **extra: Any) -> dict[str, Any]:
    row: dict[str, Any] = {
        "Arrival_Date": day.strftime("%d/%m/%Y"),
        "Commodity": "Orange",
        "Commodity_Code": "18",
        "District": "Nagpur",
        "Grade": "FAQ",
        "Market": market,
        "Max_Price": modal,
        "Min_Price": modal,
        "Modal_Price": modal,
        "State": "Maharashtra",
        "Variety": "Nagpuri",
    }
    row.update(extra)
    return row


class FakeArchive:
    def __init__(self, rows: dict[str, list[MandiPrice]], failing: set[str] | None = None):
        self.rows = rows
        self.failing = failing or set()
        self.calls: list[tuple[str, date]] = []

    async def prices(self, *, commodity: str, since: date) -> list[MandiPrice]:
        self.calls.append((commodity, since))
        if commodity in self.failing:
            raise MarketUnavailableError("connect timeout", code=REASON_UNREACHABLE)
        return self.rows.get(commodity, [])


@pytest.fixture
def maker(engine: AsyncEngine) -> async_sessionmaker[Any]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def stored(maker: async_sessionmaker[Any]) -> list[tuple[date, str, str, int]]:
    async with maker() as session:
        rows = await session.scalars(select(MarketPrice).order_by(MarketPrice.day))
        return [(r.day, r.market, r.source, r.modal_rs_per_quintal) for r in rows]


async def test_the_archive_query_names_commodity_sort_range_and_pages(
    settings: Settings,
) -> None:
    requests: list[httpx.Request] = []
    rows = [archive_row("Kalamna", TODAY, "3500")] * ARCHIVE_PAGE_LIMIT

    def handler(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        offset = int(request.url.params["offset"])
        page = rows if offset < 2 * ARCHIVE_PAGE_LIMIT else rows[:7]
        return httpx.Response(200, json={"total": 2 * ARCHIVE_PAGE_LIMIT + 7, "records": page})

    s = keyed(settings, market_timeout_seconds=7.5)
    async with market_http(s, httpx.MockTransport(handler)) as http:
        prices = await archive_client(http, s).prices(
            commodity="Mousambi(Sweet Lime)", since=date(2026, 8, 1)
        )
    assert len(requests) == 3
    first = requests[0]
    assert first.url.path == f"/resource/{s.market_archive_resource_id}"
    assert s.market_archive_resource_id == "35985678-0d79-46b4-9ed6-6f13308a1d24"
    params = dict(first.url.params)
    assert params == {
        "api-key": "market-test-key",
        "format": "json",
        "limit": str(ARCHIVE_PAGE_LIMIT),
        "offset": "0",
        "filters[Commodity]": "Mousambi(Sweet Lime)",
        "sort[Arrival_Date]": "desc",
        "range[Arrival_Date][gte]": "01/08/2026",
    }
    assert [r.url.params["offset"] for r in requests] == ["0", "1000", "2000"]
    assert {r.headers["user-agent"] for r in requests} == {s.market_user_agent}
    assert http.timeout == httpx.Timeout(7.5)
    assert prices == [], "Orange rows are not Mousambi: the commodity is matched exactly"


async def test_paging_stops_at_the_page_bound(settings: Settings) -> None:
    calls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.url.params["offset"])
        page = [archive_row("Kalamna", TODAY, 3500)] * ARCHIVE_PAGE_LIMIT
        return httpx.Response(200, json={"total": 10**6, "records": page})

    s = keyed(settings)
    async with market_http(s, httpx.MockTransport(handler)) as http:
        client = ArchiveClient(
            http,
            base_url=s.market_api_base_url,
            resource_id=s.market_archive_resource_id,
            api_key="k",
            timeout=s.market_archive_timeout_seconds,
            max_pages=2,
        )
        prices = await client.prices(commodity="Orange", since=TODAY)
    assert calls == ["0", "1000"]
    assert len(prices) == 2 * ARCHIVE_PAGE_LIMIT


async def test_paging_stops_once_total_rows_are_read(settings: Settings) -> None:
    calls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.url.params["offset"])
        page = [archive_row("Kalamna", TODAY, 3500)] * ARCHIVE_PAGE_LIMIT
        return httpx.Response(200, json={"total": ARCHIVE_PAGE_LIMIT, "records": page})

    s = keyed(settings)
    async with market_http(s, httpx.MockTransport(handler)) as http:
        prices = await archive_client(http, s).prices(commodity="Orange", since=TODAY)
    assert calls == ["0"]
    assert len(prices) == ARCHIVE_PAGE_LIMIT


async def test_string_and_number_prices_and_dd_mm_yyyy_dates_are_parsed(
    settings: Settings,
) -> None:
    payload = {
        "total": 4,
        "records": [
            archive_row("Kalamna", date(2026, 8, 2), "3,450", Min_Price="3000"),
            archive_row("Warud", date(2026, 10, 31), 4100.0, Max_Price=4500, Variety=""),
            archive_row("Katol", date(2026, 9, 1), "NR"),  # no modal price: nothing usable
            archive_row("Morshi", date(2026, 9, 1), 3000, Commodity="Orange Peel"),
        ],
    }
    s = keyed(settings)
    transport = httpx.MockTransport(lambda _: httpx.Response(200, json=payload))
    async with market_http(s, transport) as http:
        prices = await archive_client(http, s).prices(commodity="Orange", since=date(2026, 8, 1))
    assert [
        (p.market, p.day, p.min_rs_per_quintal, p.modal_rs_per_quintal, p.max_rs_per_quintal)
        for p in prices
    ] == [
        ("Kalamna", date(2026, 8, 2), 3000, 3450, 3450),
        ("Warud", date(2026, 10, 31), 4100, 4100, 4500),
    ]
    assert prices[1].variety is None
    assert prices[0].grade == "FAQ"
    assert prices[0].state == "Maharashtra"


@pytest.mark.parametrize(
    ("response", "code"),
    [
        (httpx.Response(502), REASON_UNREACHABLE),
        (httpx.Response(200, json={"message": "Invalid key"}), REASON_BAD_RESPONSE),
        (httpx.Response(200, json={"total": 1, "records": ["odd"]}), REASON_BAD_RESPONSE),
        (httpx.Response(200, text="<html>busy</html>"), REASON_BAD_RESPONSE),
        (httpx.Response(200, json=["odd"]), REASON_BAD_RESPONSE),
        (
            httpx.Response(
                200, json={"total": 1, "records": [archive_row("K", TODAY, 1, Arrival_Date="x")]}
            ),
            REASON_BAD_RESPONSE,
        ),
    ],
)
async def test_a_bad_answer_is_a_market_error(
    settings: Settings, response: httpx.Response, code: str, waits: list[float]
) -> None:
    s = keyed(settings)
    async with market_http(s, httpx.MockTransport(lambda _: response)) as http:
        with pytest.raises(MarketUnavailableError) as err:
            await archive_client(http, s).prices(commodity="Orange", since=TODAY)
    assert err.value.code == code


async def test_an_unreachable_archive_is_a_market_error(
    settings: Settings, waits: list[float]
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectTimeout("timed out", request=request)

    s = keyed(settings)
    async with market_http(s, httpx.MockTransport(handler)) as http:
        with pytest.raises(MarketUnavailableError) as err:
            await archive_client(http, s).prices(commodity="Orange", since=TODAY)
    assert err.value.code == REASON_UNREACHABLE


async def test_a_missing_key_fails_clearly(settings: Settings) -> None:
    async with market_http(settings, httpx.MockTransport(lambda _: httpx.Response(200))) as http:
        with pytest.raises(MarketUnavailableError) as err:
            await archive_client(http, settings).prices(commodity="Orange", since=TODAY)
    assert err.value.code == REASON_NOT_CONFIGURED
    assert "MARKET_API_KEY" in str(err.value)


async def test_the_cli_exits_non_zero_without_a_key(
    settings: Settings, capsys: pytest.CaptureFixture[str]
) -> None:
    assert await main([], settings) == 2
    err = capsys.readouterr().err
    assert "MARKET_API_KEY" in err


@pytest.mark.parametrize("days", ["0", "91", "x"])
async def test_the_cli_refuses_days_outside_1_to_90(settings: Settings, days: str) -> None:
    with pytest.raises(SystemExit) as exit_:
        await main(["--days", days], keyed(settings))
    assert exit_.value.code == 2


async def test_only_known_mandis_are_stored_and_existing_days_are_kept(
    settings: Settings, maker: async_sessionmaker[Any]
) -> None:
    s = keyed(settings, market_commodities={"santra": ["Orange"], "lemon": ["Lemon"]})
    async with maker() as session:
        await store_prices(
            session,
            [
                current("Kalamna", TODAY, 3600),
                current("Warud", TODAY - timedelta(days=1), 3300, variety=None, grade=None),
            ],
            source=AGMARKNET,
            now=NOW,
        )
        # A manual-only mandi is not a key from the current feed.
        await store_prices(session, [current("Katol", TODAY, 3100)], source=MANUAL, now=NOW)
    archive = FakeArchive(
        {
            "Orange": [
                current("Kalamna", TODAY, 9999),  # the day exists: never overwritten
                current("Kalamna", TODAY - timedelta(days=5), 3400),
                current("Kalamna", TODAY - timedelta(days=5), 1),  # same day again: kept once
                current("Kalamna", TODAY - timedelta(days=89), 3000),  # first day of the window
                current("Kalamna", TODAY - timedelta(days=90), 2900),  # older: ignored
                current("Warud", TODAY - timedelta(days=3), 3200, variety=None, grade=None),
                current("Pune(Moshi) APMC", TODAY - timedelta(days=2), 5000),
                current("Pune(Moshi) APMC", TODAY - timedelta(days=3), 5100),
                current("Kalamna", TODAY - timedelta(days=4), 3300, variety="Other"),
                current("Katol", TODAY - timedelta(days=4), 3000),
            ]
        },
        failing={"Lemon"},
    )
    async with maker() as session:
        summary = await run_backfill(session, archive, s, NOW)

    assert archive.calls == [
        ("Lemon", TODAY - timedelta(days=89)),
        ("Orange", TODAY - timedelta(days=89)),
    ]
    body = json.loads(summary.to_json())
    assert body["failed"] == 1
    lemon, orange = body["commodities"]
    assert lemon == {
        "commodity": "Lemon",
        "read": 0,
        "stored": 0,
        "skipped_existing": 0,
        "unmatched": 0,
        "top_unmatched_markets": [],
        "error": REASON_UNREACHABLE,
    }
    assert orange == {
        "commodity": "Orange",
        "read": 9,
        "stored": 3,
        "skipped_existing": 2,
        "unmatched": 4,
        "top_unmatched_markets": [["Pune(Moshi) APMC", 2], ["Kalamna", 1], ["Katol", 1]],
        "error": None,
    }
    assert await stored(maker) == [
        (TODAY - timedelta(days=89), "Kalamna", AGMARKNET, 3000),
        (TODAY - timedelta(days=5), "Kalamna", AGMARKNET, 3400),
        (TODAY - timedelta(days=3), "Warud", AGMARKNET, 3200),
        (TODAY - timedelta(days=1), "Warud", AGMARKNET, 3300),
        (TODAY, "Kalamna", AGMARKNET, 3600),
        (TODAY, "Katol", MANUAL, 3100),
    ]
    async with maker() as session:
        warud = await session.get(
            MarketPrice,
            (TODAY - timedelta(days=3), "Warud", "Orange", "", "", AGMARKNET),
        )
        assert warud is not None, "blank variety and grade are stored as ''"
        assert (await session.scalars(select(MarketPull))).all() == [], (
            "the backfill never touches the pull freshness record"
        )


async def test_a_shorter_window_and_no_key(
    settings: Settings, maker: async_sessionmaker[Any]
) -> None:
    archive = FakeArchive({})
    async with maker() as session:
        summary = await run_backfill(session, archive, keyed(settings), NOW, days=15)
        assert archive.calls == [("Orange", TODAY - timedelta(days=14))]
        assert summary.commodities[0].read == 0
        skipped = await run_backfill(session, FakeArchive({}), settings, NOW)
    assert skipped.skipped_reason is not None
    assert "MARKET_API_KEY" in skipped.skipped_reason
    with pytest.raises(ValueError, match=r"1\.\.90"):
        async with maker() as session:
            await run_backfill(session, archive, keyed(settings), NOW, days=91)


@pytest.fixture
async def api(settings: Settings, engine: AsyncEngine) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(keyed(settings))
    app.dependency_overrides[get_sessionmaker] = lambda: async_sessionmaker(
        engine, expire_on_commit=False
    )
    app.dependency_overrides[get_clock] = lambda: (lambda: NOW)
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c


async def test_the_history_endpoint_returns_the_backfilled_days(
    settings: Settings,
    maker: async_sessionmaker[Any],
    api: httpx.AsyncClient,
    auth_headers: dict[str, str],
) -> None:
    async with maker() as session:
        await store_prices(session, [current("Kalamna", TODAY, 3600)], source=AGMARKNET, now=NOW)
        await run_backfill(
            session,
            FakeArchive(
                {
                    "Orange": [
                        current("Kalamna", TODAY - timedelta(days=d), 3000 + d)
                        for d in (30, 60, 89)
                    ]
                }
            ),
            keyed(settings),
            NOW,
        )
    r = await api.get(
        "/v1/market/prices/history?crop=santra&market=Kalamna&variety=Nagpuri&grade=FAQ",
        headers=auth_headers,
    )
    assert r.status_code == 200, r.text
    assert [(d["day"], d["modal_rs_per_quintal"], d["source"]) for d in r.json()["days"]] == [
        ((TODAY - timedelta(days=89)).isoformat(), 3089, AGMARKNET),
        ((TODAY - timedelta(days=60)).isoformat(), 3060, AGMARKNET),
        ((TODAY - timedelta(days=30)).isoformat(), 3030, AGMARKNET),
        (TODAY.isoformat(), 3600, AGMARKNET),
    ]


@pytest.fixture
def waits(monkeypatch: pytest.MonkeyPatch) -> list[float]:
    """The retry pauses, recorded instead of slept."""
    seen: list[float] = []

    async def fake(seconds: float) -> None:
        seen.append(seconds)

    monkeypatch.setattr(backfill, "_wait", fake)
    return seen


async def test_an_unreachable_page_is_tried_again_before_giving_up(
    settings: Settings, waits: list[float]
) -> None:
    """VPS 2026-11-09: five fruits ended `source_unreachable` on one run while another run read
    them. A page is asked up to three times, with pauses, before the fruit counts as failed."""
    calls = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal calls
        calls += 1
        if calls < 3:
            raise httpx.ReadTimeout("slow", request=request)
        return httpx.Response(
            200, json={"total": 1, "records": [archive_row("Kalamna", TODAY, 3000)]}
        )

    s = keyed(settings)
    async with market_http(s, httpx.MockTransport(handler)) as http:
        rows = await archive_client(http, s).prices(commodity="Orange", since=TODAY)
    assert [r.market for r in rows] == ["Kalamna"]
    assert calls == 3
    assert waits == list(backfill.RETRY_WAITS)


async def test_three_failed_tries_are_a_market_error(
    settings: Settings, waits: list[float]
) -> None:
    calls = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal calls
        calls += 1
        return httpx.Response(503)

    s = keyed(settings)
    async with market_http(s, httpx.MockTransport(handler)) as http:
        with pytest.raises(MarketUnavailableError) as err:
            await archive_client(http, s).prices(commodity="Orange", since=TODAY)
    assert err.value.code == REASON_UNREACHABLE
    assert calls == 1 + len(backfill.RETRY_WAITS)


async def test_archive_pages_wait_longer_than_the_daily_pull(settings: Settings) -> None:
    seen: list[dict[str, float | None]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request.extensions["timeout"])
        return httpx.Response(200, json={"total": 0, "records": []})

    s = keyed(settings)
    async with market_http(s, httpx.MockTransport(handler)) as http:
        await archive_client(http, s).prices(commodity="Orange", since=TODAY)
    assert seen[0]["read"] == s.market_archive_timeout_seconds > s.market_timeout_seconds
