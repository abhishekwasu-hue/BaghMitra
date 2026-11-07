"""Feed items: `date_is_first_seen` (news items whose source gives no date, e.g. PIB RSS).

When an RSS item carries no date, `published_at` holds the time our fetcher first stored it and
this flag is true; no publication date is invented. Existing rows are dated by their source.

Revision ID: 0036
Revises: 0035
Create Date: 2026-11-07
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0036"
down_revision = "0035"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("feed_items", schema=None) as batch_op:
        batch_op.add_column(
            sa.Column("date_is_first_seen", sa.Boolean(), nullable=False, server_default=sa.false())
        )


def downgrade() -> None:
    with op.batch_alter_table("feed_items", schema=None) as batch_op:
        batch_op.drop_column("date_is_first_seen")
