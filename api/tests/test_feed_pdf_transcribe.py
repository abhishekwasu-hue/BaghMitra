"""Owner 2026-11-13 (OPEN_QUESTIONS Q152): an official PDF whose text layer is legacy-font
garbage (`text_broken`) is transcribed by the model from the PDF itself (document block,
base64, application/pdf); the transcription becomes the item's text and the normal official
article path runs on it. No live network: httpx.MockTransport answers every request."""

from __future__ import annotations

import base64
import json
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.feed.ai import (
    FALLBACK_BETA,
    AiBadAnswerError,
    AiRefusedError,
    AiUnavailableError,
    AnthropicFeedAi,
)
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent
from bagmitra_api.feed.official_items import ATTEMPT, write_official_items
from bagmitra_api.feed.pdf_transcribe import TRANSCRIBE_SCHEMA, Transcription
from bagmitra_api.feed.portal_job import run_portals
from tests.feed_docs import KRUTI_DEV, make_pdf
from tests.test_feed_article import SOURCE
from tests.test_feed_portals import GR_PDF, FakeAi, Site, adapter, listed, settings

NOW = datetime(2026, 11, 13, 6, tzinfo=UTC)
BROKEN_PDF = make_pdf([KRUTI_DEV])
PDF_HEADERS = {"content-type": "application/pdf"}


def pdf_site(data: bytes = BROKEN_PDF) -> Site:
    return Site({GR_PDF: httpx.Response(200, content=data, headers=PDF_HEADERS)})


class FakeTranscriber:
    """Answers in turn from `answers` (a Transcription or an exception); logs the bytes."""

    def __init__(self, *answers: Transcription | Exception) -> None:
        self.answers = list(answers) or [Transcription(SOURCE, 1, True, "claude-sonnet-5-5")]
        self.seen: list[bytes] = []

    async def transcribe_pdf(self, data: bytes) -> Transcription:
        self.seen.append(data)
        answer = self.answers.pop(0) if len(self.answers) > 1 else self.answers[0]
        if isinstance(answer, Exception):
            raise answer
        return answer


async def events(session: AsyncSession, kind: str) -> list[FeedReviewEvent]:
    rows = await session.scalars(select(FeedReviewEvent).where(FeedReviewEvent.kind == kind))
    return list(rows)


# --- the request -------------------------------------------------------------------------------


def sse(*events: dict[str, Any]) -> bytes:
    return "".join(f"event: {e['type']}\ndata: {json.dumps(e)}\n\n" for e in events).encode()


def streamed_answer(text: str, stop: str = "end_turn") -> bytes:
    half = len(text) // 2
    return sse(
        {"type": "message_start", "message": {"model": "claude-sonnet-5-5"}},
        {"type": "content_block_start", "index": 0, "content_block": {"type": "thinking"}},
        {"type": "content_block_delta", "index": 0, "delta": {"type": "thinking_delta"}},
        {"type": "content_block_start", "index": 1, "content_block": {"type": "text"}},
        {
            "type": "content_block_delta",
            "index": 1,
            "delta": {"type": "text_delta", "text": text[:half]},
        },
        {
            "type": "content_block_delta",
            "index": 1,
            "delta": {"type": "text_delta", "text": text[half:]},
        },
        {"type": "message_delta", "delta": {"stop_reason": stop}},
        {"type": "message_stop"},
    )


def model_client(answer: httpx.Response, seen: list[httpx.Request]) -> httpx.AsyncClient:
    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return answer

    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


