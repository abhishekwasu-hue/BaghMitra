"""News ingestion (addendum v1.4 §2, §3, G3): headlines from RSS 2.0 / Atom feeds.

Same gate as the GR portal adapter (`gr_portal.py`): only a source with tier `news` whose
terms the owner recorded as `allowed` is fetched (OPEN_QUESTIONS QG5), robots.txt must allow
our user agent, requests are spaced by the minimum interval, and a failure is recorded once
as `fetch_failed` / `disallowed` and never retried until an admin resets the source.

Stored per entry: headline, link, published_at and the source; never the article text
(description / content / summary) or images. Entries become `news` items with trust `news`
in `in_review`: a person writes our own two-line summary (en / mr / hi, through the admin
text endpoint) and approves before anything is published. Dedupe: the item's external id is
the SHA-256 of the entry's guid (Atom id), or of its link when it has none; a link already
stored as news from any source is not added again.

XML safety (no `defusedxml` dependency): the parser refuses any DOCTYPE, entity declaration
or external entity reference before it is expanded, so entity bombs (billion laughs) and
external entities (XXE) cannot work; feeds over MAX_FEED_BYTES are refused unread.
"""

from __future__ import annotations

import hashlib
import html
import re
import uuid
from dataclasses import dataclass, field
from datetime import UTC, datetime
from email.utils import parsedate_to_datetime
from typing import NoReturn
from urllib.parse import urljoin, urlsplit
from xml.parsers import expat  # nosec B407

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.feed.gr_portal import (
    SKIPPED_STATUSES,
    FetchFailedError,
    FetchOutcome,
    GrPortalAdapter,
    _lang_of,
)
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource

MAX_FEED_BYTES = 2 * 1024 * 1024
MAX_TITLE_CHARS = 500
_ATOM = "{http://www.w3.org/2005/Atom}"
_DC_DATE = "{http://purl.org/dc/elements/1.1/}date"
_TAG = re.compile(r"<[^>]*>")


class UnsafeXmlError(ValueError):
    """The feed is not safe or not readable XML, or not an RSS / Atom feed."""


@dataclass(slots=True)
class Node:
    """A parsed element: `{namespace}local` tags, as ElementTree writes them."""

    tag: str
    attrs: dict[str, str]
    # Text and child elements in document order.
    parts: list[str | Node] = field(default_factory=list)

    @property
    def children(self) -> list[Node]:
        return [p for p in self.parts if isinstance(p, Node)]

    def child(self, *tags: str) -> Node | None:
        return next((c for c in self.children if c.tag in tags), None)

    def all_text(self) -> str:
        return "".join(p if isinstance(p, str) else p.all_text() for p in self.parts)


def _qname(name: str) -> str:
    return "{" + name if "}" in name else name


def _refuse(*_: object) -> NoReturn:
    raise UnsafeXmlError("DTD / entity declarations are refused")


def safe_parse(data: bytes) -> Node:
    """Parses `data` into a Node tree, refusing DTDs, entities and oversized input."""
    if len(data) > MAX_FEED_BYTES:
        raise UnsafeXmlError(f"feed larger than {MAX_FEED_BYTES} bytes (too large)")
    parser = expat.ParserCreate(namespace_separator="}")
    parser.SetParamEntityParsing(expat.XML_PARAM_ENTITY_PARSING_NEVER)
    parser.StartDoctypeDeclHandler = _refuse
    parser.EntityDeclHandler = _refuse
    parser.UnparsedEntityDeclHandler = _refuse
    parser.ExternalEntityRefHandler = _refuse
    parser.buffer_text = True
    root = Node("", {})
    stack = [root]

    def start(name: str, attrs: dict[str, str]) -> None:
        node = Node(_qname(name), {_qname(k): v for k, v in attrs.items()})
        stack[-1].parts.append(node)
        stack.append(node)

    def end(_name: str) -> None:
        stack.pop()

    def data_(text: str) -> None:
        stack[-1].parts.append(text)

    parser.StartElementHandler = start
    parser.EndElementHandler = end
    parser.CharacterDataHandler = data_
    try:
        parser.Parse(data, True)
    except expat.ExpatError as exc:
        raise UnsafeXmlError(f"not well-formed XML: {exc}") from exc
    return root.children[0]


@dataclass(frozen=True, slots=True)
class NewsEntry:
    title: str
    link: str
    published: datetime
    guid: str | None


def entry_key(entry: NewsEntry) -> str:
    """Stable dedupe id: SHA-256 of the guid, or of the link when there is none."""
    return hashlib.sha256((entry.guid or entry.link).encode()).hexdigest()


def _clean_title(raw: str) -> str:
    text = html.unescape(_TAG.sub(" ", raw))
    return " ".join(_TAG.sub(" ", text).split())[:MAX_TITLE_CHARS]


def _web_link(raw: str | None, base_url: str) -> str | None:
    if not raw or not raw.strip():
        return None
    link = urljoin(base_url, raw.strip())
    return link if urlsplit(link).scheme in ("http", "https") else None


def _parse_when(raw: str | None) -> datetime | None:
    if not raw or not raw.strip():
        return None
    text = raw.strip()
    try:
        when = parsedate_to_datetime(text)  # RFC 822 (RSS)
    except (TypeError, ValueError):
        try:
            when = datetime.fromisoformat(text)  # ISO 8601 (Atom, dc:date)
        except ValueError:
            return None
    return when.replace(tzinfo=UTC) if when.tzinfo is None else when.astimezone(UTC)


