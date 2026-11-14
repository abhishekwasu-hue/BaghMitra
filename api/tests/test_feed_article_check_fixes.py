"""VPS 2026-11-13 (owner approved): AI articles held although the model was right. Each test
quotes the shape of the source text the check misread; the negative tests show the rule itself
("every number, date and link must come from the source") is unchanged."""

from __future__ import annotations

import copy
from typing import Any

import pytest

from bagmitra_api.feed.article import canonical_url, check_articles, parse_articles
from bagmitra_api.feed.diag_held import language_differences
from bagmitra_api.feed.output_check import check_output, text_facts
from bagmitra_api.feed.output_check import language_differences as output_language_differences
from tests.test_feed_article import SOURCE, URL, issues, payload


def _with(source: str, changes: dict[str, Any]) -> list[str]:
    """Issues of the sound test article with `changes` applied to every language."""
    data = payload()
    for lang in ("mr", "hi", "en"):
        data["lang"][lang].update(copy.deepcopy(changes))
    return check_articles(source, parse_articles(data), source_url=URL)


def _bar(*values: float) -> dict[str, Any]:
    data = [{"label": f"P{i}", "value": v} for i, v in enumerate(values)]
    return {"charts": [{"type": "bar", "title": "Farmers", "unit": "farmers", "data": data}]}


# --- case 1: chart value 365011 "is not in the source" ----------------------------------------


@pytest.mark.parametrize(
    "stated",
    [
        "३ लाख ६५ हजार ११ पात्र शेतकऱ्यांना",  # Mahasamvad: a number spelt in parts
        "3 लाख 65 हजार 11 शेतकरी",
        "३,६५,०११ पात्र शेतकरी",  # Indian grouping, Devanagari digits
        "3,65,011 पात्र शेतकरी",
        "365,011 eligible farmers",  # Western grouping
        "৩,৬৫,০১১ কৃষক",  # Bengali digits
    ],
)
def test_case1_a_count_written_in_parts_or_grouped_is_found(stated: str) -> None:
    source = f"{SOURCE} धुळे जिल्ह्यातील {stated}."
    assert _with(source, _bar(365011, 1200)) == []


def test_case1_lakh_and_crore_amounts_scale_exactly() -> None:
    # As a float product 1.15 * 100000 is 114999.99999999999; the source states 115000.
    source = f"{SOURCE} एकूण 1.15 लाख शेतकरी; 88 कोटी 19 लाख रुपये वाटप; 3.65 लाख हेक्टर."
    assert _with(source, _bar(115000, 1200, 881900000, 365000)) == []


@pytest.mark.parametrize(
    ("stated", "chart"),
    [
        ("३ लाख ६५ हजार ११", 365012),  # a different count
        ("3.65 लाख", 365011),  # 3.65 lakh is 365000: a rounded figure never stands for more
        ("3.65 लाख", 365010),
        ("५ हजार ३ जिल्ह्यांत", 5003),  # "3 districts" after a thousand alone is no rest
        ("२ लाख ५० हजार", 250001),
    ],
)
def test_case1_a_chart_value_not_stated_is_still_caught(stated: str, chart: float) -> None:
    found = _with(f"{SOURCE} {stated}.", _bar(chart, 1200))
    assert f"mr.charts[0]: chart value {chart:g} is not in the source" in found


def test_case1_parts_in_the_wrong_order_are_not_joined() -> None:
    # "65 हजार 3 लाख" is no number in parts; nothing is read as 365000 or 68000.
    source = "65 हजार 3 लाख"
    assert check_output(source, {"x": "365000"}) != []
    assert check_output(source, {"x": "68000"}) != []


# --- cases 2 and 3: government links refused for http / missing scheme / upper case ------------


