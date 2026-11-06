"""LD-08: the pull cursor must never pass a seq whose transaction has not committed yet.

`seq` is handed out at INSERT from one global sequence, so without care two phones of one
account can commit in the other order (A gets 10, B gets 11, B commits first) and a pull in
between moves the cursor past 10 for good. These tests interleave real Postgres
transactions; the SQLite test only checks the horizon rule that needs no lock.
"""

from __future__ import annotations

import asyncio
import os
import uuid
from collections.abc import AsyncIterator, Callable
from typing import Any

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from bagmitra_api.auth.jwt import AuthenticatedUser
from bagmitra_api.db.base import Base
from bagmitra_api.sync import service
from bagmitra_api.sync.registry import HANDLERS
from bagmitra_api.sync.schemas import Mutation
from tests.test_plots_sync import plot_mutation
from tests.test_sync import profile_mutation

MAX_PAYLOAD = 64 * 1024
pg = pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL")


def mutation(raw: dict[str, Any]) -> Mutation:
    return Mutation.model_validate(raw)


@pytest.fixture
async def pg_engine() -> AsyncIterator[AsyncEngine]:
    """Every table in a schema of its own, dropped afterwards (the migration tests own
    `public` in the same database)."""
    schema = f"ld08_{uuid.uuid4().hex[:12]}"
    url = os.environ["POSTGRES_TEST_URL"]
    admin = create_async_engine(url)
    async with admin.begin() as conn:
        await conn.execute(text(f'CREATE SCHEMA "{schema}"'))
    eng = create_async_engine(url, connect_args={"server_settings": {"search_path": schema}})
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    try:
        yield eng
    finally:
        await eng.dispose()
        async with admin.begin() as conn:
            await conn.execute(text(f'DROP SCHEMA "{schema}" CASCADE'))
        await admin.dispose()


async def pull(maker: async_sessionmaker[AsyncSession], user: AuthenticatedUser, since: int) -> Any:
    async with maker() as session:
        return await service.pull(session, user, since, 500)


@pytest.mark.postgres
@pg
async def test_a_lower_seq_committed_later_is_not_skipped(pg_engine: AsyncEngine) -> None:
    maker = async_sessionmaker(pg_engine, expire_on_commit=False)
    user = AuthenticatedUser(id=uuid.uuid4(), phone=None)
    first, second = uuid.uuid4(), uuid.uuid4()

    async def phone_b() -> None:
        async with maker() as session:
            await service.push(session, user, [mutation(plot_mutation(second))], MAX_PAYLOAD)

    phone_a = maker()
    b_task: asyncio.Task[None] | None = None
    try:
        await service.apply_mutation(phone_a, user, mutation(plot_mutation(first)), MAX_PAYLOAD)
        # Phone A holds its seq, uncommitted. Phone B's push must wait for it, not race past.
        b_task = asyncio.create_task(phone_b())
        await asyncio.sleep(0.5)
        b_waited = not b_task.done()
        during = await pull(maker, user, 0)
        await phone_a.commit()
        await asyncio.wait_for(b_task, timeout=10)
    finally:
        await phone_a.close()
        if b_task is not None and not b_task.done():
            b_task.cancel()
    assert b_waited, "phone B got a seq while phone A's transaction was open"
    assert during.changes == []
    assert during.cursor == 0

    after = await pull(maker, user, during.cursor)
    assert [c.entity_id for c in after.changes] == [str(first), str(second)]
    assert after.changes[0].seq < after.changes[1].seq == after.cursor


@pytest.mark.postgres
@pg
async def test_another_owner_does_not_wait(pg_engine: AsyncEngine) -> None:
    maker = async_sessionmaker(pg_engine, expire_on_commit=False)
    owner, other = (AuthenticatedUser(id=uuid.uuid4(), phone=None) for _ in range(2))
    held = maker()
    await service.apply_mutation(held, owner, mutation(plot_mutation(uuid.uuid4())), MAX_PAYLOAD)
    try:
        async with maker() as session:
            results = await asyncio.wait_for(
                service.push(session, other, [mutation(plot_mutation(uuid.uuid4()))], MAX_PAYLOAD),
                timeout=5,
            )
        assert results[0].status == "applied"
    finally:
        await held.rollback()
        await held.close()


def commit_between_entity_queries(
    monkeypatch: pytest.MonkeyPatch,
    maker: async_sessionmaker[AsyncSession],
    user: AuthenticatedUser,
) -> Callable[[], int]:
    """While a pull is between its profile query and its plot query, the owner's other phone
    commits a profile change and then a plot change (the plot gets the higher seq)."""
    handler_class = type(HANDLERS["farmer_profile"])  # a frozen dataclass: patch the class
    original = handler_class.changed_since
    calls = 0

    async def changed_since(
        self: Any, session: AsyncSession, u: AuthenticatedUser, since: int, limit: int
    ) -> Any:
        nonlocal calls
        rows = await original(self, session, u, since, limit)
        calls += 1
        if calls == 1:
            async with maker() as other:
                await service.push(
                    other,
                    user,
                    [
                        mutation(profile_mutation(user.id, updated_at="2026-10-02T06:00:00Z")),
                        mutation(plot_mutation(uuid.uuid4())),
                    ],
                    MAX_PAYLOAD,
                )
        return rows

    monkeypatch.setattr(handler_class, "changed_since", changed_since)
    return lambda: calls


async def _horizon_case(maker: async_sessionmaker[AsyncSession], user: AuthenticatedUser) -> None:
    async with maker() as session:
        await service.push(session, user, [mutation(profile_mutation(user.id))], MAX_PAYLOAD)
    page = await pull(maker, user, 0)
    # The profile query ran before the other phone's commits, the plot query after: without
    # the horizon the page would hold the new plot and its cursor would pass the new profile.
    assert [c.entity for c in page.changes] == ["farmer_profile"]
    later = await pull(maker, user, page.cursor)
    assert [c.entity for c in later.changes] == ["farmer_profile", "plot"]
    assert later.changes[0].data["display_name"] == "Abhishek"
    assert later.cursor == later.changes[-1].seq


@pytest.mark.postgres
@pg
async def test_postgres_pull_stops_at_the_horizon_read_first(
    pg_engine: AsyncEngine, monkeypatch: pytest.MonkeyPatch
) -> None:
    maker = async_sessionmaker(pg_engine, expire_on_commit=False)
    user = AuthenticatedUser(id=uuid.uuid4(), phone=None)
    calls = commit_between_entity_queries(monkeypatch, maker, user)
    await _horizon_case(maker, user)
    assert calls() >= 2


async def test_sqlite_pull_stops_at_the_horizon_read_first(
    engine: AsyncEngine, monkeypatch: pytest.MonkeyPatch
) -> None:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    user = AuthenticatedUser(id=uuid.uuid4(), phone=None)
    calls = commit_between_entity_queries(monkeypatch, maker, user)
    await _horizon_case(maker, user)
    assert calls() >= 2
