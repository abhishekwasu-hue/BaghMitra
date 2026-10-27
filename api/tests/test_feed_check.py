"""Addendum v1.4 §2 / G3: "Check this message" for pasted forwards.

The matcher is table-driven against official items; it never calls a message fake, only says
whether a matching official item exists in BagMitra. The pasted text is never stored and only
its length and the verdict are logged.
"""

from __future__ import annotations

import base64
import uuid
from collections.abc import Mapping, Sequence
from datetime import date
from typing import Any

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker
from structlog.testing import capture_logs

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.base import Base
from bagmitra_api.feed.check import (
    MAX_TEXT_CHARS,
    NOTES,
    Candidate,
    RateLimiter,
    check_message,
    note,
)
from bagmitra_api.feed.models import FeedItem
from tests.conftest import JWT_SECRET, make_token
from tests.test_feed_api import (
    ADMIN,
    ADMIN_BASE,
    ai_box,
    api,
    approve_publish,
    create,
    ocr_box,
)

__all__ = ["ai_box", "api", "ocr_box"]  # fixtures used here
GLOSSARY = Settings().feed_scheme_glossary
FALBAG = Candidate(
    id=uuid.uuid4(),
    titles={
        "en": "Bhausaheb Fundkar Falbag Lagvad subsidy",
        "mr": "भाऊसाहेब फुंडकर फळबाग लागवड अनुदान",
    },
    summaries=("प्रति हेक्टर ₹१,००,००० अनुदान.", "Subsidy ₹1,00,000 per hectare."),
    gr_number="फळबाग-२०२५/प्र.क्र.४५/११-अ",
    external_id="202610261500000001",
    published=date(2026, 10, 26),
    dates=frozenset({date(2026, 12, 31)}),
    url="https://gr.maharashtra.gov.in/1.pdf",
)
NAMO = Candidate(
    id=uuid.uuid4(),
    titles={"en": "Namo Shetkari Mahasanman Nidhi instalment released"},
    summaries=("₹2,000 to each eligible farmer.",),
    gr_number=None,
    external_id="202610201000000009",
    published=date(2026, 10, 20),
    dates=frozenset(),
    url="https://gr.maharashtra.gov.in/2.pdf",
)
RELIEF = Candidate(
    id=uuid.uuid4(),
    titles={"en": "Relief for crop loss due to unseasonal rain"},
    summaries=(),
    gr_number="12",  # too short to be matched on its own
    external_id=None,
    published=date(2026, 9, 1),
    dates=frozenset(),
    url="https://gr.maharashtra.gov.in/3.pdf",
)
CANDIDATES = (FALBAG, NAMO, RELIEF)


def run(text: str, candidates: Sequence[Candidate] = CANDIDATES) -> tuple[str, list[uuid.UUID]]:
    result = check_message(text, candidates, glossary=GLOSSARY)
    return result.verdict, [m.candidate.id for m in result.matches]


@pytest.mark.parametrize(
    ("text", "verdict", "first"),
    [
        # GR number as printed, Devanagari digits.
        ("शासन निर्णय क्र. फळबाग-२०२५/प्र.क्र.४५/११-अ नुसार अनुदान", "official_match", FALBAG),
        # Same GR number with ASCII digits and extra spaces.
        ("GR No. फळबाग - 2025 / प्र.क्र. 45 / 11-अ is out", "official_match", FALBAG),
        # The portal's unique code.
        ("Download: 202610261500000001.pdf", "official_match", FALBAG),
        # Title + publication date.
        ("भाऊसाहेब फुंडकर फळबाग लागवड अनुदान दिनांक २६/१०/२०२६", "official_match", FALBAG),
        # Title + amount in lakh form (= ₹1,00,000).
        (
            "Bhausaheb Fundkar Falbag Lagvad subsidy of ₹1 lakh per hectare",
            "official_match",
            FALBAG,
        ),
        # Title + a deadline date in words.
        ("Fundkar Falbag Lagvad subsidy: apply by 31 December 2026", "official_match", FALBAG),
        # Title only: similar, not confirmed.
        ("Bhausaheb Fundkar Falbag Lagvad subsidy", "possible_match", FALBAG),
        # Spelling variants of the Marathi title (फूंडकर, फळबागा) still found.
        ("भाऊसाहेब फूंडकर फळबागा लागवड अनुदान", "possible_match", FALBAG),
        # Scheme alias (Marathi name of an English-titled item) + amount.
        ("नमो शेतकरी महासन्मान निधी चा हप्ता ₹२,००० जमा", "possible_match", NAMO),
        ("Namo Shetkari Mahasanman Nidhi instalment released: ₹2,000", "official_match", NAMO),
    ],
)
def test_matches(text: str, verdict: str, first: Candidate) -> None:
    got, ids = run(text)
    assert got == verdict
    assert ids[0] == first.id


