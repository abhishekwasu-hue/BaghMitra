""" "Check this message" (addendum v1.4 §2, G3): does a pasted forward match an official item?

Rules, not AI. From the pasted text we read GR numbers and portal unique codes, full dates,
money amounts and scheme names (the output check's normalisation: Devanagari digits, digit
grouping, ₹ / lakh / crore) and compare them with published official items only:

- `exact`: the item's GR number or unique code appears in the text (spacing and punctuation
  ignored, Devanagari and ASCII digits equal);
- title: share of the item's title words found in the text, a word also counting when a
  close spelling is there (difflib; Devanagari vowel signs kept inside words);
- corroboration: one of the item's dates or amounts is in the text; a scheme name of the
  glossary named by both;
- `details_differ`: the text states an amount and none of the item's amounts.

Verdicts: `official_match` (exact, or a strong title match corroborated by a date or an
amount, and no amount that differs), `possible_match` (something matches but not enough, or
an amount differs), `no_official_match`. The wording never calls a message fake or false: the
note always sends the farmer to the official portal. The text is never stored.
"""

from __future__ import annotations

import difflib
import re
import time
import uuid
from collections import deque
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from datetime import date
from typing import Literal

from bagmitra_api.feed.output_check import normalise, text_facts

MAX_TEXT_CHARS = 4000
# A GR number / code shorter than this (after compaction) is too common to prove anything.
MIN_CODE_CHARS = 6
# Title share needed for a possible match, and for an official one (with corroboration).
TITLE_POSSIBLE = 0.5
TITLE_STRONG = 0.75
# Words shorter than this are compared exactly; longer ones also by close spelling.
FUZZY_MIN_CHARS = 4
FUZZY_CUTOFF = 0.8
# Score weights (the score orders matches; the verdict follows the rules above).
W_TITLE, W_DATE, W_AMOUNT, W_SCHEME = 0.7, 0.15, 0.15, 0.1

Verdict = Literal["official_match", "possible_match", "no_official_match"]

NOTES: dict[str, dict[str, str]] = {
    "official_match": {
        "en": "This matches an official item in BagMitra. Compare every detail with the "
        "official GR before acting.",
        "mr": "हा संदेश BagMitra मधील अधिकृत नोंदीशी जुळतो. कोणतीही कृती करण्यापूर्वी अधिकृत "
        "शासन निर्णय (GR) मधील सर्व तपशील तपासा.",
        "hi": "यह संदेश BagMitra की एक आधिकारिक जानकारी से मेल खाता है। कोई भी कदम उठाने से "
        "पहले आधिकारिक GR में सभी विवरण जाँचें।",
    },
    "possible_match": {
        "en": "Some details are similar to an official item in BagMitra, but not all of them "
        "match. Check the official portal before acting.",
        "mr": "काही तपशील BagMitra मधील अधिकृत नोंदीसारखे आहेत, पण सर्व जुळत नाहीत. कोणतीही "
        "कृती करण्यापूर्वी अधिकृत पोर्टल तपासा.",
        "hi": "कुछ विवरण BagMitra की एक आधिकारिक जानकारी से मिलते हैं, लेकिन सभी नहीं। कोई भी "
        "कदम उठाने से पहले आधिकारिक पोर्टल देखें।",
    },
    "no_official_match": {
        "en": "No matching official GR found in BagMitra. Check the official portal before acting.",
        "mr": "BagMitra मध्ये जुळणारा अधिकृत शासन निर्णय (GR) सापडला नाही. कोणतीही कृती "
        "करण्यापूर्वी अधिकृत पोर्टल तपासा.",
        "hi": "BagMitra में कोई मेल खाता आधिकारिक GR नहीं मिला। कोई भी कदम उठाने से पहले "
        "आधिकारिक पोर्टल देखें।",
    },
}

# Letters, digits and Devanagari (incl. vowel signs and virama; not the danda punctuation).
_WORD = re.compile(r"(?:[^\W_]|[ऀ-ॣ०-ॿ])+")
_STOPWORDS = frozenset(
    (
        *("a", "an", "and", "the", "of", "for", "to", "in", "on", "by", "at", "is", "are"),
        *("be", "with", "from", "or", "as", "this", "that", "it", "its"),
        *("व", "आणि", "या", "ला", "ची", "चा", "चे", "ने", "त", "ही", "हा", "आहे", "साठी"),
        *("के", "की", "का", "को", "में", "से", "और", "है", "पर", "यह"),
    )
)


@dataclass(frozen=True, slots=True)
class Candidate:
    """A published official item as the matcher sees it."""

    id: uuid.UUID
    titles: Mapping[str, str]  # lang -> title
    summaries: Sequence[str]
    gr_number: str | None
    external_id: str | None
    published: date
    dates: frozenset[date]  # deadline, validity, payment
    url: str


@dataclass(frozen=True, slots=True)
class Match:
    candidate: Candidate
    score: float
    exact: bool
    details_differ: bool
    verdict: Verdict


@dataclass(frozen=True, slots=True)
class CheckResult:
    verdict: Verdict
    matches: list[Match]


