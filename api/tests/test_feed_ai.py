"""Addendum v1.4 §4.3-4.4: the AI adapters are off without FEED_AI_API_KEY, send the
configured models with the quote-or-not_stated prompt, and never reach a real API in tests
(httpx.MockTransport answers instead)."""

from __future__ import annotations

import json
from typing import Any

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import (
    CARD_FIELDS,
    AiUnavailableError,
    AnthropicFeedAi,
    get_feed_ai,
    parse_classification,
    parse_summary,
)


def _settings(**extra: Any) -> Settings:
    return Settings(environment="test", feed_ai_api_key="sk-test-not-real", **extra)


def _ai(handler: Any, settings: Settings | None = None) -> AnthropicFeedAi:
    http = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    return AnthropicFeedAi(http, settings or _settings())


def _answer(text: str, stop_reason: str = "end_turn") -> httpx.Response:
    content = [{"type": "thinking", "thinking": ""}, {"type": "text", "text": text}]
    return httpx.Response(200, json={"content": content, "stop_reason": stop_reason})


async def test_off_without_key() -> None:
    gen = get_feed_ai(Settings(environment="test"))
    assert await anext(gen) is None
    with pytest.raises(StopAsyncIteration):
        await anext(gen)


async def test_on_with_key() -> None:
    gen = get_feed_ai(_settings())
    ai = await anext(gen)
    assert ai is not None
    assert isinstance(ai.classifier, AnthropicFeedAi)
    with pytest.raises(StopAsyncIteration):
        await anext(gen)


async def test_classify_uses_cheap_model_and_parses() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return _answer(
            'Here: {"relevant": true, "kind": "scheme", "categories": ["deadline", "x"],'
            ' "crops": ["orange", 3], "districts": ["Nagpur", " "]}'
        )

    result = await _ai(handler).classify("GR text")
    assert result.relevant
    assert result.kind == "scheme"
    assert result.categories == ["deadline"]
    assert result.crops == ["orange"]
    assert result.districts == ["Nagpur"]
    body = json.loads(seen[0].content)
    assert body["model"] == "claude-haiku-5-5"
    assert "fallbacks" not in body
    assert seen[0].headers["x-api-key"] == "sk-test-not-real"
    assert seen[0].headers["anthropic-version"]
    assert str(seen[0].url) == "https://api.anthropic.com/v1/messages"
    assert "never guess" in body["system"]


async def test_summarise_uses_summarise_model_and_quote_or_not_stated_prompt() -> None:
    seen: list[dict[str, Any]] = []
    answer = {
        "title": "Fruit planting subsidy",
        "summary": "Subsidy of ₹1,00,000 per ha.",
        "fields": {"amount": {"value": "₹1,00,000", "page": "p. 2"}, "deadline": None},
    }

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(json.loads(request.content))
        return _answer(json.dumps(answer, ensure_ascii=False))

    settings = _settings(feed_summarise_model="claude-sonnet-x", feed_ai_max_source_chars=5)
    result = await _ai(handler, settings).summarise("0123456789")
    assert seen[0]["model"] == "claude-sonnet-x"
    assert seen[0]["fallbacks"] == "default"
    assert "not_stated" in seen[0]["system"]
    assert "01234\n" in seen[0]["messages"][0]["content"]
    assert "56789" not in seen[0]["messages"][0]["content"]
    assert result.fields["amount"] == {"value": "₹1,00,000", "page": "p. 2"}
    assert result.fields["deadline"] == {"value": "not_stated", "page": None}
    assert set(result.fields) == set(CARD_FIELDS)


@pytest.mark.parametrize(
    ("response", "message"),
    [
        (httpx.Response(529, json={}), "HTTP 529"),
        (_answer("no json here"), "without a JSON"),
        (_answer("{broken"), "without a JSON"),
        (_answer("{'single': 1}"), "invalid JSON"),
        (_answer("{}", stop_reason="refusal"), "declined"),
    ],
)
async def test_unusable_answers_raise(response: httpx.Response, message: str) -> None:
    with pytest.raises(AiUnavailableError, match=message):
        await _ai(lambda _: response).classify("x")


async def test_network_error_raises() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("down", request=request)

    with pytest.raises(AiUnavailableError, match="ConnectError"):
        await _ai(handler).summarise("x")


def test_parse_helpers_are_strict() -> None:
    assert parse_classification({"kind": "budget"}).kind == "gr"
    assert parse_classification({"relevant": "yes"}).relevant is False
    with pytest.raises(AiUnavailableError):
        parse_summary({"title": " ", "summary": "x"})
    summary = parse_summary({"title": "T", "summary": "S", "fields": "nope"})
    assert all(f == {"value": "not_stated", "page": None} for f in summary.fields.values())
    summary = parse_summary(
        {"title": "T", "summary": "S", "fields": {"amount": {"value": "₹5", "page": 3}}}
    )
    assert summary.fields["amount"] == {"value": "₹5", "page": None}
