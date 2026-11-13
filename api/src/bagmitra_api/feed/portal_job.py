"""Official portals run (owner 2026-11-12, OPEN_QUESTIONS Q145): reads the list page of every
official-tier source whose terms are `allowed` and that has a reader for its `fetch_method`,
adds the new listings of the last BACKFILL_DAYS (at most BACKFILL_PER_RUN per source and run)
as `in_review` items, then runs the AI step (`official_items.py`: document, classify, article,
scheme card, output check, publish or hold; a legacy-font PDF is transcribed by the model first,
Q152). Prints a JSON summary.

Readers (how each portal is read is in docs/runbooks/govt-feed.md §14):
- `portal_list`: a server-rendered result table with a date and a document link per row
  (`gr_portal.parse_list_page`: the GR portal and the Agriculture Commissionerate's GR page);
- `rss`: an RSS 2.0 / Atom feed of an official site (`news.parse_feed`); undated entries skip.
Portals without a reader (`manual`: JS-only pages, no dated list, an unreadable TLS chain)
are reported `no_reader` and never requested; their items come by manual upload.

Same politeness as every feed adapter: robots.txt (wildcards read as RFC 9309), spacing,
size limits, one try; a blocked or failing list page is recorded `fetch_failed` /
`disallowed` once and skipped until an admin sets the terms again. Trust is `official` only for
a document on a `.gov.in` / `.nic.in` host. Kill switch: CRON_FEED_PORTALS=off.
    python -m bagmitra_api.feed.portal_job
"""

from __future__ import annotations

import asyncio
import html
import json
import re
import uuid
from collections.abc import Callable
from dataclasses import asdict, dataclass, field
from datetime import UTC, date, datetime, timedelta
from urllib.parse import parse_qsl, urljoin, urlsplit

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.ai import AnthropicFeedAi
from bagmitra_api.feed.article import OFFICIAL_SUFFIXES
from bagmitra_api.feed.backfill import BACKFILL_DAYS, BACKFILL_PER_RUN
from bagmitra_api.feed.gr_portal import (
    SKIPPED_STATUSES,
    FetchFailedError,
    FetchOutcome,
    GrPortalAdapter,
    _lang_of,
    parse_list_page,
)
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource
from bagmitra_api.feed.news import UnsafeXmlError, entry_key, parse_feed
from bagmitra_api.feed.official_items import (
    OfficialAi,
    OfficialRun,
    PdfTranscriber,
    write_official_items,
)
from bagmitra_api.feed.seed import seed_feed_sources, seed_option


@dataclass(frozen=True, slots=True)
class Listing:
    code: str
    title: str
    url: str
    # None: the list gives no date (MahaDBT's open schemes): first seen, never invented.
    published: date | None
    department: str | None = None
    numbered: bool = False  # the code is the portal's GR number


def _rss_listings(data: bytes, base_url: str) -> list[Listing]:
    try:
        entries = parse_feed(data, base_url)
    except UnsafeXmlError as exc:
        raise FetchFailedError("fetch_failed", f"unsafe or unreadable feed: {exc}") from exc
    return [
        Listing(entry_key(e), e.title, e.link, e.published.date())
        for e in entries
        if e.published is not None
    ]


def _table_listings(data: bytes, base_url: str) -> list[Listing]:
    return [
        Listing(g.code, g.title, g.url, g.published, g.department, g.numbered)
        for g in parse_list_page(data.decode("utf-8", errors="replace"), base_url)
    ]


_SCHEME_LINK = re.compile(
    r"""<a\s[^>]*href=["']([^"']*SchemeData[^"']*)["'][^>]*>(.*?)</a>""", re.I | re.S
)
_PDF_LINK = re.compile(r"""<a\s[^>]*href=["']([^"']+\.pdf)["'][^>]*>(.*?)</a>""", re.I | re.S)
_TAGS = re.compile(r"<[^>]+>")
GR_LABELS = ("government resolution", "शासन निर्णय")


def _label(raw: str) -> str:
    return " ".join(html.unescape(_TAGS.sub(" ", raw)).split())


