"""K0: source documents are fetched (or uploaded by an admin), hashed and tracked. Only the
hash, size and time are kept (licences forbid redistributing the text); a blocked host is
recorded as `fetch_failed` with the reason instead of being faked."""

from __future__ import annotations

import hashlib
import uuid

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.kb.fetcher import MAX_DOCUMENT_BYTES, fetch_all, fetch_source
from bagmitra_api.kb.models import KbSource
from bagmitra_api.kb.seed import seed_sources
from tests.test_admin_kb import ADMIN, BASE, REVIEWER

PDF = b"%PDF-1.4 fake citrus guideline"


def client_for(handler: httpx.MockTransport) -> httpx.AsyncClient:
    return httpx.AsyncClient(transport=handler, follow_redirects=True)


async def source(session: AsyncSession, key: str) -> KbSource:
    await seed_sources(session)
    row = await session.scalar(select(KbSource).where(KbSource.key == key))
    assert row is not None
    return row


async def test_a_fetched_document_is_hashed_and_marked_ok(engine: AsyncEngine) -> None:
    seen: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(str(request.url))
        return httpx.Response(200, content=PDF)

    async with async_sessionmaker(engine)() as session:
        src = await source(session, "ccri_monthly_january")
        async with client_for(httpx.MockTransport(handler)) as client:
            outcome = await fetch_source(session, src, client)
        assert outcome.status == "ok"
        assert seen == [src.url]
        assert src.fetch_status == "ok"
        assert src.content_hash == hashlib.sha256(PDF).hexdigest()
        assert src.fetch_bytes == len(PDF)
        assert src.fetched_at is not None
        assert src.fetch_error is None


async def test_a_blocked_host_is_recorded_not_faked(engine: AsyncEngine) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(403, text="host not allowed")

    async with async_sessionmaker(engine)() as session:
        src = await source(session, "niphm_ipm_citrus")
        async with client_for(httpx.MockTransport(handler)) as client:
            outcome = await fetch_source(session, src, client)
        assert outcome.status == "fetch_failed"
        assert src.fetch_status == "fetch_failed"
        assert "403" in (src.fetch_error or "")
        assert src.content_hash is None


async def test_network_errors_and_oversize_documents_fail_cleanly(
    engine: AsyncEngine,
) -> None:
    def boom(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("proxy refused", request=request)

    def huge(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, content=b"x" * (MAX_DOCUMENT_BYTES + 1))

    async with async_sessionmaker(engine)() as session:
        src = await source(session, "pau_fruit_drop")
        async with client_for(httpx.MockTransport(boom)) as client:
            assert (await fetch_source(session, src, client)).status == "fetch_failed"
        assert "proxy refused" in (src.fetch_error or "")
        async with client_for(httpx.MockTransport(huge)) as client:
            assert (await fetch_source(session, src, client)).status == "fetch_failed"
        assert "too large" in (src.fetch_error or "")


async def test_a_later_failure_keeps_the_last_good_hash(engine: AsyncEngine) -> None:
    ok = httpx.MockTransport(lambda _: httpx.Response(200, content=PDF))
    down = httpx.MockTransport(lambda _: httpx.Response(503))
    async with async_sessionmaker(engine)() as session:
        src = await source(session, "nhb_citrus_pht")
        async with client_for(ok) as client:
            await fetch_source(session, src, client)
        good = src.content_hash
        async with client_for(down) as client:
            await fetch_source(session, src, client)
        assert src.fetch_status == "fetch_failed"
        assert src.content_hash == good  # an old copy is still the best evidence we have


async def test_fetch_all_skips_datasets_and_internal_only_pages(engine: AsyncEngine) -> None:
    calls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(str(request.url))
        return httpx.Response(200, content=PDF)

    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        async with client_for(httpx.MockTransport(handler)) as client:
            outcomes = await fetch_all(session, client)
        keys = {o.key for o in outcomes}
        assert "ccri_monthly_march" in keys
        assert "cibrc_fungicides_2024" in keys
        assert not any(k.startswith("ds_") for k in keys)  # image datasets: never fetched
        assert "kcc_transcripts" not in keys  # internal_only
        assert len(calls) == len(outcomes)
        only = await fetch_all(
            session, client_for(httpx.MockTransport(handler)), only=["pdkv_recom_2017"]
        )
        assert [o.key for o in only] == ["pdkv_recom_2017"]


async def test_admin_uploads_a_document_the_server_could_not_fetch(
    client: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await session.commit()
    res = await client.put(
        f"{BASE}/sources/ppqs_banned_restricted/document",
        headers={**ADMIN, "Content-Type": "application/pdf"},
        content=PDF,
    )
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["fetch_status"] == "uploaded"
    assert body["content_hash"] == hashlib.sha256(PDF).hexdigest()
    listed = (await client.get(f"{BASE}/sources", headers=ADMIN)).json()["sources"]
    row = next(s for s in listed if s["key"] == "ppqs_banned_restricted")
    assert row["fetch_status"] == "uploaded"
    assert row["fetched_at"] is not None


async def test_upload_is_admin_only_and_validated(
    client: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await session.commit()
    url = f"{BASE}/sources/ppqs_banned_restricted/document"
    assert (await client.put(url, content=PDF)).status_code == 401
    assert (await client.put(url, headers=REVIEWER, content=PDF)).status_code == 403
    missing = await client.put(
        f"{BASE}/sources/{uuid.uuid4().hex}/document", headers=ADMIN, content=PDF
    )
    assert missing.status_code == 404
    empty = await client.put(url, headers=ADMIN, content=b"")
    assert empty.status_code == 422
    big = await client.put(url, headers=ADMIN, content=b"x" * (MAX_DOCUMENT_BYTES + 1))
    assert big.status_code == 413
