"""Emoji reactions after reading (owner 2026-11-12, Q146): set, change, remove, one per reader
and target, counts for feed items and bundled Q&A answers, erasure and the admin lists."""

from __future__ import annotations

import base64
import uuid
from pathlib import Path
from typing import Any

import httpx
import pytest
from alembic import command
from sqlalchemy import create_engine, inspect, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.account.erase import erase_account
from bagmitra_api.feed.models import REACTIONS, FeedReaction
from tests.conftest import make_token
from tests.test_feed_api import ADMIN, ADMIN_BASE, ai_box, api, approve_publish, create, ocr_box
from tests.test_migrations import _config, _sync_url

__all__ = ["ai_box", "api", "ocr_box"]  # fixtures used here
BASE = "/v1/reactions"


def _who(user: uuid.UUID | None = None) -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(user or uuid.uuid4())}"}


def _counts(body: dict[str, Any]) -> dict[str, int]:
    return {c["reaction"]: c["count"] for c in body["counts"] if c["count"]}


async def _published(api: httpx.AsyncClient, external_id: str = "react-1") -> str:
    pdf = base64.b64encode(f"%PDF-1.4 test {external_id}".encode()).decode()
    item = await create(api, external_id=external_id, document_base64=pdf)
    await approve_publish(api, item["id"])
    return str(item["id"])


async def test_set_change_and_remove(api: httpx.AsyncClient) -> None:
    item = await _published(api)
    me = _who()
    url = f"{BASE}/{item}"
    assert (await api.put(url, json={"reaction": "useful"})).status_code == 401

    res = await api.put(url, json={"reaction": "useful"}, headers=me)
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["target"] == item
    assert body["mine"] == "useful"
    assert [c["reaction"] for c in body["counts"]] == list(REACTIONS), "fixed app order"
    assert _counts(body) == {"useful": 1}

    # Another one replaces it; the same one again changes nothing.
    res = await api.put(url, json={"reaction": "unclear"}, headers=me)
    assert (res.json()["mine"], _counts(res.json())) == ("unclear", {"unclear": 1})
    res = await api.put(url, json={"reaction": "unclear"}, headers=me)
    assert _counts(res.json()) == {"unclear": 1}

    res = await api.delete(url, headers=me)
    assert res.status_code == 200
    assert (res.json()["mine"], _counts(res.json())) == (None, {})
    # Removing again is fine and answers the same.
    assert (await api.delete(url, headers=me)).json()["mine"] is None


async def test_counts_across_readers_and_own_choice(api: httpx.AsyncClient) -> None:
    item = await _published(api)
    readers = [uuid.uuid4() for _ in range(4)]
    for user, reaction in zip(readers, ("useful", "useful", "thanks", "okay"), strict=True):
        res = await api.put(f"{BASE}/{item}", json={"reaction": reaction}, headers=_who(user))
        assert res.status_code == 200
    qa = "qa:seed-psylla-symptoms"
    await api.put(f"{BASE}/{qa}", json={"reaction": "liked"}, headers=_who(readers[0]))

    res = await api.get(
        BASE, params=[("target", item), ("target", qa), ("target", item)], headers=_who(readers[2])
    )
    assert res.status_code == 200, res.text
    rows = res.json()["reactions"]
    assert [r["target"] for r in rows] == [item, qa], "asked order, duplicates once"
    assert _counts(rows[0]) == {"useful": 2, "thanks": 1, "okay": 1}
    assert rows[0]["mine"] == "thanks"
    assert (_counts(rows[1]), rows[1]["mine"]) == ({"liked": 1}, None)
    assert "owner_id" not in res.text

    nobody = await api.get(BASE, params={"target": "qa:never"}, headers=_who())
    assert _counts(nobody.json()["reactions"][0]) == {}


async def test_qa_targets_and_refusals(api: httpx.AsyncClient) -> None:
    me = _who()
    res = await api.put(f"{BASE}/qa:q0123abcd9", json={"reaction": "okay"}, headers=me)
    assert res.status_code == 200, res.text
    assert res.json()["target"] == "qa:q0123abcd9"
    for bad in ("qa:", "qa:has space", "nonsense", "qa:" + "x" * 65):
        res = await api.put(f"{BASE}/{bad}", json={"reaction": "okay"}, headers=me)
        assert res.status_code in (404, 422), bad
    res = await api.put(f"{BASE}/qa:x", json={"reaction": "angry"}, headers=me)
    assert res.status_code == 422
    # A feed item that is not published (or does not exist) cannot be reacted to.
    draft = await create(api, external_id="react-draft")
    for target in (draft["id"], str(uuid.uuid4())):
        res = await api.put(f"{BASE}/{target}", json={"reaction": "useful"}, headers=me)
        assert res.status_code == 404, target
    too_many: list[tuple[str, str | int | float | bool | None]] = [
        ("target", f"qa:t{i}") for i in range(51)
    ]
    assert (await api.get(BASE, params=too_many, headers=me)).status_code == 422
    assert (await api.get(BASE, params={"target": "bad key"}, headers=me)).status_code == 422


