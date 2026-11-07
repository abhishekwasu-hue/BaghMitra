"""M6b server verification (billing addendum §2.2-§2.4): a purchase token unlocks nothing until
Play confirms it; the token binds to one user; the server acknowledges; Play states map to ours;
a pending price change reaches the app for the required notice. Google is a fake."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.billing.models import BillingEvent, Subscription
from bagmitra_api.billing.play import PlayError
from bagmitra_api.billing.purchases import PLAY_STATES, account_id, read_purchase, token_hash
from tests.conftest import make_token
from tests.play_fakes import FakePlay, purchase
from tests.test_billing_play import admin_api

URL = "/v1/billing/google/verify"
TOKEN = "purchase-token-0001"


def headers(user: uuid.UUID) -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(user)}"}


@pytest.mark.parametrize(
    ("play_state", "ours"),
    [
        ("SUBSCRIPTION_STATE_PENDING", "PENDING"),
        ("SUBSCRIPTION_STATE_ACTIVE", "ACTIVE"),
        ("SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "IN_GRACE_PERIOD"),
        ("SUBSCRIPTION_STATE_ON_HOLD", "ON_HOLD"),
        ("SUBSCRIPTION_STATE_PAUSED", "PAUSED"),
        ("SUBSCRIPTION_STATE_CANCELED", "CANCELED"),
        ("SUBSCRIPTION_STATE_EXPIRED", "EXPIRED"),
        ("SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED", "EXPIRED"),
    ],
)
def test_every_play_state_maps_to_ours(play_state: str, ours: str) -> None:
    assert PLAY_STATES[play_state] == ours


async def test_a_verified_purchase_unlocks_and_is_acknowledged(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    play.purchases[TOKEN] = purchase(account_id(user))
    async with admin_api(engine, play) as client:
        res = await client.post(URL, headers=headers(user), json={"purchase_token": TOKEN})
        assert res.status_code == 200, res.text
        assert "role_grower" in res.json()["entitlements"]["plans"]
    assert ("acknowledge", ("bagmitra_grower", TOKEN)) in play.calls
    async with async_sessionmaker(engine)() as session:
        row = await session.scalar(select(Subscription))
        assert row is not None
        assert row.provider == "google_play"
        assert row.state == "ACTIVE"
        assert row.purchase_token_hash == token_hash(TOKEN)  # the token itself is never stored
        assert row.auto_renew is True
        event = await session.scalar(select(BillingEvent))
        assert event is not None
        assert event.event_type == "play_verified"
        assert TOKEN not in str(event.payload)


async def test_an_acknowledged_or_pending_purchase_is_not_acknowledged_again(
    engine: AsyncEngine,
) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    play.purchases[TOKEN] = purchase(account_id(user), acknowledged=True)
    play.purchases["pending-token-01"] = purchase(
        account_id(user), state="SUBSCRIPTION_STATE_PENDING"
    )
    async with admin_api(engine, play) as client:
        for token in (TOKEN, "pending-token-01"):
            res = await client.post(URL, headers=headers(user), json={"purchase_token": token})
            assert res.status_code == 200
    assert not [c for c in play.calls if c[0] == "acknowledge"]


async def test_a_token_replayed_from_another_account_is_refused(engine: AsyncEngine) -> None:
    owner, other = uuid.uuid4(), uuid.uuid4()
    play = FakePlay()
    play.purchases[TOKEN] = purchase(account_id(owner))
    async with admin_api(engine, play) as client:
        assert (
            await client.post(URL, headers=headers(owner), json={"purchase_token": TOKEN})
        ).status_code == 200
        replay = await client.post(URL, headers=headers(other), json={"purchase_token": TOKEN})
        assert replay.status_code == 409
        assert replay.json()["error"]["code"] == "token_in_use"
        play.purchases["fresh-token-0002"] = purchase(account_id(owner))
        stolen = await client.post(
            URL, headers=headers(other), json={"purchase_token": "fresh-token-0002"}
        )
        assert stolen.status_code == 403  # Play's obfuscated account id is not the caller's


async def test_unknown_products_play_errors_and_missing_setup(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    play.purchases[TOKEN] = purchase(account_id(user), product="someone_else_pro")
    async with admin_api(engine, play) as client:
        res = await client.post(URL, headers=headers(user), json={"purchase_token": TOKEN})
        assert res.status_code == 422
        play.fail = True
        res = await client.post(URL, headers=headers(user), json={"purchase_token": TOKEN})
        assert res.status_code == 502
        assert (await client.post(URL, json={"purchase_token": TOKEN})).status_code == 401
    async with admin_api(engine, None) as client:
        res = await client.post(URL, headers=headers(user), json={"purchase_token": TOKEN})
        assert res.status_code == 503
    async with async_sessionmaker(engine)() as session:
        assert await session.scalar(select(func.count()).select_from(Subscription)) == 0


async def test_an_upgrade_replaces_the_linked_purchase(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    play.purchases[TOKEN] = purchase(account_id(user))
    play.purchases["upgrade-token-01"] = purchase(
        account_id(user), product="bagmitra_trader", linked=TOKEN
    )
    async with admin_api(engine, play) as client:
        await client.post(URL, headers=headers(user), json={"purchase_token": TOKEN})
        res = await client.post(
            URL, headers=headers(user), json={"purchase_token": "upgrade-token-01"}
        )
        plans = res.json()["entitlements"]["plans"]
    assert "role_trader" in plans
    assert "role_grower" not in plans


async def test_a_price_increase_reaches_the_app_for_the_notice(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    change = {
        "newPrice": {"currencyCode": "INR", "units": "149", "nanos": 0},
        "priceChangeMode": "PRICE_INCREASE",
        "priceChangeState": "OUTSTANDING",
        "expectedNewPriceChargeTime": "2026-12-20T00:00:00Z",
    }
    play.purchases[TOKEN] = purchase(account_id(user), price_change=change)
    async with admin_api(engine, play) as client:
        before = (await client.get("/v1/billing/plan", headers=headers(user))).json()
        assert before["price_change"] is None
        assert before["account_id"] == account_id(user)
        await client.post(URL, headers=headers(user), json={"purchase_token": TOKEN})
        after = (await client.get("/v1/billing/plan", headers=headers(user))).json()
    assert after["price_change"] == {
        "state": "OUTSTANDING",
        "new_price_paise": 14900,
        "currency": "INR",
        "charge_time": "2026-12-20T00:00:00Z",
    }


def test_a_purchase_without_line_items_is_rejected() -> None:
    with pytest.raises(PlayError):
        read_purchase({"subscriptionState": "SUBSCRIPTION_STATE_ACTIVE"}, datetime.now(UTC))
