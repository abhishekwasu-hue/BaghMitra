"""Market linkage L1: terms / privacy / disclaimer acceptance per role with the 18+
declaration (spec v1.5 §4C), and the `require_role_accepted` gate for later writes."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime
from typing import Annotated, get_args

import httpx
import pytest
from fastapi import Depends, FastAPI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.auth.jwt import AuthenticatedUser
from bagmitra_api.core.errors import install_error_handlers
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import TERMS_ROLES, TermsAcceptance
from bagmitra_api.market_link.terms import require_role_accepted
from bagmitra_api.routers.market_link import Role
from bagmitra_api.weather.service import get_clock
from tests.conftest import make_token

NOW = datetime(2026, 11, 7, 10, 30, tzinfo=UTC)
Maker = async_sessionmaker[AsyncSession]
V1 = {"terms_version": "1", "privacy_version": "1", "disclaimer_version": "1"}


def _accept(role: str = "trader", **extra: object) -> dict[str, object]:
    return {"role": role, "adult_declared": True, **V1, **extra}


@pytest.fixture
def user() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def headers(user: uuid.UUID) -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(user)}"}


@pytest.fixture
def maker(engine: AsyncEngine) -> Maker:
    return async_sessionmaker(engine, expire_on_commit=False)


async def _client(
    settings: Settings,
    maker: Maker,
    **update: object,
) -> httpx.AsyncClient:
    app = create_app(settings.model_copy(update={"market_link_enabled": True, **update}))
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_clock] = lambda: lambda: NOW
    return httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test")


@pytest.fixture
async def on(
    settings: Settings,
    maker: Maker,
) -> AsyncIterator[httpx.AsyncClient]:
    async with await _client(settings, maker) as c:
        yield c


def test_role_literal_matches_the_table_check() -> None:
    assert set(get_args(Role)) == set(TERMS_ROLES)


async def test_flag_off_hides_every_terms_endpoint(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    for method, path in (
        ("GET", "/v1/market-link/terms"),
        ("GET", "/v1/market-link/me/acceptances"),
        ("POST", "/v1/market-link/terms/accept"),
    ):
        response = await client.request(method, path, headers=auth_headers, json=_accept())
        assert response.status_code == 404, (path, response.text)


async def test_current_documents_and_owner_as_default_grievance_officer(
    on: httpx.AsyncClient, headers: dict[str, str]
) -> None:
    body = (await on.get("/v1/market-link/terms", headers=headers)).json()
    assert body["documents"] == [
        {"kind": "terms", "version": "1", "url": None},
        {"kind": "privacy", "version": "1", "url": "/privacy"},
        {"kind": "disclaimer", "version": "1", "url": None},
    ]
    assert body["grievance_officer"] == {"name": None, "contact": None}
    assert (await on.get("/v1/market-link/terms")).status_code == 401


async def test_grievance_officer_and_terms_page_come_from_settings(
    settings: Settings,
    maker: Maker,
    headers: dict[str, str],
) -> None:
    async with await _client(settings, maker, privacy_contact_email="help@example.test") as c:
        officer = (await c.get("/v1/market-link/terms", headers=headers)).json()
        assert officer["grievance_officer"] == {"name": None, "contact": "help@example.test"}
    async with await _client(
        settings,
        maker,
        market_link_grievance_name="A. Officer",
        market_link_grievance_contact="+91 90000 00000",
        market_link_terms_url="https://example.test/terms",
    ) as c:
        body = (await c.get("/v1/market-link/terms", headers=headers)).json()
        assert body["grievance_officer"] == {"name": "A. Officer", "contact": "+91 90000 00000"}
        assert body["documents"][0]["url"] == "https://example.test/terms"


async def test_acceptance_is_stored_per_document_with_version_and_time(
    on: httpx.AsyncClient,
    headers: dict[str, str],
    user: uuid.UUID,
    maker: Maker,
) -> None:
    mine = await on.get("/v1/market-link/me/acceptances", headers=headers)
    assert mine.json() == {"roles": [], "acceptances": []}
    response = await on.post("/v1/market-link/terms/accept", headers=headers, json=_accept())
    assert response.status_code == 200, response.text
    assert response.json()["roles"] == ["trader"]
    # A retry (offline acceptance posted twice) adds nothing.
    again = await on.post("/v1/market-link/terms/accept", headers=headers, json=_accept())
    assert again.status_code == 200
    async with maker() as session:
        rows = list(await session.scalars(select(TermsAcceptance)))
    assert sorted((r.role, r.doc_kind, r.version) for r in rows) == [
        ("trader", "disclaimer", "1"),
        ("trader", "privacy", "1"),
        ("trader", "terms", "1"),
    ]
    assert all(r.user_id == user and r.adult_declared for r in rows)
    assert {r.accepted_at.replace(tzinfo=UTC) for r in rows} == {NOW}
    listed = (await on.get("/v1/market-link/me/acceptances", headers=headers)).json()
    assert listed["roles"] == ["trader"]
    assert len(listed["acceptances"]) == 3


@pytest.mark.parametrize(
    "body",
    [
        {k: v for k, v in _accept().items() if k != "adult_declared"},
        _accept(adult_declared=False),
        {k: v for k, v in _accept().items() if k != "privacy_version"},
        _accept(role="admin"),
        _accept(commission_pct=2),
        _accept(extra={"brokerage": 1}),
        _accept(aadhaar_number="1234"),
        _accept(note="free text"),
    ],
)
async def test_invalid_acceptance_is_refused(
    on: httpx.AsyncClient, headers: dict[str, str], body: dict[str, object]
) -> None:
    response = await on.post("/v1/market-link/terms/accept", headers=headers, json=body)
    assert response.status_code == 422, response.text
    mine = (await on.get("/v1/market-link/me/acceptances", headers=headers)).json()
    assert mine["acceptances"] == []


async def test_version_bump_requires_acceptance_again(
    settings: Settings,
    maker: Maker,
    on: httpx.AsyncClient,
    headers: dict[str, str],
) -> None:
    assert (
        await on.post("/v1/market-link/terms/accept", headers=headers, json=_accept())
    ).status_code == 200
    async with await _client(settings, maker, market_link_privacy_version="2") as bumped:
        mine = (await bumped.get("/v1/market-link/me/acceptances", headers=headers)).json()
        assert mine["roles"] == []
        stale = await bumped.post("/v1/market-link/terms/accept", headers=headers, json=_accept())
        assert stale.status_code == 409
        assert stale.json()["error"]["code"] == "terms_version_changed"
        fresh = await bumped.post(
            "/v1/market-link/terms/accept",
            headers=headers,
            json=_accept(privacy_version="2"),
        )
        assert fresh.json()["roles"] == ["trader"]
    async with maker() as session:
        kinds = sorted(
            (r.doc_kind, r.version) for r in await session.scalars(select(TermsAcceptance))
        )
    assert kinds == [("disclaimer", "1"), ("privacy", "1"), ("privacy", "2"), ("terms", "1")]


def _gated_app(settings: Settings, maker: Maker) -> FastAPI:
    app = FastAPI()
    install_error_handlers(app)

    @app.post("/write")
    async def write(
        user: Annotated[AuthenticatedUser, Depends(require_role_accepted("trader"))],
    ) -> dict[str, str]:
        return {"user": str(user.id)}

    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    return app


async def test_require_role_accepted_blocks_writes_until_current_terms_accepted(
    settings: Settings,
    maker: Maker,
    on: httpx.AsyncClient,
    headers: dict[str, str],
) -> None:
    gated = _gated_app(settings, maker)
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=gated), base_url="http://test"
    ) as c:
        blocked = await c.post("/write", headers=headers)
        assert blocked.status_code == 403
        assert blocked.json()["error"]["code"] == "terms_not_accepted"
        # Another role's acceptance does not open this one.
        await on.post("/v1/market-link/terms/accept", headers=headers, json=_accept("broker"))
        assert (await c.post("/write", headers=headers)).status_code == 403
        await on.post("/v1/market-link/terms/accept", headers=headers, json=_accept())
        assert (await c.post("/write", headers=headers)).status_code == 200
    gated.dependency_overrides[get_settings] = lambda: settings.model_copy(
        update={"market_link_terms_version": "2"}
    )
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=gated), base_url="http://test"
    ) as c:
        again = await c.post("/write", headers=headers)
        assert again.status_code == 403
        assert again.json()["error"]["code"] == "terms_not_accepted"


def test_require_role_accepted_refuses_an_unknown_role() -> None:
    with pytest.raises(ValueError, match="unknown"):
        require_role_accepted("admin")
