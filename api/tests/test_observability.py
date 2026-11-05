"""OPS-05: error reporting is off unless SENTRY_DSN is set, and when on it sends no personal or
secret data. `sentry_sdk.init` is replaced by a recorder (conftest), so nothing is sent."""

from __future__ import annotations

from typing import Any

from pydantic import SecretStr

from bagmitra_api.core.observability import (
    FILTERED,
    init_error_reporting,
    scrub_breadcrumb,
    scrub_event,
)
from bagmitra_api.core.settings import Settings


def test_reporting_is_off_by_default(sentry_init_calls: list[dict[str, Any]]) -> None:
    assert init_error_reporting(Settings()) is False
    assert sentry_init_calls == []


def test_an_empty_dsn_line_in_env_keeps_reporting_off(
    sentry_init_calls: list[dict[str, Any]],
) -> None:
    assert init_error_reporting(Settings(sentry_dsn=SecretStr("  "))) is False
    assert sentry_init_calls == []


def test_a_set_dsn_turns_reporting_on_without_pii(
    sentry_init_calls: list[dict[str, Any]],
) -> None:
    dsn = "https://publickey@o1.ingest.example.invalid/42"
    assert init_error_reporting(Settings(sentry_dsn=SecretStr(dsn), environment="staging"))
    (kwargs,) = sentry_init_calls
    assert kwargs["dsn"] == dsn
    assert kwargs["environment"] == "staging"
    assert kwargs["send_default_pii"] is False
    assert kwargs["include_local_variables"] is False
    assert kwargs["max_request_body_size"] == "never"
    assert kwargs["traces_sample_rate"] == 0.0
    assert kwargs["before_send"] is scrub_event
    assert kwargs["before_breadcrumb"] is scrub_breadcrumb


def test_events_lose_credentials_bodies_cookies_and_query_strings() -> None:
    event: dict[str, Any] = {
        "request": {
            "url": "https://api.example.invalid/v1/market/prices?crop=santra",
            "query_string": "crop=santra",
            "headers": {
                "Authorization": "Bearer eyJ-secret",
                "Cookie": "sb=1",
                "X-Api-Key": "k",
                "User-Agent": "BagMitra",
            },
            "cookies": {"sb": "1"},
            "data": {"name": "farmer"},
            "env": {"REMOTE_ADDR": "10.0.0.1"},
        },
        "breadcrumbs": {
            "values": [
                {
                    "category": "httplib",
                    "data": {
                        "url": "https://api.data.gov.in/resource/x?api-key=SECRET&format=json",
                        "http.query": "api-key=SECRET&format=json",
                        "method": "GET",
                    },
                }
            ]
        },
    }
    out = scrub_event(event)
    request = out["request"]
    assert request["url"] == "https://api.example.invalid/v1/market/prices"
    assert request["headers"] == {
        "Authorization": FILTERED,
        "Cookie": FILTERED,
        "X-Api-Key": FILTERED,
        "User-Agent": "BagMitra",
    }
    assert not {"query_string", "cookies", "data", "env"} & set(request)
    crumb = out["breadcrumbs"]["values"][0]["data"]
    assert crumb == {"url": "https://api.data.gov.in/resource/x", "method": "GET"}
    assert "SECRET" not in repr(out)


def test_header_pairs_and_odd_shapes_are_handled() -> None:
    event: dict[str, Any] = {
        "request": {"headers": [["authorization", "Bearer x"], ["accept", "json"]]},
        "breadcrumbs": [{"data": "not-a-dict"}, "odd"],
    }
    out = scrub_event(event)
    assert out["request"]["headers"] == [["authorization", FILTERED], ["accept", "json"]]
    assert scrub_event({"request": "odd"}) == {"request": "odd"}
    assert scrub_event({"request": {"headers": "odd"}}) == {"request": {"headers": "odd"}}
    assert scrub_breadcrumb({"data": {"url": 5}}) == {"data": {"url": 5}}


def test_secret_parameters_in_messages_are_masked() -> None:
    event: dict[str, Any] = {
        "exception": {"values": [{"type": "HTTPStatusError", "value": "GET /r?api-key=S1&x=1"}]},
        "logentry": {"message": "failed token=S2", "formatted": "failed token=S2"},
        "breadcrumbs": {"values": [{"message": "market_source_unavailable api_key=S3"}]},
    }
    out = scrub_event(event)
    assert "S1" not in repr(out)
    assert "S2" not in repr(out)
    assert "S3" not in repr(out)
    assert out["exception"]["values"][0]["value"] == f"GET /r?api-key={FILTERED}&x=1"
