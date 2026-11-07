"""Market linkage L2: trader / exporter / broker / provider registration (spec v1.5 §2, §4,
§4C; addenda 1-3; decisions c, h, j). Terms accepted first; the GPS fix is required; a mock or
other-district fix is flagged in the admin queue; an exporter needs an IEC; no Aadhaar /
commission keys; address only by the owner or a representative."""

from __future__ import annotations

import json
import re
import uuid
from collections.abc import AsyncIterator, Callable
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.base import Base
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import (
    MARKET_LINK_TABLES,
    BrokerProfile,
    BuyerProfile,
    RegistrationFix,
    RepresentativeUpload,
    ServiceProvider,
)
from bagmitra_api.routers.scouting_photos import get_photo_storage
from bagmitra_api.weather.service import get_clock
from tests.conftest import make_token

Maker = async_sessionmaker[AsyncSession]
NOW = datetime(2026, 11, 7, 6, 0, tzinfo=UTC)
BASE = "/v1/market-link"
ADMIN_BASE = "/v1/admin/market-link"
USER = uuid.uuid4()
ADMIN_ID = uuid.uuid4()
REP_ID = uuid.uuid4()
WARUD = (21.4717, 78.2667)
AMRAVATI = (20.9374, 77.7796)
GSTIN = "27ABCDE1234F1Z5"


def headers(user: uuid.UUID | None = None, *roles: str) -> dict[str, str]:
    token = make_token(user or uuid.uuid4(), app_metadata={"roles": list(roles)})
    return {"Authorization": f"Bearer {token}"}


ME = headers(USER)
ADMIN = headers(ADMIN_ID, "market_link_admin")
REP = headers(REP_ID, "market_link_rep")
JPEG_TYPE = {"Content-Type": "image/jpeg"}


def _segment(marker: int, payload: bytes) -> bytes:
    return bytes([0xFF, marker]) + (len(payload) + 2).to_bytes(2, "big") + payload


# A JPEG with an EXIF (APP1) GPS segment and a comment before the image data.
EXIF = _segment(0xE1, b"Exif\x00\x00GPS-21.47")
JPEG = (
    b"\xff\xd8"
    + _segment(0xE0, b"JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00")
    + EXIF
    + _segment(0xFE, b"hi!!")
    + _segment(0xDB, b"\x00\x01")
    + _segment(0xDA, b"\x00\x00")
    + b"\x12\x34\x56\xff\xd9"
)


class Ticks:
    """A clock one second further on each call, so the latest record is unambiguous."""

    def __init__(self) -> None:
        self.now = NOW

    def __call__(self) -> datetime:
        self.now += timedelta(seconds=1)
        return self.now


ticks = Ticks()


@pytest.fixture(autouse=True)
def _reset_clock() -> None:
    ticks.now = NOW


class FakeStorage:
    def __init__(self) -> None:
        self.objects: dict[str, bytes] = {}

    async def put_object(self, key: str, data: bytes, content_type: str) -> None:
        assert content_type == "image/jpeg"
        self.objects[key] = data


def fix(**over: Any) -> dict[str, Any]:
    return {
        "lat": WARUD[0],
        "lon": WARUD[1],
        "accuracy_m": 12.5,
        "captured_at": (NOW - timedelta(minutes=2)).isoformat(),
        "place": "Warud",
        "district": "Amravati",
        "state": "Maharashtra",
        "pin": "444906",
        "is_mocked": False,
        **over,
    }


def provider_body(kind: str = "weighbridge", **over: Any) -> dict[str, Any]:
    body: dict[str, Any] = {
        "kind": kind,
        "name": "Warud Kata",
        "phone": "+919800000003",
        "village": "Warud",
        "taluka": "Warud",
        "district": "Amravati",
        "fix": fix(),
    }
    if kind == "weighbridge":
        body["cert_valid_until"] = "2027-03-31"
    if kind == "transporter":
        body |= {"vehicle_numbers": ["MH27AB1234"], "capacity_t": 9, "refrigerated": False}
    if kind in ("labour_gang", "crate_supplier"):
        body["service_areas"] = ["Warud", "Morshi"]
    return body | over


