"""Market linkage L5: "deal done" and ratings (spec v1.5 §3 step 7, §3A; decisions d, e, j;
Q66, Q67, Q112). Only parties tap and rate; the deal completes on both the grower's and the
trader's tap; ratings are stars per question plus active tag ids, no text, once per rater and
ratee, changeable for 7 days from completion and then locked; profiles show the aggregates."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select

from bagmitra_api.market_link.deals import questions
from bagmitra_api.market_link.models import DealEvent, MarketDeal, RatingTag
from bagmitra_api.weather.service import get_clock
from tests.test_market_interests import Party, ml, party, published, send, sender

__all__ = ["ml", "sender"]

ML = "/v1/market-link"
T0 = datetime(2026, 12, 10, 6, 0, tzinfo=UTC)


class Clock:
    def __init__(self) -> None:
        self.now = T0

    def __call__(self) -> datetime:
        return self.now


@pytest.fixture
def clock(ml: Any) -> Clock:
    c = Clock()
    ml._transport.app.dependency_overrides[get_clock] = lambda: c
    return c


class Deal:
    def __init__(self, deal_id: str, gh: dict[str, str], trader: Party, broker: Party) -> None:
        self.id, self.gh, self.trader, self.broker = deal_id, gh, trader, broker


async def introduced(c: Any) -> Deal:
    """A grower accepted a trader's interest that named a broker."""
    _grower, lot_id, gh = await published(c)
    trader, broker = await party(c), await party(c, "broker", name="Wankhade")
    r = await send(c, lot_id, trader, broker_id=str(broker.profile))
    assert r.status_code == 201, r.text
    r = await c.post(f"{ML}/interests/{r.json()['id']}/accept", headers=gh)
    assert r.status_code == 200, r.text
    return Deal(r.json()["deal_id"], gh, trader, broker)


async def done(c: Any, deal: Deal, h: dict[str, str]) -> httpx.Response:
    r: httpx.Response = await c.post(f"{ML}/deals/{deal.id}/done", headers=h)
    return r


async def tags(c: Any) -> dict[str, list[uuid.UUID]]:
    """Two active tags per question; question -> ids."""
    out: dict[str, list[uuid.UUID]] = {}
    async with c.maker() as s:
        for role_qs in questions().values():
            for q in role_qs:
                for pol in ("positive", "negative"):
                    t = RatingTag(
                        key=f"{q}_{pol}_{uuid.uuid4().hex[:6]}",
                        question_key=q,
                        polarity=pol,
                        label_mr="म",
                        label_hi="ह",
                        label_en="e",
                        status="active",
                    )
                    s.add(t)
                    await s.flush()
                    out.setdefault(q, []).append(t.id)
        await s.commit()
    return out


def answers(role: str, stars: int = 4, ticks: dict[str, list[uuid.UUID]] | None = None) -> Any:
    return {
        "answers": [
            {
                "question_key": q,
                "stars": stars,
                "tag_ids": [str(t) for t in (ticks or {}).get(q, [])],
            }
            for q in questions()[role]
        ]
    }


async def rate(c: Any, deal: Deal, h: dict[str, str], role: str, body: Any) -> httpx.Response:
    r: httpx.Response = await c.put(f"{ML}/deals/{deal.id}/ratings/{role}", json=body, headers=h)
    return r


async def completed(c: Any) -> Deal:
    deal = await introduced(c)
    assert (await done(c, deal, deal.gh)).status_code == 200
    assert (await done(c, deal, deal.trader.h)).status_code == 200
    return deal


