"""Nightly re-gate (addendum §4, §9): re-check every published card against the current
label claims and restrictions. A card that fails is pulled back to draft and an admin
alert is raised; it returns only through the normal review flow.

Usage: python -m bagmitra_api.kb.regate   (schedule nightly; also runs after imports)
"""

from __future__ import annotations

import asyncio
import uuid
from collections.abc import Mapping
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.kb.context import load_context
from bagmitra_api.kb.gate import ChemicalOption, GateContext, evaluate
from bagmitra_api.kb.models import KbAdminAlert, KbCard


def _failures(card: KbCard, ctx: GateContext, now: datetime) -> list[str]:
    out: list[str] = []
    for opt in card.chemical_options:
        option = ChemicalOption(opt["active_ingredient"], opt["formulation"], opt["target"])
        result = evaluate(option, ctx, today=now.date(), planned_harvest=None)
        if not result.allowed:
            out.append(f"{option.active_ingredient} ({', '.join(result.reasons)})")
    return out


async def regate_published_cards(
    session: AsyncSession,
    *,
    crop_aliases: Mapping[str, frozenset[str]],
    crop_groups: Mapping[str, frozenset[str]],
    now: datetime,
) -> list[uuid.UUID]:
    contexts: dict[str, GateContext] = {}
    pulled: list[uuid.UUID] = []
    for card in await session.scalars(select(KbCard).where(KbCard.status == "published")):
        if card.crop not in crop_aliases:
            failures = [f"crop {card.crop!r} has no label aliases configured"]
        else:
            if card.crop not in contexts:
                contexts[card.crop] = await load_context(
                    session,
                    crop_aliases=crop_aliases[card.crop],
                    crop_groups=crop_groups.get(card.crop, frozenset()),
                    now=now,
                )
            failures = _failures(card, contexts[card.crop], now)
        if not failures:
            continue
        card.status = "draft"
        pulled.append(card.id)
        session.add(
            KbAdminAlert(
                id=uuid.uuid4(),
                kind="card_pulled",
                card_id=card.id,
                detail=f"re-gate {now.date().isoformat()}: " + "; ".join(failures),
            )
        )
    await session.flush()
    return pulled


async def regate_with_settings(
    session: AsyncSession, settings: Settings, now: datetime
) -> list[uuid.UUID]:
    return await regate_published_cards(
        session,
        crop_aliases={k: frozenset(v) for k, v in settings.kb_crop_label_aliases.items()},
        crop_groups={k: frozenset(v) for k, v in settings.kb_crop_groups.items()},
        now=now,
    )


async def main() -> None:  # pragma: no cover - thin CLI wrapper
    from bagmitra_api.core.settings import get_settings  # noqa: PLC0415
    from bagmitra_api.db.session import get_sessionmaker  # noqa: PLC0415

    async with get_sessionmaker()() as session:
        pulled = await regate_with_settings(session, get_settings(), datetime.now(UTC))
        await session.commit()
    print(f"cards pulled: {len(pulled)}")


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
