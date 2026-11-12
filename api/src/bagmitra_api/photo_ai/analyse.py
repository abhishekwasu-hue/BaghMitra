"""Crop photo analysis with Claude (owner Q135, stage 2).

One Messages API request per photo over httpx (`feed.ai.messages_text`: same headers, API
version and server-side refusal fallback as the feed). The photo goes first as a base64
image block, then the question. The answer is structured output (`output_config.format`,
JSON schema) and is validated again here: only known keys, confidence clamped to 0..1, at most
three candidates, best first; the visible signs come in en / mr / hi (owner 2026-11-11). The
model judges from what is visible and the card texts only; it names no chemical or dose and
points to the card instead.
"""

from __future__ import annotations

import base64
import json
from dataclasses import dataclass, field
from typing import Any, Protocol

import httpx

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import ANTHROPIC_VERSION, AiUnavailableError, messages_text
from bagmitra_api.photo_ai.profiles import LANGS, OTHER, known_keys, profile_text

MAX_CANDIDATES = 3
MAX_SIGNS = 8
MAX_SIGN_CHARS = 200
MAX_EXPLANATION_CHARS = 1200
GREENING = "greening"
# The button under a photo-check result that opens the matching practices (app label
# "photoCheckOpenCard", renamed in PR #358).
BUTTON = {
    "en": "See practices and details",
    "mr": "उपाय व माहिती पहा",
    "hi": "उपाय व जानकारी देखें",
}
# The greening card: only a lab test confirms greening (scouting text and look-alike card).
GREENING_LAB_NOTE = {
    "en": f'Only a lab PCR test can confirm greening; for greening, tap "{BUTTON["en"]}".',
    "mr": f'ग्रीनिंगची खात्री फक्त प्रयोगशाळेतील PCR चाचणीने होते; ग्रीनिंगसाठी "{BUTTON["mr"]}" दाबा.',
    "hi": f'ग्रीनिंग की पुष्टि केवल लैब PCR जाँच से होती है; ग्रीनिंग के लिए "{BUTTON["hi"]}" दबाएँ।',
}
PARTS = ("leaf", "fruit", "trunk", "whole_tree")


@dataclass(frozen=True, slots=True)
class Candidate:
    key: str
    confidence: float
    signs: dict[str, list[str]]
    explanation: dict[str, str]

    def to_dict(self) -> dict[str, Any]:
        return {
            "key": self.key,
            "confidence": self.confidence,
            "signs": {lang: list(found) for lang, found in self.signs.items()},
            "explanation": dict(self.explanation),
        }


@dataclass(frozen=True, slots=True)
class Analysis:
    candidates: list[Candidate] = field(default_factory=list)
    unsure: bool = True


class PhotoAnalyser(Protocol):
    model: str

    async def analyse(self, image: bytes, media_type: str, part: str | None) -> Analysis: ...


def _per_lang(value: dict[str, Any]) -> dict[str, Any]:
    return {
        "type": "object",
        "properties": {lang: dict(value) for lang in LANGS},
        "required": list(LANGS),
        "additionalProperties": False,
    }


def _text_obj() -> dict[str, Any]:
    return _per_lang({"type": "string"})


def _signs_obj() -> dict[str, Any]:
    return _per_lang({"type": "array", "items": {"type": "string"}})


def answer_schema() -> dict[str, Any]:
    """Structured output: every property required, no extra properties, no min / max."""
    candidate = {
        "type": "object",
        "properties": {
            "key": {"type": "string", "enum": list(known_keys())},
            "confidence": {"type": "number"},
            "signs": _signs_obj(),
            "explanation": _text_obj(),
        },
        "required": ["key", "confidence", "signs", "explanation"],
        "additionalProperties": False,
    }
    return {
        "type": "object",
        "properties": {
            "unsure": {"type": "boolean"},
            "candidates": {"type": "array", "items": candidate},
        },
        "required": ["unsure", "candidates"],
        "additionalProperties": False,
    }


def system_prompt() -> str:
    return f"""You help orange (santra) and sweet lime (mosambi) farmers in Maharashtra who cannot
describe what they see on their trees. You look at one photo and say which of the problems
below it may show. Your answer is shown to the farmer in the app, next to the matching card.

The problems you may name, each with what the checked practice card says it looks like:
<profiles>
{profile_text()}
</profiles>
You may also answer "healthy" (nothing on the cards is visible) or "{OTHER}" (a problem is
visible but none of the cards describes it).

How to judge:
- Judge only from what is visible in the photo and from the card texts above. Do not use
  other knowledge about the disease, the season, the weather or the place, and do not guess
  what cannot be seen.
- For each candidate, list the visible signs you actually see in this photo and compare them
  with the card text. Give the same signs in English "en", Marathi "mr" and Hindi "hi": short,
  plain phrases with the same meaning in each language, Marathi and Hindi in their own script.
- Give up to {MAX_CANDIDATES} candidates, most likely first, each with an honest confidence
  from 0 to 1. Several weak candidates are better than one confident wrong one.
- Set "unsure" to true when the photo is unclear (blurred, too dark, too far, the part is not
  visible), when the signs fit more than one problem about equally, or when nothing on the
  cards matches. Prefer "unsure" over a guess.
- For greening (HLB), the explanation must say that only a lab PCR test confirms greening,
  as the card says. A photo can only point to it.

How to write the explanation (English "en", Marathi "mr", Hindi "hi"; two to four short,
plain sentences each, for a farmer):
- Say what you see in the photo and which problem it matches, and suggest tapping the button
  under the answer to check the tree and read what to do. The button is named, exactly:
  English "{BUTTON["en"]}", Marathi "{BUTTON["mr"]}", Hindi "{BUTTON["hi"]}". Never write
  "open the card" ("कार्ड उघडून", "कार्ड उघडा", "कार्ड खोलकर").
- Calm wording: no alarming words (never "danger", "emergency", "destroy", "urgent", "loss" or
  the like), no blame and no pressure. The farmer must not be frightened.
- No chemical, pesticide, fungicide, product or brand names and no doses; the practices are
  under that button, so point to it.
- Marathi and Hindi in their own script, with the same meaning as the English."""


