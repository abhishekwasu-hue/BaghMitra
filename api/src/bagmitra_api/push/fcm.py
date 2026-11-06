"""FCM HTTP v1 push sender (audit BG-01, OPEN_QUESTIONS Q32).

Off until the owner sets both FCM_PROJECT_ID and a service-account key (FCM_SERVICE_ACCOUNT_B64,
the key file base64-encoded, or FCM_SERVICE_ACCOUNT_FILE, a path the API can read). Runbook:
docs/runbooks/push-notifications.md.

Access tokens come from Google's OAuth token endpoint with a self-signed service-account JWT
(RFC 7523, RS256 through pyjwt), so no Google SDK is needed. A token is reused until shortly
before it expires. The private key, the access token and phone tokens never reach the logs;
only FCM status codes and error codes do.

Results: SENT; UNREGISTERED when FCM says the phone token is gone or is not a token of this
project (the caller deletes it from push_devices); PushUnavailableError for everything else
(outage, quota, a bad key, a payload FCM rejects), so the alert stays unsent and the next run
tries again.
"""

from __future__ import annotations

import base64
import binascii
import json
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import httpx
import jwt
import structlog

from bagmitra_api.core.settings import Settings
from bagmitra_api.push.sender import PushMessage, PushUnavailableError, SendResult

log = structlog.get_logger(__name__)

SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
GOOGLE_TOKEN_URI = "https://oauth2.googleapis.com/token"  # noqa: S105  # nosec B105 - a URL
FCM_BASE_URL = "https://fcm.googleapis.com"
# The Android channel the app creates for server alerts (app: features/push).
ANDROID_CHANNEL = "alerts"
ANDROID_ICON = "ic_stat_notify"
_TOKEN_LIFETIME = 3600
_REFRESH_EARLY = 120
# FCM error codes that mean the phone token itself is dead or belongs to another project.
_DEAD_TOKEN_CODES = frozenset({"UNREGISTERED", "SENDER_ID_MISMATCH"})


class FcmConfigError(Exception):
    """FCM is switched on but its settings are unusable; the message never holds key material."""


@dataclass(frozen=True)
class ServiceAccount:
    client_email: str
    private_key: str = field(repr=False)
    token_uri: str = GOOGLE_TOKEN_URI

    @classmethod
    def from_json(cls, raw: str | bytes) -> ServiceAccount:
        try:
            data = json.loads(raw)
        except (ValueError, UnicodeDecodeError) as exc:
            raise FcmConfigError("service account key is not valid JSON") from exc
        if not isinstance(data, dict) or data.get("type") != "service_account":
            raise FcmConfigError("service account key: type must be service_account")
        email, key = data.get("client_email"), data.get("private_key")
        if not isinstance(email, str) or not email or not isinstance(key, str) or not key:
            raise FcmConfigError("service account key: client_email / private_key missing")
        uri = data.get("token_uri") or GOOGLE_TOKEN_URI
        if not isinstance(uri, str) or not uri.startswith("https://"):
            raise FcmConfigError("service account key: token_uri must be https")
        return cls(client_email=email, private_key=key, token_uri=uri)


