"""Addendum v1.3 §5-§6: publishing needs a valid expert review; licence rules are code."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

import pytest

from bagmitra_api.kb.policy import (
    CardFacts,
    ReviewFacts,
    SourceFacts,
    publish_blockers,
    review_expiry,
    verbatim_violations,
)

NOW = datetime(2026, 10, 12, tzinfo=UTC)
REVIEWER = uuid.uuid4()


def source(use: str = "summarise_cite") -> SourceFacts:
    return SourceFacts(id=uuid.uuid4(), allowed_use=use)  # type: ignore[arg-type]


def card(*sources: SourceFacts, version: int = 2, chemical: bool = False) -> CardFacts:
    return CardFacts(
        version=version,
        has_english=True,
        source_ids=[s.id for s in sources],
        has_chemical_options=chemical,
    )


def approval(version: int = 2, *, days_ago: int = 1, decision: str = "approve") -> ReviewFacts:
    reviewed = NOW - timedelta(days=days_ago)
    return ReviewFacts(
        card_version=version,
        decision=decision,  # type: ignore[arg-type]
        reviewer_id=REVIEWER,
        reviewed_at=reviewed,
        expires_at=reviewed + timedelta(days=365),
    )


def test_publishable_with_current_valid_approval() -> None:
    s = source()
    assert publish_blockers(card(s), [approval()], {s.id: s}, NOW) == []


@pytest.mark.parametrize(
    ("reviews", "blocker"),
    [
        ([], "no_valid_review"),
        ([approval(version=1)], "no_valid_review"),
        ([approval(decision="reject")], "no_valid_review"),
        ([approval(days_ago=400)], "no_valid_review"),
    ],
    ids=["none", "older-version", "rejected", "expired"],
)
def test_review_must_approve_current_version_and_be_unexpired(
    reviews: list[ReviewFacts], blocker: str
) -> None:
    s = source()
    assert blocker in publish_blockers(card(s), reviews, {s.id: s}, NOW)


def test_card_needs_sources_english_and_no_internal_only_sources() -> None:
    internal = source("internal_only")
    assert "no_sources" in publish_blockers(card(), [approval()], {}, NOW)
    assert "internal_only_source" in publish_blockers(
        card(internal), [approval()], {internal.id: internal}, NOW
    )
    unknown = card(source())
    assert "unknown_source" in publish_blockers(unknown, [approval()], {}, NOW)
    no_en = CardFacts(version=2, has_english=False, source_ids=[], has_chemical_options=False)
    assert "no_english" in publish_blockers(no_en, [approval()], {}, NOW)


def test_review_expiry_is_shorter_for_chemical_cards() -> None:
    assert review_expiry(NOW, chemical=False, months_default=12, months_chemical=6) == datetime(
        2027, 10, 12, tzinfo=UTC
    )
    assert review_expiry(NOW, chemical=True, months_default=12, months_chemical=6) == datetime(
        2027, 4, 12, tzinfo=UTC
    )
    # Month-end clamps (31 Aug + 6 months -> 28/29 Feb).
    assert review_expiry(
        datetime(2026, 8, 31, tzinfo=UTC), chemical=True, months_default=12, months_chemical=6
    ) == datetime(2027, 2, 28, tzinfo=UTC)


SOURCE_TEXT = (
    "Scrape the gum from the affected bark and wash the wound with potassium permanganate "
    "solution then apply a fungicide paste on the trunk up to sixty centimetres before monsoon"
)


def test_no_long_verbatim_span_from_restricted_sources() -> None:
    own_words = "Clean the gummy patch on the bark and protect the trunk before the monsoon."
    copied = "Advice: wash the wound with potassium permanganate solution then apply a paste."
    assert verbatim_violations(own_words, SOURCE_TEXT, "summarise_cite", max_words=6) == []
    [span] = verbatim_violations(copied, SOURCE_TEXT, "cite_only", max_words=6)
    assert span.startswith("wash the wound with potassium permanganate")


def test_copy_sources_may_be_quoted_and_internal_only_never_shown() -> None:
    assert verbatim_violations(SOURCE_TEXT, SOURCE_TEXT, "copy", max_words=6) == []
    assert verbatim_violations("anything", SOURCE_TEXT, "internal_only", max_words=6) == [
        "internal_only"
    ]


def test_verbatim_check_ignores_case_and_punctuation() -> None:
    copied = "WASH the wound, with Potassium-Permanganate solution; then apply!"
    assert verbatim_violations(copied, SOURCE_TEXT, "summarise_cite", max_words=6)