@pytest.mark.parametrize(
    ("url", "stored"),
    [
        ("http://www.nfsm.gov.in/mis/bline", "https://www.nfsm.gov.in/mis/bline"),  # case 2
        ("WWW.krishi.maharashtra.gov.in", "https://www.krishi.maharashtra.gov.in"),  # case 3
        ("HTTPS://Agri.NIC.in/Path", "https://agri.nic.in/Path"),
        ("//pmkisan.gov.in/", "https://pmkisan.gov.in/"),
        (" https://a@X.gov.in:8080/p?q=1#top ", "https://x.gov.in/p?q=1"),
        ("http://mahasamvad.in/12345/", "https://mahasamvad.in/12345/"),  # the source itself
    ],
)
def test_case2_3_government_links_pass_and_are_stored_canonical(url: str, stored: str) -> None:
    data = payload()
    for lang in ("mr", "hi", "en"):
        data["lang"][lang]["sources"].append({"title": "Government", "url": url})
    result = parse_articles(data)
    assert check_articles(SOURCE, result, source_url=URL) == []
    assert result.articles["mr"].as_json()["sources"][-1]["url"] == stored
    assert canonical_url(url) == stored


@pytest.mark.parametrize(
    "url",
    [
        "http://example.com/x",
        "EXAMPLE.com/x",
        "https://x.gov.in.example.com/",  # .gov.in must end the host
        "https://x.gov.in@evil.com/",  # user-name trick: the host is evil.com
        "https://gov.in.evil/",
        "ftp://x.gov.in/a",
        "mailto:a@x.gov.in",
        "javascript:alert(1)",
        "not a link",
    ],
)
def test_case2_3_other_hosts_are_still_refused(url: str) -> None:
    data = payload()
    data["lang"]["mr"]["sources"].append({"title": "Other", "url": url})
    assert any("is not the source or a government site" in i for i in issues(data))


# --- case 4: standfirst date '19 एप्रिल 2023' "is not in the source" -------------------------


@pytest.mark.parametrize(
    "stated",
    [
        "दि.19.04.2023",  # GR header: a dot right before the day
        "दि.१९.०४.२०२३",
        "दि.19/04/2023",
        "दिनांक १९ एप्रिल, २०२३",
        "१९ एप्रिल २०२३",
        "१९ एप्रील २०२३",  # common Marathi spelling of April
        "19-एप्रिल-2023",
        "19 / 04 / 2023",
        "एप्रिल 19, 2023",
        "19 April, 2023",
        "19/04/2023",
        "19-04-2023",
        "19.04.2023",
    ],
)
def test_case4_the_same_date_in_another_form_is_found(stated: str) -> None:
    source = f"{SOURCE} शासन निर्णय {stated} अन्वये योजना."
    assert _with(source, {"standfirst": "शासन निर्णय 19 एप्रिल 2023 नुसार योजना."}) == []


@pytest.mark.parametrize(
    "claimed", ["20 एप्रिल 2023", "19 मे 2023", "19 एप्रिल 2024", "04/19/2023", "2023-04-20"]
)
def test_case4_a_different_date_is_still_caught(claimed: str) -> None:
    source = f"{SOURCE} शासन निर्णय दि.19.04.2023 अन्वये योजना."
    found = _with(source, {"standfirst": f"शासन निर्णय {claimed} नुसार योजना."})
    assert any(i.startswith("mr.standfirst:") and "is not in the source" in i for i in found)


def test_case4_a_dot_after_a_digit_still_starts_no_date() -> None:
    # "1.19.04.2023" is no date (a version or a list number), as before.
    assert check_output("कलम 1.19.04.2023", {"x": "19 एप्रिल 2023"}) != []


# --- pie totals --------------------------------------------------------------------------------


def test_a_pie_of_decimal_parts_adds_up_to_its_stated_whole() -> None:
    # 0.1 + 0.2 is 0.30000000000000004 as floats; the stated whole is 0.3.
    source = f"{SOURCE} एकूण 0.3 लाख हेक्टर: 0.1 लाख आणि 0.2 लाख हेक्टर."
    data = [{"label": "A", "value": 0.1}, {"label": "B", "value": 0.2}]
    pie = {"charts": [{"type": "pie", "title": "Area", "unit": "lakh ha", "data": data}]}
    assert _with(source, pie) == []


# --- VPS 2026-11-14: "1 lakh 29 thousand" read as two amounts -------------------------------
# diag_held, agrowon.esakal.com: the source wrote "1 लाख 29 हजार शेतकरी" (joined into 129000),
# the English article "1 lakh 29 thousand farmers"; English parts were not joined, so en gave
# 100000 and 29000: "amount en.sections[3] '1 lakh'", "'29 thousand'" and "languages differ".

