"""Maharashtra GR portal adapter (addendum v1.4 §3, §4.1): polite, rate-limited, gated.

Nothing is requested unless the owner has recorded the source's terms as `allowed`
(OPEN_QUESTIONS QG1) and robots.txt allows our user agent. Each request waits until the
minimum interval since the previous one has passed; a failed request is recorded once as
`fetch_failed` (or `disallowed`) and never retried: the source is skipped until an admin
resets it, and the owner can upload the GR by hand meanwhile.

The list-page parser is driven by the table headers (department, title, unique code, date,
download link), so a column reorder does not break it. No public API is known [UV]; the
contract-test fixture is modelled on the portal's result table and must be replaced by a
recorded page once fetching is allowed.

Listings become `in_review` items with the official badge (only after review are they
published). PDFs are hashed when downloaded; the bytes are not kept (QG1).
"""

from __future__ import annotations

import asyncio
import hashlib
import re
import time
import uuid
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource

MAX_DOCUMENT_BYTES = 20 * 1024 * 1024
SKIPPED_STATUSES = ("fetch_failed", "disallowed")

_HEADERS = {
    "department": ("department", "विभाग"),
    "title": ("title", "subject", "description", "विषय", "शीर्षक"),
    "code": ("unique code", "code", "सांकेतांक", "संकेतांक"),
    "date": ("date", "दिनांक"),
}


class FetchFailedError(Exception):
    def __init__(self, status: str, reason: str) -> None:
        super().__init__(reason)
        self.status = status
        self.reason = reason


@dataclass(frozen=True, slots=True)
class GrListing:
    code: str
    title: str
    department: str | None
    published: date
    url: str
    # False: the list has no code column (the Agriculture Commissionerate's GR page), so
    # `code` is the SHA-256 of the document address, not a GR number.
    numbered: bool = True


@dataclass(slots=True)
class _Cell:
    text: list[str] = field(default_factory=list)
    href: str | None = None


class _TableParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.rows: list[list[_Cell]] = []
        self._row: list[_Cell] | None = None
        self._cell: _Cell | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "tr":
            self._row = []
        elif tag in ("td", "th") and self._row is not None:
            self._cell = _Cell()
            self._row.append(self._cell)
        elif tag == "a" and self._cell is not None and self._cell.href is None:
            self._cell.href = dict(attrs).get("href")

    def handle_endtag(self, tag: str) -> None:
        if tag in ("td", "th"):
            self._cell = None
        elif tag == "tr" and self._row is not None:
            self.rows.append(self._row)
            self._row = None

    def handle_data(self, data: str) -> None:
        if self._cell is not None:
            self._cell.text.append(data)


def _text(cell: _Cell) -> str:
    return " ".join("".join(cell.text).split())


def _column_map(header: list[_Cell]) -> dict[str, int]:
    found: dict[str, int] = {}
    for index, cell in enumerate(header):
        label = _text(cell).casefold()
        for name, keys in _HEADERS.items():
            if name not in found and any(k in label for k in keys):
                found[name] = index
                break
    return found


