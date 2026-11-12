"""Knowledge articles, ज्ञान लेख (owner 2026-11-11, Q141). The model is the real Anthropic adapter
and the sources are fetched by the real `card_check.fetch_text`, both over httpx.MockTransport
(nothing leaves the test). Covered: the three triggers, the dedupe, a number not in the input
holds the article, the held re-check, the kill switch, newspapers never read, the feed filter,
and the bundled cards being the app's own file."""

from __future__ import annotations

import json
import uuid
from collections.abc import Callable
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.bahar.seed import StageTemplateSeeds
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import PlotRiskAlert
from bagmitra_api.feed.ai import AnthropicFeedAi
from bagmitra_api.feed.knowledge import (
    DEDUPE_DAYS,
    KnowledgeRun,
    cached_fetcher,
    practice_cards,
    risk_topics,
    run_knowledge,
    scheme_topics,
    stage_topics,
)
from bagmitra_api.feed.knowledge_article import KNOWLEDGE_SCHEMA, check_knowledge, parse_knowledge
from bagmitra_api.feed.models import (
    FeedItem,
    FeedItemI18n,
    FeedKnowledgeRun,
    FeedReviewEvent,
    FeedSource,
)
from tests.test_feed_api import ai_box, api, ocr_box

__all__ = ["ai_box", "api", "ocr_box"]  # fixtures used here

ROOT = Path(__file__).resolve().parents[2]
NOW = datetime(2026, 11, 25, 4, 30, tzinfo=UTC)
TODAY = date(2026, 11, 25)
NHB_URL = "https://www.nhb.gov.in/pdf/fruits/citrus/pests.html"
PAPER_URL = "https://agrowon.esakal.com/agroguide/psylla"
NHB_PAGE = (
    "<html><body><h1>Citrus Psylla</h1><p>Hang yellow sticky traps at 30 per acre from the "
    "first week of June and change them monthly. Watch every new flush for nymphs.</p>"
    "<p>Withhold water for 40 to 60 days to induce the bahar.</p></body></html>"
)


def cards(
    psylla_text: str = "Hang yellow sticky traps, 30 per acre, and change them monthly.",
) -> dict[str, Any]:
    point = {"en": psylla_text, "mr": "एकरी ३० पिवळे चिकट सापळे लावा.", "hi": "प्रति एकड़ 30 पीले ट्रैप।"}
    return {
        "sources": {
            "S1": {"title": "NHB Citrus: Pests", "url": NHB_URL, "publisher": "NHB"},
            "AW": {"title": "Agrowon article", "url": PAPER_URL, "publisher": "Agrowon"},
        },
        "sections": [
            {
                "key": "psylla",
                "labels": {"en": "Psylla", "mr": "सायला", "hi": "सिल्ला"},
                "items": [
                    {"id": 1, "labels": point, "source_keys": ["S1"]},
                    {
                        "id": 2,
                        "labels": {"en": "Spray 7 times (newspaper).", "mr": "७ वेळा", "hi": "7"},
                        "source_keys": ["AW"],
                    },
                    {
                        "id": 3,
                        "labels": {"en": "Use 99 traps.", "mr": "९९ सापळे", "hi": "99"},
                        "source_keys": ["S1"],
                    },
                ],
            },
            {
                "key": "bahar_irrigation",
                "labels": {"en": "Bahar", "mr": "बहार", "hi": "बहार"},
                "items": [
                    {
                        "id": 4,
                        "labels": {
                            "en": "Withhold water for 40 to 60 days.",
                            "mr": "४० ते ६० दिवस पाणी तोडा.",
                            "hi": "40 से 60 दिन पानी रोकें।",
                        },
                        "source_keys": ["S1"],
                    }
                ],
            },
        ],
    }


