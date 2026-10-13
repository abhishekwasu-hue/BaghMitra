"""Q15 (owner-confirmed): label 'orange' means santra (mandarin), 'sweet lime' means mosambi."""

from bagmitra_api.core.settings import Settings


def test_default_label_aliases_follow_owner_decision() -> None:
    aliases = Settings().kb_crop_label_aliases
    assert {"orange", "mandarin"} <= set(aliases["santra"])
    assert "sweet lime" in aliases["mosambi"]
    assert "orange" not in aliases["mosambi"]
    assert "sweet lime" not in aliases["santra"]
