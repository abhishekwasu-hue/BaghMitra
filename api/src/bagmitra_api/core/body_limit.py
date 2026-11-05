"""Request-body size cap (S-06), enforced before the body is parsed.

A declared `Content-Length` over the cap is answered 413 without reading anything. A body
sent without one (chunked) is counted while it streams; once it passes the cap, reading
stops with an `ApiError(413)`. FastAPI re-raises HTTP errors raised while it reads the body,
so the normal error envelope answers; anything that escapes is answered here.
"""

from __future__ import annotations

import json
from typing import Final

from starlette.types import ASGIApp, Message, Receive, Scope, Send

from bagmitra_api.core.errors import ApiError

ADMIN_PREFIX: Final = "/v1/admin/"


class BodyTooLargeError(ApiError):
    def __init__(self, limit: int) -> None:
        super().__init__(413, "payload_too_large", f"request body over {limit} bytes")


def _request_id(scope: Scope) -> str:
    state = scope.get("state") or {}
    rid = state.get("request_id", "") if isinstance(state, dict) else ""
    return rid if isinstance(rid, str) else ""


async def _answer(scope: Scope, send: Send, status: int, code: str, message: str) -> None:
    body = json.dumps(
        {"error": {"code": code, "message": message, "request_id": _request_id(scope)}}
    ).encode()
    await send(
        {
            "type": "http.response.start",
            "status": status,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(body)).encode()),
                (b"connection", b"close"),
            ],
        }
    )
    await send({"type": "http.response.body", "body": body})


class BodyLimitMiddleware:
    def __init__(self, app: ASGIApp, *, default_limit: int, admin_limit: int) -> None:
        self.app = app
        self.default_limit = default_limit
        self.admin_limit = admin_limit

    def _limit(self, path: str) -> int:
        return self.admin_limit if path.startswith(ADMIN_PREFIX) else self.default_limit

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        limit = self._limit(scope.get("path", ""))
        declared = next(
            (v for k, v in scope.get("headers", []) if k.lower() == b"content-length"), None
        )
        if declared is not None:
            try:
                size = int(declared)
            except ValueError:
                await _answer(scope, send, 400, "invalid_content_length", "bad Content-Length")
                return
            if size > limit:
                await _answer(
                    scope, send, 413, "payload_too_large", f"request body over {limit} bytes"
                )
                return

        received = 0
        started = False

        async def limited_receive() -> Message:
            nonlocal received
            message = await receive()
            if message["type"] == "http.request":
                received += len(message.get("body", b""))
                if received > limit:
                    raise BodyTooLargeError(limit)
            return message

        async def tracking_send(message: Message) -> None:
            nonlocal started
            if message["type"] == "http.response.start":
                started = True
            await send(message)

        try:
            await self.app(scope, limited_receive, tracking_send)
        except BodyTooLargeError as exc:
            if started:  # pragma: no cover - a response already went out
                raise
            await _answer(scope, send, 413, exc.code, str(exc.detail))