async def test_the_pdf_goes_as_a_base64_document_block_and_the_answer_is_read() -> None:
    seen: list[httpx.Request] = []
    answer = {"text": SOURCE, "pages_read": 1, "legible": True}
    http = model_client(httpx.Response(200, content=streamed_answer(json.dumps(answer))), seen)
    ai = AnthropicFeedAi(http, settings(feed_ai_api_key="k"))
    found = await ai.transcribe_pdf(BROKEN_PDF)
    assert found == Transcription(SOURCE, 1, True, "claude-sonnet-5-5")
    [request] = seen
    body = json.loads(request.content)
    assert body["model"] == "claude-sonnet-5-5"  # FEED_PDF_TRANSCRIBE_MODEL empty: summariser's
    assert body["stream"] is True
    [document, question] = body["messages"][0]["content"]
    assert document["type"] == "document"
    assert document["source"]["type"] == "base64"
    assert document["source"]["media_type"] == "application/pdf"
    assert "\n" not in document["source"]["data"]
    assert base64.b64decode(document["source"]["data"]) == BROKEN_PDF
    assert question["type"] == "text"
    assert body["output_config"]["format"] == {"type": "json_schema", "schema": TRANSCRIBE_SCHEMA}
    assert "[अस्पष्ट]" in body["system"]
    assert body["fallbacks"] == "default"
    assert request.headers["anthropic-beta"] == FALLBACK_BETA
    assert request.headers["x-api-key"] == "k"

    own = AnthropicFeedAi(
        model_client(httpx.Response(200, content=streamed_answer(json.dumps(answer))), seen),
        settings(feed_ai_api_key="k", feed_pdf_transcribe_model="claude-opus-5-5"),
    )
    assert (await own.transcribe_pdf(BROKEN_PDF)).model == "claude-opus-5-5"


@pytest.mark.parametrize(
    ("answer", "error"),
    [
        (httpx.Response(529), AiUnavailableError),
        (httpx.Response(200, content=streamed_answer("", "refusal")), AiRefusedError),
        (httpx.Response(200, content=streamed_answer("no json here")), AiBadAnswerError),
        (
            httpx.Response(
                200, content=sse({"type": "error", "error": {"type": "overloaded_error"}})
            ),
            AiUnavailableError,
        ),
    ],
)
async def test_outage_refusal_and_bad_answers_are_told_apart(
    answer: httpx.Response, error: type[Exception]
) -> None:
    ai = AnthropicFeedAi(model_client(answer, []), settings(feed_ai_api_key="k"))
    with pytest.raises(error) as raised:
        await ai.transcribe_pdf(BROKEN_PDF)
    assert type(raised.value) is error


# --- the official path -------------------------------------------------------------------------


async def test_a_legacy_font_pdf_is_transcribed_and_published(engine: AsyncEngine) -> None:
    ai, reader = FakeAi(), FakeTranscriber()
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        run = await write_official_items(session, adapter(pdf_site()), ai, settings(), NOW, reader)
        assert (run.published, run.held) == (1, 0), item.check_issues
        assert run.transcribe.as_dict() == {
            "calls": 1,
            "ok": 1,
            "illegible": 0,
            "skipped_large": 0,
            "errors": 0,
        }
        assert reader.seen == [BROKEN_PDF]
        assert item.extracted_text == SOURCE  # the article path ran on the transcription
        assert ai.calls == ["classify", "write_article", "summarise"]
        assert item.status == "published"
        [provenance] = await events(session, "pdf_transcribed")
        assert provenance.detail["model"] == "claude-sonnet-5-5"
        assert (provenance.detail["pages"], provenance.detail["pages_read"]) == (1, 1)
        [attempt] = await events(session, ATTEMPT)
        assert attempt.detail == {"result": "published", "transcribed": True}
        # The PDF itself is not stored: only its hash and size.
        assert item.raw_bytes == len(BROKEN_PDF)
        assert item.raw_hash is not None
        b64 = base64.b64encode(BROKEN_PDF).decode()
        for event in await session.scalars(select(FeedReviewEvent)):
            assert b64[:40] not in json.dumps(event.detail)
            assert KRUTI_DEV not in json.dumps(event.detail, ensure_ascii=False)
        for row in await session.scalars(select(FeedItemI18n)):
            assert b64[:40] not in json.dumps(row.article)
        # Done: a second run asks nothing.
        again = await write_official_items(
            session, adapter(pdf_site()), ai, settings(), NOW + timedelta(hours=12), reader
        )
        assert (again.published, again.transcribe.calls, len(reader.seen)) == (0, 0, 1)


