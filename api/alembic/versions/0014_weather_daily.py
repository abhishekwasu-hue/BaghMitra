"""Daily weather per location cell (M4; service-only, no owner data).

Revision ID: 0014
Revises: 0013
Create Date: 2026-10-26
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0014"
down_revision = "0013"
branch_labels = None
depends_on = None

TABLE = "weather_daily"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("cell_lat", sa.Float(), nullable=False),
        sa.Column("cell_lon", sa.Float(), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("t_max_c", sa.Float(), nullable=True),
        sa.Column("t_min_c", sa.Float(), nullable=True),
        sa.Column("precip_mm", sa.Float(), nullable=True),
        sa.Column("rh_mean_pct", sa.Float(), nullable=True),
        sa.Column("wind_gust_kmh", sa.Float(), nullable=True),
        sa.Column("fetched_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("cell_lat", "cell_lon", "day", name=op.f("pk_weather_daily")),
    )
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    op.drop_table(TABLE)
