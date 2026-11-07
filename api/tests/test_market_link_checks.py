"""Market linkage L7 (spec v1.5 §4, §4C): per-check records and badges, the verified rule,
duplicate numbers, returning suspended users, the yearly re-check job, and the same-phone /
pair-only helpers for the rating flow."""

from __future__ import annotations

import re
import uuid
from typing import Any

import httpx

from bagmitra_api.market_link import checks as checks_module
from bagmitra_api.market_link.checks import OFFICIAL_PAGES, passed_kinds
from bagmitra_api.market_link.guards import is_verified
from bagmitra_api.market_link.models import (
    BuyerProfile,
    VerificationCheck,
)
from bagmitra_api.routers import admin_market_link_checks
from tests.test_market_link_registration import (
    ADMIN,
    ADMIN_BASE,
    ADMIN_ID,
    BASE,
    GSTIN,
    Maker,
    _reset_clock,
    api,
    headers,
    maker,
    register,
    storage,
)

__all__ = ["_reset_clock", "api", "maker", "storage"]  # fixtures used below
GUARANTEE = re.compile(r"guarant|हमी|गॅरंटी|गारंटी", re.IGNORECASE)


def _detail_url(subject_type: str, subject_id: str) -> str:
    return f"{ADMIN_BASE}/verifications/{subject_type}/{subject_id}"


async def _check(
    api: httpx.AsyncClient, subject_type: str, subject_id: str, kind: str, result: str = "passed"
) -> httpx.Response:
    body: dict[str, Any] = {"kind": kind, "result": result}
    return await api.post(
        f"{_detail_url(subject_type, subject_id)}/checks", json=body, headers=ADMIN
    )


async def _decide(api: httpx.AsyncClient, subject_type: str, subject_id: str) -> httpx.Response:
    url = f"{_detail_url(subject_type, subject_id)}/decision"
    return await api.post(url, json={"status": "approved"}, headers=ADMIN)


async def _badges(api: httpx.AsyncClient, subject_type: str, subject_id: str) -> list[str]:
    response = await api.get(f"{BASE}/profiles/{subject_type}/{subject_id}", headers=headers())
    return [b["kind"] for b in response.json()["badges"]] if response.status_code == 200 else []


# --- per-check records and official pages ------------------------------------------------------


