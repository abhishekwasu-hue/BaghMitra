"""Season sale package L9a rules (spec v1.5 §4E): the one visibility rule for traders
(table-driven), the trader view fields, the switch guard, grants (unique UTR, gapless receipt
numbers per prefix), revoke and the admin_actions log, at the service level."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import AdminAction, MarketLot
from bagmitra_api.market_link.package import (
    GrantRequest,
    PackageError,
    apply_changes,
    company_profile,
    lot_visible_to_traders,
    missing_for_switch,
    package_settings,
    record_grant,
    revoke_grant,
)
from bagmitra_api.market_link.package_models import PackageGrant
from bagmitra_api.routers.market_lots import BuyerLotOut
from bagmitra_api.routers.scouting_photos import get_photo_storage
from bagmitra_api.weather.service import get_clock
from tests.test_market_lots_buyer import viewer
from tests.test_market_lots_sync import LOTS, StoringStorage, draft, headers

NOW = datetime(2026, 11, 20, 6, 0, tzinfo=UTC)
ADMIN_ID = uuid.uuid4()


@pytest.fixture
async def pkg(settings: Settings, engine: AsyncEngine) -> AsyncIterator[Any]:
    """The market-link app with a movable clock (`c.now[0]`)."""
    app = create_app(settings.model_copy(update={"market_link_enabled": True}))
    maker = async_sessionmaker(engine, expire_on_commit=False)
    now = [NOW]
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_photo_storage] = StoringStorage
    app.dependency_overrides[get_clock] = lambda: lambda: now[0]
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        c.maker, c.now = maker, now  # type: ignore[attr-defined]
        yield c


async def published(c: Any) -> tuple[uuid.UUID, uuid.UUID]:
    grower = uuid.uuid4()
    lot_id, _ = await draft(c, headers(grower), grower)
    assert (await c.post(f"{LOTS}/{lot_id}/publish", headers=headers(grower))).status_code == 200
    return grower, lot_id


async def listed(c: Any) -> set[str]:
    r = await c.get(LOTS, headers=await viewer(c))
    assert r.status_code == 200, r.text
    return {x["id"] for x in r.json()["lots"]}


async def configure(c: Any, *, switch: bool = False, prefix: str = "BM/") -> None:
    """Company profile and settings filled straight in the database."""
    async with c.maker() as s:
        profile, settings = await company_profile(s), await package_settings(s)
        profile.legal_name, profile.gstin = "BagMitra Agritech Pvt Ltd", "27AABCB1234F1Z5"
        profile.upi_id, profile.invoice_prefix = "bagmitra@okaxis", prefix
        settings.price_paise, settings.validity_days, settings.enabled = 150_000, 45, switch
        await s.commit()


async def give(c: Any, grower: uuid.UUID, ref: str, lot: uuid.UUID | None = None) -> PackageGrant:
    async with c.maker() as s:
        g = await record_grant(
            s,
            GrantRequest(grower, lot, 150_000, "upi", ref, date(2026, 11, 19)),
            admin_id=ADMIN_ID,
            now=c.now[0],
        )
        await s.commit()
        return g


@pytest.mark.parametrize(
    ("switch", "grant_for", "moves", "revoke", "shown"),
    [
        (False, None, timedelta(0), False, True),  # switch OFF: every published lot
        (True, None, timedelta(0), False, False),  # ON, no grant: hidden
        (True, "lot", timedelta(0), False, True),  # ON, a grant for this lot
        (True, "all", timedelta(0), False, True),  # ON, a grant for all the grower's lots
        (True, "other", timedelta(0), False, False),  # ON, a grant for another lot only
        (True, "lot", timedelta(days=45), False, False),  # expired: hidden
        (True, "lot", timedelta(days=44), False, True),  # last day: shown
        (True, "lot", timedelta(0), True, False),  # revoked: hidden
    ],
)
async def test_lot_visible_to_traders(
    pkg: Any, switch: bool, grant_for: str | None, moves: timedelta, revoke: bool, shown: bool
) -> None:
    await configure(pkg, switch=switch)
    grower, lot_id = await published(pkg)
    other = uuid.uuid4()
    if grant_for == "other":
        async with pkg.maker() as s:
            row = await s.get(MarketLot, lot_id)
            assert row is not None
            twin = {c.key: getattr(row, c.key) for c in MarketLot.__table__.columns}
            s.add(MarketLot(**{**twin, "id": other}))
            await s.commit()
    if grant_for is not None:
        target = {"lot": lot_id, "all": None, "other": other}[grant_for]
        g = await give(pkg, grower, "UTR246824682468", target)
        if revoke:
            async with pkg.maker() as s:
                row = await s.get(PackageGrant, g.id)
                assert row is not None
                revoke_grant(s, row, "bounced", admin_id=ADMIN_ID, now=NOW)
                await s.commit()
    pkg.now[0] = NOW + moves
    assert (str(lot_id) in await listed(pkg)) is shown
    async with pkg.maker() as s:
        rule = lot_visible_to_traders(MarketLot, pkg.now[0], switch)
        hit = await s.scalar(select(MarketLot.id).where(MarketLot.id == lot_id, rule))
        assert (hit is not None) is shown
        assert await s.get(MarketLot, lot_id) is not None  # hiding never deletes the lot


async def test_hidden_lot_keeps_its_photos_from_traders(pkg: Any) -> None:
    await configure(pkg, switch=True)
    grower = uuid.uuid4()
    lot_id, photos = await draft(pkg, headers(grower), grower)
    await pkg.post(f"{LOTS}/{lot_id}/publish", headers=headers(grower))
    url = f"/v1/market-link/lot-photos/{photos[0]}/url"
    v = await viewer(pkg)
    assert (await pkg.get(url, headers=v)).status_code == 404
    assert (await pkg.get(url, headers=headers(grower))).status_code == 200  # the grower's own
    await give(pkg, grower, "UTR135713571357")
    assert (await pkg.get(url, headers=v)).status_code == 200


async def test_trader_view_has_only_the_section_4e_fields(pkg: Any) -> None:
    """First name, crop / variety, acres, tonnes, quality, photos, harvest window, district;
    never the surname, phone, village or coordinates before acceptance."""
    grower, _ = await published(pkg)
    r = await pkg.get(LOTS, headers=await viewer(pkg))
    [item] = r.json()["lots"]
    assert (
        set(item)
        == set(BuyerLotOut.model_fields)
        == {
            *("id", "first_name", "crop", "variety", "acres", "quantity_t", "quality"),
            *("harvest_from", "harvest_to", "district", "published_at", "photos"),
        }
    )
    assert (item["first_name"], item["district"]) == ("Ramesh", "Amravati")
    assert item["acres"] is not None
    assert item["acres"] > 0
    for secret in ("Patil", "+919812345678", "9812345678", "Warud", "21.27", "78.58", str(grower)):
        assert secret not in r.text, secret


async def test_guard_names_the_empty_fields(pkg: Any) -> None:
    async with pkg.maker() as s:
        profile, settings = await company_profile(s), await package_settings(s)
        assert settings.enabled is False
        assert missing_for_switch(profile, settings) == [
            "legal_name",
            "gstin",
            "upi_id",
            "price_paise",
        ]
        profile.gstin, settings.price_paise = "27AABCB1234F1Z5", 100
        assert missing_for_switch(profile, settings) == ["legal_name", "upi_id"]


async def test_grants_unique_utr_and_gapless_receipts(pkg: Any) -> None:
    await configure(pkg)
    grower, _ = await published(pkg)
    nos = [(await give(pkg, grower, f"UTR{i:06d}")).receipt_no for i in range(3)]
    assert nos == ["BM/00001", "BM/00002", "BM/00003"]
    with pytest.raises(PackageError, match="recorded") as dup:
        await give(pkg, grower, "utr 000 001")  # typed again with a space, lower case
    assert dup.value.code == "duplicate_payment_ref"
    await configure(pkg, prefix="NEW/")
    assert (await give(pkg, grower, "UTR9")).receipt_no == "NEW/00001"
    async with pkg.maker() as s:
        counts = list(await s.scalars(select(PackageGrant.receipt_seq)))
    assert sorted(counts) == [1, 1, 2, 3]


async def test_every_change_grant_and_revoke_is_logged(pkg: Any) -> None:
    await configure(pkg)
    grower, _ = await published(pkg)
    async with pkg.maker() as s:
        settings = await package_settings(s)
        changed = apply_changes(
            s, settings, {"price_paise": 200_000, "validity_days": 45}, actor_id=ADMIN_ID, now=NOW
        )
        assert changed == ["price_paise"]
        assert apply_changes(s, settings, {"validity_days": 45}, actor_id=ADMIN_ID, now=NOW) == []
        await s.commit()
    g = await give(pkg, grower, "UTR111122223333")
    async with pkg.maker() as s:
        row = await s.get(PackageGrant, g.id)
        assert row is not None
        revoke_grant(s, row, "wrong UTR", admin_id=ADMIN_ID, now=NOW)
        with pytest.raises(PackageError):
            revoke_grant(s, row, "again", admin_id=ADMIN_ID, now=NOW)
        await s.commit()
        rows = list(await s.scalars(select(AdminAction).order_by(AdminAction.acted_at)))
    assert [(a.subject_type, a.action) for a in rows] == [
        ("package_settings", "settings_change"),
        ("package_grant", "grant"),
        ("package_grant", "revoke"),
    ]
    assert rows[0].detail == {"old": {"price_paise": 150_000}, "new": {"price_paise": 200_000}}
    assert {a.actor_id for a in rows} == {ADMIN_ID}
    assert all(a.user_id is None for a in rows)  # not shown to the grower
    assert rows[2].detail is not None
    assert rows[2].detail["new"]["revoked_reason"] == "wrong UTR"
