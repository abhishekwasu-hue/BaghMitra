"""Owner 2026-11-13 (Q150): a cheap headline filter runs before the article writer, so the
writer (and its page fetch) only sees useful news. The filter is the real adapter over
httpx.MockTransport (nothing leaves the test); the writer and the source are fakes."""

from __future__ import annotations

import json
import uuid
from collections.abc import Sequence
from dataclasses import asdict
from datetime import timedelta
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import AnthropicFeedAi
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource
from bagmitra_api.feed.news_articles import (
    ATTEMPT,
    FILTER,
    FILTER_BATCH,
    AnthropicHeadlineFilter,
    Headline,
    Verdict,
    parse_verdicts,
    write_news_articles,
)
from tests.test_feed_news import HOST, adapter, news_source
from tests.test_feed_news_articles import NOW, Writer, pages, settings, sound

ORANGE = "Orange growers get help against fruit drop"
CRICKET = "Cricket team wins the series"
RALLY = "Party leader holds a rally before the election"


def verdict_for(title: str) -> dict[str, Any]:
    if "rally" in title:
        return {"relevant": True, "political": True, "reason": "election rally"}
    if "Cricket" in title:
        return {"relevant": False, "political": False, "reason": "sport"}
    return {"relevant": True, "political": False, "reason": "orchard pest news"}


class Model:
    """The Messages API fake: judges each headline of the request by its words (or answers
    with the given error status) and records each request body."""

    def __init__(self, status: int = 200) -> None:
        self.status = status
        self.bodies: list[dict[str, Any]] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content)
        self.bodies.append(body)
        if self.status != httpx.codes.OK:
            return httpx.Response(self.status, json={"type": "error"})
        rows = json.loads(self.headlines(body))
        items = [{"key": r["key"], **verdict_for(r["title"])} for r in rows]
        content = [{"type": "text", "text": json.dumps({"items": items})}]
        return httpx.Response(200, json={"content": content, "stop_reason": "end_turn"})

    @staticmethod
    def headlines(body: dict[str, Any]) -> str:
        text: str = body["messages"][0]["content"]
        return text.split("<document>\n", 1)[1].split("\n</document>", 1)[0]

    def filter(self) -> AnthropicHeadlineFilter:
        http = httpx.AsyncClient(transport=httpx.MockTransport(self))
        ai = AnthropicFeedAi(http, Settings(environment="test", feed_ai_api_key="sk-test-not-real"))
        return AnthropicHeadlineFilter(ai)


async def headline(
    session: AsyncSession, source: FeedSource, path: str, title: str, age: int = 1
) -> FeedItem:
    item = FeedItem(
        id=uuid.uuid4(),
        type="news",
        source_id=source.id,
        external_id=path,
        published_at=NOW - timedelta(hours=age),
        url=f"{HOST}{path}",
        status="in_review",
        trust_level="news",
        check_issues=[],
    )
    session.add(item)
    session.add(FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="en", title=title))
    await session.flush()
    return item


async def events(session: AsyncSession, item: FeedItem, kind: str) -> list[dict[str, Any]]:
    rows = await session.scalars(
        select(FeedReviewEvent.detail).where(
            FeedReviewEvent.item_id == item.id, FeedReviewEvent.kind == kind
        )
    )
    return list(rows)


async def test_an_irrelevant_headline_is_drafted_without_a_writer_call(
    engine: AsyncEngine,
) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/c1", CRICKET)
        model, writer, server = Model(), Writer(sound(f"{HOST}/c1")), pages("/c1")
        run = await write_news_articles(
            session, adapter(server), writer, settings(), NOW, model.filter()
        )
        assert writer.calls == []
        assert server.calls == []  # no page (not even robots.txt) fetched
        assert item.status == "draft"
        # The writer-judged bookkeeping: an ATTEMPT event with result draft (FINAL).
        assert await events(session, item, ATTEMPT) == [
            {"result": "draft", "reason": "prefilter: sport"}
        ]
        [verdict] = await events(session, item, FILTER)
        assert (verdict["result"], verdict["relevant"], verdict["political"]) == (
            "dropped",
            False,
            False,
        )
        assert (run.drafted, run.filter.dropped) == (0, 1)
        # The request: the classify model, structured output, headline only.
        [body] = model.bodies
        assert body["model"] == "claude-haiku-5-5"
        assert body["output_config"]["format"]["type"] == "json_schema"
        assert json.loads(Model.headlines(body)) == [
            {"key": "H1", "title": CRICKET, "source": source.name, "lang": "en"}
        ]


