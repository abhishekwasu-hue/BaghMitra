"""Classifier and summariser adapters (addendum v1.4 §4.3-4.4).

Both sit behind Protocols so the pipeline can run with a fake in tests. The real adapter
calls the Anthropic Messages API over httpx and is OFF unless FEED_AI_API_KEY is set
(`ai_adapters` returns None). The prompts demand "quote or `not_stated`"; whatever comes back
still goes through `output_check` and the human review gate before anything is published.
"""

from __future__ import annotations

import asyncio
import json
import re
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from typing import Annotated, Any, Protocol

import httpx
from fastapi import Depends

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.feed.article import (
    ARTICLE_PROMPT,
    ARTICLE_SCHEMA,
    ArticleError,
    ArticleSet,
    parse_articles,
)
from bagmitra_api.feed.knowledge_article import (
    KNOWLEDGE_PROMPT,
    KNOWLEDGE_SCHEMA,
    KnowledgeError,
    KnowledgeSet,
    parse_knowledge,
)
from bagmitra_api.feed.output_check import NOT_STATED
from bagmitra_api.feed.pdf_transcribe import (
    TRANSCRIBE_EFFORT,
    TRANSCRIBE_PROMPT,
    TRANSCRIBE_SCHEMA,
    Transcription,
    TranscriptionError,
    batch_content,
    batches,
    joined,
    parse_transcription,
    render_pages,
)

ANTHROPIC_VERSION = "2026-10-21"
# Server-side refusal fallback (summariser model only; Haiku has none).
FALLBACK_BETA = "server-side-fallback-2026-07-01"
# Room for a short JSON answer plus the model's (low-effort) thinking.
SMALL_JSON_MAX_TOKENS = 2000
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


class AiRefusedError(AiUnavailableError):
    """The model (and its fallback) declined the request: asking again does not help."""


class AiCutOffError(AiUnavailableError):
    """The answer was cut off at max_tokens: the same request would be cut off again."""


class AiBadAnswerError(AiUnavailableError):
    """The model answered, but not in the asked shape: not an outage, so not retried."""


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


class FeedArticleWriter(Protocol):
    async def write_article(self, text: str, *, source_url: str) -> ArticleSet: ...


class KnowledgeWriter(Protocol):
    async def write_knowledge(self, text: str, *, topic: str) -> KnowledgeSet: ...


