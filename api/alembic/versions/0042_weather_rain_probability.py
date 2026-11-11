"""Daily chance of rain for the forecast screen (OPEN_QUESTIONS Q134).

Nullable: days stored before this revision, and past days (the provider gives no chance of
rain for them), have none; the next pull fills the forecast days.

Revision ID: 0042
Revises: 0041
Create Date: 2026-11-11
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0042"
down_revision = "0041"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("weather_daily") as batch:
        batch.add_column(sa.Column("rain_prob_pct", sa.Float(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("weather_daily") as batch:
        batch.drop_column("rain_prob_pct")
