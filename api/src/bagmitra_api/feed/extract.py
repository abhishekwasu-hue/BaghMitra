"""Document text extraction (addendum v1.4 §4 step 2, OPEN_QUESTIONS QG2).

`extract` turns an uploaded PDF or HTML document into text and judges the text:
- PDF: the text layer via `pypdf` (pure Python); pages are separated by a form feed so page
  references stay possible. A scanned GR has no text layer (quality `empty`).
- HTML: the visible text only (stdlib parser; script, style, noscript and template dropped).

Many Maharashtra GRs are typed in legacy, non-Unicode Marathi fonts (Kruti Dev, Shree-Lipi…):
their text layer is Latin garbage, private-use or control characters, or Unicode Devanagari
whose vowel signs were pulled in front of the consonant. `assess` calls such text `broken` so
it is never used as the source the output check relies on.

OCR (`OcrEngine`) is a fallback for broken / empty PDFs. The Tesseract engine is OFF unless
`FEED_OCR_ENABLED=true` and both `tesseract` (with the configured language, `mar`) and
`pdftoppm` (poppler) are installed; it runs locally, never a paid or remote service.
"""

from __future__ import annotations

import asyncio
import io
import re
import shutil

# Only fixed local binaries with argument lists, never a shell.
import subprocess  # nosec B404
import tempfile
import unicodedata
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from typing import Annotated, Any, Protocol

import structlog
from fastapi import Depends

from bagmitra_api.core.settings import Settings, get_settings

log = structlog.get_logger("bagmitra.feed.extract")

PAGE_BREAK = "\f"
MAX_PAGES = 200
# Fewer meaningful (non-space) characters than this: no usable text.
MIN_CHARS = 12
# Share of private-use / control / replacement characters that marks a broken layer.
MAX_BAD_SHARE = 0.1
# Devanagari share of the letters from which a text counts as (Unicode) Marathi.
MIN_DEVANAGARI = 0.3
# Share of Devanagari words that start with a vowel sign / virama (impossible in real text).
MAX_DETACHED_SIGNS = 0.2
# Share of accented Latin letters (Latin-1 / Latin Extended) that marks legacy-font garbage.
MAX_ACCENTED_LATIN = 0.15
# A Latin text of at least this many words must look like English (common short words).
MIN_WORDS_FOR_ENGLISH = 8
MIN_ENGLISH_SHARE = 0.1
_ENGLISH_WORDS = (
    "a an and are as at be by for from has have in is it of on or shall the this that to "
    "was were which will with under per all any not who may"
)
_ENGLISH = frozenset(_ENGLISH_WORDS.split())
_SKIPPED_TAGS = frozenset({"script", "style", "noscript", "template"})
_BLOCK_TAG_NAMES = (
    "address article aside blockquote br dd div dl dt fieldset figcaption figure footer form "
    "h1 h2 h3 h4 h5 h6 header hr li main nav ol p pre section table td th title tr ul"
)
_BLOCK_TAGS = frozenset(_BLOCK_TAG_NAMES.split())
_CHARSET = re.compile(rb"""charset\s*=\s*["']?([A-Za-z0-9_.:-]+)""", re.IGNORECASE)
_LATIN_WORD = re.compile(r"[A-Za-z]+")


@dataclass(frozen=True, slots=True)
class Extraction:
    text: str
    method: str  # pdf_text | html | none
    quality: str  # ok | broken | empty
    devanagari_ratio: float
    pages: int
    reason: str | None = None

    def as_dict(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "method": self.method,
            "quality": self.quality,
            "devanagari_ratio": self.devanagari_ratio,
            "pages": self.pages,
            "reason": self.reason,
        }


def _is_devanagari(ch: str) -> bool:
    return "\u0900" <= ch <= "\u097f" or "\ua8e0" <= ch <= "\ua8ff"


def _is_bad(ch: str) -> bool:
    cat = unicodedata.category(ch)
    return cat in ("Co", "Cc", "Cs") or ch == "\ufffd"


def _detached_sign_share(text: str) -> float:
    words = [w for w in text.split() if any(_is_devanagari(c) for c in w)]
    if not words:
        return 0.0
    detached = sum(1 for w in words if _is_devanagari(w[0]) and unicodedata.category(w[0]) != "Lo")
    return detached / len(words)


