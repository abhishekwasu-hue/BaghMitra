"""Q165 (owner 2026-11-20, screenshot of an empty ज्ञान chip): older ज्ञान लेख must stay
reachable. A filtered list reads that kind's own rows (not the newest 500 of every kind), and
`before` / `before_id` page through every older item, ties on one time included."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedSource
from bagmitra_api.main import create_app
from bagmitra_api.routers import feed as feed_router

NOW = datetime.now(UTC)


@pytest.fixture
async def maker(engine: AsyncEngine) -> async_sessionmaker:  # type: ignore[type-arg]
    return async_sessionmaker(engine, expire_on_commit=False)


async def _client(settings: Settings, maker: Any) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c


@pytest.fixture
async def api(settings: Settings, maker: Any) -> AsyncIterator[httpx.AsyncClient]:
    async for c in _client(settings.model_copy(update={"feed_page_size": 3}), maker):
        yield c


async def add_items(maker: Any, kinds: list[tuple[str, datetime]]) -> list[uuid.UUID]:
    """One published item per (type, published_at), oldest-agnostic; returns their ids."""
    ids = []
    async with maker() as session:
        source = FeedSource(
            id=uuid.uuid4(),
            key=f"s{uuid.uuid4().hex[:8]}",
            name="src",
            url="https://x.example",
            tier="news",
            fetch_method="manual",
        )
        session.add(source)
        await session.flush()
        for n, (kind, at) in enumerate(kinds):
            item = FeedItem(
                id=uuid.uuid4(),
                type=kind,
                source_id=source.id,
                external_id=f"e{n}-{uuid.uuid4().hex[:6]}",
                published_at=at,
                url=f"https://x.example/{n}",
                status="published",
                trust_level="official" if kind == "knowledge" else "news",
                check_issues=[],
            )
            session.add(item)
            await session.flush()
            session.add(
                FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="mr", title=f"{kind} {n}")
            )
            ids.append(item.id)
        await session.commit()
    return ids


async def pages(
    api: httpx.AsyncClient, headers: dict[str, str], **params: str
) -> list[list[dict[str, Any]]]:
    out: list[list[dict[str, Any]]] = []
    cursor: dict[str, str] = {}
    for _ in range(50):
        body = (
            await api.get("/v1/feed", params={"lang": "mr", **params, **cursor}, headers=headers)
        ).json()
        out.append(body["items"])
        if body["next_before"] is None:
            assert body["next_before_id"] is None
            return out
        cursor = {"before": body["next_before"], "before_id": body["next_before_id"]}
    raise AssertionError("no end")


async def test_old_knowledge_is_not_crowded_out_by_news(
    api: httpx.AsyncClient,
    maker: Any,
    auth_headers: dict[str, str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    # Before: the list read the newest SCAN_LIMIT items of every kind, then filtered.
    monkeypatch.setattr(feed_router, "SCAN_LIMIT", 10)
    old = NOW - timedelta(days=150)
    (knowledge,) = await add_items(maker, [("knowledge", old)])
    await add_items(maker, [("news", NOW - timedelta(hours=h)) for h in range(20)])
    (page,) = await pages(api, auth_headers, type="knowledge")
    assert [i["id"] for i in page] == [str(knowledge)]


async def test_pages_reach_every_item_once_ties_included(
    api: httpx.AsyncClient,
    maker: Any,
    auth_headers: dict[str, str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(feed_router, "SCAN_LIMIT", 4)
    same = NOW - timedelta(days=10)
    times = [NOW - timedelta(days=d) for d in (1, 2)] + [same] * 4 + [NOW - timedelta(days=200)]
    ids = await add_items(maker, [("knowledge", t) for t in times])
    await add_items(maker, [("news", NOW - timedelta(minutes=m)) for m in range(5)])
    got = await pages(api, auth_headers, type="knowledge")
    listed = [i["id"] for p in got for i in p]
    assert sorted(listed) == sorted(str(i) for i in ids)
    assert len(listed) == len(set(listed))
    assert all(len(p) <= 3 for p in got)
    # The whole list pages the same way.
    every = [i["id"] for p in await pages(api, auth_headers) for i in p]
    assert len(every) == len(set(every)) == len(ids) + 5


async def test_a_short_list_says_it_ends(
    api: httpx.AsyncClient, maker: Any, auth_headers: dict[str, str]
) -> None:
    await add_items(maker, [("knowledge", NOW - timedelta(days=d)) for d in (1, 2)])
    body = (
        await api.get("/v1/feed", params={"lang": "mr", "type": "knowledge"}, headers=auth_headers)
    ).json()
    assert len(body["items"]) == 2
    assert (body["next_before"], body["next_before_id"]) == (None, None)
