"""Reading an agri-input shop bill photo (owner Q136): the photo goes to Claude without its
metadata (never the real API here: an httpx MockTransport answers), the answer is checked on
the server, nothing of the photo or the result is stored (only a count row, erased with the
account), and the limits per farmer are the billing admin's settings, separate from photo
analysis (default 5 a day / 50 a month, India days and months)."""

from __future__ import annotations

import base64
import json
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.account.erase import erase_account, owner_tables
from bagmitra_api.billing.models import BillingRolePrice, BillingSettings
from bagmitra_api.bills.limits import bill_limit_hit, bill_limits_for
from bagmitra_api.bills.models import BillRead
from bagmitra_api.bills.read import (
    MAX_ITEMS,
    AnthropicBillReader,
    answer_schema,
    parse_bill,
    system_prompt,
)
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.photo_ai.limits import day_window, month_window
from bagmitra_api.photo_ai.models import PhotoAnalysisSample
from bagmitra_api.routers.bills import get_bill_reader
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.test_market_link_registration import JPEG
from tests.test_photo_analysis import (
    BILLING_ADMIN,
    ME,
    OTHER_FARMER,
    PNG,
    THEM,
    Claude,
    Storage,
    _role_plan,
    add_samples,
    make_settings,
)
from tests.test_photo_analysis import FARMER as FARMER_ID

URL = "/v1/bills/read"
NOW = datetime(2026, 11, 15, 6, 30, tzinfo=UTC)  # 15 Nov 12:00 IST

BILL: dict[str, Any] = {
    "unsure": False,
    "shop_name": "  Shree Krushi Seva Kendra, Warud ",
    "bill_date": "2026-11-10",
    "bill_no": "A-1452",
    "items": [
        {
            "name": "Confidor",
            "active_ingredient": "Imidacloprid 17.8% SL",
            "quantity": 250,
            "unit": "ml",
            "amount_rs": 480.0,
        },
        {
            "name": "कॉपर ऑक्सीक्लोराईड",
            "active_ingredient": None,
            "quantity": 1,
            "unit": "kg",
            "amount_rs": 620,
        },
    ],
    "total_rs": 1100,
}


def bill(**extra: Any) -> dict[str, Any]:
    return {**BILL, **extra}


def item(name: Any = "Product", **extra: Any) -> dict[str, Any]:
    return {
        "name": name,
        "active_ingredient": None,
        "quantity": None,
        "unit": None,
        "amount_rs": None,
        **extra,
    }


def upload(data: bytes = JPEG, name: str = "bill.jpg", kind: str = "image/jpeg") -> dict[str, Any]:
    return {"files": {"photo": (name, data, kind)}}


@asynccontextmanager
async def api(
    engine: AsyncEngine,
    claude: Claude | None,
    settings: Settings | None = None,
    storage: Storage | None = None,
) -> AsyncIterator[httpx.AsyncClient]:
    cfg = settings or make_settings()
    app = create_app(cfg)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: cfg
    app.dependency_overrides[get_photo_storage] = lambda: storage
    async with httpx.AsyncClient(
        transport=httpx.MockTransport(claude.handler if claude else lambda _: httpx.Response(500))
    ) as http:
        if claude is not None and cfg.photo_ai_key:
            reader = AnthropicBillReader(http, cfg)
            app.dependency_overrides[get_bill_reader] = lambda: reader
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://test"
        ) as client:
            yield client


async def add_reads(
    engine: AsyncEngine, count: int, when: datetime, owner: uuid.UUID = FARMER_ID
) -> None:
    async with async_sessionmaker(engine)() as session:
        for _ in range(count):
            session.add(BillRead(id=uuid.uuid4(), owner_id=owner, created_at=when))
        await session.commit()


async def count_reads(engine: AsyncEngine) -> int:
    async with async_sessionmaker(engine)() as session:
        return int(await session.scalar(select(func.count()).select_from(BillRead)) or 0)


