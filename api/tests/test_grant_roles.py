"""The one-time role grant script, against a mocked Supabase Auth admin API."""

from __future__ import annotations

import json
from typing import Any

import httpx
import pytest

from bagmitra_api.auth import grant_roles

URL = "https://ref.supabase.co"
KEY = "fake-header.fake-payload.fake-signature"  # JWT-shaped, not a real key
OWNER_ID = "11111111-1111-1111-1111-111111111111"


class FakeAuth:
    def __init__(self, users: list[dict[str, Any]], *, status: int = 200) -> None:
        self.users = users
        self.status = status
        self.requests: list[httpx.Request] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        if self.status != 200:
            return httpx.Response(self.status, json={"msg": "nope"})
        if request.method == "GET" and request.url.path == "/auth/v1/admin/users":
            page = int(request.url.params["page"])
            per = int(request.url.params["per_page"])
            return httpx.Response(200, json={"users": self.users[(page - 1) * per : page * per]})
        if request.method == "PUT":
            user_id = request.url.path.rsplit("/", 1)[1]
            body = json.loads(request.content)
            for user in self.users:
                if user["id"] == user_id:
                    user["app_metadata"] = body["app_metadata"]
                    return httpx.Response(200, json=user)
        return httpx.Response(404)

    @property
    def transport(self) -> httpx.MockTransport:
        return httpx.MockTransport(self)


def owner(meta: Any) -> dict[str, Any]:
    return {"id": OWNER_ID, "email": "Owner@Example.com", "app_metadata": meta}


@pytest.fixture(autouse=True)
def service_key(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv(grant_roles.KEY_ENV, KEY)
    monkeypatch.delenv("SUPABASE_URL", raising=False)


def run(fake: FakeAuth, *args: str) -> int:
    return grant_roles.main(
        ["--supabase-url", URL, "--email", "owner@example.com", *args], transport=fake.transport
    )


def test_grants_the_default_roles_and_keeps_existing_metadata(
    capsys: pytest.CaptureFixture[str],
) -> None:
    others = [{"id": str(i), "email": f"u{i}@x.in", "app_metadata": {}} for i in range(450)]
    fake = FakeAuth([*others, owner({"provider": "email", "roles": ["kb_reviewer"]})])
    assert run(fake) == 0
    meta = fake.users[-1]["app_metadata"]
    assert meta == {
        "provider": "email",
        "roles": ["feed_admin", "kb_admin", "kb_reviewer", "market_admin"],
    }
    put = fake.requests[-1]
    assert put.method == "PUT"
    assert put.url == httpx.URL(f"{URL}/auth/v1/admin/users/{OWNER_ID}")
    assert put.headers["apikey"] == KEY
    assert put.headers["authorization"] == f"Bearer {KEY}"
    out = capsys.readouterr()
    assert "-> ['feed_admin', 'kb_admin', 'kb_reviewer', 'market_admin']" in out.out
    assert KEY not in out.out + out.err


def test_second_run_and_dry_run_write_nothing(capsys: pytest.CaptureFixture[str]) -> None:
    fake = FakeAuth([owner(None)])
    assert run(fake, "--dry-run") == 0
    assert all(r.method == "GET" for r in fake.requests)
    assert "dry run" in capsys.readouterr().out
    assert run(fake, "--roles", "feed_admin") == 0
    fake.requests.clear()
    assert run(fake, "--roles", "feed_admin") == 0
    assert all(r.method == "GET" for r in fake.requests)
    assert "nothing changed" in capsys.readouterr().out


def test_new_secret_key_goes_in_apikey_only(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv(grant_roles.KEY_ENV, "sb_secret_abc")
    fake = FakeAuth([owner({})])
    assert run(fake, "--roles", "kb_admin") == 0
    assert fake.requests[0].headers["apikey"] == "sb_secret_abc"
    assert "authorization" not in fake.requests[0].headers


@pytest.mark.parametrize(
    ("args", "message"),
    [
        (["--roles", "superuser"], "unknown role"),
        (["--roles", " , "], "unknown role"),
        (["--supabase-url", "http://ref.supabase.co"], "project URL"),
        (["--supabase-url", "https://ref.supabase.co/rest/v1"], "project URL"),
    ],
)
def test_bad_input_is_refused_before_any_call(
    args: list[str], message: str, capsys: pytest.CaptureFixture[str]
) -> None:
    fake = FakeAuth([owner({})])
    assert run(fake, *args) == 2
    assert message in capsys.readouterr().err
    assert fake.requests == []


def test_missing_key_unknown_user_and_refused_key(
    monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    assert run(FakeAuth([]), "--roles", "kb_admin") == 2
    assert "no Supabase user" in capsys.readouterr().err
    assert run(FakeAuth([], status=401)) == 2
    assert "refused the key" in capsys.readouterr().err
    assert run(FakeAuth([], status=500)) == 1
    err = capsys.readouterr().err
    assert "HTTPStatusError" in err
    assert KEY not in err
    monkeypatch.delenv(grant_roles.KEY_ENV)
    assert run(FakeAuth([owner({})])) == 2
    assert grant_roles.KEY_ENV in capsys.readouterr().err


def test_put_refused(capsys: pytest.CaptureFixture[str]) -> None:
    class ReadOnly(FakeAuth):
        def __call__(self, request: httpx.Request) -> httpx.Response:
            if request.method == "PUT":
                return httpx.Response(403)
            return super().__call__(request)

    assert run(ReadOnly([owner({})])) == 2
    assert "refused the key" in capsys.readouterr().err


def test_url_from_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("SUPABASE_URL", URL + "/")
    fake = FakeAuth([owner({})])
    args = ["--email", "owner@example.com", "--roles", "kb_admin"]
    assert grant_roles.main(args, transport=fake.transport) == 0
    assert fake.users[0]["app_metadata"]["roles"] == ["kb_admin"]


def test_remove_takes_only_the_named_roles_away(capsys: pytest.CaptureFixture[str]) -> None:
    fake = FakeAuth([owner({"provider": "email", "roles": ["feed_admin", "kb_admin"]})])
    assert run(fake, "--remove", "--roles", "kb_admin", "--dry-run") == 0
    assert all(r.method == "GET" for r in fake.requests)
    assert run(fake, "--remove", "--roles", "kb_admin") == 0
    assert fake.users[0]["app_metadata"] == {"provider": "email", "roles": ["feed_admin"]}
    assert "['feed_admin', 'kb_admin'] -> ['feed_admin']" in capsys.readouterr().out
    fake.requests.clear()
    assert run(fake, "--remove", "--roles", "kb_admin") == 0
    assert all(r.method == "GET" for r in fake.requests)
    assert "nothing changed" in capsys.readouterr().out


def test_remove_without_roles_is_refused(capsys: pytest.CaptureFixture[str]) -> None:
    fake = FakeAuth([owner({"roles": ["feed_admin"]})])
    assert run(fake, "--remove") == 2
    assert fake.requests == []
    assert "--remove needs --roles" in capsys.readouterr().err
