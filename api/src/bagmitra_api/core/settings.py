"""Runtime configuration. Every value comes from the environment (or `.env`)."""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=(".env", "../product.env"), extra="ignore")

    product_name: str = "BagMitra"
    product_slug: str = "bagmitra"
    environment: Literal["local", "test", "staging", "production"] = "local"
    log_level: str = "INFO"

    database_url: str = "sqlite+aiosqlite:///./bagmitra-local.db"

    supabase_jwt_secret: SecretStr = Field(default=SecretStr(""))
    # Supabase signs tokens with asymmetric keys (ES256/RS256) published here, e.g.
    # https://<ref>.supabase.co/auth/v1/.well-known/jwks.json. Empty: only the shared secret.
    supabase_jwks_url: str = ""
    jwt_audience: str = "authenticated"
    # Ed25519 seed (URL-safe base64) that signs entitlement snapshots; empty = unsigned (dev).
    entitlement_signing_key: SecretStr = Field(default=SecretStr(""))

    cors_origins: list[str] = Field(default_factory=list)
    sentry_dsn: SecretStr | None = None

    sync_max_batch: int = 200

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
    # APMCs near the santra belt (SPEC_v1 §2), shown first; names as Agmarknet spells them.
    market_local_markets: list[str] = Field(
        default_factory=lambda: ["Kalamna", "Warud", "Katol", "Morshi", "Amravati"]
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
    market_max_age_hours: int = 12
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
    # sweet lime = mosambi). Unmapped label names never match, so the gate stays closed.
    kb_crop_label_aliases: dict[str, list[str]] = Field(
        default_factory=lambda: {
            "santra": ["citrus", "mandarin", "orange", "santra"],
            "mosambi": ["citrus", "sweet lime", "mosambi"],
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

    @field_validator("supabase_jwt_secret")
    @classmethod
    def _secret_long_enough(cls, value: SecretStr) -> SecretStr:
        if value.get_secret_value() and len(value.get_secret_value()) < 32:
            raise ValueError("SUPABASE_JWT_SECRET must be at least 32 characters")
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
