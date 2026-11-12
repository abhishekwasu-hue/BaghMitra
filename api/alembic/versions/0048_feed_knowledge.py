"""Knowledge articles (owner 2026-11-11): `feed_knowledge_runs` (service-only), the knowledge
job's per-topic decisions used for its dedupe. The articles themselves are `feed_items` of type
`knowledge`; their source row (`bagmitra_knowledge`) is registered by the job (seed).

Revision ID: 0048
Revises: 0047
Create Date: 2026-11-11
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0048"
down_revision = "0047"
branch_labels = None
depends_on = None

TABLE = "feed_knowledge_runs"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("topic_key", sa.String(160), nullable=False),
        sa.Column("trigger", sa.String(16), nullable=False),
        sa.Column("source_hash", sa.String(64), nullable=False),
        sa.Column("window_end", sa.Date(), nullable=True),
        sa.Column("item_id", sa.Uuid(), nullable=True),
        sa.Column("result", sa.String(16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["item_id"], ["feed_items.id"], name=op.f("fk_feed_knowledge_runs_item_id_feed_items")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_knowledge_runs")),
    )
    op.create_index(op.f("ix_feed_knowledge_runs_topic_key"), TABLE, ["topic_key"])
    op.create_index(op.f("ix_feed_knowledge_runs_item_id"), TABLE, ["item_id"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    op.drop_index(op.f("ix_feed_knowledge_runs_item_id"), table_name=TABLE)
    op.drop_index(op.f("ix_feed_knowledge_runs_topic_key"), table_name=TABLE)
    op.drop_table(TABLE)
