"""Input (fertiliser / manure) and irrigation records (owner data, RLS).

Revision ID: 0009
Revises: 0008
Create Date: 2026-10-19
"""

from __future__ import annotations

from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None

TABLES = ("input_records", "irrigation_records")
INDEXED = ("owner_id", "plot_id", "bahar_cycle_id", "last_seq")


def _owned() -> list[sa.Column[Any]]:
    return [
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "input_records",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar_cycle_id", sa.Uuid(), nullable=True),
        sa.Column("applied_on", sa.Date(), nullable=False),
        sa.Column("kind", sa.String(32), nullable=False),
        sa.Column("product_name", sa.String(120), nullable=False),
        sa.Column("quantity", sa.Float(), nullable=True),
        sa.Column("unit", sa.String(16), nullable=True),
        sa.Column("cost_paise", sa.BigInteger(), nullable=False),
        sa.Column("note", sa.String(500), nullable=True),
        *_owned(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_input_records")),
    )
    op.create_table(
        "irrigation_records",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar_cycle_id", sa.Uuid(), nullable=True),
        sa.Column("irrigated_on", sa.Date(), nullable=False),
        sa.Column("duration_hours", sa.Float(), nullable=True),
        sa.Column("water_litres", sa.Float(), nullable=True),
        sa.Column("note", sa.String(500), nullable=True),
        *_owned(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_irrigation_records")),
    )
    for table in TABLES:
        for column in INDEXED:
            op.create_index(op.f(f"ix_{table}_{column}"), table, [column])
        if op.get_bind().dialect.name == "postgresql":
            for stmt in enable_owner_rls(table, "owner_id"):
                op.execute(stmt)


def downgrade() -> None:
    for table in reversed(TABLES):
        if op.get_bind().dialect.name == "postgresql":
            for stmt in disable_owner_rls(table):
                op.execute(stmt)
        for column in reversed(INDEXED):
            op.drop_index(op.f(f"ix_{table}_{column}"), table_name=table)
        op.drop_table(table)
