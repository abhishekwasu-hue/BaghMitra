"""Input names yes, doses no (owner decision 2026-11-14, OPEN_QUESTIONS Q160).

Fertilisers, pesticides and organic / bio inputs MAY be named to growers, but no dose,
quantity, rate, concentration or per-tree / per-acre amount reaches a grower, and each line
that recommends an input ends with the expert-advice note. One rule set for every place that
writes grower text: the knowledge-card grower view, the offline Q&A asset, the knowledge and
news article checks and the guard tests over the bundled app content.

A dose is a quantity (a number with a mass, volume, ppm or percent unit, or a number "per"
tree / plant / acre / hectare / litre) that stands within a few words of an input name. Water,
weather, soil-test and market numbers are not doses ("100 litres of water per tree", "humidity
above 80 %"). A formulation printed with a product ("Imidacloprid 17.8% SL", "50% WP") is
the product's name, not a dose, and stays.
"""

from __future__ import annotations

import csv
import re
from collections.abc import Iterable, Mapping, Sequence
from importlib import resources
from typing import Any

NOTE: Mapping[str, str] = {
    "mr": "(तज्ज्ञांच्या सल्ल्याने करावे)",
    "hi": "(विशेषज्ञ की सलाह से करें)",
    "en": "(follow expert advice)",
}

