"""K0: draft knowledge cards from addendum v1.3 §3. They are seeded as drafts only, cite
registered sources, carry no doses, and never name a chemical the gazette bans."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.context import load_context
from bagmitra_api.kb.gate import ChemicalOption, evaluate
from bagmitra_api.kb.models import KbCard, KbConflict, KbSource, KbTopic
from bagmitra_api.kb.seed import (
    knowledge_seeds,
    seed_knowledge,
    seed_restrictions,
    seed_sources,
)


async def seeded(engine: AsyncEngine) -> async_sessionmaker:  # type: ignore[type-arg]
    maker = async_sessionmaker(engine)
    async with maker() as session:
        await seed_sources(session)
        await seed_restrictions(session)
        await seed_knowledge(session)
        await session.commit()
    return maker


def test_every_card_has_english_text_sources_and_a_topic() -> None:
    data = knowledge_seeds()
    topics = {t.key for t in data.topics}
    assert len(data.cards) >= 20
    for card in data.cards:
        en = card.content["en"]
        assert card.topic in topics
        assert en["title"].strip()
        assert en["summary"].strip()
        assert card.sources, card.topic
        assert all(s.locator.strip() for s in card.sources)
    assert {c.topic for c in data.cards} == topics  # one card per topic, none orphaned


async def test_cards_are_seeded_as_drafts_once(engine: AsyncEngine) -> None:
    maker = await seeded(engine)
    async with maker() as session:
        first = await session.scalar(select(func.count()).select_from(KbCard))
        statuses = set(await session.scalars(select(KbCard.status)))
        await seed_knowledge(session)
        await session.commit()
        second = await session.scalar(select(func.count()).select_from(KbCard))
        assert statuses == {"draft"}
        assert first == second == len(knowledge_seeds().cards)
        assert await session.scalar(select(func.count()).select_from(KbConflict)) == len(
            knowledge_seeds().conflicts
        )


async def test_cards_only_cite_registered_non_internal_sources(engine: AsyncEngine) -> None:
    maker = await seeded(engine)
    async with maker() as session:
        sources = {s.id: s for s in await session.scalars(select(KbSource))}
        for card in await session.scalars(select(KbCard)):
            for ref in card.sources:
                source = sources[uuid.UUID(ref["source_id"])]
                assert source.allowed_use != "internal_only", (card.id, source.key)
                assert source.tier != "tier4"


async def test_a_reviewed_card_is_never_overwritten_by_reseeding(engine: AsyncEngine) -> None:
    maker = await seeded(engine)
    async with maker() as session:
        card = (await session.scalars(select(KbCard).limit(1))).one()
        card_id = card.id
        card.status = "expert_reviewed"
        card.content = {"en": {"title": "Edited by a reviewer", "summary": "kept"}}
        await session.commit()
        await seed_knowledge(session)
        await session.commit()
        again = await session.get(KbCard, card_id)
        assert again is not None
        assert again.content["en"]["title"] == "Edited by a reviewer"
        assert again.status == "expert_reviewed"


async def test_no_card_offers_a_banned_chemical_and_none_has_a_dose(engine: AsyncEngine) -> None:
    maker = await seeded(engine)
    async with maker() as session:
        ctx = await load_context(
            session,
            crop_aliases=frozenset({"citrus", "mandarin", "orange", "santra"}),
            crop_groups=frozenset({"fruit_eaten_raw"}),
            now=datetime.now(UTC),
        )
        for card in await session.scalars(select(KbCard)):
            for opt in card.chemical_options:
                assert set(opt) <= {"active_ingredient", "formulation", "target"}, opt
                result = evaluate(
                    ChemicalOption(opt["active_ingredient"], opt["formulation"], opt["target"]),
                    ctx,
                    today=datetime.now(UTC).date(),
                    planned_harvest=None,
                )
                # With no label claims loaded every chemical is suppressed; it must never be
                # for being banned or restricted: that would be advice the law forbids.
                assert "banned" not in result.reasons, (card.id, opt)
                assert "restricted_for_crop" not in result.reasons, (card.id, opt)
                assert not result.allowed  # nothing can be shown until label claims are imported


async def test_topics_carry_three_languages(engine: AsyncEngine) -> None:
    maker = await seeded(engine)
    async with maker() as session:
        for topic in await session.scalars(select(KbTopic)):
            assert {"en", "mr", "hi"} <= set(topic.labels), topic.key
            assert all(v.strip() for v in topic.labels.values())
