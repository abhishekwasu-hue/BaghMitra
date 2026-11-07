"""Migrations must match the models, be reversible, and enable RLS on every table."""

from __future__ import annotations

import os
import uuid
from pathlib import Path

import pytest
from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.config import Config
from alembic.migration import MigrationContext
from sqlalchemy import Connection, create_engine, inspect, text
from sqlalchemy import exc as sa_exc

from bagmitra_api.db import models  # noqa: F401
from bagmitra_api.db.base import Base
from bagmitra_api.db.rls import (
    CLIENT_ROLES,
    disable_owner_rls,
    disable_private_rls,
    disable_reference_rls,
    enable_feed_published_rls,
    enable_owner_rls,
    enable_private_rls,
    enable_reference_rls,
    revoke_client_roles,
)

API_DIR = Path(__file__).resolve().parents[1]


def _config(url: str) -> Config:
    cfg = Config(str(API_DIR / "alembic.ini"))
    cfg.set_main_option("script_location", str(API_DIR / "alembic"))
    cfg.set_main_option("sqlalchemy.url", url)
    return cfg


def _sync_url(async_url: str) -> str:
    return async_url.replace("+aiosqlite", "").replace("+asyncpg", "+psycopg")


def _ours(name: str | None, type_: str, _parent: object) -> bool:
    # PostGIS images ship extra tables (tiger geocoder); only compare tables we own.
    return type_ != "table" or name in Base.metadata.tables


def _diff(conn: Connection) -> list[object]:
    ctx = MigrationContext.configure(conn, opts={"include_name": _ours})
    return list(compare_metadata(ctx, Base.metadata))


def test_upgrade_downgrade_upgrade_on_sqlite(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'm.db'}"
    cfg = _config(url)
    command.upgrade(cfg, "head")
    command.downgrade(cfg, "base")
    command.upgrade(cfg, "head")
    engine = create_engine(_sync_url(url))
    with engine.connect() as conn:
        assert set(inspect(conn).get_table_names()) >= set(Base.metadata.tables)
        assert _diff(conn) == [], "models and migrations drifted; write a migration"
    engine.dispose()


def test_every_model_declares_its_rls_kind() -> None:
    """Each table is owner-scoped (owner_column), read-only reference data, private, or has
    its own policies (custom_rls: market linkage, migrations 0029-0030)."""
    for mapper in Base.registry.mappers:
        cls = mapper.class_
        if any(getattr(cls, k, False) for k in ("reference_table", "private_table", "custom_rls")):
            continue
        owner = getattr(cls, "owner_column", None)
        assert isinstance(owner, str), f"{cls.__name__} lacks owner_column / reference_table"
        assert owner in mapper.columns, f"{cls.__name__} needs owner_column for RLS"


def test_rls_statements_reject_unsafe_identifiers() -> None:
    assert enable_owner_rls("farmers", "id")[0] == "ALTER TABLE farmers ENABLE ROW LEVEL SECURITY"
    assert "auth.uid() IS NOT NULL" in enable_reference_rls("crop_stage_templates")[2]
    assert disable_reference_rls("crop_stage_templates")[0].startswith("DROP POLICY")
    assert disable_owner_rls("farmers")[0].startswith("DROP POLICY")
    assert not any("POLICY" in s for s in enable_private_rls("kb_admin_alerts"))
    assert disable_private_rls("kb_admin_alerts") == [
        "ALTER TABLE kb_admin_alerts DISABLE ROW LEVEL SECURITY"
    ]
    with pytest.raises(ValueError, match="unsafe"):
        enable_owner_rls("farmers; drop table x", "id")


def test_feed_policies_hide_unpublished_items() -> None:
    own = enable_feed_published_rls("feed_items")[2]
    assert "status IN ('published', 'withdrawn')" in own
    child = enable_feed_published_rls("feed_item_i18n", "item_id")[2]
    assert "item_id IN (SELECT id FROM feed_items WHERE status IN" in child
    assert disable_reference_rls("feed_item_i18n")[0].endswith(
        "feed_item_i18n_read ON feed_item_i18n"
    )
    with pytest.raises(ValueError, match="unsafe"):
        enable_feed_published_rls("feed_item_i18n", "id; drop")


@pytest.mark.postgres
@pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL")
def test_postgres_migrations_and_rls() -> None:
    url = os.environ["POSTGRES_TEST_URL"]
    cfg = _config(url)
    command.upgrade(cfg, "head")
    command.downgrade(cfg, "base")
    command.upgrade(cfg, "head")
    engine = create_engine(url.replace("+asyncpg", "+psycopg"))
    with engine.connect() as conn:
        rows = conn.execute(
            text(
                "SELECT c.relname, c.relrowsecurity FROM pg_class c "
                "JOIN pg_namespace n ON n.oid = c.relnamespace "
                "WHERE n.nspname = 'public' AND c.relkind = 'r' "
                # Extension-owned tables (e.g. PostGIS spatial_ref_sys) are not ours.
                "AND NOT EXISTS ("
                "  SELECT 1 FROM pg_depend d WHERE d.objid = c.oid AND d.deptype = 'e')"
            )
        ).all()
        # alembic_version too (S-01): it is in `public` like every other table.
        assert {r for r, _ in rows} == set(Base.metadata.tables) | {"alembic_version"}
        assert all(rls for _, rls in rows), f"RLS missing: {[r for r, s in rows if not s]}"
        assert _diff(conn) == []
        assert client_role_grants(conn) == []
        _assert_owner_isolation(conn)
    engine.dispose()


