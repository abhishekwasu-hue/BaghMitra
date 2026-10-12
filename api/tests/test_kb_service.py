from __future__ import annotations

import uuid
from datetime import UTC, datetime

import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.kb.models import KbCard, KbSource, KbTopic
from bagmitra_api.kb.service import PublishRefusedError, ReviewInput, publish, record_review

NOW = datetime(2026, 10, 12, tzinfo=UTC)


async def seed(
    session: AsyncSession, *, use: str = "summarise_cite", chemical: bool = False
) -> KbCard:
    source = KbSource(
        id=uuid.uuid4(),
        key=f"src_{uuid.uuid4().hex[:8]}",
        title="ICAR-CCRI monthly guidelines: June",
        publisher="ICAR-CCRI Nagpur",
        url="https://ccri.icar.gov.in/site/assets/files/1223/june.pdf",
        tier="tier1",
        licence="unknown (government)",
        allowed_use=use,
        verification="V",
    )
    topic = KbTopic(id=uuid.uuid4(), key=f"t_{uuid.uuid4().hex[:8]}", kind="disease", labels={})
    card = KbCard(
        id=uuid.uuid4(),
        topic_id=topic.id,
        crop="santra",
        version=1,
        content={"en": {"title": "Gummosis: protect the trunk", "summary": "..."}},
        reviewed_languages=[],
        chemical_options=[{"active_ingredient": "x"}] if chemical else [],
        sources=[{"source_id": str(source.id), "locator": "p. 2"}],
        status="draft",
    )
    session.add_all([source, topic, card])
    await session.flush()
    return card


async def test_draft_cannot_be_published_without_review(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        card = await seed(session)
        with pytest.raises(PublishRefusedError) as err:
            await publish(session, card, NOW)
        assert err.value.blockers == ["no_valid_review"]
        assert card.status == "draft"


async def test_approved_card_publishes_and_gets_review_due_date(
    engine: AsyncEngine, settings: Settings
) -> None:
    async with async_sessionmaker(engine)() as session:
        card = await seed(session, chemical=True)
        await record_review(
            session,
            card,
            ReviewInput(uuid.uuid4(), "plant_pathologist", "approve"),
            NOW,
            settings,
        )
        await session.flush()
        assert card.status == "expert_reviewed"
        assert card.review_due_at == datetime(2027, 4, 12, tzinfo=UTC)  # chemical: 6 months
        await publish(session, card, NOW)
        assert card.status == "published"


async def test_rejection_and_internal_sources_block_publishing(
    engine: AsyncEngine, settings: Settings
) -> None:
    async with async_sessionmaker(engine)() as session:
        card = await seed(session, use="internal_only")
        await record_review(
            session,
            card,
            ReviewInput(uuid.uuid4(), "agronomist", "reject", "dose conflicts with PDKV"),
            NOW,
            settings,
        )
        await session.flush()
        with pytest.raises(PublishRefusedError) as err:
            await publish(session, card, NOW)
        assert err.value.blockers == ["internal_only_source", "no_valid_review"]
