"""Knowledge articles, "ज्ञान लेख" (owner 2026-11-11, OPEN_QUESTIONS Q141).

Owner: farmers should become truly knowledgeable; articles come from the situation, with NO
fixed weekly count and NO cap; no newspaper content. A daily job looks for three triggers:
(a) a weather risk alert (`plot_risk_alerts`) of a rule that has a matching practice card is
    active or forecast (first day within the last ALERT_ACTIVE_DAYS or later);
(b) a bahar stage window of the stage templates starts within the next STAGE_LEAD_DAYS;
(c) an official scheme / GR item was published in the feed within SCHEME_LOOKBACK_DAYS.
For (a) and (b) the input is ONLY the checked points of the matching practice-card sections
(`kb/seed_data/practice_cards.json`, a copy of the app's asset) plus passages of the sources
those points cite, fetched as the card check does (`kb.card_check.fetch_text`, `passages_for`).
A point that cites a newspaper, whose sources cannot be read, or whose numbers are not in its
cited text is left out. For (c) the input is the item's own checked text. The model writes
mr / hi / en (`feed.ai.write_knowledge`); `check_knowledge` checks every number, amount and date
against exactly that input, and an article with any issue is HELD (status `held`, with an
`output_check_failed` event), like held news. Every run first re-checks held articles against
their stored input (no model call). Dedupe (`feed_knowledge_runs`): a topic is not written again
while its window is current or within DEDUPE_DAYS, unless its input changed (the cards' texts /
sources, or the official item's text). Kill switch: CRON_FEED_KNOWLEDGE=off.
    python -m bagmitra_api.feed.knowledge
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import uuid
from collections.abc import Awaitable, Callable, Mapping, Sequence
from dataclasses import asdict, dataclass, field
from datetime import UTC, date, datetime, timedelta
from functools import cache
from importlib import resources
from typing import Any
from urllib.parse import urlsplit
from zoneinfo import ZoneInfo

import httpx
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.bahar.seed import StageTemplateSeeds, TemplateSeed, stage_template_seeds
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import PlotRiskAlert
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.ai import AiUnavailableError, AnthropicFeedAi, KnowledgeWriter
from bagmitra_api.feed.knowledge_article import (
    KnowledgeSet,
    check_knowledge,
    from_saved,
)
from bagmitra_api.feed.models import (
    FeedItem,
    FeedItemI18n,
    FeedKnowledgeRun,
    FeedReviewEvent,
    FeedSource,
)
from bagmitra_api.feed.seed import seed_feed_sources
from bagmitra_api.feed.service import source_text
from bagmitra_api.kb.card_check import Point, fetch_text, iter_points, number_issues, passages_for
from bagmitra_api.risk.engine import RiskRule, load_rules

INDIA = ZoneInfo("Asia/Kolkata")
SOURCE_KEY = "bagmitra_knowledge"
ATTEMPT = "knowledge_article"
RECHECK = "knowledge_recheck"
# Defaults (Q141; owner may change).
# An alert whose first day is at most this old still counts as active. Degree-day alerts start
# in the weather pull's past days (WEATHER_PAST_DAYS, 7), so 14 keeps a lasting alert active.
ALERT_ACTIVE_DAYS = 14
RISK_WINDOW_DAYS = 14  # a risk topic stays current this long after its latest alert day
STAGE_LEAD_DAYS = 14  # a stage window starting within this many days triggers its article
DEDUPE_DAYS = 30
SCHEME_LOOKBACK_DAYS = 30
SCHEME_TYPES = ("scheme", "gr")
PASSAGE_CHARS = 8000  # per cited source and topic
# Risk rule -> practice-card sections. Rules without a card (storms -> claim kit, cold wave)
# write nothing.
RISK_SECTIONS: dict[str, tuple[str, ...]] = {
    "heat_fruit_drop": ("heat_drop",),
    "psylla_degree_days": ("psylla",),
    "high_humidity": ("powdery_mildew", "anthracnose"),
}
# Bahar stage -> practice-card sections.
STAGE_SECTIONS: dict[str, tuple[str, ...]] = {
    "stress_start": ("bahar_irrigation",),
    "irrigation_restart": ("bahar_irrigation", "nutrition"),
    "flowering": ("fruit_drop", "thrips"),
    "fruit_set": ("fruit_drop", "nutrition"),
    "harvest": ("harvest",),
}
CROP_NAMES = {"santra": "Nagpur mandarin (santra)", "mosambi": "sweet orange (mosambi)"}
# Publishers whose content may not be used (owner 2026-11-11: no newspaper, copyright).
NEWSPAPER_PUBLISHERS = frozenset({"Agrowon"})
# A knowledge article counts as official when every source it cites is on these hosts.
OFFICIAL_SUFFIXES = (".gov.in", ".nic.in", ".ac.in")
# Run results that keep a topic from being written again (retry / no_input do not).
COUNTED = ("published", "held", "review", "not_relevant")

Fetcher = Callable[[str], Awaitable[tuple[str, str | None]]]


@dataclass(frozen=True, slots=True)
class Topic:
    key: str
    trigger: str  # risk | stage | scheme
    about: str  # what the article is for, given to the model as <topic>
    window_end: date | None
    sections: tuple[str, ...] = ()
    item_id: uuid.UUID | None = None


@dataclass(frozen=True, slots=True)
class Input:
    text: str  # exactly what the model reads; the number check uses the same text
    sources: list[tuple[str, str]]
    trust: str
    url: str
    card_section: str | None


@dataclass(slots=True)
class KnowledgeRun:
    topics: list[str] = field(default_factory=list)
    published: int = 0
    held: int = 0
    review: int = 0
    deduped: int = 0
    not_relevant: int = 0
    no_input: int = 0
    retry: int = 0
    recheck_published: int = 0
    skipped_reason: str | None = None


@cache
def practice_cards() -> dict[str, Any]:
    text = resources.files("bagmitra_api.kb.seed_data").joinpath("practice_cards.json")
    cards: dict[str, Any] = json.loads(text.read_text("utf-8"))
    return cards


def _utc(value: datetime) -> datetime:
    return value if value.tzinfo else value.replace(tzinfo=UTC)


# Triggers -------------------------------------------------------------------------------------


async def risk_topics(
    session: AsyncSession, today: date, rules: Sequence[RiskRule] | None = None
) -> list[Topic]:
    """(a) Rules with a matching card whose alert is active or forecast for any plot."""
    by_key = {r.key: r for r in (rules if rules is not None else load_rules())}
    rows = await session.execute(
        select(PlotRiskAlert.rule_key, func.max(PlotRiskAlert.first_day))
        .where(
            PlotRiskAlert.rule_key.in_(list(RISK_SECTIONS)),
            PlotRiskAlert.first_day >= today - timedelta(days=ALERT_ACTIVE_DAYS),
        )
        .group_by(PlotRiskAlert.rule_key)
        .order_by(PlotRiskAlert.rule_key)
    )
    out = []
    for key, last_day in rows.tuples():
        rule = by_key.get(key)
        if rule is None:
            continue
        out.append(
            Topic(
                key=f"risk:{key}",
                trigger="risk",
                about=(
                    "A weather risk alert is active or forecast in the farmers' area: "
                    f"{rule.labels['en']} Explain this problem and what farmers can check "
                    "and do, from the cards."
                ),
                window_end=last_day + timedelta(days=RISK_WINDOW_DAYS),
                sections=RISK_SECTIONS[key],
            )
        )
    return out


def stage_windows(
    seeds: StageTemplateSeeds, season_year: int
) -> list[tuple[str, str, str, date, date]]:
    """(crop, bahar, stage key, first start, last end) of every stage in one season year:
    offsets count from 1 January of the season year, or from an earlier stage's window."""
    out: list[tuple[str, str, str, date, date]] = []
    jan1 = date(season_year, 1, 1)
    for t in seeds.templates:
        windows: dict[str, tuple[date, date]] = {}
        for s in t.stages:
            base = (jan1, jan1) if s.anchor == "season_start" else windows[s.anchor]
            windows[s.key] = (
                base[0] + timedelta(days=s.offset_days_min),
                base[1] + timedelta(days=s.offset_days_max),
            )
            out.append((t.crop, t.bahar, s.key, *windows[s.key]))
    return out


