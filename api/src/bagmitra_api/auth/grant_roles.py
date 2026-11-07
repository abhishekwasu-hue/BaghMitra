"""Grant admin roles to one Supabase user (OPS-02; runbook docs/runbooks/admin-web.md).

Run once by hand, inside the API container on the server:

    cd /opt/bagmitra/deploy
    read -rs SUPABASE_SERVICE_ROLE_KEY && export SUPABASE_SERVICE_ROLE_KEY
    docker compose exec -T -e SUPABASE_SERVICE_ROLE_KEY api \\
        python -m bagmitra_api.auth.grant_roles \\
        --supabase-url https://<project-ref>.supabase.co --email owner@example.com
    unset SUPABASE_SERVICE_ROLE_KEY

The service role key is read from the environment only: never an argument (it would land in
the shell history and the process list), never stored, never printed. The script finds the
user by email with the Auth admin API and adds the roles to `app_metadata.roles`, keeping every
role (and every other app_metadata key) already there. `--remove --roles <list>` takes the
listed roles away instead and keeps the rest (audit LG-07). `--dry-run` only shows the change.
The user signs out and in again so the new access token carries the change; until then (at
most the token's lifetime) the old token keeps the old roles.
"""

from __future__ import annotations

import argparse
import os
import sys
from collections.abc import Sequence
from typing import Any
from urllib.parse import urlsplit

import httpx

KEY_ENV = "SUPABASE_SERVICE_ROLE_KEY"
# Every role the API checks (`require_role` in routers/admin_*.py).
KNOWN_ROLES = frozenset(
    {"billing_admin", "feed_admin", "kb_admin", "kb_reviewer", "market_admin", "market_link_admin"}
)
DEFAULT_ROLES = ("feed_admin", "market_admin", "kb_admin")
PER_PAGE = 200
MAX_PAGES = 500


class GrantError(Exception):
    """A problem the owner can fix (shown as one line, never with the key)."""


def _headers(key: str) -> dict[str, str]:
    # A legacy service_role key is a JWT and also goes in Authorization; a new `sb_secret_`
    # key is sent as `apikey` only.
    headers = {"apikey": key}
    if key.count(".") == 2:
        headers["Authorization"] = f"Bearer {key}"
    return headers


def _check_url(url: str) -> str:
    parts = urlsplit(url.strip())
    if parts.scheme != "https" or not parts.netloc or parts.path not in ("", "/"):
        raise GrantError("--supabase-url must be the project URL, e.g. https://<ref>.supabase.co")
    return f"https://{parts.netloc}"


def _check_roles(roles: Sequence[str]) -> list[str]:
    cleaned = sorted({r.strip() for r in roles if r.strip()})
    unknown = [r for r in cleaned if r not in KNOWN_ROLES]
    if unknown or not cleaned:
        raise GrantError(f"unknown role(s) {unknown}; choose from {sorted(KNOWN_ROLES)}")
    return cleaned


def find_user(client: httpx.Client, email: str) -> dict[str, Any]:
    wanted = email.strip().lower()
    for page in range(1, MAX_PAGES + 1):
        res = client.get("/auth/v1/admin/users", params={"page": page, "per_page": PER_PAGE})
        if res.status_code in (401, 403):
            raise GrantError("Supabase refused the key: use the service role (secret) key")
        res.raise_for_status()
        users = res.json().get("users") or []
        for user in users:
            if str(user.get("email") or "").lower() == wanted:
                return dict(user)
        if len(users) < PER_PAGE:
            break
    raise GrantError(f"no Supabase user with email {email}; create the staff account first")


def grant(
    client: httpx.Client,
    email: str,
    roles: Sequence[str],
    *,
    dry_run: bool = False,
    remove: bool = False,
) -> tuple[list[str], list[str]]:
    """Return (roles before, roles after) for the user; writes only when something changes.
    With `remove` the roles are taken away instead of added."""
    user = find_user(client, email)
    meta = user.get("app_metadata")
    meta = meta if isinstance(meta, dict) else {}
    current = meta.get("roles")
    before = sorted(r for r in current if isinstance(r, str)) if isinstance(current, list) else []
    after = sorted(set(before) - set(roles)) if remove else sorted(set(before) | set(roles))
    if after != before and not dry_run:
        # The whole app_metadata goes back with only `roles` changed, so every other key is
        # kept whether the server merges or replaces it.
        body = {"app_metadata": {**meta, "roles": after}}
        res = client.put(f"/auth/v1/admin/users/{user['id']}", json=body)
        if res.status_code in (401, 403):
            raise GrantError("Supabase refused the key: use the service role (secret) key")
        res.raise_for_status()
    return before, after


def main(argv: Sequence[str] | None = None, *, transport: httpx.BaseTransport | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--supabase-url", default=os.environ.get("SUPABASE_URL", ""))
    parser.add_argument("--email", required=True)
    parser.add_argument(
        "--roles", default=None, help=f"comma separated (default {','.join(DEFAULT_ROLES)})"
    )
    parser.add_argument(
        "--remove", action="store_true", help="take the --roles away instead of adding them"
    )
    parser.add_argument("--dry-run", action="store_true", help="show the change, write nothing")
    args = parser.parse_args(argv)
    key = os.environ.get(KEY_ENV, "").strip()
    try:
        if not key:
            raise GrantError(f"set {KEY_ENV} in the environment (read -rs, never an argument)")
        base_url = _check_url(args.supabase_url)
        if args.remove and args.roles is None:
            raise GrantError("--remove needs --roles: name the role(s) to take away")
        roles = _check_roles((args.roles or ",".join(DEFAULT_ROLES)).split(","))
        with httpx.Client(
            base_url=base_url, headers=_headers(key), timeout=20, transport=transport
        ) as client:
            before, after = grant(
                client, args.email, roles, dry_run=args.dry_run, remove=args.remove
            )
    except GrantError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    except httpx.HTTPError as exc:
        # The message names the URL and status only; the key is in headers, never printed.
        print(f"ERROR: Supabase request failed: {type(exc).__name__}", file=sys.stderr)
        return 1
    if before == after:
        print(f"{args.email}: roles already {after}; nothing changed")
    elif args.dry_run:
        print(f"{args.email}: would change roles {before} -> {after} (dry run, nothing written)")
    else:
        print(f"{args.email}: roles {before} -> {after}. Sign out and in again to use them.")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
