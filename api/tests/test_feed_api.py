"""Addendum v1.4 G0/G1 server: feed_admin manual upload, review queue, output check gate,
approve / publish / withdraw, AI draft (fake adapters only) and the public GET /v1/feed."""

from __future__ import annotations

import base64
import hashlib
import uuid
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import Farmer, Plot
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.ai import AiUnavailableError, Classification, FeedAi, Summary, get_feed_ai
from bagmitra_api.feed.extract import OcrError, OcrResult, get_feed_ocr
from bagmitra_api.feed.models import FeedItem, FeedReviewEvent, FeedSource
from bagmitra_api.feed.seed import seed_feed_sources
from bagmitra_api.main import create_app
from tests.conftest import make_token
from tests.feed_docs import HTML, KRUTI_DEV, make_pdf

ADMIN_BASE = "/v1/admin/feed"
ADMIN = {
    "Authorization": f"Bearer {make_token(uuid.uuid4(), app_metadata={'roles': ['feed_admin']})}"
}
TODAY = datetime.now(UTC).date()
GR_TEXT = (
    "शासन निर्णय क्रमांक: फळबाग-२०२५/प्र.क्र.४५/११-अ, दिनांक २६ ऑक्टोबर २०२६. "
    "भाऊसाहेब फुंडकर फळबाग लागवड योजना: प्रति हेक्टर ₹ १,००,००० अनुदान. "
    f"अर्जाची अंतिम मुदत {(TODAY + timedelta(days=30)).strftime('%d/%m/%Y')}."
)
PDF = b"%PDF-1.4 fake GR for tests"


class FakeAi:
    def __init__(
        self, *, relevant: bool = True, summary: str = "Subsidy ₹1,00,000 per ha."
    ) -> None:
        self.relevant = relevant
        self.summary = summary

    async def classify(self, text: str) -> Classification:  # noqa: ARG002
        return Classification(relevant=self.relevant, kind="scheme", districts=["Nagpur"])

    async def summarise(self, text: str) -> Summary:  # noqa: ARG002
        fields: dict[str, dict[str, str | None]] = {
            "amount": {"value": "₹ १,००,०००", "page": "p. 1"},
            "documents": {"value": "not_stated", "page": None},
        }
        return Summary(title="Fruit planting subsidy", summary=self.summary, fields=fields)


class BrokenAi(FakeAi):
    async def classify(self, text: str) -> Classification:  # noqa: ARG002
        raise AiUnavailableError("HTTP 529")


@pytest.fixture
async def ai_box() -> dict[str, Any]:
    return {"ai": None}


class FakeOcr:
    def __init__(self, text: str = "", confidence: float = 90.0, *, fail: bool = False) -> None:
        self.text, self.confidence, self.fail = text, confidence, fail
        self.calls = 0

    def ocr_pdf(self, data: bytes) -> OcrResult:
        self.calls += 1
        assert data.startswith(b"%PDF")
        if self.fail:
            raise OcrError("tesseract failed: TimeoutExpired")
        return OcrResult(self.text, self.confidence, 1)


@pytest.fixture
async def ocr_box() -> dict[str, Any]:
    return {"ocr": None}