def _compact(text: str) -> str:
    return "".join(_WORD.findall(normalise(text)))


def _words(text: str) -> list[str]:
    return [w for w in _WORD.findall(normalise(text)) if w not in _STOPWORDS]


@dataclass(frozen=True, slots=True)
class _Message:
    compact: str
    words: frozenset[str]
    by_initial: Mapping[str, Sequence[str]]
    dates: frozenset[str]
    amounts: frozenset[float]
    norm: str

    @classmethod
    def read(cls, text: str) -> _Message:
        text = text[:MAX_TEXT_CHARS]
        words = frozenset(_words(text))
        by_initial: dict[str, list[str]] = {}
        for word in words:
            if len(word) >= FUZZY_MIN_CHARS:
                by_initial.setdefault(word[0], []).append(word)
        facts = text_facts(text)
        return cls(_compact(text), words, by_initial, facts.dates, facts.amounts, normalise(text))

    def has_word(self, word: str) -> bool:
        if word in self.words:
            return True
        if len(word) < FUZZY_MIN_CHARS:
            return False
        near = self.by_initial.get(word[0], ())
        return bool(difflib.get_close_matches(word, near, n=1, cutoff=FUZZY_CUTOFF))


def _title_share(message: _Message, title: str) -> float:
    words = list(dict.fromkeys(_words(title)))
    if not words:
        return 0.0
    return sum(message.has_word(w) for w in words) / len(words)


def _exact(message: _Message, candidate: Candidate) -> bool:
    for code in (candidate.gr_number, candidate.external_id):
        compact = _compact(code or "")
        if len(compact) >= MIN_CODE_CHARS and compact in message.compact:
            return True
    return False


def _names_scheme(message: _Message, text: str, glossary: Mapping[str, Sequence[str]]) -> bool:
    norm = normalise(text)
    for canonical, aliases in glossary.items():
        names = [normalise(n) for n in (canonical, *aliases)]
        if any(n in message.norm for n in names) and any(n in norm for n in names):
            return True
    return False


def _score(
    message: _Message, candidate: Candidate, glossary: Mapping[str, Sequence[str]]
) -> Match | None:
    if not candidate.titles:
        return None
    title = max(_title_share(message, t) for t in candidate.titles.values())
    exact = _exact(message, candidate)
    item_text = " ".join([*candidate.titles.values(), *candidate.summaries])
    item_dates = {d.isoformat() for d in (candidate.published, *candidate.dates)}
    date_hit = bool(item_dates & message.dates)
    item_amounts = text_facts(item_text).amounts
    amount_hit = bool(item_amounts & message.amounts)
    differ = bool(message.amounts) and not amount_hit
    scheme = _names_scheme(message, item_text, glossary)
    verdict: Verdict
    if (exact or (title >= TITLE_STRONG and (date_hit or amount_hit))) and not differ:
        verdict = "official_match"
    elif exact or title >= TITLE_POSSIBLE or scheme:
        verdict = "possible_match"
    else:
        return None
    if exact and not differ:
        score = 1.0
    else:
        score = W_TITLE * title + W_DATE * date_hit + W_AMOUNT * amount_hit + W_SCHEME * scheme
        score = min(score, 0.99)
    return Match(candidate, round(score, 2), exact, differ, verdict)


def check_message(
    text: str,
    candidates: Sequence[Candidate],
    *,
    glossary: Mapping[str, Sequence[str]] | None = None,
    limit: int = 3,
) -> CheckResult:
    """Best matches first (official before possible, then by score). The text is cut to
    MAX_TEXT_CHARS; nothing about it is kept."""
    message = _Message.read(text)
    found = [m for c in candidates if (m := _score(message, c, glossary or {})) is not None]
    found.sort(key=lambda m: (m.verdict == "official_match", m.score), reverse=True)
    best = found[:limit]
    return CheckResult(best[0].verdict if best else "no_official_match", best)


def note(verdict: str, lang: str) -> str:
    texts = NOTES[verdict]
    return texts.get(lang, texts["en"])


class RateLimiter:
    """In-memory sliding window per key (one API process; resets on restart)."""

    def __init__(
        self,
        limit: int,
        window_seconds: float,
        clock: Callable[[], float] = time.monotonic,
        max_keys: int = 10_000,
    ) -> None:
        if limit < 1:
            raise ValueError("limit must be at least 1")
        self._limit = limit
        self._window = window_seconds
        self._clock = clock
        self._max_keys = max_keys
        self._hits: dict[str, deque[float]] = {}

    def keys(self) -> list[str]:
        return list(self._hits)

    def _prune(self, now: float) -> None:
        for key in [k for k, hits in self._hits.items() if hits[-1] <= now - self._window]:
            del self._hits[key]

    def allow(self, key: str) -> bool:
        now = self._clock()
        hits = self._hits.get(key)
        if hits is None:
            if len(self._hits) >= self._max_keys:
                self._prune(now)
            hits = self._hits[key] = deque()
        while hits and hits[0] <= now - self._window:
            hits.popleft()
        if len(hits) >= self._limit:
            return False
        hits.append(now)
        return True
