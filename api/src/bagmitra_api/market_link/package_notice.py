"""Season sale package L9b (spec v1.5 §4E): the receipt's contents and the activation push.

The receipt is built from the admin's company profile and is never made while the profile is
empty; the GST line appears only when both GSTIN and GST rate are set. The push tells the
grower the end date only: no amount, price, UPI ID or link (consumption-only, research §7.1).
"""

from __future__ import annotations

from datetime import date, datetime
from zoneinfo import ZoneInfo

from pydantic import BaseModel
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.models import Farmer, PushDevice
from bagmitra_api.market_link.models import MarketLot
from bagmitra_api.market_link.package_models import CompanyProfile, PackageGrant
from bagmitra_api.push.sender import PushMessage, PushSender, PushUnavailableError, SendResult

INDIA = ZoneInfo("Asia/Kolkata")
# A receipt needs at least these company fields.
RECEIPT_FIELDS = ("legal_name", "address")
PUSH_TITLE = {"mr": "बागमित्र", "hi": "बागमित्र", "en": "BagMitra"}
PUSH_BODY = {
    "mr": "तुमचे विक्री पॅकेज {date} पर्यंत चालू आहे.",
    "hi": "आपका बिक्री पैकेज {date} तक चालू है।",
    "en": "Your sale package is active until {date}.",
}


class ReceiptGst(BaseModel):
    """GST included in the amount received (shown only with GSTIN and a rate)."""

    rate_percent: str
    taxable_paise: int
    gst_paise: int


class ReceiptOut(BaseModel):
    receipt_no: str
    issued_on: date
    legal_name: str
    trade_name: str | None
    address: str
    gstin: str | None
    pan: str | None
    grower_name: str | None
    grower_phone: str | None
    # Crop / variety of the lot, or null for "all lots this season".
    lot: str | None
    amount_paise: int
    method: str
    payment_ref: str
    paid_on: date
    valid_from: date
    valid_until: date
    revoked: bool
    gst: ReceiptGst | None


class ReceiptRefusedError(Exception):
    """The company profile lacks a receipt field (named in the message)."""


def india_date(moment: datetime) -> date:
    return moment.astimezone(INDIA).date()


def gst_split(amount_paise: int, rate_bp: int) -> ReceiptGst:
    """The GST inside an amount that includes it: amount = taxable + taxable x rate."""
    taxable = round(amount_paise * 10_000 / (10_000 + rate_bp))
    return ReceiptGst(
        rate_percent=f"{rate_bp / 100:g}",
        taxable_paise=taxable,
        gst_paise=amount_paise - taxable,
    )


async def build_receipt(
    session: AsyncSession, profile: CompanyProfile, grant: PackageGrant
) -> ReceiptOut:
    missing = [f for f in RECEIPT_FIELDS if not getattr(profile, f)]
    if missing:
        raise ReceiptRefusedError("missing: " + ", ".join(missing))
    farmer = await session.get(Farmer, grant.grower_id)
    lot = None if grant.lot_id is None else await session.get(MarketLot, grant.lot_id)
    gst = None
    if profile.gstin and profile.gst_rate_bp:
        gst = gst_split(grant.amount_paise, profile.gst_rate_bp)
    return ReceiptOut(
        receipt_no=grant.receipt_no,
        issued_on=india_date(grant.created_at),
        legal_name=str(profile.legal_name),
        trade_name=profile.trade_name,
        address=str(profile.address),
        gstin=profile.gstin,
        pan=profile.pan,
        grower_name=farmer.display_name if farmer else None,
        grower_phone=farmer.phone if farmer else None,
        lot=None if lot is None else " · ".join(x for x in (lot.crop, lot.variety) if x),
        amount_paise=grant.amount_paise,
        method=grant.method,
        payment_ref=grant.payment_ref,
        paid_on=grant.paid_on,
        valid_from=india_date(grant.activated_at),
        valid_until=india_date(grant.valid_until),
        revoked=grant.revoked_at is not None,
        gst=gst,
    )


async def notify_grant(
    session: AsyncSession, sender: PushSender | None, grant: PackageGrant, now: datetime
) -> bool:
    """Sends "your sale package is active until <date>" to the grower's phones; stamps
    `notified_at` when one phone got it. Never blocks the activation: no sender, no phone or
    an outage just leaves it unsent."""
    if sender is None:
        return False
    farmer = await session.get(Farmer, grant.grower_id)
    lang = farmer.language if farmer and farmer.language in PUSH_BODY else "en"
    until = india_date(grant.valid_until).strftime("%d-%m-%Y")
    tokens = list(
        await session.scalars(
            select(PushDevice.token).where(PushDevice.owner_id == grant.grower_id)
        )
    )
    sent, invalid = 0, []
    for token in tokens:
        message = PushMessage(
            token=token,
            title=PUSH_TITLE[lang],
            body=PUSH_BODY[lang].format(date=until),
            data={"kind": "sale_package", "grant_id": str(grant.id)},
        )
        try:
            result = await sender.send(message)
        except PushUnavailableError:
            continue
        if result is SendResult.UNREGISTERED:
            invalid.append(token)
        else:
            sent += 1
    if invalid:
        await session.execute(delete(PushDevice).where(PushDevice.token.in_(invalid)))
    if sent:
        grant.notified_at = now
    await session.commit()
    return sent > 0
