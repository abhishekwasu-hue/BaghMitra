"""Grower knowledge cards: inputs named, never a dose, the expert-advice note after each input
recommendation, nothing banned for the crop (owner decisions Q57 and Q160)."""

from __future__ import annotations

import re
import uuid
from datetime import UTC, datetime

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.dose_rules import NOTE, has_dose, names_input
from bagmitra_api.kb.grower_view import FIELDS, grower_text, sentences
from bagmitra_api.kb.models import KbCard, KbSource
from bagmitra_api.kb.seed import knowledge_seeds, seed_knowledge, seed_restrictions, seed_sources

_DEVANAGARI = str.maketrans("०१२३४५६७८९", "0123456789")


def _numbers(text: str) -> set[str]:
    return set(re.findall(r"\d+(?:\.\d+)?", text.translate(_DEVANAGARI)))


async def _seed(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await seed_restrictions(session)
        await seed_knowledge(session)
        await session.commit()


def test_every_translation_lines_up_with_the_english() -> None:
    for card in knowledge_seeds().cards:
        en = card.content["en"]
        for lang in ("mr", "hi"):
            own = card.content[lang]
            assert "organic" not in own, (card.topic, lang)
            for field in FIELDS:
                if not en.get(field):
                    continue
                assert len(sentences(own[field])) == len(sentences(en[field])), (
                    card.topic,
                    lang,
                    field,
                )
                assert _numbers(en[field]) <= _numbers(own[field]), (card.topic, lang, field)


def test_the_grower_view_names_inputs_but_drops_every_dose() -> None:
    for card in knowledge_seeds().cards:
        view = grower_text(card.content)
        assert set(view) == {"en", "mr", "hi"}, card.topic
        for lang, fields in view.items():
            for field, text in fields.items():
                assert field in FIELDS
                assert not has_dose(text), (card.topic, lang, field, text)
        # Every input recommendation that is shown carries the expert-advice note, in every
        # language.
        for field in ("summary", "cultural", "when_to_call_expert"):
            en = sentences(card.content["en"].get(field, ""))
            for i, sentence in enumerate(en):
                if not names_input(sentence) or sentence not in view["en"].get(field, ""):
                    continue
                for lang in ("en", "mr", "hi"):
                    own = sentences(card.content[lang][field])[i]
                    assert f"{own} {NOTE[lang]}" in view[lang][field], (card.topic, lang, field)
    by_topic = {c.topic: grower_text(c.content) for c in knowledge_seeds().cards}
    # The permanganate wash (10 g per litre) goes; the Bordeaux paste is named, with the note.
    cultural = by_topic["phytophthora"]["en"]["cultural"]
    assert cultural.startswith(
        "Apply Bordeaux paste to the trunk up to 60 cm before and after the monsoon. "
        "(follow expert advice) Keep the bud union high"
    )
    assert "permanganate" not in cultural
    assert by_topic["phytophthora"]["en"]["title"].endswith("Bordeaux paste")
    # A card that is only doses keeps no cultural text at all.
    assert "cultural" not in by_topic["nutrition_young"]["en"]
    # Marathi drops the same sentences as English and carries its own note.
    assert by_topic["phytophthora"]["mr"]["cultural"].startswith("पावसाळ्यापूर्वी")
    assert NOTE["mr"] in by_topic["phytophthora"]["mr"]["cultural"]


def test_a_banned_ingredient_is_never_named() -> None:
    content = {
        "en": {"cultural": "Prune the dead twigs. An old note used dicofol on mites."},
        "mr": {"cultural": "वाळलेल्या फांद्या छाटा. जुन्या नोंदीत कोळ्यासाठी डायकोफॉल होते."},
    }
    view = grower_text(content, banned={"dicofol"})
    assert view["en"] == {"cultural": "Prune the dead twigs."}
    assert view["mr"] == {"cultural": "वाळलेल्या फांद्या छाटा."}


def test_a_translation_that_does_not_line_up_is_not_shown() -> None:
    content = {
        "en": {"title": "Mites", "cultural": "Keep moisture even. Spray oil."},
        "mr": {"title": "कोळी", "cultural": "ओलावा सारखा ठेवा"},
    }
    view = grower_text(content)
    assert view["en"] == {"title": "Mites", "cultural": "Keep moisture even. Spray oil."}
    assert view["mr"] == {"title": "कोळी"}
    assert sentences("३ x ३ मी. पेक्षा कमी. डॉ. पंदेकृवि.") == ["३ x ३ मी. पेक्षा कमी.", "डॉ. पंदेकृवि."]


async def test_growers_get_general_cards_without_chemicals(
    client: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    await _seed(engine)
    r = await client.get("/v1/knowledge/cards?crop=santra", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["kind"] == "general_information"
    cards = {c["topic"]: c for c in body["cards"]}
    assert len(cards) == len([c for c in knowledge_seeds().cards if c.crop == "santra"])
    assert "bahar_mosambi" not in cards
    mites = cards["mites"]
    assert mites["reviewed"] is False
    assert mites["topic_kind"] == "pest"
    assert set(mites["text"]) == {"en", "mr", "hi"}
    assert mites["text"]["mr"]["title"] == "कोळी (लाल्या)"
    assert mites["sources"]
    assert mites["sources"][0]["url"].startswith("https://")
    raw = r.text.lower()
    assert "chemical_options" not in raw
    assert '"organic"' not in raw
    # Inputs are named now (owner Q160), with the note, and never with a dose.
    gummosis = cards["phytophthora"]["text"]
    assert "bordeaux" in gummosis["en"]["cultural"].lower()
    assert NOTE["en"] in gummosis["en"]["cultural"]
    assert NOTE["mr"] in gummosis["mr"]["cultural"]
    for card in cards.values():
        for fields in card["text"].values():
            for text in fields.values():
                assert text is None or not has_dose(text), (card["topic"], text)
    assert (await client.get("/v1/knowledge/cards")).status_code == 401


async def test_retired_cards_and_older_versions_are_left_out(
    client: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    await _seed(engine)
    async with async_sessionmaker(engine)() as session:
        mites = (
            await session.scalars(select(KbCard).where(KbCard.crop == "santra").order_by(KbCard.id))
        ).first()
        assert mites is not None
        newer = KbCard(
            id=uuid.uuid4(),
            topic_id=mites.topic_id,
            crop="santra",
            version=2,
            content={"en": {"title": "Newer", "summary": "Reviewed text."}},
            reviewed_languages=["en"],
            chemical_options=[],
            sources=mites.sources,
            status="published",
        )
        source = await session.get(KbSource, uuid.UUID(mites.sources[0]["source_id"]))
        assert source is not None
        source.fetched_at = datetime(2026, 11, 6, 9, tzinfo=UTC)
        session.add(newer)
        await session.commit()
    body = (await client.get("/v1/knowledge/cards?crop=santra", headers=auth_headers)).json()
    newest = [c for c in body["cards"] if c["text"].get("en", {}).get("title") == "Newer"]
    assert len(newest) == 1
    assert newest[0]["reviewed"] is True
    assert newest[0]["sources"][0]["checked"] == "2026-11-06"
    async with async_sessionmaker(engine)() as session:
        for card in await session.scalars(select(KbCard).where(KbCard.crop == "santra")):
            card.status = "retired"
        await session.commit()
    after = (await client.get("/v1/knowledge/cards?crop=santra", headers=auth_headers)).json()
    assert after["cards"] == []


def test_marathi_uses_the_glossary_terms() -> None:
    # docs/agronomy/GLOSSARY_mr.md: variant -> term.
    variants = {"काढणी", "सिल्ला", "पालवी", "शेंडेमर", "फांदी करपा", "कॅन्कर", "मुळकुज", "सेंमी"}
    data = knowledge_seeds()
    texts = [t.labels["mr"] for t in data.topics] + [
        text for c in data.cards for text in c.content["mr"].values()
    ]
    for text in texts:
        for variant in variants:
            assert variant not in text, (variant, text)
