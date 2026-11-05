"""Error reporting (audit OPS-05). Off unless SENTRY_DSN is set: with it empty (the default)
the SDK is not even imported and nothing is sent anywhere.

When on, only crash / error events go out, stripped of personal and secret data:
- `send_default_pii=False`: no user ids, IP addresses or cookies are attached;
- no request bodies (farmer records) and no local variables (they can hold tokens or rows);
- request headers that carry credentials (Authorization, Cookie, API keys) are removed, and
  query strings are dropped from the request and from outgoing-HTTP breadcrumbs (the market
  source takes its key as a query parameter);
- no performance tracing.
The DSN itself is a secret and is never logged.
"""

from __future__ import annotations

import re
from typing import Any

import structlog

from bagmitra_api.core.settings import Settings

log = structlog.get_logger("bagmitra.observability")

# Lower-case header names whose values never leave the server.
SECRET_HEADERS = frozenset(
    {"authorization", "proxy-authorization", "cookie", "set-cookie", "x-api-key", "api-key"}
)
FILTERED = "[Filtered]"
# `api-key=...`, `token=...` in free text (an exception or log message that quotes a URL).
_SECRET_PARAM = re.compile(r"(?i)\b(api[-_]?key|access_token|token|key|dsn)=[^&\s'\"]+")


def _scrub_headers(headers: Any) -> Any:
    if isinstance(headers, dict):
        return {
            k: (FILTERED if str(k).lower() in SECRET_HEADERS else v) for k, v in headers.items()
        }
    if isinstance(headers, list):  # [[name, value], ...]
        return [
            [pair[0], FILTERED]
            if isinstance(pair, list | tuple) and pair and str(pair[0]).lower() in SECRET_HEADERS
            else pair
            for pair in headers
        ]
    return headers


def _strip_query(url: Any) -> Any:
    return url.split("?", 1)[0] if isinstance(url, str) else url


def _scrub_text(text: Any) -> Any:
    return (
        _SECRET_PARAM.sub(lambda m: f"{m.group(1)}={FILTERED}", text)
        if isinstance(text, str)
        else text
    )


def scrub_event(event: dict[str, Any], _hint: dict[str, Any] | None = None) -> dict[str, Any]:
    """`before_send`: remove credentials, query strings, bodies and cookies from an event."""
    request = event.get("request")
    if isinstance(request, dict):
        if "headers" in request:
            request["headers"] = _scrub_headers(request["headers"])
        for key in ("cookies", "data", "query_string", "env"):
            request.pop(key, None)
        if "url" in request:
            request["url"] = _strip_query(request["url"])
    exceptions = event.get("exception")
    for exc in exceptions.get("values", []) if isinstance(exceptions, dict) else []:
        if isinstance(exc, dict) and "value" in exc:
            exc["value"] = _scrub_text(exc["value"])
    if isinstance(event.get("logentry"), dict):
        for key in ("message", "formatted"):
            if key in event["logentry"]:
                event["logentry"][key] = _scrub_text(event["logentry"][key])
    crumbs = event.get("breadcrumbs")
    values = crumbs.get("values") if isinstance(crumbs, dict) else crumbs
    if isinstance(values, list):
        for crumb in values:
            if isinstance(crumb, dict):
                scrub_breadcrumb(crumb)
    return event


def scrub_breadcrumb(crumb: dict[str, Any], _hint: dict[str, Any] | None = None) -> dict[str, Any]:
    """`before_breadcrumb`: outgoing HTTP calls keep method, host / path and status only."""
    if "message" in crumb:
        crumb["message"] = _scrub_text(crumb["message"])
    data = crumb.get("data")
    if isinstance(data, dict):
        if "url" in data:
            data["url"] = _strip_query(data["url"])
        for key in ("http.query", "http.fragment"):
            data.pop(key, None)
    return crumb


def init_error_reporting(settings: Settings) -> bool:
    dsn = settings.sentry_dsn.get_secret_value().strip() if settings.sentry_dsn else ""
    if not dsn:
        return False
    import sentry_sdk  # noqa: PLC0415 - loaded only when reporting is switched on

    sentry_sdk.init(
        dsn=dsn,
        environment=settings.environment,
        send_default_pii=False,
        include_local_variables=False,
        max_request_body_size="never",
        traces_sample_rate=0.0,
        before_send=scrub_event,  # type: ignore[arg-type]
        before_breadcrumb=scrub_breadcrumb,
    )
    log.info("error_reporting_on", environment=settings.environment)
    return True