def buyer_body(**over: Any) -> dict[str, Any]:
    return {
        "name": "Ramesh Patil",
        "firm": "Patil Fruits",
        "phone": "+919800000001",
        "markets": ["Warud APMC"],
        "taluka": "Warud",
        "district": "Amravati",
        "crops": ["santra"],
        "gst_no": GSTIN.lower(),
        "fix": fix(),
    } | over


def broker_body(**over: Any) -> dict[str, Any]:
    return {
        "name": "Suresh Wankhade",
        "phone": "+919800000002",
        "village": "Shendurjana Ghat",
        "taluka": "Warud",
        "district": "Amravati",
        "service_areas": ["Warud", "Morshi"],
        "crops": ["santra", "mosambi"],
        "fix": fix(),
    } | over


@pytest.fixture
def storage() -> FakeStorage:
    return FakeStorage()


@pytest.fixture
def maker(engine: AsyncEngine) -> Maker:
    return async_sessionmaker(engine, expire_on_commit=False)


def make_app(settings: Settings, maker: Maker, storage: FakeStorage, on: bool = True) -> FastAPI:
    app = create_app(settings.model_copy(update={"market_link_enabled": on}))
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_clock] = lambda: ticks
    app.dependency_overrides[get_photo_storage] = lambda: storage
    return app


@pytest.fixture
async def api(
    settings: Settings, maker: Maker, storage: FakeStorage
) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=make_app(settings, maker, storage))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


PATHS = {"buyer": "traders", "exporter": "exporters", "broker": "brokers", "provider": "providers"}
ROLES = {"buyer": "trader", "exporter": "exporter", "broker": "broker", "provider": "provider"}
V1 = {"terms_version": "1", "privacy_version": "1", "disclaimer_version": "1"}


async def accept(api: httpx.AsyncClient, hdrs: dict[str, str], role: str) -> None:
    """The role's terms, privacy notice and disclaimer with 18+ (L1, spec §4C)."""
    body = {"role": role, "adult_declared": True, **V1}
    response = await api.post(f"{BASE}/terms/accept", json=body, headers=hdrs)
    assert response.status_code == 200, response.text


BODIES: dict[str, Callable[..., dict[str, Any]]] = {
    "buyer": buyer_body,
    "broker": broker_body,
    "provider": provider_body,
}


async def register(
    api: httpx.AsyncClient, what: str = "provider", hdrs: dict[str, str] = ME, **over: Any
) -> Any:
    body = (buyer_body if what == "exporter" else BODIES[what])(**over)
    await accept(api, hdrs, ROLES[what])
    response = await api.post(f"{BASE}/{PATHS[what]}", json=body, headers=hdrs)
    assert response.status_code == 201, response.text
    return response.json()


async def approve(api: httpx.AsyncClient, subject_type: str, subject_id: str) -> None:
    url = f"{ADMIN_BASE}/verifications/{subject_type}/{subject_id}/decision"
    response = await api.post(url, json={"status": "approved"}, headers=ADMIN)
    assert response.status_code == 200, response.text


# --- legal gate ------------------------------------------------------------------------------


async def test_flag_off_every_l2_endpoint_is_404(
    settings: Settings, maker: Maker, storage: FakeStorage
) -> None:
    transport = httpx.ASGITransport(app=make_app(settings, maker, storage, on=False))
    sid = uuid.uuid4()
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        for method, path in [
            *(("POST", f"{BASE}/{p}") for p in PATHS.values()),
            ("GET", f"{BASE}/me/profiles"),
            ("PUT", f"{BASE}/profiles/buyer/{sid}/address"),
            ("POST", f"{ADMIN_BASE}/providers"),
        ]:
            for hdrs in (ADMIN, REP, ME, {}):
                response = await c.request(method, path, headers=hdrs)
                assert response.status_code == 404, (method, path)


