"""OPS-11: uvicorn trusts forwarded headers only from the networks the API container is on
(its own compose network and the shared `edge` one), or exactly what .env says; never '*'."""

from __future__ import annotations

import subprocess
import sys

from bagmitra_api.core.proxy_trust import FALLBACK, allowed_proxies, attached_networks

# /proc/net/route of an API container on its compose network (172.18.0.0/16, default route
# via 172.18.0.1) and on the shared edge network (172.20.0.0/24).
ROUTES = """Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT
eth0\t00000000\t010012AC\t0003\t0\t0\t0\t00000000\t0\t0\t0
eth0\t000012AC\t00000000\t0001\t0\t0\t0\t0000FFFF\t0\t0\t0
eth1\t000014AC\t00000000\t0001\t0\t0\t0\t00FFFFFF\t0\t0\t0
lo\t0000007F\t00000000\t0001\t0\t0\t0\t000000FF\t0\t0\t0
eth1\tgarbage
"""


def test_only_the_attached_networks_are_trusted() -> None:
    assert attached_networks(ROUTES) == ["172.18.0.0/16", "172.20.0.0/24"]
    assert allowed_proxies({}, ROUTES) == "172.18.0.0/16,172.20.0.0/24"


def test_the_env_setting_wins_and_nothing_means_loopback_only() -> None:
    assert allowed_proxies({"FORWARDED_ALLOW_IPS": " 172.20.0.5 "}, ROUTES) == "172.20.0.5"
    assert allowed_proxies({"FORWARDED_ALLOW_IPS": ""}, None) == FALLBACK
    assert allowed_proxies({}, "Iface\tDestination\n") == FALLBACK
    assert "*" not in allowed_proxies({}, ROUTES)


def test_the_module_prints_one_value() -> None:
    out = subprocess.run(  # noqa: S603 - fixed arguments, test only
        [sys.executable, "-m", "bagmitra_api.core.proxy_trust"],
        capture_output=True,
        text=True,
        check=True,
        env={"FORWARDED_ALLOW_IPS": "10.0.0.2", "PYTHONPATH": ":".join(sys.path)},
    ).stdout
    assert out == "10.0.0.2\n"
