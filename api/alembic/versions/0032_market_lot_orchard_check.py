"""Real orchard check on market lots (spec v1.5 §4C, build prompt L3, OPEN_QUESTIONS Q76).

`market_lots.orchard_check`: where the lot's photos were taken against the grower's mapped
plot, set at publish: inside / near (within `market_link_orchard_near_m`) / outside / unmapped.
Only inside or near lots reach verified traders and brokers; the others wait for an admin
check (admin side later). The verified-read policy of 0029 gains the same condition.

Revision ID: 0032
Revises: 0031
Create Date: 2026-11-07
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0032"
down_revision = "0031"
branch_labels = None
depends_on = None

POLICY = "market_lots_verified_read"
_VISIBLE = "status = 'published' AND deleted_at IS NULL AND ml_viewer_verified()"
_CHECKED = " AND orchard_check IN ('inside', 'near')"


def _policy(using: str) -> list[str]:
    return [
        f"DROP POLICY IF EXISTS {POLICY} ON market_lots",
        f"CREATE POLICY {POLICY} ON market_lots FOR SELECT USING ({using})",
    ]


def upgrade() -> None:
    with op.batch_alter_table("market_lots", schema=None) as batch_op:
        batch_op.add_column(sa.Column("orchard_check", sa.String(length=16), nullable=True))
        batch_op.create_check_constraint(
            "orchard_check",
            "orchard_check IN ('inside', 'near', 'outside', 'unmapped')",
        )
    if op.get_bind().dialect.name == "postgresql":
        for stmt in _policy(_VISIBLE + _CHECKED):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in _policy(_VISIBLE):
            op.execute(stmt)
    with op.batch_alter_table("market_lots", schema=None) as batch_op:
        batch_op.drop_constraint("orchard_check", type_="check")
        batch_op.drop_column("orchard_check")
