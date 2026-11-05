"""Close the Supabase Data API on `public`, RLS on alembic_version, account deletions.

- S-01 / S-02 / S-04: `anon` and `authenticated` lose every privilege on the tables,
  sequences and functions in `public`, now and for objects created later (default
  privileges). The app uses only the API, which connects as the table owner and is not
  affected. Skipped for a role that does not exist (plain Postgres).
- S-01: RLS on `alembic_version` (no policy, not forced: the migrating owner still works).
- S-10: `account_deletions`, the no-PII audit row of each erased account (private RLS).

Every statement is idempotent: it applies cleanly on a project where the owner already ran
the same REVOKEs and ENABLE by hand. Downgrade drops only the table: it gives the client roles
nothing back and leaves RLS on alembic_version, since a revert must never reopen the Data API.

Revision ID: 0025
Revises: 0024
Create Date: 2026-11-05
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls, revoke_client_roles

revision = "0025"
down_revision = "0024"
branch_labels = None
depends_on = None

TABLE = "account_deletions"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("rows_deleted", sa.Integer(), nullable=False),
        sa.Column("photos_deleted", sa.Integer(), nullable=False),
        sa.Column("followup", sa.String(64), nullable=True),
        sa.Column("followup_user_id", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_account_deletions")),
    )
    op.create_index(op.f(f"ix_{TABLE}_followup_user_id"), TABLE, ["followup_user_id"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)
        op.execute("ALTER TABLE alembic_version ENABLE ROW LEVEL SECURITY")
        op.execute(revoke_client_roles())


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    op.drop_index(op.f(f"ix_{TABLE}_followup_user_id"), table_name=TABLE)
    op.drop_table(TABLE)