def _text_of(node: Node | None) -> str | None:
    return node.all_text().strip() if node is not None else None


def _entry(
    title: str | None, link: str | None, when: str | None, guid: str | None
) -> NewsEntry | None:
    clean = _clean_title(title or "")
    published = _parse_when(when)
    if not clean or link is None or published is None:
        return None  # nothing is guessed
    return NewsEntry(clean, link, published, guid or None)


def _rss_entries(root: Node, base_url: str) -> list[NewsEntry | None]:
    channel = root.child("channel")
    items = [c for c in channel.children if c.tag == "item"] if channel else []
    return [
        _entry(
            _text_of(item.child("title")),
            _web_link(_text_of(item.child("link")), base_url),
            _text_of(item.child("pubDate", _DC_DATE)),
            _text_of(item.child("guid")),
        )
        for item in items
    ]


def _atom_link(entry: Node, base_url: str) -> str | None:
    for link in entry.children:
        if link.tag == f"{_ATOM}link" and link.attrs.get("rel", "alternate") == "alternate":
            return _web_link(link.attrs.get("href"), base_url)
    return None


def _atom_entries(root: Node, base_url: str) -> list[NewsEntry | None]:
    return [
        _entry(
            _text_of(entry.child(f"{_ATOM}title")),
            _atom_link(entry, base_url),
            _text_of(entry.child(f"{_ATOM}published", f"{_ATOM}updated")),
            _text_of(entry.child(f"{_ATOM}id")),
        )
        for entry in root.children
        if entry.tag == f"{_ATOM}entry"
    ]


def parse_feed(data: bytes, base_url: str) -> list[NewsEntry]:
    """Entries of an RSS 2.0 or Atom feed, in feed order; entries lacking a headline, a web
    link or a readable date are skipped."""
    root = safe_parse(data)
    if root.tag == "rss":
        found = _rss_entries(root, base_url)
    elif root.tag == f"{_ATOM}feed":
        found = _atom_entries(root, base_url)
    else:
        raise UnsafeXmlError(f"not an RSS / Atom feed (root {root.tag!r})")
    return [e for e in found if e is not None]


class NewsFeedAdapter(GrPortalAdapter):
    """The GR adapter's polite client (rate limit, user agent, robots) reading a feed."""

    async def read_feed(self, url: str) -> list[NewsEntry]:
        response = await self._get(url)
        host = response.url.host
        if response.status_code >= 400:
            raise FetchFailedError("fetch_failed", f"HTTP {response.status_code} from {host}")
        if len(response.content) > MAX_FEED_BYTES:
            raise FetchFailedError("fetch_failed", f"feed larger than {MAX_FEED_BYTES} bytes")
        try:
            return parse_feed(response.content, str(response.url))
        except UnsafeXmlError as exc:
            raise FetchFailedError("fetch_failed", f"unsafe or unreadable feed: {exc}") from exc


def _add_entry(session: AsyncSession, source: FeedSource, entry: NewsEntry, key: str) -> None:
    item = FeedItem(
        id=uuid.uuid4(),
        type="news",
        source_id=source.id,
        external_id=key,
        published_at=entry.published,
        url=entry.link,
        status="in_review",
        trust_level="news",
        check_issues=[],
    )
    session.add(item)
    session.add(
        FeedItemI18n(
            id=uuid.uuid4(), item_id=item.id, lang=_lang_of(entry.title), title=entry.title
        )
    )
    session.add(
        FeedReviewEvent(
            id=uuid.uuid4(), item_id=item.id, kind="created", detail={"via": "news_feed"}
        )
    )


async def fetch_news_source(
    session: AsyncSession, source: FeedSource, adapter: NewsFeedAdapter
) -> FetchOutcome:
    """One polite pass over a news source's feed. Never raises for network problems."""
    if source.tier != "news":
        return FetchOutcome(source.key, "refused", error="not a news-tier source")
    if source.terms_status != "allowed":
        if source.terms_status == "disallowed":
            source.fetch_status = "disallowed"
        source.last_error = f"not fetched: terms_status is {source.terms_status}"
        await session.flush()
        return FetchOutcome(source.key, "refused", error=source.last_error)
    if source.fetch_status in SKIPPED_STATUSES:
        return FetchOutcome(source.key, "skipped", error=source.last_error)
    try:
        await adapter.check_robots(source.url)
        entries = await adapter.read_feed(source.url)
    except FetchFailedError as exc:
        source.fetch_status = exc.status
        source.last_error = exc.reason[:500]
        await session.flush()
        return FetchOutcome(source.key, exc.status, error=source.last_error)
    known_keys = set(
        await session.scalars(select(FeedItem.external_id).where(FeedItem.source_id == source.id))
    )
    known_links = set(await session.scalars(select(FeedItem.url).where(FeedItem.type == "news")))
    added = 0
    for entry in entries:
        key = entry_key(entry)
        if key in known_keys or entry.link in known_links:
            continue
        known_keys.add(key)
        known_links.add(entry.link)
        _add_entry(session, source, entry, key)
        added += 1
    source.fetch_status = "ok"
    source.last_error = None
    source.last_ok_at = datetime.now(UTC)
    await session.flush()
    return FetchOutcome(source.key, "ok", added=added)
