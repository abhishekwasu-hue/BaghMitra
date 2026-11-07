"""Market linkage trust and safety for users (spec v1.5 §4, §4C; L6): report a profile, lot,
rating or user with a predefined reason (no text; photos optional, EXIF stripped), block and
unblock another user, see the admin actions about oneself with their reason code, and make the
one appeal (predefined reason, optional photo) that the grievance officer decides.
Behind the legal gate `market_link_enabled` (404 while off)."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Request, Response
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.guards import MarketLinkIn
from bagmitra_api.market_link.models import (
    APPEALABLE_ACTIONS,
    AdminAction,
    FraudReport,
    UserBlock,
)
from bagmitra_api.market_link.safety import PHOTO_BODY, store_photo, subject_user
from bagmitra_api.routers.admin_market_link import Clock
from bagmitra_api.routers.market_link import require_market_link
from bagmitra_api.routers.scouting_photos import PhotoContext, get_photo_context

router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={
        401: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
)
Photos = Annotated[PhotoContext, Depends(get_photo_context)]
_PHOTO_RESPONSES: dict[int | str, dict[str, object]] = {
    code: {"model": ErrorResponse} for code in (409, 413, 502, 503)
}
ReportTarget = Literal["buyer", "broker", "provider", "lot", "rating", "user"]
ReportReason = Literal["fake_identity", "fake_lot", "impersonation", "fake_rating", "abuse"]
AppealReason = Literal[
    "identity_genuine", "lot_genuine", "rating_genuine", "behaviour_proper", "not_duplicate"
]


class ReportIn(MarketLinkIn):
    """Codes only: any other key (a text, a comment) is refused."""

    subject_type: ReportTarget
    subject_id: uuid.UUID
    reason: ReportReason


class ReportOut(BaseModel):
    id: uuid.UUID
    subject_type: str
    subject_id: uuid.UUID
    reason: str
    photo_count: int
    status: str
    created_at: datetime
    decided_at: datetime | None


class ReportsResponse(BaseModel):
    reports: list[ReportOut]


class BlocksResponse(BaseModel):
    blocked_user_ids: list[uuid.UUID]


class AccountActionOut(BaseModel):
    id: uuid.UUID
    subject_type: str
    subject_id: uuid.UUID
    action: str
    reason_code: str
    acted_at: datetime
    appeal_state: str
    appeal_reason: str | None
    appealed_at: datetime | None
    appeal_photo_count: int
    appeal_decided_at: datetime | None
    # True while the one appeal is still open to make.
    can_appeal: bool


class AccountActionsResponse(BaseModel):
    actions: list[AccountActionOut]


class AppealIn(MarketLinkIn):
    reason: AppealReason


def _report_out(r: FraudReport) -> ReportOut:
    return ReportOut(
        id=r.id,
        subject_type=r.subject_type,
        subject_id=r.subject_id,
        reason=r.reason,
        photo_count=len(r.photo_keys or []),
        status=r.status,
        created_at=r.created_at,
        decided_at=r.decided_at,
    )


def _action_out(a: AdminAction) -> AccountActionOut:
    return AccountActionOut(
        id=a.id,
        subject_type=a.subject_type,
        subject_id=a.subject_id,
        action=a.action,
        reason_code=a.reason_code,
        acted_at=a.acted_at,
        appeal_state=a.appeal_state,
        appeal_reason=a.appeal_reason,
        appealed_at=a.appealed_at,
        appeal_photo_count=len(a.appeal_photo_keys or []),
        appeal_decided_at=a.appeal_decided_at,
        can_appeal=a.action in APPEALABLE_ACTIONS and a.appeal_state == "none",
    )


@router.post("/reports", operation_id="market_link_report", status_code=201)
async def report(body: ReportIn, user: CurrentUser, session: DbSession, clock: Clock) -> ReportOut:
    """Report to the admin queue. A second report of the same subject by the same person
    while the first is open returns the first."""
    owner = await subject_user(session, body.subject_type, body.subject_id)
    if owner == user.id:
        raise ApiError(422, "cannot_report_self")
    existing = await session.scalar(
        select(FraudReport).where(
            FraudReport.reporter_id == user.id,
            FraudReport.subject_type == body.subject_type,
            FraudReport.subject_id == body.subject_id,
            FraudReport.status == "open",
        )
    )
    if existing is not None:
        return _report_out(existing)
    now = clock()
    row = FraudReport(
        reporter_id=user.id,
        subject_type=body.subject_type,
        subject_id=body.subject_id,
        reason=body.reason,
        photo_keys=[],
        status="open",
        created_at=now,
        updated_at=now,
    )
    session.add(row)
    await session.commit()
    return _report_out(row)


@router.post(
    "/reports/{report_id}/photos",
    operation_id="market_link_report_photo",
    responses=_PHOTO_RESPONSES,
    openapi_extra=PHOTO_BODY,
)
async def report_photo(
    report_id: uuid.UUID, request: Request, user: CurrentUser, session: DbSession, ctx: Photos
) -> ReportOut:
    """Adds one optional JPEG to the caller's open report (EXIF stripped by the server)."""
    row = await session.get(FraudReport, report_id)
    if row is None or row.reporter_id != user.id:
        raise ApiError(404, "report_not_found")
    keys = list(row.photo_keys or [])
    if row.status != "open" or len(keys) >= ctx.settings.market_link_report_max_photos:
        raise ApiError(409, "report_photos_closed")
    key = f"{user.id}/report-{row.id}-{len(keys) + 1}.jpg"
    await store_photo(request, ctx, key)
    row.photo_keys = [*keys, key]
    await session.commit()
    return _report_out(row)


