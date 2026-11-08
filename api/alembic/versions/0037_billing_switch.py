"""Billing switch and per-role monthly amounts (billing addendum §7).

`billing_settings` (one row: switch, default OFF, optional start date) and `billing_role_prices`
(monthly amount per role, empty = free; Play's reported price). Private (admin API only).

Revision ID: 0037
Revises: 0036
Create Date: 2026-11-07
"""

from __future__ import annotations

from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0037"
down_revision = "0036"
branch_labels = None
depends_on = None

PRIVATE = ("billing_settings", "billing_role_prices")


def _stamps() -> list[sa.Column[Any]]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "billing_settings",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("starts_on", sa.Date(), nullable=True),
        *_stamps(),
        sa.CheckConstraint("id = 1", name=op.f("ck_billing_settings_single_row")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_billing_settings")),
    )
    op.create_table(
        "billing_role_prices",
        sa.Column("role", sa.String(16), nullable=False),
        sa.Column("amount_paise", sa.BigInteger(), nullable=True),
        sa.Column("play_price_paise", sa.BigInteger(), nullable=True),
        sa.Column("play_currency", sa.String(3), nullable=True),
        sa.Column("play_synced_at", sa.DateTime(timezone=True), nullable=True),
        *_stamps(),
        sa.CheckConstraint(
            "amount_paise IS NULL OR amount_paise > 0", name=op.f("ck_billing_role_prices_amount")
        ),
        sa.PrimaryKeyConstraint("role", name=op.f("pk_billing_role_prices")),
    )
    if op.get_bind().dialect.name == "postgresql":
        for table in PRIVATE:
            for stmt in enable_private_rls(table):
                op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for table in PRIVATE:
            for stmt in disable_private_rls(table):
                op.execute(stmt)
    for table in reversed(PRIVATE):
        op.drop_table(table)
