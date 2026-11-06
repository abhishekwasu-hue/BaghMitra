"""BG-01: the FCM HTTP v1 sender against a mocked Google (no real server is ever called):
OAuth JWT exchange and token reuse, the message shape, error mapping (dead tokens pruned,
outages retried), settings gating, and that key material never shows up in repr or logs."""

from __future__ import annotations

import base64
import json
import uuid
from collections.abc import Callable
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any

import httpx
import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import Farmer, PlotRiskAlert, PushDevice
from bagmitra_api.feed.alert_job import configured_sender
from bagmitra_api.push.deliver import DeliverySummary, exit_code, run_delivery
from bagmitra_api.push.fcm import (
    SCOPE,
    FcmConfigError,
    FcmSender,
    ServiceAccount,
    fcm_sender,
    load_service_account,
)
from bagmitra_api.push.sender import PushMessage, PushUnavailableError, SendResult

TOKEN_URI = "https://oauth2.example.test/token"
FCM = "https://fcm.example.test"
SEND_URL = f"{FCM}/v1/projects/demo-project/messages:send"
NOW = datetime(2026, 10, 27, 2, 0, tzinfo=UTC)

_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
PRIVATE_PEM = _KEY.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8,
    serialization.NoEncryption(),
).decode()
PUBLIC_PEM = (
    _KEY.public_key()
    .public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)
    .decode()
)


def key_json(**over: Any) -> str:
    data = {
        "type": "service_account",
        "project_id": "demo-project",
        "client_email": "push@demo-project.iam.gserviceaccount.com",
        "private_key": PRIVATE_PEM,
        "token_uri": TOKEN_URI,
        **over,
    }
    return json.dumps(data)


ACCOUNT = ServiceAccount.from_json(key_json())
MESSAGE = PushMessage(token="phone-1", title="T", body="B", data={"plot_id": "p"})


class FakeGoogle:
    """Token endpoint + FCM send endpoint; `answers` queues FCM replies (default 200)."""

    def __init__(self, answers: list[httpx.Response] | None = None) -> None:
        self.answers = answers or []
        self.token_calls = 0
        self.sends: list[dict[str, Any]] = []
        self.auth: list[str] = []
        self.assertions: list[str] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        if str(request.url) == TOKEN_URI:
            form = dict(x.split("=", 1) for x in request.content.decode().split("&"))
            assert form["grant_type"] == "urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer"
            self.assertions.append(form["assertion"])
            self.token_calls += 1
            return httpx.Response(
                200, json={"access_token": f"at-{self.token_calls}", "expires_in": 3599}
            )
        assert str(request.url) == SEND_URL
        self.sends.append(json.loads(request.content))
        self.auth.append(request.headers["Authorization"])
        if self.answers:
            return self.answers.pop(0)
        return httpx.Response(200, json={"name": "projects/demo-project/messages/1"})


def fcm_error(status: int, rpc: str, code: str | None = None, **extra: Any) -> httpx.Response:
    details: list[dict[str, Any]] = []
    if code:
        details.append(
            {"@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError", "errorCode": code}
        )
    details.extend(extra.pop("details", []))
    return httpx.Response(
        status,
        json={
            "error": {
                "code": status,
                "status": rpc,
                "message": extra.get("message", ""),
                "details": details,
            }
        },
    )


def sender(http: httpx.AsyncClient, clock: Callable[[], float] = lambda: 1_000_000.0) -> FcmSender:
    return FcmSender(http, project_id="demo-project", account=ACCOUNT, base_url=FCM, clock=clock)


async def test_sends_a_v1_message_with_a_signed_service_account_jwt() -> None:
    google = FakeGoogle()
    async with httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        assert await sender(http).send(MESSAGE) is SendResult.SENT
    claims = jwt.decode(
        google.assertions[0],
        PUBLIC_PEM,
        algorithms=["RS256"],
        audience=TOKEN_URI,
        options={"verify_exp": False, "verify_iat": False},
    )
    assert claims["iss"] == ACCOUNT.client_email
    assert claims["scope"] == SCOPE
    assert claims["exp"] - claims["iat"] == 3600
    assert google.auth == ["Bearer at-1"]
    assert google.sends == [
        {
            "message": {
                "token": "phone-1",
                "notification": {"title": "T", "body": "B"},
                "data": {"plot_id": "p"},
                "android": {
                    "priority": "high",
                    "notification": {"channel_id": "alerts", "icon": "ic_stat_notify"},
                },
            }
        }
    ]


async def test_access_token_is_reused_until_shortly_before_expiry() -> None:
    google = FakeGoogle()
    now = [1_000_000.0]
    async with httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        s = sender(http, clock=lambda: now[0])
        await s.send(MESSAGE)
        now[0] += 3000
        await s.send(MESSAGE)
        assert google.token_calls == 1
        now[0] += 500  # within the refresh margin of the 3599 s lifetime
        await s.send(MESSAGE)
    assert google.token_calls == 2
    assert google.auth == ["Bearer at-1", "Bearer at-1", "Bearer at-2"]