def article(number: str = "३०", *, en_number: str = "30") -> dict[str, Any]:
    def lang(title: str, n: str) -> dict[str, Any]:
        return {
            "title": title,
            "standfirst": "नवतीवर लक्ष ठेवा.",
            "sections": [
                {"heading": "काय दिसते", "body": "नवतीवर पिल्ले दिसतात."},
                {"heading": "काय करावे", "body": f"एकरी {n} पिवळे चिकट सापळे लावा."},
                {"heading": "केव्हा बदलावे", "body": "दर महिन्याला सापळे बदला."},
                {"heading": "KVK ला केव्हा विचारावे", "body": "खात्री नसेल तर विचारा."},
            ],
        }

    return {
        "relevant": True,
        "lang": {
            "mr": lang("सायला: नवतीवर लक्ष", number),
            "hi": lang("सिल्ला: नई फुटान", en_number),
            "en": lang("Psylla: watch the new flush", en_number),
        },
    }


def answer(payload: dict[str, Any]) -> httpx.Response:
    content = [{"type": "text", "text": json.dumps(payload, ensure_ascii=False)}]
    return httpx.Response(200, json={"content": content, "stop_reason": "end_turn"})


class Model:
    """The Messages API fake: answers in order and records each request body."""

    def __init__(self, *responses: httpx.Response) -> None:
        self.responses = list(responses)
        self.bodies: list[dict[str, Any]] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.bodies.append(json.loads(request.content))
        return self.responses.pop(0)

    def writer(self) -> AnthropicFeedAi:
        http = httpx.AsyncClient(transport=httpx.MockTransport(self))
        return AnthropicFeedAi(http, settings())


class Sources:
    """The open sources: one NHB page; every request is recorded."""

    def __init__(self, page: str = NHB_PAGE) -> None:
        self.page = page
        self.urls: list[str] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.urls.append(str(request.url))
        if str(request.url) == NHB_URL:
            return httpx.Response(200, text=self.page, headers={"content-type": "text/html"})
        return httpx.Response(404)

    def fetch(self) -> Callable[[str], Any]:
        return cached_fetcher(httpx.AsyncClient(transport=httpx.MockTransport(self)))


def settings(**extra: Any) -> Settings:
    return Settings(environment="test", feed_ai_api_key="sk-test-not-real", **extra)


def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def alert(session: AsyncSession, rule: str, first_day: date) -> None:
    session.add(
        PlotRiskAlert(
            owner_id=uuid.uuid4(), plot_id=uuid.uuid4(), rule_key=rule, first_day=first_day, value=1
        )
    )
    await session.flush()


async def run(
    session: AsyncSession,
    model: Model | None,
    sources: Sources,
    *,
    now: datetime = NOW,
    data: dict[str, Any] | None = None,
    config: Settings | None = None,
) -> KnowledgeRun:
    return await run_knowledge(
        session,
        model.writer() if model else None,
        config or settings(),
        now,
        fetch=sources.fetch(),
        cards=data or cards(),
        # No stage windows unless a test asks: the risk and scheme tests stay one topic each.
        seeds=StageTemplateSeeds(sources={}, templates=[]),
    )


async def knowledge_items(session: AsyncSession) -> list[FeedItem]:
    return list(
        await session.scalars(
            select(FeedItem).where(FeedItem.type == "knowledge").order_by(FeedItem.created_at)
        )
    )


# Triggers -------------------------------------------------------------------------------------


async def test_risk_trigger_needs_an_active_alert_with_a_card(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY - timedelta(days=2))
        await alert(session, "psylla_degree_days", TODAY + timedelta(days=3))
        await alert(session, "hail_thunderstorm", TODAY)  # claim kit, no card: no article
        await alert(session, "heat_fruit_drop", TODAY - timedelta(days=15))  # no longer active
        topics = await risk_topics(session, TODAY)
    assert [t.key for t in topics] == ["risk:psylla_degree_days"]
    (psylla,) = topics
    assert psylla.sections == ("psylla",)
    assert psylla.window_end == TODAY + timedelta(days=3 + 14)
    assert "psylla" in psylla.about


