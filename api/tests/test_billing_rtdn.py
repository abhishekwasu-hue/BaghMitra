"""Real-time developer notifications (billing addendum §2.4): Pub/Sub pushes Play's notification
with a Google-signed OIDC token; the server checks it, treats the notification only as a hint,
re-fetches the truth from Play and is idempotent on the Pub/Sub message id. Google is never
called: the signing keys and Play are fakes."""

from __future__ import annotations

import base64
import json
import time
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

import httpx
import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.auth.jwt import JwksKeys
from bagmitra_api.billing.models import BillingEvent, Subscription
from bagmitra_api.billing.play import play_publisher
from bagmitra_api.billing.purchases import account_id, token_hash
from bagmitra_api.billing.rtdn import google_oidc_keys
from bagmitra_api.billing.seed import seed_plans
from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from tests.conftest import make_token
from tests.play_fakes import PACKAGE, FakePlay, purchase
from tests.test_billing_play import play_settings

URL = "/v1/billing/google/rtdn"
AUDIENCE = "https://bagmitra.example.test/v1/billing/google/rtdn"
PUSHER = "rtdn-push@demo.iam.gserviceaccount.com"
TOKEN = "purchase-token-rtdn-1"
_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
_OTHER_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)


def jwk() -> dict[str, Any]:
    raw: dict[str, Any] = json.loads(jwt.algorithms.RSAAlgorithm.to_jwk(_KEY.public_key()))
    return {**raw, "kid": "k1", "alg": "RS256", "use": "sig"}


def oidc(key: rsa.RSAPrivateKey = _KEY, **over: Any) -> dict[str, str]:
    now = int(time.time())
    claims = {
        "iss": "https://accounts.google.com",
        "aud": AUDIENCE,
        "email": PUSHER,
        "email_verified": True,
        "iat": now,
        "exp": now + 600,
        **over,
    }
    token = jwt.encode(claims, key, algorithm="RS256", headers={"kid": "k1"})
    return {"Authorization": f"Bearer {token}"}


def push(note: dict[str, Any], message_id: str = "m-1") -> dict[str, Any]:
    data = base64.b64encode(json.dumps(note).encode()).decode()
    return {"message": {"data": data, "messageId": message_id}, "subscription": "projects/p/s"}


def sub_note(kind: int, token: str = TOKEN, package: str = PACKAGE) -> dict[str, Any]:
    return {
        "version": "1.0",
        "packageName": package,
        "eventTimeMillis": "1762560000000",
        "subscriptionNotification": {
            "version": "1.0",
            "notificationType": kind,
            "purchaseToken": token,
        },
    }


@asynccontextmanager
async def rtdn_api(
    engine: AsyncEngine, play: FakePlay, **over: object
) -> AsyncIterator[httpx.AsyncClient]:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        await seed_plans(session)
        await session.commit()
    values: dict[str, object] = {"play_rtdn_audience": AUDIENCE, "play_rtdn_pusher": PUSHER}
    cfg = play_settings(**(values | over))
    app = create_app(cfg)

    async def fetch() -> dict[str, Any]:
        return {"keys": [jwk()]}

    keys = JwksKeys(fetch)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: cfg
    app.dependency_overrides[play_publisher] = lambda: play
    app.dependency_overrides[google_oidc_keys] = lambda: keys
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        yield client


async def bought(client: httpx.AsyncClient, play: FakePlay, user: uuid.UUID) -> None:
    play.purchases[TOKEN] = purchase(account_id(user), acknowledged=True)
    headers = {"Authorization": f"Bearer {make_token(user)}"}
    res = await client.post(
        "/v1/billing/google/verify", headers=headers, json={"purchase_token": TOKEN}
    )
    assert res.status_code == 200, res.text


async def stored(engine: AsyncEngine) -> Subscription:
    async with async_sessionmaker(engine)() as session:
        row = await session.scalar(
            select(Subscription).where(Subscription.purchase_token_hash == token_hash(TOKEN))
        )
    assert row is not None
    return row


@pytest.mark.parametrize(
    "headers",
    [
        {},
        {"Authorization": "Bearer not-a-jwt"},
        oidc(_OTHER_KEY),  # not signed by Google's key
        oidc(aud="https://elsewhere.example.test"),
        oidc(iss="https://evil.example.test"),
        oidc(email="someone@else.iam.gserviceaccount.com"),
        oidc(email_verified=False),
        oidc(exp=int(time.time()) - 3600),
    ],
)
async def test_a_push_without_a_valid_google_token_is_refused(
    engine: AsyncEngine, headers: dict[str, str]
) -> None:
    play = FakePlay()
    async with rtdn_api(engine, play) as client:
        res = await client.post(URL, headers=headers, json=push(sub_note(2)))
    assert res.status_code == 401
    assert play.calls == []