async def test_detail_lists_official_pages_and_a_check_records_who_and_when(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    out = await register(api, "buyer", headers(), apmc_licence_no="WRD/12")
    links = (await api.get(_detail_url("buyer", out["id"]), headers=ADMIN)).json()["links"]
    by_kind = {link["kind"]: link for link in links}
    # Only the numbers the profile holds; no FSSAI / IEC / APEDA here.
    assert set(by_kind) == {"gstin", "apmc", "phone_call", "place_photo"}
    assert by_kind["gstin"] == {"kind": "gstin", "number": GSTIN, "url": OFFICIAL_PAGES["gstin"]}
    assert by_kind["phone_call"]["url"] == "tel:+919800000001"
    assert by_kind["place_photo"]["url"] is None
    body = {"kind": "gstin", "result": "passed", "registered_year": 2016}
    url = f"{_detail_url('buyer', out['id'])}/checks"
    response = await api.post(url, json=body, headers=ADMIN)
    assert response.status_code == 200, response.text
    [check] = response.json()["checks"]
    assert (check["kind"], check["number"], check["result"]) == ("gstin", GSTIN, "passed")
    assert check["official_url"] == OFFICIAL_PAGES["gstin"]
    assert check["checked_by"] == str(ADMIN_ID)
    assert check["checked_at"].startswith("2026-11-07")
    assert check["registered_year"] == 2016


async def test_a_check_needs_its_number_and_fits_the_subject(api: httpx.AsyncClient) -> None:
    trader = await register(api, "buyer", headers())
    broker = await register(api, "broker", headers())
    assert (await _check(api, "buyer", trader["id"], "iec")).json()["error"]["code"] == (
        "number_missing"
    )
    assert (await _check(api, "broker", broker["id"], "gstin")).json()["error"]["code"] == (
        "check_not_for_subject"
    )
    body = {"kind": "apmc", "result": "passed", "registered_year": 2016}
    url = f"{_detail_url('buyer', trader['id'])}/checks"
    bad_year = await api.post(url, json=body, headers=ADMIN)
    assert bad_year.json()["error"]["code"] == "number_missing"
    body = {"kind": "phone_call", "result": "passed", "registered_year": 2016}
    assert (await api.post(url, json=body, headers=ADMIN)).json()["error"]["code"] == (
        "registered_year_gst_only"
    )
    for extra in ({"turnover": 5}, {"aadhaar_no": "1"}, {"result": "guaranteed"}):
        body = {"kind": "gstin", "result": "passed", **extra}
        assert (await api.post(url, json=body, headers=ADMIN)).status_code == 422
    assert (await api.post(url, json=body, headers=headers())).status_code == 403


# --- verified rule (spec §4) ---------------------------------------------------------------------


async def test_trader_needs_one_of_gstin_apmc_iec(api: httpx.AsyncClient, maker: Maker) -> None:
    out = await register(api, "buyer", headers())
    sid = out["id"]
    assert (await _decide(api, "buyer", sid)).json()["error"]["code"] == "verified_rule_not_met"
    # FSSAI / phone call / a failed GSTIN check do not qualify a trader.
    assert (await _check(api, "buyer", sid, "phone_call")).status_code == 200
    assert (await _check(api, "buyer", sid, "gstin", "failed")).status_code == 200
    assert (await _decide(api, "buyer", sid)).status_code == 422
    assert (await _check(api, "buyer", sid, "gstin")).status_code == 200
    assert (await _decide(api, "buyer", sid)).status_code == 200
    async with maker() as s:
        assert await is_verified(s, "buyer", uuid.UUID(sid)) is True


async def test_exporter_needs_iec_and_broker_needs_the_phone_call(api: httpx.AsyncClient) -> None:
    exporter = await register(api, "exporter", headers(), iec_no="ABCDE12345")
    assert (await _check(api, "buyer", exporter["id"], "gstin")).status_code == 200
    assert (await _decide(api, "buyer", exporter["id"])).status_code == 422
    assert (await _check(api, "buyer", exporter["id"], "iec")).status_code == 200
    assert (await _decide(api, "buyer", exporter["id"])).status_code == 200
    broker = await register(api, "broker", headers())
    assert (await _decide(api, "broker", broker["id"])).status_code == 422
    assert (await _check(api, "broker", broker["id"], "place_photo")).status_code == 200
    assert (await _decide(api, "broker", broker["id"])).status_code == 422
    assert (await _check(api, "broker", broker["id"], "phone_call")).status_code == 200
    assert (await _decide(api, "broker", broker["id"])).status_code == 200
    assert "iec_active" in await _badges(api, "buyer", exporter["id"])


async def test_a_check_counts_only_for_the_current_number() -> None:
    profile = BuyerProfile(name="x", phone="+919800000001", district="d", gst_no=GSTIN)
    row = VerificationCheck(kind="gstin", number=GSTIN, result="passed")
    assert passed_kinds(profile, {"gstin": row}) == {"gstin"}
    profile.gst_no = "27ZZZZZ9999Z1Z5"
    assert passed_kinds(profile, {"gstin": row}) == set()


# --- badges --------------------------------------------------------------------------------------


async def test_badges_come_from_checks_only_after_approval(api: httpx.AsyncClient) -> None:
    out = await register(api, "buyer", headers(), apmc_licence_no="WRD/12")
    sid = out["id"]
    body = {"kind": "gstin", "result": "passed", "registered_year": 2016}
    await api.post(f"{_detail_url('buyer', sid)}/checks", json=body, headers=ADMIN)
    assert await _badges(api, "buyer", sid) == []  # not public before approval
    assert (await _check(api, "buyer", sid, "apmc")).status_code == 200
    assert (await _decide(api, "buyer", sid)).status_code == 200
    response = await api.get(f"{BASE}/profiles/buyer/{sid}", headers=headers())
    badges = {b["kind"]: b for b in response.json()["badges"]}
    assert badges["gst_checked"] == {
        "kind": "gst_checked",
        "on": "2026-11-07",
        "place": None,
        "since_year": 2016,
    }
    assert "apmc_seen" in badges
    assert not GUARANTEE.search(response.text)


async def test_cancelled_on_recheck_removes_the_badge_and_the_verified_status(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    out = await register(api, "buyer", headers(), apmc_licence_no="WRD/12")
    sid = out["id"]
    for kind in ("gstin", "apmc"):
        assert (await _check(api, "buyer", sid, kind)).status_code == 200
    assert (await _decide(api, "buyer", sid)).status_code == 200
    # GST cancelled: its badge goes; the APMC check still meets the rule.
    assert (await _check(api, "buyer", sid, "gstin", "cancelled")).status_code == 200
    badges = await _badges(api, "buyer", sid)
    assert "gst_checked" not in badges
    assert "apmc_seen" in badges
    async with maker() as s:
        assert await is_verified(s, "buyer", uuid.UUID(sid)) is True
    # Licence also no longer valid: the rule fails, the profile is back in the queue.
    response = await _check(api, "buyer", sid, "apmc", "cancelled")
    assert response.json()["subject"]["status"] == "pending"
    assert response.json()["history"][0]["reason"] == "Re-check: apmc cancelled / deactivated"
    async with maker() as s:
        assert await is_verified(s, "buyer", uuid.UUID(sid)) is False
    queue = (await api.get(f"{ADMIN_BASE}/verifications", headers=ADMIN)).json()["subjects"]
    assert sid in [q["subject_id"] for q in queue]
    assert await _badges(api, "buyer", sid) == []


def test_no_check_text_says_guarantee() -> None:
    texts = [
        *admin_market_link_checks.RESULT_WORDS.values(),
        *checks_module.CHECK_BADGES.values(),
        *OFFICIAL_PAGES.values(),
    ]
    assert not [t for t in texts if GUARANTEE.search(t)]
