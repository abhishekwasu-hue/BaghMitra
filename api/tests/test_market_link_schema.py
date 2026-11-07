"""Market linkage L0: owner decisions c, d, h, the introduction-only data model (Addendum 5,
migration 0030) and the draft rating-tag seed (spec v1.5)."""

from __future__ import annotations

import re
import uuid
from datetime import UTC, datetime, timedelta

import pytest
from pydantic import ValidationError
from sqlalchemy import CheckConstraint, Integer, SmallInteger, String, Text, func, select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.db.base import Base
from bagmitra_api.db.rls import disable_policy_rls, enable_policy_rls
from bagmitra_api.market_link.guards import MarketLinkIn, forbidden_keys, is_verified
from bagmitra_api.market_link.models import MARKET_LINK_TABLES, PartyVerification, RatingTag
from bagmitra_api.market_link.seed import RatingTagSeeds, rating_tag_seeds, seed_rating_tags

SPEC_TABLES = {
    "market_lots",
    "market_lot_photos",
    "buyer_profiles",
    "broker_profiles",
    "deal_parties",
    "party_verifications",
    "market_offers",
    "market_deals",
    "deal_events",
    "service_providers",
    "ratings",
    "rating_tags",
    # Added in 0030 (spec §4, §4C, §6).
    "registration_fixes",
    "representative_uploads",
    "fraud_reports",
    "admin_actions",
    "terms_acceptances",
    "user_blocks",
}
# Dropped in 0030: BagMitra never enters the transaction or its disputes (§1 core principle).
DROPPED_TABLES = {
    "deal_versions",
    "deal_confirmations",
    "weigh_slips",
    "deal_payments",
    "service_requests",
    "disputes",
}
NOT_ALLOWED = re.compile(
    r"commission|brokerage|income|dalali|aadhaar|uid|payment|paid|advance|balance|"
    r"weighing|rejection|dispute",
    re.IGNORECASE,
)


def test_every_spec_section_6_table_exists() -> None:
    assert set(MARKET_LINK_TABLES) == SPEC_TABLES
    assert set(Base.metadata.tables) >= SPEC_TABLES


def test_dropped_tables_are_gone() -> None:
    assert not DROPPED_TABLES & set(Base.metadata.tables)


def test_no_column_holds_commission_income_aadhaar_or_deal_payment() -> None:
    """Q64, addendum 1, Addendum 5: no commission, income, Aadhaar / UID, payment, weighing
    place, rejection rule or dispute anywhere in the market-link tables."""
    for name in MARKET_LINK_TABLES:
        bad = [c.name for c in Base.metadata.tables[name].columns if NOT_ALLOWED.search(c.name)]
        assert bad == [], f"{name}: {bad}"
    offer = set(Base.metadata.tables["market_offers"].columns.keys())
    assert {"basis", "rate_paise", "quantity_t", "harvest_date", "broker_user_id"} <= offer
    deal = set(Base.metadata.tables["market_deals"].columns.keys())
    assert {"accepted_at", "grower_done_at", "trader_done_at", "completed_at"} <= deal
    assert "current_version" not in deal
    assert "closed_at" not in Base.metadata.tables["deal_parties"].columns


def test_reports_and_admin_actions_hold_codes_not_text() -> None:
    """§4, §4C: predefined reasons only, no free text; admin acts with a reason code."""
    for name in ("fraud_reports", "admin_actions", "user_blocks", "terms_acceptances"):
        table = Base.metadata.tables[name]
        for column in table.columns:
            assert not isinstance(column.type, Text), (name, column.name)
            assert not any(w in column.name for w in ("text", "comment", "note")), column.name
            if isinstance(column.type, String):
                assert (column.type.length or 0) <= 32, (name, column.name)


def test_exporter_needs_an_iec_and_numbers_are_not_db_unique() -> None:
    """§4: IEC required for an exporter; §4C: a second GSTIN / IEC / APMC claim reaches admin,
    so the numbers are indexed but not unique (Q80)."""
    table = Base.metadata.tables["buyer_profiles"]
    checks = {str(c.sqltext) for c in table.constraints if isinstance(c, CheckConstraint)}
    assert "kind <> 'exporter' OR iec_no IS NOT NULL" in checks
    for column in ("gst_no", "iec_no", "apmc_licence_no"):
        assert table.c[column].index is True
        assert not table.c[column].unique


@pytest.mark.parametrize("key", ["aadhaar_no", "AadhaarPhoto", "uid", "uid_otp"])
def test_request_bodies_refuse_aadhaar_keys(key: str) -> None:
    class ProfileIn(MarketLinkIn):
        name: str
        extra: dict[str, str] | None = None

    with pytest.raises(ValidationError, match="aadhaar / uid"):
        ProfileIn.model_validate({"name": "a", "extra": {key: "1"}})
    with pytest.raises(ValidationError):
        ProfileIn.model_validate({"name": "a", key: "1"})


def test_c_no_market_link_column_holds_commission_or_income() -> None:
    """Q64: nothing records a broker's commission or anyone's income."""
    for name in MARKET_LINK_TABLES:
        table = Base.metadata.tables[name]
        bad = [c.name for c in table.columns if forbidden_keys({c.name: None})]
        assert bad == [], f"{name}: {bad}"
    assert "commission" not in {c.name for c in Base.metadata.tables["deal_parties"].columns}