@pytest.mark.parametrize(
    "text",
    [
        "Free tractors for everyone, forward to 10 groups!",
        "१२ लोकांना बक्षीस",  # the short GR number "12" alone is not a match
        "!!! ??? ...",
        "",
    ],
)
def test_no_official_match(text: str) -> None:
    assert run(text) == ("no_official_match", [])


def test_amount_that_differs_is_never_an_official_match() -> None:
    result = check_message(
        "भाऊसाहेब फुंडकर फळबाग लागवड अनुदान ₹५०,००० दिनांक २६/१०/२०२६",
        CANDIDATES,
        glossary=GLOSSARY,
    )
    assert result.verdict == "possible_match"
    [best, *_] = result.matches
    assert best.details_differ
    # Even with the exact GR number, a different amount is only a possible match.
    result = check_message("फळबाग-२०२५/प्र.क्र.४५/११-अ: ₹५ लाख", CANDIDATES, glossary=GLOSSARY)
    assert result.verdict == "possible_match"
    assert result.matches[0].exact
    assert result.matches[0].details_differ


def test_ranking_scores_and_limit() -> None:
    twins = [
        Candidate(
            id=uuid.uuid4(),
            titles={"en": f"Relief for crop loss due to unseasonal rain phase {n}"},
            summaries=(),
            gr_number=None,
            external_id=None,
            published=date(2026, 9, n),
            dates=frozenset(),
            url=f"https://x.example/{n}",
        )
        for n in range(1, 6)
    ]
    result = check_message(
        "Relief for crop loss due to unseasonal rain phase 3", twins, glossary=None, limit=3
    )
    assert len(result.matches) == 3
    assert result.matches[0].candidate.id == twins[2].id  # "3" only in its title
    scores = [m.score for m in result.matches]
    assert scores == sorted(scores, reverse=True)
    assert all(0 < s <= 1 for s in scores)


def test_candidate_without_titles_is_ignored() -> None:
    empty = Candidate(
        id=uuid.uuid4(),
        titles={},
        summaries=(),
        gr_number=None,
        external_id=None,
        published=date(2026, 1, 1),
        dates=frozenset(),
        url="https://x.example",
    )
    assert run("anything at all 01/01/2026", [empty]) == ("no_official_match", [])


def test_long_text_is_cut_not_failed() -> None:
    text = "Bhausaheb Fundkar Falbag Lagvad subsidy " + "x " * MAX_TEXT_CHARS
    assert run(text)[0] == "possible_match"


FORBIDDEN = ("fake", "false", "fraud", "खोटा", "खोटे", "बनावट", "फसवा", "फर्जी", "नकली", "झूठ")


@pytest.mark.parametrize("lang", ["en", "mr", "hi"])
def test_notes_never_say_fake(lang: str) -> None:
    for verdict in NOTES:
        text = note(verdict, lang)
        assert text
        assert not any(word in text.lower() for word in FORBIDDEN)
    assert note("no_official_match", "en") == (
        "No matching official GR found in BagMitra. Check the official portal before acting."
    )


def test_note_falls_back_to_english() -> None:
    assert note("possible_match", "ta") == note("possible_match", "en")


def test_rate_limiter_sliding_window() -> None:
    now = [0.0]
    limiter = RateLimiter(limit=2, window_seconds=60, clock=lambda: now[0], max_keys=2)
    assert limiter.allow("a")
    assert limiter.allow("a")
    assert not limiter.allow("a")
    assert limiter.allow("b")  # per key
    now[0] = 61.0
    assert limiter.allow("a")  # window slid
    limiter.allow("c")  # more keys than max_keys: idle ones are dropped
    assert set(limiter.keys()) <= {"a", "c"}
    with pytest.raises(ValueError, match="limit"):
        RateLimiter(limit=0, window_seconds=1)


# --- API -----------------------------------------------------------------------------------


