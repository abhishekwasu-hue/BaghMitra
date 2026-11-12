from __future__ import annotations

from collections.abc import AsyncIterator

import httpx
import pytest
from pydantic import ValidationError

from bagmitra_api.core.settings import Settings
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET

MR_SECTIONS = [
    "mr-collect",
    "mr-where",
    "mr-share",
    "mr-keep",
    "mr-rights",
    "mr-delete",
    "mr-children",
    "mr-security",
    "mr-changes",
    "mr-contact",
]
EN_SECTIONS = [s.replace("mr-", "en-") for s in MR_SECTIONS]
THIRD_PARTIES = ["Supabase", "Google", "Open-Meteo", "data.gov.in", "Anthropic", "Sentry"]

# Values that must never reach a public page.
SECRETS = {
    "database_url": "postgresql+asyncpg://postgres:db-pass-XYZ123@db.refabc.supabase.co:5432/x",
    "supabase_jwks_url": "https://refabc.supabase.co/auth/v1/.well-known/jwks.json",
    "entitlement_signing_key": "ent-signing-key-QWE987",
    "market_api_key": "market-key-ASD456",
    "weather_api_key": "weather-key-ZXC321",
    "feed_ai_api_key": "feed-ai-key-RTY654",
    "photo_storage_url": "https://refabc.supabase.co",
    "photo_storage_service_key": "photo-service-key-FGH852",
    "sentry_dsn": "https://sentrykey@o1.ingest.sentry.io/42",
}


async def _client(settings: Settings) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=create_app(settings))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
async def pages(settings: Settings) -> AsyncIterator[httpx.AsyncClient]:
    async for c in _client(settings):
        yield c


async def test_home_page_is_html_and_links_to_privacy(pages: httpx.AsyncClient) -> None:
    resp = await pages.get("/")
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("text/html")
    assert "बागमित्र" in resp.text
    assert "BagMitra" in resp.text
    assert 'href="/privacy#mr"' in resp.text
    assert 'href="/privacy?lang=en"' in resp.text


async def test_privacy_page_has_both_languages_and_every_section(
    pages: httpx.AsyncClient,
) -> None:
    resp = await pages.get("/privacy")
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("text/html")
    body = resp.text
    assert '<section id="mr" lang="mr">' in body
    assert '<section id="en" lang="en">' in body
    assert body.index('id="mr"') < body.index('id="en"')
    for anchor in MR_SECTIONS + EN_SECTIONS:
        assert f'id="{anchor}"' in body, anchor
    for name in THIRD_PARTIES:
        assert name in body, name
    assert "३० दिवसांत" in body
    assert "within 30 days" in body
    assert "Last updated" in body
    assert "शेवटचा बदल" in body


async def test_privacy_page_matches_the_code(pages: httpx.AsyncClient) -> None:
    """P-1..P-7: the statements the audit found untrue now match what the code does."""
    body = (await pages.get("/privacy")).text
    # P-5 / OPS-01: no IP in logs, logs capped.
    assert "address (IP)" not in body
    assert "पत्ता (IP)" not in body
    assert "They do not contain your IP address" in body
    assert "IP पत्ता, query आणि नोंदींचा मजकूर log मध्ये नसतो" in body
    # P-3 / S-10: deletion inside the app; P-2 / S-9: no Android backup; OPS-06: 14 days.
    assert "Delete my account and data" in body
    assert "माझे खाते आणि माहिती काढून टाका" in body
    assert "not included in Android" in body
    assert "kept for 14 days" in body
    assert "१४ दिवस ठेवला जातो" in body
    # P-7 / S-07: rejected changes are not kept in full.
    assert "only a fingerprint (hash)" in body
    # LD-09: the sync history's contents are erased after the configured days.
    assert "erased after 90 days" in body
    assert "९० दिवसांनंतर पुसला जातो" in body
    # P-6: both link lifetimes.
    assert "within two hours" in body
    # P-1 / S-02: the Data API is closed.
    assert "closed to app sign-ins" in body
    assert "by database row-level security" not in body


async def test_privacy_page_covers_crop_photo_analysis() -> None:
    """Q135: one-time consent at signup; AI analysis; kept PHOTO_AI_RETENTION_DAYS; deletable."""
    cfg = Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        photo_ai_retention_days=400,
    )
    async for client in _client(cfg):
        body = (await client.get("/privacy")).text
    assert "then an AI service (Anthropic) analyses it" in body
    assert "AI सेवा (Anthropic) तो फोटो तपासते" in body
    assert "kept for 400 days from the analysis" in body
    assert "तपासणीपासून ४०० दिवस ठेवले" in body
    assert "Delete this photo" in body
    assert "हा फोटो हटवा' बटणाने फोटो पुसता" in body
    assert "not asked again for each photo" in body
    assert "प्रत्येक फोटोसाठी" in body
    assert "(EXIF) are removed first" in body


