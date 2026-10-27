"""Feed G2 alert planner (addendum v1.4 §7 alert tests), table-driven on plain data:
dedupe, quiet hours, weekly cap, T-7/T-2/T-0, withdrawn / expired cancels, opt-out,
language fallback, digest contents."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, time, timedelta
from typing import Any

import pytest

from bagmitra_api.feed.alerts import (
    DIGEST_MAX_TITLES,
    INDIA,
    Item,
    Prefs,
    Receipt,
    Recipient,
    alert_text,
    in_quiet,
    is_live,
    language,
    plan_alerts,
    plan_digest,
    send_time,
    stages_due,
)
from bagmitra_api.feed.matching import Profile, Target

# 10:00 IST on 27 Oct 2026: outside the default quiet hours.
NOW = datetime(2026, 10, 27, 10, 0, tzinfo=INDIA).astimezone(UTC)
TODAY = date(2026, 10, 27)
ME = uuid.uuid4()
NAGPUR = Profile(district="Nagpur", crops=frozenset({"santra"}), land_ha=2.0)
FOOTER_EN = "Check the official GR/portal before acting."


def item(
    *,
    days: int | None = 2,
    kind: str = "apply_by",
    status: str = "published",
    type_: str = "scheme",
    targets: tuple[Target, ...] = (),
    titles: dict[str, str] | None = None,
    valid_to: date | None = None,
    published: datetime = NOW - timedelta(days=1),
    extra: dict[str, date] | None = None,
) -> Item:
    dates = {} if days is None else {kind: TODAY + timedelta(days=days)}
    return Item(
        id=uuid.uuid4(),
        type=type_,
        status=status,
        published_at=published,
        titles=titles or {"en": "Fruit planting subsidy", "mr": "फळबाग लागवड अनुदान"},
        targets=targets,
        dates=dates | (extra or {}),
        valid_to=valid_to,
    )


def me(lang: str = "en", **prefs: Any) -> Recipient:
    return Recipient(ME, lang, NAGPUR, Prefs(**prefs))


@pytest.mark.parametrize(
    ("code", "lang"),
    [("mr", "mr"), ("hi-IN", "hi"), ("EN", "en"), ("ta", "en"), (None, "en"), ("", "en")],
)
def test_language_falls_back_to_english(code: str | None, lang: str) -> None:
    assert language(code) == lang


@pytest.mark.parametrize(
    ("local", "start", "end", "quiet"),
    [
        (time(20, 59), time(21), time(7), False),
        (time(21, 0), time(21), time(7), True),  # start inclusive
        (time(23, 30), time(21), time(7), True),
        (time(0, 0), time(21), time(7), True),
        (time(6, 59), time(21), time(7), True),
        (time(7, 0), time(21), time(7), False),  # end exclusive
        (time(13, 0), time(13), time(15), True),  # window inside one day
        (time(15, 0), time(13), time(15), False),
        (time(12, 59), time(13), time(15), False),
        (time(3, 0), time(5), time(5), False),  # start == end: no quiet hours
    ],
)
def test_quiet_hours_boundaries(local: time, start: time, end: time, quiet: bool) -> None:
    assert in_quiet(local, start, end) is quiet


@pytest.mark.parametrize(
    ("local_now", "expected_local"),
    [
        (datetime(2026, 10, 27, 10, 0), datetime(2026, 10, 27, 10, 0)),
        (datetime(2026, 10, 27, 20, 59), datetime(2026, 10, 27, 20, 59)),
        (datetime(2026, 10, 27, 21, 0), datetime(2026, 10, 28, 7, 0)),
        (datetime(2026, 10, 27, 23, 45), datetime(2026, 10, 28, 7, 0)),
        (datetime(2026, 10, 28, 3, 0), datetime(2026, 10, 28, 7, 0)),
        (datetime(2026, 10, 28, 7, 0), datetime(2026, 10, 28, 7, 0)),
    ],
)
def test_push_in_quiet_hours_waits_for_their_end(
    local_now: datetime, expected_local: datetime
) -> None:
    now = local_now.replace(tzinfo=INDIA).astimezone(UTC)
    assert send_time(now, Prefs()) == expected_local.replace(tzinfo=INDIA).astimezone(UTC)


@pytest.mark.parametrize(
    ("days", "kind", "stage"),
    [
        (9, "apply_by", None),
        (8, "apply_by", None),
        (7, "apply_by", "t7"),
        (3, "apply_by", "t7"),
        (2, "apply_by", "t2"),
        (1, "window_close", "t2"),
        (0, "apply_by", "t0"),
        (-1, "apply_by", None),
        (1, "payment", None),
        (0, "payment", "payment"),
        (-2, "payment", "payment"),
        (-3, "payment", None),
        (0, "window_open", "window_open"),
        (-1, "window_open", "window_open"),
    ],
)
def test_stage_of_each_date(days: int, kind: str, stage: str | None) -> None:
    found = stages_due(item(days=days, kind=kind), TODAY)
    assert [s for s, _, _ in found] == ([stage] if stage else [])


def test_nearest_reminder_wins_and_events_add_their_own_push() -> None:
    both = item(
        days=5,
        kind="window_close",
        extra={"apply_by": TODAY + timedelta(days=2), "window_open": TODAY},
    )
    assert stages_due(both, TODAY) == [
        ("t2", "apply_by", TODAY + timedelta(days=2)),
        ("window_open", "window_open", TODAY),
    ]


@pytest.mark.parametrize(
    ("case", "it", "receipt", "prefs", "sent", "stages", "skipped"),
    [
        ("t2 due", item(days=2), Receipt(), {}, 0, ["t2"], {}),
        ("dedupe", item(days=2), Receipt(notified={"t2": NOW}), {}, 0, [], {"duplicate": 1}),
        ("later stage after t7", item(days=1), Receipt(notified={"t7": NOW}), {}, 0, ["t2"], {}),
        (
            "withdrawn cancels",
            item(days=0, status="withdrawn"),
            Receipt(),
            {},
            0,
            [],
            {"cancelled": 1},
        ),
        (
            "validity ended cancels",
            item(days=3, valid_to=TODAY - timedelta(days=1)),
            Receipt(),
            {},
            0,
            [],
            {"cancelled": 1},
        ),
        ("dismissed", item(days=0), Receipt(dismissed=True), {}, 0, [], {"dismissed": 1}),
        (
            "deadline opt-out",
            item(days=7),
            Receipt(),
            {"opted_out": frozenset({"deadline"})},
            0,
            [],
            {"opted_out": 1},
        ),
        (
            "payment opt-out keeps deadlines",
            item(days=7),
            Receipt(),
            {"opted_out": frozenset({"payment"})},
            0,
            ["t7"],
            {},
        ),
        ("cap reached", item(days=0), Receipt(), {}, 3, [], {"weekly_cap": 1}),
        ("cap 0", item(days=0), Receipt(), {"weekly_cap": 0}, 0, [], {"weekly_cap": 1}),
        (
            "not for my district",
            item(days=0, targets=(Target(district="Pune"),)),
            Receipt(),
            {},
            0,
            [],
            {},
        ),
        (
            "remind me overrides targets",
            item(days=0, targets=(Target(district="Pune"),)),
            Receipt(remind=True),
            {},
            0,
            ["t0"],
            {},
        ),
        (
            "for my crop",
            item(days=0, targets=(Target(crop="Santra"),)),
            Receipt(),
            {},
            0,
            ["t0"],
            {},
        ),
        (
            "payment today",
            item(days=0, kind="payment", type_="gr"),
            Receipt(),
            {},
            0,
            ["payment"],
            {},
        ),
        ("no date", item(days=None), Receipt(), {}, 0, [], {}),
    ],
)
def test_plan_alerts(
    case: str,
    it: Item,
    receipt: Receipt,
    prefs: dict[str, Any],
    sent: int,
    stages: list[str],
    skipped: dict[str, int],
) -> None:
    plan = plan_alerts(me(**prefs), [it], {it.id: receipt}, NOW, sent_last_week=sent)
    assert [p.stage for p in plan.pushes] == stages, case
    assert dict(plan.skipped) == skipped, case


def test_weekly_cap_is_hard_and_most_urgent_go_first() -> None:
    t0, t2, t7 = item(days=0), item(days=2), item(days=6)
    plan = plan_alerts(me(), [t7, t2, t0], {}, NOW, sent_last_week=1)
    assert [(p.item_id, p.stage) for p in plan.pushes] == [(t0.id, "t0"), (t2.id, "t2")]
    assert plan.skipped["weekly_cap"] == 1
    # QG4 default: even a T-0 reminder does not exceed the cap.
    assert plan_alerts(me(), [t0], {}, NOW, sent_last_week=3).pushes == []


def test_quiet_hours_hold_the_push_until_morning() -> None:
    night = datetime(2026, 10, 27, 22, 30, tzinfo=INDIA).astimezone(UTC)
    plan = plan_alerts(me(), [item(days=0)], {}, night, sent_last_week=0)
    assert plan.pushes[0].send_at == datetime(2026, 10, 28, 7, 0, tzinfo=INDIA).astimezone(UTC)
    custom = me(quiet_start=time(22, 0), quiet_end=time(23, 0))
    plan = plan_alerts(custom, [item(days=0)], {}, night, sent_last_week=0)
    assert plan.pushes[0].send_at == datetime(2026, 10, 27, 23, 0, tzinfo=INDIA).astimezone(UTC)


@pytest.mark.parametrize(
    ("lang", "kind", "title", "line", "footer"),
    [
        ("en", "apply_by", "Fruit planting subsidy", "Last date: 29/10/2026", FOOTER_EN),
        ("mr", "apply_by", "फळबाग लागवड अनुदान", "शेवटची तारीख: 29/10/2026", "अधिकृत शासन निर्णय"),
        ("hi", "window_close", "Fruit planting subsidy", "अंतिम तिथि: 29/10/2026", "आधिकारिक GR"),
        ("en", "payment", "Fruit planting subsidy", "Payment release date: 29/10/2026", FOOTER_EN),
        ("mr", "window_open", "फळबाग लागवड अनुदान", "अर्ज सुरू होण्याची तारीख: 29/10/2026", "पोर्टल"),
    ],
)
def test_message_text_in_the_farmer_language(
    lang: str, kind: str, title: str, line: str, footer: str
) -> None:
    got_title, body = alert_text(item(), kind, TODAY + timedelta(days=2), lang)
    assert got_title == title, "hi has no text: English title"
    first, last = body.split("\n")
    assert first == line
    assert footer in last
    assert "will receive" not in body.lower()


def test_title_falls_back_when_the_language_is_missing() -> None:
    only_mr = item(titles={"mr": "फळबाग"})
    assert alert_text(only_mr, "apply_by", TODAY, "en")[0] == "फळबाग"


def test_push_payload_names_item_and_stage() -> None:
    it = item(days=7)
    push = plan_alerts(me("mr"), [it], {}, NOW, sent_last_week=0).pushes[0]
    assert push.data == {"kind": "feed_alert", "item_id": str(it.id), "stage": "t7"}
    assert push.body.startswith("शेवटची तारीख: 03/11/2026")
    assert push.owner_id == ME


def test_expired_scheme_is_not_live_but_other_items_keep_their_events() -> None:
    late = item(days=-1, extra={"payment": TODAY})
    assert not is_live(late, TODAY)
    gr = item(days=-1, type_="gr", extra={"payment": TODAY})
    assert is_live(gr, TODAY)
    assert [p.stage for p in plan_alerts(me(), [gr], {}, NOW, sent_last_week=0).pushes] == [
        "payment"
    ]


def test_digest_lists_new_items_for_me_newest_first() -> None:
    old = item(days=None, published=NOW - timedelta(days=8), titles={"en": "Old"})
    newer = item(days=None, published=NOW - timedelta(hours=2), titles={"en": "Newer"})
    older = item(days=None, published=NOW - timedelta(days=6), titles={"en": "Older"})
    pune = item(days=None, targets=(Target(district="Pune"),), titles={"en": "Pune only"})
    gone = item(days=None, status="withdrawn", titles={"en": "Withdrawn"})
    hidden = item(days=None, titles={"en": "Dismissed"})
    receipts = {hidden.id: Receipt(dismissed=True)}
    push = plan_digest(me(), [old, older, newer, pune, gone, hidden], receipts, NOW)
    assert push is not None
    assert push.stage == "digest"
    assert push.item_id is None
    assert push.title == "Sarkari Sandesh: 2 new this week"
    assert push.body.split("\n") == ["• Newer", "• Older", FOOTER_EN]
    assert push.data == {"kind": "feed_digest", "items": f"{newer.id},{older.id}"}


def test_digest_caps_titles_and_speaks_marathi() -> None:
    many = [
        item(days=None, published=NOW - timedelta(hours=h), titles={"mr": f"बातमी {h}"})
        for h in range(1, DIGEST_MAX_TITLES + 3)
    ]
    push = plan_digest(me("mr"), many, {}, NOW)
    assert push is not None
    lines = push.body.split("\n")
    assert lines[0] == "• बातमी 1"
    assert lines[DIGEST_MAX_TITLES] == "…आणखी 2"
    assert "अधिकृत" in lines[-1]
    assert push.title == f"सरकारी संदेश: या आठवड्यात {DIGEST_MAX_TITLES + 2} नवीन"


@pytest.mark.parametrize(
    ("prefs", "items_", "sent"),
    [
        ({"digest_weekly": False}, [item(days=None)], False),
        ({"last_digest_at": NOW - timedelta(days=3)}, [item(days=None)], False),
        ({"last_digest_at": NOW - timedelta(days=7)}, [item(days=None)], True),
        ({}, [], False),
    ],
)
def test_digest_switch_interval_and_empty(
    prefs: dict[str, Any], items_: list[Item], sent: bool
) -> None:
    assert (plan_digest(me(**prefs), items_, {}, NOW) is not None) is sent
