"""Search keys for the offline question-and-answer asset (owner 2026-11-12, Q144).

The app (`app/lib/features/ask/domain/qa_text.dart`) runs the SAME rules on the farmer's typed or
spoken question; a shared fixture (`app/test/fixtures/qa_normalise_cases.json`) keeps the two
implementations equal. Rules:
1. lower case, Devanagari digits to ASCII, nukta removed, chandrabindu written as anusvara,
   zero-width joiners dropped;
2. words are runs of Devanagari letters / marks, Latin letters and digits;
3. common Marathi / Hindi / English question words and particles are dropped;
4. one common Marathi / Hindi case ending (also romanised: "sathi", "chi" ...) is cut
   ("फळगळीसाठी" -> "फळगळी", "rogachi" -> "roga"), when at least four characters stay;
5. every word also gets a sound key ("skeleton"): its consonants in a coarse Latin form, vowels
   and "y" dropped, so "फळगळ", "falgal" and "phalgal" share the key "plgl", "सायला" / "sayla" /
   "saila" share "sl", and "मोसंबी" / "mosambi" share "msmb".
"""

from __future__ import annotations

import re

_DEVANAGARI_DIGITS = str.maketrans("०१२३४५६७८९", "0123456789")
# Devanagari letters and marks (U+0900-U+0963, U+0966-U+097F; not the dandas), a-z, 0-9.
_WORD = re.compile(f"[{chr(0x900)}-{chr(0x963)}{chr(0x966)}-{chr(0x97F)}a-z0-9]+")
_NUKTA = chr(0x93C)
_JOINERS = (chr(0x200C), chr(0x200D))  # zero-width non-joiner, joiner

STOPWORDS = frozenset(
    {
        # Marathi
        "काय", "कसे", "कशी", "कसा", "कसं", "कोणते", "कोणता", "कोणती", "कोणत्या", "केव्हा",
        "कधी", "किती", "का", "की", "आहे", "आहेत", "असते", "असतो", "असेल", "होते", "होतो",
        "करावे", "करावा", "करावी", "करायचे", "करू", "मी", "माझ्या", "माझे", "माझा", "माझी",
        "आमच्या", "आम्ही", "तर", "व", "आणि", "किंवा", "हे", "ही", "हा", "तो", "ती", "ते",
        "या", "त्या", "मध्ये", "साठी", "ला", "ने", "चा", "ची", "चे", "च्या", "वर", "न",
        "नाही", "पण", "म्हणजे", "काही", "सांगा", "द्या", "मला",
        # Hindi
        "क्या", "कैसे", "कैसी", "कब", "कौन", "कौनसा", "कितना", "कितनी", "है", "हैं", "में",
        "के", "को", "से", "पर", "और", "मेरे", "मेरा", "मेरी", "हम", "करें",
        "करना", "चाहिए", "बताइए", "बताओ", "सा",
        # English and romanised question words
        "what", "how", "when", "which", "why", "is", "are", "the", "a", "an", "of", "in",
        "on", "for", "to", "do", "does", "i", "my", "and", "or", "should", "can", "it",
        "kay", "kase", "kashi", "kasa", "kevha", "kadhi", "kiti", "ahe", "aahe", "karave",
        "kya", "kaise", "kab", "hai", "me", "mein", "ka", "ki", "ke", "madhe", "madhye",
        "sathi", "la", "cha", "chi", "che", "ani", "kinva", "kon", "konte", "konti", "kontya",
    }
)  # fmt: skip

# Case endings cut once, longest first.
SUFFIXES = tuple(
    sorted(
        (
            "मध्ये", "साठी", "च्या", "ांना", "ांची", "ांचा", "ांचे", "ाच्या", "चा", "ची",
            "चे", "ला", "ना", "ने", "नी", "वर", "ांत", "ात", "ों", "ें", "ाने",
            # romanised Marathi
            "sathi", "madhye", "madhe", "chya", "chi", "cha", "che",
        ),
        key=len,
        reverse=True,
    )
)  # fmt: skip
MIN_STEM = 4

