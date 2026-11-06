"""LD-09: old sync payloads are reduced to a digest; rows, duplicates and live records stay."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

import httpx
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.db.models import SyncMutation
from bagmitra_api.sync.retention import purge_payloads
from bagmitra_api.sync.service import payload_digest
from tests.test_plots_sync import plot_changes, plot_mutation, pull, push

NOW = datetime(2026, 11, 6, 22, 13, tzinfo=UTC)


async def rows(engine: AsyncEngine) -> dict[str, SyncMutation]:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        found = (await session.scalars(select(SyncMutation))).all()
    return {str(r.client_mutation_id): r for r in found}


async def age(engine: AsyncEngine, mutation_id: str, days: int) -> None:
    async with engine.begin() as conn:
        await conn.execute(
            update(SyncMutation)
            .where(SyncMutation.client_mutation_id == uuid.UUID(mutation_id))
            .values(received_at=NOW - timedelta(days=days))
        )


async def test_old_payloads_become_digests_and_nothing_else_changes(
    client: httpx.AsyncClient, auth_headers: dict[str, str], engine: AsyncEngine
) -> None:
    plot_id = uuid.uuid4()
    old = plot_mutation(plot_id, name="Old name")
    stale = plot_mutation(plot_id, updated_at="2026-10-01T06:00:00Z", name="Lost")
    rejected = plot_mutation(uuid.uuid4(), tree_count="many")
    recent = plot_mutation(uuid.uuid4(), name="New")
    results = await push(client, auth_headers, old, stale, rejected, recent)
    assert [r["status"] for r in results] == ["applied", "stale", "rejected", "applied"]
    for m in (old, stale, rejected):
        await age(engine, m["client_mutation_id"], 91)
    await age(engine, recent["client_mutation_id"], 89)
    before = await rows(engine)

    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        summary = await purge_payloads(session, NOW, retention_days=90, batch_size=2)
    assert summary.purged == 3

    after = await rows(engine)
    assert set(after) == set(before), "rows are kept (duplicate check, pull horizon)"
    for m in (old, stale):
        row = after[m["client_mutation_id"]]
        assert row.payload == payload_digest(m["payload"])
        assert "Old name" not in str(row.payload)
        assert row.payload_purged_at is not None
    assert (
        after[rejected["client_mutation_id"]].payload
        == before[rejected["client_mutation_id"]].payload
    )
    assert after[recent["client_mutation_id"]].payload == recent["payload"]
    assert after[recent["client_mutation_id"]].payload_purged_at is None

    # A replay of a purged write is still a duplicate, and the live plot is untouched.
    again = await push(client, auth_headers, old)
    assert again[0]["status"] == "duplicate"
    plots = {
        c["entity_id"]: c["data"]["name"] for c in plot_changes(await pull(client, auth_headers))
    }
    assert plots[str(plot_id)] == "Old name"

    async with maker() as session:
        second = await purge_payloads(session, NOW, retention_days=90, batch_size=2)
    assert second.purged == 0, "a second run finds nothing left to purge"


async def test_nothing_is_purged_inside_the_retention_window(
    client: httpx.AsyncClient, auth_headers: dict[str, str], engine: AsyncEngine
) -> None:
    await push(client, auth_headers, plot_mutation(uuid.uuid4()))
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        summary = await purge_payloads(session, datetime.now(UTC), retention_days=1, batch_size=500)
    assert summary.purged == 0