SAMBHAJINAGAR = "छत्रपती संभाजीनगर जिल्ह्यात 1 लाख 29 हजार शेतकरी कर्जमुक्त"
EXAM_FEES = "राज्यातील दुष्काळग्रस्त तालुक्यांतील 2 लाख 40 हजार विद्यार्थ्यांचे परीक्षा शुल्क माफ"
HAZAR_NUKTA = "हज़ार"  # हज़ार, ज + nukta sign
HAZAR_PRECOMPOSED = "हज़ार"  # हज़ार, precomposed ज़ (U+095B)
KAROD_PRECOMPOSED = "करोड़"  # करोड़, precomposed ड़ (U+095C)


def _per_language(source: str, stated: dict[str, str]) -> list[str]:
    """Issues of the sound test article with `stated[lang]` added to a section and a fact."""
    data = payload()
    for lang, text in stated.items():
        article = data["lang"][lang]
        article["sections"].append({"heading": "District", "body": text})
        article["facts"].append({"label": "Count", "value": text})
    return check_articles(f"{SOURCE} {source}.", parse_articles(data), source_url=URL)


@pytest.mark.parametrize(
    ("source", "stated"),
    [
        (
            SAMBHAJINAGAR,
            {
                "mr": "1 लाख 29 हजार शेतकरी कर्जमुक्त",
                "hi": f"1 लाख 29 {HAZAR_NUKTA} किसान कर्जमुक्त",
                "en": "1 lakh 29 thousand farmers are debt-free",
            },
        ),
        (
            EXAM_FEES,
            {
                "mr": "२ लाख ४० हजार विद्यार्थ्यांचे शुल्क माफ",
                "hi": f"2 लाख 40 {HAZAR_PRECOMPOSED} छात्रों की फीस माफ",
                "en": "Exam fees of 2 lakh 40 thousand students waived",
            },
        ),
    ],
)
def test_compound_vps_cases_pass_in_every_language(source: str, stated: dict[str, str]) -> None:
    assert _per_language(source, stated) == []


@pytest.mark.parametrize(
    "en",
    [
        "1 lakh 29 thousand farmers",
        "1 lakhs 29 thousand farmers",
        "1 lac 29 thousand farmers",
        "1.29 lakh farmers",  # the same exact value in decimal form
        "one lakh twenty-nine thousand farmers",
        "1 Lakh 29 Thousand farmers",
    ],
)
def test_compound_english_forms_match_the_marathi_parts(en: str) -> None:
    stated = {"mr": "1 लाख 29 हजार शेतकरी", "hi": "1 लाख 29 हजार किसान", "en": en}
    assert _per_language(SAMBHAJINAGAR, stated) == []


@pytest.mark.parametrize(
    ("source", "claim"),
    [
        ("एकूण 88 कोटी 19 लाख रुपये वाटप", "₹88 crore 19 lakh disbursed"),
        ("एकूण 88 कोटी 19 लाख रुपये वाटप", "Rs 88 crores 19 lakhs disbursed"),
        ("एकूण 88 कोटी 19 लाख रुपये वाटप", f"88 {KAROD_PRECOMPOSED} 19 लाख रुपये"),
        ("Total 88 crore 19 lakh rupees", "८८ कोटी १९ लाख रुपये"),  # English source, joined too
        ("1 lakh 29 thousand farmers", "1 लाख 29 हजार शेतकरी"),
        ("3 lakh 65 thousand 11 farmers", "365,011 farmers"),
        ("1 thousand 600 animals", "1,600 animals"),
    ],
)
def test_compound_english_and_hindi_parts_join_on_both_sides(source: str, claim: str) -> None:
    assert check_output(source, {"en.body": claim}) == []


@pytest.mark.parametrize(
    "claim",
    [
        "1 lakh farmers",  # a part of the compound alone
        "29 thousand farmers",
        "29 farmers",
        "1.3 lakh farmers",  # rounded
        "1.2 lakh farmers",
        "1 lakh 30 thousand farmers",
        "1 lakh 2 thousand 9 farmers",
        "129 farmers",
    ],
)
def test_compound_a_partial_or_rounded_value_still_fails(claim: str) -> None:
    assert check_output(SAMBHAJINAGAR, {"en.body": claim}) != []


