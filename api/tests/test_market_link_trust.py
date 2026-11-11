"""Market linkage L7 (spec v1.5 §4, §4C): duplicate numbers, returning suspended users, the
yearly re-check job, and the same-phone / pair-only helpers for the rating flow."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
from sqlalchemy import select

from bagmitra_api.core.settings import Settings
from bagmitra_api.market_link.models import (
    AdminAction,
    DealParty,
    DeviceSighting,
    MarketDeal,
    MarketLot,
    MarketOffer,
    VerificationCheck,
)
from bagmitra_api.market_link.recheck_job import SKIPPED_OFF, run_recheck
from bagmitra_api.market_link.trust import norm_name, norm_number, pair_only, same_device
from tests.test_market_link_checks import _check
from tests.test_market_link_registration import (
    ADMIN,
    ADMIN_BASE,
    ADMIN_ID,
    GSTIN,
    NOW,
    WARUD,
    Maker,
    _reset_clock,
    api,
    fix,
    headers,
    maker,
    register,
    storage,
)

__all__ = ["_reset_clock", "api", "maker", "storage"]  # fixtures used below


# --- duplicate numbers and returning suspended users (spec §4C) ---------------------------------


async def test_second_claim_of_a_number_is_flagged_to_admin(api: httpx.AsyncClient) -> None:
    first = await register(api, "buyer", headers(), apmc_licence_no="WRD/12")
    second = await register(
        api, "buyer", headers(), name="Other Trader", gst_no=None, apmc_licence_no="wrd 12"
    )
    queue = (await api.get(f"{ADMIN_BASE}/verifications", headers=ADMIN)).json()["subjects"]
    flagged = {q["subject_id"]: q for q in queue}
    assert "duplicate_number" in flagged[second["id"]]["flags"]
    [related] = flagged[second["id"]]["related"]
    assert (related["why"], related["subject_id"]) == ("apmc_licence_no", first["id"])
    assert [r["subject_id"] for r in flagged[first["id"]]["related"]] == [second["id"]]
    assert norm_number(" 27abcde1234f1z5 ") == GSTIN


async def _suspend(maker: Maker, subject_id: str, action: str = "suspend") -> None:
    async with maker() as s:
        s.add(
            AdminAction(
                subject_type="buyer",
                subject_id=uuid.UUID(subject_id),
                action=action,
                reason_code="fake_identity",
                actor_id=ADMIN_ID,
                acted_at=datetime.now(UTC),
            )
        )
        await s.commit()


async def test_returning_suspended_user_goes_to_admin_by_name_number_or_gps(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    bad = await register(api, "buyer", headers(), name="Ramesh Patil")
    await _suspend(maker, bad["id"])
    by_name = await register(
        api,
        "buyer",
        headers(),
        name="ramesh  patil.",
        gst_no=None,
        apmc_licence_no="X-1",
        fix=fix(lat=20.0, lon=77.0),
    )
    by_number = await register(api, "buyer", headers(), name="New Name")
    near = (WARUD[0] + 0.005, WARUD[1])  # about 0.6 km away
    by_gps = await register(
        api, "broker", headers(), name="Someone Else", fix=fix(lat=near[0], lon=near[1])
    )
    far = await register(api, "broker", headers(), name="Far Away", fix=fix(lat=20.0, lon=77.0))
    queue = (await api.get(f"{ADMIN_BASE}/verifications", headers=ADMIN)).json()["subjects"]
    whys = {
        q["subject_id"]: {r["why"] for r in q["related"] if r["flag"] == "returning_suspended"}
        for q in queue
    }
    assert whys[by_name["id"]] == {"name"}
    assert "gst_no" in whys[by_number["id"]]
    assert whys[by_gps["id"]] == {"gps"}
    assert whys[far["id"]] == set()
    assert norm_name("रमेश  पाटील") == norm_name("रमेश पाटील")
    await _suspend(maker, bad["id"], "restore")
    queue = (await api.get(f"{ADMIN_BASE}/verifications", headers=ADMIN)).json()["subjects"]
    assert not [q for q in queue if "returning_suspended" in q["flags"]]


# --- yearly re-check job -------------------------------------------------------------------------


async def test_recheck_job_lists_old_passes_and_a_new_check_clears_them(
    api: httpx.AsyncClient, maker: Maker, settings: Settings
) -> None:
    out = await register(api, "buyer", headers(), apmc_licence_no="WRD/12")
    sid = uuid.UUID(out["id"])
    old, recent = NOW - timedelta(days=366), NOW - timedelta(days=100)
    async with maker() as s:
        for kind, at in (("gstin", old), ("apmc", recent)):
            s.add(
                VerificationCheck(
                    subject_type="buyer",
                    subject_id=sid,
                    kind=kind,
                    number=GSTIN if kind == "gstin" else "WRD/12",
                    result="passed",
                    checked_by=ADMIN_ID,
                    checked_at=at,
                )
            )
        await s.commit()
    on = settings.model_copy(update={"market_link_enabled": True})
    async with maker() as s:
        off = await run_recheck(s, settings.model_copy(update={"market_link_enabled": False}), NOW)
        assert off.skipped_reason == SKIPPED_OFF
        first = await run_recheck(s, on, NOW)
        assert (first.listed, first.already_listed) == (1, 0)
        again = await run_recheck(s, on, NOW)
        assert (again.listed, again.already_listed) == (0, 1)
    items = (await api.get(f"{ADMIN_BASE}/rechecks", headers=ADMIN)).json()["items"]
    assert [(i["subject_id"], i["kind"]) for i in items] == [(str(sid), "gstin")]
    assert (await _check(api, "buyer", str(sid), "gstin")).status_code == 200
    assert (await api.get(f"{ADMIN_BASE}/rechecks", headers=ADMIN)).json()["items"] == []
    assert (await api.get(f"{ADMIN_BASE}/rechecks", headers=headers())).status_code == 403


# --- same phone and pair-only deals (helpers for the rating flow, spec §4C) --------------------


async def test_accounts_on_one_phone_are_seen_by_the_push_registration(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    a, b, c = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    for user, token in ((a, "phone-1"), (b, "phone-1"), (c, "phone-2"), (a, "phone-1")):
        body = {"token": token, "platform": "android"}
        assert (await api.post("/v1/me/devices", json=body, headers=headers(user))).status_code == (
            204
        )
    async with maker() as s:
        assert await same_device(s, a, b) is True
        assert await same_device(s, a, c) is False
        rows = list(await s.scalars(select(DeviceSighting)))
        assert len(rows) == 3
        assert all(len(r.device_hash) == 64 and "phone" not in r.device_hash for r in rows)


async def test_pair_only_deals_are_flagged(maker: Maker) -> None:
    grower, trader, other = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()

    async def deal(s: Any, g: uuid.UUID, t: uuid.UUID, done: bool = True) -> None:
        lot = MarketLot(
            id=uuid.uuid4(),
            owner_id=g,
            client_updated_at=NOW,
            last_seq=1,
            plot_id=uuid.uuid4(),
            crop="santra",
            quantity_t=5,
            harvest_from=NOW.date(),
            harvest_to=NOW.date(),
            basis="per_quintal",
            status="closed",
        )
        s.add(lot)
        await s.flush()
        offer = MarketOffer(
            lot_id=lot.id,
            basis="per_quintal",
            rate_paise=100,
            harvest_date=NOW.date(),
            buyer_user_id=t,
            submitted_by=t,
            status="accepted",
        )
        s.add(offer)
        await s.flush()
        row = MarketDeal(
            lot_id=lot.id,
            offer_id=offer.id,
            status="completed" if done else "active",
            completed_at=NOW if done else None,
        )
        s.add(row)
        await s.flush()
        s.add_all(
            [
                DealParty(deal_id=row.id, role="grower", user_id=g),
                DealParty(deal_id=row.id, role="trader", user_id=t),
            ]
        )

    async with maker() as s:
        for _ in range(2):
            await deal(s, grower, trader)
        await deal(s, grower, trader, done=False)
        await s.commit()
        assert await pair_only(s, grower, trader, 3) is False  # two completed only
        assert await pair_only(s, grower, trader, 2) is True
        await deal(s, trader, other)  # the trader also deals with someone else
        await deal(s, grower, other)
        await s.commit()
        assert await pair_only(s, grower, trader, 2) is False
