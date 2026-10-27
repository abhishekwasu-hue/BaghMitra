"""Feed G2 (addendum v1.4 §4.8-4.9): dated events, per-farmer receipts and push settings.

`feed_deadlines` is published reference data (visible like its item); `feed_receipts` and
`feed_preferences` are owner data. Items already published get their deadline rows here.

Revision ID: 0020
Revises: 0019
Create Date: 2026-10-27
"""

from __future__ import annotations

import uuid
from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.base import utcnow
from bagmitra_api.db.rls import (
    disable_owner_rls,
    disable_reference_rls,
    enable_feed_published_rls,
    enable_owner_rls,
)

revision = "0020"
down_revision = "0019"
branch_labels = None
depends_on = None

# Same mapping as feed.service.deadline_rows (kept literal: migrations must not drift).
KIND_OF_COLUMN = {
    "deadline": "apply_by",
    "valid_from": "window_open",
    "valid_to": "window_close",
    "payment_date": "payment",
}
STAGES = ("t7", "t2", "t0", "payment", "window_open")


def _ts() -> list[sa.Column[Any]]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def _item_fk(table: str) -> list[Any]:
    return [
        sa.Column("item_id", sa.Uuid(), nullable=False),
        sa.ForeignKeyConstraint(
            ["item_id"], ["feed_items.id"], name=op.f(f"fk_{table}_item_id_feed_items")
        ),
    ]


def upgrade() -> None:
    with op.batch_alter_table("feed_items") as batch:
        batch.add_column(sa.Column("payment_date", sa.Date(), nullable=True))
    deadlines = op.create_table(
        "feed_deadlines",
        sa.Column("id", sa.Uuid(), nullable=False),
        *_item_fk("feed_deadlines"),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=False),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_deadlines")),
        sa.UniqueConstraint("item_id", "kind", name=op.f("uq_feed_deadlines_item_id")),
    )
    op.create_index(op.f("ix_feed_deadlines_item_id"), "feed_deadlines", ["item_id"])
    op.create_index(op.f("ix_feed_deadlines_due_date"), "feed_deadlines", ["due_date"])
    op.create_table(
        "feed_receipts",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        *_item_fk("feed_receipts"),
        sa.Column("seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("dismissed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("remind_requested_at", sa.DateTime(timezone=True), nullable=True),
        *[
            sa.Column(f"{stage}_notified_at", sa.DateTime(timezone=True), nullable=True)
            for stage in STAGES
        ],
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_receipts")),
        sa.UniqueConstraint("owner_id", "item_id", name=op.f("uq_feed_receipts_owner_id")),
    )
    op.create_index(op.f("ix_feed_receipts_owner_id"), "feed_receipts", ["owner_id"])
    op.create_index(op.f("ix_feed_receipts_item_id"), "feed_receipts", ["item_id"])
    op.create_table(
        "feed_preferences",
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("quiet_start", sa.Time(), nullable=False),
        sa.Column("quiet_end", sa.Time(), nullable=False),
        sa.Column("weekly_cap", sa.Integer(), nullable=False),
        sa.Column("opted_out", sa.JSON(), nullable=False),
        sa.Column("digest_weekly", sa.Boolean(), nullable=False),
        sa.Column("last_digest_at", sa.DateTime(timezone=True), nullable=True),
        *_ts(),
        sa.PrimaryKeyConstraint("owner_id", name=op.f("pk_feed_preferences")),
    )

    items = sa.table(
        "feed_items",
        sa.column("id", sa.Uuid()),
        sa.column("status", sa.String()),
        *[sa.column(c, sa.Date()) for c in KIND_OF_COLUMN],
    )
    published = op.get_bind().execute(sa.select(items).where(items.c.status == "published"))
    now = utcnow()
    rows = [
        {
            "id": uuid.uuid4(),
            "item_id": row.id,
            "kind": kind,
            "due_date": getattr(row, column),
            "created_at": now,
            "updated_at": now,
        }
        for row in published
        for column, kind in KIND_OF_COLUMN.items()
        if getattr(row, column) is not None
    ]
    if rows:
        op.bulk_insert(deadlines, rows)

    if op.get_bind().dialect.name == "postgresql":
        statements = [
            *enable_feed_published_rls("feed_deadlines", "item_id"),
            *enable_owner_rls("feed_receipts", "owner_id"),
            *enable_owner_rls("feed_preferences", "owner_id"),
        ]
        for stmt in statements:
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for table in ("feed_preferences", "feed_receipts"):
            for stmt in disable_owner_rls(table):
                op.execute(stmt)
        for stmt in disable_reference_rls("feed_deadlines"):
            op.execute(stmt)
    op.drop_table("feed_preferences")
    op.drop_index(op.f("ix_feed_receipts_item_id"), table_name="feed_receipts")
    op.drop_index(op.f("ix_feed_receipts_owner_id"), table_name="feed_receipts")
    op.drop_table("feed_receipts")
    op.drop_index(op.f("ix_feed_deadlines_due_date"), table_name="feed_deadlines")
    op.drop_index(op.f("ix_feed_deadlines_item_id"), table_name="feed_deadlines")
    op.drop_table("feed_deadlines")
    with op.batch_alter_table("feed_items") as batch:
        batch.drop_column("payment_date")