@pytest.fixture
async def api(
    settings: Settings, engine: AsyncEngine, ai_box: dict[str, Any], ocr_box: dict[str, Any]
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker

    async def fake_ai() -> AsyncIterator[FeedAi | None]:
        ai = ai_box["ai"]
        yield FeedAi(classifier=ai, summariser=ai) if ai else None

    app.dependency_overrides[get_feed_ai] = fake_ai
    app.dependency_overrides[get_feed_ocr] = lambda: ocr_box["ocr"]
    async with maker() as session:
        await seed_feed_sources(session)
        session.add(
            FeedSource(
                id=uuid.uuid4(),
                key="test_news",
                name="A news outlet (test)",
                url="https://news.example",
                tier="news",
                fetch_method="rss",
            )
        )
        await session.commit()
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


def gr_body(**extra: Any) -> dict[str, Any]:
    body: dict[str, Any] = {
        "source_key": "mh_gr_portal",
        "type": "scheme",
        "published_at": "2026-10-26T00:00:00Z",
        "url": "https://gr.maharashtra.gov.in/Upload/PDF/202610261500000001.pdf",
        "external_id": "202610261500000001",
        "gr_number": "फळबाग-२०२५/प्र.क्र.४५/११-अ",
        "department": "Agriculture",
        "deadline": (TODAY + timedelta(days=30)).isoformat(),
        "extracted_text": GR_TEXT,
        "document_base64": base64.b64encode(PDF).decode(),
        "document_type": "pdf",
        "texts": {
            "en": {"title": "Fruit planting subsidy", "summary": "₹1 lakh per hectare."},
            "mr": {"title": "फळबाग लागवड अनुदान", "summary": "प्रति हेक्टर ₹१ लाख."},
        },
        "card": {"amount": {"value": "₹1,00,000 per ha", "page": "p. 1"}},
        "targets": [{"district": "Nagpur", "crop": "santra", "min_ha": 1, "max_ha": 5}],
    }
    body.update(extra)
    return body


async def create(api: httpx.AsyncClient, **extra: Any) -> dict[str, Any]:
    res = await api.post(f"{ADMIN_BASE}/items", json=gr_body(**extra), headers=ADMIN)
    assert res.status_code == 201, res.text
    data: dict[str, Any] = res.json()
    return data


async def approve_publish(api: httpx.AsyncClient, item_id: str) -> dict[str, Any]:
    res = await api.post(f"{ADMIN_BASE}/items/{item_id}/approve", json={}, headers=ADMIN)
    assert res.status_code == 200, res.text
    res = await api.post(f"{ADMIN_BASE}/items/{item_id}/publish", headers=ADMIN)
    assert res.status_code == 200, res.text
    data: dict[str, Any] = res.json()
    return data


async def add_farmer(engine: AsyncEngine, user_id: uuid.UUID, district: str | None) -> None:
    now = datetime.now(UTC)
    async with async_sessionmaker(engine)() as session:
        session.add(
            Farmer(id=user_id, language="mr", district=district, client_updated_at=now, last_seq=1)
        )
        for crop, area in (("santra", 15_000.0), ("santra", 5_000.0)):
            session.add(
                Plot(
                    id=uuid.uuid4(),
                    owner_id=user_id,
                    name="Plot",
                    crop=crop,
                    area_sq_m=area,
                    client_updated_at=now,
                    last_seq=1,
                )
            )
        await session.commit()


async def test_roles_are_required(api: httpx.AsyncClient, auth_headers: dict[str, str]) -> None:
    assert (await api.get(f"{ADMIN_BASE}/items")).status_code == 401
    res = await api.get(f"{ADMIN_BASE}/items", headers=auth_headers)
    assert res.status_code == 403
    assert (await api.get("/v1/feed")).status_code == 401


async def test_sources_registry_and_terms(api: httpx.AsyncClient) -> None:
    sources = (await api.get(f"{ADMIN_BASE}/sources", headers=ADMIN)).json()["sources"]
    seeded = [s for s in sources if s["key"] != "test_news"]
    assert len(seeded) >= 9
    assert {s["terms_status"] for s in seeded} == {"unknown"}
    res = await api.put(
        f"{ADMIN_BASE}/sources/mh_gr_portal/terms",
        json={"terms_status": "disallowed", "notes": "ToS forbids automated access"},
        headers=ADMIN,
    )
    assert res.json()["fetch_status"] == "disallowed"
    assert res.json()["notes"] == "ToS forbids automated access"
    res = await api.put(
        f"{ADMIN_BASE}/sources/mh_gr_portal/terms", json={"terms_status": "allowed"}, headers=ADMIN
    )
    assert (res.json()["terms_status"], res.json()["fetch_status"]) == ("allowed", "not_fetched")
    res = await api.put(
        f"{ADMIN_BASE}/sources/nope/terms", json={"terms_status": "allowed"}, headers=ADMIN
    )
    assert res.status_code == 404


async def test_upload_review_publish_and_feed(
    api: httpx.AsyncClient, engine: AsyncEngine, user_id: uuid.UUID, auth_headers: dict[str, str]
) -> None:
    item = await create(api)
    assert item["status"] == "in_review"
    assert item["trust"] == "official"
    assert item["raw_hash"] == hashlib.sha256(PDF).hexdigest()
    assert item["raw_bytes"] == len(PDF)
    assert item["check_issues"] == []
    assert item["card"] == {
        "version": 1,
        "fields": {"amount": {"value": "₹1,00,000 per ha", "page": "p. 1"}},
    }
    queue = (await api.get(f"{ADMIN_BASE}/items", headers=ADMIN)).json()["items"]
    assert [q["id"] for q in queue] == [item["id"]]
    assert queue[0]["title"] == "Fruit planting subsidy"

    # Not shown before publishing.
    assert (await api.get("/v1/feed", headers=auth_headers)).json()["items"] == []
    published = await approve_publish(api, item["id"])
    assert published["status"] == "published"
    assert [e["kind"] for e in published["events"]] == ["created", "approved", "published"]

    await add_farmer(engine, user_id, "Nagpur")
    res = await api.get("/v1/feed?lang=mr", headers=auth_headers)
    assert res.status_code == 200
    body = res.json()
    assert body["footer"].startswith("कोणतीही कृती")
    [shown] = body["items"]
    assert set(shown) == {
        "id", "type", "trust", "title", "summary", "department", "gr_number", "published_at",
        "url", "deadline", "valid_to", "replaced_by", "may_be_eligible_because",
        "seen",
    }  # fmt: skip
    assert shown["title"] == "फळबाग लागवड अनुदान"
    assert shown["trust"] == "official"
    assert shown["replaced_by"] is None
    assert len(shown["may_be_eligible_because"]) == 3
    en = (await api.get("/v1/feed", headers=auth_headers)).json()
    assert en["footer"] == "Check the official GR/portal before acting."
    assert all("may be eligible" in r for r in en["items"][0]["may_be_eligible_because"])

    for query, count in (
        ("type=official", 1),
        ("type=scheme", 1),
        ("type=deadline", 1),
        ("type=news", 0),
        ("district=Nagpur&crop=santra", 1),
        ("district=Amravati", 0),
        ("crop=mosambi", 0),
    ):
        items = (await api.get(f"/v1/feed?{query}", headers=auth_headers)).json()["items"]
        assert len(items) == count, query


async def test_hallucinated_amount_forces_review(api: httpx.AsyncClient) -> None:
    texts = {"en": {"title": "Fruit planting subsidy", "summary": "₹2 lakh per hectare."}}
    item = await create(api, texts=texts)
    assert item["check_issues"] == [{"kind": "amount", "text": "₹2 lakh", "where": "en.summary"}]
    assert item["events"][-1]["kind"] == "output_check_failed"
    url = f"{ADMIN_BASE}/items/{item['id']}"
    res = await api.post(f"{url}/approve", json={}, headers=ADMIN)
    assert (res.status_code, res.json()["error"]["code"]) == (409, "check_issues_open")
    res = await api.post(f"{url}/approve", json={"accept_check_issues": True}, headers=ADMIN)
    assert res.status_code == 422
    # Fixing the text clears the issue.
    res = await api.put(
        f"{url}/texts/en", json={"title": "Subsidy", "summary": "₹1 lakh per ha."}, headers=ADMIN
    )
    assert res.json()["check_issues"] == []
    # Or the reviewer accepts explicitly with a reason (e.g. a scanned PDF without text).
    await api.put(f"{url}/texts/hi", json={"title": "अनुदान ₹9"}, headers=ADMIN)
    res = await api.post(
        f"{url}/approve",
        json={"accept_check_issues": True, "comment": "amount read on the scanned page 2"},
        headers=ADMIN,
    )
    assert res.status_code == 200
    assert res.json()["approved"] is True


async def test_hallucinated_deadline_is_caught(api: httpx.AsyncClient) -> None:
    item = await create(api, deadline=(TODAY + timedelta(days=31)).isoformat())
    assert [i["where"] for i in item["check_issues"]] == ["deadline"]


async def test_publish_blockers(api: httpx.AsyncClient) -> None:
    item = await create(
        api,
        document_base64=None,
        document_type=None,
        texts={"mr": {"title": "फळबाग"}},
        external_id=None,
    )
    url = f"{ADMIN_BASE}/items/{item['id']}"
    res = await api.post(f"{url}/publish", headers=ADMIN)
    assert res.status_code == 409
    message = res.json()["error"]["message"]
    assert "not approved" in message
    assert "English text missing" in message
    assert "without the source document hash" in message
    ended = (TODAY - timedelta(days=1)).isoformat()
    expired = await create(
        api,
        external_id="x2",
        valid_to=ended,
        document_base64=None,
        document_type=None,
        extracted_text=f"{GR_TEXT} {ended}",
    )
    url = f"{ADMIN_BASE}/items/{expired['id']}"
    await api.post(f"{url}/approve", json={}, headers=ADMIN)
    res = await api.post(f"{url}/publish", headers=ADMIN)
    assert "validity already ended" in res.json()["error"]["message"]


async def test_upload_validation(api: httpx.AsyncClient) -> None:
    await create(api)
    cases: list[tuple[dict[str, Any], int, str]] = [
        ({}, 409, "duplicate_document"),
        ({"document_base64": None, "document_type": None}, 409, "duplicate_item"),
        ({"source_key": "nope"}, 404, "source_not_found"),
        ({"document_base64": "***", "external_id": "n1"}, 422, "invalid_document"),
        ({"document_type": None, "external_id": "n2"}, 422, "invalid_document"),
        ({"document_base64": "", "external_id": "n3"}, 422, "invalid_document"),
        ({"type": "gr", "external_id": "n4", "document_base64": None}, 422, "invalid_item"),
        ({"type": "news", "external_id": "n5"}, 422, "news_text_not_stored"),
        (
            {"type": "news", "external_id": "n6", "extracted_text": None, "document_base64": None},
            422,
            "invalid_item",
        ),
    ]
    for extra, status, code in cases:
        res = await api.post(f"{ADMIN_BASE}/items", json=gr_body(**extra), headers=ADMIN)
        assert (res.status_code, res.json()["error"]["code"]) == (status, code), extra


async def test_document_size_limit(api: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("bagmitra_api.routers.admin_feed.MAX_DOCUMENT_BYTES", 4)
    res = await api.post(f"{ADMIN_BASE}/items", json=gr_body(), headers=ADMIN)
    assert res.status_code == 413


async def test_news_trust_and_feed(api: httpx.AsyncClient, auth_headers: dict[str, str]) -> None:
    news = await create(
        api,
        type="news",
        source_key="mh_gr_portal",
        external_id="news-1",
        extracted_text=None,
        document_base64=None,
        document_type=None,
        card=None,
        targets=[],
        texts={"en": {"title": "Headline", "summary": "Our own 2-line summary, 5 points."}},
    )
    assert news["trust"] == "news"
    assert news["check_issues"] == []  # article text is never stored, so review is the check
    await approve_publish(api, news["id"])
    # A GR-type item from a news-tier source is still trust news.
    other = await create(
        api, type="gr", source_key="test_news", external_id="n-2", card=None, targets=[]
    )
    assert other["trust"] == "news"
    items = (await api.get("/v1/feed?type=news", headers=auth_headers)).json()["items"]
    assert [(i["trust"], i["title"]) for i in items] == [("news", "Headline")]
    assert (await api.get("/v1/feed?type=official", headers=auth_headers)).json()["items"] == []


async def test_withdraw_shows_replacement_and_edits_go_back_to_review(
    api: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    old = await create(api)
    await approve_publish(api, old["id"])
    new = await create(
        api,
        external_id="new",
        document_base64=base64.b64encode(b"%PDF new").decode(),
    )
    await approve_publish(api, new["id"])
    url = f"{ADMIN_BASE}/items/{old['id']}/withdraw"
    for body, status in (
        ({"reason": "x", "replaced_by_id": old["id"]}, 422),
        ({"reason": "x", "replaced_by_id": str(uuid.uuid4())}, 404),
        ({"reason": "superseded", "replaced_by_id": new["id"]}, 200),
        ({"reason": "again"}, 409),
    ):
        assert (await api.post(url, json=body, headers=ADMIN)).status_code == status
    items = (await api.get("/v1/feed", headers=auth_headers)).json()["items"]
    assert {i["id"]: i["replaced_by"] for i in items} == {new["id"]: None, old["id"]: new["id"]}
    # Deadline cards only list live items, not withdrawn ones.
    deadlines = (await api.get("/v1/feed?type=deadline", headers=auth_headers)).json()["items"]
    assert [i["id"] for i in deadlines] == [new["id"]]
    res = await api.put(
        f"{ADMIN_BASE}/items/{old['id']}/texts/en", json={"title": "x"}, headers=ADMIN
    )
    assert res.status_code == 409

    # Editing a published item takes it off the feed until it is approved again.
    res = await api.put(
        f"{ADMIN_BASE}/items/{new['id']}/targets", json={"targets": [{"crop": "mosambi"}]},
        headers=ADMIN,
    )  # fmt: skip
    assert (res.json()["status"], res.json()["approved"]) == ("in_review", False)
    assert res.json()["targets"] == [
        {"district": None, "crop": "mosambi", "min_ha": None, "max_ha": None}
    ]
    items = (await api.get("/v1/feed", headers=auth_headers)).json()["items"]
    assert [i["id"] for i in items] == [old["id"]]
    res = await api.post(f"{ADMIN_BASE}/items/{new['id']}/publish", headers=ADMIN)
    assert res.status_code == 409
    res = await api.post(f"{ADMIN_BASE}/items/{old['id']}/approve", json={}, headers=ADMIN)
    assert res.json()["error"]["code"] == "not_in_review"


async def test_expired_schemes_are_hidden(
    api: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    item = await create(api)
    await approve_publish(api, item["id"])
    async with async_sessionmaker(engine)() as session:
        row = await session.get(FeedItem, uuid.UUID(item["id"]))
        assert row is not None
        row.deadline = TODAY - timedelta(days=1)
        await session.commit()
    assert (await api.get("/v1/feed", headers=auth_headers)).json()["items"] == []


async def test_card_versions_and_detail(api: httpx.AsyncClient) -> None:
    item = await create(api)
    url = f"{ADMIN_BASE}/items/{item['id']}"
    res = await api.put(
        f"{url}/card",
        json={"fields": {"amount": {"value": "₹1,00,000"}, "deadline": {"value": "not_stated"}}},
        headers=ADMIN,
    )
    assert res.json()["card"]["version"] == 2
    assert res.json()["check_issues"] == [
        {"kind": "missing_page", "text": "₹1,00,000", "where": "card.amount"}
    ]
    detail = (await api.get(url, headers=ADMIN)).json()
    assert detail["source_key"] == "mh_gr_portal"
    assert detail["has_text"] is True
    assert (await api.get(f"{ADMIN_BASE}/items/{uuid.uuid4()}", headers=ADMIN)).status_code == 404
    gr = await create(api, type="gr", external_id="g", card=None, document_base64=None)
    res = await api.put(
        f"{ADMIN_BASE}/items/{gr['id']}/card", json={"fields": {"a": {"value": "1"}}}, headers=ADMIN
    )
    assert res.status_code == 422
    drafts = (await api.get(f"{ADMIN_BASE}/items?status=draft", headers=ADMIN)).json()
    assert drafts == {"items": []}


async def test_ai_draft(
    api: httpx.AsyncClient, ai_box: dict[str, Any], engine: AsyncEngine
) -> None:
    item = await create(api, texts={})
    url = f"{ADMIN_BASE}/items/{item['id']}/ai-draft"
    res = await api.post(url, headers=ADMIN)
    assert (res.status_code, res.json()["error"]["code"]) == (503, "ai_off")

    ai_box["ai"] = FakeAi()
    res = await api.post(url, headers=ADMIN)
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["texts"]["en"] == {
        "title": "Fruit planting subsidy",
        "summary": "Subsidy ₹1,00,000 per ha.",
    }
    assert body["card"]["version"] == 2
    assert body["check_issues"] == []
    assert body["status"] == "in_review"
    assert [e["kind"] for e in body["events"]][-3:] == ["classified", "summarised", "edited"]

    ai_box["ai"] = FakeAi(summary="Subsidy ₹5,00,000 per ha by 01/01/2030.")
    body = (await api.post(url, headers=ADMIN)).json()
    assert {i["kind"] for i in body["check_issues"]} == {"amount", "date"}

    gr = await create(api, type="gr", external_id="g2", card=None, document_base64=None)
    res = await api.post(f"{ADMIN_BASE}/items/{gr['id']}/ai-draft", headers=ADMIN)
    assert res.json()["card"] is None

    ai_box["ai"] = FakeAi(relevant=False)
    res = await api.post(url, headers=ADMIN)
    assert res.json()["status"] == "draft"

    ai_box["ai"] = BrokenAi()
    res = await api.post(url, headers=ADMIN)
    assert (res.status_code, res.json()["error"]["code"]) == (503, "ai_unavailable")

    empty = await create(api, external_id="e", extracted_text=None, document_base64=None)
    res = await api.post(f"{ADMIN_BASE}/items/{empty['id']}/ai-draft", headers=ADMIN)
    assert (res.status_code, res.json()["error"]["code"]) == (409, "no_text")

    async with async_sessionmaker(engine)() as session:
        kinds = set(await session.scalars(select(FeedReviewEvent.kind)))
    assert {"created", "classified", "summarised", "output_check_failed"} <= kinds


def test_today_is_a_date() -> None:
    assert isinstance(TODAY, date)


# --- document extraction on upload (addendum §4 step 2, QG2) --------------------------------


def upload(document: bytes, document_type: str = "pdf", **extra: Any) -> dict[str, Any]:
    return {
        "extracted_text": None,
        "document_base64": base64.b64encode(document).decode(),
        "document_type": document_type,
        **extra,
    }


def extraction(item: dict[str, Any]) -> dict[str, Any]:
    found: list[dict[str, Any]] = [e["detail"] for e in item["events"] if e["kind"] == "extracted"]
    assert len(found) == 1
    return found[0]


async def stored_text(engine: AsyncEngine, item_id: str) -> str | None:
    async with async_sessionmaker(engine)() as session:
        item = await session.get(FeedItem, uuid.UUID(item_id))
        assert item is not None
        return item.extracted_text


async def test_uploaded_pdf_text_is_the_checked_source(
    api: httpx.AsyncClient, engine: AsyncEngine, ocr_box: dict[str, Any]
) -> None:
    ocr_box["ocr"] = ocr = FakeOcr()
    item = await create(api, **upload(make_pdf([GR_TEXT], unicode=True)))
    assert (item["has_text"], item["check_issues"]) == (True, [])
    detail = extraction(item)
    assert (detail["method"], detail["quality"], detail["used"]) == ("pdf_text", "ok", "pdf_text")
    assert (detail["pages"], detail["ocr"], detail["issues"]) == (1, None, [])
    assert detail["devanagari_ratio"] > 0.9
    assert "text_layer" not in detail
    assert "भाऊसाहेब फुंडकर फळबाग" in (await stored_text(engine, item["id"]) or "")
    assert ocr.calls == 0
    # The output check reads the extracted text: an invented amount is caught.
    bad = {"en": {"title": "Fruit planting subsidy", "summary": "₹2 lakh per hectare."}}
    item = await create(
        api, external_id="x2", texts=bad, **upload(make_pdf([GR_TEXT + " "], unicode=True))
    )
    assert item["check_issues"] == [{"kind": "amount", "text": "₹2 lakh", "where": "en.summary"}]


async def test_given_text_wins_over_extraction(api: httpx.AsyncClient) -> None:
    item = await create(api, document_base64=base64.b64encode(make_pdf([KRUTI_DEV])).decode())
    assert [e["kind"] for e in item["events"]] == ["created"]
    assert item["check_issues"] == []


async def test_broken_marathi_stays_in_review_with_a_reason(
    api: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    item = await create(api, **upload(make_pdf([KRUTI_DEV])))
    assert (item["status"], item["has_text"]) == ("in_review", False)
    issue = item["check_issues"][0]
    assert (issue["kind"], issue["where"]) == ("text_broken", "document")
    assert "legacy Marathi font" in issue["text"]
    detail = extraction(item)
    assert (detail["quality"], detail["used"], detail["ocr"]) == ("broken", None, None)
    assert "fu.kZ;" in detail["text_layer"]  # the broken text layer is kept for the reviewer
    assert await stored_text(engine, item["id"]) is None
    url = f"{ADMIN_BASE}/items/{item['id']}"
    res = await api.post(f"{url}/approve", json={}, headers=ADMIN)
    assert (res.status_code, res.json()["error"]["code"]) == (409, "check_issues_open")
    # The issue survives later checks (an edit re-runs the output check).
    res = await api.put(f"{url}/texts/en", json={"title": "Fruit planting"}, headers=ADMIN)
    assert res.json()["check_issues"][0]["kind"] == "text_broken"
    res = await api.post(
        f"{url}/approve",
        json={"accept_check_issues": True, "comment": "read from the printed GR"},
        headers=ADMIN,
    )
    assert res.status_code == 200


async def test_scanned_pdf_uses_ocr_and_keeps_both(
    api: httpx.AsyncClient, engine: AsyncEngine, ocr_box: dict[str, Any]
) -> None:
    ocr_box["ocr"] = FakeOcr(GR_TEXT, 88.5)
    item = await create(api, **upload(make_pdf([""])))
    assert (item["has_text"], item["check_issues"]) == (True, [])
    detail = extraction(item)
    assert (detail["quality"], detail["used"], detail["text_layer"]) == ("empty", "ocr", None)
    assert detail["ocr"]["confidence"] == 88.5
    assert detail["ocr"]["quality"] == "ok"
    assert await stored_text(engine, item["id"]) == GR_TEXT


async def test_low_ocr_confidence_is_flagged(
    api: httpx.AsyncClient, engine: AsyncEngine, ocr_box: dict[str, Any]
) -> None:
    ocr_box["ocr"] = FakeOcr(GR_TEXT, 41.0)
    item = await create(api, **upload(make_pdf([KRUTI_DEV])))
    assert [i["kind"] for i in item["check_issues"]] == ["ocr_low_confidence"]
    assert "41" in item["check_issues"][0]["text"]
    detail = extraction(item)
    assert (detail["quality"], detail["used"]) == ("broken", "ocr")
    assert "fu.kZ;" in detail["text_layer"]
    assert await stored_text(engine, item["id"]) == GR_TEXT


@pytest.mark.parametrize(
    ("ocr", "kept"),
    [(FakeOcr(KRUTI_DEV), "ocr_text"), (FakeOcr(fail=True), "error")],
)
async def test_ocr_without_usable_text(
    api: httpx.AsyncClient, ocr_box: dict[str, Any], ocr: FakeOcr, kept: str
) -> None:
    ocr_box["ocr"] = ocr
    item = await create(api, **upload(make_pdf([""])))
    issue = item["check_issues"][0]
    assert issue["kind"] == "text_empty"
    assert "and OCR" in issue["text"]
    detail = extraction(item)
    assert detail["used"] is None
    if kept == "error":
        assert "TimeoutExpired" in detail["ocr"]["error"]
    else:
        assert detail["ocr"]["quality"] == "broken"
        assert "fu.kZ;" in detail["ocr"]["text"]


async def test_uploaded_html_text(
    api: httpx.AsyncClient, engine: AsyncEngine, ocr_box: dict[str, Any]
) -> None:
    ocr_box["ocr"] = ocr = FakeOcr(GR_TEXT)
    item = await create(api, **upload(HTML.encode(), "html"))
    detail = extraction(item)
    assert (detail["method"], detail["quality"], detail["used"]) == ("html", "ok", "html")
    text = await stored_text(engine, item["id"])
    assert text is not None
    assert "१,००,००० अनुदान" in text
    assert "99,99,999" not in text
    broken = await create(
        api, external_id="h2", **upload(b"<p>" + KRUTI_DEV.encode() + b"</p>", "html")
    )
    assert broken["check_issues"][0]["kind"] == "text_broken"
    assert ocr.calls == 0  # OCR is for PDFs only
