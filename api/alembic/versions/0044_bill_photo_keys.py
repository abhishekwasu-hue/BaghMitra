"""Backed-up bill photo key on spray records and expenses (OPEN_QUESTIONS Q136).

Nullable: the photo stays on the phone unless the optional photo backup uploads it to
`<owner_id>/bill-<record_id>.jpg`; existing rows have none.

Revision ID: 0044
Revises: 0043
Create Date: 2026-11-11
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0044"
down_revision = "0043"
branch_labels = None
depends_on = None

TABLES = ("spray_records", "expenses")


def upgrade() -> None:
    for table in TABLES:
        with op.batch_alter_table(table) as batch:
            batch.add_column(sa.Column("bill_photo_key", sa.String(length=120), nullable=True))


def downgrade() -> None:
    for table in TABLES:
        with op.batch_alter_table(table) as batch:
            batch.drop_column("bill_photo_key")
