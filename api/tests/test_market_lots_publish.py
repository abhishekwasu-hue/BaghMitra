"""Market linkage L3, part 2: publish online, lot photos uploaded through the API with EXIF
stripped (spec v1.5 §4B) and the real orchard check (§4C)."""

from __future__ import annotations

import uuid
from typing import Any

import httpx
import pytest

from bagmitra_api.market_link.orchard import orchard_check
from bagmitra_api.photos.exif import NotJpegError, strip_jpeg_metadata
from bagmitra_api.photos.storage import PhotoStorageError, SupabaseStorageClient
from tests.test_market_lots_sync import (
    INSIDE,
    LOTS,
    StoringStorage,
    accept,
    draft,
    headers,
    lot,
    ml,
    photo,
    storage,
)
from tests.test_plots_sync import plot_mutation, pull, push

# The enabled client and storage fixtures of part 1.
__all__ = ["ml", "storage"]


async def test_flag_off_hides_the_grower_lot_endpoints(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    some = uuid.uuid4()
    for method, path in (
        ("POST", f"{LOTS}/{some}/publish"),
        ("POST", f"{LOTS}/{some}/close"),
        ("PUT", f"/v1/market-link/lot-photos/{some}/photo"),
    ):
        r = await client.request(method, path, headers=auth_headers, content=b"x")
        assert r.status_code == 404, (path, r.text)


async def test_grower_writes_need_the_terms(ml: Any) -> None:
    """L1a: publish, close and photo upload answer 403 until the grower terms are accepted."""
    h = headers(uuid.uuid4())
    some = uuid.uuid4()
    for method, path in (
        ("POST", f"{LOTS}/{some}/publish"),
        ("POST", f"{LOTS}/{some}/close"),
        ("PUT", f"/v1/market-link/lot-photos/{some}/photo"),
    ):
        r = await ml.request(method, path, headers=h, content=b"x")
        assert (r.status_code, r.json()["error"]["code"]) == (403, "terms_not_accepted"), path


@pytest.mark.parametrize(("count", "ok"), [(2, False), (3, True), (8, True), (9, False)])
async def test_publish_needs_three_to_eight_photos(ml: Any, count: int, ok: bool) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower, photos=count)
    r = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    if ok:
        assert r.status_code == 200, r.text
        assert r.json()["status"] == "published"
    else:
        assert r.status_code == 422
        assert r.json()["error"]["code"] == "lot_photos_needed"


async def test_publish_needs_uploaded_photos(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower, uploaded=False)
    r = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    assert (r.status_code, r.json()["error"]["code"]) == (422, "lot_photos_not_uploaded")


