"""Bill reading (owner Q136): a count row per read bill photo (owner data, RLS; no photo, no
result) and the admin's bill reading limits per role plan and for farmers without a plan
(empty = the code default).

Revision ID: 0044
Revises: 0043
Create Date: 2026-11-11
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0044"
down_revision = "0043"
branch_labels = None
depends_on = None

TABLE = "bill_reads"
SETTINGS_COLUMNS = ("bill_read_free_daily", "bill_read_free_monthly", "bill_read_daily_total")
ROLE_COLUMNS = ("bill_read_daily", "bill_read_monthly")


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_bill_reads")),
    )
    op.create_index(op.f(f"ix_{TABLE}_owner_id"), TABLE, ["owner_id"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls(TABLE, "owner_id"):
            op.execute(stmt)
    for column in SETTINGS_COLUMNS:
        op.add_column("billing_settings", sa.Column(column, sa.Integer(), nullable=True))
    for column in ROLE_COLUMNS:
        op.add_column("billing_role_prices", sa.Column(column, sa.Integer(), nullable=True))


def downgrade() -> None:
    for column in ROLE_COLUMNS:
        op.drop_column("billing_role_prices", column)
    for column in SETTINGS_COLUMNS:
        op.drop_column("billing_settings", column)
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls(TABLE):
            op.execute(stmt)
    op.drop_index(op.f(f"ix_{TABLE}_owner_id"), table_name=TABLE)
    op.drop_table(TABLE)
