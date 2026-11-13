"""AI step for listings from official portals (owner 2026-11-12, OPEN_QUESTIONS Q145).

For each official listing still waiting (status in_review, added by a portal adapter, no
finished attempt), from a source whose terms are `allowed`:
1. read its document politely (robots, spacing, MAX_DOCUMENT_BYTES) and keep its SHA-256 and
   size; extract the text (PDF text layer / HTML visible text, `feed/extract.py`). Only `ok`
   text is stored as the item's text: a scanned document is held for a person; a legacy-font
   PDF (text `broken`) is transcribed by the model first (owner 2026-11-13, Q152,
   `feed/pdf_transcribe.py`) and held only when that is not possible;
2. classify it (`gr | circular | scheme | alert`, categories `deadline | payment | new_scheme
   …`); an irrelevant document goes to `draft`;
3. write the article set (mr / hi / en) from that text and check it (`check_articles`);
4. a scheme also gets its scheme card from the summariser ("quote or not_stated");
5. the output check (`run_output_check`) compares every title, summary and card field with
   the stored text. Any issue holds the item (admin web, status "held"); otherwise it is
   published (FEED_AUTO_PUBLISH; false: it waits for a feed_admin approval).
At most FEED_AI_DAILY_ITEMS such attempts per UTC day (counted apart from the news articles).
Without a model key (FEED_AI_API_KEY empty) nothing happens and the listings wait.

Transcription (Q152): one request per PDF, at most FEED_PDF_TRANSCRIBE_DAILY per UTC day
(`pdf_transcribe` review events, counted apart from FEED_AI_DAILY_ITEMS). A listing held
earlier for a broken text gets its one transcription on a later run. Final results (never
asked again): `ok` (the text is stored, review event `pdf_transcribed` with model and pages),
`illegible`, `refused`, `cut_off`, `unusable`, `skipped_large`. Only `retry` (the API could not
be reached) is asked again on the next run.
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass, field
from datetime import datetime, time
from typing import Any, Protocol

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import (
    AiBadAnswerError,
    AiCutOffError,
    AiRefusedError,
    AiUnavailableError,
    Classification,
    Summary,
)
from bagmitra_api.feed.article import ArticleSet, check_articles
from bagmitra_api.feed.extract import assess, extract
from bagmitra_api.feed.gr_portal import FetchFailedError, GrPortalAdapter
from bagmitra_api.feed.models import FeedItem, FeedReviewEvent, FeedSchemeCard, FeedSource
from bagmitra_api.feed.news_articles import _store
from bagmitra_api.feed.pdf_transcribe import PDF_MAX_BYTES, Transcription
from bagmitra_api.feed.service import latest_card, run_output_check, sync_deadlines

ATTEMPT = "ai_official"
FINAL = ("published", "held", "draft", "review")
OFFICIAL_KINDS = ("gr", "circular", "scheme", "alert")
# Review-event `via` of the listings this step handles (manual uploads stay with the admin).
PORTAL_VIA = ("gr_portal", "official_portal")
# One event per transcription decision (detail.result) and the provenance of a stored text.
TRANSCRIBE = "pdf_transcribe"
TRANSCRIBED = "pdf_transcribed"
TRANSCRIBE_FINAL = ("ok", "illegible", "refused", "cut_off", "unusable", "skipped_large")
# Results that made a model request (the daily FEED_PDF_TRANSCRIBE_DAILY count).
TRANSCRIBE_CALLS = ("ok", "illegible", "refused", "cut_off", "unusable", "retry")
TEXT_BROKEN = "text_broken"


class OfficialAi(Protocol):
    async def classify(self, text: str) -> Classification: ...

    async def summarise(self, text: str) -> Summary: ...

    async def write_article(self, text: str, *, source_url: str) -> ArticleSet: ...


class PdfTranscriber(Protocol):
    async def transcribe_pdf(self, data: bytes) -> Transcription: ...


@dataclass(slots=True)
class TranscribeRun:
    calls: int = 0
    ok: int = 0
    illegible: int = 0
    skipped_large: int = 0
    errors: int = 0
    # Requests still allowed today, and the items whose text is a transcription.
    room: int = 0
    texts: set[uuid.UUID] = field(default_factory=set)

    def as_dict(self) -> dict[str, int]:
        return {
            "calls": self.calls,
            "ok": self.ok,
            "illegible": self.illegible,
            "skipped_large": self.skipped_large,
            "errors": self.errors,
        }


@dataclass(slots=True)
class OfficialRun:
    published: int = 0
    held: int = 0
    drafted: int = 0
    review: int = 0
    retry: int = 0
    skipped_reason: str | None = None
    transcribe: TranscribeRun = field(default_factory=TranscribeRun)

    def as_dict(self) -> dict[str, Any]:
        return {
            "published": self.published,
            "held": self.held,
            "drafted": self.drafted,
            "review": self.review,
            "retry": self.retry,
            "skipped_reason": self.skipped_reason,
        }


def _event(
    item: FeedItem, kind: str, at: datetime | None = None, **detail: object
) -> FeedReviewEvent:
    event = FeedReviewEvent(
        id=uuid.uuid4(), item_id=item.id, actor_id=None, kind=kind, detail=detail
    )
    if at is not None:
        event.created_at = at
    return event


async def _count_today(
    session: AsyncSession, now: datetime, kind: str, results: tuple[str, ...] | None = None
) -> int:
    start = datetime.combine(now.date(), time.min, tzinfo=now.tzinfo)
    query = (
        select(func.count())
        .select_from(FeedReviewEvent)
        .where(FeedReviewEvent.kind == kind, FeedReviewEvent.created_at >= start)
    )
    if results is not None:
        query = query.where(FeedReviewEvent.detail["result"].as_string().in_(results))
    return int(await session.scalar(query) or 0)


async def _calls_today(session: AsyncSession, now: datetime) -> int:
    return await _count_today(session, now, ATTEMPT)


def _from_portal() -> Any:
    return select(FeedReviewEvent.item_id).where(
        FeedReviewEvent.kind == "created",
        FeedReviewEvent.detail["via"].as_string().in_(PORTAL_VIA),
    )


def _official() -> Any:
    return (
        select(FeedItem)
        .join(FeedSource, FeedSource.id == FeedItem.source_id)
        .where(
            FeedSource.tier == "official",
            FeedSource.terms_status == "allowed",
            FeedItem.type.in_(OFFICIAL_KINDS),
            FeedItem.id.in_(_from_portal()),
        )
    )


async def waiting(session: AsyncSession, limit: int) -> list[FeedItem]:
    """Portal listings of allowed official sources without a finished attempt, newest first."""
    finished = select(FeedReviewEvent.item_id).where(
        FeedReviewEvent.kind == ATTEMPT,
        FeedReviewEvent.detail["result"].as_string().in_(FINAL),
    )
    rows = await session.scalars(
        _official()
        .where(FeedItem.status == "in_review", FeedItem.id.not_in(finished))
        .order_by(FeedItem.published_at.desc())
        .limit(limit)
    )
    return list(rows)


async def after_transcription(session: AsyncSession) -> list[FeedItem]:
    """Q152: portal listings still due their one transcription (held for a broken text, no
    final `pdf_transcribe` result) or transcribed but without a finished article attempt on
    that text (the article model was unavailable), newest first."""
    transcribed_final = select(FeedReviewEvent.item_id).where(
        FeedReviewEvent.kind == TRANSCRIBE,
        FeedReviewEvent.detail["result"].as_string().in_(TRANSCRIBE_FINAL),
    )
    rows = list(
        await session.scalars(
            _official()
            .where(FeedItem.status.in_(("held", "in_review")))
            .order_by(FeedItem.published_at.desc())
        )
    )
    if not rows:
        return []
    ids = [r.id for r in rows]
    final_ids = set(
        await session.scalars(transcribed_final.where(FeedReviewEvent.item_id.in_(ids)))
    )
    events = list(
        await session.scalars(
            select(FeedReviewEvent).where(
                FeedReviewEvent.item_id.in_(ids),
                FeedReviewEvent.kind.in_((TRANSCRIBED, ATTEMPT)),
            )
        )
    )
    transcribed = {e.item_id for e in events if e.kind == TRANSCRIBED}
    done = {
        e.item_id
        for e in events
        if e.kind == ATTEMPT and e.detail.get("transcribed") and e.detail.get("result") in FINAL
    }
    due: list[FeedItem] = []
    for item in rows:
        broken = any(i.get("kind") == TEXT_BROKEN for i in item.check_issues or [])
        if item.status == "held" and item.extracted_text is None and broken:
            if item.id not in final_ids:
                due.append(item)
        elif (
            item.status == "in_review"
            and item.extracted_text
            and item.id in transcribed
            and item.id not in done
        ):
            due.append(item)
    return due


async def _was_transcribed(session: AsyncSession, item: FeedItem) -> bool:
    found = await session.scalar(
        select(FeedReviewEvent.id)
        .where(FeedReviewEvent.item_id == item.id, FeedReviewEvent.kind == TRANSCRIBED)
        .limit(1)
    )
    return found is not None


def _hold(item: FeedItem, kind: str, text: str, where: str) -> str:
    item.status = "held"
    item.check_issues = [{"kind": kind, "text": text[:500], "where": where}]
    return "held"


async def _card(session: AsyncSession, item: FeedItem, summary: Summary) -> None:
    current = await latest_card(session, item.id)
    session.add(
        FeedSchemeCard(
            id=uuid.uuid4(),
            item_id=item.id,
            version=(current.version + 1) if current else 1,
            fields={k: dict(v) for k, v in summary.fields.items()},
        )
    )


async def _transcribed(  # noqa: PLR0913 - the PDF, its extraction and the run
    session: AsyncSession,
    item: FeedItem,
    data: bytes,
    pages: int,
    reason: str,
    transcriber: PdfTranscriber,
    settings: Settings,
    now: datetime,
    run: TranscribeRun,
) -> str | None:
    """Q152: the model's transcription of a broken-text PDF, or None (the item is then held
    with the reason; a final result is never asked again)."""
    limit = settings.feed_pdf_transcribe_max_pages
    if pages > limit or len(data) > PDF_MAX_BYTES:
        run.skipped_large += 1
        session.add(
            _event(item, TRANSCRIBE, now, result="skipped_large", pages=pages, bytes=len(data))
        )
        why = f"{pages} pages / {len(data)} bytes, over FEED_PDF_TRANSCRIBE_MAX_PAGES ({limit})"
        _hold(item, TEXT_BROKEN, f"{reason}; not sent for transcription: {why}", "extracted_text")
        return None
    if run.room <= 0:
        why = "waits for transcription (FEED_PDF_TRANSCRIBE_DAILY reached today)"
        _hold(item, TEXT_BROKEN, f"{reason}; {why}", "extracted_text")
        return None
    run.room -= 1
    run.calls += 1
    try:
        found = await transcriber.transcribe_pdf(data)
    except (AiRefusedError, AiCutOffError, AiBadAnswerError) as exc:
        result = {AiRefusedError: "refused", AiCutOffError: "cut_off"}.get(type(exc), "unusable")
        run.errors += 1
        session.add(_event(item, TRANSCRIBE, now, result=result, reason=str(exc)[:300]))
        _hold(item, TEXT_BROKEN, f"{reason}; transcription {result}: {exc}", "extracted_text")
        return None
    except AiUnavailableError as exc:
        run.errors += 1
        session.add(_event(item, TRANSCRIBE, now, result="retry", reason=str(exc)[:300]))
        why = f"transcription tried again on the next run ({exc})"
        _hold(item, TEXT_BROKEN, f"{reason}; {why}", "extracted_text")
        return None
    quality, ratio, bad = assess(found.text, expect_marathi=True)
    detail = {"model": found.model, "pages": pages, "pages_read": found.pages_read}
    if not found.legible or quality != "ok":
        run.illegible += 1
        why = "the model found it not legible" if not found.legible else bad or quality
        session.add(_event(item, TRANSCRIBE, now, result="illegible", reason=why, **detail))
        _hold(item, TEXT_BROKEN, f"{reason}; transcription: {why}", "extracted_text")
        return None
    run.ok += 1
    run.texts.add(item.id)
    session.add(_event(item, TRANSCRIBE, now, result="ok", **detail))
    session.add(
        _event(item, TRANSCRIBED, now, devanagari_ratio=ratio, chars=len(found.text), **detail)
    )
    item.status = "in_review"
    item.check_issues = []
    return found.text


async def process_one(  # noqa: PLR0913 - one listing
    session: AsyncSession,
    item: FeedItem,
    adapter: GrPortalAdapter,
    ai: OfficialAi,
    settings: Settings,
    now: datetime,
    transcriber: PdfTranscriber | None = None,
    run: TranscribeRun | None = None,
) -> str:
    if item.extracted_text and await _was_transcribed(session, item):
        # Transcribed on an earlier run: the stored transcription is the text (no new fetch,
        # never a second transcription).
        if run is not None:
            run.texts.add(item.id)
        return await _write(session, item, ai, settings, now, item.extracted_text)
    try:
        data, kind = await adapter.document(item.url)
    except FetchFailedError as exc:
        if item.status == "held":  # a held listing keeps its reason and is tried again
            return "retry"
        return _hold(item, "fetch", exc.reason, "document")
    item.raw_hash, item.raw_bytes = hashlib.sha256(data).hexdigest(), len(data)
    found = extract(data, kind, expect_marathi=True)
    session.add(
        _event(item, "extracted", method=found.method, quality=found.quality, pages=found.pages)
    )
    text = found.text if found.quality == "ok" else None
    if text is None:
        reason = found.reason or found.quality
        if found.quality != "broken" or kind != "pdf" or transcriber is None or run is None:
            return _hold(item, f"text_{found.quality}", reason, "extracted_text")
        text = await _transcribed(
            session, item, data, found.pages, reason, transcriber, settings, now, run
        )
        if text is None:
            return "held"
    elif item.status == "held":  # the document now reads (it was replaced): a fresh attempt
        item.status, item.check_issues = "in_review", []
    item.extracted_text = text
    return await _write(session, item, ai, settings, now, text)


async def _write(  # noqa: PLR0913 - the article step of one listing
    session: AsyncSession,
    item: FeedItem,
    ai: OfficialAi,
    settings: Settings,
    now: datetime,
    text: str,
) -> str:
    """Classify, article, scheme card and the checks against `text` (the stored text)."""
    try:
        sort = await ai.classify(text)
        session.add(
            _event(
                item,
                "classified",
                relevant=sort.relevant,
                item_kind=sort.kind,
                categories=sort.categories,
                crops=sort.crops,
                districts=sort.districts,
            )
        )
        if not sort.relevant:
            item.status = "draft"
            return "draft"
        item.type = sort.kind
        article = await ai.write_article(text, source_url=item.url)
        if not article.relevant or article.political:
            item.status = "draft"
            return "draft"
        summary = await ai.summarise(text) if item.type == "scheme" else None
    except AiUnavailableError as exc:
        session.add(_event(item, ATTEMPT, now, result="retry", reason=str(exc)[:300]))
        return "retry"
    await _store(session, item, article)
    if summary is not None:
        await _card(session, item, summary)
    await session.flush()
    problems = check_articles(text, article, source_url=item.url)
    issues = [{"kind": "article", "text": p, "where": ""} for p in problems]
    issues += await run_output_check(session, item, settings, None)
    item.check_issues = issues
    if issues:
        item.status = "held"
        return "held"
    if not settings.feed_auto_publish:
        return "review"
    item.status = "published"
    await sync_deadlines(session, item)
    session.add(_event(item, "auto_published"))
    return "published"


def _count(run: OfficialRun, outcome: str) -> None:
    run.published += outcome == "published"
    run.held += outcome == "held"
    run.drafted += outcome == "draft"
    run.review += outcome == "review"
    run.retry += outcome == "retry"


async def write_official_items(  # noqa: PLR0913 - the step's inputs
    session: AsyncSession,
    adapter: GrPortalAdapter,
    ai: OfficialAi | None,
    settings: Settings,
    now: datetime,
    transcriber: PdfTranscriber | None = None,
) -> OfficialRun:
    run = OfficialRun()
    if ai is None:
        run.skipped_reason = "FEED_AI_API_KEY is not set"
        return run
    room = settings.feed_ai_daily_items - await _calls_today(session, now)
    if room <= 0:
        run.skipped_reason = "daily AI limit reached"
        return run
    tr = run.transcribe
    if transcriber is not None:
        used = await _count_today(session, now, TRANSCRIBE, TRANSCRIBE_CALLS)
        tr.room = max(0, settings.feed_pdf_transcribe_daily - used)
    seen: set[uuid.UUID] = set()
    for item in await waiting(session, room):
        seen.add(item.id)
        outcome = await process_one(session, item, adapter, ai, settings, now, transcriber, tr)
        if outcome != "retry":
            flag = {"transcribed": True} if item.id in tr.texts else {}
            session.add(_event(item, ATTEMPT, now, result=outcome, **flag))
        _count(run, outcome)
        room -= 1
        await session.flush()
    if transcriber is None:
        return run
    # Q152: held broken-text listings get their one transcription; a transcribed listing
    # whose article attempt did not finish is written from its stored transcription.
    for item in await after_transcription(session):
        if room <= 0:
            break
        if item.id in seen or (item.status == "held" and tr.room <= 0):
            continue
        outcome = await process_one(session, item, adapter, ai, settings, now, transcriber, tr)
        if item.extracted_text is not None:  # the article path ran: an AI attempt
            room -= 1
            if outcome != "retry":
                flag = {"transcribed": True} if item.id in tr.texts else {}
                session.add(_event(item, ATTEMPT, now, result=outcome, **flag))
            _count(run, outcome)
        await session.flush()
    return run
