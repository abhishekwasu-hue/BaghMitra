"""Market linkage L6 visibility helpers (spec v1.5 §4, §4C; Q93): hidden / suspended subjects
and users, deleted accounts and blocks are left out of every list other milestones build."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.account.models import DeferredErasure
from bagmitra_api.auth.jwt import AuthenticatedUser
from bagmitra_api.core.errors import ApiError
from bagmitra_api.market_link.models import (
    AdminAction,
    BrokerProfile,
    BuyerProfile,
    MarketLot,
    ServiceProvider,
    UserBlock,
)
from bagmitra_api.market_link.visibility import (
    is_blocked_between,
    is_hidden_user,
    is_suspended,
    not_blocked,
    require_not_suspended,
    visible,
)

Maker = async_sessionmaker[AsyncSession]
T0 = datetime(2026, 11, 1, 9, 0, tzinfo=UTC)
GROWER = uuid.uuid4()
TRADER = uuid.uuid4()
BROKER = uuid.uuid4()


@pytest.fixture
def maker(engine: AsyncEngine) -> Maker:
    return async_sessionmaker(engine, expire_on_commit=False)


@pytest.fixture
async def ids(maker: Maker) -> dict[str, uuid.UUID]:
    i = {k: uuid.uuid4() for k in ("buyer", "broker", "provider", "lot")}
    async with maker() as s:
        s.add_all(
            [
                BuyerProfile(
                    id=i["buyer"], user_id=TRADER, name="Ramesh", phone="91", district="Nagpur"
                ),
                BrokerProfile(
                    id=i["broker"], user_id=BROKER, name="Suresh", phone="92", district="Warud"
                ),
                # Added by admin: no user behind it, still listed.
                ServiceProvider(
                    id=i["provider"], kind="weighbridge", name="Kata", phone="93", district="W"
                ),
                MarketLot(
                    id=i["lot"],
                    owner_id=GROWER,
                    plot_id=uuid.uuid4(),
                    crop="santra",
                    quantity_t=10.0,
                    harvest_from=date(2026, 12, 1),
                    harvest_to=date(2026, 12, 15),
                    basis="per_tonne",
                    status="published",
                    client_updated_at=T0,
                    last_seq=1,
                ),
            ]
        )
        await s.commit()
    return i


class Log:
    """Appends admin actions one minute apart (the latest decides)."""

    def __init__(self, maker: Maker) -> None:
        self.maker = maker
        self.at = T0

    async def __call__(
        self, kind: str, subject: uuid.UUID, user: uuid.UUID | None, action: str, reason: str
    ) -> None:
        self.at += timedelta(minutes=1)
        async with self.maker() as s:
            s.add(
                AdminAction(
                    subject_type=kind,
                    subject_id=subject,
                    user_id=user,
                    action=action,
                    reason_code=reason,
                    actor_id=uuid.uuid4(),
                    acted_at=self.at,
                    appeal_state="none",
                    appeal_photo_keys=[],
                )
            )
            await s.commit()


async def _shown(maker: Maker) -> set[str]:
    async with maker() as s:
        shown = set(
            await s.scalars(
                select(BuyerProfile.name).where(
                    visible("buyer", BuyerProfile.id, BuyerProfile.user_id)
                )
            )
        )
        shown |= set(
            await s.scalars(
                select(BrokerProfile.name).where(
                    visible("broker", BrokerProfile.id, BrokerProfile.user_id)
                )
            )
        )
        shown |= set(
            await s.scalars(
                select(ServiceProvider.name).where(
                    visible("provider", ServiceProvider.id, ServiceProvider.user_id)
                )
            )
        )
        lots = await s.scalars(
            select(MarketLot.id).where(visible("lot", MarketLot.id, MarketLot.owner_id))
        )
        return shown | {"lot" for _ in lots}


async def test_latest_hide_suspend_restore_decides(maker: Maker, ids: dict[str, uuid.UUID]) -> None:
    log = Log(maker)
    everyone = {"Ramesh", "Suresh", "Kata", "lot"}
    assert await _shown(maker) == everyone
    await log("buyer", ids["buyer"], TRADER, "warn", "abuse")
    await log("broker", ids["broker"], BROKER, "verify", "checks_passed")
    assert await _shown(maker) == everyone  # a warning or a verify hides nothing
    await log("buyer", ids["buyer"], TRADER, "hide", "fake_identity")
    await log("lot", ids["lot"], GROWER, "hide", "fake_lot")
    await log("provider", ids["provider"], None, "hide", "duplicate_user")
    assert await _shown(maker) == {"Suresh"}
    async with maker() as s:
        assert not await is_suspended(s, TRADER)  # hidden, not suspended
        assert not await is_hidden_user(s, TRADER)
    await log("buyer", ids["buyer"], TRADER, "restore", "appeal_upheld")
    await log("lot", ids["lot"], GROWER, "restore", "checks_passed")
    assert await _shown(maker) == {"Ramesh", "Suresh", "lot"}


async def test_suspend_hides_every_profile_and_lot_of_the_user(
    maker: Maker, ids: dict[str, uuid.UUID]
) -> None:
    log = Log(maker)
    async with maker() as s:  # the same trader also holds a lot
        s.add(
            MarketLot(
                id=uuid.uuid4(),
                owner_id=TRADER,
                plot_id=uuid.uuid4(),
                crop="mosambi",
                quantity_t=2.0,
                harvest_from=date(2026, 12, 1),
                harvest_to=date(2026, 12, 2),
                basis="lump_sum",
                status="published",
                client_updated_at=T0,
                last_seq=1,
            )
        )
        await s.commit()
    await log("buyer", ids["buyer"], TRADER, "suspend", "impersonation")
    assert await _shown(maker) == {"Suresh", "Kata", "lot"}
    async with maker() as s:
        assert await is_suspended(s, TRADER)
        assert await is_hidden_user(s, TRADER)
        with pytest.raises(ApiError) as err:
            await require_not_suspended(AuthenticatedUser(id=TRADER, phone=None), s)
        assert err.value.status_code == 403
        await require_not_suspended(AuthenticatedUser(id=GROWER, phone=None), s)
    await log("buyer", ids["buyer"], TRADER, "restore", "appeal_upheld")
    async with maker() as s:
        assert not await is_suspended(s, TRADER)


async def test_a_deleted_account_is_hidden_at_once(maker: Maker, ids: dict[str, uuid.UUID]) -> None:
    async with maker() as s:
        s.add(DeferredErasure(user_id=GROWER, requested_at=T0, erase_after=T0))
        s.add(DeferredErasure(user_id=BROKER, requested_at=T0, erase_after=T0))
        await s.commit()
        assert await is_hidden_user(s, GROWER)
        assert not await is_suspended(s, GROWER)
    assert await _shown(maker) == {"Ramesh", "Kata"}


async def test_blocked_users_are_hidden_from_each_other(
    maker: Maker, ids: dict[str, uuid.UUID]
) -> None:
    async with maker() as s:
        s.add(UserBlock(blocker_id=GROWER, blocked_id=TRADER))
        await s.commit()
        assert await is_blocked_between(s, TRADER, GROWER)
        assert await is_blocked_between(s, GROWER, TRADER)
        assert not await is_blocked_between(s, GROWER, BROKER)
        # The grower who blocked the trader no longer sees the trader's profile.
        for viewer, expected in ((GROWER, set()), (BROKER, {"Ramesh"})):
            names = await s.scalars(
                select(BuyerProfile.name).where(not_blocked(viewer, BuyerProfile.user_id))
            )
            assert set(names) == expected
        # The trader sees no lot of the grower who blocked them; others do.
        for viewer, count in ((TRADER, 0), (BROKER, 1)):
            lots = await s.scalars(
                select(MarketLot.id).where(not_blocked(viewer, MarketLot.owner_id))
            )
            assert len(list(lots)) == count
        providers = await s.scalars(
            select(ServiceProvider.name).where(not_blocked(TRADER, ServiceProvider.user_id))
        )
        assert list(providers) == ["Kata"]  # no user behind it: never blocked
