"""Crop photo analysis (owner Q135, stage 2): the farmer's photo of their own plot goes to Claude
(never the real API here: an httpx MockTransport answers), the answer is validated, every
analysed photo is kept as a training sample (photo without metadata in the user's folder,
erased with the account), limits per farmer come from the billing admin's settings
(default 5 a day / 50 a month, IST), and role `kb_admin` exports the labelled samples."""

from __future__ import annotations

import base64
import json
import uuid
import zlib
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.account.erase import erase_account, owner_tables
from bagmitra_api.account.models import AccountDeletion
from bagmitra_api.billing.models import (
    BillingPlan,
    BillingRolePrice,
    BillingSettings,
    Subscription,
)
from bagmitra_api.core.errors import ErrorBody
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Plot
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.photo_ai.analyse import (
    GREENING_LAB_NOTE,
    MAX_SIGN_CHARS,
    MAX_SIGNS,
    AnthropicPhotoAi,
    answer_schema,
    parse_analysis,
    system_prompt,
)
from bagmitra_api.photo_ai.limits import day_window, limit_hit, limits_for, month_window
from bagmitra_api.photo_ai.models import PhotoAnalysisSample
from bagmitra_api.photo_ai.profiles import known_keys, profiles
from bagmitra_api.photo_ai.retention import purge_samples
from bagmitra_api.photos.exif import PNG_SIGNATURE, NotPngError, strip_png_metadata
from bagmitra_api.photos.storage import PhotoStorageError, SignedUrl
from bagmitra_api.routers.photo_analysis import get_photo_analyser
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.conftest import JWT_SECRET, make_token
from tests.test_market_link_registration import JPEG

ROOT = Path(__file__).resolve().parents[2]
APP_CARDS = ROOT / "app/assets/config/practice_cards.json"
FARMER = uuid.uuid4()
OTHER_FARMER = uuid.uuid4()
ME = {"Authorization": f"Bearer {make_token(FARMER)}"}
THEM = {"Authorization": f"Bearer {make_token(OTHER_FARMER)}"}
KB_ADMIN = {
    "Authorization": f"Bearer {make_token(uuid.uuid4(), app_metadata={'roles': ['kb_admin']})}"
}
BILLING_ADMIN = {
    "Authorization": (
        f"Bearer {make_token(uuid.uuid4(), app_metadata={'roles': ['billing_admin']})}"
    )
}
TEXTS = {
    "en": "The leaf shows small raised brown spots with a yellow ring. Open the canker card.",
    "mr": "पानावर पिवळ्या कडेचे लहान उंचवट्याचे तपकिरी ठिपके दिसतात. कँकर कार्ड पाहा.",
    "hi": "पत्ती पर पीले घेरे वाले छोटे उभरे भूरे धब्बे दिखते हैं। कैंकर कार्ड देखें।",
}

SIGNS = {
    "en": ["raised brown spots", "yellow halo"],
    "mr": ["उंचवट्याचे तपकिरी ठिपके", "पिवळी कडा"],
    "hi": ["उभरे भूरे धब्बे", "पीला घेरा"],
}


def answer(candidates: list[Any], *, unsure: bool = False) -> dict[str, Any]:
    return {"unsure": unsure, "candidates": candidates}


def candidate(key: str, confidence: Any, **extra: Any) -> dict[str, Any]:
    return {
        "key": key,
        "confidence": confidence,
        "signs": SIGNS,
        "explanation": TEXTS,
        **extra,
    }


CANKER = answer([candidate("canker", 0.72), candidate("anthracnose", 0.2)])


