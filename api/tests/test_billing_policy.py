"""The admin subscription switch and per-role plans (billing addendum §7), table-driven over the
pure `compute_entitlements`: OFF or before the start date = the full app; ON = only gated
features lock, and the gate map is empty until the owner decides (OPEN_QUESTIONS Q118)."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest

from bagmitra_api.billing.entitlements import (
    GATED_FEATURES,
    BillingPolicy,
    PlanFacts,
    SubscriptionFacts,
    compute_entitlements,
)

NOW = datetime(2026, 11, 20, 12, 0, tzinfo=UTC)
DAY = timedelta(days=1)
PLANS = {
    p.key: p
    for p in (
        PlanFacts("free", {"records": None, "photos": 20}),
        PlanFacts("grower_pro", {"records": None, "calendar": None, "ai": 300}),
        PlanFacts("role_grower", {}),
        PlanFacts("role_trader", {}),
        PlanFacts("role_broker", {}),
    )
}
PRICES = {"grower": 9900, "trader": 29900, "broker": 19900}
GATE = {
    "grower": frozenset({"calendar"}),
    "trader": frozenset({"ai"}),
    "broker": frozenset({"ai"}),
}


def role_sub(role: str, state: str = "ACTIVE") -> SubscriptionFacts:
    return SubscriptionFacts(f"role_{role}", state, NOW - DAY, NOW + 29 * DAY)  # type: ignore[arg-type]


def test_the_gate_map_is_empty_until_the_owner_decides() -> None:
    assert dict(GATED_FEATURES) == {}
    assert BillingPolicy().gated == {}


@pytest.mark.parametrize(
    "policy",
    [
        BillingPolicy(),  # default: switch OFF
        BillingPolicy(enabled=False, prices=PRICES, gated=GATE),
        BillingPolicy(enabled=True, starts_on=date(2026, 12, 1), prices=PRICES, gated=GATE),
        BillingPolicy(enabled=True, prices={}, gated=GATE),  # no amount = free
        BillingPolicy(enabled=True, prices=PRICES),  # ON, but nothing is gated (today)
    ],
)
def test_off_before_start_unpriced_or_ungated_gives_the_full_app(policy: BillingPolicy) -> None:
    ent = compute_entitlements(
        [], PLANS, now=NOW, policy=policy, roles=("grower", "trader", "broker")
    )
    assert {k: (f.enabled, f.limit) for k, f in ent.features.items()} == {
        "records": (True, None),
        "photos": (True, None),  # the free plan's limit does not apply while nothing is charged
        "calendar": (True, None),
        "ai": (True, None),
    }


@pytest.mark.parametrize(
    ("roles", "plans", "locked"),
    [
        (("grower",), [], {"calendar"}),
        (("grower",), ["grower"], set()),
        (("trader",), [], {"ai"}),
        (("grower", "trader"), [], {"calendar", "ai"}),
        # one plan for a multi-role user: the higher-priced role covers the cheaper one
        (("grower", "trader"), ["trader"], set()),
        (("grower", "trader"), ["grower"], {"ai"}),
        (("grower", "broker", "trader"), ["broker"], {"ai"}),
        (("grower", "broker"), ["broker"], set()),
        # a role without an amount is free even when ON
        (("exporter",), [], set()),
        (("provider", "grower"), ["grower"], set()),
    ],
)
def test_on_locks_only_gated_features_of_uncovered_priced_roles(
    roles: tuple[str, ...], plans: list[str], locked: set[str]
) -> None:
    policy = BillingPolicy(enabled=True, prices=PRICES, gated=GATE)
    subs = [role_sub(r) for r in plans]
    ent = compute_entitlements(subs, PLANS, now=NOW, policy=policy, roles=roles)
    assert {k for k, f in ent.features.items() if not f.enabled} == locked
    assert all(ent.limit(k) == 0 for k in locked)
    assert ent.has("records")  # own records are never gated


@pytest.mark.parametrize(
    ("state", "covered"),
    [
        ("ACTIVE", True),
        ("CANCELED", True),
        ("IN_GRACE_PERIOD", True),
        ("ON_HOLD", False),
        ("EXPIRED", False),
        ("REVOKED", False),
        ("PENDING", False),
    ],
)
def test_a_role_plan_covers_only_while_it_grants_access(state: str, covered: bool) -> None:
    policy = BillingPolicy(enabled=True, prices=PRICES, gated=GATE)
    sub = role_sub("grower", state)
    if state == "IN_GRACE_PERIOD":
        sub = SubscriptionFacts("role_grower", "IN_GRACE_PERIOD", NOW - DAY, NOW, NOW + DAY)
    ent = compute_entitlements([sub], PLANS, now=NOW, policy=policy, roles=("grower",))
    assert ent.has("calendar") is covered


def test_the_start_date_is_the_start_of_that_day_in_india() -> None:
    policy = BillingPolicy(enabled=True, starts_on=date(2026, 12, 1), prices=PRICES, gated=GATE)
    start = datetime(2026, 11, 30, 18, 30, tzinfo=UTC)  # 00:00 IST
    before = compute_entitlements(
        [], PLANS, now=start - timedelta(seconds=1), policy=policy, roles=("grower",)
    )
    at = compute_entitlements([], PLANS, now=start, policy=policy, roles=("grower",))
    assert before.has("calendar")
    assert before.valid_until == start  # the cached snapshot is refreshed when the switch starts
    assert not at.has("calendar")


def test_the_offer_is_the_highest_priced_role() -> None:
    policy = BillingPolicy(enabled=True, prices=PRICES)
    assert policy.offer_role(("grower", "broker")) == "broker"
    assert policy.offer_role(("grower", "trader", "broker")) == "trader"
    assert policy.offer_role(("exporter",)) is None
    assert policy.offer_role(()) is None


def test_without_a_policy_the_plan_arithmetic_is_unchanged() -> None:
    ent = compute_entitlements([], PLANS, now=NOW)
    assert not ent.has("calendar")
    assert ent.limit("photos") == 20
