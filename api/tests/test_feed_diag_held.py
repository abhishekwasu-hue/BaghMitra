"""VPS 2026-11-13: the read-only diagnosis of held AI articles (`feed/diag_held.py`) shows, for
every date / amount / number "not in the source", the AI value next to the source places that
state the same day and month, the same digits or a number word; and `--pdf-probe` reports what
an illegible PDF is made of. No model call, no database write; the web is httpx.MockTransport."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.feed.diag_held import (
    date_patterns,
    diagnose,
    number_patterns,
    parse_args,
    pdf_probe,
    probe_pdf,
    render_lines,
    snippets,
)
from bagmitra_api.feed.models import FeedItem, FeedReviewEvent, FeedSource
from bagmitra_api.feed.official_items import TRANSCRIBE, write_official_items
from bagmitra_api.feed.pdf_transcribe import render_pages
from tests.feed_docs import KRUTI_DEV, MARATHI, PUA, make_pdf
from tests.test_feed_article import SOURCE
from tests.test_feed_news import Server, adapter
from tests.test_feed_news_articles import held_item, page_with, pages
from tests.test_feed_portals import GR_PDF, FakeAi, Site, doc_site, listed, settings
from tests.test_feed_portals import adapter as portal_adapter

PAGE_SOURCE = (
    "मुंबई, दि. ५ नोव्हेंबर २०२६: समितीची बैठक १२ नोव्हेंबरला झाली. प्रति हेक्टर ₹ ६,००० "
    "अनुदान; एकूण पाच हजार शेतकरी आणि २.५ लाख रुपये. ३,६५,०११ पात्र."
)


def _snips(kind: str, value: str) -> list[str]:
    patterns = date_patterns(value) if kind == "date" else number_patterns(value)
    return snippets(PAGE_SOURCE, patterns)


def test_a_date_shows_the_same_day_and_month_as_written() -> None:
    [line] = _snips("date", "2026-11-12")
    assert line.startswith("day+month: ")
    assert "[12 नोव्हेंबर]ला" in line  # Devanagari digits shown as ASCII, wording kept


def test_a_date_without_its_day_shows_the_month_only() -> None:
    found = _snips("date", "2026-11-30")
    assert found[0].startswith("month: ")
    assert len(found) == 2


@pytest.mark.parametrize(
    ("value", "label", "shown"),
    [
        ("₹ 6,000", "digits", "[6,000]"),
        ("₹5,000", "number word", "[पाच हजार]"),
        ("250000", "in units", "[2.5 लाख]"),
        ("365011", "digits", "[3,65,011]"),
    ],
)
def test_an_amount_shows_its_digits_units_or_number_word(
    value: str, label: str, shown: str
) -> None:
    found = _snips("amount", value)
    assert any(s.startswith(f"{label}: ") and shown in s for s in found), found


def test_snippets_are_short_and_counted() -> None:
    [line, _second, more] = snippets("x " * 200 + "5 " * 5, number_patterns("5"))
    assert len(line) < 2 * 60 + 40
    assert more == "(+3 more places)"
    assert snippets(PAGE_SOURCE, number_patterns("777")) == [
        "(no same day+month, digits or number word in the source)"
    ]


async def _counts(session: AsyncSession) -> tuple[int, int]:
    events = await session.scalar(select(func.count()).select_from(FeedReviewEvent))
    items = await session.scalar(select(func.count()).select_from(FeedItem))
    return int(events or 0), int(items or 0)


async def test_diagnose_reads_the_page_again_and_writes_nothing(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        item = await held_item(session)  # holds "अनुदान ₹ 9,000"
        passes = await held_item(session, "/a2", await session.get(FeedSource, item.source_id))
        issues = list(item.check_issues)
        before = await _counts(session)
        server = Server(
            {
                **pages("/a1").routes,
                "/a2": page_with("एकूण नऊ हजार रुपये.", "/a2").routes["/a2"],
            }
        )
        report = await diagnose(session, adapter(server), limit=15)
        text = "\n".join(report.lines)
        assert "amount mr.key_points[0]  AI '₹ 9,000'" in text
        # 9,000 is not on the page in any form: neither its digits nor a number word.
        assert "(no same day+month, digits or number word in the source)" in text
        assert "passes the current check" in text
        assert report.items == 2
        assert report.pass_now == 1
        assert report.counts["amount key_points"] == 3
        assert "/a1" in server.calls
        # Read-only: nothing added or changed, the item keeps its status and reasons.
        assert not session.new
        assert not session.dirty
        assert await _counts(session) == before
        assert (item.status, item.check_issues) == ("held", issues)
        assert passes.status == "held"


async def test_diagnose_reports_a_page_that_cannot_be_read(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        await held_item(session)
        gone = Server({"/robots.txt": httpx.Response(404)})
        report = await diagnose(session, adapter(gone), limit=5)
        assert any("page not read again: HTTP 404" in line for line in report.lines)
        assert report.fetch_failed == 1


async def test_diagnose_uses_the_stored_text_of_an_official_item(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 12, 12, tzinfo=UTC)
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        item = await listed(session, now)
        await write_official_items(session, portal_adapter(doc_site()), FakeAi(), settings(), now)
        item.status = "held"
        item.extracted_text = SOURCE.replace("६,०००", "७,०००")
        await session.flush()
        nothing = Server({})
        report = await diagnose(session, adapter(nothing), limit=5)
        text = "\n".join(report.lines)
        assert text.startswith("[official/scheme]")
        assert "amount en.key_points[0]" in text
        assert "languages" not in text
        assert nothing.calls == []  # the stored text is used: no fetch


def _image_pdf() -> bytes:
    """One page that only draws an image (a scanned GR): no text layer."""
    pixel = b"\x80"
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
        b"/Resources << /XObject << /Im1 5 0 R >> >> /Contents 4 0 R >>",
    ]
    draw = b"q 612 0 0 792 0 0 cm /Im1 Do Q"
    objects.append(b"<< /Length %d >>\nstream\n" % len(draw) + draw + b"\nendstream")
    objects.append(
        b"<< /Type /XObject /Subtype /Image /Width 1 /Height 1 /ColorSpace /DeviceGray "
        b"/BitsPerComponent 8 /Length 1 >>\nstream\n" + pixel + b"\nendstream"
    )
    out = bytearray(b"%PDF-1.4\n")
    offsets = []
    for n, body in enumerate(objects, start=1):
        offsets.append(len(out))
        out += b"%d 0 obj\n" % n + body + b"\nendobj\n"
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1)
    out += b"".join(b"%010d 00000 n \n" % o for o in offsets)
    out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (
        len(objects) + 1,
        xref,
    )
    return bytes(out)


def test_probe_a_legacy_font_text_layer() -> None:
    probe = probe_pdf(make_pdf([KRUTI_DEV, KRUTI_DEV]))
    assert (probe.pages, probe.pages_with_text, probe.image_only_pages) == (2, 2, 0)
    assert probe.ascii > 0.9
    assert probe.devanagari == 0.0
    assert probe.quality == "broken"
    assert probe.fonts == ("Helvetica",)
    assert probe.fonts_without_unicode_map == 1


def test_probe_unicode_private_use_and_scanned_pages() -> None:
    unicode = probe_pdf(make_pdf([MARATHI], unicode=True))
    assert unicode.devanagari > 0.8
    assert (unicode.quality, unicode.fonts_without_unicode_map) == ("ok", 0)
    pua = probe_pdf(make_pdf([PUA], unicode=True))
    assert pua.private_use > 0.5
    scanned = probe_pdf(_image_pdf())
    assert (scanned.pages, scanned.pages_with_text, scanned.image_only_pages) == (1, 0, 1)
    assert (scanned.chars, scanned.quality) == (0, "empty")
    blank = probe_pdf(make_pdf(["", ""]))
    assert (blank.blank_pages, blank.image_only_pages) == (2, 0)


async def test_pdf_probe_takes_the_newest_illegible_transcription(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 13, 6, tzinfo=UTC)
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        item = await listed(session, now)
        detail = {
            "result": "illegible",
            "reason": "the model found it not legible",
            "pages": 2,
            "pages_read": 0,
            "model": "claude-sonnet-5-5",
        }
        event = FeedReviewEvent(id=uuid.uuid4(), item_id=item.id, kind=TRANSCRIBE, detail=detail)
        session.add(event)
        await session.flush()
        before = await _counts(session)
        pdf = {"content-type": "application/pdf"}
        site = Site({GR_PDF: httpx.Response(200, content=_image_pdf(), headers=pdf)})
        lines = await pdf_probe(session, portal_adapter(site))
        text = "\n".join(lines)
        assert "transcription: illegible pages 2 pages_read 0 model claude-sonnet-5-5" in text
        assert "pages 1 (read 1)" in text
        assert "0 pages with text, 1 image-only, 0 blank" in text
        assert "/robots.txt" in site.calls  # the portal reader's robots rule
        assert await _counts(session) == before
        assert not session.new
        missing = await pdf_probe(session, portal_adapter(site), uuid.uuid4())
        assert missing[0].startswith("no such item")


async def test_the_render_test_renders_page_one_without_a_model_call(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 13, 6, tzinfo=UTC)
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        item = await listed(session, now)
        pdf = {"content-type": "application/pdf"}
        body = make_pdf([KRUTI_DEV, KRUTI_DEV])
        site = Site({GR_PDF: httpx.Response(200, content=body, headers=pdf)})
        before = await _counts(session)
        plain = await pdf_probe(session, portal_adapter(site), item.id)
        assert not any("render test" in line for line in plain)
        lines = await pdf_probe(session, portal_adapter(site), item.id, render_test=True)
        [line] = [x for x in lines if "render test" in x]
        page = render_pages(body, max_pages=1)[0]
        assert f"page 1 {page.width} x {page.height} px grayscale PNG" in line
        assert f"{len(page.png)} bytes" in line
        assert "pypdfium2 " in line
        assert line.endswith("no model call")
        assert site.calls.count(GR_PDF) == 2  # only the portal reader: no model request
        assert await _counts(session) == before
    assert render_lines(b"%PDF-1.4 broken")[0].startswith("  render test: failed")


def test_the_command_line() -> None:
    assert parse_args([]).limit == 15
    assert parse_args([]).pdf_probe is None
    assert parse_args([]).render_test is False
    assert parse_args(["--limit", "3", "--pdf-probe"]).pdf_probe == "illegible"
    assert parse_args(["--pdf-probe", "abc"]).pdf_probe == "abc"
    assert parse_args(["--pdf-probe", "abc", "--render-test"]).render_test is True
    assert parse_args(["--render-test"]).pdf_probe == "illegible"  # implies the probe