# --- registration and the GPS fix (addendum 3) -----------------------------------------------


@pytest.mark.parametrize("what", ["buyer", "exporter", "broker", "provider"])
async def test_registration_is_blocked_without_a_gps_fix(api: httpx.AsyncClient, what: str) -> None:
    await accept(api, ME, ROLES[what])
    body = (buyer_body if what == "exporter" else BODIES[what])(iec_no="AB12345678")
    if what in ("broker", "provider"):
        body.pop("iec_no")
    for value in (None, ...):
        if value is ...:
            body.pop("fix")
        else:
            body["fix"] = value
        response = await api.post(f"{BASE}/{PATHS[what]}", json=body, headers=ME)
        assert response.status_code == 422, (what, response.text)


async def test_registration_needs_the_role_terms_first(api: httpx.AsyncClient) -> None:
    for what in ("buyer", "exporter", "broker", "provider"):
        body = (buyer_body if what == "exporter" else BODIES[what])()
        response = await api.post(f"{BASE}/{PATHS[what]}", json=body, headers=ME)
        assert response.status_code == 403, what
        assert response.json()["error"]["code"] == "terms_not_accepted"
    # Terms of another role do not count.
    await accept(api, ME, "broker")
    response = await api.post(f"{BASE}/traders", json=buyer_body(), headers=ME)
    assert response.status_code == 403


async def test_registration_refuses_an_old_or_future_fix(api: httpx.AsyncClient) -> None:
    await accept(api, ME, "broker")
    for when in (NOW - timedelta(hours=2), NOW + timedelta(hours=1)):
        body = broker_body(fix=fix(captured_at=when.isoformat()))
        response = await api.post(f"{BASE}/brokers", json=body, headers=ME)
        assert response.status_code == 422
        assert response.json()["error"]["code"] == "registration_fix_stale"