# Input names in English (they decide whether a line recommends an input and gets the note):
# fertilisers and manures, nutrients, pesticides and their kinds, bio-agents and botanicals,
# growth regulators, traps and lures, the release of a bio-control agent, and every active
# ingredient of the bundled CIB&RC label claims. Conserving natural enemies is not an input.
_NAME_WORDS = (
    r"fertili[sz]\w*", r"manure\w*", r"FYM", r"compost\w*", r"vermicompost\w*", r"urea",
    r"nitrogen", r"phosph\w*", r"potash", r"potassium", r"NPK", r"P2O5", r"K2O", r"zinc",
    r"ZnSO4", r"FeSO4", r"CuSO4", r"MgSO4", r"ferrous", r"iron sulphate", r"magnesium sulphate",
    r"boron", r"borax", r"micronutrient\w*", r"gypsum", r"oil ?cakes?", r"neem cake",
    r"biofertili[sz]\w*", r"azotobacter", r"PSB", r"neem", r"NSKE", r"azadirachtin",
    r"trichoderma", r"pseudomonas", r"mycorrhiza\w*", r"verticillium", r"lecanicillium",
    r"beauveria", r"metarhizium", r"bacillus", r"copper", r"bordeaux", r"sulph\w*", r"sulf\w*",
    r"insecticid\w*", r"fungicid\w*", r"pesticid\w*", r"herbicid\w*", r"weedicid\w*",
    r"acaricid\w*", r"nematicid\w*", r"bio-?pesticid\w*", r"bio-?agents?", r"growth regulators?",
    r"gibberell\w*", r"GA3", r"2,4-D", r"NAA", r"chlormequat", r"paclobutrazol",
    r"streptocycline", r"antibiotic\w*", r"detergent", r"teepol", r"emulsifier", r"traps?",
    r"lures?", r"methyl[- ]eugenol", r"releases? of", r"release the", r"the feeding",
)  # fmt: skip
# Words that also mark a quantity as a dose but do not by themselves name an input: the
# Marathi and Hindi input names (English decides the note), spraying, and dose words.
_CONTEXT_WORDS = (
    r"spray(?:s|ing|ed)?", r"drench\w*", r"a\.i\.", r"active ingredient", r"dose[sd]?", r"dosage",
    r"dilution", r"solution", r"releas\w*",
    # Marathi
    r"खत(?!्?[रम])\w*", r"शेणखत", r"गांडूळ", r"युरिया", r"नत्र", r"स्फुरद", r"पालाश", r"जस्त",
    r"झिंक", r"फेरस", r"बोरॉन", r"सूक्ष्म ?अन्नद्रव्य\w*", r"जिप्सम", r"पेंड", r"निंबोळी",
    r"कडुनिंब", r"निंब\w*", r"ट्रायकोडर्मा", r"सुडोमोनास", r"स्युडोमोनास", r"स्यूडोमोनास",
    r"मायकोरायझा", r"कॉपर", r"बोर्डो", r"गंधक", r"सल्फर", r"सल्फेट", r"फॉस्फेट", r"पोटॅश\w*",
    r"कीटकनाशक\w*", r"बुरशीनाशक\w*", r"तणनाशक\w*", r"कोळीनाशक\w*", r"जैविक", r"संजीवक\w*",
    r"वाढ नियंत्रक\w*", r"फवार\w*", r"सापळ\w*", r"कामगंध", r"फेरोमोन", r"डिटर्जंट", r"टिपॉल",
    r"ॲझाडिरेक्टिन", r"ॲझाडिरॅक्टिन", r"अझाडिरेक्टिन", r"ढालकिड\w*", r"ल्युअर", r"आमिष\w*",
    r"मिथाइल", r"क्रिप्टोलिमस", r"लेडीबर्ड", r"डोस", r"मात्र[ाे]\w*", r"प्रमाणात",
    r"द्रावण\w*",
    # Hindi
    r"खाद(?!्य)\w*", r"गोबर", r"वर्मी\w*", r"यूरिया", r"नाइट्रोजन", r"फ़ॉस्फ़ोरस", r"फॉस्फोरस",
    r"पोटाश", r"जिंक", r"ज़िंक", r"सूक्ष्म पोषक\w*", r"माइक्रोन्यूट्रिएंट\w*", r"सल्फ़र", r"नीम",
    r"ट्राइकोडर्मा", r"माइकोराइज़ा", r"कीटनाशक\w*", r"फफूंदनाशक\w*", r"खरपतवारनाशक\w*",
    r"छिड़क\w*", r"ट्रैप", r"ल्योर", r"ल्यूर", r"क्रिप्टोलेमस", r"टीपॉल", r"जाल", r"ढालकीड़ा",
    r"एज़ाडिरेक्टिन", r"अज़ाडिरेक्टिन", r"डिटर्जेंट", r"घोल",
)  # fmt: skip
# Mentions of an input word that do not name an input to apply.
_NOT_INPUT = re.compile(
    r"fertili[sz]er bag|lack of fertili[sz]ation|micronutrient deficiency|"
    r"खताच्या (?:रिकाम्या )?(?:पिशवी|गोणी)\w*|खाद (?:की|के) (?:बोरी|थैली)\w*",
    re.IGNORECASE,
)


def _label_ingredients() -> tuple[str, ...]:
    """Active ingredients of the bundled CIB&RC label claims (each part of a mix)."""
    path = resources.files("bagmitra_api.kb.seed_data").joinpath("label_claims_citrus.csv")
    with path.open(encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))
    parts = {
        part.strip().lower()
        for row in rows
        for part in re.split(r"\s+\+\s+", row["active_ingredient"])
        if len(part.strip()) >= 4
    }
    return tuple(re.escape(p) for p in sorted(parts, key=len, reverse=True))


def _alternation(words: Iterable[str]) -> re.Pattern[str]:
    return re.compile(r"(?<![\w-])(?:" + "|".join(words) + r")", re.IGNORECASE)


_NAMES = _alternation((*_label_ingredients(), *_NAME_WORDS))
_CONTEXT = _alternation((*_label_ingredients(), *_NAME_WORDS, *_CONTEXT_WORDS))
# A dose word next to a number ("the dose printed is 1.0%", "मात्रा २ ग्रॅम").
_DOSE_WORD = re.compile(
    r"(?<![\w-])(?:dose[sd]?|dosage|dilution|cfu|spores?/ml|डोस|मात्रा|मात्रेत|प्रमाणात)"
    r"(?![\w])",
    re.IGNORECASE,
)