async def test_publish_copies_places_and_locks_the_draft(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, photos = await draft(ml, h, grower)
    cursor = (await pull(ml, h))["cursor"]
    stranger = headers(uuid.uuid4())
    await accept(ml, stranger)
    assert (await ml.post(f"{LOTS}/{lot_id}/publish", headers=stranger)).status_code == 404
    r = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    assert r.status_code == 200, r.text
    body = r.json()
    assert (body["village"], body["taluka"], body["district"]) == ("Warud", "Warud", "Amravati")
    assert body["published_at"] is not None
    # The grower's phones pull the new state.
    [change] = [c for c in (await pull(ml, h, cursor))["changes"] if c["entity"] == "market_lot"]
    assert change["data"]["status"] == "published"
    # A published lot and its photos no longer change through sync.
    again = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    assert (again.status_code, again.json()["error"]["code"]) == (409, "lot_not_draft")
    plot_id = uuid.uuid4()
    await push(ml, h, plot_mutation(plot_id))
    edit = lot(plot_id, lot_id)
    edit["client_updated_at"] = "2030-01-01T00:00:00Z"
    [r1] = await push(ml, h, edit)
    [r2] = await push(ml, h, {**photo(lot_id, photos[0]), "op": "delete", "payload": {}})
    [r3] = await push(ml, h, photo(lot_id, uuid.uuid4()))
    assert [r["error"] for r in (r1, r2, r3)] == ["lot_not_draft"] * 3
    # Close takes it off the list.
    closed = await ml.post(f"{LOTS}/{lot_id}/close", headers=h)
    assert closed.json()["status"] == "closed"
    assert (await ml.post(f"{LOTS}/{lot_id}/close", headers=h)).status_code == 409


def jpeg_with_gps() -> bytes:
    """A small JPEG as a phone writes it: JFIF, then EXIF with a GPS block, then the image."""
    app0 = b"JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"
    exif = b"Exif\x00\x00MM\x00*GPSLatitude 21.1458 GPSLongitude 79.0882"
    xmp = b"http://ns.adobe.com/xap/1.0/\x00<x:xmpmeta>GPS</x:xmpmeta>"
    dqt = b"\x00" + bytes(range(64))
    sos = b"\x01\x01\x00\x00\x3f\x00"

    def seg(marker: int, body: bytes) -> bytes:
        return bytes([0xFF, marker]) + (len(body) + 2).to_bytes(2, "big") + body

    return (
        b"\xff\xd8"
        + seg(0xE0, app0)
        + seg(0xE1, exif)
        + seg(0xE1, xmp)
        + seg(0xFE, b"taken on a phone")
        + seg(0xDB, dqt)
        + seg(0xDA, sos)
        + b"\x12\x34\xff\x00\x56"
        + b"\xff\xd9"
    )


def test_strip_keeps_the_image_and_drops_the_metadata() -> None:
    raw = jpeg_with_gps()
    clean = strip_jpeg_metadata(raw)
    for gone in (b"GPS", b"Exif", b"phone"):
        assert gone not in clean
    assert clean.startswith(b"\xff\xd8\xff\xe0")
    assert b"JFIF" in clean
    assert clean.endswith(b"\x12\x34\xff\x00\x56\xff\xd9")
    assert strip_jpeg_metadata(clean) == clean
    for bad in (b"", b"GIF89a", b"\xff\xd8\xff\xe1\x00", b"\xff\xd8\x00"):
        with pytest.raises(NotJpegError):
            strip_jpeg_metadata(bad)


async def upload(c: Any, photo_id: uuid.UUID, h: dict[str, str], data: bytes) -> Any:
    return await c.put(
        f"/v1/market-link/lot-photos/{photo_id}/photo",
        content=data,
        headers={**h, "Content-Type": "image/jpeg"},
    )


async def test_lot_photos_upload_without_exif(ml: Any, storage: StoringStorage) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, photos = await draft(ml, h, grower, uploaded=False)
    p = photos[0]
    up = await upload(ml, p, h, jpeg_with_gps())
    assert up.status_code == 200, up.text
    key = f"{grower}/{p}.jpg"
    assert up.json() == {"photo_key": key}
    # What the bucket holds (and so what any download returns) has no EXIF / GPS.
    assert b"GPS" not in storage.objects[key]
    assert b"Exif" not in storage.objects[key]
    other = headers(uuid.uuid4())
    await accept(ml, other)
    assert (await upload(ml, p, other, jpeg_with_gps())).status_code == 404
    bad = await upload(ml, p, h, b"GIF89a....")
    assert (bad.status_code, bad.json()["error"]["code"]) == (415, "photo_not_jpeg")
    wrong_type = await ml.put(
        f"/v1/market-link/lot-photos/{p}/photo",
        content=jpeg_with_gps(),
        headers={**h, "Content-Type": "image/png"},
    )
    assert wrong_type.status_code == 415
    big = await upload(ml, p, h, b"\xff\xd8" + b"\x00" * (2 * 1024 * 1024))
    assert (big.status_code, big.json()["error"]["code"]) == (413, "photo_too_large")
    storage.fail = PhotoStorageError("down")
    assert (await upload(ml, p, h, jpeg_with_gps())).status_code == 502
    storage.fail = None
    # Record the keys and publish: no uploads to a published lot.
    await push(ml, h, *[photo(lot_id, i, f"{grower}/{i}.jpg") for i in photos])
    assert (await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)).status_code == 200
    late = await upload(ml, p, h, jpeg_with_gps())
    assert (late.status_code, late.json()["error"]["code"]) == (409, "lot_not_draft")


async def test_supabase_upload_object_posts_raw_bytes() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200 if len(seen) == 1 else 500, json={})

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        store = SupabaseStorageClient(
            http, base_url="https://x.supabase.co/", bucket="b", service_key="k"
        )
        await store.upload_object("u/p.jpg", b"\xff\xd8", "image/jpeg")
        with pytest.raises(PhotoStorageError):
            await store.upload_object("u/p.jpg", b"\xff\xd8", "image/jpeg")
    req = seen[0]
    assert str(req.url) == "https://x.supabase.co/storage/v1/object/b/u/p.jpg"
    assert req.content == b"\xff\xd8"
    assert req.headers["content-type"] == "image/jpeg"
    assert req.headers["x-upsert"] == "true"


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
    """Spec §4C: a lot photographed away from the mapped plot is published, flagged for an
    admin check (part 3 keeps such lots out of the traders' list)."""
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower, at=at, **plot)
    r = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "published"
    assert (r.json()["orchard_check"] in ("inside", "near")) is ok


def test_orchard_check_rules() -> None:
    square = {
        "type": "Polygon",
        "coordinates": [[[0, 0], [0.001, 0], [0.001, 0.001], [0, 0.001], [0, 0]]],
    }
    holed = {
        "type": "Polygon",
        "coordinates": [
            square["coordinates"][0],
            [
                [0.0004, 0.0004],
                [0.0006, 0.0004],
                [0.0006, 0.0006],
                [0.0004, 0.0006],
                [0.0004, 0.0004],
            ],
        ],
    }
    assert orchard_check([(0.0005, 0.0005)], square, None, 50) == "inside"
    assert orchard_check([(0.0005, 0.0005)], holed, None, 20) == "near"
    assert orchard_check([(0.0005, 0.0005), (0.01, 0.01)], square, None, 50) == "outside"
    assert orchard_check([(0.0, 0.0)], None, None, 50) == "unmapped"
    assert orchard_check([], square, None, 50) == "inside"
