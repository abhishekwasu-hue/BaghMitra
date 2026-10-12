"""Manual-upload importers for CIB&RC label claims and gazette restrictions (addendum §5).

An admin uploads a human-checked CSV for one source. Every row is validated before
anything is written; the result is a dated diff. History is kept: a changed or removed
label claim is end-dated (valid_to), never deleted. Restrictions are only ever added or
updated here: lifting a ban is an explicit admin decision, not a missing CSV row.

Usage: python -m bagmitra_api.kb.importers claims|restrictions <source_key> <file.csv>
"""

from __future__ import annotations

import asyncio
import csv
import io
import sys
import uuid
from dataclasses import asdict, dataclass
from datetime import UTC, date, datetime
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.kb.gate import normalise_ai
from bagmitra_api.kb.models import KbAdminAlert, KbLabelClaim, KbRestriction, KbSource

CLAIM_COLUMNS = (
    "active_ingredient",
    "formulation",
    "crop",
    "target",
    "dose",
    "interval_days",
    "phi_days",
    "max_sprays",
)
RESTRICTION_COLUMNS = (
    "active_ingredient",
    "kind",
    "crops",
    "crop_groups",
    "notification",
    "effective_from",
)
KINDS = frozenset({"banned", "withdrawn", "refused", "restricted"})


class KbImportError(ValueError):
    def __init__(self, errors: list[str]) -> None:
        super().__init__("; ".join(errors))
        self.errors = errors


@dataclass(frozen=True, slots=True)
class ClaimRow:
    active_ingredient: str
    formulation: str
    crop: str
    target: str
    dose: str
    interval_days: int | None
    phi_days: int | None
    max_sprays: int | None

    @property
    def key(self) -> tuple[str, str, str, str]:
        return (self.active_ingredient, self.formulation, self.crop, self.target)


@dataclass(frozen=True, slots=True)
class RestrictionRow:
    active_ingredient: str
    kind: str
    crops: tuple[str, ...]
    crop_groups: tuple[str, ...]
    notification: str
    effective_from: date


@dataclass(frozen=True, slots=True)
class ImportDiff:
    added: int
    changed: int
    removed: int
    unchanged: int


def _norm(text: str) -> str:
    return normalise_ai(text, {})


def _rows(text: str, columns: tuple[str, ...]) -> list[tuple[int, dict[str, str]]]:
    reader = csv.DictReader(io.StringIO(text))
    missing = [c for c in columns if c not in (reader.fieldnames or [])]
    if missing:
        raise KbImportError([f"missing columns: {', '.join(missing)}"])
    return [(n, {k: (v or "").strip() for k, v in r.items()}) for n, r in enumerate(reader, 2)]


def _required(row: dict[str, str], names: tuple[str, ...]) -> None:
    empty = [n for n in names if not row[n]]
    if empty:
        raise ValueError(f"empty {', '.join(empty)}")


def _int(value: str) -> int | None:
    if not value:
        return None
    if not value.isdigit():
        raise ValueError(f"not a whole number: {value!r}")
    return int(value)


def _split(value: str) -> tuple[str, ...]:
    return tuple(sorted({_norm(v) for v in value.split(";") if v.strip()}))


def parse_label_claims(text: str) -> list[ClaimRow]:
    out: list[ClaimRow] = []
    errors: list[str] = []
    for n, r in _rows(text, CLAIM_COLUMNS):
        try:
            _required(r, CLAIM_COLUMNS[:5])
            row = ClaimRow(
                active_ingredient=_norm(r["active_ingredient"]),
                formulation=_norm(r["formulation"]),
                crop=_norm(r["crop"]),
                target=_norm(r["target"]),
                dose=r["dose"],
                interval_days=_int(r["interval_days"]),
                phi_days=_int(r["phi_days"]),
                max_sprays=_int(r["max_sprays"]),
            )
        except ValueError as exc:
            errors.append(f"row {n}: {exc}")
            continue
        out.append(row)
    if len({c.key for c in out}) != len(out):
        errors.append("duplicate (active_ingredient, formulation, crop, target) rows")
    if errors:
        raise KbImportError(errors)
    return out


def parse_restrictions(text: str) -> list[RestrictionRow]:
    out: list[RestrictionRow] = []
    errors: list[str] = []
    for n, r in _rows(text, RESTRICTION_COLUMNS):
        try:
            _required(r, ("active_ingredient", "kind", "notification", "effective_from"))
            if r["kind"] not in KINDS:
                raise ValueError(f"unknown kind {r['kind']!r}")
            out.append(
                RestrictionRow(
                    _norm(r["active_ingredient"]),
                    r["kind"],
                    _split(r["crops"]),
                    _split(r["crop_groups"]),
                    r["notification"],
                    date.fromisoformat(r["effective_from"]),
                )
            )
        except ValueError as exc:
            errors.append(f"row {n}: {exc}")
    if errors:
        raise KbImportError(errors)
    return out


