"""Q164: the read-only diagnostic lists the commodity names of the Agmarknet daily feed and
checks each configured name, looking a missing one up in the 90-day archive. HTTP is mocked:
no request leaves the test."""

from __future__ import annotations

from datetime import date
from typing import Any

import httpx
import pytest
from pydantic import SecretStr

from bagmitra_api.core.settings import Settings
from bagmitra_api.market.agmarknet import PAGE_LIMIT, MarketUnavailableError
from bagmitra_api.market.list_commodities import feed_names, parse_args, report

TODAY = date(2026, 11, 15)


def settings(**extra: Any) -> Settings:
    extra.setdefault(
        "market_commodities",
        {"santra": ["Orange"], "cotton": ["Cotton"], "linseed": ["Linseed"], "tur": ["Tur"]},
    )
    return Settings(
        market_api_key=SecretStr("k"),
        market_api_base_url="https://x.test",
        market_resource_id="daily",
        market_archive_resource_id="archive",
        **extra,
    )


def rows(*names: str) -> list[dict[str, str]]:
    return [{"commodity": n, "market": "Akola", "modal_price": "100"} for n in names]


class Feed:
    """Daily feed of `daily` rows (paged); archive answers from `archive` (name -> rows)."""

    def __init__(self, daily: list[dict[str, str]], archive: dict[str, int]) -> None:
        self.daily = daily
        self.archive = archive
        self.requests: list[httpx.Request] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        q = request.url.params
        if request.url.path.endswith("/daily"):
            assert "filters[commodity]" not in q
            off = int(q["offset"])
            return httpx.Response(200, json={"records": self.daily[off : off + PAGE_LIMIT]})
        name = q["filters[Commodity]"]
        # Free-text match: a longer name comes back too; only the exact one counts.
        recs = [{"Commodity": name}] * self.archive.get(name, 0) + [{"Commodity": name + " X"}]
        return httpx.Response(200, json={"records": recs})


async def run(feed: Feed, **kw: Any) -> list[str]:
    async with httpx.AsyncClient(transport=httpx.MockTransport(feed)) as http:
        return await report(
            http, settings(), state=kw.get("state"), max_pages=kw.get("max_pages", 5), today=TODAY
        )


async def test_lists_feed_names_and_checks_each_configured_name() -> None:
    feed = Feed(rows("Orange", "Orange", "Cotton", "Soyabean"), {"Linseed": 3})
    out = "\n".join(await run(feed))
    assert "Daily feed (India): 4 rows, 3 commodity names, 1 page(s)" in out
    assert "     2  Orange" in out
    assert "     1  Soyabean" in out
    assert "'Cotton': 1 rows in the daily feed" in out
    assert "'Linseed': not in the daily feed; in the 90-day archive (3 rows" in out
    assert "'Tur': not in the daily feed; NOT FOUND in the 90-day archive either" in out
    archive = [r for r in feed.requests if r.url.path.endswith("/archive")]
    assert [r.url.params["filters[Commodity]"] for r in archive] == ["Linseed", "Tur"]
    assert archive[0].url.params["range[Arrival_Date][gte]"] == "17/08/2026"


async def test_pages_until_a_short_page_and_says_when_cut_short() -> None:
    many = rows(*(["Wheat"] * PAGE_LIMIT + ["Maize"]))
    async with httpx.AsyncClient(transport=httpx.MockTransport(Feed(many, {}))) as http:
        full = await feed_names(http, settings(), state=None, max_pages=5)
        cut = await feed_names(http, settings(), state=None, max_pages=1)
    assert (full.pages, full.truncated, full.counts["Maize"]) == (2, False, 1)
    assert (cut.pages, cut.truncated, cut.counts["Maize"]) == (1, True, 0)
    out = "\n".join(await run(Feed(many, {}), max_pages=1))
    assert "raise it to see every name" in out


async def test_state_filter_and_unreadable_feed() -> None:
    feed = Feed(rows("Orange"), {})
    out = await run(feed, state="Maharashtra")
    assert out[0].startswith("Daily feed (Maharashtra)")
    assert feed.requests[0].url.params["filters[state]"] == "Maharashtra"

    def down(request: httpx.Request) -> httpx.Response:
        del request
        return httpx.Response(502)

    async with httpx.AsyncClient(transport=httpx.MockTransport(down)) as http:
        with pytest.raises(MarketUnavailableError):
            await report(http, settings(), state=None, max_pages=1, today=TODAY)


def test_args() -> None:
    a = parse_args(["--state", "Maharashtra", "--max-pages", "9"])
    assert (a.state, a.max_pages) == ("Maharashtra", 9)
    assert parse_args([]).max_pages == 60