GRANTS_SQL = """
SELECT 'table ' || table_name || ' ' || privilege_type || ' ' || grantee
  FROM information_schema.role_table_grants
 WHERE table_schema = 'public' AND grantee = ANY(:roles)
UNION ALL
SELECT 'sequence ' || c.relname || ' ' || r.rolname
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  JOIN pg_roles r ON r.rolname = ANY(:roles)
 WHERE n.nspname = 'public' AND c.relkind = 'S'
   AND has_sequence_privilege(r.oid, c.oid, 'USAGE,SELECT,UPDATE')
   AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = c.oid AND d.deptype = 'e')
UNION ALL
SELECT 'function ' || p.proname || ' ' || a.grantee::regrole::text
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace,
       aclexplode(p.proacl) a
 WHERE n.nspname = 'public' AND a.grantee::regrole::text = ANY(:roles)
UNION ALL
SELECT 'default ' || d.defaclobjtype::text || ' ' || a.grantee::regrole::text
  FROM pg_default_acl d JOIN pg_namespace n ON n.oid = d.defaclnamespace,
       aclexplode(d.defaclacl) a
 WHERE n.nspname = 'public' AND a.grantee <> 0 AND a.grantee::regrole::text = ANY(:roles)
"""


def client_role_grants(conn: Connection) -> list[str]:
    """Privileges the Supabase client roles (anon, authenticated) hold in `public`: tables,
    sequences, functions and default privileges. Empty when the roles do not exist."""
    roles = list(CLIENT_ROLES)
    return list(conn.execute(text(GRANTS_SQL), {"roles": roles}).scalars().all())


def test_revoke_block_names_every_kind_and_guards_missing_roles() -> None:
    sql = revoke_client_roles()
    assert "IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r)" in sql
    assert "ARRAY['anon', 'authenticated']" in sql
    for kind in ("TABLES", "SEQUENCES", "FUNCTIONS"):
        assert f"REVOKE ALL ON ALL {kind} IN SCHEMA public FROM %I" in sql
        assert f"IN SCHEMA public REVOKE ALL ON {kind} FROM %I" in sql


@pytest.mark.postgres
@pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL")
def test_postgres_client_roles_lose_every_grant() -> None:
    """Simulates Supabase (client roles granted everything by default), then checks that 0025
    takes it all away, keeps it away for tables created later, and leaves the API role
    working."""
    url = os.environ["POSTGRES_TEST_URL"]
    cfg = _config(url)
    engine = create_engine(url.replace("+asyncpg", "+psycopg"))
    command.downgrade(cfg, "base")
    with engine.begin() as conn:
        for role in CLIENT_ROLES:
            conn.execute(
                text(
                    f"DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{role}')"  # noqa: S608
                    f" THEN CREATE ROLE {role} NOLOGIN; END IF; END $$"
                )
            )
        for kind in ("TABLES", "SEQUENCES", "FUNCTIONS"):
            conn.execute(
                text(
                    f"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON {kind} "
                    "TO anon, authenticated"
                )
            )
        conn.execute(
            text(
                "CREATE OR REPLACE FUNCTION public.probe_fn() RETURNS int "
                "LANGUAGE sql AS 'SELECT 1'"
            )
        )
    command.upgrade(cfg, "0024")
    with engine.connect() as conn:
        before = client_role_grants(conn)
    assert any(g.startswith("table farmers ") for g in before), before
    assert any(g.startswith("default ") for g in before), before
    # The owner may already have run the same revokes by hand on the live project: 0025 must
    # then still apply cleanly (every statement is idempotent).
    with engine.begin() as conn:
        conn.execute(text(revoke_client_roles()))
        conn.execute(text("ALTER TABLE public.alembic_version ENABLE ROW LEVEL SECURITY"))
        assert client_role_grants(conn) == []
    command.upgrade(cfg, "head")
    with engine.begin() as conn:
        assert client_role_grants(conn) == []
        conn.execute(text("CREATE TABLE public.later_probe (id int)"))
        assert client_role_grants(conn) == []
        conn.execute(text("DROP TABLE public.later_probe"))
        conn.execute(text("DROP FUNCTION public.probe_fn()"))
        rls = conn.execute(
            text("SELECT relrowsecurity FROM pg_class WHERE relname = 'alembic_version'")
        ).scalar_one()
        assert rls is True
        # The migrating / API role still reads and writes alembic_version and the tables.
        assert conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one() == "0034"
        assert conn.execute(text("SELECT count(*) FROM account_deletions")).scalar_one() == 0
    # Reversible, and a revert never hands the privileges back.
    command.downgrade(cfg, "0024")
    with engine.connect() as conn:
        assert client_role_grants(conn) == []
    command.upgrade(cfg, "head")
    engine.dispose()


