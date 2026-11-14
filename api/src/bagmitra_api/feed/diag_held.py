"""Read-only diagnosis of held AI articles (VPS 2026-11-13): WHY does a date, amount or number
"not in the source" fail? For each held news / official item with a saved article, the source
is read again (news: the page is fetched politely with the news step's own robots, spacing and
size rules, as the held re-check does; official: the stored extracted text), the article check
runs, and every date / amount / number mismatch is printed with up to two source snippets
(±60 characters) where the same day and month, or the same digits / a number word, appear.

`--pdf-probe [ITEM_ID]`: re-download one official PDF (default: the newest one whose
transcription ended `illegible`) and report its page count, text layer, character mix
(Devanagari / ASCII / private use), image-only pages and fonts. With `--render-test` (implies
`--pdf-probe`) page 1 is also rendered as the image-mode transcription renders it (Q154) and its
pixel size and PNG byte size are printed, to confirm the renderer works in the container.

Nothing is written (no database change, the session is rolled back) and no model is called.
Runbook: docs/runbooks/govt-feed.md.
    python -m bagmitra_api.feed.diag_held [--limit 15] [--pdf-probe [ITEM_ID]] [--render-test]
"""

from __future__ import annotations

import argparse
import asyncio
import io
import re
import unicodedata
import uuid
from collections import Counter
from collections.abc import Sequence
from dataclasses import dataclass, field
from urllib.parse import urlsplit

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.feed.article import ArticleSet, _texts, check_articles
from bagmitra_api.feed.extract import MAX_PAGES, assess, html_text
from bagmitra_api.feed.gr_portal import FetchFailedError, GrPortalAdapter
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource
from bagmitra_api.feed.news import NewsFeedAdapter
from bagmitra_api.feed.news_articles import _page, _saved_articles
from bagmitra_api.feed.official_items import OFFICIAL_KINDS, TRANSCRIBE
from bagmitra_api.feed.output_check import (
    _DEVANAGARI_DIGITS,
    _MONTHS,
    _NUMBER,
    _UNITS,
    _WORDS,
    Mismatch,
    SourceIndex,
    _scan,
    check_output,
    normalise,
    text_facts,
)
from bagmitra_api.feed.pdf_transcribe import RenderError, render_pages

CONTEXT = 60
MAX_SNIPPETS = 2
TITLE_CHARS = 60
SAMPLE_CHARS = 80
_SCALES = (1_000, 100_000, 10_000_000)
_NOT_WORD_AFTER = r"(?![^\W\d_]|[\u0900-\u0963\u0970-\u097f])"
_NOT_WORD_BEFORE = r"(?<![^\W\d_]|[\u0900-\u097f])"


def flat(text: str) -> str:
    """The text as the snippets show it: Indic digits as ASCII (one character for one), runs
    of whitespace as one space; wording and letter case as written."""
    return re.sub(r"\s+", " ", text.translate(_DEVANAGARI_DIGITS)).strip()


def _alt(words: Sequence[str]) -> str:
    return "|".join(sorted(map(re.escape, words), key=len, reverse=True))


def _month_names(month: int) -> list[str]:
    return [name for name, number in _MONTHS.items() if number == month]


def date_patterns(value: str) -> list[tuple[str, re.Pattern[str]]]:
    """(label, pattern) for the source places that state the date in `value` (an ISO date or a
    month-year): the same day and month in any form (with or without a year), else the month."""
    found = _scan(value).dates_found
    if not found:
        return []
    key = found[0][1]
    month = int(key[5:7])
    names = _alt(_month_names(month))
    out: list[tuple[str, re.Pattern[str]]] = []
    if len(key) == 10:
        day = int(key[8:10])
        day_month = (
            rf"(?<!\d)0?{day}(?:st|nd|rd|th)?\s*(?:of\s+|[-/.]\s*)?(?:{names})"
            rf"|{_NOT_WORD_BEFORE}(?:{names})\.?\s+0?{day}(?!\d)"
            rf"|(?<![\d.])0?{day}\s?[./-]\s?0?{month}(?![\d])"
        )
        out.append(("day+month", re.compile(day_month, re.IGNORECASE)))
    out.append(("month", re.compile(rf"{_NOT_WORD_BEFORE}(?:{names})", re.IGNORECASE)))
    return out


def _grouped(digits: str) -> str:
    """Pattern for `digits` with any digit grouping (6000, 6,000; 365011, 3,65,011)."""
    whole, _, frac = digits.partition(".")
    body = ",?".join(map(re.escape, whole))
    if frac:
        body += r"\." + re.escape(frac)
    return rf"(?<![\d.,]){body}(?![\d]|[.,]\d)"


