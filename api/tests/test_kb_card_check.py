"""Q128 (owner 2026-11-09): the AI, not a human expert, checks every knowledge-card point
against its cited source. Nothing here reaches the network or Anthropic (MockTransport)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import httpx

from bagmitra_api.core.settings import Settings
from bagmitra_api.kb.card_check import (
    CHECK_PROMPT,
    AiPointChecker,
    Point,
    check_cards,
    fetch_text,
    iter_points,
    passages_for,
    quote_in_source,
    report,
)

SOURCE_HTML = (
    b"<html><body><h1>Foot rot or gummosis</h1><p>Provide drainage channels 60 cm wide and"
    b" 30 cm deep between rows.</p><p>Apply Bordeaux paste up to 60 cm of the trunk.</p>"
    b"</body></html>"
)
CARDS: dict[str, Any] = {
    "sources": {
        "C02": {"url": "https://www.nhb.gov.in/pdf/fruits/citrus/cit002.pdf"},
        "GONE": {"url": "https://blocked.example/x"},
    },
    "sections": [
        {
            "key": "phytophthora",
            "profile": {
                "symptoms": {
                    "labels": {"en": "Gum oozes from the trunk."},
                    "source_keys": ["C02"],
                }
            },
            "items": [
                {
                    "id": 19,
                    "labels": {
                        "en": "Dig a drainage channel 60 cm wide x 30 cm deep between rows.",
                        "mr": "दोन ओळींमध्ये ६० सें.मी. रुंद x ३० सें.मी. खोल चर खणा.",
                    },
                    "source": 'C02 "Foot Rot" (60 x 30 cm)',
                    "source_keys": ["C02"],
                },
                {
                    "id": 20,
                    "labels": {"en": "Paint Bordeaux paste up to 90 cm of the trunk."},
                    "source_keys": ["C02", "GONE"],
                },
            ],
        }
    ],
    "preparations": {"paste": {"labels": {"en": "Bordeaux paste."}, "source_keys": ["C02"]}},
}


def http() -> httpx.AsyncClient:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "blocked.example":
            return httpx.Response(403)
        return httpx.Response(200, content=SOURCE_HTML)

    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


class FakeChecker:
    def __init__(self, answers: dict[str, tuple[str, str]]) -> None:
        self.answers = answers
        self.calls: list[tuple[str, list[str]]] = []

    async def check(self, passages: str, points: list[Point]) -> dict[str, tuple[str, str]]:
        self.calls.append((passages, [p.id for p in points]))
        return self.answers


def test_every_cited_text_is_a_point() -> None:
    names = [p.id for p in iter_points(CARDS)]
    assert names == [
        "sections.phytophthora.profile.symptoms",
        "item 19",
        "item 20",
        "preparations.paste",
    ]


async def test_a_supported_point_passes_and_a_wrong_number_fails() -> None:
    checker = FakeChecker(
        {
            "item 19": ("supported", "drainage channels 60 cm wide and 30 cm deep"),
            "item 20": ("supported", "Apply Bordeaux paste up to 60 cm of the trunk."),
        }
    )
    results, failed, _ = await check_cards(CARDS, http(), checker, limit=60_000)
    by_id = {r.point.id: r for r in results}
    assert by_id["item 19"].passed
    # 90 cm is not in the source: the number check fails the point whatever the AI says.
    assert not by_id["item 20"].passed
    assert any("90" in i for i in by_id["item 20"].number_issues)
    assert by_id["item 20"].verdicts["GONE"] == ("unreadable", "")
    assert failed == {"GONE": "HTTP 403"}
    # Every point citing C02 was asked in one call for that source.
    assert checker.calls[0][1] == [
        "sections.phytophthora.profile.symptoms",
        "item 19",
        "item 20",
        "preparations.paste",
    ]


async def test_a_quote_not_in_the_source_is_not_trusted() -> None:
    checker = FakeChecker({"item 19": ("supported", "Channels must be one metre deep.")})
    results, _, _ = await check_cards(CARDS, http(), checker, limit=60_000)
    item = next(r for r in results if r.point.id == "item 19")
    # Reported apart from not_found, with the model's own verdict kept for the reader.
    assert item.verdicts["C02"] == (
        "unverified_quote",
        "[model: supported] Channels must be one metre deep.",
    )
    assert item.verdict == "unverified_quote"
    assert not item.passed


async def test_without_a_key_only_the_numbers_are_checked() -> None:
    results, _, _ = await check_cards(CARDS, http(), None, limit=60_000)
    assert {r.verdict for r in results} == {"not_checked", "unreadable"}
    item = next(r for r in results if r.point.id == "item 19")
    assert item.number_issues == []  # the Marathi digits are 60 and 30 too


async def test_the_report_lists_failures_first_and_unread_sources() -> None:
    results, failed, read = await check_cards(
        CARDS, http(), FakeChecker({"item 19": ("supported", "60 cm wide")}), limit=60_000
    )
    text = report(results, failed, read)
    assert "Points: 4 · passed: 1" in text
    rows = [line for line in text.splitlines() if line.startswith("| item")]
    assert rows[-1].startswith("| item 19 ")
    assert "✅" in rows[-1]
    assert "- GONE: HTTP 403" in text
    assert "## Characters read per source" in text
    assert read["C02"] > 100


def test_long_sources_send_the_passages_that_match_the_points() -> None:
    filler = "Unrelated text about mango storage. " * 400
    text = filler + "Gummosis: drainage channel between rows. " + filler
    point = Point("item 1", {"en": "Dig a drainage channel between rows for gummosis."}, ("X",))
    chosen = passages_for(text, [point], limit=8000)
    assert "drainage channel between rows" in chosen
    assert len(chosen) <= 8000
    assert passages_for("short", [point], limit=8000) == "short"


def test_quotes_match_across_spacing_case_and_line_breaks() -> None:
    assert quote_in_source(
        "Provide drainage-channels\n60 CM wide", "provide drainage channels 60 cm wide"
    )
    assert not quote_in_source("", "anything")
    # A quote shortened with an ellipsis counts when every part is in the source.
    source = "Provide drainage channels 60 cm wide and 30 cm deep between rows."
    assert quote_in_source("Provide drainage channels … 30 cm deep between rows", source)
    assert not quote_in_source("Provide drainage channels ... 90 cm deep", source)
    assert not quote_in_source("…", source)


async def test_the_ai_request_uses_the_strong_model_and_a_schema(tmp_path: Path) -> None:
    seen: list[dict[str, Any]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(json.loads(request.content))
        text = json.dumps({"points": [{"id": "item 19", "verdict": "supported", "quote": "q"}]})
        return httpx.Response(200, json={"content": [{"type": "text", "text": text}]})

    settings = Settings(environment="test", feed_ai_api_key="sk-test-not-real")
    checker = AiPointChecker(httpx.AsyncClient(transport=httpx.MockTransport(handler)), settings)
    point = Point("item 19", {"en": "Dig a drainage channel."}, ("C02",), "C02 (60 cm)")
    assert await checker.check("passages", [point]) == {"item 19": ("supported", "q")}
    body = seen[0]
    assert body["model"] == settings.feed_summarise_model
    assert body["system"] == CHECK_PROMPT
    assert body["output_config"]["format"]["type"] == "json_schema"
    content = body["messages"][0]["content"]
    assert "<document>\npassages\n</document>" in content
    assert "item 19: Dig a drainage channel. (cited as: C02 (60 cm))" in content
    for rule in ("cited as", "judge only the part", "is supported, not contradicted", "…"):
        assert rule in CHECK_PROMPT


# Card check 2026-11-10: Vikaspedia pages gave 60-81 characters (a JavaScript app shell). The
# article is in the same HTML, in the Next.js data block (props.pageProps.ssrPageContent.content).
VIKASPEDIA = (
    "<html><body><div id='__next'>Loading</div>"
    '<script id="__NEXT_DATA__" type="application/json">'
    + json.dumps(
        {
            "props": {
                "pageProps": {
                    "ssrPageContent": {
                        "title": "Citrus aphid",
                        "content": "<p>Development is best at 20 to 25 &deg;C.</p>",
                    }
                }
            }
        }
    )
    + "</script></body></html>"
)


async def test_a_next_js_page_is_read_from_its_data_block() -> None:
    transport = httpx.MockTransport(lambda _: httpx.Response(200, text=VIKASPEDIA))
    async with httpx.AsyncClient(transport=transport) as client:
        text, reason = await fetch_text(client, "https://en.vikaspedia.in/viewcontent/x")
    assert reason is None
    assert "Development is best at 20 to 25" in text
    assert "Loading" not in text


async def test_a_plain_page_is_read_as_before() -> None:
    transport = httpx.MockTransport(lambda _: httpx.Response(200, content=SOURCE_HTML))
    async with httpx.AsyncClient(transport=transport) as client:
        text, reason = await fetch_text(client, "https://www.nhb.gov.in/x")
    assert reason is None
    assert "drainage channels 60 cm wide" in text
