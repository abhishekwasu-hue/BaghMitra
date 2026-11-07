"""Market linkage API (spec v1.5). Behind the legal gate `market_link_enabled` (decision j):
while it is off, every /v1/market-link/* path answers 404 before auth runs, as if absent."""

from __future__ import annotations

import uuid
from collections.abc import Callable
from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.guards import MarketLinkIn
from bagmitra_api.market_link.models import TERMS_DOCS, RatingTag, TermsAcceptance
from bagmitra_api.market_link.terms import accepted_roles, current_versions
from bagmitra_api.weather.service import get_clock


async def require_market_link(settings: Annotated[Settings, Depends(get_settings)]) -> None:
    if not settings.market_link_enabled:
        raise ApiError(404, "not_found", "Not Found")


router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)


class RatingTagOut(BaseModel):
    id: uuid.UUID
    key: str
    question_key: str
    polarity: str
    label_mr: str
    label_hi: str
    label_en: str
    sort_order: int


class RatingTagsResponse(BaseModel):
    tags: list[RatingTagOut]


@router.get("/rating-tags", operation_id="market_link_rating_tags")
async def rating_tags(_user: CurrentUser, session: DbSession) -> RatingTagsResponse:
    """The active tick list under each rating question (spec §3A); the app caches it."""
    rows = await session.scalars(
        select(RatingTag)
        .where(RatingTag.status == "active")
        .order_by(RatingTag.question_key, RatingTag.sort_order, RatingTag.key)
    )
    return RatingTagsResponse(
        tags=[RatingTagOut.model_validate(r, from_attributes=True) for r in rows]
    )


Role = Literal["grower", "trader", "exporter", "broker", "provider", "representative"]
DocKind = Literal["terms", "privacy", "disclaimer"]
Version = Annotated[str, Field(min_length=1, max_length=20)]
Clock = Annotated[Callable[[], datetime], Depends(get_clock)]
AppSettings = Annotated[Settings, Depends(get_settings)]


class TermsDocOut(BaseModel):
    kind: DocKind
    version: str
    # Path on this API (privacy) or a full link (terms); null while no page is published.
    url: str | None


class GrievanceOfficerOut(BaseModel):
    """IT Rules 2021 grievance officer. `name` null: the owner (default, spec §4C)."""

    name: str | None
    contact: str | None


class TermsOut(BaseModel):
    documents: list[TermsDocOut]
    grievance_officer: GrievanceOfficerOut


@router.get("/terms", operation_id="market_link_terms")
async def terms(_user: CurrentUser, settings: AppSettings) -> TermsOut:
    """The current version of each document accepted before a role is used, and the
    grievance officer shown on every role home (spec §4C)."""
    versions = current_versions(settings)
    urls = {"terms": settings.market_link_terms_url.strip() or None, "privacy": "/privacy"}
    contact = settings.market_link_grievance_contact.strip() or settings.privacy_contact_email
    return TermsOut(
        documents=[
            TermsDocOut(kind=kind, version=versions[kind], url=urls.get(kind))
            for kind in TERMS_DOCS
        ],
        grievance_officer=GrievanceOfficerOut(
            name=settings.market_link_grievance_name.strip() or None, contact=contact or None
        ),
    )


class AcceptIn(MarketLinkIn):
    """The versions the user read on the acceptance screen, for one role. The 18+ declaration
    must be true (minors cannot contract)."""

    role: Role
    adult_declared: Literal[True]
    terms_version: Version
    privacy_version: Version
    disclaimer_version: Version


class AcceptanceOut(BaseModel):
    role: str
    doc_kind: str
    version: str
    accepted_at: datetime


class MyAcceptancesOut(BaseModel):
    # Roles whose current terms, privacy notice and disclaimer are all accepted.
    roles: list[str]
    acceptances: list[AcceptanceOut]


async def _mine(session: DbSession, user_id: uuid.UUID, settings: Settings) -> MyAcceptancesOut:
    rows = await session.scalars(
        select(TermsAcceptance)
        .where(TermsAcceptance.user_id == user_id)
        .order_by(TermsAcceptance.accepted_at, TermsAcceptance.role, TermsAcceptance.doc_kind)
    )
    return MyAcceptancesOut(
        roles=await accepted_roles(session, user_id, current_versions(settings)),
        acceptances=[AcceptanceOut.model_validate(r, from_attributes=True) for r in rows],
    )


@router.get("/me/acceptances", operation_id="market_link_my_acceptances")
async def my_acceptances(
    user: CurrentUser, session: DbSession, settings: AppSettings
) -> MyAcceptancesOut:
    """What the signed-in user accepted, and the roles it opens."""
    return await _mine(session, user.id, settings)


@router.post(
    "/terms/accept",
    operation_id="market_link_accept_terms",
    responses={409: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
)
async def accept_terms(
    body: AcceptIn, user: CurrentUser, session: DbSession, settings: AppSettings, clock: Clock
) -> MyAcceptancesOut:
    """Record the acceptance of every document for one role. A version that is no longer
    current answers 409 `terms_version_changed`, so the app shows the new text again."""
    read = {
        "terms": body.terms_version,
        "privacy": body.privacy_version,
        "disclaimer": body.disclaimer_version,
    }
    if read != current_versions(settings):
        raise ApiError(409, "terms_version_changed", "The terms changed; read them again")
    # Idempotent: a repeated post (the app retries offline acceptances) adds nothing.
    have = {
        (kind, version)
        for kind, version in await session.execute(
            select(TermsAcceptance.doc_kind, TermsAcceptance.version).where(
                TermsAcceptance.user_id == user.id, TermsAcceptance.role == body.role
            )
        )
    }
    now = clock()
    for kind in TERMS_DOCS:
        if (kind, read[kind]) not in have:
            session.add(
                TermsAcceptance(
                    user_id=user.id,
                    role=body.role,
                    doc_kind=kind,
                    version=read[kind],
                    accepted_at=now,
                    adult_declared=True,
                )
            )
    await session.commit()
    return await _mine(session, user.id, settings)
