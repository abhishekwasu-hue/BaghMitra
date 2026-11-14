"""Push delivery: send every new stored risk alert to the owner's phones and stamp it.

Runs after the daily weather pull (cron line from deploy.sh once FCM_PROJECT_ID is set;
OPEN_QUESTIONS Q32, runbook docs/runbooks/push-notifications.md):
    python -m bagmitra_api.push.deliver
The text is the rule's label in the farmer's language (English if missing), so a push says
exactly what the app's weather card says: the risk and what to check, never a chemical.

One message per farmer and rule: when the same rule fired on several plots of one farmer
(owner 2026-11-14: two identical pushes for two plots), one push names the plots after the
label, "… (बाग: Sharayu farm, बाग १)" (at most three names, then "+N"); its data carries the
first plot, the rule and the earliest first day, so a tap opens as before.

Shared daily budget (push/budget.py, OPEN_QUESTIONS Q157): weather danger rules ("push":
"danger" in rules.json) go first, pest / disease advisories third; a rule pushed to the farmer
within PUSH_REPEAT_DAYS is not pushed again, and a push over PUSH_DAILY_MAX is not sent. Such
alerts stay in the app and are not planned again.

Only alerts created within `max_age` are sent, so a late first run does not flood phones
with old alerts. An alert is stamped once at least one phone got its message; a service
outage leaves it for the next run, and tokens the service reports invalid are deleted.
Without a configured sender (no FCM credentials yet) nothing is sent and nothing is stamped.

Summary: `alerts` = pending alerts read, `notified` = alerts stamped, `messages` = messages a
phone accepted (one per phone per push), `failed` / `no_device` = alerts left unsent for an
outage / with no phone, `skipped_budget` / `skipped_repeat` = pushes held back.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from collections import defaultdict
from collections.abc import Sequence
from dataclasses import asdict, dataclass, replace
from datetime import datetime, timedelta

import httpx
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.observability import report_job_failure, start_job_reporting
from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.models import Farmer, Plot, PlotRiskAlert, PushDevice
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.push import budget as pb
from bagmitra_api.push import texts
from bagmitra_api.push.fcm import fcm_sender
from bagmitra_api.push.sender import PushMessage, PushSender, PushUnavailableError, SendResult
from bagmitra_api.risk.engine import RiskRule, load_rules

NO_SENDER = "no push sender configured (FCM credentials)"
SOURCE = "deliver"
TITLES = {
    "en": "BagMitra weather alert",
    "mr": "बागमित्र हवामान सूचना",
    "hi": "बागमित्र मौसम सूचना",
}


@dataclass
class DeliverySummary:
    alerts: int = 0
    notified: int = 0
    messages: int = 0
    failed: int = 0
    invalid_tokens: int = 0
    no_device: int = 0
    skipped_budget: int = 0
    skipped_repeat: int = 0
    skipped_reason: str | None = None

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


def _text(table: dict[str, str], lang: str) -> str:
    return table.get(lang) or table["en"]


def topic(rule_key: str) -> str:
    return f"risk:{rule_key}"


def priority(rule: RiskRule) -> int:
    return pb.PRIORITY.get(rule.push, pb.ADVISORY)


def alert_body(
    rule: RiskRule, plots: Sequence[uuid.UUID], names: dict[uuid.UUID, str], lang: str
) -> str:
    """The rule's label; with several plots, their names after it."""
    body = _text(dict(rule.labels), lang)
    named = [names[p] for p in plots if names.get(p)]
    if len(plots) > 1 and named:  # a plot without a stored name counts in "+N"
        listed = texts.plot_names(named, lang, total=len(plots))
        body += _text(texts.PLOTS_SUFFIX, lang).format(names=listed)
    return body


async def send_to_phones(
    sender: PushSender, phones: Sequence[str], message: PushMessage, invalid: set[str]
) -> tuple[int, int]:
    """`message` to each phone: (phones reached, phones in outage); unregistered tokens go
    into `invalid`."""
    sent = outage = 0
    for token in phones:
        try:
            result = await sender.send(replace(message, token=token, data=dict(message.data)))
        except PushUnavailableError:
            outage += 1
            continue
        if result is SendResult.UNREGISTERED:
            invalid.add(token)
        else:
            sent += 1
    return sent, outage


async def _pending(session: AsyncSession, now: datetime, max_age: timedelta) -> list[PlotRiskAlert]:
    return list(
        (
            await session.scalars(
                select(PlotRiskAlert)
                .where(
                    PlotRiskAlert.notified_at.is_(None),
                    PlotRiskAlert.created_at >= now - max_age,
                )
                .order_by(PlotRiskAlert.created_at, PlotRiskAlert.id)
            )
        ).all()
    )


