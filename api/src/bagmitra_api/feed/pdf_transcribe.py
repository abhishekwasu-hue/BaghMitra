"""Transcription of legacy-font official PDFs by Claude (owner 2026-11-13, OPEN_QUESTIONS Q152).

Many Maharashtra GRs (MahaDBT's scheme PDFs among them) are typed in non-Unicode Marathi fonts:
their text layer is garbage and `extract.assess` calls it `broken`. Such a PDF (at most
FEED_PDF_TRANSCRIBE_MAX_PAGES pages and PDF_MAX_BYTES) is transcribed by the model: a faithful
Unicode transcription of the visible text only (no summary, nothing added; unreadable parts
"[अस्पष्ट]"), answered as structured output {text, pages_read, legible}. The transcription
becomes the item's stored text (review event `pdf_transcribed`: model, pages) and the normal
official article path runs on it, so the "facts in the source" checks compare against the
transcription. Neither the PDF bytes nor the page images are ever stored.

Image mode (Q154): every page is rendered here (pypdfium2, grayscale PNG, long edge
IMAGE_LONG_EDGE px) and sent as an `image` block, at most IMAGES_PER_REQUEST pages per
request; the batches' texts are joined in page order. The PDF `document` block (Q152's first
version) is not used any more: for a PDF document block the API extracts each page's text
layer and sends it alongside the page's image (PDF-support docs, "How PDF support works"), and
for these PDFs that text layer is legacy-font garbage. Both MahaDBT PDFs sent that way on the
VPS came back `legible: false`, `pages_read: 0`. A page image carries no text layer.
"""

from __future__ import annotations

import base64
import math
import struct
import zlib
from dataclasses import dataclass
from typing import Any

import pypdfium2

UNREADABLE = "[अस्पष्ट]"
# PDF support docs: requests up to 128 MB on the first-party API (less on some platforms) and
# 600 pages; base64 adds a third. 20 MB (26.7 MB as base64) is the portal reader's own limit
# (gr_portal.MAX_DOCUMENT_BYTES), so this is a second guard.
PDF_MAX_BYTES = 20 * 1024 * 1024
# Transcription is reading, not reasoning: low effort keeps thinking (always on) short.
TRANSCRIBE_EFFORT = "low"
# Vision docs: an image above 1,568 px on its long edge is downscaled on standard-tier models
# (2,576 px on Claude 4.7 and later), so 1,568 px is used as sent on every model: ~134 dpi on an
# A4 page, a 12 pt line ~22 px high. A page costs ceil(w/28) * ceil(h/28) visual tokens
# (A4, 1109 x 1568 px: 2,240).
IMAGE_LONG_EDGE = 1568
# Vision docs: above 20 images in one request a stricter per-image size limit applies (on some
# platforms PDF blocks count too); 20 pages per request stays below it everywhere. With the
# 30-page cap a PDF takes at most two requests.
IMAGES_PER_REQUEST = 20
# Review-event `mode` of a transcription made from page images (Q154).
IMAGE_MODE = "image"

TRANSCRIBE_PROMPT = f"""You transcribe Maharashtra government documents (GRs, circulars,
scheme notices). They are printed in Marathi with legacy, non-Unicode fonts, so their text
layer cannot be used. Read the attached page images and write out the visible text in Unicode:
Devanagari for Marathi and Hindi, English as printed.
Rules:
- Transcribe only what is printed on the pages, in reading order, page after page. Separate
  pages with one form-feed character.
- Do not summarise, translate, correct, complete or explain anything. Add no headings, notes,
  labels or words of your own.
- Copy every number, amount, date, GR number and name exactly as printed (Devanagari digits
  stay Devanagari digits, English digits stay English digits).
- Keep each table row on its own line, cells separated by " | ".
- Where a word or passage cannot be read with certainty, write {UNREADABLE} in its place.
  Never guess a word.
- Leave out logos, stamps and signatures unless they carry printed words.
Answer with the JSON object only: "text" is the transcription, "pages_read" the number of pages
you transcribed, "legible" false when most of the pages cannot be read (then "text" may be
empty)."""

TRANSCRIBE_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "text": {"type": "string"},
        "pages_read": {"type": "integer"},
        "legible": {"type": "boolean"},
    },
    "required": ["text", "pages_read", "legible"],
    "additionalProperties": False,
}


class TranscriptionError(Exception):
    """The answer does not have the transcription's shape."""


class RenderError(Exception):
    """The PDF's pages could not be rendered to images (no model request was made)."""


