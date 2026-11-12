"""Owner 2026-11-12 (Q145): "many farming articles appeared in the last month, on other fruits
too; find them". The article writer and the classifier accept useful farming knowledge for
Maharashtra / Vidarbha farmers (all fruits, vegetables, soil, water, weather, pests, markets,
post-harvest) besides items that change something for farmers, and still reject politics. The
number / name checks are unchanged: a knowledge article with a number not in its source is
held like any other."""

from __future__ import annotations

from bagmitra_api.feed.ai import CLASSIFY_PROMPT
from bagmitra_api.feed.article import ARTICLE_PROMPT, check_articles, parse_articles

FRUITS = ("mango", "banana", "pomegranate", "grapes", "guava")
TOPICS = ("vegetables", "soil", "water", "weather", "pest", "markets", "post-harvest")


def test_article_prompt_accepts_farming_knowledge_for_every_fruit() -> None:
    assert "Vidarbha" in ARTICLE_PROMPT
    for word in (*FRUITS, *TOPICS):
        assert word in ARTICLE_PROMPT, word
    for word in ("Politics", "crime", "entertainment"):
        assert word in ARTICLE_PROMPT, word
    assert "agriculture news outlet" in ARTICLE_PROMPT
    # The fact rules stay as they were.
    assert "Copy every number, amount, percentage, date and scheme name" in ARTICLE_PROMPT


def test_classifier_accepts_advisories_and_rejects_politics() -> None:
    for word in ("Vidarbha", "pomegranate", "banana", "pests", "post-harvest", "politics"):
        assert word in CLASSIFY_PROMPT, word


def _article(body: str) -> dict[str, object]:
    return {
        "headline": "डाळिंबावरील तेलकट डाग",
        "standfirst": "तेलकट डाग रोगाचे व्यवस्थापन.",
        "key_points": ["बागेची स्वच्छता", "रोगट फळे नष्ट करा", "तज्ज्ञांचा सल्ला"],
        "sections": [
            {"heading": "रोग", "body": body},
            {"heading": "उपाय", "body": "रोगट फांद्या छाटा."},
            {"heading": "पुढे", "body": "कृषी सहायकांचा सल्ला घ्या."},
        ],
        "facts": [
            {"label": "पीक", "value": "डाळिंब"},
            {"label": "रोग", "value": "तेलकट डाग"},
            {"label": "स्रोत", "value": "बातमी"},
        ],
        "charts": [],
        "key_dates": [],
        "sources": [{"title": "Source", "url": "https://www.agri-news.example/pomegranate"}],
    }


def test_a_knowledge_article_still_fails_on_a_number_not_in_its_source() -> None:
    source = "Pomegranate oily spot (bacterial blight): prune infected twigs, keep orchards clean."
    good = parse_articles(
        {
            "relevant": True,
            "political": False,
            "lang": {lang: _article("तेलकट डाग जिवाणूजन्य रोग आहे.") for lang in ("mr", "hi", "en")},
        }
    )
    url = "https://www.agri-news.example/pomegranate"
    assert check_articles(source, good, source_url=url) == []
    bad = parse_articles(
        {
            "relevant": True,
            "political": False,
            "lang": {lang: _article("४० टक्के बागा बाधित आहेत.") for lang in ("mr", "hi", "en")},
        }
    )
    problems = check_articles(source, bad, source_url=url)
    assert problems
    assert any("not in the source" in p for p in problems)
