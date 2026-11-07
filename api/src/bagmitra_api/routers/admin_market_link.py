"""Market linkage admin API (spec v1.5 §3A, §4): the verification queue for traders, brokers
and service providers, and the rating-tag list only admin edits. Behind the legal gate
`market_link_enabled` (404 while off, decision j) and role `market_link_admin`.

Every decision is a NEW `party_verifications` row (who and when); an old row is never
edited, and the latest row decides (decision h, Q70)."""

from __future__ import annotations

import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime
from typing import Annotated, Any, Literal, cast

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser, require_role
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.checks import (
    CheckOut,
    OfficialLinkOut,
    latest_checks,
    meets_verified_rule,
    official_links,
    passed_kinds,
)
from bagmitra_api.market_link.guards import MarketLinkIn, latest_verifications
from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    PartyVerification,
    RatingTag,
    RegistrationFix,
    RepresentativeUpload,
    ServiceProvider,
    VerificationCheck,
)
from bagmitra_api.market_link.registration import AdminFixOut, admin_fix, fix_flags, latest_fixes
from bagmitra_api.market_link.safety import new_action
from bagmitra_api.market_link.trust import RelatedOut, trust_flags
from bagmitra_api.routers.market_link import require_market_link
from bagmitra_api.routers.scouting_photos import (
    PhotoContext,
    PhotoDownloadUrl,
    get_photo_context,
    signed_download,
)
from bagmitra_api.weather.service import get_clock

router = APIRouter(
    prefix="/v1/admin/market-link",
    tags=["admin"],
    dependencies=[Depends(require_market_link)],
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
)
MarketLinkAdmin = Annotated[AuthenticatedUser, Depends(require_role("market_link_admin"))]
Clock = Annotated[Callable[[], datetime], Depends(get_clock)]
AppSettings = Annotated[Settings, Depends(get_settings)]
SubjectType = Literal["buyer", "broker", "provider"]
Subject = BuyerProfile | BrokerProfile | ServiceProvider
MODELS: dict[str, type[Subject]] = {
    "buyer": BuyerProfile,
    "broker": BrokerProfile,
    "provider": ServiceProvider,
}
# Fields the admin checks (spec §4), in the order shown; ids and timestamps are left out.
FIELDS: dict[str, tuple[str, ...]] = {
    "buyer": (
        *("kind", "name", "firm", "phone", "markets", "district", "taluka", "crops"),
        *("apmc_licence_no", "gst_no", "iec_no", "fssai_no", "apeda_no", "address"),
    ),
    "broker": (
        *("name", "phone", "village", "district", "taluka", "service_areas", "crops"),
        "address",
    ),
    "provider": (
        *("kind", "name", "phone", "village", "district", "taluka", "service_areas"),
        *("cert_valid_until", "vehicle_numbers", "capacity_t", "refrigerated", "carrier_reg_no"),
        "address",
    ),
}


class VerificationOut(BaseModel):
    id: uuid.UUID
    status: str
    reason: str | None
    document_keys: list[str]
    checked_by: uuid.UUID | None
    checked_at: datetime | None
    created_at: datetime


class SubjectOut(BaseModel):
    subject_type: str
    subject_id: uuid.UUID
    name: str
    # The submitted fields as text (lists joined), only those that are filled in.
    fields: dict[str, str]
    document_keys: list[str]
    # When the subject entered the queue: its pending record, else its registration.
    waiting_since: datetime
    status: str
    # The registration GPS fix with exact coordinates (admin only, addendum 3) and why the
    # admin must look at it before any badge: mock location, another district, no place (L2).
    registration_fix: AdminFixOut | None = None
    flags: list[str] = []
    # L7 (spec §4C): the other profiles behind a duplicate_number / returning_suspended flag.
    related: list[RelatedOut] = []


class QueueResponse(BaseModel):
    subjects: list[SubjectOut]


class SubjectDetailOut(BaseModel):
    subject: SubjectOut
    # Every verification record, newest first.
    history: list[VerificationOut]
    # L7: every per-check record, newest first, and the official page of each check.
    checks: list[CheckOut] = []
    links: list[OfficialLinkOut] = []


class DecisionIn(MarketLinkIn):
    status: Literal["approved", "rejected"]
    reason: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def _reason_on_reject(self) -> DecisionIn:
        if self.status == "rejected" and not (self.reason or "").strip():
            raise ValueError("a rejection needs a reason")
        return self


class RatingTagAdminOut(BaseModel):
    id: uuid.UUID
    key: str
    question_key: str
    polarity: str
    label_mr: str
    label_hi: str
    label_en: str
    status: str
    sort_order: int


class RatingTagsAdminResponse(BaseModel):
    tags: list[RatingTagAdminOut]


