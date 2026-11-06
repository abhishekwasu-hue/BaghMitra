"""Feed alert run (addendum v1.4 G2): deadline / payment / window-open pushes and the weekly
digest for every farmer, then a JSON summary (rules: `feed/alerts.py`).

Pushes go out through FCM once its credentials are set (FCM_PROJECT_ID + a service-account
key, OPEN_QUESTIONS Q32, runbook docs/runbooks/push-notifications.md). Without them the run
plans only and reports `skipped_reason: no push sender configured`; nothing is stamped, so the
first run with a sender sends what is due then. Safe to run repeatedly: an item + stage is
sent once.

Run a few times a day outside the default quiet hours (runbook: docs/runbooks/govt-feed.md):
    python -m bagmitra_api.feed.alert_job
"""

from __future__ import annotations

import asyncio

import httpx

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.alerts import AlertSummary, run_alerts
from bagmitra_api.push.fcm import fcm_sender
from bagmitra_api.push.sender import PushSender


def configured_sender(
    http: httpx.AsyncClient, settings: Settings | None = None
) -> PushSender | None:
    """The FCM sender when its credentials are set (Q32); else None (plan only)."""
    return fcm_sender(settings or get_settings(), http)


async def run_once(sender: PushSender | None = None) -> AlertSummary:  # pragma: no cover
    async with get_sessionmaker()() as session:
        return await run_alerts(session, sender, utcnow())


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with httpx.AsyncClient(timeout=settings.fcm_timeout_seconds) as http:
        summary = await run_once(configured_sender(http, settings))
    print(summary.to_json())
    return 1 if summary.failed else 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