async def test_an_illegible_or_declined_pdf_stays_held_and_is_not_asked_again(
    engine: AsyncEngine,
) -> None:
    for answer in (Transcription("", 1, False, "m"), AiRefusedError("declined")):
        async with async_sessionmaker(engine)() as session:
            ai, reader = FakeAi(), FakeTranscriber(answer)
            item = await listed(session, NOW)
            run = await write_official_items(
                session, adapter(pdf_site()), ai, settings(), NOW, reader
            )
            assert (run.held, item.status, item.extracted_text) == (1, "held", None)
            assert item.check_issues[0]["kind"] == "text_broken"
            assert ai.calls == []
            for hours in (12, 24):
                later = NOW + timedelta(hours=hours)
                await write_official_items(
                    session, adapter(pdf_site()), ai, settings(), later, reader
                )
            assert len(reader.seen) == 1  # one attempt, never repeated
            assert item.status == "held"
            await session.rollback()


async def test_a_transcription_that_is_not_marathi_counts_as_illegible(engine: AsyncEngine) -> None:
    reader = FakeTranscriber(Transcription(KRUTI_DEV, 1, True, "m"))
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        run = await write_official_items(
            session, adapter(pdf_site()), FakeAi(), settings(), NOW, reader
        )
        assert (run.transcribe.illegible, item.status, item.extracted_text) == (1, "held", None)


async def test_a_large_pdf_is_not_sent(engine: AsyncEngine) -> None:
    reader = FakeTranscriber()
    big = make_pdf([KRUTI_DEV, KRUTI_DEV, KRUTI_DEV])
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        small = settings(feed_pdf_transcribe_max_pages=2)
        run = await write_official_items(
            session, adapter(pdf_site(big)), FakeAi(), small, NOW, reader
        )
        assert (run.transcribe.skipped_large, run.transcribe.calls, reader.seen) == (1, 0, [])
        assert item.status == "held"
        assert "not sent for transcription: 3 pages" in item.check_issues[0]["text"]
        later = NOW + timedelta(hours=12)
        await write_official_items(session, adapter(pdf_site(big)), FakeAi(), small, later, reader)
        assert reader.seen == []  # final: not tried again


async def test_the_daily_transcription_cap_is_kept(engine: AsyncEngine) -> None:
    reader = FakeTranscriber()
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        none_left = settings(feed_pdf_transcribe_daily=0)
        run = await write_official_items(
            session, adapter(pdf_site()), FakeAi(), none_left, NOW, reader
        )
        assert (run.held, run.transcribe.calls, reader.seen) == (1, 0, [])
        assert "FEED_PDF_TRANSCRIBE_DAILY" in item.check_issues[0]["text"]
        # The cap is apart from FEED_AI_DAILY_ITEMS, and the held listing gets its turn later.
        later = NOW + timedelta(days=1)
        run = await write_official_items(
            session,
            adapter(pdf_site()),
            FakeAi(),
            settings(feed_pdf_transcribe_daily=1),
            later,
            reader,
        )
        assert (run.published, run.transcribe.ok, item.status) == (1, 1, "published")


async def test_the_daily_cap_counts_the_requests_of_the_day(engine: AsyncEngine) -> None:
    reader = FakeTranscriber(AiUnavailableError("HTTP 529"))
    one = settings(feed_pdf_transcribe_daily=1)
    async with async_sessionmaker(engine)() as session:
        await listed(session, NOW)
        await write_official_items(session, adapter(pdf_site()), FakeAi(), one, NOW, reader)
        later = NOW + timedelta(hours=6)  # same UTC day: the request is counted
        run = await write_official_items(session, adapter(pdf_site()), FakeAi(), one, later, reader)
        assert (run.transcribe.calls, len(reader.seen)) == (0, 1)