def stage_topics(today: date, seeds: StageTemplateSeeds | None = None) -> list[Topic]:
    """(b) Stage windows (with a matching card) that start within the next STAGE_LEAD_DAYS."""
    data = seeds or stage_template_seeds()
    labels: dict[tuple[str, str], TemplateSeed] = {(t.crop, t.bahar): t for t in data.templates}
    found: dict[str, Topic] = {}
    for year in (today.year - 1, today.year, today.year + 1, today.year + 2):
        for crop, bahar, stage, start, end in stage_windows(data, year):
            if stage not in STAGE_SECTIONS or not today <= start <= today + timedelta(
                days=STAGE_LEAD_DAYS
            ):
                continue
            t = labels[(crop, bahar)]
            stage_label = next(s.labels["en"] for s in t.stages if s.key == stage)
            key = f"stage:{crop}:{bahar}:{stage}"
            found.setdefault(
                key,
                Topic(
                    key=key,
                    trigger="stage",
                    about=(
                        f"{t.labels['en']} of {CROP_NAMES[crop]}: the stage '{stage_label}' "
                        "begins in the coming days. Write a preparation article for this stage, "
                        "from the cards."
                    ),
                    window_end=end,
                    sections=STAGE_SECTIONS[stage],
                ),
            )
    return sorted(found.values(), key=lambda t: t.key)


