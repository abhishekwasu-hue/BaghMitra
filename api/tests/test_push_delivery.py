from __future__ import annotations

import json
import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.db.models import Farmer, Plot, PlotRiskAlert, PushDevice
from bagmitra_api.push.deliver import run_delivery
from bagmitra_api.push.sender import PushMessage, PushUnavailableError, SendResult

NOW = datetime(2026, 10, 27, 1, 0, tzinfo=UTC)


class FakeSender:
    def __init__(self, *, invalid: set[str] | None = None, down: set[str] | None = None) -> None:
        self.sent: list[PushMessage] = []
        self.invalid = invalid or set()
        self.down = down or set()

    async def send(self, message: PushMessage) -> SendResult:
        if message.token in self.down:
            raise PushUnavailableError("HTTP 503")
        if message.token in self.invalid:
            return SendResult.UNREGISTERED
        self.sent.append(message)
        return SendResult.SENT


@pytest.fixture
def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def seed(
    maker: async_sessionmaker[AsyncSession],
    *,
    language: str = "mr",
    tokens: tuple[str, ...] = ("tok-a",),
    created: datetime = NOW,
    notified: datetime | None = None,
    rule_key: str = "heat_fruit_drop",
) -> PlotRiskAlert:
    owner = uuid.uuid4()
    alert = PlotRiskAlert(
        owner_id=owner,
        plot_id=uuid.uuid4(),
        rule_key=rule_key,
        first_day=date(2026, 10, 28),
        value=36,
        units=None,
        created_at=created,
        notified_at=notified,
    )
    async with maker() as s:
        s.add(Farmer(id=owner, language=language, client_updated_at=NOW, last_seq=1))
        s.add_all(PushDevice(owner_id=owner, token=t, platform="android") for t in tokens)
        s.add(alert)
        await s.commit()
    return alert


async def stored(maker: async_sessionmaker[AsyncSession]) -> list[PlotRiskAlert]:
    async with maker() as s:
        return list((await s.scalars(select(PlotRiskAlert))).all())


async def test_new_alert_goes_to_every_device_in_the_farmer_language_and_is_stamped(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    alert = await seed(maker, tokens=("tok-a", "tok-b"))
    sender = FakeSender()
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)

    assert sorted(m.token for m in sender.sent) == ["tok-a", "tok-b"]
    msg = sender.sent[0]
    assert msg.body.startswith("३५ °C"), "Marathi label from rules.json"
    assert "फळगळ होऊ शकते" in msg.body  # calm wording, owner 2026-11-10
    assert msg.data == {
        "plot_id": str(alert.plot_id),
        "rule_key": "heat_fruit_drop",
        "first_day": "2026-10-28",
    }
    assert (summary.alerts, summary.notified, summary.messages) == (1, 1, 2)
    assert [a.notified_at is not None for a in await stored(maker)] == [True]
    assert json.loads(summary.to_json())["messages"] == 2

    async with maker() as s:
        again = await run_delivery(s, sender, NOW + timedelta(hours=1))
    assert again.alerts == 0
    assert len(sender.sent) == 2


