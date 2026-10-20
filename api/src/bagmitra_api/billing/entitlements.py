"""What a user may use, decided in one place (billing addendum §2.1-§2.2).

`compute_entitlements` is a pure function over subscription rows and plan configuration: no
database, no clock, no provider. Every route into premium (Play Billing, a web invoice, a manual
grant) ends up as a subscription row, so adding a provider never touches this rule.

Access is a half-open window [period_start, end): ACTIVE and CANCELED (paid until the period
ends) end at `period_end`; IN_GRACE_PERIOD at `grace_until`. PENDING, ON_HOLD, PAUSED, EXPIRED and
REVOKED never grant access, and an ACTIVE row past its end does not either, so a renewal the
server has not processed yet cannot keep premium on forever.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

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


def compute_entitlements(
    subscriptions: Sequence[SubscriptionFacts],
    plans: Mapping[str, PlanFacts],
    *,
    now: datetime,
    snapshot_ttl: timedelta = timedelta(hours=24),
) -> Entitlements:
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
    return Entitlements(
        plans=tuple(keys),
        features={name: Feature(True, _merge(limits)) for name, limits in per_feature.items()},
        valid_until=min([now + snapshot_ttl, *ends]),
        computed_at=now,
    )
