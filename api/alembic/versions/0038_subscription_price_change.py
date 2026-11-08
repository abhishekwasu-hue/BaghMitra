"""Subscriptions: `price_change` (billing addendum §7).

Play's pending price change of a subscription (state, new price, expected charge time), kept so
the app can show the required in-app notice of a price increase. Null when there is none.

Revision ID: 0038
Revises: 0037
Create Date: 2026-11-07
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0038"
down_revision = "0037"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("subscriptions", schema=None) as batch_op:
        batch_op.add_column(sa.Column("price_change", sa.JSON(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("subscriptions", schema=None) as batch_op:
        batch_op.drop_column("price_change")
