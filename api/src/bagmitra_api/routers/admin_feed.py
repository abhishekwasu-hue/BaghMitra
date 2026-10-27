"""Government feed admin API (addendum v1.4 G0/G1): source registry, manual upload, review
queue, approve / publish / withdraw, text edits and the optional AI draft. Role `feed_admin`
comes from server-set Supabase app_metadata."""

from __future__ import annotations

import base64
import binascii
import uuid
from collections.abc import Callable
from datetime import date, datetime
from typing import Annotated, Any, Literal
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser, require_role
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed import service
from bagmitra_api.feed.ai import AiUnavailableError, FeedAi, get_feed_ai
from bagmitra_api.feed.extract import OcrEngine, get_feed_ocr
from bagmitra_api.feed.gr_portal import MAX_DOCUMENT_BYTES
from bagmitra_api.feed.models import (
    FeedItem,
    FeedItemTarget,
    FeedReviewEvent,
    FeedSource,
)
from bagmitra_api.feed.service import FeedError, NewItem
from bagmitra_api.weather.service import get_clock

router = APIRouter(
    prefix="/v1/admin/feed",
    tags=["admin"],
    responses={401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
FeedAdmin = Annotated[AuthenticatedUser, Depends(require_role("feed_admin"))]
AppSettings = Annotated[Settings, Depends(get_settings)]
Clock = Annotated[Callable[[], datetime], Depends(get_clock)]
Lang = Literal["en", "mr", "hi"]
ItemType = Literal["gr", "circular", "scheme", "alert", "news"]
ItemStatus = Literal["draft", "in_review", "published", "withdrawn"]
INDIA = ZoneInfo("Asia/Kolkata")
ERRORS: dict[int | str, dict[str, Any]] = {
    404: {"model": ErrorResponse},
    409: {"model": ErrorResponse},
    422: {"model": ErrorResponse},
}


class FeedAdminSourceOut(BaseModel):
    id: uuid.UUID
    key: str
    name: str
    url: str
    tier: str
    terms_status: str
    fetch_method: str
    fetch_status: str
    last_ok_at: datetime | None
    last_error: str | None
    notes: str | None


class FeedAdminSourcesResponse(BaseModel):
    sources: list[FeedAdminSourceOut]


class FeedAdminTermsIn(BaseModel):
    terms_status: Literal["unknown", "allowed", "disallowed"]
    notes: str | None = Field(default=None, max_length=4000)


class FeedAdminTextIn(BaseModel):
    title: str = Field(min_length=1, max_length=500)
    summary: str | None = Field(default=None, max_length=4000)


class FeedAdminCardFieldIn(BaseModel):
    value: str = Field(min_length=1, max_length=4000)
    page: str | None = Field(default=None, max_length=100)


class FeedAdminTargetIn(BaseModel):
    district: str | None = Field(default=None, max_length=120)
    crop: str | None = Field(default=None, max_length=32)
    min_ha: float | None = Field(default=None, ge=0, le=100_000)
    max_ha: float | None = Field(default=None, ge=0, le=100_000)


class FeedAdminItemIn(BaseModel):
    source_key: str = Field(max_length=64)
    type: ItemType
    published_at: datetime
    url: str = Field(pattern=r"^https?://", max_length=1000)
    external_id: str | None = Field(default=None, max_length=120)
    gr_number: str | None = Field(default=None, max_length=120)
    department: str | None = Field(default=None, max_length=200)
    valid_from: date | None = None
    valid_to: date | None = None
    deadline: date | None = None
    # Payment release date as stated in the document ("payment released" push, G2).
    payment_date: date | None = None
    extracted_text: str | None = Field(default=None, max_length=2_000_000)
    # Optional PDF / HTML copy: only its SHA-256 and size are kept (OPEN_QUESTIONS QG1). Without
    # `extracted_text` the document's text is extracted (OCR fallback when enabled, QG2).
    document_base64: str | None = Field(default=None, max_length=(MAX_DOCUMENT_BYTES // 3 + 1) * 4)
    # pdf | html (a plain string: nullable enums break the generated app client)
    document_type: str | None = Field(default=None, pattern="^(pdf|html)$")
    texts: dict[Lang, FeedAdminTextIn] = Field(default_factory=dict)
    card: dict[str, FeedAdminCardFieldIn] | None = None
    targets: list[FeedAdminTargetIn] = Field(default_factory=list, max_length=50)


class FeedAdminCardIn(BaseModel):
    fields: dict[str, FeedAdminCardFieldIn] = Field(min_length=1, max_length=40)


class FeedAdminTargetsIn(BaseModel):
    targets: list[FeedAdminTargetIn] = Field(max_length=50)


class FeedAdminApproveIn(BaseModel):
    accept_check_issues: bool = False
    comment: str | None = Field(default=None, max_length=4000)


class FeedAdminWithdrawIn(BaseModel):
    reason: str = Field(min_length=1, max_length=4000)
    replaced_by_id: uuid.UUID | None = None


class FeedAdminCheckIssue(BaseModel):
    kind: str
    text: str
    where: str


class FeedAdminItemTextOut(BaseModel):
    title: str
    summary: str | None


class FeedAdminCardOut(BaseModel):
    version: int
    fields: dict[str, dict[str, Any]]


class FeedAdminTargetOut(BaseModel):
    district: str | None
    crop: str | None
    min_ha: float | None
    max_ha: float | None


class FeedAdminEventOut(BaseModel):
    kind: str
    actor_id: uuid.UUID | None
    detail: dict[str, Any]
    created_at: datetime


class FeedAdminItemSummaryOut(BaseModel):
    id: uuid.UUID
    type: str
    status: str
    trust: str
    title: str | None
    gr_number: str | None
    department: str | None
    published_at: datetime
    check_issues: list[FeedAdminCheckIssue]
    approved: bool


class FeedAdminItemsResponse(BaseModel):
    items: list[FeedAdminItemSummaryOut]


class FeedAdminItemOut(FeedAdminItemSummaryOut):
    source_key: str
    external_id: str | None
    url: str
    raw_hash: str | None
    raw_bytes: int | None
    has_text: bool
    valid_from: date | None
    valid_to: date | None
    deadline: date | None
    payment_date: date | None = None
    replaced_by_id: uuid.UUID | None
    texts: dict[str, FeedAdminItemTextOut]
    card: FeedAdminCardOut | None
    targets: list[FeedAdminTargetOut]
    events: list[FeedAdminEventOut]


def _api_error(exc: FeedError) -> ApiError:
    return ApiError(exc.status, exc.code, exc.message)


def _title(texts: dict[str, Any]) -> str | None:
    for lang in ("en", "mr", "hi"):
        if lang in texts:
            return str(texts[lang].title)
    return None


async def _summary(session: AsyncSession, item: FeedItem) -> FeedAdminItemSummaryOut:
    texts = await service.texts_of(session, item.id)
    return FeedAdminItemSummaryOut(
        id=item.id,
        type=item.type,
        status=item.status,
        trust=item.trust_level,
        title=_title(texts),
        gr_number=item.gr_number,
        department=item.department,
        published_at=item.published_at,
        check_issues=[FeedAdminCheckIssue(**c) for c in item.check_issues],
        approved=item.approved_at is not None,
    )


async def _detail(session: AsyncSession, item: FeedItem) -> FeedAdminItemOut:
    summary = await _summary(session, item)
    texts = await service.texts_of(session, item.id)
    card = await service.latest_card(session, item.id)
    source_key = await session.scalar(select(FeedSource.key).where(FeedSource.id == item.source_id))
    targets = await session.scalars(select(FeedItemTarget).where(FeedItemTarget.item_id == item.id))
    events = await session.scalars(
        select(FeedReviewEvent)
        .where(FeedReviewEvent.item_id == item.id)
        .order_by(FeedReviewEvent.created_at)
    )
    return FeedAdminItemOut(
        **summary.model_dump(),
        source_key=source_key or "",
        external_id=item.external_id,
        url=item.url,
        raw_hash=item.raw_hash,
        raw_bytes=item.raw_bytes,
        has_text=bool(item.extracted_text),
        valid_from=item.valid_from,
        valid_to=item.valid_to,
        deadline=item.deadline,
        payment_date=item.payment_date,
        replaced_by_id=item.replaced_by_id,
        texts={k: FeedAdminItemTextOut(title=v.title, summary=v.summary) for k, v in texts.items()},
        card=FeedAdminCardOut(version=card.version, fields=card.fields) if card else None,
        targets=[FeedAdminTargetOut.model_validate(t, from_attributes=True) for t in targets],
        events=[FeedAdminEventOut.model_validate(e, from_attributes=True) for e in events],
    )


async def _item(session: AsyncSession, item_id: uuid.UUID) -> FeedItem:
    try:
        return await service.get_item(session, item_id)
    except FeedError as exc:
        raise _api_error(exc) from exc


def _decode(body: FeedAdminItemIn) -> bytes | None:
    if body.document_base64 is None:
        return None
    if body.document_type is None:
        raise ApiError(422, "invalid_document", "document_type is required with a document")
    try:
        data = base64.b64decode(body.document_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ApiError(422, "invalid_document", "document is not valid base64") from exc
    if not data:
        raise ApiError(422, "invalid_document", "the document is empty")
    if len(data) > MAX_DOCUMENT_BYTES:
        raise ApiError(413, "too_large", "document is too large")
    return data


@router.get("/sources", operation_id="admin_feed_sources")
async def sources(_: FeedAdmin, session: DbSession) -> FeedAdminSourcesResponse:
    rows = await session.scalars(select(FeedSource).order_by(FeedSource.key))
    return FeedAdminSourcesResponse(
        sources=[FeedAdminSourceOut.model_validate(r, from_attributes=True) for r in rows]
    )


@router.put("/sources/{key}/terms", operation_id="admin_feed_source_terms", responses=ERRORS)
async def set_terms(
    key: str, body: FeedAdminTermsIn, _: FeedAdmin, session: DbSession
) -> FeedAdminSourceOut:
    """Record the owner's check of the source's terms of use and robots. Also clears a
    recorded fetch failure, so the next scheduled run tries once more."""
    source = await session.scalar(select(FeedSource).where(FeedSource.key == key))
    if source is None:
        raise ApiError(404, "not_found", "source not found")
    source.terms_status = body.terms_status
    source.fetch_status = "disallowed" if body.terms_status == "disallowed" else "not_fetched"
    source.last_error = None
    if body.notes is not None:
        source.notes = body.notes
    await session.commit()
    return FeedAdminSourceOut.model_validate(source, from_attributes=True)


@router.post(
    "/items",
    status_code=201,
    operation_id="admin_feed_create_item",
    responses={**ERRORS, 413: {"model": ErrorResponse}},
)
async def create_item(
    body: FeedAdminItemIn,
    user: FeedAdmin,
    session: DbSession,
    settings: AppSettings,
    ocr: Annotated[OcrEngine | None, Depends(get_feed_ocr)],
) -> FeedAdminItemOut:
    """Manual upload: metadata, optional document (hashed), optional text. Lands in review."""
    new = NewItem(
        source_key=body.source_key,
        type=body.type,
        published_at=body.published_at,
        url=body.url,
        external_id=body.external_id,
        gr_number=body.gr_number,
        department=body.department,
        valid_from=body.valid_from,
        valid_to=body.valid_to,
        deadline=body.deadline,
        payment_date=body.payment_date,
        extracted_text=body.extracted_text,
        document=_decode(body),
        document_type=body.document_type,
        texts={k: (v.title, v.summary) for k, v in body.texts.items()},
        card={k: v.model_dump() for k, v in body.card.items()} if body.card else None,
        targets=[t.model_dump() for t in body.targets],
    )
    try:
        item = await service.create_item(session, new, user.id, settings, ocr)
    except FeedError as exc:
        raise _api_error(exc) from exc
    await session.commit()
    return await _detail(session, item)


@router.get("/items", operation_id="admin_feed_items")
async def items(
    _: FeedAdmin,
    session: DbSession,
    status: Annotated[ItemStatus, Query()] = "in_review",
) -> FeedAdminItemsResponse:
    """The review queue by default (`status=in_review`), newest first."""
    rows = await session.scalars(
        select(FeedItem).where(FeedItem.status == status).order_by(FeedItem.published_at.desc())
    )
    return FeedAdminItemsResponse(items=[await _summary(session, r) for r in rows])


@router.get("/items/{item_id}", operation_id="admin_feed_item", responses=ERRORS)
async def item_detail(item_id: uuid.UUID, _: FeedAdmin, session: DbSession) -> FeedAdminItemOut:
    return await _detail(session, await _item(session, item_id))


@router.put("/items/{item_id}/texts/{lang}", operation_id="admin_feed_set_text", responses=ERRORS)
async def set_text(  # noqa: PLR0913 - path, body and dependencies
    item_id: uuid.UUID,
    lang: Lang,
    body: FeedAdminTextIn,
    user: FeedAdmin,
    session: DbSession,
    settings: AppSettings,
) -> FeedAdminItemOut:
    item = await _item(session, item_id)
    try:
        await service.set_text(session, item, lang, body.title, body.summary, user.id, settings)
    except FeedError as exc:
        raise _api_error(exc) from exc
    await session.commit()
    return await _detail(session, item)


@router.put("/items/{item_id}/card", operation_id="admin_feed_set_card", responses=ERRORS)
async def set_card(
    item_id: uuid.UUID,
    body: FeedAdminCardIn,
    user: FeedAdmin,
    session: DbSession,
    settings: AppSettings,
) -> FeedAdminItemOut:
    item = await _item(session, item_id)
    fields = {k: v.model_dump() for k, v in body.fields.items()}
    try:
        await service.set_card(session, item, fields, user.id, settings)
    except FeedError as exc:
        raise _api_error(exc) from exc
    await session.commit()
    return await _detail(session, item)


@router.put("/items/{item_id}/targets", operation_id="admin_feed_set_targets", responses=ERRORS)
async def set_targets(
    item_id: uuid.UUID, body: FeedAdminTargetsIn, user: FeedAdmin, session: DbSession
) -> FeedAdminItemOut:
    item = await _item(session, item_id)
    try:
        await service.set_targets(session, item, [t.model_dump() for t in body.targets], user.id)
    except FeedError as exc:
        raise _api_error(exc) from exc
    await session.commit()
    return await _detail(session, item)


@router.post("/items/{item_id}/approve", operation_id="admin_feed_approve", responses=ERRORS)
async def approve(
    item_id: uuid.UUID, body: FeedAdminApproveIn, user: FeedAdmin, session: DbSession, clock: Clock
) -> FeedAdminItemOut:
    item = await _item(session, item_id)
    try:
        await service.approve(
            session,
            item,
            user.id,
            clock(),
            accept_check_issues=body.accept_check_issues,
            comment=body.comment,
        )
    except FeedError as exc:
        raise _api_error(exc) from exc
    await session.commit()
    return await _detail(session, item)


@router.post("/items/{item_id}/publish", operation_id="admin_feed_publish", responses=ERRORS)
async def publish(
    item_id: uuid.UUID, user: FeedAdmin, session: DbSession, clock: Clock
) -> FeedAdminItemOut:
    item = await _item(session, item_id)
    try:
        await service.publish(session, item, user.id, clock().astimezone(INDIA).date())
    except FeedError as exc:
        raise _api_error(exc) from exc
    await session.commit()
    return await _detail(session, item)


@router.post("/items/{item_id}/withdraw", operation_id="admin_feed_withdraw", responses=ERRORS)
async def withdraw(
    item_id: uuid.UUID, body: FeedAdminWithdrawIn, user: FeedAdmin, session: DbSession
) -> FeedAdminItemOut:
    item = await _item(session, item_id)
    try:
        await service.withdraw(
            session, item, user.id, replaced_by=body.replaced_by_id, reason=body.reason
        )
    except FeedError as exc:
        raise _api_error(exc) from exc
    await session.commit()
    return await _detail(session, item)


@router.post(
    "/items/{item_id}/ai-draft",
    operation_id="admin_feed_ai_draft",
    responses={**ERRORS, 503: {"model": ErrorResponse}},
)
async def ai_draft(
    item_id: uuid.UUID,
    user: FeedAdmin,
    session: DbSession,
    settings: AppSettings,
    ai: Annotated[FeedAi | None, Depends(get_feed_ai)],
) -> FeedAdminItemOut:
    """Classify and summarise the item's text into a review draft (AI off without
    FEED_AI_API_KEY). Irrelevant documents move to `draft`, out of the queue."""
    if ai is None:
        raise ApiError(503, "ai_off", "the AI summariser is off (FEED_AI_API_KEY not set)")
    item = await _item(session, item_id)
    try:
        await service.ai_draft(session, item, ai, user.id, settings)
    except FeedError as exc:
        raise _api_error(exc) from exc
    except AiUnavailableError as exc:
        raise ApiError(503, "ai_unavailable", str(exc)) from exc
    await session.commit()
    return await _detail(session, item)
