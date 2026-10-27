"""Addendum v1.4 §2-§3 / G3: news ingestion from RSS / Atom feeds of news-tier sources.

Contract tests against fixtures; no live network (httpx.MockTransport answers every request
and logs it). Only headline + link + published_at + source are stored, never article text.
"""

from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.feed import news_job
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource
from bagmitra_api.feed.news import (
    MAX_FEED_BYTES,
    NewsFeedAdapter,
    UnsafeXmlError,
    entry_key,
    fetch_news_source,
    parse_feed,
    safe_parse,
)
from bagmitra_api.feed.seed import seed_feed_sources, source_seeds
from tests.test_feed_api import ADMIN, ADMIN_BASE, ai_box, api, ocr_box

__all__ = ["ai_box", "api", "ocr_box"]  # fixtures used here

FIXTURES = Path(__file__).parent / "fixtures" / "feed"
RSS = (FIXTURES / "news_rss.xml").read_bytes()
ATOM = (FIXTURES / "news_atom.xml").read_bytes()
HOST = "https://news.example"
UA = "BagMitra-Feed/test"
BODY_MARK = "ARTICLE BODY MUST NOT BE STORED"


class Server:
    def __init__(self, routes: dict[str, httpx.Response]) -> None:
        self.routes = routes
        self.calls: list[str] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.calls.append(request.url.path)
        assert request.headers["User-Agent"] == UA
        return self.routes.get(request.url.path, httpx.Response(404))


def adapter(server: Server, sleeps: list[float] | None = None) -> NewsFeedAdapter:
    async def fake_sleep(seconds: float) -> None:
        (sleeps if sleeps is not None else []).append(seconds)

    return NewsFeedAdapter(
        httpx.AsyncClient(transport=httpx.MockTransport(server)),
        user_agent=UA,
        min_interval=5.0,
        sleep=fake_sleep,
        clock=lambda: 100.0,
    )


def ok_server(feed: bytes = RSS) -> Server:
    return Server({"/robots.txt": httpx.Response(404), "/rss": httpx.Response(200, content=feed)})


async def news_source(
    session: AsyncSession, terms: str = "allowed", key: str = "test_rss", tier: str = "news"
) -> FeedSource:
    source = FeedSource(
        id=uuid.uuid4(),
        key=key,
        name=f"{key} (test)",
        url=f"{HOST}/rss",
        tier=tier,
        terms_status=terms,
        fetch_method="rss",
        fetch_status="not_fetched",
    )
    session.add(source)
    await session.flush()
    return source


# --- parsing -------------------------------------------------------------------------------


def test_parse_rss_keeps_headline_link_date_only() -> None:
    entries = parse_feed(RSS, "https://pib.gov.in/rss")
    assert [(e.title, e.link) for e in entries] == [
        (
            "Centre releases PM-KISAN instalment to farmers",
            "https://pib.gov.in/PressReleasePage.aspx?PRID=1000001",
        ),
        ("कृषी यांत्रिकीकरण अभियानाचा आढावा", "https://pib.gov.in/PressReleasePage.aspx?PRID=1000002"),
        (
            "Same release listed twice",
            "https://pib.gov.in/PressReleasePage.aspx?PRID=1000001",
        ),
    ]
    first, second, _ = entries
    assert first.published == datetime(2026, 10, 26, 5, 0, tzinfo=UTC)
    assert second.published == datetime(2026, 10, 25, 9, 0, tzinfo=UTC)
    assert first.guid == "PRID-1000001"
    assert second.guid is None
    assert entry_key(first) == entry_key(entries[2])  # same guid: one item
    assert entry_key(second) != entry_key(first)
    assert len(entry_key(first)) == 64
    assert not any(BODY_MARK in repr(e) for e in entries)


def test_parse_atom() -> None:
    entries = parse_feed(ATOM, "https://dept.example/feed")
    assert [(e.title, e.link, e.guid) for e in entries] == [
        ("Crop insurance window opens", "https://dept.example/news/1", "urn:example:news:1"),
        ("Soil health cards camp", "https://dept.example/news/2", "urn:example:news:2"),
    ]
    assert entries[0].published == datetime(2026, 10, 26, 0, 30, tzinfo=UTC)
    assert entries[1].published == datetime(2026, 10, 20, tzinfo=UTC)  # naive: read as UTC