class RatingTagIn(MarketLinkIn):
    label_mr: str = Field(min_length=1, max_length=120)
    label_hi: str = Field(min_length=1, max_length=120)
    label_en: str = Field(min_length=1, max_length=120)
    status: Literal["draft", "active", "retired"]


def _text(value: Any) -> str | None:
    if value is None or value in ("", []):
        return None
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    if isinstance(value, bool):
        return "yes" if value else "no"
    return str(value)


@dataclass(frozen=True)
class _Extras:
    """Per subject: the registration GPS fix and representative place-photo keys (L2)."""

    fixes: dict[uuid.UUID, RegistrationFix]
    place_keys: dict[uuid.UUID, list[str]]


async def _extras(session: AsyncSession, kind: str, ids: list[uuid.UUID]) -> _Extras:
    place_keys: dict[uuid.UUID, list[str]] = {}
    if ids:
        uploads = await session.scalars(
            select(RepresentativeUpload)
            .where(
                RepresentativeUpload.subject_type == kind,
                RepresentativeUpload.subject_id.in_(ids),
                RepresentativeUpload.photo_key.is_not(None),
            )
            .order_by(RepresentativeUpload.created_at)
        )
        for upload in uploads:
            if upload.photo_key is not None:
                place_keys.setdefault(upload.subject_id, []).append(upload.photo_key)
    return _Extras(await latest_fixes(session, kind, ids), place_keys)


def _documents(subject: Subject, latest: PartyVerification | None, extras: _Extras) -> list[str]:
    keys = list(latest.document_keys) if latest is not None else []
    cert = subject.cert_photo_key if isinstance(subject, ServiceProvider) else None
    if cert and cert not in keys:
        keys.append(cert)
    return keys + extras.place_keys.get(subject.id, [])


def _subject_out(
    kind: str,
    subject: Subject,
    latest: PartyVerification | None,
    extras: _Extras,
    related: list[RelatedOut] | None = None,
) -> SubjectOut:
    fields = {f: t for f in FIELDS[kind] if (t := _text(getattr(subject, f))) is not None}
    pending = latest is None or latest.status == "pending"
    fix = extras.fixes.get(subject.id)
    return SubjectOut(
        subject_type=kind,
        subject_id=subject.id,
        name=subject.name,
        fields=fields,
        document_keys=_documents(subject, latest, extras),
        waiting_since=latest.created_at if latest is not None and pending else subject.created_at,
        status=latest.status if latest is not None else "pending",
        registration_fix=admin_fix(fix),
        flags=[*fix_flags(fix, subject.district), *dict.fromkeys(r.flag for r in related or [])],
        related=related or [],
    )


async def _latest(
    session: AsyncSession, kind: str, ids: list[uuid.UUID]
) -> dict[uuid.UUID, PartyVerification]:
    return await latest_verifications(session, kind, ids)


async def _subject(session: AsyncSession, kind: str, subject_id: uuid.UUID) -> Subject:
    subject = cast(Subject | None, await session.get(MODELS[kind], subject_id))
    if subject is None:
        raise ApiError(404, "subject_not_found")
    return subject


async def _detail(
    session: AsyncSession, kind: str, subject: Subject, km: float
) -> SubjectDetailOut:
    history = list(
        await session.scalars(
            select(PartyVerification)
            .where(
                PartyVerification.subject_type == kind,
                PartyVerification.subject_id == subject.id,
            )
            .order_by(PartyVerification.created_at.desc())
        )
    )
    checks = await session.scalars(
        select(VerificationCheck)
        .where(VerificationCheck.subject_type == kind, VerificationCheck.subject_id == subject.id)
        .order_by(VerificationCheck.checked_at.desc(), VerificationCheck.created_at.desc())
    )
    related = (await trust_flags(session, kind, [subject], km)).get(subject.id, [])
    return SubjectDetailOut(
        subject=_subject_out(
            kind,
            subject,
            history[0] if history else None,
            await _extras(session, kind, [subject.id]),
            related,
        ),
        history=[VerificationOut.model_validate(v, from_attributes=True) for v in history],
        checks=[CheckOut.model_validate(c, from_attributes=True) for c in checks],
        links=official_links(kind, subject),
    )


@router.get("/verifications", operation_id="admin_market_link_queue")
async def queue(
    _admin: MarketLinkAdmin,
    session: DbSession,
    settings: AppSettings,
    subject_type: Annotated[SubjectType | None, Query()] = None,
) -> QueueResponse:
    """Subjects waiting for a check (latest record pending, or none yet), oldest first."""
    waiting: list[SubjectOut] = []
    kinds: list[str] = [subject_type] if subject_type else list(MODELS)
    for kind in kinds:
        subjects = cast(list[Subject], list(await session.scalars(select(MODELS[kind]))))
        latest = await _latest(session, kind, [s.id for s in subjects])
        extras = await _extras(session, kind, [s.id for s in subjects])
        pending = [s for s in subjects if (r := latest.get(s.id)) is None or r.status == "pending"]
        related = await trust_flags(session, kind, pending, settings.market_link_returning_km)
        for subject in pending:
            out = _subject_out(
                kind, subject, latest.get(subject.id), extras, related.get(subject.id)
            )
            waiting.append(out)
    waiting.sort(key=lambda s: s.waiting_since)
    return QueueResponse(subjects=waiting)


