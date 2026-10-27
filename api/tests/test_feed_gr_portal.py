"""Addendum v1.4 §3 / §7: GR portal adapter contract tests against a recorded-style fixture.
No live network: httpx.MockTransport answers every request and counts them."""

from __future__ import annotations

from pathlib import Path

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.feed.gr_portal import (
    GrPortalAdapter,
    fetch_source_listings,
    parse_list_page,
)
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedSource
from bagmitra_api.feed.seed import seed_feed_sources

FIXTURE = (Path(__file__).parent / "fixtures" / "feed" / "gr_list_page.html").read_text("utf-8")
PORTAL = "https://gr.maharashtra.gov.in"
UA = "BagMitra-Feed/test"


class Portal:
    """Fake portal: per-path responses and a log of requested URLs."""

    def __init__(self, routes: dict[str, httpx.Response]) -> None:
        self.routes = routes
        self.calls: list[str] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.calls.append(request.url.path)
        assert request.headers["User-Agent"] == UA
        return self.routes.get(request.url.path, httpx.Response(404))


def adapter(portal: Portal, sleeps: list[float] | None = None) -> GrPortalAdapter:
    async def fake_sleep(seconds: float) -> None:
        (sleeps if sleeps is not None else []).append(seconds)

    return GrPortalAdapter(
        httpx.AsyncClient(transport=httpx.MockTransport(portal)),
        user_agent=UA,
        min_interval=5.0,
        sleep=fake_sleep,
        clock=lambda: 100.0,
    )


async def gr_source(session: AsyncSession, terms: str = "allowed") -> FeedSource:
    await seed_feed_sources(session)
    source = await session.scalar(select(FeedSource).where(FeedSource.key == "mh_gr_portal"))
    assert source is not None
    source.terms_status = terms
    return source


def test_parse_list_page_reads_rows_by_header() -> None:
    listings = parse_list_page(FIXTURE, PORTAL + "/search")
    assert [(g.code, g.published.isoformat()) for g in listings] == [
        ("202610261500000001", "2026-10-26"),
        ("202610241100000002", "2026-10-24"),
    ]
    assert listings[0].url == PORTAL + "/Upload/PDF/202610261500000001.pdf"
    assert listings[0].department is not None
    assert listings[0].department.startswith("Agriculture")
    assert listings[1].title.startswith("Relief for crop loss")


def test_parse_list_page_without_a_result_table() -> None:
    assert parse_list_page("<html><p>Service unavailable</p></html>", PORTAL) == []
    no_dept = (
        "<table><tr><th>Title</th><th>Code</th><th>Date</th><th>File</th></tr>"
        "<tr><td>T</td><td>C1</td><td>2026-10-01</td><td><a href='/a.pdf'>x</a></td></tr>"
        "<tr><td>short row</td></tr></table>"
    )
    [only] = parse_list_page(no_dept, PORTAL)
    assert only.department is None


async def test_refuses_without_allowed_terms(engine: AsyncEngine) -> None:
    portal = Portal({})
    async with async_sessionmaker(engine)() as session:
        for terms, status in (("unknown", "not_fetched"), ("disallowed", "disallowed")):
            source = await gr_source(session, terms)
            outcome = await fetch_source_listings(session, source, adapter(portal))
            assert outcome.status == "refused"
            assert source.fetch_status == status
            assert source.last_error == f"not fetched: terms_status is {terms}"
    assert portal.calls == []  # nothing at all was requested


async def test_ok_run_adds_in_review_official_items_and_is_polite(engine: AsyncEngine) -> None:
    pdf = httpx.Response(200, content=b"%PDF-1.4 fixture")
    portal = Portal(
        {
            "/robots.txt": httpx.Response(200, text="User-agent: *\nDisallow: /admin\n"),
            "/": httpx.Response(200, text=FIXTURE),
            "/Upload/PDF/202610261500000001.pdf": pdf,
        }
    )
    sleeps: list[float] = []
    async with async_sessionmaker(engine)() as session:
        source = await gr_source(session)
        outcome = await fetch_source_listings(session, source, adapter(portal, sleeps))
        assert (outcome.status, outcome.added) == ("ok", 2)
        assert source.fetch_status == "ok"
        assert source.last_ok_at is not None
        items = {i.external_id: i for i in await session.scalars(select(FeedItem))}
        first, second = items["202610261500000001"], items["202610241100000002"]
        assert first.status == second.status == "in_review"
        assert first.trust_level == "official"
        assert first.raw_hash is not None
        assert first.raw_bytes == len(b"%PDF-1.4 fixture")
        assert second.raw_hash is None  # its PDF answered 404: no hash, cannot publish yet
        langs = {t.item_id: t.lang for t in await session.scalars(select(FeedItemI18n))}
        assert langs[first.id] == "mr"
        assert langs[second.id] == "en"
        # A second pass adds nothing new (dedupe by the portal's unique code).
        again = await fetch_source_listings(session, source, adapter(portal), hash_documents=False)
        assert again.added == 0
    assert portal.calls[:2] == ["/robots.txt", "/"]
    assert sleeps == [5.0, 5.0, 5.0]  # every request after the first waited its turn


@pytest.mark.parametrize(
    ("routes", "status", "error"),
    [
        ({"/robots.txt": httpx.Response(404), "/": httpx.Response(404)}, "fetch_failed", "404"),
        ({"/robots.txt": httpx.Response(403)}, "fetch_failed", "HTTP 403 for robots.txt"),
        (
            {"/robots.txt": httpx.Response(200, text="User-agent: *\nDisallow: /\n")},
            "disallowed",
            "robots.txt disallows",
        ),
    ],
)
async def test_blocked_records_failure_once_and_never_retries(
    engine: AsyncEngine, routes: dict[str, httpx.Response], status: str, error: str
) -> None:
    portal = Portal(routes)
    async with async_sessionmaker(engine)() as session:
        source = await gr_source(session)
        outcome = await fetch_source_listings(session, source, adapter(portal))
        assert outcome.status == status
        assert source.fetch_status == status
        assert source.last_error is not None
        assert error in source.last_error
        calls = len(portal.calls)
        assert calls <= 2  # robots.txt and at most one list request, no retry
        skipped = await fetch_source_listings(session, source, adapter(portal))
        assert skipped.status == "skipped"
        assert len(portal.calls) == calls
        assert await session.scalar(select(FeedItem.id)) is None


async def test_network_errors_are_recorded(engine: AsyncEngine) -> None:
    def down(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectTimeout("timed out", request=request)

    gr = GrPortalAdapter(
        httpx.AsyncClient(transport=httpx.MockTransport(down)), user_agent=UA, min_interval=0
    )
    async with async_sessionmaker(engine)() as session:
        source = await gr_source(session)
        outcome = await fetch_source_listings(session, source, gr)
        assert outcome.status == "fetch_failed"
        assert source.last_error == "ConnectTimeout: timed out"
    assert await gr.document_hash(PORTAL + "/a.pdf") is None


async def test_document_hash_limits(monkeypatch: pytest.MonkeyPatch) -> None:
    portal = Portal(
        {"/big.pdf": httpx.Response(200, content=b"x" * 32), "/empty.pdf": httpx.Response(200)}
    )
    monkeypatch.setattr("bagmitra_api.feed.gr_portal.MAX_DOCUMENT_BYTES", 16)
    gr = adapter(portal)
    assert await gr.document_hash(PORTAL + "/big.pdf") is None
    assert await gr.document_hash(PORTAL + "/empty.pdf") is None
