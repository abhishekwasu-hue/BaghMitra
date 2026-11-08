"""Per-role amounts go to Google Play (billing addendum §7): the adapter's REST contract against a
fake Google, and the admin endpoints against a fake publisher. Google is never called."""

from __future__ import annotations

import json
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime

import httpx
import jwt
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.billing.models import BillingEvent
from bagmitra_api.billing.play import (
    GooglePlayPublisher,
    PlayError,
    PlayPrice,
    money,
    paise_of,
    play_account,
    play_publisher,
)
from bagmitra_api.billing.seed import seed_plans
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET, make_token
from tests.play_fakes import PACKAGE, PLAY_BASE, TOKEN_URI, FakeGoogle, FakePlay, account_b64

ADMIN_ID = uuid.uuid4()
ADMIN = {
    "Authorization": f"Bearer {make_token(ADMIN_ID, app_metadata={'roles': ['billing_admin']})}"
}
BASE = "/v1/admin/billing"


def play_settings(**over: object) -> Settings:
    values: dict[str, object] = {
        "environment": "test",
        "database_url": "sqlite+aiosqlite://",
        "supabase_jwt_secret": JWT_SECRET,
        "play_package_name": PACKAGE,
        "play_service_account_b64": account_b64(),
        "play_api_base_url": PLAY_BASE,
        **over,
    }
    return Settings(**values)  # type: ignore[arg-type]


@pytest.mark.parametrize(("paise", "units", "nanos"), [(9900, "99", 0), (14950, "149", 500000000)])
def test_money_is_whole_units_and_nanos(paise: int, units: str, nanos: int) -> None:
    assert money(paise) == {"currencyCode": "INR", "units": units, "nanos": nanos}
    assert paise_of(money(paise)) == paise


def test_play_is_off_until_package_and_key_are_set() -> None:
    assert play_account(play_settings(play_service_account_b64="")) is None
    assert play_account(play_settings(play_package_name="")) is None
    account = play_account(play_settings())
    assert account is not None
    assert account.client_email == "billing@demo.iam.gserviceaccount.com"
    with pytest.raises(PlayError):
        play_account(play_settings(play_service_account_b64="not base64!"))


async def test_setting_a_price_patches_the_india_monthly_base_plan() -> None:
    google = FakeGoogle()
    settings = play_settings()
    account = play_account(settings)
    assert account is not None
    async with httpx.AsyncClient(transport=google.transport()) as http:
        play = GooglePlayPublisher(http, settings=settings, account=account)
        price = await play.set_monthly_price("bagmitra_grower", "monthly", 9900)
    assert price == PlayPrice(9900, "INR")
    token, get, patch = google.requests
    assert str(token.url) == TOKEN_URI
    assertion = dict(httpx.QueryParams(token.content.decode()))["assertion"]
    claims = jwt.decode(assertion, options={"verify_signature": False})
    assert claims["scope"] == "https://www.googleapis.com/auth/androidpublisher"
    path = f"/androidpublisher/v3/applications/{PACKAGE}/subscriptions/bagmitra_grower"
    assert (get.method, get.url.path) == ("GET", path)
    assert get.headers["Authorization"] == "Bearer tok"
    assert (patch.method, patch.url.path) == ("PATCH", path)
    assert patch.url.params["updateMask"] == "basePlans"
    assert patch.url.params["regionsVersion.version"] == "2022/02"
    plans = {p["basePlanId"]: p for p in json.loads(patch.content)["basePlans"]}
    assert plans["monthly"]["regionalConfigs"][0]["price"] == money(9900)
    assert plans["yearly"]["regionalConfigs"] == []  # other base plans untouched


async def test_migrating_prices_is_an_opt_in_india_migration() -> None:
    google = FakeGoogle()
    settings = play_settings()
    account = play_account(settings)
    assert account is not None
    since = datetime(2026, 11, 7, 10, 0, tzinfo=UTC)
    async with httpx.AsyncClient(transport=google.transport()) as http:
        play = GooglePlayPublisher(http, settings=settings, account=account)
        await play.migrate_prices("bagmitra_trader", "monthly", since)
    call = google.requests[-1]
    assert call.method == "POST"
    assert call.url.path.endswith("/subscriptions/bagmitra_trader/basePlans/monthly:migratePrices")
    body = json.loads(call.content)
    assert body["regionalPriceMigrations"] == [
        {
            "regionCode": "IN",
            "oldestAllowedPriceVersionTime": "2026-11-07T10:00:00Z",
            "priceIncreaseType": "PRICE_INCREASE_TYPE_OPT_IN",
        }
    ]


async def test_play_errors_and_missing_base_plans_raise() -> None:
    google = FakeGoogle()
    settings = play_settings()
    account = play_account(settings)
    assert account is not None
    async with httpx.AsyncClient(transport=google.transport()) as http:
        play = GooglePlayPublisher(http, settings=settings, account=account)
        with pytest.raises(PlayError, match="base plan not found"):
            await play.set_monthly_price("bagmitra_grower", "weekly", 100)
        google.status = 500
        with pytest.raises(PlayError, match="HTTP 500"):
            await play.set_monthly_price("bagmitra_grower", "monthly", 100)