_D = r"[0-9\u0966-\u096f]"
_NUM = rf"{_D}+(?:[.,]{_D}+)?(?:\s*(?:[-–/]|to|ते|से)\s*{_D}+(?:[.,]{_D}+)?)?"
_PERCENT = r"%|percent|per ?cent|टक्के|टक्क्[\w\u0900-\u097f]*|प्रतिशत"
_MASS_VOLUME = (
    r"ppm|mg|g|gm|gms|grams?|kg|kgs?|kilo\w*|q|quintals?|t|tonnes?|tons?|ml|"
    r"l|lit|litres?|liters?|lt|ltr|cfu|"
    r"पीपीएम|मि\.? ?ग्रॅ\.?|ग्रॅम|ग्रा\.?|ग्राम|किलो[\w\u0900-\u097f]*|कि\.? ?ग्रॅ\.?|कि\.? ?ग्रा\.?|"
    r"मि\.? ?ली\.?|मिली[\w\u0900-\u097f]*|लिटर[\w\u0900-\u097f]*|लीटर|ली\.|टन|क्विंटल"
)
_PER = r"per|प्रति|प्रती|दर|/"
_PER_UNIT = (
    r"trees?|plants?|acres?|hectares?|ha|litres?|liters?|l|lit|basins?|"
    r"झाड[\w\u0900-\u097f]*|रोप[\w\u0900-\u097f]*|एकर[\w\u0900-\u097f]*|हेक्टर[\w\u0900-\u097f]*|लिटर[\w\u0900-\u097f]*|पेड़|पौध[\w\u0900-\u097f]*|एकड़|हेक्टेयर|लीटर"
)
# Marathi distributive forms ("एकरी") and Hindi "in an acre / on a tree" that mean "per".
_PER_WORD = r"एकरी|हेक्टरी|झाडामागे|झाडाला|झाडास|रोपाला|लिटरला|(?:हेक्टेयर|एकड़|पेड़|पौधे) (?:में|पर)"
_END = r"(?![\w\u0900-\u0963\u0966-\u097f])"  # a danda (।) ends a word
_ABOUT = r"(?:about|approx\.?|सुमारे|लगभग|करीब)"
# A number of days, weeks, months or years: a timing, not an amount.
_TIME = re.compile(
    rf"{_NUM}\s*-?\s*(?:days?|weeks?|months?|years?|दिवस\w*|दिन|आठवड\w*|सप्ताह|महिन\w*|महीन\w*|"
    r"वर्ष\w*)",
    re.IGNORECASE,
)
# A share of a dose written in words ("one third of the recommended nitrogen dose").
_FRACTION = re.compile(
    r"\b(?:one|two)[- ](?:third|fourth|quarter)s?\b|\bhalf\b|\bquarter\b|तृतीयांश|चतुर्थांश|"
    r"एक तिहाई|आधा|अर्धा",
    re.IGNORECASE,
)
_FORMULATION = re.compile(
    rf"{_D}+(?:[.,]{_D}+)?\s*%\s*(?:w/[vw]\s*)?(?:\+\s*{_D}+(?:[.,]{_D}+)?\s*%\s*(?:w/[vw]\s*)?)*"
    r"(?:SL|SC|EC|WP|WG|WDG|SP|GR|CG|OD|DP|DS|FS|ME|EW|ZC|CS|DC|SE|WS|WSC|"
    r"ई\.?सी\.?|डब्ल्यू\.?पी\.?|एस\.?एल\.?|एस\.?सी\.?)(?![\w])"
    # "100% water soluble" names a fertiliser grade.
    rf"|{_D}+\s*%\s*(?:water[- ]soluble|पाण्यात विरघळणार\w*|पानी में घुलनशील)",
    re.IGNORECASE,
)
_PERCENT_Q = re.compile(rf"(?<![\w.]){_NUM}\s*(?:{_PERCENT}){_END}", re.IGNORECASE)
_QUANTITY = re.compile(
    rf"(?<![\w.]){_NUM}\s*(?:(?:{_MASS_VOLUME}){_END}"
    rf"|(?:[^\s\d.,;:()]+\s+){{0,3}}(?:{_PER})\s*(?:{_PER_UNIT}){_END}"
    rf"|(?:{_PER_WORD}){_END})"
    rf"|(?:(?:{_PER})\s*(?:{_PER_UNIT})|{_PER_WORD})\s*(?:{_ABOUT}\s*)?{_NUM}"
    rf"|\(\s*{_D}+\s*:\s*{_D}+\s*\)",
    re.IGNORECASE,
)
# A mass followed by a nutrient symbol is always a dose ("300 g N + 150 g P").
_NUTRIENT = re.compile(
    rf"(?<![\w.]){_NUM}\s*(?:g|gm|kg|ग्रॅम|ग्राम|किलो)\s*\(?(?:N|P|K|P2O5|K2O|Zn|Fe)(?![\w])"
)
# A strength in ppm, or an amount per litre of spray, is a dose with or without an input name.
_SMALL = r"mg|g|gm|ml|मि\.? ?ली\.?|मिली|ग्रॅम|ग्राम"
_LITRE = r"l|lit|litres?|liters?|लिटर[\w\u0900-\u097f]*|लीटर"
_ALWAYS = re.compile(
    rf"(?<![\w.]){_NUM}\s*(?:ppm|पीपीएम){_END}"
    rf"|(?<![\w.]){_NUM}\s*(?:{_SMALL})\s*(?:/|per|प्रति)\s*(?:{_LITRE}){_END}"
    rf"|(?:per|प्रति)\s*(?:{_LITRE})\s*{_NUM}\s*(?:{_SMALL}){_END}",
    re.IGNORECASE,
)
# A quantity of water is not a dose ("100–120 litres of water per tree").
_WATER_AFTER = re.compile(r"\s*(?:of )?(?:water|पाणी|पाण्या\w*|पानी)", re.IGNORECASE)
WINDOW = 36  # characters between a percentage and the input name it measures
# Abbreviations whose full stop does not end a sentence.
_ABBREVIATIONS = (
    "सें.मी.", "मि.मी.", "कि.मी.", " मी.", "डॉ.", "Dr.", "e.g.", "i.e.", "मि.ली.", "कि.ग्रॅ.",
    "कि.ग्रा.", "ग्रा.", " ली.", "a.i.", "Lit.", "No.",
)  # fmt: skip
_STOP = re.compile(r"(?<=[.!?।;])\s+|\n+")
_HOLD = "\u2063"  # invisible separator, stands in for a protected full stop


