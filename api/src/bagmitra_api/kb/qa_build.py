"""Offline question-and-answer knowledge base for the app's "विचारा" tab (owner 2026-11-12, Q144).

Owner: "even WITHOUT internet we can answer farmers' various questions in detail; make our
database strong". Answers come ONLY from checked material, in calm Marathi first (hi, en too):
- the AI-checked practice-card points (`kb/seed_data/practice_cards.json`, the app's own file)
  and passages of the open sources they cite, read like the knowledge articles do
  (`feed.knowledge.cards_input`: newspaper points, unreadable sources and points whose numbers
  are not in their cited text are left out); one topic per card section, per home-made
  preparation set, and per bahar stage (आंबिया, मृग; santra and mosambi);
- the CIB&RC label claims for citrus (spray safety, waiting period / PHI) as printed;
- the FCO 1985 Schedule I grades extract, as data only;
- the app's own screens and strings (how to record a spray, a bill photo, a sale lot, the
  photo check);
- with `--schemes` (on the VPS, which has the database): official, published scheme / GR items
  of the feed, from their own checked text only.
Steps, every one resumable from a JSONL work file (finished items are skipped, a submitted batch
is collected again):
1. questions: the strong model drafts the questions farmers ask per topic (mr / hi / en),
   de-duplicated across topics;
2. answers: the strong model answers up to ANSWER_GROUP questions of one topic per request, from
   that topic's input only (the input is a cached prompt prefix); every answer goes through the
   knowledge-article check (`check_knowledge`: numbers, amounts, dates, product names, contacts,
   the same facts in all languages) plus the shape (4-10 lines), brand-name and alarm-word checks:
   a failed answer is DROPPED and counted by reason;
3. paraphrases: the cheaper model writes 3-6 ways to ask each kept question (Marathi, romanised
   Marathi / Hinglish, Hindi), for matching only;
4. the asset: gzipped compact JSON with each entry's search keys (`kb.qa_text`), a report and a
   cost summary (tokens and estimated USD).
    python -m bagmitra_api.kb.qa_build build --out ../app/assets/config/qa_kb.json.gz
    python -m bagmitra_api.kb.qa_build seed --out ../app/assets/config/qa_kb.json.gz
The seed (no model) is hand-assembled from card texts only: the feature works before the first
generation run. Runbook: docs/runbooks/offline-qa.md.
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import gzip
import hashlib
import json
import os
import re
import sys
import uuid
from collections.abc import Callable, Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import UTC, datetime
from functools import cache
from importlib import resources
from pathlib import Path
from typing import Any

import httpx

from bagmitra_api.bahar.seed import StageTemplateSeeds, stage_template_seeds
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.feed.ai import AiUnavailableError, _json_object
from bagmitra_api.feed.knowledge import (
    CROP_NAMES,
    NEWSPAPER_PUBLISHERS,
    STAGE_SECTIONS,
    Fetcher,
    Topic,
    cards_input,
    practice_cards,
)
from bagmitra_api.feed.knowledge_article import (
    KnowledgeArticle,
    KnowledgeSet,
    check_knowledge,
)
from bagmitra_api.feed.output_check import normalise
from bagmitra_api.kb.card_check import fetch_text
from bagmitra_api.kb.qa_api import ModelClient, Reply, Request, Usage
from bagmitra_api.kb.qa_text import index_keys, words

PROMPT_VERSION = "qa-v2"  # v2: no closing "ask the KVK" lines (owner)
LANGS = ("mr", "hi", "en")
ANSWER_GROUP = 5
PARAPHRASE_GROUP = 25
MIN_LINES, MAX_LINES = 4, 10
MIN_QUESTIONS, MAX_QUESTIONS = 6, 60
DUPLICATE_JACCARD = 0.75
BAHARS = ("ambia", "mrig")  # owner: आंबिया, मृग
MAX_PARAPHRASES = 6
APP_SOURCE = "app"
# Words that frighten rather than inform (owner: no frightening wording); an answer using one
# that its input does not use is dropped.
ALARM_WORDS = (
    "deadly", "disaster", "catastroph", "devastat", "panic", "terrible", "alarming",
    "भयंकर", "भयानक", "हाहाकार", "सर्वनाश", "उद्ध्वस्त", "घातक", "विनाशकारी", "तबाह",
    "खतरनाक",
)  # fmt: skip
# App screens a how-to topic is written from (their strings, mr / en / hi), relative to app/.
HOWTO_SCREENS: dict[str, tuple[str, tuple[str, ...]]] = {
    "spray": (
        "Record a spray (फवारणी नोंदवा), with a tank mix, labour and the bill photo",
        (
            "lib/features/spray/presentation/add_spray_screen.dart",
            "lib/features/spray/presentation/spray_log_screen.dart",
        ),
    ),
    "bill": (
        "Keep a shop bill photo with a spray or an expense and fill the form from the bill",
        ("lib/features/bills/presentation/bill_photo_field.dart",),
    ),
    "sale_lot": (
        "Put up a sale lot (विक्रीचा माल) with photos for checked traders",
        (
            "lib/features/market_link/presentation/lot_form_screen.dart",
            "lib/features/market_link/presentation/my_lots_screen.dart",
        ),
    ),
    "photo_check": (
        "Check a leaf, fruit or trunk photo (फोटोवरून ओळखा) and open the matching card",
        ("lib/features/photo_analysis/presentation/photo_analysis_screen.dart",),
    ),
}
NAV_FILES = ("lib/app/app_shell.dart",)

QUESTIONS_PROMPT = """You prepare an offline question bank for BagMitra, an app for orange
(santra, Nagpur mandarin) and sweet-lime (mosambi) farmers in Vidarbha, Maharashtra.

