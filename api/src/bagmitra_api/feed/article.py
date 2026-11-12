"""AI news articles from government sources (spec v1.6, owner Q127).

The model writes one article per language (mr / hi / en) as JSON; `parse_articles` refuses any
shape outside the spec, and `check_articles` lists every reason not to publish. Nobody reviews
the article (owner decision), so these checks are the gate: an article with any issue is held.
"""

from __future__ import annotations

import math
import re
from collections.abc import Iterator
from dataclasses import dataclass
from datetime import date
from typing import Any
from urllib.parse import urlsplit

from bagmitra_api.feed.output_check import SourceIndex, check_output, normalise, text_facts

LANGS = ("mr", "hi", "en")
CHART_TYPES = ("bar", "pie")
# Party names that mark political content (any language); matched as whole words.
PARTY_NAMES = (
    "bjp", "congress", "shiv sena", "ncp", "aap", "mns", "bsp", "samajwadi",
    "भाजप", "भाजपा", "काँग्रेस", "कांग्रेस", "शिवसेना", "शिव सेना", "राष्ट्रवादी", "मनसे",
    "आम आदमी पार्टी", "बसपा", "समाजवादी",
)  # fmt: skip
OFFICIAL_SUFFIXES = (".gov.in", ".nic.in")
_EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
_PHONE = re.compile(r"(?<!\d)(?:\+91[\s-]?)?[6-9]\d{9}(?!\d)")

ARTICLE_PROMPT = """You are the news desk of BagMitra, an app for fruit growers (orange, sweet lime
and other orchards) and farmers in Maharashtra. Read the source in <document> (an official
government page or an agriculture news outlet's page; its address is in <source_url>) and write
a professional news article for farmers, as a careful agriculture journalist would.

Answer with ONE JSON object only, no other text:
{"relevant": true|false, "political": true|false,
 "lang": {"mr": ARTICLE, "hi": ARTICLE, "en": ARTICLE}}
ARTICLE = {"headline": str, "standfirst": str, "key_points": [3-5 str],
 "sections": [3-5 {"heading": str, "body": str}], "facts": [3-8 {"label": str, "value": str}],
 "charts": [0-2 {"type": "bar"|"pie", "title": str, "unit": str,
                 "data": [2-8 {"label": str, "value": number}]}],
 "key_dates": [{"date": "YYYY-MM-DD", "label": str}], "sources": [1-5 {"title": str, "url": str}]}

Rules:
- "relevant" is true if the source does either of these:
  (1) it changes something for farmers: a scheme, a subsidy, a payment or relief, a deadline,
      crop insurance, a pesticide or fertiliser rule, market or procurement decisions;
  (2) it gives useful farming knowledge for Maharashtra / Vidarbha farmers: horticulture and
      every fruit crop (orange, sweet lime, mango, banana, pomegranate, grapes, guava, custard
      apple and others), vegetables, soil and water, weather and crop advisories, pest and
      disease management, markets and prices, post-harvest handling and storage.
  Politics, crime, entertainment, sport and stories about a person are not relevant. Otherwise
  answer {"relevant": false, "political": false, "lang": null}.
- "political" is true if the source is about elections, parties, or praise or criticism of a
  government, minister or person. Then "lang" is null.
- Use only facts in the source. Copy every number, amount, percentage, date and scheme name
  exactly as the source states it. Never estimate, convert, add up or fill a gap from general
  knowledge. A fact the source does not state is "not_stated" in "facts" and is left out of
  the text.
- Tone: neutral and explanatory, like a news-desk explainer. No opinion, no advice beyond what
  the source says, no praise or criticism, no forecasts the source does not make. Write "may
  be eligible", never "will receive".
- Sections, in this order when the source covers them: what was decided; who benefits; amounts
  and dates; what farmers can do next; background. 250-450 words of section text per language.
- Headline at most 90 letters; standfirst one sentence.
- Charts only from numbers in the source: "bar" to compare amounts or counts; "pie" only for
  parts of one whole whose values add up to 100 % or to a total the source states. No chart
  when the source has no such numbers.
- Write Marathi as a Maharashtra farmer speaks it, simple and clear (use व्यवहार, never सौदा;
  मध्यस्थ (दलाल) for a broker). Hindi and English say the same facts as the Marathi.
- "sources": the source address first, then only addresses the source itself gives.
- "key_dates" only dates the source states, in ISO form."""


def _obj(properties: dict[str, Any]) -> dict[str, Any]:
    return {
        "type": "object",
        "properties": properties,
        "required": list(properties),
        "additionalProperties": False,
    }


def _list(items: dict[str, Any]) -> dict[str, Any]:
    return {"type": "array", "items": items}


