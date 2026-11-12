"""Feed sources: the one-off 30-day backfill (owner 2026-11-12, OPEN_QUESTIONS Q145).

`feed_sources.backfill_done_at` is a nullable timestamp: when the source's past ~30 days
(older RSS pages or daily sitemaps) were read completely. Null means the backfill is still to
do, so the next scheduled run continues it (capped per run) from `backfill_cursor`, the last
page or day read completely (null: from the start). Existing rows keep null, so every source
enabled by this deploy is backfilled once. No new table, so the row-level security of
`feed_sources` covers it.

Revision ID: 0053
Revises: 0052
Create Date: 2026-11-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0053"
down_revision = "0052"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("feed_sources") as batch:
        batch.add_column(sa.Column("backfill_done_at", sa.DateTime(timezone=True), nullable=True))
        batch.add_column(sa.Column("backfill_cursor", sa.String(length=64), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("feed_sources") as batch:
        batch.drop_column("backfill_cursor")
        batch.drop_column("backfill_done_at")
