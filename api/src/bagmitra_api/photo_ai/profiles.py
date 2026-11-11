"""The disease / pest profiles the photo analysis may name (owner Q135): a copy of the practice
cards' profiles that describe symptoms (`seed_data/disease_profiles.json`, kept equal to
`app/assets/config/practice_cards.json` by a test), plus `healthy` and `other`."""

from __future__ import annotations

import json
from dataclasses import dataclass
from functools import cache
from importlib import resources

LANGS = ("en", "mr", "hi")
HEALTHY = "healthy"
OTHER = "other"
EXTRA_NAMES: dict[str, dict[str, str]] = {
    HEALTHY: {"en": "Looks healthy", "mr": "निरोगी दिसते", "hi": "स्वस्थ दिखता है"},
    OTHER: {
        "en": "Something else (not on the cards)",
        "mr": "दुसरे काही (कार्डांवर नाही)",
        "hi": "कुछ और (कार्डों पर नहीं)",
    },
}


@dataclass(frozen=True, slots=True)
class Profile:
    key: str
    kind: str
    labels: dict[str, str]
    symptoms: dict[str, str]
    scouting: dict[str, str] | None


@cache
def profiles() -> tuple[Profile, ...]:
    text = (
        resources.files("bagmitra_api.photo_ai.seed_data")
        .joinpath("disease_profiles.json")
        .read_text("utf-8")
    )
    return tuple(
        Profile(p["key"], p["kind"], p["labels"], p["symptoms"], p["scouting"])
        for p in json.loads(text)["profiles"]
    )


def known_keys() -> tuple[str, ...]:
    """Every key a candidate may carry: the card profiles, then `healthy` and `other`."""
    return (*(p.key for p in profiles()), HEALTHY, OTHER)


def names(key: str) -> dict[str, str]:
    """The en / mr / hi name shown for a key (the card's own section label)."""
    for p in profiles():
        if p.key == key:
            return {lang: p.labels[lang] for lang in LANGS}
    return dict(EXTRA_NAMES[key])


def profile_text() -> str:
    """The card texts the model is given, one block per key (English: the checked wording)."""
    blocks = []
    for p in profiles():
        lines = [f'<profile key="{p.key}" kind="{p.kind}">', f"Name: {p.labels['en']}"]
        lines.append(f"What it looks like: {p.symptoms['en']}")
        if p.scouting:
            lines.append(f"How to scout: {p.scouting['en']}")
        lines.append("</profile>")
        blocks.append("\n".join(lines))
    return "\n".join(blocks)
