"""Knowledge base: sources, topics, cards, reviews, conflicts (addendum v1.3 §5).

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-12
"""

from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_reference_rls, enable_reference_rls

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None

TABLES = ("kb_sources", "kb_topics", "kb_cards", "kb_reviews", "kb_conflicts")


def _ts() -> list[sa.Column[datetime]]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "kb_sources",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("key", sa.String(64), nullable=False),
        sa.Column("title", sa.String(400), nullable=False),
        sa.Column("publisher", sa.String(200), nullable=False),
        sa.Column("url", sa.String(1000), nullable=False),
        sa.Column("tier", sa.String(16), nullable=False),
        sa.Column("licence", sa.String(200), nullable=False),
        sa.Column("allowed_use", sa.String(16), nullable=False),
        sa.Column("verification", sa.String(4), nullable=False),
        sa.Column("fetched_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("content_hash", sa.String(64), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_sources")),
        sa.UniqueConstraint("key", name=op.f("uq_kb_sources_key")),
    )
    op.create_table(
        "kb_topics",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("key", sa.String(64), nullable=False),
        sa.Column("kind", sa.String(32), nullable=False),
        sa.Column("labels", sa.JSON(), nullable=False),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_topics")),
        sa.UniqueConstraint("key", name=op.f("uq_kb_topics_key")),
    )
    op.create_table(
        "kb_cards",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("topic_id", sa.Uuid(), nullable=False),
        sa.Column("crop", sa.String(32), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("content", sa.JSON(), nullable=False),
        sa.Column("reviewed_languages", sa.JSON(), nullable=False),
        sa.Column("chemical_options", sa.JSON(), nullable=False),
        sa.Column("sources", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("review_due_at", sa.DateTime(timezone=True), nullable=True),
        *_ts(),
        sa.ForeignKeyConstraint(
            ["topic_id"], ["kb_topics.id"], name=op.f("fk_kb_cards_topic_id_kb_topics")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_cards")),
    )
    op.create_index(op.f("ix_kb_cards_topic_id"), "kb_cards", ["topic_id"])
    op.create_table(
        "kb_reviews",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("card_id", sa.Uuid(), nullable=False),
        sa.Column("card_version", sa.Integer(), nullable=False),
        sa.Column("reviewer_id", sa.Uuid(), nullable=False),
        sa.Column("reviewer_role", sa.String(32), nullable=False),
        sa.Column("decision", sa.String(16), nullable=False),
        sa.Column("comments", sa.Text(), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        *_ts(),
        sa.ForeignKeyConstraint(
            ["card_id"], ["kb_cards.id"], name=op.f("fk_kb_reviews_card_id_kb_cards")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_reviews")),
    )
    op.create_index(op.f("ix_kb_reviews_card_id"), "kb_reviews", ["card_id"])
    op.create_table(
        "kb_conflicts",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("topic_id", sa.Uuid(), nullable=True),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("values", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("resolution", sa.Text(), nullable=True),
        *_ts(),
        sa.ForeignKeyConstraint(
            ["topic_id"], ["kb_topics.id"], name=op.f("fk_kb_conflicts_topic_id_kb_topics")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_conflicts")),
    )
    if op.get_bind().dialect.name == "postgresql":
        for table in TABLES:
            for stmt in enable_reference_rls(table):
                op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for table in TABLES:
            for stmt in disable_reference_rls(table):
                op.execute(stmt)
    op.drop_table("kb_conflicts")
    op.drop_index(op.f("ix_kb_reviews_card_id"), table_name="kb_reviews")
    op.drop_table("kb_reviews")
    op.drop_index(op.f("ix_kb_cards_topic_id"), table_name="kb_cards")
    op.drop_table("kb_cards")
    op.drop_table("kb_topics")
    op.drop_table("kb_sources")
