"""Market linkage account deletion (Q68, spec v1.5 §4C): market-link data is hidden at once
at `DELETE /v1/me` and erased by the nightly job after 180 days; ratings stay (no name)."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import ColumnElement, func, select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.account.models import DeferredErasure
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.erase_job import SKIPPED_LOCKED, erase_lock, run_locked
from bagmitra_api.market_link.erasure import erase_due
from bagmitra_api.market_link.models import (
    AdminAction,
    BuyerProfile,
    FraudReport,
    MarketDeal,
    MarketLot,
    MarketLotPhoto,
    MarketOffer,
    PartyVerification,
    Rating,
    RegistrationFix,
    TermsAcceptance,
    UserBlock,
)
from bagmitra_api.market_link.visibility import is_hidden_user, visible
from bagmitra_api.photos.storage import PhotoStorageError, SignedUrl
from bagmitra_api.routers.me import get_auth_admin
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.conftest import make_token

Maker = async_sessionmaker[AsyncSession]
T0 = datetime(2026, 11, 1, 9, 0, tzinfo=UTC)
TRADER = uuid.uuid4()
GROWER = uuid.uuid4()
OTHER = uuid.uuid4()


class FakeStorage:
    def __init__(self) -> None:
        self.deleted: list[str] = []
        self.fail = False

    async def signed_upload_url(self, key: str) -> SignedUrl:  # pragma: no cover
        return SignedUrl(key, 1)

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:  # pragma: no cover
        return SignedUrl(key, expires_in)

    async def put_object(self, key: str, data: bytes, content_type: str) -> None:  # noqa: ARG002
        raise AssertionError(key)  # pragma: no cover - the erasure never uploads

    async def list_folder(self, folder: str) -> list[str]:  # noqa: ARG002
        return []

    async def delete_objects(self, keys: list[str]) -> None:
        if self.fail:
            raise PhotoStorageError("HTTP 503")
        self.deleted += keys


def _lot(owner: uuid.UUID, status: str = "published") -> MarketLot:
    return MarketLot(
        id=uuid.uuid4(),
        owner_id=owner,
        plot_id=uuid.uuid4(),
        crop="santra",
        quality="size 70+",
        village="Warud",
        quantity_t=5.0,
        harvest_from=date(2026, 12, 1),
        harvest_to=date(2026, 12, 9),
        basis="per_tonne",
        status=status,
        client_updated_at=T0,
        last_seq=1,
    )


def _offer(lot: uuid.UUID, status: str) -> MarketOffer:
    return MarketOffer(
        id=uuid.uuid4(),
        basis="per_tonne",
        rate_paise=2_000_000,
        harvest_date=date(2026, 12, 2),
        lot_id=lot,
        buyer_user_id=OTHER,
        submitted_by=OTHER,
        status=status,
    )


@pytest.fixture
def maker(engine: AsyncEngine) -> Maker:
    return async_sessionmaker(engine, expire_on_commit=False)


@pytest.fixture
async def data(maker: Maker) -> dict[str, uuid.UUID]:
    """A trader (profile, documents, fix, terms, block, report, a rating given) and a grower
    (a lot with only an open interest, and a lot that led to an introduction)."""
    buyer = uuid.uuid4()
    free, introduced = _lot(GROWER), _lot(GROWER, "closed")
    async with maker() as s:
        s.add_all(
            [
                BuyerProfile(
                    id=buyer, user_id=TRADER, name="Ramesh", phone="9198", district="Nagpur"
                ),
                free,
                introduced,
                MarketLotPhoto(
                    id=uuid.uuid4(),
                    owner_id=GROWER,
                    lot_id=free.id,
                    captured_at=T0,
                    lat=21.3,
                    lon=78.0,
                    photo_key=f"{GROWER}/p1.jpg",
                    client_updated_at=T0,
                    last_seq=1,
                ),
            ]
        )
        await s.flush()
        open_offer, accepted = _offer(free.id, "open"), _offer(introduced.id, "accepted")
        s.add_all(
            [
                open_offer,
                accepted,
                PartyVerification(
                    subject_type="buyer",
                    subject_id=buyer,
                    status="pending",
                    document_keys=[f"{TRADER}/gst.jpg"],
                ),
                RegistrationFix(
                    subject_type="buyer",
                    subject_id=buyer,
                    user_id=TRADER,
                    lat=21.1,
                    lon=79.0,
                    accuracy_m=8.0,
                    captured_at=T0,
                ),
                TermsAcceptance(
                    user_id=TRADER,
                    role="trader",
                    doc_kind="terms",
                    version="1",
                    accepted_at=T0,
                    adult_declared=True,
                ),
                UserBlock(blocker_id=OTHER, blocked_id=TRADER),
                FraudReport(
                    reporter_id=TRADER,
                    subject_type="user",
                    subject_id=OTHER,
                    reason="abuse",
                    photo_keys=[f"{TRADER}/report-1.jpg"],
                    status="open",
                ),
            ]
        )
        await s.flush()
        deal = MarketDeal(
            id=uuid.uuid4(), lot_id=introduced.id, offer_id=accepted.id, status="completed"
        )
        s.add(deal)
        await s.flush()
        s.add(
            Rating(
                deal_id=deal.id,
                rater_id=TRADER,
                ratee_id=GROWER,
                ratee_role="grower",
                question_key="produce_matched",
                stars=5,
                tag_ids=[],
            )
        )
        await s.commit()
    return {"buyer": buyer, "free": free.id, "introduced": introduced.id, "offer": open_offer.id}


async def _delete_me(settings: Settings, maker: Maker, user: uuid.UUID) -> None:
    app = create_app(settings.model_copy(update={"market_link_enabled": True}))
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_photo_storage] = lambda: FakeStorage()
    app.dependency_overrides[get_auth_admin] = lambda: None
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        r = await c.delete("/v1/me", headers={"Authorization": f"Bearer {make_token(user)}"})
    assert r.status_code == 200, r.text


async def _count(maker: Maker, model: type[Any], *where: ColumnElement[bool]) -> int:
    async with maker() as s:
        return int(await s.scalar(select(func.count()).select_from(model).where(*where)) or 0)


async def test_delete_me_hides_at_once_and_erases_after_180_days(
    settings: Settings, maker: Maker, data: dict[str, uuid.UUID]
) -> None:
    before = datetime.now(UTC)
    await _delete_me(settings, maker, TRADER)
    await _delete_me(settings, maker, GROWER)
    async with maker() as s:
        rows = {r.user_id: r for r in await s.scalars(select(DeferredErasure))}
        assert set(rows) == {TRADER, GROWER}
        after = rows[TRADER].erase_after.replace(tzinfo=UTC)
        assert timedelta(days=179) < after - before < timedelta(days=181)
        assert await is_hidden_user(s, TRADER)
        assert await is_hidden_user(s, GROWER)
        shown = await s.scalars(
            select(BuyerProfile.id).where(visible("buyer", BuyerProfile.id, BuyerProfile.user_id))
        )
        assert list(shown) == []
        lots = {lot.id: lot.status for lot in await s.scalars(select(MarketLot))}
    # Lots stay (an interest points at them), but no longer published.
    assert lots == {data["free"]: "withdrawn", data["introduced"]: "closed"}
    assert await _count(maker, BuyerProfile) == 1
    storage = FakeStorage()
    async with maker() as s:
        early = await erase_due(s, storage, datetime.now(UTC) + timedelta(days=100))
    assert early.erased == 0
    async with maker() as s:
        done = await erase_due(s, storage, datetime.now(UTC) + timedelta(days=181))
    assert done.erased == 2
    assert sorted(storage.deleted) == sorted(
        [f"{TRADER}/gst.jpg", f"{TRADER}/report-1.jpg", f"{GROWER}/p1.jpg"]
    )
    for model in (
        BuyerProfile,
        PartyVerification,
        RegistrationFix,
        TermsAcceptance,
        UserBlock,
        FraudReport,
        MarketLotPhoto,
    ):
        assert await _count(maker, model) == 0, model.__tablename__
    # The lot with only an interest goes with it; the introduced lot stays without its text.
    assert await _count(maker, MarketOffer, MarketOffer.id == data["offer"]) == 0
    async with maker() as s:
        [kept] = list(await s.scalars(select(MarketLot)))
        assert (kept.id, kept.quality, kept.village) == (data["introduced"], None, None)
        # The rating given stays; it names an id only, and the id stays hidden (no name).
        assert await s.scalar(select(func.count()).select_from(Rating)) == 1
        assert await is_hidden_user(s, TRADER)
        again = await erase_due(s, storage, datetime.now(UTC) + timedelta(days=400))
    assert again.erased == 0


async def test_a_user_without_market_link_data_gets_no_erasure_row(
    settings: Settings, maker: Maker, data: dict[str, uuid.UUID]
) -> None:
    await _delete_me(settings, maker, uuid.uuid4())
    assert await _count(maker, DeferredErasure) == 0


async def test_without_storage_or_with_a_failing_one_nothing_is_touched(
    settings: Settings, maker: Maker, data: dict[str, uuid.UUID]
) -> None:
    await _delete_me(settings, maker, TRADER)
    later = datetime.now(UTC) + timedelta(days=200)
    async with maker() as s:
        summary = await erase_due(s, None, later)
    assert (summary.erased, summary.waiting_for_storage) == (0, 1)
    failing = FakeStorage()
    failing.fail = True
    async with maker() as s:
        summary = await erase_due(s, failing, later)
    assert (summary.erased, summary.failed) == (0, 1)
    assert await _count(maker, BuyerProfile) == 1
    assert await _count(maker, DeferredErasure, DeferredErasure.erased_at.is_(None)) == 1


async def test_job_runs_unguarded_on_sqlite(engine: AsyncEngine, maker: Maker) -> None:
    async with erase_lock(engine) as held:
        assert held
    async with maker() as s:
        assert await run_locked(engine, s, None, T0) == {
            "erased": 0,
            "waiting_for_storage": 0,
            "failed": 0,
        }
    assert SKIPPED_LOCKED


async def test_admin_actions_survive_erasure(
    settings: Settings, maker: Maker, data: dict[str, uuid.UUID]
) -> None:
    async with maker() as s:
        s.add(
            AdminAction(
                subject_type="buyer",
                subject_id=data["buyer"],
                user_id=TRADER,
                action="warn",
                reason_code="abuse",
                actor_id=OTHER,
                acted_at=T0,
                appeal_state="none",
                appeal_photo_keys=[],
            )
        )
        await s.commit()
    await _delete_me(settings, maker, TRADER)
    async with maker() as s:
        await erase_due(s, FakeStorage(), datetime.now(UTC) + timedelta(days=181))
    assert await _count(maker, AdminAction) == 1
