"""Addendum v1.3 §7: every AI answer, alert and voice script is scanned before display."""

from __future__ import annotations

from bagmitra_api.kb.gate import GateContext
from bagmitra_api.kb.output_filter import filter_text
from tests.test_kb_gate import CLAIMS, RESTRICTIONS, SYNONYMS

CTX = GateContext(
    crop_aliases=frozenset({"citrus"}),
    crop_groups=frozenset({"fruit_eaten_raw"}),
    claims=CLAIMS,
    restrictions=RESTRICTIONS,
    synonyms=SYNONYMS,
)
KNOWN = ("imidacloprid", "dichlorvos", "dicofol", "copper oxychloride", "chlorpyrifos")


def run(text: str) -> tuple[str, list[str]]:
    result = filter_text(text, CTX, known_ingredients=KNOWN)
    return result.text, result.removed


def test_removes_sentences_with_banned_or_unlabelled_chemicals() -> None:
    text = (
        "Remove and burn affected twigs. Spray dichlorvos 2 ml per litre on the trunk. "
        "Use DDVP if borers persist. Keep the basin weed-free."
    )
    out, removed = run(text)
    assert out == "Remove and burn affected twigs. Keep the basin weed-free."
    assert set(removed) == {"dichlorvos"}


def test_keeps_gated_chemicals_and_plain_text() -> None:
    text = "For psylla on new flush, imidacloprid has a citrus label. Monitor weekly."
    out, removed = run(text)
    assert out == text
    assert removed == []


def test_chemical_without_known_target_context_is_still_screened_by_restrictions() -> None:
    out, removed = run("Chlorpyrifos works well. Prune the dead wood.")
    assert out == "Prune the dead wood."
    assert removed == ["chlorpyrifos"]


def test_marathi_text_with_trade_name_is_screened() -> None:
    out, removed = run("ताण नसेल तर काळजी घ्या. blitox फवारा. पाणी द्या.")
    assert "blitox" not in out.lower()
    assert removed == ["copper oxychloride"]