def sentences(text: str) -> list[str]:
    """Split on a full stop (or ! ? । ;) followed by a space, keeping abbreviations whole."""
    held = text.strip()
    for abbreviation in _ABBREVIATIONS:
        held = held.replace(abbreviation, abbreviation.replace(".", _HOLD))
    return [s.replace(_HOLD, ".") for s in _STOP.split(held) if s.strip()]


def _spans(pattern: re.Pattern[str], text: str) -> list[tuple[int, int]]:
    blocked = [m.span() for m in _NOT_INPUT.finditer(text)]
    return [
        m.span() for m in pattern.finditer(text) if not any(a <= m.start() < b for a, b in blocked)
    ]


def names_input(text: str) -> bool:
    """True when the (English) text names an input: a fertiliser, pesticide, bio / organic input,
    trap or lure. Such a line, written as advice, gets the expert-advice note."""
    return bool(_spans(_NAMES, without_note(text)))


def dose_spans(text: str) -> list[str]:
    """The doses in `text`, sentence by sentence (formulations excepted): a mass with a nutrient
    symbol, a ppm strength or an amount per litre; a dose word ("dose", "dilution", "मात्रा")
    with a number; and, in a sentence that names an input, every mass, volume or per-tree /
    per-acre / per-litre quantity that is not water and every percentage within WINDOW
    characters of the input name. Empty means no dose."""
    found: list[str] = []
    for sentence in sentences(text):
        masked = _FORMULATION.sub(lambda m: "§" * len(m.group(0)), sentence)
        found += [m.group(0).strip() for m in _NUTRIENT.finditer(masked)]
        found += [m.group(0).strip() for m in _ALWAYS.finditer(masked)]
        bare = _TIME.sub("", masked.replace("§", ""))
        if (word := _DOSE_WORD.search(masked)) and (re.search(_D, bare) or _FRACTION.search(bare)):
            found.append(word.group(0))
        inputs = _spans(_CONTEXT, masked)
        if not inputs:
            continue
        for m in _QUANTITY.finditer(masked):
            if not _WATER_AFTER.match(masked, m.end()) and m.group(0).strip() not in found:
                found.append(m.group(0).strip())
        for m in _PERCENT_Q.finditer(masked):
            start, end = m.span()
            if any(a - WINDOW <= end and b + WINDOW >= start for a, b in inputs):
                found.append(m.group(0).strip())
    return found


