"""Terms of use, privacy notice and disclaimer accepted per role before the role is used
(spec v1.5 §4C): versioned, time-stamped, with the 18+ declaration (minors cannot contract).

Every later market-link write for a role depends on `require_role_accepted(role)`: it answers
403 `terms_not_accepted` until the user has accepted the current version of every document for
that role. Raising a version in the settings asks everyone to accept again.
"""

from __future__ import annotations

import uuid
from collections.abc import Awaitable, Callable
from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser, CurrentUser
from bagmitra_api.core.errors import ApiError
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.models import TERMS_DOCS, TERMS_ROLES, TermsAcceptance


def current_versions(settings: Settings) -> dict[str, str]:
    """The version of each document a user accepts today, by document kind."""
    return {
        "terms": settings.market_link_terms_version,
        "privacy": settings.market_link_privacy_version,
        "disclaimer": settings.market_link_disclaimer_version,
    }


async def accepted_roles(
    session: AsyncSession, user_id: uuid.UUID, versions: dict[str, str]
) -> list[str]:
    """Roles for which the user accepted the current version of every document, with 18+."""
    rows = await session.scalars(
        select(TermsAcceptance).where(
            TermsAcceptance.user_id == user_id, TermsAcceptance.adult_declared.is_(True)
        )
    )
    done: dict[str, set[str]] = {}
    for row in rows:
        if versions.get(row.doc_kind) == row.version:
            done.setdefault(row.role, set()).add(row.doc_kind)
    return [role for role in TERMS_ROLES if done.get(role, set()) >= set(TERMS_DOCS)]


def require_role_accepted(role: str) -> Callable[..., Awaitable[AuthenticatedUser]]:
    """Dependency for every market-link write made in `role`: the signed-in user, or 403
    `terms_not_accepted` until the current terms, privacy notice and disclaimer are accepted."""
    if role not in TERMS_ROLES:
        raise ValueError(f"unknown market-link role {role!r}")

    async def _check(
        user: CurrentUser,
        session: DbSession,
        settings: Annotated[Settings, Depends(get_settings)],
    ) -> AuthenticatedUser:
        if role not in await accepted_roles(session, user.id, current_versions(settings)):
            raise ApiError(403, "terms_not_accepted", f"Accept the current terms for {role}")
        return user

    return _check
