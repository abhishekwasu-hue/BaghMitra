"""Label-claim details for the label information screen (owner decision Q57, WP4).

`kb_label_claims` gains the rest of a CIB&RC "Major Uses" row and plain product facts:
`category` (chemical | bio), `dilution` (water L/ha as printed), `page_ref` (where the row
sits in the source document), `description` (mode of action from the label / official
source), `brand_names` (plain list), `maker_url` (the maker's official product page) and
`photo_url` (an optional owner-set photo; no copied images). `target` widens from 120 to 300
characters: some printed targets (a list of fungi or weed species) are longer, and they are kept
whole as printed.

Idempotent: each column is added only when missing; the downgrade drops only those present.

Revision ID: 0028
Revises: 0027
Create Date: 2026-11-06
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0028"
down_revision = "0027"
branch_labels = None
depends_on = None

TABLE = "kb_label_claims"


def _new_columns() -> list[sa.Column[object]]:
    return [
        sa.Column("category", sa.String(16), nullable=False, server_default="chemical"),
        sa.Column("dilution", sa.String(120), nullable=True),
        sa.Column("page_ref", sa.String(60), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("brand_names", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
        sa.Column("maker_url", sa.String(500), nullable=True),
        sa.Column("photo_url", sa.String(500), nullable=True),
    ]


NAMES = ("category", "dilution", "page_ref", "description", "brand_names", "maker_url", "photo_url")


def _columns() -> set[str]:
    return {c["name"] for c in sa.inspect(op.get_bind()).get_columns(TABLE)}


def upgrade() -> None:
    present = _columns()
    missing = [c for c in _new_columns() if c.name not in present]
    with op.batch_alter_table(TABLE) as batch:
        for column in missing:
            batch.add_column(column)
        # Widening is idempotent; the downgrade keeps the width (narrowing could cut rows).
        batch.alter_column(
            "target", existing_type=sa.String(120), type_=sa.String(300), existing_nullable=False
        )


def downgrade() -> None:
    present = _columns()
    gone = [c for c in reversed(NAMES) if c in present]
    if gone:
        with op.batch_alter_table(TABLE) as batch:
            for name in gone:
                batch.drop_column(name)