def load_service_account(settings: Settings) -> ServiceAccount | None:
    """The key from FCM_SERVICE_ACCOUNT_B64 (wins) or FCM_SERVICE_ACCOUNT_FILE; None if neither."""
    encoded = settings.fcm_service_account_b64.get_secret_value().strip()
    if encoded:
        try:
            raw = base64.b64decode(encoded, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise FcmConfigError("FCM_SERVICE_ACCOUNT_B64 is not valid base64") from exc
        return ServiceAccount.from_json(raw)
    path = settings.fcm_service_account_file.strip()
    if not path:
        return None
    try:
        raw_text = Path(path).read_text(encoding="utf-8")
    except OSError as exc:
        raise FcmConfigError("FCM_SERVICE_ACCOUNT_FILE cannot be read") from exc
    return ServiceAccount.from_json(raw_text)


class FcmSender:
    """PushSender over the FCM HTTP v1 API."""

    def __init__(
        self,
        http: httpx.AsyncClient,
        *,
        project_id: str,
        account: ServiceAccount,
        base_url: str = FCM_BASE_URL,
        clock: Callable[[], float] = time.time,
    ) -> None:
        self._http = http
        self._account = account
        self._url = f"{base_url.rstrip('/')}/v1/projects/{project_id}/messages:send"
        self._clock = clock
        self._token: str | None = None
        self._token_expires = 0.0

    async def _access_token(self, *, force: bool = False) -> str:
        now = self._clock()
        if not force and self._token is not None and now < self._token_expires - _REFRESH_EARLY:
            return self._token
        assertion = jwt.encode(
            {
                "iss": self._account.client_email,
                "scope": SCOPE,
                "aud": self._account.token_uri,
                "iat": int(now),
                "exp": int(now) + _TOKEN_LIFETIME,
            },
            self._account.private_key,
            algorithm="RS256",
        )
        try:
            response = await self._http.post(
                self._account.token_uri,
                data={
                    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                    "assertion": assertion,
                },
            )
        except httpx.HTTPError as exc:
            raise PushUnavailableError("FCM token endpoint unreachable") from exc
        if response.status_code != httpx.codes.OK:
            log.warning("fcm_token_failed", status=response.status_code)
            raise PushUnavailableError(f"FCM token endpoint HTTP {response.status_code}")
        try:
            body = response.json()
            token = body["access_token"]
            lifetime = float(body.get("expires_in", _TOKEN_LIFETIME))
        except (ValueError, KeyError, TypeError) as exc:
            raise PushUnavailableError("FCM token endpoint: unexpected answer") from exc
        if not isinstance(token, str) or not token:
            raise PushUnavailableError("FCM token endpoint: unexpected answer")
        self._token, self._token_expires = token, now + lifetime
        return token

    @staticmethod
    def _payload(message: PushMessage) -> dict[str, Any]:
        return {
            "message": {
                "token": message.token,
                "notification": {"title": message.title, "body": message.body},
                "data": dict(message.data),
                "android": {
                    "priority": "high",
                    "notification": {"channel_id": ANDROID_CHANNEL, "icon": ANDROID_ICON},
                },
            }
        }

    async def _post(self, message: PushMessage, token: str) -> httpx.Response:
        try:
            return await self._http.post(
                self._url,
                json=self._payload(message),
                headers={"Authorization": f"Bearer {token}"},
            )
        except httpx.HTTPError as exc:
            raise PushUnavailableError("FCM unreachable") from exc

    async def send(self, message: PushMessage) -> SendResult:
        response = await self._post(message, await self._access_token())
        if response.status_code == httpx.codes.UNAUTHORIZED:  # token revoked early: once more
            response = await self._post(message, await self._access_token(force=True))
        if response.status_code == httpx.codes.OK:
            return SendResult.SENT
        status, code = _error(response)
        if code in _DEAD_TOKEN_CODES or response.status_code == httpx.codes.NOT_FOUND:
            return SendResult.UNREGISTERED
        if status == "INVALID_ARGUMENT" and _names_token(response):
            return SendResult.UNREGISTERED
        log.warning("fcm_send_failed", status=response.status_code, error=code or status)
        raise PushUnavailableError(f"FCM HTTP {response.status_code} {code or status}")


def _error(response: httpx.Response) -> tuple[str, str]:
    """(google.rpc status, FCM error code) of an FCM error answer; empty when absent."""
    try:
        error = response.json().get("error", {})
    except ValueError:
        return "", ""
    if not isinstance(error, dict):
        return "", ""
    status = error.get("status") if isinstance(error.get("status"), str) else ""
    code = ""
    for detail in error.get("details") or []:
        if isinstance(detail, dict) and isinstance(detail.get("errorCode"), str):
            code = detail["errorCode"]
            break
    return str(status), code


def _names_token(response: httpx.Response) -> bool:
    """FCM answers a malformed phone token with INVALID_ARGUMENT on `message.token`."""
    try:
        error = response.json()["error"]
    except (ValueError, KeyError, TypeError):
        return False
    text = str(error.get("message", "")).lower() if isinstance(error, dict) else ""
    if "registration token" in text:
        return True
    details = error.get("details") or [] if isinstance(error, dict) else []
    return any(
        isinstance(v, dict) and v.get("field") == "message.token"
        for d in details
        if isinstance(d, dict)
        for v in d.get("fieldViolations") or []
    )


def fcm_sender(settings: Settings, http: httpx.AsyncClient) -> FcmSender | None:
    """The FCM sender when push is switched on (project id + key), else None (push off).

    Raises FcmConfigError when the settings are present but unusable, so the job fails loudly
    instead of silently sending nothing."""
    if not settings.push_enabled:
        return None
    account = load_service_account(settings)
    if account is None:  # pragma: no cover - push_enabled means a key setting is present
        return None
    return FcmSender(
        http,
        project_id=settings.fcm_project_id.strip(),
        account=account,
        base_url=settings.fcm_base_url,
    )
