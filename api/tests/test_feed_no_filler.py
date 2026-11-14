"""Owner 2026-11-14 (screenshot, agrowon article): when the source has nothing for a section or a
point, the writer omits it. A sentence that only says the source lacks the information ("माहिती
उपलब्ध मजकुरात दिलेली नाही") is dropped deterministically, and real farming advice that happens
to say "not available" is kept."""

from __future__ import annotations

import copy
import uuid
from datetime import UTC, datetime
from typing import Any

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.feed.article import ARTICLE_PROMPT, ArticleError, parse_articles
from bagmitra_api.feed.clean_filler import EVENT, clean_filler
from bagmitra_api.feed.knowledge_article import KNOWLEDGE_PROMPT, from_saved, parse_knowledge
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent
from bagmitra_api.feed.no_filler import clean_saved, clean_text, is_filler
from tests.test_feed_article import payload
from tests.test_feed_knowledge import (
    TODAY,
    Model,
    Sources,
    alert,
    answer,
    knowledge_items,
    maker,
    run,
)
from tests.test_feed_knowledge import article as knowledge_article
from tests.test_feed_news import news_source

FILLER = [
    # The owner's screenshot, word for word.
    "पेरणीची वेळ, वाण, खत व्यवस्थापन याबद्दलची माहिती उपलब्ध मजकुरात दिलेली नाही.",
    "त्यातील मजकूर येथे उपलब्ध नाही.",
    "या योजनेची अंतिम मुदत स्रोतात नमूद केलेली नाही.",
    "वृत्तात अर्जाची पद्धत सांगितलेली नाही.",
    "याबाबत अधिक माहिती दिलेली नाही.",
    "बुवाई के समय की जानकारी स्रोत में नहीं दी गई है।",
    "लेख में आवेदन की अंतिम तिथि का उल्लेख नहीं है।",
    "Details of the sowing time are not available in the text.",
    "The source does not mention the subsidy amount.",
    "The article does not say when the scheme starts.",
    "No information on varieties is given in the source.",
]

ADVICE = [
    "पाणी उपलब्ध नाही तेथे ठिबक सिंचन वापरा.",
    "जेथे पाण्याचा स्रोत उपलब्ध नाही तेथे शेततळे करा.",
    "बियाणे बाजारात उपलब्ध नाही अशी तक्रार शेतकऱ्यांनी केली.",
    "लेखी अर्ज उपलब्ध नाही तर ऑनलाइन अर्ज करा.",
    "कृषी विभागाकडून अधिक माहिती घ्या.",
    "जहाँ पानी उपलब्ध नहीं है, वहाँ ड्रिप लगाएं।",
    "If water is not available, use drip irrigation.",
    "If the source of water is not available, dig a farm pond.",
    "Apply on the MahaDBT portal before 30 November 2026.",
    "रु. 6,000 प्रति हेक्टर अनुदान मिळेल.",
]


@pytest.mark.parametrize("sentence", FILLER)
def test_a_missing_information_sentence_is_filler(sentence: str) -> None:
    assert is_filler(sentence)
    assert clean_text(sentence) == ""


@pytest.mark.parametrize("sentence", ADVICE)
def test_real_advice_is_kept(sentence: str) -> None:
    assert not is_filler(sentence)
    assert clean_text(sentence) == sentence


def test_only_the_filler_sentence_leaves_a_paragraph() -> None:
    body = (
        "अर्ज mahadbt पोर्टलवर करावा. पेरणीची वेळ, वाण याबद्दलची माहिती उपलब्ध मजकुरात "
        "दिलेली नाही. रु. 6,000 अनुदान मिळेल.\n- त्यातील मजकूर येथे उपलब्ध नाही.\n"
        "- पाणी उपलब्ध नाही तेथे ठिबक वापरा."
    )
    assert clean_text(body) == (
        "अर्ज mahadbt पोर्टलवर करावा. रु. 6,000 अनुदान मिळेल.\n- पाणी उपलब्ध नाही तेथे ठिबक वापरा."
    )


