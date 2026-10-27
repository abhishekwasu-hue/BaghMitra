"""Phones that receive push alerts: one row per FCM registration token."""

from __future__ import annotations

import uuid

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin


class PushDevice(TimestampMixin, Base):
    """A phone's push token, owned by the account signed in on it. Owner data (RLS).

    A token belongs to one phone, so it is unique: when another account signs in on the
    same phone the row moves to that account.
    """

    __tablename__ = "push_devices"
    owner_column = "owner_id"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    token: Mapped[str] = mapped_column(String(512), unique=True)
    platform: Mapped[str] = mapped_column(String(16))