async def scheme_topics(session: AsyncSession, now: datetime) -> list[Topic]:
    """(c) Official scheme / GR items published recently, still open, with stored text."""
    today = now.astimezone(INDIA).date()
    rows = await session.scalars(
        select(FeedItem)
        .where(
            FeedItem.type.in_(SCHEME_TYPES),
            FeedItem.status == "published",
            FeedItem.trust_level == "official",
            FeedItem.extracted_text.is_not(None),
            FeedItem.published_at >= now - timedelta(days=SCHEME_LOOKBACK_DAYS),
        )
        .order_by(FeedItem.published_at)
    )
    out = []
    for item in rows:
        if any(d is not None and d < today for d in (item.deadline, item.valid_to)):
            continue
        out.append(
            Topic(
                key=f"scheme:{item.id}",
                trigger="scheme",
                about=(
                    "A new official government item was published in the feed. Explain to "
                    "farmers what it offers, who may be eligible, which documents are needed "
                    "and how to apply, from this document's own text only."
                ),
                window_end=item.deadline or item.valid_to,
                item_id=item.id,
            )
        )
    return out


# Inputs ---------------------------------------------------------------------------------------


def _sections(cards: Mapping[str, Any], keys: Sequence[str]) -> list[dict[str, Any]]:
    by_key = {s["key"]: s for s in cards.get("sections", [])}
    return [by_key[k] for k in keys if k in by_key]


def _cited(cards: Mapping[str, Any], sections: list[dict[str, Any]]) -> dict[str, Any]:
    sources: Mapping[str, Any] = cards.get("sources", {})
    keys = {k for sec in sections for p in iter_points(sec) for k in p.source_keys}
    return {k: sources[k] for k in sorted(keys) if k in sources}


def _hash(value: object) -> str:
    raw = json.dumps(value, ensure_ascii=False, sort_keys=True, default=str)
    return hashlib.sha256(raw.encode()).hexdigest()


