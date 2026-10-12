"""Card lifecycle operations backed by the database, delegating rules to kb.policy."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.base import as_utc
from bagmitra_api.kb.models import KbCard, KbReview, KbSource
from bagmitra_api.kb.policy import (
    CardFacts,
    ReviewFacts,
    SourceFacts,
    publish_blockers,
    review_expiry,
)


class PublishRefusedError(Exception):
    def __init__(self, blockers: list[str]) -> None:
        super().__init__(", ".join(blockers))
        self.blockers = blockers


@dataclass(frozen=True, slots=True)
class ReviewInput:
    reviewer_id: uuid.UUID
    reviewer_role: str
    decision: str
    comments: str | None = None


async def record_review(
    session: AsyncSession, card: KbCard, review_in: ReviewInput, now: datetime, settings: Settings
) -> KbReview:
    expires = review_expiry(
        now,
        chemical=bool(card.chemical_options),
        months_default=settings.kb_review_months_default,
        months_chemical=settings.kb_review_months_chemical,
    )
    review = KbReview(
        id=uuid.uuid4(),
        card_id=card.id,
        card_version=card.version,
        reviewer_id=review_in.reviewer_id,
        reviewer_role=review_in.reviewer_role,
        decision=review_in.decision,
        comments=review_in.comments,
        reviewed_at=now,
        expires_at=expires,
    )
    session.add(review)
    if review_in.decision == "approve":
        card.status = "expert_reviewed"
        card.review_due_at = expires
    return review


async def publish(session: AsyncSession, card: KbCard, now: datetime) -> None:
    """Publish only when kb.policy finds no blockers; otherwise raise with the reasons."""
    source_ids = [uuid.UUID(s["source_id"]) for s in card.sources]
    sources = {
        s.id: SourceFacts(id=s.id, allowed_use=s.allowed_use)  # type: ignore[arg-type]
        for s in await session.scalars(select(KbSource).where(KbSource.id.in_(source_ids)))
    }
    reviews = [
        ReviewFacts(
            card_version=r.card_version,
            decision=r.decision,  # type: ignore[arg-type]
            reviewer_id=r.reviewer_id,
            reviewed_at=as_utc(r.reviewed_at),
            expires_at=as_utc(r.expires_at),
        )
        for r in await session.scalars(select(KbReview).where(KbReview.card_id == card.id))
    ]
    facts = CardFacts(
        version=card.version,
        has_english="en" in card.content,
        source_ids=source_ids,
        has_chemical_options=bool(card.chemical_options),
    )
    blockers = publish_blockers(facts, reviews, sources, now)
    if blockers:
        raise PublishRefusedError(blockers)
    card.status = "published"
