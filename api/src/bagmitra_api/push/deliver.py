"""Push delivery: send every new stored risk alert to the owner's phones and stamp it.

Runs after the daily weather pull (cron line from deploy.sh once FCM_PROJECT_ID is set;
OPEN_QUESTIONS Q32, runbook docs/runbooks/push-notifications.md):
    python -m bagmitra_api.push.deliver
The text is the
rule's label in the farmer's language (English if missing), so a push says exactly what the
app's weather card says: the risk and what to check, never a chemical.

Only alerts created within `max_age` are sent, so a late first run does not flood phones
with old alerts. An alert is stamped once at least one phone got it; a service outage
leaves it for the next run, and tokens the service reports invalid are deleted. Without a
configured sender (no FCM credentials yet) nothing is sent and nothing is stamped.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from collections import defaultdict
from collections.abc import Sequence
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta

import httpx
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.observability import report_job_failure, start_job_reporting
from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.models import Farmer, PlotRiskAlert, PushDevice
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.push.fcm import fcm_sender
from bagmitra_api.push.sender import PushMessage, PushSender, PushUnavailableError, SendResult
from bagmitra_api.risk.engine import RiskRule, load_rules

NO_SENDER = "no push sender configured (FCM credentials)"
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
    skipped_reason: str | None = None

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


def _text(table: dict[str, str], lang: str) -> str:
    return table.get(lang) or table["en"]


async def run_delivery(
    session: AsyncSession,
    sender: PushSender | None,
    now: datetime,
    *,
    max_age: timedelta = timedelta(hours=48),
    rules: Sequence[RiskRule] | None = None,
) -> DeliverySummary:
    """Send each unsent recent alert to its owner's phones; return what happened."""
    pending = list(
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
    by_key = {r.key: r for r in (rules if rules is not None else load_rules())}
    invalid: set[str] = set()
    for alert in pending:
        rule = by_key.get(alert.rule_key)
        phones = [t for t in tokens.get(alert.owner_id, []) if t not in invalid]
        if rule is None:  # rule removed from rules.json since the pull stored it
            continue
        if not phones:
            summary.no_device += 1
            continue
        lang = language.get(alert.owner_id, "en")
        sent = outage = 0
        for token in phones:
            message = PushMessage(
                token=token,
                title=_text(TITLES, lang),
                body=_text(dict(rule.labels), lang),
                data={
                    "plot_id": str(alert.plot_id),
                    "rule_key": alert.rule_key,
                    "first_day": alert.first_day.isoformat(),
                    **({"action": rule.action} if rule.action else {}),
                },
            )
            try:
                result = await sender.send(message)
            except PushUnavailableError:
                outage += 1
                continue
            if result is SendResult.UNREGISTERED:
                invalid.add(token)
            else:
                sent += 1
        summary.messages += sent
        if sent:
            alert.notified_at = now
            summary.notified += 1
        elif outage:
            summary.failed += 1
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
        summary = await run_delivery(session, fcm_sender(settings, http), utcnow())
    print(summary.to_json())
    return exit_code(summary, reporting)


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