async def _source(session: AsyncSession, key: str) -> KbSource:
    source = await session.scalar(select(KbSource).where(KbSource.key == key))
    if source is None:
        raise KbImportError([f"unknown source {key!r}"])
    return source


def _claim_of(row: KbLabelClaim) -> ClaimRow:
    return ClaimRow(
        row.active_ingredient,
        row.formulation,
        row.crop,
        row.target,
        row.dose,
        row.interval_days,
        row.phi_days,
        row.max_sprays,
    )


async def _record(session: AsyncSession, what: str, diff: ImportDiff, at: datetime) -> None:
    counts = ", ".join(f"{k}={v}" for k, v in asdict(diff).items())
    detail = f"{what} at {at.isoformat()}: {counts}"
    session.add(KbAdminAlert(id=uuid.uuid4(), kind="import_applied", detail=detail))
    await session.flush()


async def import_label_claims(
    session: AsyncSession, source_key: str, text: str, at: datetime
) -> ImportDiff:
    source = await _source(session, source_key)
    incoming = {c.key: c for c in parse_label_claims(text)}
    current = {
        (r.active_ingredient, r.formulation, r.crop, r.target): r
        for r in await session.scalars(
            select(KbLabelClaim).where(
                KbLabelClaim.source_id == source.id, KbLabelClaim.valid_to.is_(None)
            )
        )
    }
    added = changed = removed = unchanged = 0
    for key, row in current.items():
        new = incoming.get(key)
        if new == _claim_of(row):
            unchanged += 1
            continue
        row.valid_to = at
        if new is None:
            removed += 1
        else:
            changed += 1
    for key, claim in incoming.items():
        if key in current and current[key].valid_to is None:
            continue
        added += key not in current
        session.add(
            KbLabelClaim(
                id=uuid.uuid4(),
                **{c: getattr(claim, c) for c in CLAIM_COLUMNS},
                source_id=source.id,
                valid_from=at,
            )
        )
    diff = ImportDiff(added, changed, removed, unchanged)
    await _record(session, f"label claims from {source_key}", diff, at)
    return diff


async def import_restrictions(
    session: AsyncSession, source_key: str, text: str, at: datetime
) -> ImportDiff:
    source = await _source(session, source_key)
    rows = parse_restrictions(text)
    current = {
        (r.active_ingredient, r.kind): r
        for r in await session.scalars(
            select(KbRestriction).where(KbRestriction.source_id == source.id)
        )
    }
    added = changed = unchanged = 0
    for r in rows:
        values = {
            "crops": list(r.crops),
            "crop_groups": list(r.crop_groups),
            "notification": r.notification,
            "effective_from": datetime.combine(r.effective_from, datetime.min.time(), UTC),
        }
        row = current.get((r.active_ingredient, r.kind))
        if row is None:
            added += 1
            row = KbRestriction(id=uuid.uuid4(), active_ingredient=r.active_ingredient, kind=r.kind)
            row.source_id = source.id
            session.add(row)
        elif _same(row, values):
            unchanged += 1
            continue
        else:
            changed += 1
        for field, value in values.items():
            setattr(row, field, value)
    diff = ImportDiff(added, changed, 0, unchanged)
    await _record(session, f"restrictions from {source_key}", diff, at)
    return diff


def _same(row: KbRestriction, values: dict[str, object]) -> bool:
    eff = row.effective_from
    eff = eff if eff.tzinfo else eff.replace(tzinfo=UTC)
    return (
        sorted(row.crops) == values["crops"]
        and sorted(row.crop_groups) == values["crop_groups"]
        and row.notification == values["notification"]
        and eff == values["effective_from"]
    )


async def main(argv: list[str]) -> None:  # pragma: no cover - thin CLI wrapper
    from bagmitra_api.core.settings import get_settings  # noqa: PLC0415
    from bagmitra_api.db.session import get_sessionmaker  # noqa: PLC0415
    from bagmitra_api.kb.regate import regate_with_settings  # noqa: PLC0415

    kind, source_key, path = argv
    text = await asyncio.to_thread(Path(path).read_text, "utf-8")
    importer = {"claims": import_label_claims, "restrictions": import_restrictions}[kind]
    async with get_sessionmaker()() as session:
        now = datetime.now(UTC)
        diff = await importer(session, source_key, text, now)
        pulled = await regate_with_settings(session, get_settings(), now)
        await session.commit()
    print(f"{diff}; cards pulled: {len(pulled)}")


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main(sys.argv[1:]))
