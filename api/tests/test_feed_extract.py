"""Addendum v1.4 §4 step 2 / §7: text extraction from uploaded PDF / HTML, broken-Marathi
detection (contract tests) and the OCR engine (fake runner; tesseract is never needed)."""

from __future__ import annotations

from collections.abc import Sequence
from pathlib import Path

import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.extract import (
    OcrError,
    TesseractOcr,
    assess,
    extract,
    get_feed_ocr,
    html_text,
    parse_tsv,
    run_tool,
)
from tests.feed_docs import (
    ENGLISH,
    HTML,
    KRUTI_DEV,
    MARATHI,
    PUA,
    SHREE_LIPI,
    SHUFFLED,
    make_pdf,
)

# --- quality contract ---------------------------------------------------------------------


def test_unicode_marathi_is_ok() -> None:
    quality, ratio, reason = assess(MARATHI)
    assert (quality, reason) == ("ok", None)
    assert ratio > 0.9


def test_english_is_ok_unless_marathi_was_expected() -> None:
    assert assess(ENGLISH)[0] == "ok"
    quality, ratio, reason = assess(ENGLISH, expect_marathi=True)
    assert (quality, ratio) == ("broken", 0.0)
    assert reason is not None
    assert "Devanagari" in reason


@pytest.mark.parametrize(
    ("text", "hint"),
    [
        (KRUTI_DEV, "not English"),
        (SHREE_LIPI, "accented Latin"),
        (PUA, "private-use"),
        ("शासन निर्णय \x01\x02\x03\x04\x05\x06\x07\x08 \x0e\x0f\x10\x11\x12", "control"),
        ("शासन निर्णय " + "\ufffd" * 20, "private-use"),
        (SHUFFLED, "vowel signs"),
    ],
)
def test_broken_marathi_text_layers(text: str, hint: str) -> None:
    quality, _, reason = assess(text)
    assert quality == "broken", text
    assert reason is not None
    assert hint in reason


@pytest.mark.parametrize("text", ["", "   \n\f ", "१२ ३", "Page 1"])
def test_almost_no_text_is_empty(text: str) -> None:
    assert assess(text)[0] == "empty"


def test_short_latin_is_not_judged_on_words() -> None:
    assert assess("GR 2025/45 dt. 26.10.2026 Agri-dept")[0] == "ok"


# --- PDF ----------------------------------------------------------------------------------


def test_pdf_with_unicode_text_layer() -> None:
    found = extract(make_pdf([MARATHI, "दुसरे पान अनुदान ₹ १,००,०००"], unicode=True), "pdf")
    assert (found.method, found.quality, found.pages) == ("pdf_text", "ok", 2)
    assert "भाऊसाहेब फुंडकर" in found.text
    assert "₹ १,००,०००" in found.text
    assert "\f" in found.text  # page boundary kept for page references
    assert found.devanagari_ratio > 0.9
    assert found.as_dict()["quality"] == "ok"


def test_pdf_with_legacy_font_is_broken() -> None:
    found = extract(make_pdf([KRUTI_DEV]), "application/pdf")
    assert (found.method, found.quality) == ("pdf_text", "broken")
    assert "fu.kZ;" in found.text


def test_scanned_pdf_is_empty() -> None:
    found = extract(make_pdf(["", ""]), "pdf")
    assert (found.method, found.quality, found.pages, found.text) == ("pdf_text", "empty", 2, "")


def test_unreadable_pdf() -> None:
    found = extract(b"%PDF-1.4 not really", "pdf")
    assert (found.method, found.quality, found.pages) == ("none", "empty", 0)
    assert found.reason is not None


def test_page_cap() -> None:
    found = extract(make_pdf(["Page one of the resolution", ENGLISH, ENGLISH]), "pdf", max_pages=1)
    assert found.pages == 3
    assert "Government" not in found.text


def test_unknown_type() -> None:
    found = extract(b"PK\x03\x04", "application/zip")
    assert (found.method, found.quality) == ("none", "empty")


# --- HTML ---------------------------------------------------------------------------------


def test_html_visible_text_only() -> None:
    found = extract(HTML.encode(), "text/html; charset=utf-8")
    assert (found.method, found.quality, found.pages) == ("html", "ok", 1)
    assert "प्रति हेक्टर ₹ १,००,००० अनुदान." in found.text
    assert "फळबाग लागवड योजना\n" in found.text
    for hidden in ("99,99,999", "color", "JavaScript"):
        assert hidden not in found.text


def test_html_charset_and_bad_bytes() -> None:
    page = '<meta charset="windows-1252"><p>Resolution on the subsidy for the farmers</p>'
    assert html_text(page.encode("cp1252")).startswith("Resolution")
    assert html_text(b"<p>\xff\xfe \xe0\xa4</p>")  # decoded with replacement, not raised
    assert html_text(b'<meta charset="no-such-codec"><p>x</p>') == "x"


# --- OCR engine ---------------------------------------------------------------------------

