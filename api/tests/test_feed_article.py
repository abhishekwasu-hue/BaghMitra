"""Spec v1.6 (owner Q127): the AI writes a professional article per language, and automated
checks alone decide whether it is published. Anthropic is never called (MockTransport)."""

from __future__ import annotations

import copy
import json
from typing import Any

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import AiUnavailableError, AnthropicFeedAi
from bagmitra_api.feed.article import (
    ARTICLE_PROMPT,
    ArticleError,
    check_articles,
    parse_articles,
)

SOURCE = (
    "मुंबई, दि. ५ नोव्हेंबर २०२६: राज्य शासनाने संत्रा उत्पादकांसाठी फळबाग योजनेत प्रति हेक्टर "
    "₹ ६,००० अनुदान जाहीर केले. अर्जाची अंतिम मुदत ३० नोव्हेंबर २०२६ आहे. नागपूर विभागात 60 टक्के, "
    "अमरावती विभागात 40 टक्के लाभार्थी आहेत. एकूण 1,200 शेतकरी पात्र. अर्ज mahadbt.maharashtra.gov.in "
    "वर करावा."
)
URL = "https://mahasamvad.in/12345/"


def _article(lang: str) -> dict[str, Any]:
    word = {"mr": "अनुदान", "hi": "अनुदान", "en": "subsidy"}[lang]
    body = f"{word} ₹ 6,000 per hectare; last date 30 November 2026. " * 8
    return {
        "headline": f"Orange growers: {word} ₹ 6,000 per hectare",
        "standfirst": "The state announced help for orange growers in the fruit orchard scheme.",
        "key_points": [
            f"{word} ₹ 6,000 per hectare",
            "Last date 30 November 2026",
            "1,200 eligible",
        ],
        "sections": [
            {"heading": "What was decided", "body": body},
            {"heading": "Who benefits", "body": "Orange growers in Nagpur and Amravati divisions."},
            {"heading": "What farmers can do next", "body": "Apply on the MahaDBT portal."},
        ],
        "facts": [
            {"label": "Amount", "value": "₹ 6,000 per hectare"},
            {"label": "Last date", "value": "30 November 2026"},
            {"label": "Eligible farmers", "value": "1,200"},
        ],
        "charts": [
            {
                "type": "pie",
                "title": "Beneficiaries by division",
                "unit": "%",
                "data": [{"label": "Nagpur", "value": 60}, {"label": "Amravati", "value": 40}],
            }
        ],
        "key_dates": [{"date": "2026-11-30", "label": "Last date to apply"}],
        "sources": [
            {"title": "Mahasamvad", "url": URL},
            {"title": "MahaDBT", "url": "https://mahadbt.maharashtra.gov.in/"},
        ],
    }


def payload(**changes: Any) -> dict[str, Any]:
    data: dict[str, Any] = {
        "relevant": True,
        "political": False,
        "lang": {lang: _article(lang) for lang in ("mr", "hi", "en")},
    }
    data.update(changes)
    return data


def issues(data: dict[str, Any]) -> list[str]:
    return check_articles(SOURCE, parse_articles(data), source_url=URL)


def test_a_sound_article_passes() -> None:
    result = parse_articles(payload())
    assert result.relevant
    assert not result.political
    assert set(result.articles) == {"mr", "hi", "en"}
    assert result.articles["mr"].charts[0].type == "pie"
    assert issues(payload()) == []


def test_an_invented_amount_is_caught() -> None:
    data = payload()
    data["lang"]["mr"]["key_points"][0] = "अनुदान ₹ 9,000 प्रति हेक्टर"
    assert any("9,000" in i for i in issues(data))


def test_languages_must_state_the_same_amounts_and_dates() -> None:
    data = payload()
    for part in ("headline", "key_points", "sections", "facts"):
        data["lang"]["en"][part] = copy.deepcopy(data["lang"]["en"][part])
    data["lang"]["en"]["headline"] = "Orange growers get help"
    data["lang"]["en"]["key_points"] = ["Help for orange growers", "Apply soon", "1,200 eligible"]
    data["lang"]["en"]["sections"][0]["body"] = "Orange growers get help from the state. " * 20
    data["lang"]["en"]["facts"] = [{"label": "Eligible farmers", "value": "1,200"}] * 3
    data["lang"]["en"]["key_dates"] = []
    assert any("languages" in i for i in issues(data))


def test_a_pie_must_add_up() -> None:
    data = payload()
    data["lang"]["hi"]["charts"][0]["data"][1]["value"] = 30
    assert any("pie" in i for i in issues(data))


def test_a_chart_value_must_be_in_the_source() -> None:
    data = payload()
    data["lang"]["en"]["charts"] = [
        {
            "type": "bar",
            "title": "Help",
            "unit": "₹",
            "data": [{"label": "A", "value": 6000}, {"label": "B", "value": 7500}],
        }
    ]
    assert any("7500" in i for i in issues(data))


