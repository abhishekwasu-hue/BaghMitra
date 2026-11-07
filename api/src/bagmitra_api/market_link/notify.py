"""Market-link pushes (L4): the grower hears of a new interest, the trader (and the named
broker) of an acceptance, and the other senders that the lot is closed. Text only: no rate,
no name, no phone in a push (a lock screen is not private).

The messages are built inside the request (tokens and language read before the commit) and
sent after the response by a background task through the existing push module (FCM HTTP v1,
Q32). Without FCM credentials nothing is sent. A token FCM reports as gone is left for the
nightly delivery run to remove.
"""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator, Callable, Iterable
from contextlib import AbstractAsyncContextManager, asynccontextmanager
from typing import Annotated, Literal

import httpx
import structlog
from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Farmer, PushDevice
from bagmitra_api.push.fcm import fcm_sender
from bagmitra_api.push.sender import PushMessage, PushSender, PushUnavailableError

log = structlog.get_logger("bagmitra.market_link.notify")
Kind = Literal["new_interest", "accepted", "closed"]
TEXTS: dict[str, dict[str, tuple[str, str]]] = {
    "new_interest": {
        "mr": ("बागमित्र: नवी ऑफर", "तुमच्या विक्रीच्या मालावर नवी ऑफर आली आहे. ॲपमध्ये तुलना करा."),
        "hi": ("बागमित्र: नया ऑफ़र", "आपके बिक्री के माल पर नया ऑफ़र आया है। ऐप में तुलना करें।"),
        "en": (
            "BagMitra: new offer",
            "A new offer came in on your produce. Compare it in the app.",
        ),
    },
    "accepted": {
        "mr": (
            "बागमित्र: ऑफर स्वीकारली",
            "शेतकऱ्याने ऑफर स्वीकारली. संपर्क ॲपमध्ये पहा; पुढील व्यवहार थेट आपसात ठरवा.",
        ),
        "hi": (
            "बागमित्र: ऑफ़र स्वीकार हुआ",
            "किसान ने ऑफ़र स्वीकार किया। संपर्क ऐप में देखें; आगे का लेन-देन सीधे आपस में तय करें।",
        ),
        "en": (
            "BagMitra: offer accepted",
            "The grower accepted the offer. See the contacts in the app; settle the rest directly.",
        ),
    },
    "closed": {
        "mr": ("बागमित्र: माल बंद", "तुम्ही ऑफर दिलेला माल आता यादीत नाही."),
        "hi": ("बागमित्र: माल बंद", "जिस माल पर आपने ऑफ़र दिया, वह अब सूची में नहीं है।"),
        "en": ("BagMitra: produce closed", "The produce you made an offer on is no longer listed."),
    },
}
PushFactory = Callable[[], AbstractAsyncContextManager[PushSender | None]]


def get_push_factory(settings: Annotated[Settings, Depends(get_settings)]) -> PushFactory:
    """Opens the FCM sender for one background send; None while push is off (tests override)."""

    @asynccontextmanager
    async def _open() -> AsyncIterator[PushSender | None]:
        if not settings.push_enabled:
            yield None
            return
        async with httpx.AsyncClient(timeout=settings.fcm_timeout_seconds) as http:
            yield fcm_sender(settings, http)

    return _open


async def messages(
    session: AsyncSession, kind: Kind, users: Iterable[uuid.UUID], data: dict[str, str]
) -> list[PushMessage]:
    """One message per phone of each user, in that user's app language (English if unknown)."""
    ids = set(users)
    if not ids:
        return []
    lang = dict(
        (await session.execute(select(Farmer.id, Farmer.language).where(Farmer.id.in_(ids))))
        .tuples()
        .all()
    )
    phones = await session.execute(
        select(PushDevice.owner_id, PushDevice.token)
        .where(PushDevice.owner_id.in_(ids))
        .order_by(PushDevice.owner_id, PushDevice.token)
    )
    out: list[PushMessage] = []
    for owner, token in phones.tuples():
        title, body = TEXTS[kind].get(lang.get(owner, "en"), TEXTS[kind]["en"])
        out.append(PushMessage(token=token, title=title, body=body, data={"kind": kind, **data}))
    return out


async def send_all(factory: PushFactory, batch: list[PushMessage]) -> None:
    """Background task: send each message; an outage is logged, never raised."""
    if not batch:
        return
    async with factory() as sender:
        if sender is None:
            return
        for message in batch:
            try:
                await sender.send(message)
            except PushUnavailableError as exc:
                log.warning("market_link_push_failed", reason=str(exc))
