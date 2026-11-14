"""Update pushes (owner 2026-11-12, OPEN_QUESTIONS Q147): a push when a new article is
published, when a followed mandi price changes, and when the weather changes suddenly.

    python -m bagmitra_api.push.updates

Runs a few times a day after the market pulls (deploy.sh adds the cron line once
FCM_PROJECT_ID is set, unless CRON_PUSH_UPDATES=off). Each run:
1. weather: compares the stored forecast of every located plot's cell with the forecast this
   check saw last time (`push_weather_seen`) and stores each new change as a pending
   `push_notices` row (rules: `push/changes.py`); risk-rule changes already pushed by
   `push.deliver` are left out;
2. plans per grower at most one push per kind, then sends through FCM and logs it in
   `push_notices` (unique per grower, kind and subject: a re-run never repeats a push).

Who gets what: only growers with a registered phone, whose switch for the kind is on
(`push_topic_prefs`, Settings -> सूचना; no row = PUSH_TOPIC_*_DEFAULT), outside their feed
quiet hours (`feed_preferences`, default 21:00-07:00 India time: the push waits for a later
run), and within the daily caps (India day):
- articles: knowledge / news items with an AI article, published (event `published`,
  `auto_published` or a passing knowledge re-check) within PUSH_ARTICLE_LOOKBACK_HOURS and
  still published, matched to the grower like the feed (targets; none = everyone). Left out:
  dismissed items, items with a date (the deadline reminders tell those), items a reminder
  stage already went out for, items the weekly digest already listed (sent after publication),
  items already pushed. Several go in one push ("३ नवीन लेख"); at most PUSH_ARTICLE_DAILY_MAX;
- market: the grower's crops are the crops of their plots that have prices; the mandis are the
  ones in the grower's district (profile) for that crop; when the district has none (or is
  empty), the local APMC list the market tab shows first (MARKET_LOCAL_MARKETS). The app stores
  no mandi choice and plots no nearest mandi. Series combined; at most PUSH_MARKET_DAILY_MAX;
- weather: pending changes of the grower's plots, at most PUSH_WEATHER_DAILY_MAX per plot;
  the same change on several plots of one cell is one line naming the plots.
Then the shared daily budget (push/budget.py, OPEN_QUESTIONS Q157): weather changes first,
market moves, new articles last; a topic ("weather:<signal>", "market:<crop>",
"article:<thread or item>") sent to the grower within PUSH_REPEAT_DAYS is left out, and a push
over PUSH_DAILY_MAX is not sent. What is held back is logged and not planned again.
Without a sender (no FCM credentials) or with CRON_PUSH_UPDATES=off nothing is read or sent.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from collections import defaultdict
from collections.abc import Iterable, Sequence
from dataclasses import asdict, dataclass, field
from datetime import date, datetime, time, timedelta
from typing import Any

import httpx
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.observability import report_job_failure, start_job_reporting
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import as_utc, utcnow
from bagmitra_api.db.models import Farmer, Plot, PlotRiskAlert, PushDevice
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.alerts import (
    INDIA,
    Item,
    Prefs,
    Receipt,
    Recipient,
    is_for,
    load_recipients,
    send_time,
)
from bagmitra_api.feed.matching import Target
from bagmitra_api.feed.models import (
    FeedDeadline,
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedReceipt,
    FeedReviewEvent,
)
from bagmitra_api.market.models import MarketPrice
from bagmitra_api.market.service import MANUAL
from bagmitra_api.push import budget as pb
from bagmitra_api.push import texts
from bagmitra_api.push.changes import (
    SIGNAL_ORDER,
    DayValues,
    MarketRules,
    PriceChange,
    SeriesKey,
    StoredAlert,
    WeatherRules,
    WeatherSignal,
    new_signals,
    price_change,
    weather_signals,
)
from bagmitra_api.push.deliver import NO_SENDER
from bagmitra_api.push.fcm import fcm_sender
from bagmitra_api.push.models import (
    ARTICLE,
    MARKET,
    WEATHER,
    PushNotice,
    PushTopicPrefs,
    PushWeatherSeen,
)
from bagmitra_api.push.sender import PushMessage, PushSender, PushUnavailableError, SendResult
from bagmitra_api.routers.market import market_matches
from bagmitra_api.weather.models import WeatherDaily
from bagmitra_api.weather.service import Cell, cell_for

SWITCHED_OFF = "update pushes switched off (CRON_PUSH_UPDATES)"
SOURCE = "updates"
ARTICLE_TYPES = ("news", "knowledge")
PUBLISH_EVENTS = ("published", "auto_published", "knowledge_recheck")
MAX_LINES = 3  # lines in one push body; the rest is "…and N more"
MAX_IDS = 10  # item ids carried in a grouped article push
SUMMARY_MAX = 160
TITLE_MAX = 120
PENDING_HOURS = 24  # a weather change not sent within this long is dropped
TOPIC_FIELDS = {ARTICLE: "articles", MARKET: "market", WEATHER: "weather_change"}


@dataclass(frozen=True, slots=True)
class Topics:
    articles: bool = True
    market: bool = True
    weather_change: bool = True

    def on(self, kind: str) -> bool:
        return bool(getattr(self, TOPIC_FIELDS[kind]))


def default_topics(settings: Settings) -> Topics:
    return Topics(
        settings.push_topic_articles_default,
        settings.push_topic_market_default,
        settings.push_topic_weather_default,
    )


@dataclass
class UpdatesSummary:
    growers: int = 0
    weather_changes_found: int = 0
    planned: dict[str, int] = field(default_factory=dict)
    sent: dict[str, int] = field(default_factory=dict)
    messages: int = 0
    failed: int = 0
    invalid_tokens: int = 0
    skipped: dict[str, int] = field(default_factory=dict)
    skipped_budget: int = 0
    skipped_repeat: int = 0
    skipped_reason: str | None = None

    def count(self, table: dict[str, int], key: str) -> None:
        table[key] = table.get(key, 0) + 1

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


@dataclass(frozen=True, slots=True)
class Planned:
    owner_id: uuid.UUID
    kind: str
    title: str
    body: str
    data: dict[str, str]
    rows: tuple[PushNotice, ...]  # new rows (articles, market) or pending rows (weather)
    priority: int = pb.ARTICLES
    topics: tuple[str, ...] = ()


@dataclass
class Grower:
    recipient: Recipient
    district: str
    topics: Topics
    tokens: list[str]
    plots: list[tuple[uuid.UUID, str, str]] = field(default_factory=list)  # id, name, crop

    @property
    def owner_id(self) -> uuid.UUID:
        return self.recipient.owner_id

    @property
    def lang(self) -> str:
        return self.recipient.lang

    @property
    def prefs(self) -> Prefs:
        return self.recipient.prefs


def india_day(now: datetime) -> date:
    return now.astimezone(INDIA).date()


def india_midnight(now: datetime) -> datetime:
    return datetime.combine(india_day(now), time.min, INDIA)


def _lines(lines: Sequence[str], lang: str) -> str:
    shown = list(lines[:MAX_LINES])
    if len(lines) > MAX_LINES:
        shown.append(
            texts.pick(texts.MORE, lang).format(n=texts.digits(str(len(lines) - MAX_LINES), lang))
        )
    return "\n".join(shown)


# --- loading ---------------------------------------------------------------------------------


async def _growers(session: AsyncSession, settings: Settings) -> dict[uuid.UUID, Grower]:
    """Growers with at least one registered phone (nobody else can receive a push)."""
    tokens: dict[uuid.UUID, list[str]] = defaultdict(list)
    for owner_id, token in (
        await session.execute(
            select(PushDevice.owner_id, PushDevice.token).order_by(PushDevice.token)
        )
    ).tuples():
        tokens[owner_id].append(token)
    if not tokens:
        return {}
    districts = dict(
        (
            await session.execute(
                select(Farmer.id, Farmer.district).where(Farmer.id.in_(list(tokens)))
            )
        )
        .tuples()
        .all()
    )
    saved = {
        t.owner_id: Topics(t.articles, t.market, t.weather_change)
        for t in await session.scalars(
            select(PushTopicPrefs).where(PushTopicPrefs.owner_id.in_(list(tokens)))
        )
    }
    default = default_topics(settings)
    out: dict[uuid.UUID, Grower] = {}
    for recipient in await load_recipients(session):
        if recipient.owner_id in tokens:
            out[recipient.owner_id] = Grower(
                recipient,
                texts.place_key(districts.get(recipient.owner_id)),
                saved.get(recipient.owner_id, default),
                tokens[recipient.owner_id],
            )
    for plot_id, owner_id, name, crop in (
        await session.execute(
            select(Plot.id, Plot.owner_id, Plot.name, Plot.crop)
            .where(Plot.deleted_at.is_(None), Plot.owner_id.in_(list(out)))
            .order_by(Plot.name, Plot.id)
        )
    ).tuples():
        out[owner_id].plots.append((plot_id, name, crop))
    return out


async def _sent_today(
    session: AsyncSession, kind: str, now: datetime
) -> dict[tuple[uuid.UUID, uuid.UUID | None], int]:
    """Pushes of `kind` sent since India midnight, per (grower, plot); plot None for articles
    and market."""
    rows = await session.execute(
        select(
            PushNotice.owner_id, PushNotice.plot_id, func.count(func.distinct(PushNotice.push_id))
        )
        .where(
            PushNotice.kind == kind,
            PushNotice.notified_at.is_not(None),
            PushNotice.notified_at >= india_midnight(now),
        )
        .group_by(PushNotice.owner_id, PushNotice.plot_id)
    )
    out: dict[tuple[uuid.UUID, uuid.UUID | None], int] = defaultdict(int)
    for owner_id, plot_id, n in rows.tuples():
        out[(owner_id, plot_id if kind == WEATHER else None)] += int(n)
    return out


async def _subjects(
    session: AsyncSession, kind: str, owners: Iterable[uuid.UUID], since: date
) -> set[tuple[uuid.UUID, str]]:
    """(grower, subject) of `kind` logged from `since` on; older subjects cannot recur (an
    article older than the look-back, a price or forecast day before it)."""
    rows = await session.execute(
        select(PushNotice.owner_id, PushNotice.subject).where(
            PushNotice.kind == kind,
            PushNotice.owner_id.in_(list(owners)),
            PushNotice.day >= since,
        )
    )
    return set(rows.tuples())


def _repeats(  # noqa: PLR0913 - one grower's candidates with the run context
    session: AsyncSession,
    budget: pb.Budget,
    grower: Grower,
    priority: int,
    topics: Sequence[str],
    summary: UpdatesSummary,
) -> set[str]:
    """The topics sent to the grower within PUSH_REPEAT_DAYS; logged as held back."""
    again = {t for t in topics if budget.repeated(grower.owner_id, t)}
    if again:
        budget.record(session, grower.owner_id, SOURCE, priority, sorted(again), pb.REPEAT)
        summary.skipped_repeat += 1
    return again


def _park(session: AsyncSession, rows: Iterable[PushNotice], now: datetime) -> None:
    """Log article / market subjects held back by the budget unsent, so no run plans them
    again (they stay in the app)."""
    for row in rows:
        row.day, row.created_at = india_day(now), now
        session.add(row)


def _gate(grower: Grower, kind: str, now: datetime, summary: UpdatesSummary) -> bool:
    """Switch on and outside quiet hours; counts why not."""
    if not grower.topics.on(kind):
        summary.count(summary.skipped, f"{kind}_switched_off")
        return False
    if send_time(now, grower.prefs) > now:
        summary.count(summary.skipped, f"{kind}_quiet_hours")
        return False
    return True


# --- articles --------------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class Article:
    item: Item
    published: datetime  # when it entered the feed (review event)
    titles: dict[str, str]
    summaries: dict[str, str]
    thread_id: uuid.UUID | None


async def recent_articles(
    session: AsyncSession, settings: Settings, now: datetime
) -> list[Article]:
    since = now - timedelta(hours=settings.push_article_lookback_hours)
    events = dict(
        (
            await session.execute(
                select(FeedReviewEvent.item_id, func.max(FeedReviewEvent.created_at))
                .where(
                    FeedReviewEvent.kind.in_(PUBLISH_EVENTS),
                    FeedReviewEvent.created_at >= since,
                    FeedReviewEvent.created_at <= now,
                )
                .group_by(FeedReviewEvent.item_id)
            )
        )
        .tuples()
        .all()
    )
    if not events:
        return []
    rows = list(
        await session.scalars(
            select(FeedItem).where(
                FeedItem.id.in_(list(events)),
                FeedItem.status == "published",
                FeedItem.type.in_(ARTICLE_TYPES),
            )
        )
    )
    ids = [r.id for r in rows]
    titles: dict[uuid.UUID, dict[str, str]] = defaultdict(dict)
    summaries: dict[uuid.UUID, dict[str, str]] = defaultdict(dict)
    with_article: set[uuid.UUID] = set()
    for t in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id.in_(ids))):
        titles[t.item_id][t.lang] = t.title
        if t.summary:
            summaries[t.item_id][t.lang] = t.summary
        if t.article:
            with_article.add(t.item_id)
    targets: dict[uuid.UUID, list[Target]] = defaultdict(list)
    for g in await session.scalars(select(FeedItemTarget).where(FeedItemTarget.item_id.in_(ids))):
        targets[g.item_id].append(Target(g.district, g.crop, g.min_ha, g.max_ha))
    dates: dict[uuid.UUID, dict[str, date]] = defaultdict(dict)
    for d in await session.scalars(select(FeedDeadline).where(FeedDeadline.item_id.in_(ids))):
        dates[d.item_id][d.kind] = d.due_date
    out = [
        Article(
            item=Item(
                id=r.id,
                type=r.type,
                status=r.status,
                published_at=as_utc(r.published_at),
                titles=titles[r.id],
                targets=tuple(targets[r.id]),
                dates=dates[r.id],
                valid_to=r.valid_to,
            ),
            published=as_utc(events[r.id]),
            titles=titles[r.id],
            summaries=summaries[r.id],
            thread_id=r.thread_id,
        )
        for r in rows
        if r.id in with_article and titles[r.id]
    ]
    return sorted(out, key=lambda a: (a.published, str(a.item.id)), reverse=True)


def articles_for(
    grower: Grower,
    articles: Sequence[Article],
    receipts: dict[uuid.UUID, Receipt],
    pushed: set[str],
    last_digest_at: datetime | None,
) -> list[Article]:
    """The new articles this grower should hear about (see the module docstring)."""
    out = []
    for a in articles:
        receipt = receipts.get(a.item.id, Receipt())
        if str(a.item.id) in pushed or receipt.dismissed or receipt.notified:
            continue
        if a.item.dates:  # the deadline reminders tell about dated items
            continue
        if last_digest_at is not None and last_digest_at >= a.published:
            continue  # the weekly digest already listed it
        if is_for(a.item, grower.recipient, receipt):
            out.append(a)
    return out


def article_topic(article: Article) -> str:
    """An article's topic: its news thread (Q139) or the item itself."""
    return f"article:{article.thread_id or article.item.id}"


