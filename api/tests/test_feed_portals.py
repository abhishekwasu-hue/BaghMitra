"""Owner 2026-11-12 (OPEN_QUESTIONS Q145): the official portals are read by the portal job and
their documents go through the AI classify / article / scheme-card path with the existing
output checks. Contract tests against pages recorded from a GitHub runner on 2026-11-12
(tests/fixtures/feed/*_recorded.*, trimmed); no live network: httpx.MockTransport answers
every request and logs it."""

from __future__ import annotations

import copy
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import AiUnavailableError, Classification, Summary
from bagmitra_api.feed.article import ArticleSet, parse_articles
from bagmitra_api.feed.gr_portal import GrPortalAdapter, parse_list_page, robots_allows
from bagmitra_api.feed.knowledge import scheme_topics
from bagmitra_api.feed.models import (
    FeedItem,
    FeedItemI18n,
    FeedReviewEvent,
    FeedSchemeCard,
    FeedSource,
)
from bagmitra_api.feed.official_items import write_official_items
from bagmitra_api.feed.output_check import NOT_STATED
from bagmitra_api.feed.portal_job import (
    READERS,
    fetch_portal,
    run_portals,
    scheme_document,
    scheme_listings,
)
from bagmitra_api.feed.seed import seed_feed_sources, source_seeds
from tests.test_feed_article import SOURCE, payload

FIX = Path(__file__).parent / "fixtures" / "feed"
UA = "BagMitra-Feed/test"
GR_PAGE = (FIX / "gr_portal_recorded.html").read_bytes()
KRISHI_PAGE = (FIX / "krishi_gr_recorded.html").read_bytes()
MAHADBT_LIST = (FIX / "mahadbt_farmer_recorded.html").read_bytes()
MAHADBT_SCHEME = (FIX / "mahadbt_scheme_recorded.html").read_bytes()
GR_PDF = "/Farmer/PDF/Scheme-BhausahebPhundkarFalbaagLagvadYojana.pdf"
DOC = f"<html><body><h1>शासन निर्णय</h1><p>{SOURCE}</p></body></html>"
HTML = {"content-type": "text/html; charset=utf-8"}


class Site:
    """Fake web: per-path responses (any host) and a log of requested paths."""

    def __init__(self, routes: dict[str, httpx.Response]) -> None:
        self.routes = {"/robots.txt": httpx.Response(404), **routes}
        self.calls: list[str] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        assert request.headers["User-Agent"] == UA
        path = request.url.path
        self.calls.append(path)
        return self.routes.get(path, httpx.Response(404))


def adapter(site: Site, sleeps: list[float] | None = None) -> GrPortalAdapter:
    async def fake_sleep(seconds: float) -> None:
        (sleeps if sleeps is not None else []).append(seconds)

    return GrPortalAdapter(
        httpx.AsyncClient(transport=httpx.MockTransport(site)),
        user_agent=UA,
        min_interval=5.0,
        sleep=fake_sleep,
        clock=lambda: 100.0,
    )


class FakeAi:
    """Classifier, summariser and article writer; counts the calls."""

    def __init__(
        self,
        kind: str = "scheme",
        relevant: bool = True,
        article: dict[str, Any] | None = None,
        fields: dict[str, dict[str, str | None]] | None = None,
        fail: bool = False,
    ) -> None:
        self.kind, self.relevant, self.fail = kind, relevant, fail
        self.article = article
        self.fields = fields or {
            "who_benefits": {"value": "संत्रा उत्पादकांसाठी", "page": "p. 1"},
            "amount": {"value": "₹ ६,०००", "page": "p. 1"},
            "deadline": {"value": "३० नोव्हेंबर २०२६", "page": "p. 1"},
        }
        self.calls: list[str] = []

    async def classify(self, text: str) -> Classification:
        assert text
        self.calls.append("classify")
        if self.fail:
            raise AiUnavailableError("HTTP 529")
        return Classification(self.relevant, self.kind, ["new_scheme", "deadline"])

    async def summarise(self, text: str) -> Summary:
        assert text
        self.calls.append("summarise")
        fields = {
            name: self.fields.get(name, {"value": NOT_STATED, "page": None})
            for name in ("scheme_name", "who_benefits", "amount", "deadline")
        }
        return Summary("Orange orchard scheme", "Help for orange growers.", fields)

    async def write_article(self, text: str, *, source_url: str) -> ArticleSet:
        assert text
        self.calls.append("write_article")
        data = copy.deepcopy(self.article) if self.article is not None else payload()
        for lang in ("mr", "hi", "en"):
            if data.get("lang"):
                data["lang"][lang]["sources"] = [{"title": "GR", "url": source_url}]
        return parse_articles(data)


