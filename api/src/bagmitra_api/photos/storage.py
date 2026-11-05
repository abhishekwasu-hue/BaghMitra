"""Supabase Storage adapter for scouting photo backup (OPEN_QUESTIONS Q34).

Only signed URLs are handed out: the phone uploads straight to the private bucket with a
signed upload URL and reads back with a short-lived signed download URL. The service key is
sent to Supabase only, never returned or logged.

REST calls (Supabase Storage API, paths under {url}/storage/v1):
- POST /object/upload/sign/{bucket}/{key} -> {"url": "/object/upload/sign/...?token=..."}
- POST /object/sign/{bucket}/{key} {"expiresIn": n} -> {"signedURL": "/object/sign/..."}
- POST /object/list/{bucket} {"prefix", "limit", "offset"} -> [{"name": ...}, ...]
- DELETE /object/{bucket} {"prefixes": [key, ...]} -> [deleted objects]
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

import httpx

# Supabase signs upload URLs for a fixed two hours (not configurable on their side).
SIGNED_UPLOAD_TTL_SECONDS = 7200
# Objects per list page and per delete call.
LIST_PAGE = 1000


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

    async def list_folder(self, folder: str) -> list[str]: ...

    async def delete_objects(self, keys: list[str]) -> None: ...


class SupabaseStorageClient:
    def __init__(
        self, http: httpx.AsyncClient, *, base_url: str, bucket: str, service_key: str
    ) -> None:
        self._http = http
        self._root = f"{base_url.rstrip('/')}/storage/v1"
        self._bucket = bucket
        self._headers = {"Authorization": f"Bearer {service_key}", "apikey": service_key}

    async def _send(
        self,
        method: str,
        path: str,
        json: dict[str, object],
        extra: dict[str, str] | None = None,
    ) -> object:
        try:
            response = await self._http.request(
                method,
                f"{self._root}{path}",
                json=json,
                headers={**self._headers, **(extra or {})},
            )
        except httpx.HTTPError as exc:
            raise PhotoStorageError(type(exc).__name__) from exc
        if response.status_code in (httpx.codes.NOT_FOUND, httpx.codes.BAD_REQUEST):
            # Storage answers 400 {"error": "not_found"} for a missing object.
            raise PhotoNotFoundError(f"HTTP {response.status_code}")
        if response.status_code != httpx.codes.OK:
            raise PhotoStorageError(f"HTTP {response.status_code}")
        try:
            return response.json()
        except ValueError as exc:
            raise PhotoStorageError("unexpected response") from exc

    async def _post(
        self, path: str, json: dict[str, object], extra: dict[str, str] | None = None
    ) -> dict[str, object]:
        body = await self._send("POST", path, json, extra)
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

    async def list_folder(self, folder: str) -> list[str]:
        """Every object key directly in `folder` (photo keys are `<owner>/<record>.jpg`)."""
        keys: list[str] = []
        offset = 0
        while True:
            try:
                body = await self._send(
                    "POST",
                    f"/object/list/{self._bucket}",
                    {"prefix": folder, "limit": LIST_PAGE, "offset": offset},
                )
            except PhotoNotFoundError:
                return keys
            if not isinstance(body, list):
                raise PhotoStorageError("unexpected response")
            names = [
                e["name"] for e in body if isinstance(e, dict) and isinstance(e.get("name"), str)
            ]
            keys += [f"{folder}/{name}" for name in names]
            if len(body) < LIST_PAGE:
                return keys
            offset += LIST_PAGE

    async def delete_objects(self, keys: list[str]) -> None:
        for start in range(0, len(keys), LIST_PAGE):
            try:
                await self._send(
                    "DELETE",
                    f"/object/{self._bucket}",
                    {"prefixes": keys[start : start + LIST_PAGE]},
                )
            except PhotoNotFoundError:
                continue  # already gone
