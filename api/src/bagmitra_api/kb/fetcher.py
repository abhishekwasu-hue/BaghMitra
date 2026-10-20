"""Fetches the registered source documents and records what happened (addendum v1.3 §2, §5).

A fetch only records a content hash, size and time; the text itself is not stored (several
licences forbid redistribution). A host the environment cannot reach is recorded as
`fetch_failed` with the reason: nothing is mocked or invented, and an admin can upload the
document by hand instead (`PUT /v1/admin/kb/sources/{key}/document`).

Usage: python -m bagmitra_api.kb.fetch_sources [--only KEY ...]
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from datetime import UTC, datetime

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.kb.models import KbSource

MAX_DOCUMENT_BYTES = 20 * 1024 * 1024
USER_AGENT = "BagMitra-KB/1.0 (+source registry; contact via repository)"


@dataclass(frozen=True)
class FetchOutcome:
    key: str
    status: str
    error: str | None = None


def _fail(source: KbSource, reason: str) -> FetchOutcome:
    source.fetch_status = "fetch_failed"
    source.fetch_error = reason[:500]
    return FetchOutcome(source.key, "fetch_failed", source.fetch_error)


async def fetch_source(
    session: AsyncSession, source: KbSource, client: httpx.AsyncClient
) -> FetchOutcome:
    """Download one source and update its record. Never raises for network problems; a failure
    keeps the last good hash (an old copy is still the best evidence there is)."""
    try:
        async with client.stream(
            "GET", source.url, headers={"User-Agent": USER_AGENT}, timeout=30
        ) as response:
            if response.status_code >= 400:
                outcome = _fail(source, f"HTTP {response.status_code} from {response.url.host}")
            else:
                digest = hashlib.sha256()
                size = 0
                async for chunk in response.aiter_bytes():
                    size += len(chunk)
                    if size > MAX_DOCUMENT_BYTES:
                        break
                    digest.update(chunk)
                if size > MAX_DOCUMENT_BYTES:
                    outcome = _fail(source, f"document too large (over {MAX_DOCUMENT_BYTES} bytes)")
                else:
                    source.fetch_status = "ok"
                    source.fetch_error = None
                    source.content_hash = digest.hexdigest()
                    source.fetch_bytes = size
                    source.fetched_at = datetime.now(UTC)
                    outcome = FetchOutcome(source.key, "ok")
    except httpx.HTTPError as exc:
        outcome = _fail(source, f"{type(exc).__name__}: {exc}")
    session.add(source)
    await session.flush()
    return outcome


def _fetchable(source: KbSource) -> bool:
    # Image datasets are large and licence-restricted; internal-only pages are never shown.
    return source.tier != "tier4" and source.allowed_use != "internal_only"


async def fetch_all(
    session: AsyncSession, client: httpx.AsyncClient, only: list[str] | None = None
) -> list[FetchOutcome]:
    rows = await session.scalars(select(KbSource).order_by(KbSource.tier, KbSource.key))
    sources = [s for s in rows if _fetchable(s) and (only is None or s.key in only)]
    return [await fetch_source(session, s, client) for s in sources]
