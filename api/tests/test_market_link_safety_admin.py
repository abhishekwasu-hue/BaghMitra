"""Market linkage L6 admin: the report queue, actions with a reason code the user sees, the
action log and the appeals the grievance officer decides, with the 24 h / 15 day timeline
(spec v1.5 §4, §4C; Addendum 5: platform rules only; Q92, Q93)."""

from __future__ import annotations

import uuid
from datetime import timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select

from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import (
    ACTION_REASONS,
    AdminAction,
    BuyerProfile,
    MarketLot,
    PartyVerification,
)
from bagmitra_api.market_link.visibility import is_suspended, visible
from tests.test_market_link_reports import (
    ADMIN,
    ADMIN_BASE,
    ADMIN_ID,
    BROKER,
    EXIF_JPEG,
    GROWER,
    ML,
    TRADER,
    Clock,
    FakeStorage,
    Maker,
    _headers,
    _report,
    api,
    clock,
    ids,
    maker,
    storage,
)

__all__ = ["api", "clock", "ids", "maker", "storage"]  # fixtures used by name


async def test_admin_paths_are_404_while_the_flag_is_off(settings: Any, maker: Maker) -> None:
    app = create_app(settings)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        for path in ("reports", "appeals", "actions"):
            assert (await c.get(f"{ADMIN_BASE}/{path}", headers=ADMIN)).status_code == 404


async def test_admin_opens_a_report_photo_by_a_short_link(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID]
) -> None:
    report = await _report(api, GROWER, "buyer", ids["buyer"], "impersonation")
    jpeg = {**_headers(GROWER), "Content-Type": "image/jpeg"}
    await api.post(f"{ML}/reports/{report['id']}/photos", content=EXIF_JPEG, headers=jpeg)
    base = f"{ADMIN_BASE}/reports/{report['id']}/photos"
    link = (await api.get(f"{base}/0/url", headers=ADMIN)).json()
    assert link["photo_key"] == f"{GROWER}/report-{report['id']}-1.jpg"
    assert (await api.get(f"{base}/1/url", headers=ADMIN)).status_code == 404
    assert (await api.get(f"{base}/0/url", headers=_headers(GROWER))).status_code == 403


async def test_admin_queue_oldest_first_with_grievance_timeline(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], clock: Clock
) -> None:
    assert (await api.get(f"{ADMIN_BASE}/reports", headers=_headers(GROWER))).status_code == 403
    first = await _report(api, GROWER, "buyer", ids["buyer"], "fake_identity")
    second = await _report(api, TRADER, "broker", ids["broker"], "abuse")
    queue = (await api.get(f"{ADMIN_BASE}/reports", headers=ADMIN)).json()["reports"]
    assert [q["id"] for q in queue] == [first["id"], second["id"]]
    assert queue[0]["subject_user_id"] == str(TRADER)
    assert not queue[0]["ack_overdue"]
    assert not queue[0]["close_overdue"]
    only = await api.get(f"{ADMIN_BASE}/reports?subject_type=broker", headers=ADMIN)
    assert [q["id"] for q in only.json()["reports"]] == [second["id"]]
    clock.now += timedelta(hours=25)
    late = (await api.get(f"{ADMIN_BASE}/reports", headers=ADMIN)).json()["reports"][0]
    assert late["ack_overdue"]
    assert not late["close_overdue"]
    acked = await api.post(f"{ADMIN_BASE}/reports/{first['id']}/acknowledge", headers=ADMIN)
    assert acked.json()["acknowledged_at"] is not None
    assert not acked.json()["ack_overdue"]
    clock.now += timedelta(days=15)
    late = (await api.get(f"{ADMIN_BASE}/reports", headers=ADMIN)).json()["reports"][0]
    assert late["close_overdue"]
    assert not late["ack_overdue"]


@pytest.mark.parametrize(
    ("action", "reason"),
    [
        ("hide", "late_payment"),
        ("hide", "checks_passed"),
        ("warn", "appeal_upheld"),
        ("warn", None),
    ],
)
async def test_admin_acts_only_on_platform_rules(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], action: str, reason: str | None
) -> None:
    report = await _report(api, GROWER, "buyer", ids["buyer"], "fake_identity")
    r = await api.post(
        f"{ADMIN_BASE}/reports/{report['id']}/decision",
        json={"action": action, "reason_code": reason},
        headers=ADMIN,
    )
    assert r.status_code == 422


