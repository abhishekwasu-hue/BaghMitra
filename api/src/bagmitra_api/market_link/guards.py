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
# Zero-cost verification (addendum 1): no Aadhaar number, card image or OTP anywhere.
AADHAAR_KEY = re.compile(r"aadhaar|uid", re.IGNORECASE)


def _keys_matching(data: Any, pattern: re.Pattern[str]) -> list[str]:
    found: list[str] = []
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(key, str) and pattern.search(key):
                found.append(key)
            found.extend(_keys_matching(value, pattern))
    elif isinstance(data, list):
        for item in data:
            found.extend(_keys_matching(item, pattern))
    return found


def forbidden_keys(data: Any) -> list[str]:
    """Every key, at any depth of dicts and lists, that names a commission or income."""
    return _keys_matching(data, FORBIDDEN_KEY)


def aadhaar_keys(data: Any) -> list[str]:
    """Every key, at any depth, that names an Aadhaar / UID field."""
    return _keys_matching(data, AADHAAR_KEY)


class MarketLinkIn(BaseModel):
    """Base of every market-link request body: unknown keys are refused, and a key naming a
    commission, income or Aadhaar / UID is refused even inside a nested dict."""

    model_config = ConfigDict(extra="forbid")

    @model_validator(mode="before")
    @classmethod
    def _no_commission_or_income(cls, data: Any) -> Any:
        bad = forbidden_keys(data)
        if bad:
            raise ValueError(f"commission / income fields are not allowed: {sorted(bad)}")
        if aadhaar := aadhaar_keys(data):
            raise ValueError(f"aadhaar / uid fields are not allowed: {sorted(aadhaar)}")
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
