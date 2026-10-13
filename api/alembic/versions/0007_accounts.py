"""Grower accounts: expenses and incomes (owner data, RLS).

Revision ID: 0007
Revises: 0006
Create Date: 2026-10-13
"""

from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None

INDEXED = ("owner_id", "plot_id", "bahar_cycle_id", "last_seq")


def _owned() -> list[sa.Column[datetime]]:
    return [
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "expenses",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar_cycle_id", sa.Uuid(), nullable=True),
        sa.Column("spent_on", sa.Date(), nullable=False),
        sa.Column("category", sa.String(32), nullable=False),
        sa.Column("amount_paise", sa.BigInteger(), nullable=False),
        sa.Column("note", sa.String(500), nullable=True),
        *_owned(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_expenses")),
    )
    op.create_table(
        "incomes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar_cycle_id", sa.Uuid(), nullable=True),
        sa.Column("sold_on", sa.Date(), nullable=False),
        sa.Column("buyer_name", sa.String(120), nullable=False),
        sa.Column("grade", sa.String(32), nullable=True),
        sa.Column("quantity_kg", sa.Float(), nullable=False),
        sa.Column("rate_paise_per_quintal", sa.BigInteger(), nullable=False),
        sa.Column("deductions_paise", sa.BigInteger(), nullable=False),
        sa.Column("payment_status", sa.String(16), nullable=False),
        sa.Column("paid_paise", sa.BigInteger(), nullable=False),
        sa.Column("paid_on", sa.Date(), nullable=True),
        *_owned(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_incomes")),
    )
    for table in ("expenses", "incomes"):
        for column in INDEXED:
            op.create_index(op.f(f"ix_{table}_{column}"), table, [column])
        if op.get_bind().dialect.name == "postgresql":
            for stmt in enable_owner_rls(table, "owner_id"):
                op.execute(stmt)


def downgrade() -> None:
    for table in ("incomes", "expenses"):
        if op.get_bind().dialect.name == "postgresql":
            for stmt in disable_owner_rls(table):
                op.execute(stmt)
        for column in reversed(INDEXED):
            op.drop_index(op.f(f"ix_{table}_{column}"), table_name=table)
        op.drop_table(table)
