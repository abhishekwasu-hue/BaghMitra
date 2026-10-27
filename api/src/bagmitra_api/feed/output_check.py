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
from typing import Any

NOT_STATED = "not_stated"

_DEVANAGARI_DIGITS = str.maketrans("०१२३४५६७८९", "0123456789")

_MONTHS: dict[str, int] = {}
for _number, _names in enumerate(
    (
        ("january", "jan", "जानेवारी", "जनवरी"),
        ("february", "feb", "फेब्रुवारी", "फरवरी"),
        ("march", "mar", "मार्च"),
        ("april", "apr", "एप्रिल", "अप्रैल"),
        ("may", "मे", "मई"),
        ("june", "jun", "जून"),
        ("july", "jul", "जुलै", "जुलाई"),
        ("august", "aug", "ऑगस्ट", "अगस्त"),
        ("september", "sept", "sep", "सप्टेंबर", "सितंबर", "सितम्बर"),
        ("october", "oct", "ऑक्टोबर", "अक्टूबर", "अक्तूबर"),
        ("november", "nov", "नोव्हेंबर", "नवंबर", "नवम्बर"),
        ("december", "dec", "डिसेंबर", "दिसंबर", "दिसम्बर"),
    ),
    start=1,
):
    for _name in _names:
        _MONTHS[_name] = _number

_MONTH = "|".join(sorted(map(re.escape, _MONTHS), key=len, reverse=True))
_ORD = r"(?:st|nd|rd|th)?"
_NUMERIC_DMY = re.compile(r"(?<![\d.])(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})(?!\d)")
_NUMERIC_YMD = re.compile(r"(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)")
_DAY_MONTH_YEAR = re.compile(
    rf"(?<!\d)(\d{{1,2}}){_ORD}\s*(?:of\s+)?({_MONTH})\.?,?\s*(\d{{4}})(?!\d)", re.IGNORECASE
)
_MONTH_DAY_YEAR = re.compile(
    rf"(?<![^\W\d_])({_MONTH})\.?\s+(\d{{1,2}}){_ORD},?\s+(\d{{4}})(?!\d)", re.IGNORECASE
)
_MONTH_YEAR = re.compile(rf"(?<![^\W\d_])({_MONTH})\.?,?\s+(\d{{4}})(?!\d)", re.IGNORECASE)

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
    "thousand": 1_000,
    "हजार": 1_000,
    "हज़ार": 1_000,
}
_UNIT = "|".join(sorted(map(re.escape, _UNITS), key=len, reverse=True))
_CURRENCY = r"(?:₹|rs\.?|inr|रु\.?|रुपये|रुपए)"
_NUMBER = re.compile(
    rf"(?P<cur>{_CURRENCY}\s*)?(?<![\d.,])(?P<num>\d{{1,3}}(?:,\d{{2,3}})+(?:\.\d+)?|\d+(?:\.\d+)?)"
    rf"(?:\s*(?P<unit>{_UNIT})(?![^\W\d_]))?",
    re.IGNORECASE,
)
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
    numbers: list[tuple[str, float, bool]] = field(default_factory=list)


def normalise(text: str) -> str:
    """Devanagari digits to ASCII, unified whitespace, lower case."""
    return re.sub(r"\s+", " ", text.translate(_DEVANAGARI_DIGITS)).strip().lower()


def _date_key(year: int, month: int, day: int) -> str | None:
    try:
        return date(year, month, day).isoformat()
    except ValueError:
        return None


def _scan(text: str) -> _Facts:
    """Dates (full and month-year) and numbers in `text`. Date spans are blanked before
    numbers are read, so a date's parts are not reported again as plain numbers."""
    facts = _Facts()
    norm = normalise(text)
    spans: list[tuple[int, int]] = []

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
        value = float(m["num"].replace(",", ""))
        unit = (m["unit"] or "").lower()
        is_amount = bool(m["cur"] or unit)
        facts.numbers.append((m[0].strip(), value * _UNITS.get(unit, 1), is_amount))
    return facts


def _contains(haystack: str, needle: str) -> bool:
    return bool(needle) and normalise(needle) in haystack


@dataclass(frozen=True, slots=True)
class SourceIndex:
    text: str
    dates: frozenset[str]
    values: frozenset[float]

    @classmethod
    def build(cls, source: str) -> SourceIndex:
        """Values the source vouches for: plain numbers (also the parts of its dates, so a year
        or a day mentioned alone still matches) and unit-multiplied amounts."""
        norm = normalise(source)
        facts = _scan(source)
        values = {float(n.replace(",", "")) for n in _PLAIN_NUMBER.findall(norm)}
        values |= {value for _, value, _ in facts.numbers}
        return cls(norm, frozenset(facts.dates), frozenset(values))


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
) -> list[Mismatch]:
    """Mismatches between generated text and its source; empty means every checked claim was
    found. `texts` maps a location (e.g. "mr.summary", "deadline") to the text shown there."""
    index = SourceIndex.build(source_text)
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
