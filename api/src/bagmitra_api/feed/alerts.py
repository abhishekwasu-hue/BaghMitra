"""Feed push alerts and the weekly digest (addendum v1.4 §4.8-4.9, G2).

Who: every farmer an item is matched to by the rules in `feed.matching` (an item without
targets is for everyone), plus anyone who pressed "Remind me" on it. A dismissed item sends
nothing more. What: for each published item date (`feed_deadlines`)
- `apply_by` / `window_close`: reminders at T-7, T-2 and T-0 (days before the date, India
  calendar). A run inside a stage's span sends that stage once: 3-7 days left is T-7, 1-2 is
  T-2, the day itself is T-0; a stage that was missed (item published late) is not sent
  afterwards, the next one is;
- `payment` / `window_open`: one push on the day, or up to `EVENT_GRACE_DAYS` later.
Every item + stage is sent at most once (dedupe on `feed_receipts.<stage>_notified_at`).
A withdrawn or expired item cancels whatever it had pending.

Limits (per farmer, `feed_preferences`, defaults when no row): quiet hours (a push due inside
them is held until the quiet time ends; the job sends it on its first run after that),
category opt-out (deadline / payment / window_open), and a hard weekly cap on alert pushes
counted over the rolling 7 days, the most urgent first (OPEN_QUESTIONS QG4: T-0 does not
exceed the cap). The weekly digest (new items matched to the farmer in the last 7 days) is
its own switch, sent at most once in 7 days and not counted in the cap.

Text: the item title, the date line ("Last date: ..."), and the footer "Check the official
GR/portal before acting.", in the farmer's language (English when missing). Never a promise
("you will receive"): dates only. Sending uses the `PushSender` protocol like push/deliver.py;
without a sender the job only plans and reports `no push sender configured`.
"""

from __future__ import annotations

import json
import uuid
from collections import Counter, defaultdict
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import asdict, dataclass, field
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import delete, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.base import as_utc
from bagmitra_api.db.models import Farmer, Plot, PushDevice
from bagmitra_api.feed.matching import Profile, Target, profile_from, target_matches
from bagmitra_api.feed.models import (
    LANGS,
    FeedDeadline,
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedPreferences,
    FeedReceipt,
)
from bagmitra_api.feed.texts import FOOTER
from bagmitra_api.push.deliver import NO_SENDER
from bagmitra_api.push.sender import PushMessage, PushSender, PushUnavailableError, SendResult

INDIA = ZoneInfo("Asia/Kolkata")
WEEK = timedelta(days=7)
MAX_WEEKLY_CAP = 21
# A payment / window-open push still goes out this many days after the date (a missed run).
EVENT_GRACE_DAYS = 2
DIGEST_MAX_TITLES = 5
TITLE_MAX = 200
DIGEST = "digest"
STAGES = ("t0", "t2", "t7", "payment", "window_open")  # most urgent first
REMINDER_KINDS = ("apply_by", "window_close")
EVENT_KINDS = ("payment", "window_open")
# (lowest days left, highest days left, stage) for the reminder kinds.
REMINDER_SPANS = ((0, 0, "t0"), (1, 2, "t2"), (3, 7, "t7"))
CATEGORY = {"t7": "deadline", "t2": "deadline", "t0": "deadline"} | {k: k for k in EVENT_KINDS}

DATE_LINE = {
    "apply_by": {
        "en": "Last date: {date}",
        "mr": "शेवटची तारीख: {date}",
        "hi": "अंतिम तिथि: {date}",
    },
    "window_close": {
        "en": "Last date: {date}",
        "mr": "शेवटची तारीख: {date}",
        "hi": "अंतिम तिथि: {date}",
    },
    "payment": {
        "en": "Payment release date: {date}",
        "mr": "रक्कम वितरणाची तारीख: {date}",
        "hi": "भुगतान जारी होने की तिथि: {date}",
    },
    "window_open": {
        "en": "Applications open from: {date}",
        "mr": "अर्ज सुरू होण्याची तारीख: {date}",
        "hi": "आवेदन शुरू होने की तिथि: {date}",
    },
}
DIGEST_TITLE = {
    "en": "Sarkari Sandesh: {n} new this week",
    "mr": "सरकारी संदेश: या आठवड्यात {n} नवीन",
    "hi": "सरकारी संदेश: इस सप्ताह {n} नए",
}
DIGEST_MORE = {"en": "…and {n} more", "mr": "…आणखी {n}", "hi": "…और {n}"}