def has_dose(text: str) -> bool:
    return bool(dose_spans(text))


def note(lang: str) -> str:
    return NOTE.get(lang, NOTE["en"])


def has_note(text: str, lang: str) -> bool:
    return note(lang) in text


def with_note(text: str, lang: str) -> str:
    """`text` ending with the expert-advice note (added once)."""
    text = text.rstrip()
    return text if has_note(text, lang) else f"{text} {note(lang)}"


def without_note(text: str) -> str:
    """`text` with every expert-advice note taken out (for numbers / language checks)."""
    for note in NOTE.values():
        text = text.replace(f" {note}", "").replace(note, "")
    return text


def banned_names(
    restrictions: Iterable[Mapping[str, Any]], crop_aliases: Iterable[str],
    crop_groups: Iterable[str],
) -> frozenset[str]:  # fmt: skip
    """Active ingredients (and their listed synonyms) banned, withdrawn, refused, or restricted
    for this crop, lower-cased: never named to a grower of the crop."""
    aliases = {a.lower() for a in crop_aliases}
    groups = set(crop_groups)
    out: set[str] = set()
    for r in restrictions:
        crops = {str(c).lower() for c in r.get("crops") or []}
        rgroups = {str(g) for g in r.get("crop_groups") or []}
        if r["kind"] != "restricted" or aliases & crops or groups & rgroups:
            out.add(str(r["active_ingredient"]).lower())
            out.update(str(s).lower() for s in r.get("synonyms") or [])
    return frozenset(out)


def names_banned(text: str, banned: Iterable[str]) -> list[str]:
    lowered = text.lower()
    return sorted(n for n in banned if re.search(rf"(?<![\w-]){re.escape(n)}(?![\w-])", lowered))


def note_sections(
    sections: Mapping[str, Sequence[tuple[str, str]]],
) -> dict[str, tuple[tuple[str, str], ...]]:
    """Article sections per language with the expert-advice note after each section body whose
    English text names an input. A language whose section count differs from the English gets
    the note once, after its last section, when any English section names an input."""
    english = sections.get("en", ())
    advised = [names_input(f"{h}\n{b}") for h, b in english]
    out: dict[str, tuple[tuple[str, str], ...]] = {}
    for lang, parts in sections.items():
        if len(parts) == len(english):
            marks = advised
        else:
            marks = [i == len(parts) - 1 and any(advised) for i in range(len(parts))]
        out[lang] = tuple(
            (h, with_note(b, lang) if mark else b)
            for (h, b), mark in zip(parts, marks, strict=True)
        )
    return out
