"""Update pushes (owner 2026-11-12, OPEN_QUESTIONS Q147): new articles, market price changes
and sudden weather changes (`push/updates.py`).

- `push_topic_prefs` (owner data, RLS owner policy): each grower's three switches; no row
  means the defaults (all on).
- `push_notices` (owner data, RLS owner policy): what each update push told whom, once
  (unique per owner, kind and subject); weather rows wait here until sent.
- `push_weather_seen` (service only: RLS forced with one policy that matches no row): the
  forecast per weather cell and day as the change check last compared it.

Revision ID: 0052
Revises: 0051
Create Date: 2026-11-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import (
    disable_owner_rls,
    disable_policy_rls,
    enable_owner_rls,
    enable_policy_rls,
)

revision = "0052"
down_revision = "0051"
branch_labels = None
depends_on = None

PREFS = "push_topic_prefs"
NOTICES = "push_notices"
SEEN = "push_weather_seen"
SEEN_POLICIES = [("service_only", "SELECT", "false")]


def upgrade() -> None:
    op.create_table(
        PREFS,
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("articles", sa.Boolean(), nullable=False),
        sa.Column("market", sa.Boolean(), nullable=False),
        sa.Column("weather_change", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("owner_id", name=op.f(f"pk_{PREFS}")),
    )
    op.create_table(
        NOTICES,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("subject", sa.String(300), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=True),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("data", sa.JSON(), nullable=False),
        sa.Column("push_id", sa.Uuid(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notified_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id", name=op.f(f"pk_{NOTICES}")),
        sa.UniqueConstraint("owner_id", "kind", "subject", name=op.f(f"uq_{NOTICES}_owner_id")),
    )
    op.create_index(op.f(f"ix_{NOTICES}_owner_id"), NOTICES, ["owner_id"])
    op.create_index(op.f(f"ix_{NOTICES}_day"), NOTICES, ["day"])
    op.create_table(
        SEEN,
        sa.Column("cell_lat", sa.Float(), nullable=False),
        sa.Column("cell_lon", sa.Float(), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("rain_prob_pct", sa.Float(), nullable=True),
        sa.Column("precip_mm", sa.Float(), nullable=True),
        sa.Column("wind_gust_kmh", sa.Float(), nullable=True),
        sa.Column("t_max_c", sa.Float(), nullable=True),
        sa.Column("t_min_c", sa.Float(), nullable=True),
        sa.Column("seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("cell_lat", "cell_lon", "day", name=op.f(f"pk_{SEEN}")),
    )
    if op.get_bind().dialect.name == "postgresql":
        for table in (PREFS, NOTICES):
            for stmt in enable_owner_rls(table, "owner_id"):
                op.execute(stmt)
        for stmt in enable_policy_rls(SEEN, SEEN_POLICIES):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_policy_rls(SEEN, [n for n, _, _ in SEEN_POLICIES]):
            op.execute(stmt)
        for table in (NOTICES, PREFS):
            for stmt in disable_owner_rls(table):
                op.execute(stmt)
    op.drop_table(SEEN)
    op.drop_index(op.f(f"ix_{NOTICES}_day"), table_name=NOTICES)
    op.drop_index(op.f(f"ix_{NOTICES}_owner_id"), table_name=NOTICES)
    op.drop_table(NOTICES)
    op.drop_table(PREFS)
