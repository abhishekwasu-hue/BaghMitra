"""Q147 update pushes end to end on SQLite: new articles, market price changes and sudden
weather changes; batching, daily caps, user switches, quiet hours, idempotence, deep-link
payloads, and no duplicate with the digest, the deadline reminders or the risk-alert pushes."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, time, timedelta
from typing import Any

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import Farmer, Plot, PlotRiskAlert, PushDevice
from bagmitra_api.feed.alerts import Item, Recipient, plan_digest
from bagmitra_api.feed.matching import Profile
from bagmitra_api.feed.models import (
    FeedDeadline,
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedPreferences,
    FeedReceipt,
    FeedReviewEvent,
    FeedSource,
    FeedThread,
)
from bagmitra_api.market.models import MarketPrice
from bagmitra_api.push.deliver import NO_SENDER
from bagmitra_api.push.models import PushNotice, PushTopicPrefs, PushWeatherSeen
from bagmitra_api.push.updates import SWITCHED_OFF, run_updates
from bagmitra_api.weather.models import WeatherDaily
from tests.test_push_delivery import FakeSender

NOW = datetime(2026, 11, 12, 2, 47, tzinfo=UTC)  # 08:17 India time
TODAY = date(2026, 11, 12)
LAT, LON = 21.46, 78.26  # one weather cell (2 decimals)
SOURCE = uuid.uuid4()
SETTINGS = Settings(environment="test", database_url="sqlite+aiosqlite://")


@pytest.fixture
def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def grower(
    maker: async_sessionmaker[AsyncSession],
    *,
    lang: str = "mr",
    district: str | None = "Amravati",
    crop: str = "santra",
    tokens: tuple[str, ...] = ("tok-a",),
    plots: int = 1,
    located: bool = True,
) -> tuple[uuid.UUID, list[uuid.UUID]]:
    owner = uuid.uuid4()
    plot_ids = [uuid.uuid4() for _ in range(plots)]
    async with maker() as s:
        s.add(Farmer(id=owner, language=lang, district=district, client_updated_at=NOW, last_seq=1))
        s.add_all(PushDevice(owner_id=owner, token=t, platform="android") for t in tokens)
        for n, pid in enumerate(plot_ids):
            s.add(
                Plot(
                    id=pid,
                    owner_id=owner,
                    name=f"बाग {n + 1}",
                    crop=crop,
                    area_sq_m=4000,
                    centroid_lat=LAT if located else None,
                    centroid_lon=LON if located else None,
                    client_updated_at=NOW,
                    last_seq=1,
                )
            )
        await s.commit()
    return owner, plot_ids


async def article(
    maker: async_sessionmaker[AsyncSession],
    title: str,
    *,
    kind: str = "knowledge",
    published: datetime = NOW - timedelta(hours=2),
    event: str = "auto_published",
    status: str = "published",
    with_article: bool = True,
    district: str | None = None,
    deadline: date | None = None,
    thread: bool = False,
) -> uuid.UUID:
    item_id = uuid.uuid4()
    async with maker() as s:
        if await s.get(FeedSource, SOURCE) is None:
            s.add(
                FeedSource(
                    id=SOURCE,
                    key="test",
                    name="Test",
                    url="https://example.org",
                    tier="news",
                    fetch_method="manual",
                )
            )
        thread_id = None
        if thread:
            thread_id = uuid.uuid4()
            s.add(FeedThread(id=thread_id, title=title, last_item_at=published))
        s.add(
            FeedItem(
                id=item_id,
                type=kind,
                source_id=SOURCE,
                published_at=published - timedelta(days=1),  # the source date, older
                url="https://example.org/a",
                status=status,
                trust_level="news",
                thread_id=thread_id,
            )
        )
        s.add(
            FeedItemI18n(
                id=uuid.uuid4(),
                item_id=item_id,
                lang="mr",
                title=title,
                summary=f"{title} याचा सारांश",
                article={"headline": title} if with_article else None,
            )
        )
        s.add(FeedItemI18n(id=uuid.uuid4(), item_id=item_id, lang="en", title=f"EN {title}"))
        s.add(
            FeedReviewEvent(
                id=uuid.uuid4(), item_id=item_id, kind=event, detail={}, created_at=published
            )
        )
        if district:
            s.add(FeedItemTarget(id=uuid.uuid4(), item_id=item_id, district=district))
        if deadline:
            s.add(
                FeedDeadline(id=uuid.uuid4(), item_id=item_id, kind="apply_by", due_date=deadline)
            )
        await s.commit()
    return item_id


async def notices(
    maker: async_sessionmaker[AsyncSession], kind: str | None = None
) -> list[PushNotice]:
    async with maker() as s:
        q = select(PushNotice).order_by(PushNotice.subject)
        if kind:
            q = q.where(PushNotice.kind == kind)
        return list(await s.scalars(q))


async def run(
    maker: async_sessionmaker[AsyncSession],
    sender: FakeSender | None,
    now: datetime = NOW,
    **overrides: Any,
) -> Any:
    settings = SETTINGS.model_copy(update=overrides) if overrides else SETTINGS
    async with maker() as s:
        return await run_updates(s, sender, settings, now)


# --- switches, sender ------------------------------------------------------------------------


async def test_off_without_a_sender_or_with_the_kill_switch(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker)
    await article(maker, "नवती व्यवस्थापन")
    summary = await run(maker, None)
    assert summary.skipped_reason == NO_SENDER
    sender = FakeSender()
    summary = await run(maker, sender, cron_push_updates=False)
    assert summary.skipped_reason == SWITCHED_OFF
    assert sender.sent == []
    assert await notices(maker) == []


# --- articles --------------------------------------------------------------------------------


async def test_one_new_article_push_with_its_deep_link_once(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, tokens=("tok-a", "tok-b"))
    item = await article(maker, "संत्र्यावरील सायला ओळख")
    sender = FakeSender()
    summary = await run(maker, sender)
    assert sorted(m.token for m in sender.sent) == ["tok-a", "tok-b"]
    msg = sender.sent[0]
    assert msg.title == "नवीन लेख: संत्र्यावरील सायला ओळख"
    assert msg.body == "संत्र्यावरील सायला ओळख याचा सारांश"
    assert msg.data == {"kind": "article", "item_id": str(item)}
    assert summary.sent == {"article": 1}
    assert [n.subject for n in await notices(maker, "article")] == [str(item)]
    again = FakeSender()
    await run(maker, again, NOW + timedelta(hours=6))
    assert again.sent == [], "a re-run never repeats a push"


async def test_news_article_opens_its_topic_thread_and_english_falls_back(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, lang="en")
    item = await article(maker, "कांदा दर", kind="news", event="published", thread=True)
    sender = FakeSender()
    await run(maker, sender)
    msg = sender.sent[0]
    assert msg.title == "New article: EN कांदा दर"
    assert msg.data["kind"] == "article"
    assert msg.data["item_id"] == str(item)
    assert "thread_id" in msg.data


async def test_several_articles_are_grouped_and_capped_per_day(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker)
    ids = [
        await article(maker, f"लेख {n}", published=NOW - timedelta(hours=n)) for n in (1, 2, 3, 4)
    ]
    sender = FakeSender()
    await run(maker, sender)
    assert len(sender.sent) == 1
    msg = sender.sent[0]
    assert msg.title == "४ नवीन लेख"
    assert msg.body == "• लेख 1\n• लेख 2\n• लेख 3\n…आणखी १"
    assert msg.data == {"kind": "article", "items": ",".join(str(i) for i in ids)}
    # Later the same day nothing more: one article push a day (Q157).
    await article(maker, "लेख 5", published=NOW + timedelta(hours=1))
    second = FakeSender()
    summary = await run(maker, second, NOW + timedelta(hours=6))
    assert second.sent == []
    assert summary.skipped == {"article_daily_cap": 1}
    await article(maker, "लेख 6", published=NOW + timedelta(hours=7))
    # The next India day both go out in one push.
    fourth = FakeSender()
    await run(maker, fourth, NOW + timedelta(days=1))
    assert [m.title for m in fourth.sent] == ["२ नवीन लेख"]
    one_day = await run(maker, FakeSender(), NOW + timedelta(days=1), push_article_daily_max=0)
    assert one_day.sent == {}


async def test_articles_already_told_another_way_are_left_out(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    owner, _ = await grower(maker, district="Nagpur")
    dismissed = await article(maker, "बंद केलेला")
    staged = await article(maker, "आठवण गेलेला")
    await article(maker, "तारीख असलेला", deadline=TODAY + timedelta(days=5))
    await article(maker, "पुण्यासाठी", district="Pune")
    await article(maker, "लेख नसलेला", with_article=False)
    await article(maker, "थांबवलेला", status="held")
    await article(maker, "जुना", published=NOW - timedelta(hours=49))
    await article(maker, "डायजेस्टमध्ये", published=NOW - timedelta(hours=5))
    wanted = await article(maker, "नागपूरसाठी", district="nagpur")
    async with maker() as s:
        s.add(FeedReceipt(id=uuid.uuid4(), owner_id=owner, item_id=dismissed, dismissed_at=NOW))
        s.add(FeedReceipt(id=uuid.uuid4(), owner_id=owner, item_id=staged, t7_notified_at=NOW))
        s.add(FeedPreferences(owner_id=owner, last_digest_at=NOW - timedelta(hours=4)))
        await s.commit()
    sender = FakeSender()
    await run(maker, sender)
    assert [(m.title, m.data.get("item_id")) for m in sender.sent] == [
        ("नवीन लेख: नागपूरसाठी", str(wanted))
    ]


async def test_switch_off_and_quiet_hours(maker: async_sessionmaker[AsyncSession]) -> None:
    owner, _ = await grower(maker)
    await article(maker, "लेख")
    async with maker() as s:
        s.add(PushTopicPrefs(owner_id=owner, articles=False, market=True, weather_change=True))
        await s.commit()
    sender = FakeSender()
    summary = await run(maker, sender)
    assert sender.sent == []
    assert summary.skipped == {"article_switched_off": 1}
    async with maker() as s:
        prefs = await s.get(PushTopicPrefs, owner)
        assert prefs is not None
        prefs.articles = True
        s.add(FeedPreferences(owner_id=owner, quiet_start=time(8, 0), quiet_end=time(9, 0)))
        await s.commit()
    summary = await run(maker, sender)  # 08:17 India: inside the grower's quiet hours
    assert sender.sent == []
    assert summary.skipped == {"article_quiet_hours": 1}
    await run(maker, sender, NOW + timedelta(hours=1))  # 09:17: after them
    assert len(sender.sent) == 1
    defaults_off = FakeSender()
    await grower(maker, tokens=("tok-other",))
    await run(maker, defaults_off, push_topic_articles_default=False)
    assert defaults_off.sent == [], "the admin default applies without a saved choice"


async def test_outage_retries_next_run_and_dead_tokens_are_dropped(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, tokens=("tok-down",))
    await article(maker, "लेख")
    summary = await run(maker, FakeSender(down={"tok-down"}))
    assert summary.failed == 1
    assert await notices(maker) == []
    sender = FakeSender()
    await run(maker, sender)
    assert len(sender.sent) == 1
    await grower(maker, tokens=("tok-dead",))
    await article(maker, "दुसरा लेख")
    summary = await run(maker, FakeSender(invalid={"tok-dead"}), NOW + timedelta(hours=6))
    assert summary.invalid_tokens == 1
    async with maker() as s:
        assert "tok-dead" not in set(await s.scalars(select(PushDevice.token)))


def test_digest_leaves_out_items_already_pushed_as_articles() -> None:
    owner = uuid.uuid4()
    me = Recipient(owner, "mr", Profile(district=None, crops=frozenset(), land_ha=None))
    pushed = Item(uuid.uuid4(), "knowledge", "published", NOW - timedelta(days=1), {"mr": "अ"})
    fresh = Item(uuid.uuid4(), "gr", "published", NOW - timedelta(days=1), {"mr": "ब"})
    digest = plan_digest(me, [pushed, fresh], {}, NOW, already_pushed=frozenset({pushed.id}))
    assert digest is not None
    assert digest.data["items"] == str(fresh.id)
    assert plan_digest(me, [pushed], {}, NOW, already_pushed=frozenset({pushed.id})) is None


# --- market ----------------------------------------------------------------------------------


async def price(
    maker: async_sessionmaker[AsyncSession],
    market: str,
    district: str,
    *pairs: tuple[int, int],
    commodity: str = "Orange",
    variety: str = "Nagpuri",
) -> None:
    async with maker() as s:
        for ago, modal in pairs:
            s.add(
                MarketPrice(
                    day=TODAY - timedelta(days=ago),
                    market=market,
                    commodity=commodity,
                    variety=variety,
                    grade="FAQ",
                    source="agmarknet",
                    state="Maharashtra",
                    district=district,
                    modal_rs_per_quintal=modal,
                    fetched_at=NOW,
                )
            )
        await s.commit()


async def test_market_change_of_the_district_mandis_in_one_push_a_day(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, district="अमरावती")  # typed in Marathi
    await price(maker, "Warud", "Amravati", (1, 3200), (0, 3700))
    await price(maker, "Morshi", "Amravati", (2, 3000), (1, 2600))
    await price(maker, "Pune", "Pune", (1, 3000), (0, 4000))  # another district
    await price(maker, "Katol", "Amravati", (1, 3000), (0, 3100))  # +100, +3 %: too small
    sender = FakeSender()
    await run(maker, sender)
    assert len(sender.sent) == 1
    msg = sender.sent[0]
    assert msg.title == "बाजारभाव"
    assert msg.body == (
        "वरूड संत्रा (नागपुरी): आज ₹३,७०० (+₹५००, +१६%)\nमोर्शी संत्रा (नागपुरी): काल ₹२,६०० (-₹४००, -१३%)"
    )
    assert msg.data == {"kind": "market", "crop": "santra"}
    assert len(await notices(maker, "market")) == 2
    # A new change later the same day waits: one market push a day.
    await price(maker, "Morshi", "Amravati", (0, 3400))
    later = FakeSender()
    summary = await run(maker, later, NOW + timedelta(hours=6))
    assert later.sent == []
    assert summary.skipped == {"market_daily_cap": 1}
    nothing = FakeSender()
    await run(maker, nothing, NOW + timedelta(hours=12))
    assert nothing.sent == []


async def test_market_falls_back_to_the_local_mandis_and_follows_plot_crops(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, district="", lang="en")
    await grower(maker, district="Nagpur", crop="banana", tokens=("tok-banana",))
    await price(maker, "Warud", "Amravati", (1, 3200), (0, 3700))  # local list
    await price(maker, "Pune", "Pune", (1, 3000), (0, 4000))
    sender = FakeSender()
    await run(maker, sender)
    assert [(m.token, m.body) for m in sender.sent] == [
        ("tok-a", "Warud Santra (Nagpuri): today ₹3,700 (+₹500, +16%)")
    ], "the banana grower has no changed banana price"


# --- weather ---------------------------------------------------------------------------------


async def forecast(
    maker: async_sessionmaker[AsyncSession],
    rows: dict[int, dict[str, float]],
    fetched: datetime = NOW - timedelta(hours=2),
) -> None:
    async with maker() as s:
        for offset, values in rows.items():
            day = TODAY + timedelta(days=offset)
            old = await s.get(WeatherDaily, (LAT, LON, day))
            if old is not None:
                await s.delete(old)
                await s.flush()
            s.add(WeatherDaily(cell_lat=LAT, cell_lon=LON, day=day, fetched_at=fetched, **values))
        await s.commit()


async def test_sudden_rain_chance_once_per_plot_with_the_forecast_link(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    _, (plot,) = await grower(maker)
    await forecast(
        maker,
        {
            -1: {"rain_prob_pct": 10, "t_max_c": 31},
            0: {"rain_prob_pct": 20, "t_max_c": 31},
            1: {"rain_prob_pct": 70, "t_max_c": 30},
        },
    )
    sender = FakeSender()
    summary = await run(maker, sender)
    assert summary.weather_changes_found == 1
    msg = sender.sent[0]
    assert msg.title == "हवामान बदल"
    assert msg.body == "उद्या पावसाची शक्यता ७०%; फवारणीचे नियोजन पाहा."
    assert msg.data == {"kind": "weather_change", "plot_id": str(plot)}
    async with maker() as s:
        seen = list(await s.scalars(select(PushWeatherSeen).order_by(PushWeatherSeen.day)))
    assert [(r.day, r.rain_prob_pct) for r in seen] == [(TODAY, 20), (TODAY + timedelta(1), 70)]
    again = FakeSender()
    await run(maker, again, NOW + timedelta(hours=6))
    assert again.sent == [], "already seen: not a change any more"
    # Wind jumps the same afternoon: found, but the plot already had its push today.
    await forecast(maker, {1: {"rain_prob_pct": 70, "t_max_c": 30, "wind_gust_kmh": 50}})
    await forecast(maker, {0: {"rain_prob_pct": 20, "t_max_c": 31, "wind_gust_kmh": 10}})
    capped = FakeSender()
    summary = await run(maker, capped, NOW + timedelta(hours=6))
    assert capped.sent == []
    assert summary.weather_changes_found == 1
    assert summary.skipped == {"weather_daily_cap": 1}
    nextday = FakeSender()
    await run(maker, nextday, NOW + timedelta(hours=22))  # 06:17 India: quiet hours, held
    await run(maker, nextday, NOW + timedelta(days=1))
    assert [m.body for m in nextday.sent] == [
        "आज वाऱ्याचा वेग ताशी ५० कि.मी. पर्यंत; फवारणीचे नियोजन पाहा."
    ]


async def test_risk_rule_alerts_are_not_pushed_twice(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    owner, (plot,) = await grower(maker)
    await forecast(
        maker,
        {
            0: {"precip_mm": 0, "t_max_c": 30},
            1: {"precip_mm": 70, "t_max_c": 36},  # heavy rain and +6 °C to 36 °C
        },
    )
    async with maker() as s:
        for rule in ("heavy_rain", "heat_fruit_drop"):
            s.add(
                PlotRiskAlert(
                    owner_id=owner,
                    plot_id=plot,
                    rule_key=rule,
                    first_day=TODAY + timedelta(days=1),
                    value=70,
                    created_at=NOW - timedelta(hours=2),
                )
            )
        await s.commit()
    sender = FakeSender()
    summary = await run(maker, sender)
    assert sender.sent == []
    assert summary.weather_changes_found == 0


async def test_several_plots_in_one_push_and_old_forecasts_ignored(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    await grower(maker, plots=2, lang="en")
    await forecast(maker, {0: {"t_max_c": 30, "t_min_c": 8}, 1: {"t_max_c": 24, "t_min_c": 3}})
    sender = FakeSender()
    await run(maker, sender)
    assert len(sender.sent) == 1
    assert sender.sent[0].body.split("\n") == [
        "बाग 1, बाग 2: Highest temperature tomorrow: 24 °C, 6 °C below today.",
        "बाग 1, बाग 2: Lowest temperature tomorrow: 3 °C; look over young plants and the nursery.",
    ], "the same change on two plots is one line naming both"
    rows = await notices(maker, "weather")
    assert len(rows) == 4
    assert all(r.notified_at is not None for r in rows)
    await grower(maker, tokens=("tok-stale",))
    await forecast(
        maker, {0: {"rain_prob_pct": 0}, 1: {"rain_prob_pct": 90}}, NOW - timedelta(days=3)
    )
    stale = FakeSender()
    summary = await run(maker, stale, NOW + timedelta(hours=1))
    assert stale.sent == []
    assert summary.weather_changes_found == 0