def scheme_listings(data: bytes, base_url: str) -> list[Listing]:
    """MahaDBT's farmer scheme list: one undated listing per scheme page (code: its `str`
    parameter, stable across fetches); the address is resolved to the scheme's GR later."""
    found: dict[str, Listing] = {}
    for href, text in _SCHEME_LINK.findall(data.decode("utf-8", errors="replace")):
        url = urljoin(base_url, html.unescape(href))
        code = dict(parse_qsl(urlsplit(url).query)).get("str")
        title = _label(text)
        if code and title and code not in found:
            found[code] = Listing(code, title, url, None)
    return list(found.values())


def scheme_document(data: bytes, base_url: str) -> str | None:
    """The scheme page's "Government Resolution" PDF, or None (then nothing is added)."""
    for href, text in _PDF_LINK.findall(data.decode("utf-8", errors="replace")):
        if any(label in _label(text).casefold() for label in GR_LABELS):
            return urljoin(base_url, html.unescape(str(href)).strip())
    return None


READERS: dict[str, Callable[[bytes, str], list[Listing]]] = {
    "portal_list": _table_listings,
    "rss": _rss_listings,
    "scheme_list": scheme_listings,
}
MAX_LIST_BYTES = 5 * 1024 * 1024


def official_host(url: str) -> bool:
    host = (urlsplit(url).hostname or "").lower()
    return any(host.endswith(s) for s in OFFICIAL_SUFFIXES)


async def _page(adapter: GrPortalAdapter, url: str) -> httpx.Response:
    await adapter.check_robots(url)
    response = await adapter.get(url)
    if response.status_code >= 400:
        raise FetchFailedError("fetch_failed", f"HTTP {response.status_code} from {url}")
    if len(response.content) > MAX_LIST_BYTES:
        raise FetchFailedError("fetch_failed", f"page larger than {MAX_LIST_BYTES} bytes")
    return response


async def read_listings(adapter: GrPortalAdapter, source: FeedSource) -> list[Listing]:
    response = await _page(adapter, source.url)
    return READERS[source.fetch_method](response.content, str(response.url))


def wanted(source: FeedSource, listing: Listing) -> bool:
    """The seed's `departments` (Q145: the GR portal lists every department's GRs; only the
    farm departments are read) keep a listing whose department names one of them."""
    departments = seed_option(source.key, "departments")
    if not departments or listing.department is None:
        return True
    return any(d in listing.department for d in departments)


def _add(session: AsyncSession, source: FeedSource, listing: Listing, now: datetime) -> None:
    published = (
        datetime.combine(listing.published, datetime.min.time(), UTC)
        if listing.published is not None
        else now
    )
    item = FeedItem(
        id=uuid.uuid4(),
        type="scheme" if source.fetch_method == "scheme_list" else "gr",
        source_id=source.id,
        external_id=listing.code[:120],
        gr_number=listing.code[:120] if listing.numbered else None,
        department=listing.department,
        published_at=published,
        date_is_first_seen=listing.published is None,
        url=listing.url,
        status="in_review",
        trust_level="official" if official_host(listing.url) else "news",
        check_issues=[],
    )
    session.add(item)
    session.add(
        FeedItemI18n(
            id=uuid.uuid4(),
            item_id=item.id,
            lang=_lang_of(listing.title),
            title=listing.title[:500],
        )
    )
    session.add(
        FeedReviewEvent(
            id=uuid.uuid4(),
            item_id=item.id,
            kind="created",
            detail={"via": "official_portal", "fetch_method": source.fetch_method},
        )
    )


async def _resolved(
    adapter: GrPortalAdapter, source: FeedSource, listing: Listing
) -> Listing | None:
    """A scheme-list listing points at its GR PDF (read from the scheme page)."""
    if source.fetch_method != "scheme_list":
        return listing
    try:
        page = await _page(adapter, listing.url)
    except FetchFailedError:
        return None
    pdf = scheme_document(page.content, str(page.url))
    return Listing(listing.code, listing.title, pdf, None) if pdf else None


