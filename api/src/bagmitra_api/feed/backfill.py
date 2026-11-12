"""One-off ~30-day backfill of a news source (owner 2026-11-12, OPEN_QUESTIONS Q145).

The owner: many farming articles appeared in the last month, on other fruits too; find them.
A news source's regular run reads only its newest feed. While its `backfill_done_at` is empty,
every scheduled run also reads the older material the site offers, as the seed's `backfill`
plan names it:
- `rss_paged`: WordPress-style older feed pages (`?paged=2`, `?paged=3`, ...);
- `daily_sitemap`: one sitemap per day (`{date}` in the address). These list only links and
  dates, so each new link's page is read once for its own headline (`og:title`) and
  publication time (`article:published_time`); a page without both is skipped (nothing is
  guessed). Links whose path matches the seed's `skip_paths` (web stories, videos) are not read.
Same politeness as the regular run (robots.txt, request spacing, size limits, XML safety) and
the same dedupe (guid, then link); each entry becomes an `in_review` news item, so the article
step writes, checks and publishes it, and the topic threads group repeats.

`backfill_cursor` keeps the last page or day read completely, so a run continues where the
previous one stopped. At most BACKFILL_PER_RUN new items and MAX_PAGE_READS article pages per
source and run. The backfill is marked done at the first missing, empty, unreadable or
entirely older page, after the plan's `max_pages`, or after the last day of the window.
"""

from __future__ import annotations

import html
import re
from collections.abc import AsyncIterator
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Any
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.feed.gr_portal import FetchFailedError
from bagmitra_api.feed.models import FeedItem, FeedSource
from bagmitra_api.feed.news import (
    MAX_FEED_BYTES,
    RECENT_DAYS,
    NewsEntry,
    NewsFeedAdapter,
    UnsafeXmlError,
    _clean_title,
    _parse_when,
    add_new_entries,
    safe_parse,
    skipped_paths,
)
from bagmitra_api.feed.seed import seed_option

BACKFILL_DAYS = RECENT_DAYS
BACKFILL_PER_RUN = 100
MAX_PAGE_READS = 150
DEFAULT_MAX_PAGES = 15
_SITEMAP = "{http://www.sitemaps.org/schemas/sitemap/0.9}"
_META = re.compile(r"<meta\s[^>]*>", re.IGNORECASE)
_ATTR = re.compile(r"""([a-zA-Z:_-]+)\s*=\s*("[^"]*"|'[^']*')""")
_JSONLD_DATE = re.compile(r"""\"datePublished\"\s*:\s*\"([^\"]+)\"""")


@dataclass(slots=True)
class BackfillOutcome:
    key: str
    status: str  # done | partial | skipped | not_planned
    added: int = 0
    pages: int = 0
    error: str | None = None


def backfill_plan(key: str) -> dict[str, Any] | None:
    """The seed's `backfill` entry for a source, or None without one."""
    plan = seed_option(key, "backfill")
    return dict(plan) if isinstance(plan, dict) else None


def page_url(url: str, param: str, page: int) -> str:
    """`url` with `param=page` set in its query (other query values kept)."""
    parts = urlsplit(url)
    query = [(k, v) for k, v in parse_qsl(parts.query, keep_blank_values=True) if k != param]
    query.append((param, str(page)))
    return urlunsplit(parts._replace(query=urlencode(query)))


def sitemap_links(data: bytes) -> list[str]:
    """The `<loc>` addresses of a plain sitemap (`<urlset>`)."""
    root = safe_parse(data)
    if root.tag != f"{_SITEMAP}urlset":
        raise UnsafeXmlError(f"not a sitemap (root {root.tag!r})")
    links = []
    for node in root.children:
        loc = node.child(f"{_SITEMAP}loc")
        text = loc.all_text().strip() if loc is not None else ""
        if urlsplit(text).scheme in ("http", "https"):
            links.append(text)
    return links


def page_headline(data: bytes) -> tuple[str, datetime] | None:
    """A page's own headline (`og:title`) and publication time (`article:published_time`, else
    the JSON-LD `datePublished` the page states); None unless both are there and readable."""
    text = data[:MAX_FEED_BYTES].decode("utf-8", errors="replace")
    meta: dict[str, str] = {}
    for tag in _META.findall(text):
        attrs = {k.lower(): html.unescape(v[1:-1]) for k, v in _ATTR.findall(tag)}
        name = attrs.get("property") or attrs.get("name")
        if name and "content" in attrs:
            meta.setdefault(name.lower(), attrs["content"])
    title = _clean_title(meta.get("og:title", ""))
    stated = meta.get("article:published_time")
    if stated is None and (found := _JSONLD_DATE.search(text)) is not None:
        stated = found.group(1)
    published = _parse_when(stated)
    return (title, published) if title and published else None


