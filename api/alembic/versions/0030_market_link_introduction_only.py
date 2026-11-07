"""Market linkage L0c (spec v1.5 §1 core principle, §4, §4C, §6; Addendum 5): introduction
only. BagMitra introduces grower, trader and broker and never enters their transaction or
disputes, so this drops deal versions / confirmations, weigh slips, deal payments, service
requests, disputes and the offer's payer / advance / balance / weighing-place / rejection-rule
columns; market_deals keeps only the introduction and both "deal done" taps.

Adds: exporter kind + IEC on buyer_profiles (GSTIN / IEC / APMC indexed, not unique: a second
claim reaches admin, Q80), the optional address (who / when) on trader, broker and provider
profiles, and the tables `registration_fixes` (the one registration GPS fix, admin-only
coordinates), `representative_uploads`, `fraud_reports`, `admin_actions`, `terms_acceptances`
and `user_blocks`. RLS (Postgres, second wall): each user reads only their own rows of the new
tables (blocks: own rows, all commands); writes go through the API.

Revision ID: 0030
Revises: 0029
Create Date: 2026-11-07
"""

from __future__ import annotations

from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_policy_rls, enable_policy_rls

revision = "0030"
down_revision = "0029"
branch_labels = None
depends_on = None

DEAL_PARTY = "ml_deal_party(deal_id)"
NEW_POLICIES: dict[str, list[tuple[str, str, str]]] = {
    "registration_fixes": [("own_read", "SELECT", "user_id = auth.uid()")],
    "representative_uploads": [("uploader_read", "SELECT", "uploaded_by = auth.uid()")],
    "fraud_reports": [("reporter_read", "SELECT", "reporter_id = auth.uid()")],
    # The user an action is about sees it with its reason code (and may appeal, §4C).
    "admin_actions": [("subject_read", "SELECT", "user_id = auth.uid()")],
    "terms_acceptances": [("own_read", "SELECT", "user_id = auth.uid()")],
    "user_blocks": [("owner_all", "ALL", "blocker_id = auth.uid()")],
}
# 0029 policies of the dropped tables, restored on downgrade.
OLD_POLICIES: dict[str, list[tuple[str, str, str]]] = {
    "deal_versions": [("party_read", "SELECT", DEAL_PARTY)],
    "deal_confirmations": [
        ("party_read", "SELECT", "deal_version_id IN (SELECT id FROM deal_versions)")
    ],
    "service_requests": [
        ("party_read", "SELECT", DEAL_PARTY),
        (
            "provider_read",
            "SELECT",
            "provider_id IN (SELECT id FROM service_providers WHERE user_id = auth.uid())",
        ),
    ],
    "weigh_slips": [("party_read", "SELECT", DEAL_PARTY)],
    "deal_payments": [("party_read", "SELECT", DEAL_PARTY)],
    "disputes": [("raiser_read", "SELECT", "raised_by = auth.uid()")],
}
DROPPED = (
    "deal_confirmations",
    "weigh_slips",
    "service_requests",
    "deal_payments",
    "disputes",
    "deal_versions",
)
ADDRESS_COLUMNS = ("address_set_at", "address_set_by", "address")
OFFER_PAYERS = ("labour_paid_by", "crates_paid_by", "transport_paid_by")
PAYER_CHECK = "{col} IN ('grower', 'trader', 'none')"
SUBJECTS = "'buyer', 'broker', 'provider'"
TARGETS = f"{SUBJECTS}, 'lot', 'user'"
REASONS = "'fake_identity', 'fake_lot', 'impersonation', 'fake_rating', 'abuse'"


def _ck(table: str, name: str, sql: str) -> sa.CheckConstraint:
    return sa.CheckConstraint(sql, name=op.f(f"ck_{table}_{name}"))


