"""Photo analysis limits (owner 2026-11-11): photos per farmer per day and per month, set by the
billing admin for each role plan and for farmers without a plan; an optional cap on all farmers
together per day. Nothing here is an environment setting.

Which limits apply:
- while the subscription switch is in force and the farmer holds an active role plan: that
  plan's values (several plans: the most generous); a plan value left empty = the default;
- otherwise (no plan, or the switch off / not started yet): the admin's "without a plan"
  values; empty = the default.
The default is DAILY_DEFAULT / MONTHLY_DEFAULT (owner: "डेली 5 फोटो, मंथली 50"). The overall
cap has no default: empty = no overall cap.

Counting: analysed photos (stored samples) per India calendar day (Asia/Kolkata midnight) and
per India calendar month. A failed analysis stores nothing and is not counted.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, time, timedelta
from typing import Literal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.entitlements import INDIA, ROLE_PLAN_PREFIX
from bagmitra_api.billing.models import BillingRolePrice, BillingSettings
from bagmitra_api.billing.service import entitlements_for
from bagmitra_api.billing.switch import load_policy
from bagmitra_api.photo_ai.models import PhotoAnalysisSample

DAILY_DEFAULT = 5
MONTHLY_DEFAULT = 50
LimitKind = Literal["daily", "monthly", "total"]


@dataclass(frozen=True, slots=True)
class PhotoLimits:
    daily: int
    monthly: int
    # Photos of all farmers together per India day; None = no overall cap.
    daily_total: int | None
    # Where the per-farmer values came from: "plan" or "no_plan".
    source: str


@dataclass(frozen=True, slots=True)
class LimitHit:
    kind: LimitKind
    limit: int
    resets_at: datetime


def day_window(now: datetime) -> tuple[datetime, datetime]:
    """The India calendar day around `now`, in UTC."""
    local = now.astimezone(INDIA).date()
    start = datetime.combine(local, time(), INDIA)
    return start.astimezone(UTC), (start + timedelta(days=1)).astimezone(UTC)


def month_window(now: datetime) -> tuple[datetime, datetime]:
    """The India calendar month around `now`, in UTC."""
    local = now.astimezone(INDIA).date().replace(day=1)
    following = (local.replace(day=28) + timedelta(days=4)).replace(day=1)
    return (
        datetime.combine(local, time(), INDIA).astimezone(UTC),
        datetime.combine(following, time(), INDIA).astimezone(UTC),
    )


def _or_default(value: int | None, default: int) -> int:
    return default if value is None else value


async def limits_for(session: AsyncSession, user_id: uuid.UUID, now: datetime) -> PhotoLimits:
    settings = await session.get(BillingSettings, 1)
    total = settings.photo_ai_daily_total if settings else None
    policy = await load_policy(session)
    roles: list[str] = []
    if policy.in_force(now):
        plans = (await entitlements_for(session, "farmer", user_id, now)).plans
        roles = [p.removeprefix(ROLE_PLAN_PREFIX) for p in plans if p.startswith(ROLE_PLAN_PREFIX)]
    if roles:
        rows = list(
            await session.scalars(select(BillingRolePrice).where(BillingRolePrice.role.in_(roles)))
        )
        daily = [_or_default(r.photo_ai_daily, DAILY_DEFAULT) for r in rows]
        monthly = [_or_default(r.photo_ai_monthly, MONTHLY_DEFAULT) for r in rows]
        return PhotoLimits(
            daily=max(daily, default=DAILY_DEFAULT),
            monthly=max(monthly, default=MONTHLY_DEFAULT),
            daily_total=total,
            source="plan",
        )
    return PhotoLimits(
        daily=_or_default(settings.photo_ai_free_daily if settings else None, DAILY_DEFAULT),
        monthly=_or_default(settings.photo_ai_free_monthly if settings else None, MONTHLY_DEFAULT),
        daily_total=total,
        source="no_plan",
    )


async def _count(
    session: AsyncSession, start: datetime, end: datetime, owner: uuid.UUID | None
) -> int:
    query = (
        select(func.count())
        .select_from(PhotoAnalysisSample)
        .where(PhotoAnalysisSample.created_at >= start, PhotoAnalysisSample.created_at < end)
    )
    if owner is not None:
        query = query.where(PhotoAnalysisSample.owner_id == owner)
    return int(await session.scalar(query) or 0)


async def limit_hit(session: AsyncSession, user_id: uuid.UUID, now: datetime) -> LimitHit | None:
    """The first limit the farmer's next photo would pass (daily, monthly, overall), or None."""
    limits = await limits_for(session, user_id, now)
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