def test_compound_separate_amounts_in_the_source_do_not_vouch_for_a_compound() -> None:
    source = "1 लाख शेतकरी आणि 29 हजार विद्यार्थी"
    assert check_output(source, {"en.body": "1 lakh farmers and 29 thousand students"}) == []
    assert check_output(source, {"en.body": "1 lakh 29 thousand beneficiaries"}) != []


def test_compound_parts_in_text_facts_are_one_amount_in_every_form() -> None:
    forms = [
        "1 लाख 29 हजार",
        "१ लाख २९ हजार",
        f"1 लाख 29 {HAZAR_NUKTA}",
        f"1 लाख 29 {HAZAR_PRECOMPOSED}",
        "1 lakh 29 thousand",
        "1.29 lakh",
        "₹1,29,000",
    ]
    assert {f: text_facts(f).amounts for f in forms} == {f: {129000.0} for f in forms}


def test_compound_languages_differ_only_on_a_real_difference() -> None:
    stated = {"mr": "1 लाख 29 हजार शेतकरी", "hi": "1 लाख 29 हजार किसान"}
    found = _per_language(SAMBHAJINAGAR, {**stated, "en": "1 lakh 30 thousand farmers"})
    assert "languages: amounts or dates differ between mr / hi / en" in found
    data = payload()
    for lang, text in {**stated, "en": "1 lakh 29 thousand farmers"}.items():
        data["lang"][lang]["facts"].append({"label": "Count", "value": text})
    assert language_differences(parse_articles(data)) == []


@pytest.mark.parametrize(
    ("source", "mr", "en"),
    [
        ("सुमारे १ हजार ६०० जनावरे", "१ हजार ६०० जनावरे", "1,600 animals"),
        ("1,600 जनावरे", "1,600 जनावरे", "1 thousand 600 animals"),
        (SAMBHAJINAGAR, "1 लाख 29 हजार शेतकरी", "1.29 lakh farmers"),
        (SAMBHAJINAGAR, "1 लाख 29 हजार शेतकरी", "129,000 farmers"),
        ("एकूण 1 लाख शेतकरी", "1 लाख शेतकरी", "100,000 farmers"),
    ],
)
def test_compound_the_same_value_in_another_form_is_no_language_difference(
    source: str, mr: str, en: str
) -> None:
    found = _per_language(source, {"mr": mr, "hi": mr, "en": en})
    assert found == []
    facts = {"mr": text_facts(mr), "en": text_facts(en)}
    assert output_language_differences(facts) == {}


@pytest.mark.parametrize(
    ("mr", "en", "lacking"),
    [
        ("१ हजार ६०० जनावरे", "1,700 animals", {"mr": ["1600"]}),
        ("1,600 जनावरे", "1 thousand 700 animals", {"en": ["1700"]}),
        ("1 लाख 29 हजार शेतकरी", "1.3 lakh farmers", {"mr": ["129000"], "en": ["130000"]}),
        ("₹ 7,000 अनुदान", "a subsidy for farmers", {"mr": ["7000"]}),  # en drops it
    ],
)
def test_compound_a_real_language_difference_is_still_flagged(
    mr: str, en: str, lacking: dict[str, list[str]]
) -> None:
    facts = {"mr": text_facts(mr), "hi": text_facts(mr), "en": text_facts(en)}
    hi = {"hi": lacking["mr"]} if "mr" in lacking else {}  # hi states what mr states
    assert output_language_differences(facts) == {**lacking, **hi}
    source = f"{mr} {en}"
    found = _per_language(source, {"mr": mr, "hi": mr, "en": en})
    assert "languages: amounts or dates differ between mr / hi / en" in found


def test_compound_a_number_absent_from_the_source_is_still_held() -> None:
    # diag_held, kept held: "number mr.sections[2] AI '2.25'"; no such digits or words in source.
    stated = {
        "mr": "1 लाख 29 हजार शेतकरी; दर 2.25",
        "hi": "1 लाख 29 हजार किसान; दर 2.25",
        "en": "1 lakh 29 thousand farmers; rate 2.25",
    }
    found = _per_language(SAMBHAJINAGAR, stated)
    assert "mr.sections[3]: number '2.25' is not in the source" in found
    assert not any("lakh" in i or "लाख" in i or "thousand" in i for i in found)