def test_rss_date_formats() -> None:
    feed = (
        b"<rss><channel>"
        b"<item><title>A</title><link>https://x.example/a</link>"
        b"<pubDate>2026-10-01T00:00:00Z</pubDate></item>"
        b"<item><title>B</title><link>https://x.example/b</link>"
        b"<pubDate>Thu, 01 Oct 2026 00:00:00</pubDate></item>"
        b"<item><title>C</title><link>https://x.example/c</link><pubDate>soon</pubDate></item>"
        b"</channel></rss>"
    )
    assert [e.title for e in parse_feed(feed, HOST)] == ["A", "B"]
    assert parse_feed(b"<rss/>", HOST) == []  # no channel: nothing


def test_title_is_capped_and_cleaned() -> None:
    long = "x" * 900
    feed = (
        f"<rss><channel><item><title>&lt;p&gt;{long}&lt;/p&gt; &amp;amp; more</title>"
        "<link>https://x.example/a</link><pubDate>2026-10-01T00:00:00Z</pubDate></item>"
        "</channel></rss>"
    ).encode()
    [entry] = parse_feed(feed, HOST)
    assert len(entry.title) == 500
    assert "<p>" not in entry.title


@pytest.mark.parametrize(
    "xml",
    [
        # Billion laughs: entity expansion bomb.
        b'<?xml version="1.0"?><!DOCTYPE lolz [<!ENTITY lol "lol">'
        b'<!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">]>'
        b"<rss><channel><item><title>&lol2;</title></item></channel></rss>",
        # External entity (XXE).
        b'<?xml version="1.0"?><!DOCTYPE r [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>'
        b"<rss><channel><item><title>&xxe;</title></item></channel></rss>",
        # External DTD.
        b'<?xml version="1.0"?><!DOCTYPE rss SYSTEM "http://evil.example/x.dtd"><rss/>',
        # Parameter entity.
        b'<!DOCTYPE r [<!ENTITY % p SYSTEM "http://evil.example/p">%p;]><rss/>',
        # Undefined entity without a DTD.
        b"<rss><channel><title>&undefined;</title></channel></rss>",
        # Not well-formed.
        b"<rss><channel>",
        # Not a feed.
        b"<html><body>Service unavailable</body></html>",
    ],
)
def test_unsafe_or_unknown_xml_is_refused(xml: bytes) -> None:
    with pytest.raises(UnsafeXmlError):
        parse_feed(xml, HOST)


def test_oversized_feed_is_refused() -> None:
    with pytest.raises(UnsafeXmlError, match="too large"):
        safe_parse(b" " * (MAX_FEED_BYTES + 1))


def test_namespaced_attributes_are_read() -> None:
    root = safe_parse(b'<a xmlns:x="urn:x" x:k="v" k2="w"><b>t</b>tail</a>')
    assert root.attrs == {"{urn:x}k": "v", "k2": "w"}
    assert root.children[0].tag == "b"


# --- seeded source -------------------------------------------------------------------------


def test_pib_news_source_is_seeded_unknown_and_marked_unverified() -> None:
    [pib] = [s for s in source_seeds() if s["key"] == "pib_agriculture_news"]
    assert pib["tier"] == "news"
    assert pib["fetch_method"] == "rss"
    assert "[UV]" in pib["notes"]
    assert "terms_status" not in pib  # seeding always records unknown


# --- fetching ------------------------------------------------------------------------------


