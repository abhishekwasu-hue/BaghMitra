"""Builds the gate's input from the database (claims valid today, all restrictions)."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.kb.gate import GateContext, LabelClaim, Restriction
from bagmitra_api.kb.models import KbLabelClaim, KbRestriction, KbSource, KbSynonym


async def load_context(
    session: AsyncSession,
    *,
    crop_aliases: frozenset[str],
    crop_groups: frozenset[str],
    now: datetime,
) -> GateContext:
    claim_rows = await session.execute(
        select(KbLabelClaim, KbSource.key)
        .join(KbSource, KbSource.id == KbLabelClaim.source_id)
        .where(
            KbLabelClaim.valid_from <= now,
            or_(KbLabelClaim.valid_to.is_(None), KbLabelClaim.valid_to > now),
        )
    )
    claims = [
        LabelClaim(
            active_ingredient=c.active_ingredient,
            formulation=c.formulation,
            crop=c.crop,
            target=c.target,
            dose=c.dose,
            interval_days=c.interval_days,
            phi_days=c.phi_days,
            max_sprays=c.max_sprays,
            source_key=key,
        )
        for c, key in claim_rows.all()
    ]
    restrictions = [
        Restriction(
            r.active_ingredient,
            r.kind,  # type: ignore[arg-type]
            tuple(r.crops),
            tuple(r.crop_groups),
            r.notification,
        )
        for r in await session.scalars(
            select(KbRestriction).where(KbRestriction.effective_from <= now)
        )
    ]
    synonyms = {s.name: s.active_ingredient for s in await session.scalars(select(KbSynonym))}
    return GateContext(crop_aliases, crop_groups, claims, restrictions, synonyms)
