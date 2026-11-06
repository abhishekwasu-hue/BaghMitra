"""Which proxies may set X-Forwarded-For / -Proto for uvicorn (audit OPS-11).

Printed at container start and passed to `uvicorn --forwarded-allow-ips`:
- FORWARDED_ALLOW_IPS from deploy/.env when set (e.g. the shared Caddy's own address);
- else the IPv4 networks this container is attached to (from /proc/net/route): its own
  compose network (only BagMitra's Caddy and database) and, when sharing the server, the
  shared `edge` network the other project's Caddy joins. Any other address is not trusted;
- else 127.0.0.1 (uvicorn's own default: trust nobody else).

Usage: python -m bagmitra_api.core.proxy_trust
"""

from __future__ import annotations

import ipaddress
import os
import socket
import struct
from pathlib import Path

ROUTE_TABLE = Path("/proc/net/route")
FALLBACK = "127.0.0.1"


def _ip(hex_le: str) -> str:
    return socket.inet_ntoa(struct.pack("<L", int(hex_le, 16)))


def attached_networks(route_table: str) -> list[str]:
    """CIDRs of the directly connected IPv4 networks (no gateway, not the default route)."""
    found: set[str] = set()
    for line in route_table.splitlines()[1:]:
        fields = line.split()
        if len(fields) < 8 or fields[0] == "lo":
            continue
        destination, gateway, mask = fields[1], fields[2], fields[7]
        if gateway != "00000000" or destination == "00000000":
            continue
        try:
            net = ipaddress.ip_network(f"{_ip(destination)}/{_ip(mask)}", strict=False)
        except ValueError:
            continue
        found.add(str(net))
    return sorted(found)


def allowed_proxies(env: dict[str, str], route_table: str | None) -> str:
    configured = env.get("FORWARDED_ALLOW_IPS", "").strip()
    if configured:
        return configured
    networks = attached_networks(route_table) if route_table else []
    return ",".join(networks) or FALLBACK


def main() -> None:  # pragma: no cover - thin CLI wrapper
    try:
        table: str | None = ROUTE_TABLE.read_text()
    except OSError:
        table = None
    print(allowed_proxies(dict(os.environ), table))


if __name__ == "__main__":  # pragma: no cover
    main()
