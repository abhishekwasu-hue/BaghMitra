"""Retention of photo analysis training samples (owner Q135; privacy policy §5): a sample older
than PHOTO_AI_RETENTION_DAYS (default 730) is deleted, its photo first. When storage is set up
but fails, the rows stay and the next run tries again; while storage is off, a row whose photo
is recorded stays too (its photo could not be deleted), and the summary says so.

deploy/deploy.sh adds the cron line unless CRON_PHOTO_AI_RETENTION=off:
    python -m bagmitra_api.photo_ai.retention
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta

import httpx
import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.photo_ai.models import PhotoAnalysisSample
from bagmitra_api.photos.storage import PhotoStorage, PhotoStorageError, SupabaseStorageClient

log = structlog.get_logger("bagmitra.photo_ai")


@dataclass
class RetentionSummary:
    cutoff: str
    deleted: int = 0
    photos_deleted: int = 0
    # Rows kept because their photo could not be deleted (storage off or failing).
    waiting_for_storage: int = 0

    def to_json(self) -> str:
        return json.dumps(asdict(self))


async def purge_samples(
    session: AsyncSession, storage: PhotoStorage | None, now: datetime, retention_days: int
) -> RetentionSummary:
    cutoff = now - timedelta(days=retention_days)
    summary = RetentionSummary(cutoff=cutoff.isoformat())
    rows = list(
        await session.scalars(
            select(PhotoAnalysisSample).where(PhotoAnalysisSample.created_at < cutoff)
        )
    )
    keys = [r.photo_key for r in rows if r.photo_key]
    photos_gone = not keys
    if keys and storage is not None:
        try:
            await storage.delete_objects(keys)
            photos_gone = True
            summary.photos_deleted = len(keys)
        except PhotoStorageError as exc:
            log.warning("photo_ai_retention_storage_failed", reason=str(exc))
    for row in rows:
        if row.photo_key and not photos_gone:
            summary.waiting_for_storage += 1
            continue
        await session.delete(row)
        summary.deleted += 1
    await session.commit()
    return summary


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    maker = get_sessionmaker()
    async with (
        maker() as session,
        httpx.AsyncClient(timeout=settings.photo_storage_timeout_seconds) as http,
    ):
        storage = (
            SupabaseStorageClient(
                http,
                base_url=settings.photo_storage_url,
                bucket=settings.photo_storage_bucket,
                service_key=settings.photo_storage_service_key.get_secret_value(),
            )
            if settings.photo_storage_enabled
            else None
        )
        summary = await purge_samples(session, storage, utcnow(), settings.photo_ai_retention_days)
    print(summary.to_json())
    return 1 if summary.waiting_for_storage else 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
