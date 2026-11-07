"""The audit trail of account deletions (S-10)."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, utcnow


class AccountDeletion(Base):
    """One erased account: when, how many rows and photos went, and what is left to do.

    It holds no personal data. `followup_user_id` is set only while something still has to be
    finished by hand (`followup`: `auth_user` = the Supabase sign-in account, `photos` = the
    storage folder); the owner clears both once done. Then nothing links the row to a person.
    """

    __tablename__ = "account_deletions"
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    deleted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    rows_deleted: Mapped[int] = mapped_column(Integer)
    photos_deleted: Mapped[int] = mapped_column(Integer)
    followup: Mapped[str | None] = mapped_column(String(64))
    followup_user_id: Mapped[uuid.UUID | None] = mapped_column(index=True)


class DeferredErasure(Base):
    """Market-link data of a deleted account, waiting for erasure (Q68, spec v1.5 §4C): hidden
    from everyone at once, erased by `market_link.erase_job` once `erase_after` has passed
    (IT Rules 2021 retention, 180 days). The row stays with `erased_at` set, so the user
    remains hidden wherever a rating or deal record still names the id (shown without name).
    """

    __tablename__ = "deferred_erasures"
    private_table = True

    user_id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    erase_after: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    erased_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
