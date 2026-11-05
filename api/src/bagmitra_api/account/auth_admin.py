"""Supabase Auth admin call that removes a sign-in account (needs the service role key).

DELETE {SUPABASE_URL}/auth/v1/admin/users/{id}. The key is sent to Supabase only, never
returned or logged.
"""

from __future__ import annotations

import uuid
from typing import Protocol

import httpx


class AuthAdminError(Exception):
    """Supabase Auth could not be reached or refused the call."""


class AuthAdmin(Protocol):
    async def delete_user(self, user_id: uuid.UUID) -> None: ...


class SupabaseAuthAdmin:
    def __init__(self, http: httpx.AsyncClient, *, base_url: str, service_key: str) -> None:
        self._http = http
        self._root = f"{base_url.rstrip('/')}/auth/v1/admin/users"
        self._headers = {"Authorization": f"Bearer {service_key}", "apikey": service_key}

    async def delete_user(self, user_id: uuid.UUID) -> None:
        try:
            response = await self._http.delete(f"{self._root}/{user_id}", headers=self._headers)
        except httpx.HTTPError as exc:
            raise AuthAdminError(type(exc).__name__) from exc
        # 404: the account is already gone, which is the goal.
        if response.status_code not in (
            httpx.codes.OK,
            httpx.codes.NO_CONTENT,
            httpx.codes.NOT_FOUND,
        ):
            raise AuthAdminError(f"HTTP {response.status_code}")
