"""News topic threads (owner Q139, 2026-11-11).

Mahasamvad publishes one government decision from many districts under different links, so the
feed showed the same event as several cards. Each published news item is now put in a topic
thread: the app shows one card per thread and, when opened, a dated timeline of every item.

Rule (conservative: a wrong merge is worse than a duplicate):
- candidates are threads whose newest item is within THREAD_WINDOW of the new item and that share
  a signal with it (a number other than a year, or two word stems); at most MAX_CANDIDATES,
  newest first;
- no candidate: a new thread, no model call;
- otherwise ONE small structured-output call asks "same event / decision as thread X, or new";
  anything but a clear match, and every model error, starts a new thread.
The thread's title / summary are the latest item's checked title / summary, copied, never new
text. Items are threaded oldest first, only once (thread_id stays set), so the step and the
backfill (`thread_backfill.py`) are safe to repeat.
"""

from __future__ import annotations

import re
import uuid
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any, Protocol

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.feed.ai import AiUnavailableError, AnthropicFeedAi
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedThread
from bagmitra_api.feed.output_check import normalise

THREAD_WINDOW = timedelta(days=30)
MAX_CANDIDATES = 20
# Text languages in the order the matcher reads them (Mahasamvad writes Marathi).
TEXT_LANGS = ("mr", "en", "hi")
EVENT = "threaded"
STEM = 5
MIN_WORD = 4
MIN_SHARED_STEMS = 2
# Curly single quotes by code point (they look like a backtick to the linter).
_QUOTES = chr(0x2018) + chr(0x2019)
_SPLIT = re.compile(rf"[\s,.;:!?()\[\]{{}}\"'{_QUOTES}“”।॥\-–—/|+*=<>&%₹]+")
_NUMBER = re.compile(r"\d+")
_GROUPING = re.compile(r"(?<=\d),(?=\d)")
# Word stems almost every farm news item has; they are no sign of the same topic.
_COMMON = frozenset(
    w[:STEM]
    for w in (
        "शेतकरी", "शेतकऱ्यांना", "शेतकऱ्यांच्या", "सरकार", "शासन", "शासनाने", "राज्य",
        "राज्यात", "जिल्हा", "जिल्ह्यात", "महाराष्ट्र", "मंत्री", "मुख्यमंत्री", "करण्यात",
        "यांच्या", "यांनी", "किसान", "किसानों", "farmer", "farmers", "government", "state",
        "district", "minister", "maharashtra",
    )
)  # fmt: skip


@dataclass(frozen=True, slots=True)
class TopicText:
    """What the matcher compares: a checked title and summary with its date."""

    title: str
    summary: str | None
    when: datetime

    def joined(self) -> str:
        return f"{self.title}\n{self.summary or ''}"


class FeedThreader(Protocol):
    async def same_topic(self, item: TopicText, candidates: Sequence[TopicText]) -> int | None:
        """The index of the candidate that reports the same event or decision, or None (new).
        Raises AiUnavailableError when the model cannot answer."""
        ...


THREAD_PROMPT = """You group farm news for BagMitra, an app for Maharashtra farmers. <document>
holds one NEW news item and recent topic THREADS, each with an id (T1, T2, ...), a date, a title
and a summary. Decide whether the NEW item reports the SAME specific event or government decision
as one thread: for example the same relief package, the same payment, the same scheme decision or
the same order, reported from another district or as a later update of it.
Answer with JSON only: {"match": "<thread id>"} when it obviously is the same event or decision,
otherwise {"match": "new"}.
- A shared broad subject (drought, rain, a crop, a department) is NOT enough.
- Different amounts, dates or places that point to a different decision mean "new".
- If you are not sure, answer "new": a wrong merge is worse than a duplicate."""


def thread_schema(keys: Sequence[str]) -> dict[str, Any]:
    return {
        "type": "object",
        "properties": {"match": {"type": "string", "enum": [*keys, "new"]}},
        "required": ["match"],
        "additionalProperties": False,
    }


def _block(tag: str, attrs: str, t: TopicText) -> str:
    return (
        f"<{tag}{attrs} date='{t.when.date().isoformat()}'>\n"
        f"title: {t.title}\nsummary: {t.summary or ''}\n</{tag}>"
    )


def render_question(item: TopicText, candidates: Sequence[TopicText]) -> str:
    threads = [_block("thread", f" id='T{i + 1}'", c) for i, c in enumerate(candidates)]
    return "\n".join([_block("new_item", "", item), *threads])


def _signals(text: str) -> tuple[set[str], set[str]]:
    """(numbers, word stems) of a text: numbers of two or more digits other than years, and the
    first STEM letters of longer words, so Marathi endings (दुष्काळी / दुष्काळग्रस्त) match."""
    numbers: set[str] = set()
    stems: set[str] = set()
    # Indian digit grouping (5,000 / 1,00,000) is one number.
    flat = _GROUPING.sub("", normalise(text))
    for token in _SPLIT.split(flat):
        digits = _NUMBER.findall(token)
        numbers |= {str(int(d)) for d in digits if len(d) >= 2 and not 1900 <= int(d) <= 2100}
        if not digits and len(token) >= MIN_WORD and token[:STEM] not in _COMMON:
            stems.add(token[:STEM])
    return numbers, stems