async def run_delivery(  # noqa: PLR0913 - the job's context
    session: AsyncSession,
    sender: PushSender | None,
    now: datetime,
    *,
    max_age: timedelta = timedelta(hours=48),
    rules: Sequence[RiskRule] | None = None,
    budget_rules: pb.BudgetRules | None = None,
) -> DeliverySummary:
    """Send each unsent recent alert to its owner's phones; return what happened."""
    pending = await _pending(session, now, max_age)
    summary = DeliverySummary(alerts=len(pending))
    if sender is None:
        summary.skipped_reason = NO_SENDER
        return summary
    owners = {a.owner_id for a in pending}
    language = dict(
        (await session.execute(select(Farmer.id, Farmer.language).where(Farmer.id.in_(owners))))
        .tuples()
        .all()
    )
    tokens: dict[uuid.UUID, list[str]] = defaultdict(list)
    for owner_id, token in (
        await session.execute(
            select(PushDevice.owner_id, PushDevice.token)
            .where(PushDevice.owner_id.in_(owners))
            .order_by(PushDevice.token)
        )
    ).tuples():
        tokens[owner_id].append(token)
    names = dict(
        (
            await session.execute(
                select(Plot.id, Plot.name).where(Plot.id.in_({a.plot_id for a in pending}))
            )
        )
        .tuples()
        .all()
    )
    budget = await pb.Budget.load(session, budget_rules or pb.BudgetRules(), now, owners)
    by_key = {r.key: r for r in (rules if rules is not None else load_rules())}
    # One message per farmer and rule; alerts a run already held back are not planned again.
    groups: dict[tuple[uuid.UUID, str], list[PlotRiskAlert]] = defaultdict(list)
    for alert in pending:
        if alert.rule_key in by_key and not budget.held_since(
            alert.owner_id, topic(alert.rule_key), alert.created_at
        ):
            groups[(alert.owner_id, alert.rule_key)].append(alert)
    ordered = sorted(groups.items(), key=lambda g: priority(by_key[g[0][1]]))  # stable
    invalid: set[str] = set()
    for (owner_id, rule_key), alerts in ordered:
        rule = by_key[rule_key]
        phones = [t for t in tokens.get(owner_id, []) if t not in invalid]
        if not phones:
            summary.no_device += len(alerts)
            continue
        rank, topics = priority(rule), [topic(rule_key)]
        if budget.repeated(owner_id, topics[0]):
            budget.record(session, owner_id, SOURCE, rank, topics, pb.REPEAT)
            summary.skipped_repeat += 1
            continue
        if not budget.room(owner_id, rank):
            budget.record(session, owner_id, SOURCE, rank, topics, pb.BUDGET)
            summary.skipped_budget += 1
            continue
        lang = language.get(owner_id, "en")
        plots = list(dict.fromkeys(a.plot_id for a in alerts))
        data = {
            "plot_id": str(plots[0]),
            "rule_key": rule_key,
            "first_day": min(a.first_day for a in alerts).isoformat(),
            **({"action": rule.action} if rule.action else {}),
        }
        body = alert_body(rule, plots, names, lang)
        message = PushMessage(token="", title=_text(TITLES, lang), body=body, data=data)
        sent, outage = await send_to_phones(sender, phones, message, invalid)
        summary.messages += sent
        if sent:
            for alert in alerts:
                alert.notified_at = now
            summary.notified += len(alerts)
            budget.record(session, owner_id, SOURCE, rank, topics, pb.SENT)
        elif outage:
            summary.failed += len(alerts)
    if invalid:
        await session.execute(delete(PushDevice).where(PushDevice.token.in_(invalid)))
    summary.invalid_tokens = len(invalid)
    await session.commit()
    return summary


def exit_code(summary: DeliverySummary, reporting: bool) -> int:
    """1 when alerts stayed unsent because the push service failed (BG-05 style notice)."""
    if not summary.failed:
        return 0
    report_job_failure("push_deliver", reporting, alerts=summary.alerts, failed=summary.failed)
    return 1


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    reporting = start_job_reporting(settings)
    async with (
        get_sessionmaker()() as session,
        httpx.AsyncClient(timeout=settings.fcm_timeout_seconds) as http,
    ):
        summary = await run_delivery(
            session,
            fcm_sender(settings, http),
            utcnow(),
            budget_rules=pb.BudgetRules.of(settings),
        )
    print(summary.to_json())
    return exit_code(summary, reporting)


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
