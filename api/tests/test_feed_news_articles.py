"""Spec v1.6 (owner Q127): the news job fetches each new headline's page from an allowed
source, has the AI write the article and publishes it when every check passes; otherwise it
is held. Anthropic and the source are fakes; nothing leaves the test."""

from __future__ import annotations

import copy
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import AiUnavailableError
from bagmitra_api.feed.article import ArticleSet, parse_articles
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource
from bagmitra_api.feed.news_articles import recheck_held_articles, write_news_articles
from tests.test_feed_api import ai_box, api, approve_publish, create, ocr_box
from tests.test_feed_article import SOURCE, payload
from tests.test_feed_news import HOST, Server, adapter, news_source

__all__ = ["ai_box", "api", "ocr_box"]  # fixtures used here

NOW = datetime(2026, 11, 9, 6, tzinfo=UTC)
PAGE = f"<html><body><nav>menu</nav><article><p>{SOURCE}</p></article></body></html>"


def sound(url: str) -> dict[str, Any]:
    data = payload()
    for lang in ("mr", "hi", "en"):
        data["lang"][lang]["sources"] = [{"title": "Source", "url": url}]
    return data


class Writer:
    def __init__(self, answer: dict[str, Any] | Exception) -> None:
        self.answer = answer
        self.calls: list[tuple[str, str]] = []

    async def write_article(self, text: str, *, source_url: str) -> ArticleSet:
        self.calls.append((text, source_url))
        if isinstance(self.answer, Exception):
            raise self.answer
        return parse_articles(copy.deepcopy(self.answer))


def settings(**extra: Any) -> Settings:
    return Settings(environment="test", **extra)


def pages(*paths: str) -> Server:
    routes = {"/robots.txt": httpx.Response(404)}
    routes |= {p: httpx.Response(200, text=PAGE) for p in paths}
    return Server(routes)


async def headline(session: AsyncSession, source: FeedSource, path: str) -> FeedItem:
    item = FeedItem(
        id=uuid.uuid4(),
        type="news",
        source_id=source.id,
        external_id=path,
        published_at=NOW - timedelta(hours=1),
        url=f"{HOST}{path}",
        status="in_review",
        trust_level="news",
        check_issues=[],
    )
    session.add(item)
    session.add(FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="mr", title="मथळा"))
    await session.flush()
    return item


async def texts(session: AsyncSession, item: FeedItem) -> dict[str, FeedItemI18n]:
    rows = await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
    return {r.lang: r for r in rows}


async def kinds(session: AsyncSession, item: FeedItem) -> list[str]:
    rows = await session.scalars(
        select(FeedReviewEvent.kind).where(FeedReviewEvent.item_id == item.id)
    )
    return list(rows)