@pytest.fixture
def settings() -> Settings:
    return Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="INFO",
        feed_check_rate_limit=4,
    )


def farmer() -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}


async def post_check(
    api: httpx.AsyncClient, text: str, headers: Mapping[str, str], lang: str = "en"
) -> httpx.Response:
    return await api.post(
        "/v1/feed/check", params={"lang": lang}, json={"text": text}, headers=dict(headers)
    )


async def row_counts(engine: AsyncEngine) -> dict[str, int]:
    async with async_sessionmaker(engine)() as session:
        return {
            name: int(await session.scalar(select(func.count()).select_from(table)) or 0)
            for name, table in Base.metadata.tables.items()
        }


async def test_check_api_official_match(api: httpx.AsyncClient, engine: AsyncEngine) -> None:
    published = await create(api)
    await approve_publish(api, published["id"])
    await create(
        api,
        external_id="in-review-only",
        url="https://gr.example/2.pdf",
        document_base64=base64.b64encode(b"%PDF-1.4 another").decode(),
    )
    before = await row_counts(engine)
    text = "फळबाग-२०२५/प्र.क्र.४५/११-अ: प्रति हेक्टर ₹१ लाख अनुदान"
    with capture_logs() as logs:
        res = await post_check(api, text, farmer(), lang="mr")
    assert res.status_code == 200, res.text
    body: dict[str, Any] = res.json()
    assert body["verdict"] == "official_match"
    [match] = body["matches"]
    assert match == {
        "id": published["id"],
        "title": "फळबाग लागवड अनुदान",
        "gr_number": "फळबाग-२०२५/प्र.क्र.४५/११-अ",
        "published_at": "2026-10-26T00:00:00Z",
        "url": "https://gr.maharashtra.gov.in/Upload/PDF/202610261500000001.pdf",
        "score": 1.0,
    }
    assert body["note"] == note("official_match", "mr")
    # Privacy: nothing stored, only length + verdict logged.
    assert await row_counts(engine) == before
    [entry] = [e for e in logs if e["event"] == "feed.check"]
    assert entry == {
        "event": "feed.check",
        "log_level": "info",
        "length": len(text),
        "verdict": "official_match",
    }
    assert not any(text in str(e) for e in logs)


async def test_check_api_only_published_official_items(
    api: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    item = await create(api)  # in review: not official yet
    text = "Fruit planting subsidy GR फळबाग-२०२५/प्र.क्र.४५/११-अ"
    body = (await post_check(api, text, farmer())).json()
    assert body == {
        "verdict": "no_official_match",
        "matches": [],
        "note": note("no_official_match", "en"),
    }
    await approve_publish(api, item["id"])
    res = await api.post(
        f"{ADMIN_BASE}/items/{item['id']}/withdraw", json={"reason": "superseded"}, headers=ADMIN
    )
    assert res.status_code == 200, res.text
    assert (await post_check(api, text, farmer())).json()["verdict"] == "no_official_match"
    async with async_sessionmaker(engine)() as session:  # news is never "official"
        row = await session.get(FeedItem, uuid.UUID(item["id"]))
        assert row is not None
        row.status, row.trust_level, row.type = "published", "news", "news"
        await session.commit()
    assert (await post_check(api, text, farmer())).json()["verdict"] == "no_official_match"


async def test_check_api_hindi_possible_match(api: httpx.AsyncClient) -> None:
    item = await create(api)
    await approve_publish(api, item["id"])
    body = (await post_check(api, "Fruit planting subsidy", farmer(), lang="hi")).json()
    assert body["verdict"] == "possible_match"
    assert body["matches"][0]["title"] == "Fruit planting subsidy"  # no hi text: English
    assert body["note"] == note("possible_match", "hi")


async def test_check_api_auth_validation_and_rate_limit(api: httpx.AsyncClient) -> None:
    assert (await api.post("/v1/feed/check", json={"text": "x"})).status_code == 401
    user = farmer()
    assert (await post_check(api, "", user)).status_code == 422
    assert (await post_check(api, "x" * (MAX_TEXT_CHARS + 1), user)).status_code == 422
    for _ in range(4):
        assert (await post_check(api, "hello", user)).status_code == 200
    res = await post_check(api, "hello", user)
    assert res.status_code == 429
    assert res.json()["error"]["code"] == "rate_limited"
    assert (await post_check(api, "hello", farmer())).status_code == 200  # per user