# --- The prompt, the schema and the server checks ------------------------------------------


def test_the_prompt_says_read_only_what_is_printed() -> None:
    prompt = system_prompt()
    assert "Read only what is printed or written on the bill" in prompt
    assert "Never guess" in prompt
    assert "null" in prompt
    assert "exactly as printed" in prompt
    assert "only when it is printed on the bill" in prompt
    assert "ISO date (YYYY-MM-DD)" in prompt
    assert "in rupees as a number" in prompt
    assert "Marathi, Hindi or English" in prompt
    assert '"unsure" to true' in prompt
    assert "not a bill" in prompt


def test_answer_schema_is_strict_without_bounds() -> None:
    schema = answer_schema()
    text = json.dumps(schema)
    for word in ("minimum", "maximum", "maxItems", "minLength", "maxLength", "format"):
        assert word not in text

    def check(node: Any) -> None:
        if isinstance(node, dict):
            if node.get("type") == "object":
                assert node["additionalProperties"] is False
                assert set(node["required"]) == set(node["properties"])
            for value in node.values():
                check(value)
        elif isinstance(node, list):
            for value in node:
                check(value)

    check(schema)
    assert set(schema["properties"]) == {
        "unsure",
        "shop_name",
        "bill_date",
        "bill_no",
        "items",
        "total_rs",
    }


def test_a_clean_bill_is_passed_on_with_trimmed_text() -> None:
    read = parse_bill(BILL, NOW)
    assert read.shop_name == "Shree Krushi Seva Kendra, Warud"
    assert read.bill_date is not None
    assert read.bill_date.isoformat() == "2026-11-10"
    assert read.bill_no == "A-1452"
    assert [i.name for i in read.items] == ["Confidor", "कॉपर ऑक्सीक्लोराईड"]
    assert read.items[0].active_ingredient == "Imidacloprid 17.8% SL"
    assert (read.items[0].quantity, read.items[0].unit, read.items[0].amount_rs) == (
        250.0,
        "ml",
        480.0,
    )
    assert read.items[1].active_ingredient is None
    assert read.total_rs == 1100.0
    assert read.unsure is False


def test_items_without_a_name_are_dropped_and_thirty_kept() -> None:
    raw = [item(None), item("  "), item(7), "not an item", item("A")]
    raw += [item(f"P{n}") for n in range(40)]
    read = parse_bill(bill(items=raw), NOW)
    assert len(read.items) == MAX_ITEMS
    assert read.items[0].name == "A"
    assert read.items[-1].name == f"P{MAX_ITEMS - 2}"
    assert parse_bill(bill(items="x"), NOW).items == []


def test_numbers_must_be_finite_and_not_negative() -> None:
    raw = [
        item("a", quantity=-1, amount_rs=-0.5),
        item("b", quantity=True, amount_rs="480"),
        item("c", quantity=float("inf"), amount_rs=float("nan")),
        item("d", quantity=0, amount_rs=12.3456),
    ]
    read = parse_bill(bill(items=raw, total_rs=-10), NOW)
    assert [(i.quantity, i.amount_rs) for i in read.items] == [
        (None, None),
        (None, None),
        (None, None),
        (0.0, 12.346),
    ]
    assert read.total_rs is None
    assert parse_bill(bill(total_rs="1,100"), NOW).total_rs is None