def article_push(grower: Grower, chosen: Sequence[Article], now: datetime) -> Planned:
    lang = grower.lang
    day = india_day(now)
    titles = [texts.pick(a.titles, lang)[:TITLE_MAX] for a in chosen]
    if len(chosen) == 1:
        one = chosen[0]
        title = texts.pick(texts.ARTICLE_ONE, lang).format(title=titles[0])
        body = (one.summaries.get(lang) or one.summaries.get("en") or "")[:SUMMARY_MAX]
        data = {"kind": ARTICLE, "item_id": str(one.item.id)}
        if one.thread_id is not None:
            data["thread_id"] = str(one.thread_id)
    else:
        n = texts.digits(str(len(chosen)), lang)
        title = texts.pick(texts.ARTICLE_MANY, lang).format(n=n)
        body = _lines([f"• {t}" for t in titles], lang)
        data = {"kind": ARTICLE, "items": ",".join(str(a.item.id) for a in chosen[:MAX_IDS])}
    rows = tuple(
        PushNotice(
            owner_id=grower.owner_id,
            kind=ARTICLE,
            subject=str(a.item.id),
            day=day,
            data={"title": t},
        )
        for a, t in zip(chosen, titles, strict=True)
    )
    topics = tuple(dict.fromkeys(article_topic(a) for a in chosen))
    return Planned(grower.owner_id, ARTICLE, title, body, data, rows, pb.ARTICLES, topics)


