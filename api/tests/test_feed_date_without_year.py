"""VPS 2026-11-13: 135 held reasons were `key_dates[N]: date '…' is not in the source`. News
pages state a date without its year ("१२ नोव्हेंबरला", "12 नोव्हेंबर रोजी", "Nov 12") while
the writer must give key_dates as YYYY-MM-DD, so the year it adds was never found. Rule
(strict): a full date is vouched for when the source states the same day and month without a
year AND the year is the item's published year. Never another day, month or year; a source
that states the year is still matched exactly."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.feed.article import check_articles, parse_articles
from bagmitra_api.feed.models import FeedItemI18n
from bagmitra_api.feed.news_articles import recheck_held_articles, write_news_articles
from bagmitra_api.feed.official_items import recheck_held_official, write_official_items
from bagmitra_api.feed.output_check import check_output, day_months
from tests.test_feed_article import SOURCE, URL, payload
from tests.test_feed_news import HOST, Server, adapter, news_source
from tests.test_feed_news_articles import NOW, Writer, headline, settings, sound
from tests.test_feed_portals import GR_PDF, FakeAi, Site, listed
from tests.test_feed_portals import adapter as portal_adapter

KEY_DATE = "2026-11-12 Meeting of the committee"


def _dated(source: str, year: int | None = 2026, text: str = KEY_DATE) -> list[tuple[str, str]]:
    return [(m.kind, m.text) for m in check_output(source, {"key_dates[0]": text}, year=year)]


@pytest.mark.parametrize(
    "source",
    [
        "समितीची बैठक १२ नोव्हेंबरला झाली.",  # Devanagari digits, ला written onto the month
        "समितीची बैठक 12 नोव्हेंबर रोजी झाली.",
        "दि. १२ नोव्हेंबरपासून अर्ज सुरू.",
        "अर्ज १० ते १२ नोव्हेंबरपर्यंत.",
        "समिति की बैठक 12 नवंबर को हुई।",
        "The committee met on Nov 12.",
        "The committee met on 12th November, said the minister.",
        "The committee met on November 12 in Pune.",
    ],
)
def test_a_day_and_month_without_a_year_vouches_for_the_items_year(source: str) -> None:
    assert _dated(source) == []


def test_without_the_items_year_nothing_is_inferred() -> None:
    assert _dated("समितीची बैठक १२ नोव्हेंबरला झाली.", year=None) == [("date", "2026-11-12")]


@pytest.mark.parametrize(
    ("year", "text"),
    [
        (2026, "2026-11-13 Meeting"),  # another day
        (2026, "2026-10-12 Meeting"),  # another month
        (2026, "2027-11-12 Meeting"),  # another year than the item's
        (2025, KEY_DATE),  # the item is from 2025
    ],
)
def test_another_day_month_or_year_is_still_not_in_the_source(year: int, text: str) -> None:
    found = _dated("समितीची बैठक १२ नोव्हेंबरला झाली.", year=year, text=text)
    assert [kind for kind, _ in found] == ["date"]


def test_a_year_the_source_states_is_matched_exactly() -> None:
    """ "१२ नोव्हेंबर २०२५" is a full date: it vouches for 2025-11-12 only, even for an item
    published in 2026."""
    source = "समितीची बैठक १२ नोव्हेंबर २०२५ रोजी झाली."
    assert _dated(source, text="2026-11-12 Meeting") == [("date", "2026-11-12")]
    assert _dated(source, text="2025-11-12 Meeting") == []
    assert day_months(source) == []


@pytest.mark.parametrize(
    "source",
    [
        "पिकाचे 12 नोव्हेंबरच्या आधी",  # another ending than ला / रोजी / पासून / पर्यंत
        "12 में से 5 जिलों में",  # Hindi "in", not May
        "farmers may 12 days wait",  # English modal verb
        "1.12 November",  # part of a number
    ],
)
def test_other_words_are_no_day_and_month(source: str) -> None:
    assert [(m, d) for _, m, d in day_months(source) if (m, d) in ((11, 12), (5, 12))] == []


def test_month_only_and_numbers_are_unchanged() -> None:
    """The year rule completes full dates only: a month-year and plain numbers are checked as
    before."""
    assert _dated("बैठक १२ नोव्हेंबरला", text="Meeting in December 2026") == [("date", "december 2026")]
    assert _dated("बैठक १२ नोव्हेंबरला", text="Meeting 2026-11-12, 14 members") == [("number", "14")]


def _with_key_date(url: str = URL) -> dict[str, Any]:
    data = payload()
    for lang in ("mr", "hi", "en"):
        data["lang"][lang]["key_dates"].append({"date": "2026-11-12", "label": "Meeting"})
        data["lang"][lang]["sources"] = [{"title": "Source", "url": url}]
    return data


def test_check_articles_uses_the_published_year() -> None:
    source = f"{SOURCE} समितीची बैठक १२ नोव्हेंबरला झाली."
    result = parse_articles(_with_key_date())
    assert check_articles(source, result, source_url=URL, published=date(2026, 11, 13)) == []
    held = check_articles(source, result, source_url=URL, published=date(2025, 11, 13))
    assert any("key_dates[1]: date '2026-11-12'" in p for p in held)
    assert any("key_dates[1]" in p for p in check_articles(source, result, source_url=URL))


# --- the published date reaches the check on every path ---------------------------------------


def _page(extra: str, path: str = "/a1") -> Server:
    body = f"<html><body><article><p>{SOURCE} {extra}</p></article></body></html>"
    return Server({"/robots.txt": httpx.Response(404), path: httpx.Response(200, text=body)})


async def test_news_write_and_recheck_use_the_items_year(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        src = await news_source(session)
        item = await headline(session, src, "/a1")
        old = await headline(session, src, "/a2")
        old.published_at = NOW - timedelta(days=365)  # a 2025 item
        data = sound(f"{HOST}/a1")
        for lang in ("mr", "hi", "en"):
            data["lang"][lang]["key_dates"].append({"date": "2026-11-12", "label": "Meeting"})
        page = Server(
            {
                "/robots.txt": httpx.Response(404),
                "/a1": httpx.Response(200, text=f"<p>{SOURCE} बैठक १२ नोव्हेंबरला झाली.</p>"),
                "/a2": httpx.Response(200, text=f"<p>{SOURCE} बैठक १२ नोव्हेंबरला झाली.</p>"),
            }
        )
        await write_news_articles(session, adapter(page), Writer(data), settings(), NOW)
        assert item.status == "published", item.check_issues
        assert old.status == "held"
        assert any("2026-11-12" in i["text"] for i in old.check_issues)

        # Held re-check: a page that did not state the day held it; read again, it does.
        late = await headline(session, src, "/a3")
        await write_news_articles(session, adapter(_page("", "/a3")), Writer(data), settings(), NOW)
        assert late.status == "held"
        run = await recheck_held_articles(
            session, adapter(_page("बैठक 12 नोव्हेंबर रोजी झाली.", "/a3")), settings()
        )
        assert late.status == "published", late.check_issues
        assert old.status == "held"  # its year is 2025: still not in the source
        assert run.published == 1


async def test_official_write_and_recheck_use_the_items_year(engine: AsyncEngine) -> None:
    now = datetime(2026, 11, 13, 6, tzinfo=UTC)
    article = _with_key_date()
    doc = f"<html><body><p>{SOURCE} बैठक १२ नोव्हेंबरला झाली.</p></body></html>"
    site = Site({GR_PDF: httpx.Response(200, text=doc, headers={"content-type": "text/html"})})
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        item = await listed(session, now)
        ai = FakeAi(kind="gr", article=article)
        await write_official_items(session, portal_adapter(site), ai, settings(), now)
        assert item.status == "published", item.check_issues

        # The same listing, as if held by the old check: the re-check passes it.
        item.status = "held"
        item.check_issues = [{"kind": "article", "text": "old check", "where": ""}]
        await session.flush()
        run = await recheck_held_official(session, settings())
        assert (run.published, item.status) == (1, "published")

        # From another year the same stored text does not vouch for 2026-11-12.
        item.status, item.published_at = "held", now - timedelta(days=365)
        await session.flush()
        run = await recheck_held_official(session, settings())
        assert (run.held, item.status) == (1, "held")
        assert any("2026-11-12" in i["text"] for i in item.check_issues)
        rows = await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
        assert all(r.article for r in rows)