CLASSIFY_PROMPT = f"""You sort Maharashtra government documents (GRs, circulars, notices) for an
app used by orange and sweet-lime farmers. Read the document and answer with one JSON object
only, no other text:
{{"relevant": true|false, "kind": one of {list(ITEM_KINDS)}, "categories": a list from
{list(CATEGORIES)}, "crops": [crop names written in the document], "districts": [district
names written in the document]}}
"relevant" is true if the document changes something for farmers (a scheme, a payment or
relief, a deadline, an insurance window, a pesticide or fertiliser rule), or if it gives useful
farming knowledge for Maharashtra / Vidarbha farmers (an advisory on horticulture and any fruit
crop such as orange, mango, banana, pomegranate, grapes or guava, vegetables, soil, water,
weather, pests and diseases, markets or post-harvest handling). Administrative transfers,
budgets, staff matters and politics are not relevant. List only crops and districts that
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


async def _streamed(
    http: httpx.AsyncClient, url: str, headers: dict[str, str], body: dict[str, Any], wait: float
) -> tuple[str, str | None]:
    """The text deltas and the stop reason of a streamed answer (server-sent events). With
    the refusal fallback, a fallback model continues on the same stream after any partial
    text, so the deltas joined are the whole answer."""
    texts: list[str] = []
    stop: str | None = None
    async with http.stream(
        "POST", url, headers=headers, json={**body, "stream": True}, timeout=wait
    ) as response:
        if response.status_code != httpx.codes.OK:
            raise AiUnavailableError(f"HTTP {response.status_code}")
        async for line in response.aiter_lines():
            if not line.startswith("data:"):
                continue
            event = json.loads(line[5:])
            kind = event.get("type")
            if kind == "error":
                raise AiUnavailableError(f"stream error: {event.get('error', {}).get('type')}")
            if kind == "content_block_delta" and event["delta"].get("type") == "text_delta":
                texts.append(event["delta"].get("text", ""))
            elif kind == "message_delta":
                stop = event.get("delta", {}).get("stop_reason") or stop
    return "".join(texts), stop


async def messages_text(  # noqa: PLR0913 - the one Messages API call of the repo
    http: httpx.AsyncClient,
    *,
    base_url: str,
    headers: dict[str, str],
    body: dict[str, Any],
    fallback: bool,
    read_seconds: float,
    stream: bool = False,
) -> str:
    """POST /v1/messages and the answer's text; AiUnavailableError for a transport error or a
    non-200 status, AiRefusedError for a refusal, AiCutOffError for an answer cut off at
    max_tokens (both subclasses). With `fallback`, the server-side refusal fallback beta
    routes a declined request to the default fallback. `stream` reads the answer as
    server-sent events (a long answer: no idle HTTP wait of many minutes)."""
    if fallback:
        headers = {**headers, "anthropic-beta": FALLBACK_BETA}
        body = {**body, "fallbacks": "default"}
    url = f"{base_url.rstrip('/')}/v1/messages"
    try:
        if stream:
            text, stop = await _streamed(http, url, headers, body, read_seconds)
        else:
            response = await http.post(url, headers=headers, json=body, timeout=read_seconds)
            if response.status_code != httpx.codes.OK:
                raise AiUnavailableError(f"HTTP {response.status_code}")
            payload = response.json()
            stop = payload.get("stop_reason")
            blocks = payload.get("content", [])
            text = "".join(b.get("text", "") for b in blocks if b.get("type") == "text")
    except httpx.HTTPError as exc:
        raise AiUnavailableError(f"{type(exc).__name__}: {exc}") from exc
    except (ValueError, KeyError, AttributeError) as exc:
        raise AiUnavailableError(f"unreadable answer: {type(exc).__name__}") from exc
    if stop == "refusal":
        raise AiRefusedError("model declined the request")
    if stop == "max_tokens":
        raise AiCutOffError("answer cut off at max_tokens")
    return text


class AnthropicFeedAi:
    """Classifier (cheap model) and summariser (stronger model) over the Messages API."""

    def __init__(self, http: httpx.AsyncClient, settings: Settings) -> None:
        self._http = http
        self._settings = settings

    async def _ask(  # noqa: PLR0913 - one request shape for every prompt
        self,
        model: str,
        system: str,
        text: str,
        *,
        fallback: bool,
        max_tokens: int | None = None,
        source_url: str | None = None,
        schema: dict[str, Any] | None = None,
        wait_seconds: float | None = None,
        question: str | None = None,
        effort: str | None = None,
    ) -> str:
        s = self._settings
        headers = {
            "x-api-key": s.feed_ai_api_key.get_secret_value(),
            "anthropic-version": ANTHROPIC_VERSION,
            "content-type": "application/json",
        }
        body: dict[str, Any] = {
            "model": model,
            "max_tokens": max_tokens or s.feed_ai_max_tokens,
            "system": system,
            "messages": [
                {
                    "role": "user",
                    "content": (
                        (f"<source_url>{source_url}</source_url>\n" if source_url else "")
                        + f"<document>\n{text[: s.feed_ai_max_source_chars]}\n</document>"
                        + (f"\n{question}" if question else "")
                    ),
                }
            ],
        }
        if schema is not None:
            # Structured outputs: the answer is JSON matching the schema (no broken JSON).
            body["output_config"] = {"format": {"type": "json_schema", "schema": schema}}
        if effort is not None:
            body["output_config"] = {**body.get("output_config", {}), "effort": effort}
        return await messages_text(
            self._http,
            base_url=s.feed_ai_base_url,
            headers=headers,
            body=body,
            fallback=fallback,
            read_seconds=wait_seconds or s.feed_ai_timeout_seconds,
        )

    async def classify(self, text: str) -> Classification:
        answer = await self._ask(
            self._settings.feed_classify_model, CLASSIFY_PROMPT, text, fallback=False
        )
        return parse_classification(_json_object(answer))

    async def write_article(self, text: str, *, source_url: str) -> ArticleSet:
        """Spec v1.6: the article set (mr / hi / en) for one news source page."""
        s = self._settings
        answer = await self._ask(
            s.feed_summarise_model,
            ARTICLE_PROMPT,
            text,
            fallback=True,
            max_tokens=s.feed_article_max_tokens,
            source_url=source_url,
            schema=ARTICLE_SCHEMA,
            wait_seconds=s.feed_article_timeout_seconds,
        )
        try:
            return parse_articles(_json_object(answer))
        except ArticleError as exc:
            raise AiUnavailableError(f"article JSON: {exc}") from exc

    async def write_knowledge(self, text: str, *, topic: str) -> KnowledgeSet:
        """Owner 2026-11-11: one knowledge article set (mr / hi / en) from the cards' checked
        texts and their sources' passages (or an official item's text) only."""
        s = self._settings
        answer = await self._ask(
            s.feed_summarise_model,
            KNOWLEDGE_PROMPT,
            text,
            fallback=True,
            max_tokens=s.feed_article_max_tokens,
            schema=KNOWLEDGE_SCHEMA,
            wait_seconds=s.feed_article_timeout_seconds,
            question=f"<topic>{topic}</topic>",
        )
        try:
            return parse_knowledge(_json_object(answer))
        except KnowledgeError as exc:
            raise AiUnavailableError(f"knowledge JSON: {exc}") from exc

    async def ask_json(
        self, system: str, text: str, *, question: str, schema: dict[str, Any], max_tokens: int
    ) -> dict[str, Any]:
        """One structured-output answer from the stronger model (Q128 card check)."""
        s = self._settings
        answer = await self._ask(
            s.feed_summarise_model,
            system,
            text,
            fallback=True,
            max_tokens=max_tokens,
            schema=schema,
            wait_seconds=s.feed_article_timeout_seconds,
            question=question,
        )
        return _json_object(answer)

    async def ask_small_json(
        self,
        system: str,
        text: str,
        *,
        schema: dict[str, Any],
        max_tokens: int = SMALL_JSON_MAX_TOKENS,
    ) -> dict[str, Any]:
        """One short structured-output answer from the cheap classify model at low effort
        (Q139 topic threads: "same topic as thread X, or new"; Q150 news headline filter)."""
        answer = await self._ask(
            self._settings.feed_classify_model,
            system,
            text,
            fallback=False,
            max_tokens=max_tokens,
            schema=schema,
            effort="low",
        )
        return _json_object(answer)

    async def transcribe_pdf(self, data: bytes) -> Transcription:
        """Owner 2026-11-13 (Q152, image mode Q155): the visible text of a legacy-font PDF,
        transcribed by the model from its rendered pages (image blocks, at most
        IMAGES_PER_REQUEST a request; the batches joined in page order). Streamed: a long GR
        takes minutes. RenderError (no request made) when the pages cannot be rendered."""
        s = self._settings
        model = s.feed_pdf_transcribe_model or s.feed_summarise_model
        pages = await asyncio.to_thread(
            render_pages, data, max_pages=s.feed_pdf_transcribe_max_pages
        )
        headers = {
            "x-api-key": s.feed_ai_api_key.get_secret_value(),
            "anthropic-version": ANTHROPIC_VERSION,
            "content-type": "application/json",
        }
        parts: list[Transcription] = []
        first = 1
        for batch in batches(pages):
            body: dict[str, Any] = {
                "model": model,
                "max_tokens": s.feed_pdf_transcribe_max_tokens,
                "system": TRANSCRIBE_PROMPT,
                "messages": [{"role": "user", "content": batch_content(batch, first, len(pages))}],
                "output_config": {
                    "format": {"type": "json_schema", "schema": TRANSCRIBE_SCHEMA},
                    "effort": TRANSCRIBE_EFFORT,
                },
            }
            answer = await messages_text(
                self._http,
                base_url=s.feed_ai_base_url,
                headers=headers,
                body=body,
                fallback=True,
                read_seconds=s.feed_pdf_transcribe_timeout_seconds,
                stream=True,
            )
            try:
                parts.append(parse_transcription(_json_object(answer), model=model))
            except (AiUnavailableError, TranscriptionError) as exc:
                raise AiBadAnswerError(f"transcription JSON: {exc}") from exc
            first += len(batch)
        return joined(parts, model=model)

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
