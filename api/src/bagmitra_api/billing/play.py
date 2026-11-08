"""Google Play Developer API adapter (billing addendum §2.4, §7). Runbook:
docs/runbooks/billing-play.md.

Off until the owner sets PLAY_PACKAGE_NAME and PLAY_SERVICE_ACCOUNT_B64 (the service-account key
file, base64; it lives only in the server's secret store). Access tokens come from Google's OAuth
endpoint with a self-signed service-account JWT, as push/fcm.py does. Tests and CI never reach
Google: they pass an httpx transport or a fake `PlayPublisher`.

Prices: the admin's amount is written to the role's monthly base plan for India through
`monetization.subscriptions.patch`; the price Play answers with is what the admin page shows.
`basePlans.migratePrices` moves existing subscribers only when the admin runs it on purpose.
"""

from __future__ import annotations

import base64
import binascii
import time
from collections.abc import AsyncIterator
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Annotated, Any, Protocol
from urllib.parse import quote

import httpx
import jwt
import structlog
from fastapi import Depends

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.push.fcm import FcmConfigError, ServiceAccount

log = structlog.get_logger(__name__)

SCOPE = "https://www.googleapis.com/auth/androidpublisher"
REGION = "IN"
CURRENCY = "INR"
_TOKEN_LIFETIME = 3600
_REFRESH_EARLY = 120
_NANOS_PER_PAISA = 10_000_000


class PlayError(Exception):
    """Play is unreachable or refused; the message never holds key material or tokens."""


@dataclass(frozen=True, slots=True)
class PlayPrice:
    paise: int
    currency: str


class PlayPublisher(Protocol):
    async def set_monthly_price(self, product_id: str, base_plan_id: str, paise: int) -> PlayPrice:
        """Set the base plan's India price; returns the price Play now reports."""
        ...

    async def migrate_prices(
        self, product_id: str, base_plan_id: str, oldest_allowed: datetime
    ) -> None:
        """Move India subscribers on a price older than `oldest_allowed` to the current one."""
        ...

    async def get_subscription(self, token: str) -> dict[str, Any]:
        """`purchases.subscriptionsv2.get`: the truth about one purchase token."""
        ...

    async def acknowledge(self, product_id: str, token: str) -> None:
        """Acknowledge a purchase (Google refunds one left unacknowledged for 3 days)."""
        ...


