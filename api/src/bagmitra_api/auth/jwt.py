"""Verification of Supabase-issued access tokens (phone OTP / Google sign-in).

Two signing schemes are accepted: the legacy shared secret (HS256) and the asymmetric keys
(ES256 / RS256) a Supabase project publishes at its JWKS URL. The scheme is chosen from the
token header but each is verified only with its own key material, so a public key can never be
used as an HMAC secret, and a missing or unreachable key set fails closed.
"""

from __future__ import annotations

import asyncio
import time
import uuid
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Annotated, Any

import httpx
import jwt
import structlog
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from bagmitra_api.core.errors import ApiError
from bagmitra_api.core.settings import Settings, get_settings

_bearer = HTTPBearer(auto_error=False)
log = structlog.get_logger("bagmitra.auth")


@dataclass(frozen=True, slots=True)
class AuthenticatedUser:
    id: uuid.UUID
    phone: str | None
    # From Supabase `app_metadata`, which only the service role can set (never the user).
    roles: frozenset[str] = frozenset()
    reviewer_role: str | None = None


def _unauthorized(message: str) -> ApiError:
    return ApiError(401, "unauthorized", message)


ASYMMETRIC_ALGORITHMS = frozenset({"ES256", "RS256"})


class JwksKeys:
    """Signing keys published by Supabase, cached. An unknown key id triggers one refresh (a
    rotated key is picked up without a restart), but never more often than
    `min_refresh_seconds`, so garbage tokens cannot hammer the key endpoint.

    One lock covers the fetch: requests that arrive while it runs (e.g. the parallel first
    requests after a restart) wait for it and use its result instead of failing. A refresh that
    fails while keys are cached keeps serving those keys; with nothing cached it fails closed."""

    def __init__(
        self,
        fetch: Callable[[], Awaitable[dict[str, Any]]],
        *,
        ttl_seconds: float = 3600,
        min_refresh_seconds: float = 30,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self._fetch = fetch
        self._ttl = ttl_seconds
        self._min_refresh = min_refresh_seconds
        self._clock = clock
        self._keys: dict[str, jwt.PyJWK] = {}
        self._fetched_at: float | None = None
        self._attempted_at: float | None = None
        self._lock = asyncio.Lock()

    def _fresh_key(self, kid: str) -> jwt.PyJWK | None:
        fetched = self._fetched_at
        if kid in self._keys and fetched is not None and self._clock() - fetched <= self._ttl:
            return self._keys[kid]
        return None

    async def key_for(self, kid: str) -> jwt.PyJWK | None:
        key = self._fresh_key(kid)
        if key is not None:
            return key
        async with self._lock:
            # Another request may have refreshed the keys while this one waited.
            key = self._fresh_key(kid)
            if key is not None:
                return key
            now = self._clock()
            if self._attempted_at is None or now - self._attempted_at >= self._min_refresh:
                self._attempted_at = now
                try:
                    document = await self._fetch()
                    keys = {
                        str(raw["kid"]): jwt.PyJWK(raw)
                        for raw in document.get("keys", [])
                        if isinstance(raw, dict) and raw.get("kid")
                    }
                except (httpx.HTTPError, ValueError, KeyError, jwt.PyJWTError) as exc:
                    if not self._keys:
                        raise
                    log.warning("jwks_refresh_failed_serving_cached", error=type(exc).__name__)
                else:
                    self._keys = keys
                    self._fetched_at = now
            return self._keys.get(kid)


_JWKS: dict[str, JwksKeys] = {}


def get_jwks(settings: Annotated[Settings, Depends(get_settings)]) -> JwksKeys | None:
    url = settings.supabase_jwks_url
    if not url:
        return None
    if url not in _JWKS:

        async def fetch() -> dict[str, Any]:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(url)
                response.raise_for_status()
                document: dict[str, Any] = response.json()
                return document

        _JWKS[url] = JwksKeys(fetch)
    return _JWKS[url]


def _user_from_claims(claims: dict[str, Any]) -> AuthenticatedUser:
    try:
        user_id = uuid.UUID(str(claims["sub"]))
    except (KeyError, ValueError) as exc:
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


async def verify_token_async(
    token: str, settings: Settings, keys: JwksKeys | None
) -> AuthenticatedUser:
    try:
        header = jwt.get_unverified_header(token)
    except jwt.PyJWTError as exc:
        raise _unauthorized("invalid or expired token") from exc
    algorithm = header.get("alg")
    if algorithm == "HS256":
        return verify_token(token, settings)
    kid = header.get("kid")
    if (
        algorithm not in ASYMMETRIC_ALGORITHMS
        or keys is None
        or not settings.supabase_jwks_url
        or not isinstance(kid, str)
    ):
        raise _unauthorized("invalid or expired token")
    try:
        key = await keys.key_for(kid)
    except (httpx.HTTPError, ValueError, KeyError, jwt.PyJWTError) as exc:
        raise _unauthorized("signing keys unavailable") from exc
    if key is None or key.algorithm_name != algorithm:
        raise _unauthorized("invalid or expired token")
    try:
        claims = jwt.decode(
            token,
            key.key,
            algorithms=[algorithm],
            audience=settings.jwt_audience,
            options={"require": ["sub", "exp", "aud"]},
            leeway=settings.jwt_leeway_seconds,
        )
    except jwt.PyJWTError as exc:
        raise _unauthorized("invalid or expired token") from exc
    return _user_from_claims(claims)


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
            leeway=settings.jwt_leeway_seconds,
        )
    except jwt.PyJWTError as exc:
        raise _unauthorized("invalid or expired token") from exc
    return _user_from_claims(claims)


async def current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    settings: Annotated[Settings, Depends(get_settings)],
    keys: Annotated[JwksKeys | None, Depends(get_jwks)],
) -> AuthenticatedUser:
    if credentials is None:
        raise _unauthorized("missing bearer token")
    return await verify_token_async(credentials.credentials, settings, keys)


CurrentUser = Annotated[AuthenticatedUser, Depends(current_user)]


def require_role(role: str) -> Callable[[AuthenticatedUser], Awaitable[AuthenticatedUser]]:
    """Dependency factory: 403 unless the signed-in user holds `role`."""

    async def _check(user: CurrentUser) -> AuthenticatedUser:
        if role not in user.roles:
            raise ApiError(403, "forbidden", f"requires role {role}")
        return user

    return _check
