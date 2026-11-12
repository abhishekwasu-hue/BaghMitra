"""Q139 (owner 2026-11-11): related news items form one topic thread. The model is the real
adapter over httpx.MockTransport (nothing leaves the test); the decision is conservative: no
candidate means no call, and anything but a clear match (including a model error) starts a new
thread. The backfill is the same step and is idempotent. The feed API returns the threads."""

from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import event, select
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import StaticPool

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.base import Base
from bagmitra_api.feed import news_job
from bagmitra_api.feed.ai import AnthropicFeedAi
from bagmitra_api.feed.models import (
    FeedItem,
    FeedItemI18n,
    FeedReviewEvent,
    FeedSource,
    FeedThread,
)
from bagmitra_api.feed.threads import (
    MAX_CANDIDATES,
    THREADS_PER_RUN,
    AnthropicThreader,
    ThreadRun,
    TopicText,
    render_question,
    shares_signal,
    thread_item,
    thread_news,
)
from tests.test_feed_api import ai_box, api, ocr_box

__all__ = ["ai_box", "api", "ocr_box"]  # fixtures used here

T0 = datetime(2026, 11, 9, 6, tzinfo=UTC)
DROUGHT_1 = (
    "दुष्काळग्रस्त शेतकऱ्यांना दिवाळीपूर्वी ₹५,००० अग्रिम",
    "टंचाईग्रस्त गावांना २४ ते ४८ तासांत टँकर देण्याचे निर्देश.",
)
DROUGHT_2 = (
    "दुष्काळग्रस्त भागात दिवाळीपूर्वी ५,००० रुपये अग्रिम; टँकर ४८ तासांत",
    "जिल्हाधिकाऱ्यांनी टंचाईग्रस्त गावांचा आढावा घेतला.",
)
ORANGE_EXPORT = (
    "Orange export centre opens at Morshi",
    "The centre will grade and pack fruit for export.",
)


def answer(match: str) -> httpx.Response:
    content = [{"type": "text", "text": json.dumps({"match": match})}]
    return httpx.Response(200, json={"content": content, "stop_reason": "end_turn"})


class Model:
    """The Messages API fake: answers in order and records each request body."""

    def __init__(self, *responses: httpx.Response) -> None:
        self.responses = list(responses)
        self.bodies: list[dict[str, Any]] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.bodies.append(json.loads(request.content))
        return self.responses.pop(0)

    def threader(self) -> AnthropicThreader:
        http = httpx.AsyncClient(transport=httpx.MockTransport(self))
        settings = Settings(environment="test", feed_ai_api_key="sk-test-not-real")
        return AnthropicThreader(AnthropicFeedAi(http, settings))


async def source_of(session: AsyncSession) -> FeedSource:
    found = await session.scalar(select(FeedSource).where(FeedSource.key == "thread_src"))
    if found is not None:
        return found
    source = FeedSource(
        id=uuid.uuid4(),
        key="thread_src",
        name="Mahasamvad (test)",
        url="https://mahasamvad.example/rss",
        tier="news",
        terms_status="allowed",
        fetch_method="rss",
    )
    session.add(source)
    await session.flush()
    return source


async def news(
    session: AsyncSession,
    text: tuple[str, str],
    when: datetime,
    *,
    status: str = "published",
    lang: str = "mr",
) -> FeedItem:
    source = await source_of(session)
    item = FeedItem(
        id=uuid.uuid4(),
        type="news",
        source_id=source.id,
        external_id=uuid.uuid4().hex,
        published_at=when,
        url=f"https://mahasamvad.example/{uuid.uuid4().hex[:8]}",
        status=status,
        trust_level="news",
        check_issues=[],
    )
    session.add(item)
    session.add(
        FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang=lang, title=text[0], summary=text[1])
    )
    await session.flush()
    return item


async def events(session: AsyncSession, item: FeedItem) -> list[dict[str, Any]]:
    rows = await session.scalars(
        select(FeedReviewEvent.detail).where(
            FeedReviewEvent.item_id == item.id, FeedReviewEvent.kind == "threaded"
        )
    )
    return list(rows)


