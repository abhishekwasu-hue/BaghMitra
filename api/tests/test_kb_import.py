"""Addendum v1.3 §5/§9: manual-upload importers for label claims and restrictions,
version-dated with a diff report; removals end-date rows instead of deleting them."""

from __future__ import annotations

import csv
import io
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


DETAIL_HEADER = (
    "source_key,edition,page_ref,crop,target,active_ingredient,formulation,category,"
    "formulation_qty,dose_ai,dose,dilution,interval_days,phi_days,max_sprays,description,"
    "brand_names,maker_url,photo_url\n"
)
# The shape of seed_data/label_claims_citrus.csv; values are test fixtures, not label data.
DETAIL_SAMPLE = DETAIL_HEADER + (
    "cibrc_fungicides_2024,as on 31.03.2024,p. 9 S.No. 4,citrus,gummosis,fixture a,50 WP,"
    "chemical,500 g,250 g,,500-1000,,30,,Contact.,zeta brand; Alpha brand;beta,"
    "https://maker.example/a,\n"
    "cibrc_fungicides_2024,as on 31.03.2024,p. 70 S.No. 2,citrus,foot rot,fixture bio,1% WP,"
    "bio,,,2.5 kg/ha,,,,,Living fungus.,,,\n"
)


def test_detail_columns_are_parsed_as_printed() -> None:
    rows = parse_label_claims(DETAIL_SAMPLE, "cibrc_fungicides_2024")
    chem, bio = rows
    assert chem.dose == "500 g/ha (a.i. 250 g/ha)"  # built from the two printed columns
    assert (chem.dilution, chem.page_ref, chem.phi_days) == ("500-1000", "p. 9 S.No. 4", 30)
    assert chem.brand_names == ("Alpha brand", "beta", "zeta brand")  # alphabetical, no rank
    assert (chem.category, chem.maker_url, chem.photo_url) == (
        "chemical",
        "https://maker.example/a",
        None,
    )
    assert (bio.category, bio.dose, bio.brand_names) == ("bio", "2.5 kg/ha", ())


@pytest.mark.parametrize(
    ("old", "new", "message"),
    [
        ("https://maker.example/a", "http://maker.example/a", "https://"),
        (",chemical,", ",pesticide,", "unknown category"),
        ("cibrc_fungicides_2024,as on 31.03.2024,p. 9", "other_doc,x,p. 9", "not 'cibrc"),
    ],
)
def test_detail_columns_are_validated(old: str, new: str, message: str) -> None:
    with pytest.raises(KbImportError, match=message):
        parse_label_claims(DETAIL_SAMPLE.replace(old, new, 1), "cibrc_fungicides_2024")


def test_shipped_extract_parses_and_names_its_sources() -> None:
    """The shipped CSV is only ever filled from a fetched document: every row names a
    source that is registered and marked read in the fetch log."""
    import json  # noqa: PLC0415
    from importlib import resources  # noqa: PLC0415

    from bagmitra_api.kb.seed import label_claim_seed_text, source_seeds  # noqa: PLC0415

    text = label_claim_seed_text()
    assert text.splitlines()[0] + "\n" == DETAIL_HEADER
    rows = list(csv.DictReader(io.StringIO(text)))
    parse_label_claims(text)
    log = json.loads(
        resources.files("bagmitra_api.kb.seed_data")
        .joinpath("label_claims_fetch_log.json")
        .read_text("utf-8")
    )
    status = {d["source_key"]: d["status"] for d in log["documents"]}
    registered = {s.key for s in source_seeds()}
    assert set(status) <= registered
    for r in rows:
        assert status.get(r["source_key"]) == "read", r
        assert r["edition"], r
        assert r["page_ref"], r
        assert r["crop"].lower() not in {"acid lime", "lemon"}, r