async def input_hash(session: AsyncSession, topic: Topic, cards: Mapping[str, Any]) -> str:
    """What "the source changed" means, without a network call: the cards' checked texts and
    their source list, or the official item's stored text and checked titles."""
    if topic.item_id is not None:
        item = await session.get(FeedItem, topic.item_id)
        rows = await session.scalars(
            select(FeedItemI18n).where(FeedItemI18n.item_id == topic.item_id)
        )
        titles = sorted((r.lang, r.title, r.summary or "") for r in rows)
        return _hash([source_text(item) if item else "", titles])
    sections = _sections(cards, topic.sections)
    return _hash({"sections": sections, "sources": _cited(cards, sections)})


def _official(urls: Sequence[str]) -> bool:
    hosts = [(urlsplit(u).hostname or "").lower() for u in urls]
    return bool(hosts) and all(h.endswith(OFFICIAL_SUFFIXES) for h in hosts)


def _point_line(p: Point) -> str:
    en, mr = p.labels.get("en", ""), p.labels.get("mr", "")
    return f"- {en}" + (f"\n  (मराठी: {mr})" if mr else "")


async def cards_input(
    topic: Topic, cards: Mapping[str, Any], fetch: Fetcher, limit: int
) -> Input | None:
    """The checked points of the topic's card sections and passages of their readable sources;
    None when nothing is left to write from."""
    sections = _sections(cards, topic.sections)
    sources = _cited(cards, sections)
    texts: dict[str, str] = {}
    for key, src in sources.items():
        if src.get("publisher") in NEWSPAPER_PUBLISHERS or not src.get("url"):
            continue
        text, reason = await fetch(str(src["url"]))
        if reason is None:
            texts[key] = text
    kept: dict[str, list[Point]] = {}
    for sec in sections:
        for p in iter_points(sec):
            if any(
                sources.get(k, {}).get("publisher") in NEWSPAPER_PUBLISHERS for k in p.source_keys
            ):
                continue
            cited = "\n".join(texts[k] for k in p.source_keys if k in texts)
            if cited and not number_issues(p, cited):
                kept.setdefault(sec["key"], []).append(p)
    if not kept:
        return None
    used = sorted({k for ps in kept.values() for p in ps for k in p.source_keys if k in texts})
    parts = ["<cards>"]
    for sec in sections:
        if sec["key"] in kept:
            parts.append(f"## {sec['labels']['en']} ({sec['labels'].get('mr', '')})")
            parts += [_point_line(p) for p in kept[sec["key"]]]
    parts.append("</cards>")
    for key in used:
        mine = [p for ps in kept.values() for p in ps if key in p.source_keys]
        title = sources[key].get("title", key)
        passages = passages_for(texts[key], mine, PASSAGE_CHARS)
        parts.append(f'<source key="{key}" title="{title}">\n{passages}\n</source>')
    urls = [str(sources[k]["url"]) for k in used]
    return Input(
        text="\n".join(parts)[:limit],
        sources=[(str(sources[k].get("title", k)), str(sources[k]["url"])) for k in used],
        trust="official" if _official(urls) else "news",
        url=urls[0],
        card_section=next(iter(kept)),
    )


async def scheme_input(session: AsyncSession, topic: Topic, limit: int) -> Input | None:
    item = await session.get(FeedItem, topic.item_id) if topic.item_id else None
    if item is None or not item.extracted_text:
        return None
    rows = {
        r.lang: r
        for r in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
    }
    head = [f"{r.title}\n{r.summary or ''}" for lang in ("mr", "en", "hi") if (r := rows.get(lang))]
    title = next((rows[lang].title for lang in ("mr", "en", "hi") if lang in rows), item.url)
    return Input(
        text="\n".join([*head, source_text(item)])[:limit],
        sources=[(title, item.url)],
        trust=item.trust_level,
        url=item.url,
        card_section=None,
    )


# The run --------------------------------------------------------------------------------------


def _event(item: FeedItem, kind: str, **detail: object) -> FeedReviewEvent:
    return FeedReviewEvent(
        id=uuid.uuid4(), item_id=item.id, actor_id=None, kind=kind, detail=detail
    )


