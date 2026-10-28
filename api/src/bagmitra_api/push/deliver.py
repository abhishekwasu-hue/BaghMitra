"""Push delivery: send every new stored risk alert to the owner's phones and stamp it.

Meant to run right after the daily weather pull; it gets a command and a cron line once an
FCM sender exists (OPEN_QUESTIONS Q32, runbook: docs/runbooks/weather-pull.md). The text is the
rule's label in the farmer's language (English if missing), so a push says exactly what the
app's weather card says: the risk and what to check, never a chemical.

Only alerts created within `max_age` are sent, so a late first run does not flood phones
with old alerts. An alert is stamped once at least one phone got it; a service outage
leaves it for the next run, and tokens the service reports invalid are deleted. Without a
configured sender (no FCM credentials yet) nothing is sent and nothing is stamped.
"""

from __future__ import annotations

import json
import uuid
from collections import defaultdict
from collections.abc import Sequence
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.models import Farmer, PlotRiskAlert, PushDevice
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
