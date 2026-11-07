"""Real orchard check (spec v1.5 §4C): a lot's photos must be taken inside or near the
grower's mapped plot. Plane geometry on a local equirectangular projection is exact enough
at orchard size (hundreds of metres)."""

from __future__ import annotations

import math
from collections.abc import Iterable, Sequence
from itertools import pairwise
from typing import Any, Literal

OrchardCheck = Literal["inside", "near", "outside", "unmapped"]
_EARTH_M = 6_371_000.0
Point = tuple[float, float]  # (lat, lon)


def _xy(origin: Point, p: Point) -> tuple[float, float]:
    """Metres east / north of `origin`."""
    lat0 = math.radians(origin[0])
    return (
        math.radians(p[1] - origin[1]) * math.cos(lat0) * _EARTH_M,
        math.radians(p[0] - origin[0]) * _EARTH_M,
    )


def _inside(x: float, y: float, ring: Sequence[tuple[float, float]]) -> bool:
    hit = False
    for (x1, y1), (x2, y2) in pairwise(ring):
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            hit = not hit
    return hit


def _to_segment(x: float, y: float, a: tuple[float, float], b: tuple[float, float]) -> float:
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = (
        0.0
        if dx == dy == 0
        else max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / (dx * dx + dy * dy)))
    )
    return math.hypot(x - a[0] - t * dx, y - a[1] - t * dy)


def _one(p: Point, rings: list[list[Point]], centroid: Point | None, near_m: float) -> OrchardCheck:
    if rings:
        origin = rings[0][0]
        x, y = _xy(origin, p)
        flat = [[_xy(origin, q) for q in ring] for ring in rings]
        if _inside(x, y, flat[0]) and not any(_inside(x, y, hole) for hole in flat[1:]):
            return "inside"
        edge = min(_to_segment(x, y, a, b) for ring in flat for a, b in pairwise(ring))
        return "near" if edge <= near_m else "outside"
    if centroid is not None:
        return "near" if math.hypot(*_xy(centroid, p)) <= near_m else "outside"
    return "unmapped"


def orchard_check(
    photos: Iterable[Point],
    boundary: dict[str, Any] | None,
    centroid: Point | None,
    near_m: float,
) -> OrchardCheck:
    """The worst result over the photos: every one must be inside or within `near_m` metres of
    the plot boundary (or of its point when only a point is mapped)."""
    rings: list[list[Point]] = []
    if boundary and boundary.get("type") == "Polygon":
        rings = [
            [(float(lat), float(lon)) for lon, lat in ring] for ring in boundary["coordinates"]
        ]
    order: list[OrchardCheck] = ["inside", "near", "outside", "unmapped"]
    worst: OrchardCheck = "inside"
    for p in photos:
        r = _one(p, rings, centroid, near_m)
        if order.index(r) > order.index(worst):
            worst = r
    return worst