@dataclass(frozen=True, slots=True)
class Prefs:
    quiet_start: time = time(21, 0)
    quiet_end: time = time(7, 0)
    weekly_cap: int = 3
    opted_out: frozenset[str] = frozenset()
    digest_weekly: bool = True
    last_digest_at: datetime | None = None


DEFAULT_PREFS = Prefs()


@dataclass(frozen=True, slots=True)
class Item:
    id: uuid.UUID
    type: str
    status: str
    published_at: datetime
    titles: Mapping[str, str]
    targets: tuple[Target, ...] = ()
    dates: Mapping[str, date] = field(default_factory=dict)  # feed_deadlines kind -> date
    valid_to: date | None = None


@dataclass(frozen=True, slots=True)
class Receipt:
    dismissed: bool = False
    remind: bool = False
    notified: Mapping[str, datetime] = field(default_factory=dict)  # stage -> sent at


NO_RECEIPT = Receipt()


@dataclass(frozen=True, slots=True)
class Recipient:
    owner_id: uuid.UUID
    lang: str
    profile: Profile
    prefs: Prefs = DEFAULT_PREFS


@dataclass(frozen=True, slots=True)
class Push:
    owner_id: uuid.UUID
    item_id: uuid.UUID | None  # None for the digest
    stage: str
    title: str
    body: str
    send_at: datetime
    data: Mapping[str, str]


@dataclass
class Plan:
    pushes: list[Push] = field(default_factory=list)
    skipped: Counter[str] = field(default_factory=Counter)


def language(code: str | None) -> str:
    """The farmer's language among the feed languages; English when unknown or missing."""
    short = (code or "").strip()[:2].lower()
    return short if short in LANGS else "en"


def _pick(table: Mapping[str, str], lang: str) -> str:
    for key in (lang, "en", "mr", "hi"):
        if key in table:
            return table[key]
    return ""


def in_quiet(local: time, start: time, end: time) -> bool:
    """Start inclusive, end exclusive; a window may cross midnight; start == end: none."""
    if start == end:
        return False
    if start < end:
        return start <= local < end
    return local >= start or local < end


def send_time(now: datetime, prefs: Prefs) -> datetime:
    """`now`, or the end of the quiet time `now` falls in (UTC)."""
    local = now.astimezone(INDIA)
    if not in_quiet(local.time().replace(tzinfo=None), prefs.quiet_start, prefs.quiet_end):
        return now
    end = datetime.combine(local.date(), prefs.quiet_end, INDIA)
    if end <= local:
        end += timedelta(days=1)
    return end.astimezone(UTC)


def stages_due(item: Item, today: date) -> list[tuple[str, str, date]]:
    """(stage, kind, date) the item calls for today: at most one reminder (the nearest
    apply_by / window_close date in a stage span) plus each payment / window-open event."""
    out: list[tuple[str, str, date]] = []
    reminders = sorted(
        (due, kind) for kind, due in item.dates.items() if kind in REMINDER_KINDS and due >= today
    )
    for due, kind in reminders:
        left = (due - today).days
        stage = next((s for lo, hi, s in REMINDER_SPANS if lo <= left <= hi), None)
        if stage is not None:
            out.append((stage, kind, due))
            break
    for kind in EVENT_KINDS:
        on = item.dates.get(kind)
        if on is not None and 0 <= (today - on).days <= EVENT_GRACE_DAYS:
            out.append((kind, kind, on))
    return out


def is_live(item: Item, today: date) -> bool:
    """Published, validity not ended, and (for a scheme) the application date not passed:
    the same rule as the feed list, so nothing expired is pushed."""
    if item.status != "published":
        return False
    if item.valid_to is not None and item.valid_to < today:
        return False
    apply_by = item.dates.get("apply_by")
    return not (item.type == "scheme" and apply_by is not None and apply_by < today)


def is_for(item: Item, recipient: Recipient, receipt: Receipt) -> bool:
    if receipt.remind or not item.targets:
        return True
    return any(target_matches(t, recipient.profile) for t in item.targets)