def test_strings_are_trimmed_to_sensible_lengths() -> None:
    long = "x" * 500
    read = parse_bill(
        bill(
            shop_name=long,
            bill_no=long,
            items=[item(long, active_ingredient=long, unit=long)],
        ),
        NOW,
    )
    assert read.shop_name is not None
    assert len(read.shop_name) == 120
    assert read.bill_no is not None
    assert len(read.bill_no) == 40
    first = read.items[0]
    assert len(first.name) == 120
    assert first.active_ingredient is not None
    assert len(first.active_ingredient) == 160
    assert first.unit is not None
    assert len(first.unit) == 16
    blank = parse_bill(bill(shop_name="   ", bill_no=12), NOW)
    assert (blank.shop_name, blank.bill_no) == (None, None)


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("2026-11-15", "2026-11-15"),  # today in India
        ("2026-11-16", "2026-11-16"),  # one day ahead is allowed
        ("2026-11-17", None),  # more than a day ahead
        ("2025-03-01", "2025-03-01"),
        ("15/11/2026", None),
        ("2026-02-30", None),
        ("2026-11-15T10:00:00", None),
        (20261115, None),
        (None, None),
    ],
)
def test_bill_date_is_iso_and_not_more_than_a_day_ahead(raw: Any, expected: str | None) -> None:
    found = parse_bill(bill(bill_date=raw), NOW).bill_date
    assert (found.isoformat() if found else None) == expected


def test_the_day_ahead_counts_in_india_time() -> None:
    late = datetime(2026, 11, 15, 19, 0, tzinfo=UTC)  # 16 Nov 00:30 IST
    found = parse_bill(bill(bill_date="2026-11-17"), late).bill_date
    assert found is not None
    assert found.isoformat() == "2026-11-17"


def test_a_missing_or_odd_unsure_counts_as_unsure() -> None:
    assert parse_bill({"items": []}, NOW).unsure is True
    assert parse_bill(bill(unsure="no"), NOW).unsure is True
    assert parse_bill(bill(unsure=True), NOW).unsure is True


# --- The endpoint ------------------------------------------------------------------------


async def test_request_shape_image_first_model_fallback_and_schema(engine: AsyncEngine) -> None:
    claude = Claude(BILL)
    async with api(engine, claude) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 200, res.text
    request = claude.requests[0]
    assert str(request.url) == "https://api.anthropic.com/v1/messages"
    assert request.headers["x-api-key"] == "test-anthropic-key"
    assert request.headers["anthropic-version"] == "2026-10-21"
    assert request.headers["anthropic-beta"] == "server-side-fallback-2026-07-01"
    body = claude.body()
    assert body["model"] == "claude-opus-5-5"
    assert body["max_tokens"] == 8000
    assert body["fallbacks"] == "default"
    assert "thinking" not in body
    assert "budget_tokens" not in json.dumps(body)
    assert body["system"] == system_prompt()
    assert body["output_config"] == {"format": {"type": "json_schema", "schema": answer_schema()}}
    content = body["messages"][0]["content"]
    assert [block["type"] for block in content] == ["image", "text"]
    image = content[0]["source"]
    assert image["type"] == "base64"
    assert image["media_type"] == "image/jpeg"
    sent = base64.b64decode(image["data"])  # metadata stripped before it leaves the server
    assert b"GPS" not in sent
    assert sent.startswith(b"\xff\xd8")


async def test_the_farmer_gets_the_bill_and_only_a_count_is_stored(engine: AsyncEngine) -> None:
    storage = Storage()
    async with api(engine, Claude(BILL), storage=storage) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 200, res.text
    assert res.json() == {
        "shop_name": "Shree Krushi Seva Kendra, Warud",
        "bill_date": "2026-11-10",
        "bill_no": "A-1452",
        "items": [
            {
                "name": "Confidor",
                "active_ingredient": "Imidacloprid 17.8% SL",
                "quantity": 250.0,
                "unit": "ml",
                "amount_rs": 480.0,
            },
            {
                "name": "कॉपर ऑक्सीक्लोराईड",
                "active_ingredient": None,
                "quantity": 1.0,
                "unit": "kg",
                "amount_rs": 620.0,
            },
        ],
        "total_rs": 1100.0,
        "unsure": False,
    }
    assert storage.objects == {}  # the photo is not kept
    async with async_sessionmaker(engine)() as session:
        row = (await session.scalars(select(BillRead))).one()
        assert row.owner_id == FARMER_ID
        assert set(BillRead.__table__.columns.keys()) == {"id", "owner_id", "created_at"}
        assert int(await session.scalar(select(func.count()).select_from(PhotoAnalysisSample))) == 0