async def test_privacy_page_covers_bill_reading() -> None:
    """Q136: a bill photo is sent to Anthropic only to read it and is not kept on the server."""
    cfg = Settings(
        environment="test", database_url="sqlite+aiosqlite://", supabase_jwt_secret=JWT_SECRET
    )
    async for client in _client(cfg):
        body = (await client.get("/privacy")).text
    assert "sent to an AI service (Anthropic) only to read the bill" in body
    assert "sent for reading and what is read from it are not kept on the server" in body
    assert "बिल वाचण्यासाठी तो AI सेवेकडे (Anthropic) जातो" in body
    assert "सर्व्हरवर ठेवली जात नाही" in body
    # The bill photo kept with a record follows the scouting photo backup (Q136, app PR).
    assert "bill photos kept with a spray record or an expense" in body
    assert "is backed up only when photo\nbackup is on" in body
    assert "a\nbacked-up copy is erased with the account" in body
    assert "बिलांचे फोटो" in body
    assert "फक्त फोटो बॅकअप चालू असल्यास" in body
    assert "bill photos sent to be read (without EXIF)" in body
    assert "Your signup consent covers this.</li>" in body


async def test_privacy_page_covers_reactions(pages: httpx.AsyncClient) -> None:
    """Q146: reactions are stored per user, used only as totals and erased with the account."""
    body = (await pages.get("/privacy")).text
    assert "The reaction you give after reading an article or an answer" in body
    assert (
        "only the totals are used, who chose what is never shown. Erased\nwith the account." in body
    )
    assert "वाचून तुम्ही दिलेला प्रतिसाद" in body
    assert "खाते काढल्यावर पुसला जातो." in body


@pytest.mark.parametrize(("lang", "present", "absent"), [("en", "en", "mr"), ("mr", "mr", "en")])
async def test_privacy_page_one_language(
    pages: httpx.AsyncClient, lang: str, present: str, absent: str
) -> None:
    resp = await pages.get("/privacy", params={"lang": lang})
    assert resp.status_code == 200
    assert f'<section id="{present}"' in resp.text
    assert f'<section id="{absent}"' not in resp.text
    assert f'<html lang="{lang}">' in resp.text


async def test_unknown_language_shows_both(pages: httpx.AsyncClient) -> None:
    resp = await pages.get("/privacy", params={"lang": "hi"})
    assert resp.status_code == 200
    assert '<section id="mr"' in resp.text
    assert '<section id="en"' in resp.text


async def test_contact_fallback_when_email_unset(pages: httpx.AsyncClient) -> None:
    body = (await pages.get("/privacy")).text
    assert "mailto:" not in body
    assert "not published here yet" in body
    assert "अजून इथे प्रसिद्ध केलेला नाही" in body


async def test_contact_email_from_setting_and_no_other_env_values() -> None:
    settings = Settings(
        environment="test",
        database_url=SECRETS["database_url"],
        supabase_jwt_secret=JWT_SECRET,
        supabase_jwks_url=SECRETS["supabase_jwks_url"],
        entitlement_signing_key=SECRETS["entitlement_signing_key"],
        market_api_key=SECRETS["market_api_key"],
        weather_api_key=SECRETS["weather_api_key"],
        feed_ai_api_key=SECRETS["feed_ai_api_key"],
        photo_storage_url=SECRETS["photo_storage_url"],
        photo_storage_service_key=SECRETS["photo_storage_service_key"],
        sentry_dsn=None,
        privacy_contact_email="privacy@example.org",
        log_level="WARNING",
    )
    async for c in _client(settings):
        texts = [(await c.get(path)).text for path in ("/", "/privacy", "/privacy?lang=en")]
    privacy_body = texts[1]
    assert 'href="mailto:privacy@example.org"' in privacy_body
    assert "not published here yet" not in privacy_body
    for text in texts:
        for value in [*SECRETS.values(), JWT_SECRET, "refabc"]:
            assert value not in text


async def test_pages_need_no_auth_load_nothing_and_skip_openapi(pages: httpx.AsyncClient) -> None:
    for path in ("/", "/privacy"):
        resp = await pages.get(path)
        assert resp.status_code == 200
        assert "<script" not in resp.text
        assert "src=" not in resp.text
        assert "http://" not in resp.text
        assert "https://" not in resp.text
        assert "default-src 'none'" in resp.headers["content-security-policy"]
        assert resp.headers["x-content-type-options"] == "nosniff"
        assert resp.headers["x-request-id"]
        # Raised from 30 000 for the crop photo analysis text (Q135; Marathi is 3 bytes a letter),
        # and to 35 000 for the reactions line (Q146).
        assert len(resp.content) < 35_000
        head = await pages.head(path)
        assert head.status_code == 200
    spec = (await pages.get("/openapi.json")).json()
    assert "/" not in spec["paths"]
    assert "/privacy" not in spec["paths"]


async def test_cors_headers_still_applied(settings: Settings) -> None:
    settings.cors_origins = ["https://admin.example.org"]
    async for c in _client(settings):
        resp = await c.get("/privacy", headers={"Origin": "https://admin.example.org"})
    assert resp.status_code == 200
    assert resp.headers["access-control-allow-origin"] == "https://admin.example.org"


def test_contact_email_setting_rejects_markup() -> None:
    with pytest.raises(ValidationError):
        Settings(privacy_contact_email='<b>x</b>@example.org"')
    assert Settings(privacy_contact_email="  a@b.in ").privacy_contact_email == "a@b.in"