def shares_signal(a: str, b: str) -> bool:
    """The cheap pre-filter: one shared number, or MIN_SHARED_STEMS shared word stems."""
    a_numbers, a_stems = _signals(a)
    b_numbers, b_stems = _signals(b)
    return bool(a_numbers & b_numbers) or len(a_stems & b_stems) >= MIN_SHARED_STEMS


def _aware(when: datetime) -> datetime:
    # SQLite gives naive datetimes back; the database stores UTC.
    return when if when.tzinfo else when.replace(tzinfo=UTC)


async def topic_text(session: AsyncSession, item: FeedItem) -> TopicText | None:
    rows = {
        r.lang: r
        for r in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
    }
    for lang in (*TEXT_LANGS, *sorted(rows)):
        row = rows.get(lang)
        if row is not None and row.title.strip():
            return TopicText(row.title, row.summary, _aware(item.published_at))
    return None


async def candidates(session: AsyncSession, item: TopicText) -> list[tuple[FeedThread, TopicText]]:
    rows = await session.scalars(
        select(FeedThread)
        .where(
            FeedThread.last_item_at >= item.when - THREAD_WINDOW,
            FeedThread.last_item_at <= item.when + THREAD_WINDOW,
        )
        .order_by(FeedThread.last_item_at.desc(), FeedThread.id)
    )
    found = []
    for thread in rows:
        text = TopicText(thread.title, thread.summary, _aware(thread.last_item_at))
        if shares_signal(item.joined(), text.joined()):
            found.append((thread, text))
            if len(found) >= MAX_CANDIDATES:
                break
    return found


class AnthropicThreader:
    """The topic question over the feed's Messages API path: the cheap classify model and a
    small structured-output answer (an enum of the candidate ids or "new")."""

    def __init__(self, ai: AnthropicFeedAi) -> None:
        self._ai = ai

    async def same_topic(self, item: TopicText, candidates: Sequence[TopicText]) -> int | None:
        keys = [f"T{i + 1}" for i in range(len(candidates))]
        answer = await self._ai.ask_small_json(
            THREAD_PROMPT, render_question(item, candidates), schema=thread_schema(keys)
        )
        match = answer.get("match")
        return keys.index(match) if isinstance(match, str) and match in keys else None


@dataclass(slots=True)
class ThreadRun:
    joined: int = 0
    new: int = 0
    model_calls: int = 0
    ai_errors: int = 0
    skipped_reason: str | None = None


async def thread_item(
    session: AsyncSession, item: FeedItem, threader: FeedThreader, run: ThreadRun
) -> FeedThread | None:
    """Puts one published news item in a thread; None (left unthreaded) without any text."""
    text = await topic_text(session, item)
    if text is None:
        return None
    found = await candidates(session, text)
    chosen: FeedThread | None = None
    reason = "no_candidates"
    if found:
        run.model_calls += 1
        reason = "model"
        try:
            index = await threader.same_topic(text, [t for _, t in found])
        except AiUnavailableError as exc:
            run.ai_errors += 1
            reason, index = f"ai_error: {str(exc)[:200]}", None
        if index is not None and 0 <= index < len(found):
            chosen = found[index][0]
    joined = chosen is not None
    if chosen is None:
        chosen = FeedThread(
            id=uuid.uuid4(), title=text.title[:500], summary=text.summary, last_item_at=text.when
        )
        session.add(chosen)
        run.new += 1
    else:
        run.joined += 1
        if text.when >= _aware(chosen.last_item_at):
            chosen.title, chosen.summary = text.title[:500], text.summary
            chosen.last_item_at = text.when
    item.thread_id = chosen.id
    session.add(
        FeedReviewEvent(
            id=uuid.uuid4(),
            item_id=item.id,
            actor_id=None,
            kind=EVENT,
            detail={
                "thread_id": str(chosen.id),
                "joined": joined,
                "candidates": len(found),
                "reason": reason,
            },
        )
    )
    await session.flush()
    return chosen


async def thread_news(
    session: AsyncSession, threader: FeedThreader | None, *, limit: int | None = None
) -> ThreadRun:
    """Threads every published news item that has no thread yet, oldest first (so a later update
    joins the earlier report). Without a model (FEED_AI_API_KEY empty) nothing is threaded: the
    items stay single cards and are threaded by the first run that has the model."""
    run = ThreadRun()
    if threader is None:
        run.skipped_reason = "FEED_AI_API_KEY is not set"
        return run
    query = (
        select(FeedItem)
        .where(
            FeedItem.type == "news",
            FeedItem.status == "published",
            FeedItem.thread_id.is_(None),
        )
        .order_by(FeedItem.published_at, FeedItem.id)
    )
    if limit is not None:
        query = query.limit(limit)
    for item in list(await session.scalars(query)):
        await thread_item(session, item, threader, run)
    return run
