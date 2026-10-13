"""Knowledge-base admin API (addendum v1.3 K0): sources, card review/publish, manual
imports and admin alerts. Roles come from server-set Supabase app_metadata."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser, require_role
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.kb.importers import KbImportError, import_label_claims, import_restrictions
from bagmitra_api.kb.models import KbAdminAlert, KbCard, KbSource, KbTopic
from bagmitra_api.kb.regate import card_gate_failures, regate_with_settings
from bagmitra_api.kb.service import PublishRefusedError, ReviewInput, publish, record_review

router = APIRouter(
    prefix="/v1/admin/kb",
    tags=["admin"],
    responses={401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
Admin = Annotated[AuthenticatedUser, Depends(require_role("kb_admin"))]
Reviewer = Annotated[AuthenticatedUser, Depends(require_role("kb_reviewer"))]
AppSettings = Annotated[Settings, Depends(get_settings)]
CardStatus = Literal["draft", "expert_reviewed", "published", "retired"]


class SourceOut(BaseModel):
    id: uuid.UUID
    key: str
    title: str
    publisher: str
    url: str
    tier: str
    allowed_use: str
    verification: str


class SourcesResponse(BaseModel):
    sources: list[SourceOut]


class CardOut(BaseModel):
    id: uuid.UUID
    topic: str
    crop: str
    version: int
    status: str
    title: str
    has_chemical_options: bool
    review_due_at: datetime | None


class CardsResponse(BaseModel):
    cards: list[CardOut]


class ReviewIn(BaseModel):
    decision: Literal["approve", "edit", "reject"]
    comments: str | None = Field(default=None, max_length=4000)


class ImportIn(BaseModel):
    source_key: str = Field(max_length=64)
    csv: str = Field(max_length=2_000_000)


class ImportOut(BaseModel):
    added: int
    changed: int
    removed: int
    unchanged: int
    cards_pulled: int


class AlertOut(BaseModel):
    id: uuid.UUID
    kind: str
    card_id: uuid.UUID | None
    detail: str
    created_at: datetime


class AlertsResponse(BaseModel):
    alerts: list[AlertOut]


def _now() -> datetime:
    return datetime.now(UTC)


async def _card(session: AsyncSession, card_id: uuid.UUID) -> tuple[KbCard, str]:
    row = (
        await session.execute(
            select(KbCard, KbTopic.key)
            .join(KbTopic, KbTopic.id == KbCard.topic_id)
            .where(KbCard.id == card_id)
        )
    ).first()
    if row is None:
        raise ApiError(404, "not_found", "card not found")
    return row[0], row[1]


def _card_out(card: KbCard, topic: str) -> CardOut:
    return CardOut(
        id=card.id,
        topic=topic,
        crop=card.crop,
        version=card.version,
        status=card.status,
        title=card.content.get("en", {}).get("title", topic),
        has_chemical_options=bool(card.chemical_options),
        review_due_at=card.review_due_at,
    )


@router.get("/sources", operation_id="admin_kb_sources")
async def sources(_: Admin, session: DbSession) -> SourcesResponse:
    rows = await session.scalars(select(KbSource).order_by(KbSource.tier, KbSource.key))
    return SourcesResponse(
        sources=[SourceOut.model_validate(r, from_attributes=True) for r in rows]
    )


@router.get("/cards", operation_id="admin_kb_cards")
async def cards(
    _: Admin, session: DbSession, status: Annotated[CardStatus | None, Query()] = None
) -> CardsResponse:
    query = select(KbCard, KbTopic.key).join(KbTopic, KbTopic.id == KbCard.topic_id)
    if status is not None:
        query = query.where(KbCard.status == status)
    rows = await session.execute(query.order_by(KbTopic.key, KbCard.crop))
    return CardsResponse(cards=[_card_out(c, k) for c, k in rows.all()])


@router.post("/cards/{card_id}/reviews", status_code=201, operation_id="admin_kb_review")
async def review(
    card_id: uuid.UUID, body: ReviewIn, user: Reviewer, session: DbSession, settings: AppSettings
) -> CardOut:
    if user.reviewer_role not in settings.kb_reviewer_roles:
        raise ApiError(403, "forbidden", "reviewer has no recognised expert role")
    card, topic = await _card(session, card_id)
    review_in = ReviewInput(user.id, user.reviewer_role, body.decision, body.comments)
    await record_review(session, card, review_in, _now(), settings)
    await session.commit()
    return _card_out(card, topic)


@router.post(
    "/cards/{card_id}/publish",
    operation_id="admin_kb_publish",
    responses={409: {"model": ErrorResponse}},
)
async def publish_card(
    card_id: uuid.UUID, _: Admin, session: DbSession, settings: AppSettings
) -> CardOut:
    card, topic = await _card(session, card_id)
    now = _now()
    blockers = [f"gate: {f}" for f in await card_gate_failures(session, card, settings, now)]
    try:
        await publish(session, card, now)
    except PublishRefusedError as exc:
        blockers = exc.blockers + blockers
    if blockers:
        raise ApiError(409, "publish_refused", "; ".join(blockers))
    await session.commit()
    return _card_out(card, topic)


@router.post(
    "/imports/{kind}", operation_id="admin_kb_import", responses={422: {"model": ErrorResponse}}
)
async def run_import(
    kind: Literal["claims", "restrictions"],
    body: ImportIn,
    _: Admin,
    session: DbSession,
    settings: AppSettings,
) -> ImportOut:
    importer = import_label_claims if kind == "claims" else import_restrictions
    now = _now()
    try:
        diff = await importer(session, body.source_key, body.csv, now)
    except KbImportError as exc:
        raise ApiError(422, "import_rejected", "; ".join(exc.errors)) from exc
    pulled = await regate_with_settings(session, settings, now)
    await session.commit()
    return ImportOut(
        added=diff.added,
        changed=diff.changed,
        removed=diff.removed,
        unchanged=diff.unchanged,
        cards_pulled=len(pulled),
    )


@router.get("/alerts", operation_id="admin_kb_alerts")
async def alerts(_: Admin, session: DbSession) -> AlertsResponse:
    rows = await session.scalars(
        select(KbAdminAlert)
        .where(KbAdminAlert.resolved_at.is_(None))
        .order_by(KbAdminAlert.created_at.desc())
    )
    return AlertsResponse(alerts=[AlertOut.model_validate(r, from_attributes=True) for r in rows])


@router.post("/alerts/{alert_id}/resolve", operation_id="admin_kb_resolve_alert")
async def resolve_alert(alert_id: uuid.UUID, _: Admin, session: DbSession) -> AlertOut:
    alert = await session.get(KbAdminAlert, alert_id)
    if alert is None:
        raise ApiError(404, "not_found", "alert not found")
    alert.resolved_at = _now()
    await session.commit()
    return AlertOut.model_validate(alert, from_attributes=True)
