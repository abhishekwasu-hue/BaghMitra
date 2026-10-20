"""Supabase projects sign access tokens with asymmetric keys (ES256 / RS256) published at a
JWKS URL, as well as the legacy shared secret (HS256). Both must verify; neither may be
confused for the other, and a missing or unreachable key set fails closed."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import time
import uuid
from typing import Any

import httpx
import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import (
    Encoding,
    NoEncryption,
    PrivateFormat,
    PublicFormat,
)
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.auth.jwt import JwksKeys, get_jwks, verify_token_async
from bagmitra_api.core.errors import ApiError
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET, make_token


def new_key(kid: str) -> tuple[Any, dict[str, Any]]:
    private = ec.generate_private_key(ec.SECP256R1())
    jwk = json.loads(jwt.algorithms.ECAlgorithm.to_jwk(private.public_key()))
    jwk.update({"kid": kid, "alg": "ES256", "use": "sig"})
    return private, jwk


def sign(private: Any, kid: str, sub: uuid.UUID, **extra: Any) -> str:
    now = int(time.time())
    claims = {"sub": str(sub), "aud": "authenticated", "iat": now, "exp": now + 3600, **extra}
    pem = private.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption())
    return jwt.encode(claims, pem, algorithm="ES256", headers={"kid": kid})


class FakeJwks:
    """A key-set endpoint whose contents the test controls, counting the requests it gets."""

    def __init__(self, *jwks: dict[str, Any]) -> None:
        self.keys = list(jwks)
        self.calls = 0
        self.down = False

    async def __call__(self) -> dict[str, Any]:
        self.calls += 1
        if self.down:
            raise httpx.ConnectError("jwks unreachable")
        return {"keys": self.keys}


def settings(**extra: Any) -> Settings:
    return Settings(
        supabase_jwt_secret=JWT_SECRET,
        supabase_jwks_url="https://project.supabase.co/auth/v1/.well-known/jwks.json",
        **extra,
    )


async def test_an_es256_token_is_verified_with_the_published_key() -> None:
    private, jwk = new_key("k1")
    user = uuid.uuid4()
    keys = JwksKeys(FakeJwks(jwk))
    verified = await verify_token_async(
        sign(private, "k1", user, phone="919800000000", app_metadata={"roles": ["kb_admin"]}),
        settings(),
        keys,
    )
    assert verified.id == user
    assert verified.phone == "919800000000"
    assert verified.roles == frozenset({"kb_admin"})


async def test_the_key_set_is_cached_between_requests() -> None:
    private, jwk = new_key("k1")
    source = FakeJwks(jwk)
    keys = JwksKeys(source)
    for _ in range(3):
        await verify_token_async(sign(private, "k1", uuid.uuid4()), settings(), keys)
    assert source.calls == 1


async def test_a_rotated_key_is_picked_up_without_a_restart() -> None:
    old_private, old_jwk = new_key("old")
    new_private, new_jwk = new_key("new")
    source = FakeJwks(old_jwk)
    keys = JwksKeys(source, min_refresh_seconds=0)
    await verify_token_async(sign(old_private, "old", uuid.uuid4()), settings(), keys)
    source.keys = [old_jwk, new_jwk]  # the project rotated its signing key
    await verify_token_async(sign(new_private, "new", uuid.uuid4()), settings(), keys)
    assert source.calls == 2


async def test_an_unknown_key_id_is_rejected_and_cannot_hammer_the_endpoint() -> None:
    private, jwk = new_key("k1")
    other, _ = new_key("other")
    source = FakeJwks(jwk)
    keys = JwksKeys(source, min_refresh_seconds=300)
    await verify_token_async(sign(private, "k1", uuid.uuid4()), settings(), keys)
    for _ in range(5):
        with pytest.raises(ApiError) as err:
            await verify_token_async(sign(other, "nope", uuid.uuid4()), settings(), keys)
        assert err.value.status_code == 401
    assert source.calls == 1  # unknown ids inside the refresh window do not refetch


async def test_a_token_signed_by_a_different_key_with_a_known_id_is_rejected() -> None:
    _, jwk = new_key("k1")
    attacker, _ = new_key("k1")
    with pytest.raises(ApiError):
        await verify_token_async(
            sign(attacker, "k1", uuid.uuid4()), settings(), JwksKeys(FakeJwks(jwk))
        )


async def test_an_unreachable_key_set_fails_closed() -> None:
    private, jwk = new_key("k1")
    source = FakeJwks(jwk)
    source.down = True
    with pytest.raises(ApiError) as err:
        await verify_token_async(sign(private, "k1", uuid.uuid4()), settings(), JwksKeys(source))
    assert err.value.status_code == 401


async def test_asymmetric_tokens_are_refused_when_no_key_set_is_configured() -> None:
    private, jwk = new_key("k1")
    with pytest.raises(ApiError):
        await verify_token_async(
            sign(private, "k1", uuid.uuid4()),
            Settings(supabase_jwt_secret=JWT_SECRET),
            JwksKeys(FakeJwks(jwk)),
        )


async def test_the_public_key_cannot_be_used_as_an_hmac_secret() -> None:
    """Classic algorithm-confusion attack: sign HS256 with the public key as the secret."""
    private, jwk = new_key("k1")
    public_pem = private.public_key().public_bytes(Encoding.PEM, PublicFormat.SubjectPublicKeyInfo)
    header = {"alg": "HS256", "typ": "JWT", "kid": "k1"}
    payload = {"sub": str(uuid.uuid4()), "aud": "authenticated", "exp": int(time.time()) + 3600}

    def b64(data: dict[str, Any]) -> bytes:
        return base64.urlsafe_b64encode(json.dumps(data).encode()).rstrip(b"=")

    signing_input = b64(header) + b"." + b64(payload)
    signature = base64.urlsafe_b64encode(
        hmac.new(public_pem, signing_input, hashlib.sha256).digest()
    ).rstrip(b"=")
    forged = (signing_input + b"." + signature).decode()
    with pytest.raises(ApiError):
        await verify_token_async(forged, settings(), JwksKeys(FakeJwks(jwk)))


async def test_the_legacy_shared_secret_still_works_and_unsigned_tokens_do_not() -> None:
    user = uuid.uuid4()
    verified = await verify_token_async(make_token(user), settings(), JwksKeys(FakeJwks()))
    assert verified.id == user
    unsigned = jwt.encode(
        {"sub": str(user), "aud": "authenticated", "exp": int(time.time()) + 60},
        key="",
        algorithm="none",
    )
    with pytest.raises(ApiError):
        await verify_token_async(unsigned, settings(), JwksKeys(FakeJwks()))


async def test_expired_and_wrong_audience_asymmetric_tokens_are_rejected() -> None:
    private, jwk = new_key("k1")
    keys = JwksKeys(FakeJwks(jwk))
    for extra in ({"exp": int(time.time()) - 10}, {"aud": "anon"}):
        with pytest.raises(ApiError):
            await verify_token_async(sign(private, "k1", uuid.uuid4(), **extra), settings(), keys)


async def test_the_api_accepts_an_asymmetric_token_end_to_end(engine: AsyncEngine) -> None:
    private, jwk = new_key("k1")
    cfg = settings()
    app = create_app(cfg)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: cfg
    keys = JwksKeys(FakeJwks(jwk))
    app.dependency_overrides[get_jwks] = lambda: keys
    token = sign(private, "k1", uuid.uuid4())
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 404  # signed in, no profile yet; a 401 would mean rejected