def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def test_first_item_starts_a_thread_without_a_model_call(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        item = await news(session, DROUGHT_1, T0)
        model = Model()
        run = await thread_news(session, model.threader())
        assert (run.new, run.joined, run.model_calls) == (1, 0, 0)
        assert model.bodies == []
        thread = await session.get(FeedThread, item.thread_id)
        assert thread is not None
        assert (thread.title, thread.summary) == DROUGHT_1  # copied, never written new
        assert (await events(session, item))[0]["reason"] == "no_candidates"


async def test_same_decision_from_another_district_joins_the_thread(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        first = await news(session, DROUGHT_1, T0)
        later = await news(session, DROUGHT_2, T0 + timedelta(days=2))
        model = Model(answer("T1"))
        run = await thread_news(session, model.threader())
        assert (run.new, run.joined, run.model_calls) == (1, 1, 1)
        assert later.thread_id == first.thread_id
        thread = await session.get(FeedThread, first.thread_id)
        assert thread is not None
        # The card shows the latest item's own checked title.
        assert thread.title == DROUGHT_2[0]
        assert thread.last_item_at.replace(tzinfo=UTC) == T0 + timedelta(days=2)
        detail = (await events(session, later))[0]
        assert detail == {
            "thread_id": str(first.thread_id),
            "joined": True,
            "candidates": 1,
            "reason": "model",
        }
        # One small structured-output call on the cheap model, low effort, enum answer.
        body = model.bodies[0]
        assert body["model"] == "claude-haiku-5-5"
        assert body["max_tokens"] <= 2000
        out = body["output_config"]
        assert out["effort"] == "low"
        assert out["format"]["schema"]["properties"]["match"]["enum"] == ["T1", "new"]
        assert "fallbacks" not in body
        assert "wrong merge is worse" in body["system"]
        question = body["messages"][0]["content"]
        assert DROUGHT_1[0] in question
        assert DROUGHT_2[0] in question


async def test_model_saying_new_starts_a_new_thread(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        first = await news(session, DROUGHT_1, T0)
        later = await news(session, DROUGHT_2, T0 + timedelta(days=1))
        run = await thread_news(session, Model(answer("new")).threader())
        assert (run.new, run.joined, run.model_calls) == (2, 0, 1)
        assert later.thread_id != first.thread_id
        assert (await events(session, later))[0]["joined"] is False


async def test_model_error_falls_back_to_a_new_thread(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        first = await news(session, DROUGHT_1, T0)
        later = await news(session, DROUGHT_2, T0 + timedelta(days=1))
        broken = Model(httpx.Response(529, json={"error": "overloaded"}))
        run = await thread_news(session, broken.threader())
        assert (run.new, run.joined, run.ai_errors) == (2, 0, 1)
        assert later.thread_id not in (None, first.thread_id)
        assert (await events(session, later))[0]["reason"].startswith("ai_error")


async def test_cut_off_or_unknown_answers_are_new(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        first = await news(session, DROUGHT_1, T0)
        second = await news(session, DROUGHT_2, T0 + timedelta(days=1))
        third = await news(session, DROUGHT_2, T0 + timedelta(days=2))
        cut = httpx.Response(
            200,
            json={"content": [{"type": "text", "text": "{"}], "stop_reason": "max_tokens"},
        )
        run = await thread_news(session, Model(cut, answer("T9")).threader())
        assert run.joined == 0
        assert len({first.thread_id, second.thread_id, third.thread_id}) == 3


async def test_no_shared_signal_or_outside_the_window_means_no_call(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        await news(session, DROUGHT_1, T0)
        await news(session, ORANGE_EXPORT, T0 + timedelta(days=1), lang="en")
        await news(session, DROUGHT_2, T0 + timedelta(days=45))
        model = Model()
        run = await thread_news(session, model.threader())
        assert (run.new, run.model_calls) == (3, 0)
        assert model.bodies == []


async def test_backfill_is_idempotent_and_skips_unpublished(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        first = await news(session, DROUGHT_1, T0)
        later = await news(session, DROUGHT_2, T0 + timedelta(days=1))
        held = await news(session, DROUGHT_2, T0 + timedelta(days=1), status="held")
        run = await thread_news(session, Model(answer("T1")).threader())
        assert (run.new, run.joined) == (1, 1)
        before = (first.thread_id, later.thread_id)
        again_model = Model()
        again = await thread_news(session, again_model.threader())
        assert again == ThreadRun()
        assert again_model.bodies == []
        assert (first.thread_id, later.thread_id) == before
        assert held.thread_id is None
        assert len(list(await session.scalars(select(FeedThread)))) == 1


async def test_news_run_threads_old_items_capped_per_run(
    engine: AsyncEngine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """No manual step after deploy: each scheduled news run threads published news without a
    topic, oldest first, at most THREADS_PER_RUN, and the next run goes on."""
    monkeypatch.setattr(news_job, "THREADS_PER_RUN", 2)
    async with maker(engine)() as session:
        items = [
            await news(session, (f"Topic {i} alpha", ""), T0 + timedelta(days=40 * i))
            for i in range(3)
        ]
        await session.commit()
        model = Model()
        first = await news_job.thread_step(session, model.threader())
        assert first.new == 2
        assert [i.thread_id is not None for i in items] == [True, True, False]
        second = await news_job.thread_step(session, model.threader())
        assert second.new == 1
        assert all(i.thread_id is not None for i in items)
        third = await news_job.thread_step(session, model.threader())
        assert third == ThreadRun()
        assert model.bodies == []  # 40 days apart: no candidates, no calls
    assert THREADS_PER_RUN == 50  # the real cap


async def test_without_the_model_nothing_is_threaded(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        item = await news(session, DROUGHT_1, T0)
        run = await thread_news(session, None)
        assert run.skipped_reason == "FEED_AI_API_KEY is not set"
        assert item.thread_id is None


async def test_an_item_without_text_stays_unthreaded(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        source = await source_of(session)
        item = FeedItem(
            id=uuid.uuid4(),
            type="news",
            source_id=source.id,
            published_at=T0,
            url="https://mahasamvad.example/x",
            status="published",
            trust_level="news",
            check_issues=[],
        )
        session.add(item)
        await session.flush()
        assert await thread_item(session, item, Model().threader(), ThreadRun()) is None
        assert item.thread_id is None


async def test_candidates_are_capped(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        for i in range(MAX_CANDIDATES + 3):
            session.add(
                FeedThread(
                    id=uuid.uuid4(),
                    title=f"{DROUGHT_1[0]} {i}",
                    summary=DROUGHT_1[1],
                    last_item_at=T0 - timedelta(hours=i),
                )
            )
        item = await news(session, DROUGHT_2, T0 + timedelta(hours=1))
        model = Model(answer("T2"))
        await thread_news(session, model.threader())
        enum = model.bodies[0]["output_config"]["format"]["schema"]["properties"]["match"]
        assert len(enum["enum"]) == MAX_CANDIDATES + 1
        joined = await session.get(FeedThread, item.thread_id)
        assert joined is not None
        assert joined.title == DROUGHT_2[0]  # T2 is the second-newest; it now has this item


def test_pre_filter_signals() -> None:
    assert shares_signal("₹५,००० अग्रिम", "5000 रुपये")  # Devanagari digits, grouping
    assert shares_signal("दुष्काळग्रस्त टँकर", "दुष्काळी भागात टँकर")  # stems
    assert not shares_signal("दुष्काळ 2026", "पाऊस 2026")  # a year is no signal
    assert not shares_signal("शेतकऱ्यांना सरकार", "शेतकऱ्यांच्या सरकारने")  # common words
    assert not shares_signal(ORANGE_EXPORT[0], DROUGHT_1[0])


def test_question_lists_dates_and_ids() -> None:
    a = TopicText("A", None, T0)
    b = TopicText("B", "b", T0 - timedelta(days=1))
    text = render_question(a, [b])
    assert "<new_item date='2026-11-09'>" in text
    assert "<thread id='T1' date='2026-11-08'>" in text
    assert "summary: b" in text


# --- API ---------------------------------------------------------------------------------


async def thread_of(engine: AsyncEngine, *items: tuple[tuple[str, str], datetime]) -> list[str]:
    async with maker(engine)() as session:
        rows = [await news(session, t, when, lang="en") for t, when in items]
        thread = FeedThread(
            id=uuid.uuid4(), title="x", summary=None, last_item_at=max(w for _, w in items)
        )
        session.add(thread)
        await session.flush()
        for row in rows:
            row.thread_id = thread.id
        await session.commit()
        return [str(thread.id), *(str(r.id) for r in rows)]


async def test_feed_lists_threads_and_the_thread_timeline(
    api: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    now = datetime.now(UTC)
    thread_id, oldest, newest = await thread_of(
        engine, (DROUGHT_1, now - timedelta(days=2)), (DROUGHT_2, now - timedelta(days=1))
    )
    async with maker(engine)() as session:
        single = await news(session, ORANGE_EXPORT, now - timedelta(hours=1), lang="en")
        await session.commit()
    body = (await api.get("/v1/feed?lang=en", headers=auth_headers)).json()
    # Older apps keep every item; each news item carries its thread.
    by_id = {i["id"]: i for i in body["items"]}
    assert by_id[oldest]["thread_id"] == thread_id
    assert by_id[newest]["thread_id"] == thread_id
    assert by_id[str(single.id)]["thread_id"] is None
    (card,) = body["threads"]
    assert card["id"] == thread_id
    assert card["title"] == DROUGHT_2[0]  # the latest item's own title
    assert card["item_count"] == 2
    assert (card["unseen_count"], card["has_new"]) == (2, True)
    assert card["latest_at"] == by_id[newest]["published_at"]

    res = await api.get(f"/v1/feed/threads/{thread_id}?lang=en", headers=auth_headers)
    assert res.status_code == 200
    timeline = res.json()
    assert [i["id"] for i in timeline["items"]] == [oldest, newest]  # oldest first
    assert timeline["thread"]["item_count"] == 2
    assert timeline["footer"]

    await api.post(f"/v1/feed/{oldest}/seen", headers=auth_headers)
    card = (await api.get("/v1/feed?lang=en", headers=auth_headers)).json()["threads"][0]
    assert (card["unseen_count"], card["has_new"]) == (1, True)
    await api.post(f"/v1/feed/{newest}/seen", headers=auth_headers)
    card = (await api.get("/v1/feed?lang=en", headers=auth_headers)).json()["threads"][0]
    assert (card["unseen_count"], card["has_new"]) == (0, False)


async def test_thread_endpoint_hides_unpublished_and_unknown(
    api: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    missing = await api.get(f"/v1/feed/threads/{uuid.uuid4()}", headers=auth_headers)
    assert missing.status_code == 404
    thread_id, item_id = await thread_of(engine, (DROUGHT_1, datetime.now(UTC)))
    async with maker(engine)() as session:
        row = await session.get(FeedItem, uuid.UUID(item_id))
        assert row is not None
        row.status = "held"
        await session.commit()
    res = await api.get(f"/v1/feed/threads/{thread_id}", headers=auth_headers)
    assert res.status_code == 404
    assert (await api.get(f"/v1/feed/threads/{thread_id}")).status_code == 401


async def test_new_thread_is_written_before_the_item_points_at_it() -> None:
    """VPS 2026-11-12: Postgres refused the backfill (fk_feed_items_thread_id_feed_threads) because
    the item's thread_id was flushed before the new thread row. SQLite checks foreign keys only
    with the pragma on, so this test turns it on."""
    eng = create_async_engine(
        "sqlite+aiosqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )

    @event.listens_for(eng.sync_engine, "connect")
    def _fk_on(dbapi_conn: Any, _record: Any) -> None:
        dbapi_conn.execute("PRAGMA foreign_keys=ON")

    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    try:
        async with maker(eng)() as session:
            await news(session, DROUGHT_1, T0)
            await session.commit()
            run = await thread_news(session, Model().threader())
            await session.commit()
            assert run.new == 1
    finally:
        await eng.dispose()
