"""Addendum v1.3 §4 and §9: the legal & safety gate, table-driven."""

from __future__ import annotations

from datetime import date

import pytest

from bagmitra_api.kb.gate import (
    ChemicalOption,
    GateContext,
    LabelClaim,
    Restriction,
    evaluate,
    normalise_ai,
)

# Mirrors addendum §3.8 (checked 2026-10-12). Real data arrives via importers (K1b).
RESTRICTIONS = [
    Restriction("benomyl", "banned", (), (), "S.O. 3951(E) 8 Aug 2018"),
    Restriction("phorate", "banned", (), (), "S.O. 3951(E) 8 Aug 2018"),
    Restriction("dichlorvos", "banned", (), (), "S.O. 3951(E); S.O. 1196(E) 2020"),
    Restriction("dicofol", "banned", (), (), "S.O. 4294(E) 3 Oct 2023"),
    Restriction("chlorpyrifos", "restricted", ("citrus", "ber", "tobacco"), (), "S.O. 4294(E)"),
    Restriction("dimethoate", "restricted", (), ("fruit_eaten_raw",), "S.O. 4294(E)"),
]
CLAIMS = [
    LabelClaim(
        active_ingredient="imidacloprid",
        formulation="17.8 SL",
        crop="citrus",
        target="psylla",
        dose="per label",
        interval_days=None,
        phi_days=15,
        max_sprays=None,
        source_key="cibrc_insecticides",
    ),
    LabelClaim(
        active_ingredient="copper oxychloride",
        formulation="50 WP",
        crop="citrus",
        target="canker",
        dose="per label",
        interval_days=None,
        phi_days=None,
        max_sprays=None,
        source_key="cibrc_fungicides_2024",
    ),
]
SYNONYMS = {"cycocel": "chlormequat chloride", "ddvp": "dichlorvos", "blitox": "copper oxychloride"}
CTX = GateContext(
    crop_aliases=frozenset({"citrus", "mandarin"}),
    crop_groups=frozenset({"fruit_eaten_raw"}),
    claims=CLAIMS,
    restrictions=RESTRICTIONS,
    synonyms=SYNONYMS,
)


def opt(ai: str, target: str = "psylla", formulation: str = "17.8 SL") -> ChemicalOption:
    return ChemicalOption(active_ingredient=ai, formulation=formulation, target=target)


@pytest.mark.parametrize(
    ("ai", "reason"),
    [
        ("benomyl", "banned"),
        ("Dichlorvos", "banned"),
        ("DDVP", "banned"),
        ("dicofol", "banned"),
        ("phorate", "banned"),
        ("chlorpyrifos", "restricted_for_crop"),
        ("dimethoate", "restricted_for_crop"),
    ],
)
def test_banned_and_restricted_chemicals_never_pass(ai: str, reason: str) -> None:
    result = evaluate(opt(ai), CTX, today=date(2026, 10, 12), planned_harvest=None)
    assert not result.allowed
    assert reason in result.reasons


def test_registered_with_citrus_label_passes_and_label_values_are_used() -> None:
    result = evaluate(opt("imidacloprid"), CTX, today=date(2026, 10, 12), planned_harvest=None)
    assert result.allowed
    assert result.claim is not None
    assert result.claim.phi_days == 15


def test_no_label_claim_for_this_target_or_formulation_is_suppressed() -> None:
    wrong_target = evaluate(
        opt("imidacloprid", target="mites"), CTX, today=date(2026, 1, 1), planned_harvest=None
    )
    wrong_form = evaluate(
        opt("imidacloprid", formulation="70 WG"), CTX, today=date(2026, 1, 1), planned_harvest=None
    )
    unknown = evaluate(
        opt("gibberellic acid", target="fruit_drop"),
        CTX,
        today=date(2026, 1, 1),
        planned_harvest=None,
    )
    for result in (wrong_target, wrong_form, unknown):
        assert not result.allowed
        assert result.reasons == ["no_label_claim"]


def test_phi_beyond_planned_harvest_blocks() -> None:
    ok = evaluate(
        opt("imidacloprid"), CTX, today=date(2026, 10, 1), planned_harvest=date(2026, 10, 20)
    )
    late = evaluate(
        opt("imidacloprid"), CTX, today=date(2026, 10, 10), planned_harvest=date(2026, 10, 20)
    )
    assert ok.allowed
    assert not late.allowed
    assert late.reasons == ["phi_conflict"]


def test_trade_names_resolve_to_active_ingredients() -> None:
    assert normalise_ai("  Blitox ", SYNONYMS) == "copper oxychloride"
    result = evaluate(
        opt("Blitox", target="canker", formulation="50 WP"),
        CTX,
        today=date(2026, 1, 1),
        planned_harvest=None,
    )
    assert result.allowed


def test_restriction_on_other_crops_does_not_block_citrus() -> None:
    ctx = GateContext(
        crop_aliases=frozenset({"citrus"}),
        crop_groups=frozenset(),
        claims=CLAIMS,
        restrictions=[Restriction("imidacloprid", "restricted", ("paddy",), (), "test")],
        synonyms={},
    )
    assert evaluate(opt("imidacloprid"), ctx, today=date(2026, 1, 1), planned_harvest=None).allowed
