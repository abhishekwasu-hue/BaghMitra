"""Market linkage L2 intake (spec v1.5 §4, §4B; addenda 1, 3): EXIF strip before storage,
the registration GPS fix (freshness, flags), FSSAI / APEDA numbers (0031), and the admin
queue showing the fix with exact coordinates and its flags before any badge."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.errors import ApiError
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    PartyVerification,
    RegistrationFix,
    RepresentativeUpload,
)
from bagmitra_api.market_link.photos import NotAJpegError, strip_jpeg_metadata
from bagmitra_api.market_link.registration import (
    RegistrationFixIn,
    check_fresh,
    distance_km,
    fix_flags,
    india_date,
)
from bagmitra_api.photos.storage import PhotoStorageError, SupabaseStorageClient
from tests.conftest import make_token

NOW = datetime(2026, 11, 7, 6, 0, tzinfo=UTC)
WARUD = (21.4717, 78.2667)
AMRAVATI = (20.9374, 77.7796)
_TOKEN = make_token(uuid.uuid4(), app_metadata={"roles": ["market_link_admin"]})
ADMIN = {"Authorization": f"Bearer {_TOKEN}"}


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


def test_strip_jpeg_metadata_keeps_the_image_and_refuses_junk() -> None:
    clean = strip_jpeg_metadata(JPEG)
    assert clean.startswith(b"\xff\xd8\xff\xe0")
    assert clean.endswith(b"\x12\x34\x56\xff\xd9")
    assert EXIF not in clean
    assert b"GPS" not in clean
    assert b"hi!!" not in clean
    assert strip_jpeg_metadata(clean) == clean
    # A restart marker is kept; a fill byte before a marker is dropped.
    head = b"\xff\xd8\xff\xd0" + _segment(0xDB, b"\x00")
    assert strip_jpeg_metadata(head + b"\xff\xff\xd9") == head + b"\xff\xd9"
    for junk in (b"", b"GIF89a", b"\xff\xd8\xff\xe1\x00\xff", b"\xff\xd8\x00\x00", b"\xff\xd8"):
        with pytest.raises(NotAJpegError):
            strip_jpeg_metadata(junk)
    for truncated in (b"\xff\xd8\xff", b"\xff\xd8\xff\xdb\x00"):
        with pytest.raises(NotAJpegError):
            strip_jpeg_metadata(truncated)


async def test_put_object_stores_with_the_service_key_and_reports_errors() -> None:
    seen: list[httpx.Request] = []

    def answer(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200 if request.url.path.endswith("ok.jpg") else 500, json={})

    async with httpx.AsyncClient(transport=httpx.MockTransport(answer)) as http:
        client = SupabaseStorageClient(
            http, base_url="https://sb.test/", bucket="photos", service_key="svc"
        )
        await client.put_object("market-link/ok.jpg", b"jpeg", "image/jpeg")
        with pytest.raises(PhotoStorageError):
            await client.put_object("market-link/bad.jpg", b"jpeg", "image/jpeg")
    assert seen[0].url.path == "/storage/v1/object/photos/market-link/ok.jpg"
    assert seen[0].headers["x-upsert"] == "true"
    assert seen[0].headers["content-type"] == "image/jpeg"
    assert seen[0].content == b"jpeg"


def _fix(**over: Any) -> dict[str, Any]:
    return {
        "lat": WARUD[0],
        "lon": WARUD[1],
        "accuracy_m": 12.5,
        "captured_at": (NOW - timedelta(minutes=2)).isoformat(),
        "place": "Warud",
        "district": "Amravati",
        "pin": "444906",
        **over,
    }


def test_the_fix_must_be_taken_now() -> None:
    check_fresh(RegistrationFixIn(**_fix()), NOW)
    for when in (NOW - timedelta(hours=2), NOW + timedelta(hours=1)):
        with pytest.raises(ApiError) as caught:
            check_fresh(RegistrationFixIn(**_fix(captured_at=when.isoformat())), NOW)
        assert caught.value.code == "registration_fix_stale"


@pytest.mark.parametrize("key", ["aadhaar_no", "uid", "commission", "income"])
def test_the_fix_refuses_aadhaar_and_commission_keys(key: str) -> None:
    with pytest.raises(ValidationError):
        RegistrationFixIn(**_fix(**{key: "x"}))
    with pytest.raises(ValidationError):
        RegistrationFixIn(**_fix(pin="44490"))


@pytest.mark.parametrize(
    ("over", "stated", "flags"),
    [
        ({}, "Amravati", []),
        ({"is_mocked": True}, "Amravati", ["mock_location"]),
        ({"district": "Nagpur"}, "Amravati", ["outside_stated_district"]),
        ({"district": None}, "Amravati", ["place_not_named"]),
        ({"district": "Amravati District"}, "amravati", []),
        ({"district": "अमरावती जिल्हा"}, "अमरावती", []),
    ],
)
def test_fix_flags(over: dict[str, Any], stated: str, flags: list[str]) -> None:
    fix = RegistrationFix(**{**_fix(), "captured_at": NOW, "is_mocked": False, **over})
    assert fix_flags(fix, stated) == flags
    assert fix_flags(None, stated) == []


def test_distance_and_india_date() -> None:
    assert distance_km(*WARUD, *WARUD) == 0
    assert 70 < distance_km(*WARUD, *AMRAVATI) < 80
    assert str(india_date(datetime(2026, 11, 6, 20, 0))) == "2026-11-07"


@pytest.fixture
async def api(settings: Settings, engine: AsyncEngine) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings.model_copy(update={"market_link_enabled": True}))
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c


async def _seed(engine: AsyncEngine) -> tuple[uuid.UUID, uuid.UUID]:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    session: AsyncSession
    async with maker() as session:
        broker = BrokerProfile(
            user_id=uuid.uuid4(), name="Suresh", phone="+919800000002", district="Amravati"
        )
        buyer = BuyerProfile(
            user_id=uuid.uuid4(),
            name="Ramesh",
            phone="+919800000001",
            district="Amravati",
            fssai_no="12345678901234",
            apeda_no="RCMC/1",
        )
        session.add_all([broker, buyer])
        await session.flush()
        for kind, subject in (("broker", broker), ("buyer", buyer)):
            session.add(
                PartyVerification(subject_type=kind, subject_id=subject.id, status="pending")
            )
        session.add(
            RegistrationFix(
                **{**_fix(district="Nagpur"), "captured_at": NOW},
                subject_type="broker",
                subject_id=broker.id,
                user_id=broker.user_id,
                is_mocked=True,
            )
        )
        session.add(
            RepresentativeUpload(
                subject_type="broker",
                subject_id=broker.id,
                uploaded_by=uuid.uuid4(),
                photo_key="market-link/broker/place.jpg",
                captured_at=NOW,
                lat=WARUD[0],
                lon=WARUD[1],
            )
        )
        await session.commit()
        return broker.id, buyer.id


async def test_admin_queue_shows_the_fix_flags_numbers_and_place_photo(
    api: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    broker_id, buyer_id = await _seed(engine)
    queue = (await api.get("/v1/admin/market-link/verifications", headers=ADMIN)).json()
    by_id = {s["subject_id"]: s for s in queue["subjects"]}
    broker = by_id[str(broker_id)]
    assert broker["flags"] == ["mock_location", "outside_stated_district"]
    assert broker["registration_fix"]["lat"] == WARUD[0]
    assert broker["registration_fix"]["is_mocked"] is True
    assert broker["document_keys"] == ["market-link/broker/place.jpg"]
    buyer = by_id[str(buyer_id)]
    assert (buyer["registration_fix"], buyer["flags"]) == (None, [])
    assert buyer["fields"]["fssai_no"] == "12345678901234"
    assert buyer["fields"]["apeda_no"] == "RCMC/1"
    detail = await api.get(f"/v1/admin/market-link/verifications/broker/{broker_id}", headers=ADMIN)
    assert detail.json()["subject"]["flags"] == ["mock_location", "outside_stated_district"]
