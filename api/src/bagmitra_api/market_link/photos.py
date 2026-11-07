"""Market-link photo intake (spec v1.5 §4B): the API receives the JPEG, strips every metadata
segment (EXIF GPS included) and only then stores it. No image library: JPEG segments are
copied as they are, except APP1–APP15 (EXIF, XMP, ...) and comments, so the picture itself
is never re-encoded."""

from __future__ import annotations

import structlog
from fastapi import Request

from bagmitra_api.core.errors import ApiError
from bagmitra_api.photos.storage import PhotoStorageError
from bagmitra_api.routers.scouting_photos import PhotoContext

log = structlog.get_logger("bagmitra.market_link")
JPEG = "image/jpeg"
# OpenAPI for an endpoint whose body is the raw JPEG.
JPEG_BODY: dict[str, object] = {
    "requestBody": {
        "required": True,
        "content": {JPEG: {"schema": {"type": "string", "format": "binary"}}},
    }
}
SOI = b"\xff\xd8"
SOS = 0xDA
EOI = 0xD9
APPN = range(0xE1, 0xF0)
COM = 0xFE
# Markers that stand alone (no length): TEM and RST0–RST7.
STANDALONE = {0x01, *range(0xD0, 0xD8)}


class NotAJpegError(ValueError):
    pass


def strip_jpeg_metadata(data: bytes) -> bytes:
    """The same JPEG without APPn (n >= 1) and COM segments; NotAJpegError if malformed."""
    if not data.startswith(SOI):
        raise NotAJpegError("not a JPEG")
    out = bytearray(SOI)
    i = 2
    while i < len(data):
        if data[i] != 0xFF:
            raise NotAJpegError("bad segment")
        marker = data[i + 1] if i + 1 < len(data) else None
        if marker is None:
            raise NotAJpegError("truncated")
        if marker == 0xFF:  # fill byte
            i += 1
            continue
        if marker in STANDALONE:
            out += data[i : i + 2]
            i += 2
            continue
        if marker == EOI:
            out += data[i : i + 2]
            return bytes(out)
        if i + 4 > len(data):
            raise NotAJpegError("truncated")
        length = int.from_bytes(data[i + 2 : i + 4], "big")
        end = i + 2 + length
        if length < 2 or end > len(data):
            raise NotAJpegError("bad segment length")
        if marker == SOS:
            # Entropy-coded data follows to the end; it holds no metadata.
            out += data[i:]
            return bytes(out)
        if marker not in APPN and marker != COM:
            out += data[i:end]
        i = end
    raise NotAJpegError("no image data")


async def clean_jpeg(request: Request, ctx: PhotoContext) -> bytes:
    """The request body as a JPEG without metadata (422 / 413 otherwise)."""
    if request.headers.get("content-type", "").split(";")[0].strip() != JPEG:
        raise ApiError(422, "photo_not_jpeg", "send image/jpeg")
    data = await request.body()
    if len(data) > ctx.settings.photo_max_bytes:
        raise ApiError(413, "photo_too_large", f"at most {ctx.settings.photo_max_bytes} bytes")
    try:
        return strip_jpeg_metadata(data)
    except NotAJpegError as exc:
        raise ApiError(422, "photo_not_jpeg", str(exc)) from exc


async def store_jpeg(ctx: PhotoContext, key: str, data: bytes) -> None:
    """Stores a cleaned photo in the private bucket (503 when storage is off)."""
    if ctx.storage is None:
        raise ApiError(503, "photo_backup_not_configured", "photo storage not configured")
    try:
        await ctx.storage.put_object(key, data, JPEG)
    except PhotoStorageError as exc:
        log.warning("market_link_photo_store_failed", reason=str(exc))
        raise ApiError(502, "photo_storage_unavailable") from exc
