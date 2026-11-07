"""Market linkage L3, part 1: grower lots through the offline sync (spec v1.5 §3 step 1,
§4B lot text, §4C terms before any grower write; decisions c, j)."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from typing import Any

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.guards import has_contact_details
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.conftest import make_token
from tests.test_accounts_sync import mutation
from tests.test_plots_sync import plot_mutation, pull, push
from tests.test_scouting_photos import FakeStorage

LOTS = "/v1/market-link/lots"
TERMS = {"terms_version": "1", "privacy_version": "1", "disclaimer_version": "1"}


def lot(plot_id: uuid.UUID, lot_id: uuid.UUID, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": None,
        "quantity_t": 12.5,
        "quality": "मोठा आकार, चांगला रंग",
        "harvest_from": "2026-12-01",
        "harvest_to": "2026-12-20",
        "basis": "per_tonne",
        "asking_rate_paise": 3_000_000,
    }
    fields.update(kw)
    return mutation("market_lot", lot_id, **fields)


# Inside the test plot's square (tests.test_plots_sync.SQUARE).
INSIDE = (21.2751, 78.5853)


def photo(
    lot_id: uuid.UUID,
    photo_id: uuid.UUID,
    key: str | None = None,
    at: tuple[float, float] = INSIDE,
) -> dict[str, Any]:
    return mutation(
        "market_lot_photo",
        photo_id,
        lot_id=str(lot_id),
        captured_at="2026-11-07T05:30:00Z",
        lat=at[0],
        lon=at[1],
        photo_key=key,
    )


def profile(**kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "display_name": "Ramesh Patil",
        "language": "mr",
        "village": "Warud",
        "taluka": "Warud",
        "district": "Amravati",
        "phone": "+919812345678",
    }
    fields.update(kw)
    return fields


class StoringStorage(FakeStorage):
    """Fake storage that keeps uploaded bytes, as the bucket would."""

    def __init__(self) -> None:
        super().__init__()
        self.objects: dict[str, bytes] = {}

    async def upload_object(self, key: str, data: bytes, content_type: str) -> None:
        self.calls.append(("put", key, None))
        if self.fail:
            raise self.fail
        assert content_type == "image/jpeg"
        self.objects[key] = data


@pytest.fixture
def storage() -> StoringStorage:
    return StoringStorage()


@pytest.fixture
async def ml(settings: Settings, engine: AsyncEngine, storage: FakeStorage) -> AsyncIterator[Any]:
    app = create_app(settings.model_copy(update={"market_link_enabled": True}))
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_photo_storage] = lambda: storage
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        c.maker = maker  # type: ignore[attr-defined]
        yield c


def headers(user: uuid.UUID) -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(user)}"}


async def accept(c: Any, h: dict[str, str], role: str = "grower") -> None:
    """The role's terms, privacy notice and disclaimer with 18+ (L1a), needed before writes."""
    r = await c.post(
        "/v1/market-link/terms/accept",
        json={"role": role, "adult_declared": True, **TERMS},
        headers=h,
    )
    assert r.status_code in (200, 201), r.text


async def draft(
    c: Any,
    h: dict[str, str],
    user: uuid.UUID,
    photos: int = 3,
    uploaded: bool = True,
    at: tuple[float, float] = INSIDE,
    **plot: Any,
) -> tuple[uuid.UUID, list[uuid.UUID]]:
    await accept(c, h)
    plot_id, lot_id = uuid.uuid4(), uuid.uuid4()
    ids = [uuid.uuid4() for _ in range(photos)]
    muts = [
        mutation("farmer_profile", user, **profile()),
        plot_mutation(plot_id, **plot),
        lot(plot_id, lot_id),
        *[photo(lot_id, p, f"{user}/{p}.jpg" if uploaded else None, at) for p in ids],
    ]
    results = await push(c, h, *muts)
    assert [r["status"] for r in results] == ["applied"] * len(muts), results
    return lot_id, ids


async def test_lot_syncs_as_a_draft_with_crop_from_the_plot(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower)
    [change] = [c for c in (await pull(ml, h))["changes"] if c["entity"] == "market_lot"]
    assert change["entity_id"] == str(lot_id)
    data = change["data"]
    assert data["status"] == "draft"
    assert (data["crop"], data["variety"]) == ("santra", "nagpur")
    assert data["published_at"] is None
    photos = [c for c in (await pull(ml, h))["changes"] if c["entity"] == "market_lot_photo"]
    assert len(photos) == 3
    assert set(photos[0]["data"]) == {"lot_id", "captured_at", "lat", "lon", "photo_key"}


