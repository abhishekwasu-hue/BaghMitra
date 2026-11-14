"""Knowledge articles ("ज्ञान लेख", owner 2026-11-11): the prompt, the answer's shape and the
checks that decide whether one may be published.

The model writes from ONE input only: the checked texts of our KB practice cards plus the
passages of the open sources those cards cite, or an official scheme item's own checked text.
Newspaper content never enters (owner: copyright). The answer is one article per language
(mr first, hi, en) with a title, one line under it and 4-8 short sections. Sources are not
written by the model: the job attaches the cards' own source list. `check_knowledge` lists every
reason not to publish; any number, amount or date that is not in the input holds the article.
"""

from __future__ import annotations

import csv
import json
import re
from collections.abc import Iterator
from dataclasses import dataclass
from functools import cache
from importlib import resources
from typing import Any

from bagmitra_api.feed.output_check import (
    check_output,
    language_differences,
    normalise,
    text_facts,
)

LANGS = ("mr", "hi", "en")
MIN_SECTIONS, MAX_SECTIONS = 4, 8
_EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
_PHONE = re.compile(r"(?<!\d)(?:\+91[\s-]?)?[6-9]\d{9}(?!\d)")

KNOWLEDGE_PROMPT = """You write "ज्ञान लेख" (knowledge articles) for BagMitra, an app for orange
(santra) and sweet-lime (mosambi) farmers in Vidarbha and Marathwada, Maharashtra. The aim is to
make farmers truly knowledgeable, in calm and simple words.

The user message has <topic> (why the article is written now) and <document>: the ONLY material
you may use. It holds checked advice-card points and passages of the official or university
sources they cite, or one official government item. Use nothing else: no general knowledge, no
other source, no newspaper.

Answer with ONE JSON object only:
{"relevant": true|false, "lang": {"mr": ARTICLE, "hi": ARTICLE, "en": ARTICLE} | null}
ARTICLE = {"title": str, "standfirst": str, "sections": [4-8 {"heading": str, "body": str}]}

Rules:
- "relevant" is false (and "lang" null) when the document does not give enough to explain the
  topic to a farmer (for a scheme: who may apply, how to apply or what the scheme gives).
- Marathi first, as a Vidarbha farmer speaks it, simple and clear; Hindi and English say exactly
  the same facts as the Marathi.
- Title at most 80 letters; standfirst one calm sentence; 4-8 sections, each with a short,
  farmer-friendly heading (for example: what you see, when it comes, what to check in the
  orchard, what to do, what not to do, when to ask the KVK; for a scheme: what the scheme is,
  who may be eligible, documents, how to apply, last date) and a body of 40-120 words.
- Copy every number, amount, percentage and date exactly as the document states it. Never
  estimate, convert, round, add up or add a number, year or date the document does not state.
- No pesticide, fungicide, growth-regulator or fertiliser product or brand names and no doses
  beyond what the card points themselves say; where the document uses a product, write that the
  registered label information is on the card in the app and to ask the KVK.
- Calm tone: no alarm words, no promises, no praise or criticism. For a scheme write "may be
  eligible", never "will receive".
- Do not write source lists or links; the app adds the sources."""


def _obj(properties: dict[str, Any]) -> dict[str, Any]:
    return {
        "type": "object",
        "properties": properties,
        "required": list(properties),
        "additionalProperties": False,
    }


_STR = {"type": "string"}
KNOWLEDGE_SCHEMA: dict[str, Any] = {
    **_obj(
        {
            "relevant": {"type": "boolean"},
            "lang": {
                "anyOf": [
                    _obj({lang: {"$ref": "#/$defs/article"} for lang in LANGS}),
                    {"type": "null"},
                ]
            },
        }
    ),
    "$defs": {
        "article": _obj(
            {
                "title": _STR,
                "standfirst": _STR,
                "sections": {
                    "type": "array",
                    "items": _obj({"heading": _STR, "body": _STR}),
                },
            }
        )
    },
}


class KnowledgeError(ValueError):
    """The model's JSON does not have the knowledge-article shape."""


@dataclass(frozen=True, slots=True)
class KnowledgeArticle:
    title: str
    standfirst: str
    sections: tuple[tuple[str, str], ...]

    def as_json(self, sources: list[tuple[str, str]], card_section: str | None) -> dict[str, Any]:
        """Stored in `feed_item_i18n.article`, in the news article's shape (the app and the
        feed contract read both), plus the practice-card section to open."""
        return {
            "headline": self.title,
            "standfirst": self.standfirst,
            "key_points": [],
            "sections": [{"heading": h, "body": b} for h, b in self.sections],
            "facts": [],
            "charts": [],
            "key_dates": [],
            "sources": [{"title": t, "url": u} for t, u in sources],
            "card_section": card_section,
        }


@dataclass(frozen=True, slots=True)
class KnowledgeSet:
    relevant: bool
    articles: dict[str, KnowledgeArticle]