async def test_a_png_bill_is_sent_as_png_without_its_text_chunks(engine: AsyncEngine) -> None:
    claude = Claude(BILL)
    async with api(engine, claude) as client:
        res = await client.post(URL, headers=ME, **upload(PNG, "bill.png", "image/png"))
    assert res.status_code == 200, res.text
    image = claude.body()["messages"][0]["content"][0]["source"]
    assert image["media_type"] == "image/png"
    sent = base64.b64decode(image["data"])
    assert b"GPS" not in sent


async def test_not_a_bill_is_unsure_and_empty(engine: AsyncEngine) -> None:
    empty: dict[str, Any] = {
        "unsure": True,
        "shop_name": None,
        "bill_date": None,
        "bill_no": None,
        "items": [],
        "total_rs": None,
    }
    async with api(engine, Claude(empty)) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 200
    assert res.json() == empty


async def test_without_an_api_key_the_answer_is_analysis_unavailable(
    engine: AsyncEngine,
) -> None:
    claude = Claude(BILL)
    async with api(engine, claude, make_settings(feed_ai_api_key="")) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 503
    assert res.json()["error"]["code"] == "analysis_unavailable"
    assert claude.requests == []


async def test_the_photo_ai_key_is_used_before_the_feed_key(engine: AsyncEngine) -> None:
    claude = Claude(BILL)
    async with api(engine, claude, make_settings(photo_ai_api_key="photo-key")) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 200
    assert claude.requests[0].headers["x-api-key"] == "photo-key"


async def test_sign_in_is_required(engine: AsyncEngine) -> None:
    claude = Claude(BILL)
    async with api(engine, claude) as client:
        res = await client.post(URL, **upload())
    assert res.status_code == 401
    assert claude.requests == []


async def test_too_large_or_not_an_image_is_refused(engine: AsyncEngine) -> None:
    claude = Claude(BILL)
    async with api(engine, claude, make_settings(photo_max_bytes=len(JPEG) - 1)) as client:
        big = await client.post(URL, headers=ME, **upload())
    async with api(engine, claude) as client:
        gif = await client.post(URL, headers=ME, **upload(b"GIF89a....", "x.gif", "image/gif"))
        broken = await client.post(URL, headers=ME, **upload(b"\xff\xd8\x00\x01"))
    assert big.status_code == 413
    assert big.json()["error"]["code"] == "photo_too_large"
    assert gif.status_code == 415
    assert gif.json()["error"]["code"] == "photo_not_supported"
    assert broken.status_code == 415
    assert claude.requests == []
    assert await count_reads(engine) == 0


@pytest.mark.parametrize(
    "claude",
    [
        Claude(status=500),
        Claude(stop="refusal"),
        Claude(stop="max_tokens"),
        Claude(raw="not json"),
        Claude(raw="[1, 2]"),
    ],
)
async def test_a_failed_read_counts_nothing(engine: AsyncEngine, claude: Claude) -> None:
    async with api(engine, claude) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 502, res.text
    assert res.json()["error"]["code"] == "analysis_failed"
    assert await count_reads(engine) == 0


# --- Limits (admin settings per plan, separate from photo analysis; default 5 / 50) -------


async def test_the_daily_default_of_five_answers_429_with_the_reset(engine: AsyncEngine) -> None:
    claude = Claude(BILL)
    await add_reads(engine, 5, datetime.now(UTC))
    await add_reads(engine, 9, datetime.now(UTC), owner=OTHER_FARMER)  # not counted
    async with api(engine, claude) as client:
        res = await client.post(URL, headers=ME, **upload())
        other = await client.post(URL, headers=THEM, **upload())
    assert res.status_code == 429
    error = res.json()["error"]
    assert error["code"] == "bill_read_limit"
    assert error["details"]["limit"] == "daily"
    assert error["details"]["max"] == "5"
    _, end = day_window(datetime.now(UTC))
    assert error["details"]["resets_at"] == end.strftime("%Y-%m-%dT%H:%M:%SZ")
    assert 0 < int(res.headers["retry-after"]) <= 86400
    assert other.status_code == 429  # the other farmer has read nine today
    assert claude.requests == []


