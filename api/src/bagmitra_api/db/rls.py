"""Row-level security helpers used by migrations (Postgres / Supabase only).

The API connects with a privileged role and enforces ownership in code; RLS is the
second wall that protects rows from direct Supabase client access.
"""

from __future__ import annotations

import re

_IDENT = re.compile(r"^[a-z_][a-z0-9_]{0,62}$")

# Plain Postgres (CI, local docker) has no Supabase `auth` schema. Create a compatible
# auth.uid() only when it is missing, so a real Supabase function is never replaced.
AUTH_UID_SHIM = """
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'auth' AND p.proname = 'uid'
  ) THEN
    CREATE SCHEMA IF NOT EXISTS auth;
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
      $f$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $f$;
  END IF;
END $$;
"""


def _check(name: str) -> str:
    if not _IDENT.match(name):
        raise ValueError(f"unsafe SQL identifier: {name!r}")
    return name


def enable_owner_rls(table: str, owner_column: str) -> list[str]:
    """Statements that enable RLS and allow a user to touch only their own rows."""
    t, c = _check(table), _check(owner_column)
    return [
        f"ALTER TABLE {t} ENABLE ROW LEVEL SECURITY",
        f"ALTER TABLE {t} FORCE ROW LEVEL SECURITY",
        f"CREATE POLICY {t}_owner_all ON {t} FOR ALL "
        f"USING ({c} = auth.uid()) WITH CHECK ({c} = auth.uid())",
    ]


def disable_owner_rls(table: str) -> list[str]:
    t = _check(table)
    return [
        f"DROP POLICY IF EXISTS {t}_owner_all ON {t}",
        f"ALTER TABLE {t} DISABLE ROW LEVEL SECURITY",
    ]


def enable_reference_rls(table: str) -> list[str]:
    """Reference/config tables: any signed-in user may read; only privileged roles write."""
    t = _check(table)
    return [
        f"ALTER TABLE {t} ENABLE ROW LEVEL SECURITY",
        f"ALTER TABLE {t} FORCE ROW LEVEL SECURITY",
        f"CREATE POLICY {t}_read ON {t} FOR SELECT USING (auth.uid() IS NOT NULL)",
    ]


def disable_reference_rls(table: str) -> list[str]:
    t = _check(table)
    return [
        f"DROP POLICY IF EXISTS {t}_read ON {t}",
        f"ALTER TABLE {t} DISABLE ROW LEVEL SECURITY",
    ]


def enable_private_rls(table: str) -> list[str]:
    """Service-only tables: RLS on with no policy, so only BYPASSRLS roles see rows."""
    t = _check(table)
    return [
        f"ALTER TABLE {t} ENABLE ROW LEVEL SECURITY",
        f"ALTER TABLE {t} FORCE ROW LEVEL SECURITY",
    ]


def disable_private_rls(table: str) -> list[str]:
    return [f"ALTER TABLE {_check(table)} DISABLE ROW LEVEL SECURITY"]


_POLICY_COMMANDS = frozenset({"ALL", "SELECT"})


def enable_policy_rls(table: str, policies: list[tuple[str, str, str]]) -> list[str]:
    """RLS on with named policies `(name, command, USING expression)` (market linkage,
    migration 0029). The expressions are constants written in the migration, never input;
    FOR ALL reuses USING as WITH CHECK. Writes without a policy go through the API only."""
    t = _check(table)
    out = [
        f"ALTER TABLE {t} ENABLE ROW LEVEL SECURITY",
        f"ALTER TABLE {t} FORCE ROW LEVEL SECURITY",
    ]
    for name, command, using in policies:
        if command not in _POLICY_COMMANDS:
            raise ValueError(f"unsupported policy command: {command!r}")
        out.append(f"CREATE POLICY {_check(f'{t}_{name}')} ON {t} FOR {command} USING ({using})")
    return out


def disable_policy_rls(table: str, names: list[str]) -> list[str]:
    t = _check(table)
    drops = [f"DROP POLICY IF EXISTS {_check(f'{t}_{n}')} ON {t}" for n in names]
    return [*drops, f"ALTER TABLE {t} DISABLE ROW LEVEL SECURITY"]


FEED_VISIBLE = "status IN ('published', 'withdrawn')"


def enable_feed_published_rls(table: str, item_column: str | None = None) -> list[str]:
    """Feed reference tables: signed-in users read only rows of published or withdrawn items
    (drafts and the review queue stay hidden). `item_column` points a child table at
    feed_items; without it the table itself carries `status`. Dropped by
    `disable_reference_rls` (same policy name)."""
    t = _check(table)
    # Identifiers pass _check; the status list is a constant.
    visible = (
        FEED_VISIBLE
        if item_column is None
        else f"{_check(item_column)} IN (SELECT id FROM feed_items WHERE {FEED_VISIBLE})"  # noqa: S608  # nosec B608
    )
    return [
        f"ALTER TABLE {t} ENABLE ROW LEVEL SECURITY",
        f"ALTER TABLE {t} FORCE ROW LEVEL SECURITY",
        f"CREATE POLICY {t}_read ON {t} FOR SELECT USING (auth.uid() IS NOT NULL AND {visible})",
    ]


# Supabase's client roles. The app never reads tables through PostgREST (it talks only to
# the API), so these roles get no privileges on schema `public` at all (S-01 / S-02 / S-04).
CLIENT_ROLES = ("anon", "authenticated")


_REVOKE_TEMPLATE = """
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY[@ROLES@] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
@REVOKES@
    END IF;
  END LOOP;
END $$;
"""
_REVOKE_KIND = (
    "      EXECUTE format('REVOKE ALL ON ALL @KIND@ IN SCHEMA public FROM %I', r);\n"
    "      EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public "
    "REVOKE ALL ON @KIND@ FROM %I', r);"
)


def revoke_client_roles() -> str:
    """One DO block: revoke every privilege of the client roles on the tables, sequences and
    functions in `public`, and the default privileges that would grant them future ones.
    A role that does not exist (plain Postgres in CI) is skipped. Role names pass _check and
    the object kinds are constants."""
    roles = ", ".join(f"'{_check(r)}'" for r in CLIENT_ROLES)
    revokes = "\n".join(
        _REVOKE_KIND.replace("@KIND@", kind) for kind in ("TABLES", "SEQUENCES", "FUNCTIONS")
    )
    return _REVOKE_TEMPLATE.replace("@ROLES@", roles).replace("@REVOKES@", revokes)