def test_links_only_to_the_source_or_government_hosts() -> None:
    data = payload()
    data["lang"]["mr"]["sources"].append({"title": "Blog", "url": "https://example.com/x"})
    assert any("example.com" in i for i in issues(data))


def test_political_content_is_never_published() -> None:
    assert any("political" in i for i in issues(payload(political=True)))
    data = payload()
    data["lang"]["mr"]["sections"][1]["body"] = "भाजपच्या सरकारचा निर्णय."
    assert any("political" in i for i in issues(data))
    data = payload()
    data["lang"]["en"]["sections"][1]["body"] = "Congressional hearings were held."
    assert not any("political" in i for i in issues(data))


def test_an_e_mail_or_phone_not_in_the_source_is_caught() -> None:
    data = payload()
    data["lang"]["en"]["sections"][2]["body"] = "Call 9876543210 or write to help@agri.example."
    found = issues(data)
    assert any("9876543210" in i for i in found)
    assert any("help@agri.example" in i for i in found)


@pytest.mark.parametrize(
    "breaker",
    [
        lambda a: a.update(key_points=["only one"]),
        lambda a: a.update(sections=[]),
        lambda a: a.update(headline=""),
        lambda a: a.update(charts=[{"type": "line", "title": "x", "unit": "", "data": []}]),
        lambda a: a["charts"][0].update(data=[{"label": "x", "value": -1}] * 2),
        lambda a: a.update(key_dates=[{"date": "30/11/2026", "label": "x"}]),
    ],
)
def test_a_malformed_article_is_refused(breaker: Any) -> None:
    data = payload()
    breaker(data["lang"]["mr"])
    with pytest.raises(ArticleError):
        parse_articles(data)


def test_all_three_languages_are_required() -> None:
    data = payload()
    del data["lang"]["hi"]
    with pytest.raises(ArticleError):
        parse_articles(data)


def test_not_relevant_needs_no_article() -> None:
    result = parse_articles({"relevant": False, "political": False})
    assert not result.relevant
    assert result.articles == {}


async def test_the_writer_uses_the_article_prompt_and_the_strong_model() -> None:
    seen: list[dict[str, Any]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(json.loads(request.content))
        text = "Article:\n" + json.dumps(payload(), ensure_ascii=False)
        return httpx.Response(200, json={"content": [{"type": "text", "text": text}]})

    settings = Settings(environment="test", feed_ai_api_key="sk-test-not-real")
    http = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    result = await AnthropicFeedAi(http, settings).write_article(SOURCE, source_url=URL)
    assert set(result.articles) == {"mr", "hi", "en"}
    body = seen[0]
    assert body["model"] == settings.feed_summarise_model
    assert body["system"] == ARTICLE_PROMPT
    assert body["max_tokens"] == settings.feed_article_max_tokens
    assert URL in body["messages"][0]["content"]
    for rule in ("not_stated", "political", "Marathi", "pie"):
        assert rule in ARTICLE_PROMPT


async def test_the_writer_asks_for_schema_valid_json() -> None:
    """VPS run 2026-11-09: two articles came back as broken JSON ("Expecting ','"). The
    request now uses structured outputs (output_config.format json_schema), allows 16000
    tokens and a long timeout, and names a cut-off answer as such."""
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        text = json.dumps(payload(), ensure_ascii=False)
        return httpx.Response(200, json={"content": [{"type": "text", "text": text}]})

    settings = Settings(environment="test", feed_ai_api_key="sk-test-not-real")
    http = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    await AnthropicFeedAi(http, settings).write_article(SOURCE, source_url=URL)
    body = json.loads(seen[0].content)
    fmt = body["output_config"]["format"]
    assert fmt["type"] == "json_schema"
    schema = fmt["schema"]
    assert schema["required"] == ["relevant", "political", "lang"]
    article = schema["$defs"]["article"]
    assert article["additionalProperties"] is False
    assert set(article["required"]) == set(article["properties"])
    chart = article["properties"]["charts"]["items"]
    assert chart["properties"]["type"]["enum"] == ["bar", "pie"]
    # Structured outputs reject numeric / length / array-size constraints: none are sent.
    flat = json.dumps(schema)
    for unsupported in ("minItems", "maxItems", "minLength", "maxLength", "minimum"):
        assert unsupported not in flat
    assert settings.feed_article_max_tokens == 16000
    assert seen[0].extensions["timeout"]["read"] == settings.feed_article_timeout_seconds


async def test_a_cut_off_answer_is_reported_as_such() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        content = [{"type": "text", "text": '{"relevant": true, "lang": {"mr": {"head'}]
        return httpx.Response(200, json={"content": content, "stop_reason": "max_tokens"})

    settings = Settings(environment="test", feed_ai_api_key="sk-test-not-real")
    http = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    with pytest.raises(AiUnavailableError, match="max_tokens"):
        await AnthropicFeedAi(http, settings).write_article(SOURCE, source_url=URL)
