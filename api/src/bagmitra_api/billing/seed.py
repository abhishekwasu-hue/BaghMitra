"""Idempotent seeding of the default plans (Usage: python -m bagmitra_api.billing.seed).

Plans are config: seeding only creates a plan that does not exist yet, so an admin's edits to
limits and features are never overwritten by a deploy."""

from __future__ import annotations

import asyncio
import json
from importlib import resources
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.models import BillingPlan
from bagmitra_api.billing.service import PlanConfig, replace_plan
from bagmitra_api.db.session import get_sessionmaker


def default_plans() -> list[dict[str, Any]]:
    text = (
        resources.files("bagmitra_api.billing.seed_data").joinpath("plans.json").read_text("utf-8")
    )
    plans: list[dict[str, Any]] = json.loads(text)["plans"]
    return plans


async def seed_plans(session: AsyncSession) -> int:
    existing = set(await session.scalars(select(BillingPlan.key)))
    created = 0
    for plan in default_plans():
        if plan["key"] in existing:
            continue
        await replace_plan(
            session,
            PlanConfig(
                key=plan["key"],
                names=plan["names"],
                kind=plan["kind"],
                active=True,
                sort_order=plan["sort_order"],
                features=plan["features"],
            ),
        )
        created += 1
    await session.flush()
    return created


async def main() -> None:  # pragma: no cover - thin CLI wrapper
    async with get_sessionmaker()() as session:
        await seed_plans(session)
        await session.commit()


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