async def test_not_set_up_answers_503_so_pubsub_retries_later(engine: AsyncEngine) -> None:
    async with rtdn_api(engine, FakePlay(), play_rtdn_audience="") as client:
        res = await client.post(URL, headers=oidc(), json=push(sub_note(2)))
    assert res.status_code == 503


async def test_a_notification_is_a_hint_the_truth_comes_from_play(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    async with rtdn_api(engine, play) as client:
        await bought(client, play, user)
        play.purchases[TOKEN] = purchase(
            account_id(user), state="SUBSCRIPTION_STATE_ON_HOLD", acknowledged=True
        )
        res = await client.post(URL, headers=oidc(), json=push(sub_note(5)))  # ON_HOLD
        assert res.status_code == 204, res.text
        # Pub/Sub delivers at least once: the same message again changes nothing.
        play.purchases[TOKEN] = purchase(account_id(user), acknowledged=True)
        again = await client.post(URL, headers=oidc(), json=push(sub_note(5)))
        assert again.status_code == 204
    assert (await stored(engine)).state == "ON_HOLD"
    async with async_sessionmaker(engine)() as session:
        events = await session.scalar(
            select(func.count())
            .select_from(BillingEvent)
            .where(BillingEvent.notification_id == "rtdn:m-1")
        )
    assert events == 1


async def test_revoked_ends_access_at_once(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    async with rtdn_api(engine, play) as client:
        await bought(client, play, user)
        play.purchases[TOKEN] = purchase(
            account_id(user), state="SUBSCRIPTION_STATE_EXPIRED", acknowledged=True
        )
        res = await client.post(URL, headers=oidc(), json=push(sub_note(12), "m-2"))
        assert res.status_code == 204, res.text
    assert (await stored(engine)).state == "REVOKED"


async def test_a_voided_purchase_is_revoked(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    note = {
        "version": "1.0",
        "packageName": PACKAGE,
        "eventTimeMillis": "1762560000000",
        "voidedPurchaseNotification": {
            "purchaseToken": TOKEN,
            "orderId": "GPA.1234",
            "productType": 1,
            "refundType": 1,
        },
    }
    async with rtdn_api(engine, play) as client:
        await bought(client, play, user)
        res = await client.post(URL, headers=oidc(), json=push(note, "m-3"))
        assert res.status_code == 204, res.text
    assert (await stored(engine)).state == "REVOKED"


@pytest.mark.parametrize(
    "note",
    [
        {"version": "1.0", "packageName": PACKAGE, "testNotification": {"version": "1.0"}},
        sub_note(4, token="token-the-app-never-sent"),  # stored once the app sends it
        sub_note(2, package="com.other.app"),
    ],
)
async def test_notifications_with_nothing_to_do_are_acknowledged(
    engine: AsyncEngine, note: dict[str, Any]
) -> None:
    play = FakePlay()
    play.purchases["token-the-app-never-sent"] = purchase(account_id(uuid.uuid4()))
    async with rtdn_api(engine, play) as client:
        res = await client.post(URL, headers=oidc(), json=push(note))
    assert res.status_code == 204, res.text


async def test_play_down_answers_502_so_pubsub_redelivers(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    play = FakePlay()
    async with rtdn_api(engine, play) as client:
        await bought(client, play, user)
        play.fail = True
        res = await client.post(URL, headers=oidc(), json=push(sub_note(2), "m-4"))
        assert res.status_code == 502
        play.fail = False
        retry = await client.post(URL, headers=oidc(), json=push(sub_note(2), "m-4"))
        assert retry.status_code == 204  # the failed try left no ledger row behind


async def test_an_unreadable_message_is_acknowledged_and_logged(engine: AsyncEngine) -> None:
    """Pub/Sub redelivers anything not 2xx; a message that can never be read would loop."""
    play = FakePlay()
    async with rtdn_api(engine, play) as client:
        bad = {"message": {"data": "!!not base64!!", "messageId": "m-5"}}
        res = await client.post(URL, headers=oidc(), json=bad)
    assert res.status_code == 204
    assert play.calls == []
    async with async_sessionmaker(engine)() as session:
        event = await session.scalar(
            select(BillingEvent).where(BillingEvent.notification_id == "rtdn:m-5")
        )
    assert event is not None
    assert event.event_type == "rtdn_unreadable"