async def test_a_sound_article_is_published_in_three_languages(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1")
        writer = Writer(sound(f"{HOST}/a1"))
        run = await write_news_articles(session, adapter(pages("/a1")), writer, settings(), NOW)
        assert (run.published, run.held) == (1, 0)
        assert item.status == "published"
        assert item.raw_hash is not None
        assert item.raw_bytes == len(PAGE.encode())
        rows = await texts(session, item)
        assert set(rows) == {"mr", "hi", "en"}
        en, mr = rows["en"].article, rows["mr"].article
        assert en is not None
        assert mr is not None
        assert en["charts"][0]["type"] == "pie"
        assert rows["mr"].title == mr["headline"]
        assert rows["mr"].summary == mr["standfirst"]
        assert "ai_article" in await kinds(session, item)
        assert "auto_published" in await kinds(session, item)
        # The model got the page text (not the menu), with the page address.
        text, url = writer.calls[0]
        assert SOURCE in text
        assert url == f"{HOST}/a1"


async def test_a_failing_check_holds_the_article(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1")
        bad = sound(f"{HOST}/a1")
        bad["lang"]["mr"]["key_points"][0] = "अनुदान ₹ 9,000"
        run = await write_news_articles(
            session, adapter(pages("/a1")), Writer(bad), settings(), NOW
        )
        assert (run.published, run.held) == (0, 1)
        assert item.status == "held"
        assert any("9,000" in i["text"] for i in item.check_issues)
        assert (await texts(session, item))["mr"].article is not None  # kept for the admin


async def test_not_relevant_or_political_goes_to_draft(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        a = await headline(session, source, "/a1")
        await write_news_articles(
            session,
            adapter(pages("/a1")),
            Writer({"relevant": False, "political": False}),
            settings(),
            NOW,
        )
        assert a.status == "draft"


async def test_the_daily_cap_limits_model_calls(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        first = await headline(session, source, "/a1")
        second = await headline(session, source, "/a2")
        writer = Writer(sound(f"{HOST}/a1"))
        capped = settings(feed_ai_daily_items=1)
        await write_news_articles(session, adapter(pages("/a1", "/a2")), writer, capped, NOW)
        assert len(writer.calls) == 1
        await write_news_articles(session, adapter(pages("/a1", "/a2")), writer, capped, NOW)
        assert len(writer.calls) == 1  # same UTC day: nothing more
        statuses = {first.status, second.status}
        assert "in_review" in statuses
        tomorrow = NOW + timedelta(days=1)
        await write_news_articles(session, adapter(pages("/a1", "/a2")), writer, capped, tomorrow)
        assert len(writer.calls) == 2


async def test_without_a_key_nothing_is_written(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1")
        run = await write_news_articles(session, adapter(pages()), None, settings(), NOW)
        assert run.skipped_reason
        assert item.status == "in_review"


async def test_a_page_that_cannot_be_read_is_held(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/gone")
        writer = Writer(sound(f"{HOST}/gone"))
        await write_news_articles(session, adapter(pages()), writer, settings(), NOW)
        assert item.status == "held"
        assert writer.calls == []
        assert "404" in item.check_issues[0]["text"]


async def test_ai_unavailable_is_retried_next_run(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1")
        await write_news_articles(
            session, adapter(pages("/a1")), Writer(AiUnavailableError("HTTP 529")), settings(), NOW
        )
        assert item.status == "in_review"
        writer = Writer(sound(f"{HOST}/a1"))
        await write_news_articles(session, adapter(pages("/a1")), writer, settings(), NOW)
        assert item.status == "published"


async def test_auto_publish_off_leaves_the_article_for_review(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1")
        writer = Writer(sound(f"{HOST}/a1"))
        await write_news_articles(
            session, adapter(pages("/a1")), writer, settings(feed_auto_publish=False), NOW
        )
        assert item.status == "in_review"
        assert (await texts(session, item))["en"].article is not None


async def test_sources_without_allowed_terms_are_not_read(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session, terms="unknown")
        item = await headline(session, source, "/a1")
        writer = Writer(sound(f"{HOST}/a1"))
        await write_news_articles(session, adapter(pages("/a1")), writer, settings(), NOW)
        assert writer.calls == []
        assert item.status == "in_review"


async def test_the_feed_returns_the_article_in_the_asked_language(
    api: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    item = await create(
        api,
        type="news",
        source_key="test_news",
        external_id="art-1",
        extracted_text=None,
        document_base64=None,
        document_type=None,
        card=None,
        targets=[],
        texts={"en": {"title": "Headline", "summary": "Standfirst."}},
    )
    articles = parse_articles(sound("https://news.example/a1")).articles
    async with async_sessionmaker(engine)() as session:
        for lang, article in articles.items():
            if lang == "en":
                continue
            session.add(
                FeedItemI18n(
                    id=uuid.uuid4(),
                    item_id=uuid.UUID(item["id"]),
                    lang=lang,
                    title=article.headline,
                    summary=article.standfirst,
                    article=article.as_json(),
                )
            )
        row = await session.scalar(
            select(FeedItemI18n).where(
                FeedItemI18n.item_id == uuid.UUID(item["id"]), FeedItemI18n.lang == "en"
            )
        )
        assert row is not None
        row.article = articles["en"].as_json()
        await session.commit()
    await approve_publish(api, item["id"])
    [shown] = (await api.get("/v1/feed?lang=mr", headers=auth_headers)).json()["items"]
    article = shown["article"]
    assert article["headline"] == articles["mr"].headline
    assert article["charts"][0]["data"][0] == {"label": "Nagpur", "value": 60.0}
    assert article["key_dates"] == [{"date": "2026-11-30", "label": "Last date to apply"}]
    assert {s["heading"] for s in article["sections"]} >= {"What was decided"}
    old = await create(api, external_id="old-1")
    await approve_publish(api, old["id"])
    items = (await api.get("/v1/feed", headers=auth_headers)).json()["items"]
    assert [i["article"] for i in items if i["id"] == old["id"]] == [None]


def page_with(extra: str, *paths: str) -> Server:
    """The same page plus one more sentence (the source as it reads on a later fetch)."""
    body = f"<html><body><article><p>{SOURCE} {extra}</p></article></body></html>"
    routes = {"/robots.txt": httpx.Response(404)}
    routes |= {p: httpx.Response(200, text=body) for p in paths}
    return Server(routes)


async def held_item(
    session: AsyncSession, path: str = "/a1", source: FeedSource | None = None
) -> FeedItem:
    """An article held because it states ₹9,000, which the first page did not."""
    source = source or await news_source(session)
    item = await headline(session, source, path)
    bad = sound(f"{HOST}{path}")
    for lang in ("mr", "hi", "en"):
        bad["lang"][lang]["key_points"][0] = "अनुदान ₹ 9,000"
    await write_news_articles(session, adapter(pages(path)), Writer(bad), settings(), NOW)
    assert item.status == "held"
    return item


async def test_a_held_article_that_now_passes_is_published_without_a_new_ai_call(
    engine: AsyncEngine,
) -> None:
    """Owner 2026-11-09 ("थांबलेल्या बातम्या पुन्हा तपासून प्रकाशित करा"): after the check
    learned number words, the held articles are checked again against their page. The saved
    article is used as it is: the model is not asked again."""
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        item = await held_item(session)
        run = await recheck_held_articles(
            session, adapter(page_with("एकूण नऊ हजार रुपये.", "/a1")), settings()
        )
        assert (run.published, run.held) == (1, 0)
        assert item.status == "published"
        assert item.check_issues == []
        assert {"ai_article_recheck", "auto_published"} <= set(await kinds(session, item))


async def test_a_held_article_that_still_fails_stays_held_with_fresh_reasons(
    engine: AsyncEngine,
) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        item = await held_item(session)
        run = await recheck_held_articles(session, adapter(pages("/a1")), settings())
        assert (run.published, run.held) == (0, 1)
        assert item.status == "held"
        assert any("9,000" in i["text"] for i in item.check_issues)
        assert "ai_article_recheck" in await kinds(session, item)


async def test_recheck_skips_items_without_a_saved_article_and_keeps_review_mode(
    engine: AsyncEngine,
) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        unread = await headline(session, source, "/gone")
        unread.status = "held"
        unread.check_issues = [{"kind": "fetch", "text": "HTTP 404", "where": "page"}]
        item = await held_item(session, "/a2", source)
        run = await recheck_held_articles(
            session,
            adapter(page_with("एकूण नऊ हजार रुपये.", "/a2")),
            settings(feed_auto_publish=False),
        )
        assert (run.published, run.held) == (0, 0)
        assert unread.status == "held"  # no article to check: left for the admin
        assert item.status == "in_review"  # passes, waits for a feed_admin approval
