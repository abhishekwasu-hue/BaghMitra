"""Billing: plans, plan entitlements, subscriptions, billing events, entitlement snapshots.

Plans and their features are reference data (any signed-in user may read, only privileged roles
write); subscriptions, the event ledger and snapshots are private (service only).

Revision ID: 0012
Revises: 0011
Create Date: 2026-10-20
"""

from __future__ import annotations

from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import (
    disable_private_rls,
    disable_reference_rls,
    enable_private_rls,
    enable_reference_rls,
)

revision = "0012"
down_revision = "0011"
branch_labels = None
depends_on = None

REFERENCE = ("billing_plans", "plan_entitlements")
PRIVATE = ("subscriptions", "billing_events", "entitlement_snapshots")


def _stamps() -> list[sa.Column[Any]]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "billing_plans",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("key", sa.String(32), nullable=False),
        sa.Column("names", sa.JSON(), nullable=False),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        *_stamps(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_billing_plans")),
        sa.UniqueConstraint("key", name=op.f("uq_billing_plans_key")),
    )
    op.create_table(
        "plan_entitlements",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("plan_id", sa.Uuid(), nullable=False),
        sa.Column("feature_key", sa.String(32), nullable=False),
        sa.Column("limit_value", sa.Integer(), nullable=True),
        *_stamps(),
        sa.ForeignKeyConstraint(
            ["plan_id"],
            ["billing_plans.id"],
            name=op.f("fk_plan_entitlements_plan_id_billing_plans"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_plan_entitlements")),
        sa.UniqueConstraint("plan_id", "feature_key", name=op.f("uq_plan_entitlements_plan_id")),
    )
    op.create_index(op.f("ix_plan_entitlements_plan_id"), "plan_entitlements", ["plan_id"])
    op.create_table(
        "subscriptions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("subject_type", sa.String(16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("plan_id", sa.Uuid(), nullable=False),
        sa.Column("provider", sa.String(16), nullable=False),
        sa.Column("provider_product_id", sa.String(120), nullable=True),
        sa.Column("purchase_token_hash", sa.String(64), nullable=True),
        sa.Column("state", sa.String(16), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("auto_renew", sa.Boolean(), nullable=False),
        sa.Column("grace_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("granted_by", sa.Uuid(), nullable=True),
        *_stamps(),
        sa.ForeignKeyConstraint(
            ["plan_id"], ["billing_plans.id"], name=op.f("fk_subscriptions_plan_id_billing_plans")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_subscriptions")),
        sa.UniqueConstraint(
            "purchase_token_hash", name=op.f("uq_subscriptions_purchase_token_hash")
        ),
    )
    op.create_index(op.f("ix_subscriptions_subject_id"), "subscriptions", ["subject_id"])
    op.create_index(op.f("ix_subscriptions_plan_id"), "subscriptions", ["plan_id"])
    op.create_table(
        "billing_events",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("subscription_id", sa.Uuid(), nullable=True),
        sa.Column("provider", sa.String(16), nullable=False),
        sa.Column("event_type", sa.String(40), nullable=False),
        sa.Column("notification_id", sa.String(120), nullable=True),
        sa.Column("payload", sa.JSON(), nullable=False),
        *_stamps(),
        sa.ForeignKeyConstraint(
            ["subscription_id"],
            ["subscriptions.id"],
            name=op.f("fk_billing_events_subscription_id_subscriptions"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_billing_events")),
        sa.UniqueConstraint("notification_id", name=op.f("uq_billing_events_notification_id")),
    )
    op.create_index(
        op.f("ix_billing_events_subscription_id"), "billing_events", ["subscription_id"]
    )
    op.create_table(
        "entitlement_snapshots",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("subject_type", sa.String(16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("computed", sa.JSON(), nullable=False),
        sa.Column("valid_until", sa.DateTime(timezone=True), nullable=False),
        sa.Column("signature", sa.Text(), nullable=True),
        *_stamps(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_entitlement_snapshots")),
        sa.UniqueConstraint(
            "subject_type", "subject_id", name=op.f("uq_entitlement_snapshots_subject_type")
        ),
    )
    op.create_index(
        op.f("ix_entitlement_snapshots_subject_id"), "entitlement_snapshots", ["subject_id"]
    )
    if op.get_bind().dialect.name == "postgresql":
        for table in REFERENCE:
            for stmt in enable_reference_rls(table):
                op.execute(stmt)
        for table in PRIVATE:
            for stmt in enable_private_rls(table):
                op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for table in reversed(PRIVATE):
            for stmt in disable_private_rls(table):
                op.execute(stmt)
        for table in reversed(REFERENCE):
            for stmt in disable_reference_rls(table):
                op.execute(stmt)
    op.drop_index(op.f("ix_entitlement_snapshots_subject_id"), table_name="entitlement_snapshots")
    op.drop_table("entitlement_snapshots")
    op.drop_index(op.f("ix_billing_events_subscription_id"), table_name="billing_events")
    op.drop_table("billing_events")
    op.drop_index(op.f("ix_subscriptions_plan_id"), table_name="subscriptions")
    op.drop_index(op.f("ix_subscriptions_subject_id"), table_name="subscriptions")
    op.drop_table("subscriptions")
    op.drop_index(op.f("ix_plan_entitlements_plan_id"), table_name="plan_entitlements")
    op.drop_table("plan_entitlements")
    op.drop_table("billing_plans")