async def fetch_portal(
    session: AsyncSession,
    source: FeedSource,
    adapter: GrPortalAdapter,
    now: datetime,
    *,
    cap: int = BACKFILL_PER_RUN,
) -> FetchOutcome:
    """One polite pass over an official source's list: the new listings of the last
    BACKFILL_DAYS (undated ones: every new one), newest first, at most `cap` per run. Never
    raises for network problems."""
    if source.terms_status != "allowed":
        return FetchOutcome(source.key, "refused", error=f"terms_status is {source.terms_status}")
    if source.fetch_method not in READERS:
        return FetchOutcome(source.key, "no_reader", error=f"fetch_method {source.fetch_method}")
    if source.fetch_status in SKIPPED_STATUSES:
        return FetchOutcome(source.key, "skipped", error=source.last_error)
    try:
        listings = await read_listings(adapter, source)
    except FetchFailedError as exc:
        source.fetch_status = exc.status
        source.last_error = exc.reason[:500]
        await session.flush()
        return FetchOutcome(source.key, exc.status, error=source.last_error)
    known = set(
        await session.scalars(select(FeedItem.external_id).where(FeedItem.source_id == source.id))
    )
    known_links = set(await session.scalars(select(FeedItem.url)))
    since = (now - timedelta(days=BACKFILL_DAYS)).date()
    added, full = 0, False
    for listing in sorted(listings, key=lambda g: g.published or now.date(), reverse=True):
        if listing.published is not None and listing.published < since:
            break
        if listing.code[:120] in known or listing.url in known_links or not wanted(source, listing):
            continue
        if added >= cap:
            full = True
            break
        resolved = await _resolved(adapter, source, listing)
        if resolved is None or resolved.url in known_links:
            continue
        known.add(listing.code[:120])
        known_links.add(resolved.url)
        _add(session, source, resolved, now)
        added += 1
    source.fetch_status = "ok"
    source.last_error = None
    source.last_ok_at = now
    if source.backfill_done_at is None and not full:
        source.backfill_done_at = now  # the list's last 30 days are all in
    await session.flush()
    return FetchOutcome(source.key, "ok", added=added)


@dataclass(slots=True)
class PortalSummary:
    sources: list[FetchOutcome] = field(default_factory=list)
    official: OfficialRun = field(default_factory=OfficialRun)
    skipped_reason: str | None = None

    def to_json(self) -> str:
        return json.dumps(
            {
                "sources": [asdict(o) for o in self.sources],
                "added": sum(o.added for o in self.sources),
                "official": self.official.as_dict(),
                "pdf_transcribe": self.official.transcribe.as_dict(),
                "skipped_reason": self.skipped_reason,
            },
            ensure_ascii=False,
        )


async def run_portals(  # noqa: PLR0913 - the job's inputs
    session: AsyncSession,
    adapter: GrPortalAdapter,
    ai: OfficialAi | None,
    settings: Settings,
    now: datetime,
    transcriber: PdfTranscriber | None = None,
) -> PortalSummary:
    summary = PortalSummary()
    if not settings.cron_feed_portals:
        summary.skipped_reason = "CRON_FEED_PORTALS is off"
        return summary
    await seed_feed_sources(session)
    sources = await session.scalars(
        select(FeedSource).where(FeedSource.tier == "official").order_by(FeedSource.key)
    )
    for source in list(sources):
        summary.sources.append(await fetch_portal(session, source, adapter, now))
    await session.commit()
    summary.official = await write_official_items(session, adapter, ai, settings, now, transcriber)
    await session.commit()
    return summary


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with httpx.AsyncClient(follow_redirects=True) as http:
        adapter = GrPortalAdapter(
            http,
            user_agent=settings.feed_fetch_user_agent,
            min_interval=settings.feed_fetch_min_interval_seconds,
            timeout=settings.feed_fetch_timeout_seconds,
        )
        ai = (
            AnthropicFeedAi(http, settings) if settings.feed_ai_api_key.get_secret_value() else None
        )
        async with get_sessionmaker()() as session:
            summary = await run_portals(session, adapter, ai, settings, datetime.now(UTC), ai)
    print(summary.to_json())
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