_STR = {"type": "string"}
# Structured outputs (output_config.format): the API returns JSON that matches this schema.
# Counts and lengths are not expressible there; parse_articles checks them.
ARTICLE_SCHEMA: dict[str, Any] = {
    **_obj(
        {
            "relevant": {"type": "boolean"},
            "political": {"type": "boolean"},
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
                "headline": _STR,
                "standfirst": _STR,
                "key_points": _list(_STR),
                "sections": _list(_obj({"heading": _STR, "body": _STR})),
                "facts": _list(_obj({"label": _STR, "value": _STR})),
                "charts": _list(
                    _obj(
                        {
                            "type": {"type": "string", "enum": list(CHART_TYPES)},
                            "title": _STR,
                            "unit": _STR,
                            "data": _list(_obj({"label": _STR, "value": {"type": "number"}})),
                        }
                    )
                ),
                "key_dates": _list(_obj({"date": _STR, "label": _STR})),
                "sources": _list(_obj({"title": _STR, "url": _STR})),
            }
        )
    },
}


class ArticleError(ValueError):
    """The model's JSON does not have the article shape of spec v1.6 §3."""


@dataclass(frozen=True, slots=True)
class ChartPoint:
    label: str
    value: float


@dataclass(frozen=True, slots=True)
class Chart:
    type: str
    title: str
    unit: str
    data: tuple[ChartPoint, ...]


@dataclass(frozen=True, slots=True)
class Article:
    headline: str
    standfirst: str
    key_points: tuple[str, ...]
    sections: tuple[tuple[str, str], ...]
    facts: tuple[tuple[str, str], ...]
    charts: tuple[Chart, ...]
    key_dates: tuple[tuple[str, str], ...]
    sources: tuple[tuple[str, str], ...]

    def as_json(self) -> dict[str, Any]:
        return {
            "headline": self.headline,
            "standfirst": self.standfirst,
            "key_points": list(self.key_points),
            "sections": [{"heading": h, "body": b} for h, b in self.sections],
            "facts": [{"label": k, "value": v} for k, v in self.facts],
            "charts": [
                {
                    "type": c.type,
                    "title": c.title,
                    "unit": c.unit,
                    "data": [{"label": p.label, "value": p.value} for p in c.data],
                }
                for c in self.charts
            ],
            "key_dates": [{"date": d, "label": label} for d, label in self.key_dates],
            "sources": [{"title": t, "url": u} for t, u in self.sources],
        }


@dataclass(frozen=True, slots=True)
class ArticleSet:
    relevant: bool
    political: bool
    articles: dict[str, Article]


def _text(value: object, where: str, max_len: int) -> str:
    if not isinstance(value, str) or not value.strip() or len(value.strip()) > max_len:
        raise ArticleError(f"{where}: text missing or longer than {max_len}")
    return value.strip()


def _items(value: object, where: str, low: int, high: int) -> list[Any]:
    if not isinstance(value, list) or not low <= len(value) <= high:
        raise ArticleError(f"{where}: needs {low}-{high} entries")
    return value


def _field(entry: object, key: str, where: str) -> object:
    if not isinstance(entry, dict):
        raise ArticleError(f"{where}: not an object")
    return entry.get(key)


def _chart(raw: object, where: str) -> Chart:
    kind = _field(raw, "type", where)
    if kind not in CHART_TYPES:
        raise ArticleError(f"{where}: type must be bar or pie")
    points = []
    for i, p in enumerate(_items(_field(raw, "data", where), f"{where}.data", 2, 8)):
        value = _field(p, "value", f"{where}.data[{i}]")
        if isinstance(value, bool) or not isinstance(value, int | float):
            raise ArticleError(f"{where}.data[{i}]: value is not a number")
        if not math.isfinite(value) or value < 0:
            raise ArticleError(f"{where}.data[{i}]: value must be finite and >= 0")
        points.append(ChartPoint(_text(_field(p, "label", where), where, 60), float(value)))
    unit = _field(raw, "unit", where)
    return Chart(
        str(kind),
        _text(_field(raw, "title", where), where, 120),
        unit.strip() if isinstance(unit, str) else "",
        tuple(points),
    )


def _iso(value: object, where: str) -> str:
    try:
        return date.fromisoformat(str(value)).isoformat()
    except ValueError as exc:
        raise ArticleError(f"{where}: date is not YYYY-MM-DD") from exc


