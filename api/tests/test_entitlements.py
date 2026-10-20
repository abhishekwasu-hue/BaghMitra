"""compute_entitlements is the only place that decides what a user may use (billing addendum
§2.1-§2.2). Pure and table-driven: every subscription state, the time edges and the merge rules."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from bagmitra_api.billing.entitlements import (
    Feature,
    PlanFacts,
    SubscriptionFacts,
    access_end,
    compute_entitlements,
)

NOW = datetime(2026, 10, 20, 12, 0, tzinfo=UTC)
DAY = timedelta(days=1)

FREE = PlanFacts("free", {"records": None, "accounts": None, "photos": 20})
PRO = PlanFacts("grower_pro", {"records": None, "calendar": None, "ai": 100, "photos": None})
CONSULTANT = PlanFacts("consultant", {"roster": 100, "ai": 500})
PLANS = {p.key: p for p in (FREE, PRO, CONSULTANT)}


def sub(
    state: str,
    *,
    plan: str = "grower_pro",
    start: datetime = NOW - 10 * DAY,
    end: datetime = NOW + 20 * DAY,
    grace: datetime | None = None,
) -> SubscriptionFacts:
    return SubscriptionFacts(plan, state, start, end, grace)  # type: ignore[arg-type]


@pytest.mark.parametrize(
    ("state", "grants_access"),
    [
        ("ACTIVE", True),
        ("CANCELED", True),  # cancelled but paid until the period ends
        ("IN_GRACE_PERIOD", True),  # payment failed, access kept for the grace period
        ("PENDING", False),
        ("ON_HOLD", False),  # suspended: features lock, data stays
        ("PAUSED", False),
        ("EXPIRED", False),
        ("REVOKED", False),  # refunded or voided: immediate loss
    ],
)
def test_each_state_decides_access(state: str, grants_access: bool) -> None:
    grace = NOW + 3 * DAY if state == "IN_GRACE_PERIOD" else None
    ent = compute_entitlements([sub(state, grace=grace)], PLANS, now=NOW)
    assert ent.has("calendar") is grants_access
    assert ent.has("records")  # the free baseline is always there


def test_a_user_with_no_subscription_gets_the_free_plan() -> None:
    ent = compute_entitlements([], PLANS, now=NOW)
    assert ent.plans == ("free",)
    assert ent.features == {
        "records": Feature(True, None),
        "accounts": Feature(True, None),
        "photos": Feature(True, 20),
    }
    assert not ent.has("ai")
    assert ent.limit("photos") == 20
    assert ent.limit("records") is None  # included and unlimited
    assert ent.limit("ai") == 0  # not included at all


def test_the_time_edges_are_half_open() -> None:
    assert access_end(sub("ACTIVE", end=NOW), NOW) is None  # ends exactly now: no access
    assert access_end(sub("ACTIVE", end=NOW + timedelta(seconds=1)), NOW) is not None
    assert access_end(sub("ACTIVE", start=NOW), NOW) is not None  # starts exactly now
    assert access_end(sub("ACTIVE", start=NOW + timedelta(seconds=1)), NOW) is None


def test_an_active_row_past_its_period_end_does_not_grant_access() -> None:
    """A renewal the server has not processed yet must not keep premium on forever."""
    late = sub("ACTIVE", end=NOW - timedelta(hours=1))
    assert not compute_entitlements([late], PLANS, now=NOW).has("calendar")


def test_grace_extends_access_only_until_the_grace_date() -> None:
    in_grace = sub("IN_GRACE_PERIOD", end=NOW - DAY, grace=NOW + 2 * DAY)
    assert compute_entitlements([in_grace], PLANS, now=NOW).has("calendar")
    over = sub("IN_GRACE_PERIOD", end=NOW - 3 * DAY, grace=NOW - DAY)
    assert not compute_entitlements([over], PLANS, now=NOW).has("calendar")
    assert access_end(sub("IN_GRACE_PERIOD", grace=None), NOW) == NOW + 20 * DAY


def test_features_merge_across_subscriptions() -> None:
    subs = [sub("ACTIVE", plan="grower_pro"), sub("ACTIVE", plan="consultant")]
    ent = compute_entitlements(subs, PLANS, now=NOW)
    assert ent.plans == ("free", "grower_pro", "consultant")
    assert ent.limit("roster") == 100
    assert ent.limit("ai") == 500  # the larger limit wins
    assert ent.limit("photos") is None  # unlimited beats a limit of 20
    assert ent.limit("calendar") is None


def test_a_lapsed_subscription_does_not_add_features() -> None:
    subs = [sub("EXPIRED", plan="consultant"), sub("ACTIVE", plan="grower_pro")]
    ent = compute_entitlements(subs, PLANS, now=NOW)
    assert ent.plans == ("free", "grower_pro")
    assert not ent.has("roster")


def test_an_unknown_plan_is_ignored_not_fatal() -> None:
    ent = compute_entitlements([sub("ACTIVE", plan="retired_plan")], PLANS, now=NOW)
    assert ent.plans == ("free",)


def test_validity_ends_when_the_earliest_access_ends() -> None:
    soon = sub("ACTIVE", end=NOW + 2 * timedelta(hours=1))
    later = sub("ACTIVE", plan="consultant", end=NOW + 30 * DAY)
    ent = compute_entitlements([later, soon], PLANS, now=NOW, snapshot_ttl=DAY)
    assert ent.valid_until == NOW + timedelta(hours=2)


def test_validity_is_capped_by_the_snapshot_lifetime() -> None:
    ent = compute_entitlements([sub("ACTIVE")], PLANS, now=NOW, snapshot_ttl=timedelta(hours=6))
    assert ent.valid_until == NOW + timedelta(hours=6)
    free_only = compute_entitlements([], PLANS, now=NOW, snapshot_ttl=timedelta(hours=6))
    assert free_only.valid_until == NOW + timedelta(hours=6)


def test_the_baseline_plan_must_exist() -> None:
    with pytest.raises(KeyError):
        compute_entitlements([], {"grower_pro": PRO}, now=NOW)


def test_the_snapshot_serialises_for_the_app() -> None:
    data = compute_entitlements([sub("ACTIVE")], PLANS, now=NOW).to_dict()
    assert data["plans"] == ["free", "grower_pro"]
    assert data["features"]["ai"] == {"enabled": True, "limit": 100}
    assert data["features"]["records"] == {"enabled": True, "limit": None}
    assert data["valid_until"].endswith("Z")
    assert data["computed_at"] == "2026-10-20T12:00:00Z"
