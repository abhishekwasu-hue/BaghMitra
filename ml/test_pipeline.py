"""Smoke test of the training pipeline on synthetic images (no downloads).

Run: python -m pytest -q ml/test_pipeline.py  (with ml/requirements.txt installed)
"""

import json
import zipfile
from pathlib import Path

import numpy as np
import pytest
from PIL import Image

import train_citrus as tc

LABELS_MAP = Path(__file__).resolve().parent / "labels_map.json"
CARDS = Path(__file__).resolve().parents[1] / "app" / "assets" / "config" / "practice_cards.json"


def _img(path: Path, colour, size=(40, 30)):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGB", size, colour).save(path)


@pytest.fixture()
def lm():
    return tc.load_labels_map(LABELS_MAP)


def test_labels_map_classes_match_practice_cards(lm):
    cards = {s["key"] for s in json.loads(CARDS.read_text(encoding="utf-8"))["sections"]}
    for c in lm["classes"]:
        assert c in cards or c in {"healthy", "other"}, c
    # black spot / melanose have no card, so they must go to 'other'
    assert "black_spot" not in cards and "melanose" not in cards
    assert tc.map_label(lm, "citrus_leaves", "Black spot") == "other"
    assert tc.map_label(lm, "citrus_leaves", "canker") == "canker"
    assert tc.map_label(lm, "citrus_leaves", "greening") == "greening"
    assert tc.map_label(lm, "citrus_leaves", "healthy") == "healthy"


def test_unknown_labels_fail_loudly(lm):
    with pytest.raises(KeyError):
        tc.map_label(lm, "citrus_leaves", "scab")
    with pytest.raises(KeyError):
        tc.map_label(lm, "extra", "psylla")  # not a class until added to labels_map.json


def test_folder_matching_and_licence(lm, tmp_path):
    def m(name):
        return tc.match_folder_label(lm, "mendeley_hlb_mexico", name)

    assert m("HOJAS CON SINTOMAS") == "greening"
    assert m("HOJAS SANAS") == "healthy"
    # processed copies in the second zip are never used
    for name in ("preprocessed_images", "visualizations", "Symptoms HLB Leaves", "Raw Images Healthy "):
        assert m(name) is None
    mixed = {"classes": ["a", "b"], "sources": {"s": {"hlb": "a", "healthy": "b"}}}
    assert tc.match_folder_label(mixed, "s", "Database HLB and Healthy - Final") == tc.AMBIGUOUS
    assert tc.licence_is_cc_by_4({"data_licence": {"short_name": "CC BY 4.0"}})[0]
    assert not tc.licence_is_cc_by_4({"data_licence": {"short_name": "CC BY NC 3.0"}})[0]
    assert not tc.licence_is_cc_by_4({"name": "x"})[0]

    # nested zip as Mendeley may serve it
    inner = tmp_path / "inner.zip"
    with zipfile.ZipFile(inner, "w") as z:
        for folder in ("Final/HOJAS CON SINTOMAS", "Final/HOJAS SANAS", "Final/notes",
                       "B/Symptoms HLB Leaves/preprocessed_images", "B/hojas sanas y hojas con sintomas/x"):
            src = tmp_path / "src.png"
            _img(src, (1, 2, 3))
            z.write(src, f"{folder}/a.png")
    raw = tmp_path / "raw"
    raw.mkdir()
    with zipfile.ZipFile(raw / "all.zip", "w") as z:
        z.write(inner, "data/inner.zip")
    ext = tmp_path / "ext"
    ext.mkdir()
    tc._extract_all(raw, ext)
    recs, unmatched = tc.records_from_tree(ext, lm, "mendeley_hlb_mexico")
    # 'notes' and the processed folder match nothing; the mixed folder labels nothing
    assert sorted(r.label for r in recs) == ["greening", "healthy"]
    assert sum(unmatched.values()) == 3