def _row_columns() -> list[sa.Column[Any]]:
    return [
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def _address_columns() -> list[sa.Column[Any]]:
    return [
        sa.Column("address", sa.String(length=300), nullable=True),
        sa.Column("address_set_by", sa.Uuid(), nullable=True),
        sa.Column("address_set_at", sa.DateTime(timezone=True), nullable=True),
    ]


def _index(table: str, *columns: str) -> None:
    with op.batch_alter_table(table, schema=None) as batch_op:
        for column in columns:
            batch_op.create_index(batch_op.f(f"ix_{table}_{column}"), [column], unique=False)


def _create_new_tables() -> None:
    op.create_table(
        "registration_fixes",
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("lat", sa.Float(), nullable=False),
        sa.Column("lon", sa.Float(), nullable=False),
        sa.Column("accuracy_m", sa.Float(), nullable=False),
        sa.Column("captured_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("place", sa.String(length=120), nullable=True),
        sa.Column("district", sa.String(length=120), nullable=True),
        sa.Column("state", sa.String(length=120), nullable=True),
        sa.Column("pin", sa.String(length=6), nullable=True),
        sa.Column("is_mocked", sa.Boolean(), nullable=False),
        *_row_columns(),
        _ck(
            "registration_fixes",
            "subject_type",
            f"subject_type IN ({SUBJECTS}, 'representative')",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_registration_fixes")),
    )
    _index("registration_fixes", "subject_id", "user_id")
    op.create_table(
        "representative_uploads",
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("uploaded_by", sa.Uuid(), nullable=False),
        sa.Column("photo_key", sa.String(length=160), nullable=True),
        sa.Column("captured_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("lat", sa.Float(), nullable=True),
        sa.Column("lon", sa.Float(), nullable=True),
        sa.Column("address", sa.String(length=300), nullable=True),
        *_row_columns(),
        _ck(
            "representative_uploads",
            "photo_time_gps",
            "photo_key IS NULL OR (captured_at IS NOT NULL AND lat IS NOT NULL "
            "AND lon IS NOT NULL)",
        ),
        _ck(
            "representative_uploads",
            "something",
            "photo_key IS NOT NULL OR address IS NOT NULL",
        ),
        _ck("representative_uploads", "subject_type", f"subject_type IN ({SUBJECTS})"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_representative_uploads")),
    )
    _index("representative_uploads", "subject_id", "uploaded_by")
    op.create_table(
        "admin_actions",
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=True),
        sa.Column("action", sa.String(length=16), nullable=False),
        sa.Column("reason_code", sa.String(length=32), nullable=False),
        sa.Column("actor_id", sa.Uuid(), nullable=False),
        sa.Column("acted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("appeal_state", sa.String(length=16), nullable=False),
        sa.Column("appealed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("appeal_decided_by", sa.Uuid(), nullable=True),
        sa.Column("appeal_decided_at", sa.DateTime(timezone=True), nullable=True),
        *_row_columns(),
        _ck(
            "admin_actions",
            "action",
            "action IN ('verify', 'warn', 'hide', 'suspend', 'restore')",
        ),
        _ck(
            "admin_actions",
            "appeal_state",
            "appeal_state IN ('none', 'appealed', 'upheld', 'rejected')",
        ),
        _ck(
            "admin_actions",
            "reason_code",
            f"reason_code IN ({REASONS}, 'duplicate_user', 'checks_passed', 'appeal_upheld')",
        ),
        _ck("admin_actions", "subject_type", f"subject_type IN ({TARGETS})"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_admin_actions")),
    )
    _index("admin_actions", "subject_id", "user_id")
    op.create_table(
        "fraud_reports",
        sa.Column("reporter_id", sa.Uuid(), nullable=False),
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("reason", sa.String(length=32), nullable=False),
        sa.Column("photo_keys", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("decided_by", sa.Uuid(), nullable=True),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("admin_action_id", sa.Uuid(), nullable=True),
        *_row_columns(),
        _ck("fraud_reports", "reason", f"reason IN ({REASONS})"),
        _ck("fraud_reports", "status", "status IN ('open', 'actioned', 'dismissed')"),
        _ck("fraud_reports", "subject_type", f"subject_type IN ({TARGETS})"),
        sa.ForeignKeyConstraint(
            ["admin_action_id"],
            ["admin_actions.id"],
            name=op.f("fk_fraud_reports_admin_action_id_admin_actions"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_fraud_reports")),
    )
    _index("fraud_reports", "reporter_id", "status", "subject_id")
    op.create_table(
        "terms_acceptances",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("role", sa.String(length=16), nullable=False),
        sa.Column("doc_kind", sa.String(length=16), nullable=False),
        sa.Column("version", sa.String(length=20), nullable=False),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("adult_declared", sa.Boolean(), nullable=False),
        *_row_columns(),
        _ck("terms_acceptances", "doc_kind", "doc_kind IN ('terms', 'privacy', 'disclaimer')"),
        _ck(
            "terms_acceptances",
            "role",
            "role IN ('grower', 'trader', 'exporter', 'broker', 'provider', 'representative')",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_terms_acceptances")),
        sa.UniqueConstraint(
            "user_id",
            "role",
            "doc_kind",
            "version",
            name=op.f("uq_terms_acceptances_user_id"),
        ),
    )
    _index("terms_acceptances", "user_id")
    op.create_table(
        "user_blocks",
        sa.Column("blocker_id", sa.Uuid(), nullable=False),
        sa.Column("blocked_id", sa.Uuid(), nullable=False),
        *_row_columns(),
        _ck("user_blocks", "not_self", "blocker_id <> blocked_id"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_user_blocks")),
        sa.UniqueConstraint("blocker_id", "blocked_id", name=op.f("uq_user_blocks_blocker_id")),
    )
    _index("user_blocks", "blocked_id", "blocker_id")


def upgrade() -> None:
    postgres = op.get_bind().dialect.name == "postgresql"
    for table in DROPPED:
        op.drop_table(table)
    with op.batch_alter_table("market_offers", schema=None) as batch_op:
        batch_op.drop_constraint(
            batch_op.f("fk_market_offers_weighing_provider_id_service_providers"),
            type_="foreignkey",
        )
        for col in OFFER_PAYERS:
            batch_op.drop_constraint(batch_op.f(f"ck_market_offers_{col}"), type_="check")
        for col in (
            "weighing_provider_id",
            *OFFER_PAYERS,
            "advance_paise",
            "advance_date",
            "balance_date",
            "rejection_rule",
        ):
            batch_op.drop_column(col)
    with op.batch_alter_table("market_deals", schema=None) as batch_op:
        batch_op.drop_column("current_version")
        batch_op.add_column(
            sa.Column(
                "accepted_at",
                sa.DateTime(timezone=True),
                nullable=False,
                server_default=sa.func.now(),
            )
        )
        batch_op.add_column(sa.Column("grower_done_at", sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column("trader_done_at", sa.DateTime(timezone=True), nullable=True))
    with op.batch_alter_table("market_deals", schema=None) as batch_op:
        batch_op.alter_column("accepted_at", server_default=None)
    with op.batch_alter_table("deal_parties", schema=None) as batch_op:
        batch_op.drop_column("closed_at")
    # Providers are a directory now (no service flow), so nobody rates them.
    with op.batch_alter_table("ratings", schema=None) as batch_op:
        batch_op.drop_constraint(batch_op.f("ck_ratings_ratee_role"), type_="check")
        batch_op.create_check_constraint(
            batch_op.f("ck_ratings_ratee_role"), "ratee_role IN ('grower', 'trader', 'broker')"
        )
    with op.batch_alter_table("buyer_profiles", schema=None) as batch_op:
        batch_op.add_column(
            sa.Column(
                "kind", sa.String(length=16), nullable=False, server_default=sa.text("'trader'")
            )
        )
        batch_op.add_column(sa.Column("iec_no", sa.String(length=10), nullable=True))
        for column in _address_columns():
            batch_op.add_column(column)
        batch_op.create_check_constraint(
            batch_op.f("ck_buyer_profiles_kind"), "kind IN ('trader', 'exporter')"
        )
        batch_op.create_check_constraint(
            batch_op.f("ck_buyer_profiles_exporter_iec"),
            "kind <> 'exporter' OR iec_no IS NOT NULL",
        )
    with op.batch_alter_table("buyer_profiles", schema=None) as batch_op:
        batch_op.alter_column("kind", server_default=None)
    _index("buyer_profiles", "apmc_licence_no", "gst_no", "iec_no")
    for table in ("broker_profiles", "service_providers"):
        with op.batch_alter_table(table, schema=None) as batch_op:
            for column in _address_columns():
                batch_op.add_column(column)
    _create_new_tables()
    if postgres:
        for table, policies in NEW_POLICIES.items():
            for stmt in enable_policy_rls(table, policies):
                op.execute(stmt)


def downgrade() -> None:  # noqa: PLR0912 - the dropped tables come back as in 0029
    postgres = op.get_bind().dialect.name == "postgresql"
    if postgres:
        for table, policies in reversed(NEW_POLICIES.items()):
            for stmt in disable_policy_rls(table, [name for name, _, _ in policies]):
                op.execute(stmt)
    for table in (
        "user_blocks",
        "terms_acceptances",
        "fraud_reports",
        "admin_actions",
        "representative_uploads",
        "registration_fixes",
    ):
        op.drop_table(table)
    for table in ("broker_profiles", "service_providers"):
        with op.batch_alter_table(table, schema=None) as batch_op:
            for name in ADDRESS_COLUMNS:
                batch_op.drop_column(name)
    with op.batch_alter_table("buyer_profiles", schema=None) as batch_op:
        for column in ("iec_no", "gst_no", "apmc_licence_no"):
            batch_op.drop_index(batch_op.f(f"ix_buyer_profiles_{column}"))
        batch_op.drop_constraint(batch_op.f("ck_buyer_profiles_exporter_iec"), type_="check")
        batch_op.drop_constraint(batch_op.f("ck_buyer_profiles_kind"), type_="check")
        for name in ADDRESS_COLUMNS:
            batch_op.drop_column(name)
        batch_op.drop_column("iec_no")
        batch_op.drop_column("kind")
    with op.batch_alter_table("ratings", schema=None) as batch_op:
        batch_op.drop_constraint(batch_op.f("ck_ratings_ratee_role"), type_="check")
        batch_op.create_check_constraint(
            batch_op.f("ck_ratings_ratee_role"),
            "ratee_role IN ('grower', 'trader', 'broker', 'provider')",
        )
    with op.batch_alter_table("deal_parties", schema=None) as batch_op:
        batch_op.add_column(sa.Column("closed_at", sa.DateTime(timezone=True), nullable=True))
    with op.batch_alter_table("market_deals", schema=None) as batch_op:
        batch_op.drop_column("trader_done_at")
        batch_op.drop_column("grower_done_at")
        batch_op.drop_column("accepted_at")
        batch_op.add_column(
            sa.Column("current_version", sa.Integer(), nullable=False, server_default="1")
        )
    with op.batch_alter_table("market_deals", schema=None) as batch_op:
        batch_op.alter_column("current_version", server_default=None)
    with op.batch_alter_table("market_offers", schema=None) as batch_op:
        batch_op.add_column(sa.Column("weighing_provider_id", sa.Uuid(), nullable=True))
        for col in OFFER_PAYERS:
            batch_op.add_column(
                sa.Column(col, sa.String(length=16), nullable=False, server_default="none")
            )
        batch_op.add_column(sa.Column("advance_paise", sa.BigInteger(), nullable=True))
        batch_op.add_column(sa.Column("advance_date", sa.Date(), nullable=True))
        batch_op.add_column(sa.Column("balance_date", sa.Date(), nullable=True))
        batch_op.add_column(sa.Column("rejection_rule", sa.String(length=1000), nullable=True))
        batch_op.create_foreign_key(
            batch_op.f("fk_market_offers_weighing_provider_id_service_providers"),
            "service_providers",
            ["weighing_provider_id"],
            ["id"],
        )
        for col in OFFER_PAYERS:
            batch_op.create_check_constraint(
                batch_op.f(f"ck_market_offers_{col}"), PAYER_CHECK.format(col=col)
            )
    with op.batch_alter_table("market_offers", schema=None) as batch_op:
        for col in OFFER_PAYERS:
            batch_op.alter_column(col, server_default=None)
    _recreate_dropped()
    if postgres:
        for table, policies in OLD_POLICIES.items():
            for stmt in enable_policy_rls(table, policies):
                op.execute(stmt)


def _recreate_dropped() -> None:
    op.create_table(
        "deal_versions",
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("created_by", sa.Uuid(), nullable=False),
        sa.Column("other_conditions", sa.String(length=1000), nullable=True),
        sa.Column("paper_note_photo_key", sa.String(length=160), nullable=True),
        sa.Column("basis", sa.String(length=16), nullable=False),
        sa.Column("rate_paise", sa.BigInteger(), nullable=False),
        sa.Column("quantity_t", sa.Float(), nullable=True),
        sa.Column("harvest_date", sa.Date(), nullable=False),
        sa.Column("weighing_provider_id", sa.Uuid(), nullable=True),
        sa.Column("labour_paid_by", sa.String(length=16), nullable=False),
        sa.Column("crates_paid_by", sa.String(length=16), nullable=False),
        sa.Column("transport_paid_by", sa.String(length=16), nullable=False),
        sa.Column("advance_paise", sa.BigInteger(), nullable=True),
        sa.Column("advance_date", sa.Date(), nullable=True),
        sa.Column("balance_date", sa.Date(), nullable=True),
        sa.Column("rejection_rule", sa.String(length=1000), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "basis IN ('per_tonne', 'per_crate', 'lump_sum')", name=op.f("ck_deal_versions_basis")
        ),
        sa.CheckConstraint(
            "crates_paid_by IN ('grower', 'trader', 'none')",
            name=op.f("ck_deal_versions_crates_paid_by"),
        ),
        sa.CheckConstraint(
            "labour_paid_by IN ('grower', 'trader', 'none')",
            name=op.f("ck_deal_versions_labour_paid_by"),
        ),
        sa.CheckConstraint(
            "transport_paid_by IN ('grower', 'trader', 'none')",
            name=op.f("ck_deal_versions_transport_paid_by"),
        ),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_deal_versions_deal_id_market_deals")
        ),
        sa.ForeignKeyConstraint(
            ["weighing_provider_id"],
            ["service_providers.id"],
            name=op.f("fk_deal_versions_weighing_provider_id_service_providers"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_deal_versions")),
        sa.UniqueConstraint("deal_id", "version", name=op.f("uq_deal_versions_deal_id")),
    )
    with op.batch_alter_table("deal_versions", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_deal_versions_deal_id"), ["deal_id"], unique=False)

    op.create_table(
        "deal_confirmations",
        sa.Column("deal_version_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["deal_version_id"],
            ["deal_versions.id"],
            name=op.f("fk_deal_confirmations_deal_version_id_deal_versions"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_deal_confirmations")),
        sa.UniqueConstraint(
            "deal_version_id", "user_id", name=op.f("uq_deal_confirmations_deal_version_id")
        ),
    )
    with op.batch_alter_table("deal_confirmations", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_deal_confirmations_deal_version_id"), ["deal_version_id"], unique=False
        )

    op.create_table(
        "service_requests",
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("provider_id", sa.Uuid(), nullable=False),
        sa.Column("requested_by", sa.Uuid(), nullable=False),
        sa.Column("needed_on", sa.Date(), nullable=True),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "status IN ('sent', 'confirmed', 'declined', 'cancelled')",
            name=op.f("ck_service_requests_status"),
        ),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_service_requests_deal_id_market_deals")
        ),
        sa.ForeignKeyConstraint(
            ["provider_id"],
            ["service_providers.id"],
            name=op.f("fk_service_requests_provider_id_service_providers"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_service_requests")),
    )
    with op.batch_alter_table("service_requests", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_service_requests_deal_id"), ["deal_id"], unique=False)
        batch_op.create_index(
            batch_op.f("ix_service_requests_provider_id"), ["provider_id"], unique=False
        )

    op.create_table(
        "weigh_slips",
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("weighbridge_id", sa.Uuid(), nullable=True),
        sa.Column("photo_key", sa.String(length=160), nullable=True),
        sa.Column("gross_kg", sa.Integer(), nullable=False),
        sa.Column("tare_kg", sa.Integer(), nullable=False),
        sa.Column("net_kg", sa.Integer(), nullable=False),
        sa.Column("truck_number", sa.String(length=20), nullable=True),
        sa.Column("dispatched_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("entered_by", sa.Uuid(), nullable=False),
        sa.Column("grower_confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("trader_confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_weigh_slips_deal_id_market_deals")
        ),
        sa.ForeignKeyConstraint(
            ["weighbridge_id"],
            ["service_providers.id"],
            name=op.f("fk_weigh_slips_weighbridge_id_service_providers"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_weigh_slips")),
    )
    with op.batch_alter_table("weigh_slips", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_weigh_slips_deal_id"), ["deal_id"], unique=False)

    op.create_table(
        "deal_payments",
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.String(length=16), nullable=False),
        sa.Column("amount_paise", sa.BigInteger(), nullable=False),
        sa.Column("received_on", sa.Date(), nullable=False),
        sa.Column("accounts_sale_id", sa.Uuid(), nullable=True),
        sa.Column("recorded_by", sa.Uuid(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("kind IN ('advance', 'balance')", name=op.f("ck_deal_payments_kind")),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_deal_payments_deal_id_market_deals")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_deal_payments")),
    )
    with op.batch_alter_table("deal_payments", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_deal_payments_deal_id"), ["deal_id"], unique=False)

    op.create_table(
        "disputes",
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("raised_by", sa.Uuid(), nullable=False),
        sa.Column("against_user_id", sa.Uuid(), nullable=True),
        sa.Column("kind", sa.String(length=16), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("photo_keys", sa.JSON(), nullable=False),
        sa.Column("decision_note", sa.String(length=1000), nullable=True),
        sa.Column("decided_by", sa.Uuid(), nullable=True),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "kind IN ('non_payment', 'weight', 'quality', 'terms', 'other')",
            name=op.f("ck_disputes_kind"),
        ),
        sa.CheckConstraint("status IN ('open', 'resolved')", name=op.f("ck_disputes_status")),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_disputes_deal_id_market_deals")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_disputes")),
    )
    with op.batch_alter_table("disputes", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_disputes_against_user_id"), ["against_user_id"], unique=False
        )
        batch_op.create_index(batch_op.f("ix_disputes_deal_id"), ["deal_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_disputes_raised_by"), ["raised_by"], unique=False)
        batch_op.create_index(batch_op.f("ix_disputes_status"), ["status"], unique=False)
