from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, BigInteger, DateTime, Index, Integer, String, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, utcnow


class SyncMutation(Base):
    """Audit log of every client write received, including stale and rejected ones.

    The autoincrement `seq` doubles as the global, monotonic pull cursor. After
    `sync_payload_retention_days` the retention job (sync/retention.py, LD-09) replaces an
    applied / stale payload with its digest and sets `payload_purged_at`; the row stays.
    """

    __tablename__ = "sync_mutations"
    __table_args__ = (
        UniqueConstraint("owner_id", "client_mutation_id"),
        Index(
            "ix_sync_mutations_unpurged_received_at",
            "received_at",
            postgresql_where=text("payload_purged_at IS NULL"),
            sqlite_where=text("payload_purged_at IS NULL"),
        ),
    )
    owner_column = "owner_id"

    seq: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True
    )
    client_mutation_id: Mapped[uuid.UUID] = mapped_column()
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    entity: Mapped[str] = mapped_column(String(64))
    entity_id: Mapped[str] = mapped_column(String(64))
    op: Mapped[str] = mapped_column(String(16))
    payload: Mapped[dict[str, Any]] = mapped_column(JSON)
    client_updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    status: Mapped[str] = mapped_column(String(16))
    error: Mapped[str | None] = mapped_column(String(64))
    payload_purged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