def _assert_owner_isolation(conn: Connection) -> None:
    me, other = str(uuid.uuid4()), str(uuid.uuid4())
    insert = text(
        "INSERT INTO farmers (id, language, consent_data_processing, consent_whatsapp, "
        "client_updated_at, last_seq, created_at, updated_at) "
        "VALUES (:id, 'mr', false, false, now(), 1, now(), now())"
    )
    conn.commit()
    with conn.begin():
        # Idempotent on a reused database: the role keeps grants on the auth schema.
        conn.execute(
            text(
                "DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rls_probe') "
                "THEN DROP OWNED BY rls_probe; DROP ROLE rls_probe; END IF; END $$"
            )
        )
        conn.execute(text("CREATE ROLE rls_probe NOLOGIN"))
        conn.execute(text("GRANT SELECT, INSERT ON farmers TO rls_probe"))
        conn.execute(text("GRANT USAGE ON SCHEMA auth TO rls_probe"))
    with conn.begin() as tx:
        conn.execute(text("SET LOCAL ROLE rls_probe"))
        conn.execute(text("SELECT set_config('request.jwt.claim.sub', :s, true)"), {"s": me})
        conn.execute(insert, {"id": me})
        with (
            pytest.raises(sa_exc.ProgrammingError, match="row-level security"),
            conn.begin_nested(),
        ):
            conn.execute(insert, {"id": other})
        visible = conn.execute(text("SELECT id::text FROM farmers")).scalars().all()
        assert visible == [me]
        tx.rollback()


def test_0027_is_idempotent_and_reversible(tmp_path: Path) -> None:
    """LD-09: re-running 0027 over a half-applied state adds nothing twice; the downgrade
    removes the column and index and can run on a database that never had them."""
    url = f"sqlite+aiosqlite:///{tmp_path / 'm.db'}"
    cfg = _config(url)
    command.upgrade(cfg, "0027")
    engine = create_engine(_sync_url(url))
    with engine.begin() as conn:
        conn.execute(text("UPDATE alembic_version SET version_num = '0026'"))
    command.upgrade(cfg, "0027")  # column and index already there: skipped
    with engine.connect() as conn:
        cols = {c["name"] for c in inspect(conn).get_columns("sync_mutations")}
        idx = {i["name"] for i in inspect(conn).get_indexes("sync_mutations")}
    assert "payload_purged_at" in cols
    assert "ix_sync_mutations_unpurged_received_at" in idx
    command.downgrade(cfg, "0026")
    with engine.begin() as conn:
        cols = {c["name"] for c in inspect(conn).get_columns("sync_mutations")}
        assert "payload_purged_at" not in cols
        conn.execute(text("UPDATE alembic_version SET version_num = '0027'"))
    command.downgrade(cfg, "0026")  # nothing left to drop: no error
    engine.dispose()


def test_0028_label_claim_details_idempotent_and_reversible(tmp_path: Path) -> None:
    """WP4: the label-claim detail columns are added once, keep existing rows (category
    'chemical', no brand names), and the downgrade can run twice."""
    url = f"sqlite+aiosqlite:///{tmp_path / 'm.db'}"
    cfg = _config(url)
    command.upgrade(cfg, "0027")
    engine = create_engine(_sync_url(url))
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO kb_sources (id, key, title, publisher, url, tier, licence, "
                "allowed_use, verification, fetch_status, created_at, updated_at) VALUES "
                "('s1', 'src', 't', 'p', 'https://x', 'tier2', 'l', 'cite_only', 'V', "
                "'not_fetched', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
            )
        )
        conn.execute(
            text(
                "INSERT INTO kb_label_claims (id, active_ingredient, formulation, crop, target, "
                "dose, source_id, valid_from, created_at, updated_at) VALUES ('c1', 'x', '50 WP', "
                "'citrus', 'canker', 'd', 's1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, "
                "CURRENT_TIMESTAMP)"
            )
        )
    command.upgrade(cfg, "0028")
    new = {"category", "dilution", "page_ref", "description", "brand_names", "maker_url"}
    new |= {"photo_url"}
    with engine.begin() as conn:
        cols = {c["name"] for c in inspect(conn).get_columns("kb_label_claims")}
        assert new <= cols
        row = conn.execute(text("SELECT category, brand_names FROM kb_label_claims")).one()
        assert (row[0], row[1]) == ("chemical", "[]")
        conn.execute(text("UPDATE alembic_version SET version_num = '0027'"))
    command.upgrade(cfg, "0028")  # columns already there: skipped
    command.downgrade(cfg, "0027")
    with engine.begin() as conn:
        cols = {c["name"] for c in inspect(conn).get_columns("kb_label_claims")}
        assert not (new & cols)
        assert conn.execute(text("SELECT count(*) FROM kb_label_claims")).scalar_one() == 1
        conn.execute(text("UPDATE alembic_version SET version_num = '0028'"))
    command.downgrade(cfg, "0027")  # nothing left to drop: no error
    engine.dispose()