def assess(  # noqa: PLR0911 - one return per verdict
    text: str, *, expect_marathi: bool = False
) -> tuple[str, float, str | None]:
    """(quality, devanagari_ratio, reason). Quality is ok | broken | empty; the ratio is the
    Devanagari share of the letters (and of the private-use / control characters)."""
    chars = [c for c in text if not c.isspace()]
    script = [c for c in chars if unicodedata.category(c)[0] in "LMC" or c == "\ufffd"]
    if len(chars) < MIN_CHARS or not script:
        return "empty", 0.0, "no text layer (scanned or empty document)"
    deva = sum(1 for c in script if _is_devanagari(c))
    ratio = round(deva / len(script), 3)
    bad = sum(1 for c in script if _is_bad(c))
    if bad / len(script) > MAX_BAD_SHARE:
        return "broken", ratio, "private-use or control characters (legacy font, no Unicode map)"
    if ratio >= MIN_DEVANAGARI:
        if _detached_sign_share(text) > MAX_DETACHED_SIGNS:
            return "broken", ratio, "Devanagari vowel signs out of order (font shaping lost)"
        return "ok", ratio, None
    if expect_marathi:
        return "broken", ratio, "almost no Devanagari in a Marathi document"
    letters = [c for c in script if unicodedata.category(c)[0] == "L"]
    accented = sum(1 for c in letters if "\u00c0" <= c <= "\u024f")
    if letters and accented / len(letters) > MAX_ACCENTED_LATIN:
        return "broken", ratio, "accented Latin letters (legacy Marathi font such as Shree-Lipi)"
    words = [w.lower() for w in _LATIN_WORD.findall(text)]
    if len(words) >= MIN_WORDS_FOR_ENGLISH:
        english = sum(1 for w in words if w in _ENGLISH) / len(words)
        if english < MIN_ENGLISH_SHARE:
            return "broken", ratio, "Latin text that is not English (legacy Marathi font)"
    return "ok", ratio, None


def _result(text: str, method: str, pages: int, *, expect_marathi: bool) -> Extraction:
    quality, ratio, reason = assess(text, expect_marathi=expect_marathi)
    return Extraction(text, method, quality, ratio, pages, reason)


def pdf_text(data: bytes, max_pages: int = MAX_PAGES) -> tuple[str, int]:
    """The text layer of the first `max_pages` pages and the page count."""
    from pypdf import PdfReader  # noqa: PLC0415 - imported only when a PDF arrives

    reader = PdfReader(io.BytesIO(data))
    if reader.is_encrypted:
        reader.decrypt("")  # GRs are at most "owner-locked"; a user password is not guessed
    pages = len(reader.pages)
    texts = [(reader.pages[i].extract_text() or "").strip() for i in range(min(pages, max_pages))]
    return PAGE_BREAK.join(texts) if any(texts) else "", pages