async def plan_articles(  # noqa: PLR0913 - the run context
    session: AsyncSession,
    settings: Settings,
    growers: dict[uuid.UUID, Grower],
    now: datetime,
    summary: UpdatesSummary,
    budget: pb.Budget,
) -> list[Planned]:
    articles = await recent_articles(session, settings, now)
    if not articles:
        return []
    ids = [a.item.id for a in articles]
    receipts: dict[uuid.UUID, dict[uuid.UUID, Receipt]] = defaultdict(dict)
    stages = ("t7", "t2", "t0", "payment", "window_open")
    for r in await session.scalars(
        select(FeedReceipt).where(
            FeedReceipt.item_id.in_(ids), FeedReceipt.owner_id.in_(list(growers))
        )
    ):
        receipts[r.owner_id][r.item_id] = Receipt(
            dismissed=r.dismissed_at is not None,
            remind=r.remind_requested_at is not None,
            notified={
                s: as_utc(v) for s in stages if (v := getattr(r, f"{s}_notified_at")) is not None
            },
        )
    pushed: dict[uuid.UUID, set[str]] = defaultdict(set)
    for owner_id, subject in await _subjects(
        session, ARTICLE, growers, india_day(now) - timedelta(days=8)
    ):
        pushed[owner_id].add(subject)
    sent = await _sent_today(session, ARTICLE, now)
    out = []
    for grower in growers.values():
        chosen = articles_for(
            grower,
            articles,
            receipts[grower.owner_id],
            pushed[grower.owner_id],
            grower.prefs.last_digest_at,
        )
        if not chosen or not _gate(grower, ARTICLE, now, summary):
            continue
        if sent[(grower.owner_id, None)] >= settings.push_article_daily_max:
            summary.count(summary.skipped, "article_daily_cap")
            continue
        topics = [article_topic(a) for a in chosen]
        again = _repeats(session, budget, grower, pb.ARTICLES, topics, summary)
        if again:
            _park(
                session,
                article_push(grower, [a for a in chosen if article_topic(a) in again], now).rows,
                now,
            )
            chosen = [a for a in chosen if article_topic(a) not in again]
        if chosen:
            out.append(article_push(grower, chosen, now))
    return out


