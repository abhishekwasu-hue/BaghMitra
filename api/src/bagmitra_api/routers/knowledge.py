"""Knowledge cards for growers, as general information (owner decision Q57).

The cards stay drafts until an expert reviews them. Until then a grower sees only their general
part: no chemical options, no `organic` rates, and no sentence that names a product or carries a
dose (`kb/grower_view.py`). Every card names its sources and the date each was read.
"""

from __future__ import annotations

import uuid
from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.kb.grower_view import grower_text
from bagmitra_api.kb.models import KbCard, KbSource, KbTopic

router = APIRouter(
    prefix="/v1/knowledge", tags=["knowledge"], responses={401: {"model": ErrorResponse}}
)


class CardText(BaseModel):
    title: str | None = None
    summary: str | None = None
    cultural: str | None = None
    warnings: str | None = None
    when_to_call_expert: str | None = None


class CardSourceOut(BaseModel):
    title: str
    publisher: str
    url: str
    # When the source was read; null when it was taken from a summary and not yet fetched.
    checked: date | None


class GrowerCardOut(BaseModel):
    topic: str
    topic_kind: str
    topic_labels: dict[str, str]
    crop: str
    # True only once an expert review has published the card; until then it is general
    # information from public sources.
    reviewed: bool
    text: dict[str, CardText]
    sources: list[CardSourceOut]


class GrowerCardsResponse(BaseModel):
    kind: Literal["general_information"] = "general_information"
    cards: list[GrowerCardOut]


@router.get("/cards", operation_id="knowledge_cards")
async def cards(
    _user: CurrentUser,
    session: DbSession,
    crop: Annotated[str | None, Query(pattern="^[a-z_]{2,32}$")] = None,
) -> GrowerCardsResponse:
    """The general part of every live knowledge card (newest version per topic and crop)."""
    query = select(KbCard, KbTopic).join(KbTopic, KbTopic.id == KbCard.topic_id)
    query = query.where(KbCard.status != "retired")
    if crop is not None:
        query = query.where(KbCard.crop == crop)
    newest: dict[tuple[uuid.UUID, str], tuple[KbCard, KbTopic]] = {}
    for card, topic in (await session.execute(query)).tuples():
        key = (card.topic_id, card.crop)
        if key not in newest or newest[key][0].version < card.version:
            newest[key] = (card, topic)
    source_ids = {
        uuid.UUID(ref["source_id"]) for card, _ in newest.values() for ref in card.sources
    }
    sources = {
        s.id: s for s in await session.scalars(select(KbSource).where(KbSource.id.in_(source_ids)))
    }
    out = []
    for card, topic in sorted(newest.values(), key=lambda ct: (ct[1].kind, ct[1].key, ct[0].crop)):
        cited = [sources[uuid.UUID(ref["source_id"])] for ref in card.sources]
        out.append(
            GrowerCardOut(
                topic=topic.key,
                topic_kind=topic.kind,
                topic_labels=topic.labels,
                crop=card.crop,
                reviewed=card.status == "published",
                text={
                    lang: CardText(**fields) for lang, fields in grower_text(card.content).items()
                },
                sources=[
                    CardSourceOut(
                        title=s.title,
                        publisher=s.publisher,
                        url=s.url,
                        checked=s.fetched_at.date() if s.fetched_at else None,
                    )
                    for s in dict.fromkeys(cited)
                ],
            )
        )
    return GrowerCardsResponse(cards=out)
