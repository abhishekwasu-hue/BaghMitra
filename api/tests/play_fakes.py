"""Fakes for the Google Play Developer API. Tests and CI never reach Google: the adapter is
either replaced by `FakePlay` or driven through `FakeGoogle` (an httpx MockTransport that
answers like the documented REST API)."""

from __future__ import annotations

import base64
import json
from datetime import datetime
from typing import Any

import httpx
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

from bagmitra_api.billing.play import PlayError, PlayPrice

TOKEN_URI = "https://oauth2.example.test/token"
PLAY_BASE = "https://play.example.test"
PACKAGE = "in.bagmitra.app"

_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
PRIVATE_PEM = _KEY.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8,
    serialization.NoEncryption(),
).decode()


def account_b64() -> str:
    data = {
        "type": "service_account",
        "client_email": "billing@demo.iam.gserviceaccount.com",
        "private_key": PRIVATE_PEM,
        "token_uri": TOKEN_URI,
    }
    return base64.b64encode(json.dumps(data).encode()).decode()


class FakePlay:
    """A PlayPublisher that records calls; `fail` makes the next call raise PlayError."""

    def __init__(self) -> None:
        self.calls: list[tuple[str, tuple[Any, ...]]] = []
        self.fail = False
        self.purchases = {}
        self.voided: list[dict[str, Any]] = []

    def _record(self, name: str, *args: Any) -> None:
        self.calls.append((name, args))
        if self.fail:
            raise PlayError("Google Play HTTP 500")

    async def set_monthly_price(self, product_id: str, base_plan_id: str, paise: int) -> PlayPrice:
        self._record("set_monthly_price", product_id, base_plan_id, paise)
        return PlayPrice(paise, "INR")

    async def migrate_prices(
        self, product_id: str, base_plan_id: str, oldest_allowed: datetime
    ) -> None:
        self._record("migrate_prices", product_id, base_plan_id, oldest_allowed)

    purchases: dict[str, dict[str, Any]]

    async def get_subscription(self, token: str) -> dict[str, Any]:
        self._record("get_subscription", token)
        return self.purchases[token]

    async def acknowledge(self, product_id: str, token: str) -> None:
        self._record("acknowledge", product_id, token)

    async def list_voided(self, since: datetime) -> list[dict[str, Any]]:
        self._record("list_voided", since)
        return self.voided


def purchase(
    account: str,
    *,
    state: str = "SUBSCRIPTION_STATE_ACTIVE",
    product: str = "bagmitra_grower",
    expiry: str = "2099-01-01T00:00:00Z",
    acknowledged: bool = False,
    linked: str | None = None,
    price_change: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """A `SubscriptionPurchaseV2` as Play's REST API returns it."""
    plan: dict[str, Any] = {"autoRenewEnabled": True}
    if price_change:
        plan["priceChangeDetails"] = price_change
    body: dict[str, Any] = {
        "kind": "androidpublisher#subscriptionPurchaseV2",
        "startTime": "2026-11-01T00:00:00Z",
        "subscriptionState": state,
        "acknowledgementState": "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
        if acknowledged
        else "ACKNOWLEDGEMENT_STATE_PENDING",
        "externalAccountIdentifiers": {"obfuscatedExternalAccountId": account},
        "lineItems": [
            {
                "productId": product,
                "expiryTime": expiry,
                "autoRenewingPlan": plan,
                "offerDetails": {"basePlanId": "monthly"},
            }
        ],
    }
    if linked:
        body["linkedPurchaseToken"] = linked
    return body


class FakeGoogle:
    """Answers the OAuth token endpoint and the androidpublisher v3 REST paths."""

    def __init__(self) -> None:
        self.requests: list[httpx.Request] = []
        self.subscription: dict[str, Any] = {
            "productId": "bagmitra_grower",
            "basePlans": [
                {"basePlanId": "yearly", "regionalConfigs": []},
                {
                    "basePlanId": "monthly",
                    "regionalConfigs": [
                        {
                            "regionCode": "IN",
                            "newSubscriberAvailability": True,
                            "price": {"currencyCode": "INR", "units": "49", "nanos": 0},
                        }
                    ],
                },
            ],
        }
        self.status = 200

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        if str(request.url) == TOKEN_URI:
            return httpx.Response(200, json={"access_token": "tok", "expires_in": 3600})
        if self.status != 200:
            return httpx.Response(self.status, json={"error": {"status": "INTERNAL"}})
        if request.method == "PATCH":
            self.subscription = json.loads(request.content)
            return httpx.Response(200, json=self.subscription)
        if request.method == "GET" and "/subscriptions/" in request.url.path:
            return httpx.Response(200, json=self.subscription)
        return httpx.Response(200, json={})

    def transport(self) -> httpx.MockTransport:
        return httpx.MockTransport(self)