def _unit_words(scale: int) -> list[str]:
    return [u for u, s in _UNITS.items() if s == scale]


def number_patterns(value: str) -> list[tuple[str, re.Pattern[str]]]:
    """(label, pattern) for the source places that state the number in `value`: the same
    digits (any grouping), the value in units ("2.5 लाख" for 250000) and number words
    ("पाच हजार", or "पाच" alone for 5)."""
    m = _NUMBER.search(normalise(value))
    if m is None:
        return []
    mantissa = m["num"].replace(",", "")
    scanned = [v for _, v, _ in _scan(value).numbers]
    total = scanned[0] if scanned else float(mantissa)
    out = [("digits", _grouped(mantissa))]
    if total != float(mantissa) and total.is_integer():
        out.append(("digits", _grouped(str(int(total)))))
    for scale in _SCALES:
        part = round(total / scale, 6)
        if total >= scale and part < 1000 and part * scale == total:
            units = _alt(_unit_words(scale))
            out.append(("in units", rf"(?<![\d.,]){re.escape(f'{part:g}')}\s*(?:{units})"))
            words = [w for w, n in _WORDS.items() if n == part]
            if words:
                out.append(("number word", rf"{_NOT_WORD_BEFORE}(?:{_alt(words)})\s+(?:{units})"))
    small = [w for w, n in _WORDS.items() if n == total]
    if small:
        out.append(("number word", rf"{_NOT_WORD_BEFORE}(?:{_alt(small)}){_NOT_WORD_AFTER}"))
    return [(label, re.compile(p, re.IGNORECASE)) for label, p in out]


def snippets(source: str, patterns: Sequence[tuple[str, re.Pattern[str]]]) -> list[str]:
    """Up to MAX_SNIPPETS source snippets (±CONTEXT characters) for the first pattern group
    that is found (day+month before month; digits, units and words together), then the count
    of the other places."""
    text = flat(source)
    groups: dict[str, list[tuple[int, int, str]]] = {}
    for label, pattern in patterns:
        group = "month" if label == "month" else "same"
        groups.setdefault(group, [])
        groups[group] += [(m.start(), m.end(), label) for m in pattern.finditer(text)]
    hits: list[tuple[int, int, str]] = []
    for group in ("same", "month"):
        if groups.get(group):
            hits = sorted(set(groups[group]))
            break
    kept: list[tuple[int, int, str]] = []
    for start, end, label in hits:
        if not kept or start >= kept[-1][1]:
            kept.append((start, end, label))
    out = []
    for start, end, label in kept[:MAX_SNIPPETS]:
        lo, hi = max(0, start - CONTEXT), min(len(text), end + CONTEXT)
        lead, tail = ("…" if lo else ""), ("…" if hi < len(text) else "")
        out.append(f"{label}: {lead}{text[lo:start]}[{text[start:end]}]{text[end:hi]}{tail}")
    if len(kept) > MAX_SNIPPETS:
        out.append(f"(+{len(kept) - MAX_SNIPPETS} more places)")
    return out or ["(no same day+month, digits or number word in the source)"]


def _patterns(kind: str, text: str) -> list[tuple[str, re.Pattern[str]]]:
    return date_patterns(text) if kind == "date" else number_patterns(text)


def mismatches(
    source: str, articles: ArticleSet, year: int | None
) -> list[tuple[Mismatch, list[str]]]:
    """Each date / amount / number mismatch of the article set (chart values included) with
    its source snippets."""
    index = SourceIndex.build(source, year=year)
    found: list[Mismatch] = []
    for lang, a in articles.articles.items():
        texts = dict(_texts(lang, a))
        found += [
            m
            for m in check_output(source, texts, year=year)
            if m.kind in ("date", "amount", "number")
        ]
        for i, c in enumerate(a.charts):
            found += [
                Mismatch("number", f"{p.value:g}", f"{lang}.charts[{i}].value")
                for p in c.data
                if p.value not in index.values
            ]
    return [(m, snippets(source, _patterns(m.kind, m.text))) for m in dict.fromkeys(found)]


