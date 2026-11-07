from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from bagmitra_api.core.body_limit import BodyLimitMiddleware
from bagmitra_api.core.errors import install_error_handlers
from bagmitra_api.core.logging import configure_logging
from bagmitra_api.core.middleware import RequestIdMiddleware
from bagmitra_api.core.observability import init_error_reporting
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.routers import (
    admin_billing,
    admin_feed,
    admin_kb,
    admin_market,
    admin_market_link,
    admin_market_link_checks,
    admin_market_link_safety,
    admin_package,
    admin_web,
    app_release,
    billing,
    devices,
    feed,
    feed_check,
    feed_receipts,
    health,
    insurance,
    knowledge,
    market,
    market_deals,
    market_interests,
    market_link,
    market_link_profiles,
    market_link_registration,
    market_link_safety,
    market_lots,
    me,
    public_pages,
    reference,
    scouting_photos,
    sync,
    weather,
)


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    configure_logging(settings.log_level)
    init_error_reporting(settings)

    # OPS-07: no interactive docs or schema on the production server (they publish the whole
    # admin surface). The schema the app client is built from comes from `export_openapi`.
    public_docs = settings.environment != "production"
    app = FastAPI(
        title=f"{settings.product_name} API",
        version="0.1.0",
        docs_url="/docs" if public_docs else None,
        redoc_url="/redoc" if public_docs else None,
        openapi_url="/openapi.json" if public_docs else None,
    )
    app.dependency_overrides[get_settings] = lambda: settings
    if settings.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.cors_origins,
            allow_methods=["GET", "POST", "PUT", "DELETE"],
            allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
        )
    # Added first so it runs inside RequestIdMiddleware: a 413 still carries the request id.
    app.add_middleware(
        BodyLimitMiddleware,
        default_limit=settings.max_request_body_bytes,
        admin_limit=settings.max_admin_request_body_bytes,
    )
    app.add_middleware(RequestIdMiddleware)
    install_error_handlers(app)
    for module in (
        admin_billing,
        admin_feed,
        admin_kb,
        admin_market,
        admin_market_link,
        admin_market_link_checks,
        admin_market_link_safety,
        admin_package,
        admin_web,
        app_release,
        billing,
        devices,
        feed,
        feed_check,
        feed_receipts,
        health,
        insurance,
        knowledge,
        market,
        market_deals,
        market_interests,
        market_link,
        market_link_profiles,
        market_link_registration,
        market_link_safety,
        market_lots,
        me,
        public_pages,
        reference,
        scouting_photos,
        sync,
        weather,
    ):
        app.include_router(module.router)
    app.include_router(market_link_registration.admin_router)
    # Last, so `/admin/config.json` (admin_web router) wins over the static files.
    admin_files = admin_web.admin_web_files(settings)
    if admin_files is not None:
        app.mount(admin_web.MOUNT_PATH, admin_files, name="admin_web")
    return app
