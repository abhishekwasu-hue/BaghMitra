"""Owner 2026-11-12 (OPEN_QUESTIONS Q145): "many farming articles must have appeared in the
last month, on other fruits too; find them". Each news source with a backfill plan is read back
~30 days once, capped per run and resumed from its cursor, on the scheduled runs themselves.
Contract tests against feeds and sitemaps recorded from a GitHub runner on 2026-11-12
(tests/fixtures/feed/*_recorded.*); no live network."""

from __future__ import annotations

import json
import re
from collections.abc import Callable
from datetime import UTC, datetime
from pathlib import Path

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.feed import news_job
from bagmitra_api.feed.backfill import (
    BACKFILL_DAYS,
    backfill_news_source,
    page_headline,
    page_url,
    sitemap_links,
)
from bagmitra_api.feed.models import FeedItem, FeedSource
from bagmitra_api.feed.news import NewsFeedAdapter, fetch_news_source, parse_feed
from bagmitra_api.feed.seed import seed_feed_sources

FIX = Path(__file__).parent / "fixtures" / "feed"
UA = "BagMitra-Feed/test"
DAILY = (FIX / "agrowon_daily_sitemap_recorded.xml").read_bytes()
ARTICLE = (FIX / "agrowon_article_recorded.html").read_bytes()
NEWS_SITEMAP = (FIX / "agrowon_news_sitemap_recorded.xml").read_bytes()
RSS = (FIX / "businessline_rss_recorded.xml").read_bytes()
NOW = datetime(2026, 11, 12, 12, tzinfo=UTC)

Route = Callable[[httpx.Request], httpx.Response]


class Web:
    """Fake web: a handler per path pattern; logs every requested path (and query)."""

    def __init__(self, routes: dict[str, Route]) -> None:
        self.routes = routes
        self.calls: list[str] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        assert request.headers["User-Agent"] == UA
        target = request.url.path + (f"?{request.url.query.decode()}" if request.url.query else "")
        self.calls.append(target)
        for pattern, handler in self.routes.items():
            if re.fullmatch(pattern, request.url.path):
                return handler(request)
        return httpx.Response(404)


def adapter(web: Web) -> NewsFeedAdapter:
    async def no_sleep(_: float) -> None:
        return None

    return NewsFeedAdapter(
        httpx.AsyncClient(transport=httpx.MockTransport(web)),
        user_agent=UA,
        min_interval=5.0,
        sleep=no_sleep,
        clock=lambda: 100.0,
    )


def ok(body: bytes) -> Route:
    return lambda _request: httpx.Response(200, content=body)


async def seeded(session: AsyncSession, key: str) -> FeedSource:
    await seed_feed_sources(session)
    row = await session.scalar(select(FeedSource).where(FeedSource.key == key))
    assert row is not None
    row.fetch_status = "ok"  # the regular run read the newest feed first
    return row


# --- parsing the recorded material ------------------------------------------------------------


def test_recorded_feeds_and_news_sitemaps_parse() -> None:
    counts = {}
    for name in (
        "businessline_rss_recorded.xml",
        "krishijagran_rss_recorded.xml",
        "pib_rss_recorded.xml",
        "agrowon_news_sitemap_recorded.xml",
        "kisantak_news_sitemap_recorded.xml",
    ):
        entries = parse_feed((FIX / name).read_bytes(), "https://example.org/")
        counts[name] = (len(entries), sum(e.published is None for e in entries))
    assert counts == {
        "businessline_rss_recorded.xml": (2, 0),
        "krishijagran_rss_recorded.xml": (2, 0),
        "pib_rss_recorded.xml": (2, 2),  # PIB items carry no date: first-seen
        "agrowon_news_sitemap_recorded.xml": (2, 0),
        "kisantak_news_sitemap_recorded.xml": (2, 0),
    }
    [first, _] = parse_feed(NEWS_SITEMAP, "https://agrowon.esakal.com/")
    assert first.title.startswith("Agrowon Diwali Article")
    assert first.published == datetime(2026, 11, 12, 9, 30, tzinfo=UTC)
    assert first.link.startswith("https://agrowon.esakal.com/agro-special/")


