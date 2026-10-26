"""Published mandi prices (M5; service-only, no owner data).

Revision ID: 0015
Revises: 0014
Create Date: 2026-10-26
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0015"
down_revision = "0014"
branch_labels = None
depends_on = None

TABLE = "market_prices"
KEY = ("day", "market", "commodity", "variety", "grade", "source")


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("market", sa.String(80), nullable=False),
        sa.Column("commodity", sa.String(80), nullable=False),
        sa.Column("variety", sa.String(80), nullable=False),
        sa.Column("grade", sa.String(40), nullable=False),
        sa.Column("source", sa.String(32), nullable=False),
        sa.Column("district", sa.String(80), nullable=False),
        sa.Column("min_rs_per_quintal", sa.Integer(), nullable=True),
        sa.Column("max_rs_per_quintal", sa.Integer(), nullable=True),
        sa.Column("modal_rs_per_quintal", sa.Integer(), nullable=False),
        sa.Column("fetched_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint(*KEY, name=op.f("pk_market_prices")),
    )
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    op.drop_table(TABLE)
