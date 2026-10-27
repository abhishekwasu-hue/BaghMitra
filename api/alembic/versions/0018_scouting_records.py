"""Field scouting log (owner data, RLS). The photo stays on the phone: no photo column.

Revision ID: 0018
Revises: 0017
Create Date: 2026-10-27
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0018"
down_revision = "0017"
branch_labels = None
depends_on = None

TABLE = "scouting_records"
INDEXED = ("owner_id", "plot_id", "bahar_cycle_id", "last_seq")


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar_cycle_id", sa.Uuid(), nullable=True),
        sa.Column("observed_on", sa.Date(), nullable=False),
        sa.Column("item", sa.String(32), nullable=False),
        sa.Column("severity", sa.String(16), nullable=False),
        sa.Column("note", sa.String(500), nullable=True),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_scouting_records")),
    )
    for column in INDEXED:
        op.create_index(op.f(f"ix_{TABLE}_{column}"), TABLE, [column])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls(TABLE, "owner_id"):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls(TABLE):
            op.execute(stmt)
    for column in reversed(INDEXED):
        op.drop_index(op.f(f"ix_{TABLE}_{column}"), table_name=TABLE)
    op.drop_table(TABLE)
