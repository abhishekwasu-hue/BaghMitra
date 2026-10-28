"""Crop insurance policy records (owner data, RLS; OPEN_QUESTIONS Q37).

Revision ID: 0022
Revises: 0021
Create Date: 2026-10-28
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0022"
down_revision = "0021"
branch_labels = None
depends_on = None

TABLE = "insurance_policies"
INDEXED = ("owner_id", "plot_id", "last_seq")


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("scheme", sa.String(16), nullable=False),
        sa.Column("season", sa.String(16), nullable=False),
        sa.Column("season_year", sa.Integer(), nullable=True),
        sa.Column("insurer_name", sa.String(120), nullable=True),
        sa.Column("policy_number", sa.String(60), nullable=True),
        sa.Column("sum_insured_paise", sa.BigInteger(), nullable=True),
        sa.Column("premium_paid_paise", sa.BigInteger(), nullable=True),
        sa.Column("enrolled_on", sa.Date(), nullable=True),
        sa.Column("note", sa.String(500), nullable=True),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_insurance_policies")),
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