# --- market ----------------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class Series:
    key: SeriesKey
    crop: str
    district: str  # place_key of the source district
    local: bool  # in MARKET_LOCAL_MARKETS


async def market_changes(
    session: AsyncSession, settings: Settings, now: datetime
) -> tuple[list[Series], dict[SeriesKey, PriceChange]]:
    """Every stored series of a priced crop in the window, and the ones that changed."""
    crop_of = {c: crop for crop, names in settings.market_commodities.items() for c in names}
    if not crop_of:
        return [], {}
    today = india_day(now)
    since = today - timedelta(days=settings.market_window_days)
    days: dict[SeriesKey, dict[date, int]] = defaultdict(dict)
    meta: dict[SeriesKey, str] = {}
    query = (
        select(MarketPrice)
        .where(MarketPrice.commodity.in_(list(crop_of)), MarketPrice.day >= since)
        .order_by(MarketPrice.day, MarketPrice.source == MANUAL)
    )
    for row in await session.scalars(query):
        key = SeriesKey(row.market, row.commodity, row.variety, row.grade)
        days[key].setdefault(row.day, row.modal_rs_per_quintal)  # Agmarknet wins on a day
        meta[key] = row.district
    rules = MarketRules.of(settings)
    series = [
        Series(
            key,
            crop_of[key.commodity],
            texts.place_key(meta[key]),
            market_matches(key.market, settings.market_local_markets),
        )
        for key in sorted(days, key=lambda k: (k.market, k.commodity, k.variety, k.grade))
    ]
    changes = {}
    for s in series:
        change = price_change(s.key, days[s.key], today, rules)
        if change is not None:
            changes[s.key] = change
    return series, changes


