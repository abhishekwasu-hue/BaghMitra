"""Grower knowledge cards: general information only (owner decision Q57)."""

from __future__ import annotations

import re
import uuid
from datetime import UTC, datetime

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.grower_view import FIELDS, grower_text, sentences
from bagmitra_api.kb.models import KbCard, KbSource
from bagmitra_api.kb.seed import knowledge_seeds, seed_knowledge, seed_restrictions, seed_sources

_DEVANAGARI = str.maketrans("०१२३४५६७८९", "0123456789")
# Names that must never reach a grower from a knowledge card.
_NEVER = (
    "bordeaux",
    "permanganate",
    "urea",
    "superphosphate",
    "potash",
    "neem",
    "abamectin",
    "novaluron",
    "regulator",
    "spray",
)


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


def test_the_grower_view_drops_products_doses_and_rates() -> None:
    for card in knowledge_seeds().cards:
        view = grower_text(card.content)
        assert set(view) == {"en", "mr", "hi"}, card.topic
        for field, text in view["en"].items():
            assert field in FIELDS
            lowered = text.lower()
            for word in _NEVER:
                if field == "warnings" and word in {"spray", "regulator"}:
                    continue
                assert word not in lowered, (card.topic, field, word)
            assert not re.search(r"\b\d+\s*(?:g|kg|ml)\b", text), (card.topic, field)
    by_topic = {c.topic: grower_text(c.content) for c in knowledge_seeds().cards}
    # The general part survives: the drainage advice stays, the paste and the wash go.
    assert by_topic["phytophthora"]["en"]["cultural"].startswith("Keep the bud union high")
    assert "title" not in by_topic["phytophthora"]["en"]
    assert "cultural" not in by_topic["nutrition_young"]["en"]
    # Marathi drops the same sentences as English.
    assert by_topic["phytophthora"]["mr"]["cultural"].startswith("डोळ्याचा जोड उंच")


def test_a_translation_that_does_not_line_up_is_not_shown() -> None:
    content = {
        "en": {"title": "Mites", "cultural": "Keep moisture even. Spray oil."},
        "mr": {"title": "कोळी", "cultural": "ओलावा सारखा ठेवा"},
    }
    view = grower_text(content)
    assert view["en"] == {"title": "Mites", "cultural": "Keep moisture even."}
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
    assert "bordeaux" not in raw
    assert "neem" not in raw
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