def test_daily_sitemap_links_and_page_headline() -> None:
    assert sitemap_links(DAILY) == [
        "https://agrowon.esakal.com/agro-special/rabi-jowar-seed-subsidy-2026-27-rat16",
        "https://agrowon.esakal.com/ampstories/web-stories/instant-guava-pickle-recipe-make-"
        "tangy-sweet-and-sour-pickle-in-just-10-minutes-aak11",
    ]
    found = page_headline(ARTICLE)
    assert found is not None
    title, published = found
    assert title.startswith("Jowar Seed Subsidy Scheme: रब्बी ज्वारीच्या बियाणे")
    assert published == datetime(2026, 10, 20, 20, 0, tzinfo=UTC)
    assert page_headline(b"<html><head><title>No meta</title></head></html>") is None
    with_meta = (
        b'<meta property="og:title" content="A &amp; B"/>'
        b'<meta property="article:published_time" content="2026-11-01T10:00:00+05:30">'
    )
    assert page_headline(with_meta) == ("A & B", datetime(2026, 11, 1, 4, 30, tzinfo=UTC))


def test_page_url_sets_the_page_parameter() -> None:
    assert (
        page_url("https://mahasamvad.in/feed/", "paged", 2) == "https://mahasamvad.in/feed/?paged=2"
    )
    assert page_url("https://x.in/feed/?lang=mr&paged=1", "paged", 3) == (
        "https://x.in/feed/?lang=mr&paged=3"
    )


# --- daily sitemaps (Agrowon) -----------------------------------------------------------------


async def test_daily_sitemaps_read_each_new_page_once_and_skip_web_stories(
    engine: AsyncEngine,
) -> None:
    web = Web(
        {
            r"/robots.txt": lambda _r: httpx.Response(404),
            r"/sitemap/sitemap-daily-\d{4}-\d{2}-\d{2}\.xml": ok(DAILY),
            r"/agro-special/.*": ok(ARTICLE),
        }
    )
    async with async_sessionmaker(engine)() as session:
        agrowon = await seeded(session, "agrowon_mr")
        outcome = await backfill_news_source(session, agrowon, adapter(web), NOW)
        assert (outcome.status, outcome.added) == ("done", 1)
        assert outcome.pages == BACKFILL_DAYS + 1  # today and the 30 days before
        [item] = list(await session.scalars(select(FeedItem)))
        assert item.type == "news"
        assert item.status == "in_review"
        assert item.published_at.replace(tzinfo=UTC) == datetime(2026, 10, 20, 20, tzinfo=UTC)
        assert agrowon.backfill_done_at is not None
        assert agrowon.backfill_cursor == "day:2026-10-13"
        again = await backfill_news_source(session, agrowon, adapter(web), NOW)
        assert (again.status, again.added) == ("done", 0)
    pages = [c for c in web.calls if c.startswith("/agro-special/")]
    assert len(pages) == 1  # the same link on every day's sitemap is read once
    assert not any("/ampstories/" in c for c in web.calls)
    assert web.calls[:2] == ["/robots.txt", "/sitemap/sitemap-daily-2026-11-12.xml"]


async def test_a_page_older_than_the_window_is_not_added(engine: AsyncEngine) -> None:
    web = Web(
        {
            r"/robots.txt": lambda _r: httpx.Response(404),
            r"/sitemap/.*": ok(DAILY),
            r"/agro-special/.*": ok(ARTICLE),
        }
    )
    later = datetime(2026, 12, 15, tzinfo=UTC)  # the recorded page is then 55 days old
    async with async_sessionmaker(engine)() as session:
        agrowon = await seeded(session, "agrowon_mr")
        outcome = await backfill_news_source(session, agrowon, adapter(web), later)
        assert (outcome.status, outcome.added) == ("done", 0)


# --- WordPress feed pages (Mahasamvad) ---------------------------------------------------------


def rss_page(page: int, n: int = 2) -> bytes:
    """The recorded BusinessLine items with page-specific links (n per page)."""
    text = RSS.decode()
    items = re.findall(r"<item>.*?</item>", text, re.S)
    head, tail = text[: text.index("<item>")], "</channel></rss>"
    body = []
    for i in range(n):
        item = items[i % len(items)].replace("/article", f"/p{page}-{i}/article")
        body.append(item.replace("article-", f"article-p{page}-{i}-"))
    return (head + "".join(body) + tail).encode()