def language_differences(articles: ArticleSet) -> list[str]:
    """For "amounts or dates differ between mr / hi / en": what each language has that
    another lacks."""
    facts = {}
    for lang, a in articles.articles.items():
        found = text_facts("\n".join(text for _, text in _texts(lang, a)))
        facts[lang] = {f"{v:g}" for v in found.amounts} | set(found.dates)
    every = set.intersection(*facts.values()) if facts else set()
    return [
        f"{lang} only/extra: {', '.join(sorted(values - every))}"
        for lang, values in facts.items()
        if values - every
    ]


def _field(where: str) -> str:
    """ "en.key_dates[2]" -> "key_dates" (the VPS count's masked form)."""
    return re.sub(r"\[\d+\].*$", "", where.split(".", 1)[-1])


@dataclass(slots=True)
class Report:
    lines: list[str] = field(default_factory=list)
    counts: Counter[str] = field(default_factory=Counter)
    items: int = 0
    pass_now: int = 0
    fetch_failed: int = 0


async def _title(session: AsyncSession, item: FeedItem) -> str:
    rows = await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
    titles = {r.lang: r.title.strip() for r in rows if r.title.strip()}
    title = next((titles[lang] for lang in ("en", "mr", "hi") if lang in titles), "")
    return title[:TITLE_CHARS]


async def _held(
    session: AsyncSession, kinds: Sequence[str], limit: int
) -> list[tuple[FeedItem, ArticleSet]]:
    """The newest `limit` held items of `kinds` that have a saved article (an item held
    before an article existed, for an unreadable page or text, has nothing to diagnose)."""
    query = select(FeedItem).where(FeedItem.type.in_(kinds), FeedItem.status == "held")
    if kinds != ("news",):
        query = query.where(FeedItem.extracted_text.is_not(None))
    out: list[tuple[FeedItem, ArticleSet]] = []
    for item in list(await session.scalars(query.order_by(FeedItem.published_at.desc()))):
        if len(out) >= limit:
            break
        articles = await _saved_articles(session, item)
        if articles is not None:
            out.append((item, articles))
    return out


async def _tiers(session: AsyncSession, items: Sequence[FeedItem]) -> dict[uuid.UUID, str]:
    rows = await session.execute(
        select(FeedSource.id, FeedSource.tier).where(
            FeedSource.id.in_({i.source_id for i in items})
        )
    )
    return dict(rows.tuples().all())


def _item_lines(source: str, articles: ArticleSet, item: FeedItem, report: Report) -> list[str]:
    year = item.published_at.year
    problems = check_articles(source, articles, source_url=item.url, published=item.published_at)
    if not problems:
        report.pass_now += 1
        return ["  passes the current check (would publish on the next re-check)"]
    lines: list[str] = []
    for m, found in mismatches(source, articles, year):
        report.counts[f"{m.kind} {_field(m.where)}"] += 1
        lines.append(f"  {m.kind} {m.where}  AI '{m.text}'")
        lines += [f"      {s}" for s in found]
    if any(p.startswith("languages:") for p in problems):
        report.counts["languages differ"] += 1
        lines.append("  languages: amounts or dates differ")
        lines += [f"      {d}" for d in language_differences(articles)]
    numeric = (" date '", " amount '", " number '", "chart value", "languages:")
    for p in problems:
        if not any(n in p for n in numeric):
            report.counts["other"] += 1
            lines.append(f"  other: {p}")
    return lines


async def diagnose(session: AsyncSession, adapter: NewsFeedAdapter, *, limit: int) -> Report:
    """At most `limit` held news and `limit` held official items with a saved article, newest
    first."""
    report = Report()
    held = await _held(session, ("news",), limit) + await _held(session, OFFICIAL_KINDS, limit)
    tiers = await _tiers(session, [item for item, _ in held])
    for item, articles in held:
        report.items += 1
        host = urlsplit(item.url).hostname or "?"
        head = (
            f"[{tiers.get(item.source_id, '?')}/{item.type}] {item.published_at.date()} "
            f'{host} {str(item.id)[:8]} "{await _title(session, item)}"'
        )
        report.lines.append(head)
        if item.type == "news":
            try:
                source = html_text(await _page(adapter, item.url))
            except FetchFailedError as exc:
                report.fetch_failed += 1
                report.lines.append(f"  page not read again: {exc.reason[:200]}")
                continue
        else:
            source = item.extracted_text or ""
        report.lines += _item_lines(source, articles, item, report)
    report.lines.append(
        f"== {report.items} held items with an article; {report.pass_now} pass the current "
        f"check; {report.fetch_failed} pages not read"
    )
    report.lines += [f"   {n:4d}  {key}" for key, n in report.counts.most_common()]
    return report