_DEV_CONSONANTS = {
    "क": "k", "ख": "k", "ग": "g", "घ": "g", "ङ": "n",
    "च": "c", "छ": "c", "ज": "j", "झ": "j", "ञ": "n",
    "ट": "t", "ठ": "t", "ड": "d", "ढ": "d", "ण": "n",
    "त": "t", "थ": "t", "द": "d", "ध": "d", "न": "n",
    "प": "p", "फ": "p", "ब": "b", "भ": "b", "म": "m",
    "य": "", "र": "r", "ऱ": "r", "ल": "l", "ळ": "l", "व": "v",
    "श": "s", "ष": "s", "स": "s", "ह": "h", "ं": "n",
}  # fmt: skip
_LATIN_PAIRS = (
    ("chh", "c"), ("ch", "c"), ("sh", "s"), ("kh", "k"), ("gh", "g"), ("jh", "j"),
    ("th", "t"), ("dh", "d"), ("ph", "p"), ("bh", "b"), ("ck", "k"),
)  # fmt: skip
_LATIN_SINGLE = {"f": "p", "w": "v", "z": "j", "q": "k", "x": "ks"}
_LATIN_VOWELS = frozenset("aeiou")
# "y" is a glide in most farmer spellings ("sayla", "saila", "psylla"): never part of a key.
_DROPPED = frozenset("y")


def normalise(text: str) -> str:
    out = text.lower().translate(_DEVANAGARI_DIGITS).replace(_NUKTA, "").replace("ँ", "ं")
    for j in _JOINERS:
        out = out.replace(j, "")
    return out


def stem(word: str) -> str:
    for suffix in SUFFIXES:
        if word.endswith(suffix) and len(word) - len(suffix) >= MIN_STEM:
            return word[: -len(suffix)]
    return word


def words(text: str) -> list[str]:
    """Normalised, stemmed words without stopwords, in order, without repeats."""
    out: list[str] = []
    for raw in _WORD.findall(normalise(text)):
        if raw in STOPWORDS or len(raw) < 2:  # one letter is never a key
            continue
        w = stem(raw)
        if w not in out:
            out.append(w)
    return out


def _latin_skeleton(word: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(word):
        for pair, rep in _LATIN_PAIRS:
            if word.startswith(pair, i):
                out.append(rep)
                i += len(pair)
                break
        else:
            ch = word[i]
            nxt = word[i + 1] if i + 1 < len(word) else ""
            if ch in _LATIN_VOWELS or ch.isdigit():
                pass
            elif ch == "c":
                out.append("s" if nxt in ("e", "i", "y") else "k")
            elif ch in _DROPPED:
                pass
            else:
                out.append(_LATIN_SINGLE.get(ch, ch))
            i += 1
    return "".join(out)


def skeleton(word: str) -> str:
    """The word's consonants in a coarse Latin form (see the module note); repeats merged."""
    if any(chr(0x900) <= ch <= chr(0x97F) for ch in word):
        raw = "".join(_DEV_CONSONANTS.get(ch, "") for ch in word)
    else:
        raw = _latin_skeleton(word)
    # A nasal before p / b sounds as m ("मोसंबी" = "mosambi").
    raw = raw.replace("np", "mp").replace("nb", "mb")
    merged: list[str] = []
    for ch in raw:
        if not merged or merged[-1] != ch:
            merged.append(ch)
    return "".join(merged)


def index_keys(*texts: str) -> list[str]:
    """Words of all `texts`, then "~" + each word's sound key (two letters or more)."""
    found: list[str] = []
    for text in texts:
        for w in words(text):
            if w not in found:
                found.append(w)
    keys = list(found)
    for w in found:
        s = skeleton(w)
        if len(s) >= 2 and f"~{s}" not in keys:
            keys.append(f"~{s}")
    return keys