def _parse_date(text: str) -> date | None:
    for fmt in ("%d-%m-%Y", "%d/%m/%Y", "%d.%m.%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(text.strip(), fmt).date()
        except ValueError:
            continue
    return None


def parse_list_page(html: str, base_url: str) -> list[GrListing]:
    """Listings from a result table found by its headers (title and date; a code column when
    the list has one); rows lacking a title, valid date, link or (with a code column) code are
    skipped (nothing is guessed). Script links (sorting postbacks) are not document links."""
    parser = _TableParser()
    parser.feed(html)
    columns: dict[str, int] | None = None
    listings: list[GrListing] = []
    for row in parser.rows:
        mapped = _column_map(row)
        if {"title", "date"} <= mapped.keys():
            columns = mapped
            continue
        if columns is None or len(row) <= max(columns.values()):
            continue
        href = next((c.href for c in row if c.href and not c.href.startswith("javascript:")), None)
        title = _text(row[columns["title"]])
        published = _parse_date(_text(row[columns["date"]]))
        if not title or published is None or not href:
            continue
        url = urljoin(base_url, href.strip())
        numbered = "code" in columns
        code = _text(row[columns["code"]]) if numbered else hashlib.sha256(url.encode()).hexdigest()
        if not code:
            continue
        department = _text(row[columns["department"]]) if "department" in columns else ""
        listings.append(GrListing(code, title, department or None, published, url, numbered))
    return listings


def _rule_regex(pattern: str) -> re.Pattern[str]:
    anchored = pattern.endswith("$")
    body = re.escape(pattern.rstrip("$")).replace(r"\*", ".*")
    return re.compile(body + ("$" if anchored else ""))


def robots_allows(text: str, user_agent: str, target: str) -> bool:
    """robots.txt as Google and RFC 9309 read it (the stdlib parser ignores `*` and `$`):
    the groups naming our agent (else the `*` groups, merged), and of their Allow / Disallow
    rules the longest matching one wins, Allow on a tie. A page that is not robots.txt (an HTML
    error page served with status 200) has no rules, so it allows everything."""
    agent = user_agent.split("/")[0].strip().lower()
    groups: list[tuple[set[str], list[tuple[bool, str]]]] = []
    agents: set[str] = set()
    rules: list[tuple[bool, str]] = []
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].strip()
        name, _, value = line.partition(":")
        name, value = name.strip().lower(), value.strip()
        if name == "user-agent":
            if rules:
                groups.append((agents, rules))
                agents, rules = set(), []
            agents.add(value.lower())
        elif name in ("allow", "disallow") and agents:
            if value:
                rules.append((name == "allow", value))
    if agents:
        groups.append((agents, rules))
    mine = [r for a, r in groups if agent in a]
    chosen = mine or [r for a, r in groups if "*" in a]
    best: tuple[int, bool] | None = None
    for group in chosen:
        for allow, pattern in group:
            if _rule_regex(pattern).match(target):
                length = len(pattern)
                if best is None or length > best[0] or (length == best[0] and allow):
                    best = (length, allow)
    return best is None or best[1]


