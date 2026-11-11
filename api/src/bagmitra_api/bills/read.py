"""Reading an agri-input shop bill with Claude (owner 2026-11-11, Q136).

One Messages API request per photo over httpx (`feed.ai.messages_text`: same headers, API
version and server-side refusal fallback as photo analysis). The photo goes first as a base64
image block, then the question. The answer is structured output (`output_config.format`, JSON
schema) and is checked again here: items without a name are dropped, numbers must be finite
and not negative, at most MAX_ITEMS items, strings are trimmed, and a bill date more than one
day after today (India) is dropped. Nothing is stored here.
"""

from __future__ import annotations

import base64
import json
import math
import re
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from typing import Any, Protocol

import httpx

from bagmitra_api.billing.entitlements import INDIA
from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import ANTHROPIC_VERSION, AiUnavailableError, messages_text

MAX_ITEMS = 30
SHOP_CHARS = 120
BILL_NO_CHARS = 40
NAME_CHARS = 120
INGREDIENT_CHARS = 160
UNIT_CHARS = 16
FUTURE_DAYS = 1
_ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


@dataclass(frozen=True, slots=True)
class BillItem:
    name: str
    active_ingredient: str | None = None
    quantity: float | None = None
    unit: str | None = None
    amount_rs: float | None = None


@dataclass(frozen=True, slots=True)
class Bill:
    shop_name: str | None = None
    bill_date: date | None = None
    bill_no: str | None = None
    items: list[BillItem] = field(default_factory=list)
    total_rs: float | None = None
    unsure: bool = True


class BillReader(Protocol):
    model: str

    async def read(self, image: bytes, media_type: str) -> Bill: ...


def _nullable(schema: dict[str, Any]) -> dict[str, Any]:
    return {"anyOf": [schema, {"type": "null"}]}


_STR = {"type": "string"}
_NUM = {"type": "number"}


def answer_schema() -> dict[str, Any]:
    """Structured output: every property required, no extra properties, no min / max."""
    item = {
        "type": "object",
        "properties": {
            "name": _STR,
            "active_ingredient": _nullable(_STR),
            "quantity": _nullable(_NUM),
            "unit": _nullable(_STR),
            "amount_rs": _nullable(_NUM),
        },
        "required": ["name", "active_ingredient", "quantity", "unit", "amount_rs"],
        "additionalProperties": False,
    }
    return {
        "type": "object",
        "properties": {
            "unsure": {"type": "boolean"},
            "shop_name": _nullable(_STR),
            "bill_date": _nullable(_STR),
            "bill_no": _nullable(_STR),
            "items": {"type": "array", "items": item},
            "total_rs": _nullable(_NUM),
        },
        "required": ["unsure", "shop_name", "bill_date", "bill_no", "items", "total_rs"],
        "additionalProperties": False,
    }


def system_prompt() -> str:
    return f"""You read one photo of a bill (invoice or cash memo) from an agri-input shop in
Maharashtra, India, for an orange (santra) or sweet lime (mosambi) farmer. The farmer uses what
you read to fill in a spray record and an expense in their farm app, and checks it before saving.

What to read:
- Read only what is printed or written on the bill. Never guess, never fill in from your own
  knowledge, and never work out a value that is not on the bill. When a field cannot be read
  clearly, or is not on the bill, give null.
- shop_name: the shop or firm name as printed at the top of the bill.
- bill_date: the bill date as an ISO date (YYYY-MM-DD). Indian bills write the day first
  (DD/MM/YYYY or DD-MM-YY). Give null when the date or its order is not clear.
- bill_no: the bill, invoice or memo number as printed.
- items: one entry per product line, in the order on the bill, at most {MAX_ITEMS}.
  - name: the product name exactly as printed (brand / trade name), in the bill's own script
    and spelling. Do not translate it, correct it or swap it for another product.
  - active_ingredient: the technical name or active ingredient (with its strength, for example
    "Imidacloprid 17.8% SL") only when it is printed on the bill for that line; otherwise null.
    Do not add it from your knowledge of the product.
  - quantity and unit: the quantity of that line as a number and its unit as printed (for
    example ml, L, g, kg, nos, packet, bottle). null when not clear.
  - amount_rs: the line amount in rupees as a number (no currency sign, no commas). null when
    not clear.
- total_rs: the bill's grand total (net amount payable) in rupees as a number, as printed.
  Do not add up the lines yourself; null when the total cannot be read.
- Bills may be in Marathi, Hindi or English, printed or handwritten, with Devanagari or Latin
  digits. Read Devanagari digits as numbers.

Set "unsure" to true when the photo is unclear (blurred, dark, cut off, at an angle that hides
parts), when some values could not be read with confidence, or when the photo is not a bill.
When the photo is not a bill, give no items and null for every other field."""