def settings(**extra: Any) -> Settings:
    return Settings(environment="test", **extra)


async def source(session: AsyncSession, key: str, terms: str = "allowed") -> FeedSource:
    await seed_feed_sources(session)
    row = await session.scalar(select(FeedSource).where(FeedSource.key == key))
    assert row is not None
    row.terms_status = terms
    return row


# --- readers on the recorded pages ------------------------------------------------------------


def test_gr_portal_recorded_table_is_read_by_its_marathi_headers() -> None:
    listings = parse_list_page(
        GR_PAGE.decode(), "https://gr.maharashtra.gov.in/1145/Government-Resolutions"
    )
    assert [(g.code, g.published.isoformat(), g.numbered) for g in listings] == [
        ("202611121517579608", "2026-11-12", True),
        ("202611121259475834", "2026-11-12", True),
    ]
    assert listings[0].department == "उच्च व तंत्र शिक्षण विभाग"
    assert listings[0].url == (
        "https://gr.maharashtra.gov.in/Site/Upload/Government%20Resolutions/Marathi/"
        "202611121517579608.pdf"
    )


def test_agriculture_commissionerate_table_has_no_code_column() -> None:
    base = "https://krishi.maharashtra.gov.in/Site/Common/ViewGr.aspx?Doctype=x?MenuID=2952"
    listings = parse_list_page(KRISHI_PAGE.decode(), base)
    assert [(g.published.isoformat(), g.numbered) for g in listings] == [
        ("2026-09-24", False),
        ("2026-07-08", False),
        ("2026-07-01", False),
    ]
    assert listings[1].title.startswith("सुधारित प्रधानमंत्री पीक विमा योजना")
    assert listings[1].url.startswith("https://krishi.maharashtra.gov.in/Site/Upload/GR/PMFBY")
    assert len(listings[0].code) == 64  # SHA-256 of the document address, not a GR number
    assert not any(g.url.startswith("javascript:") for g in listings)


def test_mahadbt_scheme_list_and_its_government_resolution() -> None:
    base = "https://mahadbt.maharashtra.gov.in/Farmer/AgriLogin/AgriLogin"
    listings = scheme_listings(MAHADBT_LIST, base)
    assert [g.title for g in listings] == [
        "Pradhan Mantri Krishi Sinchayee Yojana - Per Drop More Crop (Micro-irrigation Component)",
        "Mission for Integrated Development of Horticulture",
        "Bhausaheb Fundkar Phalbaag Lagvad Yojana",
        "Kaju Kalam Vatap Yojana",
    ]
    assert listings[2].code == "E9DDFA703C38E51AD8FABF0B538FA508"
    assert all(g.published is None for g in listings)  # the list gives no date
    page = "https://mahadbt.maharashtra.gov.in/Farmer/SchemeData/SchemeData?str=x"
    assert scheme_document(MAHADBT_SCHEME, page) == f"https://mahadbt.maharashtra.gov.in{GR_PDF}"
    assert scheme_document(b"<a href='/manual.pdf'>User manual</a>", page) is None


