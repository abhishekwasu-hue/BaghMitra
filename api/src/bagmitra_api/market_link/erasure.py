"""Account deletion for the market link (Q68, spec v1.5 §4C): hidden at once, erased after
`market_link_erase_after_days` (IT Rules 2021 retention, 180 days).

At `DELETE /v1/me` (`defer_market_link`): a `deferred_erasures` row makes the user hidden
everywhere at once (`visibility.hidden_user_ids`), and their published lots are withdrawn.
The grower's lots and lot photos are not deleted with the other owner tables then: an
interest or an introduction of another person points at them.

Later (`erase_due`, nightly job `market_link.erase_job`): the user's trader / exporter /
broker / provider profiles, verification records and documents, representative uploads about
them, registration GPS fixes, terms acceptances, blocks and reports are deleted, with their
stored photos; a lot without an introduction goes with its photos and interests; a lot with
one stays as part of the other party's record without its photos and text. Kept: ratings
(shown without name), interests and introductions of other people, and the admin action log
(user ids only, no name or phone)."""

from __future__ import annotations

import uuid
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import delete, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.account.models import DeferredErasure
from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    FraudReport,
    MarketDeal,
    MarketLot,
    MarketLotPhoto,
    MarketOffer,
    PartyVerification,
    RegistrationFix,
    RepresentativeUpload,
    ServiceProvider,
    TermsAcceptance,
    UserBlock,
)
from bagmitra_api.photos.storage import PhotoStorage, PhotoStorageError

# Owner-scoped tables kept at deletion time and erased later (account/erase.py skips them).
DEFERRED_TABLES = frozenset({MarketLot.__tablename__, MarketLotPhoto.__tablename__})
# Every market-link row keyed by the user: any of them means there is something to erase.
USER_KEYED: tuple[tuple[type[Any], str], ...] = (
    (BuyerProfile, "user_id"),
    (BrokerProfile, "user_id"),
    (ServiceProvider, "user_id"),
    (MarketLot, "owner_id"),
    (RegistrationFix, "user_id"),
    (TermsAcceptance, "user_id"),
    (UserBlock, "blocker_id"),
    (FraudReport, "reporter_id"),
)
PROFILES: tuple[tuple[str, type[Any]], ...] = (
    ("buyer", BuyerProfile),
    ("broker", BrokerProfile),
    ("provider", ServiceProvider),
)


async def defer_market_link(
    session: AsyncSession, user_id: uuid.UUID, now: datetime, days: int
) -> bool:
    """Hide the user's market-link data at once; True when there was any. No commit."""
    found = False
    for model, column in USER_KEYED:
        if await session.scalar(select(model.id).where(getattr(model, column) == user_id)):
            found = True
            break
    if not found:
        return False
    if await session.get(DeferredErasure, user_id) is None:
        session.add(
            DeferredErasure(
                user_id=user_id, requested_at=now, erase_after=now + timedelta(days=days)
            )
        )
    await session.execute(
        update(MarketLot)
        .where(MarketLot.owner_id == user_id, MarketLot.status == "published")
        .values(status="withdrawn")
    )
    return True


@dataclass
class ErasureSummary:
    erased: int = 0
    # Stored photos to delete but no storage configured: left for the next run.
    waiting_for_storage: int = 0
    # Storage refused a delete: nothing of that account was touched; retried next run.
    failed: int = 0

    def to_dict(self) -> dict[str, int]:
        return asdict(self)


async def _keys(session: AsyncSession, user_id: uuid.UUID, subjects: list[uuid.UUID]) -> set[str]:
    keys: set[str] = set()
    for docs in await session.scalars(
        select(PartyVerification.document_keys).where(PartyVerification.subject_id.in_(subjects))
    ):
        keys |= set(docs or [])
    for stmt in (
        select(ServiceProvider.cert_photo_key).where(ServiceProvider.user_id == user_id),
        select(RepresentativeUpload.photo_key).where(RepresentativeUpload.subject_id.in_(subjects)),
        select(MarketLotPhoto.photo_key).where(MarketLotPhoto.owner_id == user_id),
    ):
        keys |= {k for k in await session.scalars(stmt) if k}
    for photos in await session.scalars(
        select(FraudReport.photo_keys).where(FraudReport.reporter_id == user_id)
    ):
        keys |= set(photos or [])
    return keys


async def _erase_lots(session: AsyncSession, user_id: uuid.UUID) -> None:
    lots = list(await session.scalars(select(MarketLot.id).where(MarketLot.owner_id == user_id)))
    introduced = set(
        await session.scalars(select(MarketDeal.lot_id).where(MarketDeal.lot_id.in_(lots)))
    )
    free = [lot for lot in lots if lot not in introduced]
    await session.execute(delete(MarketLotPhoto).where(MarketLotPhoto.owner_id == user_id))
    await session.execute(delete(MarketOffer).where(MarketOffer.lot_id.in_(free)))
    await session.execute(delete(MarketLot).where(MarketLot.id.in_(free)))
    await session.execute(
        update(MarketLot)
        .where(MarketLot.id.in_(introduced))
        .values(quality=None, village=None, variety=None)
    )


async def erase_user(
    session: AsyncSession, user_id: uuid.UUID, storage: PhotoStorage | None
) -> bool:
    """Erase one user's market-link data (see the module text); False, with nothing
    touched, when stored photos exist but no storage is configured. No commit."""
    subjects: list[uuid.UUID] = []
    for _kind, model in PROFILES:
        subjects += list(await session.scalars(select(model.id).where(model.user_id == user_id)))
    keys = await _keys(session, user_id, subjects)
    if keys:
        if storage is None:
            return False
        await storage.delete_objects(sorted(keys))
    await _erase_lots(session, user_id)
    for stmt in (
        delete(PartyVerification).where(PartyVerification.subject_id.in_(subjects)),
        delete(RepresentativeUpload).where(RepresentativeUpload.subject_id.in_(subjects)),
        delete(RegistrationFix).where(
            or_(RegistrationFix.user_id == user_id, RegistrationFix.subject_id.in_(subjects))
        ),
        *(delete(model).where(model.user_id == user_id) for _kind, model in PROFILES),
        delete(TermsAcceptance).where(TermsAcceptance.user_id == user_id),
        delete(UserBlock).where(
            or_(UserBlock.blocker_id == user_id, UserBlock.blocked_id == user_id)
        ),
        delete(FraudReport).where(FraudReport.reporter_id == user_id),
    ):
        await session.execute(stmt)
    return True


async def erase_due(
    session: AsyncSession, storage: PhotoStorage | None, now: datetime
) -> ErasureSummary:
    """Erase every deferred account whose time has come."""
    summary = ErasureSummary()
    due = list(
        await session.scalars(
            select(DeferredErasure.user_id)
            .where(DeferredErasure.erased_at.is_(None), DeferredErasure.erase_after <= now)
            .order_by(DeferredErasure.erase_after)
        )
    )
    for user_id in due:  # one transaction per account
        try:
            done = await erase_user(session, user_id, storage)
        except PhotoStorageError:
            await session.rollback()
            summary.failed += 1
            continue
        if not done:
            summary.waiting_for_storage += 1
            continue
        await session.execute(
            update(DeferredErasure).where(DeferredErasure.user_id == user_id).values(erased_at=now)
        )
        await session.commit()
        summary.erased += 1
    return summary
