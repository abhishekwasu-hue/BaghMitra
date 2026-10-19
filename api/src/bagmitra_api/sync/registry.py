"""Entities that clients may write through the outbox.

Each handler declares its payload schema and how to apply / serialise a row. Adding a
synced entity means registering a handler here — the push/pull mechanics stay unchanged.
Most entities are owner-scoped rows and reuse [OwnedEntityHandler].
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Literal, Protocol

from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser
from bagmitra_api.db.base import OwnedSyncedRowMixin
from bagmitra_api.db.models import BaharCycle, Expense, Farmer, Income, Plot, SprayRecord
from bagmitra_api.sync.payloads import (
    BaharCyclePayload,
    ExpensePayload,
    FarmerProfilePayload,
    IncomePayload,
    PlotPayload,
    RowPayload,
    SprayRecordPayload,
)


class RejectedError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


@dataclass(frozen=True, slots=True)
class ValidatedWrite:
    entity_id: str
    op: Literal["upsert", "delete"]
    payload: BaseModel | None  # None for deletes
    client_updated_at: datetime
    seq: int


@dataclass(frozen=True, slots=True)
class RowChange:
    entity_id: str
    op: Literal["upsert", "delete"]
    data: dict[str, Any]
    updated_at: datetime
    seq: int


class EntityHandler(Protocol):
    @property
    def name(self) -> str: ...
    @property
    def supported_ops(self) -> frozenset[str]: ...
    @property
    def payload_model(self) -> type[BaseModel]: ...

    async def current_version(
        self, session: AsyncSession, user: AuthenticatedUser, entity_id: str
    ) -> datetime | None: ...

    async def check_references(
        self, session: AsyncSession, user: AuthenticatedUser, payload: BaseModel
    ) -> None: ...

    async def apply(
        self, session: AsyncSession, user: AuthenticatedUser, write: ValidatedWrite
    ) -> None: ...

    async def changed_since(
        self, session: AsyncSession, user: AuthenticatedUser, since: int
    ) -> list[RowChange]: ...


@dataclass(frozen=True)
class FarmerProfileHandler:
    name: str = "farmer_profile"
    supported_ops: frozenset[str] = frozenset({"upsert"})
    payload_model: type[BaseModel] = FarmerProfilePayload

    @staticmethod
    def _own_id(user: AuthenticatedUser, entity_id: str) -> uuid.UUID:
        if entity_id != str(user.id):
            raise RejectedError("forbidden")
        return user.id

    async def current_version(
        self, session: AsyncSession, user: AuthenticatedUser, entity_id: str
    ) -> datetime | None:
        farmer = await session.get(Farmer, self._own_id(user, entity_id))
        return farmer.client_updated_at if farmer else None

    async def check_references(
        self,
        session: AsyncSession,  # noqa: ARG002
        user: AuthenticatedUser,  # noqa: ARG002
        payload: BaseModel,  # noqa: ARG002
    ) -> None:
        return None  # a profile references nothing

    async def apply(
        self, session: AsyncSession, user: AuthenticatedUser, write: ValidatedWrite
    ) -> None:
        if write.payload is None:
            raise TypeError("farmer_profile supports upsert only")
        farmer_id = self._own_id(user, write.entity_id)
        farmer = await session.get(Farmer, farmer_id)
        if farmer is None:
            farmer = Farmer(id=farmer_id)
            session.add(farmer)
        for key, value in write.payload.model_dump().items():
            setattr(farmer, key, value)
        if user.phone:
            farmer.phone = user.phone
        farmer.client_updated_at = write.client_updated_at
        farmer.last_seq = write.seq

    async def changed_since(
        self, session: AsyncSession, user: AuthenticatedUser, since: int
    ) -> list[RowChange]:
        rows = await session.scalars(
            select(Farmer).where(Farmer.id == user.id, Farmer.last_seq > since)
        )
        return [
            RowChange(str(f.id), "upsert", profile_dict(f), f.updated_at, f.last_seq) for f in rows
        ]


def profile_dict(farmer: Farmer) -> dict[str, Any]:
    data = {key: getattr(farmer, key) for key in FarmerProfilePayload.model_fields}
    data["phone"] = farmer.phone
    return data


@dataclass(frozen=True)
class OwnedEntityHandler:
    """Upsert / soft-delete for rows owned by one farmer, keyed by a client UUID."""

    name: str
    model: type[OwnedSyncedRowMixin]
    payload_model: type[RowPayload]
    supported_ops: frozenset[str] = frozenset({"upsert", "delete"})
    # (payload attribute, parent model): the parent must exist, be live and be the user's.
    parents: tuple[tuple[str, type[OwnedSyncedRowMixin]], ...] = ()

    async def _row(
        self, session: AsyncSession, user: AuthenticatedUser, entity_id: str
    ) -> OwnedSyncedRowMixin | None:
        try:
            row_id = uuid.UUID(entity_id)
        except ValueError as exc:
            raise RejectedError("invalid_entity_id") from exc
        row = await session.get(self.model, row_id)
        if row is not None and row.owner_id != user.id:
            raise RejectedError("forbidden")
        return row

    async def current_version(
        self, session: AsyncSession, user: AuthenticatedUser, entity_id: str
    ) -> datetime | None:
        row = await self._row(session, user, entity_id)
        return row.client_updated_at if row else None

    async def check_references(
        self, session: AsyncSession, user: AuthenticatedUser, payload: BaseModel
    ) -> None:
        for attr, model in self.parents:
            parent_id = getattr(payload, attr)
            if parent_id is None:  # optional link (e.g. an expense not tied to a bahar)
                continue
            parent = await session.get(model, parent_id)
            if parent is None or parent.owner_id != user.id or parent.deleted_at is not None:
                raise RejectedError("invalid_reference")

    async def apply(
        self, session: AsyncSession, user: AuthenticatedUser, write: ValidatedWrite
    ) -> None:
        row = await self._row(session, user, write.entity_id)
        if write.op == "delete":
            if row is None:
                return  # never synced; nothing to tombstone
            row.deleted_at = write.client_updated_at
        else:
            if not isinstance(write.payload, RowPayload):
                raise TypeError(f"{self.name}: upsert needs a {self.payload_model.__name__}")
            if row is None:
                row = self.model()
                row.id = uuid.UUID(write.entity_id)
                row.owner_id = user.id
                session.add(row)
            for key, value in write.payload.to_columns().items():
                setattr(row, key, value)
            row.deleted_at = None
        row.client_updated_at = write.client_updated_at
        row.last_seq = write.seq

    async def changed_since(
        self, session: AsyncSession, user: AuthenticatedUser, since: int
    ) -> list[RowChange]:
        rows = await session.scalars(
            select(self.model).where(self.model.owner_id == user.id, self.model.last_seq > since)
        )
        fields = list(self.payload_model.model_fields)
        return [
            RowChange(str(r.id), "delete", {}, r.updated_at, r.last_seq)
            if r.deleted_at is not None
            else RowChange(
                str(r.id), "upsert", {f: getattr(r, f) for f in fields}, r.updated_at, r.last_seq
            )
            for r in rows
        ]


HANDLERS: dict[str, EntityHandler] = {
    h.name: h
    for h in (
        FarmerProfileHandler(),
        OwnedEntityHandler(name="plot", model=Plot, payload_model=PlotPayload),
        OwnedEntityHandler(
            name="bahar_cycle",
            model=BaharCycle,
            payload_model=BaharCyclePayload,
            parents=(("plot_id", Plot),),
        ),
        OwnedEntityHandler(
            name="expense",
            model=Expense,
            payload_model=ExpensePayload,
            parents=(("plot_id", Plot), ("bahar_cycle_id", BaharCycle)),
        ),
        OwnedEntityHandler(
            name="income",
            model=Income,
            payload_model=IncomePayload,
            parents=(("plot_id", Plot), ("bahar_cycle_id", BaharCycle)),
        ),
        OwnedEntityHandler(
            name="spray_record",
            model=SprayRecord,
            payload_model=SprayRecordPayload,
            parents=(("plot_id", Plot), ("bahar_cycle_id", BaharCycle)),
        ),
    )
}