def test_text_without_filler_is_returned_unchanged() -> None:
    body = "Line one.  Two spaces stay.\n\nA new paragraph."
    assert clean_text(body) == body


def _with_filler() -> dict[str, Any]:
    data = payload()
    mr = data["lang"]["mr"]
    mr["sections"].append(
        {
            "heading": "शेतकरी पुढे काय करू शकतात",
            "body": "पेरणीची वेळ, वाण याबद्दलची माहिती उपलब्ध मजकुरात दिलेली नाही. "
            "त्यातील मजकूर येथे उपलब्ध नाही.",
        }
    )
    mr["key_points"].append("अर्जाची पद्धत स्रोतात दिलेली नाही.")
    mr["facts"].append({"label": "वाण", "value": "स्रोतात दिलेले नाही"})
    return data


def test_the_parser_drops_filler_points_facts_and_empty_sections() -> None:
    clean = parse_articles(payload()).articles["mr"]
    got = parse_articles(_with_filler()).articles["mr"]
    assert got.sections == clean.sections
    assert got.key_points == clean.key_points
    assert got.facts == clean.facts
    assert "शेतकरी पुढे काय करू शकतात" not in str(got.as_json())


def test_fewer_sections_and_points_are_allowed() -> None:
    data = payload()
    for lang in data["lang"].values():
        lang["sections"] = lang["sections"][:1]
        lang["key_points"] = lang["key_points"][:1]
    got = parse_articles(data).articles["en"]
    assert len(got.sections) == 1
    assert len(got.key_points) == 1


def test_an_article_that_is_only_filler_is_refused() -> None:
    data = payload()
    data["lang"]["en"]["sections"] = [
        {"heading": "Next steps", "body": "The source does not mention what farmers can do."}
    ]
    with pytest.raises(ArticleError):
        parse_articles(data)


def test_the_saved_article_is_cleaned_on_the_recheck_path() -> None:
    """The held re-checks read the saved article through `parse_articles` (news and official)
    and `from_saved` (knowledge), so a saved filler sentence is dropped before it is stored."""
    data = _with_filler()
    saved = dict(data["lang"])
    again = parse_articles({"relevant": True, "political": False, "lang": copy.deepcopy(saved)})
    assert "मजकुरात" not in str(again.articles["mr"].as_json())
    k = knowledge_article()
    k["lang"]["mr"]["sections"].append(
        {"heading": "अंतिम मुदत", "body": "अर्जाची अंतिम मुदत स्रोतात दिलेली नाही."}
    )
    written = parse_knowledge(copy.deepcopy(k)).articles["mr"]
    assert len(written.sections) == 4
    stored = {
        lang: {"headline": a["title"], "standfirst": a["standfirst"], "sections": a["sections"]}
        for lang, a in k["lang"].items()
    }
    result = from_saved(stored)
    assert result is not None
    assert len(result.articles["mr"].sections) == 4


def test_knowledge_allows_fewer_sections() -> None:
    k = knowledge_article()
    for lang in k["lang"].values():
        lang["sections"] = lang["sections"][:2]
    assert len(parse_knowledge(k).articles["hi"].sections) == 2


def test_clean_saved_reports_what_it_removes() -> None:
    saved = _with_filler()["lang"]["mr"]
    cleaned, removed = clean_saved(saved)
    assert cleaned is not None
    assert len(removed) == 4
    assert [s["heading"] for s in cleaned["sections"]] == [
        s["heading"] for s in payload()["lang"]["mr"]["sections"]
    ]
    assert cleaned["key_points"] == payload()["lang"]["mr"]["key_points"]
    assert cleaned["facts"] == payload()["lang"]["mr"]["facts"]
    assert saved["sections"][-1]["heading"] == "शेतकरी पुढे काय करू शकतात"  # input untouched
    same, none = clean_saved(payload()["lang"]["mr"])
    assert (same, none) == (payload()["lang"]["mr"], [])


