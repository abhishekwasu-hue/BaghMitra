"""Feed G2 farmer API: push preferences, seen / dismiss / remind receipts, `seen` in the
feed list, and the dated events written on publish."""

from __future__ import annotations

import uuid
from datetime import timedelta

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.feed.models import FeedDeadline, FeedReceipt
from tests.conftest import make_token
from tests.test_feed_api import (
    ADMIN,
    ADMIN_BASE,
    GR_TEXT,
    TODAY,
    ai_box,
    api,
    approve_publish,
    create,
    ocr_box,
)

__all__ = ["ai_box", "api", "ocr_box"]  # fixtures used here
PREFS = "/v1/me/feed-preferences"


async def test_preferences_default_and_update(
    api: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    assert (await api.get(PREFS)).status_code == 401
    res = await api.get(PREFS, headers=auth_headers)
    assert res.json() == {
        "quiet_start": "21:00",
        "quiet_end": "07:00",
        "weekly_cap": 3,
        "opted_out": [],
        "digest_weekly": True,
    }
    body = {
        "quiet_start": "22:30",
        "quiet_end": "06:00",
        "weekly_cap": 5,
        "opted_out": ["payment", "deadline", "payment"],
        "digest_weekly": False,
    }
    res = await api.put(PREFS, json=body, headers=auth_headers)
    assert res.status_code == 200, res.text
    assert res.json()["opted_out"] == ["deadline", "payment"]
    assert (await api.get(PREFS, headers=auth_headers)).json() == res.json()
    other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    assert (await api.get(PREFS, headers=other)).json()["weekly_cap"] == 3, "owner-scoped"
    for bad in ({"quiet_start": "24:00"}, {"weekly_cap": 99}, {"opted_out": ["news"]}):
        res = await api.put(PREFS, json=body | bad, headers=auth_headers)
        assert res.status_code == 422, bad


async def test_publish_writes_dated_events(api: httpx.AsyncClient, engine: AsyncEngine) -> None:
    pay = TODAY + timedelta(days=30)
    item = await create(
        api,
        external_id="pay-1",
        payment_date=pay.isoformat(),
        valid_from=TODAY.isoformat(),
        extracted_text=(
            f"{GR_TEXT} रक्कम वितरण {pay.strftime('%d/%m/%Y')}, सुरू {TODAY.strftime('%d/%m/%Y')}."
        ),
    )
    assert item["payment_date"] == pay.isoformat()
    assert item["check_issues"] == []
    await approve_publish(api, item["id"])
    async with async_sessionmaker(engine)() as s:
        rows = await s.scalars(
            select(FeedDeadline).where(FeedDeadline.item_id == uuid.UUID(item["id"]))
        )
        kinds = {r.kind: r.due_date for r in rows}
    assert kinds == {
        "apply_by": TODAY + timedelta(days=30),
        "payment": pay,
        "window_open": TODAY,
    }


async def test_hallucinated_payment_date_is_caught(api: httpx.AsyncClient) -> None:
    item = await create(
        api, external_id="pay-2", payment_date=(TODAY + timedelta(days=99)).isoformat()
    )
    assert [c["where"] for c in item["check_issues"]] == ["payment_date"]


async def test_seen_dismiss_remind(
    api: httpx.AsyncClient,
    engine: AsyncEngine,
    user_id: uuid.UUID,
    auth_headers: dict[str, str],
) -> None:
    item = await create(api)
    url = f"/v1/feed/{item['id']}"
    assert (await api.post(f"{url}/seen", headers=auth_headers)).status_code == 404, "in review"
    await approve_publish(api, item["id"])
    assert (
        await api.post(f"/v1/feed/{uuid.uuid4()}/seen", headers=auth_headers)
    ).status_code == 404

    feed = (await api.get("/v1/feed", headers=auth_headers)).json()["items"]
    assert [i["seen"] for i in feed] == [False]
    res = await api.post(f"{url}/seen", headers=auth_headers)
    assert res.json() == {"item_id": item["id"], "seen": True, "dismissed": False, "remind": False}
    feed = (await api.get("/v1/feed", headers=auth_headers)).json()["items"]
    assert [i["seen"] for i in feed] == [True]
    other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    assert [i["seen"] for i in (await api.get("/v1/feed", headers=other)).json()["items"]] == [
        False
    ]

    res = await api.post(f"{url}/dismiss", headers=auth_headers)
    assert res.json()["dismissed"] is True
    res = await api.post(f"{url}/remind", headers=auth_headers)
    assert (res.json()["remind"], res.json()["dismissed"]) == (True, False)
    async with async_sessionmaker(engine)() as s:
        [row] = list(await s.scalars(select(FeedReceipt)))
    assert (row.owner_id, row.seen_at is not None) == (user_id, True)

    res = await api.post(
        f"{ADMIN_BASE}/items/{item['id']}/withdraw", json={"reason": "superseded"}, headers=ADMIN
    )
    assert res.status_code == 200, res.text
    res = await api.post(f"{url}/remind", headers=auth_headers)
    assert (res.status_code, res.json()["error"]["code"]) == (409, "withdrawn")


async def test_remind_needs_a_date(api: httpx.AsyncClient, auth_headers: dict[str, str]) -> None:
    item = await create(api, external_id="no-date", deadline=None)
    await approve_publish(api, item["id"])
    res = await api.post(f"/v1/feed/{item['id']}/remind", headers=auth_headers)
    assert (res.status_code, res.json()["error"]["code"]) == (409, "no_deadline")