The user message has <topic> and <document>: the ONLY material the answers may use (checked
advice-card points and passages of the official or university sources they cite, label claims
as printed, a government schedule, the app's own screen texts, or one official government item).

Write the questions such farmers really ask about this topic, as they ask them: plain, short,
practical (what do I see, when does it come, how do I check, what do I do, what not to do, how
to prepare, which registered label lists it, what waiting period the label prints, how do I do
this in the app ...). Every question must be FULLY answerable from the document alone; never
ask what the document does not state. Do not repeat a question in other words. Write each
question in Marathi as a Vidarbha farmer speaks it, in Hindi and in English, with the same
meaning. Never put a number, dose, date or product in a question unless the document states it.
Answer with one JSON object: {"questions": [{"mr": str, "hi": str, "en": str}]} with about
<count> questions (fewer when the document supports fewer)."""

ANSWERS_PROMPT = """You answer farmers' questions for BagMitra's offline question bank (orange
/ santra and sweet-lime / mosambi farmers in Vidarbha, Maharashtra).

The user message has <topic>, <document> (the ONLY material you may use) and <questions>.
For each question:
- "answerable": false when the document does not fully answer it (then empty lists).
- Otherwise answer in Marathi first, as a Vidarbha farmer speaks, simple and clear; Hindi and
  English say exactly the same facts. Each language is a list of 4-10 short sentences or
  bullet points (one per list item, without bullet signs), detailed but plain.
- Use only the document: no general knowledge, no other source. Copy every number, amount,
  percentage and date exactly as the document states it; never estimate, convert, round or add
  one.
- Name no pesticide, fungicide, growth regulator or fertiliser product and give no dose beyond
  what the document itself states. Where the document lists a registered label claim, give it as
  printed.
- Calm tone: no alarm words, no promises, no praise or criticism.
- Do not end an answer with a line that only sends the farmer to the KVK, an expert or an
  officer ("for more information ask your KVK", "the label and the KVK have the full
  directions"): the owner removed such closing lines from the app. Every line carries a fact.
- "source_keys": the keys of the <source key="..."> blocks (or of the label / schedule rows) the
  answer uses; [] when it uses only the card points.
Answer with one JSON object:
{"answers": [{"id": str, "answerable": bool, "mr": [str], "hi": [str], "en": [str],
"source_keys": [str]}]} with one entry for every question id."""

PARAPHRASE_PROMPT = """For each farmer question below (orange / sweet-lime growers in
Vidarbha), write 3 to 6 other ways a farmer may ask the SAME thing, for search matching: at least
one more Marathi way, one in romanised Marathi or Hinglish (Latin letters, as typed on a phone,
for example "santra falgal kashi thambvavi"), and one in Hindi. Keep the meaning exactly; add no
number, product or fact. Answer with one JSON object:
{"items": [{"id": str, "paraphrases": [str]}]} with one entry for every id."""


def _obj(properties: dict[str, Any]) -> dict[str, Any]:
    return {
        "type": "object",
        "properties": properties,
        "required": list(properties),
        "additionalProperties": False,
    }


_STR = {"type": "string"}
_STRS = {"type": "array", "items": _STR}
QUESTIONS_SCHEMA = _obj({"questions": {"type": "array", "items": _obj(dict.fromkeys(LANGS, _STR))}})
ANSWERS_SCHEMA = _obj(
    {
        "answers": {
            "type": "array",
            "items": _obj(
                {
                    "id": _STR,
                    "answerable": {"type": "boolean"},
                    **dict.fromkeys(LANGS, _STRS),
                    "source_keys": _STRS,
                }
            ),
        }
    }
)
PARAPHRASE_SCHEMA = _obj(
    {"items": {"type": "array", "items": _obj({"id": _STR, "paraphrases": _STRS})}}
)


# Topics -----------------------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class QaTopic:
    key: str
    about: str  # what the topic is, given to the model as <topic>
    text: str  # exactly what the model reads; the checks use the same text
    sources: dict[str, tuple[str, str]]  # source key -> (title, url); url "" for the app
    points: int  # card points / rows / strings the input holds
    section: str | None = None  # practice-card section the app can open

    @property
    def target(self) -> int:
        return max(MIN_QUESTIONS, min(MAX_QUESTIONS, 3 * self.points + 4))

    @property
    def digest(self) -> str:
        return _sha(PROMPT_VERSION, self.key, self.about, self.text)[:16]


def _sha(*parts: str) -> str:
    return hashlib.sha256("\x1f".join(parts).encode()).hexdigest()


@cache
def _seed_json(name: str) -> Any:
    return json.loads(
        resources.files("bagmitra_api.kb.seed_data").joinpath(name).read_text("utf-8")
    )


def kb_sources() -> dict[str, dict[str, Any]]:
    return {s["key"]: s for s in _seed_json("sources.json")["sources"]}


_SOURCE_KEY = re.compile(r'<source key="([^"]+)"')


def _card_topic(  # noqa: PLR0913 - one topic from a cards input
    key: str,
    about: str,
    found_text: str,
    cards: Mapping[str, Any],
    section: str | None,
    extra: str = "",
) -> QaTopic:
    srcs: Mapping[str, Any] = cards.get("sources", {})
    keys = _SOURCE_KEY.findall(found_text)
    text = found_text + (f"\n{extra}" if extra else "")
    return QaTopic(
        key=key,
        about=about,
        text=text,
        sources={k: (str(srcs[k].get("title", k)), str(srcs[k].get("url", ""))) for k in keys},
        points=found_text.split("</cards>")[0].count("\n- "),
        section=section,
    )


def _gaps_block(cards: Mapping[str, Any]) -> str:
    gaps = cards.get("gaps") or []
    if not gaps:
        return ""
    lines = [f"- {g.get('en', '')}\n  (मराठी: {g.get('mr', '')})" for g in gaps]
    return "<not_in_sources_read>\n" + "\n".join(lines) + "\n</not_in_sources_read>"


async def card_topics(
    cards: Mapping[str, Any], fetch: Fetcher, limit: int, seeds: StageTemplateSeeds
) -> list[QaTopic]:
    """One topic per card section, the home-made preparations, and each bahar stage."""
    out: list[QaTopic] = []
    gaps = _gaps_block(cards)
    for sec in cards.get("sections", []):
        label = sec["labels"]
        about = (
            f"Practice card '{label['en']}' ({label.get('mr', '')}): what farmers ask about it "
            "(what they see, when it comes, how to scout, what to do and what not to do)."
        )
        topic = Topic(key=f"qa:{sec['key']}", trigger="qa", about=about, window_end=None,
                      sections=(sec["key"],))  # fmt: skip
        found = await cards_input(topic, cards, fetch, limit)
        if found is not None:
            extra = gaps if "profile" in sec else ""
            out.append(
                _card_topic(f"section:{sec['key']}", about, found.text, cards, sec["key"], extra)
            )
    preps = cards.get("preparations") or {}
    if preps:
        pseudo = {
            "sources": cards.get("sources", {}),
            "sections": [
                {
                    "key": "preparations",
                    "labels": {"en": "Home-made preparations", "mr": "घरगुती अर्क / द्रावण"},
                    "items": [
                        {"id": k, "labels": p["labels"], "source_keys": p.get("source_keys", [])}
                        for k, p in sorted(preps.items())
                    ],
                }
            ],
        }
        about = "How to prepare the home-made bio preparations the cards name, as published."
        topic = Topic("qa:preparations", "qa", about, None, ("preparations",))
        found = await cards_input(topic, pseudo, fetch, limit)
        if found is not None:
            out.append(_card_topic("preparations", about, found.text, cards, None))
    for t in seeds.templates:
        if t.bahar not in BAHARS:
            continue
        for s in t.stages:
            if s.key not in STAGE_SECTIONS:
                continue
            about = (
                f"{t.labels['en']} ({t.labels['mr']}) of {CROP_NAMES[t.crop]}, stage "
                f"'{s.labels['en']}' ({s.labels['mr']}): what farmers ask to prepare for and "
                "manage this stage, from the cards."
            )
            topic = Topic(f"qa:{t.crop}:{t.bahar}:{s.key}", "qa", about, None,
                          STAGE_SECTIONS[s.key])  # fmt: skip
            found = await cards_input(topic, cards, fetch, limit)
            if found is not None:
                out.append(
                    _card_topic(
                        f"stage:{t.crop}:{t.bahar}:{s.key}",
                        about,
                        found.text,
                        cards,
                        STAGE_SECTIONS[s.key][0],
                    )
                )
    return out


LABEL_FIELDS = (
    ("target", "target pest / disease / weed"),
    ("active_ingredient", "active ingredient"),
    ("formulation", "formulation"),
    ("category", "category"),
    ("dose", "dose as printed"),
    ("dilution", "dilution (litres of water) as printed"),
    ("interval_days", "spray interval (days)"),
    ("phi_days", "waiting period / PHI (days) as printed"),
    ("max_sprays", "maximum sprays"),
    ("description", "note"),
)


def label_rows() -> list[dict[str, str]]:
    path = resources.files("bagmitra_api.kb.seed_data").joinpath("label_claims_citrus.csv")
    with path.open(encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def label_topics() -> list[QaTopic]:
    """One topic per label-claim list (fungicides, insecticides ...): spray safety and PHI."""
    by_source: dict[str, list[dict[str, str]]] = {}
    for row in label_rows():
        by_source.setdefault(row["source_key"], []).append(row)
    srcs = kb_sources()
    out = []
    for key, rows in sorted(by_source.items()):
        src = srcs.get(key, {})
        title = str(src.get("title", key))
        lines = [f'<source key="{key}" title="{title}">', "CIB&RC registered label claims "
                 f"for citrus, as printed (edition {rows[0]['edition']}). An empty field is not "
                 "printed."]  # fmt: skip
        for i, row in enumerate(rows, 1):
            parts = [f"{name}: {row[f]}" for f, name in LABEL_FIELDS if row.get(f, "").strip()]
            lines.append(f"- row {i} (page {row['page_ref']}): " + "; ".join(parts))
        lines.append("</source>")
        out.append(
            QaTopic(
                key=f"label:{key}",
                about=(
                    f"{title}: which registered label claims for citrus this list prints and "
                    "the spray-safety facts it prints (dose, dilution, interval, waiting period "
                    "/ PHI), exactly as printed."
                ),
                text="\n".join(lines),
                sources={key: (title, str(src.get("url", "")))},
                points=len(rows),
            )
        )
    return out


def fco_topic() -> QaTopic:
    data = _seed_json("fco_schedule1_grades.json")
    srcs = kb_sources()
    entries = data.get("entries", [])
    key = entries[0]["source"] if entries else "fco_1985_odisha_2009"
    src = srcs.get(key, {})
    title = str(src.get("title", key))
    lines = [f'<source key="{key}" title="{title}">']
    lines += [f"- {e['type']}: {e['name']} ({e['schedule_ref']})" for e in entries]
    lines.append("</source>")
    return QaTopic(
        key="fco",
        about=(
            "Fertiliser (Control) Order 1985 Schedule I grades (micronutrients and 100% water "
            "soluble complex fertilisers) AS DATA ONLY: which grades the schedule lists and under "
            "which reference. No advice on use, dose or timing."
        ),
        text="\n".join(lines),
        sources={key: (title, str(src.get("url", "")))},
        points=max(1, len(entries) // 3),
    )


_T_KEY = re.compile(r"\bt\.([a-zA-Z]\w*)")


def _arb(app_root: Path, lang: str) -> dict[str, Any]:
    raw: dict[str, Any] = json.loads(
        (app_root / "lib" / "l10n" / f"app_{lang}.arb").read_text("utf-8")
    )
    return raw


def howto_topics(app_root: Path) -> list[QaTopic]:
    """The app's own screen strings (mr / en / hi), per how-to."""
    arbs = {lang: _arb(app_root, lang) for lang in ("en", "mr", "hi")}
    nav: list[str] = []
    for f in NAV_FILES:
        nav += _T_KEY.findall((app_root / f).read_text("utf-8"))
    out = []
    for key, (about, files) in HOWTO_SCREENS.items():
        names: list[str] = []
        for f in files:
            for k in _T_KEY.findall((app_root / f).read_text("utf-8")):
                if k not in names and isinstance(arbs["en"].get(k), str):
                    names.append(k)
        names += [k for k in nav if k not in names and isinstance(arbs["en"].get(k), str)]
        lines = [f'<source key="{APP_SOURCE}" title="BagMitra app screens">']
        lines.append("Texts the farmer sees on these screens (key: English | मराठी | हिंदी):")
        for k in names:
            lines.append(
                f"- {k}: {arbs['en'][k]} | {arbs['mr'].get(k, '')} | {arbs['hi'].get(k, '')}"
            )
        lines.append("</source>")
        out.append(
            QaTopic(
                key=f"howto:{key}",
                about=f"How to use the BagMitra app: {about}. Explain the steps from the screen "
                "texts only; quote button names as the screen writes them.",
                text="\n".join(lines),
                sources={APP_SOURCE: ("BagMitra ॲप", "")},
                points=max(2, len(names) // 6),
            )
        )
    return out


async def scheme_topics(limit: int) -> list[QaTopic]:  # pragma: no cover
    """Official, published scheme / GR items of the feed that are still open (database)."""
    from sqlalchemy import select  # noqa: PLC0415 - only the VPS run needs the database

    from bagmitra_api.db.session import get_sessionmaker  # noqa: PLC0415
    from bagmitra_api.feed.knowledge import INDIA, SCHEME_TYPES, scheme_input  # noqa: PLC0415
    from bagmitra_api.feed.models import FeedItem  # noqa: PLC0415

    today = datetime.now(UTC).astimezone(INDIA).date()
    out = []
    async with get_sessionmaker()() as session:
        rows = await session.scalars(
            select(FeedItem)
            .where(
                FeedItem.type.in_(SCHEME_TYPES),
                FeedItem.status == "published",
                FeedItem.trust_level == "official",
                FeedItem.extracted_text.is_not(None),
            )
            .order_by(FeedItem.published_at)
        )
        for item in list(rows):
            if any(d is not None and d < today for d in (item.deadline, item.valid_to)):
                continue
            topic = Topic(f"qa:scheme:{item.id}", "scheme", "", None, (), item.id)
            found = await scheme_input(session, topic, limit)
            if found is None:
                continue
            title, url = found.sources[0]
            key = f"scheme-{str(item.id)[:8]}"
            out.append(
                QaTopic(
                    key=f"scheme:{item.id}",
                    about=(
                        f"Official government item '{title}': what it offers, who may be "
                        "eligible, documents, how to apply and the last date, from its own text."
                    ),
                    text=f'<source key="{key}" title="{title}">\n{found.text}\n</source>',
                    sources={key: (title, url)},
                    points=4,
                )
            )
    return out


# Work file --------------------------------------------------------------------------------------


class WorkFile:
    """Append-only JSONL of finished steps; the last record per (kind, key) wins."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.records: dict[tuple[str, str], dict[str, Any]] = {}
        if path.exists():
            for line in path.read_text("utf-8").splitlines():
                if line.strip():
                    rec = json.loads(line)
                    self.records[(rec["kind"], rec["key"])] = rec
        path.parent.mkdir(parents=True, exist_ok=True)

    def get(self, kind: str, key: str) -> dict[str, Any] | None:
        return self.records.get((kind, key))

    def done(self, kind: str, key: str) -> bool:
        rec = self.get(kind, key)
        return rec is not None and rec.get("status") == "done"

    def put(self, kind: str, key: str, **data: Any) -> None:
        rec = {"kind": kind, "key": key, **data}
        self.records[(kind, key)] = rec
        with self.path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")

    def of_kind(self, kind: str) -> list[dict[str, Any]]:
        return [r for (k, _), r in self.records.items() if k == kind]


# Requests ---------------------------------------------------------------------------------------


def _cid(kind: str, key: str) -> str:
    return f"{kind[0]}-{_sha(kind, key)[:40]}"


def _doc_block(topic: QaTopic) -> dict[str, Any]:
    """The topic and its input: the shared, cached prefix of every request of the topic."""
    return {
        "type": "text",
        "text": f"<topic>{topic.about}</topic>\n<document>\n{topic.text}\n</document>",
        "cache_control": {"type": "ephemeral"},
    }


def _body(  # noqa: PLR0913 - one structured-output request
    model: str,
    system: str,
    content: list[dict[str, Any]],
    schema: dict[str, Any],
    max_tokens: int,
    effort: str | None = None,
) -> dict[str, Any]:
    output: dict[str, Any] = {"format": {"type": "json_schema", "schema": schema}}
    if effort is not None:
        output["effort"] = effort
    return {
        "model": model,
        "max_tokens": max_tokens,
        "system": system,
        "messages": [{"role": "user", "content": content}],
        "output_config": output,
    }


# Checks -----------------------------------------------------------------------------------------


@cache
def brand_names() -> frozenset[str]:
    names: set[str] = set()
    for row in label_rows():
        names.update(n.strip().lower() for n in re.split(r"[,;/]", row.get("brand_names") or ""))
    return frozenset(n for n in names if len(n) >= 4)


def _named(text: str, name: str) -> bool:
    return re.search(rf"(?<![\w-]){re.escape(name)}(?![\w-])", text) is not None


def reason_code(problem: str) -> str:
    """A `check_knowledge` line as a counting reason."""
    if problem.startswith("languages:"):
        return "languages_differ"
    if "product '" in problem:
        return "product"
    if "contact '" in problem:
        return "contact"
    if re.search(r": (number|amount|date) '", problem):
        return "number"
    return "other"


def check_answer(
    source_text: str, question: Mapping[str, str], answer: Mapping[str, Any]
) -> list[str]:
    """Every reason not to ship one answer (codes: not_answerable, length, number, product,
    contact, languages_differ, alarm_word, other); empty means it may be shipped."""
    if answer.get("answerable") is not True:
        return ["not_answerable"]
    lines = {
        lang: [str(x).strip() for x in answer.get(lang) or [] if str(x).strip()] for lang in LANGS
    }
    if any(not MIN_LINES <= len(v) <= MAX_LINES for v in lines.values()):
        return ["length"]
    result = KnowledgeSet(
        True,
        {
            lang: KnowledgeArticle(
                title=question.get(lang, ""),
                standfirst="",
                sections=tuple(("", line) for line in lines[lang]),
            )
            for lang in LANGS
        },
    )
    reasons = [reason_code(p) for p in check_knowledge(source_text, result)]
    source_norm = normalise(source_text)
    joined = normalise("\n".join(line for v in lines.values() for line in v))
    for brand in sorted(brand_names()):
        if _named(joined, brand) and not _named(source_norm, brand):
            reasons.append("product")
    for word in ALARM_WORDS:
        if word in joined and word not in source_norm:
            reasons.append("alarm_word")
    return list(dict.fromkeys(reasons))


# Closing "ask the KVK" lines (owner: such "check with your local expert" lines are
# unnecessary warnings) --------------------------------------------------------------------------

REFERRAL = {
    "en": re.compile(r"\b(kvk|krishi vigyan kendra|experts?|officers?)\b", re.IGNORECASE),
    "mr": re.compile(r"KVK|कृषी विज्ञान केंद्र|कृषि विज्ञान केंद्र|तज्ज्ञ|अधिकारी"),
    "hi": re.compile(r"KVK|कृषि विज्ञान केंद्र|विशेषज्ञ|अधिकारी"),
}
# English words that carry no fact in a referral line ("For more details, please check the
# label and ask your KVK").
REFERRAL_FILLER = frozenset(
    """a about advice advise advised also amount amounts an and any apply applying are ask at be
    before can check confirm consult contact correct detail details directions direction do dose
    doses doubt doubts exact expert experts for from full further get guidance guide has have
    help here if in including information info instructions is it its kvk krishi label labels
    level list local more name names nearest need not of officer officers on only or please
    product products quantities quantity questions read see should so spray spraying sure that
    the their them there these this those timing to unsure use using vigyan kendra want when
    with you your agricultural agriculture orchard own method reference needed""".split()  # noqa: SIM905 - a word list
)
_DIGIT = re.compile("[0-9\u0966-\u096f]")


def is_referral(lang: str, line: str) -> bool:
    """A line that only refers the farmer to the KVK, an expert or an officer: it names one,
    has no number, and (read on the English line) every other clause is either a "For ..." /
    "If ..." / "To ..." lead-in or words that carry no fact. "Only a lab test confirms
    greening; ask your KVK" carries a fact and is kept."""
    if _DIGIT.search(line) or not REFERRAL[lang].search(line):
        return False
    if lang != "en":
        return True
    for raw in re.split(r"[;,.:]| so ", line.lower()):
        clause = raw.strip()
        if REFERRAL["en"].search(clause) or clause.startswith(("for ", "if ", "to ")):
            continue
        if any(w not in REFERRAL_FILLER for w in re.findall(r"[a-z]+", clause)):
            return False
    return True


def strip_referral_tail(answer: Mapping[str, list[str]]) -> tuple[dict[str, list[str]], bool]:
    """The answer without its last line when that line, in every language, only refers the
    farmer to the KVK / an expert / an officer; lines inside the answer stay."""
    out = {lang: list(answer.get(lang) or []) for lang in LANGS}
    if all(len(out[lang]) > 1 and is_referral(lang, out[lang][-1]) for lang in LANGS):
        return {lang: lines[:-1] for lang, lines in out.items()}, True
    return out, False


# The build --------------------------------------------------------------------------------------


@dataclass(slots=True)
class BuildReport:
    topics: int = 0
    topics_by_kind: dict[str, int] = field(default_factory=dict)
    questions_drafted: int = 0
    duplicates_removed: int = 0
    answers_kept: int = 0
    answers_dropped: dict[str, int] = field(default_factory=dict)
    dropped_examples: list[str] = field(default_factory=list)
    errors: dict[str, int] = field(default_factory=dict)
    paraphrases: int = 0
    unreadable_sources: dict[str, str] = field(default_factory=dict)
    skipped: list[str] = field(default_factory=list)
    referral_lines_removed: int = 0
    seed_entries: int = 0
    asset_bytes: int = 0
    asset_raw_bytes: int = 0


def _jaccard(a: set[str], b: set[str]) -> float:
    return len(a & b) / len(a | b) if a and b else 0.0


def dedupe(questions: Sequence[dict[str, str]]) -> tuple[list[dict[str, str]], int]:
    """Drop near-duplicates (same normalised words in English or Marathi, Jaccard >= 0.75),
    keeping the first; returns (kept, removed)."""
    kept: list[dict[str, str]] = []
    seen: list[tuple[set[str], set[str]]] = []
    for q in questions:
        en, mr = set(words(q.get("en", ""))), set(words(q.get("mr", "")))
        if not en and not mr:
            continue
        if any(
            _jaccard(en, e) >= DUPLICATE_JACCARD or _jaccard(mr, m) >= DUPLICATE_JACCARD
            for e, m in seen
        ):
            continue
        seen.append((en, mr))
        kept.append(q)
    return kept, len(questions) - len(kept)


def _qid(topic: QaTopic, q: Mapping[str, str]) -> str:
    return "q" + _sha(topic.key, q.get("en", ""), q.get("mr", ""))[:10]


def _strings(value: object) -> list[str]:
    return (
        [v.strip() for v in value if isinstance(v, str) and v.strip()]
        if isinstance(value, list)
        else []
    )


class Builder:
    def __init__(  # noqa: PLR0913 - the build's parts, injectable for tests
        self,
        client: ModelClient,
        work: WorkFile,
        *,
        strong_model: str,
        cheap_model: str,
        max_tokens: int,
        log: Callable[[str], None] = lambda _m: None,
    ) -> None:
        self.client = client
        self.work = work
        self.strong = strong_model
        self.cheap = cheap_model
        self.max_tokens = max_tokens
        self.log = log
        self.report = BuildReport()

    async def _send(
        self, kind: str, items: dict[str, Request], handle: Callable[[str, Reply], None]
    ) -> None:
        """Send the requests of `items` (work key -> request) whose step is not done yet;
        batches an earlier run submitted are collected first."""
        by_cid = {r.custom_id: k for k, r in items.items()}
        for rec in self.work.of_kind("batch"):
            if rec.get("status") != "submitted" or rec.get("step") != kind:
                continue
            models = dict(rec.get("models") or {})
            self.log(f"collecting batch {rec['key']} of an earlier run")
            try:
                replies = await self.client.collect(rec["key"], models)
            except RuntimeError as exc:  # e.g. results no longer kept: those items are re-sent
                self.work.put("batch", rec["key"], status="lost", step=kind, error=str(exc))
                continue
            for reply in replies:
                if reply.custom_id in by_cid:
                    handle(by_cid[reply.custom_id], reply)
            self.work.put("batch", rec["key"], status="collected", step=kind)
        todo = [r for k, r in items.items() if not self.work.done(kind, k)]
        if not todo:
            return
        self.log(f"{kind}: {len(todo)} requests ({self.client.mode})")

        def submitted(batch_id: str, cids: list[str]) -> None:
            models = {c: str(items[by_cid[c]].body.get("model", "")) for c in cids}
            self.work.put("batch", batch_id, status="submitted", step=kind, models=models)

        def on_reply(reply: Reply) -> None:
            if reply.custom_id in by_cid:
                handle(by_cid[reply.custom_id], reply)

        await self.client.run(todo, on_reply, submitted)
        for rec in self.work.of_kind("batch"):
            if rec.get("status") == "submitted" and rec.get("step") == kind:
                self.work.put("batch", rec["key"], status="collected", step=kind)

    def _record(
        self, kind: str, key: str, reply: Reply, parse: Callable[[dict[str, Any]], dict[str, Any]]
    ) -> None:
        """One reply: its tokens (kept also when it failed, for the cost) and its result."""
        if reply.model:
            self.work.put(
                "usage",
                f"{reply.custom_id}:{uuid.uuid4().hex[:12]}",
                model=reply.model,
                batch=reply.batch,
                usage=reply.usage,
            )
        if reply.text is None:
            self.work.put(kind, key, status="error", error=reply.error)
            return
        try:
            data = parse(_json_object(reply.text))
        except (AiUnavailableError, ValueError, KeyError, TypeError) as exc:
            self.work.put(kind, key, status="error", error=f"parse: {exc}")
            return
        self.work.put(kind, key, status="done", **data)

    async def questions(self, topics: Sequence[QaTopic]) -> dict[str, list[dict[str, str]]]:
        items = {}
        for t in topics:
            prompt = QUESTIONS_PROMPT.replace("<count>", str(t.target))
            items[f"{t.key}:{t.digest}"] = Request(
                _cid("questions", f"{t.key}:{t.digest}"),
                _body(self.strong, prompt, [_doc_block(t)], QUESTIONS_SCHEMA, self.max_tokens),
                fallback=True,
            )

        def parse(payload: dict[str, Any]) -> dict[str, Any]:
            qs = []
            for q in payload.get("questions") or []:
                if isinstance(q, dict) and all(
                    isinstance(q.get(lang), str) and q[lang].strip() for lang in LANGS
                ):
                    qs.append({lang: q[lang].strip() for lang in LANGS})
            return {"questions": qs}

        await self._send("questions", items, lambda k, r: self._record("questions", k, r, parse))
        out = {}
        for t in topics:
            rec = self.work.get("questions", f"{t.key}:{t.digest}")
            if rec and rec.get("status") == "done":
                out[t.key] = rec["questions"]
            else:
                self._error("questions", rec)
        return out

    def _error(self, kind: str, rec: Mapping[str, Any] | None) -> None:
        reason = str(rec.get("error")) if rec else "no reply"
        key = f"{kind}: {reason.split(':')[0][:60]}"
        self.report.errors[key] = self.report.errors.get(key, 0) + 1

    async def answers(
        self, topics: Sequence[QaTopic], questions: Mapping[str, list[dict[str, str]]]
    ) -> list[dict[str, Any]]:
        groups: list[tuple[str, QaTopic, list[dict[str, str]]]] = []
        for t in topics:
            qs = questions.get(t.key, [])
            for i in range(0, len(qs), ANSWER_GROUP):
                chunk = qs[i : i + ANSWER_GROUP]
                gid = f"{t.key}:{t.digest}:" + _sha(*(_qid(t, q) for q in chunk))[:12]
                groups.append((gid, t, chunk))
        # The first group of every topic goes first, so the others can read its cached input.
        firsts: dict[str, str] = {}
        for gid, t, _chunk in groups:
            firsts.setdefault(t.key, gid)
        groups.sort(key=lambda g: 0 if firsts[g[1].key] == g[0] else 1)
        items = {}
        for gid, t, chunk in groups:
            listed = "\n".join(f"{_qid(t, q)}: {q['en']} / {q['mr']}" for q in chunk)
            items[gid] = Request(
                _cid("answers", gid),
                _body(
                    self.strong,
                    ANSWERS_PROMPT,
                    [
                        _doc_block(t),
                        {"type": "text", "text": f"<questions>\n{listed}\n</questions>"},
                    ],
                    ANSWERS_SCHEMA,
                    self.max_tokens,
                ),
                fallback=True,
            )

        def parse(payload: dict[str, Any]) -> dict[str, Any]:
            got = [a for a in payload.get("answers") or [] if isinstance(a, dict)]
            return {"answers": got}

        await self._send("answers", items, lambda k, r: self._record("answers", k, r, parse))
        kept: list[dict[str, Any]] = []
        for gid, t, chunk in groups:
            rec = self.work.get("answers", gid)
            if not rec or rec.get("status") != "done":
                self._error("answers", rec)
                continue
            answers = {str(a.get("id")): a for a in rec["answers"]}
            for q in chunk:
                qid = _qid(t, q)
                a = answers.get(qid)
                reasons = ["missing"] if a is None else check_answer(t.text, q, a)
                if a is None or reasons:
                    for r in reasons:
                        self.report.answers_dropped[r] = self.report.answers_dropped.get(r, 0) + 1
                    if len(self.report.dropped_examples) < 40:
                        self.report.dropped_examples.append(
                            f"{t.key} · {q['en']} · {', '.join(reasons)}"
                        )
                    continue
                used = [k for k in _strings(a.get("source_keys")) if k in t.sources] or list(
                    t.sources
                )
                lines, stripped = strip_referral_tail(
                    {lang: _strings(a.get(lang)) for lang in LANGS}
                )
                self.report.referral_lines_removed += stripped
                kept.append(
                    {
                        "id": qid,
                        "t": t.key,
                        "sec": t.section,
                        "q": dict(q),
                        "a": lines,
                        "s": used,
                        "p": [],
                    }
                )
        self.report.answers_kept = len(kept)
        return kept

    async def paraphrases(self, entries: list[dict[str, Any]]) -> None:
        items: dict[str, Request] = {}
        chunks: dict[str, list[dict[str, Any]]] = {}
        by_topic: dict[str, list[dict[str, Any]]] = {}
        for e in entries:
            by_topic.setdefault(e["t"], []).append(e)
        # Chunks per topic: a topic whose answers change does not shift the other chunks.
        groups = [
            es[i : i + PARAPHRASE_GROUP]
            for es in by_topic.values()
            for i in range(0, len(es), PARAPHRASE_GROUP)
        ]
        for chunk in groups:
            gid = _sha(PROMPT_VERSION, *(e["id"] for e in chunk))[:20]
            chunks[gid] = chunk
            listed = "\n".join(
                f"{e['id']}: {e['q']['mr']} | {e['q']['hi']} | {e['q']['en']}" for e in chunk
            )
            items[gid] = Request(
                _cid("paraphrases", gid),
                _body(
                    self.cheap,
                    PARAPHRASE_PROMPT,
                    [{"type": "text", "text": f"<questions>\n{listed}\n</questions>"}],
                    PARAPHRASE_SCHEMA,
                    4000,
                    effort="low",
                ),
            )

        def parse(payload: dict[str, Any]) -> dict[str, Any]:
            got = {
                str(x.get("id")): _strings(x.get("paraphrases"))[:MAX_PARAPHRASES]
                for x in payload.get("items") or []
                if isinstance(x, dict)
            }
            return {"items": got}

        await self._send(
            "paraphrases", items, lambda k, r: self._record("paraphrases", k, r, parse)
        )
        for gid, chunk in chunks.items():
            rec = self.work.get("paraphrases", gid)
            if not rec or rec.get("status") != "done":
                self._error("paraphrases", rec)
                continue
            for e in chunk:
                e["p"] = rec["items"].get(e["id"], [])
                self.report.paraphrases += len(e["p"])

    async def build(self, topics: Sequence[QaTopic]) -> list[dict[str, Any]]:
        self.report.topics = len(topics)
        for t in topics:
            kind = t.key.split(":")[0]
            self.report.topics_by_kind[kind] = self.report.topics_by_kind.get(kind, 0) + 1
        drafted = await self.questions(topics)
        self.report.questions_drafted = sum(len(v) for v in drafted.values())
        flat = [(t.key, q) for t in topics for q in drafted.get(t.key, [])]
        kept_qs, removed = dedupe([q for _, q in flat])
        self.report.duplicates_removed = removed
        kept_ids = {id(q) for q in kept_qs}
        unique: dict[str, list[dict[str, str]]] = {}
        for key, q in flat:
            if id(q) in kept_ids:
                unique.setdefault(key, []).append(q)
        entries = await self.answers(topics, unique)
        await self.paraphrases(entries)
        return entries

    def usage(self) -> Usage:
        total = Usage()
        for rec in self.work.of_kind("usage"):
            total.add(str(rec["model"]), bool(rec.get("batch")), rec.get("usage") or {})
        return total


# The asset --------------------------------------------------------------------------------------


def asset(
    entries: Iterable[dict[str, Any]], sources: Mapping[str, tuple[str, str]], kind: str
) -> dict[str, Any]:
    out_entries = []
    used: set[str] = set()
    for e in entries:
        keys = index_keys(*(e["q"][lang] for lang in LANGS), *e.get("p", []))
        out_entries.append({**e, "k": keys})
        used.update(e["s"])
    return {
        "version": 1,
        "kind": kind,
        # Generated answers have had their closing "ask the KVK" line removed (once only).
        "tidy": kind == "generated",
        "langs": list(LANGS),
        "src": {k: {"t": sources[k][0], "u": sources[k][1]} for k in sorted(used) if k in sources},
        "entries": out_entries,
    }


def write_asset(data: Mapping[str, Any], path: Path) -> tuple[int, int]:
    """Compact JSON, gzipped with no timestamp (the same input gives the same bytes)."""
    raw = json.dumps(data, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode()
    packed = gzip.compress(raw, compresslevel=9, mtime=0)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(packed)
    return len(raw), len(packed)


def read_asset(path: Path) -> dict[str, Any]:
    data: dict[str, Any] = json.loads(gzip.decompress(path.read_bytes()))
    return data


def report_markdown(report: BuildReport, usage: Usage, mode: str) -> str:
    dollars = usage.dollars()
    lines = [
        "# Offline Q&A build",
        "",
        f"- Mode: {mode}",
        f"- Topics: {report.topics} ("
        + ", ".join(f"{k} {v}" for k, v in sorted(report.topics_by_kind.items()))
        + ")",
        f"- Questions drafted: {report.questions_drafted} · duplicates removed: "
        f"{report.duplicates_removed}",
        f"- Answers kept: {report.answers_kept} · dropped: "
        + (", ".join(f"{k} {v}" for k, v in sorted(report.answers_dropped.items())) or "0"),
        f"- Closing 'ask the KVK' lines removed: {report.referral_lines_removed}",
        f"- Seed entries kept (card texts): {report.seed_entries}",
        f"- Paraphrases: {report.paraphrases}",
        "- Errors (retried on the next run): "
        + (", ".join(f"{k}: {v}" for k, v in sorted(report.errors.items())) or "none"),
        f"- Asset: {report.asset_bytes / 1e6:.2f} MB gzipped "
        f"({report.asset_raw_bytes / 1e6:.2f} MB JSON)",
        "- Estimated cost (estimate from list prices, not a bill): "
        + (f"${dollars:.2f}" if dollars is not None else "unknown model price"),
        "",
        "| Model | Batch | Requests | Input | Cache write | Cache read | Output |",
        "|---|---|---|---|---|---|---|",
    ]
    for (model, batch), row in sorted(usage.rows.items()):
        lines.append(
            f"| {model} | {'yes' if batch else 'no'} | {row['requests']} | {row['input_tokens']} | "
            f"{row['cache_creation_input_tokens']} | {row['cache_read_input_tokens']} | "
            f"{row['output_tokens']} |"
        )
    if report.unreadable_sources:
        lines += ["", "## Sources not read", ""]
        lines += [f"- {k}: {v}" for k, v in sorted(report.unreadable_sources.items())]
    if report.skipped:
        lines += ["", "## Not included", ""] + [f"- {s}" for s in report.skipped]
    if report.dropped_examples:
        lines += ["", "## Dropped answers (first 40)", ""]
        lines += [f"- {x}" for x in report.dropped_examples]
    return "\n".join(lines) + "\n"


# The seed (no model) ----------------------------------------------------------------------------

SEED_TEMPLATES: tuple[tuple[str, dict[str, str]], ...] = (
    ("symptoms", {"mr": "{mr}: लक्षणे काय दिसतात?", "hi": "{hi}: क्या लक्षण दिखते हैं?",
                  "en": "{en}: what are the signs?"}),
    ("when", {"mr": "{mr}: कोणत्या काळात दिसून येते?", "hi": "{hi}: इसका मौसम कौन-सा है?",
              "en": "{en}: when does it come?"}),
    ("scouting", {"mr": "{mr}: बागेत पाहणी कशी करावी?", "hi": "{hi}: बाग में जाँच कैसे करें?",
                  "en": "{en}: how do I scout for it?"}),
    ("items", {"mr": "{mr}: काय उपाय करावेत?", "hi": "{hi}: क्या उपाय करें?",
               "en": "{en}: what should I do?"}),
)  # fmt: skip
SEED_MAX = 60
SEED_ITEMS = 6


def _short(label: str) -> str:
    return label.split(" (")[0].split(":")[0].strip()


def _no_paper(cards: Mapping[str, Any], keys: Sequence[str]) -> bool:
    srcs: Mapping[str, Any] = cards.get("sources", {})
    return not any(srcs.get(k, {}).get("publisher") in NEWSPAPER_PUBLISHERS for k in keys)


def build_seed(cards: Mapping[str, Any]) -> dict[str, Any]:
    """30-60 Q&A from the cards' own texts only (answers are card sentences, word for word);
    no model, no fetch."""
    srcs: Mapping[str, Any] = cards.get("sources", {})
    entries: list[dict[str, Any]] = []
    for sec in cards.get("sections", []):
        profile = sec.get("profile")
        if not profile:
            continue
        names = {lang: _short(sec["labels"].get(lang) or sec["labels"]["en"]) for lang in LANGS}
        for part, template in SEED_TEMPLATES:
            if part == "items":
                points = [i for i in sec.get("items", []) if _no_paper(cards, i["source_keys"])]
                points = points[:SEED_ITEMS]
            else:
                p = profile.get(part)
                points = [p] if p and _no_paper(cards, p["source_keys"]) else []
            if not points:
                continue
            # One card text per line, word for word (a test checks it).
            answer = {lang: [p["labels"][lang].strip() for p in points] for lang in LANGS}
            keys = list(dict.fromkeys(k for p in points for k in p["source_keys"]))
            q = {lang: template[lang].format(**names) for lang in LANGS}
            entries.append(
                {
                    "id": f"seed-{sec['key']}-{part}",
                    "t": f"section:{sec['key']}",
                    "sec": sec["key"],
                    "q": q,
                    "a": answer,
                    "s": keys,
                    "p": [],
                }
            )
            if len(entries) >= SEED_MAX:
                break
        if len(entries) >= SEED_MAX:
            break
    sources = {k: (str(v.get("title", k)), str(v.get("url", ""))) for k, v in srcs.items()}
    return asset(entries, sources, "seed")


def merge_seed(
    entries: Sequence[dict[str, Any]], cards: Mapping[str, Any]
) -> tuple[list[dict[str, Any]], int]:
    """The seed entries (card texts, word for word) first, then the generated ones whose
    question is not a near-duplicate of a seed question; returns (entries, generated dropped)."""
    seed = build_seed(cards)["entries"]
    plain = [{k: v for k, v in e.items() if k != "k"} for e in seed]
    kept, _ = dedupe([e["q"] for e in plain] + [e["q"] for e in entries])
    ids = {id(q) for q in kept}
    generated = [e for e in entries if id(e["q"]) in ids and not e["id"].startswith("seed-")]
    return [*plain, *generated], len(entries) - len(generated)


def finalise_asset(
    data: Mapping[str, Any], cards: Mapping[str, Any]
) -> tuple[dict[str, Any], dict[str, int]]:
    """A generated asset made final: closing referral lines removed from generated answers,
    the seed merged in, search keys rebuilt. Returns (asset, counts)."""
    generated = []
    removed = 0
    done = bool(data.get("tidy"))
    for e in data.get("entries", []):
        if e["id"].startswith("seed-"):
            continue
        lines, stripped = (e["a"], False) if done else strip_referral_tail(e["a"])
        removed += stripped
        generated.append({**{k: v for k, v in e.items() if k != "k"}, "a": lines})
    merged, dropped = merge_seed(generated, cards)
    sources = {k: (v["t"], v["u"]) for k, v in data.get("src", {}).items()}
    sources.update(
        {k: (str(v.get("title", k)), str(v.get("url", ""))) for k, v in cards["sources"].items()}
    )
    counts = {"referral_lines_removed": removed, "duplicates_of_seed": dropped}
    return asset(merged, sources, "generated"), counts


# CLI --------------------------------------------------------------------------------------------


def api_key(settings: Settings) -> tuple[str, str]:
    """(key, which name held it): ANTHROPIC_API_KEY first, then FEED_AI_API_KEY."""
    if value := os.environ.get("ANTHROPIC_API_KEY", "").strip():
        return value, "ANTHROPIC_API_KEY"
    if value := settings.feed_ai_api_key.get_secret_value().strip():
        return value, "FEED_AI_API_KEY"
    return "", ""


def recording_fetcher(http: httpx.AsyncClient, failed: dict[str, str]) -> Fetcher:
    seen: dict[str, tuple[str, str | None]] = {}

    async def fetch(url: str) -> tuple[str, str | None]:
        if url not in seen:
            seen[url] = await fetch_text(http, url)
            if seen[url][1]:
                failed[url] = str(seen[url][1])
        return seen[url]

    return fetch


async def gather_topics(  # noqa: PLR0913 - the build's inputs
    http: httpx.AsyncClient,
    settings: Settings,
    app_root: Path,
    *,
    schemes: bool,
    report: BuildReport,
    cards: Mapping[str, Any] | None = None,
    fetch: Fetcher | None = None,
) -> list[QaTopic]:
    limit = settings.feed_ai_max_source_chars
    fetcher = fetch or recording_fetcher(http, report.unreadable_sources)
    topics = await card_topics(cards or practice_cards(), fetcher, limit, stage_template_seeds())
    topics += label_topics()
    topics.append(fco_topic())
    topics += howto_topics(app_root)
    if schemes:
        topics += await scheme_topics(limit)
    else:
        report.skipped.append(
            "Government schemes: run with --schemes where the feed database is reachable (VPS)."
        )
    return topics


def all_sources(cards: Mapping[str, Any], topics: Sequence[QaTopic]) -> dict[str, tuple[str, str]]:
    out = {
        k: (str(v.get("title", k)), str(v.get("url", "")))
        for k, v in cards.get("sources", {}).items()
    }
    for t in topics:
        out.update(t.sources)
    return out


async def run_build(args: argparse.Namespace, settings: Settings) -> int:  # pragma: no cover
    key, name = api_key(settings)
    if not key:
        print("No API key: set ANTHROPIC_API_KEY or FEED_AI_API_KEY.", file=sys.stderr)
        return 2
    print(f"API key from {name}", file=sys.stderr)
    work_dir = Path(args.work)
    async with httpx.AsyncClient(follow_redirects=True) as http:
        report = BuildReport()
        topics = await gather_topics(
            http, settings, Path(args.app_root), schemes=args.schemes, report=report
        )
        client = ModelClient(
            http,
            api_key=key,
            base_url=settings.feed_ai_base_url,
            mode=args.mode,
            concurrency=args.concurrency,
            poll_seconds=args.poll_seconds,
            read_seconds=settings.feed_article_timeout_seconds,
        )
        builder = Builder(
            client,
            WorkFile(work_dir / "qa_work.jsonl"),
            strong_model=settings.feed_summarise_model,
            cheap_model=settings.feed_classify_model,
            max_tokens=settings.feed_article_max_tokens,
            log=lambda m: print(m, file=sys.stderr),
        )
        builder.report = report
        entries = await builder.build(topics)
    return finish(builder, entries, all_sources(practice_cards(), topics), args, work_dir)


def finish(
    builder: Builder,
    entries: list[dict[str, Any]],
    sources: Mapping[str, tuple[str, str]],
    args: argparse.Namespace,
    work_dir: Path,
) -> int:
    report = builder.report
    if not entries:
        print("No answer passed the checks: the asset was not written.", file=sys.stderr)
        code = 1
    else:
        merged, dropped = merge_seed(entries, practice_cards())
        report.seed_entries = len(merged) - (len(entries) - dropped)
        raw, packed = write_asset(asset(merged, sources, "generated"), Path(args.out))
        report.asset_raw_bytes, report.asset_bytes = raw, packed
        code = 0
    usage = builder.usage()
    text = report_markdown(report, usage, builder.client.mode)
    (work_dir / "qa_build_report.md").write_text(text, encoding="utf-8")
    (work_dir / "qa_build_cost.json").write_text(
        json.dumps(usage.as_json(), indent=1), encoding="utf-8"
    )
    print(text)
    return code


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="python -m bagmitra_api.kb.qa_build")
    sub = p.add_subparsers(dest="command", required=True)
    b = sub.add_parser("build", help="generate the Q&A asset with the Anthropic API")
    b.add_argument(
        "--out", required=True, help="asset path, e.g. ../app/assets/config/qa_kb.json.gz"
    )
    b.add_argument("--work", default="qa_work", help="folder of the resumable work file and report")
    b.add_argument("--app-root", default="../app", help="the app folder (screen strings)")
    b.add_argument("--mode", choices=("batch", "concurrent"), default="batch")
    b.add_argument("--concurrency", type=int, default=8)
    b.add_argument("--poll-seconds", type=float, default=30.0)
    b.add_argument("--schemes", action="store_true", help="add official feed items (database)")
    s = sub.add_parser("seed", help="write the seed asset from the card texts (no model)")
    s.add_argument("--out", required=True)
    f = sub.add_parser(
        "finalise", help="tidy a generated asset (closing KVK lines, seed merged), no model"
    )
    f.add_argument("--asset", required=True)
    return p


def main(argv: list[str]) -> int:  # pragma: no cover - thin CLI wrapper
    args = parser().parse_args(argv)
    if args.command == "seed":
        raw, packed = write_asset(build_seed(practice_cards()), Path(args.out))
        print(f"seed written: {raw} bytes JSON, {packed} bytes gzipped")
        return 0
    if args.command == "finalise":
        data, counts = finalise_asset(read_asset(Path(args.asset)), practice_cards())
        raw, packed = write_asset(data, Path(args.asset))
        print(json.dumps({**counts, "entries": len(data["entries"]), "json_bytes": raw,
                          "gz_bytes": packed}))  # fmt: skip
        return 0
    return asyncio.run(run_build(args, get_settings()))


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv[1:]))
