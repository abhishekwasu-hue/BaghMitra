"""JPEG metadata stripping for market-link photos (spec v1.5 §4B): a phone JPEG carries EXIF
with the GPS point of where it was taken, which would show a buyer where the plot is. Every
APPn segment except APP0 (JFIF) and every comment is dropped; the image data is copied as is.
"""

from __future__ import annotations

SOI = b"\xff\xd8"
_APP0 = 0xE0
_APP15 = 0xEF
_COM = 0xFE
_SOS = 0xDA
# Markers without a length field.
_STANDALONE = {0x01, *range(0xD0, 0xD8)}


class NotJpegError(ValueError):
    """The bytes are not a JPEG this function can read."""


def strip_jpeg_metadata(data: bytes) -> bytes:
    """The same JPEG without EXIF / XMP / ICC / comments (APP1-APP15 and COM segments)."""
    if not data.startswith(SOI):
        raise NotJpegError("not a JPEG")
    out = bytearray(SOI)
    i = 2
    while i < len(data):
        if data[i] != 0xFF:
            raise NotJpegError("bad marker")
        marker = data[i + 1] if i + 1 < len(data) else -1
        if marker == 0xFF:  # fill byte
            i += 1
            continue
        if marker in _STANDALONE:
            out += data[i : i + 2]
            i += 2
            continue
        if i + 4 > len(data):
            raise NotJpegError("truncated")
        length = int.from_bytes(data[i + 2 : i + 4], "big")
        if length < 2 or i + 2 + length > len(data):
            raise NotJpegError("bad segment length")
        segment = data[i : i + 2 + length]
        if marker == _SOS:
            # Entropy-coded data up to the end: copied whole.
            out += data[i:]
            return bytes(out)
        if not ((_APP0 < marker <= _APP15) or marker == _COM):
            out += segment
        i += 2 + length
    raise NotJpegError("no image data")


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
# Ancillary chunks that only describe how to show the pixels; every other ancillary chunk
# (eXIf, tEXt, zTXt, iTXt, tIME, ...) may carry metadata and is dropped.
_PNG_KEEP = {b"tRNS", b"gAMA", b"sRGB", b"cHRM", b"sBIT", b"pHYs", b"bKGD"}


class NotPngError(ValueError):
    """The bytes are not a PNG this function can read."""


def strip_png_metadata(data: bytes) -> bytes:
    """The same PNG with only the critical chunks and the display chunks above (no EXIF, text
    or time). The chunks kept are copied as they are (their CRCs stay valid)."""
    if not data.startswith(PNG_SIGNATURE):
        raise NotPngError("not a PNG")
    out = bytearray(PNG_SIGNATURE)
    i = len(PNG_SIGNATURE)
    while i + 8 <= len(data):
        length = int.from_bytes(data[i : i + 4], "big")
        kind = data[i + 4 : i + 8]
        end = i + 12 + length
        if end > len(data):
            raise NotPngError("truncated chunk")
        if kind[:1].isupper() or kind in _PNG_KEEP:
            out += data[i:end]
        i = end
        if kind == b"IEND":
            return bytes(out)
    raise NotPngError("no IEND chunk")
