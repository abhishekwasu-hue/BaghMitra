"""News topic threads (owner Q139): `feed_threads` (service-only) and `feed_items.thread_id`.
Existing published news is threaded by `python -m bagmitra_api.feed.thread_backfill`.

Revision ID: 0046
Revises: 0045
Create Date: 2026-11-11
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0046"
down_revision = "0045"
branch_labels = None
depends_on = None

TABLE = "feed_threads"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("summary", sa.Text(), nullable=True),
        sa.Column("last_item_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_threads")),
    )
    op.create_index(op.f("ix_feed_threads_last_item_at"), TABLE, ["last_item_at"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)
    with op.batch_alter_table("feed_items") as batch:
        batch.add_column(sa.Column("thread_id", sa.Uuid(), nullable=True))
        batch.create_foreign_key(
            op.f("fk_feed_items_thread_id_feed_threads"), TABLE, ["thread_id"], ["id"]
        )
        batch.create_index(op.f("ix_feed_items_thread_id"), ["thread_id"])


def downgrade() -> None:
    with op.batch_alter_table("feed_items") as batch:
        batch.drop_index(op.f("ix_feed_items_thread_id"))
        batch.drop_constraint(op.f("fk_feed_items_thread_id_feed_threads"), type_="foreignkey")
        batch.drop_column("thread_id")
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    op.drop_index(op.f("ix_feed_threads_last_item_at"), table_name=TABLE)
    op.drop_table(TABLE)
