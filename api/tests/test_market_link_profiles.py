"""Market linkage L2: public profiles, taluka list and service directory (spec v1.5 §3 step 6,
§3A, §4; decisions g, h). Verified only; never coordinates, PIN, numbers or flags; deals and
stars computed from the tables (0 / empty until any exist); badges only from records, with
dates, never "guarantee"; providers by distance from the grower's own plot."""

from __future__ import annotations

import json
import uuid
from datetime import timedelta
from typing import Any

import httpx

from bagmitra_api.db.models import Plot
from bagmitra_api.market_link.models import (
    DealParty,
    MarketDeal,
    MarketLot,
    MarketOffer,
    Rating,
    RatingTag,
)
from bagmitra_api.market_link.registration import distance_km
from tests.test_market_link_registration import (
    ADMIN,
    ADMIN_BASE,
    AMRAVATI,
    BASE,
    ME,
    NOW,
    USER,
    WARUD,
    Maker,
    api,
    approve,
    fix,
    headers,
    maker,
    register,
    storage,
)

__all__ = ["api", "maker", "storage"]  # fixtures used below
SECRET_KEYS = {"lat", "lon", "fix", "flags", "pin", "accuracy_m", "numbers", "status", "reason"}


def _assert_public(profile: dict[str, Any]) -> None:
    text = json.dumps(profile)
    assert not (SECRET_KEYS & set(profile)), set(profile)
    assert str(WARUD[0]) not in text
    assert str(WARUD[1]) not in text
    assert "444906" not in text
    assert "27ABCDE1234F1Z5" not in text
    assert "guarantee" not in text.lower()


async def _list(api: httpx.AsyncClient, path: str = "profiles", **params: Any) -> Any:
    response = await api.get(f"{BASE}/{path}", params=params, headers=headers(USER))
    assert response.status_code == 200, response.text
    return response.json()["profiles"]


async def test_only_verified_profiles_are_public_and_without_coordinates(
    api: httpx.AsyncClient,
) -> None:
    pending = await register(api, "buyer", headers(), name="Pending Trader")
    shown = await register(api, "buyer", headers(), name="Shown Trader")
    rejected = await register(api, "buyer", headers(), name="Rejected Trader")
    await approve(api, "buyer", shown["id"])
    await api.post(
        f"{ADMIN_BASE}/verifications/buyer/{rejected['id']}/decision",
        json={"status": "rejected", "reason": "GSTIN cancelled"},
        headers=ADMIN,
    )
    listed = await _list(api, role="trader", taluka="warud")
    assert [p["id"] for p in listed] == [shown["id"]]
    (p,) = listed
    _assert_public(p)
    assert (p["name"], p["firm"], p["phone"], p["markets"]) == (
        "Shown Trader",
        "Patil Fruits",
        "+919800000001",
        ["Warud APMC"],
    )
    assert p["badges"] == [
        {"kind": "checked", "on": "2026-11-07", "place": None, "since_year": None},
        {"kind": "gst_checked", "on": "2026-11-07", "place": None, "since_year": None},
        {
            "kind": "registered_from",
            "on": "2026-11-07",
            "place": "Warud, Amravati",
            "since_year": None,
        },
    ]
    assert (p["deals_completed"], p["stars"], p["tags"]) == (0, [], [])
    for other in (pending, rejected):
        url = f"{BASE}/profiles/buyer/{other['id']}"
        assert (await api.get(url, headers=ME)).status_code == 404
    one = await api.get(f"{BASE}/profiles/buyer/{shown['id']}", headers=ME)
    assert one.status_code == 200
    _assert_public(one.json())
    assert (await api.get(f"{BASE}/profiles", params={"role": "trader"})).status_code == 401
    assert await _list(api, role="exporter") == []
    assert await _list(api, role="trader", district="Nagpur") == []


async def test_no_grower_profile_endpoint(api: httpx.AsyncClient) -> None:
    response = await api.get(f"{BASE}/profiles", params={"role": "grower"}, headers=ME)
    assert response.status_code == 422
    response = await api.get(f"{BASE}/profiles/grower/{uuid.uuid4()}", headers=ME)
    assert response.status_code == 422


async def _deal(maker: Maker, trader: uuid.UUID, broker: uuid.UUID | None, done: bool) -> uuid.UUID:
    grower = uuid.uuid4()
    async with maker() as s:
        lot = MarketLot(
            id=uuid.uuid4(),
            owner_id=grower,
            plot_id=uuid.uuid4(),
            crop="santra",
            quantity_t=10,
            harvest_from=NOW.date(),
            harvest_to=NOW.date() + timedelta(days=10),
            basis="per_tonne",
            status="closed",
            client_updated_at=NOW,
            last_seq=1,
        )
        s.add(lot)
        await s.flush()
        offer = MarketOffer(
            basis="per_tonne",
            rate_paise=3_000_000,
            harvest_date=NOW.date(),
            lot_id=lot.id,
            buyer_user_id=trader,
            broker_user_id=broker,
            submitted_by=trader,
            status="accepted",
        )
        s.add(offer)
        await s.flush()
        deal = MarketDeal(
            lot_id=lot.id,
            offer_id=offer.id,
            status="completed" if done else "active",
            completed_at=NOW if done else None,
        )
        s.add(deal)
        await s.flush()
        s.add(DealParty(deal_id=deal.id, role="grower", user_id=grower))
        s.add(DealParty(deal_id=deal.id, role="trader", user_id=trader))
        if broker is not None:
            s.add(DealParty(deal_id=deal.id, role="broker", user_id=broker))
        await s.commit()
        return deal.id


