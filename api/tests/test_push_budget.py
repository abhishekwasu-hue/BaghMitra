"""Q157 shared push budget: at most PUSH_DAILY_MAX pushes per farmer per India day across the
push jobs, most important first, the same topic not again within PUSH_REPEAT_DAYS, and what is
held back is not sent later."""

from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.db.models import PlotRiskAlert
from bagmitra_api.push import budget as pb
from bagmitra_api.push.deliver import DeliverySummary, run_delivery
from bagmitra_api.push.models import PushLog
from bagmitra_api.risk.engine import load_rules
from tests.test_push_delivery import NOW, FakeSender, seed_plots
from tests.test_push_updates import NOW as UPDATES_NOW
from tests.test_push_updates import SETTINGS, article, forecast, grower, notices, price, run


@pytest.fixture
def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def log(maker: async_sessionmaker[AsyncSession]) -> list[tuple[str, str, str]]:
    async with maker() as s:
        rows = await s.scalars(select(PushLog).order_by(PushLog.created_at, PushLog.topic))
        return [(r.source, r.topic, r.status) for r in rows]


async def deliver(
    maker: async_sessionmaker[AsyncSession], sender: FakeSender, now: datetime
) -> DeliverySummary:
    async with maker() as s:
        return await run_delivery(s, sender, now)


async def add_alert(
    maker: async_sessionmaker[AsyncSession],
    owner: uuid.UUID,
    plot: uuid.UUID,
    rule_key: str,
    created: datetime,
    first_day: date = date(2026, 10, 28),
) -> None:
    async with maker() as s:
        s.add(
            PlotRiskAlert(
                owner_id=owner,
                plot_id=plot,
                rule_key=rule_key,
                first_day=first_day,
                value=36,
                created_at=created,
            )
        )
        await s.commit()


def test_every_rule_has_a_push_class_and_the_danger_rules_are_the_owner_list() -> None:
    classes = {r.key: r.push for r in load_rules()}
    assert {k for k, v in classes.items() if v == "danger"} == {
        "heavy_rain",
        "unseasonal_rain",
        "hail_thunderstorm",
        "heat_fruit_drop",
        "cold_wave",
        "high_wind_gust",
    }
    assert {k for k, v in classes.items() if v == "advisory"} == {
        "psylla_degree_days",
        "high_humidity",
    }


