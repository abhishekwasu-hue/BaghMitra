"""Emoji reactions to feed items and bundled Q&A answers (OPEN_QUESTIONS Q146).

`feed_reactions`: one row per reader and target, where the target is a feed item (`item_id`)
or a Q&A answer bundled in the app (`qa_id`), never both. Owner data: RLS lets a user read and
write only their own rows; the API (privileged role) reads counts across owners. Erased with
the account (owner-scoped, found by `account.erase.owner_tables`).

Revision ID: 0051
Revises: 0050
Create Date: 2026-11-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0051"
down_revision = "0050"
branch_labels = None
depends_on = None

TABLE = "feed_reactions"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("item_id", sa.Uuid(), nullable=True),
        sa.Column("qa_id", sa.String(64), nullable=True),
        sa.Column("reaction", sa.String(16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "(item_id IS NULL) <> (qa_id IS NULL)", name=op.f("ck_feed_reactions_one_target")
        ),
        sa.CheckConstraint(
            "reaction IN ('useful', 'thanks', 'liked', 'okay', 'unclear')",
            name=op.f("ck_feed_reactions_reaction"),
        ),
        sa.ForeignKeyConstraint(
            ["item_id"], ["feed_items.id"], name=op.f("fk_feed_reactions_item_id_feed_items")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_reactions")),
        sa.UniqueConstraint("item_id", "owner_id", name=op.f("uq_feed_reactions_item_id")),
        sa.UniqueConstraint("qa_id", "owner_id", name=op.f("uq_feed_reactions_qa_id")),
    )
    for column in ("owner_id", "item_id", "qa_id"):
        op.create_index(op.f(f"ix_feed_reactions_{column}"), TABLE, [column])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls(TABLE, "owner_id"):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls(TABLE):
            op.execute(stmt)
    for column in ("qa_id", "item_id", "owner_id"):
        op.drop_index(op.f(f"ix_feed_reactions_{column}"), table_name=TABLE)
    op.drop_table(TABLE)