def followed(grower: Grower, series: Sequence[Series]) -> list[Series]:
    """The grower's mandi series: the crops of their plots; per crop the mandis of their
    district, or the local list when their district has none for that crop."""
    crops = {crop.strip().casefold() for _, _, crop in grower.plots if crop}
    out = []
    for crop in sorted(crops):
        mine = [s for s in series if s.crop == crop]
        district = [s for s in mine if grower.district and s.district == grower.district]
        out += district or [s for s in mine if s.local]
    return out


def market_line(change: PriceChange, crop: str, lang: str, today: date) -> str:
    k = change.key
    variety = texts.variety_name(k.variety, k.commodity, lang)
    name = texts.crop_name(crop, lang) + (f" ({variety})" if variety else "")
    return texts.pick(texts.MARKET_LINE, lang).format(
        mandi=texts.mandi_name(k.market, lang),
        crop=name,
        when=texts.when_word(change.day, today, lang),
        price=texts.digits(texts.indian(change.price), lang),
        rs=texts.signed_rs(change.delta, lang),
        pct=texts.signed_pct(change.pct, lang),
    )


def market_push(
    grower: Grower, changed: Sequence[tuple[Series, PriceChange]], now: datetime
) -> Planned:
    lang, today = grower.lang, india_day(now)
    ordered = sorted(changed, key=lambda sc: (-abs(sc[1].pct), sc[0].key.market))
    body = _lines([market_line(c, s.crop, lang, today) for s, c in ordered], lang)
    rows = tuple(
        PushNotice(
            owner_id=grower.owner_id,
            kind=MARKET,
            subject=c.subject,
            day=today,
            data={
                "market": s.key.market,
                "crop": s.crop,
                "day": c.day.isoformat(),
                "price": c.price,
                "previous": c.previous,
                "previous_day": c.previous_day.isoformat(),
            },
        )
        for s, c in ordered
    )
    data = {"kind": MARKET, "crop": ordered[0][0].crop}
    title = texts.pick(texts.MARKET_TITLE, lang)
    topics = tuple(dict.fromkeys(market_topic(s.crop) for s, _ in ordered))
    return Planned(grower.owner_id, MARKET, title, body, data, rows, pb.MARKET_MOVE, topics)


def market_topic(crop: str) -> str:
    return f"market:{crop}"


