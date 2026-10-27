from __future__ import annotations

import json
import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.db.models import Farmer, PlotRiskAlert, PushDevice
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
) -> PlotRiskAlert:
    owner = uuid.uuid4()
    alert = PlotRiskAlert(
        owner_id=owner,
        plot_id=uuid.uuid4(),
        rule_key="heat_fruit_drop",
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
    assert "स्थानिक तज्ज्ञ" in msg.body
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