async def test_an_unreachable_api_is_tried_again_on_the_next_run(engine: AsyncEngine) -> None:
    reader = FakeTranscriber(AiUnavailableError("HTTP 529"), Transcription(SOURCE, 1, True, "m"))
    ai = FakeAi()
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        run = await write_official_items(session, adapter(pdf_site()), ai, settings(), NOW, reader)
        assert (run.transcribe.errors, run.held, item.status) == (1, 1, "held")
        assert "tried again on the next run" in item.check_issues[0]["text"]
        later = NOW + timedelta(days=1)
        run = await write_official_items(
            session, adapter(pdf_site()), ai, settings(), later, reader
        )
        assert (run.transcribe.ok, run.published, item.status) == (1, 1, "published")
        assert item.extracted_text == SOURCE
        # A held listing whose document cannot be fetched keeps its reason for the next run.
        assert len(reader.seen) == 2


async def test_a_held_listing_whose_fetch_fails_keeps_waiting(engine: AsyncEngine) -> None:
    reader = FakeTranscriber(AiUnavailableError("HTTP 529"), Transcription(SOURCE, 1, True, "m"))
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        await write_official_items(session, adapter(pdf_site()), FakeAi(), settings(), NOW, reader)
        reason = item.check_issues[0]["text"]
        down = Site({GR_PDF: httpx.Response(503)})
        later = NOW + timedelta(days=1)
        await write_official_items(session, adapter(down), FakeAi(), settings(), later, reader)
        assert (item.status, item.check_issues[0]["text"]) == ("held", reason)
        run = await write_official_items(
            session, adapter(pdf_site()), FakeAi(), settings(), later + timedelta(days=1), reader
        )
        assert run.published == 1


async def test_after_an_article_outage_the_stored_transcription_is_used(
    engine: AsyncEngine,
) -> None:
    reader = FakeTranscriber()
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        run = await write_official_items(
            session, adapter(pdf_site()), FakeAi(fail=True), settings(), NOW, reader
        )
        assert (run.retry, item.status, item.extracted_text) == (1, "in_review", SOURCE)
        site = pdf_site()
        later = NOW + timedelta(hours=12)
        run = await write_official_items(
            session, adapter(site), FakeAi(), settings(), later, reader
        )
        assert (run.published, len(reader.seen)) == (1, 1)  # no second transcription
        assert GR_PDF not in site.calls  # nor a second fetch


async def test_an_old_held_listing_gets_its_transcription(engine: AsyncEngine) -> None:
    """The VPS state: listings held `text_broken` before this step existed (no transcriber)."""
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        await write_official_items(session, adapter(pdf_site()), FakeAi(), settings(), NOW)
        assert item.check_issues == [
            {
                "kind": "text_broken",
                "text": "almost no Devanagari in a Marathi document",
                "where": "extracted_text",
            }
        ]
        reader = FakeTranscriber()
        later = NOW + timedelta(days=1)
        run = await write_official_items(
            session, adapter(pdf_site()), FakeAi(), settings(), later, reader
        )
        assert (run.published, run.transcribe.ok, item.status) == (1, 1, "published")


async def test_the_job_summary_has_the_transcription_counts(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        summary = await run_portals(
            session, adapter(Site({})), FakeAi(), settings(), NOW, FakeTranscriber()
        )
    data = json.loads(summary.to_json())
    assert data["pdf_transcribe"] == {
        "calls": 0,
        "ok": 0,
        "illegible": 0,
        "skipped_large": 0,
        "errors": 0,
    }
    assert "transcribe" not in data["official"]


async def test_the_real_adapter_end_to_end(engine: AsyncEngine) -> None:
    """Transcriber = AnthropicFeedAi over MockTransport; article path = the fake writer."""
    seen: list[httpx.Request] = []
    answer = {"text": SOURCE, "pages_read": 1, "legible": True}
    http = model_client(httpx.Response(200, content=streamed_answer(json.dumps(answer))), seen)
    reader = AnthropicFeedAi(http, settings(feed_ai_api_key="k"))
    async with async_sessionmaker(engine)() as session:
        item = await listed(session, NOW)
        run = await write_official_items(
            session, adapter(pdf_site()), FakeAi(), settings(), NOW, reader
        )
        assert (run.published, item.extracted_text, len(seen)) == (1, SOURCE, 1)
        stored = await session.scalar(select(FeedItem).where(FeedItem.id == item.id))
        assert stored is not None
        assert stored.raw_bytes == len(BROKEN_PDF)