def _date(value: date) -> str:
    return value.strftime("%d/%m/%Y")


def alert_text(item: Item, kind: str, due: date, lang: str) -> tuple[str, str]:
    title = _pick(item.titles, lang)[:TITLE_MAX]
    line = _pick(DATE_LINE[kind], lang).format(date=_date(due))
    return title, f"{line}\n{_pick(FOOTER, lang)}"


def plan_alerts(
    recipient: Recipient,
    items: Iterable[Item],
    receipts: Mapping[uuid.UUID, Receipt],
    now: datetime,
    *,
    sent_last_week: int,
) -> Plan:
    """The alert pushes one farmer should get now, most urgent first, within the cap."""
    today = now.astimezone(INDIA).date()
    prefs = recipient.prefs
    plan = Plan()
    candidates: list[tuple[date, int, Item, str, str]] = []
    for item in items:
        receipt = receipts.get(item.id, NO_RECEIPT)
        if not is_for(item, recipient, receipt):
            continue
        for stage, kind, due in stages_due(item, today):
            if stage in receipt.notified:
                plan.skipped["duplicate"] += 1
            elif not is_live(item, today):
                plan.skipped["cancelled"] += 1
            elif receipt.dismissed:
                plan.skipped["dismissed"] += 1
            elif CATEGORY[stage] in prefs.opted_out:
                plan.skipped["opted_out"] += 1
            else:
                candidates.append((due, STAGES.index(stage), item, stage, kind))
    budget = prefs.weekly_cap - sent_last_week
    at = send_time(now, prefs)
    for due, _, item, stage, kind in sorted(candidates, key=lambda c: (c[0], c[1], str(c[2].id))):
        if budget <= 0:
            plan.skipped["weekly_cap"] += 1
            continue
        budget -= 1
        title, body = alert_text(item, kind, due, recipient.lang)
        plan.pushes.append(
            Push(
                owner_id=recipient.owner_id,
                item_id=item.id,
                stage=stage,
                title=title,
                body=body,
                send_at=at,
                data={"kind": "feed_alert", "item_id": str(item.id), "stage": stage},
            )
        )
    return plan


def plan_digest(
    recipient: Recipient,
    items: Iterable[Item],
    receipts: Mapping[uuid.UUID, Receipt],
    now: datetime,
) -> Push | None:
    """New items for the farmer published in the last 7 days, newest first; None when the
    digest is off, was sent less than 7 days ago, or there is nothing new."""
    prefs = recipient.prefs
    if not prefs.digest_weekly:
        return None
    if prefs.last_digest_at is not None and now - prefs.last_digest_at < WEEK:
        return None
    today = now.astimezone(INDIA).date()
    new = sorted(
        (
            item
            for item in items
            if now - WEEK < item.published_at <= now
            and is_live(item, today)
            and not receipts.get(item.id, NO_RECEIPT).dismissed
            and is_for(item, recipient, receipts.get(item.id, NO_RECEIPT))
        ),
        key=lambda i: (i.published_at, str(i.id)),
        reverse=True,
    )
    if not new:
        return None
    lang = recipient.lang
    lines = [f"• {_pick(i.titles, lang)[:TITLE_MAX]}" for i in new[:DIGEST_MAX_TITLES]]
    if len(new) > DIGEST_MAX_TITLES:
        lines.append(_pick(DIGEST_MORE, lang).format(n=len(new) - DIGEST_MAX_TITLES))
    lines.append(_pick(FOOTER, lang))
    return Push(
        owner_id=recipient.owner_id,
        item_id=None,
        stage=DIGEST,
        title=_pick(DIGEST_TITLE, lang).format(n=len(new)),
        body="\n".join(lines),
        send_at=send_time(now, prefs),
        data={"kind": "feed_digest", "items": ",".join(str(i.id) for i in new)},
    )


# --- the job: load, plan, send, stamp -------------------------------------------------------


@dataclass
class AlertSummary:
    farmers: int = 0
    items: int = 0
    planned: int = 0
    digests_planned: int = 0
    deferred_quiet: int = 0
    sent: int = 0
    digests_sent: int = 0
    messages: int = 0
    failed: int = 0
    invalid_tokens: int = 0
    no_device: int = 0
    skipped: dict[str, int] = field(default_factory=dict)
    skipped_reason: str | None = None

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


