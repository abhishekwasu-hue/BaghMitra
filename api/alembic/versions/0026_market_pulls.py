"""Scheduled market pull outcomes (audit BG-04; service-only, no owner data).

`market_pulls` holds one row per Agmarknet commodity: when the scheduled pull last ran, when
it last succeeded and the reason code of its last failure. The price read path no longer
fetches inside a user request; it reads this row to mark stored prices stale.

Idempotent: the table is created only when missing, and the downgrade drops it only when it
exists. The 0025 default privileges already keep the client roles off the new table.

Revision ID: 0026
Revises: 0025
Create Date: 2026-11-05
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0026"
down_revision = "0025"
branch_labels = None
depends_on = None

TABLE = "market_pulls"


def _exists() -> bool:
    return sa.inspect(op.get_bind()).has_table(TABLE)


def upgrade() -> None:
    if not _exists():
        op.create_table(
            TABLE,
            sa.Column("commodity", sa.String(80), nullable=False),
            sa.Column("last_attempt_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("last_success_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("last_error", sa.String(32), nullable=True),
            sa.Column("last_rows", sa.Integer(), nullable=False),
            sa.PrimaryKeyConstraint("commodity", name=op.f("pk_market_pulls")),
        )
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)


def downgrade() -> None:
    if not _exists():
        return
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    op.drop_table(TABLE)