async def test_refused_without_allowed_terms_or_news_tier(engine: AsyncEngine) -> None:
    server = ok_server()
    async with async_sessionmaker(engine)() as session:
        await seed_feed_sources(session)
        pib = await session.scalar(
            select(FeedSource).where(FeedSource.key == "pib_agriculture_news")
        )
        assert pib is not None
        assert pib.terms_status == "unknown"
        outcome = await fetch_news_source(session, pib, adapter(server))
        assert outcome.status == "refused"
        assert pib.last_error == "not fetched: terms_status is unknown"
        bad = await news_source(session, "disallowed")
        assert (await fetch_news_source(session, bad, adapter(server))).status == "refused"
        assert bad.fetch_status == "disallowed"
        official = await news_source(session, key="official_rss", tier="official")
        outcome = await fetch_news_source(session, official, adapter(server))
        assert (outcome.status, outcome.error) == ("refused", "not a news-tier source")
    assert server.calls == []  # nothing at all was requested


async def test_ok_run_stores_headline_link_date_source_only(engine: AsyncEngine) -> None:
    server = ok_server()
    sleeps: list[float] = []
    async with async_sessionmaker(engine)() as session:
        source = await news_source(session)
        outcome = await fetch_news_source(session, source, adapter(server, sleeps))
        assert (outcome.status, outcome.added) == ("ok", 2)
        assert server.calls == ["/robots.txt", "/rss"]
        assert sleeps == [5.0]  # the second request waited its turn
        assert source.fetch_status == "ok"
        assert source.last_ok_at is not None
        items = list(await session.scalars(select(FeedItem).order_by(FeedItem.published_at)))
        assert [i.url for i in items] == [
            f"{HOST}/PressReleasePage.aspx?PRID=1000002",
            "https://pib.gov.in/PressReleasePage.aspx?PRID=1000001",
        ]
        for item in items:
            assert (item.type, item.trust_level, item.status) == ("news", "news", "in_review")
            assert item.source_id == source.id
            assert item.extracted_text is None
            assert item.raw_hash is None
            assert item.raw_bytes is None
            assert item.external_id is not None
            assert len(item.external_id) == 64
        texts = list(await session.scalars(select(FeedItemI18n)))
        assert {(t.lang, t.summary) for t in texts} == {("en", None), ("mr", None)}
        events = list(await session.scalars(select(FeedReviewEvent)))
        assert {e.kind for e in events} == {"created"}
        assert {e.detail["via"] for e in events} == {"news_feed"}
        stored = json.dumps(
            [
                [str(getattr(row, c.name)) for c in type(row).__table__.columns]
                for row in [*items, *texts, *events]
            ]
        )
        assert BODY_MARK not in stored
        assert ".jpg" not in stored  # no images

        # Second run: nothing new (dedupe by guid / link hash).
        again = await fetch_news_source(session, source, adapter(server))
        assert (again.status, again.added) == ("ok", 0)


async def test_same_link_from_another_news_source_is_not_added_twice(
    engine: AsyncEngine,
) -> None:
    async with async_sessionmaker(engine)() as session:
        first = await news_source(session, key="first")
        second = await news_source(session, key="second")
        assert (await fetch_news_source(session, first, adapter(ok_server()))).added == 2
        assert (await fetch_news_source(session, second, adapter(ok_server()))).added == 0