async def test_a_401_refreshes_the_token_once() -> None:
    google = FakeGoogle([fcm_error(401, "UNAUTHENTICATED")])
    async with httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        assert await sender(http).send(MESSAGE) is SendResult.SENT
    assert google.auth == ["Bearer at-1", "Bearer at-2"]


@pytest.mark.parametrize(
    "answer",
    [
        fcm_error(404, "NOT_FOUND", "UNREGISTERED"),
        fcm_error(404, "NOT_FOUND"),
        fcm_error(403, "PERMISSION_DENIED", "SENDER_ID_MISMATCH"),
        fcm_error(
            400,
            "INVALID_ARGUMENT",
            "INVALID_ARGUMENT",
            message="The registration token is not a valid FCM registration token",
        ),
        fcm_error(
            400,
            "INVALID_ARGUMENT",
            details=[
                {
                    "@type": "type.googleapis.com/google.rpc.BadRequest",
                    "fieldViolations": [{"field": "message.token", "description": "bad"}],
                }
            ],
        ),
    ],
)
async def test_dead_or_foreign_tokens_are_unregistered(answer: httpx.Response) -> None:
    google = FakeGoogle([answer])
    async with httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        assert await sender(http).send(MESSAGE) is SendResult.UNREGISTERED


@pytest.mark.parametrize(
    "answer",
    [
        fcm_error(503, "UNAVAILABLE", "UNAVAILABLE"),
        fcm_error(429, "RESOURCE_EXHAUSTED", "QUOTA_EXCEEDED"),
        fcm_error(500, "INTERNAL", "INTERNAL"),
        fcm_error(400, "INVALID_ARGUMENT", "INVALID_ARGUMENT", message="bad data payload"),
        fcm_error(403, "PERMISSION_DENIED", "THIRD_PARTY_AUTH_ERROR"),
        httpx.Response(502, text="<html>bad gateway</html>"),
        httpx.Response(500, json={"error": "flat"}),
    ],
)
async def test_other_errors_are_an_outage_for_the_next_run(answer: httpx.Response) -> None:
    google = FakeGoogle([answer])
    async with httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        with pytest.raises(PushUnavailableError):
            await sender(http).send(MESSAGE)


async def test_a_second_401_is_an_outage() -> None:
    google = FakeGoogle([fcm_error(401, "UNAUTHENTICATED"), fcm_error(401, "UNAUTHENTICATED")])
    async with httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        with pytest.raises(PushUnavailableError):
            await sender(http).send(MESSAGE)


@pytest.mark.parametrize(
    "token_answer",
    [
        httpx.Response(400, json={"error": "invalid_grant"}),
        httpx.Response(200, text="not json"),
        httpx.Response(200, json={"expires_in": 10}),
        httpx.Response(200, json={"access_token": ""}),
    ],
)
async def test_token_endpoint_failures_are_an_outage(token_answer: httpx.Response) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert str(request.url) == TOKEN_URI
        return token_answer

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        with pytest.raises(PushUnavailableError):
            await sender(http).send(MESSAGE)


@pytest.mark.parametrize("fail_on", [TOKEN_URI, SEND_URL])
async def test_network_errors_are_an_outage(fail_on: str) -> None:
    google = FakeGoogle()

    def handler(request: httpx.Request) -> httpx.Response:
        if str(request.url) == fail_on:
            raise httpx.ConnectError("down", request=request)
        return google(request)

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        with pytest.raises(PushUnavailableError):
            await sender(http).send(MESSAGE)


def test_service_account_json_is_checked() -> None:
    for bad in (
        "{not json",
        "[]",
        key_json(type="authorized_user"),
        key_json(client_email=""),
        key_json(private_key=None),
        key_json(token_uri="http://plain.example"),
    ):
        with pytest.raises(FcmConfigError):
            ServiceAccount.from_json(bad)
    assert ServiceAccount.from_json(key_json(token_uri=None)).token_uri.startswith("https://")
    assert "PRIVATE KEY" not in repr(ACCOUNT)


def settings(**over: Any) -> Settings:
    return Settings(_env_file=None, **over)


def test_push_is_off_unless_project_and_key_are_set(tmp_path: Path) -> None:
    encoded = base64.b64encode(key_json().encode()).decode()
    assert not settings().push_enabled
    assert not settings(fcm_project_id="demo-project").push_enabled
    assert not settings(fcm_service_account_b64=encoded).push_enabled
    assert settings(fcm_project_id="p", fcm_service_account_b64=encoded).push_enabled
    assert settings(fcm_project_id="p", fcm_service_account_file="/x.json").push_enabled
    http = httpx.AsyncClient()
    assert fcm_sender(settings(), http) is None
    assert fcm_sender(settings(fcm_project_id="demo-project"), http) is None
    assert configured_sender(http, settings()) is None
    on = settings(fcm_project_id="demo-project", fcm_service_account_b64=encoded)
    assert isinstance(fcm_sender(on, http), FcmSender)
    assert isinstance(configured_sender(http, on), FcmSender)


