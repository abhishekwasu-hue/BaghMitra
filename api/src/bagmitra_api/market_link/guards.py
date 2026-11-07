"""Market-link guards for owner decisions c (no commission / income anywhere, Q64) and
h (nothing is "verified" without an admin verification record)."""

from __future__ import annotations

import re
import uuid
from typing import Any

from pydantic import BaseModel, ConfigDict, model_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.market_link.models import SUBJECT_TYPES, PartyVerification

FORBIDDEN_KEY = re.compile(r"commission|brokerage|income|dalali", re.IGNORECASE)


def forbidden_keys(data: Any) -> list[str]:
    """Every key, at any depth of dicts and lists, that names a commission or income."""
    found: list[str] = []
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(key, str) and FORBIDDEN_KEY.search(key):
                found.append(key)
            found.extend(forbidden_keys(value))
    elif isinstance(data, list):
        for item in data:
            found.extend(forbidden_keys(item))
    return found


class MarketLinkIn(BaseModel):
    """Base of every market-link request body: unknown keys are refused, and a key naming a
    commission or income is refused even inside a nested dict."""

    model_config = ConfigDict(extra="forbid")

    @model_validator(mode="before")
    @classmethod
    def _no_commission_or_income(cls, data: Any) -> Any:
        bad = forbidden_keys(data)
        if bad:
            raise ValueError(f"commission / income fields are not allowed: {sorted(bad)}")
        return data


async def is_verified(session: AsyncSession, subject_type: str, subject_id: uuid.UUID) -> bool:
    """True only when the subject's latest verification record is approved by an admin."""
    if subject_type not in SUBJECT_TYPES:
        raise ValueError(f"unknown subject type {subject_type!r}")
    latest = await session.scalar(
        select(PartyVerification)
        .where(
            PartyVerification.subject_type == subject_type,
            PartyVerification.subject_id == subject_id,
        )
        .order_by(PartyVerification.created_at.desc())
        .limit(1)
    )
    return (
        latest is not None
        and latest.status == "approved"
        and latest.checked_by is not None
        and latest.checked_at is not None
    )