def test_stage_trigger_fires_only_for_a_window_starting_within_14_days() -> None:
    # Santra Ambia stress starts 8-14 December (stage templates, season_start -24..-18).
    soon = {t.key for t in stage_topics(date(2026, 11, 25))}
    assert "stage:santra:ambia:stress_start" in soon
    assert {t.key for t in stage_topics(date(2026, 11, 22))} == {
        "stage:mosambi:ambia:irrigation_restart"
    }
    assert "stage:santra:ambia:stress_start" not in {t.key for t in stage_topics(date(2026, 12, 9))}
    (stress,) = [t for t in stage_topics(date(2026, 11, 25)) if t.key.endswith("stress_start")]
    assert stress.sections == ("bahar_irrigation",)
    assert stress.window_end == date(2026, 12, 14)
    assert "Water stress starts" in stress.about


async def official_item(
    session: AsyncSession,
    *,
    published_at: datetime = NOW - timedelta(days=3),
    type_: str = "scheme",
    trust: str = "official",
    deadline: date | None = date(2026, 12, 31),
    text: str = "Orange orchard scheme: ₹6,000 per hectare. Apply on the MahaDBT portal.",
) -> FeedItem:
    source = await session.scalar(select(FeedSource).where(FeedSource.key == "mahadbt"))
    if source is None:
        source = FeedSource(
            id=uuid.uuid4(),
            key="mahadbt",
            name="MahaDBT",
            url="https://mahadbt.maharashtra.gov.in",
            tier="official",
            fetch_method="manual",
        )
        session.add(source)
    item = FeedItem(
        id=uuid.uuid4(),
        type=type_,
        source_id=source.id,
        external_id=uuid.uuid4().hex,
        published_at=published_at,
        url="https://mahadbt.maharashtra.gov.in/scheme.pdf",
        extracted_text=text,
        raw_hash="a" * 64,
        status="published",
        trust_level=trust,
        deadline=deadline,
        check_issues=[],
    )
    session.add(item)
    session.add(
        FeedItemI18n(
            id=uuid.uuid4(), item_id=item.id, lang="en", title="Orange orchard scheme", summary=""
        )
    )
    await session.flush()
    return item


