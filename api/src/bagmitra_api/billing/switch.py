"""The admin's subscription switch and per-role amounts (billing addendum §7): load them as a
`BillingPolicy`, change them with a ledger entry (admin id, old / new) in `billing_events`, and
find which roles a user holds."""

from __future__ import annotations

import uuid
from datetime import date
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.entitlements import BILLING_ROLES, BillingPolicy
from bagmitra_api.billing.models import BillingEvent, BillingRolePrice, BillingSettings
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
