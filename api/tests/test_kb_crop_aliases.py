"""Q15 (owner-confirmed): label 'orange' means santra (mandarin), 'sweet lime' means mosambi."""

from bagmitra_api.core.settings import Settings


def test_default_label_aliases_follow_owner_decision() -> None:
    aliases = Settings().kb_crop_label_aliases
    assert {"orange", "mandarin"} <= set(aliases["santra"])
    assert "sweet lime" in aliases["mosambi"]
    assert "orange" not in aliases["mosambi"]
    assert "sweet lime" not in aliases["santra"]


def test_wp4_sweet_orange_is_mosambi_and_acid_lime_is_neither() -> None:
    aliases = Settings().kb_crop_label_aliases
    assert "sweet orange" in aliases["mosambi"]
    assert "sweet orange" not in aliases["santra"]
    for crop in ("santra", "mosambi"):
        assert not {"acid lime", "lemon", "lime"} & set(aliases[crop])
