"""Scouting photo backup (OPEN_QUESTIONS Q34): nullable object path of the backed-up photo.

The photo file is in a private Supabase Storage bucket (signed URLs only); this column holds
`<owner_id>/<record_id>.jpg` once the phone has uploaded it, None while it is phone-only.

Revision ID: 0021
Revises: 0020
Create Date: 2026-10-27
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0021"
down_revision = "0020"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("scouting_records") as batch:
        batch.add_column(sa.Column("photo_key", sa.String(120), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("scouting_records") as batch:
        batch.drop_column("photo_key")
