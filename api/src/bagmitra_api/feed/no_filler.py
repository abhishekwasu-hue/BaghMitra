"""No "the source does not say" filler in AI articles (owner 2026-11-14, agrowon screenshot).

When the source has nothing for a section or a point, the writer must leave it out. The prompts
say so; this guard makes it certain: a sentence that states the source / text / article lacks
some information ("माहिती उपलब्ध मजकुरात दिलेली नाही", "मजकूर येथे उपलब्ध नाही", "स्रोत में
नहीं दी गई", "not available in the text") is dropped; a key point, fact or section left empty is
dropped with it. Deterministic, no model call.

A sentence is filler only when an absence phrase ("दिलेली नाही", "उपलब्ध नाही", "नहीं दी गई",
"not mentioned", ...) appears together with a word for the source (मजकूर, स्रोत, वृत्त, बातमी,
लेख, source, text, article) or right after an information word (माहिती, तपशील, जानकारी,
information, details). Real advice is kept: "पाणी उपलब्ध नाही तेथे ठिबक वापरा" names no source
word, and a sentence that starts with a condition ("जेथे", "जर", "if", "यदि") or whose absence
phrase leads into an instruction ("... नाही तेथे / तर", "... नहीं, वहाँ") is never filler.
"""

from __future__ import annotations

import copy
import re
from typing import Any

_DEV = "ऀ-ॣ०-ॿ"  # Devanagari letters and digits (not the danda)
_START = rf"(?<![{_DEV}\w])"
_END = rf"(?![{_DEV}\w])"

# Words for the source itself. मजकूर / स्रोत / वृत्त / बातमी / समाचार take any ending
# (मजकुरात, स्रोतात, वृत्तात, बातमीत); लेख only as लेख / लेखात / लेखामध्ये / लेखातील, so लेखी
# (written) and लेखा (accounts) are not read as "article".
_SOURCE_WORD = re.compile(
    rf"{_START}(?:मजक[ुू]र|स्रोत|स्त्रोत|वृत्त|बातमी|समाचार|खबर|ख़बर)"
    rf"|{_START}लेख(?:ात|ामध्ये|ातील|ाच्या)?{_END}"
    r"|\b(?:the\s+)?(?:source|sources|text|article)\b",
    re.IGNORECASE,
)
_INFO_WORD = rf"(?:{_START}(?:माहिती|तपशील|जानकारी|विवरण)|\b(?:information|details?)\b)"

_ABSENT_MR = (
    r"(?:दिलेल[ीेा्य]*|नमूद\s+(?:केलेल[ीेा्य]*\s+)?|सांगितलेल[ीेा्य]*|उल्लेख\s+(?:केलेला\s+)?"
    r"|स्पष्ट\s+(?:केलेल[ीेा्य]*\s+)?|उपलब्ध|मिळत|दिसत)\s*नाहीत?"
)
_ABSENT_HI = (
    r"(?:नहीं\s+(?:दी|दिया|दिए|दिये|बताई|बताया|बताए|बताये|की|किया)\s+(?:गई|गयी|गया|गए|गये)"
    r"|(?:उपलब्ध|उल्लेख|स्पष्ट)\s+नहीं|नहीं\s+है|नहीं\s+मिलती)"
)
_ABSENT_EN = (
    r"\b(?:(?:is|are|was|were)?\s*not\s+(?:available|given|mentioned|stated|specified|provided"
    r"|included|described|covered|disclosed|clear)"
    r"|(?:is|are)n't\s+(?:available|given|mentioned|stated|specified|provided)"
    r"|(?:does|do|did)\s+not\s+(?:say|state|mention|give|specify|provide|include|describe|cover)"
    r"|(?:doesn't|don't|didn't)\s+(?:say|state|mention|give|specify|provide|include)"
    r"|no\s+(?:information|details|mention))\b"
)
_ABSENT = re.compile(f"(?:{_ABSENT_MR}|{_ABSENT_HI}|{_ABSENT_EN})", re.IGNORECASE)
_INFO_THEN_ABSENT = re.compile(rf"{_INFO_WORD}(?:\s+\S+){{0,4}}?\s+{_ABSENT.pattern}", re.I)