def test_reason_codes_per_action_are_platform_rules_only() -> None:
    quarrels = {"payment", "weight", "quality", "late_payment", "rate"}
    for codes in ACTION_REASONS.values():
        assert not quarrels & set(codes)
    assert set(ACTION_REASONS["restore"]) == {"checks_passed", "appeal_upheld"}


async def test_dismiss_and_act_close_reports(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], maker: Maker
) -> None:
    a = await _report(api, TRADER, "lot", ids["lot"], "fake_lot")
    b = await _report(api, BROKER, "buyer", ids["buyer"], "fake_identity")
    c = await _report(api, GROWER, "buyer", ids["buyer"], "impersonation")
    dismissed = await api.post(f"{ADMIN_BASE}/reports/{a['id']}/dismiss", headers=ADMIN)
    assert dismissed.json()["status"] == "dismissed"
    assert dismissed.json()["admin_action_id"] is None
    acted = await api.post(
        f"{ADMIN_BASE}/reports/{b['id']}/decision",
        json={"action": "hide", "reason_code": "fake_identity"},
        headers=ADMIN,
    )
    assert acted.json()["status"] == "actioned"
    closed = (await api.get(f"{ADMIN_BASE}/reports?status=actioned", headers=ADMIN)).json()
    assert {r["id"] for r in closed["reports"]} == {b["id"], c["id"]}
    again = await api.post(f"{ADMIN_BASE}/reports/{b['id']}/dismiss", headers=ADMIN)
    assert again.status_code == 409
    log = (await api.get(f"{ADMIN_BASE}/actions?user_id={TRADER}", headers=ADMIN)).json()
    [row] = log["actions"]
    assert (row["action"], row["reason_code"], row["actor_id"]) == (
        "hide",
        "fake_identity",
        str(ADMIN_ID),
    )
    async with maker() as s:
        names = await s.scalars(
            select(BuyerProfile.name).where(visible("buyer", BuyerProfile.id, BuyerProfile.user_id))
        )
        assert list(names) == []
        assert not await is_suspended(s, TRADER)  # hidden, not suspended


async def _act(
    api: httpx.AsyncClient, kind: str, subject: uuid.UUID, action: str, reason: str
) -> dict[str, Any]:
    r = await api.post(
        f"{ADMIN_BASE}/actions",
        json={
            "subject_type": kind,
            "subject_id": str(subject),
            "action": action,
            "reason_code": reason,
        },
        headers=ADMIN,
    )
    assert r.status_code == 201, r.text
    body: dict[str, Any] = r.json()
    return body


async def _visible_lots(maker: Maker) -> list[uuid.UUID]:
    async with maker() as s:
        return list(
            await s.scalars(
                select(MarketLot.id).where(visible("lot", MarketLot.id, MarketLot.owner_id))
            )
        )


async def test_suspend_hides_everything_of_the_user_until_restored(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], maker: Maker
) -> None:
    assert await _visible_lots(maker) == [ids["lot"]]
    await _act(api, "user", GROWER, "warn", "abuse")
    assert await _visible_lots(maker) == [ids["lot"]]  # a warning hides nothing
    suspended = await _act(api, "user", GROWER, "suspend", "duplicate_user")
    assert suspended["user_id"] == str(GROWER)
    assert await _visible_lots(maker) == []
    async with maker() as s:
        assert await is_suspended(s, GROWER)
    await _act(api, "user", GROWER, "restore", "checks_passed")
    assert await _visible_lots(maker) == [ids["lot"]]
    await _act(api, "lot", ids["lot"], "hide", "fake_lot")
    assert await _visible_lots(maker) == []
    async with maker() as s:
        assert not await is_suspended(s, GROWER)


