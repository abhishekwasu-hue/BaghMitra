"""Addendum v1.4 §4.7 / §7: table-driven matching rules (district / crop / hectare edges)."""

from __future__ import annotations

import pytest

from bagmitra_api.feed.matching import (
    Profile,
    Target,
    eligibility_reasons,
    passes_filter,
    profile_from,
    target_matches,
)

NAGPUR_SANTRA_2HA = Profile(district="Nagpur", crops=frozenset({"santra"}), land_ha=2.0)
NO_DATA = Profile(district=None, crops=frozenset(), land_ha=None)


@pytest.mark.parametrize(
    ("target", "profile", "expected"),
    [
        (Target(), NAGPUR_SANTRA_2HA, True),
        (Target(district="Nagpur"), NAGPUR_SANTRA_2HA, True),
        (Target(district="  nagpur "), NAGPUR_SANTRA_2HA, True),
        (Target(district="Amravati"), NAGPUR_SANTRA_2HA, False),
        (Target(district="Nagpur"), NO_DATA, False),
        (Target(crop="Santra"), NAGPUR_SANTRA_2HA, True),
        (Target(crop="mosambi"), NAGPUR_SANTRA_2HA, False),
        (Target(min_ha=2.0), NAGPUR_SANTRA_2HA, True),  # inclusive lower edge
        (Target(max_ha=2.0), NAGPUR_SANTRA_2HA, True),  # inclusive upper edge
        (Target(min_ha=2.01), NAGPUR_SANTRA_2HA, False),
        (Target(max_ha=1.99), NAGPUR_SANTRA_2HA, False),
        (Target(min_ha=0.5, max_ha=5), NAGPUR_SANTRA_2HA, True),
        (Target(min_ha=0.5), NO_DATA, False),  # unknown land never matches a size rule
        (Target(district="Nagpur", crop="mosambi"), NAGPUR_SANTRA_2HA, False),
        (Target(district="Nagpur", crop="santra", max_ha=5), NAGPUR_SANTRA_2HA, True),
    ],
)
def test_target_matches(target: Target, profile: Profile, expected: bool) -> None:
    assert target_matches(target, profile) is expected


@pytest.mark.parametrize(
    ("targets", "lang", "expected"),
    [
        ([], "en", []),
        ([Target(district="Amravati")], "en", []),
        (
            [Target(district="Nagpur")],
            "en",
            ["You may be eligible because your farm is in Nagpur district."],
        ),
        (
            [Target(crop="santra", min_ha=1, max_ha=5)],
            "en",
            [
                "You may be eligible because you grow santra.",
                "You may be eligible because your recorded land (2 ha) is within 1–5 ha.",
            ],
        ),
        (
            [Target(min_ha=1)],
            "en",
            ["You may be eligible because your recorded land (2 ha) is at least 1 ha."],
        ),
        (
            [Target(max_ha=2.5)],
            "mr",
            ["तुमची नोंदवलेली जमीन (2 हे.) जास्तीत जास्त 2.5 हे. असल्याने तुम्ही पात्र असू शकता."],
        ),
        (
            [Target(district="Nagpur"), Target(district="Nagpur", crop="mosambi")],
            "hi",
            ["आपका खेत Nagpur जिले में है, इसलिए आप पात्र हो सकते हैं।"],
        ),
        (
            [Target(crop="santra"), Target(crop="santra", district="Nagpur")],
            "xx",  # unknown language falls back to English
            [
                "You may be eligible because you grow santra.",
                "You may be eligible because your farm is in Nagpur district.",
            ],
        ),
    ],
)
def test_eligibility_reasons(targets: list[Target], lang: str, expected: list[str]) -> None:
    assert eligibility_reasons(targets, NAGPUR_SANTRA_2HA, lang) == expected


def test_wording_never_promises_a_benefit() -> None:
    target = Target(district="Nagpur", crop="santra", min_ha=1, max_ha=3)
    for lang in ("en", "mr", "hi"):
        for reason in eligibility_reasons([target], NAGPUR_SANTRA_2HA, lang):
            assert "will receive" not in reason
            assert "मिळेल" not in reason
            assert "मिलेगा" not in reason
    assert all("may be eligible" in r for r in eligibility_reasons([target], NAGPUR_SANTRA_2HA))


@pytest.mark.parametrize(
    ("targets", "district", "crop", "expected"),
    [
        ([], "Nagpur", "santra", True),
        ([Target(district="Amravati")], None, None, True),
        ([Target(district="Amravati")], "Nagpur", None, False),
        ([Target(district="amravati")], "Amravati", None, True),
        ([Target(crop="santra")], "Nagpur", None, True),
        ([Target(crop="santra")], None, "mosambi", False),
        ([Target(district="Nagpur", crop="mosambi")], "Nagpur", "santra", False),
        ([Target(crop="mosambi"), Target(crop="santra")], None, "santra", True),
    ],
)
def test_passes_filter(
    targets: list[Target], district: str | None, crop: str | None, expected: bool
) -> None:
    assert passes_filter(targets, district=district, crop=crop) is expected


def test_profile_from_plots() -> None:
    profile = profile_from(" Nagpur ", [("santra", 12_500.0), ("Mosambi", 7_500.0), ("", None)])
    assert profile == Profile("Nagpur", frozenset({"santra", "mosambi"}), 2.0)
    assert profile_from("  ", [("santra", None), ("santra", 0.0)]) == Profile(
        None, frozenset({"santra"}), None
    )