async def _last_run(session: AsyncSession, topic: Topic) -> FeedKnowledgeRun | None:
    run: FeedKnowledgeRun | None = await session.scalar(
        select(FeedKnowledgeRun)
        .where(FeedKnowledgeRun.topic_key == topic.key, FeedKnowledgeRun.result.in_(COUNTED))
        .order_by(FeedKnowledgeRun.created_at.desc())
        .limit(1)
    )
    return run


def _still_current(last: FeedKnowledgeRun, digest: str, now: datetime, today: date) -> bool:
    if last.source_hash != digest:
        return False
    in_window = last.window_end is not None and last.window_end >= today
    return in_window or now - _utc(last.created_at) < timedelta(days=DEDUPE_DAYS)


def _issues(problems: list[str]) -> list[dict[str, str]]:
    return [{"kind": "knowledge", "text": p[:500], "where": ""} for p in problems]


async def _store(  # noqa: PLR0913 - one article with its run context
    session: AsyncSession,
    source: FeedSource,
    topic: Topic,
    found: Input,
    result: KnowledgeSet,
    problems: list[str],
    status: str,
    digest: str,
    now: datetime,
) -> FeedItem:
    item = FeedItem(
        id=uuid.uuid4(),
        type="knowledge",
        source_id=source.id,
        external_id=f"{topic.key}:{digest[:12]}:{now.date().isoformat()}"[:120],
        published_at=now,
        url=found.url,
        raw_hash=hashlib.sha256(found.text.encode()).hexdigest(),
        raw_bytes=len(found.text.encode()),
        extracted_text=found.text,
        status=status,
        trust_level=found.trust,
        check_issues=_issues(problems),
    )
    session.add(item)
    for lang, a in result.articles.items():
        session.add(
            FeedItemI18n(
                id=uuid.uuid4(),
                item_id=item.id,
                lang=lang,
                title=a.title[:500],
                summary=a.standfirst,
                article=a.as_json(found.sources, found.card_section),
            )
        )
    session.add(
        _event(item, "created", via="knowledge_job", topic=topic.key, trigger=topic.trigger)
    )
    if problems:
        session.add(_event(item, "output_check_failed", issues=item.check_issues))
    if status == "published":
        session.add(_event(item, "auto_published"))
    return item


async def _supersede(session: AsyncSession, last: FeedKnowledgeRun | None, new: FeedItem) -> None:
    """The input changed: the older article of the topic leaves the feed."""
    if last is None or last.item_id is None:
        return
    old = await session.get(FeedItem, last.item_id)
    if old is not None and old.status in ("published", "held", "in_review"):
        old.status = "draft"
        session.add(_event(old, "superseded", by=str(new.id)))


async def write_topic(  # noqa: PLR0913 - one topic with the run's tools
    session: AsyncSession,
    topic: Topic,
    writer: KnowledgeWriter,
    settings: Settings,
    now: datetime,
    *,
    source: FeedSource,
    fetch: Fetcher,
    cards: Mapping[str, Any],
) -> str:
    today = now.astimezone(INDIA).date()
    digest = await input_hash(session, topic, cards)
    last = await _last_run(session, topic)
    if last is not None and _still_current(last, digest, now, today):
        if topic.window_end and (last.window_end is None or topic.window_end > last.window_end):
            last.window_end = topic.window_end  # a still active alert keeps its topic current
        return "deduped"

    def record(result: str, item: FeedItem | None = None) -> str:
        session.add(
            FeedKnowledgeRun(
                id=uuid.uuid4(),
                topic_key=topic.key,
                trigger=topic.trigger,
                source_hash=digest,
                window_end=topic.window_end,
                item_id=item.id if item else None,
                result=result,
                created_at=now,
            )
        )
        return result

    limit = settings.feed_ai_max_source_chars
    found = (
        await scheme_input(session, topic, limit)
        if topic.item_id
        else await cards_input(topic, cards, fetch, limit)
    )
    if found is None:
        return record("no_input")
    try:
        result = await writer.write_knowledge(found.text, topic=topic.about)
    except AiUnavailableError:
        return record("retry")
    if not result.relevant:
        return record("not_relevant")
    problems = check_knowledge(found.text, result)
    status = "held" if problems else ("published" if settings.feed_auto_publish else "in_review")
    item = await _store(session, source, topic, found, result, problems, status, digest, now)
    await session.flush()
    await _supersede(session, last, item)
    outcome = {"published": "published", "held": "held", "in_review": "review"}[status]
    session.add(_event(item, ATTEMPT, result=outcome, topic=topic.key))
    return record(outcome, item)