async def test_deals_stars_and_tags_come_from_the_tables(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    top_user, low_user = uuid.uuid4(), uuid.uuid4()
    top = await register(api, "buyer", headers(top_user), name="Top")
    low = await register(api, "buyer", headers(low_user), name="Low")
    busy = await register(api, "buyer", headers(), name="Busy no stars")
    for p in (top, low, busy):
        await approve(api, "buyer", p["id"])
    tag = RatingTag(
        key="trader_on_date_yes",
        question_key="trader_on_date",
        polarity="positive",
        label_mr="ठरलेल्या दिवशी आले",
        label_hi="तय दिन आए",
        label_en="Came on the agreed date",
        status="active",
    )
    async with maker() as s:
        s.add(tag)
        await s.commit()
    d1 = await _deal(maker, top_user, None, done=True)
    d2 = await _deal(maker, low_user, None, done=True)
    await _deal(maker, low_user, None, done=True)
    await _deal(maker, top_user, None, done=False)  # not completed: not counted
    async with maker() as s:
        for deal, ratee, stars in ((d1, top_user, 5), (d2, low_user, 2)):
            s.add(
                Rating(
                    deal_id=deal,
                    rater_id=uuid.uuid4(),
                    ratee_id=ratee,
                    ratee_role="trader",
                    question_key="trader_on_date",
                    stars=stars,
                    tag_ids=[str(tag.id)] if ratee == top_user else [],
                )
            )
        await s.commit()
    by_rating = await _list(api, role="trader")
    assert [p["name"] for p in by_rating] == ["Top", "Low", "Busy no stars"]
    assert by_rating[0]["stars"] == [{"question_key": "trader_on_date", "average": 5.0, "count": 1}]
    assert by_rating[0]["deals_completed"] == 1
    assert [(t["key"], t["count"]) for t in by_rating[0]["tags"]] == [("trader_on_date_yes", 1)]
    by_deals = await _list(api, role="trader", sort="deals")
    assert [(p["name"], p["deals_completed"]) for p in by_deals] == [
        ("Low", 2),
        ("Top", 1),
        ("Busy no stars", 0),
    ]


async def test_broker_profile_counts_broker_deals_only(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    broker_user = uuid.uuid4()
    broker = await register(api, "broker", headers(broker_user))
    await approve(api, "broker", broker["id"])
    await _deal(maker, uuid.uuid4(), broker_user, done=True)
    (p,) = await _list(api, role="broker", taluka="Warud")
    _assert_public(p)
    assert (p["kind"], p["village"], p["areas"], p["deals_completed"]) == (
        "broker",
        "Shendurjana Ghat",
        ["Warud", "Morshi"],
        1,
    )


# --- service directory -------------------------------------------------------------------------


async def _plot(maker: Maker, owner: uuid.UUID, at: tuple[float, float] | None) -> uuid.UUID:
    pid = uuid.uuid4()
    async with maker() as s:
        s.add(
            Plot(
                id=pid,
                owner_id=owner,
                name="Plot",
                crop="santra",
                area_sq_m=10_000.0,
                centroid_lat=at[0] if at else None,
                centroid_lon=at[1] if at else None,
                client_updated_at=NOW,
                last_seq=1,
            )
        )
        await s.commit()
    return pid


async def test_directory_lists_verified_providers_by_distance(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    pending = await register(api, "provider", headers())
    far = await register(
        api,
        "provider",
        headers(),
        kind="labour_gang",
        name="Amravati Toli",
        taluka="Amravati",
        fix=fix(lat=AMRAVATI[0], lon=AMRAVATI[1]),
    )
    near = await register(api, "provider", headers(), name="Near Kata")
    for p in (far, near):
        await approve(api, "provider", p["id"])
    plot = await _plot(maker, USER, (21.46, 78.25))
    listed = await _list(api, "providers", plot_id=str(plot))
    assert [p["id"] for p in listed] == [near["id"], far["id"]]
    assert pending["id"] not in {p["id"] for p in listed}
    km = round(distance_km(21.46, 78.25, *AMRAVATI))
    assert [p["distance_km"] for p in listed] == [2, km]
    for p in listed:
        _assert_public(p)
        assert p["phone"] == "+919800000003"
    assert [p["id"] for p in await _list(api, "providers", type="labour_gang")] == [far["id"]]
    assert [p["id"] for p in await _list(api, "providers", taluka="amravati")] == [far["id"]]
    assert await _list(api, "providers", district="Nagpur") == []
    no_pin = await _plot(maker, USER, None)
    assert all(p["distance_km"] is None for p in await _list(api, "providers", plot_id=str(no_pin)))
    other = await _plot(maker, uuid.uuid4(), WARUD)
    response = await api.get(f"{BASE}/providers", params={"plot_id": str(other)}, headers=ME)
    assert response.status_code == 404


async def test_directory_warns_of_an_expired_certificate(api: httpx.AsyncClient) -> None:
    out = await register(api, "provider", cert_valid_until="2026-11-06")
    await approve(api, "provider", out["id"])
    (listed,) = await _list(api, "providers")
    assert listed["provider"]["certificate_expired"] is True
    assert listed["provider"]["cert_valid_until"] == "2026-11-06"


def test_distance_is_great_circle() -> None:
    assert distance_km(*WARUD, *WARUD) == 0
    assert 70 < distance_km(*WARUD, *AMRAVATI) < 80
