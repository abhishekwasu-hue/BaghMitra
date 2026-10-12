from __future__ import annotations

import uuid
from datetime import UTC, date, datetime

from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.context import load_context
from bagmitra_api.kb.gate import ChemicalOption, evaluate
from bagmitra_api.kb.models import KbLabelClaim, KbRestriction, KbSource, KbSynonym

NOW = datetime(2026, 10, 12, tzinfo=UTC)


async def test_gate_runs_on_database_data_and_honours_validity(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        src = KbSource(
            id=uuid.uuid4(),
            key="cibrc_fungicides_2024",
            title="CIB&RC Major Uses of Pesticides: fungicides (31.03.2024)",
            publisher="PPQS / CIB&RC",
            url="https://ppqs.gov.in/sites/default/files/fungicides_31.03.2024.pdf",
            tier="tier2",
            licence="government publication",
            allowed_use="cite_only",
            verification="V",
        )
        base = {"formulation": "50 WP", "crop": "citrus", "target": "canker", "dose": "per label"}
        session.add_all(
            [
                src,
                KbLabelClaim(
                    id=uuid.uuid4(),
                    active_ingredient="copper oxychloride",
                    source_id=src.id,
                    valid_from=datetime(2024, 3, 31, tzinfo=UTC),
                    **base,
                ),
                KbLabelClaim(  # expired claim must not count
                    id=uuid.uuid4(),
                    active_ingredient="old fungicide",
                    source_id=src.id,
                    valid_from=datetime(2010, 1, 1, tzinfo=UTC),
                    valid_to=datetime(2020, 1, 1, tzinfo=UTC),
                    **base,
                ),
                KbRestriction(
                    id=uuid.uuid4(),
                    active_ingredient="benomyl",
                    kind="banned",
                    crops=[],
                    crop_groups=[],
                    notification="S.O. 3951(E) 8 Aug 2018",
                    effective_from=datetime(2018, 8, 8, tzinfo=UTC),
                    source_id=src.id,
                ),
                KbSynonym(id=uuid.uuid4(), name="blitox", active_ingredient="copper oxychloride"),
            ]
        )
        await session.commit()
        ctx = await load_context(
            session, crop_aliases=frozenset({"citrus"}), crop_groups=frozenset(), now=NOW
        )

    def check(ai: str) -> list[str]:
        result = evaluate(
            ChemicalOption(ai, "50 WP", "canker"),
            ctx,
            today=date(2026, 10, 12),
            planned_harvest=None,
        )
        return result.reasons

    assert check("Blitox") == []
    assert check("old fungicide") == ["no_label_claim"]
    assert check("benomyl") == ["banned"]
    assert ctx.claims[0].source_key == "cibrc_fungicides_2024"
