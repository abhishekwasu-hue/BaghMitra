"""What a user may use, decided in one place (billing addendum §2.1-§2.2).

`compute_entitlements` is a pure function over subscription rows and plan configuration: no
database, no clock, no provider. Every route into premium (Play Billing, a web invoice, a manual
grant) ends up as a subscription row, so adding a provider never touches this rule.

Access is a half-open window [period_start, end): ACTIVE and CANCELED (paid until the period
ends) end at `period_end`; IN_GRACE_PERIOD at `grace_until`. PENDING, ON_HOLD, PAUSED, EXPIRED and
REVOKED never grant access, and an ACTIVE row past its end does not either, so a renewal the
server has not processed yet cannot keep premium on forever.

The subscription switch (addendum §7) is a `BillingPolicy`: while it is OFF (or before its start
date) every signed-in user gets the full app, every feature without a limit. While it is ON, a
feature locks only if the gate map lists it for one of the user's priced roles and no role plan
covers that role. The gate map is empty until the owner says which features need a plan
(OPEN_QUESTIONS Q117), so nothing locks today. A user's own records are never gated.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, time, timedelta
from typing import Any, Literal
from zoneinfo import ZoneInfo

SubscriptionState = Literal[
    "PENDING",
    "ACTIVE",
    "IN_GRACE_PERIOD",
    "ON_HOLD",
    "PAUSED",
    "CANCELED",
    "EXPIRED",
    "REVOKED",
]
BASELINE_PLAN = "free"
# One monthly plan per role (addendum §7); the plan key of a role is ROLE_PLAN_PREFIX + role.
BILLING_ROLES = ("grower", "trader", "broker", "exporter", "provider")
ROLE_PLAN_PREFIX = "role_"
INDIA = ZoneInfo("Asia/Kolkata")
# Role -> features that need that role's plan while the switch is ON. Empty on purpose: the
# owner decides what a plan unlocks (OPEN_QUESTIONS Q117, default "nothing locked").
GATED_FEATURES: Mapping[str, frozenset[str]] = {}


@dataclass(frozen=True, slots=True)
class BillingPolicy:
    """The admin's switch, its optional start date (India) and the monthly amount per role in
    paise (a role without an amount stays free)."""

    enabled: bool = False
    starts_on: date | None = None
    prices: Mapping[str, int] = field(default_factory=dict)
    gated: Mapping[str, frozenset[str]] = field(default_factory=lambda: GATED_FEATURES)

    def starts_at(self) -> datetime | None:
        if self.starts_on is None:
            return None
        return datetime.combine(self.starts_on, time(), INDIA).astimezone(UTC)

    def in_force(self, now: datetime) -> bool:
        start = self.starts_at()
        return self.enabled and (start is None or now >= start)

    def priced_roles(self, roles: Sequence[str]) -> list[str]:
        return [r for r in BILLING_ROLES if r in roles and self.prices.get(r)]

    def offer_role(self, roles: Sequence[str]) -> str | None:
        """The plan a user buys: the highest-priced of the user's roles (it covers them all)."""
        priced = self.priced_roles(roles)
        return max(priced, key=lambda r: self.prices[r]) if priced else None

    def covered_roles(self, roles: Sequence[str], plan_roles: Sequence[str]) -> set[str]:
        """A plan of role X covers every role of the user priced at most X's amount."""
        paid = [self.prices.get(r, 0) for r in plan_roles if self.prices.get(r)]
        best = max(paid, default=0)
        return {r for r in self.priced_roles(roles) if self.prices[r] <= best}

    def locked(self, roles: Sequence[str], plan_roles: Sequence[str], now: datetime) -> set[str]:
        if not self.in_force(now):
            return set()
        covered = self.covered_roles(roles, plan_roles)
        locked: set[str] = set()
        for role in self.priced_roles(roles):
            if role not in covered:
                locked |= set(self.gated.get(role, frozenset()))
        return locked


@dataclass(frozen=True, slots=True)
class PlanFacts:
    key: str
    # feature -> limit; None means included without a limit. Absent means not included.
    features: Mapping[str, int | None]