def _shipped() -> tuple[list[dict[str, str]], dict[str, dict[str, object]]]:
    import json  # noqa: PLC0415
    from importlib import resources  # noqa: PLC0415

    from bagmitra_api.kb.seed import label_claim_seed_text  # noqa: PLC0415

    rows = list(csv.DictReader(io.StringIO(label_claim_seed_text())))
    log = json.loads(
        resources.files("bagmitra_api.kb.seed_data")
        .joinpath("label_claims_fetch_log.json")
        .read_text("utf-8")
    )
    return rows, {d["source_key"]: d for d in log["documents"]}


# Citrus rows read from each PPQS / CIB&RC document (edition as on 30.09.2026), owner Q57.
EXPECTED_ROWS = {
    "cibrc_fungicides_2026_09": 15,
    "cibrc_bio_fungicides_2026_09": 0,
    "cibrc_bio_insecticides_2026_09": 1,
    "cibrc_herbicides_2026_09": 2,
    "cibrc_pgr_2026_09": 0,
    "cibrc_insecticides_2026_09": 12,
}


def test_shipped_extract_row_counts_match_each_read_document() -> None:
    rows, docs = _shipped()
    counts = {key: sum(r["source_key"] == key for r in rows) for key in docs}
    for key, expected in EXPECTED_ROWS.items():
        assert docs[key]["status"] == "read", key
        assert docs[key]["edition"] == "as on 30.09.2026", key
        assert docs[key]["rows"] == expected == counts[key], key
    assert sum(EXPECTED_ROWS.values()) == len(rows)


def test_shipped_extract_has_no_acid_lime_or_lemon_row_and_keeps_doses_as_printed() -> None:
    from bagmitra_api.kb.seed import label_claim_seed_text  # noqa: PLC0415

    rows, _ = _shipped()
    parsed = parse_label_claims(label_claim_seed_text())
    assert len(parsed) == len(rows)
    for r, claim in zip(rows, parsed, strict=True):
        printed = " ".join((r["crop"], r["target"], r["description"])).lower()
        assert not any(w in printed for w in ("acid lime", "lemon", "kagzi")), r
        assert r["crop"] in {"citrus", "mandarin", "orange", "sweet orange", "sweet lime"}, r
        assert claim.dose == r["dose"]  # never rebuilt or rounded
        assert len(r["page_ref"]) <= 60, r
        assert r["formulation_qty"] in r["dose"], r  # the printed cell is inside the dose
        if r["dose_ai"]:
            assert f"(a.i. {r['dose_ai']})" in r["dose"], r
        # No official registrant list was reachable: no brand names, no maker links.
        assert not r["brand_names"], r
        assert not r["maker_url"], r
    # No row names an active ingredient the PPQS list bans, withdraws or refuses, or restricts on
    # citrus (e.g. chlorpyriphos, III.4: its printed citrus row is left out).
    from bagmitra_api.kb.seed import restriction_seeds  # noqa: PLC0415

    blocked = {
        r.active_ingredient
        for r in restriction_seeds()[1]
        if r.kind != "restricted" or {"citrus", "mandarin", "sweet orange"} & set(r.crops)
    }
    for r in rows:
        parts = {p.strip().lower() for p in r["active_ingredient"].split("+")}
        assert not parts & blocked, r


async def test_seed_imports_only_sources_with_rows(engine: AsyncEngine) -> None:
    from bagmitra_api.kb.seed import seed_label_claims  # noqa: PLC0415

    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await import_label_claims(session, "cibrc_insecticides_pgr", CLAIMS_V1, T1)
        assert await seed_label_claims(session, T2, DETAIL_HEADER) == {}  # empty: no-op
        diffs = await seed_label_claims(session, T2, DETAIL_SAMPLE)
        assert list(diffs) == ["cibrc_fungicides_2024"]
        assert diffs["cibrc_fungicides_2024"].added == 2
        await session.commit()
        ctx = await load_context(
            session, crop_aliases=frozenset({"citrus"}), crop_groups=frozenset(), now=T2
        )
    by_ai = {c.active_ingredient: c for c in ctx.claims}
    assert {"imidacloprid", "copper oxychloride"} <= set(by_ai)  # admin upload kept
    assert by_ai["fixture bio"].category == "bio"
    assert by_ai["fixture a"].brand_names == ("Alpha brand", "beta", "zeta brand")