def question(part: str | None) -> str:
    seen = part.replace("_", " ") if part else "not stated"
    return (
        f"The farmer says the photo shows: {seen}. Look at the photo above and answer in the "
        "JSON format, with only the keys you were given."
    )


def _clamp(value: object) -> float:
    if isinstance(value, bool) or not isinstance(value, int | float):
        return 0.0
    return round(min(1.0, max(0.0, float(value))), 3)


def _texts(value: object, limit: int) -> dict[str, str]:
    raw = value if isinstance(value, dict) else {}
    out: dict[str, str] = {}
    for lang in LANGS:
        text = raw.get(lang)
        out[lang] = text.strip()[:limit] if isinstance(text, str) else ""
    return out


def _sign_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    found = [s.strip()[:MAX_SIGN_CHARS] for s in value if isinstance(s, str) and s.strip()]
    return found[:MAX_SIGNS]


def signs_by_lang(value: object) -> dict[str, list[str]]:
    """The signs per language, each at most MAX_SIGNS of MAX_SIGN_CHARS. A plain list (an older
    answer or stored sample) is English, with Marathi and Hindi empty."""
    if isinstance(value, list):
        return {lang: _sign_list(value) if lang == "en" else [] for lang in LANGS}
    raw = value if isinstance(value, dict) else {}
    return {lang: _sign_list(raw.get(lang)) for lang in LANGS}


def _with_lab_note(explanation: dict[str, str]) -> dict[str, str]:
    """Greening: make sure each language says a lab PCR test confirms it (the card's rule)."""
    out = dict(explanation)
    for lang in LANGS:
        if "PCR" not in out[lang]:
            out[lang] = f"{out[lang]} {GREENING_LAB_NOTE[lang]}".strip()
    return out


def parse_analysis(payload: dict[str, Any]) -> Analysis:
    """Server-side check of the model's JSON: unknown or repeated keys are dropped, confidence
    is clamped to 0..1, the best three are kept (highest confidence first). No candidate left
    means unsure."""
    allowed = set(known_keys())
    seen: set[str] = set()
    found: list[Candidate] = []
    raw = payload.get("candidates")
    for item in raw if isinstance(raw, list) else []:
        if not isinstance(item, dict):
            continue
        key = item.get("key")
        if not isinstance(key, str) or key not in allowed or key in seen:
            continue
        seen.add(key)
        explanation = _texts(item.get("explanation"), MAX_EXPLANATION_CHARS)
        if key == GREENING:
            explanation = _with_lab_note(explanation)
        found.append(
            Candidate(
                key, _clamp(item.get("confidence")), signs_by_lang(item.get("signs")), explanation
            )
        )
    found.sort(key=lambda c: c.confidence, reverse=True)
    best = found[:MAX_CANDIDATES]
    unsure = payload.get("unsure") is not False or not best
    return Analysis(best, unsure)


class AnthropicPhotoAi:
    """Claude over the Messages API (PHOTO_AI_API_KEY, else FEED_AI_API_KEY)."""

    def __init__(self, http: httpx.AsyncClient, settings: Settings) -> None:
        self._http = http
        self._settings = settings
        self.model = settings.photo_ai_model

    def request_body(self, image: bytes, media_type: str, part: str | None) -> dict[str, Any]:
        # No `thinking` field: the model runs adaptive thinking by default, and "disabled" or a
        # budget is refused (400). Effort is left at the model's default.
        return {
            "model": self.model,
            "max_tokens": self._settings.photo_ai_max_tokens,
            "system": system_prompt(),
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": base64.b64encode(image).decode("ascii"),
                            },
                        },
                        {"type": "text", "text": question(part)},
                    ],
                }
            ],
            "output_config": {"format": {"type": "json_schema", "schema": answer_schema()}},
        }

    async def analyse(self, image: bytes, media_type: str, part: str | None) -> Analysis:
        s = self._settings
        answer = await messages_text(
            self._http,
            base_url=s.feed_ai_base_url,
            headers={
                "x-api-key": s.photo_ai_key,
                "anthropic-version": ANTHROPIC_VERSION,
                "content-type": "application/json",
            },
            body=self.request_body(image, media_type, part),
            fallback=True,
            read_seconds=s.photo_ai_timeout_seconds,
        )
        try:
            payload = json.loads(answer)
        except json.JSONDecodeError as exc:
            raise AiUnavailableError(f"model answered with invalid JSON: {exc}") from exc
        if not isinstance(payload, dict):
            raise AiUnavailableError("model answered with a non-object")
        return parse_analysis(payload)
