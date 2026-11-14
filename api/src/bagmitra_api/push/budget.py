"""One push budget per farmer per India day, shared by every push job (owner 2026-11-14:
"notifications must not be excessive; only truly important things", OPEN_QUESTIONS Q157).

Jobs that use it: `push.deliver` (weather risk alerts), `push.updates` (sudden weather change,
market moves, new articles) and `feed.alert_job` (scheme reminders, weekly digest). The
market-link pushes (a new offer, an accepted offer, a closed lot) and the sale-package notice
answer the farmer's or trader's own action at once and are not counted.

Rules (settings, `.env`):
- at most PUSH_DAILY_MAX pushes (default 2) reach a farmer per India day, all jobs together;
- the same topic is not pushed to the same farmer again within PUSH_REPEAT_DAYS (default 3);
- new articles and the weekly digest together at most PUSH_ARTICLE_DAILY_MAX a day (1);
- when a run has more than the budget leaves, the more important go first (PRIORITY order);
  across runs the budget is first come, first served (cron order: deliver 07:07 IST, updates
  08:17 / 14:17 / 20:17, feed reminders 08:47 / 16:47);
- a push held back is not kept for later: it is logged (status budget / repeat) and a later
  run does not plan it again (the app still shows it).

A topic names what a push is about: "risk:<rule key>", "weather:<signal>", "market:<crop>",
"article:<thread or item id>", "feed:<item id>:<stage>", "digest".
"""

from __future__ import annotations

import uuid
from collections import Counter
from collections.abc import Iterable, Sequence
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.base import as_utc
from bagmitra_api.push.models import PushLog

INDIA = ZoneInfo("Asia/Kolkata")
# Priority when the budget is short (owner 2026-11-14), most important first.
DANGER = 1  # weather danger: heavy / untimely rain, hail, heat / cold wave, strong wind
WEATHER_CHANGE = 2  # sudden weather change (push.updates)
ADVISORY = 3  # pest / disease risk advisories (risk rules with "push": "advisory")
SCHEME = 4  # scheme deadline / payment / window-open reminders
MARKET_MOVE = 5  # big mandi price moves
ARTICLES = 6  # new articles and the weekly digest (lowest)
PRIORITY = {"danger": DANGER, "advisory": ADVISORY}  # risk rule "push" class -> priority

SENT = "sent"
BUDGET = "budget"
REPEAT = "repeat"
# How far back a held-back decision is looked up: the longest a candidate can come back
# (a T-7 reminder span of 5 days, the weekly digest).
HELD_DAYS = 8


@dataclass(frozen=True, slots=True)
class BudgetRules:
    daily_max: int = 2
    repeat_days: int = 3
    low_daily_max: int = 1  # ARTICLES priority (new articles + weekly digest)

    @classmethod
    def of(cls, settings: Settings) -> BudgetRules:
        return cls(
            settings.push_daily_max, settings.push_repeat_days, settings.push_article_daily_max
        )


def india_day(now: datetime) -> date:
    return now.astimezone(INDIA).date()


@dataclass
class Budget:
    """What the log says for the farmers of one run, kept current as the run sends."""

    rules: BudgetRules
    now: datetime
    sent: Counter[uuid.UUID] = field(default_factory=Counter)  # pushes sent today
    low: Counter[uuid.UUID] = field(default_factory=Counter)  # ARTICLES pushes sent today
    recent: set[tuple[uuid.UUID, str]] = field(default_factory=set)  # sent in the window
    held: dict[tuple[uuid.UUID, str], datetime] = field(default_factory=dict)  # last held

    @classmethod
    async def load(
        cls,
        session: AsyncSession,
        rules: BudgetRules,
        now: datetime,
        owners: Iterable[uuid.UUID],
    ) -> Budget:
        budget = cls(rules, now)
        ids = list(set(owners))
        if not ids:
            return budget
        since = now - timedelta(days=max(rules.repeat_days, HELD_DAYS))
        rows = await session.scalars(
            select(PushLog).where(PushLog.owner_id.in_(ids), PushLog.created_at >= since)
        )
        today = india_day(now)
        pushes_today: set[tuple[uuid.UUID, uuid.UUID, int]] = set()
        for row in rows:
            at = as_utc(row.created_at)
            key = (row.owner_id, row.topic)
            if row.status == SENT:
                if at >= now - timedelta(days=rules.repeat_days):
                    budget.recent.add(key)
                if row.day == today:
                    pushes_today.add((row.owner_id, row.push_id, row.priority))
            elif key not in budget.held or at > budget.held[key]:
                budget.held[key] = at
        for owner_id, _, priority in pushes_today:
            budget.sent[owner_id] += 1
            if priority == ARTICLES:
                budget.low[owner_id] += 1
        return budget

    def repeated(self, owner_id: uuid.UUID, topic: str) -> bool:
        """Sent to this farmer within PUSH_REPEAT_DAYS."""
        return (owner_id, topic) in self.recent

    def held_since(self, owner_id: uuid.UUID, topic: str, created: datetime | None) -> bool:
        """A run already held this topic back at or after `created` (the candidate's own
        time; None: at any time in the look-back), so it is not planned again."""
        at = self.held.get((owner_id, topic))
        return at is not None and (created is None or at >= as_utc(created))

    def room(self, owner_id: uuid.UUID, priority: int) -> bool:
        if self.sent[owner_id] >= self.rules.daily_max:
            return False
        return priority != ARTICLES or self.low[owner_id] < self.rules.low_daily_max

    def record(  # noqa: PLR0913 - one push with its context
        self,
        session: AsyncSession,
        owner_id: uuid.UUID,
        source: str,
        priority: int,
        topics: Sequence[str],
        status: str,
    ) -> None:
        """Log one push (one row per topic) and count it in this run."""
        push_id, day = uuid.uuid4(), india_day(self.now)
        for topic in dict.fromkeys(t[:160] for t in topics):
            session.add(
                PushLog(
                    owner_id=owner_id,
                    push_id=push_id,
                    day=day,
                    source=source,
                    priority=priority,
                    topic=topic,
                    status=status,
                    created_at=self.now,
                )
            )
            if status == SENT:
                self.recent.add((owner_id, topic))
            else:
                self.held[(owner_id, topic)] = self.now
        if status == SENT:
            self.sent[owner_id] += 1
            if priority == ARTICLES:
                self.low[owner_id] += 1
