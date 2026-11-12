"""Many Messages API calls for the offline Q&A build (Q144): Message Batches or concurrency.

Raw httpx, the same API version and headers as `feed.ai` (x-api-key, anthropic-version,
structured outputs in `output_config`). Two ways to send a list of requests:
- "batch" (default): `POST /v1/messages/batches`, poll until `ended`, read the JSONL results
  (half price, results within 24 hours, usually much sooner). The batch id is handed to
  `on_submitted` before polling, so a run that stops can collect it later (`collect`).
- "concurrent": `POST /v1/messages`, at most `concurrency` at a time, retried on 429 / 5xx /
  transport errors. The strong model then also gets the server-side refusal fallback.
Every reply carries its token usage; `Usage` adds them up and prices them (an estimate from the
list prices below, never a bill).
"""

from __future__ import annotations

import asyncio
import json
from collections.abc import Callable, Sequence
from dataclasses import dataclass, field
from typing import Any

import httpx

from bagmitra_api.feed.ai import ANTHROPIC_VERSION, FALLBACK_BETA

MODES = ("batch", "concurrent")
BATCH_MAX_REQUESTS = 200  # per batch; far below the API limit, keeps each upload small
RETRIES = 3
# USD per million tokens: input, output, cache write (5 minutes), cache read. List prices of
# 2026-11; the Batches API halves every one of them. Unknown models are reported unpriced.
PRICES: dict[str, tuple[float, float, float, float]] = {
    "claude-sonnet-5-5": (2.00, 10.00, 2.50, 0.10),
    "claude-haiku-5-5": (0.10, 0.50, 0.125, 0.01),
    "claude-opus-5-5": (4.00, 20.00, 5.00, 0.20),
}
BATCH_DISCOUNT = 0.5
TOKEN_FIELDS = (
    "input_tokens",
    "output_tokens",
    "cache_creation_input_tokens",
    "cache_read_input_tokens",
)


@dataclass(frozen=True, slots=True)
class Request:
    custom_id: str  # ^[a-zA-Z0-9_-]{1,64}$
    body: dict[str, Any]  # a Messages API body, with "model"
    fallback: bool = False  # server-side refusal fallback (concurrent mode only)


@dataclass(frozen=True, slots=True)
class Reply:
    custom_id: str
    model: str
    text: str | None  # None on error
    error: str | None
    usage: dict[str, int]
    batch: bool


@dataclass(slots=True)
class Usage:
    """Tokens per (model, batch?) and their estimated price."""

    rows: dict[tuple[str, bool], dict[str, int]] = field(default_factory=dict)

    def add(self, model: str, batch: bool, usage: dict[str, int]) -> None:
        row = self.rows.setdefault((model, batch), dict.fromkeys((*TOKEN_FIELDS, "requests"), 0))
        for f in TOKEN_FIELDS:
            row[f] += int(usage.get(f) or 0)
        row["requests"] += 1

    def dollars(self) -> float | None:
        """Estimated USD of everything added; None when a model has no price."""
        total = 0.0
        for (model, batch), row in self.rows.items():
            price = PRICES.get(model)
            if price is None:
                return None
            cost = sum(row[f] * p for f, p in zip(TOKEN_FIELDS, price, strict=True)) / 1e6
            total += cost * (BATCH_DISCOUNT if batch else 1.0)
        return round(total, 4)

    def as_json(self) -> dict[str, Any]:
        return {
            "rows": [{"model": m, "batch": b, **row} for (m, b), row in sorted(self.rows.items())],
            "estimated_usd": self.dollars(),
            "prices_per_mtok": {
                m: dict(zip(TOKEN_FIELDS, p, strict=True)) for m, p in PRICES.items()
            },
            "batch_discount": BATCH_DISCOUNT,
        }


def message_text(payload: dict[str, Any]) -> tuple[str | None, str | None]:
    """(text, None) or (None, reason) for one Messages API answer."""
    stop = payload.get("stop_reason")
    if stop == "refusal":
        return None, "model declined the request"
    if stop == "max_tokens":
        return None, "answer cut off at max_tokens"
    texts = [b.get("text", "") for b in payload.get("content", []) if b.get("type") == "text"]
    return "".join(texts), None


def _usage(payload: dict[str, Any]) -> dict[str, int]:
    raw = payload.get("usage") if isinstance(payload.get("usage"), dict) else {}
    return {f: int(raw.get(f) or 0) for f in TOKEN_FIELDS} if isinstance(raw, dict) else {}