class _VisibleText(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._skip = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:  # noqa: ARG002
        if tag in _SKIPPED_TAGS:
            self._skip += 1
        elif tag in _BLOCK_TAGS:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in _SKIPPED_TAGS:
            self._skip = max(0, self._skip - 1)
        elif tag in _BLOCK_TAGS:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self._skip:
            self.parts.append(data)


def _decode_html(data: bytes) -> str:
    found = _CHARSET.search(data[:4096])
    if found:
        try:
            return data.decode(found.group(1).decode("ascii"), errors="replace")
        except LookupError:
            pass
    return data.decode("utf-8", errors="replace")


def html_text(data: bytes) -> str:
    parser = _VisibleText()
    parser.feed(_decode_html(data))
    parser.close()
    lines = (" ".join(line.split()) for line in "".join(parser.parts).splitlines())
    return "\n".join(line for line in lines if line)


def extract(
    data: bytes, content_type: str, *, expect_marathi: bool = False, max_pages: int = MAX_PAGES
) -> Extraction:
    kind = content_type.split(";")[0].strip().lower()
    if kind in ("pdf", "application/pdf"):
        try:
            text, pages = pdf_text(data, max_pages)
        except Exception as exc:  # pypdf raises many types on damaged files
            log.warning("feed.extract.pdf_unreadable", error=type(exc).__name__)
            return Extraction("", "none", "empty", 0.0, 0, f"PDF could not be read ({exc})")
        return _result(text, "pdf_text", pages, expect_marathi=expect_marathi)
    if kind in ("html", "text/html", "application/xhtml+xml"):
        return _result(html_text(data), "html", 1, expect_marathi=expect_marathi)
    return Extraction("", "none", "empty", 0.0, 0, f"no extractor for {kind or 'unknown type'}")


# --- OCR ------------------------------------------------------------------------------------


class OcrError(Exception):
    pass


@dataclass(frozen=True, slots=True)
class OcrResult:
    text: str
    confidence: float  # mean word confidence, 0-100
    pages: int


class OcrEngine(Protocol):
    def ocr_pdf(self, data: bytes) -> OcrResult: ...


Runner = Callable[[Sequence[str], float], tuple[str, str]]


def run_tool(args: Sequence[str], timeout: float) -> tuple[str, str]:
    """Run a local binary (absolute path, argument list, no shell); (stdout, stderr)."""
    try:
        done = subprocess.run(  # noqa: S603  # nosec B603
            list(args), capture_output=True, timeout=timeout, check=True, text=True
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise OcrError(f"{Path(args[0]).name} failed: {type(exc).__name__}") from exc
    return done.stdout, done.stderr


def parse_tsv(tsv: str) -> tuple[str, list[float]]:
    """Tesseract TSV → text (lines joined by newlines, blocks by a blank line) and the
    confidences of the recognised words."""
    lines: dict[tuple[str, str, str], list[str]] = {}
    confs: list[float] = []
    for row in tsv.splitlines()[1:]:
        cols = row.split("\t")
        if len(cols) < 12:
            continue
        try:
            word, conf = cols[11].strip(), float(cols[10])
        except ValueError:
            continue
        if not word or conf < 0:
            continue
        lines.setdefault((cols[2], cols[3], cols[4]), []).append(word)
        confs.append(conf)
    out: list[str] = []
    last_block = None
    for (block, _, _), words in lines.items():
        if last_block is not None and block != last_block:
            out.append("")
        out.append(" ".join(words))
        last_block = block
    return "\n".join(out), confs


@dataclass(frozen=True, slots=True)
class TesseractOcr:
    tesseract: str
    pdftoppm: str
    lang: str
    dpi: int
    max_pages: int
    timeout: float
    runner: Runner = run_tool

    @classmethod
    def from_settings(
        cls,
        settings: Settings,
        *,
        which: Callable[[str], str | None] = shutil.which,
        runner: Runner = run_tool,
    ) -> TesseractOcr | None:
        """The engine, or None while OCR is off or not installed (nothing is probed while
        FEED_OCR_ENABLED is false)."""
        if not settings.feed_ocr_enabled:
            return None
        tesseract, pdftoppm = which("tesseract"), which("pdftoppm")
        if tesseract is None or pdftoppm is None:
            log.warning("feed.ocr.not_installed")
            return None
        try:
            out, err = runner([tesseract, "--list-langs"], settings.feed_ocr_timeout_seconds)
        except OcrError:
            log.warning("feed.ocr.list_langs_failed")
            return None
        langs = {line.strip() for line in (out + "\n" + err).splitlines()}
        if settings.feed_ocr_lang not in langs:
            log.warning("feed.ocr.language_missing", lang=settings.feed_ocr_lang)
            return None
        return cls(
            tesseract=tesseract,
            pdftoppm=pdftoppm,
            lang=settings.feed_ocr_lang,
            dpi=settings.feed_ocr_dpi,
            max_pages=settings.feed_ocr_max_pages,
            timeout=settings.feed_ocr_timeout_seconds,
            runner=runner,
        )

    def ocr_pdf(self, data: bytes) -> OcrResult:
        with tempfile.TemporaryDirectory(prefix="feed-ocr-") as tmp:
            pdf = Path(tmp) / "doc.pdf"
            pdf.write_bytes(data)
            prefix = Path(tmp) / "page"
            self.runner(
                [self.pdftoppm, "-r", str(self.dpi), "-gray", "-png", "-l", str(self.max_pages),
                 str(pdf), str(prefix)],
                self.timeout,
            )  # fmt: skip
            images = sorted(Path(tmp).glob("page*.png"))
            if not images:
                raise OcrError("pdftoppm rendered no pages")
            texts: list[str] = []
            confs: list[float] = []
            for image in images:
                tsv, _ = self.runner(
                    [self.tesseract, str(image), "stdout", "-l", self.lang, "tsv"], self.timeout
                )
                text, page_confs = parse_tsv(tsv)
                texts.append(text)
                confs += page_confs
        confidence = round(sum(confs) / len(confs), 2) if confs else 0.0
        return OcrResult(PAGE_BREAK.join(texts), confidence, len(images))


async def get_feed_ocr(
    settings: Annotated[Settings, Depends(get_settings)],
) -> OcrEngine | None:
    """The OCR engine for uploads, or None while OCR is off / not installed."""
    if not settings.feed_ocr_enabled:
        return None
    return await asyncio.to_thread(TesseractOcr.from_settings, settings)
