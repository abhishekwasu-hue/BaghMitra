"""Season sale package L9b (spec v1.5 §4E): receipt contents (never with an empty profile; GST
line only with GSTIN and rate), the grower's own status (dates only) and the activation push
(end date only, no amount, price, UPI ID or link)."""

from __future__ import annotations

import re
import uuid
from typing import Any

import pytest
from sqlalchemy import select

from bagmitra_api.db.models import PushDevice
from bagmitra_api.market_link.package_models import PackageGrant
from bagmitra_api.market_link.package_notice import gst_split
from bagmitra_api.push.sender import PushMessage, PushUnavailableError, SendResult
from bagmitra_api.routers.admin_package import get_push_sender
from tests.test_market_lots_sync import headers
from tests.test_package import ADMIN, PKG, grant, ready
from tests.test_package_rules import pkg, published

__all__ = ["pkg"]
PRICE_WORDS = re.compile(r"₹|rs\.?\s|rupee|amount|price|upi|@|pay|qr|http|1500|150000", re.I)


class FakeSender:
    def __init__(self, result: SendResult | None = SendResult.SENT) -> None:
        self.result = result
        self.sent: list[PushMessage] = []

    async def send(self, message: PushMessage) -> SendResult:
        if self.result is None:
            raise PushUnavailableError
        self.sent.append(message)
        return self.result


def use_sender(c: Any, sender: FakeSender | None) -> None:
    c._transport.app.dependency_overrides[get_push_sender] = lambda: sender


async def phone(c: Any, owner: uuid.UUID, token: str = "tok-1") -> None:  # noqa: S107
    async with c.maker() as s:
        s.add(PushDevice(owner_id=owner, token=token, platform="android"))
        await s.commit()


async def test_receipt_never_with_an_empty_profile(pkg: Any) -> None:
    await ready(pkg)
    grower, _ = await published(pkg)
    g = (await grant(pkg, grower, "UTR100020003000")).json()
    url = f"{PKG}/grants/{g['id']}/receipt"
    r = await pkg.get(url, headers=ADMIN)
    assert r.status_code == 200, r.text
    body = r.json()
    assert (body["receipt_no"], body["grower_name"]) == ("BM/26-27/00001", "Ramesh Patil")
    assert (body["amount_paise"], body["payment_ref"], body["lot"]) == (
        150_000,
        "UTR100020003000",
        None,
    )
    assert body["gst"] is None  # no GST rate yet
    await pkg.put(f"{PKG}/company-profile", json={"legal_name": ""}, headers=ADMIN)
    r = await pkg.get(url, headers=ADMIN)
    assert (r.status_code, r.json()["error"]["code"]) == (409, "company_profile_empty")
    assert r.json()["error"]["message"] == "missing: legal_name"
    assert (await pkg.get(f"{PKG}/grants/{uuid.uuid4()}/receipt", headers=ADMIN)).status_code == 404


async def test_gst_line_only_with_gstin_and_rate(pkg: Any) -> None:
    await ready(pkg)
    grower, lot_id = await published(pkg)
    g = (await grant(pkg, grower, "UTR555566667777", lot_id)).json()
    url = f"{PKG}/grants/{g['id']}/receipt"
    await pkg.put(f"{PKG}/company-profile", json={"gst_rate_percent": "18"}, headers=ADMIN)
    body = (await pkg.get(url, headers=ADMIN)).json()
    assert body["gst"] == {"rate_percent": "18", "taxable_paise": 127_119, "gst_paise": 22_881}
    assert body["lot"] == "santra · nagpur"
    # No GSTIN (switch OFF, so it may be cleared): no GST line even with a rate.
    await pkg.put(f"{PKG}/company-profile", json={"gstin": ""}, headers=ADMIN)
    assert (await pkg.get(url, headers=ADMIN)).json()["gst"] is None


@pytest.mark.parametrize(
    ("amount", "bp", "taxable"), [(150_000, 1800, 127_119), (100_000, 500, 95_238), (1, 1800, 1)]
)
def test_gst_split_adds_up(amount: int, bp: int, taxable: int) -> None:
    gst = gst_split(amount, bp)
    assert gst.taxable_paise == taxable
    assert gst.taxable_paise + gst.gst_paise == amount


async def test_grower_status_is_dates_only(pkg: Any) -> None:
    await ready(pkg)
    grower, lot_id = await published(pkg)
    url = "/v1/market-link/package"
    assert (await pkg.get(url, headers=headers(grower))).json() == {
        "switch_on": False,
        "active": [],
    }
    await ready(pkg, enabled=True)
    g = (await grant(pkg, grower, "UTR909090909090", lot_id)).json()
    r = await pkg.get(url, headers=headers(grower))
    [cover] = r.json()["active"]
    assert set(r.json()) == {"switch_on", "active"}
    assert set(cover) == {"lot_id", "valid_until"}
    assert cover["lot_id"] == str(lot_id)
    assert not PRICE_WORDS.search(r.text)
    # Another grower sees nothing of it; a revoked grant is gone.
    assert (await pkg.get(url, headers=headers(uuid.uuid4()))).json()["active"] == []
    await pkg.post(f"{PKG}/grants/{g['id']}/revoke", json={"reason": "bounced"}, headers=ADMIN)
    assert (await pkg.get(url, headers=headers(grower))).json()["active"] == []


async def test_activation_push_names_the_end_date_only(pkg: Any) -> None:
    sender = FakeSender()
    use_sender(pkg, sender)
    await ready(pkg)
    grower, _ = await published(pkg)
    await phone(pkg, grower)
    g = (await grant(pkg, grower, "UTR121212121212")).json()
    [msg] = sender.sent
    assert msg.token == "tok-1"
    assert msg.title == "बागमित्र"  # the grower's language (mr)
    assert msg.body == "तुमचे विक्री पॅकेज 04-01-2027 पर्यंत चालू आहे."
    assert not PRICE_WORDS.search(f"{msg.title} {msg.body} {msg.data}")
    async with pkg.maker() as s:
        row = await s.get(PackageGrant, uuid.UUID(g["id"]))
        assert row is not None
        assert row.notified_at is not None


@pytest.mark.parametrize("result", [None, SendResult.UNREGISTERED])
async def test_push_failure_never_blocks_the_activation(pkg: Any, result: Any) -> None:
    use_sender(pkg, FakeSender(result))
    await ready(pkg)
    grower, _ = await published(pkg)
    await phone(pkg, grower, "tok-old")
    r = await grant(pkg, grower, "UTR343434343434")
    assert r.status_code == 201
    async with pkg.maker() as s:
        row = await s.get(PackageGrant, uuid.UUID(r.json()["id"]))
        assert row is not None
        assert row.notified_at is None
        tokens = list(await s.scalars(select(PushDevice.token)))
    assert tokens == ([] if result else ["tok-old"])


async def test_no_sender_no_push(pkg: Any) -> None:
    use_sender(pkg, None)
    await ready(pkg)
    grower, _ = await published(pkg)
    assert (await grant(pkg, grower, "UTR565656565656")).status_code == 201