async def test_affected_user_sees_reason_and_appeals_once(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], clock: Clock, storage: FakeStorage
) -> None:
    hidden = await _act(api, "buyer", ids["buyer"], "hide", "fake_identity")
    t = _headers(TRADER)
    [mine] = (await api.get(f"{ML}/account-actions", headers=t)).json()["actions"]
    assert (mine["action"], mine["reason_code"], mine["can_appeal"]) == (
        "hide",
        "fake_identity",
        True,
    )
    assert (await api.get(f"{ML}/account-actions", headers=_headers(GROWER))).json() == {
        "actions": []
    }
    url = f"{ML}/account-actions/{hidden['id']}/appeal"
    assert (
        await api.post(url, json={"reason": "identity_genuine"}, headers=_headers(GROWER))
    ).status_code == 404
    text = {"reason": "identity_genuine", "text": "I am real"}
    assert (await api.post(url, json=text, headers=t)).status_code == 422
    assert (await api.post(url, json={"reason": "paid_on_time"}, headers=t)).status_code == 422
    r = await api.post(url, json={"reason": "identity_genuine"}, headers=t)
    assert r.status_code == 200, r.text
    assert (r.json()["appeal_state"], r.json()["can_appeal"]) == ("appealed", False)
    assert (await api.post(url, json={"reason": "not_duplicate"}, headers=t)).status_code == 409
    photo = await api.post(
        f"{url}/photos", content=EXIF_JPEG, headers={**t, "Content-Type": "image/jpeg"}
    )
    assert photo.json()["appeal_photo_count"] == 1
    assert all(b"Exif" not in v for v in storage.objects.values())
    # The grievance officer's list: oldest first, with the 24 h / 15 day flags.
    clock.now += timedelta(hours=30)
    [appeal] = (await api.get(f"{ADMIN_BASE}/appeals", headers=ADMIN)).json()["actions"]
    assert appeal["ack_overdue"]
    assert not appeal["close_overdue"]
    assert appeal["appeal_reason"] == "identity_genuine"
    link = await api.get(f"{ADMIN_BASE}/appeals/{hidden['id']}/photos/0/url", headers=ADMIN)
    assert link.status_code == 200
    ack = await api.post(f"{ADMIN_BASE}/appeals/{hidden['id']}/acknowledge", headers=ADMIN)
    assert not ack.json()["ack_overdue"]
    decided = await api.post(
        f"{ADMIN_BASE}/appeals/{hidden['id']}/decision",
        json={"outcome": "upheld"},
        headers=ADMIN,
    )
    assert decided.json()["appeal_state"] == "upheld"
    again = await api.post(
        f"{ADMIN_BASE}/appeals/{hidden['id']}/decision",
        json={"outcome": "rejected"},
        headers=ADMIN,
    )
    assert again.status_code == 409
    actions = (await api.get(f"{ML}/account-actions", headers=t)).json()["actions"]
    assert [(a["action"], a["reason_code"]) for a in actions] == [
        ("restore", "appeal_upheld"),
        ("hide", "fake_identity"),
    ]
    assert not actions[0]["can_appeal"]  # a restore is not appealable
    assert (await api.get(f"{ADMIN_BASE}/appeals", headers=ADMIN)).json() == {"actions": []}


async def test_a_rejected_appeal_keeps_the_suspension(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], maker: Maker
) -> None:
    action = await _act(api, "lot", ids["lot"], "suspend", "fake_lot")
    r = await api.post(
        f"{ML}/account-actions/{action['id']}/appeal",
        json={"reason": "lot_genuine"},
        headers=_headers(GROWER),
    )
    assert r.status_code == 200
    await api.post(
        f"{ADMIN_BASE}/appeals/{action['id']}/decision",
        json={"outcome": "rejected"},
        headers=ADMIN,
    )
    async with maker() as s:
        assert await is_suspended(s, GROWER)
    assert await _visible_lots(maker) == []


async def test_a_verify_is_logged_and_not_appealable(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], maker: Maker
) -> None:
    async with maker() as s:
        s.add(PartyVerification(subject_type="broker", subject_id=ids["broker"], status="pending"))
        await s.commit()
    r = await api.post(
        f"{ADMIN_BASE}/verifications/broker/{ids['broker']}/decision",
        json={"status": "approved"},
        headers=ADMIN,
    )
    assert r.status_code == 200, r.text
    [verify] = (await api.get(f"{ML}/account-actions", headers=_headers(BROKER))).json()["actions"]
    assert (verify["action"], verify["reason_code"], verify["can_appeal"]) == (
        "verify",
        "checks_passed",
        False,
    )
    url = f"{ML}/account-actions/{verify['id']}/appeal"
    r = await api.post(url, json={"reason": "identity_genuine"}, headers=_headers(BROKER))
    assert r.status_code == 409
    async with maker() as s:
        rows = list(await s.scalars(select(AdminAction)))
        assert [a.actor_id for a in rows] == [ADMIN_ID]
