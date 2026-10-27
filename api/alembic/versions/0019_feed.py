"""Government GR, scheme and news feed (addendum v1.4 G0), with the §3 source registry.

Revision ID: 0019
Revises: 0018
Create Date: 2026-10-27
"""

from __future__ import annotations

import uuid
from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.base import utcnow
from bagmitra_api.db.rls import (
    disable_private_rls,
    disable_reference_rls,
    enable_feed_published_rls,
    enable_private_rls,
    enable_reference_rls,
)
from bagmitra_api.feed.seed import source_seeds

revision = "0019"
down_revision = "0018"
branch_labels = None
depends_on = None


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
    sources = op.create_table(
        "feed_sources",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("key", sa.String(64), nullable=False),
        sa.Column("name", sa.String(300), nullable=False),
        sa.Column("url", sa.String(1000), nullable=False),
        sa.Column("tier", sa.String(16), nullable=False),
        sa.Column("terms_status", sa.String(16), nullable=False),
        sa.Column("fetch_method", sa.String(16), nullable=False),
        sa.Column("fetch_status", sa.String(16), nullable=False),
        sa.Column("last_ok_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_sources")),
        sa.UniqueConstraint("key", name=op.f("uq_feed_sources_key")),
    )
    op.create_table(
        "feed_items",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("type", sa.String(16), nullable=False),
        sa.Column("source_id", sa.Uuid(), nullable=False),
        sa.Column("external_id", sa.String(120), nullable=True),
        sa.Column("gr_number", sa.String(120), nullable=True),
        sa.Column("department", sa.String(200), nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("url", sa.String(1000), nullable=False),
        sa.Column("raw_hash", sa.String(64), nullable=True),
        sa.Column("raw_bytes", sa.Integer(), nullable=True),
        sa.Column("extracted_text", sa.Text(), nullable=True),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("trust_level", sa.String(16), nullable=False),
        sa.Column("valid_from", sa.Date(), nullable=True),
        sa.Column("valid_to", sa.Date(), nullable=True),
        sa.Column("deadline", sa.Date(), nullable=True),
        sa.Column("replaced_by_id", sa.Uuid(), nullable=True),
        sa.Column("check_issues", sa.JSON(), nullable=False),
        sa.Column("approved_by", sa.Uuid(), nullable=True),
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
        *_ts(),
        sa.ForeignKeyConstraint(
            ["source_id"], ["feed_sources.id"], name=op.f("fk_feed_items_source_id_feed_sources")
        ),
        sa.ForeignKeyConstraint(
            ["replaced_by_id"],
            ["feed_items.id"],
            name=op.f("fk_feed_items_replaced_by_id_feed_items"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_items")),
        sa.UniqueConstraint("source_id", "external_id", name=op.f("uq_feed_items_source_id")),
    )
    for column in ("source_id", "published_at", "raw_hash", "status"):
        op.create_index(op.f(f"ix_feed_items_{column}"), "feed_items", [column])
    op.create_table(
        "feed_item_i18n",
        sa.Column("id", sa.Uuid(), nullable=False),
        *_item_fk("feed_item_i18n"),
        sa.Column("lang", sa.String(2), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("summary", sa.Text(), nullable=True),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_item_i18n")),
        sa.UniqueConstraint("item_id", "lang", name=op.f("uq_feed_item_i18n_item_id")),
    )
    op.create_table(
        "feed_scheme_cards",
        sa.Column("id", sa.Uuid(), nullable=False),
        *_item_fk("feed_scheme_cards"),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("fields", sa.JSON(), nullable=False),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_scheme_cards")),
        sa.UniqueConstraint("item_id", "version", name=op.f("uq_feed_scheme_cards_item_id")),
    )
    op.create_table(
        "feed_item_targets",
        sa.Column("id", sa.Uuid(), nullable=False),
        *_item_fk("feed_item_targets"),
        sa.Column("district", sa.String(120), nullable=True),
        sa.Column("crop", sa.String(32), nullable=True),
        sa.Column("min_ha", sa.Float(), nullable=True),
        sa.Column("max_ha", sa.Float(), nullable=True),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_item_targets")),
    )
    op.create_table(
        "feed_review_events",
        sa.Column("id", sa.Uuid(), nullable=False),
        *_item_fk("feed_review_events"),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column("kind", sa.String(32), nullable=False),
        sa.Column("detail", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_feed_review_events")),
    )
    for table in CHILDREN:
        op.create_index(op.f(f"ix_{table}_item_id"), table, ["item_id"])

    now = utcnow()
    op.bulk_insert(
        sources,
        [
            {
                **seed,
                "id": uuid.uuid4(),
                "terms_status": "unknown",
                "fetch_status": "not_fetched",
                "created_at": now,
                "updated_at": now,
            }
            for seed in source_seeds()
        ],
    )

    if op.get_bind().dialect.name == "postgresql":
        statements = [
            *enable_reference_rls("feed_sources"),
            *enable_feed_published_rls("feed_items"),
            *[s for t in PUBLISHED_CHILDREN for s in enable_feed_published_rls(t, "item_id")],
            *enable_private_rls("feed_review_events"),
        ]
        for stmt in statements:
            op.execute(stmt)


PUBLISHED_CHILDREN = ("feed_item_i18n", "feed_scheme_cards", "feed_item_targets")
CHILDREN = (*PUBLISHED_CHILDREN, "feed_review_events")


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls("feed_review_events"):
            op.execute(stmt)
        for table in (*PUBLISHED_CHILDREN, "feed_items", "feed_sources"):
            for stmt in disable_reference_rls(table):
                op.execute(stmt)
    for table in CHILDREN:
        op.drop_index(op.f(f"ix_{table}_item_id"), table_name=table)
        op.drop_table(table)
    for column in ("source_id", "published_at", "raw_hash", "status"):
        op.drop_index(op.f(f"ix_feed_items_{column}"), table_name="feed_items")
    op.drop_table("feed_items")
    op.drop_table("feed_sources")
