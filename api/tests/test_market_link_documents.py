"""Market linkage L2: document and place photos (spec v1.5 §4, §4B; addendum 2). Owner-only
documents behind the role's terms, representative-only place photos behind the representative
terms; every photo EXIF-stripped before storage; a document after a decision re-queues."""

from __future__ import annotations

import uuid

import httpx
from sqlalchemy import select

from bagmitra_api.core.settings import Settings
from bagmitra_api.market_link.models import PartyVerification, RepresentativeUpload
from bagmitra_api.market_link.photos import strip_jpeg_metadata
from tests.test_market_link_registration import (
    ADMIN,
    ADMIN_BASE,
    BASE,
    EXIF,
    JPEG,
    JPEG_TYPE,
    ME,
    NOW,
    REP,
    REP_ID,
    WARUD,
    FakeStorage,
    Maker,
    accept,
    api,
    approve,
    headers,
    make_app,
    maker,
    register,
    storage,
)

__all__ = ["api", "maker", "storage"]  # fixtures used below


async def test_flag_off_photo_and_profile_endpoints_are_404(
    settings: Settings, maker: Maker, storage: FakeStorage
) -> None:
    transport = httpx.ASGITransport(app=make_app(settings, maker, storage, on=False))
    sid = uuid.uuid4()
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        for method, path in [
            ("GET", f"{BASE}/profiles"),
            ("GET", f"{BASE}/profiles/buyer/{sid}"),
            ("GET", f"{BASE}/providers"),
            ("POST", f"{BASE}/profiles/buyer/{sid}/documents"),
            ("POST", f"{BASE}/profiles/buyer/{sid}/place-photo"),
        ]:
            for hdrs in (ADMIN, REP, ME, {}):
                assert (await c.request(method, path, headers=hdrs)).status_code == 404


async def test_only_a_representative_adds_a_place_photo(
    api: httpx.AsyncClient, maker: Maker, storage: FakeStorage
) -> None:
    out = await register(api, "buyer")
    url = f"{BASE}/profiles/buyer/{out['id']}/place-photo"
    params: dict[str, str | float] = {
        "captured_at": NOW.isoformat(),
        "lat": WARUD[0],
        "lon": WARUD[1],
    }
    for hdrs in (ME, ADMIN):
        response = await api.post(url, params=params, content=JPEG, headers=hdrs | JPEG_TYPE)
        assert response.status_code == 403
    response = await api.post(url, params=params, content=JPEG, headers=REP | JPEG_TYPE)
    assert response.json()["error"]["code"] == "terms_not_accepted"
    await accept(api, REP, "representative")
    response = await api.post(url, params=params, content=JPEG, headers=REP | JPEG_TYPE)
    assert response.status_code == 201, response.text
    async with maker() as s:
        photo = await s.scalar(select(RepresentativeUpload))
        assert photo is not None
        assert photo.uploaded_by == REP_ID
        assert photo.photo_key in storage.objects
    (stored,) = storage.objects.values()
    assert stored == strip_jpeg_metadata(JPEG)
    assert b"Exif" not in stored
    assert b"GPS" not in stored
    detail = await api.get(f"{ADMIN_BASE}/verifications/buyer/{out['id']}", headers=ADMIN)
    assert photo.photo_key in detail.json()["subject"]["document_keys"]
    mine = (await api.get(f"{BASE}/me/profiles", headers=ME)).json()["profiles"]
    assert {"kind": "place_photo", "on": "2026-11-07", "place": None, "since_year": None} in mine[
        0
    ]["badges"]


# --- document photos and the weighbridge certificate -----------------------------------------


async def test_document_photos_are_stripped_and_listed_for_the_admin(
    api: httpx.AsyncClient, storage: FakeStorage, maker: Maker
) -> None:
    out = await register(api, "buyer")
    url = f"{BASE}/profiles/buyer/{out['id']}/documents"
    response = await api.post(
        url, params={"doc": "gst"}, content=JPEG, headers=headers() | JPEG_TYPE
    )
    assert response.status_code == 403
    response = await api.post(url, params={"doc": "gst"}, content=b"junk", headers=ME | JPEG_TYPE)
    assert response.status_code == 422
    for doc in ("certificate", "aadhaar"):
        response = await api.post(url, params={"doc": doc}, content=JPEG, headers=ME | JPEG_TYPE)
        assert response.status_code == 422, doc
    response = await api.post(url, params={"doc": "gst"}, content=JPEG, headers=ME | JPEG_TYPE)
    assert response.status_code == 200, response.text
    assert response.json()["documents"] == 1
    ((key, stored),) = storage.objects.items()
    assert EXIF not in stored
    assert "/gst-" in key
    detail = await api.get(f"{ADMIN_BASE}/verifications/buyer/{out['id']}", headers=ADMIN)
    assert detail.json()["subject"]["document_keys"] == [key]
    # After a decision, a new document puts the profile back in the queue (Q81).
    await approve(api, "buyer", out["id"])
    await api.post(url, params={"doc": "iec"}, content=JPEG, headers=ME | JPEG_TYPE)
    async with maker() as s:
        rows = list(
            await s.scalars(select(PartyVerification).order_by(PartyVerification.created_at))
        )
    assert [r.status for r in rows] == ["pending", "approved", "pending"]
    assert len(rows[-1].document_keys) == 2


async def test_broker_has_no_documents(api: httpx.AsyncClient) -> None:
    out = await register(api, "broker")
    response = await api.post(
        f"{BASE}/profiles/broker/{out['id']}/documents",
        params={"doc": "gst"},
        content=JPEG,
        headers=ME | JPEG_TYPE,
    )
    assert response.status_code == 422


async def test_weighbridge_certificate_and_expiry(
    api: httpx.AsyncClient, storage: FakeStorage
) -> None:
    out = await register(api, "provider")
    assert out["provider"]["certificate_expired"] is False
    assert out["has_certificate_photo"] is False
    url = f"{BASE}/profiles/provider/{out['id']}/documents"
    response = await api.post(
        url, params={"doc": "certificate"}, content=JPEG, headers=ME | JPEG_TYPE
    )
    assert response.json()["error"]["code"] == "valid_until_required"
    params = {"doc": "certificate", "valid_until": "2026-11-06"}
    response = await api.post(url, params=params, content=JPEG, headers=ME | JPEG_TYPE)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["provider"]["certificate_expired"] is True
    assert body["has_certificate_photo"] is True
    (stored,) = storage.objects.values()
    assert EXIF not in stored
    gang = await register(api, "provider", kind="labour_gang")
    response = await api.post(
        f"{BASE}/profiles/provider/{gang['id']}/documents",
        params=params,
        content=JPEG,
        headers=ME | JPEG_TYPE,
    )
    assert response.status_code == 422