def test_robots_wildcards_are_read_as_rfc_9309() -> None:
    krishak = "User-agent: *\nAllow: /\nDisallow: /?s=\nDisallow: */feed/\nDisallow: /wp-admin/\n"
    assert not robots_allows(krishak, UA, "/feed/")
    assert robots_allows(krishak, UA, "/news/onion-prices/")
    agrowon = "User-agent: *\nAllow: /\nDisallow: /agrowon-weather-updates/\nDisallow: *?page*\n"
    assert not robots_allows(agrowon, UA, "/agrowon-weather-updates/rain")
    assert not robots_allows(agrowon, UA, "/news?page=2")
    assert robots_allows(agrowon, UA, "/news_sitemap.xml")
    gpt_only = "User-agent: GPTBot\nDisallow: /\n\nUser-agent: *\nAllow: /\nDisallow: /api/*\n"
    assert robots_allows(gpt_only, UA, "/feeds/rss")
    assert not robots_allows(gpt_only, UA, "/api/x")
    assert not robots_allows("User-agent: bagmitra-feed\nDisallow: /\n", UA, "/x")
    assert robots_allows("User-agent: bag\nDisallow: /\n", UA, "/x")  # another agent's group
    end = "User-agent: *\nDisallow: /*.pdf$\n"
    assert not robots_allows(end, UA, "/a/b.pdf")
    assert robots_allows(end, UA, "/a/b.pdf?x=1")
    assert robots_allows("<html><body>Not found</body></html>", UA, "/x")  # error page served


# --- listing pass -----------------------------------------------------------------------------


async def test_gr_portal_keeps_only_farm_departments(engine: AsyncEngine) -> None:
    site = Site({"/1145/Government-Resolutions": httpx.Response(200, content=GR_PAGE)})
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    async with async_sessionmaker(engine)() as session:
        gr = await source(session, "mh_gr_portal")
        outcome = await fetch_portal(session, gr, adapter(site), now)
        # Recorded day: higher education and OBC welfare GRs, no farm department.
        assert (outcome.status, outcome.added) == ("ok", 0)
        farm = GR_PAGE.replace("उच्च व तंत्र शिक्षण विभाग".encode(), "कृषी विभाग".encode())
        site.routes["/1145/Government-Resolutions"] = httpx.Response(200, content=farm)
        outcome = await fetch_portal(session, gr, adapter(site), now)
        assert outcome.added == 1
        [item] = list(await session.scalars(select(FeedItem)))
        assert (item.gr_number, item.department) == ("202611121517579608", "कृषी विभाग")
        assert (item.status, item.trust_level, item.type) == ("in_review", "official", "gr")
        assert gr.backfill_done_at == now
        again = await fetch_portal(session, gr, adapter(site), now)
        assert again.added == 0  # dedupe by the unique code
    assert site.calls[:2] == ["/robots.txt", "/1145/Government-Resolutions"]


async def test_commissionerate_list_keeps_the_last_30_days(engine: AsyncEngine) -> None:
    path = "/Site/Common/ViewGr.aspx"
    site = Site({path: httpx.Response(200, content=KRISHI_PAGE)})
    async with async_sessionmaker(engine)() as session:
        krishi = await source(session, "mh_agri_commissionerate")
        recorded_day = datetime(2026, 11, 12, tzinfo=UTC)
        assert (await fetch_portal(session, krishi, adapter(site), recorded_day)).added == 0
        a_week_after_the_pkvy_gr = datetime(2026, 10, 1, tzinfo=UTC)
        outcome = await fetch_portal(session, krishi, adapter(site), a_week_after_the_pkvy_gr)
        assert outcome.added == 1
        [item] = list(await session.scalars(select(FeedItem)))
        assert item.gr_number is None  # the page has no GR number
        assert item.published_at.date().isoformat() == "2026-09-24"
        assert item.trust_level == "official"


