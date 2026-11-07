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
