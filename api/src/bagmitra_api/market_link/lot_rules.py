"""Lot form settings (owner 2026-11-11, Q138): the rate range per crop and sale basis, and the
default length of the harvest window. The market-link admin sets them (admin API / admin web);
an empty value means the default below, the owner's own numbers:

- per quintal: Rs 2,500 to Rs 10,000 ("2500 ते 10000");
- per crate: Rs 400 to Rs 1,200 ("400-1200");
- whole orchard (lump sum): no range;
- santra and mosambi each have their own range ("मोसंबीचे दर वेगळे असू शकतात"); the owner gave
  no mosambi numbers, so mosambi starts at the same defaults;
- harvest window, one for all crops: the grower picks the start, the end is start + 15 days
  ("पंधरा दिवसाची गॅप"); the grower may move the end, never before the start.

The range binds the grower's asking rate (checked at publish; a draft may hold anything while
it is on the phone) and a trader's interest ("व्यापाराच्या ऑफरवर पण ठेवा"), by the lot's crop
and the basis chosen. A crop not listed in `CROPS` has no range.

`legacy_basis` reads the old "per_tonne" basis that phones built before 0047 still send: the
rate becomes per quintal (Rs / tonne / 10), rounded to the paisa.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.market_link.models import AdminAction, MarketLotSettings

CROPS = ("santra", "mosambi")
RANGED_BASES = ("per_quintal", "per_crate")
# basis -> (min, max) in paise, the same for every crop until the admin changes one.
DEFAULT_RANGES = {"per_quintal": (2_500_00, 10_000_00), "per_crate": (400_00, 1_200_00)}
HARVEST_DAYS_DEFAULT = 15
LOT_SETTINGS_SUBJECT = uuid.UUID("00000000-0000-4000-8000-00000000c003")
LEGACY_BASIS = "per_tonne"


def range_column(crop: str, basis: str, end: str) -> str:
    """The settings column of one end ("min" / "max") of a crop's range for a basis."""
    return f"{crop}_{basis}_{end}_paise"


RANGE_COLUMNS = tuple(
    range_column(c, b, e) for c in CROPS for b in RANGED_BASES for e in ("min", "max")
)
SETTING_FIELDS = (*RANGE_COLUMNS, "harvest_window_days")


@dataclass(frozen=True, slots=True)
class LotRules:
    # (crop, basis) -> (min, max) in paise, both inclusive; a pair not listed has no range.
    ranges: dict[tuple[str, str], tuple[int, int]]
    harvest_window_days: int

    def out_of_range(
        self, crop: str | None, basis: str, rate_paise: int | None
    ) -> tuple[int, int] | None:
        """The range the rate misses, or None when it fits (or has no range / no rate)."""
        span = self.ranges.get((crop or "", basis))
        if span is None or rate_paise is None or span[0] <= rate_paise <= span[1]:
            return None
        return span


async def lot_settings_row(session: AsyncSession) -> MarketLotSettings:
    """The single settings row; created empty (= every default) on first use."""
    row = await session.get(MarketLotSettings, 1)
    if row is None:
        row = MarketLotSettings(id=1)
        session.add(row)
        await session.flush()
    return row


def rules_of(row: MarketLotSettings | None) -> LotRules:
    """Each setting as it applies: the admin's value, else the default."""

    def value(column: str, default: int) -> int:
        v = getattr(row, column, None) if row else None
        return default if v is None else int(v)

    return LotRules(
        ranges={
            (c, b): (
                value(range_column(c, b, "min"), DEFAULT_RANGES[b][0]),
                value(range_column(c, b, "max"), DEFAULT_RANGES[b][1]),
            )
            for c in CROPS
            for b in RANGED_BASES
        },
        harvest_window_days=value("harvest_window_days", HARVEST_DAYS_DEFAULT),
    )


async def lot_rules(session: AsyncSession) -> LotRules:
    return rules_of(await session.get(MarketLotSettings, 1))


def change_lot_settings(
    session: AsyncSession,
    row: MarketLotSettings,
    changes: dict[str, int | None],
    *,
    actor_id: uuid.UUID,
    now: datetime,
) -> list[str]:
    """Sets the changed fields and logs them in `admin_actions` (old / new, who, when)."""
    old = {k: getattr(row, k) for k, v in changes.items() if getattr(row, k) != v}
    if not old:
        return []
    for key in old:
        setattr(row, key, changes[key])
    session.add(
        AdminAction(
            subject_type="lot_settings",
            subject_id=LOT_SETTINGS_SUBJECT,
            user_id=None,
            action="settings_change",
            reason_code="admin_setting",
            actor_id=actor_id,
            acted_at=now,
            detail={"old": old, "new": {k: changes[k] for k in old}},
        )
    )
    return list(old)


def legacy_basis(data: Any, rate_key: str) -> Any:
    """An old phone's "per_tonne" body as per quintal (rate / 10); anything else unchanged."""
    if not isinstance(data, dict) or data.get("basis") != LEGACY_BASIS:
        return data
    out = {**data, "basis": "per_quintal"}
    rate = data.get(rate_key)
    if isinstance(rate, int) and not isinstance(rate, bool):
        out[rate_key] = max(1, (rate + 5) // 10)
    return out
