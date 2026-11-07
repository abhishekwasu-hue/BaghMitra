"""Market linkage L3, part 3: published lots for admin-verified traders and brokers only,
with no grower identity, plot, pin or photo point (spec v1.5 §3 step 2, §4B, §4C; decisions
g, h, j)."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

import httpx
import pytest

from bagmitra_api.market_link.models import BrokerProfile, BuyerProfile, PartyVerification
from bagmitra_api.routers.market_lots import BuyerLotOut, LotPhotoView
from tests.test_market_lots_publish import jpeg_with_gps, upload
from tests.test_market_lots_sync import (
    INSIDE,
    LOTS,
    accept,
    draft,
    headers,
    ml,
    photo,
    storage,
)
from tests.test_plots_sync import push

# The enabled client and storage fixtures of part 1.
__all__ = ["ml", "storage"]


async def viewer(
    c: Any, kind: str = "buyer", status: str = "approved", checked: bool = True
) -> dict[str, str]:
    user = uuid.uuid4()
    async with c.maker() as s:
        model = BuyerProfile if kind == "buyer" else BrokerProfile
        prof = model(user_id=user, name="Trader", phone="+919800000001", district="Amravati")
        s.add(prof)
        await s.flush()
        s.add(
            PartyVerification(
                subject_type=kind,
                subject_id=prof.id,
                document_keys=[],
                status=status,
                checked_by=uuid.uuid4() if checked else None,
                checked_at=datetime.now(UTC) if checked else None,
            )
        )
        await s.commit()
    return headers(user)


async def test_flag_off_hides_every_lot_endpoint(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    some = uuid.uuid4()
    for method, path in (
        ("GET", LOTS),
        ("POST", f"{LOTS}/{some}/publish"),
        ("POST", f"{LOTS}/{some}/close"),
        ("PUT", f"/v1/market-link/lot-photos/{some}/photo"),
        ("GET", f"/v1/market-link/lot-photos/{some}/url"),
    ):
        r = await client.request(method, path, headers=auth_headers, content=b"x")
        assert r.status_code == 404, (path, r.text)


async def test_unverified_sees_no_lot(ml: Any) -> None:
    grower = uuid.uuid4()
    lot_id, _ = await draft(ml, headers(grower), grower)
    await ml.post(f"{LOTS}/{lot_id}/publish", headers=headers(grower))
    for h in (
        headers(grower),  # a grower
        headers(uuid.uuid4()),  # anyone signed in
        await viewer(ml, status="pending"),
        await viewer(ml, status="rejected"),
        await viewer(ml, checked=False),  # "approved" without who / when never counts
    ):
        r = await ml.get(LOTS, headers=h)
        assert (r.status_code, r.json()["error"]["code"]) == (403, "not_verified")
    assert (await ml.get(LOTS)).status_code == 401


@pytest.mark.parametrize("kind", ["buyer", "broker"])
async def test_verified_sees_published_only_without_identity(ml: Any, kind: str) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    published, photos = await draft(ml, h, grower)
    await draft(ml, h, grower)  # stays a draft
    closed, _ = await draft(ml, h, grower)
    await ml.post(f"{LOTS}/{published}/publish", headers=h)
    await ml.post(f"{LOTS}/{closed}/publish", headers=h)
    await ml.post(f"{LOTS}/{closed}/close", headers=h)
    v = await viewer(ml, kind)
    r = await ml.get(LOTS, headers=v)
    assert r.status_code == 200, r.text
    [item] = r.json()["lots"]
    assert item["id"] == str(published)
    assert set(item) == set(BuyerLotOut.model_fields)
    assert (item["crop"], item["quantity_t"], item["basis"]) == ("santra", 12.5, "per_tonne")
    assert (item["village"], item["district"]) == ("Warud", "Amravati")
    assert {p["id"] for p in item["photos"]} == {str(p) for p in photos}
    assert set(item["photos"][0]) == {"id", "captured_at"}
    text = r.text
    for secret in (str(grower), "Ramesh", "+919812345678", "21.2751", "78.5853", "Bag 1"):
        assert secret not in text
    # Filters
    assert (await ml.get(LOTS, headers=v, params={"district": "Nagpur"})).json()["lots"] == []
    assert len((await ml.get(LOTS, headers=v, params={"crop": "santra"})).json()["lots"]) == 1


def test_buyer_schema_has_no_identity_fields() -> None:
    names = set(BuyerLotOut.model_fields) | set(LotPhotoView.model_fields)
    for banned in ("owner_id", "plot_id", "name", "display_name", "phone", "lat", "lon", "pin"):
        assert banned not in names
    assert not any("commission" in n or "income" in n for n in names)


async def test_lot_photo_links_for_the_grower_and_verified_buyers_only(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, photos = await draft(ml, h, grower, uploaded=False)
    p = photos[0]
    assert (await upload(ml, p, h, jpeg_with_gps())).status_code == 200
    await push(ml, h, *[photo(lot_id, i, f"{grower}/{i}.jpg") for i in photos])
    assert (await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)).status_code == 200
    other = headers(uuid.uuid4())
    await accept(ml, other)
    url = f"/v1/market-link/lot-photos/{p}/url"
    assert (await ml.get(url, headers=h)).status_code == 200
    assert (await ml.get(url, headers=other)).status_code == 404
    assert (await ml.get(url, headers=await viewer(ml, status="pending"))).status_code == 404
    got = await ml.get(url, headers=await viewer(ml))
    assert got.status_code == 200
    # No key (it names the grower's account), no point.
    assert set(got.json()) == {"url", "expires_in"}
    for secret in ("21.2751", "78.5853", "lat", "lon"):
        assert secret not in got.text


@pytest.mark.parametrize(
    ("at", "plot", "ok"),
    [
        (INSIDE, {}, True),
        ((21.2815, 78.585), {}, True),  # about 170 m north of the boundary: near
        ((21.30, 78.585), {}, False),  # over 2 km away
        ((21.2752, 78.5852), {"boundary": None}, True),  # near the plot point only
        ((21.30, 78.585), {"boundary": None}, False),
        (INSIDE, {"boundary": None, "centroid_lat": None, "centroid_lon": None}, False),
    ],
)
async def test_publish_needs_photos_taken_in_the_orchard(
    ml: Any, at: tuple[float, float], plot: dict[str, Any], ok: bool
) -> None:
    """Spec §4C: a lot photographed away from the mapped plot is published but waits for an
    admin check: it is not in the traders' list and its photos are not shown to them."""
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, photos = await draft(ml, h, grower, at=at, **plot)
    r = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "published"
    assert (r.json()["orchard_check"] in ("inside", "near")) is ok
    v = await viewer(ml)
    listed = [x["id"] for x in (await ml.get(LOTS, headers=v)).json()["lots"]]
    assert (str(lot_id) in listed) is ok
    url = f"/v1/market-link/lot-photos/{photos[0]}/url"
    assert (await ml.get(url, headers=v)).status_code == (200 if ok else 404)
    assert (await ml.get(url, headers=h)).status_code == 200  # the grower always sees them
