from __future__ import annotations

import uuid
from datetime import UTC, datetime

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.models import KbLabelClaim, KbRestriction, KbSource

START = datetime(2024, 3, 31, tzinfo=UTC)


async def seed(engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        src = KbSource(
            id=uuid.uuid4(),
            key="cibrc_insecticides_2024",
            title="CIB&RC Major Uses of Pesticides: insecticides (31.03.2024)",
            publisher="PPQS / CIB&RC",
            url="https://ppqs.gov.in/sites/default/files/insecticides_31.03.2024.pdf",
            tier="tier2",
            licence="government publication",
            allowed_use="cite_only",
            verification="V",
        )

        def claim(ai: str, crop: str, target: str, **extra: object) -> KbLabelClaim:
            values: dict[str, object] = {
                "id": uuid.uuid4(),
                "active_ingredient": ai,
                "formulation": "17.8 SL",
                "crop": crop,
                "target": target,
                "dose": "0.3 ml/L",
                "interval_days": None,
                "phi_days": 15,
                "max_sprays": None,
                "source_id": src.id,
                "valid_from": START,
            }
            return KbLabelClaim(**(values | extra))

        session.add_all(
            [
                src,
                claim("imidacloprid", "citrus", "psylla"),
                claim("imidacloprid", "citrus", "leaf miner"),
                claim("dicofol", "citrus", "mites"),  # banned: must never show
                claim("chlorpyrifos", "citrus", "aphid"),  # restricted on citrus
                claim("thiamethoxam", "grapes", "thrips"),  # other crop
                claim("old one", "citrus", "psylla", valid_to=datetime(2020, 1, 1, tzinfo=UTC)),
                KbRestriction(
                    id=uuid.uuid4(),
                    active_ingredient="dicofol",
                    kind="banned",
                    crops=[],
                    crop_groups=[],
                    notification="S.O. 4294(E) 3 Oct 2023",
                    effective_from=datetime(2023, 10, 3, tzinfo=UTC),
                    source_id=src.id,
                ),
                KbRestriction(
                    id=uuid.uuid4(),
                    active_ingredient="chlorpyrifos",
                    kind="restricted",
                    crops=["citrus"],
                    crop_groups=[],
                    notification="S.O. 4294(E) 3 Oct 2023",
                    effective_from=datetime(2023, 10, 3, tzinfo=UTC),
                    source_id=src.id,
                ),
            ]
        )
        await session.commit()


async def test_label_info_lists_only_current_legal_claims_for_the_crop(
    client: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    await seed(engine)
    r = await client.get("/v1/reference/label-claims?crop=santra", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["kind"] == "label_information"
    rows = body["claims"]
    assert [(c["active_ingredient"], c["target"]) for c in rows] == [
        ("imidacloprid", "leaf miner"),
        ("imidacloprid", "psylla"),
    ]
    first = rows[0]
    assert (first["formulation"], first["dose"], first["phi_days"]) == ("17.8 SL", "0.3 ml/L", 15)
    assert first["label_crop"] == "citrus"
    assert first["source_title"].startswith("CIB&RC")
    assert first["source_url"].startswith("https://ppqs.gov.in/")

    psylla = await client.get(
        "/v1/reference/label-claims?crop=santra&target=Psylla", headers=auth_headers
    )
    assert [c["target"] for c in psylla.json()["claims"]] == ["psylla"]


async def test_label_info_for_an_unmapped_crop_is_empty_and_needs_a_token(
    client: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    await seed(engine)
    r = await client.get("/v1/reference/label-claims?crop=banana", headers=auth_headers)
    assert r.json()["claims"] == []
    assert (await client.get("/v1/reference/label-claims?crop=santra")).status_code == 401


async def test_label_info_flags_banned_and_restricted_rows_without_a_dose(
    client: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    await seed(engine)
    body = (await client.get("/v1/reference/label-claims?crop=santra", headers=auth_headers)).json()
    blocked = body["blocked"]
    assert [(b["active_ingredient"], b["target"], b["reason"]) for b in blocked] == [
        ("chlorpyrifos", "aphid", "restricted_for_crop"),
        ("dicofol", "mites", "banned"),
    ]
    assert blocked[1]["notification"] == "S.O. 4294(E) 3 Oct 2023"
    assert all("dose" not in b for b in blocked)
    mites = await client.get(
        "/v1/reference/label-claims?crop=santra&target=mites", headers=auth_headers
    )
    assert (mites.json()["claims"], len(mites.json()["blocked"])) == ([], 1)


async def test_label_info_carries_the_printed_details(
    client: httpx.AsyncClient, engine: AsyncEngine, auth_headers: dict[str, str]
) -> None:
    await seed(engine)
    async with async_sessionmaker(engine)() as session:
        src = await session.scalar(select(KbSource))
        assert src is not None
        session.add(
            KbLabelClaim(
                id=uuid.uuid4(),
                active_ingredient="fixture bio",
                formulation="1% WP",
                crop="citrus",
                target="foot rot",
                dose="2.5 kg/ha",
                source_id=src.id,
                valid_from=START,
                category="bio",
                dilution="500",
                page_ref="p. 70",
                description="Living fungus.",
                brand_names=["zeta", "Alpha"],
                maker_url="https://maker.example/p",
            )
        )
        await session.commit()
    rows = (
        await client.get(
            "/v1/reference/label-claims?crop=mosambi&target=foot rot", headers=auth_headers
        )
    ).json()["claims"]
    assert len(rows) == 1
    row = rows[0]
    assert (row["category"], row["dilution"], row["page_ref"]) == ("bio", "500", "p. 70")
    assert row["brand_names"] == ["Alpha", "zeta"]
    assert (row["maker_url"], row["photo_url"]) == ("https://maker.example/p", None)
    assert row["description"] == "Living fungus."
