"""Market linkage data model (spec v1.5 §6, build prompt L0): every §6 table, RLS per role,
and the append-only trigger on `deal_events`.

RLS (Postgres only; the API connects with a BYPASSRLS role and scopes in code, RLS is the
second wall, ADR 0002): a grower sees own lots and the offers on them; a buyer / broker sees
published lots only while verified (latest party_verifications row approved) and their own
offers; deal parties see their deal and its versions, events, slips and payments; a provider
sees only requests sent to it; public trader / broker / provider profiles only once verified;
signed-in users read only active rating tags. Three SECURITY DEFINER helpers (owned by the
migrating role, which bypasses RLS like the API) let one table's policy look at another table
without policy recursion. Writes other than the owner's own lot / profile rows have no policy,
so they go through the API. Contacts stay in `farmers` / `plots` (owner-only RLS): the API
reveals them to deal parties (RLS cannot limit columns).

Rating tags are seeded by `python -m bagmitra_api.kb.seed` (draft, `market_link/seed.py`).

Revision ID: 0029
Revises: 0028
Create Date: 2026-11-07
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_policy_rls, enable_policy_rls

revision = "0029"
down_revision = "0028"
branch_labels = None
depends_on = None

OWN_ROW = "{col} = auth.uid()"
DEAL_PARTY = "ml_deal_party(deal_id)"

FUNCTIONS = (
    # The subject's latest verification is an admin approval (decision h).
    """CREATE FUNCTION ml_verified(p_type text, p_subject uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $f$
      SELECT coalesce((
        SELECT v.status = 'approved' AND v.checked_by IS NOT NULL AND v.checked_at IS NOT NULL
          FROM party_verifications v
         WHERE v.subject_type = p_type AND v.subject_id = p_subject
         ORDER BY v.created_at DESC LIMIT 1), false)
    $f$""",
    # The signed-in user is a verified buyer or broker.
    """CREATE FUNCTION ml_viewer_verified() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $f$
      SELECT EXISTS (SELECT 1 FROM buyer_profiles b
                      WHERE b.user_id = auth.uid() AND ml_verified('buyer', b.id))
          OR EXISTS (SELECT 1 FROM broker_profiles b
                      WHERE b.user_id = auth.uid() AND ml_verified('broker', b.id))
    $f$""",
    # The signed-in user is a party (grower, trader, broker) of the deal.
    """CREATE FUNCTION ml_deal_party(p_deal uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $f$
      SELECT EXISTS (SELECT 1 FROM deal_parties p
                      WHERE p.deal_id = p_deal AND p.user_id = auth.uid())
    $f$""",
    """CREATE FUNCTION deal_events_append_only() RETURNS trigger
    LANGUAGE plpgsql AS $f$
    BEGIN
      RAISE EXCEPTION 'deal_events is append-only';
    END $f$""",
    "CREATE TRIGGER deal_events_no_change BEFORE UPDATE OR DELETE ON deal_events "
    "FOR EACH ROW EXECUTE FUNCTION deal_events_append_only()",
    "CREATE TRIGGER deal_events_no_truncate BEFORE TRUNCATE ON deal_events "
    "FOR EACH STATEMENT EXECUTE FUNCTION deal_events_append_only()",
)
DROP_FUNCTIONS = (
    "DROP TRIGGER IF EXISTS deal_events_no_truncate ON deal_events",
    "DROP TRIGGER IF EXISTS deal_events_no_change ON deal_events",
    "DROP FUNCTION IF EXISTS deal_events_append_only()",
    "DROP FUNCTION IF EXISTS ml_deal_party(uuid)",
    "DROP FUNCTION IF EXISTS ml_viewer_verified()",
    "DROP FUNCTION IF EXISTS ml_verified(text, uuid)",
)


def _verified_profile(kind: str) -> str:
    return f"auth.uid() IS NOT NULL AND ml_verified('{kind}', id)"


_OWN_SUBJECT = (
    "(subject_type = 'buyer' AND subject_id IN "
    "(SELECT id FROM buyer_profiles WHERE user_id = auth.uid())) "
    "OR (subject_type = 'broker' AND subject_id IN "
    "(SELECT id FROM broker_profiles WHERE user_id = auth.uid())) "
    "OR (subject_type = 'provider' AND subject_id IN "
    "(SELECT id FROM service_providers WHERE user_id = auth.uid()))"
)

# table -> (policy name, command, USING). Order: referenced tables first.
POLICIES: dict[str, list[tuple[str, str, str]]] = {
    "party_verifications": [("subject_read", "SELECT", _OWN_SUBJECT)],
    "buyer_profiles": [
        ("owner_all", "ALL", OWN_ROW.format(col="user_id")),
        ("verified_read", "SELECT", _verified_profile("buyer")),
    ],
    "broker_profiles": [
        ("owner_all", "ALL", OWN_ROW.format(col="user_id")),
        ("verified_read", "SELECT", _verified_profile("broker")),
    ],
    "service_providers": [
        ("owner_all", "ALL", OWN_ROW.format(col="user_id")),
        ("verified_read", "SELECT", _verified_profile("provider")),
    ],
    "market_lots": [
        ("owner_all", "ALL", OWN_ROW.format(col="owner_id")),
        (
            "verified_read",
            "SELECT",
            "status = 'published' AND deleted_at IS NULL AND ml_viewer_verified()",
        ),
        (
            "party_read",
            "SELECT",
            "EXISTS (SELECT 1 FROM market_deals d WHERE d.lot_id = market_lots.id)",
        ),
    ],
    # Photos of every lot the user may see (the market_lots policies apply inside).
    "market_lot_photos": [
        ("owner_all", "ALL", OWN_ROW.format(col="owner_id")),
        ("lot_read", "SELECT", "deleted_at IS NULL AND lot_id IN (SELECT id FROM market_lots)"),
    ],
    "market_offers": [
        (
            "grower_read",
            "SELECT",
            "lot_id IN (SELECT id FROM market_lots WHERE owner_id = auth.uid())",
        ),
        ("party_read", "SELECT", "buyer_user_id = auth.uid() OR broker_user_id = auth.uid()"),
    ],
    "market_deals": [("party_read", "SELECT", "ml_deal_party(id)")],
    "deal_parties": [("party_read", "SELECT", DEAL_PARTY)],
    "deal_versions": [("party_read", "SELECT", DEAL_PARTY)],
    "deal_confirmations": [
        ("party_read", "SELECT", "deal_version_id IN (SELECT id FROM deal_versions)")
    ],
    "deal_events": [("party_read", "SELECT", DEAL_PARTY)],
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
    "ratings": [("own_read", "SELECT", "rater_id = auth.uid() OR ratee_id = auth.uid()")],
    "rating_tags": [("active_read", "SELECT", "auth.uid() IS NOT NULL AND status = 'active'")],
    # Disputes go to admin; the raiser sees only their own.
    "disputes": [("raiser_read", "SELECT", OWN_ROW.format(col="raised_by"))],
}


def upgrade() -> None:  # noqa: PLR0915 - one create_table per spec §6 table
    op.create_table(
        "broker_profiles",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("village", sa.String(length=120), nullable=True),
        sa.Column("district", sa.String(length=120), nullable=False),
        sa.Column("taluka", sa.String(length=120), nullable=True),
        sa.Column("service_areas", sa.JSON(), nullable=False),
        sa.Column("crops", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_broker_profiles")),
        sa.UniqueConstraint("user_id", name=op.f("uq_broker_profiles_user_id")),
    )
    with op.batch_alter_table("broker_profiles", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_broker_profiles_district"), ["district"], unique=False)
        batch_op.create_index(batch_op.f("ix_broker_profiles_taluka"), ["taluka"], unique=False)

    op.create_table(
        "buyer_profiles",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("firm", sa.String(length=120), nullable=True),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("markets", sa.JSON(), nullable=False),
        sa.Column("district", sa.String(length=120), nullable=False),
        sa.Column("taluka", sa.String(length=120), nullable=True),
        sa.Column("crops", sa.JSON(), nullable=False),
        sa.Column("apmc_licence_no", sa.String(length=40), nullable=True),
        sa.Column("gst_no", sa.String(length=20), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_buyer_profiles")),
        sa.UniqueConstraint("user_id", name=op.f("uq_buyer_profiles_user_id")),
    )
    with op.batch_alter_table("buyer_profiles", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_buyer_profiles_district"), ["district"], unique=False)
        batch_op.create_index(batch_op.f("ix_buyer_profiles_taluka"), ["taluka"], unique=False)

    op.create_table(
        "market_lot_photos",
        sa.Column("lot_id", sa.Uuid(), nullable=False),
        sa.Column("captured_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("lat", sa.Float(), nullable=False),
        sa.Column("lon", sa.Float(), nullable=False),
        sa.Column("photo_key", sa.String(length=160), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_market_lot_photos")),
    )
    with op.batch_alter_table("market_lot_photos", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_market_lot_photos_last_seq"), ["last_seq"], unique=False
        )
        batch_op.create_index(batch_op.f("ix_market_lot_photos_lot_id"), ["lot_id"], unique=False)
        batch_op.create_index(
            batch_op.f("ix_market_lot_photos_owner_id"), ["owner_id"], unique=False
        )

    op.create_table(
        "market_lots",
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar_cycle_id", sa.Uuid(), nullable=True),
        sa.Column("crop", sa.String(length=32), nullable=False),
        sa.Column("variety", sa.String(length=60), nullable=True),
        sa.Column("quantity_t", sa.Float(), nullable=False),
        sa.Column("quality", sa.String(length=500), nullable=True),
        sa.Column("harvest_from", sa.Date(), nullable=False),
        sa.Column("harvest_to", sa.Date(), nullable=False),
        sa.Column("basis", sa.String(length=16), nullable=False),
        sa.Column("asking_rate_paise", sa.BigInteger(), nullable=True),
        sa.Column("village", sa.String(length=120), nullable=True),
        sa.Column("taluka", sa.String(length=120), nullable=True),
        sa.Column("district", sa.String(length=120), nullable=True),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "basis IN ('per_tonne', 'per_crate', 'lump_sum')", name=op.f("ck_market_lots_basis")
        ),
        sa.CheckConstraint(
            "status IN ('draft', 'published', 'closed', 'withdrawn')",
            name=op.f("ck_market_lots_status"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_market_lots")),
    )
    with op.batch_alter_table("market_lots", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_market_lots_bahar_cycle_id"), ["bahar_cycle_id"], unique=False
        )
        batch_op.create_index(batch_op.f("ix_market_lots_district"), ["district"], unique=False)
        batch_op.create_index(batch_op.f("ix_market_lots_last_seq"), ["last_seq"], unique=False)
        batch_op.create_index(batch_op.f("ix_market_lots_owner_id"), ["owner_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_market_lots_plot_id"), ["plot_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_market_lots_status"), ["status"], unique=False)
        batch_op.create_index(batch_op.f("ix_market_lots_taluka"), ["taluka"], unique=False)

    op.create_table(
        "party_verifications",
        sa.Column("subject_type", sa.String(length=16), nullable=False),
        sa.Column("subject_id", sa.Uuid(), nullable=False),
        sa.Column("document_keys", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("reason", sa.String(length=500), nullable=True),
        sa.Column("checked_by", sa.Uuid(), nullable=True),
        sa.Column("checked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "status IN ('pending', 'approved', 'rejected')",
            name=op.f("ck_party_verifications_status"),
        ),
        sa.CheckConstraint(
            "subject_type IN ('buyer', 'broker', 'provider')",
            name=op.f("ck_party_verifications_subject_type"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_party_verifications")),
    )
    with op.batch_alter_table("party_verifications", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_party_verifications_status"), ["status"], unique=False)
        batch_op.create_index(
            batch_op.f("ix_party_verifications_subject_id"), ["subject_id"], unique=False
        )

    op.create_table(
        "rating_tags",
        sa.Column("key", sa.String(length=64), nullable=False),
        sa.Column("question_key", sa.String(length=40), nullable=False),
        sa.Column("polarity", sa.String(length=16), nullable=False),
        sa.Column("label_mr", sa.String(length=120), nullable=False),
        sa.Column("label_hi", sa.String(length=120), nullable=False),
        sa.Column("label_en", sa.String(length=120), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "polarity IN ('positive', 'negative')", name=op.f("ck_rating_tags_polarity")
        ),
        sa.CheckConstraint(
            "status IN ('draft', 'active', 'retired')", name=op.f("ck_rating_tags_status")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_rating_tags")),
        sa.UniqueConstraint("key", name=op.f("uq_rating_tags_key")),
    )
    with op.batch_alter_table("rating_tags", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_rating_tags_question_key"), ["question_key"], unique=False
        )
        batch_op.create_index(batch_op.f("ix_rating_tags_status"), ["status"], unique=False)

    op.create_table(
        "service_providers",
        sa.Column("user_id", sa.Uuid(), nullable=True),
        sa.Column("added_by", sa.Uuid(), nullable=True),
        sa.Column("kind", sa.String(length=16), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("village", sa.String(length=120), nullable=True),
        sa.Column("district", sa.String(length=120), nullable=False),
        sa.Column("taluka", sa.String(length=120), nullable=True),
        sa.Column("service_areas", sa.JSON(), nullable=False),
        sa.Column("lat", sa.Float(), nullable=True),
        sa.Column("lon", sa.Float(), nullable=True),
        sa.Column("cert_photo_key", sa.String(length=160), nullable=True),
        sa.Column("cert_valid_until", sa.Date(), nullable=True),
        sa.Column("vehicle_numbers", sa.JSON(), nullable=False),
        sa.Column("capacity_t", sa.Float(), nullable=True),
        sa.Column("refrigerated", sa.Boolean(), nullable=True),
        sa.Column("carrier_reg_no", sa.String(length=40), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "kind IN ('weighbridge', 'transporter', 'labour_gang', 'crate_supplier')",
            name=op.f("ck_service_providers_kind"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_service_providers")),
    )
    with op.batch_alter_table("service_providers", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_service_providers_district"), ["district"], unique=False
        )
        batch_op.create_index(batch_op.f("ix_service_providers_kind"), ["kind"], unique=False)
        batch_op.create_index(batch_op.f("ix_service_providers_taluka"), ["taluka"], unique=False)
        batch_op.create_index(batch_op.f("ix_service_providers_user_id"), ["user_id"], unique=False)

    op.create_table(
        "market_offers",
        sa.Column("lot_id", sa.Uuid(), nullable=False),
        sa.Column("buyer_user_id", sa.Uuid(), nullable=False),
        sa.Column("broker_user_id", sa.Uuid(), nullable=True),
        sa.Column("submitted_by", sa.Uuid(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
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
            "basis IN ('per_tonne', 'per_crate', 'lump_sum')", name=op.f("ck_market_offers_basis")
        ),
        sa.CheckConstraint(
            "crates_paid_by IN ('grower', 'trader', 'none')",
            name=op.f("ck_market_offers_crates_paid_by"),
        ),
        sa.CheckConstraint(
            "labour_paid_by IN ('grower', 'trader', 'none')",
            name=op.f("ck_market_offers_labour_paid_by"),
        ),
        sa.CheckConstraint(
            "status IN ('open', 'accepted', 'closed', 'withdrawn')",
            name=op.f("ck_market_offers_status"),
        ),
        sa.CheckConstraint(
            "transport_paid_by IN ('grower', 'trader', 'none')",
            name=op.f("ck_market_offers_transport_paid_by"),
        ),
        sa.ForeignKeyConstraint(
            ["lot_id"], ["market_lots.id"], name=op.f("fk_market_offers_lot_id_market_lots")
        ),
        sa.ForeignKeyConstraint(
            ["weighing_provider_id"],
            ["service_providers.id"],
            name=op.f("fk_market_offers_weighing_provider_id_service_providers"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_market_offers")),
    )
    with op.batch_alter_table("market_offers", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_market_offers_broker_user_id"), ["broker_user_id"], unique=False
        )
        batch_op.create_index(
            batch_op.f("ix_market_offers_buyer_user_id"), ["buyer_user_id"], unique=False
        )
        batch_op.create_index(batch_op.f("ix_market_offers_lot_id"), ["lot_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_market_offers_status"), ["status"], unique=False)

    op.create_table(
        "market_deals",
        sa.Column("lot_id", sa.Uuid(), nullable=False),
        sa.Column("offer_id", sa.Uuid(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("current_version", sa.Integer(), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "status IN ('active', 'completed', 'cancelled')", name=op.f("ck_market_deals_status")
        ),
        sa.ForeignKeyConstraint(
            ["lot_id"], ["market_lots.id"], name=op.f("fk_market_deals_lot_id_market_lots")
        ),
        sa.ForeignKeyConstraint(
            ["offer_id"], ["market_offers.id"], name=op.f("fk_market_deals_offer_id_market_offers")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_market_deals")),
        sa.UniqueConstraint("offer_id", name=op.f("uq_market_deals_offer_id")),
    )
    with op.batch_alter_table("market_deals", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_market_deals_lot_id"), ["lot_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_market_deals_status"), ["status"], unique=False)

    op.create_table(
        "deal_events",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column("kind", sa.String(length=32), nullable=False),
        sa.Column("detail", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_deal_events_deal_id_market_deals")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_deal_events")),
    )
    with op.batch_alter_table("deal_events", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_deal_events_deal_id"), ["deal_id"], unique=False)

    op.create_table(
        "deal_parties",
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("role", sa.String(length=16), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("closed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "role IN ('grower', 'trader', 'broker')", name=op.f("ck_deal_parties_role")
        ),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_deal_parties_deal_id_market_deals")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_deal_parties")),
        sa.UniqueConstraint("deal_id", "role", name=op.f("uq_deal_parties_deal_id")),
    )
    with op.batch_alter_table("deal_parties", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_deal_parties_deal_id"), ["deal_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_deal_parties_user_id"), ["user_id"], unique=False)

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

    op.create_table(
        "ratings",
        sa.Column("deal_id", sa.Uuid(), nullable=False),
        sa.Column("rater_id", sa.Uuid(), nullable=False),
        sa.Column("ratee_id", sa.Uuid(), nullable=False),
        sa.Column("ratee_role", sa.String(length=16), nullable=False),
        sa.Column("question_key", sa.String(length=40), nullable=False),
        sa.Column("stars", sa.SmallInteger(), nullable=False),
        sa.Column("tag_ids", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "ratee_role IN ('grower', 'trader', 'broker', 'provider')",
            name=op.f("ck_ratings_ratee_role"),
        ),
        sa.CheckConstraint("stars BETWEEN 1 AND 5", name=op.f("ck_ratings_stars")),
        sa.ForeignKeyConstraint(
            ["deal_id"], ["market_deals.id"], name=op.f("fk_ratings_deal_id_market_deals")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_ratings")),
        sa.UniqueConstraint(
            "deal_id", "rater_id", "ratee_id", "question_key", name=op.f("uq_ratings_deal_id")
        ),
    )
    with op.batch_alter_table("ratings", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_ratings_deal_id"), ["deal_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_ratings_ratee_id"), ["ratee_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_ratings_rater_id"), ["rater_id"], unique=False)

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

    if op.get_bind().dialect.name == "postgresql":
        for stmt in FUNCTIONS:
            op.execute(stmt)
        for table, policies in POLICIES.items():
            for stmt in enable_policy_rls(table, policies):
                op.execute(stmt)


def downgrade() -> None:  # noqa: PLR0915
    if op.get_bind().dialect.name == "postgresql":
        for table, policies in reversed(POLICIES.items()):
            for stmt in disable_policy_rls(table, [name for name, _, _ in policies]):
                op.execute(stmt)
        for stmt in DROP_FUNCTIONS:
            op.execute(stmt)
    with op.batch_alter_table("deal_confirmations", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_deal_confirmations_deal_version_id"))

    op.drop_table("deal_confirmations")
    with op.batch_alter_table("weigh_slips", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_weigh_slips_deal_id"))

    op.drop_table("weigh_slips")
    with op.batch_alter_table("service_requests", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_service_requests_provider_id"))
        batch_op.drop_index(batch_op.f("ix_service_requests_deal_id"))

    op.drop_table("service_requests")
    with op.batch_alter_table("ratings", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_ratings_rater_id"))
        batch_op.drop_index(batch_op.f("ix_ratings_ratee_id"))
        batch_op.drop_index(batch_op.f("ix_ratings_deal_id"))

    op.drop_table("ratings")
    with op.batch_alter_table("disputes", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_disputes_status"))
        batch_op.drop_index(batch_op.f("ix_disputes_raised_by"))
        batch_op.drop_index(batch_op.f("ix_disputes_deal_id"))
        batch_op.drop_index(batch_op.f("ix_disputes_against_user_id"))

    op.drop_table("disputes")
    with op.batch_alter_table("deal_versions", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_deal_versions_deal_id"))

    op.drop_table("deal_versions")
    with op.batch_alter_table("deal_payments", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_deal_payments_deal_id"))

    op.drop_table("deal_payments")
    with op.batch_alter_table("deal_parties", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_deal_parties_user_id"))
        batch_op.drop_index(batch_op.f("ix_deal_parties_deal_id"))

    op.drop_table("deal_parties")
    with op.batch_alter_table("deal_events", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_deal_events_deal_id"))

    op.drop_table("deal_events")
    with op.batch_alter_table("market_deals", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_market_deals_status"))
        batch_op.drop_index(batch_op.f("ix_market_deals_lot_id"))

    op.drop_table("market_deals")
    with op.batch_alter_table("market_offers", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_market_offers_status"))
        batch_op.drop_index(batch_op.f("ix_market_offers_lot_id"))
        batch_op.drop_index(batch_op.f("ix_market_offers_buyer_user_id"))
        batch_op.drop_index(batch_op.f("ix_market_offers_broker_user_id"))

    op.drop_table("market_offers")
    with op.batch_alter_table("service_providers", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_service_providers_user_id"))
        batch_op.drop_index(batch_op.f("ix_service_providers_taluka"))
        batch_op.drop_index(batch_op.f("ix_service_providers_kind"))
        batch_op.drop_index(batch_op.f("ix_service_providers_district"))

    op.drop_table("service_providers")
    with op.batch_alter_table("rating_tags", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_rating_tags_status"))
        batch_op.drop_index(batch_op.f("ix_rating_tags_question_key"))

    op.drop_table("rating_tags")
    with op.batch_alter_table("party_verifications", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_party_verifications_subject_id"))
        batch_op.drop_index(batch_op.f("ix_party_verifications_status"))

    op.drop_table("party_verifications")
    with op.batch_alter_table("market_lots", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_market_lots_taluka"))
        batch_op.drop_index(batch_op.f("ix_market_lots_status"))
        batch_op.drop_index(batch_op.f("ix_market_lots_plot_id"))
        batch_op.drop_index(batch_op.f("ix_market_lots_owner_id"))
        batch_op.drop_index(batch_op.f("ix_market_lots_last_seq"))
        batch_op.drop_index(batch_op.f("ix_market_lots_district"))
        batch_op.drop_index(batch_op.f("ix_market_lots_bahar_cycle_id"))

    op.drop_table("market_lots")
    with op.batch_alter_table("market_lot_photos", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_market_lot_photos_owner_id"))
        batch_op.drop_index(batch_op.f("ix_market_lot_photos_lot_id"))
        batch_op.drop_index(batch_op.f("ix_market_lot_photos_last_seq"))

    op.drop_table("market_lot_photos")
    with op.batch_alter_table("buyer_profiles", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_buyer_profiles_taluka"))
        batch_op.drop_index(batch_op.f("ix_buyer_profiles_district"))

    op.drop_table("buyer_profiles")
    with op.batch_alter_table("broker_profiles", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_broker_profiles_taluka"))
        batch_op.drop_index(batch_op.f("ix_broker_profiles_district"))

    op.drop_table("broker_profiles")
