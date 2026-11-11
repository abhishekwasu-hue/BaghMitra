"""Bill reads (Q136): one row per successful read, only to count the farmer's limits. The bill
photo and what was read from it are not stored on the server. Owner data (RLS); erased with the
account like every `owner_column` table."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, utcnow


class BillRead(Base):
    __tablename__ = "bill_reads"
    owner_column = "owner_id"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
