"""Output check for feed summaries and scheme cards (addendum v1.4 §6).

Every number, amount, date and scheme name in a summary or card must appear in the source
text. Matching is done on normalised values, not on spelling: Devanagari digits, Indian
digit grouping (1,00,000), lakh / crore / thousand units and the common date formats
(26/10/2026, 2026-10-26, 26 October 2026, २६ ऑक्टोबर २०२६) compare equal. Anything that does
not match is returned as a mismatch and the item goes (back) to review. Scheme names are
checked through a glossary: a summary that names a scheme must have one of that scheme's
names in the source.
"""

from __future__ import annotations

import re
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal
from typing import Any

NOT_STATED = "not_stated"

# Devanagari and the other Indic scripts' digits (Bengali, Gurmukhi, Gujarati, Oriya, Tamil,
# Telugu, Kannada, Malayalam) read as ASCII digits. One character for one, so offsets stay.
_INDIC_ZEROS = (0x0966, 0x09E6, 0x0A66, 0x0AE6, 0x0B66, 0x0BE6, 0x0C66, 0x0CE6, 0x0D66)
_DEVANAGARI_DIGITS = str.maketrans({zero + d: str(d) for zero in _INDIC_ZEROS for d in range(10)})

_MONTHS: dict[str, int] = {}
for _number, _names in enumerate(
    (
        ("january", "jan", "जानेवारी", "जनवरी"),
        ("february", "feb", "फेब्रुवारी", "फेब्रुवरी", "फरवरी", "फ़रवरी", "\u095eरवरी"),
        ("march", "mar", "मार्च"),
        ("april", "apr", "एप्रिल", "एप्रील", "अप्रैल", "अप्रेल"),
        ("may", "मे", "मई"),
        ("june", "jun", "जून"),
        ("july", "jul", "जुलै", "जुलाई"),
        ("august", "aug", "ऑगस्ट", "ऑगष्ट", "अगस्त"),
        ("september", "sept", "sep", "सप्टेंबर", "सप्टेबर", "सितंबर", "सितम्बर"),
        ("october", "oct", "ऑक्टोबर", "ऑक्टोंबर", "अक्टूबर", "अक्तूबर"),
        ("november", "nov", "नोव्हेंबर", "नोव्हेबर", "नवंबर", "नवम्बर"),
        ("december", "dec", "डिसेंबर", "डिसेबर", "दिसंबर", "दिसम्बर"),
    ),
    start=1,
):
    for _name in _names:
        _MONTHS[_name] = _number

_MONTH = "|".join(sorted(map(re.escape, _MONTHS), key=len, reverse=True))
_ORD = r"(?:st|nd|rd|th)?"
# A dot right before the day is allowed after a letter ("दि.19.04.2023", the usual GR form),
# not after a digit (so "1.19.04.2023" is no date). One space may stand around a separator.
_NUMERIC_DMY = re.compile(r"(?<!\d)(?<!\d\.)(\d{1,2}) ?[/.\-] ?(\d{1,2}) ?[/.\-] ?(\d{4})(?!\d)")
_NUMERIC_YMD = re.compile(r"(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)")
_DAY_MONTH_YEAR = re.compile(
    rf"(?<!\d)(\d{{1,2}}){_ORD}\s*(?:of\s+|[-/]\s*)?({_MONTH})\.?,?\s*[-/]?\s*(\d{{4}})(?!\d)",
    re.IGNORECASE,
)
_MONTH_DAY_YEAR = re.compile(
    rf"(?<![^\W\d_])({_MONTH})\.?\s+(\d{{1,2}}){_ORD},?\s+(\d{{4}})(?!\d)", re.IGNORECASE
)
_MONTH_YEAR = re.compile(rf"(?<![^\W\d_])({_MONTH})\.?,?\s+(\d{{4}})(?!\d)", re.IGNORECASE)
# A day and month WITHOUT a year, as news pages state them ("१२ नोव्हेंबरला", "12 नोव्हेंबर
# रोजी", "Nov 12"). Read in the source only, where it vouches for that day and month in the
# item's own year (`SourceIndex.build(year=...)`). A Marathi ending written onto the month
# (ला / रोजी / पासून / पर्यंत) is allowed; any other letter or vowel sign right after it is
# not ("12 में" is Hindi "in 12", not 12 May). English "may" counts only before the day is
# named ("12 May"): "may 15" is left out, as in "farmers may 15 days ...".
_NOT_AFTER_WORD = r"(?![\w\u0900-\u0963\u0970-\u097f])"
_DATE_ENDING = r"(?:ला|रोजी|पासून|पर्यंत)?"
_DAY_MONTH = re.compile(
    rf"(?<!\d)(?<!\d\.)(\d{{1,2}}){_ORD}\s*(?:of\s+|[-/]\s*)?({_MONTH})\.?{_DATE_ENDING}"
    rf"{_NOT_AFTER_WORD}",
    re.IGNORECASE,
)
_MONTH_DAY = re.compile(
    rf"(?<![\w\u0900-\u097f])(?!may\b)({_MONTH})\.?\s+(\d{{1,2}}){_ORD}{_DATE_ENDING}"
    rf"{_NOT_AFTER_WORD}(?!\.?\d)",
    re.IGNORECASE,
)

