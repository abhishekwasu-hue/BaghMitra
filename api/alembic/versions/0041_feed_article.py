"""AI news articles (spec v1.6): the article per language; status "held" needs no schema change.

Revision ID: 0041
Revises: 0040
Create Date: 2026-11-09
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0041"
down_revision = "0040"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("feed_item_i18n", sa.Column("article", sa.JSON(), nullable=True))


def downgrade() -> None:
    op.execute("UPDATE feed_items SET status = 'in_review' WHERE status = 'held'")
    op.drop_column("feed_item_i18n", "article")