@dataclass(frozen=True, slots=True)
class Transcription:
    text: str
    pages_read: int
    legible: bool
    model: str
    requests: int = 1


@dataclass(frozen=True, slots=True)
class PageImage:
    """One rendered page: a grayscale PNG, held in memory only for the request."""

    png: bytes
    width: int
    height: int

    @property
    def visual_tokens(self) -> int:
        """Vision docs: ceil(width / 28) * ceil(height / 28) input tokens."""
        return math.ceil(self.width / 28) * math.ceil(self.height / 28)


def _chunk(kind: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(kind + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc)


def gray_png(gray: bytes, width: int, height: int, stride: int) -> bytes:
    """An 8-bit grayscale PNG of a pixel buffer (zlib only; no image library needed)."""
    rows = b"".join(b"\x00" + gray[y * stride : y * stride + width] for y in range(height))
    header = struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", header)
        + _chunk(b"IDAT", zlib.compress(rows, 9))
        + _chunk(b"IEND", b"")
    )


def render_pages(
    data: bytes, *, max_pages: int, long_edge: int = IMAGE_LONG_EDGE
) -> list[PageImage]:
    """The first `max_pages` pages as grayscale PNGs whose long edge is `long_edge` px."""
    try:
        pdf = pypdfium2.PdfDocument(data)
    except pypdfium2.PdfiumError as exc:
        raise RenderError(f"PDF not opened for rendering: {exc}") from exc
    out: list[PageImage] = []
    try:
        for index in range(min(len(pdf), max_pages)):
            page = pdf[index]
            try:
                width, height = page.get_size()
                bitmap = page.render(scale=long_edge / max(width, height, 1.0), grayscale=True)
                if bitmap.n_channels != 1:  # pragma: no cover - grayscale is one byte a pixel
                    raise RenderError(f"page {index + 1}: {bitmap.n_channels} channels")
                png = gray_png(bytes(bitmap.buffer), bitmap.width, bitmap.height, bitmap.stride)
                out.append(PageImage(png, bitmap.width, bitmap.height))
                bitmap.close()
            except pypdfium2.PdfiumError as exc:
                raise RenderError(f"page {index + 1} not rendered: {exc}") from exc
            finally:
                page.close()
    finally:
        pdf.close()
    return out


def image_block(page: PageImage) -> dict[str, Any]:
    """The Messages API image block of a rendered page (base64 without line breaks)."""
    return {
        "type": "image",
        "source": {
            "type": "base64",
            "media_type": "image/png",
            "data": base64.b64encode(page.png).decode("ascii"),
        },
    }


def requests_for(pages: int) -> int:
    """Model requests that a transcription of `pages` pages makes (the daily cap counts them)."""
    return max(1, math.ceil(pages / IMAGES_PER_REQUEST))


def batches(pages: list[PageImage]) -> list[list[PageImage]]:
    return [pages[i : i + IMAGES_PER_REQUEST] for i in range(0, len(pages), IMAGES_PER_REQUEST)]


def batch_content(batch: list[PageImage], first: int, total: int) -> list[dict[str, Any]]:
    """One request's user content: each page image after its page label, then the question."""
    content: list[dict[str, Any]] = []
    for number, page in enumerate(batch, start=first):
        content.append({"type": "text", "text": f"Page {number}:"})
        content.append(image_block(page))
    last = first + len(batch) - 1
    question = (
        f"Transcribe the visible text of these page images: pages {first} to {last} of a "
        f"{total}-page document."
    )
    content.append({"type": "text", "text": question})
    return content


def joined(parts: list[Transcription], *, model: str) -> Transcription:
    """The batches' transcriptions in page order (form feed between them); legible only when
    every batch is legible."""
    return Transcription(
        text="\f".join(p.text for p in parts if p.text),
        pages_read=sum(p.pages_read for p in parts),
        legible=bool(parts) and all(p.legible for p in parts),
        model=model,
        requests=len(parts),
    )


def parse_transcription(payload: dict[str, Any], *, model: str) -> Transcription:
    text, pages, legible = payload.get("text"), payload.get("pages_read"), payload.get("legible")
    if not isinstance(text, str) or not isinstance(legible, bool):
        raise TranscriptionError("transcription JSON lacks text or legible")
    if not isinstance(pages, int) or isinstance(pages, bool) or pages < 0:
        raise TranscriptionError("transcription JSON lacks pages_read")
    return Transcription(text=text.strip(), pages_read=pages, legible=legible, model=model)