def _stage_times(row: FeedReceipt) -> dict[str, datetime]:
    out = {}
    for stage in STAGES:
        value = getattr(row, f"{stage}_notified_at")
        if value is not None:
            out[stage] = as_utc(value)
    return out


def _prefs(row: FeedPreferences | None) -> Prefs:
    if row is None:
        return DEFAULT_PREFS
    return Prefs(
        quiet_start=row.quiet_start,
        quiet_end=row.quiet_end,
        weekly_cap=row.weekly_cap,
        opted_out=frozenset(row.opted_out),
        digest_weekly=row.digest_weekly,
        last_digest_at=as_utc(row.last_digest_at) if row.last_digest_at else None,
    )


async def _load_items(session: AsyncSession, now: datetime) -> list[Item]:
    """Items with a date near today (published or withdrawn: a withdrawn one is reported as
    cancelled) and items published in the last 7 days (for the digest)."""
    today = now.astimezone(INDIA).date()
    dated = (
        select(FeedDeadline.item_id)
        .join(FeedItem, FeedItem.id == FeedDeadline.item_id)
        .where(
            FeedItem.status.in_(("published", "withdrawn")),
            FeedDeadline.due_date >= today - timedelta(days=EVENT_GRACE_DAYS),
            FeedDeadline.due_date <= today + timedelta(days=REMINDER_SPANS[-1][1]),
        )
    )
    rows = list(
        await session.scalars(
            select(FeedItem).where(
                or_(
                    FeedItem.id.in_(dated),
                    (FeedItem.status == "published") & (FeedItem.published_at > now - WEEK),
                )
            )
        )
    )
    ids = [r.id for r in rows]
    titles: dict[uuid.UUID, dict[str, str]] = defaultdict(dict)
    for t in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id.in_(ids))):
        titles[t.item_id][t.lang] = t.title
    targets: dict[uuid.UUID, list[Target]] = defaultdict(list)
    for g in await session.scalars(select(FeedItemTarget).where(FeedItemTarget.item_id.in_(ids))):
        targets[g.item_id].append(Target(g.district, g.crop, g.min_ha, g.max_ha))
    dates: dict[uuid.UUID, dict[str, date]] = defaultdict(dict)
    for d in await session.scalars(select(FeedDeadline).where(FeedDeadline.item_id.in_(ids))):
        dates[d.item_id][d.kind] = d.due_date
    return [
        Item(
            id=r.id,
            type=r.type,
            status=r.status,
            published_at=as_utc(r.published_at),
            titles=titles[r.id],
            targets=tuple(targets[r.id]),
            dates=dates[r.id],
            valid_to=r.valid_to,
        )
        for r in rows
        if titles[r.id]
    ]


async def _recipients(session: AsyncSession) -> list[Recipient]:
    plots: dict[uuid.UUID, list[tuple[str, float | None]]] = defaultdict(list)
    for owner, crop, area in (
        await session.execute(
            select(Plot.owner_id, Plot.crop, Plot.area_sq_m).where(Plot.deleted_at.is_(None))
        )
    ).tuples():
        plots[owner].append((crop, area))
    prefs = {p.owner_id: p for p in await session.scalars(select(FeedPreferences))}
    farmers = (
        await session.execute(
            select(Farmer.id, Farmer.language, Farmer.district).order_by(Farmer.id)
        )
    ).tuples()
    return [
        Recipient(fid, language(lang), profile_from(district, plots[fid]), _prefs(prefs.get(fid)))
        for fid, lang, district in farmers
    ]


def _sent_in_week(rows: Iterable[FeedReceipt], now: datetime) -> Counter[uuid.UUID]:
    count: Counter[uuid.UUID] = Counter()
    for row in rows:
        count[row.owner_id] += sum(1 for at in _stage_times(row).values() if now - WEEK < at <= now)
    return count


async def _send(
    sender: PushSender, push: Push, phones: Sequence[str], invalid: set[str]
) -> tuple[int, int]:
    """(phones reached, phones in outage); unregistered tokens go into `invalid`."""
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


@dataclass
class _Planned:
    pushes: list[Push]
    receipts: dict[tuple[uuid.UUID, uuid.UUID], FeedReceipt]


