"""Season sale package L9a admin API (spec v1.5 §4D, §4E; build prompt Addendum 6): company
profile and settings start empty with the switch OFF, the switch guard (the page names the
missing field), grants (unique UTR, gapless receipt numbers per prefix), revoke and the
admin_actions log; admin role and legal gate."""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select

from bagmitra_api.market_link.models import AdminAction
from tests.conftest import make_token
from tests.test_market_lots_sync import headers
from tests.test_package_rules import pkg, published

__all__ = ["pkg"]
PKG = "/v1/admin/market-link/package"
ADMIN_ID = uuid.uuid4()
ADMIN = {
    "Authorization": "Bearer " + make_token(ADMIN_ID, app_metadata={"roles": ["market_link_admin"]})
}
PROFILE = {
    "legal_name": "BagMitra Agritech Pvt Ltd",
    "address": "Warud, Amravati, Maharashtra",
    "gstin": "27AABCB1234F1Z5",
    "upi_id": "bagmitra@okaxis",
    "invoice_prefix": "BM/26-27/",
}
SETTINGS = {"enabled": False, "price_paise": 150_000, "validity_days": 45, "starts_at": None}


async def ready(c: Any, **settings: Any) -> None:
    """Company profile filled and the package settings saved (switch as given)."""
    assert (await c.put(f"{PKG}/company-profile", json=PROFILE, headers=ADMIN)).status_code == 200
    r = await c.put(f"{PKG}/settings", json={**SETTINGS, **settings}, headers=ADMIN)
    assert r.status_code == 200, r.text


async def grant(c: Any, grower: uuid.UUID, ref: str, lot: uuid.UUID | None = None) -> Any:
    return await c.post(
        f"{PKG}/grants",
        json={
            "grower_id": str(grower),
            "lot_id": None if lot is None else str(lot),
            "amount_paise": 150_000,
            "method": "upi",
            "payment_ref": ref,
            "paid_on": "2026-11-19",
        },
        headers=ADMIN,
    )


async def test_profile_and_settings_start_empty_with_the_switch_off(pkg: Any) -> None:
    profile = (await pkg.get(f"{PKG}/company-profile", headers=ADMIN)).json()
    assert profile.pop("merchant_qr") is False
    assert set(profile.values()) == {None}
    s = (await pkg.get(f"{PKG}/settings", headers=ADMIN)).json()
    assert s == {
        "enabled": False,
        "price_paise": None,
        "validity_days": None,
        "starts_at": None,
        "missing": ["legal_name", "gstin", "upi_id", "price_paise"],
    }


async def test_admin_role_and_legal_gate(pkg: Any, client: httpx.AsyncClient) -> None:
    for h in ({}, headers(uuid.uuid4())):
        assert (await pkg.get(f"{PKG}/settings", headers=h)).status_code in (401, 403)
    assert (await client.get(f"{PKG}/settings", headers=ADMIN)).status_code == 404


@pytest.mark.parametrize("empty", ["legal_name", "gstin", "upi_id", "price_paise"])
async def test_guard_blocks_on_while_a_field_is_empty(pkg: Any, empty: str) -> None:
    profile = {k: v for k, v in PROFILE.items() if k != empty}
    await pkg.put(f"{PKG}/company-profile", json=profile, headers=ADMIN)
    body = {
        **SETTINGS,
        "enabled": True,
        **({"price_paise": None} if empty == "price_paise" else {}),
    }
    r = await pkg.put(f"{PKG}/settings", json=body, headers=ADMIN)
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "package_fields_missing"
    assert r.json()["error"]["message"] == f"missing: {empty}"
    assert (await pkg.get(f"{PKG}/settings", headers=ADMIN)).json()["enabled"] is False


async def test_switch_on_then_a_guard_field_cannot_be_cleared(pkg: Any) -> None:
    await ready(pkg, enabled=True)
    assert (await pkg.get(f"{PKG}/settings", headers=ADMIN)).json()["enabled"] is True
    r = await pkg.put(f"{PKG}/company-profile", json={"gstin": ""}, headers=ADMIN)
    assert (r.status_code, r.json()["error"]["message"]) == (409, "missing: gstin")
    got = (await pkg.get(f"{PKG}/company-profile", headers=ADMIN)).json()
    assert got["gstin"] == PROFILE["gstin"]


async def test_bad_profile_values_are_refused(pkg: Any) -> None:
    for bad in ({"gstin": "27AAB"}, {"upi_id": "no-at-sign"}, {"bank_account_last4": "12345"}):
        r = await pkg.put(f"{PKG}/company-profile", json=bad, headers=ADMIN)
        assert r.status_code == 422, bad


async def test_settings_changes_and_grants_are_logged(pkg: Any) -> None:
    await ready(pkg)
    await pkg.put(f"{PKG}/settings", json={**SETTINGS, "price_paise": 200_000}, headers=ADMIN)
    grower, lot_id = await published(pkg)
    g = (await grant(pkg, grower, "UTR111122223333", lot_id)).json()
    await pkg.post(f"{PKG}/grants/{g['id']}/revoke", json={"reason": "wrong UTR"}, headers=ADMIN)
    async with pkg.maker() as s:
        rows = list(await s.scalars(select(AdminAction).order_by(AdminAction.acted_at)))
    kinds = [(a.subject_type, a.action) for a in rows]
    assert kinds.count(("company_profile", "settings_change")) == 1
    assert kinds.count(("package_settings", "settings_change")) == 2
    assert ("package_grant", "grant") in kinds
    assert ("package_grant", "revoke") in kinds
    price = [a for a in rows if a.detail and "price_paise" in (a.detail["new"] or {})][-1]
    assert price.detail == {"old": {"price_paise": 150_000}, "new": {"price_paise": 200_000}}
    assert {a.actor_id for a in rows} == {ADMIN_ID}
    assert all(a.user_id is None for a in rows)  # not shown to the grower
    revoked = next(a for a in rows if a.action == "revoke")
    assert revoked.detail["new"]["revoked_reason"] == "wrong UTR"
    assert revoked.detail["old"]["revoked_at"] is None


