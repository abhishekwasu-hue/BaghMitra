"""Admin subscription switch and per-role amounts (billing addendum §7): default OFF = the full
app; every change is in the ledger with the admin id and old / new; the user's plan offer only
appears while the switch is ON and the role has an amount."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.billing.models import BillingEvent, BillingPlan, BillingRolePrice
from bagmitra_api.billing.switch import user_roles
from bagmitra_api.db.models.plot import Plot
from bagmitra_api.market_link.models import BrokerProfile, BuyerProfile
from tests.conftest import make_token
from tests.test_billing_api import BASE, KB_ADMIN, api, entitlements, grower

ADMIN_ID = uuid.uuid4()
ADMIN = {
    "Authorization": f"Bearer {make_token(ADMIN_ID, app_metadata={'roles': ['billing_admin']})}"
}


async def set_amount(engine: AsyncEngine, role: str, paise: int | None) -> None:
    async with async_sessionmaker(engine)() as session:
        row = await session.get(BillingRolePrice, role) or BillingRolePrice(role=role)
        row.amount_paise = paise
        session.add(row)
        await session.commit()


async def test_the_switch_starts_off_with_every_role_free(engine: AsyncEngine) -> None:
    async with api(engine) as client:
        res = await client.get(f"{BASE}/settings", headers=ADMIN)
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["enabled"] is False
    assert body["starts_on"] is None
    assert [r["role"] for r in body["roles"]] == [
        "grower",
        "trader",
        "broker",
        "exporter",
        "provider",
    ]
    assert all(r["amount_paise"] is None and r["play_price_paise"] is None for r in body["roles"])


async def test_only_billing_admins_change_the_switch(engine: AsyncEngine) -> None:
    async with api(engine) as client:
        for headers in (grower(uuid.uuid4()), KB_ADMIN):
            assert (await client.get(f"{BASE}/settings", headers=headers)).status_code == 403
            put = await client.put(f"{BASE}/settings", headers=headers, json={"enabled": True})
            assert put.status_code == 403
        assert (await client.get(f"{BASE}/settings")).status_code == 401


async def test_every_switch_change_is_logged_with_admin_and_old_new(engine: AsyncEngine) -> None:
    async with api(engine) as client:
        on = await client.put(
            f"{BASE}/settings", headers=ADMIN, json={"enabled": True, "starts_on": "2026-12-01"}
        )
        assert on.status_code == 200, on.text
        assert on.json()["enabled"] is True
        assert on.json()["starts_on"] == "2026-12-01"
        same = await client.put(
            f"{BASE}/settings", headers=ADMIN, json={"enabled": True, "starts_on": "2026-12-01"}
        )
        assert same.status_code == 200
        off = await client.put(f"{BASE}/settings", headers=ADMIN, json={"enabled": False})
        assert off.json()["enabled"] is False
    async with async_sessionmaker(engine)() as session:
        rows = list(
            await session.scalars(
                select(BillingEvent).where(BillingEvent.event_type == "switch_changed")
            )
        )
    assert len(rows) == 2  # an unchanged save writes nothing
    payloads = sorted((r.payload for r in rows), key=lambda p: p["new"]["enabled"], reverse=True)
    assert payloads[0] == {
        "admin_id": str(ADMIN_ID),
        "old": {"enabled": False, "starts_on": None},
        "new": {"enabled": True, "starts_on": "2026-12-01"},
    }
    assert payloads[1]["old"] == {"enabled": True, "starts_on": "2026-12-01"}
    assert all(r.provider == "admin" and r.subscription_id is None for r in rows)


async def test_off_gives_the_full_app_and_no_offer(engine: AsyncEngine) -> None:
    await set_amount(engine, "grower", 9900)
    user = uuid.uuid4()
    async with api(engine) as client:
        snap = (await entitlements(client, user))["entitlements"]
        offer = (await client.get("/v1/billing/plan", headers=grower(user))).json()
    features = snap["features"]  # type: ignore[index]
    assert features["calendar"] == {"enabled": True, "limit": None}
    assert features["photos"] == {"enabled": True, "limit": None}
    assert {k: offer[k] for k in ("in_force", "role", "product_id", "covered", "locked")} == {
        "in_force": False,
        "role": None,
        "product_id": None,
        "covered": False,
        "locked": [],
    }


async def test_on_offers_the_highest_priced_role_but_locks_nothing(engine: AsyncEngine) -> None:
    await set_amount(engine, "grower", 9900)
    await set_amount(engine, "trader", 29900)
    user = uuid.uuid4()
    async with async_sessionmaker(engine)() as session:
        session.add(_buyer(user))
        await session.commit()
    async with api(engine) as client:
        await client.put(f"{BASE}/settings", headers=ADMIN, json={"enabled": True})
        offer = (await client.get("/v1/billing/plan", headers=grower(user))).json()
        snap = (await entitlements(client, user))["entitlements"]
    assert offer["in_force"] is True
    assert offer["role"] == "trader"
    assert offer["product_id"] == "bagmitra_trader"
    assert offer["base_plan_id"] == "monthly"
    assert offer["covered"] is False
    assert offer["locked"] == []  # the gate map is empty (Q117)
    assert all(f["enabled"] for f in snap["features"].values())  # type: ignore[index]


async def test_a_future_start_date_is_not_in_force_yet(engine: AsyncEngine) -> None:
    await set_amount(engine, "grower", 9900)
    later = (datetime.now(UTC) + timedelta(days=5)).date().isoformat()
    async with api(engine) as client:
        await client.put(
            f"{BASE}/settings", headers=ADMIN, json={"enabled": True, "starts_on": later}
        )
        offer = (await client.get("/v1/billing/plan", headers=grower(uuid.uuid4()))).json()
    assert offer["in_force"] is False
    assert offer["role"] is None


async def test_a_role_plan_grant_covers_the_user(engine: AsyncEngine) -> None:
    await set_amount(engine, "grower", 9900)
    user = uuid.uuid4()
    async with async_sessionmaker(engine)() as session:
        session.add(BillingPlan(id=uuid.uuid4(), key="role_grower", names={"en": "G"}, kind="role"))
        await session.commit()
    async with api(engine) as client:
        await client.put(f"{BASE}/settings", headers=ADMIN, json={"enabled": True})
        res = await client.post(
            f"{BASE}/grants",
            headers=ADMIN,
            json={
                "subject_type": "farmer",
                "subject_id": str(user),
                "plan_key": "role_grower",
                "period_end": (datetime.now(UTC) + timedelta(days=30)).isoformat(),
                "reason": "course bundle",
            },
        )
        assert res.status_code == 201, res.text
        offer = (await client.get("/v1/billing/plan", headers=grower(user))).json()
    assert offer["role"] == "grower"
    assert offer["covered"] is True


async def test_roles_come_from_plots_and_market_registrations(engine: AsyncEngine) -> None:
    nobody, trader, both, broker = (uuid.uuid4() for _ in range(4))
    async with async_sessionmaker(engine)() as session:
        session.add_all([_buyer(trader), _buyer(both, kind="exporter"), _plot(both)])
        session.add(
            BrokerProfile(user_id=broker, name="B", phone="+919800000001", district="Nagpur")
        )
        await session.flush()
        assert await user_roles(session, nobody) == ("grower",)
        assert await user_roles(session, trader) == ("trader",)
        assert await user_roles(session, both) == ("grower", "exporter")
        assert await user_roles(session, broker) == ("broker",)


def _buyer(user: uuid.UUID, kind: str = "trader") -> BuyerProfile:
    return BuyerProfile(
        user_id=user,
        name="T",
        phone="+919800000000",
        district="Nagpur",
        kind=kind,
        iec_no="0123456789" if kind == "exporter" else None,
    )


def _plot(owner: uuid.UUID) -> Plot:
    return Plot(
        id=uuid.uuid4(),
        owner_id=owner,
        name="Plot",
        crop="orange",
        area_sq_m=1000.0,
        client_updated_at=datetime.now(UTC),
        last_seq=1,
    )
