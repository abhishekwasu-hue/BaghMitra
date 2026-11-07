"""Market linkage L7 admin API (spec v1.5 §4): per-check records. The admin opens the
official public page (link on the subject detail), checks by hand and records the result
here, with who and when; nothing is fetched or automated. Behind the legal gate
`market_link_enabled` (404 while off) and role `market_link_admin`.

A check is never edited: each one is a new `verification_checks` row and the latest of each
kind decides. When a re-check that did not pass leaves an approved profile short of the §4 rule
(e.g. its only GSTIN is now cancelled), a new pending verification record puts it back in the
queue, so it stops counting as verified until the admin approves again (Q102)."""

from __future__ import annotations

import uuid
from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import Field

from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.checks import (
    SUBJECT_CHECKS,
    latest_checks,
    meets_verified_rule,
    number_for,
    official_url,
    passed_kinds,
)
from bagmitra_api.market_link.guards import MarketLinkIn, counts_as_verified
from bagmitra_api.market_link.models import PartyVerification, VerificationCheck
from bagmitra_api.routers.admin_market_link import (
    Clock,
    MarketLinkAdmin,
    SubjectDetailOut,
    SubjectType,
    _detail,
    _latest,
    _subject,
)
from bagmitra_api.routers.market_link import require_market_link

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
CheckKind = Literal["gstin", "apmc", "fssai", "iec", "apeda", "phone_call", "place_photo"]
RESULT_WORDS = {"failed": "did not pass", "cancelled": "cancelled / deactivated"}


class CheckIn(MarketLinkIn):
    kind: CheckKind
    result: Literal["passed", "failed", "cancelled"]
    # GST only: the registration year shown on the public record.
    registered_year: int | None = Field(default=None, ge=1900, le=2100)


@router.post(
    "/verifications/{subject_type}/{subject_id}/checks",
    operation_id="admin_market_link_record_check",
    responses={422: {"model": ErrorResponse}},
)
async def record_check(  # noqa: PLR0913 - path, body and dependencies
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    body: CheckIn,
    admin: MarketLinkAdmin,
    session: DbSession,
    clock: Clock,
) -> SubjectDetailOut:
    """Record one check done by hand on the official page: a new record with who and when."""
    subject = await _subject(session, subject_type, subject_id)
    if body.kind not in SUBJECT_CHECKS[subject_type]:
        raise ApiError(422, "check_not_for_subject")
    number = number_for(subject, body.kind)
    if body.kind not in ("phone_call", "place_photo") and number is None:
        raise ApiError(422, "number_missing", "the profile has no number for this check")
    if body.registered_year is not None and body.kind != "gstin":
        raise ApiError(422, "registered_year_gst_only")
    was_verified = counts_as_verified(
        (await _latest(session, subject_type, [subject.id])).get(subject.id)
    )
    now = clock()
    session.add(
        VerificationCheck(
            subject_type=subject_type,
            subject_id=subject.id,
            kind=body.kind,
            number=number,
            result=body.result,
            registered_year=body.registered_year,
            official_url=official_url(subject, body.kind),
            checked_by=admin.id,
            checked_at=now,
            created_at=now,
            updated_at=now,
        )
    )
    await session.flush()
    checks = (await latest_checks(session, subject_type, [subject.id])).get(subject.id, {})
    if (
        body.result != "passed"
        and was_verified
        and not meets_verified_rule(subject, passed_kinds(subject, checks))
    ):
        latest = (await _latest(session, subject_type, [subject.id])).get(subject.id)
        session.add(
            PartyVerification(
                subject_type=subject_type,
                subject_id=subject.id,
                document_keys=list(latest.document_keys) if latest is not None else [],
                status="pending",
                reason=f"Re-check: {body.kind} {RESULT_WORDS[body.result]}",
                created_at=now,
                updated_at=now,
            )
        )
    await session.commit()
    return await _detail(session, subject_type, subject)