async def test_a_political_headline_is_drafted(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/p1", RALLY)
        writer = Writer(sound(f"{HOST}/p1"))
        await write_news_articles(
            session, adapter(pages("/p1")), writer, settings(), NOW, Model().filter()
        )
        assert writer.calls == []
        assert item.status == "draft"
        assert (await events(session, item, FILTER))[0]["political"] is True


async def test_a_relevant_headline_reaches_the_writer(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1", ORANGE)
        drop = await headline(session, source, "/c1", CRICKET)
        writer = Writer(sound(f"{HOST}/a1"))
        run = await write_news_articles(
            session, adapter(pages("/a1", "/c1")), writer, settings(), NOW, Model().filter()
        )
        assert [url for _, url in writer.calls] == [f"{HOST}/a1"]
        assert item.status == "published"
        assert drop.status == "draft"
        assert asdict(run.filter) == {"calls": 1, "relevant": 1, "dropped": 1, "errors": 0}


async def test_a_filter_error_leaves_the_headlines_waiting(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1", ORANGE)
        drop = await headline(session, source, "/c1", CRICKET)
        writer = Writer(sound(f"{HOST}/a1"))
        run = await write_news_articles(
            session, adapter(pages("/a1")), writer, settings(), NOW, Model(529).filter()
        )
        assert writer.calls == []  # unclassified: not written either
        assert (item.status, drop.status) == ("in_review", "in_review")
        assert asdict(run.filter) == {"calls": 1, "relevant": 0, "dropped": 0, "errors": 1}
        # The next run classifies them and writes the relevant one.
        await write_news_articles(
            session, adapter(pages("/a1")), writer, settings(), NOW, Model().filter()
        )
        assert (item.status, drop.status) == ("published", "draft")


async def test_a_headline_is_classified_once(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1", ORANGE)
        first, again = Model(), Model()
        # The writer cap is reached: the verdict is kept and the item waits for the writer.
        await write_news_articles(
            session,
            adapter(pages("/a1")),
            Writer(sound(f"{HOST}/a1")),
            settings(feed_ai_daily_items=0),
            NOW,
            first.filter(),
        )
        assert (len(first.bodies), item.status) == (1, "in_review")
        writer = Writer(sound(f"{HOST}/a1"))
        run = await write_news_articles(
            session, adapter(pages("/a1")), writer, settings(), NOW, again.filter()
        )
        assert again.bodies == []  # already judged: no second filter call
        assert run.filter.calls == 0
        assert len(writer.calls) == 1
        assert item.status == "published"


async def test_the_filter_cap_and_batches(engine: AsyncEngine) -> None:
    """One call judges at most FILTER_BATCH headlines, newest first; at most
    FEED_AI_FILTER_DAILY_CALLS calls a UTC day; the rest waits for the next day."""
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        items = [
            await headline(session, source, f"/c{n}", f"{CRICKET} {n}", age=n + 1)
            for n in range(FILTER_BATCH + 1)
        ]
        capped = settings(feed_ai_filter_daily_calls=1)
        model = Model()
        run = await write_news_articles(
            session, adapter(pages()), Writer(sound(HOST)), capped, NOW, model.filter()
        )
        assert asdict(run.filter) == {
            "calls": 1,
            "relevant": 0,
            "dropped": FILTER_BATCH,
            "errors": 0,
        }
        assert items[-1].status == "in_review"  # the oldest waits
        assert all(i.status == "draft" for i in items[:-1])
        await write_news_articles(
            session, adapter(pages()), Writer(sound(HOST)), capped, NOW, model.filter()
        )
        assert len(model.bodies) == 1  # same UTC day: no more filter calls
        tomorrow = NOW + timedelta(days=1)
        await write_news_articles(
            session, adapter(pages()), Writer(sound(HOST)), capped, tomorrow, model.filter()
        )
        assert len(model.bodies) == 2
        assert items[-1].status == "draft"


async def test_filter_drafts_do_not_use_the_writer_cap(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        for n in range(3):
            await headline(session, source, f"/c{n}", f"{CRICKET} {n}")
        item = await headline(session, source, "/a1", ORANGE, age=5)
        writer = Writer(sound(f"{HOST}/a1"))
        run = await write_news_articles(
            session,
            adapter(pages("/a1")),
            writer,
            settings(feed_ai_daily_items=1),
            NOW,
            Model().filter(),
        )
        assert run.filter.dropped == 3
        assert len(writer.calls) == 1  # the one writer call of the day is still free
        assert item.status == "published"


async def test_the_writer_gets_the_newest_relevant_headline_first(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        await headline(session, source, "/old", f"{ORANGE} (old)", age=5)
        await headline(session, source, "/new", ORANGE, age=1)
        writer = Writer(sound(f"{HOST}/new"))
        await write_news_articles(
            session,
            adapter(pages("/old", "/new")),
            writer,
            settings(feed_ai_daily_items=1),
            NOW,
            Model().filter(),
        )
        assert [url for _, url in writer.calls] == [f"{HOST}/new"]


async def test_the_job_summary_carries_the_filter_counters(engine: AsyncEngine) -> None:
    from bagmitra_api.feed.news_job import article_step  # noqa: PLC0415

    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        await headline(session, source, "/a1", ORANGE)
        await headline(session, source, "/c1", CRICKET)
        await headline(session, source, "/p1", RALLY)
        written, _ = await article_step(
            session,
            adapter(pages("/a1")),
            Writer(sound(f"{HOST}/a1")),
            settings(),
            NOW,
            Model().filter(),
        )
        summary = json.loads(json.dumps(asdict(written)))
        assert summary["filter"] == {"calls": 1, "relevant": 1, "dropped": 2, "errors": 0}
        assert summary["published"] == 1


class Silent:
    """A filter that answers without any verdict."""

    def __init__(self) -> None:
        self.seen: list[int] = []

    async def judge(self, headlines: Sequence[Headline]) -> dict[str, Verdict]:
        self.seen.append(len(headlines))
        return {}


async def test_an_answer_without_verdicts_counts_as_an_error(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        source = await news_source(session)
        item = await headline(session, source, "/a1", ORANGE)
        capped = settings(feed_ai_filter_daily_calls=1)
        run = await write_news_articles(
            session, adapter(pages("/a1")), Writer(sound(HOST)), capped, NOW, Silent()
        )
        assert asdict(run.filter) == {"calls": 1, "relevant": 0, "dropped": 0, "errors": 1}
        assert item.status == "in_review"
        [error] = await events(session, item, FILTER)
        assert error["result"] == "error"
        again = await write_news_articles(
            session, adapter(pages("/a1")), Writer(sound(HOST)), capped, NOW, Silent()
        )
        assert again.filter.calls == 0  # the failed call counted against the daily cap


def test_unknown_repeated_or_missing_keys_give_no_verdict() -> None:
    answer = {
        "items": [
            {"key": "H1", "relevant": True, "political": False, "reason": " pests "},
            {"key": "H1", "relevant": False, "political": False, "reason": "repeat"},
            {"key": "H9", "relevant": False, "political": False, "reason": "unknown key"},
            {"key": "H2", "relevant": "yes", "political": None, "reason": 3},
            "not an object",
        ]
    }
    assert parse_verdicts(answer, ["H1", "H2", "H3"]) == {
        "H1": Verdict(relevant=True, political=False, reason="pests"),
        "H2": Verdict(relevant=False, political=False, reason=""),
    }
    assert parse_verdicts({"items": None}, ["H1"]) == {}