async def test_grant_needs_the_profile_price_and_validity(pkg: Any) -> None:
    grower, _ = await published(pkg)
    r = await grant(pkg, grower, "UTR000000000001")
    assert r.status_code == 409
    assert r.json()["error"]["message"] == (
        "missing: legal_name, gstin, upi_id, price_paise, validity_days"
    )


async def test_duplicate_utr_is_refused(pkg: Any) -> None:
    await ready(pkg)
    grower, _ = await published(pkg)
    assert (await grant(pkg, grower, "utr 4455 6677")).status_code == 201
    r = await grant(pkg, grower, "UTR44556677")  # the same reference typed again
    assert (r.status_code, r.json()["error"]["code"]) == (409, "duplicate_payment_ref")


async def test_receipt_numbers_are_unique_and_gapless_per_prefix(pkg: Any) -> None:
    await ready(pkg)
    grower, _ = await published(pkg)
    nos = [(await grant(pkg, grower, f"UTR{i:010d}")).json()["receipt_no"] for i in range(3)]
    assert nos == ["BM/26-27/00001", "BM/26-27/00002", "BM/26-27/00003"]
    first = (await pkg.get(f"{PKG}/grants", headers=ADMIN)).json()["grants"][-1]
    await pkg.post(f"{PKG}/grants/{first['id']}/revoke", json={"reason": "x" * 3}, headers=ADMIN)
    await pkg.put(f"{PKG}/company-profile", json={"invoice_prefix": "BM/27-28/"}, headers=ADMIN)
    assert (await grant(pkg, grower, "UTR9")).json()["receipt_no"] == "BM/27-28/00001"
    await pkg.put(f"{PKG}/company-profile", json={"invoice_prefix": "BM/26-27/"}, headers=ADMIN)
    assert (await grant(pkg, grower, "UTR10")).json()["receipt_no"] == "BM/26-27/00004"


async def test_grant_lot_must_be_the_growers(pkg: Any) -> None:
    await ready(pkg)
    grower, _ = await published(pkg)
    _, other_lot = await published(pkg)
    r = await grant(pkg, grower, "UTR123412341234", other_lot)
    assert r.status_code == 404
    assert (await grant(pkg, uuid.uuid4(), "UTR5555")).status_code == 404


async def test_find_grower_by_phone(pkg: Any) -> None:
    grower, lot_id = await published(pkg)
    for phone in ("9812345678", "+91 98123 45678"):
        r = await pkg.get(f"{PKG}/growers", params={"phone": phone}, headers=ADMIN)
        [g] = r.json()["growers"]
        assert (g["id"], g["name"]) == (str(grower), "Ramesh Patil")
        assert [x["id"] for x in g["lots"]] == [str(lot_id)]
    r = await pkg.get(f"{PKG}/growers", params={"phone": "98123-4567x"}, headers=ADMIN)
    assert r.status_code == 422


async def test_validity_starts_at_the_season_start(pkg: Any) -> None:
    await ready(pkg, starts_at="2026-12-01")
    grower, _ = await published(pkg)
    g = (await grant(pkg, grower, "UTR777788889999")).json()
    assert g["activated_at"].startswith("2026-11-30T18:30")  # 1 Dec 00:00 in India
    start = datetime.fromisoformat(g["activated_at"])
    assert datetime.fromisoformat(g["valid_until"]) - start == timedelta(days=45)


async def test_merchant_qr_upload(pkg: Any) -> None:
    url = f"{PKG}/company-profile/merchant-qr"
    assert (await pkg.get(url, headers=ADMIN)).status_code == 404
    png = b"\x89PNG\r\n\x1a\n" + b"0" * 100
    bad = await pkg.put(url, content=png, headers={**ADMIN, "Content-Type": "text/plain"})
    assert bad.status_code == 415
    r = await pkg.put(url, content=png, headers={**ADMIN, "Content-Type": "image/png"})
    assert r.json()["merchant_qr"] is True
    got = await pkg.get(url, headers=ADMIN)
    assert (got.content, got.headers["content-type"]) == (png, "image/png")


async def test_gst_rate_is_entered_in_percent_and_can_be_cleared(pkg: Any) -> None:
    url = f"{PKG}/company-profile"
    r = await pkg.put(url, json={"gst_rate_percent": "18"}, headers=ADMIN)
    assert r.json()["gst_rate_percent"] == "18"
    r = await pkg.put(url, json={"gst_rate_percent": "2.5"}, headers=ADMIN)
    assert r.json()["gst_rate_percent"] == "2.5"
    assert (await pkg.put(url, json={"gst_rate_percent": "abc"}, headers=ADMIN)).status_code == 422
    r = await pkg.put(url, json={"gst_rate_percent": ""}, headers=ADMIN)
    assert r.json()["gst_rate_percent"] is None