def _text(value: object, where: str, max_len: int) -> str:
    if not isinstance(value, str) or not value.strip() or len(value.strip()) > max_len:
        raise KnowledgeError(f"{where}: text missing or longer than {max_len}")
    return value.strip()


def _article(raw: object, lang: str) -> KnowledgeArticle:
    if not isinstance(raw, dict):
        raise KnowledgeError(f"{lang}: article missing")
    sections = raw.get("sections")
    if not isinstance(sections, list) or not MIN_SECTIONS <= len(sections) <= MAX_SECTIONS:
        raise KnowledgeError(f"{lang}.sections: needs {MIN_SECTIONS}-{MAX_SECTIONS} entries")
    parts = []
    for i, s in enumerate(sections):
        if not isinstance(s, dict):
            raise KnowledgeError(f"{lang}.sections[{i}]: not an object")
        parts.append(
            (
                _text(s.get("heading"), f"{lang}.sections[{i}].heading", 120),
                _text(s.get("body"), f"{lang}.sections[{i}].body", 2000),
            )
        )
    return KnowledgeArticle(
        title=_text(raw.get("title"), f"{lang}.title", 160),
        standfirst=_text(raw.get("standfirst"), f"{lang}.standfirst", 400),
        sections=tuple(parts),
    )


def parse_knowledge(payload: dict[str, Any]) -> KnowledgeSet:
    if payload.get("relevant") is not True:
        return KnowledgeSet(False, {})
    langs = payload.get("lang")
    if not isinstance(langs, dict):
        raise KnowledgeError("lang: missing")
    return KnowledgeSet(True, {lang: _article(langs.get(lang), lang) for lang in LANGS})


def from_saved(saved: dict[str, dict[str, Any]]) -> KnowledgeSet | None:
    """The article set as stored per language (`as_json`), for the held re-check; None when a
    language is missing or damaged."""
    try:
        return KnowledgeSet(
            True,
            {
                lang: _article(
                    {
                        "title": saved[lang].get("headline"),
                        "standfirst": saved[lang].get("standfirst"),
                        "sections": saved[lang].get("sections"),
                    },
                    lang,
                )
                for lang in LANGS
            },
        )
    except (KeyError, KnowledgeError, AttributeError):
        return None


@cache
def chemical_names() -> frozenset[str]:
    """Active ingredients our KB knows (CIB&RC label claims, PPQS restrictions, the cards'
    chemical options), lower case. An article may name one only when its input does."""
    seed = resources.files("bagmitra_api.kb.seed_data")
    names: set[str] = set()
    with seed.joinpath("label_claims_citrus.csv").open(encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            names.update(p.strip() for p in row["active_ingredient"].split("+"))
    restrictions = json.loads(seed.joinpath("restrictions.json").read_text("utf-8"))
    for entry in restrictions.get("restrictions", []):
        names.update(
            str(n) for n in [entry.get("active_ingredient"), *entry.get("synonyms", [])] if n
        )
    knowledge = json.loads(seed.joinpath("knowledge.json").read_text("utf-8"))
    for card in knowledge.get("cards", []):
        names.update(o["active_ingredient"] for o in card.get("chemical_options", []))
    return frozenset(n.lower() for n in names if len(n) >= 4)


def _texts(lang: str, a: KnowledgeArticle) -> Iterator[tuple[str, str]]:
    yield f"{lang}.title", a.title
    yield f"{lang}.standfirst", a.standfirst
    for i, (heading, body) in enumerate(a.sections):
        yield f"{lang}.sections[{i}]", f"{heading}\n{body}"


def _named(text: str, name: str) -> bool:
    return re.search(rf"(?<![\w-]){re.escape(name)}(?![\w-])", text) is not None


def check_knowledge(source_text: str, result: KnowledgeSet) -> list[str]:
    """Every reason not to publish; empty means the article set may be published.
    `source_text` is exactly the input the model was given."""
    if not result.relevant:
        return ["not relevant: the input does not explain the topic"]
    source_norm = normalise(source_text)
    out: list[str] = []
    facts_by_lang = {}
    for lang, a in result.articles.items():
        texts = dict(_texts(lang, a))
        for m in check_output(source_text, texts):
            out.append(f"{m.where}: {m.kind} '{m.text}' is not in the source")
        joined = normalise("\n".join(texts.values()))
        for name in sorted(chemical_names()):
            if _named(joined, name) and not _named(source_norm, name):
                out.append(f"{lang}: product '{name}' is not in the cards or the source")
        for found in (*_EMAIL.findall(joined), *_PHONE.findall(joined)):
            if normalise(found) not in source_norm:
                out.append(f"{lang}: contact '{found}' is not in the source")
        facts_by_lang[lang] = text_facts("\n".join(texts.values()))
    if language_differences(facts_by_lang):
        out.append("languages: amounts or dates differ between mr / hi / en")
    return out
