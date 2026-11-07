"""Market linkage L2 (spec v1.5 §4): FSSAI licence and APEDA registration numbers on
buyer_profiles, kept for the admin's manual check on the official public page (no automation,
no paid KYC). Indexed, not unique, like GSTIN / IEC / APMC (Q80).

Revision ID: 0031
Revises: 0030
Create Date: 2026-11-07
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0031"
down_revision = "0030"
branch_labels = None
depends_on = None

COLUMNS = {"fssai_no": 14, "apeda_no": 40}


def upgrade() -> None:
    with op.batch_alter_table("buyer_profiles", schema=None) as batch_op:
        for name, length in COLUMNS.items():
            batch_op.add_column(sa.Column(name, sa.String(length=length), nullable=True))
            batch_op.create_index(batch_op.f(f"ix_buyer_profiles_{name}"), [name], unique=False)


def downgrade() -> None:
    with op.batch_alter_table("buyer_profiles", schema=None) as batch_op:
        for name in COLUMNS:
            batch_op.drop_index(batch_op.f(f"ix_buyer_profiles_{name}"))
            batch_op.drop_column(name)
