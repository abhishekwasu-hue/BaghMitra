"""Google Play purchases become subscription rows (billing addendum §2.2-§2.4).

The app sends a purchase token; the server asks Play (`purchases.subscriptionsv2.get`) for the
truth, maps Play's state to ours, binds the token (stored only as a SHA-256 hash) to exactly one
user, checks the obfuscated account id the app passed to the billing flow, acknowledges the
purchase (the server acknowledges; the app never does) and records the result in the ledger.
Notifications and the reconciliation job call the same `sync_purchase`.
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.entitlements import BILLING_ROLES, ROLE_PLAN_PREFIX, SubscriptionState
from bagmitra_api.billing.models import BillingEvent, BillingPlan, Subscription
from bagmitra_api.billing.play import PlayError, PlayPublisher, paise_of

PLAY_STATES: dict[str, SubscriptionState] = {
    "SUBSCRIPTION_STATE_PENDING": "PENDING",
    "SUBSCRIPTION_STATE_ACTIVE": "ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD": "IN_GRACE_PERIOD",
    "SUBSCRIPTION_STATE_ON_HOLD": "ON_HOLD",
    "SUBSCRIPTION_STATE_PAUSED": "PAUSED",
    "SUBSCRIPTION_STATE_CANCELED": "CANCELED",
    "SUBSCRIPTION_STATE_EXPIRED": "EXPIRED",
    "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED": "EXPIRED",
}
ROLE_NAMES = {
    # The app's own role words (l10n mlRole*), so the plan name reads the same everywhere.
    "grower": {"en": "Grower", "mr": "शेतकरी", "hi": "किसान"},
    "trader": {"en": "Trader", "mr": "व्यापारी", "hi": "व्यापारी"},
    "broker": {"en": "Broker", "mr": "मध्यस्थ (दलाल)", "hi": "मध्यस्थ (दलाल)"},
    "exporter": {"en": "Exporter", "mr": "निर्यातदार", "hi": "निर्यातक"},
    "provider": {"en": "Service provider", "mr": "सेवा देणारे", "hi": "सेवा देने वाले"},
}


class TokenOwnedError(Exception):
    """The token is already bound to a different user (a replayed token)."""


class AccountMismatchError(Exception):
    """Play's obfuscated account id is not the caller's."""


class UnknownProductError(Exception):
    pass


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def account_id(user_id: uuid.UUID) -> str:
    """The stable obfuscated id the app passes to the billing flow (64 hex characters)."""
    return hashlib.sha256(f"bagmitra-play:{user_id}".encode()).hexdigest()


@dataclass(frozen=True, slots=True)
class PlayFacts:
    product_id: str
    state: SubscriptionState
    start: datetime
    end: datetime
    auto_renew: bool
    acknowledged: bool
    account: str | None
    linked_token: str | None
    price_change: dict[str, Any] | None


def _time(value: Any, default: datetime) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00")) if value else default


def read_purchase(body: dict[str, Any], now: datetime) -> PlayFacts:
    items = body.get("lineItems") or []
    if not items or body.get("subscriptionState") not in PLAY_STATES:
        raise PlayError("Google Play: unexpected purchase")
    item = items[0]
    plan = item.get("autoRenewingPlan") or {}
    change = plan.get("priceChangeDetails")
    price_change = None
    if change:
        price = change.get("newPrice") or {}
        price_change = {
            "state": change.get("priceChangeState"),
            "mode": change.get("priceChangeMode"),
            "new_price_paise": paise_of(price),
            "currency": price.get("currencyCode"),
            "charge_time": change.get("expectedNewPriceChargeTime"),
        }
    return PlayFacts(
        product_id=str(item.get("productId", "")),
        state=PLAY_STATES[body["subscriptionState"]],
        start=_time(body.get("startTime"), now),
        end=_time(item.get("expiryTime"), now),
        auto_renew=bool(plan.get("autoRenewEnabled")),
        acknowledged=body.get("acknowledgementState") == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
        account=(body.get("externalAccountIdentifiers") or {}).get("obfuscatedExternalAccountId"),
        linked_token=body.get("linkedPurchaseToken"),
        price_change=price_change,
    )


async def ensure_role_plan(session: AsyncSession, role: str) -> BillingPlan:
    """The plan row a role subscription points at (no features of its own: it covers roles)."""
    key = ROLE_PLAN_PREFIX + role
    plan = await session.scalar(select(BillingPlan).where(BillingPlan.key == key))
    if plan is None:
        sort_order = 100 + BILLING_ROLES.index(role)
        plan = BillingPlan(
            id=uuid.uuid4(), key=key, names=ROLE_NAMES[role], kind="role", sort_order=sort_order
        )
        session.add(plan)
        await session.flush()
    return plan


async def sync_purchase(  # noqa: PLR0913 - session, Play, token, subject, clock, prefix
    session: AsyncSession,
    play: PlayPublisher,
    token: str,
    *,
    subject_id: uuid.UUID | None,
    now: datetime,
    product_prefix: str,
) -> Subscription | None:
    """Fetch the truth from Play and store it. `subject_id` is the caller when the app sends
    the token; None for a notification or the job (then only a known token is updated)."""
    facts = read_purchase(await play.get_subscription(token), now)
    role = facts.product_id.removeprefix(product_prefix)
    if not facts.product_id.startswith(product_prefix) or role not in BILLING_ROLES:
        raise UnknownProductError(facts.product_id)
    hashed = token_hash(token)
    row = await session.scalar(
        select(Subscription).where(Subscription.purchase_token_hash == hashed)
    )
    if row is not None and subject_id is not None and row.subject_id != subject_id:
        raise TokenOwnedError
    subject = subject_id or (row.subject_id if row else None)
    if subject is None:
        return None  # the app has not sent this token yet; it will on its next start
    if facts.account != account_id(subject):
        raise AccountMismatchError
    plan = await ensure_role_plan(session, role)
    if row is None:
        row = Subscription(
            id=uuid.uuid4(),
            subject_type="farmer",
            subject_id=subject,
            provider="google_play",
            purchase_token_hash=hashed,
        )
    row.plan_id, row.provider_product_id, row.state = plan.id, facts.product_id, facts.state
    row.period_start, row.period_end, row.auto_renew = facts.start, facts.end, facts.auto_renew
    row.grace_until = facts.end if facts.state == "IN_GRACE_PERIOD" else None
    row.last_verified_at, row.price_change = now, facts.price_change
    session.add(row)
    await session.flush()
    if facts.linked_token:  # upgrade, downgrade or re-subscribe: the old token is replaced
        old = await session.scalar(
            select(Subscription).where(
                Subscription.purchase_token_hash == token_hash(facts.linked_token),
                Subscription.subject_id == subject,
            )
        )
        if old is not None and old.id != row.id and old.state != "REVOKED":
            old.state = "EXPIRED"
    if not facts.acknowledged and facts.state in ("ACTIVE", "IN_GRACE_PERIOD"):
        await play.acknowledge(facts.product_id, token)
    session.add(
        BillingEvent(
            id=uuid.uuid4(),
            subscription_id=row.id,
            provider="google_play",
            event_type="play_verified",
            notification_id=None,
            payload={"state": facts.state, "product_id": facts.product_id},
        )
    )
    await session.flush()
    return row
