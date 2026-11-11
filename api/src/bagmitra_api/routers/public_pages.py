"""Public home (`/`) and privacy policy (`/privacy`) pages, needed for the Google OAuth consent
screen and the Play Store listing (OPEN_QUESTIONS Q49). Plain HTML: no auth, no scripts, no
external assets, and not part of the OpenAPI contract (the app never calls them).

The only setting shown is PRIVACY_CONTACT_EMAIL; nothing else from the environment is read.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from fastapi.responses import HTMLResponse

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.public_pages import home, privacy
from bagmitra_api.public_pages.layout import page

router = APIRouter(include_in_schema=False)

# These pages load nothing: no scripts, frames, images or forms; inline styles only.
HEADERS = {
    "Content-Security-Policy": (
        "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; "
        "form-action 'none'; frame-ancestors 'none'"
    ),
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
    "Cache-Control": "public, max-age=3600",
}

_LANG_LINKS = (
    '<nav class="lang"><a href="/privacy#mr" hreflang="mr">मराठी</a>'
    '<a href="/privacy?lang=en" hreflang="en">English</a></nav>'
)


def _html(content: str) -> HTMLResponse:
    return HTMLResponse(content, headers=HEADERS)


@router.api_route("/", methods=["GET", "HEAD"])
async def home_page() -> HTMLResponse:
    header = (
        "<h1>बागमित्र · BagMitra</h1>"
        "<p>संत्रा आणि मोसंबी बागायतदारांसाठी · for santra and mosambi growers</p>"
        f"{_LANG_LINKS}"
    )
    footer = '<a href="/privacy">गोपनीयता धोरण · Privacy policy</a>'
    return _html(page(lang="mr", title="BagMitra", header=header, body=home.BODY, footer=footer))


@router.api_route("/privacy", methods=["GET", "HEAD"])
async def privacy_page(
    settings: Annotated[Settings, Depends(get_settings)],
    lang: Annotated[str | None, Query(max_length=8)] = None,
) -> HTMLResponse:
    """Marathi then English on one page; `?lang=mr` or `?lang=en` shows one language (any
    other value shows both)."""
    email = settings.privacy_contact_email
    langs = [lang] if lang is not None and lang in {"mr", "en"} else ["mr", "en"]
    if langs == ["en"]:
        title, heading = "BagMitra privacy policy", "BagMitra privacy policy"
    else:
        title, heading = "बागमित्र गोपनीयता धोरण", "बागमित्र गोपनीयता धोरण"
    if len(langs) == 2:
        heading += " · Privacy policy"
    header = f"<h1>{heading}</h1>{_LANG_LINKS}"
    days = settings.sync_payload_retention_days
    photo_days = settings.photo_ai_retention_days
    body = "".join(privacy.section(code, email, days, photo_days) for code in langs)
    footer = '<a href="/">बागमित्र · BagMitra</a>'
    return _html(page(lang=langs[0], title=title, header=header, body=body, footer=footer))