async def test_mahadbt_schemes_come_with_their_gr_document(engine: AsyncEngine) -> None:
    site = Site(
        {
            "/Farmer/AgriLogin/AgriLogin": httpx.Response(200, content=MAHADBT_LIST),
            "/Farmer/SchemeData/SchemeData": httpx.Response(200, content=MAHADBT_SCHEME),
        }
    )
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    async with async_sessionmaker(engine)() as session:
        mahadbt = await source(session, "mahadbt")
        outcome = await fetch_portal(session, mahadbt, adapter(site), now, cap=2)
        assert (outcome.status, outcome.added) == ("ok", 1)  # one GR PDF serves every fake page
        [item] = list(await session.scalars(select(FeedItem)))
        assert item.type == "scheme"
        assert item.url == f"https://mahadbt.maharashtra.gov.in{GR_PDF}"
        assert item.date_is_first_seen
        assert item.published_at.replace(tzinfo=UTC) == now
        assert item.trust_level == "official"


async def test_refused_skipped_and_unread_portals_request_nothing(engine: AsyncEngine) -> None:
    site = Site({})
    now = datetime(2026, 11, 12, tzinfo=UTC)
    async with async_sessionmaker(engine)() as session:
        pmfby = await source(session, "pmfby")
        assert (await fetch_portal(session, pmfby, adapter(site), now)).status == "no_reader"
        kisan = await source(session, "pm_kisan")
        assert (await fetch_portal(session, kisan, adapter(site), now)).status == "no_reader"
        gr = await source(session, "mh_gr_portal", terms="disallowed")
        assert (await fetch_portal(session, gr, adapter(site), now)).status == "refused"
    assert site.calls == []


async def test_robots_disallow_is_recorded_once(engine: AsyncEngine) -> None:
    site = Site({"/robots.txt": httpx.Response(200, text="User-agent: *\nDisallow: /1145/\n")})
    now = datetime(2026, 11, 12, tzinfo=UTC)
    async with async_sessionmaker(engine)() as session:
        gr = await source(session, "mh_gr_portal")
        outcome = await fetch_portal(session, gr, adapter(site), now)
        assert (outcome.status, gr.fetch_status) == ("disallowed", "disallowed")
        assert (await fetch_portal(session, gr, adapter(site), now)).status == "skipped"
    assert site.calls == ["/robots.txt"]


# --- AI step ----------------------------------------------------------------------------------


async def listed(session: AsyncSession, now: datetime) -> FeedItem:
    site = Site(
        {
            "/Farmer/AgriLogin/AgriLogin": httpx.Response(200, content=MAHADBT_LIST),
            "/Farmer/SchemeData/SchemeData": httpx.Response(200, content=MAHADBT_SCHEME),
        }
    )
    mahadbt = await source(session, "mahadbt")
    await fetch_portal(session, mahadbt, adapter(site), now, cap=1)
    [item] = list(await session.scalars(select(FeedItem)))
    return item


def doc_site(body: str = DOC, headers: dict[str, str] = HTML) -> Site:
    return Site({GR_PDF: httpx.Response(200, text=body, headers=headers)})


async def test_a_checked_scheme_is_typed_carded_and_published(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    ai = FakeAi()
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, now)
        run = await write_official_items(session, adapter(doc_site()), ai, settings(), now)
        assert (run.published, run.held) == (1, 0), item.check_issues
        assert ai.calls == ["classify", "write_article", "summarise"]
        assert (item.status, item.type, item.trust_level) == ("published", "scheme", "official")
        assert item.raw_hash is not None
        assert item.extracted_text is not None
        assert SOURCE in item.extracted_text
        texts = {t.lang: t for t in await session.scalars(select(FeedItemI18n))}
        assert set(texts) == {"mr", "hi", "en"}
        assert texts["en"].article is not None
        [card] = list(await session.scalars(select(FeedSchemeCard)))
        assert card.fields["amount"] == {"value": "₹ ६,०००", "page": "p. 1"}
        assert card.fields["scheme_name"] == {"value": NOT_STATED, "page": None}
        kinds = [e.kind for e in await session.scalars(select(FeedReviewEvent))]
        assert {"classified", "extracted", "auto_published", "ai_official"} <= set(kinds)
        # Knowledge trigger (c): a published official scheme with text calls for an explainer.
        topics = await scheme_topics(session, now)
        assert [t.item_id for t in topics] == [item.id]
        # Done: a second run asks nothing.
        again = await write_official_items(session, adapter(doc_site()), ai, settings(), now)
        assert (again.published, len(ai.calls)) == (0, 3)


