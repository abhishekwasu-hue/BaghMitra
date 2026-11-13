"""VPS 2026-11-13 (owner approved): AI articles held although the model was right. Each test
quotes the shape of the source text the check misread; the negative tests show the rule itself
("every number, date and link must come from the source") is unchanged."""

from __future__ import annotations

import copy
from typing import Any

import pytest

from bagmitra_api.feed.article import canonical_url, check_articles, parse_articles
from bagmitra_api.feed.output_check import check_output
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
