"""Market linkage admin trust and safety (spec v1.5 §4, §4C; L6): the report queue, actions
(verify / warn / hide / suspend / restore) with a reason code the user sees, the action log,
and the appeals the grievance officer decides. Role `market_link_admin`, behind the legal gate.

Admin acts only on platform rules (fake or duplicate users, fake lots, impersonation, abuse),
never on a payment, weight or quality quarrel (§1 core principle, Addendum 5): the reason codes
each action may carry are fixed (`ACTION_REASONS`). Every action is a new `admin_actions` row
(actor, time); nothing is edited or deleted except the appeal state. Reports and appeals carry
the grievance timeline (acknowledged within 24 h, closed within 15 days) with overdue flags."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, model_validator
from sqlalchemy import select

from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.guards import MarketLinkIn
from bagmitra_api.market_link.models import (
    ACTION_REASONS,
    AdminAction,
    FraudReport,
)
from bagmitra_api.market_link.safety import new_action, overdue, subject_user
from bagmitra_api.routers.admin_market_link import Clock, MarketLinkAdmin
from bagmitra_api.routers.market_link import require_market_link
from bagmitra_api.routers.market_link_safety import ReportTarget
from bagmitra_api.routers.scouting_photos import (
    PhotoContext,
    PhotoDownloadUrl,
    get_photo_context,
    signed_download,
)

router = APIRouter(
    prefix="/v1/admin/market-link",
    tags=["admin"],
    dependencies=[Depends(require_market_link)],
    responses={code: {"model": ErrorResponse} for code in (401, 403, 404, 409, 422, 502, 503)},
)
Cfg = Annotated[Settings, Depends(get_settings)]
ActionName = Literal["verify", "warn", "hide", "suspend", "restore"]
ReasonCode = Literal[
    "fake_identity",
    "fake_lot",
    "impersonation",
    "fake_rating",
    "abuse",
    "duplicate_user",
    "checks_passed",
    "appeal_upheld",
]


class ReportAdminOut(BaseModel):
    id: uuid.UUID
    reporter_id: uuid.UUID
    subject_type: str
    subject_id: uuid.UUID
    subject_user_id: uuid.UUID | None
    reason: str
    photo_count: int
    status: str
    created_at: datetime
    acknowledged_at: datetime | None
    decided_at: datetime | None
    decided_by: uuid.UUID | None
    admin_action_id: uuid.UUID | None
    ack_overdue: bool
    close_overdue: bool


class ReportsAdminResponse(BaseModel):
    reports: list[ReportAdminOut]


class ActionOut(BaseModel):
    id: uuid.UUID
    subject_type: str
    subject_id: uuid.UUID
    user_id: uuid.UUID | None
    action: str
    reason_code: str
    actor_id: uuid.UUID
    acted_at: datetime
    appeal_state: str
    appeal_reason: str | None
    appealed_at: datetime | None
    appeal_photo_count: int
    appeal_acknowledged_at: datetime | None
    appeal_decided_by: uuid.UUID | None
    appeal_decided_at: datetime | None
    ack_overdue: bool
    close_overdue: bool


class ActionsResponse(BaseModel):
    actions: list[ActionOut]


def _check_reason(action: str, reason_code: str) -> None:
    if reason_code not in ACTION_REASONS[action]:
        raise ValueError(f"reason code {reason_code!r} is not allowed for {action}")


class ActionIn(MarketLinkIn):
    subject_type: ReportTarget
    subject_id: uuid.UUID
    action: ActionName
    reason_code: ReasonCode

    @model_validator(mode="after")
    def _reason_fits(self) -> ActionIn:
        _check_reason(self.action, self.reason_code)
        return self


class ReportDecisionIn(MarketLinkIn):
    action: Literal["warn", "hide", "suspend"]
    reason_code: ReasonCode

    @model_validator(mode="after")
    def _reason_fits(self) -> ReportDecisionIn:
        _check_reason(self.action, self.reason_code)
        return self


class AppealDecisionIn(MarketLinkIn):
    outcome: Literal["upheld", "rejected"]


def _report_out(
    r: FraudReport, owner: uuid.UUID | None, settings: Settings, now: datetime
) -> ReportAdminOut:
    closed = r.status != "open"
    ack, late = overdue(settings, now, r.created_at, r.acknowledged_at, closed)
    return ReportAdminOut(
        id=r.id,
        reporter_id=r.reporter_id,
        subject_type=r.subject_type,
        subject_id=r.subject_id,
        subject_user_id=owner,
        reason=r.reason,
        photo_count=len(r.photo_keys or []),
        status=r.status,
        created_at=r.created_at,
        acknowledged_at=r.acknowledged_at,
        decided_at=r.decided_at,
        decided_by=r.decided_by,
        admin_action_id=r.admin_action_id,
        ack_overdue=ack,
        close_overdue=late,
    )


def _action_out(a: AdminAction, settings: Settings, now: datetime) -> ActionOut:
    closed = a.appeal_state in ("upheld", "rejected")
    ack, late = overdue(settings, now, a.appealed_at, a.appeal_acknowledged_at, closed)
    return ActionOut(
        id=a.id,
        subject_type=a.subject_type,
        subject_id=a.subject_id,
        user_id=a.user_id,
        action=a.action,
        reason_code=a.reason_code,
        actor_id=a.actor_id,
        acted_at=a.acted_at,
        appeal_state=a.appeal_state,
        appeal_reason=a.appeal_reason,
        appealed_at=a.appealed_at,
        appeal_photo_count=len(a.appeal_photo_keys or []),
        appeal_acknowledged_at=a.appeal_acknowledged_at,
        appeal_decided_by=a.appeal_decided_by,
        appeal_decided_at=a.appeal_decided_at,
        ack_overdue=ack,
        close_overdue=late,
    )


async def _owner(session: DbSession, subject_type: str, subject_id: uuid.UUID) -> uuid.UUID | None:
    try:
        return await subject_user(session, subject_type, subject_id)
    except ApiError:
        return None  # the subject was erased since; the report stays in the log


@router.get("/reports", operation_id="admin_market_link_reports")
async def reports(
    _admin: MarketLinkAdmin,
    session: DbSession,
    settings: Cfg,
    clock: Clock,
    status: Annotated[Literal["open", "actioned", "dismissed"], Query()] = "open",
    subject_type: Annotated[ReportTarget | None, Query()] = None,
) -> ReportsAdminResponse:
    """Reports in one state, oldest first (the grievance timeline runs from creation)."""
    query = select(FraudReport).where(FraudReport.status == status)
    if subject_type is not None:
        query = query.where(FraudReport.subject_type == subject_type)
    rows = list(await session.scalars(query.order_by(FraudReport.created_at)))
    now = clock()
    return ReportsAdminResponse(
        reports=[
            _report_out(r, await _owner(session, r.subject_type, r.subject_id), settings, now)
            for r in rows
        ]
    )


async def _report(session: DbSession, report_id: uuid.UUID) -> FraudReport:
    row = await session.get(FraudReport, report_id)
    if row is None:
        raise ApiError(404, "report_not_found")
    return row


@router.post("/reports/{report_id}/acknowledge", operation_id="admin_market_link_report_ack")
async def acknowledge_report(
    report_id: uuid.UUID, _admin: MarketLinkAdmin, session: DbSession, settings: Cfg, clock: Clock
) -> ReportAdminOut:
    row = await _report(session, report_id)
    now = clock()
    if row.acknowledged_at is None:
        row.acknowledged_at = now
        await session.commit()
    owner = await _owner(session, row.subject_type, row.subject_id)
    return _report_out(row, owner, settings, now)


async def _close(
    session: DbSession,
    reports: list[FraudReport],
    admin_id: uuid.UUID,
    action_id: uuid.UUID | None,
    now: datetime,
) -> None:
    for r in reports:
        r.status = "dismissed" if action_id is None else "actioned"
        r.admin_action_id = action_id
        r.decided_by = admin_id
        r.decided_at = now
        r.acknowledged_at = r.acknowledged_at or now
    await session.commit()


async def _open_report(session: DbSession, report_id: uuid.UUID) -> FraudReport:
    row = await _report(session, report_id)
    if row.status != "open":
        raise ApiError(409, "report_closed")
    return row


@router.post("/reports/{report_id}/decision", operation_id="admin_market_link_report_decide")
async def decide_report(  # noqa: PLR0913 - path, body and dependencies
    report_id: uuid.UUID,
    body: ReportDecisionIn,
    admin: MarketLinkAdmin,
    session: DbSession,
    settings: Cfg,
    clock: Clock,
) -> ReportAdminOut:
    """Warn, hide or suspend the reported subject with a reason code; this closes every open
    report of the same subject with that action."""
    row = await _open_report(session, report_id)
    now = clock()
    owner = await _owner(session, row.subject_type, row.subject_id)
    action = new_action(
        subject_type=row.subject_type,
        subject_id=row.subject_id,
        user_id=owner,
        action=body.action,
        reason_code=body.reason_code,
        actor_id=admin.id,
        now=now,
    )
    session.add(action)
    await session.flush()
    same = await session.scalars(
        select(FraudReport).where(
            FraudReport.subject_type == row.subject_type,
            FraudReport.subject_id == row.subject_id,
            FraudReport.status == "open",
        )
    )
    await _close(session, list(same), admin.id, action.id, now)
    return _report_out(row, owner, settings, now)


@router.post("/reports/{report_id}/dismiss", operation_id="admin_market_link_report_dismiss")
async def dismiss_report(
    report_id: uuid.UUID, admin: MarketLinkAdmin, session: DbSession, settings: Cfg, clock: Clock
) -> ReportAdminOut:
    """No platform rule is broken: the report closes without an action."""
    row = await _open_report(session, report_id)
    now = clock()
    await _close(session, [row], admin.id, None, now)
    return _report_out(row, await _owner(session, row.subject_type, row.subject_id), settings, now)


@router.get(
    "/reports/{report_id}/photos/{index}/url", operation_id="admin_market_link_report_photo"
)
async def report_photo_url(
    report_id: uuid.UUID,
    index: int,
    _admin: MarketLinkAdmin,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> PhotoDownloadUrl:
    keys = list((await _report(session, report_id)).photo_keys or [])
    if not 0 <= index < len(keys):
        raise ApiError(404, "photo_not_found")
    return await signed_download(ctx, keys[index])


@router.post("/actions", operation_id="admin_market_link_act", status_code=201)
async def act(
    body: ActionIn, admin: MarketLinkAdmin, session: DbSession, settings: Cfg, clock: Clock
) -> ActionOut:
    """An action without a report (e.g. restore after a check, or hide a duplicate user)."""
    owner = await subject_user(session, body.subject_type, body.subject_id)
    now = clock()
    row = new_action(
        subject_type=body.subject_type,
        subject_id=body.subject_id,
        user_id=owner,
        action=body.action,
        reason_code=body.reason_code,
        actor_id=admin.id,
        now=now,
    )
    session.add(row)
    await session.commit()
    return _action_out(row, settings, now)


@router.get("/actions", operation_id="admin_market_link_actions")
async def actions(
    _admin: MarketLinkAdmin,
    session: DbSession,
    settings: Cfg,
    clock: Clock,
    subject_id: Annotated[uuid.UUID | None, Query()] = None,
    user_id: Annotated[uuid.UUID | None, Query()] = None,
) -> ActionsResponse:
    """The action log, newest first (at most 200 rows)."""
    query = select(AdminAction)
    if subject_id is not None:
        query = query.where(AdminAction.subject_id == subject_id)
    if user_id is not None:
        query = query.where(AdminAction.user_id == user_id)
    rows = await session.scalars(query.order_by(AdminAction.acted_at.desc()).limit(200))
    now = clock()
    return ActionsResponse(actions=[_action_out(a, settings, now) for a in rows])


@router.get("/appeals", operation_id="admin_market_link_appeals")
async def appeals(
    _admin: MarketLinkAdmin,
    session: DbSession,
    settings: Cfg,
    clock: Clock,
    state: Annotated[Literal["appealed", "upheld", "rejected"], Query()] = "appealed",
) -> ActionsResponse:
    """Appeals in one state, oldest appeal first."""
    rows = await session.scalars(
        select(AdminAction)
        .where(AdminAction.appeal_state == state)
        .order_by(AdminAction.appealed_at)
    )
    now = clock()
    return ActionsResponse(actions=[_action_out(a, settings, now) for a in rows])


async def _appeal(session: DbSession, action_id: uuid.UUID) -> AdminAction:
    row = await session.get(AdminAction, action_id)
    if row is None or row.appeal_state == "none":
        raise ApiError(404, "appeal_not_found")
    return row


@router.post("/appeals/{action_id}/acknowledge", operation_id="admin_market_link_appeal_ack")
async def acknowledge_appeal(
    action_id: uuid.UUID, _admin: MarketLinkAdmin, session: DbSession, settings: Cfg, clock: Clock
) -> ActionOut:
    row = await _appeal(session, action_id)
    now = clock()
    if row.appeal_acknowledged_at is None:
        row.appeal_acknowledged_at = now
        await session.commit()
    return _action_out(row, settings, now)


@router.post("/appeals/{action_id}/decision", operation_id="admin_market_link_appeal_decide")
async def decide_appeal(  # noqa: PLR0913 - path, body and dependencies
    action_id: uuid.UUID,
    body: AppealDecisionIn,
    admin: MarketLinkAdmin,
    session: DbSession,
    settings: Cfg,
    clock: Clock,
) -> ActionOut:
    """Uphold (a hide / suspend is lifted by a new restore row, reason `appeal_upheld`) or
    reject. Decided once."""
    row = await _appeal(session, action_id)
    if row.appeal_state != "appealed":
        raise ApiError(409, "appeal_decided")
    now = clock()
    row.appeal_state = body.outcome
    row.appeal_decided_by = admin.id
    row.appeal_decided_at = now
    row.appeal_acknowledged_at = row.appeal_acknowledged_at or now
    if body.outcome == "upheld" and row.action in ("hide", "suspend"):
        session.add(
            new_action(
                subject_type=row.subject_type,
                subject_id=row.subject_id,
                user_id=row.user_id,
                action="restore",
                reason_code="appeal_upheld",
                actor_id=admin.id,
                now=now,
            )
        )
    await session.commit()
    return _action_out(row, settings, now)


@router.get(
    "/appeals/{action_id}/photos/{index}/url", operation_id="admin_market_link_appeal_photo"
)
async def appeal_photo_url(
    action_id: uuid.UUID,
    index: int,
    _admin: MarketLinkAdmin,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> PhotoDownloadUrl:
    keys = list((await _appeal(session, action_id)).appeal_photo_keys or [])
    if not 0 <= index < len(keys):
        raise ApiError(404, "photo_not_found")
    return await signed_download(ctx, keys[index])
