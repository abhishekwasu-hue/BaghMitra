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
    jwt_audience: str = "authenticated"

    cors_origins: list[str] = Field(default_factory=list)
    sentry_dsn: SecretStr | None = None

    sync_max_batch: int = 200

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
    kb_crop_groups: dict[str, list[str]] = Field(
        default_factory=lambda: {"santra": ["fruit_eaten_raw"], "mosambi": ["fruit_eaten_raw"]}
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