_UNITS = {
    "lakh": 100_000,
    "lakhs": 100_000,
    "lac": 100_000,
    "lacs": 100_000,
    "लाख": 100_000,
    "crore": 10_000_000,
    "crores": 10_000_000,
    "cr": 10_000_000,
    "कोटी": 10_000_000,
    "करोड़": 10_000_000,
    "करोड": 10_000_000,
    "करोड़": 10_000_000,  # करोड़ with the precomposed ड़ (U+095C)
    "thousand": 1_000,
    "हजार": 1_000,
    "हज़ार": 1_000,
    "हज़ार": 1_000,  # हज़ार with the precomposed ज़ (U+095B)
}
_UNIT = "|".join(sorted(map(re.escape, _UNITS), key=len, reverse=True))
_CURRENCY = r"(?:₹|rs\.?|inr|रु\.?|रुपये|रुपए)"
_NUMBER = re.compile(
    rf"(?P<cur>{_CURRENCY}\s*)?(?<![\d.,])(?P<num>\d{{1,3}}(?:,\d{{2,3}})+(?:\.\d+)?|\d+(?:\.\d+)?)"
    rf"(?:\s*(?P<unit>{_UNIT})(?![^\W\d_]))?",
    re.IGNORECASE,
)
# Marathi and Hindi number words that appear before हजार / लाख / कोटी in government news.
_WORDS: dict[str, int] = {
    "एक": 1, "दोन": 2, "दो": 2, "तीन": 3, "चार": 4, "पाच": 5, "पांच": 5, "पाँच": 5,
    "सहा": 6, "छह": 6, "सात": 7, "आठ": 8, "नऊ": 9, "नौ": 9, "दहा": 10, "दस": 10,
    "अकरा": 11, "बारा": 12, "तेरा": 13, "चौदा": 14, "पंधरा": 15, "सोळा": 16, "सतरा": 17,
    "अठरा": 18, "एकोणीस": 19, "वीस": 20, "बीस": 20, "पंचवीस": 25, "पच्चीस": 25,
    "तीस": 30, "चाळीस": 40, "चालीस": 40, "पन्नास": 50, "पचास": 50, "साठ": 60,
    "सत्तर": 70, "ऐंशी": 80, "अस्सी": 80, "नव्वद": 90, "नब्बे": 90,
}  # fmt: skip
_UNIT_WORDS = "|".join(sorted((u for u in _UNITS if not u.isascii()), key=len, reverse=True))
_WORD_BEFORE_UNIT = re.compile(
    rf"(?<![^\W\d_])({'|'.join(sorted(map(re.escape, _WORDS), key=len, reverse=True))})"
    rf"\s+({_UNIT_WORDS})"
)
# English words before a unit (card check 2026-11-10: PDKV wrote "Seventy per cent agro-net").
_EN_SMALL = [
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "ten",
    "eleven",
    "twelve",
    "thirteen",
    "fourteen",
    "fifteen",
    "sixteen",
    "seventeen",
    "eighteen",
    "nineteen",
]
_EN_TENS = ["twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
_EN_WORDS_BEFORE_UNIT = re.compile(
    rf"\b(?:({'|'.join(_EN_TENS)})(?:[\s-]({'|'.join(_EN_SMALL[1:10])}))?"
    rf"|({'|'.join(sorted(_EN_SMALL, key=len, reverse=True))}))"
    r"(?=\s*(?:per\s?cent|%|thousand|lakhs?|crores?)\b|\s*%)"
)


def _english_value(m: re.Match[str]) -> str:
    if m[3]:
        return str(_EN_SMALL.index(m[3]))
    return str((_EN_TENS.index(m[1]) + 2) * 10 + (_EN_SMALL.index(m[2]) if m[2] else 0))


# The units of a number spelt in parts: Marathi, Hindi (हज़ार / करोड़ with the nukta as a
# combining sign or precomposed, or without it) and English. VPS 2026-11-14: the source wrote
# "1 लाख 29 हजार", the English article "1 lakh 29 thousand"; only Devanagari parts were joined,
# so en read 100000 and 29000 where the source and mr read 129000. Not "cr", not "hundred".
_PART_UNITS = {unit: scale for unit, scale in _UNITS.items() if unit != "cr"}
_PART_UNIT = "|".join(
    re.escape(u) + ("(?![a-z])" if u.isascii() else "")  # "lakh" only as a whole word
    for u in sorted(_PART_UNITS, key=len, reverse=True)
)
# A number spelt in parts: "८८ कोटी १९ लाख", "३ लाख ६५ हजार ११", "१ हजार ६००",
# "1 lakh 29 thousand", "88 crore 19 lakh".
_PARTS = re.compile(
    rf"(?<![\d.,])\d{{1,3}} (?:{_PART_UNIT})(?: \d{{1,2}} (?:{_PART_UNIT}))*"
    rf"(?: (\d{{1,3}})(?![\d,]|\.\d| ?(?:{_PART_UNIT})))?"
)
_PART = re.compile(rf"(\d+) ({_PART_UNIT})")


def _join_parts(m: re.Match[str]) -> str | None:
    """One number for a number spelt in parts, when the parts are in falling order and each
    fits below the one before (lakh and thousand counts below 100). A trailing plain number is
    the rest below a thousand only after a thousand part: three digits after a thousand alone
    ("१ हजार ६००"), one to three after a lakh / crore chain ("३ लाख ६५ हजार ११", Mahasamvad
    style). Exact sums only; anything else stays as written (None). The same rules in every
    language, on the source and on the output alike.

    A joined number is one value: its parts do not vouch for themselves ("1 लाख 29 हजार" in
    the source vouches for 129000 only, never for "1 lakh", "29 thousand", 1 or 29 alone), and
    it is a unit-multiplied amount, as "1.29 lakh" is (`TextFacts.amounts`)."""
    parts = [(int(n), _PART_UNITS[u]) for n, u in _PART.findall(m[0])]
    rest = m[1]
    scales = [scale for _, scale in parts]
    if scales != sorted(set(scales), reverse=True):
        return None
    if any(n >= 100 for n, _ in parts[1:]):
        return None
    if rest is not None and (scales[-1] != 1_000 or (len(parts) == 1 and len(rest) != 3)):
        return None
    if len(parts) == 1 and rest is None:
        return None
    return str(sum(n * scale for n, scale in parts) + int(rest or 0))


_PLAIN_NUMBER = re.compile(r"\d+(?:,\d{2,3})*(?:\.\d+)?")


@dataclass(frozen=True, slots=True)
class Mismatch:
    kind: str  # number | amount | date | scheme_name | missing_page
    text: str
    where: str

    def as_dict(self) -> dict[str, str]:
        return {"kind": self.kind, "text": self.text, "where": self.where}


@dataclass(slots=True)
class _Facts:
    dates: set[str] = field(default_factory=set)
    dates_found: list[tuple[str, str]] = field(default_factory=list)
    spans: list[tuple[int, int]] = field(default_factory=list)  # of the dates, in normalised text
    numbers: list[tuple[str, float, bool]] = field(default_factory=list)


def _number_words(text: str) -> tuple[str, list[tuple[int, int]]]:
    """Number words before a unit become digits ("पाच हजार" -> "5 हजार"), and the "N lakh M
    thousand" / "N thousand MMM" forms become one number ("१ हजार ६००" -> "1600"); also the
    spans of those joined numbers in the result. VPS 2026-11-09: Mahasamvad wrote "पाच हजार
    रुपयांची" and "१ हजार ६०० जनावरांची" and held two correct articles. A word counts only right
    before हजार / लाख / कोटी (so "साठी" is not 60 and a bare "पाच दिवसांत" is not read)."""
    text = _WORD_BEFORE_UNIT.sub(lambda m: f"{_WORDS[m[1]]} {m[2]}", text)
    text = _EN_WORDS_BEFORE_UNIT.sub(_english_value, text)
    out: list[str] = []
    joined: list[tuple[int, int]] = []
    pos = length = 0
    for m in _PARTS.finditer(text):
        value = _join_parts(m)
        if value is None:
            continue
        length += m.start() - pos
        joined.append((length, length + len(value)))
        length += len(value)
        out += [text[pos : m.start()], value]
        pos = m.end()
    out.append(text[pos:])
    return "".join(out), joined


def _normalised(text: str) -> tuple[str, list[tuple[int, int]]]:
    flat = re.sub(r"\s+", " ", text.translate(_DEVANAGARI_DIGITS)).strip().lower()
    return _number_words(flat)


def normalise(text: str) -> str:
    """Devanagari digits to ASCII, number words before a unit to digits, a number spelt in
    parts to one number, unified whitespace, lower case."""
    return _normalised(text)[0]


def _date_key(year: int, month: int, day: int) -> str | None:
    try:
        return date(year, month, day).isoformat()
    except ValueError:
        return None


def _scan(text: str) -> _Facts:
    """Dates (full and month-year) and numbers in `text`. Date spans are blanked before
    numbers are read, so a date's parts are not reported again as plain numbers."""
    facts = _Facts()
    norm, joined = _normalised(text)
    spans = facts.spans

    def add_date(start: int, end: int, key: str | None) -> None:
        if key is None or any(s <= start < e for s, e in spans):
            return
        spans.append((start, end))
        facts.dates.add(key)
        if len(key) == 10:
            facts.dates.add(key[:7])  # a full date also vouches for its month-year
        facts.dates_found.append((norm[start:end], key))

    for m in _NUMERIC_DMY.finditer(norm):
        add_date(m.start(), m.end(), _date_key(int(m[3]), int(m[2]), int(m[1])))
    for m in _NUMERIC_YMD.finditer(norm):
        add_date(m.start(), m.end(), _date_key(int(m[1]), int(m[2]), int(m[3])))
    for m in _DAY_MONTH_YEAR.finditer(norm):
        add_date(m.start(), m.end(), _date_key(int(m[3]), _MONTHS[m[2].lower()], int(m[1])))
    for m in _MONTH_DAY_YEAR.finditer(norm):
        add_date(m.start(), m.end(), _date_key(int(m[3]), _MONTHS[m[1].lower()], int(m[2])))
    for m in _MONTH_YEAR.finditer(norm):
        add_date(m.start(), m.end(), f"{int(m[2]):04d}-{_MONTHS[m[1].lower()]:02d}")

    blanked = list(norm)
    for start, end in spans:
        blanked[start:end] = " " * (end - start)
    for m in _NUMBER.finditer("".join(blanked)):
        # Decimal: "1.15 लाख" is exactly 115000 (as a float product it is 114999.99999999999).
        unit = (m["unit"] or "").lower()
        value = Decimal(m["num"].replace(",", "")) * _UNITS.get(unit, 1)
        start = m.start("num")  # a number joined from parts is an amount (`_join_parts`)
        is_amount = bool(m["cur"] or unit or any(s <= start < e for s, e in joined))
        facts.numbers.append((m[0].strip(), float(value), is_amount))
    return facts


@dataclass(frozen=True, slots=True)
class TextFacts:
    """Full dates (ISO) and money amounts (₹ / lakh / crore, unit-multiplied) in a text."""

    dates: frozenset[str]
    amounts: frozenset[float]


def day_months(text: str) -> list[tuple[str, int, int]]:
    """(as written, normalised; month; day) of every day-and-month WITHOUT a year in `text`. A
    day and month that is part of a full date ("12 नोव्हेंबर 2026") is not one."""
    return _day_months(normalise(text), _scan(text).spans)


def _day_months(norm: str, spans: Sequence[tuple[int, int]]) -> list[tuple[str, int, int]]:
    found = [(m.start(), m.end(), m[0], m[2], m[1]) for m in _DAY_MONTH.finditer(norm)]
    found += [(m.start(), m.end(), m[0], m[1], m[2]) for m in _MONTH_DAY.finditer(norm)]
    out = []
    for start, end, raw, month, day in sorted(found):
        if not any(s < end and start < e for s, e in spans):
            out.append((raw, _MONTHS[month.lower()], int(day)))
    return out


def text_facts(text: str) -> TextFacts:
    """The dates and amounts the output check reads, for other matchers (e.g. "Check this
    message"): same normalisation of Devanagari digits, digit grouping and units."""
    facts = _scan(text)
    return TextFacts(
        frozenset(k for k in facts.dates if len(k) == 10),
        frozenset(v for _, v, is_amount in facts.numbers if is_amount),
    )


def _contains(haystack: str, needle: str) -> bool:
    return bool(needle) and normalise(needle) in haystack


@dataclass(frozen=True, slots=True)
class SourceIndex:
    text: str
    dates: frozenset[str]
    values: frozenset[float]

    @classmethod
    def build(cls, source: str, *, year: int | None = None) -> SourceIndex:
        """Values the source vouches for: plain numbers (also the parts of its dates, so a year
        or a day mentioned alone still matches) and unit-multiplied amounts.

        `year` (the item's own published year): a day and month the source states without a
        year ("१२ नोव्हेंबरला") also vouches for that full date in exactly this year; never in
        another year, never for another day or month (VPS 2026-11-13: news pages seldom repeat
        the year, while the writer must give key_dates as YYYY-MM-DD)."""
        norm = normalise(source)
        facts = _scan(source)
        values = {float(n.replace(",", "")) for n in _PLAIN_NUMBER.findall(norm)}
        values |= {value for _, value, _ in facts.numbers}
        dates = set(facts.dates)
        if year is not None:
            for _raw, month, day in _day_months(norm, facts.spans):
                key = _date_key(year, month, day)
                if key is not None:
                    dates.add(key)
        return cls(norm, frozenset(dates), frozenset(values))


def _check_text(index: SourceIndex, text: str, where: str) -> list[Mismatch]:
    facts = _scan(text)
    out = [Mismatch("date", raw, where) for raw, key in facts.dates_found if key not in index.dates]
    for raw, value, is_amount in facts.numbers:
        if value not in index.values:
            out.append(Mismatch("amount" if is_amount else "number", raw, where))
    return out


def _check_schemes(
    index: SourceIndex, text: str, where: str, glossary: Mapping[str, Sequence[str]]
) -> list[Mismatch]:
    norm = normalise(text)
    out = []
    for canonical, aliases in glossary.items():
        names = [canonical, *aliases]
        named = [n for n in names if _contains(norm, n)]
        if named and not any(_contains(index.text, n) for n in names):
            out.append(Mismatch("scheme_name", named[0], where))
    return out


def check_output(
    source_text: str,
    texts: Mapping[str, str | None],
    *,
    card_fields: Mapping[str, Mapping[str, Any]] | None = None,
    scheme_glossary: Mapping[str, Sequence[str]] | None = None,
    year: int | None = None,
) -> list[Mismatch]:
    """Mismatches between generated text and its source; empty means every checked claim was
    found. `texts` maps a location (e.g. "mr.summary", "deadline") to the text shown there.
    `year`: the item's published year, for source dates stated without one (`SourceIndex`)."""
    index = SourceIndex.build(source_text, year=year)
    glossary = scheme_glossary or {}
    out: list[Mismatch] = []
    for where, text in texts.items():
        if text:
            out += _check_text(index, text, where)
            out += _check_schemes(index, text, where, glossary)
    for name, entry in (card_fields or {}).items():
        value = str(entry.get("value") or NOT_STATED)
        if value == NOT_STATED:
            continue
        where = f"card.{name}"
        if not entry.get("page"):
            out.append(Mismatch("missing_page", value, where))
        out += _check_text(index, value, where)
        out += _check_schemes(index, value, where, glossary)
        if name == "scheme_name" and not _known_name(index, value, glossary):
            out.append(Mismatch("scheme_name", value, where))
    return _unique(out)


def _known_name(index: SourceIndex, value: str, glossary: Mapping[str, Sequence[str]]) -> bool:
    if _contains(index.text, value):
        return True
    for canonical, aliases in glossary.items():
        names = [canonical, *aliases]
        if any(normalise(n) == normalise(value) for n in names):
            return any(_contains(index.text, n) for n in names)
    return False


def _unique(items: Iterable[Mismatch]) -> list[Mismatch]:
    return list(dict.fromkeys(items))
