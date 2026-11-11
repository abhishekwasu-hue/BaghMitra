"""Reading an agri-input shop bill photo (owner 2026-11-11, Q136): the farmer photographs the
bill from the spray-record or Add expense screen and gets back the shop, date, bill number,
product lines and total, to check before saving the record on the phone.

- Consent is the one given at signup through the privacy policy; nothing is asked per photo.
- The photo's metadata (EXIF GPS, phone, time) is stripped before it goes to the model. The
  photo and the result are NOT stored on the server; only a count row (`bill_reads`: id,
  owner, time) for the limits, erased with the account.
- Limits per farmer per India day and month are the billing admin's settings
  (`bills/limits.py`), separate from photo analysis; over a limit the answer is 429
  `bill_read_limit` with which limit and when it resets.
"""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime
from typing import Annotated

import httpx
import structlog
from fastapi import APIRouter, Depends, File, UploadFile
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.bills.limits import bill_limit_hit
from bagmitra_api.bills.models import BillRead
from bagmitra_api.bills.read import AnthropicBillReader, Bill, BillReader
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.ai import AiUnavailableError
from bagmitra_api.routers.photo_analysis import clean_photo

router = APIRouter(prefix="/v1", tags=["bills"])
log = structlog.get_logger("bagmitra.bills")


async def get_bill_reader(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[BillReader | None]:
    """Claude with PHOTO_AI_API_KEY (else FEED_AI_API_KEY); None while neither is set."""
    if not settings.photo_ai_key:
        yield None
        return
    async with httpx.AsyncClient() as http:
        yield AnthropicBillReader(http, settings)


Reader = Annotated[BillReader | None, Depends(get_bill_reader)]


class BillItemOut(BaseModel):
    # The product name as printed on the bill.
    name: str
    # Only when printed on the bill for this line.
    active_ingredient: str | None
    quantity: float | None
    unit: str | None
    amount_rs: float | None


class BillReadOut(BaseModel):
    shop_name: str | None
    # ISO date (YYYY-MM-DD); null when it could not be read or was more than a day ahead.
    bill_date: date | None
    bill_no: str | None
    # At most 30, in the bill's order; every item has a name.
    items: list[BillItemOut]
    total_rs: float | None
    # The photo was unclear, some values could not be read, or it is not a bill.
    unsure: bool


def _out(bill: Bill) -> BillReadOut:
    return BillReadOut(
        shop_name=bill.shop_name,
        bill_date=bill.bill_date,
        bill_no=bill.bill_no,
        items=[
            BillItemOut(
                name=i.name,
                active_ingredient=i.active_ingredient,
                quantity=i.quantity,
                unit=i.unit,
                amount_rs=i.amount_rs,
            )
            for i in bill.items
        ],
        total_rs=bill.total_rs,
        unsure=bill.unsure,
    )


@router.post(
    "/bills/read",
    operation_id="bills_read",
    responses={
        401: {"model": ErrorResponse},
        413: {"model": ErrorResponse},
        415: {"model": ErrorResponse},
        429: {"model": ErrorResponse},
        502: {"model": ErrorResponse},
        503: {"model": ErrorResponse},
    },
)
async def read_bill(
    photo: Annotated[UploadFile, File(description="One JPEG or PNG photo of the bill")],
    user: CurrentUser,
    session: DbSession,
    reader: Reader,
    settings: Annotated[Settings, Depends(get_settings)],
) -> BillReadOut:
    """Reads one agri-input shop bill photo (owner Q136). Nothing of the photo or the result
    is stored; only a count row for the limits.

    429 `bill_read_limit`: `error.details` has `limit` (daily | monthly | total), `max` and
    `resets_at` (UTC); the `Retry-After` header has the seconds until then. 503
    `analysis_unavailable`: no API key on the server. 502 `analysis_failed`: the model could
    not answer; nothing is counted."""
    if reader is None:
        raise ApiError(503, "analysis_unavailable", "bill reading is not set up")
    data = await photo.read(settings.photo_max_bytes + 1)
    if len(data) > settings.photo_max_bytes:
        raise ApiError(413, "photo_too_large", f"at most {settings.photo_max_bytes} bytes")
    media_type, clean = clean_photo(data)
    now = datetime.now(UTC)
    hit = await bill_limit_hit(session, user.id, now)
    if hit is not None:
        seconds = max(1, int((hit.resets_at - now).total_seconds()))
        raise ApiError(
            429,
            "bill_read_limit",
            f"{hit.kind} bill reading limit reached",
            details={
                "limit": hit.kind,
                "max": str(hit.limit),
                "resets_at": hit.resets_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            },
            headers={"Retry-After": str(seconds)},
        )
    try:
        bill = await reader.read(clean, media_type)
    except AiUnavailableError as exc:
        log.warning("bill_read_failed", reason=str(exc))
        raise ApiError(502, "analysis_failed", "the bill could not be read") from exc
    session.add(BillRead(id=uuid.uuid4(), owner_id=user.id, created_at=now))
    await session.commit()
    # No bill content in the log: only how much was read.
    log.info("bill_read", unsure=bill.unsure, items=len(bill.items))
    return _out(bill)