async def plan_market(  # noqa: PLR0913 - the run context
    session: AsyncSession,
    settings: Settings,
    growers: dict[uuid.UUID, Grower],
    now: datetime,
    summary: UpdatesSummary,
    budget: pb.Budget,
) -> list[Planned]:
    series, changes = await market_changes(session, settings, now)
    if not changes:
        return []
    pushed = await _subjects(
        session, MARKET, growers, india_day(now) - timedelta(days=settings.market_window_days)
    )
    sent = await _sent_today(session, MARKET, now)
    out = []
    for grower in growers.values():
        changed = [
            (s, changes[s.key])
            for s in followed(grower, series)
            if s.key in changes and (grower.owner_id, changes[s.key].subject) not in pushed
        ]
        if not changed or not _gate(grower, MARKET, now, summary):
            continue
        if sent[(grower.owner_id, None)] >= settings.push_market_daily_max:
            summary.count(summary.skipped, "market_daily_cap")
            continue
        topics = [market_topic(s.crop) for s, _ in changed]
        again = _repeats(session, budget, grower, pb.MARKET_MOVE, topics, summary)
        if again:
            held = [(s, c) for s, c in changed if market_topic(s.crop) in again]
            _park(session, market_push(grower, held, now).rows, now)
            changed = [(s, c) for s, c in changed if market_topic(s.crop) not in again]
        if changed:
            out.append(market_push(grower, changed, now))
    return out


# --- weather ---------------------------------------------------------------------------------


def _values(row: WeatherDaily | PushWeatherSeen) -> DayValues:
    return DayValues(
        row.day, row.rain_prob_pct, row.precip_mm, row.wind_gust_kmh, row.t_max_c, row.t_min_c
    )


async def find_weather_changes(
    session: AsyncSession,
    settings: Settings,
    growers: dict[uuid.UUID, Grower],
    now: datetime,
) -> int:
    """Store each new sudden change of a grower's located plot as a pending notice, then keep
    the compared forecast as "the previous forecast" of the next run. Returns how many."""
    rules = WeatherRules.of(settings)
    today = india_day(now)
    first, last = today - timedelta(days=1), today + timedelta(days=rules.days - 1)
    located = await session.execute(
        select(Plot.id, Plot.owner_id, Plot.centroid_lat, Plot.centroid_lon).where(
            Plot.deleted_at.is_(None),
            Plot.owner_id.in_(list(growers)),
            Plot.centroid_lat.is_not(None),
            Plot.centroid_lon.is_not(None),
        )
    )
    by_cell: dict[Cell, list[tuple[uuid.UUID, uuid.UUID]]] = defaultdict(list)
    for plot_id, owner_id, lat, lon in located.tuples():
        if lat is not None and lon is not None:
            by_cell[cell_for(lat, lon, settings.weather_cell_decimals)].append((plot_id, owner_id))
    if not by_cell:
        return 0
    plot_ids = [p for plots in by_cell.values() for p, _ in plots]
    alerts: dict[uuid.UUID, list[StoredAlert]] = defaultdict(list)
    for plot_id, rule_key, first_day, created in (
        await session.execute(
            select(
                PlotRiskAlert.plot_id,
                PlotRiskAlert.rule_key,
                PlotRiskAlert.first_day,
                PlotRiskAlert.created_at,
            ).where(
                PlotRiskAlert.plot_id.in_(plot_ids),
                (PlotRiskAlert.first_day >= first - timedelta(days=1))
                | (PlotRiskAlert.created_at >= now - timedelta(hours=24)),
            )
        )
    ).tuples():
        alerts[plot_id].append(StoredAlert(rule_key, first_day, as_utc(created)))
    existing = await _subjects(session, WEATHER, growers, first - timedelta(days=1))
    fresh = now - timedelta(hours=settings.push_weather_fresh_hours)
    found = 0
    for cell, plots in sorted(by_cell.items()):
        rows = await session.scalars(
            select(WeatherDaily).where(
                WeatherDaily.cell_lat == cell[0],
                WeatherDaily.cell_lon == cell[1],
                WeatherDaily.day >= first,
                WeatherDaily.day <= last,
            )
        )
        current = {r.day: _values(r) for r in rows if as_utc(r.fetched_at) >= fresh}
        if not current:
            continue
        seen_rows = {
            r.day: r
            for r in await session.scalars(
                select(PushWeatherSeen).where(
                    PushWeatherSeen.cell_lat == cell[0], PushWeatherSeen.cell_lon == cell[1]
                )
            )
        }
        signals = weather_signals(
            current, {d: _values(r) for d, r in seen_rows.items()}, today, rules
        )
        for plot_id, owner_id in plots:
            for signal in new_signals(signals, alerts[plot_id], now, rules):
                subject = signal.subject(plot_id)
                if (owner_id, subject) in existing:
                    continue
                existing.add((owner_id, subject))
                session.add(
                    PushNotice(
                        owner_id=owner_id,
                        kind=WEATHER,
                        subject=subject,
                        plot_id=plot_id,
                        day=signal.day,
                        data=_signal_data(signal),
                        created_at=now,
                    )
                )
                found += 1
        _remember(session, cell, current, seen_rows, today, last, now)
    await session.execute(delete(PushWeatherSeen).where(PushWeatherSeen.day < first))
    await session.commit()
    return found