class GrPortalAdapter:
    """One instance per run; spaces every request to the portal by `min_interval` seconds."""

    def __init__(  # noqa: PLR0913 - injectable clock and sleep for tests
        self,
        http: httpx.AsyncClient,
        *,
        user_agent: str,
        min_interval: float,
        timeout: float = 30.0,
        sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self._http = http
        self._user_agent = user_agent
        self._min_interval = min_interval
        self._timeout = timeout
        self._sleep = sleep
        self._clock = clock
        self._last: float | None = None

    async def _wait_turn(self) -> None:
        if self._last is not None:
            delay = self._min_interval - (self._clock() - self._last)
            if delay > 0:
                await self._sleep(delay)
        self._last = self._clock()

    async def get(self, url: str) -> httpx.Response:
        """One polite GET (spacing, user agent); FetchFailedError on a network error."""
        return await self._get(url)

    async def _get(self, url: str) -> httpx.Response:
        await self._wait_turn()
        try:
            return await self._http.get(
                url, headers={"User-Agent": self._user_agent}, timeout=self._timeout
            )
        except httpx.HTTPError as exc:
            raise FetchFailedError("fetch_failed", f"{type(exc).__name__}: {exc}") from exc

    async def check_robots(self, url: str) -> None:
        parts = urlsplit(url)
        robots_url = f"{parts.scheme}://{parts.netloc}/robots.txt"
        response = await self._get(robots_url)
        if response.status_code == httpx.codes.NOT_FOUND:
            return  # no robots.txt: no robots restriction (terms were checked separately)
        if response.status_code >= 400:
            raise FetchFailedError("fetch_failed", f"HTTP {response.status_code} for robots.txt")
        target = parts.path or "/"
        if parts.query:
            target += f"?{parts.query}"
        if not robots_allows(response.text, self._user_agent, target):
            raise FetchFailedError("disallowed", f"robots.txt disallows {parts.path or '/'}")

    async def list_page(self, url: str) -> list[GrListing]:
        response = await self._get(url)
        if response.status_code >= 400:
            raise FetchFailedError(
                "fetch_failed", f"HTTP {response.status_code} from {response.url.host}"
            )
        return parse_list_page(response.text, str(response.url))

    async def document(self, url: str) -> tuple[bytes, str]:
        """The bytes of a listed document (robots checked, at most MAX_DOCUMENT_BYTES) and its
        kind, `pdf` or `html`; FetchFailedError when it cannot be read."""
        await self.check_robots(url)
        await self._wait_turn()
        chunks: list[bytes] = []
        size = 0
        try:
            async with self._http.stream(
                "GET", url, headers={"User-Agent": self._user_agent}, timeout=self._timeout
            ) as response:
                if response.status_code >= 400:
                    raise FetchFailedError(
                        "fetch_failed", f"HTTP {response.status_code} for the document"
                    )
                content_type = response.headers.get("content-type", "")
                async for chunk in response.aiter_bytes():
                    size += len(chunk)
                    if size > MAX_DOCUMENT_BYTES:
                        raise FetchFailedError(
                            "fetch_failed", f"document larger than {MAX_DOCUMENT_BYTES} bytes"
                        )
                    chunks.append(chunk)
        except httpx.HTTPError as exc:
            raise FetchFailedError("fetch_failed", f"{type(exc).__name__}: {exc}") from exc
        data = b"".join(chunks)
        if data.startswith(b"%PDF"):
            return data, "pdf"
        if "html" in content_type or data.lstrip()[:1] == b"<":
            return data, "html"
        raise FetchFailedError("fetch_failed", f"not a PDF or HTML document ({content_type})")

    async def document_hash(self, url: str) -> tuple[str, int] | None:
        """SHA-256 and size of a GR document, or None when it cannot be read (the item then
        stays without a hash and cannot be published until an admin uploads it)."""
        await self._wait_turn()
        digest, size = hashlib.sha256(), 0
        try:
            async with self._http.stream(
                "GET", url, headers={"User-Agent": self._user_agent}, timeout=self._timeout
            ) as response:
                if response.status_code >= 400:
                    return None
                async for chunk in response.aiter_bytes():
                    size += len(chunk)
                    if size > MAX_DOCUMENT_BYTES:
                        return None
                    digest.update(chunk)
        except httpx.HTTPError:
            return None
        return (digest.hexdigest(), size) if size else None


@dataclass(frozen=True, slots=True)
class FetchOutcome:
    key: str
    status: str  # ok | refused | skipped | fetch_failed | disallowed
    added: int = 0
    error: str | None = None


def _lang_of(text: str) -> str:
    return "mr" if any("ऀ" <= ch <= "ॿ" for ch in text) else "en"


async def _add_listing(
    session: AsyncSession,
    source: FeedSource,
    listing: GrListing,
    hashed: tuple[str, int] | None,
) -> FeedItem:
    item = FeedItem(
        id=uuid.uuid4(),
        type="gr",
        source_id=source.id,
        external_id=listing.code,
        gr_number=listing.code,
        department=listing.department,
        published_at=datetime.combine(listing.published, datetime.min.time(), UTC),
        url=listing.url,
        raw_hash=hashed[0] if hashed else None,
        raw_bytes=hashed[1] if hashed else None,
        status="in_review",
        trust_level="official" if source.tier == "official" else "news",
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
            detail={"via": "gr_portal", "hashed": hashed is not None},
        )
    )
    return item


async def fetch_source_listings(
    session: AsyncSession,
    source: FeedSource,
    adapter: GrPortalAdapter,
    *,
    hash_documents: bool = True,
) -> FetchOutcome:
    """One polite pass over the source's list page. Never raises for network problems."""
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
        listings = await adapter.list_page(source.url)
    except FetchFailedError as exc:
        source.fetch_status = exc.status
        source.last_error = exc.reason[:500]
        await session.flush()
        return FetchOutcome(source.key, exc.status, error=source.last_error)
    known = set(
        await session.scalars(select(FeedItem.external_id).where(FeedItem.source_id == source.id))
    )
    added = 0
    for listing in listings:
        if listing.code in known:
            continue
        known.add(listing.code)
        hashed = await adapter.document_hash(listing.url) if hash_documents else None
        await _add_listing(session, source, listing, hashed)
        added += 1
    source.fetch_status = "ok"
    source.last_error = None
    source.last_ok_at = datetime.now(UTC)
    await session.flush()
    return FetchOutcome(source.key, "ok", added=added)