# A condition or a place: the sentence is advice ("if water is not available, ...").
_CONDITION_START = re.compile(
    r"^\W*(?:जर|जेथे|जिथे|ज्या\s+ठिकाणी|यदि|अगर|जहाँ|जहां|if|where|unless|when)"
    rf"(?:{_END}|\b)",
    re.IGNORECASE,
)
_LEADS_ON = re.compile(
    rf"{_ABSENT.pattern}[\s,;]*(?:(?:तेथे|तिथे|तर|त्या\s+ठिकाणी|वहाँ|वहां|तो|तब){_END}"
    r"|(?:there|then|use|apply|ask|contact)\b)",
    re.IGNORECASE,
)

_SENTENCE_END = re.compile(r"(?<=[.!?।॥])\s+")
_ABBREVIATION = re.compile(r"(?:^|\s)(?:रु|रू|डॉ|क्र|सं|ता|जि|मा|श्री|Rs|No|Dr|Mr|Ms|St)\.$")
_BULLET = re.compile(r"^(\s*(?:[-•*]|\d+[.)])\s+)")


def is_filler(sentence: str) -> bool:
    """True when the sentence only says the source / text lacks some information."""
    s = " ".join(sentence.split())
    if not _ABSENT.search(s) or _CONDITION_START.search(s) or _LEADS_ON.search(s):
        return False
    return bool(_SOURCE_WORD.search(s) or _INFO_THEN_ABSENT.search(s))


def _sentences(line: str) -> list[str]:
    """The line's sentences; a split after an abbreviation ("रु.", "Dr.") is joined back."""
    out: list[str] = []
    for piece in _SENTENCE_END.split(line):
        if out and _ABBREVIATION.search(out[-1]):
            out[-1] = f"{out[-1]} {piece}"
        else:
            out.append(piece)
    return out


def _clean_line(line: str) -> str:
    bullet = _BULLET.match(line)
    prefix = bullet.group(1) if bullet else ""
    parts = _sentences(line[len(prefix) :])
    kept = [p for p in parts if not is_filler(p)]
    if len(kept) == len(parts):
        return line
    return f"{prefix}{' '.join(kept)}" if kept else ""


def filler_sentences(text: str) -> list[str]:
    """The filler sentences of `text`, in order."""
    out = []
    for line in text.split("\n"):
        bullet = _BULLET.match(line)
        out += [p for p in _sentences(line[bullet.end() if bullet else 0 :]) if is_filler(p)]
    return out


def clean_text(text: str) -> str:
    """`text` without its filler sentences; a line left empty is removed. Text without filler
    is returned exactly as it was."""
    lines = text.split("\n")
    cleaned = [_clean_line(line) for line in lines]
    if cleaned == lines:
        return text
    kept = [c for c, line in zip(cleaned, lines, strict=True) if c or not line.strip()]
    return re.sub(r"\n{3,}", "\n\n", "\n".join(kept)).strip()


def clean_saved(article: dict[str, Any]) -> tuple[dict[str, Any] | None, list[str]]:
    """A stored article (`feed_item_i18n.article`, news and knowledge shape) without filler, and
    the removed sentences. (None, removed) when no section would be left; the article is then
    left for a person. The input is not changed."""
    out = copy.deepcopy(article)
    removed: list[str] = []

    def clean(text: str) -> str:
        removed.extend(filler_sentences(text))
        return clean_text(text)

    if isinstance(out.get("standfirst"), str):
        out["standfirst"] = clean(out["standfirst"])
    out["key_points"] = [
        k for k in (clean(k) for k in out.get("key_points") or [] if isinstance(k, str)) if k
    ]
    out["sections"] = [
        {**s, "body": body}
        for s in out.get("sections") or []
        if isinstance(s, dict) and (body := clean(str(s.get("body", ""))))
    ]
    out["facts"] = [
        {**f, "value": value}
        for f in out.get("facts") or []
        if isinstance(f, dict) and (value := clean(str(f.get("value", ""))))
    ]
    if not removed:
        return article, []
    if not out["sections"] or not out.get("standfirst"):
        return None, removed
    return out, removed