@asynccontextmanager
async def admin_api(engine: AsyncEngine, play: FakePlay | None) -> AsyncIterator[httpx.AsyncClient]:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        await seed_plans(session)
        await session.commit()
    cfg = play_settings()
    app = create_app(cfg)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: cfg
    app.dependency_overrides[play_publisher] = lambda: play
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        yield client


def role(body: dict[str, object], name: str) -> dict[str, object]:
    roles = body["roles"]
    assert isinstance(roles, list)
    found: dict[str, object] = next(r for r in roles if r["role"] == name)
    return found


async def test_saving_an_amount_sets_the_play_price_and_shows_it(engine: AsyncEngine) -> None:
    play = FakePlay()
    async with admin_api(engine, play) as client:
        res = await client.put(
            f"{BASE}/roles/trader/amount", headers=ADMIN, json={"amount_paise": 29900}
        )
        assert res.status_code == 200, res.text
        trader = role(res.json(), "trader")
        assert trader["amount_paise"] == 29900
        assert trader["play_price_paise"] == 29900
        assert trader["play_currency"] == "INR"
        assert play.calls == [("set_monthly_price", ("bagmitra_trader", "monthly", 29900))]
        cleared = await client.put(
            f"{BASE}/roles/trader/amount", headers=ADMIN, json={"amount_paise": None}
        )
        assert role(cleared.json(), "trader")["amount_paise"] is None
        assert len(play.calls) == 1  # clearing (role free again) does not touch Play
    async with async_sessionmaker(engine)() as session:
        rows = list(await session.scalars(select(BillingEvent).order_by(BillingEvent.created_at)))
    assert [r.event_type for r in rows] == ["role_price_changed", "role_price_changed"]
    assert rows[0].payload == {
        "admin_id": str(ADMIN_ID),
        "old": {"role": "trader", "amount_paise": None, "play_price_paise": None},
        "new": {"role": "trader", "amount_paise": 29900, "play_price_paise": 29900},
    }


async def test_nothing_is_saved_when_play_is_missing_or_refuses(engine: AsyncEngine) -> None:
    async with admin_api(engine, None) as client:
        res = await client.put(
            f"{BASE}/roles/grower/amount", headers=ADMIN, json={"amount_paise": 9900}
        )
        assert res.status_code == 503
        assert res.json()["error"]["code"] == "play_not_set_up"
    failing = FakePlay()
    failing.fail = True
    async with admin_api(engine, failing) as client:
        res = await client.put(
            f"{BASE}/roles/grower/amount", headers=ADMIN, json={"amount_paise": 9900}
        )
        assert res.status_code == 502
        settings = (await client.get(f"{BASE}/settings", headers=ADMIN)).json()
    assert role(settings, "grower")["amount_paise"] is None
    async with async_sessionmaker(engine)() as session:
        assert list(await session.scalars(select(BillingEvent))) == []


async def test_amounts_and_roles_are_validated(engine: AsyncEngine) -> None:
    async with admin_api(engine, FakePlay()) as client:
        for body in ({"amount_paise": 0}, {"amount_paise": -5}, {}):
            res = await client.put(f"{BASE}/roles/grower/amount", headers=ADMIN, json=body)
            assert res.status_code == 422
        res = await client.put(
            f"{BASE}/roles/robot/amount", headers=ADMIN, json={"amount_paise": 100}
        )
        assert res.status_code == 422
        grower = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
        res = await client.put(
            f"{BASE}/roles/grower/amount", headers=grower, json={"amount_paise": 100}
        )
        assert res.status_code == 403


async def test_migrating_existing_subscribers_needs_a_confirmed_action(engine: AsyncEngine) -> None:
    play = FakePlay()
    async with admin_api(engine, play) as client:
        url = f"{BASE}/roles/broker/migrate-prices"
        assert (await client.post(url, headers=ADMIN, json={})).status_code == 422
        assert (await client.post(url, headers=ADMIN, json={"confirm": False})).status_code == 422
        early = await client.post(url, headers=ADMIN, json={"confirm": True})
        assert early.status_code == 409  # no Play price yet
        await client.put(f"{BASE}/roles/broker/amount", headers=ADMIN, json={"amount_paise": 100})
        res = await client.post(url, headers=ADMIN, json={"confirm": True})
        assert res.status_code == 200, res.text
    name, args = play.calls[-1]
    assert name == "migrate_prices"
    assert args[:2] == ("bagmitra_broker", "monthly")
    async with async_sessionmaker(engine)() as session:
        event = await session.scalar(
            select(BillingEvent).where(BillingEvent.event_type == "prices_migrated")
        )
    assert event is not None
    assert event.payload["admin_id"] == str(ADMIN_ID)