async def test_a_phone_cannot_publish_or_set_server_fields(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    await accept(ml, h)
    plot_id = uuid.uuid4()
    await push(ml, h, plot_mutation(plot_id))
    for extra in ({"status": "published"}, {"crop": "mosambi"}, {"village": "x"}):
        [r] = await push(ml, h, lot(plot_id, uuid.uuid4(), **extra))
        assert (r["status"], r["error"]) == ("rejected", "invalid_payload"), extra


async def test_commission_or_income_keys_are_rejected(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    await accept(ml, h)
    plot_id = uuid.uuid4()
    await push(ml, h, plot_mutation(plot_id))
    for key in ("broker_commission_paise", "dalali", "income_paise", "Brokerage"):
        [r] = await push(ml, h, lot(plot_id, uuid.uuid4(), **{key: 1}))
        assert (r["status"], r["error"]) == ("rejected", "invalid_payload"), key


async def test_lot_payload_checks(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    await accept(ml, h)
    plot_id = uuid.uuid4()
    await push(ml, h, plot_mutation(plot_id))
    bad = (
        {"harvest_to": "2026-11-01"},
        {"basis": "per_kg"},
        {"quantity_t": 0},
        {"asking_rate_paise": 0},
    )
    for fields in bad:
        [r] = await push(ml, h, lot(plot_id, uuid.uuid4(), **fields))
        assert r["status"] == "rejected", fields
    [r] = await push(ml, h, lot(uuid.uuid4(), uuid.uuid4()))
    assert (r["status"], r["error"]) == ("rejected", "invalid_reference")
    # Someone else's plot is not a reference either.
    stranger = headers(uuid.uuid4())
    await accept(ml, stranger)
    [r] = await push(ml, stranger, lot(plot_id, uuid.uuid4()))
    assert (r["status"], r["error"]) == ("rejected", "invalid_reference")
    # A bahar of another plot is refused.
    other_plot, cycle = uuid.uuid4(), uuid.uuid4()
    await push(
        ml,
        h,
        plot_mutation(other_plot),
        mutation(
            "bahar_cycle",
            cycle,
            plot_id=str(other_plot),
            bahar="ambia",
            season_year=2026,
            status="active",
        ),
    )
    [r] = await push(ml, h, lot(plot_id, uuid.uuid4(), bahar_cycle_id=str(cycle)))
    assert (r["status"], r["error"]) == ("rejected", "invalid_reference")
    [r] = await push(ml, h, lot(other_plot, uuid.uuid4(), bahar_cycle_id=str(cycle)))
    assert r["status"] == "applied"


async def test_photo_key_must_be_the_callers_own(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower, photos=0)
    p = uuid.uuid4()
    [r] = await push(ml, h, photo(lot_id, p, f"{uuid.uuid4()}/{p}.jpg"))
    assert (r["status"], r["error"]) == ("rejected", "invalid_photo_key")


@pytest.mark.parametrize(
    "text",
    [
        "call 9822012345",
        "फोन ९८२२० १२३४५",
        "+91 98220-12345",
        "9 8 2 2 0 1 2 3 4 5",
        "see www.example.com",
        "https://x.example/lot",
        "wa.me/919822012345",
        "mail me at a@b.in",
        "photos on mybag.in",
    ],
)
async def test_lot_text_refuses_phone_numbers_and_links(ml: Any, text: str) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    await accept(ml, h)
    plot_id = uuid.uuid4()
    await push(ml, h, plot_mutation(plot_id))
    [r] = await push(ml, h, lot(plot_id, uuid.uuid4(), quality=text))
    assert (r["status"], r["error"]) == ("rejected", "invalid_payload"), text


@pytest.mark.parametrize(
    "text", ["मोठा आकार, ७०-८० मिमी, रंग चांगला", "12.5 tonnes, 2026-12-01 to 2026-12-20", "A grade"]
)
def test_ordinary_lot_text_passes(text: str) -> None:
    assert not has_contact_details(text)


async def test_lot_writes_wait_for_the_grower_terms(ml: Any) -> None:
    """Spec §4C / L1a: no lot or photo write before the grower role's terms are accepted."""
    user = uuid.uuid4()
    h = headers(user)
    plot_id, lot_id = uuid.uuid4(), uuid.uuid4()
    results = await push(ml, h, plot_mutation(plot_id), lot(plot_id, lot_id))
    assert [(r["status"], r["error"]) for r in results] == [
        ("applied", None),
        ("rejected", "terms_not_accepted"),
    ]
    await accept(ml, h, role="trader")
    [r] = await push(ml, h, lot(plot_id, lot_id))
    assert r["error"] == "terms_not_accepted"
    await accept(ml, h)
    [r] = await push(ml, h, lot(plot_id, lot_id))
    assert r["status"] == "applied"
    [r] = await push(ml, h, photo(lot_id, uuid.uuid4()))
    assert r["status"] == "applied"