@pytest.mark.parametrize("key", ["commission", "brokerage_pct", "Broker_Income", "dalali", "x"])
def test_c_request_bodies_refuse_commission_keys(key: str) -> None:
    class OfferIn(MarketLinkIn):
        rate_paise: int
        extra: dict[str, int] | None = None

    with pytest.raises(ValidationError, match=r"not allowed|Extra inputs"):
        OfferIn.model_validate({"rate_paise": 1, key: 2})
    if key != "x":
        with pytest.raises(ValidationError, match="commission / income"):
            OfferIn.model_validate({"rate_paise": 1, "extra": {key: 2}})
        with pytest.raises(ValidationError, match="commission / income"):
            OfferIn.model_validate({"rate_paise": 1, "items": [{key: 2}]})
    assert OfferIn.model_validate({"rate_paise": 1, "extra": {"crates": 2}}).rate_paise == 1


def test_d_ratings_hold_stars_and_tag_ids_only() -> None:
    """Q66: no free text, comment or reply column on ratings."""
    table = Base.metadata.tables["ratings"]
    for column in table.columns:
        assert not isinstance(column.type, Text), column.name
        assert not any(w in column.name for w in ("text", "comment", "reply", "note")), column.name
    strings = {c.name: c.type.length for c in table.columns if isinstance(c.type, String)}
    # Only the two enum keys, both checked against fixed lists (constraint / question list).
    assert strings == {"ratee_role": 16, "question_key": 40}
    assert isinstance(table.c.stars.type, SmallInteger | Integer)
    checks = {str(c.sqltext) for c in table.constraints if isinstance(c, CheckConstraint)}
    assert "stars BETWEEN 1 AND 5" in checks


def _session_maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def test_h_verified_only_with_an_admin_approval_record(engine: AsyncEngine) -> None:
    maker = _session_maker(engine)
    subject = uuid.uuid4()
    now = datetime.now(UTC)
    async with maker() as session:
        assert await is_verified(session, "buyer", subject) is False
        session.add(PartyVerification(subject_type="buyer", subject_id=subject, status="pending"))
        await session.flush()
        assert await is_verified(session, "buyer", subject) is False
        # "approved" without who / when is not a verification record.
        session.add(
            PartyVerification(
                subject_type="buyer",
                subject_id=subject,
                status="approved",
                created_at=now + timedelta(seconds=1),
            )
        )
        await session.flush()
        assert await is_verified(session, "buyer", subject) is False
        session.add(
            PartyVerification(
                subject_type="buyer",
                subject_id=subject,
                status="approved",
                checked_by=uuid.uuid4(),
                checked_at=now,
                created_at=now + timedelta(seconds=2),
            )
        )
        await session.flush()
        assert await is_verified(session, "buyer", subject) is True
        assert await is_verified(session, "broker", subject) is False
        # A later rejection wins: the latest record decides.
        session.add(
            PartyVerification(
                subject_type="buyer",
                subject_id=subject,
                status="rejected",
                reason="licence copy unreadable",
                checked_by=uuid.uuid4(),
                checked_at=now,
                created_at=now + timedelta(seconds=3),
            )
        )
        await session.flush()
        assert await is_verified(session, "buyer", subject) is False
        with pytest.raises(ValueError, match="unknown subject type"):
            await is_verified(session, "grower", subject)


def test_rating_tag_seed_covers_every_section_3a_question() -> None:
    data = rating_tag_seeds()
    assert data.questions == {
        "trader": [
            "trader_on_date",
            "trader_weighing_correct",
            "trader_paid_as_agreed",
            "trader_kept_conditions",
        ],
        "broker": ["broker_honest", "broker_trader_kept_deal"],
        "grower": ["grower_produce_matched", "grower_ready_on_date"],
    }
    assert len(data.tags) == 16
    assert len({t.key for t in data.tags}) == 16
    for t in data.tags:
        assert t.label_en not in (t.label_mr, t.label_hi), t.key


def test_rating_tag_seed_refuses_a_question_without_both_polarities() -> None:
    raw = rating_tag_seeds().model_dump(by_alias=True)
    raw["tags"] = [t for t in raw["tags"] if t["key"] != "broker_honest_no"]
    with pytest.raises(ValidationError, match="broker_honest"):
        RatingTagSeeds.model_validate(raw)


async def test_seed_adds_drafts_once_and_keeps_admin_edits(engine: AsyncEngine) -> None:
    maker = _session_maker(engine)
    async with maker() as session:
        assert await seed_rating_tags(session) == 16
        tag = await session.scalar(select(RatingTag).where(RatingTag.key == "trader_on_date_yes"))
        assert tag is not None
        assert tag.status == "draft"
        tag.status = "active"
        tag.label_mr = "admin edit"
        await session.flush()
        assert await seed_rating_tags(session) == 0
        assert await session.scalar(select(func.count()).select_from(RatingTag)) == 16
        statuses = set(await session.scalars(select(RatingTag.status)))
        assert statuses == {"draft", "active"}
        assert tag.label_mr == "admin edit"


def test_policy_rls_helpers_check_identifiers_and_commands() -> None:
    sql = enable_policy_rls("ratings", [("own_read", "SELECT", "rater_id = auth.uid()")])
    assert sql[1] == "ALTER TABLE ratings FORCE ROW LEVEL SECURITY"
    assert sql[2] == (
        "CREATE POLICY ratings_own_read ON ratings FOR SELECT USING (rater_id = auth.uid())"
    )
    assert disable_policy_rls("ratings", ["own_read"])[0] == (
        "DROP POLICY IF EXISTS ratings_own_read ON ratings"
    )
    with pytest.raises(ValueError, match="unsupported policy command"):
        enable_policy_rls("ratings", [("w", "DELETE", "true")])
    with pytest.raises(ValueError, match="unsafe"):
        enable_policy_rls("ratings", [("x; drop", "SELECT", "true")])