async def test_a_card_value_not_in_the_document_holds_the_item(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    ai = FakeAi(fields={"amount": {"value": "₹ 9,000", "page": "p. 1"}})
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, now)
        run = await write_official_items(session, adapter(doc_site()), ai, settings(), now)
        assert run.held == 1
        assert item.status == "held"
        assert any("9,000" in i["text"] for i in item.check_issues)


async def test_an_article_number_not_in_the_document_holds_the_item(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    bad = payload()
    bad["lang"]["mr"]["key_points"][0] = "अनुदान ₹ 9,000 प्रति हेक्टर"
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, now)
        ai = FakeAi(article=bad)
        run = await write_official_items(session, adapter(doc_site()), ai, settings(), now)
        assert run.held == 1
        assert item.status == "held"


async def test_irrelevant_unreadable_and_unavailable(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, now)
        down = FakeAi(fail=True)
        run = await write_official_items(session, adapter(doc_site()), down, settings(), now)
        assert (run.retry, item.status) == (1, "in_review")  # tried again next run
        run = await write_official_items(
            session, adapter(doc_site()), FakeAi(relevant=False), settings(), now
        )
        assert (run.drafted, item.status) == (1, "draft")


async def test_a_scanned_document_is_held_for_a_person(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    ai = FakeAi()
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, now)
        site = doc_site("<html><body><img src='scan.png'></body></html>")
        run = await write_official_items(session, adapter(site), ai, settings(), now)
        assert (run.held, item.status) == (1, "held")
        assert item.check_issues[0]["kind"] == "text_empty"
        assert ai.calls == []  # no model call on an empty text


async def test_review_when_auto_publish_is_off_and_no_ai_without_key(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, now)
        run = await write_official_items(session, adapter(doc_site()), None, settings(), now)
        assert run.skipped_reason == "FEED_AI_API_KEY is not set"
        off = settings(feed_auto_publish=False)
        run = await write_official_items(session, adapter(doc_site()), FakeAi(), off, now)
        assert (run.review, item.status) == (1, "in_review")


async def test_the_daily_model_cap_is_kept(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    async with async_sessionmaker(engine)() as session:
        await listed(session, now)
        capped = settings(feed_ai_daily_items=0)
        run = await write_official_items(session, adapter(doc_site()), FakeAi(), capped, now)
        assert run.skipped_reason == "daily AI limit reached"


# --- job --------------------------------------------------------------------------------------


async def test_job_kill_switch_and_summary(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    site = Site({"/1145/Government-Resolutions": httpx.Response(200, content=GR_PAGE)})
    async with async_sessionmaker(engine)() as session:
        off = await run_portals(
            session, adapter(site), FakeAi(), settings(cron_feed_portals=False), now
        )
        assert off.skipped_reason == "CRON_FEED_PORTALS is off"
        assert site.calls == []
        summary = await run_portals(session, adapter(site), None, settings(), now)
    data = json.loads(summary.to_json())
    by_key = {s["key"]: s for s in data["sources"]}
    assert by_key["mh_gr_portal"]["status"] == "ok"
    assert by_key["pmfby"]["status"] == "no_reader"
    assert by_key["pm_kisan"]["status"] == "no_reader"
    assert by_key["mahadbt"]["status"] == "fetch_failed"  # the fake has no MahaDBT page
    assert data["official"]["skipped_reason"] == "FEED_AI_API_KEY is not set"
    assert "mahasamvad_news" not in by_key  # news sources belong to the news job


@pytest.mark.parametrize("key", ["mh_gr_portal", "mahadbt", "mh_agri_commissionerate"])
def test_seeded_readers_exist(key: str) -> None:
    [seed] = [s for s in source_seeds() if s["key"] == key]
    assert seed["fetch_method"] in READERS
