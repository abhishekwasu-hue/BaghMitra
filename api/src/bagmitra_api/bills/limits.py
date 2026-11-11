"""Bill reading limits (owner 2026-11-11, Q136): bill photos read per farmer per day and per
month, set by the billing admin for each role plan and for farmers without a plan, separately
from the photo analysis limits; an optional cap on all farmers together per day.

Which limits apply is the same rule as for photo analysis (`photo_ai/limits.py`): while the
subscription switch is in force and the farmer holds an active role plan, that plan's values
(several plans: the most generous); otherwise the admin's "without a plan" values. An empty
value = DAILY_DEFAULT / MONTHLY_DEFAULT (5 / 50); an empty overall cap = no cap.

Counting: rows in `bill_reads` (one per successful read) per India calendar day and month. A
failed read stores nothing and is not counted.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.entitlements import ROLE_PLAN_PREFIX
from bagmitra_api.billing.models import BillingRolePrice, BillingSettings
from bagmitra_api.billing.service import entitlements_for
from bagmitra_api.billing.switch import load_policy
from bagmitra_api.bills.models import BillRead
from bagmitra_api.photo_ai.limits import (
    DAILY_DEFAULT,
    MONTHLY_DEFAULT,
    LimitHit,
    PhotoLimits,
    day_window,
    month_window,
)

__all__ = ["DAILY_DEFAULT", "MONTHLY_DEFAULT", "bill_limit_hit", "bill_limits_for"]


def _or_default(value: int | None, default: int) -> int:
    return default if value is None else value


async def bill_limits_for(session: AsyncSession, user_id: uuid.UUID, now: datetime) -> PhotoLimits:
    settings = await session.get(BillingSettings, 1)
    total = settings.bill_read_daily_total if settings else None
    policy = await load_policy(session)
    roles: list[str] = []
    if policy.in_force(now):
        plans = (await entitlements_for(session, "farmer", user_id, now)).plans
        roles = [p.removeprefix(ROLE_PLAN_PREFIX) for p in plans if p.startswith(ROLE_PLAN_PREFIX)]
    if roles:
        rows = list(
            await session.scalars(select(BillingRolePrice).where(BillingRolePrice.role.in_(roles)))
        )
        daily = [_or_default(r.bill_read_daily, DAILY_DEFAULT) for r in rows]
        monthly = [_or_default(r.bill_read_monthly, MONTHLY_DEFAULT) for r in rows]
        return PhotoLimits(
            daily=max(daily, default=DAILY_DEFAULT),
            monthly=max(monthly, default=MONTHLY_DEFAULT),
            daily_total=total,
            source="plan",
        )
    return PhotoLimits(
        daily=_or_default(settings.bill_read_free_daily if settings else None, DAILY_DEFAULT),
        monthly=_or_default(settings.bill_read_free_monthly if settings else None, MONTHLY_DEFAULT),
        daily_total=total,
        source="no_plan",
    )


async def _count(
    session: AsyncSession, start: datetime, end: datetime, owner: uuid.UUID | None
) -> int:
    query = (
        select(func.count())
        .select_from(BillRead)
        .where(BillRead.created_at >= start, BillRead.created_at < end)
    )
    if owner is not None:
        query = query.where(BillRead.owner_id == owner)
    return int(await session.scalar(query) or 0)


async def bill_limit_hit(
    session: AsyncSession, user_id: uuid.UUID, now: datetime
) -> LimitHit | None:
    """The first limit the farmer's next bill would pass (daily, monthly, overall), or None."""
    limits = await bill_limits_for(session, user_id, now)
    day_start, day_end = day_window(now)
    month_start, month_end = month_window(now)
    if await _count(session, day_start, day_end, user_id) >= limits.daily:
        return LimitHit("daily", limits.daily, day_end)
    if await _count(session, month_start, month_end, user_id) >= limits.monthly:
        return LimitHit("monthly", limits.monthly, month_end)
    total = limits.daily_total
    if total is not None and await _count(session, day_start, day_end, None) >= total:
        return LimitHit("total", total, day_end)
    return None
