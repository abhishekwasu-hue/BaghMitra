"""Feed item lifecycle (addendum v1.4 §4.5): create (manual upload), edit, output check,
approve, publish, withdraw, AI draft. Every step appends a review event.

Rules kept here, not in the routers:
- trust is official only when the source's tier is official and the item is not news;
- news keeps headline + link + our own summary only (no article text, no document);
- the official badge needs the source document's SHA-256 before publishing;
- any edit clears the approval and sends a published item back to review;
- output-check mismatches block approval unless the reviewer explicitly accepts them;
- an uploaded document without admin text is extracted (PDF text layer / HTML, OCR fallback
  when enabled); a missing or broken text is a check issue, so the item stays in review until
  the reviewer accepts it with a comment (QG2).
"""

from __future__ import annotations

import asyncio
import hashlib
import uuid
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date, datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import FeedAi
from bagmitra_api.feed.extract import OcrEngine, OcrError, assess, extract
from bagmitra_api.feed.models import (
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedReviewEvent,
    FeedSchemeCard,
    FeedSource,
)
from bagmitra_api.feed.output_check import check_output


class FeedError(Exception):
    def __init__(self, status: int, code: str, message: str) -> None:
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message


@dataclass(frozen=True, slots=True)
class NewItem:
    source_key: str
    type: str
    published_at: datetime
    url: str
    external_id: str | None = None
    gr_number: str | None = None
    department: str | None = None
    valid_from: date | None = None
    valid_to: date | None = None
    deadline: date | None = None
    extracted_text: str | None = None
    document: bytes | None = None
    document_type: str | None = None  # pdf | html
    texts: Mapping[str, tuple[str, str | None]] | None = None
    card: Mapping[str, Mapping[str, Any]] | None = None
    targets: Sequence[Mapping[str, Any]] = ()


def event(item: FeedItem, kind: str, actor: uuid.UUID | None, **detail: Any) -> FeedReviewEvent:
    return FeedReviewEvent(
        id=uuid.uuid4(), item_id=item.id, actor_id=actor, kind=kind, detail=detail
    )


async def texts_of(session: AsyncSession, item_id: uuid.UUID) -> dict[str, FeedItemI18n]:
    rows = await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item_id))
    return {r.lang: r for r in rows}


async def latest_card(session: AsyncSession, item_id: uuid.UUID) -> FeedSchemeCard | None:
    card: FeedSchemeCard | None = await session.scalar(
        select(FeedSchemeCard)
        .where(FeedSchemeCard.item_id == item_id)
        .order_by(FeedSchemeCard.version.desc())
        .limit(1)
    )
    return card


def source_text(item: FeedItem) -> str:
    """What the output check may rely on: the document text plus the metadata the admin
    copied from the document header (GR number, publication date)."""
    meta = [item.gr_number or "", item.published_at.date().isoformat()]
    return "\n".join([item.extracted_text or "", *meta])


async def run_output_check(
    session: AsyncSession, item: FeedItem, settings: Settings, actor: uuid.UUID | None
) -> list[dict[str, str]]:
    """Checks every shown text, card field and date against the source. News is not checked:
    by design its article text is never stored, so it always goes through human review."""
    if item.trust_level == "news":
        item.check_issues = []
        return []
    texts: dict[str, str | None] = {}
    for lang, row in (await texts_of(session, item.id)).items():
        texts[f"{lang}.title"] = row.title
        texts[f"{lang}.summary"] = row.summary
    for name in ("deadline", "valid_from", "valid_to"):
        value = getattr(item, name)
        texts[name] = value.isoformat() if value else None
    card = await latest_card(session, item.id)
    text_issues = await extraction_issues(session, item)
    found = check_output(
        source_text(item),
        texts,
        card_fields=card.fields if card else None,
        scheme_glossary=settings.feed_scheme_glossary,
    )
    item.check_issues = text_issues + [m.as_dict() for m in found]
    if found:
        session.add(event(item, "output_check_failed", actor, issues=item.check_issues))
    return item.check_issues


# Text kept in review events (the text not stored as `extracted_text`) is cut to this size.
MAX_KEPT_TEXT = 2_000_000


