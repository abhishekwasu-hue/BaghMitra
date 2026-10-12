"""Addendum v1.3 §4/§9: when a ban is imported, affected published cards are pulled
automatically and an admin alert is raised."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.kb.importers import import_label_claims, import_restrictions
from bagmitra_api.kb.models import KbAdminAlert, KbCard, KbTopic
from bagmitra_api.kb.regate import regate_published_cards, regate_with_settings
from bagmitra_api.kb.seed import seed_sources
from tests.test_kb_import import CLAIMS_V1

T1 = datetime(2026, 10, 12, tzinfo=UTC)
T2 = datetime(2026, 11, 2, tzinfo=UTC)
ALIASES = {"santra": frozenset({"citrus", "mandarin"})}
GROUPS = {"santra": frozenset({"fruit_eaten_raw"})}


def card(topic: KbTopic, ai: str, form: str, target: str, status: str = "published") -> KbCard:
    return KbCard(
        id=uuid.uuid4(),
        topic_id=topic.id,
        crop="santra",
        version=1,
        content={"en": {"title": f"{target} card"}},
        reviewed_languages=["en"],
        chemical_options=[{"active_ingredient": ai, "formulation": form, "target": target}],
        sources=[],
        status=status,
    )


async def test_new_ban_pulls_published_cards_and_alerts(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await import_label_claims(session, "cibrc_insecticides_pgr", CLAIMS_V1, T1)
        topic = KbTopic(id=uuid.uuid4(), key="psylla", kind="pest", labels={})
        psylla = card(topic, "imidacloprid", "17.8 SL", "psylla")
        canker = card(topic, "copper oxychloride", "50 WP", "canker")
        draft = card(topic, "imidacloprid", "17.8 SL", "psylla", status="draft")
        session.add_all([topic, psylla, canker, draft])
        await session.flush()

        assert (
            await regate_published_cards(session, crop_aliases=ALIASES, crop_groups=GROUPS, now=T1)
            == []
        )

        await import_restrictions(
            session,
            "ppqs_banned_restricted",
            "active_ingredient,kind,crops,crop_groups,notification,effective_from\n"
            "imidacloprid,banned,,,Hypothetical S.O. test,2026-11-01\n",
            T2,
        )
        pulled = await regate_published_cards(
            session, crop_aliases=ALIASES, crop_groups=GROUPS, now=T2
        )
        assert pulled == [psylla.id]
        assert psylla.status == "draft"
        assert canker.status == "published"
        assert draft.status == "draft"
        alerts = (await session.scalars(select(KbAdminAlert))).all()
        assert sorted(a.kind for a in alerts) == ["card_pulled", "import_applied", "import_applied"]
        [alert] = [a for a in alerts if a.kind == "card_pulled"]
        assert alert.kind == "card_pulled"
        assert alert.card_id == psylla.id
        assert "banned" in alert.detail


async def test_card_for_unconfigured_crop_is_pulled_not_trusted(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        topic = KbTopic(id=uuid.uuid4(), key="x", kind="pest", labels={})
        orphan = card(topic, "imidacloprid", "17.8 SL", "psylla")
        orphan.crop = "pomegranate"
        session.add_all([topic, orphan])
        await session.flush()
        assert await regate_published_cards(
            session, crop_aliases=ALIASES, crop_groups=GROUPS, now=T1
        ) == [orphan.id]


async def test_settings_supply_crop_aliases(engine: AsyncEngine) -> None:
    settings = Settings(kb_crop_label_aliases={}, kb_crop_groups={})
    async with async_sessionmaker(engine)() as session:
        topic = KbTopic(id=uuid.uuid4(), key="y", kind="pest", labels={})
        c = card(topic, "imidacloprid", "17.8 SL", "psylla")
        session.add_all([topic, c])
        await session.flush()
        assert await regate_with_settings(session, settings, T1) == [c.id]
