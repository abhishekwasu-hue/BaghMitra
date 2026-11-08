"""Guard (audit 2026-11-07): every market-link endpoint that returns other people's rows goes
through the visibility rule (`market_link/visibility.py`: `visible` / `not_blocked`, or the
one lot rule `lot_visible_to_traders` / `lot_shown`, or a helper built on them). A new
endpoint must be listed here as either OTHERS (with the call it uses) or OWN, or this fails.
The behaviour itself is tested through the API in `test_market_link_enforcement.py`."""

from __future__ import annotations

import inspect

import pytest
from fastapi.routing import APIRoute

from bagmitra_api.core.settings import Settings
from bagmitra_api.main import create_app

# operation function -> the visibility call its body must make.
OTHERS = {
    "list_lots": "lot_visible_to_traders(",
    "lot_photo_url": "lot_shown(",
    "send_interest": "lot_shown(",
    "lot_interests": "_profiles(",
    "profiles": "_shown(",
    "profile": "_shown(",
    "directory": "_shown(",
}
# Helpers named above -> the rule they apply.
HELPERS = {
    ("market_interests", "_profiles"): ("visible(", "not_blocked("),
    ("market_link_profiles", "_shown"): ("visible(", "not_blocked("),
    ("package", "lot_visible_to_traders"): ("visible(", "not_blocked("),
    ("package", "lot_shown"): ("lot_visible_to_traders(",),
}
# Only the caller's own rows, a party's own deal, or fixed reference data.
OWN = {
    "deal_ratings",
    "my_interests",
    "introduction",
    "rating_tags",
    "terms",
    "my_acceptances",
    "my_profiles",
    "my_reports",
    "blocks",
    "account_actions",
    "package_status",
}


def _routes() -> list[APIRoute]:
    app = create_app(Settings(market_link_enabled=True))
    return [
        r for r in app.routes if isinstance(r, APIRoute) and r.path.startswith("/v1/market-link")
    ]


def test_every_market_link_read_is_classified() -> None:
    reads = {r.endpoint.__name__ for r in _routes() if "GET" in r.methods}
    assert reads - OTHERS.keys() - OWN == set(), "classify the new endpoint here"
    assert not OWN & OTHERS.keys()


@pytest.mark.parametrize("name", sorted(OTHERS))
def test_endpoints_with_other_peoples_rows_use_the_rule(name: str) -> None:
    [route] = [r for r in _routes() if r.endpoint.__name__ == name]
    assert OTHERS[name] in inspect.getsource(route.endpoint), name


@pytest.mark.parametrize(("module", "name"), sorted(HELPERS))
def test_the_helpers_apply_visible_and_not_blocked(module: str, name: str) -> None:
    package = "market_link" if module == "package" else "routers"
    mod = __import__(f"bagmitra_api.{package}.{module}", fromlist=[name])
    source = inspect.getsource(getattr(mod, name))
    for call in HELPERS[(module, name)]:
        assert call in source, (module, name, call)
