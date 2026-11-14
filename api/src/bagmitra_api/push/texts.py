"""Words of the update pushes (owner 2026-11-12, Q147) in mr / hi / en: calm, numbers first,
never an alarm word ("धोका", "सावधान", "इशारा" ...), never a chemical.

Mandi, crop and variety names follow the app's display lists (app/lib/features/market/domain/
market_labels.dart, market_crops.dart); a name not listed stays as the price source wrote it.
Marathi writes Devanagari digits (as the app's formatting does for `mr`); Hindi and English
Latin digits. Rupees use Indian grouping (३,५०० / 1,25,000)."""

from __future__ import annotations

import re
from collections.abc import Mapping, Sequence
from datetime import date

_MARATHI_DIGITS = str.maketrans("0123456789", "०१२३४५६७८९")
LANGS = ("en", "mr", "hi")

# Same as the app's _markets (market_labels.dart).
MARKETS: dict[str, tuple[str, str]] = {
    "kalamna": ("कळमना", "कलमना"),
    "warud": ("वरूड", "वरुड़"),
    "katol": ("काटोल", "काटोल"),
    "morshi": ("मोर्शी", "मोर्शी"),
    "amravati": ("अमरावती", "अमरावती"),
    "azadpur": ("आझादपूर", "आज़ादपुर"),
    "mumbai": ("मुंबई", "मुंबई"),
    "pune": ("पुणे", "पुणे"),
    "nagpur": ("नागपूर", "नागपुर"),
    "bangalore": ("बंगळुरू", "बेंगलुरु"),
    "chennai": ("चेन्नई", "चेन्नई"),
    "hyderabad": ("हैदराबाद", "हैदराबाद"),
    "kolkata": ("कोलकाता", "कोलकाता"),
    "ahmedabad": ("अहमदाबाद", "अहमदाबाद"),
    "jaipur": ("जयपूर", "जयपुर"),
    "lucknow": ("लखनौ", "लखनऊ"),
    "indore": ("इंदूर", "इंदौर"),
}
# Same as the app's marketCrops: crop key -> (en, mr, hi).
CROPS: dict[str, tuple[str, str, str]] = {
    "santra": ("Santra", "संत्रा", "संतरा"),
    "mosambi": ("Mosambi", "मोसंबी", "मौसंबी"),
    "banana": ("Banana", "केळी", "केला"),
    "guava": ("Guava", "पेरू", "अमरूद"),
    "pomegranate": ("Pomegranate", "डाळिंब", "अनार"),
    "grapes": ("Grapes", "द्राक्ष", "अंगूर"),
    "papaya": ("Papaya", "पपई", "पपीता"),
    "lemon": ("Lemon", "लिंबू", "नींबू"),
    "apple": ("Apple", "सफरचंद", "सेब"),
}
VARIETIES: dict[str, tuple[str, str]] = {
    "nagpur": ("नागपुरी", "नागपुरी"),
    "nagpuri": ("नागपुरी", "नागपुरी"),
}
_IGNORED = {"apmc"}
_WORD = re.compile(r"[a-z]+")

ARTICLE_ONE = {"en": "New article: {title}", "mr": "नवीन लेख: {title}", "hi": "नया लेख: {title}"}
ARTICLE_MANY = {"en": "{n} new articles", "mr": "{n} नवीन लेख", "hi": "{n} नए लेख"}
MORE = {"en": "…and {n} more", "mr": "…आणखी {n}", "hi": "…और {n}"}
MARKET_TITLE = {"en": "Market prices", "mr": "बाजारभाव", "hi": "मंडी भाव"}
# A risk alert that fired on several plots of one farmer: "<label> (बाग: Sharayu farm, बाग १)".
PLOTS_SUFFIX = {"en": " (plots: {names})", "mr": " (बाग: {names})", "hi": " (बाग: {names})"}
PLOT_NAMES_SHOWN = 3
WEATHER_TITLE = {"en": "Weather change", "mr": "हवामान बदल", "hi": "मौसम में बदलाव"}
TODAY = {"en": "today", "mr": "आज", "hi": "आज"}
YESTERDAY = {"en": "yesterday", "mr": "काल", "hi": "कल"}
TOMORROW = {"en": "tomorrow", "mr": "उद्या", "hi": "कल"}
ON_DATE = {"en": "on {d}", "mr": "{d} रोजी", "hi": "{d} को"}
MARKET_LINE = {
    "en": "{mandi} {crop}: {when} ₹{price} ({rs}, {pct})",
    "mr": "{mandi} {crop}: {when} ₹{price} ({rs}, {pct})",
    "hi": "{mandi} {crop}: {when} ₹{price} ({rs}, {pct})",
}
# {day} is today / tomorrow / a date; {v} the value; {d} a difference; {ref} the day compared.
WEATHER_LINES: dict[str, dict[str, str]] = {
    "rain_prob": {
        "en": "Chance of rain {day}: {v}%; check your spray plan.",
        "mr": "{day} पावसाची शक्यता {v}%; फवारणीचे नियोजन पाहा.",
        "hi": "{day} बारिश की संभावना {v}%; छिड़काव की योजना देखें।",
    },
    "rain_mm": {
        "en": "About {v} mm of rain expected {day}; check your spray plan.",
        "mr": "{day} सुमारे {v} मिमी पावसाचा अंदाज; फवारणीचे नियोजन पाहा.",
        "hi": "{day} लगभग {v} मिमी बारिश का अनुमान; छिड़काव की योजना देखें।",
    },
    "temp_up": {
        "en": "Highest temperature {day}: {v} °C, {d} °C above {ref}; check irrigation.",
        "mr": "{day} कमाल तापमान {v} °C, {ref}पेक्षा {d} °C जास्त; ओलित पाहा.",
        "hi": "{day} अधिकतम तापमान {v} °C, {ref} से {d} °C अधिक; सिंचाई देखें।",
    },
    "temp_down": {
        "en": "Highest temperature {day}: {v} °C, {d} °C below {ref}.",
        "mr": "{day} कमाल तापमान {v} °C, {ref}पेक्षा {d} °C कमी.",
        "hi": "{day} अधिकतम तापमान {v} °C, {ref} से {d} °C कम।",
    },
    "heat": {
        "en": "Highest temperature {day}: {v} °C; check irrigation.",
        "mr": "{day} कमाल तापमान {v} °C; ओलित पाहा.",
        "hi": "{day} अधिकतम तापमान {v} °C; सिंचाई देखें।",
    },
    "cold": {
        "en": "Lowest temperature {day}: {v} °C; look over young plants and the nursery.",
        "mr": "{day} किमान तापमान {v} °C; लहान झाडे व रोपवाटिका पाहा.",
        "hi": "{day} न्यूनतम तापमान {v} °C; छोटे पौधे और नर्सरी देखें।",
    },
    "wind": {
        "en": "Wind gusts up to {v} km/h {day}; check your spray plan.",
        "mr": "{day} वाऱ्याचा वेग ताशी {v} कि.मी. पर्यंत; फवारणीचे नियोजन पाहा.",
        "hi": "{day} हवा की गति {v} किमी/घंटा तक; छिड़काव की योजना देखें।",
    },
}
# Words the update pushes never use (tests check every template against it).
ALARM_WORDS = ("धोका", "सावधान", "इशारा", "खतरा", "चेतावनी", "danger", "warning", "alert")


