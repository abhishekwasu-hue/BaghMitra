from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Response
from pydantic import BaseModel, Field
from sqlalchemy import delete, select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.db.models import PushDevice
from bagmitra_api.db.session import DbSession

router = APIRouter(prefix="/v1", tags=["profile"])


class DeviceIn(BaseModel):
    token: str = Field(min_length=1, max_length=512)
    platform: Literal["android", "ios", "web"]


class DeviceOut(BaseModel):
    token: str = Field(min_length=1, max_length=512)


@router.post(
    "/me/devices",
    operation_id="me_device_register",
    status_code=204,
    responses={401: {"model": ErrorResponse}},
)
async def register_device(body: DeviceIn, user: CurrentUser, session: DbSession) -> Response:
    """Register this phone for push alerts; repeating it is harmless."""
    row = await session.scalar(select(PushDevice).where(PushDevice.token == body.token))
    if row is None:
        session.add(PushDevice(owner_id=user.id, token=body.token, platform=body.platform))
    else:
        row.owner_id, row.platform = user.id, body.platform
    await session.commit()
    return Response(status_code=204)


@router.delete(
    "/me/devices",
    operation_id="me_device_unregister",
    status_code=204,
    responses={401: {"model": ErrorResponse}},
)
async def unregister_device(body: DeviceOut, user: CurrentUser, session: DbSession) -> Response:
    """Stop push alerts to this phone (sign-out); unknown tokens are ignored."""
    await session.execute(
        delete(PushDevice).where(PushDevice.token == body.token, PushDevice.owner_id == user.id)
    )
    await session.commit()
    return Response(status_code=204)
