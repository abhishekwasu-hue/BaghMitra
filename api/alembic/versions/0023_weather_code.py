"""Daily WMO weather code for the storm / hail rules (OPEN_QUESTIONS Q38).

Nullable: days stored before this revision have no code and simply never trigger the
thunderstorm rule until the next pull refreshes them.

Revision ID: 0023
Revises: 0022
Create Date: 2026-10-28
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0023"
down_revision = "0022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("weather_daily") as batch:
        batch.add_column(sa.Column("weather_code", sa.Float(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("weather_daily") as batch:
        batch.drop_column("weather_code")