async def test_photo_analysis_does_not_use_up_bill_reads(engine: AsyncEngine) -> None:
    await add_samples(engine, 5, datetime.now(UTC))
    async with api(engine, Claude(BILL)) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 200


async def test_the_monthly_default_of_fifty(engine: AsyncEngine) -> None:
    now = datetime.now(UTC)
    start, end = month_window(now)
    day_start, _ = day_window(now)
    if day_start == start:
        pytest.skip("first IST day of the month: no earlier day this month")
    await add_reads(engine, 50, start + timedelta(minutes=1))
    await add_reads(engine, 7, start - timedelta(minutes=1))  # last month
    async with api(engine, Claude(BILL)) as client:
        res = await client.post(URL, headers=ME, **upload())
    assert res.status_code == 429
    assert res.json()["error"]["details"] == {
        "limit": "monthly",
        "max": "50",
        "resets_at": end.strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


async def test_limit_hit_counts_by_india_day_and_month(engine: AsyncEngine) -> None:
    await add_reads(engine, 4, datetime(2026, 11, 15, 0, 0, tzinfo=UTC))
    await add_reads(engine, 1, datetime(2026, 11, 14, 18, 29, tzinfo=UTC))  # 14 Nov IST
    await add_reads(engine, 1, datetime(2026, 10, 31, 18, 31, tzinfo=UTC))  # 1 Nov IST
    await add_reads(engine, 1, datetime(2026, 10, 31, 18, 29, tzinfo=UTC))  # October
    async with async_sessionmaker(engine)() as session:
        assert await bill_limit_hit(session, FARMER_ID, NOW) is None
    await add_reads(engine, 44, datetime(2026, 11, 10, tzinfo=UTC))
    async with async_sessionmaker(engine)() as session:
        hit = await bill_limit_hit(session, FARMER_ID, NOW)
        assert hit is not None
        assert (hit.kind, hit.limit) == ("monthly", 50)
        assert hit.resets_at == datetime(2026, 11, 30, 18, 30, tzinfo=UTC)
    await add_reads(engine, 1, datetime(2026, 11, 15, 1, 0, tzinfo=UTC))
    async with async_sessionmaker(engine)() as session:
        hit = await bill_limit_hit(session, FARMER_ID, NOW)
        assert hit is not None
        assert (hit.kind, hit.resets_at) == ("daily", datetime(2026, 11, 15, 18, 30, tzinfo=UTC))


async def test_admin_bill_limits_without_a_plan_and_the_optional_overall_cap(
    engine: AsyncEngine,
) -> None:
    async with api(engine, Claude(BILL)) as client:
        before = await client.get("/v1/admin/billing/settings", headers=BILLING_ADMIN)
        assert before.json()["bill_limits"] == {
            "free_daily": None,
            "free_monthly": None,
            "daily_total": None,
            "default_daily": 5,
            "default_monthly": 50,
        }
        assert all(
            (r["bill_read_daily"], r["bill_read_monthly"]) == (None, None)
            for r in before.json()["roles"]
        )
        denied = await client.put("/v1/admin/billing/bill-limits", headers=ME, json={})
        assert denied.status_code == 403
        res = await client.put(
            "/v1/admin/billing/bill-limits",
            headers=BILLING_ADMIN,
            json={"free_daily": 1, "free_monthly": 30, "daily_total": None},
        )
        assert res.status_code == 200, res.text
        assert res.json()["bill_limits"]["free_daily"] == 1
        assert res.json()["photo_limits"]["free_daily"] is None  # photo limits untouched
        first = await client.post(URL, headers=ME, **upload())
        second = await client.post(URL, headers=ME, **upload())
        assert first.status_code == 200
        assert second.status_code == 429
        assert second.json()["error"]["details"]["max"] == "1"
        await client.put(
            "/v1/admin/billing/bill-limits",
            headers=BILLING_ADMIN,
            json={"free_daily": None, "free_monthly": None, "daily_total": 3},
        )
        await add_reads(engine, 2, datetime.now(UTC), owner=OTHER_FARMER)
        third = await client.post(URL, headers=ME, **upload())
        assert third.status_code == 429
        assert third.json()["error"]["details"]["limit"] == "total"
        bad = await client.put(
            "/v1/admin/billing/bill-limits", headers=BILLING_ADMIN, json={"free_daily": -1}
        )
        assert bad.status_code == 422
        events = await client.get("/v1/admin/billing/events", headers=BILLING_ADMIN)
    assert "bill_limits_changed" in {e["event_type"] for e in events.json()["events"]}
    async with async_sessionmaker(engine)() as session:
        row = await session.get(BillingSettings, 1)
        assert row is not None
        assert (row.bill_read_daily_total, row.bill_read_free_daily) == (3, None)
        assert row.photo_ai_daily_total is None


async def test_role_plan_bill_limits_apply_while_the_switch_is_on(engine: AsyncEngine) -> None:
    await _role_plan(engine, switch_on=True)
    await add_reads(engine, 5, datetime.now(UTC))
    async with api(engine, Claude(BILL)) as client:
        res = await client.post(URL, headers=ME, **upload())
        assert res.status_code == 429  # the plan has no value yet: the default 5 a day
        edit = await client.put(
            "/v1/admin/billing/roles/grower/bill-limits",
            headers=BILLING_ADMIN,
            json={"daily": 20, "monthly": 200},
        )
        assert edit.status_code == 200, edit.text
        grower = next(r for r in edit.json()["roles"] if r["role"] == "grower")
        assert (grower["bill_read_daily"], grower["bill_read_monthly"]) == (20, 200)
        assert (grower["photo_ai_daily"], grower["photo_ai_monthly"]) == (None, None)
        res = await client.post(URL, headers=ME, **upload())
        assert res.status_code == 200, res.text
        unknown = await client.put(
            "/v1/admin/billing/roles/farmer/bill-limits",
            headers=BILLING_ADMIN,
            json={"daily": 1},
        )
        assert unknown.status_code == 422
    async with async_sessionmaker(engine)() as session:
        limits = await bill_limits_for(session, FARMER_ID, datetime.now(UTC))
    assert (limits.daily, limits.monthly, limits.source) == (20, 200, "plan")


async def test_switch_off_uses_the_no_plan_bill_limits(engine: AsyncEngine) -> None:
    await _role_plan(engine, switch_on=False)
    async with async_sessionmaker(engine)() as session:
        role = await session.get(BillingRolePrice, "grower")
        assert role is not None
        role.bill_read_daily = 20
        settings = await session.get(BillingSettings, 1)
        assert settings is not None
        settings.bill_read_free_daily = 2
        settings.photo_ai_free_daily = 9  # photo analysis limits do not apply to bills
        await session.commit()
        limits = await bill_limits_for(session, FARMER_ID, datetime.now(UTC))
    assert (limits.daily, limits.monthly, limits.daily_total, limits.source) == (
        2,
        50,
        None,
        "no_plan",
    )


# --- Erasure -----------------------------------------------------------------------------


async def test_account_erasure_includes_the_bill_reads(engine: AsyncEngine) -> None:
    assert "bill_reads" in {t.name for t, _ in owner_tables()}
    await add_reads(engine, 3, datetime.now(UTC))
    await add_reads(engine, 1, datetime.now(UTC), owner=OTHER_FARMER)
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        await erase_account(session, FARMER_ID, storage=Storage(), auth_admin=None)
    async with async_sessionmaker(engine)() as session:
        owners = set(await session.scalars(select(BillRead.owner_id)))
    assert owners == {OTHER_FARMER}
