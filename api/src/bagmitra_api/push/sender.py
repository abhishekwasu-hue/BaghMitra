"""What a push sender does, independent of the service behind it (FCM later)."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Protocol


class PushUnavailableError(Exception):
    """The push service could not be reached or failed; try again on the next run."""


class SendResult(Enum):
    SENT = "sent"
    UNREGISTERED = "unregistered"  # the phone uninstalled the app or the token expired


@dataclass(frozen=True)
class PushMessage:
    token: str
    title: str
    body: str
    data: dict[str, str] = field(default_factory=dict)


class PushSender(Protocol):
    async def send(self, message: PushMessage) -> SendResult: ...
