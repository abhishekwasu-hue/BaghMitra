"""Runtime configuration. Every value comes from the environment (or `.env`)."""

from __future__ import annotations

import re
from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_EMAIL = re.compile(r"[^@\s<>\"'&]+@[^@\s<>\"'&]+\.[^@\s<>\"'&]+")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=(".env", "../product.env"), extra="ignore")

    product_name: str = "BagMitra"
    product_slug: str = "bagmitra"
    environment: Literal["local", "test", "staging", "production"] = "local"
    log_level: str = "INFO"

    database_url: str = "sqlite+aiosqlite:///./bagmitra-local.db"
    # Connection pool for PostgreSQL (audit OPS-10). Production reaches Supabase through the
    # Session pooler, where every open connection holds one of the project's pooler slots, and
    # the cron jobs (`docker compose exec`) open their own pool next to the API's. So the pool
    # stays small: at most db_pool_size + db_max_overflow connections per process. pre_ping
    # drops connections the pooler closed; recycle replaces them before an idle timeout does.
    # Ignored for SQLite (local runs and tests).
    db_pool_size: int = Field(default=5, ge=1, le=50)
    db_max_overflow: int = Field(default=5, ge=0, le=50)
    db_pool_timeout_seconds: float = Field(default=30.0, gt=0, le=300)
    db_pool_recycle_seconds: int = Field(default=1800, ge=-1)
    db_pool_pre_ping: bool = True

    supabase_jwt_secret: SecretStr = Field(default=SecretStr(""))
    # Supabase signs tokens with asymmetric keys (ES256/RS256) published here, e.g.
    # https://<ref>.supabase.co/auth/v1/.well-known/jwks.json. Empty: only the shared secret.
    supabase_jwks_url: str = ""
    jwt_audience: str = "authenticated"
    # Clock skew allowed on the token's exp / nbf / iat checks (audit LG-04): a VPS clock a
    # few seconds behind Supabase must not turn a just-issued token into a 401. Small on
    # purpose: an expired token stays usable for at most this long.
    jwt_leeway_seconds: int = Field(default=30, ge=0, le=300)
    # Ed25519 seed (URL-safe base64) that signs entitlement snapshots; empty = unsigned (dev).
    entitlement_signing_key: SecretStr = Field(default=SecretStr(""))

    cors_origins: list[str] = Field(default_factory=list)
    sentry_dsn: SecretStr | None = None

    # Request bodies (S-06): checked from Content-Length, and while streaming, before the body
    # is parsed; over the cap the API answers 413. Admin routes (feed documents up to 20 MB as
    # base64, KB CSV imports) get their own, larger cap.
    max_request_body_bytes: int = Field(default=3 * 1024 * 1024, ge=1024)
    max_admin_request_body_bytes: int = Field(default=40 * 1024 * 1024, ge=1024)

    sync_max_batch: int = 200
    # Sync payload caps (S-07), counted as compact UTF-8 JSON: one mutation over the first is
    # rejected as `payload_too_large`; a batch whose payloads add up to more than the second
    # is refused whole (413). Rejected payloads are stored only as a digest and a size.
    sync_max_payload_bytes: int = Field(default=64 * 1024, ge=256)
    sync_max_batch_payload_bytes: int = Field(default=2 * 1024 * 1024, ge=1024)
    # Rows per pull response; the phone keeps pulling from the returned cursor until empty.
    sync_pull_page_size: int = Field(default=500, ge=1)
    # Retention of the sync audit log (LD-09): the nightly job `bagmitra_api.sync.retention`
    # replaces the payload (farmer records, names, phone) of an applied or stale write older
    # than this with its {sha256, bytes} digest. The row stays (duplicate check, pull cursor);
    # the live records in the entity tables are not touched.
    sync_payload_retention_days: int = Field(default=90, ge=1)
    sync_retention_batch_size: int = Field(default=500, ge=1)

    # Weather (M4): free Open-Meteo endpoint by default; the commercial endpoint
    # (customer-api.open-meteo.com) needs WEATHER_API_KEY (OPEN_QUESTIONS Q25).
    weather_base_url: str = "https://api.open-meteo.com/v1"
    weather_api_key: SecretStr = Field(default=SecretStr(""))
    # Plots within one cell (lat/lon rounded to this many decimals, about 1 km) share a pull.
    weather_cell_decimals: int = 2
    weather_max_age_hours: int = 6
    weather_past_days: int = 7
    weather_forecast_days: int = 7

    # Market prices (M5): Agmarknet "current daily price" resource on data.gov.in. The key is
    # issued free on data.gov.in registration and stays out of git (OPEN_QUESTIONS Q26).
    market_api_base_url: str = "https://api.data.gov.in"
    market_resource_id: str = "9ef84268-d588-465a-a308-a864a43d0070"
    market_api_key: SecretStr = Field(default=SecretStr(""))
    # Empty = all India (owner, 2026-10-26: prices from all major mandis in the country).
    market_state: str = ""
    market_max_pages: int = 20
    # APMCs near the santra belt (SPEC_v1 §2), shown first. Matched as whole words in the
    # Agmarknet mandi name; the Kalamna yard is Nagpur APMC and is printed "APMC Nagpur"
    # (live pull 2026-11-07), so "Nagpur" is listed with it.
    market_local_markets: list[str] = Field(
        default_factory=lambda: ["Kalamna", "Nagpur", "Warud", "Katol", "Morshi", "Amravati"]
    )
    # Big terminal markets shown next (OPEN_QUESTIONS Q27: spellings to confirm on the first
    # live pull). Every other reporting mandi is still listed after these.
    market_major_markets: list[str] = Field(
        default_factory=lambda: [
            "Azadpur",
            "Mumbai",
            "Pune",
            "Nagpur",
            "Bangalore",
            "Chennai",
            "Hyderabad",
            "Kolkata",
            "Ahmedabad",
            "Jaipur",
            "Lucknow",
            "Indore",
        ]
    )
    # Stored prices count as current while the last successful scheduled pull (BG-04, cron
    # every 6 h: one missed run still stays inside) is younger than this.
    market_max_age_hours: int = 12
    # Per request to data.gov.in; one pull makes at most market_max_pages requests per commodity.
    market_timeout_seconds: float = Field(default=15.0, gt=0)
    # data.gov.in answers 502 to the default "python-httpx" User-Agent (seen from the VPS on
    # 2026-11-06; curl and other agents get 200 in under a second), so the pull names itself.
    market_user_agent: str = Field(
        default="BagMitra/1.0 (+https://bagmitra.aialgodesk.org)", min_length=1
    )
    market_window_days: int = 14
    # Our crop key -> Agmarknet commodity names.
    market_commodities: dict[str, list[str]] = Field(
        default_factory=lambda: {"santra": ["Orange"], "mosambi": ["Mousambi(Sweet Lime)"]}
    )

    # Knowledge base (addendum v1.3 §5-§6): review validity and licence span limit.
    kb_review_months_default: int = 12
    kb_review_months_chemical: int = 6
    kb_max_verbatim_words: int = 12
    # Our crop key -> crop names as written on CIB&RC labels, and crop groups used by
    # gazette restrictions (OPEN_QUESTIONS Q15, owner-confirmed: orange = santra/mandarin,
    # sweet lime = mosambi; WP4 owner order: mosambi also = sweet orange). Acid lime / lemon
    # are other crops. Unmapped label names never match, so the gate stays closed.
    kb_crop_label_aliases: dict[str, list[str]] = Field(
        default_factory=lambda: {
            "santra": ["citrus", "mandarin", "orange", "santra"],
            "mosambi": ["citrus", "sweet orange", "sweet lime", "mosambi"],
        }
    )
    # Reviewer roles accepted on a card review (addendum §6).
    kb_reviewer_roles: list[str] = Field(
        default_factory=lambda: ["agronomist", "plant_pathologist", "entomologist"]
    )
    kb_crop_groups: dict[str, list[str]] = Field(
        default_factory=lambda: {"santra": ["fruit_eaten_raw"], "mosambi": ["fruit_eaten_raw"]}
    )

    # Government feed (addendum v1.4). The AI summariser / classifier stays off unless
    # FEED_AI_API_KEY is set; the key is a secret and never leaves the environment.
    feed_ai_api_key: SecretStr = Field(default=SecretStr(""))
    feed_ai_base_url: str = "https://api.anthropic.com"
    feed_classify_model: str = "claude-haiku-5-5"
    feed_summarise_model: str = "claude-sonnet-5-5"
    feed_ai_max_tokens: int = 2000
    feed_ai_timeout_seconds: float = 60.0
    # Source text sent to the model is cut to this many characters (cost bound).
    feed_ai_max_source_chars: int = 60_000
    # Polite fetching: at least this long between two requests to one host, one try only.
    feed_fetch_min_interval_seconds: float = 5.0
    feed_fetch_timeout_seconds: float = 30.0
    feed_fetch_user_agent: str = "BagMitra-Feed/1.0 (+manual review; contact via repository)"
    feed_page_size: int = 50
    # "Check this message" (G3): requests per signed-in user per window (in memory, per API
    # process). The pasted text is never stored.
    feed_check_rate_limit: int = Field(default=20, ge=1)
    feed_check_rate_window_seconds: float = 3600.0
    # OCR for uploaded PDFs whose text layer is missing or broken Marathi (QG2). Off unless
    # set AND `tesseract` (with the language below) and `pdftoppm` are installed; local only.
    feed_ocr_enabled: bool = False
    feed_ocr_lang: str = "mar"
    feed_ocr_dpi: int = 300
    feed_ocr_max_pages: int = 40
    feed_ocr_timeout_seconds: float = 120.0
    # Mean word confidence (0-100) under which OCR text is flagged for the reviewer.
    feed_ocr_min_confidence: float = 70.0
    # Scheme names the output check knows (canonical -> other spellings). From addendum §3
    # secondary pages; spellings to be confirmed against the GRs (OPEN_QUESTIONS QG3).
    feed_scheme_glossary: dict[str, list[str]] = Field(
        default_factory=lambda: {
            "Namo Shetkari Mahasanman Nidhi": ["नमो शेतकरी महासन्मान निधी"],
            "Mukhyamantri Baliraja": ["मुख्यमंत्री बळीराजा"],
            "Bhausaheb Fundkar Falbag Lagvad": ["भाऊसाहेब फुंडकर फळबाग लागवड"],
            "PM-KISAN": ["PM KISAN", "पीएम किसान", "प्रधानमंत्री किसान सन्मान निधी"],
            "PMFBY": ["Pradhan Mantri Fasal Bima Yojana", "प्रधानमंत्री पीक विमा योजना"],
            "MIDH": ["Mission for Integrated Development of Horticulture"],
            "PMKSY": ["Per Drop More Crop", "प्रधानमंत्री कृषी सिंचाई योजना"],
        }
    )

    # Scouting photo backup (OPEN_QUESTIONS Q34): off unless all of URL and service key are
    # set. Photos go to a private Supabase Storage bucket through short-lived signed URLs only;
    # the service key never leaves the API and is never logged.
    photo_storage_url: str = ""
    photo_storage_bucket: str = "scouting-photos"
    photo_storage_service_key: SecretStr = Field(default=SecretStr(""))
    photo_max_bytes: int = Field(default=2 * 1024 * 1024, ge=1)
    photo_download_expiry_seconds: int = Field(default=300, ge=10)
    photo_storage_timeout_seconds: float = 15.0

    # Public privacy policy page (`GET /privacy`): the address people write to for access,
    # correction or deletion requests. Empty: the page says the contact is not published yet.
    privacy_contact_email: str = ""

    # Account deletion (`DELETE /v1/me`, S-10): the sign-in account itself lives in Supabase Auth
    # and needs the service role key to remove. Unless both are set, the API erases everything
    # it holds and leaves a follow-up row (account_deletions) for the owner to finish by hand.
    supabase_url: str = ""
    supabase_service_role_key: SecretStr = Field(default=SecretStr(""))
    supabase_admin_timeout_seconds: float = 15.0
    # Admin web (OPS-02): the Flutter web build served by this API at `/admin/` (same origin,
    # so no CORS). Empty dir or no index.html there: `/admin/` answers 404. The Supabase
    # project URL and its public anon (publishable) key are handed to the page at runtime by
    # `/admin/config.json`, so the build itself holds no environment values. Never the
    # service role key: the page runs in the browser.
    admin_web_dir: str = ""
    admin_web_supabase_url: str = ""
    admin_web_supabase_anon_key: str = ""
    # App update path (audit BG-06; runbooks release-apk.md and vps-deploy.md). The app asks
    # `GET /v1/app/version` on start: below the latest it shows an "update available" notice,
    # below the minimum a blocking screen. 0 = not set (no notice). `GET /app` serves
    # APP_DOWNLOAD_DIR/bagmitra.apk (a host folder mounted read-only). APP_DOWNLOAD_URL
    # overrides the link the app opens; empty = this API's own `/app`.
    app_latest_version_code: int = Field(default=0, ge=0)
    app_latest_version_name: str = ""
    app_min_version_code: int = Field(default=0, ge=0)
    app_download_dir: str = "/srv/bagmitra-apk"
    app_download_url: str = ""
    # Push alerts (audit BG-01, OPEN_QUESTIONS Q32; runbook docs/runbooks/push-notifications.md):
    # off unless FCM_PROJECT_ID and a service-account key are both set. The key is the
    # downloaded JSON file, base64-encoded in FCM_SERVICE_ACCOUNT_B64 (wins), or a path the API
    # can read in FCM_SERVICE_ACCOUNT_FILE. Never logged.
    fcm_project_id: str = ""
    fcm_service_account_b64: SecretStr = Field(default=SecretStr(""))
    fcm_service_account_file: str = ""
    fcm_base_url: str = "https://fcm.googleapis.com"
    fcm_timeout_seconds: float = Field(default=15.0, gt=0)

    @property
    def push_enabled(self) -> bool:
        has_key = bool(
            self.fcm_service_account_b64.get_secret_value().strip()
            or self.fcm_service_account_file.strip()
        )
        return bool(self.fcm_project_id.strip()) and has_key

    @property
    def photo_storage_enabled(self) -> bool:
        return bool(self.photo_storage_url and self.photo_storage_service_key.get_secret_value())

    @property
    def auth_admin_enabled(self) -> bool:
        return bool(self.supabase_url and self.supabase_service_role_key.get_secret_value())

    @model_validator(mode="after")
    def _min_not_above_latest(self) -> Settings:
        # A minimum above the latest would block every phone, even one on the newest APK.
        if self.app_min_version_code > self.app_latest_version_code:
            raise ValueError("APP_MIN_VERSION_CODE must not be above APP_LATEST_VERSION_CODE")
        return self

    @field_validator("privacy_contact_email")
    @classmethod
    def _plain_email(cls, value: str) -> str:
        value = value.strip()
        if value and not _EMAIL.fullmatch(value):
            raise ValueError("PRIVACY_CONTACT_EMAIL must be one plain email address")
        return value

    @field_validator("supabase_jwt_secret")
    @classmethod
    def _secret_long_enough(cls, value: SecretStr) -> SecretStr:
        if value.get_secret_value() and len(value.get_secret_value()) < 32:
            raise ValueError("SUPABASE_JWT_SECRET must be at least 32 characters")
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
