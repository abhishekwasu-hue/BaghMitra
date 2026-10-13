"""Verification of Supabase-issued access tokens (phone OTP / Google sign-in)."""

from __future__ import annotations

import uuid
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Annotated

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from bagmitra_api.core.errors import ApiError
from bagmitra_api.core.settings import Settings, get_settings

_bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True, slots=True)
class AuthenticatedUser:
    id: uuid.UUID
    phone: str | None
    # From Supabase `app_metadata`, which only the service role can set (never the user).
    roles: frozenset[str] = frozenset()
    reviewer_role: str | None = None


def _unauthorized(message: str) -> ApiError:
    return ApiError(401, "unauthorized", message)


def verify_token(token: str, settings: Settings) -> AuthenticatedUser:
    secret = settings.supabase_jwt_secret.get_secret_value()
    if not secret:
        raise _unauthorized("authentication is not configured")
    try:
        claims = jwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            audience=settings.jwt_audience,
            options={"require": ["sub", "exp", "aud"]},
        )
        user_id = uuid.UUID(str(claims["sub"]))
    except (jwt.PyJWTError, ValueError) as exc:
        raise _unauthorized("invalid or expired token") from exc
    phone = claims.get("phone")
    meta = claims.get("app_metadata")
    meta = meta if isinstance(meta, dict) else {}
    roles = meta.get("roles")
    reviewer_role = meta.get("reviewer_role")
    return AuthenticatedUser(
        id=user_id,
        phone=str(phone) if phone else None,
        roles=frozenset(r for r in roles if isinstance(r, str))
        if isinstance(roles, list)
        else frozenset(),
        reviewer_role=reviewer_role if isinstance(reviewer_role, str) else None,
    )


async def current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> AuthenticatedUser:
    if credentials is None:
        raise _unauthorized("missing bearer token")
    return verify_token(credentials.credentials, settings)


CurrentUser = Annotated[AuthenticatedUser, Depends(current_user)]


def require_role(role: str) -> Callable[[AuthenticatedUser], Awaitable[AuthenticatedUser]]:
    """Dependency factory: 403 unless the signed-in user holds `role`."""

    async def _check(user: CurrentUser) -> AuthenticatedUser:
        if role not in user.roles:
            raise ApiError(403, "forbidden", f"requires role {role}")
        return user

    return _check
