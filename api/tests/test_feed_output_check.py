"""Addendum v1.4 §6: every number, amount, date and scheme name in a summary must appear in
the source text; a hallucinated value is caught and reported."""

from __future__ import annotations

from typing import Any

import pytest

from bagmitra_api.feed.output_check import Mismatch, check_output, normalise

SOURCE_MR = (
    "शासन निर्णय क्रमांक: फळबाग-२०२५/प्र.क्र.४५/११-अ, दिनांक २६ ऑक्टोबर २०२६. "
    "भाऊसाहेब फुंडकर फळबाग लागवड योजना अंतर्गत प्रति हेक्टर ₹ १,००,००० अनुदान तीन वर्षांत "
    "देय. अर्जाची अंतिम मुदत ३१/१२/२०२६ आहे. झाडे जगण्याचे प्रमाण ८० % व ९० % असावे. "
    "एकूण तरतूद ५० कोटी."
)
GLOSSARY = {
    "Bhausaheb Fundkar Falbag Lagvad": ["भाऊसाहेब फुंडकर फळबाग लागवड"],
    "Namo Shetkari Mahasanman Nidhi": ["नमो शेतकरी महासन्मान निधी"],
}


def kinds(found: list[Mismatch]) -> list[tuple[str, str]]:
    return [(m.kind, m.text) for m in found]


@pytest.mark.parametrize(
    "summary",
    [
        "Bhausaheb Fundkar Falbag Lagvad: ₹1,00,000 per hectare over three years.",
        "Rs. 1 lakh per hectare; apply by 31 December 2026.",
        "Apply by 2026-12-31 (GR dated 26/10/2026).",
        "Apply by December 31, 2026. Survival 80 % and 90 %.",
        "अंतिम मुदत ३१ डिसेंबर २०२६; ₹१ लाख प्रति हेक्टर.",
        "अंतिम तिथि 31 दिसंबर 2026, कुल 50 करोड़ रुपये।",
        "Total outlay ₹50 crore; GR 2025/45 of October 2026.",
        "Survival 80%, budget 500000000.",
        "",
    ],
)
def test_supported_claims_pass(summary: str) -> None:
    assert check_output(SOURCE_MR, {"en.summary": summary}, scheme_glossary=GLOSSARY) == []


def test_injected_hallucinated_amount_is_caught() -> None:
    found = check_output(SOURCE_MR, {"en.summary": "Subsidy ₹1,50,000 per hectare."})
    assert kinds(found) == [("amount", "₹1,50,000")]
    found = check_output(SOURCE_MR, {"mr.summary": "अनुदान २ लाख"})
    assert kinds(found) == [("amount", "2 लाख")]


def test_injected_hallucinated_date_is_caught() -> None:
    found = check_output(SOURCE_MR, {"en.summary": "Apply by 15/01/2027."})
    assert found == [Mismatch("date", "15/01/2027", "en.summary")]
    assert kinds(check_output(SOURCE_MR, {"x": "by 30 November 2026"})) == [
        ("date", "30 november 2026")
    ]
    assert kinds(check_output(SOURCE_MR, {"x": "from March 2027"})) == [("date", "march 2027")]


def test_plain_numbers_and_impossible_dates() -> None:
    assert kinds(check_output(SOURCE_MR, {"x": "Plant 400 trees"})) == [("number", "400")]
    # 31/02 is no date; its parts are read as numbers, and 2 is not in the source.
    assert kinds(check_output(SOURCE_MR, {"x": "31/02/2026"})) == [("number", "02")]


def test_unknown_scheme_name_in_summary_is_caught() -> None:
    found = check_output(
        SOURCE_MR, {"en.title": "Namo Shetkari Mahasanman Nidhi top-up"}, scheme_glossary=GLOSSARY
    )
    assert kinds(found) == [("scheme_name", "Namo Shetkari Mahasanman Nidhi")]


def test_card_fields_need_source_values_and_pages() -> None:
    card: dict[str, dict[str, Any]] = {
        "scheme_name": {"value": "Bhausaheb Fundkar Falbag Lagvad", "page": "p. 1"},
        "amount": {"value": "₹1,00,000 per ha", "page": "p. 2"},
        "deadline": {"value": "31/12/2026", "page": None},
        "documents": {"value": "not_stated", "page": None},
        "eligibility": {"value": None},
        "who_benefits": {"value": "Farmers growing 400 trees", "page": "p. 3"},
    }
    found = check_output(SOURCE_MR, {}, card_fields=card, scheme_glossary=GLOSSARY)
    assert kinds(found) == [("missing_page", "31/12/2026"), ("number", "400")]


def test_card_scheme_name_must_be_in_source() -> None:
    for value in ("Mukhyamantri Baliraja", "Namo Shetkari Mahasanman Nidhi"):
        card = {"scheme_name": {"value": value, "page": "p. 1"}}
        found = check_output(SOURCE_MR, {}, card_fields=card, scheme_glossary=GLOSSARY)
        assert ("scheme_name", value) in kinds(found)
    card = {"scheme_name": {"value": "भाऊसाहेब फुंडकर फळबाग लागवड योजना", "page": "p. 1"}}
    assert check_output(SOURCE_MR, {}, card_fields=card) == []


def test_mismatches_are_unique_and_serialisable() -> None:
    found = check_output(SOURCE_MR, {"x": "₹7 and ₹7"})
    assert [m.as_dict() for m in found] == [{"kind": "amount", "text": "₹7", "where": "x"}]


def test_normalise() -> None:
    assert normalise("  १,००,०००\n रुपये ") == "1,00,000 रुपये"