@router.get("/verifications/{subject_type}/{subject_id}", operation_id="admin_market_link_subject")
async def subject_history(
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    _admin: MarketLinkAdmin,
    session: DbSession,
    settings: AppSettings,
) -> SubjectDetailOut:
    """The subject's submitted fields, documents, every verification and check record."""
    subject = await _subject(session, subject_type, subject_id)
    return await _detail(session, subject_type, subject, settings.market_link_returning_km)


@router.post(
    "/verifications/{subject_type}/{subject_id}/decision",
    operation_id="admin_market_link_decide",
    responses={422: {"model": ErrorResponse}},
)
async def decide(  # noqa: PLR0913 - path, body and dependencies
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    body: DecisionIn,
    admin: MarketLinkAdmin,
    session: DbSession,
    clock: Clock,
    settings: AppSettings,
) -> SubjectDetailOut:
    """Approve, or reject with a reason: always a new record with who and when (Q70). An
    approval needs the spec §4 checks on record (trader: GSTIN / APMC / IEC; exporter: IEC;
    broker: the phone call), else 422 `verified_rule_not_met`."""
    subject = await _subject(session, subject_type, subject_id)
    if body.status == "approved":
        checks = (await latest_checks(session, subject_type, [subject.id])).get(subject.id, {})
        if not meets_verified_rule(subject, passed_kinds(subject, checks)):
            raise ApiError(422, "verified_rule_not_met", "record the required check first")
    latest = (await _latest(session, subject_type, [subject.id])).get(subject.id)
    now = clock()
    session.add(
        PartyVerification(
            subject_type=subject_type,
            subject_id=subject.id,
            document_keys=list(latest.document_keys) if latest is not None else [],
            status=body.status,
            reason=(body.reason or "").strip() or None,
            checked_by=admin.id,
            checked_at=now,
            created_at=now,
            updated_at=now,
        )
    )
    if body.status == "approved":  # every verify is in the open action log too (§4C)
        session.add(
            new_action(
                subject_type=subject_type,
                subject_id=subject.id,
                user_id=subject.user_id,
                action="verify",
                reason_code="checks_passed",
                actor_id=admin.id,
                now=now,
            )
        )
    await session.commit()
    return await _detail(session, subject_type, subject, settings.market_link_returning_km)


@router.get(
    "/verifications/{subject_type}/{subject_id}/documents/{index}/url",
    operation_id="admin_market_link_document_url",
    responses={502: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
)
async def document_url(
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    index: int,
    _admin: MarketLinkAdmin,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> PhotoDownloadUrl:
    """A short-lived signed URL for one stored document; only keys on record are signed."""
    subject = await _subject(session, subject_type, subject_id)
    latest = (await _latest(session, subject_type, [subject.id])).get(subject.id)
    keys = _documents(subject, latest, await _extras(session, subject_type, [subject.id]))
    if not 0 <= index < len(keys):
        raise ApiError(404, "photo_not_found")
    return await signed_download(ctx, keys[index])


@router.get("/rating-tags", operation_id="admin_market_link_rating_tags")
async def rating_tags(_admin: MarketLinkAdmin, session: DbSession) -> RatingTagsAdminResponse:
    """Every tag, drafts and retired ones included."""
    rows = await session.scalars(
        select(RatingTag).order_by(RatingTag.question_key, RatingTag.sort_order, RatingTag.key)
    )
    return RatingTagsAdminResponse(
        tags=[RatingTagAdminOut.model_validate(r, from_attributes=True) for r in rows]
    )


@router.put(
    "/rating-tags/{tag_id}",
    operation_id="admin_market_link_rating_tag_update",
    responses={422: {"model": ErrorResponse}},
)
async def update_rating_tag(
    tag_id: uuid.UUID, body: RatingTagIn, _admin: MarketLinkAdmin, session: DbSession
) -> RatingTagAdminOut:
    """Edit the three labels and set draft / active / retired (spec §3A: admin only)."""
    tag = await session.get(RatingTag, tag_id)
    if tag is None:
        raise ApiError(404, "rating_tag_not_found")
    for field, value in body.model_dump().items():
        setattr(tag, field, value.strip() if isinstance(value, str) else value)
    await session.commit()
    return RatingTagAdminOut.model_validate(tag, from_attributes=True)