async def extraction_issues(session: AsyncSession, item: FeedItem) -> list[dict[str, str]]:
    """Issues recorded when the uploaded document was extracted (missing / broken text, low
    OCR confidence). They stay until a reviewer accepts them with a comment."""
    detail: dict[str, Any] | None = await session.scalar(
        select(FeedReviewEvent.detail)
        .where(FeedReviewEvent.item_id == item.id, FeedReviewEvent.kind == "extracted")
        .order_by(FeedReviewEvent.created_at.desc())
        .limit(1)
    )
    return list(detail.get("issues", [])) if detail else []


def _keep(text: str) -> str | None:
    return text[:MAX_KEPT_TEXT] or None


async def extract_document(  # noqa: PLR0913
    session: AsyncSession,
    item: FeedItem,
    data: bytes,
    content_type: str,
    actor: uuid.UUID | None,
    settings: Settings,
    ocr: OcrEngine | None,
) -> None:
    """Extract the uploaded document into `item.extracted_text` (only when the text is usable)
    and record method / quality / Devanagari ratio / pages / OCR confidence, the text that was
    not used (broken text layer or OCR text) and the review issues in an `extracted` event."""
    found = await asyncio.to_thread(extract, data, content_type)
    detail: dict[str, Any] = {
        "method": found.method,
        "quality": found.quality,
        "devanagari_ratio": found.devanagari_ratio,
        "pages": found.pages,
        "reason": found.reason,
        "chars": len(found.text),
        "used": None,
        "ocr": None,
    }
    issues: list[dict[str, str]] = []
    if found.quality == "ok":
        item.extracted_text, detail["used"] = found.text, found.method
    else:
        detail["text_layer"] = _keep(found.text)
        if ocr is not None and found.method != "html":
            await _ocr(item, data, ocr, settings, detail, issues)
        if item.extracted_text is None:
            tried = " and OCR" if detail["ocr"] else ""
            issues.insert(0, {
                "kind": f"text_{found.quality}",
                "text": f"{found.reason}; no usable text from the text layer{tried}: paste "
                "the text from the document or accept with a comment",
                "where": "document",
            })  # fmt: skip
    detail["issues"] = issues
    session.add(event(item, "extracted", actor, **detail))


async def _ocr(  # noqa: PLR0913
    item: FeedItem,
    data: bytes,
    ocr: OcrEngine,
    settings: Settings,
    detail: dict[str, Any],
    issues: list[dict[str, str]],
) -> None:
    try:
        result = await asyncio.to_thread(ocr.ocr_pdf, data)
    except OcrError as exc:
        detail["ocr"] = {"error": str(exc)}
        return
    quality, ratio, reason = assess(result.text)
    detail["ocr"] = {
        "quality": quality,
        "confidence": result.confidence,
        "devanagari_ratio": ratio,
        "pages": result.pages,
        "reason": reason,
    }
    if quality != "ok":
        detail["ocr"]["text"] = _keep(result.text)
        return
    item.extracted_text, detail["used"] = result.text, "ocr"
    if result.confidence < settings.feed_ocr_min_confidence:
        issues.append({
            "kind": "ocr_low_confidence",
            "text": f"OCR confidence {result.confidence:g} < "
            f"{settings.feed_ocr_min_confidence:g}: check the text against the document",
            "where": "document",
        })  # fmt: skip


def mark_changed(item: FeedItem) -> None:
    item.approved_at = None
    item.approved_by = None
    if item.status in ("published", "draft"):
        item.status = "in_review"


def _validate_new(source: FeedSource, new: NewItem) -> str:
    if new.type == "news":
        if new.extracted_text or new.document:
            raise FeedError(
                422, "news_text_not_stored", "news keeps headline, link and own summary only"
            )
        if new.card:
            raise FeedError(422, "invalid_item", "news items carry no scheme card")
        return "news"
    if new.card and new.type != "scheme":
        raise FeedError(422, "invalid_item", "only scheme items carry a scheme card")
    return "official" if source.tier == "official" else "news"