@router.get("/reports/mine", operation_id="market_link_my_reports")
async def my_reports(user: CurrentUser, session: DbSession) -> ReportsResponse:
    rows = await session.scalars(
        select(FraudReport)
        .where(FraudReport.reporter_id == user.id)
        .order_by(FraudReport.created_at.desc())
    )
    return ReportsResponse(reports=[_report_out(r) for r in rows])


@router.get("/blocks", operation_id="market_link_blocks")
async def blocks(user: CurrentUser, session: DbSession) -> BlocksResponse:
    rows = await session.scalars(
        select(UserBlock.blocked_id)
        .where(UserBlock.blocker_id == user.id)
        .order_by(UserBlock.created_at)
    )
    return BlocksResponse(blocked_user_ids=list(rows))


@router.put("/blocks/{user_id}", operation_id="market_link_block", status_code=204)
async def block(
    user_id: uuid.UUID, user: CurrentUser, session: DbSession, clock: Clock
) -> Response:
    """Block a user: neither sees the other in lists or interests. Repeating it is a no-op."""
    if user_id == user.id:
        raise ApiError(422, "cannot_block_self")
    found = await session.scalar(
        select(UserBlock).where(UserBlock.blocker_id == user.id, UserBlock.blocked_id == user_id)
    )
    if found is None:
        now = clock()
        session.add(
            UserBlock(blocker_id=user.id, blocked_id=user_id, created_at=now, updated_at=now)
        )
        await session.commit()
    return Response(status_code=204)


@router.delete("/blocks/{user_id}", operation_id="market_link_unblock", status_code=204)
async def unblock(user_id: uuid.UUID, user: CurrentUser, session: DbSession) -> Response:
    found = await session.scalar(
        select(UserBlock).where(UserBlock.blocker_id == user.id, UserBlock.blocked_id == user_id)
    )
    if found is not None:
        await session.delete(found)
        await session.commit()
    return Response(status_code=204)


@router.get("/account-actions", operation_id="market_link_account_actions")
async def account_actions(user: CurrentUser, session: DbSession) -> AccountActionsResponse:
    """Every admin action about the caller, newest first, with its reason code (§4C)."""
    rows = await session.scalars(
        select(AdminAction)
        .where(AdminAction.user_id == user.id)
        .order_by(AdminAction.acted_at.desc())
    )
    return AccountActionsResponse(actions=[_action_out(a) for a in rows])


async def _own_action(session: DbSession, user: CurrentUser, action_id: uuid.UUID) -> AdminAction:
    row = await session.get(AdminAction, action_id)
    if row is None or row.user_id != user.id:
        raise ApiError(404, "action_not_found")
    return row


@router.post(
    "/account-actions/{action_id}/appeal",
    operation_id="market_link_appeal",
    responses={409: {"model": ErrorResponse}},
)
async def appeal(
    action_id: uuid.UUID, body: AppealIn, user: CurrentUser, session: DbSession, clock: Clock
) -> AccountActionOut:
    """The one appeal against a warn, hide or suspend; the grievance officer decides."""
    row = await _own_action(session, user, action_id)
    if row.action not in APPEALABLE_ACTIONS or row.appeal_state != "none":
        raise ApiError(409, "appeal_not_open")
    row.appeal_state = "appealed"
    row.appeal_reason = body.reason
    row.appealed_at = clock()
    await session.commit()
    return _action_out(row)


@router.post(
    "/account-actions/{action_id}/appeal/photos",
    operation_id="market_link_appeal_photo",
    responses=_PHOTO_RESPONSES,
    openapi_extra=PHOTO_BODY,
)
async def appeal_photo(
    action_id: uuid.UUID, request: Request, user: CurrentUser, session: DbSession, ctx: Photos
) -> AccountActionOut:
    """Adds one optional JPEG to the caller's open appeal (EXIF stripped by the server)."""
    row = await _own_action(session, user, action_id)
    keys = list(row.appeal_photo_keys or [])
    if row.appeal_state != "appealed" or len(keys) >= ctx.settings.market_link_report_max_photos:
        raise ApiError(409, "appeal_photos_closed")
    key = f"{user.id}/appeal-{row.id}-{len(keys) + 1}.jpg"
    await store_photo(request, ctx, key)
    row.appeal_photo_keys = [*keys, key]
    await session.commit()
    return _action_out(row)