# --- PDF probe ------------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class PdfProbe:
    pages: int
    encrypted: bool
    pages_with_text: int
    image_only_pages: int
    blank_pages: int
    chars: int
    devanagari: float
    ascii: float
    private_use: float
    other: float
    quality: str
    reason: str | None
    fonts: tuple[str, ...]
    fonts_without_unicode_map: int
    sample: str


def _share(count: int, total: int) -> float:
    return round(count / total, 3) if total else 0.0


def _fonts(page: object) -> list[tuple[str, bool]]:
    """(BaseFont, has ToUnicode) of a page's fonts."""
    try:
        fonts = page["/Resources"]["/Font"]  # type: ignore[index]
        out = []
        for ref in fonts.values():
            font = ref.get_object()
            out.append((str(font.get("/BaseFont", "?")).lstrip("/"), "/ToUnicode" in font))
    except (KeyError, TypeError, AttributeError):
        return []
    return out


def probe_pdf(data: bytes) -> PdfProbe:
    """Page count, text layer per page (text / image-only / blank), the character mix of the
    pypdf text layer (as `feed/extract.py` reads it) and the fonts. No model call."""
    from pypdf import PdfReader  # noqa: PLC0415 - only for the probe

    reader = PdfReader(io.BytesIO(data))
    encrypted = reader.is_encrypted
    if encrypted:
        reader.decrypt("")
    texts: list[str] = []
    with_text = image_only = blank = 0
    fonts: dict[str, bool] = {}
    for page in reader.pages[:MAX_PAGES]:
        text = (page.extract_text() or "").strip()
        texts.append(text)
        try:
            images = len(page.images)
        except Exception:  # a damaged image entry counts as none
            images = 0
        if text:
            with_text += 1
        elif images:
            image_only += 1
        else:
            blank += 1
        for name, mapped in _fonts(page):
            fonts[name] = fonts.get(name, True) and mapped
    joined = "\f".join(texts)
    chars = [c for c in joined if not c.isspace()]
    deva = sum(1 for c in chars if "ऀ" <= c <= "ॿ" or "꣠" <= c <= "ꣿ")
    asc = sum(1 for c in chars if c.isascii())
    pua = sum(1 for c in chars if unicodedata.category(c) == "Co")
    quality, _ratio, reason = assess(joined, expect_marathi=True)
    return PdfProbe(
        pages=len(reader.pages),
        encrypted=encrypted,
        pages_with_text=with_text,
        image_only_pages=image_only,
        blank_pages=blank,
        chars=len(chars),
        devanagari=_share(deva, len(chars)),
        ascii=_share(asc, len(chars)),
        private_use=_share(pua, len(chars)),
        other=_share(len(chars) - deva - asc - pua, len(chars)),
        quality=quality,
        reason=reason,
        fonts=tuple(sorted(fonts)),
        fonts_without_unicode_map=sum(1 for mapped in fonts.values() if not mapped),
        sample=flat(joined)[:SAMPLE_CHARS],
    )


def probe_lines(probe: PdfProbe) -> list[str]:
    fonts = ", ".join(probe.fonts[:6]) + (" …" if len(probe.fonts) > 6 else "")
    return [
        f"  pages {probe.pages} (read {min(probe.pages, MAX_PAGES)}), "
        f"encrypted {'yes' if probe.encrypted else 'no'}",
        f"  text layer: {probe.pages_with_text} pages with text, {probe.image_only_pages} "
        f"image-only, {probe.blank_pages} blank; {probe.chars} characters",
        f"  characters: devanagari {probe.devanagari}, ascii {probe.ascii}, "
        f"private-use {probe.private_use}, other {probe.other}",
        f"  extract.assess: {probe.quality}" + (f" ({probe.reason})" if probe.reason else ""),
        f"  fonts: {len(probe.fonts)} ({probe.fonts_without_unicode_map} without a ToUnicode "
        f"map) {fonts}".rstrip(),
        f"  sample: {probe.sample!r}",
    ]


def render_lines(data: bytes) -> list[str]:
    """Page 1 rendered as the image-mode transcription renders it (no model call)."""
    import pypdfium2  # noqa: PLC0415 - only for its version line

    try:
        pages = render_pages(data, max_pages=1)
    except RenderError as exc:
        return [f"  render test: failed ({str(exc)[:200]})"]
    if not pages:
        return ["  render test: the PDF has no page"]
    page = pages[0]
    return [
        f"  render test: page 1 {page.width} x {page.height} px grayscale PNG, "
        f"{len(page.png)} bytes, ~{page.visual_tokens} visual tokens "
        f"(pypdfium2 {pypdfium2.PYPDFIUM_INFO}, PDFium {pypdfium2.PDFIUM_INFO}); no model call"
    ]