async def test_flag_off_hides_the_l5_endpoints(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    some = uuid.uuid4()
    for method, path in (
        ("POST", f"{ML}/deals/{some}/done"),
        ("GET", f"{ML}/deals/{some}/ratings"),
        ("PUT", f"{ML}/deals/{some}/ratings/trader"),
    ):
        r = await client.request(method, path, headers=auth_headers, json={})
        assert r.status_code == 404, (path, r.text)


async def test_non_party_cannot_tap_rate_or_read(ml: Any, clock: Clock) -> None:
    deal = await completed(ml)
    stranger = await party(ml)
    assert (await done(ml, deal, stranger.h)).status_code == 404
    assert (await rate(ml, deal, stranger.h, "grower", answers("grower"))).status_code == 404
    r = await ml.get(f"{ML}/deals/{deal.id}/ratings", headers=stranger.h)
    assert r.status_code == 404
    missing = Deal(str(uuid.uuid4()), deal.gh, deal.trader, deal.broker)
    assert (await done(ml, missing, deal.gh)).status_code == 404


async def test_one_sided_tap_does_not_complete(ml: Any, clock: Clock) -> None:
    deal = await introduced(ml)
    r = await done(ml, deal, deal.gh)
    assert r.status_code == 200, r.text
    state = r.json()["state"]
    assert state["my_role"] == "grower"
    assert state["grower_done_at"] is not None
    assert state["trader_done_at"] is None
    assert state["completed_at"] is None
    assert state["rating_until"] is None
    # A repeat tap changes nothing; the broker does not tap (Q67, Q81).
    assert (await done(ml, deal, deal.gh)).json()["state"] == state
    r = await done(ml, deal, deal.broker.h)
    assert (r.status_code, r.json()["error"]["code"]) == (403, "broker_does_not_tap")
    r = await rate(ml, deal, deal.gh, "trader", answers("trader"))
    assert (r.status_code, r.json()["error"]["code"]) == (409, "deal_not_completed")
    # The trader's tap completes it.
    clock.now = T0 + timedelta(hours=3)
    r = await done(ml, deal, deal.trader.h)
    state = r.json()["state"]
    assert state["my_role"] == "trader"
    assert state["rates"] == ["grower"]
    assert datetime.fromisoformat(state["completed_at"]) == clock.now
    assert datetime.fromisoformat(state["rating_until"]) == clock.now + timedelta(days=7)
    async with ml.maker() as s:
        row = await s.get(MarketDeal, uuid.UUID(deal.id))
        assert row is not None
        assert row.status == "completed"
        kinds = [
            e.kind
            for e in await s.scalars(
                select(DealEvent).where(DealEvent.deal_id == row.id).order_by(DealEvent.created_at)
            )
        ]
    assert kinds == ["accepted", "done", "done", "completed"]
    # The broker sees the completed state and rates the grower.
    r = await ml.get(f"{ML}/deals/{deal.id}", headers=deal.broker.h)
    assert r.json()["state"]["my_role"] == "broker"
    assert r.json()["state"]["rates"] == ["grower"]


async def test_rating_refuses_text_unknown_and_wrong_tags(ml: Any, clock: Clock) -> None:
    deal = await completed(ml)
    ids = await tags(ml)
    body = answers("trader")
    for extra in ({"comment": "चांगला"}, {"text": "x"}):
        r = await rate(ml, deal, deal.gh, "trader", {**body, **extra})
        assert r.status_code == 422, extra
        inner = {"answers": [{**body["answers"][0], **extra}, *body["answers"][1:]]}
        assert (await rate(ml, deal, deal.gh, "trader", inner)).status_code == 422, extra
    q0 = questions()["trader"][0]
    async with ml.maker() as s:
        retired = RatingTag(
            key="old",
            question_key=q0,
            polarity="negative",
            label_mr="म",
            label_hi="ह",
            label_en="e",
            status="retired",
        )
        s.add(retired)
        await s.commit()
    for bad in ([uuid.uuid4()], [retired.id], [ids[questions()["trader"][1]][0]], [ids[q0][0]] * 2):
        r = await rate(ml, deal, deal.gh, "trader", answers("trader", ticks={q0: bad}))
        assert (r.status_code, r.json()["error"]["code"]) == (422, "unknown_tag"), bad
    for stars in (0, 6):
        assert (
            await rate(ml, deal, deal.gh, "trader", answers("trader", stars))
        ).status_code == 422
    partial = {"answers": answers("trader")["answers"][:-1]}
    r = await rate(ml, deal, deal.gh, "trader", partial)
    assert (r.status_code, r.json()["error"]["code"]) == (422, "questions_mismatch")
    # The trader does not rate the broker, nor the grower itself (Q112).
    assert (await rate(ml, deal, deal.trader.h, "broker", answers("broker"))).status_code == 404
    assert (await rate(ml, deal, deal.gh, "grower", answers("grower"))).status_code == 404
    assert (await rate(ml, deal, deal.gh, "seller", answers("grower"))).status_code == 422


async def test_rating_changes_within_7_days_then_locks(ml: Any, clock: Clock) -> None:
    deal = await completed(ml)
    ids = await tags(ml)
    q0 = questions()["trader"][0]
    r = await rate(ml, deal, deal.gh, "trader", answers("trader", 5, {q0: [ids[q0][0]]}))
    assert r.status_code == 200, r.text
    [given] = r.json()["given"]
    assert given["ratee_role"] == "trader"
    assert [a["question_key"] for a in given["answers"]] == list(questions()["trader"])
    clock.now = T0 + timedelta(days=6, hours=23)
    r = await rate(ml, deal, deal.gh, "trader", answers("trader", 2, {q0: [ids[q0][1]]}))
    assert r.status_code == 200, r.text
    [given] = r.json()["given"]  # changed, not a second rating
    assert {a["stars"] for a in given["answers"]} == {2}
    assert given["answers"][0]["tag_ids"] == [str(ids[q0][1])]
    clock.now = T0 + timedelta(days=7)
    r = await rate(ml, deal, deal.gh, "trader", answers("trader", 5))
    assert (r.status_code, r.json()["error"]["code"]) == (409, "rating_locked")
    r = await rate(ml, deal, deal.broker.h, "grower", answers("grower", 5))
    assert (r.status_code, r.json()["error"]["code"]) == (409, "rating_locked")
    r = await ml.get(f"{ML}/deals/{deal.id}/ratings", headers=deal.gh)
    assert r.json()["state"]["rating_locked"] is True
    assert {a["stars"] for a in r.json()["given"][0]["answers"]} == {2}


async def test_profiles_show_the_aggregates(ml: Any, clock: Clock) -> None:
    ids = await tags(ml)
    q0, q1 = questions()["trader"][:2]
    one = await completed(ml)
    trader = one.trader
    # A second deal with the same trader, another grower.
    _g, lot_id, gh2 = await published(ml)
    r = await send(ml, lot_id, trader)
    r = await ml.post(f"{ML}/interests/{r.json()['id']}/accept", headers=gh2)
    two = Deal(r.json()["deal_id"], gh2, trader, one.broker)
    await done(ml, two, gh2)
    await done(ml, two, trader.h)
    # A third, never completed, counts nothing.
    await introduced(ml)
    await rate(ml, one, one.gh, "trader", answers("trader", 5, {q0: [ids[q0][0]]}))
    await rate(ml, two, gh2, "trader", answers("trader", 2, {q0: [ids[q0][0]], q1: [ids[q1][1]]}))
    r = await ml.get(f"{ML}/profiles/buyer/{trader.profile}", headers=gh2)
    assert r.status_code == 200, r.text
    p = r.json()
    assert p["deals_completed"] == 2
    stars = {s["question_key"]: (s["average"], s["count"]) for s in p["stars"]}
    assert stars == dict.fromkeys(questions()["trader"], (3.5, 2))
    counts = {t["tag_id"]: t["count"] for t in p["tags"]}
    assert counts == {str(ids[q0][0]): 2, str(ids[q1][1]): 1}
    r = await ml.get(f"{ML}/profiles/broker/{one.broker.profile}", headers=gh2)
    assert r.json()["deals_completed"] == 1
    assert r.json()["stars"] == []
