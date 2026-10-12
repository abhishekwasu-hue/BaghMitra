from __future__ import annotations

from datetime import UTC, date, datetime

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.context import load_context
from bagmitra_api.kb.gate import ChemicalOption, evaluate
from bagmitra_api.kb.models import KbRestriction, KbSource
from bagmitra_api.kb.seed import (
    restriction_seeds,
    seed_restrictions,
    seed_sources,
    source_seeds,
)


def test_registry_is_complete_and_licence_rules_hold() -> None:
    seeds = source_seeds()
    keys = [s.key for s in seeds]
    assert len(keys) == len(set(keys)), "duplicate source keys"
    by_key = {s.key: s for s in seeds}
    assert {f"ccri_monthly_{m}" for m in ("january", "june", "december")} <= set(keys)
    # Addendum §2/§5: no-derivatives / all-rights-reserved sources are never copied.
    for key in ("ufifas_citrus_guide", "uc_ipm_citrus", "eppo_gd", "fundecitrus"):
        assert by_key[key].allowed_use in {"summarise_cite", "cite_only"}, key
    # Members-only, comparison-only and image datasets never reach growers.
    for key in ("cri_south_africa", "eu_pesticides_db", "us_epa_tolerances", "kcc_transcripts"):
        assert by_key[key].allowed_use == "internal_only", key
    assert all(s.allowed_use == "internal_only" for s in seeds if s.tier == "tier4")
    assert not any(s.allowed_use == "copy" for s in seeds), "nothing is cleared for copying yet"


async def test_seeding_is_idempotent_and_feeds_the_gate(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await seed_restrictions(session)
        await seed_sources(session)
        await seed_restrictions(session)
        await session.commit()
        sources = await session.scalar(select(func.count()).select_from(KbSource))
        restrictions = await session.scalar(select(func.count()).select_from(KbRestriction))
        assert sources == len(source_seeds())
        assert restrictions == len(restriction_seeds()[1])
        ctx = await load_context(
            session,
            crop_aliases=frozenset({"citrus", "mandarin"}),
            crop_groups=frozenset({"fruit_eaten_raw"}),
            now=datetime(2026, 10, 12, tzinfo=UTC),
        )
    for ai in ("benomyl", "dichlorvos", "dicofol", "phorate", "chlorpyrifos", "dimethoate"):
        result = evaluate(
            ChemicalOption(ai, "any", "any"), ctx, today=date(2026, 10, 12), planned_harvest=None
        )
        assert not result.allowed, ai
        assert set(result.reasons) <= {"banned", "restricted_for_crop"}, ai


async def test_restrictions_need_their_source(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        with pytest.raises(LookupError, match="ppqs_banned_restricted"):
            await seed_restrictions(session)