async def test_failure_is_recorded_once_and_not_retried(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        source = await news_source(session)
        server = Server({"/robots.txt": httpx.Response(404), "/rss": httpx.Response(503)})
        outcome = await fetch_news_source(session, source, adapter(server))
        assert outcome.status == "fetch_failed"
        assert source.fetch_status == "fetch_failed"
        assert source.last_error == "HTTP 503 from news.example"
        server.calls.clear()
        outcome = await fetch_news_source(session, source, adapter(server))
        assert outcome.status == "skipped"
        assert server.calls == []


@pytest.mark.parametrize(
    ("routes", "status", "error"),
    [
        (
            {
                "/robots.txt": httpx.Response(200, text="User-agent: *\nDisallow: /rss\n"),
                "/rss": httpx.Response(200, content=RSS),
            },
            "disallowed",
            "robots.txt disallows /rss",
        ),
        (
            {
                "/robots.txt": httpx.Response(404),
                "/rss": httpx.Response(
                    200, content=b'<!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]><r/>'
                ),
            },
            "fetch_failed",
            "unsafe or unreadable feed: DTD / entity declarations are refused",
        ),
        (
            {
                "/robots.txt": httpx.Response(404),
                "/rss": httpx.Response(200, content=b"<rss>" + b" " * MAX_FEED_BYTES),
            },
            "fetch_failed",
            "feed larger than 2097152 bytes",
        ),
    ],
)
async def test_blocked_or_unsafe_feed(
    engine: AsyncEngine, routes: dict[str, httpx.Response], status: str, error: str
) -> None:
    async with async_sessionmaker(engine)() as session:
        source = await news_source(session)
        outcome = await fetch_news_source(session, source, adapter(Server(routes)))
        assert (outcome.status, source.fetch_status, source.last_error) == (status, status, error)
        assert list(await session.scalars(select(FeedItem))) == []


async def test_network_error_is_fetch_failed(engine: AsyncEngine) -> None:
    def broken(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("no route", request=request)

    async with async_sessionmaker(engine)() as session:
        source = await news_source(session)
        news = NewsFeedAdapter(
            httpx.AsyncClient(transport=httpx.MockTransport(broken)), user_agent=UA, min_interval=0
        )
        outcome = await fetch_news_source(session, source, news)
        assert outcome.status == "fetch_failed"
        assert source.last_error is not None
        assert source.last_error.startswith("ConnectError")


# --- job -----------------------------------------------------------------------------------


async def test_job_fetches_only_allowed_news_sources(engine: AsyncEngine) -> None:
    server = ok_server(ATOM)
    async with async_sessionmaker(engine)() as session:
        await news_source(session)  # allowed news source
        await news_source(session, key="official_allowed", tier="official")
        summary = await news_job.run_news(session, adapter(server))
        await session.commit()
    data = json.loads(summary.to_json())
    by_key = {s["key"]: s for s in data["sources"]}
    assert data["added"] == 2
    assert by_key["test_rss"] == {"key": "test_rss", "status": "ok", "added": 2, "error": None}
    assert by_key["pib_agriculture_news"]["status"] == "refused"  # seeded by the job, unknown
    assert "official_allowed" not in by_key
    assert "mh_gr_portal" not in by_key
    assert server.calls == ["/robots.txt", "/rss"]


# --- review: our own summary, then publish as "News - not official" ------------------------


async def test_admin_writes_own_summary_then_publishes_as_news(
    api: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    async with async_sessionmaker(engine)() as session:
        source = await news_source(session, key="review_rss")
        await fetch_news_source(session, source, adapter(ok_server()))
        await session.commit()
        item = await session.scalar(select(FeedItem).where(FeedItem.url.like("%PRID=1000001")))
        assert item is not None
        item_id = str(item.id)
    queue = (await api.get(f"{ADMIN_BASE}/items", headers=ADMIN)).json()
    assert item_id in {i["id"] for i in queue["items"]}
    for lang, title, summary in (
        ("en", "PM-KISAN instalment released", "The Centre released an instalment. Read more."),
        ("mr", "पीएम किसान हप्ता जारी", "केंद्राने हप्ता जारी केला. अधिक वाचा."),
    ):
        res = await api.put(
            f"{ADMIN_BASE}/items/{item_id}/texts/{lang}",
            json={"title": title, "summary": summary},
            headers=ADMIN,
        )
        assert res.status_code == 200, res.text
    res = await api.post(f"{ADMIN_BASE}/items/{item_id}/approve", json={}, headers=ADMIN)
    assert res.status_code == 200, res.text
    res = await api.post(f"{ADMIN_BASE}/items/{item_id}/publish", headers=ADMIN)
    assert res.status_code == 200, res.text
    feed: dict[str, Any] = (
        await api.get("/v1/feed", params={"type": "news", "lang": "mr"}, headers=auth_headers)
    ).json()
    [shown] = feed["items"]
    assert (shown["trust"], shown["title"]) == ("news", "पीएम किसान हप्ता जारी")
    assert shown["url"] == "https://pib.gov.in/PressReleasePage.aspx?PRID=1000001"
