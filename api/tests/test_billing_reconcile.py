"""Daily Play reconciliation (billing addendum §2.4): the Voided Purchases API as a safety net for
missed notifications, and a drift list. Tokens are stored only as hashes (ADR 0008, Q120), so
the job cannot re-ask Play about a token itself: it matches voided tokens by hash and lists rows
whose state should have changed. Google is never called: `FakePlay` and a fake transport."""

from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime, timedelta

import httpx
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.billing.models import BillingEvent, BillingPlan, Subscription
from bagmitra_api.billing.play import GooglePlayPublisher, play_account
from bagmitra_api.billing.purchases import token_hash
from bagmitra_api.billing.reconcile_job import SKIPPED_NOT_SET_UP, run_reconcile
from bagmitra_api.billing.seed import seed_plans
from tests.play_fakes import PACKAGE, FakeGoogle, FakePlay
from tests.test_billing_play import play_settings

NOW = datetime(2026, 11, 8, 4, 0, tzinfo=UTC)


async def add_row(
    engine: AsyncEngine, token: str, state: str, end: datetime, verified: datetime | None = None
) -> uuid.UUID:
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        await seed_plans(session)
        plan = await session.scalar(select(BillingPlan).where(BillingPlan.key == "free"))
        assert plan is not None
        row = Subscription(
            id=uuid.uuid4(),
            subject_type="farmer",
            subject_id=uuid.uuid4(),
            plan_id=plan.id,
            provider="google_play",
            provider_product_id="bagmitra_grower",
            purchase_token_hash=token_hash(token),
            state=state,
            period_start=end - timedelta(days=30),
            period_end=end,
            auto_renew=True,
            last_verified_at=verified,
        )
        session.add(row)
        await session.commit()
        return row.id


async def state_of(engine: AsyncEngine, row_id: uuid.UUID) -> str:
    async with async_sessionmaker(engine)() as session:
        row = await session.get(Subscription, row_id)
        assert row is not None
        return row.state


async def test_without_play_the_job_does_nothing(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        summary = await run_reconcile(session, None, NOW)
    assert summary.skipped_reason == SKIPPED_NOT_SET_UP


async def test_a_voided_purchase_is_revoked_once(engine: AsyncEngine) -> None:
    row = await add_row(engine, "tok-voided", "ACTIVE", NOW + timedelta(days=20))
    other = await add_row(engine, "tok-fine", "ACTIVE", NOW + timedelta(days=20))
    play = FakePlay()
    play.voided = [
        {"purchaseToken": "tok-voided", "orderId": "GPA.1", "voidedTimeMillis": "1762500000000"},
        {"purchaseToken": "tok-not-ours", "orderId": "GPA.2"},
    ]
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        first = await run_reconcile(session, play, NOW)
    async with maker() as session:
        again = await run_reconcile(session, play, NOW)
    assert (first.revoked, again.revoked) == (1, 0)
    assert await state_of(engine, row) == "REVOKED"
    assert await state_of(engine, other) == "ACTIVE"
    assert ("list_voided", (NOW - timedelta(days=30),)) in play.calls
    async with maker() as session:
        count = await session.scalar(
            select(func.count())
            .select_from(BillingEvent)
            .where(BillingEvent.notification_id == "voided:GPA.1")
        )
    assert count == 1


async def test_drift_lists_rows_that_should_have_changed(engine: AsyncEngine) -> None:
    await add_row(engine, "tok-a", "ACTIVE", NOW - timedelta(days=2))  # missed renewal / expiry
    await add_row(  # stuck pending: last verified 4 days ago
        engine, "tok-b", "PENDING", NOW + timedelta(days=26), NOW - timedelta(days=4)
    )
    await add_row(engine, "tok-c", "ACTIVE", NOW + timedelta(days=10))  # fine
    await add_row(engine, "tok-d", "EXPIRED", NOW - timedelta(days=40))  # final, fine
    async with async_sessionmaker(engine)() as session:
        summary = await run_reconcile(session, FakePlay(), NOW)
    assert summary.drift == 2
    assert json.loads(summary.to_json())["drift"] == 2


async def test_the_voided_list_is_paged_and_includes_subscriptions() -> None:
    google = FakeGoogle()
    pages = [
        {"voidedPurchases": [{"purchaseToken": "t1"}], "tokenPagination": {"nextPageToken": "p2"}},
        {"voidedPurchases": [{"purchaseToken": "t2"}]},
    ]
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path.endswith("/purchases/voidedpurchases"):
            seen.append(request)
            return httpx.Response(200, json=pages[len(seen) - 1])
        return google(request)

    settings = play_settings()
    account = play_account(settings)
    assert account is not None
    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        play = GooglePlayPublisher(http, settings=settings, account=account)
        voided = await play.list_voided(NOW - timedelta(days=30))
    assert [v["purchaseToken"] for v in voided] == ["t1", "t2"]
    first, second = seen
    assert (
        first.url.path == f"/androidpublisher/v3/applications/{PACKAGE}/purchases/voidedpurchases"
    )
    assert first.url.params["type"] == "1"
    assert first.url.params["startTime"] == str(int((NOW - timedelta(days=30)).timestamp() * 1000))
    assert second.url.params["token"] == "p2"
