"""Daily Play reconciliation (billing addendum §2.4). Runbook: docs/runbooks/billing-play.md.

1. Voided purchases (safety net for missed notifications): `purchases.voidedpurchases.list` for
   the last 30 days (Play's limit); a voided token we hold (matched by its hash) becomes REVOKED,
   once per order id (`billing_events.notification_id = voided:<orderId>`).
2. Drift: Play rows still ACTIVE / IN_GRACE_PERIOD a day after their end, or PENDING / ON_HOLD
   for more than 3 days. Tokens are stored only as hashes (ADR 0008, OPEN_QUESTIONS Q120), so
   the job cannot re-ask Play itself; it counts and logs them (access already ends at the end
   date, compute_entitlements), and the app re-sends its tokens on every start.

Does nothing while Play is not set up. Two runs never overlap on Postgres (advisory lock, pattern
of market_link/recheck_job.py). Prints a JSON summary. Cron (deploy/deploy.sh, once
PLAY_PACKAGE_NAME is set): python -m bagmitra_api.billing.reconcile_job
"""

from __future__ import annotations

import asyncio
import json
import uuid
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta

import httpx
import structlog
from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.models import BillingEvent, Subscription
from bagmitra_api.billing.play import GooglePlayPublisher, PlayError, PlayPublisher, play_account
from bagmitra_api.billing.purchases import token_hash
from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.market_link.recheck_job import recheck_lock

log = structlog.get_logger(__name__)

RECONCILE_LOCK_KEY = 0x6261_676D_6269_6C31  # "bagmbil1"
LATE_END = timedelta(days=1)
STUCK = timedelta(days=3)
SKIPPED_NOT_SET_UP = "Google Play is not set up (PLAY_PACKAGE_NAME, PLAY_SERVICE_ACCOUNT_B64)"
SKIPPED_LOCKED = "another reconciliation run is running"


@dataclass
class ReconcileSummary:
    revoked: int = 0
    drift: int = 0
    skipped_reason: str | None = None
    play_error: str | None = None

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


async def revoke_voided(
    session: AsyncSession, play: PlayPublisher, summary: ReconcileSummary
) -> None:
    for voided in await play.list_voided():
        token, order = voided.get("purchaseToken"), voided.get("orderId")
        if not token:
            continue
        row = await session.scalar(
            select(Subscription).where(Subscription.purchase_token_hash == token_hash(str(token)))
        )
        if row is None or row.state == "REVOKED":  # already ended (e.g. by RTDN), audit L9
            continue
        key = f"voided:{order or token_hash(str(token))}"
        if await session.scalar(select(BillingEvent.id).where(BillingEvent.notification_id == key)):
            continue
        row.state = "REVOKED"
        session.add(
            BillingEvent(
                id=uuid.uuid4(),
                subscription_id=row.id,
                provider="google_play",
                event_type="voided_poll",
                notification_id=key,
                payload={
                    "reason": voided.get("voidedReason"),
                    "source": voided.get("voidedSource"),
                },
            )
        )
        summary.revoked += 1


async def count_drift(session: AsyncSession, now: datetime) -> int:
    late = and_(
        Subscription.state.in_(("ACTIVE", "IN_GRACE_PERIOD")),
        func.coalesce(Subscription.grace_until, Subscription.period_end) < now - LATE_END,
    )
    stuck = and_(
        Subscription.state.in_(("PENDING", "ON_HOLD")),
        func.coalesce(Subscription.last_verified_at, Subscription.updated_at) < now - STUCK,
    )
    query = select(Subscription.id).where(Subscription.provider == "google_play", or_(late, stuck))
    ids = list(await session.scalars(query))
    for row_id in ids:
        log.warning("billing_drift", subscription_id=str(row_id))
    return len(ids)


async def run_reconcile(
    session: AsyncSession, play: PlayPublisher | None, now: datetime
) -> ReconcileSummary:
    summary = ReconcileSummary()
    if play is None:
        summary.skipped_reason = SKIPPED_NOT_SET_UP
        return summary
    try:
        await revoke_voided(session, play, summary)
    except PlayError as exc:  # the drift list still runs; the next day's poll covers the gap
        summary.play_error = str(exc)
    summary.drift = await count_drift(session, now)
    await session.commit()
    return summary


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    maker = get_sessionmaker()
    engine = maker.kw["bind"]
    account = play_account(settings)
    async with httpx.AsyncClient(timeout=settings.play_timeout_seconds) as http:
        play = GooglePlayPublisher(http, settings=settings, account=account) if account else None
        async with recheck_lock(engine, RECONCILE_LOCK_KEY) as held, maker() as session:
            if held:
                summary = await run_reconcile(session, play, utcnow())
            else:
                summary = ReconcileSummary(skipped_reason=SKIPPED_LOCKED)
    await engine.dispose()
    print(summary.to_json())
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