def pick(table: Mapping[str, str], lang: str) -> str:
    return table.get(lang) or table["en"]


def plot_names(names: Sequence[str], lang: str, total: int | None = None) -> str:
    """Plot names as one short list: the first PLOT_NAMES_SHOWN, then "+N" for the rest of
    `total` plots (default: len(names)), e.g. "Sharayu farm, बाग १, बाग २ +२". Names are the
    farmer's own, never translated."""
    head = ", ".join(names[:PLOT_NAMES_SHOWN])
    rest = (len(names) if total is None else total) - min(len(names), PLOT_NAMES_SHOWN)
    return f"{head} +{digits(str(rest), lang)}" if rest > 0 else head


def digits(text: str, lang: str) -> str:
    """Devanagari digits for Marathi; the text unchanged otherwise."""
    return text.translate(_MARATHI_DIGITS) if lang == "mr" else text


def indian(value: int) -> str:
    """Indian digit grouping: 3500 -> 3,500; 125000 -> 1,25,000 (sign kept)."""
    sign, text = ("-", str(-value)) if value < 0 else ("", str(value))
    if len(text) <= 3:
        return sign + text
    head, tail = text[:-3], text[-3:]
    groups: list[str] = []
    while len(head) > 2:
        groups.insert(0, head[-2:])
        head = head[:-2]
    if head:
        groups.insert(0, head)
    return sign + ",".join([*groups, tail])


def number(value: float, lang: str) -> str:
    """A whole number (rounded) in the language's digits."""
    return digits(str(round(value)), lang)


def _words(text: str) -> list[str]:
    return [w for w in _WORD.findall(text.casefold()) if w not in _IGNORED]


def mandi_name(market: str, lang: str) -> str:
    """The mandi as the app shows it: its Marathi / Hindi name when listed (whole name, or
    the first listed word of it, e.g. "APMC Nagpur" -> नागपूर), else the source name."""
    if lang not in ("mr", "hi"):
        return market
    index = 0 if lang == "mr" else 1
    whole = MARKETS.get(market.strip().casefold())
    if whole is not None:
        return whole[index]
    for word in _words(market):
        if word in MARKETS:
            return MARKETS[word][index]
    return market


def crop_name(crop: str, lang: str) -> str:
    names = CROPS.get(crop)
    if names is None:
        return crop
    return {"en": names[0], "mr": names[1], "hi": names[2]}.get(lang, names[0])


def variety_name(variety: str, commodity: str, lang: str) -> str:
    """The variety when it says something ("Other" or the crop name repeated say nothing,
    as in the app's marketVarietyIsInformative); '' otherwise."""
    v, c = variety.strip().casefold(), commodity.strip().casefold()
    if not v or v in ("other", "others") or v == c or c.startswith((f"{v}(", f"{v} ")):
        return ""
    names = VARIETIES.get(v)
    if names is not None and lang in ("mr", "hi"):
        return names[0 if lang == "mr" else 1]
    return variety.strip()


def place_key(text: str | None) -> str:
    """A district as one comparable key: Latin words casefolded, or the English key of a
    place the app lists in Marathi / Hindi (अमरावती -> amravati); '' when empty."""
    raw = " ".join((text or "").split())
    if not raw:
        return ""
    for key, (mr, hi) in MARKETS.items():
        if raw in (mr, hi):
            return key
    return raw.casefold()


def when_word(day: date, today: date, lang: str) -> str:
    """today / yesterday / tomorrow, else the date as d/m."""
    delta = (day - today).days
    if delta == 0:
        return pick(TODAY, lang)
    if delta == -1:
        return pick(YESTERDAY, lang)
    if delta == 1:
        return pick(TOMORROW, lang)
    return pick(ON_DATE, lang).format(d=digits(f"{day.day}/{day.month}", lang))


def signed_rs(delta: int, lang: str) -> str:
    sign = "+" if delta >= 0 else "-"
    return f"{sign}₹{digits(indian(abs(delta)), lang)}"


def signed_pct(pct: float, lang: str) -> str:
    sign = "+" if pct >= 0 else "-"
    return f"{sign}{digits(str(round(abs(pct))), lang)}%"
