"""Feed G2 alert run against the database: no-sender path, send + stamp, dedupe across runs,
weekly cap from stamped pushes, quiet hours, digest stamp, withdrawn cancels, phones."""

from __future__ import annotations

import json
import uuid
from datetime import UTC, date, datetime, time, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.db.models import Farmer, Plot, PushDevice
from bagmitra_api.feed.alert_job import configured_sender
from bagmitra_api.feed.alerts import INDIA, AlertSummary, run_alerts
from bagmitra_api.feed.models import (
    FeedDeadline,
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedPreferences,
    FeedReceipt,
    FeedSource,
)
from bagmitra_api.feed.seed import seed_feed_sources
from bagmitra_api.push.sender import PushMessage, PushUnavailableError, SendResult

NOW = datetime(2026, 10, 27, 10, 0, tzinfo=INDIA).astimezone(UTC)
TODAY = date(2026, 10, 27)


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
async def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    m = async_sessionmaker(engine, expire_on_commit=False)
    async with m() as s:
        await seed_feed_sources(s)
        await s.commit()
    return m


async def add_item(
    maker: async_sessionmaker[AsyncSession],
    *,
    due_in: int | None = 2,
    kind: str = "apply_by",
    status: str = "published",
    district: str | None = None,
    published: datetime = NOW - timedelta(days=1),
    title: str = "Fruit planting subsidy",
) -> uuid.UUID:
    async with maker() as s:
        source = await s.scalar(select(FeedSource.id).where(FeedSource.key == "mh_gr_portal"))
        assert source is not None
        item = FeedItem(
            id=uuid.uuid4(),
            type="scheme",
            source_id=source,
            published_at=published,
            url="https://gr.maharashtra.gov.in/x.pdf",
            status=status,
            trust_level="official",
            check_issues=[],
        )
        s.add(item)
        s.add(FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="en", title=title))
        if district:
            s.add(FeedItemTarget(id=uuid.uuid4(), item_id=item.id, district=district))
        if due_in is not None:
            s.add(
                FeedDeadline(
                    id=uuid.uuid4(),
                    item_id=item.id,
                    kind=kind,
                    due_date=TODAY + timedelta(days=due_in),
                )
            )
        await s.commit()
        return item.id


async def add_farmer(
    maker: async_sessionmaker[AsyncSession],
    *,
    language: str = "mr",
    district: str | None = "Nagpur",
    tokens: tuple[str, ...] = ("tok-a",),
) -> uuid.UUID:
    owner = uuid.uuid4()
    async with maker() as s:
        s.add(
            Farmer(
                id=owner, language=language, district=district, client_updated_at=NOW, last_seq=1
            )
        )
        s.add(
            Plot(
                id=uuid.uuid4(),
                owner_id=owner,
                name="Plot",
                crop="santra",
                area_sq_m=10_000.0,
                client_updated_at=NOW,
                last_seq=1,
            )
        )
        s.add_all(PushDevice(owner_id=owner, token=t, platform="android") for t in tokens)
        await s.commit()
    return owner


async def receipts(maker: async_sessionmaker[AsyncSession]) -> list[FeedReceipt]:
    async with maker() as s:
        return list(await s.scalars(select(FeedReceipt)))


async def run(
    maker: async_sessionmaker[AsyncSession], sender: FakeSender | None, now: datetime = NOW
) -> AlertSummary:
    async with maker() as s:
        return await run_alerts(s, sender, now)


async def test_without_a_sender_it_only_plans(maker: async_sessionmaker[AsyncSession]) -> None:
    assert configured_sender() is None
    await add_item(maker)
    await add_farmer(maker)
    summary = await run(maker, None)
    assert summary.skipped_reason == "no push sender configured (FCM credentials)"
    assert (summary.farmers, summary.items, summary.planned) == (1, 1, 1)
    assert summary.digests_planned == 1
    assert summary.sent == summary.messages == 0
    assert await receipts(maker) == []
    assert json.loads(summary.to_json())["planned"] == 1