async def create_item(
    session: AsyncSession,
    new: NewItem,
    actor: uuid.UUID,
    settings: Settings,
    ocr: OcrEngine | None = None,
) -> FeedItem:
    source = await session.scalar(select(FeedSource).where(FeedSource.key == new.source_key))
    if source is None:
        raise FeedError(404, "source_not_found", "feed source not found")
    trust = _validate_new(source, new)
    raw_hash = None
    if new.document is not None:
        raw_hash = hashlib.sha256(new.document).hexdigest()
        dup = await session.scalar(
            select(FeedItem.id).where(
                FeedItem.source_id == source.id, FeedItem.raw_hash == raw_hash
            )
        )
        if dup is not None:
            raise FeedError(409, "duplicate_document", f"same document already stored as {dup}")
    if new.external_id is not None:
        dup = await session.scalar(
            select(FeedItem.id).where(
                FeedItem.source_id == source.id, FeedItem.external_id == new.external_id
            )
        )
        if dup is not None:
            raise FeedError(409, "duplicate_item", f"external id already stored as {dup}")
    item = FeedItem(
        id=uuid.uuid4(),
        type=new.type,
        source_id=source.id,
        external_id=new.external_id,
        gr_number=new.gr_number,
        department=new.department,
        published_at=new.published_at,
        url=new.url,
        raw_hash=raw_hash,
        raw_bytes=len(new.document) if new.document is not None else None,
        extracted_text=new.extracted_text,
        status="in_review",
        trust_level=trust,
        valid_from=new.valid_from,
        valid_to=new.valid_to,
        deadline=new.deadline,
        check_issues=[],
    )
    session.add(item)
    session.add(event(item, "created", actor, via="manual_upload", hashed=raw_hash is not None))
    if new.document is not None and new.document_type and not new.extracted_text:
        await extract_document(session, item, new.document, new.document_type, actor, settings, ocr)
    for lang, (title, summary) in (new.texts or {}).items():
        session.add(
            FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang=lang, title=title, summary=summary)
        )
    if new.card:
        session.add(_card_row(item.id, 1, new.card))
    for target in new.targets:
        session.add(FeedItemTarget(id=uuid.uuid4(), item_id=item.id, **target))
    await session.flush()
    await run_output_check(session, item, settings, actor)
    return item


def _card_row(item_id: uuid.UUID, version: int, fields: Mapping[str, Any]) -> FeedSchemeCard:
    return FeedSchemeCard(
        id=uuid.uuid4(),
        item_id=item_id,
        version=version,
        fields={k: dict(v) for k, v in fields.items()},
    )


async def get_item(session: AsyncSession, item_id: uuid.UUID) -> FeedItem:
    item = await session.get(FeedItem, item_id)
    if item is None:
        raise FeedError(404, "not_found", "feed item not found")
    return item


def _editable(item: FeedItem) -> None:
    if item.status == "withdrawn":
        raise FeedError(409, "withdrawn", "a withdrawn item cannot be edited")


async def set_text(  # noqa: PLR0913
    session: AsyncSession,
    item: FeedItem,
    lang: str,
    title: str,
    summary: str | None,
    actor: uuid.UUID,
    settings: Settings,
) -> None:
    _editable(item)
    row = (await texts_of(session, item.id)).get(lang)
    if row is None:
        row = FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang=lang, title=title)
        session.add(row)
    row.title, row.summary = title, summary
    mark_changed(item)
    session.add(event(item, "edited", actor, lang=lang))
    await session.flush()
    await run_output_check(session, item, settings, actor)


async def set_card(
    session: AsyncSession,
    item: FeedItem,
    fields: Mapping[str, Mapping[str, Any]],
    actor: uuid.UUID | None,
    settings: Settings,
) -> FeedSchemeCard:
    _editable(item)
    if item.type != "scheme":
        raise FeedError(422, "invalid_item", "only scheme items carry a scheme card")
    current = await latest_card(session, item.id)
    card = _card_row(item.id, (current.version + 1) if current else 1, fields)
    session.add(card)
    mark_changed(item)
    session.add(event(item, "edited", actor, card_version=card.version))
    await session.flush()
    await run_output_check(session, item, settings, actor)
    return card