class ModelClient:
    def __init__(  # noqa: PLR0913 - the run's knobs, all with defaults
        self,
        http: httpx.AsyncClient,
        *,
        api_key: str,
        base_url: str = "https://api.anthropic.com",
        mode: str = "batch",
        concurrency: int = 8,
        poll_seconds: float = 30.0,
        retry_seconds: float = 5.0,
        read_seconds: float = 300.0,
        batch_max: int = BATCH_MAX_REQUESTS,
    ) -> None:
        if mode not in MODES:
            raise ValueError(f"mode must be one of {MODES}")
        self._http = http
        self._base = base_url.rstrip("/")
        self._headers = {
            "x-api-key": api_key,
            "anthropic-version": ANTHROPIC_VERSION,
            "content-type": "application/json",
        }
        self.mode = mode
        self._concurrency = max(1, concurrency)
        self._poll = poll_seconds
        self._retry = retry_seconds
        self._read = read_seconds
        self._batch_max = max(1, batch_max)

    async def run(
        self,
        requests: Sequence[Request],
        on_reply: Callable[[Reply], None],
        on_submitted: Callable[[str, list[str]], None] | None = None,
    ) -> None:
        """Send every request; `on_reply` gets each reply (any order), `on_submitted` each
        batch id with its custom ids as soon as the batch exists."""
        if not requests:
            return
        if self.mode == "concurrent":
            await self._concurrent(requests, on_reply)
            return
        # Every batch is submitted first (they run side by side), then each is collected.
        submitted = []
        for start in range(0, len(requests), self._batch_max):
            chunk = list(requests[start : start + self._batch_max])
            batch_id = await self._submit(chunk)
            if on_submitted is not None:
                on_submitted(batch_id, [r.custom_id for r in chunk])
            submitted.append((batch_id, {r.custom_id: str(r.body.get("model", "")) for r in chunk}))
        for batch_id, models in submitted:
            for reply in await self.collect(batch_id, models):
                on_reply(reply)

    # Message Batches -------------------------------------------------------------------------

    async def _call(
        self, method: str, url: str, *, json_body: Any = None, headers: dict[str, str] | None = None
    ) -> httpx.Response:
        last: Exception | None = None
        for attempt in range(RETRIES):
            try:
                response = await self._http.request(
                    method,
                    url,
                    headers=headers or self._headers,
                    json=json_body,
                    timeout=self._read,
                )
            except httpx.HTTPError as exc:
                last = exc
            else:
                if response.status_code < httpx.codes.INTERNAL_SERVER_ERROR and (
                    response.status_code != httpx.codes.TOO_MANY_REQUESTS
                ):
                    return response
                last = RuntimeError(f"HTTP {response.status_code}")
            await asyncio.sleep(self._retry * 2**attempt)
        raise RuntimeError(f"{method} {url}: {last}")

    async def _submit(self, chunk: list[Request]) -> str:
        body = {"requests": [{"custom_id": r.custom_id, "params": r.body} for r in chunk]}
        response = await self._call("POST", f"{self._base}/v1/messages/batches", json_body=body)
        if response.status_code != httpx.codes.OK:
            raise RuntimeError(f"batch create: HTTP {response.status_code}: {response.text[:300]}")
        return str(response.json()["id"])

    async def collect(self, batch_id: str, models: dict[str, str]) -> list[Reply]:
        """Wait for a batch to end and read its results (also for a batch an earlier run
        submitted). `models` maps custom id to model, for the usage rows."""
        url = f"{self._base}/v1/messages/batches/{batch_id}"
        while True:
            response = await self._call("GET", url)
            if response.status_code != httpx.codes.OK:
                raise RuntimeError(f"batch {batch_id}: HTTP {response.status_code}")
            info = response.json()
            if info.get("processing_status") == "ended":
                break
            await asyncio.sleep(self._poll)
        results_url = info.get("results_url") or f"{url}/results"
        response = await self._call("GET", str(results_url))
        if response.status_code != httpx.codes.OK:
            raise RuntimeError(f"batch {batch_id} results: HTTP {response.status_code}")
        replies = []
        for line in response.text.splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            cid = str(row.get("custom_id"))
            result = row.get("result") or {}
            model = models.get(cid, "")
            if result.get("type") == "succeeded":
                message = result.get("message") or {}
                text, error = message_text(message)
                replies.append(
                    Reply(
                        cid, str(message.get("model") or model), text, error, _usage(message), True
                    )
                )
            else:
                reason = result.get("type") or "unknown"
                detail = result.get("error")
                replies.append(
                    Reply(cid, model, None, f"batch {reason}: {json.dumps(detail)[:300]}", {}, True)
                )
        return replies

    # Concurrency -----------------------------------------------------------------------------

    async def _one(self, r: Request) -> Reply:
        headers, body = self._headers, r.body
        if r.fallback:
            headers = {**headers, "anthropic-beta": FALLBACK_BETA}
            body = {**body, "fallbacks": "default"}
        model = str(r.body.get("model", ""))
        try:
            response = await self._call(
                "POST", f"{self._base}/v1/messages", json_body=body, headers=headers
            )
        except RuntimeError as exc:
            return Reply(r.custom_id, model, None, str(exc), {}, False)
        if response.status_code != httpx.codes.OK:
            return Reply(
                r.custom_id,
                model,
                None,
                f"HTTP {response.status_code}: {response.text[:300]}",
                {},
                False,
            )
        payload = response.json()
        text, error = message_text(payload)
        return Reply(
            r.custom_id, str(payload.get("model") or model), text, error, _usage(payload), False
        )

    async def _concurrent(
        self, requests: Sequence[Request], on_reply: Callable[[Reply], None]
    ) -> None:
        gate = asyncio.Semaphore(self._concurrency)

        async def go(r: Request) -> None:
            async with gate:
                reply = await self._one(r)
            on_reply(reply)

        await asyncio.gather(*(go(r) for r in requests))