class Claude:
    """MockTransport for the Messages API: records each request, answers with `reply`."""

    def __init__(
        self,
        reply: dict[str, Any] | None = None,
        *,
        status: int = 200,
        stop: str = "end_turn",
        raw: str | None = None,
    ) -> None:
        self.text = raw if raw is not None else json.dumps(reply if reply is not None else CANKER)
        self.status = status
        self.stop = stop
        self.requests: list[httpx.Request] = []

    def handler(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        body = {
            "id": "msg_test",
            "type": "message",
            "role": "assistant",
            "stop_reason": self.stop,
            "content": [{"type": "text", "text": self.text}],
        }
        return httpx.Response(self.status, json=body)

    def body(self, index: int = -1) -> dict[str, Any]:
        loaded: dict[str, Any] = json.loads(self.requests[index].content)
        return loaded


class Storage:
    def __init__(self) -> None:
        self.objects: dict[str, bytes] = {}
        self.types: dict[str, str] = {}
        self.deleted: list[str] = []
        self.fail = False

    async def put_object(self, key: str, data: bytes, content_type: str) -> None:
        if self.fail:
            raise PhotoStorageError("HTTP 503")
        self.objects[key] = data
        self.types[key] = content_type

    async def signed_upload_url(self, key: str) -> SignedUrl:
        return SignedUrl(f"https://files.test/upload/{key}", 600)

    async def upload_object(self, key: str, data: bytes, content_type: str) -> None:
        await self.put_object(key, data, content_type)

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:
        return SignedUrl(f"https://files.test/{key}", expires_in)

    async def list_folder(self, folder: str) -> list[str]:
        return [k for k in self.objects if k.startswith(f"{folder}/")]

    async def delete_objects(self, keys: list[str]) -> None:
        if self.fail:
            raise PhotoStorageError("HTTP 503")
        self.deleted += keys
        for key in keys:
            self.objects.pop(key, None)


def make_settings(**extra: Any) -> Settings:
    values: dict[str, Any] = {
        "environment": "test",
        "database_url": "sqlite+aiosqlite://",
        "supabase_jwt_secret": JWT_SECRET,
        "log_level": "WARNING",
        "feed_ai_api_key": "test-anthropic-key",
    }
    values.update(extra)
    return Settings(**values)


@asynccontextmanager
async def api(
    engine: AsyncEngine,
    claude: Claude | None,
    storage: Storage | None = None,
    settings: Settings | None = None,
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
            analyser = AnthropicPhotoAi(http, cfg)
            app.dependency_overrides[get_photo_analyser] = lambda: analyser
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://test"
        ) as client:
            yield client


async def add_plot(
    engine: AsyncEngine, owner: uuid.UUID = FARMER, *, deleted: bool = False
) -> uuid.UUID:
    plot_id = uuid.uuid4()
    now = datetime.now(UTC)
    async with async_sessionmaker(engine)() as session:
        session.add(
            Plot(
                id=plot_id,
                owner_id=owner,
                name="Bag 1",
                crop="santra",
                area_sq_m=4000.0,
                client_updated_at=now,
                last_seq=1,
                deleted_at=now if deleted else None,
            )
        )
        await session.commit()
    return plot_id


async def add_samples(
    engine: AsyncEngine, count: int, when: datetime, owner: uuid.UUID = FARMER
) -> None:
    async with async_sessionmaker(engine)() as session:
        for _ in range(count):
            session.add(
                PhotoAnalysisSample(
                    id=uuid.uuid4(),
                    owner_id=owner,
                    plot_id=uuid.uuid4(),
                    model="claude-opus-5-5",
                    candidates=[],
                    unsure=True,
                    created_at=when,
                )
            )
        await session.commit()


def upload(
    data: bytes = JPEG, name: str = "leaf.jpg", kind: str = "image/jpeg", **form: str
) -> dict[str, Any]:
    return {"files": {"photo": (name, data, kind)}, "data": form}


def _chunk(kind: bytes, payload: bytes) -> bytes:
    crc = zlib.crc32(kind + payload).to_bytes(4, "big")
    return len(payload).to_bytes(4, "big") + kind + payload + crc


PNG = (
    PNG_SIGNATURE
    + _chunk(b"IHDR", b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00")
    + _chunk(b"tEXt", b"GPS\x0021.47,78.58")
    + _chunk(b"eXIf", b"MM\x00*GPS")
    + _chunk(b"IDAT", zlib.compress(b"\x00\xff\x00\x00"))
    + _chunk(b"IEND", b"")
)


async def count_samples(engine: AsyncEngine) -> int:
    async with async_sessionmaker(engine)() as session:
        return int(await session.scalar(select(func.count()).select_from(PhotoAnalysisSample)))


# --- The cards ---------------------------------------------------------------------------


def test_seed_matches_the_app_cards() -> None:
    """The model is told what each problem looks like from the checked cards, word for word."""
    if not APP_CARDS.exists():  # the API image is built without the app folder
        pytest.skip("no app folder")
    cards = json.loads(APP_CARDS.read_text("utf-8"))
    expected = []
    for section in cards["sections"]:
        profile = section.get("profile")
        if not profile or profile["kind"] not in ("disease", "pest", "disorder"):
            continue
        if "symptoms" not in profile:
            continue  # the card does not say what it looks like; the model cannot be told
        expected.append(
            (
                section["key"],
                profile["kind"],
                section["labels"],
                profile["symptoms"]["labels"],
                profile["scouting"]["labels"] if "scouting" in profile else None,
            )
        )
    seeded = [(p.key, p.kind, p.labels, p.symptoms, p.scouting) for p in profiles()]
    assert seeded == expected
    for key in ("phytophthora", "canker", "greening", "psylla", "mites", "heat_drop"):
        assert key in known_keys()
    assert known_keys()[-2:] == ("healthy", "other")


def test_the_prompt_carries_every_card_text_and_the_rules() -> None:
    prompt = system_prompt()
    for p in profiles():
        assert f'key="{p.key}"' in prompt
        assert p.symptoms["en"] in prompt
    for rule in ("only from what is visible", "unsure", "PCR", "No chemical", "Calm wording"):
        assert rule in prompt


def test_answer_schema_is_strict_without_bounds() -> None:
    schema = answer_schema()
    text = json.dumps(schema)
    for bound in ("minimum", "maximum", "minItems", "maxItems", "minLength", "maxLength"):
        assert bound not in text

    def walk(node: Any) -> None:
        if isinstance(node, dict):
            if node.get("type") == "object":
                assert node["additionalProperties"] is False
                assert set(node["required"]) == set(node["properties"])
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(schema)
    key_enum = schema["properties"]["candidates"]["items"]["properties"]["key"]["enum"]
    assert key_enum == list(known_keys())


# --- Validation of the model's answer ----------------------------------------------------


def test_unknown_and_repeated_keys_are_dropped_and_three_kept_best_first() -> None:
    result = parse_analysis(
        answer(
            [
                candidate("mites", 0.1),
                candidate("citrus_scab", 0.9),  # not on the cards
                candidate("canker", 1.7),  # clamped to 1
                candidate("canker", 0.5),  # repeated
                candidate("thrips", -0.2),  # clamped to 0
                candidate("anthracnose", 0.4),
                "not an object",
            ]
        )
    )
    assert [c.key for c in result.candidates] == ["canker", "anthracnose", "mites"]
    assert [c.confidence for c in result.candidates] == [1.0, 0.4, 0.1]
    assert result.unsure is False


def test_no_usable_candidate_means_unsure() -> None:
    assert parse_analysis(answer([candidate("citrus_scab", 0.9)])).unsure is True
    assert parse_analysis({"candidates": "x"}).unsure is True
    assert parse_analysis(answer([candidate("canker", 0.3)], unsure=True)).unsure is True
    weird = parse_analysis(answer([candidate("canker", "high", signs="spots")]))
    assert weird.candidates[0].confidence == 0.0
    assert weird.candidates[0].signs == {"en": [], "mr": [], "hi": []}


def test_signs_per_language_keep_the_limits_and_a_plain_list_is_english() -> None:
    long = "x" * (MAX_SIGN_CHARS + 50)
    many = [f"sign {i}" for i in range(MAX_SIGNS + 3)]
    result = parse_analysis(
        answer([candidate("canker", 0.6, signs={"en": many, "mr": [long, " ", 7], "hi": "x"})])
    )
    signs = result.candidates[0].signs
    assert signs["en"] == many[:MAX_SIGNS]
    assert signs["mr"] == ["x" * MAX_SIGN_CHARS]
    assert signs["hi"] == []
    plain = parse_analysis(answer([candidate("canker", 0.6, signs=["  yellow halo ", ""])]))
    assert plain.candidates[0].signs == {"en": ["yellow halo"], "mr": [], "hi": []}
    assert parse_analysis(answer([candidate("canker", 0.6)])).candidates[0].signs == SIGNS


def test_greening_always_says_a_lab_pcr_test_confirms_it() -> None:
    plain = {"en": "Yellow mottled leaves.", "mr": "पिवळी पाने.", "hi": "पीली पत्तियाँ।"}
    result = parse_analysis(answer([candidate("greening", 0.4, explanation=plain)]))
    explanation = result.candidates[0].explanation
    for lang, note in GREENING_LAB_NOTE.items():
        assert explanation[lang].endswith(note)
    already = {lang: f"{text} PCR" for lang, text in plain.items()}
    again = parse_analysis(answer([candidate("greening", 0.4, explanation=already)]))
    assert again.candidates[0].explanation == already


def test_png_metadata_is_stripped() -> None:
    clean = strip_png_metadata(PNG)
    assert b"tEXt" not in clean
    assert b"eXIf" not in clean
    assert b"GPS" not in clean
    assert b"IHDR" in clean
    assert clean.endswith(_chunk(b"IEND", b""))
    with pytest.raises(NotPngError):
        strip_png_metadata(b"not a png")
    with pytest.raises(NotPngError):
        strip_png_metadata(PNG[:-6])


# --- The endpoint ------------------------------------------------------------------------


async def test_request_shape_image_first_model_fallback_and_schema(engine: AsyncEngine) -> None:
    claude = Claude()
    plot = await add_plot(engine)
    async with api(engine, claude, Storage()) as client:
        res = await client.post(
            f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload(part="leaf")
        )
    assert res.status_code == 200, res.text
    request = claude.requests[0]
    assert str(request.url) == "https://api.anthropic.com/v1/messages"
    assert request.headers["x-api-key"] == "test-anthropic-key"
    assert request.headers["anthropic-version"] == "2026-10-21"
    assert request.headers["anthropic-beta"] == "server-side-fallback-2026-07-01"
    body = claude.body()
    assert body["model"] == "claude-opus-5-5"
    assert body["fallbacks"] == "default"
    assert "thinking" not in body
    assert "budget_tokens" not in json.dumps(body)
    assert body["output_config"] == {"format": {"type": "json_schema", "schema": answer_schema()}}
    content = body["messages"][0]["content"]
    assert [block["type"] for block in content] == ["image", "text"]
    image = content[0]["source"]
    assert image["type"] == "base64"
    assert image["media_type"] == "image/jpeg"
    sent = base64.b64decode(image["data"])  # metadata stripped before it leaves the server
    assert b"GPS" not in sent
    assert sent.startswith(b"\xff\xd8")
    assert "leaf" in content[1]["text"]


async def test_the_farmer_gets_named_candidates_and_the_sample_is_stored(
    engine: AsyncEngine,
) -> None:
    storage = Storage()
    plot = await add_plot(engine)
    async with api(engine, Claude(), storage) as client:
        res = await client.post(
            f"/v1/plots/{plot}/photo-analysis",
            headers=ME,
            **upload(part="fruit", scouting_item="fruit_drop"),
        )
    assert res.status_code == 200, res.text
    out = res.json()
    assert out["unsure"] is False
    assert [c["key"] for c in out["candidates"]] == ["canker", "anthracnose"]
    first = out["candidates"][0]
    assert first["name"]["mr"]
    assert first["name"]["en"].lower().startswith("canker")
    assert first["confidence"] == 0.72
    assert first["signs"] == SIGNS
    assert first["explanation"] == TEXTS
    photo_id = uuid.UUID(out["photo_id"])
    async with async_sessionmaker(engine)() as session:
        row = await session.get(PhotoAnalysisSample, photo_id)
    assert row is not None
    assert row.owner_id == FARMER
    assert row.plot_id == plot
    assert row.part == "fruit"
    assert row.scouting_item == "fruit_drop"
    assert row.model == "claude-opus-5-5"
    assert row.unsure is False
    assert row.candidates[0]["key"] == "canker"
    assert row.candidates[0]["signs"] == SIGNS
    assert row.label is None
    assert row.photo_key == f"{FARMER}/analysis-{photo_id}.jpg"
    stored = storage.objects[row.photo_key]
    assert b"GPS" not in stored
    assert storage.types[row.photo_key] == "image/jpeg"


async def test_a_png_photo_is_sent_and_stored_as_png(engine: AsyncEngine) -> None:
    storage, claude = Storage(), Claude()
    plot = await add_plot(engine)
    async with api(engine, claude, storage) as client:
        res = await client.post(
            f"/v1/plots/{plot}/photo-analysis",
            headers=ME,
            **upload(PNG, "leaf.png", "image/png"),
        )
    assert res.status_code == 200, res.text
    assert claude.body()["messages"][0]["content"][0]["source"]["media_type"] == "image/png"
    (key,) = storage.objects
    assert key.endswith(".png")
    assert b"tEXt" not in storage.objects[key]


async def test_unsure_answer_is_passed_on_and_kept(engine: AsyncEngine) -> None:
    plot = await add_plot(engine)
    blurred = answer([candidate("mites", 0.3), candidate("thrips", 0.28)], unsure=True)
    async with api(engine, Claude(blurred), None) as client:
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    assert res.status_code == 200
    assert res.json()["unsure"] is True
    async with async_sessionmaker(engine)() as session:
        row = (await session.scalars(select(PhotoAnalysisSample))).one()
    assert row.unsure is True
    assert row.photo_key is None  # photo storage off: the result is still kept


async def test_without_an_api_key_the_answer_is_analysis_unavailable(
    engine: AsyncEngine,
) -> None:
    plot = await add_plot(engine)
    claude = Claude()
    async with api(engine, claude, None, make_settings(feed_ai_api_key="")) as client:
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    assert res.status_code == 503
    assert res.json()["error"]["code"] == "analysis_unavailable"
    assert claude.requests == []


async def test_photo_ai_key_falls_back_to_the_feed_key() -> None:
    assert make_settings().photo_ai_key == "test-anthropic-key"
    assert make_settings(photo_ai_api_key="photo-key").photo_ai_key == "photo-key"
    assert make_settings(feed_ai_api_key="").photo_ai_key == ""


async def test_another_farmers_plot_or_a_deleted_plot_is_not_found(engine: AsyncEngine) -> None:
    claude = Claude()
    mine = await add_plot(engine)
    gone = await add_plot(engine, deleted=True)
    async with api(engine, claude, Storage()) as client:
        theirs = await client.post(f"/v1/plots/{mine}/photo-analysis", headers=THEM, **upload())
        deleted = await client.post(f"/v1/plots/{gone}/photo-analysis", headers=ME, **upload())
        anonymous = await client.post(f"/v1/plots/{mine}/photo-analysis", **upload())
    assert theirs.status_code == 404
    assert theirs.json()["error"]["code"] == "plot_not_found"
    assert deleted.status_code == 404
    assert anonymous.status_code == 401
    assert claude.requests == []


async def test_too_large_or_not_an_image_is_refused(engine: AsyncEngine) -> None:
    plot = await add_plot(engine)
    claude = Claude()
    async with api(engine, claude, None, make_settings(photo_max_bytes=len(JPEG) - 1)) as client:
        big = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    async with api(engine, claude, None) as client:
        text = await client.post(
            f"/v1/plots/{plot}/photo-analysis",
            headers=ME,
            **upload(b"GIF89a....", "x.gif", "image/gif"),
        )
        broken = await client.post(
            f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload(b"\xff\xd8\x00\x01")
        )
        bad_part = await client.post(
            f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload(part="root")
        )
    assert big.status_code == 413
    assert big.json()["error"]["code"] == "photo_too_large"
    assert text.status_code == 415
    assert text.json()["error"]["code"] == "photo_not_supported"
    assert broken.status_code == 415
    assert bad_part.status_code == 422
    assert claude.requests == []


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
async def test_a_failed_analysis_stores_and_counts_nothing(
    engine: AsyncEngine, claude: Claude
) -> None:
    plot = await add_plot(engine)
    storage = Storage()
    async with api(engine, claude, storage) as client:
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    assert res.status_code == 502, res.text
    assert res.json()["error"]["code"] == "analysis_failed"
    assert await count_samples(engine) == 0
    assert storage.objects == {}


async def test_a_storage_failure_still_answers_and_keeps_the_result(engine: AsyncEngine) -> None:
    plot = await add_plot(engine)
    storage = Storage()
    storage.fail = True
    async with api(engine, Claude(), storage) as client:
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    assert res.status_code == 200
    async with async_sessionmaker(engine)() as session:
        row = (await session.scalars(select(PhotoAnalysisSample))).one()
    assert row.photo_key is None


# --- Limits (owner 2026-11-11: admin settings per plan; default 5 a day, 50 a month) ------


def test_windows_are_india_calendar_day_and_month() -> None:
    now = datetime(2026, 11, 30, 20, 0, tzinfo=UTC)  # 1 December 01:30 IST
    start, end = day_window(now)
    assert start == datetime(2026, 11, 30, 18, 30, tzinfo=UTC)
    assert end == datetime(2026, 12, 1, 18, 30, tzinfo=UTC)
    m_start, m_end = month_window(now)
    assert m_start == datetime(2026, 11, 30, 18, 30, tzinfo=UTC)
    assert m_end == datetime(2026, 12, 31, 18, 30, tzinfo=UTC)
    dec = month_window(datetime(2026, 12, 15, tzinfo=UTC))
    assert dec[1] == datetime(2026, 12, 31, 18, 30, tzinfo=UTC)


async def test_the_daily_default_of_five_answers_429_with_the_reset(engine: AsyncEngine) -> None:
    plot = await add_plot(engine)
    claude = Claude()
    await add_samples(engine, 5, datetime.now(UTC))
    await add_samples(engine, 9, datetime.now(UTC), owner=OTHER_FARMER)  # not counted
    async with api(engine, claude, None) as client:
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    assert res.status_code == 429
    error = res.json()["error"]
    assert error["code"] == "analysis_limit"
    assert error["details"]["limit"] == "daily"
    assert error["details"]["max"] == "5"
    _, end = day_window(datetime.now(UTC))
    assert error["details"]["resets_at"] == end.strftime("%Y-%m-%dT%H:%M:%SZ")
    assert 0 < int(res.headers["retry-after"]) <= 86400
    assert claude.requests == []


async def test_the_monthly_default_of_fifty(engine: AsyncEngine) -> None:
    plot = await add_plot(engine)
    now = datetime.now(UTC)
    start, end = month_window(now)
    day_start, _ = day_window(now)
    if day_start == start:
        pytest.skip("first IST day of the month: no earlier day this month")
    await add_samples(engine, 50, start + timedelta(minutes=1))
    await add_samples(engine, 7, start - timedelta(minutes=1))  # last month
    async with api(engine, Claude(), None) as client:
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    assert res.status_code == 429
    details = res.json()["error"]["details"]
    assert details == {
        "limit": "monthly",
        "max": "50",
        "resets_at": end.strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


async def test_limit_hit_counts_by_india_day_and_month(engine: AsyncEngine) -> None:
    """Fixed clock: 15 Nov 12:00 IST. 4 today + 46 earlier this month = 50 (monthly hit);
    a photo at 23:59 IST on 14 Nov is yesterday, one at 00:01 IST on 1 Nov is this month."""
    now = datetime(2026, 11, 15, 6, 30, tzinfo=UTC)
    await add_samples(engine, 4, datetime(2026, 11, 15, 0, 0, tzinfo=UTC))
    await add_samples(engine, 1, datetime(2026, 11, 14, 18, 29, tzinfo=UTC))
    await add_samples(engine, 1, datetime(2026, 10, 31, 18, 31, tzinfo=UTC))
    await add_samples(engine, 1, datetime(2026, 10, 31, 18, 29, tzinfo=UTC))  # October
    async with async_sessionmaker(engine)() as session:
        assert await limit_hit(session, FARMER, now) is None
    await add_samples(engine, 44, datetime(2026, 11, 10, tzinfo=UTC))
    async with async_sessionmaker(engine)() as session:
        hit = await limit_hit(session, FARMER, now)
        assert hit is not None
        assert (hit.kind, hit.limit) == ("monthly", 50)
        assert hit.resets_at == datetime(2026, 11, 30, 18, 30, tzinfo=UTC)
    await add_samples(engine, 1, datetime(2026, 11, 15, 1, 0, tzinfo=UTC))
    async with async_sessionmaker(engine)() as session:
        hit = await limit_hit(session, FARMER, now)
        assert hit is not None
        assert (hit.kind, hit.resets_at) == ("daily", datetime(2026, 11, 15, 18, 30, tzinfo=UTC))


async def test_admin_limits_without_a_plan_and_the_optional_overall_cap(
    engine: AsyncEngine,
) -> None:
    plot = await add_plot(engine)
    async with api(engine, Claude(), None) as client:
        before = await client.get("/v1/admin/billing/settings", headers=BILLING_ADMIN)
        assert before.json()["photo_limits"] == {
            "free_daily": None,
            "free_monthly": None,
            "daily_total": None,
            "default_daily": 5,
            "default_monthly": 50,
        }
        denied = await client.put(
            "/v1/admin/billing/photo-limits", headers=ME, json={"free_daily": 1}
        )
        assert denied.status_code == 403
        res = await client.put(
            "/v1/admin/billing/photo-limits",
            headers=BILLING_ADMIN,
            json={"free_daily": 1, "free_monthly": 30, "daily_total": None},
        )
        assert res.status_code == 200, res.text
        assert res.json()["photo_limits"]["free_daily"] == 1
        first = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
        second = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
        assert first.status_code == 200
        assert second.status_code == 429
        assert second.json()["error"]["details"]["max"] == "1"
        # The overall cap: all farmers together.
        await client.put(
            "/v1/admin/billing/photo-limits",
            headers=BILLING_ADMIN,
            json={"free_daily": None, "free_monthly": None, "daily_total": 3},
        )
        await add_samples(engine, 2, datetime.now(UTC), owner=OTHER_FARMER)
        third = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
        assert third.status_code == 429
        assert third.json()["error"]["details"]["limit"] == "total"
        bad = await client.put(
            "/v1/admin/billing/photo-limits", headers=BILLING_ADMIN, json={"free_daily": -1}
        )
        assert bad.status_code == 422
    async with async_sessionmaker(engine)() as session:
        row = await session.get(BillingSettings, 1)
        assert row is not None
        assert row.photo_ai_daily_total == 3
        assert row.photo_ai_free_daily is None


async def _role_plan(engine: AsyncEngine, *, switch_on: bool) -> None:
    now = datetime.now(UTC)
    async with async_sessionmaker(engine)() as session:
        plan = BillingPlan(
            id=uuid.uuid4(), key="role_grower", names={"en": "Grower"}, kind="grower"
        )
        session.add(plan)
        session.add(BillingPlan(id=uuid.uuid4(), key="free", names={"en": "Free"}, kind="grower"))
        await session.flush()
        session.add(
            Subscription(
                id=uuid.uuid4(),
                subject_type="farmer",
                subject_id=FARMER,
                plan_id=plan.id,
                provider="manual_grant",
                state="ACTIVE",
                period_start=now - timedelta(days=1),
                period_end=now + timedelta(days=30),
            )
        )
        session.add(BillingSettings(id=1, enabled=switch_on, starts_on=None))
        session.add(BillingRolePrice(role="grower", amount_paise=9900))
        await session.commit()


async def test_role_plan_limits_apply_while_the_switch_is_on(engine: AsyncEngine) -> None:
    await _role_plan(engine, switch_on=True)
    plot = await add_plot(engine)
    await add_samples(engine, 5, datetime.now(UTC))
    async with api(engine, Claude(), None) as client:
        # The plan has no value yet: the default 5 a day applies.
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
        assert res.status_code == 429
        edit = await client.put(
            "/v1/admin/billing/roles/grower/photo-limits",
            headers=BILLING_ADMIN,
            json={"daily": 20, "monthly": 200},
        )
        assert edit.status_code == 200, edit.text
        grower = next(r for r in edit.json()["roles"] if r["role"] == "grower")
        assert (grower["photo_ai_daily"], grower["photo_ai_monthly"]) == (20, 200)
        res = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
        assert res.status_code == 200, res.text
        unknown = await client.put(
            "/v1/admin/billing/roles/farmer/photo-limits",
            headers=BILLING_ADMIN,
            json={"daily": 1},
        )
        assert unknown.status_code == 422
    async with async_sessionmaker(engine)() as session:
        limits = await limits_for(session, FARMER, datetime.now(UTC))
        assert (limits.daily, limits.monthly, limits.source) == (20, 200, "plan")


async def test_switch_off_uses_the_no_plan_limits(engine: AsyncEngine) -> None:
    await _role_plan(engine, switch_on=False)
    async with async_sessionmaker(engine)() as session:
        role = await session.get(BillingRolePrice, "grower")
        assert role is not None
        role.photo_ai_daily = 20
        settings = await session.get(BillingSettings, 1)
        assert settings is not None
        settings.photo_ai_free_daily = 2
        await session.commit()
        limits = await limits_for(session, FARMER, datetime.now(UTC))
    assert (limits.daily, limits.monthly, limits.daily_total, limits.source) == (
        2,
        50,
        None,
        "no_plan",
    )


async def test_switch_starting_later_is_not_in_force_yet(engine: AsyncEngine) -> None:
    await _role_plan(engine, switch_on=True)
    async with async_sessionmaker(engine)() as session:
        settings = await session.get(BillingSettings, 1)
        assert settings is not None
        settings.starts_on = date.today() + timedelta(days=10)
        await session.commit()
        limits = await limits_for(session, FARMER, datetime.now(UTC))
    assert limits.source == "no_plan"


# --- Deletion, erasure, retention ---------------------------------------------------------


async def test_the_farmer_deletes_an_analysed_photo(engine: AsyncEngine) -> None:
    storage = Storage()
    plot = await add_plot(engine)
    async with api(engine, Claude(), storage) as client:
        made = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
        photo_id = made.json()["photo_id"]
        theirs = await client.delete(f"/v1/photo-analysis/{photo_id}", headers=THEM)
        storage.fail = True
        failing = await client.delete(f"/v1/photo-analysis/{photo_id}", headers=ME)
        storage.fail = False
        mine = await client.delete(f"/v1/photo-analysis/{photo_id}", headers=ME)
        again = await client.delete(f"/v1/photo-analysis/{photo_id}", headers=ME)
    assert theirs.status_code == 404
    assert failing.status_code == 502
    assert mine.status_code == 204
    assert again.status_code == 404
    assert storage.objects == {}
    assert await count_samples(engine) == 0


async def test_account_erasure_includes_the_samples_and_their_photos(
    engine: AsyncEngine,
) -> None:
    assert "photo_analysis_samples" in {t.name for t, _ in owner_tables()}
    storage = Storage()
    plot = await add_plot(engine)
    async with api(engine, Claude(), storage) as client:
        made = await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())
    key = f"{FARMER}/analysis-{made.json()['photo_id']}.jpg"
    await add_samples(engine, 1, datetime.now(UTC), owner=OTHER_FARMER)
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        await erase_account(session, FARMER, storage=storage, auth_admin=None)
    assert key in storage.deleted
    async with async_sessionmaker(engine)() as session:
        owners = set(await session.scalars(select(PhotoAnalysisSample.owner_id)))
    assert owners == {OTHER_FARMER}


async def test_account_erasure_without_storage_leaves_a_photo_followup(
    engine: AsyncEngine,
) -> None:
    async with async_sessionmaker(engine)() as session:
        session.add(
            PhotoAnalysisSample(
                id=uuid.uuid4(),
                owner_id=FARMER,
                plot_id=uuid.uuid4(),
                model="m",
                candidates=[],
                unsure=True,
                photo_key=f"{FARMER}/analysis-x.jpg",
            )
        )
        await session.commit()
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        await erase_account(session, FARMER, storage=None, auth_admin=None)
    async with async_sessionmaker(engine)() as session:
        tombstone = (await session.scalars(select(AccountDeletion))).one()
    assert tombstone.followup is not None
    assert "photos" in tombstone.followup


async def test_retention_deletes_old_samples_and_their_photos(engine: AsyncEngine) -> None:
    now = datetime.now(UTC)
    storage = Storage()
    old_id, new_id = uuid.uuid4(), uuid.uuid4()
    async with async_sessionmaker(engine)() as session:
        for sample_id, when in ((old_id, now - timedelta(days=731)), (new_id, now)):
            key = f"{FARMER}/analysis-{sample_id}.jpg"
            storage.objects[key] = b"x"
            session.add(
                PhotoAnalysisSample(
                    id=sample_id,
                    owner_id=FARMER,
                    plot_id=uuid.uuid4(),
                    model="m",
                    candidates=[],
                    unsure=True,
                    photo_key=key,
                    created_at=when,
                )
            )
        await session.commit()
    async with async_sessionmaker(engine)() as session:
        storage.fail = True
        waiting = await purge_samples(session, storage, now, 730)
        storage.fail = False
        assert (waiting.deleted, waiting.waiting_for_storage) == (0, 1)
        summary = await purge_samples(session, storage, now, 730)
        assert (summary.deleted, summary.photos_deleted) == (1, 1)
        assert json.loads(summary.to_json())["deleted"] == 1
        nothing = await purge_samples(session, None, now, 730)
        assert nothing.deleted == 0
    assert list(storage.objects) == [f"{FARMER}/analysis-{new_id}.jpg"]
    async with async_sessionmaker(engine)() as session:
        assert list(await session.scalars(select(PhotoAnalysisSample.id))) == [new_id]


# --- Admin training export -----------------------------------------------------------------


async def test_kb_admin_labels_samples_and_exports_the_labelled_ones(engine: AsyncEngine) -> None:
    storage = Storage()
    plot = await add_plot(engine)
    async with api(engine, Claude(), storage) as client:
        ids = [
            (await client.post(f"/v1/plots/{plot}/photo-analysis", headers=ME, **upload())).json()[
                "photo_id"
            ]
            for _ in range(2)
        ]
        empty = await client.get("/v1/admin/photo-analysis/samples", headers=KB_ADMIN)
        denied = await client.get("/v1/admin/photo-analysis/samples", headers=ME)
        bad = await client.put(
            f"/v1/admin/photo-analysis/samples/{ids[0]}/label",
            headers=KB_ADMIN,
            json={"label": "citrus_scab"},
        )
        missing = await client.put(
            f"/v1/admin/photo-analysis/samples/{uuid.uuid4()}/label",
            headers=KB_ADMIN,
            json={"label": "canker"},
        )
        labelled = await client.put(
            f"/v1/admin/photo-analysis/samples/{ids[0]}/label",
            headers=KB_ADMIN,
            json={"label": "canker", "source": "expert"},
        )
        export = await client.get("/v1/admin/photo-analysis/samples", headers=KB_ADMIN)
        todo = await client.get(
            "/v1/admin/photo-analysis/samples", headers=KB_ADMIN, params={"labelled": "false"}
        )
    assert empty.json() == {"samples": []}
    assert denied.status_code == 403
    assert bad.status_code == 422
    assert bad.json()["error"]["code"] == "unknown_label"
    assert missing.status_code == 404
    assert labelled.status_code == 200
    (sample,) = export.json()["samples"]
    assert sample["id"] == ids[0]
    assert sample["label"] == "canker"
    assert sample["label_source"] == "expert"
    assert sample["photo_url"] == f"https://files.test/{FARMER}/analysis-{ids[0]}.jpg"
    assert sample["candidates"][0]["key"] == "canker"
    assert "owner_id" not in sample
    assert [s["id"] for s in todo.json()["samples"]] == [ids[1]]


async def test_the_export_reads_old_samples_with_english_only_signs(engine: AsyncEngine) -> None:
    """Rows stored before the languages hold `signs` as a plain list: read as English."""
    async with async_sessionmaker(engine)() as session:
        session.add(
            PhotoAnalysisSample(
                id=uuid.uuid4(),
                owner_id=FARMER,
                plot_id=uuid.uuid4(),
                model="claude-opus-5-5",
                candidates=[
                    {
                        "key": "canker",
                        "confidence": 0.7,
                        "signs": ["yellow halo"],
                        "explanation": TEXTS,
                    },
                    {"key": "mites", "confidence": 0.2, "explanation": TEXTS},
                ],
                unsure=False,
                label="canker",
                label_source="expert",
            )
        )
        await session.commit()
    async with api(engine, Claude(), Storage()) as client:
        res = await client.get("/v1/admin/photo-analysis/samples", headers=KB_ADMIN)
    assert res.status_code == 200, res.text
    (sample,) = res.json()["samples"]
    assert [c["signs"] for c in sample["candidates"]] == [
        {"en": ["yellow halo"], "mr": [], "hi": []},
        {"en": [], "mr": [], "hi": []},
    ]


def test_other_error_bodies_carry_no_details_key() -> None:
    """The envelope gained `details` for `analysis_limit`; every other error stays as it was."""
    assert ErrorBody(code="x", message="y", request_id="z").model_dump(exclude_none=True) == {
        "code": "x",
        "message": "y",
        "request_id": "z",
    }