async def set_targets(
    session: AsyncSession, item: FeedItem, targets: Sequence[Mapping[str, Any]], actor: uuid.UUID
) -> None:
    _editable(item)
    for row in await session.scalars(
        select(FeedItemTarget).where(FeedItemTarget.item_id == item.id)
    ):
        await session.delete(row)
    for target in targets:
        session.add(FeedItemTarget(id=uuid.uuid4(), item_id=item.id, **target))
    mark_changed(item)
    session.add(event(item, "edited", actor, targets=len(targets)))
    await session.flush()


async def approve(  # noqa: PLR0913
    session: AsyncSession,
    item: FeedItem,
    actor: uuid.UUID,
    now: datetime,
    *,
    accept_check_issues: bool,
    comment: str | None,
) -> None:
    if item.status != "in_review":
        raise FeedError(409, "not_in_review", f"item is {item.status}")
    if item.check_issues and not accept_check_issues:
        raise FeedError(
            409, "check_issues_open", "fix the texts or accept the output-check issues explicitly"
        )
    if item.check_issues and not comment:
        raise FeedError(422, "comment_required", "accepting check issues needs a comment")
    item.approved_at, item.approved_by = now, actor
    session.add(
        event(item, "approved", actor, comment=comment, accepted_issues=item.check_issues or None)
    )


async def publish_blockers(session: AsyncSession, item: FeedItem, today: date) -> list[str]:
    blockers = []
    if item.status != "in_review":
        blockers.append(f"item is {item.status}")
    if item.approved_at is None:
        blockers.append("not approved since the last change")
    texts = await texts_of(session, item.id)
    if "en" not in texts:
        blockers.append("English text missing (source of truth for translations)")
    if item.trust_level == "official" and item.raw_hash is None:
        blockers.append("official item without the source document hash")
    if item.valid_to is not None and item.valid_to < today:
        blockers.append("validity already ended")
    return blockers


async def publish(session: AsyncSession, item: FeedItem, actor: uuid.UUID, today: date) -> None:
    blockers = await publish_blockers(session, item, today)
    if blockers:
        raise FeedError(409, "publish_refused", "; ".join(blockers))
    item.status = "published"
    session.add(event(item, "published", actor))


async def withdraw(
    session: AsyncSession,
    item: FeedItem,
    actor: uuid.UUID,
    *,
    replaced_by: uuid.UUID | None,
    reason: str,
) -> None:
    if item.status == "withdrawn":
        raise FeedError(409, "withdrawn", "item is already withdrawn")
    if replaced_by is not None:
        if replaced_by == item.id:
            raise FeedError(422, "invalid_replacement", "an item cannot replace itself")
        if await session.get(FeedItem, replaced_by) is None:
            raise FeedError(404, "not_found", "replacement item not found")
    item.status = "withdrawn"
    item.replaced_by_id = replaced_by
    session.add(
        event(item, "withdrawn", actor, reason=reason, replaced_by=str(replaced_by or "") or None)
    )


async def ai_draft(
    session: AsyncSession, item: FeedItem, ai: FeedAi, actor: uuid.UUID, settings: Settings
) -> bool:
    """Classify, and when relevant summarise into the English text (+ scheme card); the
    result is a draft for review, never published here. Returns whether it was relevant."""
    _editable(item)
    if not item.extracted_text:
        raise FeedError(409, "no_text", "the item has no extracted text to summarise")
    found = await ai.classifier.classify(item.extracted_text)
    session.add(
        event(
            item,
            "classified",
            actor,
            relevant=found.relevant,
            item_kind=found.kind,
            categories=found.categories,
            crops=found.crops,
            districts=found.districts,
        )
    )
    if not found.relevant:
        item.status = "draft"  # out of the queue; an admin can still open or withdraw it
        item.approved_at = item.approved_by = None
        return False
    summary = await ai.summariser.summarise(item.extracted_text)
    row = (await texts_of(session, item.id)).get("en")
    if row is None:
        row = FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="en", title=summary.title)
        session.add(row)
    row.title, row.summary = summary.title[:500], summary.summary
    mark_changed(item)
    session.add(event(item, "summarised", actor, fields=sorted(summary.fields)))
    if item.type == "scheme":
        await set_card(session, item, summary.fields, actor, settings)
    else:
        await session.flush()
        await run_output_check(session, item, settings, actor)
    return True