async def test_unknown_language_falls_back_to_english(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed(maker, language="ta")
    sender = FakeSender()
    async with maker() as s:
        await run_delivery(s, sender, NOW)
    assert sender.sent[0].body.startswith("Heat of 35 °C")


async def test_invalid_tokens_are_dropped_and_outages_retried_next_run(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed(maker, tokens=("dead",))
    await seed(maker, tokens=("busy",))
    sender = FakeSender(invalid={"dead"}, down={"busy"})
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)

    assert (summary.alerts, summary.notified, summary.failed) == (2, 0, 1)
    assert summary.invalid_tokens == 1
    async with maker() as s:
        assert [d.token for d in (await s.scalars(select(PushDevice))).all()] == ["busy"]
    assert all(a.notified_at is None for a in await stored(maker))

    sender.down.clear()
    async with maker() as s:
        retry = await run_delivery(s, sender, NOW + timedelta(hours=1))
    assert retry.notified == 1
    assert [m.token for m in sender.sent] == ["busy"]


async def test_old_alerts_and_farmers_without_devices_get_nothing(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed(maker, created=NOW - timedelta(days=3))
    await seed(maker, tokens=())
    sender = FakeSender()
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)
    assert sender.sent == []
    assert (summary.alerts, summary.notified, summary.no_device) == (1, 0, 1)


async def test_without_a_sender_nothing_is_sent_or_stamped(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed(maker)
    async with maker() as s:
        summary = await run_delivery(s, None, NOW)
    assert summary.skipped_reason == "no push sender configured (FCM credentials)"
    assert summary.alerts == 1
    assert all(a.notified_at is None for a in await stored(maker))


async def test_storm_alert_tells_the_app_to_open_the_claim_kit(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    alert = await seed(maker, rule_key="hail_thunderstorm")
    sender = FakeSender()
    async with maker() as s:
        await run_delivery(s, sender, NOW)
    [msg] = sender.sent
    assert "फोटो" in msg.body
    assert msg.data == {
        "plot_id": str(alert.plot_id),
        "rule_key": "hail_thunderstorm",
        "first_day": "2026-10-28",
        "action": "claim_kit",
    }


async def seed_plots(
    maker: async_sessionmaker[AsyncSession],
    alerts: list[tuple[str, str]],
    *,
    language: str = "mr",
    tokens: tuple[str, ...] = ("tok-a",),
) -> dict[str, uuid.UUID]:
    """One farmer with a plot per distinct name and one alert per (plot name, rule)."""
    owner = uuid.uuid4()
    plots = {name: uuid.uuid4() for name, _ in alerts}
    async with maker() as s:
        s.add(Farmer(id=owner, language=language, client_updated_at=NOW, last_seq=1))
        s.add_all(PushDevice(owner_id=owner, token=t, platform="android") for t in tokens)
        s.add_all(
            Plot(
                id=pid,
                owner_id=owner,
                name=name,
                crop="santra",
                area_sq_m=4000,
                client_updated_at=NOW,
                last_seq=1,
            )
            for name, pid in plots.items()
        )
        for n, (name, rule_key) in enumerate(alerts):
            s.add(
                PlotRiskAlert(
                    owner_id=owner,
                    plot_id=plots[name],
                    rule_key=rule_key,
                    first_day=date(2026, 10, 28),
                    value=36,
                    created_at=NOW - timedelta(minutes=10 - n),
                )
            )
        await s.commit()
    return plots


async def test_same_rule_on_two_plots_is_one_message_naming_both_plots(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    plots = await seed_plots(
        maker, [("Sharayu farm", "heat_fruit_drop"), ("बाग १", "heat_fruit_drop")]
    )
    sender = FakeSender()
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)

    [msg] = sender.sent
    assert msg.title == "बागमित्र हवामान सूचना"
    assert msg.body.startswith("३५ °C")
    assert msg.body.endswith(" (बाग: Sharayu farm, बाग १)")
    assert msg.data == {
        "plot_id": str(plots["Sharayu farm"]),
        "rule_key": "heat_fruit_drop",
        "first_day": "2026-10-28",
    }
    assert (summary.alerts, summary.notified, summary.messages) == (2, 2, 1)
    assert all(a.notified_at is not None for a in await stored(maker))


async def test_grouped_message_goes_to_every_phone_and_lists_at_most_three_plots(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    names = ["A farm", "B farm", "C farm", "D farm", "E farm"]
    await seed_plots(
        maker, [(n, "heat_fruit_drop") for n in names], language="en", tokens=("t1", "t2")
    )
    sender = FakeSender()
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)
    assert [m.token for m in sender.sent] == ["t1", "t2"]
    assert sender.sent[0].body.endswith(" (plots: A farm, B farm, C farm +2)")
    assert (summary.alerts, summary.notified, summary.messages) == (5, 5, 2)


async def test_different_rules_stay_separate_messages(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed_plots(
        maker,
        [
            ("Sharayu farm", "heat_fruit_drop"),
            ("बाग १", "heat_fruit_drop"),
            ("बाग १", "hail_thunderstorm"),
        ],
    )
    sender = FakeSender()
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)
    assert [m.data["rule_key"] for m in sender.sent] == ["heat_fruit_drop", "hail_thunderstorm"]
    assert sender.sent[0].body.endswith("(बाग: Sharayu farm, बाग १)")
    assert "(बाग:" not in sender.sent[1].body, "one plot: the rule label only"
    assert (summary.alerts, summary.notified, summary.messages) == (3, 3, 2)


async def test_same_rule_of_two_farmers_is_not_merged(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed_plots(maker, [("बाग १", "heat_fruit_drop")], tokens=("tok-1",))
    await seed_plots(maker, [("बाग १", "heat_fruit_drop")], tokens=("tok-2",))
    sender = FakeSender()
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)
    assert sorted(m.token for m in sender.sent) == ["tok-1", "tok-2"]
    assert all("(बाग:" not in m.body for m in sender.sent)
    assert (summary.alerts, summary.notified, summary.messages) == (2, 2, 2)


async def test_grouped_alerts_stay_unsent_together_on_an_outage(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed_plots(
        maker,
        [("Sharayu farm", "heat_fruit_drop"), ("बाग १", "heat_fruit_drop")],
        tokens=("busy",),
    )
    sender = FakeSender(down={"busy"})
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)
    assert (summary.alerts, summary.notified, summary.messages, summary.failed) == (2, 0, 0, 2)
    assert all(a.notified_at is None for a in await stored(maker))
    sender.down.clear()
    async with maker() as s:
        retry = await run_delivery(s, sender, NOW + timedelta(hours=1))
    assert (retry.notified, retry.messages) == (2, 1)


async def test_grouped_alerts_to_an_unregistered_phone_are_not_stamped(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await seed_plots(
        maker,
        [("Sharayu farm", "heat_fruit_drop"), ("बाग १", "heat_fruit_drop")],
        tokens=("dead",),
    )
    sender = FakeSender(invalid={"dead"})
    async with maker() as s:
        summary = await run_delivery(s, sender, NOW)
    assert (summary.notified, summary.messages, summary.invalid_tokens) == (0, 0, 1)
    assert all(a.notified_at is None for a in await stored(maker))