async def test_trader_registration_stores_fix_numbers_and_enters_the_queue(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    out = await register(api, "buyer", fssai_no="12345678901234", apmc_licence_no=" wrd/12 ")
    assert out["status"] == "pending"
    assert out["kind"] == "trader"
    assert out["flags"] == []
    assert out["numbers"]["gst_no"] == GSTIN
    assert out["numbers"]["apmc_licence_no"] == "WRD/12"
    assert [b["kind"] for b in out["badges"]] == ["registered_from"]
    assert out["badges"][0] == {
        "kind": "registered_from",
        "on": "2026-11-07",
        "place": "Warud, Amravati",
    }
    async with maker() as s:
        row = await s.scalar(select(RegistrationFix))
        assert row is not None
        assert (row.subject_type, row.user_id, row.pin, row.is_mocked) == (
            "buyer",
            USER,
            "444906",
            False,
        )
        profile = await s.get(BuyerProfile, uuid.UUID(out["id"]))
        assert profile is not None
        assert (profile.fssai_no, profile.user_id) == ("12345678901234", USER)
    queue = (await api.get(f"{ADMIN_BASE}/verifications", headers=ADMIN)).json()["subjects"]
    assert [s["subject_id"] for s in queue] == [out["id"]]
    assert queue[0]["registration_fix"]["lat"] == WARUD[0]
    assert queue[0]["fields"]["fssai_no"] == "12345678901234"


async def test_exporter_needs_an_iec(api: httpx.AsyncClient) -> None:
    await accept(api, ME, "exporter")
    response = await api.post(f"{BASE}/exporters", json=buyer_body(), headers=ME)
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "exporter_needs_iec"
    out = await register(api, "exporter", iec_no="ab12345678", gst_no=None)
    assert (out["kind"], out["numbers"]["iec_no"]) == ("exporter", "AB12345678")


async def test_trader_needs_one_checkable_number(api: httpx.AsyncClient) -> None:
    await accept(api, ME, "trader")
    body = buyer_body(gst_no=None, fssai_no="12345678901234")
    response = await api.post(f"{BASE}/traders", json=body, headers=ME)
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "trader_needs_a_number"
    for bad in ({"gst_no": "27ABC"}, {"iec_no": "12"}, {"fssai_no": "abc"}):
        response = await api.post(f"{BASE}/traders", json=buyer_body(**bad), headers=ME)
        assert response.status_code == 422, bad


async def test_one_account_holds_several_roles_once_each(api: httpx.AsyncClient) -> None:
    await register(api, "buyer")
    await register(api, "broker")
    await register(api, "provider")
    await register(api, "provider", kind="transporter")
    for what in ("buyer", "exporter", "broker", "provider"):
        await accept(api, ME, ROLES[what])
        body = (buyer_body if what == "exporter" else BODIES[what])(iec_no="AB12345678")
        if what in ("broker", "provider"):
            body.pop("iec_no")
        response = await api.post(f"{BASE}/{PATHS[what]}", json=body, headers=ME)
        assert response.status_code == 409, what
    mine = (await api.get(f"{BASE}/me/profiles", headers=ME)).json()["profiles"]
    assert sorted(p["kind"] for p in mine) == ["broker", "trader", "transporter", "weighbridge"]


@pytest.mark.parametrize(
    ("over", "flags"),
    [
        ({"is_mocked": True}, ["mock_location"]),
        ({"district": "Nagpur"}, ["outside_stated_district"]),
        ({"district": None}, ["place_not_named"]),
        ({"is_mocked": True, "district": "Nagpur"}, ["mock_location", "outside_stated_district"]),
        ({"district": "amravati district"}, []),
    ],
)
async def test_mock_or_far_fix_lands_flagged_in_the_admin_queue(
    api: httpx.AsyncClient, over: dict[str, Any], flags: list[str]
) -> None:
    out = await register(api, "broker", fix=fix(**over))
    assert out["flags"] == flags
    queue = (await api.get(f"{ADMIN_BASE}/verifications", headers=ADMIN)).json()["subjects"]
    (entry,) = [s for s in queue if s["subject_id"] == out["id"]]
    assert (entry["flags"], entry["status"]) == (flags, "pending")


@pytest.mark.parametrize(
    ("kind", "over"),
    [
        ("weighbridge", {"cert_valid_until": None}),
        ("transporter", {"vehicle_numbers": []}),
        ("transporter", {"refrigerated": None}),
        ("labour_gang", {"service_areas": []}),
        ("labour_gang", {"cert_valid_until": "2027-01-01"}),
        ("crate_supplier", {"capacity_t": 4}),
        ("weighbridge", {"phone": "12345"}),
        ("weighbridge", {"rate_per_tonne": 100}),
    ],
)
async def test_provider_fields_per_kind(
    api: httpx.AsyncClient, kind: str, over: dict[str, Any]
) -> None:
    await accept(api, ME, "provider")
    body = provider_body(kind, **over)
    assert (await api.post(f"{BASE}/providers", json=body, headers=ME)).status_code == 422


@pytest.mark.parametrize(
    "key", ["commission", "brokerage_pct", "income", "dalali", "aadhaar_no", "uid", "aadhaar_photo"]
)
@pytest.mark.parametrize("what", ["buyer", "broker", "provider"])
async def test_commission_and_aadhaar_keys_are_rejected(
    api: httpx.AsyncClient, key: str, what: str
) -> None:
    await accept(api, ME, ROLES[what])
    for body in (BODIES[what](**{key: "x"}), BODIES[what](fix=fix(**{key: "x"}))):
        response = await api.post(f"{BASE}/{PATHS[what]}", json=body, headers=ME)
        assert response.status_code == 422, key
    response = await api.put(
        f"{BASE}/profiles/buyer/{uuid.uuid4()}/address", json={key: 1}, headers=ME
    )
    assert response.status_code == 422


def test_no_aadhaar_or_uid_column_in_any_market_link_table() -> None:
    pattern = re.compile(r"aadhaar|uid", re.IGNORECASE)
    for name in MARKET_LINK_TABLES:
        bad = [c.name for c in Base.metadata.tables[name].columns if pattern.search(c.name)]
        assert bad == [], f"{name}: {bad}"


def _keys(node: Any) -> set[str]:
    if isinstance(node, dict):
        return set(node) | {k for v in node.values() for k in _keys(v)}
    if isinstance(node, list):
        return {k for v in node for k in _keys(v)}
    return set()


async def test_no_aadhaar_or_commission_in_the_l2_api_schemas(api: httpx.AsyncClient) -> None:
    schemas = (await api.get("/openapi.json")).json()["components"]["schemas"]
    names = {n for n in schemas if re.search(r"Profile|Provider|Fix|Buyer|Broker|Badge", n)}
    assert {"BuyerIn", "BrokerIn", "ProviderIn", "MyProfileOut", "RegistrationFixIn"} <= names
    for name in names:
        props = _keys(schemas[name].get("properties", {}))
        assert not [p for p in props if re.search(r"aadhaar|uid|commission|income", p, re.I)]


# --- address and representative photos (addendum 2) ------------------------------------------


async def test_profile_saves_without_an_address(api: httpx.AsyncClient) -> None:
    for what in ("buyer", "broker", "provider"):
        assert (await register(api, what))["address"] is None


async def test_address_only_by_owner_or_representative(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    out = await register(api, "broker")
    url = f"{BASE}/profiles/broker/{out['id']}/address"
    for hdrs in (headers(), ADMIN, headers(None, "market_link_admin", "kb_admin")):
        response = await api.put(url, json={"address": "Main road"}, headers=hdrs)
        assert response.status_code == 403
    response = await api.put(url, json={"address": " Near APMC gate "}, headers=ME)
    assert (response.status_code, response.json()["address"]) == (200, "Near APMC gate")
    response = await api.put(url, json={"address": "Shop 4, Warud"}, headers=REP)
    assert response.json()["error"]["code"] == "terms_not_accepted"
    await accept(api, REP, "representative")
    response = await api.put(url, json={"address": "Shop 4, Warud"}, headers=REP)
    assert response.status_code == 200
    async with maker() as s:
        profile = await s.get(BrokerProfile, uuid.UUID(out["id"]))
        assert profile is not None
        assert (profile.address, profile.address_set_by) == ("Shop 4, Warud", REP_ID)
        upload = await s.scalar(select(RepresentativeUpload))
        assert upload is not None
        assert (upload.uploaded_by, upload.address, upload.photo_key) == (
            REP_ID,
            "Shop 4, Warud",
            None,
        )
    assert (await api.put(url, json={"address": None}, headers=ME)).json()["address"] is None


async def test_admin_adds_a_provider_without_a_fix(api: httpx.AsyncClient, maker: Maker) -> None:
    body = provider_body("crate_supplier")
    del body["fix"]
    assert (await api.post(f"{ADMIN_BASE}/providers", json=body, headers=ME)).status_code == 403
    response = await api.post(f"{ADMIN_BASE}/providers", json=body, headers=ADMIN)
    assert response.status_code == 201, response.text
    out = response.json()
    assert (out["status"], out["fix"], out["badges"]) == ("pending", None, [])
    async with maker() as s:
        provider = await s.get(ServiceProvider, uuid.UUID(out["id"]))
        assert provider is not None
        assert (provider.user_id, provider.added_by) == (None, ADMIN_ID)
    queue = (await api.get(f"{ADMIN_BASE}/verifications", headers=ADMIN)).json()["subjects"]
    assert out["id"] in [s["subject_id"] for s in queue]
    assert "guarantee" not in json.dumps(out).lower()
