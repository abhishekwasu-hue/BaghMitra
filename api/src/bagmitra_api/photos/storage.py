"""Supabase Storage adapter for scouting photo backup (OPEN_QUESTIONS Q34).

Only signed URLs are handed out: the phone uploads straight to the private bucket with a
signed upload URL and reads back with a short-lived signed download URL. The service key is
sent to Supabase only, never returned or logged.

REST calls (Supabase Storage API, paths under {url}/storage/v1):
- POST /object/upload/sign/{bucket}/{key} -> {"url": "/object/upload/sign/...?token=..."}
- POST /object/sign/{bucket}/{key} {"expiresIn": n} -> {"signedURL": "/object/sign/..."}
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

import httpx

# Supabase signs upload URLs for a fixed two hours (not configurable on their side).
SIGNED_UPLOAD_TTL_SECONDS = 7200


class PhotoStorageError(Exception):
    """Storage could not be reached or answered with something we cannot use."""


class PhotoNotFoundError(PhotoStorageError):
    """The object does not exist in the bucket."""


@dataclass(frozen=True)
class SignedUrl:
    url: str
    expires_in: int


class PhotoStorage(Protocol):
    async def signed_upload_url(self, key: str) -> SignedUrl: ...

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl: ...


class SupabaseStorageClient:
    def __init__(
        self, http: httpx.AsyncClient, *, base_url: str, bucket: str, service_key: str
    ) -> None:
        self._http = http
        self._root = f"{base_url.rstrip('/')}/storage/v1"
        self._bucket = bucket
        self._headers = {"Authorization": f"Bearer {service_key}", "apikey": service_key}

    async def _post(
        self, path: str, json: dict[str, object], extra: dict[str, str] | None = None
    ) -> dict[str, object]:
        try:
            response = await self._http.post(
                f"{self._root}{path}", json=json, headers={**self._headers, **(extra or {})}
            )
        except httpx.HTTPError as exc:
            raise PhotoStorageError(type(exc).__name__) from exc
        if response.status_code in (httpx.codes.NOT_FOUND, httpx.codes.BAD_REQUEST):
            # Storage answers 400 {"error": "not_found"} for a missing object.
            raise PhotoNotFoundError(f"HTTP {response.status_code}")
        if response.status_code != httpx.codes.OK:
            raise PhotoStorageError(f"HTTP {response.status_code}")
        body = response.json()
        if not isinstance(body, dict):
            raise PhotoStorageError("unexpected response")
        return body

    def _absolute(self, relative: object) -> str:
        if not isinstance(relative, str) or not relative.startswith("/"):
            raise PhotoStorageError("no signed url in response")
        return f"{self._root}{relative}"

    async def signed_upload_url(self, key: str) -> SignedUrl:
        # x-upsert: a retried upload of the same record replaces the earlier object.
        try:
            body = await self._post(
                f"/object/upload/sign/{self._bucket}/{key}", {}, {"x-upsert": "true"}
            )
        except PhotoNotFoundError as exc:
            raise PhotoStorageError(str(exc)) from exc
        return SignedUrl(self._absolute(body.get("url")), SIGNED_UPLOAD_TTL_SECONDS)

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:
        body = await self._post(f"/object/sign/{self._bucket}/{key}", {"expiresIn": expires_in})
        return SignedUrl(self._absolute(body.get("signedURL")), expires_in)