def _article(raw: object, lang: str) -> Article:
    if not isinstance(raw, dict):
        raise ArticleError(f"{lang}: article missing")
    w = lang
    facts = [
        (_text(_field(f, "label", w), f"{w}.facts", 80), _text(_field(f, "value", w), w, 300))
        for f in _items(raw.get("facts"), f"{w}.facts", 3, 8)
    ]
    return Article(
        headline=_text(raw.get("headline"), f"{w}.headline", 160),
        standfirst=_text(raw.get("standfirst"), f"{w}.standfirst", 400),
        key_points=tuple(
            _text(k, f"{w}.key_points", 300) for k in _items(raw.get("key_points"), w, 3, 5)
        ),
        sections=tuple(
            (
                _text(_field(s, "heading", w), f"{w}.sections", 120),
                _text(_field(s, "body", w), f"{w}.sections", 3000),
            )
            for s in _items(raw.get("sections"), f"{w}.sections", 3, 5)
        ),
        facts=tuple((k, v) for k, v in facts if v != "not_stated"),
        charts=tuple(
            _chart(c, f"{w}.charts[{i}]")
            for i, c in enumerate(_items(raw.get("charts", []), f"{w}.charts", 0, 2))
        ),
        key_dates=tuple(
            (_iso(_field(d, "date", w), f"{w}.key_dates"), _text(_field(d, "label", w), w, 120))
            for d in _items(raw.get("key_dates", []), f"{w}.key_dates", 0, 8)
        ),
        sources=tuple(
            (_text(_field(s, "title", w), w, 200), _text(_field(s, "url", w), w, 1000))
            for s in _items(raw.get("sources"), f"{w}.sources", 1, 5)
        ),
    )


def parse_articles(payload: dict[str, Any]) -> ArticleSet:
    relevant = payload.get("relevant") is True
    political = payload.get("political") is True
    if not relevant or political:
        return ArticleSet(relevant, political, {})
    langs = payload.get("lang")
    if not isinstance(langs, dict):
        raise ArticleError("lang: missing")
    return ArticleSet(
        relevant, political, {lang: _article(langs.get(lang), lang) for lang in LANGS}
    )


def _texts(lang: str, a: Article) -> Iterator[tuple[str, str]]:
    yield f"{lang}.headline", a.headline
    yield f"{lang}.standfirst", a.standfirst
    for i, k in enumerate(a.key_points):
        yield f"{lang}.key_points[{i}]", k
    for i, (heading, body) in enumerate(a.sections):
        yield f"{lang}.sections[{i}]", f"{heading}\n{body}"
    for i, (label, value) in enumerate(a.facts):
        yield f"{lang}.facts[{i}]", f"{label}: {value}"
    for i, c in enumerate(a.charts):
        yield f"{lang}.charts[{i}]", c.title
    for i, (day, label) in enumerate(a.key_dates):
        yield f"{lang}.key_dates[{i}]", f"{day} {label}"


def _names(text: str, name: str) -> bool:
    """Whole word for Latin names; for Devanagari names only the start must be a word start,
    so inflected forms (भाजपच्या, काँग्रेसचे) are found too."""
    end = r"(?![^\W\d_])" if name.isascii() else ""
    return re.search(rf"(?<![^\W\d_]){re.escape(name)}{end}", text) is not None


def _official(url: str, source_host: str) -> bool:
    parts = urlsplit(url)
    host = (parts.hostname or "").lower()
    return parts.scheme == "https" and (
        host == source_host or any(host.endswith(s) for s in OFFICIAL_SUFFIXES)
    )


def _chart_issues(c: Chart, where: str, index: SourceIndex) -> list[str]:
    out = [
        f"{where}: chart value {p.value:g} is not in the source"
        for p in c.data
        if p.value not in index.values
    ]
    if c.type == "pie":
        total = sum(p.value for p in c.data)
        whole = abs(total - 100) <= 1 if c.unit.strip() == "%" else total in index.values
        if not whole:
            out.append(f"{where}: pie parts add up to {total:g}, not to a stated whole")
    return out


def check_articles(source_text: str, result: ArticleSet, *, source_url: str) -> list[str]:
    """Every reason not to publish; empty means the article set may be published."""
    if result.political:
        return ["political: the model marked the source as political"]
    if not result.relevant:
        return ["not relevant to farmers"]
    index = SourceIndex.build(source_text)
    source_norm = normalise(source_text)
    source_host = (urlsplit(source_url).hostname or "").lower()
    out: list[str] = []
    facts_by_lang = {}
    for lang, a in result.articles.items():
        texts = dict(_texts(lang, a))
        for m in check_output(source_text, texts):
            out.append(f"{m.where}: {m.kind} '{m.text}' is not in the source")
        joined = normalise("\n".join(texts.values()))
        out += [f"{lang}: political: names '{n}'" for n in PARTY_NAMES if _names(joined, n)]
        for found in (*_EMAIL.findall(joined), *_PHONE.findall(joined)):
            if normalise(found) not in source_norm:
                out.append(f"{lang}: contact '{found}' is not in the source")
        for _title, url in a.sources:
            if not _official(url, source_host):
                out.append(f"{lang}.sources: '{url}' is not the source or a government site")
        for i, c in enumerate(a.charts):
            out += _chart_issues(c, f"{lang}.charts[{i}]", index)
        facts = text_facts("\n".join(texts.values()))
        facts_by_lang[lang] = (facts.amounts, facts.dates)
    if len(set(facts_by_lang.values())) > 1:
        out.append("languages: amounts or dates differ between mr / hi / en")
    return out
