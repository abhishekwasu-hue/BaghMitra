"""RLS on `feed_reactions` (migration 0051, Q146). Postgres only (`pytest -m postgres`, CI
migrations-postgres job with POSTGRES_TEST_URL). A client role with full table grants still
reads and writes only its own rows; the API's privileged role reads every row for counts."""

from __future__ import annotations

import os
import uuid
from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from alembic import command
from sqlalchemy import Connection, create_engine, text
from sqlalchemy import exc as sa_exc

from tests.test_migrations import _config

pytestmark = [
    pytest.mark.postgres,
    pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL"),
]
PROBE = "reaction_probe"
NOW = datetime.now(UTC)


@pytest.fixture
def conn() -> Iterator[Connection]:
    url = os.environ["POSTGRES_TEST_URL"]
    command.upgrade(_config(url), "head")
    engine = create_engine(url.replace("+asyncpg", "+psycopg"))
    with engine.connect() as c:
        with c.begin():
            c.execute(
                text(
                    f"DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{PROBE}') "  # noqa: S608
                    f"THEN DROP OWNED BY {PROBE}; DROP ROLE {PROBE}; END IF; END $$"
                )
            )
            c.execute(text(f"CREATE ROLE {PROBE} NOLOGIN"))
            c.execute(text(f"GRANT SELECT, INSERT, UPDATE, DELETE ON feed_reactions TO {PROBE}"))
            c.execute(text(f"GRANT USAGE ON SCHEMA auth TO {PROBE}"))
        yield c
        c.rollback()
        with c.begin():
            c.execute(text(f"DROP OWNED BY {PROBE}"))
            c.execute(text(f"DROP ROLE {PROBE}"))
    engine.dispose()


def _insert(conn: Connection, owner: uuid.UUID, qa_id: str, reaction: str = "useful") -> None:
    conn.execute(
        text(
            "INSERT INTO feed_reactions (id, owner_id, qa_id, reaction, created_at, updated_at) "
            "VALUES (:id, :o, :q, :r, :t, :t)"
        ),
        {"id": uuid.uuid4(), "o": owner, "q": qa_id, "r": reaction, "t": NOW},
    )


def _as(conn: Connection, user: uuid.UUID | None) -> None:
    conn.execute(text(f"SET LOCAL ROLE {PROBE}"))
    conn.execute(
        text("SELECT set_config('request.jwt.claim.sub', :s, true)"),
        {"s": str(user) if user else ""},
    )


def test_policy_and_forced_rls(conn: Connection) -> None:
    row = conn.execute(
        text(
            "SELECT c.relrowsecurity, c.relforcerowsecurity, "
            "(SELECT array_agg(polname::text) FROM pg_policy p WHERE p.polrelid = c.oid) "
            "FROM pg_class c WHERE c.relname = 'feed_reactions'"
        )
    ).one()
    assert row[0], "RLS on"
    assert row[1], "forced for the table owner too"
    assert row[2] == ["feed_reactions_owner_all"]


def test_owner_reads_and_writes_only_own_rows(conn: Connection) -> None:
    me, other = uuid.uuid4(), uuid.uuid4()
    with conn.begin() as tx:
        _insert(conn, me, "seed-a")
        _insert(conn, other, "seed-a", "unclear")
        # The privileged role (the API) counts across owners.
        assert conn.execute(text("SELECT count(*) FROM feed_reactions")).scalar() == 2
        _as(conn, me)
        seen = conn.execute(text("SELECT owner_id, reaction FROM feed_reactions")).tuples().all()
        assert [tuple(r) for r in seen] == [(me, "useful")]
        # Updating or deleting another reader's row touches nothing.
        changed = conn.execute(text("UPDATE feed_reactions SET reaction = 'okay' WHERE true"))
        assert changed.rowcount == 1
        gone = conn.execute(text("DELETE FROM feed_reactions WHERE owner_id = :o"), {"o": other})
        assert gone.rowcount == 0
        conn.execute(text("RESET ROLE"))
        assert conn.execute(text("SELECT count(*) FROM feed_reactions")).scalar() == 2
        _as(conn, None)
        assert conn.execute(text("SELECT count(*) FROM feed_reactions")).scalar() == 0
        conn.execute(text("RESET ROLE"))
        tx.rollback()


def test_owner_cannot_write_a_row_for_someone_else(conn: Connection) -> None:
    me = uuid.uuid4()
    with conn.begin() as tx:
        _as(conn, me)
        _insert(conn, me, "seed-own")
        with (
            pytest.raises(sa_exc.ProgrammingError, match="row-level security"),
            conn.begin_nested(),
        ):
            _insert(conn, uuid.uuid4(), "seed-other")
        tx.rollback()
