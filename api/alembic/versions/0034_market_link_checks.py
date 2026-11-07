"""Market linkage L7 (spec v1.5 §4, §4C): per-check verification records and device sightings.

`verification_checks`: one check the admin did by hand on a free official page (GSTIN, APMC
licence, FSSAI, IEC, APEDA, phone call, place photo) with the number, the result (passed /
failed / cancelled), the page opened, who and when, and when the yearly re-check job listed
it. `device_sightings`: the SHA-256 of a push token per account, so two accounts on one phone
cannot rate each other (Q100). Written by the API only; RLS: a profile's owner reads the checks
on it, an account its own sightings.

Applies after L3 (0032) and L6 (0033).

Revision ID: 0034
Revises: 0033
Create Date: 2026-11-07
"""

from __future__ import annotations

from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_policy_rls, enable_policy_rls

revision = "0034"
down_revision = "0033"
branch_labels = None
depends_on = None

OWN_PROFILE = (
    "(subject_type = 'buyer' AND subject_id IN "
    "(SELECT id FROM buyer_profiles WHERE user_id = auth.uid())) OR "
    "(subject_type = 'broker' AND subject_id IN "
    "(SELECT id FROM broker_profiles WHERE user_id = auth.uid())) OR "
    "(subject_type = 'provider' AND subject_id IN "
    "(SELECT id FROM service_providers WHERE user_id = auth.uid()))"
)
# Read only: the profile's owner sees the checks done on it; each account its own sightings.
POLICIES: dict[str, list[tuple[str, str, str]]] = {
    "verification_checks": [("owner_read", "SELECT", OWN_PROFILE)],
    "device_sightings": [("own_read", "SELECT", "user_id = auth.uid()")],
}
TABLES = tuple(POLICIES)
KINDS = "'gstin', 'apmc', 'fssai', 'iec', 'apeda', 'phone_call', 'place_photo'"


def _row_columns() -> list[sa.Column[Any]]:
    return [
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "verification_checks",
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.String(length=16), nullable=False),
        sa.Column("number", sa.String(length=40), nullable=True),
        sa.Column("result", sa.String(length=16), nullable=False),
        sa.Column("registered_year", sa.SmallInteger(), nullable=True),
        sa.Column("official_url", sa.String(length=300), nullable=True),
        sa.Column("checked_by", sa.Uuid(), nullable=False),
        sa.Column("checked_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("recheck_listed_at", sa.DateTime(timezone=True), nullable=True),
        *_row_columns(),
        sa.CheckConstraint(
            "subject_type IN ('buyer', 'broker', 'provider')",
            name=op.f("ck_verification_checks_subject_type"),
        ),
        sa.CheckConstraint(f"kind IN ({KINDS})", name=op.f("ck_verification_checks_kind")),
        sa.CheckConstraint(
            "result IN ('passed', 'failed', 'cancelled')",
            name=op.f("ck_verification_checks_result"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_verification_checks")),
    )
    with op.batch_alter_table("verification_checks", schema=None) as batch_op:
        for column in ("subject_id", "checked_at"):
            batch_op.create_index(batch_op.f(f"ix_verification_checks_{column}"), [column])
    op.create_table(
        "device_sightings",
        sa.Column("device_hash", sa.String(length=64), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        *_row_columns(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_device_sightings")),
        sa.UniqueConstraint("device_hash", "user_id", name=op.f("uq_device_sightings_device_hash")),
    )
    with op.batch_alter_table("device_sightings", schema=None) as batch_op:
        for column in ("device_hash", "user_id"):
            batch_op.create_index(batch_op.f(f"ix_device_sightings_{column}"), [column])
    if op.get_bind().dialect.name == "postgresql":
        for table, policies in POLICIES.items():
            for stmt in enable_policy_rls(table, policies):
                op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for table, policies in POLICIES.items():
            for stmt in disable_policy_rls(table, [name for name, _, _ in policies]):
                op.execute(stmt)
    for table in reversed(TABLES):
        op.drop_table(table)
