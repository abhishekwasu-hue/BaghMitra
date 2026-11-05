"""Structured JSON logging with request-id context."""

from __future__ import annotations

import logging
import sys

import structlog

# HTTP client libraries log every request URL at INFO, and those URLs carry third-party API
# keys (data.gov.in, Open-Meteo) and storage object paths with user ids (S-08).
QUIET_LOGGERS = ("httpx", "httpcore")


def configure_logging(level: str) -> None:
    log_level = logging.getLevelNamesMapping().get(level.upper(), logging.INFO)
    logging.basicConfig(format="%(message)s", stream=sys.stdout, level=log_level, force=True)
    for name in QUIET_LOGGERS:
        logging.getLogger(name).setLevel(max(logging.WARNING, log_level))
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(log_level),
        logger_factory=structlog.PrintLoggerFactory(file=sys.stdout),
        cache_logger_on_first_use=False,
    )