TSV = "\n".join(
    [
        "level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext",
        "1\t1\t0\t0\t0\t0\t0\t0\t10\t10\t-1\t",
        "5\t1\t1\t1\t1\t1\t0\t0\t10\t10\t90.5\tशासन",
        "5\t1\t1\t1\t1\t2\t0\t0\t10\t10\t80.5\tनिर्णय",
        "5\t1\t1\t1\t2\t1\t0\t0\t10\t10\t70\tकृषी",
        "5\t1\t2\t1\t1\t1\t0\t0\t10\t10\t60\tविभाग",
        "5\t1\t2\t1\t1\t2\t0\t0\t10\t10\t95\t ",
        "bad row",
    ]
)


def test_parse_tsv() -> None:
    text, confs = parse_tsv(TSV)
    assert text == "शासन निर्णय\nकृषी\n\nविभाग"
    assert confs == [90.5, 80.5, 70.0, 60.0]


class FakeRunner:
    def __init__(self, *, langs: str = "List of available languages (2):\neng\nmar\n") -> None:
        self.langs = langs
        self.calls: list[list[str]] = []

    def __call__(self, args: Sequence[str], timeout: float) -> tuple[str, str]:
        assert timeout > 0
        self.calls.append(list(args))
        if "--list-langs" in args:
            return "", self.langs  # older tesseract prints the list on stderr
        if Path(args[0]).name == "pdftoppm":
            prefix = Path(args[-1])
            for n in (1, 2):
                prefix.with_name(f"{prefix.name}-{n}.png").write_bytes(b"png")
            return "", ""
        return TSV, "Estimating resolution as 300"


def which(name: str) -> str | None:
    return f"/usr/bin/{name}"


def ocr_settings(**extra: object) -> Settings:
    return Settings(environment="test", feed_ocr_enabled=True, **extra)  # type: ignore[arg-type]


def test_tesseract_is_off_unless_enabled_and_installed() -> None:
    runner = FakeRunner()
    assert (
        TesseractOcr.from_settings(Settings(environment="test"), which=which, runner=runner) is None
    )
    assert runner.calls == []  # nothing is probed while the setting is off
    assert TesseractOcr.from_settings(ocr_settings(), which=lambda _: None, runner=runner) is None
    no_mar = FakeRunner(langs="eng\nhin\n")
    assert TesseractOcr.from_settings(ocr_settings(), which=which, runner=no_mar) is None

    def failing(args: Sequence[str], timeout: float) -> tuple[str, str]:
        raise OcrError("boom")

    assert TesseractOcr.from_settings(ocr_settings(), which=which, runner=failing) is None
    assert TesseractOcr.from_settings(ocr_settings(), which=which, runner=runner) is not None


def test_tesseract_pages_and_confidence() -> None:
    runner = FakeRunner()
    ocr = TesseractOcr.from_settings(ocr_settings(feed_ocr_max_pages=5), which=which, runner=runner)
    assert ocr is not None
    result = ocr.ocr_pdf(make_pdf([""]))
    assert result.pages == 2
    assert result.text == "शासन निर्णय\nकृषी\n\nविभाग\f" + "शासन निर्णय\nकृषी\n\nविभाग"
    assert result.confidence == pytest.approx(75.25)
    render = runner.calls[1]
    assert render[0] == "/usr/bin/pdftoppm"
    assert render[render.index("-l") + 1] == "5"
    assert runner.calls[2][-3:] == ["-l", "mar", "tsv"]


def test_tesseract_without_pages_or_words() -> None:
    class NoPages(FakeRunner):
        def __call__(self, args: Sequence[str], timeout: float) -> tuple[str, str]:
            if Path(args[0]).name == "pdftoppm":
                return "", ""
            return super().__call__(args, timeout)

    ocr = TesseractOcr.from_settings(ocr_settings(), which=which, runner=NoPages())
    assert ocr is not None
    with pytest.raises(OcrError):
        ocr.ocr_pdf(b"%PDF")

    class NoWords(FakeRunner):
        def __call__(self, args: Sequence[str], timeout: float) -> tuple[str, str]:
            out, err = super().__call__(args, timeout)
            return (TSV.splitlines()[0], err) if out == TSV else (out, err)

    ocr = TesseractOcr.from_settings(ocr_settings(), which=which, runner=NoWords())
    assert ocr is not None
    result = ocr.ocr_pdf(b"%PDF")
    assert (result.text, result.confidence) == ("\f", 0.0)


def test_real_runner_errors_become_ocr_errors() -> None:
    with pytest.raises(OcrError):
        run_tool(["/nonexistent/tesseract", "--version"], 5)
    with pytest.raises(OcrError):
        run_tool(["/bin/sh", "-c", "exit 3"], 5)
    assert run_tool(["/bin/sh", "-c", "echo hi"], 5)[0].strip() == "hi"


async def test_dependency_is_none_by_default() -> None:
    assert await get_feed_ocr(Settings(environment="test")) is None
