from __future__ import annotations

import hashlib
import json
from typing import Any

import structlog
from pydantic import BaseModel, ValidationError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser
from bagmitra_api.db.base import as_utc
from bagmitra_api.db.models import SyncMutation
from bagmitra_api.sync.registry import HANDLERS, RejectedError, ValidatedWrite
from bagmitra_api.sync.schemas import (
    Change,
    Mutation,
    MutationResult,
    MutationStatus,
    PullResponse,
)

log = structlog.get_logger("bagmitra.sync")


def _compact(payload: dict[str, Any]) -> bytes:
    return json.dumps(payload, separators=(",", ":"), ensure_ascii=False, default=str).encode()


def payload_size(payload: dict[str, Any]) -> int:
    """Size of a payload as compact UTF-8 JSON: what the sync caps count (S-07)."""
    return len(_compact(payload))


def _digest(payload: dict[str, Any]) -> dict[str, Any]:
    """What is kept of a rejected payload: enough to recognise a repeat, none of the content."""
    raw = _compact(payload)
    return {"sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}


async def _record(
    session: AsyncSession,
    user: AuthenticatedUser,
    m: Mutation,
    status: MutationStatus,
    error: str | None,
) -> SyncMutation:
    row = SyncMutation(
        client_mutation_id=m.client_mutation_id,
        owner_id=user.id,
        entity=m.entity,
        entity_id=m.entity_id,
        op=m.op,
        payload=_digest(m.payload) if status == "rejected" else m.payload,
        client_updated_at=m.client_updated_at,
        status=status,
        error=error,
    )
    session.add(row)
    await session.flush()
    return row


async def _decide(
    session: AsyncSession, user: AuthenticatedUser, m: Mutation
) -> tuple[MutationStatus, str | None, BaseModel | None]:
    """Validate a mutation without writing anything. Returns (status, error, payload)."""
    handler = HANDLERS.get(m.entity)
    if handler is None:
        return "rejected", "unknown_entity", None
    if m.op not in handler.supported_ops:
        return "rejected", "unsupported_op", None
    try:
        payload = None if m.op == "delete" else handler.payload_model.model_validate(m.payload)
        current = await handler.current_version(session, user, m.entity_id)
        if payload is not None:
            handler.check_payload(user, m.entity_id, payload)
            await handler.check_references(session, user, payload)
    except ValidationError:
        return "rejected", "invalid_payload", None
    except RejectedError as exc:
        return "rejected", exc.code, None
    if current is not None and as_utc(current) > m.client_updated_at:
        return "stale", None, None
    return "applied", None, payload


async def apply_mutation(
    session: AsyncSession, user: AuthenticatedUser, m: Mutation, max_payload_bytes: int
) -> MutationResult:
    seen = await session.scalar(
        select(SyncMutation.seq).where(
            SyncMutation.owner_id == user.id,
            SyncMutation.client_mutation_id == m.client_mutation_id,
        )
    )
    if seen is not None:
        return MutationResult(client_mutation_id=m.client_mutation_id, status="duplicate")

    status: MutationStatus
    error: str | None
    payload: BaseModel | None
    if payload_size(m.payload) > max_payload_bytes:
        status, error, payload = "rejected", "payload_too_large", None
    else:
        status, error, payload = await _decide(session, user, m)
    row = await _record(session, user, m, status, error)
    if status == "applied":
        write = ValidatedWrite(m.entity_id, m.op, payload, m.client_updated_at, row.seq)
        await HANDLERS[m.entity].apply(session, user, write)
    else:
        if status == "stale":
            # The phone shows its losing write; send it the kept version on its next pull.
            await HANDLERS[m.entity].resend(session, user, m.entity_id, row.seq)
        log.info("sync_mutation_not_applied", entity=m.entity, status=status, error=error)
    return MutationResult(client_mutation_id=m.client_mutation_id, status=status, error=error)


async def push(
    session: AsyncSession,
    user: AuthenticatedUser,
    mutations: list[Mutation],
    max_payload_bytes: int,
) -> list[MutationResult]:
    results = []
    for m in mutations:
        results.append(await apply_mutation(session, user, m, max_payload_bytes))
        await session.commit()
    return results


async def pull(
    session: AsyncSession, user: AuthenticatedUser, since: int, limit: int
) -> PullResponse:
    """The next `limit` changes after `since`. Each entity yields its own lowest `limit`, so
    the lowest `limit` overall are among them; the cursor is the last one returned."""
    changes = [
        Change(
            entity=handler.name,
            entity_id=rc.entity_id,
            op=rc.op,
            data=rc.data,
            updated_at=as_utc(rc.updated_at),
            seq=rc.seq,
        )
        for handler in HANDLERS.values()
        for rc in await handler.changed_since(session, user, since, limit)
    ]
    changes.sort(key=lambda c: c.seq)
    del changes[limit:]
    return PullResponse(changes=changes, cursor=max((c.seq for c in changes), default=since))