async def test_scheme_trigger_takes_new_open_official_items_only(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        new = await official_item(session)
        await official_item(session, published_at=NOW - timedelta(days=40))  # too old
        await official_item(session, deadline=TODAY - timedelta(days=1))  # closed
        await official_item(session, type_="news", trust="news")  # not official
        topics = await scheme_topics(session, NOW)
    assert [t.item_id for t in topics] == [new.id]
    assert topics[0].window_end == date(2026, 12, 31)


# Writing, checks, publish ---------------------------------------------------------------------


async def test_risk_article_is_written_from_checked_cards_and_published(
    engine: AsyncEngine,
) -> None:
    sources, model = Sources(), Model(answer(article()))
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        result = await run(session, model, sources, data=cards())
        await session.commit()
        assert result.topics == ["risk:psylla_degree_days=published"]
        (item,) = [i for i in await knowledge_items(session) if i.status == "published"]
        assert (item.type, item.trust_level, item.url) == ("knowledge", "official", NHB_URL)
        assert item.thread_id is None  # never threaded
        texts = {
            r.lang: r
            for r in await session.scalars(
                select(FeedItemI18n).where(FeedItemI18n.item_id == item.id)
            )
        }
        assert set(texts) == {"mr", "hi", "en"}
        saved = texts["mr"].article
        assert saved is not None
        assert saved["sources"] == [{"title": "NHB Citrus: Pests", "url": NHB_URL}]
        assert saved["card_section"] == "psylla"
        assert len(saved["sections"]) == 4
        (decision,) = await session.scalars(
            select(FeedKnowledgeRun).where(FeedKnowledgeRun.topic_key == "risk:psylla_degree_days")
        )
        assert (decision.result, decision.item_id) == ("published", item.id)
    # The newspaper is never read; the NHB page is read once per run (cached).
    assert PAPER_URL not in sources.urls
    assert sources.urls.count(NHB_URL) == 1
    body = model.bodies[0]
    assert body["model"] == "claude-sonnet-5-5"
    assert body["output_config"]["format"]["schema"] == KNOWLEDGE_SCHEMA
    assert body["fallbacks"] == "default"
    assert "no newspaper" in body["system"]
    content = body["messages"][0]["content"]
    assert "30 per acre" in content  # the checked point and its source passage
    assert "Spray 7 times" not in content  # cites a newspaper: left out
    assert "99 traps" not in content  # its number is not in the cited source: left out
    assert "<topic>" in content


async def test_a_number_not_in_the_input_holds_the_article(engine: AsyncEngine) -> None:
    model = Model(answer(article("४५", en_number="45")))
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        result = await run(session, model, Sources())
        (item,) = await knowledge_items(session)
        assert result.held == 1
        assert item.status == "held"
        assert any("'45' is not in the source" in i["text"] for i in item.check_issues)
        kinds = set(
            await session.scalars(
                select(FeedReviewEvent.kind).where(FeedReviewEvent.item_id == item.id)
            )
        )
        assert {"created", "output_check_failed", "knowledge_article"} <= kinds
        # The held re-check reads the stored input (no model call): still held.
        again = await run(session, None, Sources())
        assert (again.recheck_published, item.status) == (0, "held")
        # Once the stored input vouches for the number, the re-check publishes it.
        item.extracted_text = f"{item.extracted_text}\n45 per acre"
        again = await run(session, None, Sources())
        assert (again.recheck_published, item.status) == (1, "published")


def test_a_product_name_not_in_the_input_is_an_issue() -> None:
    raw = article()
    raw["lang"]["en"]["sections"][1]["body"] = "Spray imidacloprid and hang 30 traps."
    problems = check_knowledge("hang 30 traps", parse_knowledge(raw))
    assert "en: product 'imidacloprid' is not in the cards or the source" in problems


async def test_dedupe_same_topic_not_rewritten_until_the_input_changes(
    engine: AsyncEngine,
) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        first = Model(answer(article()))
        await run(session, first, Sources())
        # Same day again: idempotent, no model call.
        again = Model()
        result = await run(session, again, Sources())
        assert "risk:psylla_degree_days=deduped" in result.topics
        assert again.bodies == []
        # The alert keeps coming (daily runs): its window is extended, so even after 30 days
        # nothing is written again while it lasts.
        for days in (10, 20, DEDUPE_DAYS + 3):
            later = NOW + timedelta(days=days)
            await alert(session, "psylla_degree_days", later.date())
            result = await run(session, Model(), Sources(), now=later)
            assert "risk:psylla_degree_days=deduped" in result.topics
        (decision,) = await session.scalars(
            select(FeedKnowledgeRun).where(FeedKnowledgeRun.result == "published")
        )
        assert decision.window_end == later.date() + timedelta(days=14)
        # The card's checked text changed: a new article, the old one leaves the feed.
        changed = cards("Hang yellow sticky traps, 30 per acre, from the first week of June.")
        result = await run(session, Model(answer(article())), Sources(), now=later, data=changed)
        assert "risk:psylla_degree_days=published" in result.topics
        old, new = [i for i in await knowledge_items(session) if i.url == NHB_URL][:2]
        assert (old.status, new.status) == ("draft", "published")


async def test_a_topic_is_written_again_after_30_days_once_its_window_ended(
    engine: AsyncEngine,
) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        await run(session, Model(answer(article())), Sources())
        later = NOW + timedelta(days=DEDUPE_DAYS + 1)
        await alert(session, "psylla_degree_days", later.date())
        # The first article's window (its alert day + 14) ended long ago and 30 days passed.
        (decision,) = await session.scalars(select(FeedKnowledgeRun))
        assert decision.window_end == TODAY + timedelta(days=14)
        result = await run(session, Model(answer(article())), Sources(), now=later)
        assert "risk:psylla_degree_days=published" in result.topics


async def test_model_error_and_not_relevant_write_nothing(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        result = await run(session, Model(httpx.Response(529, json={})), Sources())
        assert result.retry >= 1
        assert await knowledge_items(session) == []
        # A retry does not count for the dedupe: the next run asks again.
        result = await run(session, Model(answer({"relevant": False, "lang": None})), Sources())
        assert "risk:psylla_degree_days=not_relevant" in result.topics
        assert await knowledge_items(session) == []


async def test_unreadable_sources_mean_no_input_and_no_model_call(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        model = Model()
        result = await run(session, model, Sources(page=""))
        assert "risk:psylla_degree_days=no_input" in result.topics
        assert model.bodies == []


async def test_scheme_explainer_uses_only_the_items_own_text(engine: AsyncEngine) -> None:
    raw = {
        "relevant": True,
        "lang": {
            lang: {
                "title": "फळबाग योजना: कोण अर्ज करू शकतो",
                "standfirst": "हेक्टरी ₹६,००० अनुदान.",
                "sections": [
                    {"heading": "योजना काय", "body": "हेक्टरी ₹6,000 अनुदान."},
                    {"heading": "कोण पात्र असू शकतो", "body": "संत्रा उत्पादक."},
                    {"heading": "अर्ज कसा", "body": "MahaDBT पोर्टलवर."},
                    {"heading": "अधिक माहिती", "body": "अधिकृत GR पाहा."},
                ],
            }
            for lang in ("mr", "hi", "en")
        },
    }
    model = Model(answer(raw))
    sources = Sources()
    async with maker(engine)() as session:
        scheme = await official_item(session)
        result = await run(session, model, sources)
        assert f"scheme:{scheme.id}=published" in result.topics
        (item,) = await knowledge_items(session)
        assert (item.trust_level, item.url) == ("official", scheme.url)
        row = await session.scalar(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
        assert row is not None
        assert row.article is not None
        assert row.article["sources"] == [{"title": "Orange orchard scheme", "url": scheme.url}]
        assert row.article["card_section"] is None
    assert sources.urls == []  # nothing fetched: the item's own stored text
    assert "₹6,000 per hectare" in model.bodies[0]["messages"][0]["content"]


async def test_kill_switch_stops_everything(engine: AsyncEngine) -> None:
    model, sources = Model(), Sources()
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        result = await run(session, model, sources, config=settings(cron_feed_knowledge=False))
    assert result.skipped_reason == "CRON_FEED_KNOWLEDGE is off"
    assert (model.bodies, sources.urls, result.topics) == ([], [], [])


async def test_without_a_key_nothing_is_written(engine: AsyncEngine) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", TODAY)
        result = await run(session, None, Sources())
    assert result.skipped_reason == "FEED_AI_API_KEY is not set"


# Feed API -------------------------------------------------------------------------------------


async def test_feed_lists_knowledge_under_its_own_filter(
    api: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    async with maker(engine)() as session:
        await alert(session, "psylla_degree_days", datetime.now(UTC).date())
        await run(session, Model(answer(article())), Sources(), now=datetime.now(UTC))
        await session.commit()
    body = (await api.get("/v1/feed?lang=mr&type=knowledge", headers=auth_headers)).json()
    (item,) = body["items"]
    assert (item["type"], item["title"]) == ("knowledge", "सायला: नवतीवर लक्ष")
    assert item["article"]["sources"][0]["url"] == NHB_URL
    assert item["article"]["card_section"] == "psylla"
    assert item["thread_id"] is None
    for other in ("official", "news"):
        listed = (await api.get(f"/v1/feed?lang=mr&type={other}", headers=auth_headers)).json()
        assert all(i["type"] != "knowledge" for i in listed["items"])


def test_bundled_cards_are_the_apps_own_file() -> None:
    app = json.loads((ROOT / "app/assets/config/practice_cards.json").read_text("utf-8"))
    assert practice_cards() == app, "copy app/assets/config/practice_cards.json to kb/seed_data"