@dataclass(frozen=True, slots=True)
class SubscriptionFacts:
    plan_key: str
    state: SubscriptionState
    period_start: datetime
    period_end: datetime
    grace_until: datetime | None = None


@dataclass(frozen=True, slots=True)
class Feature:
    enabled: bool
    limit: int | None


@dataclass(frozen=True, slots=True)
class Entitlements:
    plans: tuple[str, ...]
    features: Mapping[str, Feature]
    valid_until: datetime
    computed_at: datetime

    def has(self, feature: str) -> bool:
        found = self.features.get(feature)
        return found is not None and found.enabled

    def limit(self, feature: str) -> int | None:
        """None: included without a limit. 0: not included."""
        found = self.features.get(feature)
        if found is None or not found.enabled:
            return 0
        return found.limit

    def to_dict(self) -> dict[str, Any]:
        def stamp(value: datetime) -> str:
            return value.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")

        return {
            "plans": list(self.plans),
            "features": {
                key: {"enabled": f.enabled, "limit": f.limit}
                for key, f in sorted(self.features.items())
            },
            "valid_until": stamp(self.valid_until),
            "computed_at": stamp(self.computed_at),
        }


def access_end(subscription: SubscriptionFacts, now: datetime) -> datetime | None:
    """When the access this subscription grants right now ends; None if it grants none."""
    if now < subscription.period_start:
        return None
    if subscription.state in ("ACTIVE", "CANCELED"):
        end = subscription.period_end
    elif subscription.state == "IN_GRACE_PERIOD":
        end = subscription.grace_until or subscription.period_end
    else:
        return None
    return end if now < end else None


def _merge(limits: Sequence[int | None]) -> int | None:
    """Unlimited beats any limit; otherwise the most generous limit."""
    if any(limit is None for limit in limits):
        return None
    return max(limit for limit in limits if limit is not None)


def compute_entitlements(  # noqa: PLR0913 - rows, plans, clock and the §7 policy
    subscriptions: Sequence[SubscriptionFacts],
    plans: Mapping[str, PlanFacts],
    *,
    now: datetime,
    snapshot_ttl: timedelta = timedelta(hours=24),
    policy: BillingPolicy | None = None,
    roles: Sequence[str] = (),
) -> Entitlements:
    """Without a policy: the plan arithmetic alone (M6a). With one: the switch decides (§7)."""
    ends: list[datetime] = []
    keys: list[str] = [BASELINE_PLAN]
    for subscription in subscriptions:
        end = access_end(subscription, now)
        if end is None or subscription.plan_key not in plans:
            continue
        ends.append(end)
        if subscription.plan_key not in keys:
            keys.append(subscription.plan_key)
    per_feature: dict[str, list[int | None]] = {}
    for key in keys:
        for feature, limit in plans[key].features.items():
            per_feature.setdefault(feature, []).append(limit)
    features = {name: Feature(True, _merge(limits)) for name, limits in per_feature.items()}
    if policy is not None:
        features = _apply_policy(policy, plans, keys, roles, now)
        start = policy.starts_at()
        if policy.enabled and start is not None and now < start:
            ends.append(start)  # the switch takes effect: download a fresh snapshot then
    return Entitlements(
        plans=tuple(keys),
        features=features,
        valid_until=min([now + snapshot_ttl, *ends]),
        computed_at=now,
    )


def _apply_policy(
    policy: BillingPolicy,
    plans: Mapping[str, PlanFacts],
    keys: Sequence[str],
    roles: Sequence[str],
    now: datetime,
) -> dict[str, Feature]:
    """The full app (every feature, no limit) minus the gated features no plan covers."""
    plan_roles = [k.removeprefix(ROLE_PLAN_PREFIX) for k in keys if k.startswith(ROLE_PLAN_PREFIX)]
    locked = policy.locked(roles, plan_roles, now)
    names = {f for plan in plans.values() for f in plan.features} | locked
    return {name: Feature(name not in locked, 0 if name in locked else None) for name in names}