async def test_danger_goes_first_and_the_advisory_over_budget_is_not_sent_later(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed_plots(  # the advisory is the oldest alert
        maker,
        [
            ("बाग १", "psylla_degree_days"),
            ("बाग १", "heat_fruit_drop"),
            ("बाग १", "hail_thunderstorm"),
        ],
    )
    sender = FakeSender()
    summary = await deliver(maker, sender, NOW)
    assert [m.data["rule_key"] for m in sender.sent] == ["heat_fruit_drop", "hail_thunderstorm"]
    assert (summary.notified, summary.skipped_budget, summary.skipped_repeat) == (2, 1, 0)
    assert ("deliver", "risk:psylla_degree_days", "budget") in await log(maker)
    nextday = FakeSender()
    later = await deliver(maker, nextday, NOW + timedelta(days=1))
    assert nextday.sent == [], "held back: not kept for later (the app still shows it)"
    assert (later.alerts, later.skipped_budget) == (1, 0)


async def test_the_same_rule_is_not_pushed_again_within_the_repeat_window(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    plots = await seed_plots(maker, [("बाग १", "heat_fruit_drop")])
    plot = plots["बाग १"]
    async with maker() as s:
        owner = (await s.scalars(select(PlotRiskAlert.owner_id))).one()
    first = FakeSender()
    await deliver(maker, first, NOW)
    assert len(first.sent) == 1

    await add_alert(
        maker, owner, plot, "heat_fruit_drop", NOW + timedelta(days=1), date(2026, 10, 30)
    )
    second = FakeSender()
    summary = await deliver(maker, second, NOW + timedelta(days=1, minutes=5))
    assert second.sent == []
    assert summary.skipped_repeat == 1
    third = FakeSender()
    await deliver(maker, third, NOW + timedelta(days=2))
    assert third.sent == [], "the held alert is not planned again"

    await add_alert(
        maker, owner, plot, "heat_fruit_drop", NOW + timedelta(days=3, hours=1), date(2026, 11, 1)
    )
    fourth = FakeSender()
    await deliver(maker, fourth, NOW + timedelta(days=3, hours=2))
    assert len(fourth.sent) == 1, "after PUSH_REPEAT_DAYS it goes out again"


async def test_budget_is_shared_across_jobs_and_counts_pushes_not_phones(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    owner, (plot,) = await grower(maker, tokens=("tok-a", "tok-b"))
    morning = UPDATES_NOW - timedelta(minutes=70)  # 07:07 India time, the deliver run
    for rule in ("psylla_degree_days", "high_humidity"):
        await add_alert(maker, owner, plot, rule, morning - timedelta(hours=1))
    first = FakeSender()
    async with maker() as s:
        summary = await run_delivery(s, first, morning)
    assert (summary.notified, summary.messages) == (2, 4), "two pushes, each to two phones"

    await forecast(maker, {0: {"t_max_c": 30}, 1: {"t_max_c": 24}})  # a 6 °C drop
    updates = FakeSender()
    result = await run(maker, updates)
    assert result.weather_changes_found == 1
    assert updates.sent == []
    assert (result.skipped_budget, result.planned) == (1, {"weather": 1})
    assert ("updates", "weather:temp_down", "budget") in await log(maker)
    again = await run(maker, FakeSender(), UPDATES_NOW + timedelta(hours=6))
    assert again.planned == {}, "a weather change held back is not planned again"


async def test_updates_send_weather_and_market_before_articles(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, district="Amravati")
    await forecast(maker, {0: {"t_max_c": 30}, 1: {"t_max_c": 24}})
    await price(maker, "Warud", "Amravati", (1, 3200), (0, 3700))
    await article(maker, "लेख")
    sender = FakeSender()
    summary = await run(maker, sender)
    assert [m.data["kind"] for m in sender.sent] == ["weather_change", "market"]
    assert summary.skipped_budget == 1
    [held] = await notices(maker, "article")
    assert held.notified_at is None, "logged unsent so no run plans it again"
    nextday = FakeSender()
    await run(maker, nextday, UPDATES_NOW + timedelta(days=1))
    assert [m.data["kind"] for m in nextday.sent] == []


async def test_market_topic_repeat_and_a_larger_budget(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, district="Amravati")
    await price(maker, "Warud", "Amravati", (1, 3200), (0, 3700))
    first = FakeSender()
    await run(maker, first)
    assert len(first.sent) == 1
    await price(maker, "Morshi", "Amravati", (2, 3000), (-1, 3600))  # tomorrow's price moves
    second = FakeSender()
    summary = await run(maker, second, UPDATES_NOW + timedelta(days=1))
    assert second.sent == []
    assert summary.skipped_repeat == 1, "santra prices again within 3 days"
    roomy = FakeSender()
    await article(maker, "लेख", published=UPDATES_NOW + timedelta(days=1))
    await run(maker, roomy, UPDATES_NOW + timedelta(days=1, hours=1), push_daily_max=5)
    assert [m.data["kind"] for m in roomy.sent] == ["article"]
    assert SETTINGS.push_daily_max == 2


async def test_budget_counts_distinct_pushes_of_today_and_the_article_class(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    owner = uuid.uuid4()
    today = pb.india_day(NOW)
    async with maker() as s:
        one, two = uuid.uuid4(), uuid.uuid4()
        s.add_all(
            [
                PushLog(
                    owner_id=owner,
                    push_id=one,
                    day=today,
                    source="updates",
                    priority=pb.ARTICLES,
                    topic="article:a",
                    status=pb.SENT,
                    created_at=NOW,
                ),
                PushLog(
                    owner_id=owner,
                    push_id=one,
                    day=today,
                    source="updates",
                    priority=pb.ARTICLES,
                    topic="article:b",
                    status=pb.SENT,
                    created_at=NOW,
                ),
                PushLog(
                    owner_id=owner,
                    push_id=two,
                    day=today - timedelta(days=1),
                    source="deliver",
                    priority=pb.DANGER,
                    topic="risk:x",
                    status=pb.SENT,
                    created_at=NOW - timedelta(days=1),
                ),
            ]
        )
        await s.commit()
        budget = await pb.Budget.load(s, pb.BudgetRules(), NOW, [owner])
    assert budget.sent[owner] == 1, "one combined push today; yesterday's does not count"
    assert not budget.room(owner, pb.ARTICLES), "one article push a day"
    assert budget.room(owner, pb.DANGER)
    assert budget.repeated(owner, "risk:x")
