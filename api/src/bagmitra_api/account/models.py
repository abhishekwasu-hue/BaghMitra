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
