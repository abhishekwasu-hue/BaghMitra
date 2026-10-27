"""Classifier and summariser adapters (addendum v1.4 §4.3-4.4).

Both sit behind Protocols so the pipeline can run with a fake in tests. The real adapter
calls the Anthropic Messages API over httpx and is OFF unless FEED_AI_API_KEY is set
(`ai_adapters` returns None). The prompts demand "quote or `not_stated`"; whatever comes back
still goes through `output_check` and the human review gate before anything is published.
"""

from __future__ import annotations

import json
import re
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from typing import Annotated, Any, Protocol

import httpx
from fastapi import Depends

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.feed.output_check import NOT_STATED

ANTHROPIC_VERSION = "2026-10-21"
# Server-side refusal fallback (summariser model only; Haiku has none).
FALLBACK_BETA = "server-side-fallback-2026-07-01"
CARD_FIELDS = (
    "scheme_name",
    "who_benefits",
    "eligibility",
    "documents",
    "how_to_apply",
    "deadline",
    "amount",
    "gr_number",
    "gr_date",
)
ITEM_KINDS = ("gr", "circular", "scheme", "alert")
CATEGORIES = ("deadline", "payment", "new_scheme", "amendment", "cancellation", "other")


class AiUnavailableError(Exception):
    """The model could not be reached or answered with something unusable."""


@dataclass(frozen=True, slots=True)
class Classification:
    relevant: bool
    kind: str
    categories: list[str] = field(default_factory=list)
    crops: list[str] = field(default_factory=list)
    districts: list[str] = field(default_factory=list)


@dataclass(frozen=True, slots=True)
class Summary:
    title: str
    summary: str
    # {name: {"value": quoted text | "not_stated", "page": str | None}}
    fields: dict[str, dict[str, str | None]]


class FeedClassifier(Protocol):
    async def classify(self, text: str) -> Classification: ...


class FeedSummariser(Protocol):
    async def summarise(self, text: str) -> Summary: ...


CLASSIFY_PROMPT = f"""You sort Maharashtra government documents (GRs, circulars, notices) for an
app used by orange and sweet-lime farmers. Read the document and answer with one JSON object
only, no other text:
{{"relevant": true|false, "kind": one of {list(ITEM_KINDS)}, "categories": a list from
{list(CATEGORIES)}, "crops": [crop names written in the document], "districts": [district
names written in the document]}}
"relevant" is true only if the document changes something for farmers (a scheme, a payment or
relief, a deadline, an insurance window, a pesticide or fertiliser rule). Administrative
transfers, budgets and staff matters are not relevant. List only crops and districts that
the document names; never guess."""

SUMMARISE_PROMPT = f"""You prepare a review draft of a government document for farmers. Answer
with one JSON object only, no other text:
{{"title": short English title, "summary": one or two plain English sentences, "fields":
{{name: {{"value": ..., "page": ...}}}} for each name in {list(CARD_FIELDS)}}}
Rules:
- Every value must be quoted or copied from the document, with "page" naming where it is
  (for example "p. 2" or "para 4").
- If the document does not state a field, the value is "{NOT_STATED}" and "page" is null.
  Never infer, estimate or fill a gap from general knowledge.
- Copy numbers, amounts and dates exactly as the document writes them.
- The summary only repeats facts that are in the fields. Use "may be eligible", never
  "will receive". No advice and no opinion."""


def _json_object(text: str) -> dict[str, Any]:
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match is None:
        raise AiUnavailableError("model answered without a JSON object")
    try:
        value = json.loads(match.group(0))
    except json.JSONDecodeError as exc:
        raise AiUnavailableError(f"model answered with invalid JSON: {exc}") from exc
    if not isinstance(value, dict):  # pragma: no cover - the regex only matches objects
        raise AiUnavailableError("model answered with a non-object")
    return value


def _strings(value: object) -> list[str]:
    return (
        [v.strip() for v in value if isinstance(v, str) and v.strip()]
        if isinstance(value, list)
        else []
    )