QUESTION = (
    "Read the bill in the photo above and answer in the JSON format. Use null for anything "
    "that is not printed on the bill or cannot be read clearly."
)


def _text(value: object, limit: int) -> str | None:
    if not isinstance(value, str):
        return None
    text = " ".join(value.split())[:limit].strip()
    return text or None


def _number(value: object) -> float | None:
    """A finite, non-negative number, else None."""
    if isinstance(value, bool) or not isinstance(value, int | float):
        return None
    number = float(value)
    if not math.isfinite(number) or number < 0:
        return None
    return round(number, 3)


def _bill_date(value: object, now: datetime) -> date | None:
    """An ISO date not more than FUTURE_DAYS after today in India, else None."""
    if not isinstance(value, str) or not _ISO_DATE.match(value.strip()):
        return None
    try:
        found = date.fromisoformat(value.strip())
    except ValueError:
        return None
    if found > now.astimezone(INDIA).date() + timedelta(days=FUTURE_DAYS):
        return None
    return found


def _items(value: object) -> list[BillItem]:
    found: list[BillItem] = []
    for raw in value if isinstance(value, list) else []:
        if not isinstance(raw, dict):
            continue
        name = _text(raw.get("name"), NAME_CHARS)
        if name is None:
            continue
        found.append(
            BillItem(
                name=name,
                active_ingredient=_text(raw.get("active_ingredient"), INGREDIENT_CHARS),
                quantity=_number(raw.get("quantity")),
                unit=_text(raw.get("unit"), UNIT_CHARS),
                amount_rs=_number(raw.get("amount_rs")),
            )
        )
        if len(found) == MAX_ITEMS:
            break
    return found


def parse_bill(payload: dict[str, Any], now: datetime) -> Bill:
    """Server-side check of the model's JSON (see the module docstring). A missing or
    non-boolean `unsure` counts as unsure."""
    return Bill(
        shop_name=_text(payload.get("shop_name"), SHOP_CHARS),
        bill_date=_bill_date(payload.get("bill_date"), now),
        bill_no=_text(payload.get("bill_no"), BILL_NO_CHARS),
        items=_items(payload.get("items")),
        total_rs=_number(payload.get("total_rs")),
        unsure=payload.get("unsure") is not False,
    )


class AnthropicBillReader:
    """Claude over the Messages API (PHOTO_AI_API_KEY, else FEED_AI_API_KEY; PHOTO_AI_MODEL)."""

    def __init__(self, http: httpx.AsyncClient, settings: Settings) -> None:
        self._http = http
        self._settings = settings
        self.model = settings.photo_ai_model

    def request_body(self, image: bytes, media_type: str) -> dict[str, Any]:
        # No `thinking` field: the model runs adaptive thinking by default, and "disabled" or a
        # budget is refused (400). Effort is left at the model's default.
        return {
            "model": self.model,
            "max_tokens": self._settings.photo_ai_max_tokens,
            "system": system_prompt(),
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": base64.b64encode(image).decode("ascii"),
                            },
                        },
                        {"type": "text", "text": QUESTION},
                    ],
                }
            ],
            "output_config": {"format": {"type": "json_schema", "schema": answer_schema()}},
        }

    async def read(self, image: bytes, media_type: str) -> Bill:
        s = self._settings
        answer = await messages_text(
            self._http,
            base_url=s.feed_ai_base_url,
            headers={
                "x-api-key": s.photo_ai_key,
                "anthropic-version": ANTHROPIC_VERSION,
                "content-type": "application/json",
            },
            body=self.request_body(image, media_type),
            fallback=True,
            read_seconds=s.photo_ai_timeout_seconds,
        )
        try:
            payload = json.loads(answer)
        except json.JSONDecodeError as exc:
            raise AiUnavailableError(f"model answered with invalid JSON: {exc}") from exc
        if not isinstance(payload, dict):
            raise AiUnavailableError("model answered with a non-object")
        return parse_bill(payload, datetime.now(INDIA))
