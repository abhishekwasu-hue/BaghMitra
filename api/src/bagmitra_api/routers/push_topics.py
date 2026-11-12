"""The grower's update-push switches (owner 2026-11-12, OPEN_QUESTIONS Q147): new articles,
market prices, weather changes. Settings -> सूचना in the app; `push/updates.py` reads them.
Owner data: one row per signed-in user; no row means the defaults (PUSH_TOPIC_*_DEFAULT)."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.push.models import PushTopicPrefs

router = APIRouter(prefix="/v1", tags=["profile"], responses={401: {"model": ErrorResponse}})


class PushTopicsBody(BaseModel):
    """Which update pushes the caller wants: a new article, a market price change of their
    crops' mandis, a sudden weather change at their plots."""

    articles: bool
    market: bool
    weather_change: bool


def _out(row: PushTopicPrefs | None, settings: Settings) -> PushTopicsBody:
    if row is None:
        return PushTopicsBody(
            articles=settings.push_topic_articles_default,
            market=settings.push_topic_market_default,
            weather_change=settings.push_topic_weather_default,
        )
    return PushTopicsBody(
        articles=row.articles, market=row.market, weather_change=row.weather_change
    )


@router.get("/me/push-topics", operation_id="push_topics_get")
async def get_push_topics(
    user: CurrentUser,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
) -> PushTopicsBody:
    """The caller's switches, or the defaults (all on unless the admin changed them)."""
    return _out(await session.get(PushTopicPrefs, user.id), settings)


@router.put(
    "/me/push-topics",
    operation_id="push_topics_put",
    responses={422: {"model": ErrorResponse}},
)
async def put_push_topics(
    body: PushTopicsBody,
    user: CurrentUser,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
) -> PushTopicsBody:
    """Saves all three switches; repeating the same body is harmless (the app retries a
    change made offline)."""
    row = await session.get(PushTopicPrefs, user.id)
    if row is None:
        row = PushTopicPrefs(owner_id=user.id)
        session.add(row)
    row.articles, row.market, row.weather_change = body.articles, body.market, body.weather_change
    await session.commit()
    return _out(row, settings)
