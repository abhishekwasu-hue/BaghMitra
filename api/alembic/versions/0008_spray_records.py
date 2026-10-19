"""Spray records (owner data, RLS).

Revision ID: 0008
Revises: 0007
Create Date: 2026-10-19
"""

from __future__ import annotations

from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None

TABLE = "spray_records"
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
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar_cycle_id", sa.Uuid(), nullable=True),
        sa.Column("sprayed_on", sa.Date(), nullable=False),
        sa.Column("product_name", sa.String(120), nullable=False),
        sa.Column("active_ingredient", sa.String(120), nullable=True),
        sa.Column("dose", sa.String(200), nullable=True),
        sa.Column("water_litres", sa.Float(), nullable=True),
        sa.Column("area_acres", sa.Float(), nullable=True),
        sa.Column("cost_paise", sa.BigInteger(), nullable=False),
        sa.Column("operator", sa.String(120), nullable=True),
        sa.Column("phi_days", sa.Integer(), nullable=True),
        sa.Column("target", sa.String(120), nullable=True),
        *_owned(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_spray_records")),
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
