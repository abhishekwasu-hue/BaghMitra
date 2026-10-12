"""Addendum v1.3 §5/§9: manual-upload importers for label claims and restrictions,
version-dated with a diff report; removals end-date rows instead of deleting them."""

from __future__ import annotations

from datetime import UTC, date, datetime

import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.context import load_context
from bagmitra_api.kb.gate import ChemicalOption, evaluate
from bagmitra_api.kb.importers import (
    KbImportError,
    import_label_claims,
    import_restrictions,
    parse_label_claims,
    parse_restrictions,
)
from bagmitra_api.kb.seed import seed_sources

CLAIMS_V1 = """active_ingredient,formulation,crop,target,dose,interval_days,phi_days,max_sprays
imidacloprid,17.8 SL,citrus,psylla,per label,,15,
copper oxychloride,50 WP,citrus,canker,per label,,,
"""
CLAIMS_V2 = """active_ingredient,formulation,crop,target,dose,interval_days,phi_days,max_sprays
imidacloprid,17.8 SL,citrus,psylla,per label,,21,
cyantraniliprole,10.26 OD,citrus,psylla,600 ml/ha,,5,
"""
T1 = datetime(2026, 10, 12, tzinfo=UTC)
T2 = datetime(2026, 11, 1, tzinfo=UTC)


def test_parse_reports_every_bad_row() -> None:
    bad = """active_ingredient,formulation,crop,target,dose,interval_days,phi_days,max_sprays
imidacloprid,17.8 SL,citrus,psylla,per label,,fifteen,
,50 WP,citrus,canker,per label,,,
"""
    with pytest.raises(KbImportError) as err:
        parse_label_claims(bad)
    assert [e.split(":")[0] for e in err.value.errors] == ["row 2", "row 3"]
    with pytest.raises(KbImportError, match="missing columns"):
        parse_label_claims("active_ingredient,crop\nx,citrus\n")


def test_parse_restrictions_validates_kind() -> None:
    text = "active_ingredient,kind,crops,crop_groups,notification,effective_from\n"
    rows = parse_restrictions(text + "dicofol,banned,,,S.O. 4294(E),2023-10-03\n")
    assert rows[0].kind == "banned"
    with pytest.raises(KbImportError):
        parse_restrictions(text + "dicofol,maybe,,,x,2023-10-03\n")


async def test_claim_import_diffs_and_end_dates_removed_claims(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        first = await import_label_claims(session, "cibrc_insecticides_pgr", CLAIMS_V1, T1)
        assert (first.added, first.changed, first.removed) == (2, 0, 0)
        again = await import_label_claims(session, "cibrc_insecticides_pgr", CLAIMS_V1, T1)
        assert (again.added, again.changed, again.removed) == (0, 0, 0)
        second = await import_label_claims(session, "cibrc_insecticides_pgr", CLAIMS_V2, T2)
        assert (second.added, second.changed, second.removed) == (1, 1, 1)
        await session.commit()

        async def phi(ai: str, form: str, target: str, at: datetime) -> int | None:
            ctx = await load_context(
                session, crop_aliases=frozenset({"citrus"}), crop_groups=frozenset(), now=at
            )
            res = evaluate(
                ChemicalOption(ai, form, target), ctx, today=at.date(), planned_harvest=None
            )
            return res.claim.phi_days if res.allowed and res.claim else None

        assert await phi("imidacloprid", "17.8 SL", "psylla", T1) == 15  # history kept
        assert await phi("imidacloprid", "17.8 SL", "psylla", T2) == 21
        assert await phi("copper oxychloride", "50 WP", "canker", T2) is None  # end-dated


async def test_restriction_import_adds_new_ban(engine: AsyncEngine) -> None:
    text = (
        "active_ingredient,kind,crops,crop_groups,notification,effective_from\n"
        "imidacloprid,banned,,,Hypothetical S.O. test,2026-11-01\n"
    )
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await import_label_claims(session, "cibrc_insecticides_pgr", CLAIMS_V1, T1)
        diff = await import_restrictions(session, "ppqs_banned_restricted", text, T2)
        assert diff.added == 1
        same = await import_restrictions(session, "ppqs_banned_restricted", text, T2)
        assert (same.added, same.changed, same.unchanged) == (0, 0, 1)
        moved = text.replace("2026-11-01", "2026-10-20")
        assert (
            await import_restrictions(session, "ppqs_banned_restricted", moved, T2)
        ).changed == 1
        await session.commit()
        ctx = await load_context(
            session, crop_aliases=frozenset({"citrus"}), crop_groups=frozenset(), now=T2
        )
    res = evaluate(
        ChemicalOption("imidacloprid", "17.8 SL", "psylla"),
        ctx,
        today=date(2026, 11, 2),
        planned_harvest=None,
    )
    assert res.reasons == ["banned"]


async def test_unknown_source_is_refused(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        with pytest.raises(KbImportError, match="unknown source"):
            await import_label_claims(session, "nope", CLAIMS_V1, T1)


def test_duplicate_claim_rows_are_rejected() -> None:
    with pytest.raises(KbImportError, match="duplicate"):
        parse_label_claims(CLAIMS_V1 + "Imidacloprid,17.8 SL,Citrus,Psylla,per label,,15,\n")