def _signal_data(signal: WeatherSignal) -> dict[str, Any]:
    return {
        "signal": signal.kind,
        "day": signal.day.isoformat(),
        "value": round(signal.value, 1),
        "before": None if signal.before is None else round(signal.before, 1),
    }


def _remember(  # noqa: PLR0913 - one cell with its run context
    session: AsyncSession,
    cell: Cell,
    current: dict[date, DayValues],
    seen_rows: dict[date, PushWeatherSeen],
    today: date,
    last: date,
    now: datetime,
) -> None:
    for day, v in current.items():
        if not today <= day <= last:
            continue
        row = seen_rows.get(day)
        if row is None:
            row = PushWeatherSeen(cell_lat=cell[0], cell_lon=cell[1], day=day)
            session.add(row)
        row.rain_prob_pct, row.precip_mm, row.wind_gust_kmh = (
            v.rain_prob_pct,
            v.precip_mm,
            v.wind_gust_kmh,
        )
        row.t_max_c, row.t_min_c, row.seen_at = v.t_max_c, v.t_min_c, now


def weather_line(data: dict[str, Any], lang: str, today: date) -> str:
    kind = str(data["signal"])
    day = date.fromisoformat(str(data["day"]))
    value, before = float(data["value"]), data.get("before")
    template = texts.pick(texts.WEATHER_LINES[kind], lang)
    ref = texts.when_word(day - timedelta(days=1), today, lang)
    diff = abs(value - float(before)) if before is not None else 0.0
    return template.format(
        day=texts.when_word(day, today, lang),
        v=texts.number(value, lang),
        d=texts.number(diff, lang),
        ref=ref,
    )


def weather_push(
    grower: Grower,
    pending: Sequence[PushNotice],
    names: dict[uuid.UUID, str],
    now: datetime,
) -> Planned:
    lang, today = grower.lang, india_day(now)
    # The grower's plot order (by name), so the push reads the same on every run.
    known = [pid for pid, _, _ in grower.plots]
    plots = sorted(
        {r.plot_id for r in pending},
        key=lambda p: (known.index(p) if p in known else len(known), str(p)),
    )

    def order(r: PushNotice) -> tuple[int, date, int]:
        return (plots.index(r.plot_id), r.day, SIGNAL_ORDER.index(str(r.data["signal"])))

    # The same change on several plots (one weather cell) is one line naming them all.
    same: dict[str, list[uuid.UUID]] = {}
    for row in sorted(pending, key=order):
        on = same.setdefault(weather_line(row.data, lang, today), [])
        if row.plot_id is not None and row.plot_id not in on:
            on.append(row.plot_id)
    lines = []
    for line, on in same.items():
        named = [names[p] for p in on if names.get(p)]
        lines.append(
            f"{texts.plot_names(named, lang, total=len(on))}: {line}"
            if len(plots) > 1 and named
            else line
        )
    data = {"kind": "weather_change", "plot_id": str(plots[0])}
    title = texts.pick(texts.WEATHER_TITLE, lang)
    topics = tuple(dict.fromkeys(weather_topic(r) for r in sorted(pending, key=order)))
    body = _lines(lines, lang)
    return Planned(
        grower.owner_id, WEATHER, title, body, data, tuple(pending), pb.WEATHER_CHANGE, topics
    )


def weather_topic(row: PushNotice) -> str:
    return f"weather:{row.data['signal']}"


async def plan_weather(  # noqa: PLR0913 - the run context
    session: AsyncSession,
    settings: Settings,
    growers: dict[uuid.UUID, Grower],
    now: datetime,
    summary: UpdatesSummary,
    budget: pb.Budget,
) -> list[Planned]:
    today = india_day(now)
    pending = list(
        await session.scalars(
            select(PushNotice)
            .where(
                PushNotice.kind == WEATHER,
                PushNotice.notified_at.is_(None),
                PushNotice.day >= today,
                PushNotice.created_at >= now - timedelta(hours=PENDING_HOURS),
                PushNotice.owner_id.in_(list(growers)),
            )
            .order_by(PushNotice.day, PushNotice.subject)
        )
    )
    if not pending:
        return []
    sent = await _sent_today(session, WEATHER, now)
    by_owner: dict[uuid.UUID, list[PushNotice]] = defaultdict(list)
    for row in pending:  # a change a run already held back is not planned again
        if not budget.held_since(row.owner_id, weather_topic(row), row.created_at):
            by_owner[row.owner_id].append(row)
    out = []
    for owner_id, rows in by_owner.items():
        grower = growers[owner_id]
        if not _gate(grower, WEATHER, now, summary):
            continue
        open_rows = [
            r for r in rows if sent[(owner_id, r.plot_id)] < settings.push_weather_daily_max
        ]
        if len(open_rows) < len(rows):
            summary.count(summary.skipped, "weather_daily_cap")
        if not open_rows:
            continue
        topics = [weather_topic(r) for r in open_rows]
        again = _repeats(session, budget, grower, pb.WEATHER_CHANGE, topics, summary)
        open_rows = [r for r in open_rows if weather_topic(r) not in again]
        if not open_rows:
            continue
        names = {pid: name for pid, name, _ in grower.plots}
        out.append(weather_push(grower, open_rows, names, now))
    return out