def test_clean_saved_refuses_to_empty_an_article() -> None:
    saved = payload()["lang"]["en"]
    saved["sections"] = [{"heading": "x", "body": "The source does not mention it."}]
    cleaned, removed = clean_saved(saved)
    assert cleaned is None
    assert removed


def test_the_prompts_forbid_missing_information_sentences() -> None:
    for prompt in (ARTICLE_PROMPT, KNOWLEDGE_PROMPT):
        assert "Leave out" in prompt
        assert (
            "Never write a sentence, in any language, saying that something is not given"
            in " ".join(prompt.split())
        )
    assert '"key_points": [1-5 str]' in ARTICLE_PROMPT
    assert '"sections": [1-5 {' in ARTICLE_PROMPT
    assert '"sections": [2-8 {' in KNOWLEDGE_PROMPT


async def _saved_item(
    session: AsyncSession, article: dict[str, Any] | None, status: str
) -> FeedItem:
    source = await news_source(session, key=f"src_{uuid.uuid4().hex[:8]}")
    item = FeedItem(
        id=uuid.uuid4(),
        type="news",
        source_id=source.id,
        published_at=datetime(2026, 11, 14, tzinfo=UTC),
        url="https://agrowon.example/1",
        status=status,
        trust_level="news",
        check_issues=[],
    )
    session.add(item)
    session.add(
        FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang="mr", title="मथळा", article=article)
    )
    await session.flush()
    return item


async def test_the_cleaner_is_read_only_unless_applied(engine: AsyncEngine) -> None:
    dirty = _with_filler()["lang"]["mr"]
    only_filler = payload()["lang"]["en"]
    only_filler["sections"] = [{"heading": "x", "body": "The source does not mention it."}]
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        published = await _saved_item(session, dirty, "published")
        await _saved_item(session, payload()["lang"]["mr"], "published")
        await _saved_item(session, only_filler, "held")
        await _saved_item(session, None, "held")

        dry = await clean_filler(session, apply=False)
        assert (dry.applied, dry.checked, dry.changed, len(dry.left)) == (False, 3, 1, 1)
        assert dry.items[0]["item"] == str(published.id)
        assert len(dry.items[0]["removed"]) == 4
        row = await session.scalar(select(FeedItemI18n).where(FeedItemI18n.item_id == published.id))
        assert row is not None
        assert row.article == dirty

        done = await clean_filler(session, apply=True)
        assert done.changed == 1
        await session.refresh(row)
        assert row.article is not None
        assert "मजकुरात" not in str(row.article)
        assert row.article["sections"] == payload()["lang"]["mr"]["sections"]
        kinds = await session.scalars(
            select(FeedReviewEvent.kind).where(FeedReviewEvent.item_id == published.id)
        )
        assert list(kinds) == [EVENT]
        again = await clean_filler(session, apply=True)
        assert again.changed == 0


async def test_the_held_knowledge_recheck_stores_the_cleaned_article(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        await run(session, Model(answer(knowledge_article("४५", en_number="45"))), Sources())
        (item,) = await knowledge_items(session)
        assert item.status == "held"
        row = await session.scalar(
            select(FeedItemI18n).where(FeedItemI18n.item_id == item.id, FeedItemI18n.lang == "mr")
        )
        assert row is not None
        assert row.article is not None
        filler = {"heading": "अंतिम मुदत", "body": "अर्जाची अंतिम मुदत स्रोतात दिलेली नाही."}
        row.article = {**row.article, "sections": [*row.article["sections"], filler]}
        await session.flush()
        await run(session, None, Sources())
        await session.refresh(row)
        assert row.article is not None
        assert filler not in row.article["sections"]
        assert len(row.article["sections"]) == 4
