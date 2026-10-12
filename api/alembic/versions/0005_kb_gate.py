"""Legal gate data: CIB&RC label claims, gazette restrictions, trade-name synonyms.

Revision ID: 0005
Revises: 0004
Create Date: 2026-10-12
"""

from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_reference_rls, enable_reference_rls

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None

TABLES = ("kb_label_claims", "kb_restrictions", "kb_synonyms")


def _ts() -> list[sa.Column[datetime]]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def _source_fk(table: str) -> sa.ForeignKeyConstraint:
    return sa.ForeignKeyConstraint(
        ["source_id"], ["kb_sources.id"], name=op.f(f"fk_{table}_source_id_kb_sources")
    )


def upgrade() -> None:
    op.create_table(
        "kb_label_claims",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("active_ingredient", sa.String(120), nullable=False),
        sa.Column("formulation", sa.String(60), nullable=False),
        sa.Column("crop", sa.String(60), nullable=False),
        sa.Column("target", sa.String(120), nullable=False),
        sa.Column("dose", sa.String(200), nullable=False),
        sa.Column("interval_days", sa.Integer(), nullable=True),
        sa.Column("phi_days", sa.Integer(), nullable=True),
        sa.Column("max_sprays", sa.Integer(), nullable=True),
        sa.Column("source_id", sa.Uuid(), nullable=False),
        sa.Column("valid_from", sa.DateTime(timezone=True), nullable=False),
        sa.Column("valid_to", sa.DateTime(timezone=True), nullable=True),
        *_ts(),
        _source_fk("kb_label_claims"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_label_claims")),
    )
    op.create_table(
        "kb_restrictions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("active_ingredient", sa.String(120), nullable=False),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("crops", sa.JSON(), nullable=False),
        sa.Column("crop_groups", sa.JSON(), nullable=False),
        sa.Column("notification", sa.String(300), nullable=False),
        sa.Column("effective_from", sa.DateTime(timezone=True), nullable=False),
        sa.Column("source_id", sa.Uuid(), nullable=False),
        *_ts(),
        _source_fk("kb_restrictions"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_restrictions")),
    )
    for table in ("kb_label_claims", "kb_restrictions"):
        op.create_index(op.f(f"ix_{table}_active_ingredient"), table, ["active_ingredient"])
    op.create_table(
        "kb_synonyms",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("active_ingredient", sa.String(120), nullable=False),
        *_ts(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_synonyms")),
        sa.UniqueConstraint("name", name=op.f("uq_kb_synonyms_name")),
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
    op.drop_table("kb_synonyms")
    for table in ("kb_restrictions", "kb_label_claims"):
        op.drop_index(op.f(f"ix_{table}_active_ingredient"), table_name=table)
        op.drop_table(table)