# --- sending ---------------------------------------------------------------------------------


async def _send(
    sender: PushSender, push: Planned, phones: Sequence[str], invalid: set[str]
) -> tuple[int, int]:
    sent = outage = 0
    for token in phones:
        message = PushMessage(token=token, title=push.title, body=push.body, data=dict(push.data))
        try:
            result = await sender.send(message)
        except PushUnavailableError:
            outage += 1
            continue
        if result is SendResult.UNREGISTERED:
            invalid.add(token)
        else:
            sent += 1
    return sent, outage


def _stamp(session: AsyncSession, push: Planned, now: datetime) -> None:
    push_id = uuid.uuid4()
    today = india_day(now)
    for row in push.rows:
        row.notified_at, row.push_id = now, push_id
        if push.kind != WEATHER:
            row.day, row.created_at = today, now
            session.add(row)


async def run_updates(
    session: AsyncSession, sender: PushSender | None, settings: Settings, now: datetime
) -> UpdatesSummary:
    summary = UpdatesSummary()
    if not settings.cron_push_updates:
        summary.skipped_reason = SWITCHED_OFF
        return summary
    if sender is None:
        summary.skipped_reason = NO_SENDER
        return summary
    growers = await _growers(session, settings)
    summary.growers = len(growers)
    if not growers:
        return summary
    if settings.push_weather_change:
        summary.weather_changes_found = await find_weather_changes(session, settings, growers, now)
    budget = await pb.Budget.load(session, pb.BudgetRules.of(settings), now, growers)
    planned: list[Planned] = []
    if settings.push_articles:
        planned += await plan_articles(session, settings, growers, now, summary, budget)
    if settings.push_market:
        planned += await plan_market(session, settings, growers, now, summary, budget)
    if settings.push_weather_change:
        planned += await plan_weather(session, settings, growers, now, summary, budget)
    await _send_planned(session, sender, planned, growers, budget, summary, now)
    await session.commit()
    return summary


async def _send_planned(  # noqa: PLR0913 - the run context
    session: AsyncSession,
    sender: PushSender,
    planned: Sequence[Planned],
    growers: dict[uuid.UUID, Grower],
    budget: pb.Budget,
    summary: UpdatesSummary,
    now: datetime,
) -> None:
    """Send within the shared budget, most important first; drop dead tokens."""
    invalid: set[str] = set()
    for push in sorted(planned, key=lambda p: p.priority):  # stable: most important first
        summary.count(summary.planned, push.kind)
        if not budget.room(push.owner_id, push.priority):
            budget.record(session, push.owner_id, SOURCE, push.priority, push.topics, pb.BUDGET)
            summary.skipped_budget += 1
            if push.kind != WEATHER:  # weather rows are dropped by the logged topics
                _park(session, push.rows, now)
            continue
        phones = [t for t in growers[push.owner_id].tokens if t not in invalid]
        sent, outage = await _send(sender, push, phones, invalid)
        summary.messages += sent
        if sent:
            _stamp(session, push, now)
            summary.count(summary.sent, push.kind)
            budget.record(session, push.owner_id, SOURCE, push.priority, push.topics, pb.SENT)
        elif outage:
            summary.failed += 1
    if invalid:
        await session.execute(delete(PushDevice).where(PushDevice.token.in_(invalid)))
    summary.invalid_tokens = len(invalid)


def exit_code(summary: UpdatesSummary, reporting: bool) -> int:
    if not summary.failed:
        return 0
    report_job_failure("push_updates", reporting, failed=summary.failed)
    return 1


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    reporting = start_job_reporting(settings)
    async with (
        get_sessionmaker()() as session,
        httpx.AsyncClient(timeout=settings.fcm_timeout_seconds) as http,
    ):
        summary = await run_updates(session, fcm_sender(settings, http), settings, utcnow())
    print(summary.to_json())
    return exit_code(summary, reporting)


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
