"""Owner 2026-11-12 (OPEN_QUESTIONS Q145): the seed records the owner's approval of the
official portals and the agriculture outlets, and a deploy carries it onto existing rows that
are still `unknown`, idempotently, never over an admin's own decision."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.feed.models import FeedSource
from bagmitra_api.feed.seed import seed_feed_sources, source_seeds

APPROVED = (
    "mh_gr_portal",
    "mahadbt",
    "pm_kisan",
    "pmfby",
    "pib_agriculture_news",
    "mh_agri_commissionerate",
)
NOTE = "owner approval 2026-11-12 (any available source); robots.txt checked"


def seeds() -> dict[str, dict[str, object]]:
    return {s["key"]: s for s in source_seeds()}


def test_owner_approved_sources_are_seeded_with_the_note() -> None:
    by_key = seeds()
    for key in APPROVED:
        seed = by_key[key]
        assert seed["terms_status"] in ("allowed", "disallowed"), key
        assert str(seed["notes"]).startswith(NOTE), key
    news = [s for s in by_key.values() if s["tier"] == "news" and s["key"] != "mahasamvad_news"]
    outlets = [s for s in news if s["key"] != "pib_agriculture_news"]
    assert len(outlets) >= 3, "a few non-government agriculture outlets"
    for seed in outlets:
        assert str(seed["notes"]).startswith(NOTE), seed["key"]
        assert seed["fetch_method"] == "rss"
        assert not str(seed["url"]).endswith((".gov.in", ".nic.in"))


def test_a_source_whose_robots_disallow_us_stays_disallowed() -> None:
    disallowed = [s for s in source_seeds() if s.get("terms_status") == "disallowed"]
    for seed in disallowed:
        assert "robots.txt" in str(seed["notes"])
        assert "disallow" in str(seed["notes"]).lower()


async def test_deploy_updates_unknown_rows_only_and_is_idempotent(engine: AsyncEngine) -> None:
    by_key = seeds()
    async with async_sessionmaker(engine)() as session:
        # An older database: every row as migration 0019 seeded it (terms unknown, home URL).
        for key in ("mh_gr_portal", "mahadbt", "pmfby", "pib_agriculture_news"):
            session.add(
                FeedSource(
                    id=uuid.uuid4(),
                    key=key,
                    name="old name",
                    url="https://old.example",
                    tier=str(by_key[key]["tier"]),
                    fetch_method="manual",
                    terms_status="unknown",
                    last_error="not fetched: terms_status is unknown",
                )
            )
        # An admin's explicit decisions win over the seed.
        await session.flush()
        rows = {s.key: s for s in await session.scalars(select(FeedSource))}
        rows["mahadbt"].terms_status = "disallowed"
        rows["mahadbt"].notes = "admin: terms forbid automated use"
        rows["pmfby"].terms_status = "allowed"
        rows["pmfby"].notes = "admin note kept"
        await session.commit()

        added = await seed_feed_sources(session)
        await session.commit()
        rows = {s.key: s for s in await session.scalars(select(FeedSource))}
        gr = rows["mh_gr_portal"]
        assert gr.terms_status == by_key["mh_gr_portal"]["terms_status"]
        assert gr.notes == by_key["mh_gr_portal"]["notes"]
        assert gr.url == by_key["mh_gr_portal"]["url"]
        assert gr.fetch_method == by_key["mh_gr_portal"]["fetch_method"]
        assert gr.last_error is None
        pib = rows["pib_agriculture_news"]
        assert (pib.terms_status, pib.url) == (
            by_key["pib_agriculture_news"]["terms_status"],
            by_key["pib_agriculture_news"]["url"],
        )
        assert (rows["mahadbt"].terms_status, rows["mahadbt"].notes) == (
            "disallowed",
            "admin: terms forbid automated use",
        )
        assert (rows["pmfby"].terms_status, rows["pmfby"].notes) == ("allowed", "admin note kept")
        assert rows["pmfby"].url == "https://old.example"
        assert added == len(by_key) - 4
        assert set(rows) == set(by_key)

        snapshot = {k: (r.terms_status, r.notes, r.url, r.fetch_method) for k, r in rows.items()}
        assert await seed_feed_sources(session) == 0
        await session.commit()
        again = {
            s.key: (s.terms_status, s.notes, s.url, s.fetch_method)
            for s in await session.scalars(select(FeedSource))
        }
        assert again == snapshot, "a second deploy changes nothing"
