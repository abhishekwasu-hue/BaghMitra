"""Who and what other people may see (spec v1.5 §4, §4C; L6). Every list of profiles, lots,
interests or ratings that other milestones build filters through these helpers:

- `visible(kind, id_col, user_col)`: the row is not hidden or suspended by an admin action and
  its user is not suspended nor a deleted account waiting for erasure (Q68: hidden at once).
- `not_blocked(viewer_id, user_col)`: neither side blocked the other (blocked users are hidden
  from each other in lists and interests).
- `is_suspended` / `require_not_suspended`: a suspended account cannot act in the module.

State comes from the append-only `admin_actions` log: for each subject the latest hide /
suspend / restore decides (a warn or a verify changes nothing). A suspend also suspends the
user the action is about, so all of their profiles and lots disappear.
"""

from __future__ import annotations

import uuid
from typing import Any

from fastapi import Depends
from sqlalchemy import ColumnElement, Select, and_, func, or_, select, union
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import InstrumentedAttribute

from bagmitra_api.account.models import DeferredErasure
from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.models import AdminAction, UserBlock

STATE_ACTIONS = ("hide", "suspend", "restore")
HIDING_ACTIONS = ("hide", "suspend")
# A model column (`BuyerProfile.user_id`) or any column expression.
Col = ColumnElement[Any] | InstrumentedAttribute[Any]


def _latest_state() -> Any:
    rank = (
        func.row_number()
        .over(
            partition_by=(AdminAction.subject_type, AdminAction.subject_id),
            order_by=(AdminAction.acted_at.desc(), AdminAction.created_at.desc()),
        )
        .label("rank")
    )
    return (
        select(AdminAction.subject_type, AdminAction.subject_id, AdminAction.user_id)
        .add_columns(AdminAction.action, rank)
        .where(AdminAction.action.in_(STATE_ACTIONS))
        .subquery()
    )


def hidden_subject_ids(kind: str) -> Select[tuple[uuid.UUID]]:
    """Ids of `kind` subjects whose latest state action is hide or suspend."""
    s = _latest_state()
    return select(s.c.subject_id).where(
        s.c.rank == 1, s.c.subject_type == kind, s.c.action.in_(HIDING_ACTIONS)
    )


def hidden_user_ids() -> Any:
    """Suspended users and deleted accounts (hidden at once, erased later)."""
    s = _latest_state()
    suspended = select(s.c.user_id).where(
        s.c.rank == 1, s.c.action == "suspend", s.c.user_id.is_not(None)
    )
    return union(suspended, select(DeferredErasure.user_id))


def visible(kind: str, id_col: Col, user_col: Col | None = None) -> ColumnElement[bool]:
    """A WHERE clause: the row is shown to other people."""
    clause = id_col.not_in(hidden_subject_ids(kind))
    if user_col is None:
        return clause
    return and_(clause, or_(user_col.is_(None), user_col.not_in(hidden_user_ids())))


def not_blocked(viewer_id: uuid.UUID, user_col: Col) -> ColumnElement[bool]:
    """A WHERE clause: neither the viewer nor the row's user blocked the other."""
    blocked = select(UserBlock.blocked_id).where(UserBlock.blocker_id == viewer_id)
    blockers = select(UserBlock.blocker_id).where(UserBlock.blocked_id == viewer_id)
    return or_(user_col.is_(None), and_(user_col.not_in(blocked), user_col.not_in(blockers)))


async def is_blocked_between(session: AsyncSession, a: uuid.UUID, b: uuid.UUID) -> bool:
    """True when either user blocked the other (an interest between them is refused)."""
    found = await session.scalar(
        select(UserBlock.id).where(
            or_(
                and_(UserBlock.blocker_id == a, UserBlock.blocked_id == b),
                and_(UserBlock.blocker_id == b, UserBlock.blocked_id == a),
            )
        )
    )
    return found is not None


async def is_hidden_user(session: AsyncSession, user_id: uuid.UUID) -> bool:
    """Suspended or deleted: shown nowhere, and ratings they gave appear without a name."""
    hidden = hidden_user_ids().subquery()
    found = await session.scalar(select(hidden.c.user_id).where(hidden.c.user_id == user_id))
    return found is not None


async def is_suspended(session: AsyncSession, user_id: uuid.UUID) -> bool:
    s = _latest_state()
    found = await session.scalar(
        select(s.c.user_id).where(s.c.rank == 1, s.c.action == "suspend", s.c.user_id == user_id)
    )
    return found is not None


async def require_not_suspended(user: CurrentUser, session: DbSession) -> None:
    """Dependency for market-link writes: 403 `suspended` while suspended (the reason is in
    the user's "My account actions")."""
    if await is_suspended(session, user.id):
        raise ApiError(403, "suspended")


# Route dependencies of every market-link write a suspended account may not make: register
# (and its address / documents / place photo), publish and lot photos, interest, accept,
# deal done, rate, report. Blocks, appeals, terms and closing an own lot stay open.
NOT_SUSPENDED = [Depends(require_not_suspended)]
