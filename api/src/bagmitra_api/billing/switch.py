"""The admin's subscription switch and per-role amounts (billing addendum §7): load them as a
`BillingPolicy`, change them with a ledger entry (admin id, old / new) in `billing_events`, and
find which roles a user holds."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import date, datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.entitlements import BILLING_ROLES, BillingPolicy
from bagmitra_api.billing.models import BillingEvent, BillingRolePrice, BillingSettings
from bagmitra_api.billing.play import PlayPublisher
from bagmitra_api.db.models.plot import Plot
from bagmitra_api.market_link.models import BrokerProfile, BuyerProfile, ServiceProvider


async def billing_settings(session: AsyncSession) -> BillingSettings:
    """The single settings row; created with the switch OFF on first use."""
    row = await session.get(BillingSettings, 1)
    if row is None:
        row = BillingSettings(id=1, enabled=False)
        session.add(row)
        await session.flush()
    return row


async def role_prices(session: AsyncSession) -> dict[str, BillingRolePrice]:
    """One row per role; missing rows are created empty (free)."""
    rows = {r.role: r for r in await session.scalars(select(BillingRolePrice))}
    for role in BILLING_ROLES:
        if role not in rows:
            rows[role] = BillingRolePrice(role=role)
            session.add(rows[role])
    await session.flush()
    return {role: rows[role] for role in BILLING_ROLES}


async def load_policy(session: AsyncSession) -> BillingPolicy:
    settings = await session.get(BillingSettings, 1)
    prices = {
        r.role: r.amount_paise
        for r in await session.scalars(select(BillingRolePrice))
        if r.amount_paise
    }
    if settings is None:
        return BillingPolicy(prices=prices)
    return BillingPolicy(enabled=settings.enabled, starts_on=settings.starts_on, prices=prices)


def log_admin_change(
    session: AsyncSession, event_type: str, admin_id: uuid.UUID, old: Any, new: Any
) -> None:
    session.add(
        BillingEvent(
            id=uuid.uuid4(),
            subscription_id=None,
            provider="admin",
            event_type=event_type,
            notification_id=None,
            payload={"admin_id": str(admin_id), "old": old, "new": new},
        )
    )


async def change_switch(
    session: AsyncSession, admin_id: uuid.UUID, *, enabled: bool, starts_on: date | None
) -> BillingSettings:
    row = await billing_settings(session)
    old = {"enabled": row.enabled, "starts_on": _iso(row.starts_on)}
    new = {"enabled": enabled, "starts_on": _iso(starts_on)}
    if old != new:
        row.enabled, row.starts_on = enabled, starts_on
        log_admin_change(session, "switch_changed", admin_id, old, new)
    await session.flush()
    return row


async def change_photo_limits(
    session: AsyncSession,
    admin_id: uuid.UUID,
    *,
    free_daily: int | None,
    free_monthly: int | None,
    daily_total: int | None,
) -> BillingSettings:
    """Photo analysis limits without a plan and the optional overall cap (Q135)."""
    row = await billing_settings(session)
    old = {
        "free_daily": row.photo_ai_free_daily,
        "free_monthly": row.photo_ai_free_monthly,
        "daily_total": row.photo_ai_daily_total,
    }
    new = {"free_daily": free_daily, "free_monthly": free_monthly, "daily_total": daily_total}
    if old != new:
        row.photo_ai_free_daily, row.photo_ai_free_monthly = free_daily, free_monthly
        row.photo_ai_daily_total = daily_total
        log_admin_change(session, "photo_limits_changed", admin_id, old, new)
    await session.flush()
    return row


async def set_role_photo_limits(
    session: AsyncSession,
    admin_id: uuid.UUID,
    role: str,
    *,
    daily: int | None,
    monthly: int | None,
) -> BillingRolePrice:
    """Photo analysis limits of one role's plan (Q135); None = the default."""
    row = (await role_prices(session))[role]
    old = {"role": role, "daily": row.photo_ai_daily, "monthly": row.photo_ai_monthly}
    new = {"role": role, "daily": daily, "monthly": monthly}
    if old != new:
        row.photo_ai_daily, row.photo_ai_monthly = daily, monthly
        log_admin_change(session, "role_photo_limits_changed", admin_id, old, new)
    await session.flush()
    return row


def _iso(value: date | None) -> str | None:
    return value.isoformat() if value else None


async def user_roles(session: AsyncSession, user_id: uuid.UUID) -> tuple[str, ...]:
    """Trader / exporter / broker / provider from the market-link registrations; grower when
    the user keeps a plot, or holds no other role (OPEN_QUESTIONS Q119)."""
    roles: list[str] = []
    buyer = await session.scalar(select(BuyerProfile.kind).where(BuyerProfile.user_id == user_id))
    if buyer:
        roles.append(buyer)
    if await session.scalar(select(BrokerProfile.id).where(BrokerProfile.user_id == user_id)):
        roles.append("broker")
    provider = select(ServiceProvider.id).where(ServiceProvider.user_id == user_id).limit(1)
    if await session.scalar(provider):
        roles.append("provider")
    plot = select(Plot.id).where(Plot.owner_id == user_id, Plot.deleted_at.is_(None)).limit(1)
    if not roles or await session.scalar(plot):
        roles.insert(0, "grower")
    return tuple(roles)


@dataclass(frozen=True, slots=True)
class PlayPlan:
    product_id: str
    base_plan_id: str


class PlayNotSetUpError(Exception):
    pass


class NoPlayPriceError(Exception):
    pass


async def set_role_amount(  # noqa: PLR0913 - session, Play, role, amount, plan, admin, clock
    session: AsyncSession,
    publisher: PlayPublisher | None,
    role: str,
    amount_paise: int | None,
    plan: PlayPlan,
    *,
    admin_id: uuid.UUID,
    now: datetime,
) -> BillingRolePrice:
    """Save a role's monthly amount. An amount is first written to Play (the price source of
    truth) and the price Play reports is stored; nothing is saved when Play refuses. Clearing
    the amount (the role becomes free) does not touch Play."""
    row = (await role_prices(session))[role]
    old = {"role": role, "amount_paise": row.amount_paise, "play_price_paise": row.play_price_paise}
    if amount_paise is not None:
        if publisher is None:
            raise PlayNotSetUpError(role)
        price = await publisher.set_monthly_price(plan.product_id, plan.base_plan_id, amount_paise)
        row.play_price_paise, row.play_currency = price.paise, price.currency
        row.play_synced_at = now
    row.amount_paise = amount_paise
    new = {**old, "amount_paise": amount_paise, "play_price_paise": row.play_price_paise}
    log_admin_change(session, "role_price_changed", admin_id, old, new)
    await session.flush()
    return row


async def migrate_role_prices(
    session: AsyncSession,
    publisher: PlayPublisher | None,
    role: str,
    plan: PlayPlan,
    *,
    admin_id: uuid.UUID,
) -> None:
    """The admin's confirmed action: existing subscribers of the role move to the price set
    last (Play's opt-in increase: notice first, cancelled when not accepted)."""
    row = (await role_prices(session))[role]
    if row.play_synced_at is None:
        raise NoPlayPriceError(role)
    if publisher is None:
        raise PlayNotSetUpError(role)
    await publisher.migrate_prices(plan.product_id, plan.base_plan_id, row.play_synced_at)
    new = {"role": role, "play_price_paise": row.play_price_paise}
    log_admin_change(session, "prices_migrated", admin_id, None, new)
    await session.flush()