def parse_classification(payload: dict[str, Any]) -> Classification:
    kind = payload.get("kind")
    return Classification(
        relevant=payload.get("relevant") is True,
        kind=kind if kind in ITEM_KINDS else "gr",
        categories=[c for c in _strings(payload.get("categories")) if c in CATEGORIES],
        crops=_strings(payload.get("crops")),
        districts=_strings(payload.get("districts")),
    )


def parse_summary(payload: dict[str, Any]) -> Summary:
    title, summary = payload.get("title"), payload.get("summary")
    if not isinstance(title, str) or not title.strip() or not isinstance(summary, str):
        raise AiUnavailableError("summary JSON lacks a title or summary")
    raw = payload.get("fields") if isinstance(payload.get("fields"), dict) else {}
    fields: dict[str, dict[str, str | None]] = {}
    for name in CARD_FIELDS:
        entry = raw.get(name) if isinstance(raw, dict) else None
        value = entry.get("value") if isinstance(entry, dict) else None
        page = entry.get("page") if isinstance(entry, dict) else None
        if not isinstance(value, str) or not value.strip() or value.strip() == NOT_STATED:
            fields[name] = {"value": NOT_STATED, "page": None}
        else:
            fields[name] = {"value": value.strip(), "page": page if isinstance(page, str) else None}
    return Summary(title=title.strip(), summary=summary.strip(), fields=fields)


class AnthropicFeedAi:
    """Classifier (cheap model) and summariser (stronger model) over the Messages API."""

    def __init__(self, http: httpx.AsyncClient, settings: Settings) -> None:
        self._http = http
        self._settings = settings

    async def _ask(self, model: str, system: str, text: str, *, fallback: bool) -> str:
        s = self._settings
        headers = {
            "x-api-key": s.feed_ai_api_key.get_secret_value(),
            "anthropic-version": ANTHROPIC_VERSION,
            "content-type": "application/json",
        }
        body: dict[str, Any] = {
            "model": model,
            "max_tokens": s.feed_ai_max_tokens,
            "system": system,
            "messages": [
                {
                    "role": "user",
                    "content": f"<document>\n{text[: s.feed_ai_max_source_chars]}\n</document>",
                }
            ],
        }
        if fallback:
            headers["anthropic-beta"] = FALLBACK_BETA
            body["fallbacks"] = "default"
        url = f"{s.feed_ai_base_url.rstrip('/')}/v1/messages"
        try:
            response = await self._http.post(
                url, headers=headers, json=body, timeout=s.feed_ai_timeout_seconds
            )
        except httpx.HTTPError as exc:
            raise AiUnavailableError(f"{type(exc).__name__}: {exc}") from exc
        if response.status_code != httpx.codes.OK:
            raise AiUnavailableError(f"HTTP {response.status_code}")
        payload = response.json()
        if payload.get("stop_reason") == "refusal":
            raise AiUnavailableError("model declined the request")
        texts = [b.get("text", "") for b in payload.get("content", []) if b.get("type") == "text"]
        return "".join(texts)

    async def classify(self, text: str) -> Classification:
        answer = await self._ask(
            self._settings.feed_classify_model, CLASSIFY_PROMPT, text, fallback=False
        )
        return parse_classification(_json_object(answer))

    async def summarise(self, text: str) -> Summary:
        answer = await self._ask(
            self._settings.feed_summarise_model, SUMMARISE_PROMPT, text, fallback=True
        )
        return parse_summary(_json_object(answer))


@dataclass(frozen=True, slots=True)
class FeedAi:
    classifier: FeedClassifier
    summariser: FeedSummariser


async def get_feed_ai(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[FeedAi | None]:
    """The configured adapters, or None while FEED_AI_API_KEY is empty (AI off)."""
    if not settings.feed_ai_api_key.get_secret_value():
        yield None
        return
    async with httpx.AsyncClient() as http:
        ai = AnthropicFeedAi(http, settings)
        yield FeedAi(classifier=ai, summariser=ai)