async def test_one_row_per_reader_and_target(api: httpx.AsyncClient, engine: AsyncEngine) -> None:
    item = await _published(api)
    user = uuid.uuid4()
    for reaction in ("useful", "thanks", "liked"):
        await api.put(f"{BASE}/{item}", json={"reaction": reaction}, headers=_who(user))
        await api.put(f"{BASE}/qa:seed-a", json={"reaction": reaction}, headers=_who(user))
    maker = async_sessionmaker(engine)
    async with maker() as s:
        rows = list(await s.scalars(select(FeedReaction).where(FeedReaction.owner_id == user)))
    assert sorted((str(r.item_id), r.qa_id, r.reaction) for r in rows) == sorted(
        [(item, None, "liked"), ("None", "seed-a", "liked")]
    )
    # The database refuses a second row for the same reader and target.
    for extra in (
        {"item_id": uuid.UUID(item)},
        {"qa_id": "seed-a"},
    ):
        async with maker() as s:
            s.add(FeedReaction(id=uuid.uuid4(), owner_id=user, reaction="okay", **extra))
            with pytest.raises(IntegrityError):
                await s.commit()
    # ... and a row with both targets or none.
    for both in ({"item_id": uuid.UUID(item), "qa_id": "seed-b"}, {}):
        async with maker() as s:
            s.add(FeedReaction(id=uuid.uuid4(), owner_id=uuid.uuid4(), reaction="okay", **both))
            with pytest.raises(IntegrityError):
                await s.commit()


async def test_account_erasure_deletes_only_the_callers_reactions(
    api: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    item = await _published(api)
    me, other = uuid.uuid4(), uuid.uuid4()
    for user in (me, other):
        await api.put(f"{BASE}/{item}", json={"reaction": "useful"}, headers=_who(user))
        await api.put(f"{BASE}/qa:seed-a", json={"reaction": "thanks"}, headers=_who(user))
    async with async_sessionmaker(engine, expire_on_commit=False)() as s:
        await erase_account(s, me, storage=None, auth_admin=None)
    async with async_sessionmaker(engine)() as s:
        owners = list(await s.scalars(select(FeedReaction.owner_id)))
    assert owners == [other, other]
    res = await api.get(BASE, params={"target": item}, headers=_who(other))
    assert _counts(res.json()["reactions"][0]) == {"useful": 1}


async def test_admin_counts_and_helpful_lists(api: httpx.AsyncClient) -> None:
    good = await _published(api, "react-good")
    weak = await _published(api, "react-weak")
    for reaction in ("useful", "useful", "thanks"):
        await api.put(f"{BASE}/{good}", json={"reaction": reaction}, headers=_who())
    for reaction in ("unclear", "unclear", "okay"):
        await api.put(f"{BASE}/{weak}", json={"reaction": reaction}, headers=_who())
    await api.put(f"{BASE}/qa:seed-a", json={"reaction": "liked"}, headers=_who())

    assert (await api.get(f"{ADMIN_BASE}/reactions", headers=_who())).status_code == 403
    res = await api.get(f"{ADMIN_BASE}/reactions", headers=ADMIN)
    assert res.status_code == 200, res.text
    body = res.json()
    assert (body["targets"], body["total"]) == (3, 7)
    assert [r["target"] for r in body["most_helpful"]] == [good, "qa:seed-a", weak]
    assert body["least_helpful"][0]["target"] == weak
    top = body["most_helpful"][0]
    assert top["kind"] == "item"
    assert top["item_type"] == "scheme"
    assert top["title"] == "Fruit planting subsidy"
    assert (top["total"], top["helpful"], top["unclear"]) == (3, 3, 0)
    qa_row = body["most_helpful"][1]
    assert (qa_row["kind"], qa_row["title"], qa_row["item_type"]) == ("qa", "seed-a", None)
    assert "owner" not in res.text, "counts only, no reader identities"
    limited = await api.get(f"{ADMIN_BASE}/reactions", params={"limit": 1}, headers=ADMIN)
    assert len(limited.json()["most_helpful"]) == 1

    # Per-item counts in the feed admin list and detail.
    listed = await api.get(f"{ADMIN_BASE}/items", params={"status": "published"}, headers=ADMIN)
    by_id = {i["id"]: i for i in listed.json()["items"]}
    assert {c["reaction"]: c["count"] for c in by_id[weak]["reactions"] if c["count"]} == {
        "unclear": 2,
        "okay": 1,
    }
    detail = await api.get(f"{ADMIN_BASE}/items/{good}", headers=ADMIN)
    assert {c["reaction"]: c["count"] for c in detail.json()["reactions"] if c["count"]} == {
        "useful": 2,
        "thanks": 1,
    }


def test_migration_0051_up_and_down(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'r.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))

    def exists() -> bool:
        with engine.connect() as conn:
            return "feed_reactions" in inspect(conn).get_table_names()

    command.upgrade(cfg, "0051")
    assert exists()
    with engine.connect() as conn:
        uniques = {u["name"] for u in inspect(conn).get_unique_constraints("feed_reactions")}
    assert uniques == {"uq_feed_reactions_item_id", "uq_feed_reactions_qa_id"}
    command.downgrade(cfg, "0050")
    assert not exists()
    command.upgrade(cfg, "0051")
    assert exists()
    engine.dispose()
