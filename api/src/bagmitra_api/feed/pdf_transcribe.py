"""Transcription of legacy-font official PDFs by Claude (owner 2026-11-13, OPEN_QUESTIONS Q152).

Many Maharashtra GRs (MahaDBT's scheme PDFs among them) are typed in non-Unicode Marathi fonts:
their text layer is garbage and `extract.assess` calls it `broken`. Such a PDF (at most
FEED_PDF_TRANSCRIBE_MAX_PAGES pages and PDF_MAX_BYTES) is sent to the model as a document block
(base64, `application/pdf`) with one request: a faithful Unicode transcription of the visible
text only (no summary, nothing added; unreadable parts "[अस्पष्ट]"), answered as structured
output {text, pages_read, legible}. The transcription becomes the item's stored text (review
event `pdf_transcribed`: model, pages) and the normal official article path runs on it, so the
"facts in the source" checks compare against the transcription. The PDF bytes are never stored.
"""

from __future__ import annotations

import base64
from dataclasses import dataclass
from typing import Any

UNREADABLE = "[अस्पष्ट]"
# PDF support docs: requests up to 128 MB on the first-party API (less on some platforms) and
# 600 pages; base64 adds a third. 20 MB (26.7 MB as base64) is the portal reader's own limit
# (gr_portal.MAX_DOCUMENT_BYTES), so this is a second guard.
PDF_MAX_BYTES = 20 * 1024 * 1024
# Transcription is reading, not reasoning: low effort keeps thinking (always on) short.
TRANSCRIBE_EFFORT = "low"

TRANSCRIBE_PROMPT = f"""You transcribe Maharashtra government documents (GRs, circulars,
scheme notices). They are printed in Marathi with legacy, non-Unicode fonts, so their text
layer cannot be used. Read the attached PDF pages and write out the visible text in Unicode:
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
you transcribed, "legible" false when most of the document cannot be read (then "text" may be
empty)."""

TRANSCRIBE_QUESTION = "Transcribe the visible text of this document."

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


@dataclass(frozen=True, slots=True)
class Transcription:
    text: str
    pages_read: int
    legible: bool
    model: str


def pdf_document_block(data: bytes) -> dict[str, Any]:
    """The Messages API document block of a PDF (base64 without line breaks)."""
    return {
        "type": "document",
        "source": {
            "type": "base64",
            "media_type": "application/pdf",
            "data": base64.b64encode(data).decode("ascii"),
        },
    }


def parse_transcription(payload: dict[str, Any], *, model: str) -> Transcription:
    text, pages, legible = payload.get("text"), payload.get("pages_read"), payload.get("legible")
    if not isinstance(text, str) or not isinstance(legible, bool):
        raise TranscriptionError("transcription JSON lacks text or legible")
    if not isinstance(pages, int) or isinstance(pages, bool) or pages < 0:
        raise TranscriptionError("transcription JSON lacks pages_read")
    return Transcription(text=text.strip(), pages_read=pages, legible=legible, model=model)