async def _plan_all(session: AsyncSession, now: datetime, summary: AlertSummary) -> _Planned:
    items = await _load_items(session, now)
    recipients = await _recipients(session)
    stage_columns = [getattr(FeedReceipt, f"{stage}_notified_at") for stage in STAGES]
    receipt_rows = list(
        await session.scalars(
            select(FeedReceipt).where(
                or_(
                    FeedReceipt.item_id.in_([i.id for i in items]),
                    *[column > now - WEEK for column in stage_columns],
                )
            )
        )
    )
    receipts: dict[uuid.UUID, dict[uuid.UUID, Receipt]] = defaultdict(dict)
    for r in receipt_rows:
        receipts[r.owner_id][r.item_id] = Receipt(
            dismissed=r.dismissed_at is not None,
            remind=r.remind_requested_at is not None,
            notified=_stage_times(r),
        )
    sent_week = _sent_in_week(receipt_rows, now)
    summary.farmers, summary.items = len(recipients), len(items)
    skipped: Counter[str] = Counter()
    pushes: list[Push] = []
    for recipient in recipients:
        mine = receipts.get(recipient.owner_id, {})
        plan = plan_alerts(
            recipient, items, mine, now, sent_last_week=sent_week[recipient.owner_id]
        )
        skipped += plan.skipped
        pushes += plan.pushes
        digest = plan_digest(recipient, items, mine, now)
        if digest is not None:
            pushes.append(digest)
            summary.digests_planned += 1
    summary.planned = len(pushes) - summary.digests_planned
    summary.skipped = dict(sorted(skipped.items()))
    return _Planned(pushes, {(r.owner_id, r.item_id): r for r in receipt_rows})


async def _stamp(
    session: AsyncSession,
    push: Push,
    planned: _Planned,
    prefs_rows: dict[uuid.UUID, FeedPreferences],
    now: datetime,
) -> None:
    """Record the sent push: the digest time, or the item + stage (never sent again)."""
    if push.item_id is None:
        row = prefs_rows.get(push.owner_id)
        if row is None:
            row = prefs_rows[push.owner_id] = FeedPreferences(owner_id=push.owner_id)
            session.add(row)
        row.last_digest_at = now
        return
    key = (push.owner_id, push.item_id)
    receipt = planned.receipts.get(key)
    if receipt is None:
        receipt = planned.receipts[key] = FeedReceipt(
            id=uuid.uuid4(), owner_id=push.owner_id, item_id=push.item_id
        )
        session.add(receipt)
    setattr(receipt, f"{push.stage}_notified_at", now)


async def run_alerts(
    session: AsyncSession, sender: PushSender | None, now: datetime
) -> AlertSummary:
    """Plan every farmer's alerts and digest; send those due now through `sender` and stamp
    them. Without a sender nothing is sent or stamped."""
    summary = AlertSummary()
    planned = await _plan_all(session, now, summary)
    if sender is None:
        summary.skipped_reason = NO_SENDER
        return summary
    owners = {p.owner_id for p in planned.pushes}
    tokens: dict[uuid.UUID, list[str]] = defaultdict(list)
    for owner_id, token in (
        await session.execute(
            select(PushDevice.owner_id, PushDevice.token)
            .where(PushDevice.owner_id.in_(owners))
            .order_by(PushDevice.token)
        )
    ).tuples():
        tokens[owner_id].append(token)
    prefs_rows = {
        p.owner_id: p
        for p in await session.scalars(
            select(FeedPreferences).where(FeedPreferences.owner_id.in_(owners))
        )
    }
    invalid: set[str] = set()
    for push in planned.pushes:
        if push.send_at > now:
            summary.deferred_quiet += 1
            continue
        phones = [t for t in tokens.get(push.owner_id, []) if t not in invalid]
        if not phones:
            summary.no_device += 1
            continue
        sent, outage = await _send(sender, push, phones, invalid)
        summary.messages += sent
        if not sent:
            summary.failed += 1 if outage else 0
            continue
        await _stamp(session, push, planned, prefs_rows, now)
        if push.item_id is None:
            summary.digests_sent += 1
        else:
            summary.sent += 1
    if invalid:
        await session.execute(delete(PushDevice).where(PushDevice.token.in_(invalid)))
    summary.invalid_tokens = len(invalid)
    await session.commit()
    return summary
