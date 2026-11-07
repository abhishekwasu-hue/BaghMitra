"""Erase everything the server holds about one grower (S-10, `DELETE /v1/me`).

Order, so that a failure never leaves an untracked half:
1. photos in storage (when configured): the caller's folder plus every recorded key. If
   storage fails, nothing else is touched and the call can be repeated;
2. in one transaction: every owner-scoped table (found from the models, so a new table is
   covered automatically), the farmer's entitlement snapshot, and an `account_deletions`
   row that still names the sign-in account as a follow-up;
3. the Supabase sign-in account (when the service role key is set); on success the
   follow-up is cleared, otherwise it stays for the owner.

Market link (Q68, `market_link/erasure.py`): the user's market-link data is hidden at once
(`deferred_erasures` row, published lots withdrawn) and erased by a nightly job after 180 days;
the lot tables are therefore skipped here.

Kept on purpose: the billing ledger (`subscriptions`, `billing_events`), which holds no
personal data beyond the account id and may have to be kept for accounting (owner decision).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass

import structlog
from sqlalchemy import Table, delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.account.auth_admin import AuthAdmin, AuthAdminError
from bagmitra_api.account.models import AccountDeletion
from bagmitra_api.billing.models import EntitlementSnapshot
from bagmitra_api.db.base import Base, utcnow
from bagmitra_api.db.models import ScoutingRecord
from bagmitra_api.market_link.erasure import DEFERRED_TABLES, defer_market_link
from bagmitra_api.market_link.models import MarketLotPhoto
from bagmitra_api.photos.storage import PhotoStorage

log = structlog.get_logger("bagmitra.account")

FOLLOWUP_AUTH = "auth_user"
FOLLOWUP_PHOTOS = "photos"


@dataclass(frozen=True)
class ErasureResult:
    rows_deleted: int
    photos_deleted: int
    sign_in_account_removed: bool


def owner_tables() -> list[tuple[Table, str]]:
    """Every table whose rows belong to one grower, with its owner column."""
    found: list[tuple[Table, str]] = []
    for mapper in Base.registry.mappers:
        column = getattr(mapper.class_, "owner_column", None)
        table = mapper.local_table
        if isinstance(column, str) and isinstance(table, Table):
            found.append((table, column))
    return sorted(found, key=lambda t: t[0].name)


async def _photo_keys(session: AsyncSession, user_id: uuid.UUID) -> list[str]:
    stored = list(
        await session.scalars(
            select(ScoutingRecord.photo_key).where(
                ScoutingRecord.owner_id == user_id, ScoutingRecord.photo_key.is_not(None)
            )
        )
    )
    # Lot photos share the bucket and the `<owner_id>/` folder (market linkage L3).
    stored += await session.scalars(
        select(MarketLotPhoto.photo_key).where(
            MarketLotPhoto.owner_id == user_id, MarketLotPhoto.photo_key.is_not(None)
        )
    )
    return sorted({k for k in stored if k})


async def erase_account(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    storage: PhotoStorage | None,
    auth_admin: AuthAdmin | None,
    market_link_days: int = 180,
) -> ErasureResult:
    """Erase the account. Raises PhotoStorageError (before any row is touched) when storage
    is configured but fails."""
    recorded = await _photo_keys(session, user_id)
    photos = 0
    followups: list[str] = []
    if storage is not None:
        keys = sorted(set(await storage.list_folder(str(user_id))) | set(recorded))
        if keys:
            await storage.delete_objects(keys)
        photos = len(keys)
    elif recorded:
        followups.append(FOLLOWUP_PHOTOS)

    rows = 0
    await defer_market_link(session, user_id, utcnow(), market_link_days)
    for table, column in owner_tables():
        if table.name in DEFERRED_TABLES:
            continue
        result = await session.execute(delete(table).where(table.c[column] == user_id))
        rows += max(result.rowcount or 0, 0)
    snapshots = await session.execute(
        delete(EntitlementSnapshot).where(
            EntitlementSnapshot.subject_type == "farmer",
            EntitlementSnapshot.subject_id == user_id,
        )
    )
    rows += max(snapshots.rowcount or 0, 0)
    tombstone = AccountDeletion(
        id=uuid.uuid4(),
        rows_deleted=rows,
        photos_deleted=photos,
        followup=",".join([FOLLOWUP_AUTH, *followups]),
        followup_user_id=user_id,
    )
    session.add(tombstone)
    await session.commit()

    removed = False
    if auth_admin is not None:
        try:
            await auth_admin.delete_user(user_id)
            removed = True
        except AuthAdminError as exc:
            log.warning("account_auth_delete_failed", reason=str(exc))
    if removed:
        tombstone.followup = ",".join(followups) or None
        if not followups:
            tombstone.followup_user_id = None
        await session.commit()
    log.info(
        "account_erased",
        rows_deleted=rows,
        photos_deleted=photos,
        followup=tombstone.followup,
    )
    return ErasureResult(rows, photos, removed)