async def _get(adapter: NewsFeedAdapter, url: str, what: str) -> bytes:
    await adapter.check_robots(url)
    response = await adapter.get(url)
    if response.status_code >= 400:
        raise FetchFailedError("fetch_failed", f"HTTP {response.status_code} for the {what}")
    if len(response.content) > MAX_FEED_BYTES:
        raise FetchFailedError("fetch_failed", f"{what} larger than {MAX_FEED_BYTES} bytes")
    return response.content


@dataclass(slots=True)
class _Walk:
    source: FeedSource
    plan: dict[str, Any]
    adapter: NewsFeedAdapter
    session: AsyncSession
    now: datetime
    cap: int
    outcome: BackfillOutcome
    reads: int = 0

    @property
    def cutoff(self) -> datetime:
        return self.now - timedelta(days=BACKFILL_DAYS)

    @property
    def full(self) -> bool:
        return self.outcome.added >= self.cap or self.reads >= MAX_PAGE_READS

    async def add(self, entries: list[NewsEntry]) -> list[NewsEntry]:
        recent = [e for e in entries if e.published is not None and e.published >= self.cutoff]
        self.outcome.added += await add_new_entries(
            self.session, self.source, recent, self.now, limit=self.cap - self.outcome.added
        )
        return recent


def _cursor(source: FeedSource, kind: str) -> str | None:
    value = source.backfill_cursor or ""
    prefix = f"{kind}:"
    return value[len(prefix) :] if value.startswith(prefix) else None


async def _rss_paged(walk: _Walk) -> AsyncIterator[None]:
    """Older feed pages after the cursor page; ends the walk at an empty / old page."""
    param = str(walk.plan.get("param", "paged"))
    start = int(_cursor(walk.source, "page") or 1) + 1
    for page in range(start, int(walk.plan.get("max_pages", DEFAULT_MAX_PAGES)) + 1):
        url = page_url(walk.source.url, param, page)
        await walk.adapter.check_robots(url)
        entries = await walk.adapter.read_feed(url)
        walk.outcome.pages += 1
        recent = await walk.add(entries)
        if walk.full:
            return
        walk.source.backfill_cursor = f"page:{page}"
        if not recent:
            return
        yield None


async def _daily_sitemap(walk: _Walk) -> AsyncIterator[None]:
    """One sitemap per day, newest day first, after the cursor day; each new link's page is
    read for its headline and date."""
    skip = skipped_paths(walk.source.key)
    done = _cursor(walk.source, "day")
    today = walk.now.date()
    for back in range(BACKFILL_DAYS + 1):
        day = today - timedelta(days=back)
        if done is not None and day >= date.fromisoformat(done):
            continue
        url = str(walk.plan["url_template"]).format(date=day.isoformat())
        try:
            links = sitemap_links(await _get(walk.adapter, url, "sitemap"))
        except UnsafeXmlError as exc:
            raise FetchFailedError("fetch_failed", f"unreadable sitemap: {exc}") from exc
        walk.outcome.pages += 1
        known = set(await walk.session.scalars(select(FeedItem.url).where(FeedItem.type == "news")))
        for link in links:
            if walk.full:
                return
            if link in known or any(p in urlsplit(link).path for p in skip):
                continue
            walk.reads += 1
            try:
                found = page_headline(await _get(walk.adapter, link, "page"))
            except FetchFailedError:
                continue  # one unreadable page does not end the day
            if found is not None:
                await walk.add([NewsEntry(found[0], link, found[1], None)])
        walk.source.backfill_cursor = f"day:{day.isoformat()}"
        yield None


WALKS = {"rss_paged": _rss_paged, "daily_sitemap": _daily_sitemap}


async def backfill_news_source(
    session: AsyncSession,
    source: FeedSource,
    adapter: NewsFeedAdapter,
    now: datetime,
    *,
    cap: int = BACKFILL_PER_RUN,
) -> BackfillOutcome:
    """One capped backfill pass over a news source; never raises for network problems."""
    plan = backfill_plan(source.key)
    if plan is None or plan.get("kind") not in WALKS:
        return BackfillOutcome(source.key, "not_planned")
    if source.backfill_done_at is not None:
        return BackfillOutcome(source.key, "done")
    if source.terms_status != "allowed" or source.fetch_status != "ok":
        # The regular run decides first: refused, blocked or failing sources wait.
        return BackfillOutcome(source.key, "skipped", error=source.last_error)
    walk = _Walk(source, plan, adapter, session, now, cap, BackfillOutcome(source.key, "done"))
    try:
        async for _ in WALKS[plan["kind"]](walk):
            pass
    except FetchFailedError as exc:
        # A missing or unreadable older page ends the backfill (the site has no more).
        walk.outcome.error = exc.reason[:300]
    if walk.full:
        walk.outcome.status = "partial"
    else:
        source.backfill_done_at = now
    await session.flush()
    return walk.outcome