async def recheck_held_knowledge(session: AsyncSession, settings: Settings) -> int:
    """Held articles are checked again against their stored input (no model call, no fetch);
    those that now pass are published. Returns how many were published."""
    published = 0
    held = await session.scalars(
        select(FeedItem).where(FeedItem.type == "knowledge", FeedItem.status == "held")
    )
    for item in list(held):
        rows = await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
        saved = from_saved({r.lang: r.article for r in rows if r.article})
        if saved is None:
            continue
        problems = check_knowledge(item.extracted_text or "", saved)
        item.check_issues = _issues(problems)
        if problems:
            continue
        item.status = "published" if settings.feed_auto_publish else "in_review"
        session.add(_event(item, RECHECK, result=item.status))
        published += item.status == "published"
    await session.flush()
    return published


async def run_knowledge(  # noqa: PLR0913 - the job and its injectable parts
    session: AsyncSession,
    writer: KnowledgeWriter | None,
    settings: Settings,
    now: datetime,
    *,
    fetch: Fetcher,
    cards: Mapping[str, Any] | None = None,
    seeds: StageTemplateSeeds | None = None,
    rules: Sequence[RiskRule] | None = None,
) -> KnowledgeRun:
    run = KnowledgeRun()
    if not settings.cron_feed_knowledge:
        run.skipped_reason = "CRON_FEED_KNOWLEDGE is off"
        return run
    run.recheck_published = await recheck_held_knowledge(session, settings)
    if writer is None:
        run.skipped_reason = "FEED_AI_API_KEY is not set"
        return run
    await seed_feed_sources(session)
    source = await session.scalar(select(FeedSource).where(FeedSource.key == SOURCE_KEY))
    if source is None:  # pragma: no cover - the seed registers it
        run.skipped_reason = f"feed source {SOURCE_KEY} missing"
        return run
    today = now.astimezone(INDIA).date()
    topics = [
        *await risk_topics(session, today, rules),
        *stage_topics(today, seeds),
        *await scheme_topics(session, now),
    ]
    for topic in topics:
        outcome = await write_topic(
            session,
            topic,
            writer,
            settings,
            now,
            source=source,
            fetch=fetch,
            cards=cards if cards is not None else practice_cards(),
        )
        run.topics.append(f"{topic.key}={outcome}")
        setattr(run, outcome, getattr(run, outcome) + 1)
        await session.flush()
    return run


def cached_fetcher(http: httpx.AsyncClient) -> Fetcher:
    """`card_check.fetch_text`, each address read once per run."""
    seen: dict[str, tuple[str, str | None]] = {}

    async def fetch(url: str) -> tuple[str, str | None]:
        if url not in seen:
            seen[url] = await fetch_text(http, url)
        return seen[url]

    return fetch


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with httpx.AsyncClient(follow_redirects=True) as http:
        writer = (
            AnthropicFeedAi(http, settings) if settings.feed_ai_api_key.get_secret_value() else None
        )
        async with get_sessionmaker()() as session:
            run = await run_knowledge(
                session, writer, settings, datetime.now(UTC), fetch=cached_fetcher(http)
            )
            await session.commit()
    print(json.dumps(asdict(run), ensure_ascii=False))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
