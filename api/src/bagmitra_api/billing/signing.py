"""Server-signed entitlement snapshots (billing addendum §2.3). The app caches a snapshot to
keep features working offline; the Ed25519 signature lets it detect a tampered cache. The
private key lives only in the API's environment; the app carries the public key."""

from __future__ import annotations

import base64
import json
from typing import Any

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import (
    Encoding,
    NoEncryption,
    PrivateFormat,
    PublicFormat,
)


def canonical(payload: dict[str, Any]) -> bytes:
    """One stable byte form of a snapshot (sorted keys, no spaces) so both sides sign and verify
    the same bytes."""
    return json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _unb64(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def generate_signing_key() -> tuple[str, str]:
    """A new key pair as (private seed, public key), both URL-safe base64."""
    private = Ed25519PrivateKey.generate()
    seed = private.private_bytes(Encoding.Raw, PrivateFormat.Raw, NoEncryption())
    public = private.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw)
    return _b64(seed), _b64(public)


def sign_snapshot(payload: dict[str, Any], seed: str) -> str:
    return _b64(Ed25519PrivateKey.from_private_bytes(_unb64(seed)).sign(canonical(payload)))