def test_key_from_base64_or_file(tmp_path: Path) -> None:
    encoded = base64.b64encode(key_json().encode()).decode()
    assert load_service_account(settings()) is None
    from_b64 = load_service_account(settings(fcm_service_account_b64=f" {encoded}\n"))
    assert from_b64 == ACCOUNT
    path = tmp_path / "key.json"
    path.write_text(key_json())
    assert load_service_account(settings(fcm_service_account_file=str(path))) == ACCOUNT
    with pytest.raises(FcmConfigError, match="base64"):
        load_service_account(settings(fcm_service_account_b64="%%%not-base64"))
    with pytest.raises(FcmConfigError, match="cannot be read"):
        load_service_account(settings(fcm_service_account_file=str(tmp_path / "missing.json")))


def test_key_material_never_reaches_settings_repr_or_errors() -> None:
    encoded = base64.b64encode(key_json().encode()).decode()
    s = settings(fcm_project_id="p", fcm_service_account_b64=encoded)
    assert encoded not in repr(s)
    assert encoded not in str(s.model_dump())
    with pytest.raises(FcmConfigError) as err:
        load_service_account(settings(fcm_service_account_b64=encoded[:-8] + "@@@@@@@@"))
    assert "PRIVATE" not in str(err.value)
    assert encoded[:40] not in str(err.value)


async def test_failure_logs_carry_no_tokens(capsys: pytest.CaptureFixture[str]) -> None:
    google = FakeGoogle([fcm_error(503, "UNAVAILABLE", "UNAVAILABLE")])
    async with httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        with pytest.raises(PushUnavailableError) as err:
            await sender(http).send(MESSAGE)
    out = capsys.readouterr()
    for text in (out.out, out.err, str(err.value)):
        assert "phone-1" not in text
        assert "at-1" not in text
        assert "PRIVATE KEY" not in text


# --- delivery through the real sender, against the database ---


@pytest.fixture
def maker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


async def test_weather_alert_delivery_prunes_dead_tokens_and_stamps_after_a_send(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    owner = uuid.uuid4()
    async with maker() as s:
        s.add(Farmer(id=owner, language="mr", client_updated_at=NOW, last_seq=1))
        s.add_all(PushDevice(owner_id=owner, token=t, platform="android") for t in ("dead", "live"))
        s.add(
            PlotRiskAlert(
                owner_id=owner,
                plot_id=uuid.uuid4(),
                rule_key="heat_fruit_drop",
                first_day=date(2026, 10, 28),
                value=36,
                units=None,
                created_at=NOW,
            )
        )
        await s.commit()

    google = FakeGoogle([fcm_error(404, "NOT_FOUND", "UNREGISTERED")])  # "dead" sorts first
    async with maker() as s, httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        summary = await run_delivery(s, sender(http), NOW)
    assert (summary.notified, summary.messages, summary.invalid_tokens) == (1, 1, 1)
    assert [m["message"]["token"] for m in google.sends] == ["dead", "live"]
    assert google.sends[1]["message"]["notification"]["title"] == "बागमित्र हवामान सूचना"
    async with maker() as s:
        assert list(await s.scalars(select(PushDevice.token))) == ["live"]
        assert (await s.scalar(select(PlotRiskAlert.notified_at))) is not None


async def test_weather_alert_outage_leaves_it_unsent(
    maker: async_sessionmaker[AsyncSession],
) -> None:
    owner = uuid.uuid4()
    async with maker() as s:
        s.add(Farmer(id=owner, language="en", client_updated_at=NOW, last_seq=1))
        s.add(PushDevice(owner_id=owner, token="live", platform="android"))
        s.add(
            PlotRiskAlert(
                owner_id=owner,
                plot_id=uuid.uuid4(),
                rule_key="heat_fruit_drop",
                first_day=date(2026, 10, 28),
                value=36,
                units=None,
                created_at=NOW,
            )
        )
        await s.commit()
    google = FakeGoogle([fcm_error(503, "UNAVAILABLE", "UNAVAILABLE")])
    async with maker() as s, httpx.AsyncClient(transport=httpx.MockTransport(google)) as http:
        summary = await run_delivery(s, sender(http), NOW)
    assert (summary.failed, summary.notified) == (1, 0)
    assert exit_code(summary, reporting=False) == 1
    async with maker() as s:
        assert (await s.scalar(select(PlotRiskAlert.notified_at))) is None
        assert list(await s.scalars(select(PushDevice.token))) == ["live"]


def test_exit_code_is_zero_without_failures() -> None:
    assert exit_code(DeliverySummary(alerts=2, notified=2), reporting=False) == 0