def money(paise: int) -> dict[str, Any]:
    return {"currencyCode": CURRENCY, "units": str(paise // 100), "nanos": (paise % 100) * 10**7}


def paise_of(price: dict[str, Any]) -> int:
    return int(price.get("units", "0")) * 100 + int(price.get("nanos", 0)) // _NANOS_PER_PAISA


class GooglePlayPublisher:
    def __init__(
        self, http: httpx.AsyncClient, *, settings: Settings, account: ServiceAccount
    ) -> None:
        self._http = http
        self._account = account
        package = quote(settings.play_package_name.strip(), safe="")
        self._base = f"{settings.play_api_base_url.rstrip('/')}/androidpublisher/v3/applications/"
        self._base += package
        self._package = settings.play_package_name.strip()
        self._regions_version = settings.play_regions_version
        self._token: str | None = None
        self._token_expires = 0.0

    async def _access_token(self) -> str:
        now = time.time()
        if self._token is not None and now < self._token_expires - _REFRESH_EARLY:
            return self._token
        claims = {
            "iss": self._account.client_email,
            "scope": SCOPE,
            "aud": self._account.token_uri,
            "iat": int(now),
            "exp": int(now) + _TOKEN_LIFETIME,
        }
        assertion = jwt.encode(claims, self._account.private_key, algorithm="RS256")
        grant = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        body = await self._send(
            "POST", self._account.token_uri, data={"grant_type": grant, "assertion": assertion}
        )
        token = body.get("access_token")
        if not isinstance(token, str) or not token:
            raise PlayError("Play token endpoint: unexpected answer")
        self._token = token
        self._token_expires = now + float(body.get("expires_in", _TOKEN_LIFETIME))
        return token

    async def _send(self, method: str, url: str, **kwargs: Any) -> dict[str, Any]:
        try:
            response = await self._http.request(method, url, **kwargs)
        except httpx.HTTPError as exc:
            raise PlayError("Google Play unreachable") from exc
        if response.status_code != httpx.codes.OK:
            log.warning("play_api_failed", status=response.status_code)
            raise PlayError(f"Google Play HTTP {response.status_code}")
        try:
            data = response.json() if response.content else {}
        except ValueError as exc:
            raise PlayError("Google Play: unexpected answer") from exc
        if not isinstance(data, dict):
            raise PlayError("Google Play: unexpected answer")
        return data

    async def call(self, method: str, path: str, **kwargs: Any) -> dict[str, Any]:
        headers = {"Authorization": f"Bearer {await self._access_token()}"}
        return await self._send(method, self._base + path, headers=headers, **kwargs)

    async def set_monthly_price(self, product_id: str, base_plan_id: str, paise: int) -> PlayPrice:
        path = f"/subscriptions/{quote(product_id, safe='')}"
        subscription = await self.call("GET", path)
        plans = subscription.get("basePlans") or []
        plan = next((p for p in plans if p.get("basePlanId") == base_plan_id), None)
        if plan is None:
            raise PlayError("base plan not found in Play Console")
        configs = plan.setdefault("regionalConfigs", [])
        config = next((c for c in configs if c.get("regionCode") == REGION), None)
        if config is None:
            config = {"regionCode": REGION, "newSubscriberAvailability": True}
            configs.append(config)
        config["price"] = money(paise)
        params = {"updateMask": "basePlans", "regionsVersion.version": self._regions_version}
        saved = await self.call("PATCH", path, params=params, json=subscription)
        return _india_price(saved, base_plan_id)

    async def migrate_prices(
        self, product_id: str, base_plan_id: str, oldest_allowed: datetime
    ) -> None:
        path = (
            f"/subscriptions/{quote(product_id, safe='')}"
            f"/basePlans/{quote(base_plan_id, safe='')}:migratePrices"
        )
        stamp = oldest_allowed.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        body = {
            "packageName": self._package,
            "productId": product_id,
            "basePlanId": base_plan_id,
            "regionalPriceMigrations": [
                {
                    "regionCode": REGION,
                    "oldestAllowedPriceVersionTime": stamp,
                    # Opt-in: Play asks each subscriber; one who does not accept is cancelled.
                    "priceIncreaseType": "PRICE_INCREASE_TYPE_OPT_IN",
                }
            ],
            "regionsVersion": {"version": self._regions_version},
        }
        await self.call("POST", path, json=body)

    async def get_subscription(self, token: str) -> dict[str, Any]:
        return await self.call("GET", f"/purchases/subscriptionsv2/tokens/{quote(token, safe='')}")

    async def acknowledge(self, product_id: str, token: str) -> None:
        path = (
            f"/purchases/subscriptions/{quote(product_id, safe='')}"
            f"/tokens/{quote(token, safe='')}:acknowledge"
        )
        await self.call("POST", path, json={})


def _india_price(subscription: dict[str, Any], base_plan_id: str) -> PlayPrice:
    for plan in subscription.get("basePlans") or []:
        if plan.get("basePlanId") != base_plan_id:
            continue
        for config in plan.get("regionalConfigs") or []:
            if config.get("regionCode") == REGION and isinstance(config.get("price"), dict):
                price = config["price"]
                return PlayPrice(paise_of(price), str(price.get("currencyCode", CURRENCY)))
    raise PlayError("Play did not report an India price")


def play_account(settings: Settings) -> ServiceAccount | None:
    """The service account from PLAY_SERVICE_ACCOUNT_B64; None when Play is not set up."""
    encoded = settings.play_service_account_b64.get_secret_value().strip()
    if not encoded or not settings.play_package_name.strip():
        return None
    try:
        return ServiceAccount.from_json(base64.b64decode(encoded, validate=True))
    except (binascii.Error, ValueError, FcmConfigError) as exc:
        raise PlayError("PLAY_SERVICE_ACCOUNT_B64 is not a usable service-account key") from exc


async def play_publisher(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[PlayPublisher | None]:
    """FastAPI dependency: the Play client, or None while Play is not set up."""
    account = play_account(settings)
    if account is None:
        yield None
        return
    async with httpx.AsyncClient(timeout=settings.play_timeout_seconds) as http:
        yield GooglePlayPublisher(http, settings=settings, account=account)