def paged(max_page: int) -> Route:
    def handler(request: httpx.Request) -> httpx.Response:
        page = int(request.url.params.get("paged", "1"))
        if page > max_page:
            return httpx.Response(404)
        return httpx.Response(200, content=rss_page(page))

    return handler


async def test_feed_pages_are_capped_per_run_and_resumed(engine: AsyncEngine) -> None:
    web = Web({r"/robots.txt": lambda _r: httpx.Response(404), r"/feed/": paged(4)})
    when = datetime(2026, 11, 12, tzinfo=UTC)  # the recorded items are a day old
    async with async_sessionmaker(engine)() as session:
        mahasamvad = await seeded(session, "mahasamvad_news")
        first = await backfill_news_source(session, mahasamvad, adapter(web), when, cap=3)
        assert (first.status, first.added) == ("partial", 3)
        assert mahasamvad.backfill_done_at is None
        assert mahasamvad.backfill_cursor == "page:2"
        second = await backfill_news_source(session, mahasamvad, adapter(web), when, cap=4)
        # Page 3's second item and page 4's two; page 5 is missing: the end.
        assert (second.status, second.added) == ("done", 3)
        assert second.error is not None
        assert "404" in second.error
        assert mahasamvad.backfill_done_at == when
        assert len(list(await session.scalars(select(FeedItem)))) == 6
    assert "/feed/?paged=2" in web.calls
    assert web.calls.count("/feed/?paged=2") == 1  # resumed after the cursor


async def test_sources_without_a_plan_or_not_yet_read_are_left(engine: AsyncEngine) -> None:
    web = Web({})
    async with async_sessionmaker(engine)() as session:
        kj = await seeded(session, "krishijagran_en")
        assert (await backfill_news_source(session, kj, adapter(web), NOW)).status == (
            "not_planned"
        )
        agrowon = await seeded(session, "agrowon_mr")
        agrowon.fetch_status = "fetch_failed"
        assert (await backfill_news_source(session, agrowon, adapter(web), NOW)).status == "skipped"
    assert web.calls == []


# --- regular run: news sitemaps and skipped paths -----------------------------------------------


async def test_regular_run_reads_a_news_sitemap_without_web_stories(engine: AsyncEngine) -> None:
    web = Web(
        {r"/robots.txt": lambda _r: httpx.Response(404), r"/news_sitemap.xml": ok(NEWS_SITEMAP)}
    )
    async with async_sessionmaker(engine)() as session:
        agrowon = await seeded(session, "agrowon_mr")
        outcome = await fetch_news_source(session, agrowon, adapter(web))
        assert (outcome.status, outcome.added) == ("ok", 1)  # the web story is skipped
        [item] = list(await session.scalars(select(FeedItem)))
        assert item.url.startswith("https://agrowon.esakal.com/agro-special/")


async def test_news_job_reports_the_backfill(engine: AsyncEngine) -> None:
    web = Web(
        {
            r"/robots.txt": lambda _r: httpx.Response(404),
            r"/news_sitemap.xml": ok(NEWS_SITEMAP),
            r"/sitemap/.*": ok(DAILY),
            r"/agro-special/.*": ok(ARTICLE),
        }
    )
    async with async_sessionmaker(engine)() as session:
        summary = await news_job.run_news(session, adapter(web), NOW)
        await session.commit()
    data = json.loads(summary.to_json())
    [agrowon] = [b for b in data["backfill"] if b["key"] == "agrowon_mr"]
    assert (agrowon["status"], agrowon["added"]) == ("done", 1)
    assert data["added"] >= 2  # one from the news sitemap, one from the daily sitemaps


async def test_regular_run_skips_entries_a_month_older_than_the_feed(engine: AsyncEngine) -> None:
    """Krishi Jagran's feed reached back to 2026-08-19 when recorded (99 items): only the 30
    days before its newest entry are added."""
    old = RSS.replace(b"Wed, 11 Nov 2026 21:55:05 +0530", b"Fri, 02 Oct 2026 21:55:05 +0530")
    assert old != RSS
    web = Web({r"/robots.txt": lambda _r: httpx.Response(404), r"/.*": ok(old)})
    async with async_sessionmaker(engine)() as session:
        business = await seeded(session, "businessline_agri")
        outcome = await fetch_news_source(session, business, adapter(web))
        assert (outcome.status, outcome.added) == ("ok", 1)