async def test_sends_once_per_stage_and_stamps(maker: async_sessionmaker[AsyncSession]) -> None:
    item_id = await add_item(maker, due_in=6)
    owner = await add_farmer(maker, tokens=("tok-a", "tok-b"))
    sender = FakeSender()
    summary = await run(maker, sender)
    assert (summary.sent, summary.digests_sent, summary.messages) == (1, 1, 4)
    alert = next(m for m in sender.sent if m.data["kind"] == "feed_alert")
    assert alert.title == "Fruit planting subsidy", "no Marathi text: English title"
    assert alert.body.startswith("शेवटची तारीख: 02/11/2026")
    assert alert.data == {"kind": "feed_alert", "item_id": str(item_id), "stage": "t7"}
    [row] = await receipts(maker)
    assert (row.owner_id, row.item_id) == (owner, item_id)
    assert row.t7_notified_at is not None
    assert row.t2_notified_at is None
    async with maker() as s:
        prefs = await s.get(FeedPreferences, owner)
        assert prefs is not None
        assert prefs.last_digest_at is not None

    again = await run(maker, sender, NOW + timedelta(days=1))
    assert (again.sent, again.digests_sent) == (0, 0)
    assert again.skipped == {"duplicate": 1}
    later = await run(maker, sender, NOW + timedelta(days=4))  # 2 days left: T-2
    assert later.sent == 1
    assert sender.sent[-1].data["stage"] == "t2"


async def test_weekly_cap_counts_pushes_already_sent(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    owner = await add_farmer(maker)
    async with maker() as s:
        s.add(
            FeedPreferences(
                owner_id=owner,
                quiet_start=time(21),
                quiet_end=time(7),
                weekly_cap=2,
                opted_out=[],
                digest_weekly=False,
            )
        )
        await s.commit()
    for due in (0, 2, 5):
        await add_item(maker, due_in=due)
    sender = FakeSender()
    first = await run(maker, sender)
    assert (first.sent, first.skipped) == (2, {"weekly_cap": 1})
    assert [m.data["stage"] for m in sender.sent] == ["t0", "t2"]
    second = await run(maker, sender, NOW + timedelta(hours=3))
    assert (second.sent, second.skipped) == (0, {"duplicate": 2, "weekly_cap": 1})


async def test_quiet_hours_defer_without_stamping(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await add_item(maker, due_in=2)
    await add_farmer(maker)
    night = datetime(2026, 10, 27, 22, 0, tzinfo=INDIA).astimezone(UTC)
    summary = await run(maker, FakeSender(), night)
    assert (summary.deferred_quiet, summary.sent) == (2, 0)
    assert await receipts(maker) == []
    morning = datetime(2026, 10, 28, 7, 5, tzinfo=INDIA).astimezone(UTC)
    assert (await run(maker, FakeSender(), morning)).sent == 1


async def test_withdrawn_item_cancels_reminders_and_targets_apply(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await add_item(maker, due_in=0, status="withdrawn")
    await add_item(maker, due_in=0, district="Pune")
    await add_item(maker, due_in=0, status="in_review")
    await add_farmer(maker)
    sender = FakeSender()
    summary = await run(maker, sender)
    assert summary.sent == 0
    assert summary.skipped == {"cancelled": 1}
    assert summary.items == 2, "drafts and the review queue are never loaded"


async def test_phones_invalid_outage_and_none(maker: async_sessionmaker[AsyncSession]) -> None:
    await add_item(maker, due_in=0, published=NOW - timedelta(days=30))
    await add_farmer(maker, tokens=("dead",))
    await add_farmer(maker, tokens=("busy",))
    await add_farmer(maker, tokens=())
    summary = await run(maker, FakeSender(invalid={"dead"}, down={"busy"}))
    assert (summary.sent, summary.failed, summary.no_device) == (0, 1, 1)
    assert summary.invalid_tokens == 1
    assert await receipts(maker) == []
    async with maker() as s:
        assert [d.token for d in await s.scalars(select(PushDevice))] == ["busy"]


async def test_dismissed_and_remind_receipts(maker: async_sessionmaker[AsyncSession]) -> None:
    pune = await add_item(maker, due_in=0, district="Pune", published=NOW - timedelta(days=30))
    mine = await add_item(maker, due_in=0, published=NOW - timedelta(days=30))
    owner = await add_farmer(maker, language="en")
    async with maker() as s:
        s.add(FeedReceipt(id=uuid.uuid4(), owner_id=owner, item_id=pune, remind_requested_at=NOW))
        s.add(FeedReceipt(id=uuid.uuid4(), owner_id=owner, item_id=mine, dismissed_at=NOW))
        await s.commit()
    sender = FakeSender()
    summary = await run(maker, sender)
    assert summary.skipped == {"dismissed": 1}
    assert [m.data["item_id"] for m in sender.sent] == [str(pune)]
    assert sender.sent[0].body == (
        "Last date: 27/10/2026\nCheck the official GR/portal before acting."
    )
