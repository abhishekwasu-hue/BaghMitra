"""Crop guides (पीक मार्गदर्शक, owner 2026-11-14, Q160): every checkable fact of a guide line
(sowing windows, durations, spacing, seed rates, varieties' numbers) is in the source passage
the line keeps (`quote`), by the feed's output check; the quote itself is checked against the
fetched source by `card_check --quotes` (the card-sources workflow). No network here."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import httpx

from bagmitra_api.feed.output_check import check_output
from bagmitra_api.kb.card_check import check_quotes

GUIDES = Path(__file__).resolve().parents[2] / "app" / "assets" / "config" / "crop_guides.json"


def _items() -> list[dict[str, Any]]:
    data = json.loads(GUIDES.read_text(encoding="utf-8"))
    return [i for c in data["crops"] for s in c["sections"] for i in s["items"]]


def test_every_number_of_a_line_is_in_its_source_passage() -> None:
    items = _items()
    assert len(items) > 50
    misses = [
        f"{i['id']} {m.where}: {m.text}"
        for i in items
        for m in check_output(i["quote"], i["labels"])
    ]
    assert misses == []


def test_every_line_keeps_a_quote_and_known_sources() -> None:
    data = json.loads(GUIDES.read_text(encoding="utf-8"))
    for i in _items():
        assert i["quote"].strip(), i["id"]
        assert i["source_keys"], i["id"]
        for key in i["source_keys"]:
            assert key in data["sources"], (i["id"], key)
    for source in data["sources"].values():
        assert source["url"].startswith("https://")
        assert source["checked"]


async def test_quote_check_finds_a_quote_or_a_number_not_in_the_source() -> None:
    page = b"<html><body><p>Sow rainfed chickpea from 15th Oct. to 04th Nov.</p></body></html>"

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, content=page, headers={"content-type": "text/html"})

    guides = {
        "sources": {"S": {"url": "https://example.org/s"}},
        "crops": [
            {
                "sections": [
                    {
                        "items": [
                            {
                                "id": "ok",
                                "labels": {"en": "Sow from 15 Oct. to 04 Nov."},
                                "source_keys": ["S"],
                                "quote": "Sow rainfed chickpea from 15th Oct. to 04th Nov.",
                            },
                            {
                                "id": "made-up",
                                "labels": {"en": "Sow by 30 Nov."},
                                "source_keys": ["S"],
                                "quote": "Sow chickpea by 30th Nov.",
                            },
                            {
                                "id": "number",
                                "labels": {"en": "Sow from 15 Oct. to 20 Nov."},
                                "source_keys": ["S"],
                                "quote": "Sow rainfed chickpea from 15th Oct. to 04th Nov.",
                            },
                        ]
                    }
                ]
            }
        ],
    }
    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        problems, failed = await check_quotes(guides, http)
    assert failed == {}
    assert set(problems) == {"made-up", "number"}
    assert problems["made-up"] == "quote not in the cited sources"
    assert problems["number"].startswith("numbers not in the quote")
