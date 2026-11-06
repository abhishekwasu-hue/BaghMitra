"""Retention of the sync audit log (audit LD-09).

Every client write is recorded in `sync_mutations` with its payload (farmer records: names,
phone, plot details). After `sync_payload_retention_days` the payload of an applied or stale
write is replaced with its `{sha256, bytes}` digest (what a rejected write keeps from the
start) and `payload_purged_at` is set. The row itself stays: the duplicate check uses
(owner_id, client_mutation_id) and the pull horizon (LD-08) uses `seq`; neither reads the
payload. The live records in the entity tables are never touched.

Run nightly (deploy.sh adds the cron line unless CRON_SYNC_RETENTION is off):
    python -m bagmitra_api.sync.retention
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.base import utcnow
from bagmitra_api.db.models import SyncMutation
from bagmitra_api.sync.service import payload_digest


@dataclass
class RetentionSummary:
    cutoff: str
    purged: int = 0

    def to_json(self) -> str:
        return json.dumps(asdict(self))


async def purge_payloads(
    session: AsyncSession, now: datetime, retention_days: int, batch_size: int
) -> RetentionSummary:
    """Digest every payload received before `now - retention_days`, `batch_size` rows per
    transaction (a long backlog never holds one big transaction)."""
    cutoff = now - timedelta(days=retention_days)
    summary = RetentionSummary(cutoff=cutoff.isoformat())
    while True:
        rows = (
            await session.scalars(
                select(SyncMutation)
                .where(SyncMutation.payload_purged_at.is_(None), SyncMutation.received_at < cutoff)
                .order_by(SyncMutation.seq)
                .limit(batch_size)
            )
        ).all()
        if not rows:
            return summary
        for row in rows:
            if row.status != "rejected":  # a rejected payload is a digest already
                row.payload = payload_digest(row.payload)
            row.payload_purged_at = now
        await session.commit()
        summary.purged += len(rows)


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    from bagmitra_api.core.settings import get_settings  # noqa: PLC0415
    from bagmitra_api.db.session import get_sessionmaker  # noqa: PLC0415

    settings = get_settings()
    async with get_sessionmaker()() as session:
        summary = await purge_payloads(
            session,
            utcnow(),
            settings.sync_payload_retention_days,
            settings.sync_retention_batch_size,
        )
    print(summary.to_json())
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