async def _illegible(session: AsyncSession, item_id: uuid.UUID | None) -> FeedItem | None:
    if item_id is not None:
        return await session.get(FeedItem, item_id)
    events = await session.scalars(
        select(FeedReviewEvent)
        .where(FeedReviewEvent.kind == TRANSCRIBE)
        .order_by(FeedReviewEvent.created_at.desc())
    )
    latest: dict[uuid.UUID, str] = {}
    for event in events:
        latest.setdefault(event.item_id, str(event.detail.get("result")))
    ids = [i for i, result in latest.items() if result == "illegible"]
    if not ids:
        return None
    rows = await session.scalars(
        select(FeedItem).where(FeedItem.id.in_(ids)).order_by(FeedItem.published_at.desc())
    )
    return rows.first()


async def pdf_probe(
    session: AsyncSession,
    adapter: GrPortalAdapter,
    item_id: uuid.UUID | None = None,
    *,
    render_test: bool = False,
) -> list[str]:
    item = await _illegible(session, item_id)
    if item is None:
        return ["no such item (and no PDF whose transcription ended illegible)"]
    host = urlsplit(item.url).hostname or "?"
    lines = [f"PDF probe [{item.type}] {item.published_at.date()} {host} {item.id}"]
    events = await session.scalars(
        select(FeedReviewEvent)
        .where(FeedReviewEvent.item_id == item.id, FeedReviewEvent.kind == TRANSCRIBE)
        .order_by(FeedReviewEvent.created_at.desc())
    )
    last = events.first()
    if last is not None:
        d = last.detail
        lines.append(
            f"  transcription: {d.get('result')} pages {d.get('pages')} pages_read "
            f"{d.get('pages_read')} model {d.get('model')} reason {str(d.get('reason'))[:120]}"
        )
    try:
        data, kind = await adapter.document(item.url)
    except FetchFailedError as exc:
        return [*lines, f"  document not read: {exc.reason[:200]}"]
    lines.append(f"  bytes {len(data)}, kind {kind}")
    if kind != "pdf":
        return [*lines, "  not a PDF"]
    try:
        lines += probe_lines(probe_pdf(data))
    except Exception as exc:  # pypdf raises many types on damaged files
        lines.append(f"  PDF could not be read ({type(exc).__name__})")
    return lines + render_lines(data) if render_test else lines


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="python -m bagmitra_api.feed.diag_held")
    parser.add_argument("--limit", type=int, default=15, help="held items per tier")
    parser.add_argument(
        "--pdf-probe",
        nargs="?",
        const="illegible",
        default=None,
        metavar="ITEM_ID",
        help="probe one official PDF (default: the newest illegible transcription)",
    )
    parser.add_argument(
        "--render-test",
        action="store_true",
        help="with the PDF probe: render page 1 as image mode does and print its size",
    )
    args = parser.parse_args(argv)
    if args.render_test and args.pdf_probe is None:
        args.pdf_probe = "illegible"
    return args


async def main(argv: Sequence[str] | None = None) -> int:  # pragma: no cover - CLI wrapper
    from bagmitra_api.core.settings import get_settings  # noqa: PLC0415
    from bagmitra_api.db.session import get_sessionmaker  # noqa: PLC0415

    args = parse_args(argv)
    settings = get_settings()
    # The same clients as the steps whose input is read again: the held news re-check
    # (`recheck_held`, no redirects) and the portal job (`portal_job`, redirects followed).
    redirects = args.pdf_probe is not None
    async with (
        httpx.AsyncClient(follow_redirects=redirects) as http,
        get_sessionmaker()() as session,
    ):
        adapter = NewsFeedAdapter(
            http,
            user_agent=settings.feed_fetch_user_agent,
            min_interval=settings.feed_fetch_min_interval_seconds,
            timeout=settings.feed_fetch_timeout_seconds,
        )
        try:
            if args.pdf_probe is not None:
                item_id = None if args.pdf_probe == "illegible" else uuid.UUID(args.pdf_probe)
                lines = await pdf_probe(session, adapter, item_id, render_test=args.render_test)
            else:
                lines = (await diagnose(session, adapter, limit=args.limit)).lines
        finally:
            await session.rollback()  # read-only: nothing is ever written
    print("\n".join(lines))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