def test_dedupe_drops_copies_and_conflicts(tmp_path):
    rng = np.random.default_rng(0)

    def photo():  # smooth random picture (like a photo, not pixel noise)
        small = Image.fromarray(rng.integers(0, 255, (6, 8, 3), dtype=np.uint8))
        return small.resize((80, 60), Image.BICUBIC)

    a, b, c = photo(), photo(), photo()
    a.save(tmp_path / "a.png")
    a.resize((160, 120)).save(tmp_path / "a_big.png")  # same photo, rescaled
    b.save(tmp_path / "b.png")
    b.save(tmp_path / "b_copy.png")
    c.save(tmp_path / "c.png")
    R = tc.Record
    recs = [R(str(tmp_path / "a.png"), "healthy", "s1", "x"), R(str(tmp_path / "a_big.png"), "healthy", "s2", "x"),
            R(str(tmp_path / "b.png"), "healthy", "s1", "x"), R(str(tmp_path / "b_copy.png"), "greening", "s1", "y"),
            R(str(tmp_path / "c.png"), "canker", "s1", "z")]
    kept, dropped, conflicts = tc.dedupe(recs)
    assert sorted(Path(r.path).name for r in kept) == ["a.png", "c.png"]
    assert (dropped, conflicts) == (1, 2)


def test_extra_split_export_and_card(lm, tmp_path):
    colours = {"canker": (200, 30, 30), "greening": (220, 220, 40), "healthy": (30, 160, 30), "black_spot": (20, 20, 20)}
    extra = tmp_path / "extra"
    for folder, col in colours.items():
        for i in range(6):
            _img(extra / folder / f"{i}.jpg", tuple(min(255, c + 5 * i) for c in col))
    recs, status = tc.collect_extra(extra, lm)
    assert status["status"] == "used" and len(recs) == 24
    assert {r.label for r in recs} == {"canker", "greening", "healthy", "other"}

    train, val, test = tc.stratified_split(recs, 0.2, 0.2, seed=1)
    assert len(train) + len(val) + len(test) == 24
    assert {r.label for r in test} == set(lm["classes"])  # every class in the test set
    assert not {r.path for r in train} & {r.path for r in test}

    classes = lm["classes"]
    size = 32
    xtr, ytr = tc.to_arrays(train, classes, size)
    xte, yte = tc.to_arrays(test, classes, size)
    assert xtr.shape[1:] == (size, size, 3) and xtr.dtype == np.uint8

    model, base = tc.build_model(len(classes), size, weights=None, alpha=0.35)
    tc.train(model, base, tc.make_dataset(xtr, ytr, 8, True), tc.make_dataset(xte, yte, 8, False),
             epochs=1, ft_epochs=1, weights=tc.class_weights(ytr, len(classes)))

    out = tmp_path / "out"
    out.mkdir()
    for quant in ("float16", "int8"):
        path = out / f"m_{quant}.tflite"
        size_bytes = tc.export_tflite(model, xtr, path, quant)
        assert size_bytes == path.stat().st_size > 0
        pred = tc.predict_tflite(path, xte)
        assert pred.shape == yte.shape and pred.min() >= 0 and pred.max() < len(classes)

    labels = tc.write_labels(out, classes).read_text().split()
    assert labels == classes

    cm = tc.confusion(yte, pred, len(classes))
    assert cm.sum() == len(yte)
    info = {
        "model_name": "m_int8.tflite", "date": "test", "alpha": 0.35, "base_weights": "none",
        "epochs": 1, "ft_epochs": 1, "quant": "int8", "size_bytes": size_bytes, "sha256": "x",
        "img_size": size, "tf_version": "t", "keras_version": "k", "classes": classes,
        "sources": {"extra": {**status, "counts": {"canker": 6}}},
        "raw_to_class": sorted({(r.source, r.raw_label, r.label) for r in recs}),
        "seed": 1, "split": {c: {"train": 1, "val": 1, "test": 1} for c in classes},
        "confusion": cm, "keras_test_acc": 0.5, "per_source": {"extra": (1, len(yte))},
    }
    card = tc.write_model_card(out, info).read_text()
    for needle in ("## Data sources", "Own photos", "Confusion matrix", "| canker |", "## Limits", "extra/black_spot"):
        assert needle in card
