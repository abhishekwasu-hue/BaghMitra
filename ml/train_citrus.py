"""Train the on-device citrus leaf classifier (OPEN_QUESTIONS Q135).

Transfer learning on Keras MobileNetV2 (ImageNet weights), exported as an int8
(default) or float16 TFLite file with labels.txt and model_card.md.

Data: only public sets whose licence is confirmed (CC BY 4.0), plus an optional
folder of labelled field photos (--extra DIR, one subfolder per class).
See docs/runbooks/photo-model.md.
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime as dt
import hashlib
import json
import os
import random
import re
import shutil
import urllib.error
import urllib.request
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

HERE = Path(__file__).resolve().parent
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
USER_AGENT = "BagMitra-model-training/1.0"

SOURCES = {
    "citrus_leaves": {
        "title": "Rauf et al. 2019, citrus leaves (TensorFlow Datasets `citrus_leaves`)",
        "url": "https://data.mendeley.com/datasets/3f83gxmv57/2",
        "licence": "CC BY 4.0 (stated in the TFDS builder: creativecommons.org/licenses/by/4.0)",
        "citation": "Rauf H.T. et al., A citrus fruits and leaves dataset for detection and "
        "classification of citrus diseases through machine learning, Data in Brief 26 (2019) "
        "104340, doi 10.1016/j.dib.2019.104340",
        "where": "Field (orchards), Sargodha, Pakistan; DSLR",
    },
    "mendeley_hlb_mexico": {
        "title": "Orange leaves images dataset for the detection of HLB (Mendeley `jgkh2jxbwt`)",
        "url": "https://data.mendeley.com/datasets/jgkh2jxbwt",
        "licence": "CC BY 4.0 (used only if the Mendeley API states it in the runner)",
        "citation": "Orange Leaves Images Dataset for the Detection of HLB, Data 10(5):56 (2025), "
        "Mendeley doi 10.17632/jgkh2jxbwt",
        "where": "San Luis Potosi, Mexico; leaves on a white sheet (controlled)",
    },
    "extra": {
        "title": "Extra labelled photos (--extra)",
        "url": "-",
        "licence": "Own photos (BagMitra)",
        "citation": "-",
        "where": "As exported",
    },
}

MENDELEY_ID = "jgkh2jxbwt"
MENDELEY_API = "https://data.mendeley.com/public-api"
CC_BY_4 = re.compile(r"(cc[\s_-]*by[\s_-]*4\.0|creativecommons\.org/licenses/by/4\.0)", re.I)
CC_RESTRICTED = re.compile(r"(\bnc\b|\bnd\b|\bsa\b|noncommercial|noderiv|sharealike)", re.I)


@dataclasses.dataclass(frozen=True)
class Record:
    path: str
    label: str  # model class
    source: str
    raw_label: str


# --------------------------------------------------------------------------- labels


def load_labels_map(path: Path) -> dict:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    classes = data["classes"]
    if len(classes) != len(set(classes)):
        raise ValueError("labels_map.json: duplicate class names")
    for src, table in data["sources"].items():
        for raw, target in table.items():
            if raw.startswith("_"):
                continue
            if target not in classes:
                raise ValueError(f"labels_map.json: {src}/{raw} -> {target!r} is not in classes")
    return data


def map_label(labels_map: dict, source: str, raw: str) -> str:
    """Exact mapping for a source's raw label. Raises KeyError when unmapped."""
    table = labels_map["sources"].get(source, {})
    if raw in table and not raw.startswith("_"):
        return table[raw]
    if source == "extra" and raw in labels_map["classes"]:
        return raw
    raise KeyError(f"no class for {source}/{raw!r}; add it to ml/labels_map.json")


def match_folder_label(labels_map: dict, source: str, folder: str) -> str | None:
    """Substring match (case-insensitive, longest key first) for archive folder names."""
    table = {k: v for k, v in labels_map["sources"].get(source, {}).items() if not k.startswith("_")}
    name = folder.lower()
    for key in sorted(table, key=len, reverse=True):
        if key.lower() in name:
            return table[key]
    return None


# --------------------------------------------------------------------------- sources


def collect_citrus_leaves(work: Path, labels_map: dict) -> tuple[list[Record], dict]:
    import tensorflow_datasets as tfds

    out_dir = work / "images" / "citrus_leaves"
    ds, info = tfds.load(
        "citrus_leaves", split="train", data_dir=str(work / "tfds"), with_info=True,
        as_supervised=False,
    )
    names = info.features["label"].names
    records: list[Record] = []
    for i, ex in enumerate(tfds.as_numpy(ds)):
        raw = names[int(ex["label"])]
        target = map_label(labels_map, "citrus_leaves", raw)
        dest = out_dir / raw.replace(" ", "_") / f"{i:05d}.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.exists():
            Image.fromarray(ex["image"]).save(dest)
        records.append(Record(str(dest), target, "citrus_leaves", raw))
    status = {
        "status": "used",
        "note": f"TFDS {info.version}: {info.splits['train'].num_examples} leaf images; "
        "TFDS drops the 13 melanose leaves and all fruit images.",
    }
    return records, status


def _http_json(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def _http_download(url: str, dest: Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=600) as r, open(dest, "wb") as f:
        shutil.copyfileobj(r, f)


def _licence_strings(obj, inside: bool = False) -> list[str]:
    """All string values under any key whose name contains 'licen'."""
    found: list[str] = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            hit = inside or "licen" in str(k).lower()
            if isinstance(v, str) and hit:
                found.append(v)
            else:
                found.extend(_licence_strings(v, hit))
    elif isinstance(obj, list):
        for v in obj:
            found.extend(_licence_strings(v, inside))
    elif isinstance(obj, str) and inside:
        found.append(obj)
    return found


def licence_is_cc_by_4(meta) -> tuple[bool, str]:
    texts = _licence_strings(meta)
    joined = " | ".join(texts)
    ok = bool(CC_BY_4.search(joined)) and not CC_RESTRICTED.search(joined)
    return ok, joined or "(no licence field found)"


def _find_files(obj) -> list[dict]:
    """File entries anywhere in a Mendeley JSON answer (dicts with a download_url)."""
    out: list[dict] = []
    if isinstance(obj, dict):
        details = obj.get("content_details") or {}
        url = details.get("download_url") if isinstance(details, dict) else None
        url = url or obj.get("download_url")
        if url:
            out.append({"name": obj.get("filename") or obj.get("name") or "file", "url": url})
        else:
            for v in obj.values():
                out.extend(_find_files(v))
    elif isinstance(obj, list):
        for v in obj:
            out.extend(_find_files(v))
    return out


def _extract_all(archive_dir: Path, dest: Path) -> None:
    """Extract every zip (also zips found inside zips) into dest."""
    pending = sorted(archive_dir.rglob("*.zip"))
    seen: set[Path] = set()
    while pending:
        z = pending.pop()
        if z in seen:
            continue
        seen.add(z)
        target = dest / z.stem
        with zipfile.ZipFile(z) as zf:
            for member in zf.infolist():
                p = (target / member.filename).resolve()
                if not str(p).startswith(str(target.resolve())):
                    raise ValueError(f"unsafe path in {z.name}: {member.filename}")
            zf.extractall(target)
        pending.extend(q for q in target.rglob("*.zip") if q not in seen)
    for f in archive_dir.iterdir():
        if f.suffix.lower() in IMAGE_EXTS:
            (dest / "loose").mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest / "loose" / f.name)


def records_from_tree(root: Path, labels_map: dict, source: str) -> tuple[list[Record], Counter]:
    """Label each image by the nearest ancestor folder that matches the map."""
    records: list[Record] = []
    unmatched: Counter = Counter()
    for p in sorted(root.rglob("*")):
        if p.suffix.lower() not in IMAGE_EXTS or "__MACOSX" in p.parts:
            continue
        label = None
        raw = p.parent.name
        for parent in p.relative_to(root).parents:
            if parent.name and (m := match_folder_label(labels_map, source, parent.name)):
                label, raw = m, parent.name
                break
        if label is None:
            unmatched[str(p.parent.relative_to(root))] += 1
            continue
        records.append(Record(str(p), label, source, raw))
    return records, unmatched


def collect_mendeley_hlb(work: Path, labels_map: dict) -> tuple[list[Record], dict]:
    source = "mendeley_hlb_mexico"
    base = work / "mendeley" / MENDELEY_ID
    try:
        meta = _http_json(f"{MENDELEY_API}/datasets/{MENDELEY_ID}")
    except Exception as e:  # network, HTTP or JSON error
        return [], {"status": "skipped", "note": f"metadata not fetched: {e!r}"}
    print(f"[mendeley] metadata keys: {sorted(meta)[:40] if isinstance(meta, dict) else type(meta)}")
    ok, lic = licence_is_cc_by_4(meta)
    print(f"[mendeley] licence fields: {lic[:300]}")
    if not ok:
        return [], {"status": "skipped", "note": f"licence not confirmed as CC BY 4.0: {lic[:200]}"}
    version = meta.get("version") if isinstance(meta, dict) else None
    raw_dir = base / "raw"
    ext_dir = base / "extracted"
    if not ext_dir.exists():
        raw_dir.mkdir(parents=True, exist_ok=True)
        files: list[dict] = []
        attempts = [f"{MENDELEY_API}/datasets/{MENDELEY_ID}/files?version={version}",
                    f"{MENDELEY_API}/datasets/{MENDELEY_ID}/files?folder_id=root&version={version}"]
        for url in attempts:
            try:
                answer = _http_json(url)
                files = _find_files(answer)
                print(f"[mendeley] {url} -> {len(files)} files")
                if files:
                    break
            except Exception as e:
                print(f"[mendeley] {url} -> {e!r}")
        try:
            if files:
                for f in files:
                    name = re.sub(r"[^\w.\-]", "_", f["name"])
                    print(f"[mendeley] download {name}")
                    _http_download(f["url"], raw_dir / name)
            else:
                url = f"{MENDELEY_API}/zip/{MENDELEY_ID}/download/{version}"
                print(f"[mendeley] download {url}")
                _http_download(url, raw_dir / "all.zip")
            ext_dir.mkdir(parents=True, exist_ok=True)
            _extract_all(raw_dir, ext_dir)
        except Exception as e:
            shutil.rmtree(ext_dir, ignore_errors=True)
            return [], {"status": "skipped", "note": f"files not downloaded: {e!r}"}
    records, unmatched = records_from_tree(ext_dir, labels_map, source)
    folders = Counter(r.raw_label for r in records)
    print(f"[mendeley] matched folders: {dict(folders)}; unmatched: {dict(unmatched)}")
    if not records:
        return [], {"status": "skipped", "note": f"no folder matched labels_map: {dict(unmatched)}"}
    note = f"version {version}; licence field: {lic[:120]}"
    if unmatched:
        note += f"; skipped unmatched folders {dict(unmatched)}"
    return records, {"status": "used", "note": note}


def collect_extra(extra: Path, labels_map: dict) -> tuple[list[Record], dict]:
    records: list[Record] = []
    for sub in sorted(p for p in Path(extra).iterdir() if p.is_dir()):
        target = map_label(labels_map, "extra", sub.name)  # raises on an unknown folder
        for p in sorted(sub.rglob("*")):
            if p.suffix.lower() in IMAGE_EXTS:
                records.append(Record(str(p), target, "extra", sub.name))
    if not records:
        raise ValueError(f"--extra {extra}: no images in class subfolders")
    return records, {"status": "used", "note": f"folder {extra}"}


# --------------------------------------------------------------------------- split / images


def stratified_split(records, val_frac=0.15, test_frac=0.15, seed=42):
    """Split per (class, source) so each source is present in val and test."""
    groups: dict[tuple, list] = defaultdict(list)
    for r in records:
        groups[(r.label, r.source)].append(r)
    rng = random.Random(seed)
    train, val, test = [], [], []
    for key in sorted(groups):
        g = sorted(groups[key], key=lambda r: r.path)
        rng.shuffle(g)
        n = len(g)
        n_test = max(1, round(n * test_frac)) if n >= 3 else 0
        n_val = max(1, round(n * val_frac)) if n >= 3 else 0
        test += g[:n_test]
        val += g[n_test:n_test + n_val]
        train += g[n_test + n_val:]
    return train, val, test


def load_image(path: str, size: int) -> np.ndarray:
    """Whole photo, EXIF-rotated, RGB, resized (no crop) to size x size, uint8."""
    with Image.open(path) as im:
        im = ImageOps.exif_transpose(im).convert("RGB")
        return np.asarray(im.resize((size, size), Image.BILINEAR), dtype=np.uint8)


def to_arrays(records, classes, size):
    x = np.stack([load_image(r.path, size) for r in records]) if records else np.zeros((0, size, size, 3), np.uint8)
    y = np.array([classes.index(r.label) for r in records], dtype=np.int32)
    return x, y


# --------------------------------------------------------------------------- model


def build_model(num_classes: int, img_size: int = 224, weights: str | None = "imagenet", alpha: float = 1.0):
    import keras

    inp = keras.Input((img_size, img_size, 3), name="image")  # RGB floats 0..255
    x = keras.layers.Rescaling(1 / 127.5, offset=-1.0)(inp)
    base = keras.applications.MobileNetV2(
        input_shape=(img_size, img_size, 3), include_top=False, weights=weights, alpha=alpha, pooling="avg"
    )
    base.trainable = False
    x = base(x, training=False)
    x = keras.layers.Dropout(0.2)(x)
    out = keras.layers.Dense(num_classes, activation="softmax", name="probs")(x)
    return keras.Model(inp, out), base


def make_dataset(x, y, batch, training, seed=42):
    import keras
    import tensorflow as tf

    ds = tf.data.Dataset.from_tensor_slices((x, y))
    if training:
        ds = ds.shuffle(len(x), seed=seed, reshuffle_each_iteration=True)
    ds = ds.batch(batch).map(lambda a, b: (tf.cast(a, tf.float32), b))
    if training:
        aug = keras.Sequential([
            keras.layers.RandomFlip("horizontal_and_vertical", seed=seed),
            keras.layers.RandomRotation(0.1, seed=seed),
            keras.layers.RandomZoom(0.15, seed=seed),
            keras.layers.RandomContrast(0.2, seed=seed),
        ])
        ds = ds.map(lambda a, b: (tf.clip_by_value(aug(a, training=True), 0.0, 255.0), b))
    return ds.prefetch(tf.data.AUTOTUNE)


def class_weights(y, n):
    counts = np.bincount(y, minlength=n)
    return {i: (len(y) / (n * c)) if c else 0.0 for i, c in enumerate(counts)}


def train(model, base, train_ds, val_ds, epochs, ft_epochs, weights, ft_layers=40):
    import keras

    stop = lambda: keras.callbacks.EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True)
    model.compile(keras.optimizers.Adam(1e-3), "sparse_categorical_crossentropy", metrics=["accuracy"])
    model.fit(train_ds, validation_data=val_ds, epochs=epochs, class_weight=weights, callbacks=[stop()], verbose=2)
    if ft_epochs > 0:
        base.trainable = True
        for layer in base.layers[:-ft_layers]:
            layer.trainable = False
        for layer in base.layers:
            if isinstance(layer, keras.layers.BatchNormalization):
                layer.trainable = False
        model.compile(keras.optimizers.Adam(1e-5), "sparse_categorical_crossentropy", metrics=["accuracy"])
        model.fit(train_ds, validation_data=val_ds, epochs=ft_epochs, class_weight=weights, callbacks=[stop()], verbose=2)
    return model


# --------------------------------------------------------------------------- export / evaluate


def export_tflite(model, rep_images: np.ndarray, out_path: Path, quant: str = "int8") -> int:
    import tensorflow as tf

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    if quant == "int8":
        def rep():
            for img in rep_images[:200]:
                yield [img[None].astype(np.float32)]
        converter.representative_dataset = rep
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        # Input and output stay float32 (RGB 0..255 in, probabilities out).
    elif quant == "float16":
        converter.target_spec.supported_types = [tf.float16]
    else:
        raise ValueError(f"unknown quant {quant!r}")
    data = converter.convert()
    Path(out_path).write_bytes(data)
    return len(data)


def _interpreter(model_path: str):
    try:
        from ai_edge_litert.interpreter import Interpreter
    except ImportError:
        import tensorflow as tf
        Interpreter = tf.lite.Interpreter
    return Interpreter(model_path=model_path)


def predict_tflite(model_path: Path, x: np.ndarray) -> np.ndarray:
    it = _interpreter(str(model_path))
    it.allocate_tensors()
    inp = it.get_input_details()[0]
    out = it.get_output_details()[0]
    preds = []
    for img in x:
        it.set_tensor(inp["index"], img[None].astype(inp["dtype"]))
        it.invoke()
        preds.append(int(np.argmax(it.get_tensor(out["index"])[0])))
    return np.array(preds, dtype=np.int32)


def confusion(y_true, y_pred, n):
    cm = np.zeros((n, n), dtype=int)
    for t, p in zip(y_true, y_pred):
        cm[t, p] += 1
    return cm


def write_labels(out_dir: Path, classes) -> Path:
    p = Path(out_dir) / "labels.txt"
    p.write_text("\n".join(classes) + "\n", encoding="utf-8")
    return p


def _pct(a, b):
    return f"{100 * a / b:.1f} %" if b else "n/a"


def write_model_card(out_dir: Path, info: dict) -> Path:
    classes = info["classes"]
    n = len(classes)
    cm = info["confusion"]
    lines = [
        f"# Citrus leaf classifier `{info['model_name']}` — model card",
        "",
        f"- Date (UTC): {info['date']}",
        f"- Commit: {info.get('commit', 'local')}",
        f"- Base: Keras MobileNetV2 (alpha {info['alpha']}, {info['base_weights']} weights), "
        f"transfer learning ({info['epochs']} head epochs + {info['ft_epochs']} fine-tune epochs max, early stopping)",
        f"- File: `{info['model_name']}` — {info['quant']} quantized, {info['size_bytes']:,} bytes, sha256 `{info['sha256']}`",
        f"- Input: 1 x {info['img_size']} x {info['img_size']} x 3 float32, RGB 0..255 (whole photo resized, no crop; "
        f"scaling to -1..1 is inside the model). Output: 1 x {n} float32 probabilities in `labels.txt` order.",
        f"- TensorFlow {info['tf_version']}, Keras {info['keras_version']}",
        "",
        "## Data sources",
        "",
        "| Source | Licence | Status | Images used (raw label: count) | Where taken |",
        "|---|---|---|---|---|",
    ]
    for key, st in info["sources"].items():
        meta = SOURCES[key]
        counts = ", ".join(f"{k}: {v}" for k, v in sorted(st.get("counts", {}).items())) or "0"
        lines.append(f"| {meta['title']} — {meta['url']} | {meta['licence']} | {st['status']}: {st['note']} | {counts} | {meta['where']} |")
    lines += ["", "Citations: " + "; ".join(SOURCES[k]["citation"] for k in info["sources"] if SOURCES[k]["citation"] != "-"), ""]
    lines += ["## Classes (`ml/labels_map.json`)", ""]
    for c in classes:
        raws = sorted({f"{s}/{r}" for (s, r, lab) in info["raw_to_class"] if lab == c})
        lines.append(f"- `{c}` <- {', '.join(raws) if raws else '(no images)'}")
    lines += ["", "## Split (per class and source, seed %d)" % info["seed"], "",
              "| Class | Train | Val | Test |", "|---|---|---|---|"]
    for c in classes:
        lines.append(f"| {c} | {info['split'][c]['train']} | {info['split'][c]['val']} | {info['split'][c]['test']} |")
    tot = {s: sum(info['split'][c][s] for c in classes) for s in ("train", "val", "test")}
    lines.append(f"| **total** | {tot['train']} | {tot['val']} | {tot['test']} |")
    lines += ["", "## Held-out test set (the exported .tflite file)", "",
              "| Class | Test images | Correct | Accuracy (recall) |", "|---|---|---|---|"]
    for i, c in enumerate(classes):
        row = int(cm[i].sum())
        lines.append(f"| {c} | {row} | {int(cm[i, i])} | {_pct(cm[i, i], row)} |")
    total, correct = int(cm.sum()), int(np.trace(cm))
    lines.append(f"| **all** | {total} | {correct} | {_pct(correct, total)} |")
    lines.append("")
    if info.get("keras_test_acc") is not None:
        lines.append(f"Float Keras model before export, same test set: {100 * info['keras_test_acc']:.1f} %.")
        lines.append("")
    lines += ["Confusion matrix (rows = true, columns = predicted):", "",
              "| true \\ pred | " + " | ".join(classes) + " |", "|---" * (n + 1) + "|"]
    for i, c in enumerate(classes):
        lines.append(f"| {c} | " + " | ".join(str(int(v)) for v in cm[i]) + " |")
    lines += ["", "Test accuracy per source:", "", "| Source | Test images | Accuracy |", "|---|---|---|"]
    for src, (ok, cnt) in sorted(info["per_source"].items()):
        lines.append(f"| {src} | {cnt} | {_pct(ok, cnt)} |")
    lines += [
        "",
        "## Limits",
        "",
        "- Test images come from the same sets as the training images (same-dataset numbers). "
        "They do not predict accuracy on a Vidarbha grower's phone photo: studies found lab-to-field accuracy "
        "dropping to 23-31 %. Field photos from the app (stage 2, `--extra`) are the fix; report the test "
        "accuracy of the `extra` source once it exists.",
        "- From the public sets, `other` is black spot only (TFDS drops the 13 melanose leaves). Out-of-scope photos (not citrus, "
        "fruit, trunk, blurred) still get one of the classes; the app needs a confidence threshold.",
        "- No Nagpur mandarin or mosambi images; no psylla, mites, thrips, gummosis or nutrient-deficiency classes.",
        "- Greening vs zinc / other deficiencies is a known look-alike; only PCR confirms greening.",
        "- Test sets are small; one image changes a class's accuracy by several points.",
        "",
    ]
    p = Path(out_dir) / "model_card.md"
    p.write_text("\n".join(lines), encoding="utf-8")
    return p


# --------------------------------------------------------------------------- main


def run(args) -> dict:
    import keras
    import tensorflow as tf

    keras.utils.set_random_seed(args.seed)
    labels_map = load_labels_map(args.labels_map)
    classes = list(labels_map["classes"])
    work, out = Path(args.work), Path(args.out)
    work.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)

    records: list[Record] = []
    sources: dict[str, dict] = {}
    collectors = []
    if not args.no_public:
        collectors.append(("citrus_leaves", lambda: collect_citrus_leaves(work, labels_map)))
        if not args.skip_mendeley:
            collectors.append(("mendeley_hlb_mexico", lambda: collect_mendeley_hlb(work, labels_map)))
        else:
            sources["mendeley_hlb_mexico"] = {"status": "skipped", "note": "--skip-mendeley"}
    if args.extra:
        collectors.append(("extra", lambda: collect_extra(Path(args.extra), labels_map)))
    for key, fn in collectors:
        recs, status = fn()
        status["counts"] = dict(Counter(r.raw_label for r in recs))
        sources[key] = status
        records += recs
        print(f"[data] {key}: {status['status']} ({len(recs)} images) {status['note']}")
    if not records:
        raise SystemExit("no training images")

    train_r, val_r, test_r = stratified_split(records, args.val_frac, args.test_frac, args.seed)
    split = {c: {"train": 0, "val": 0, "test": 0} for c in classes}
    for name, rs in (("train", train_r), ("val", val_r), ("test", test_r)):
        for r in rs:
            split[r.label][name] += 1
    print(f"[data] split: {split}")

    xtr, ytr = to_arrays(train_r, classes, args.img_size)
    xva, yva = to_arrays(val_r, classes, args.img_size)
    xte, yte = to_arrays(test_r, classes, args.img_size)

    weights = None if args.base_weights == "none" else args.base_weights
    model, base = build_model(len(classes), args.img_size, weights, args.alpha)
    train(model, base, make_dataset(xtr, ytr, args.batch, True, args.seed),
          make_dataset(xva, yva, args.batch, False), args.epochs, args.fine_tune_epochs,
          class_weights(ytr, len(classes)))

    keras_acc = None
    if len(xte):
        keras_pred = np.argmax(model.predict(xte.astype(np.float32), verbose=0), axis=1)
        keras_acc = float(np.mean(keras_pred == yte))

    model_path = out / args.model_name
    size = export_tflite(model, xtr, model_path, args.quant)
    write_labels(out, classes)
    pred = predict_tflite(model_path, xte)
    cm = confusion(yte, pred, len(classes))
    per_source: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    for r, t, p in zip(test_r, yte, pred):
        per_source[r.source][0] += int(t == p)
        per_source[r.source][1] += 1

    info = {
        "model_name": args.model_name,
        "date": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M"),
        "commit": os.environ.get("GITHUB_SHA", "local")[:12],
        "alpha": args.alpha,
        "base_weights": args.base_weights,
        "epochs": args.epochs,
        "ft_epochs": args.fine_tune_epochs,
        "quant": args.quant,
        "size_bytes": size,
        "sha256": hashlib.sha256(model_path.read_bytes()).hexdigest(),
        "img_size": args.img_size,
        "tf_version": tf.__version__,
        "keras_version": keras.__version__,
        "classes": classes,
        "sources": sources,
        "raw_to_class": sorted({(r.source, r.raw_label, r.label) for r in records}),
        "seed": args.seed,
        "split": split,
        "confusion": cm,
        "keras_test_acc": keras_acc,
        "per_source": {k: tuple(v) for k, v in per_source.items()},
    }
    card = write_model_card(out, info)
    print(card.read_text(encoding="utf-8"))
    return info


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=str(HERE / "out"), help="output folder for .tflite, labels.txt, model_card.md")
    ap.add_argument("--work", default=str(HERE / "work"), help="download / cache folder")
    ap.add_argument("--extra", default=None, help="folder of extra labelled photos, one subfolder per class")
    ap.add_argument("--labels-map", default=str(HERE / "labels_map.json"))
    ap.add_argument("--model-name", default="citrus_v1.tflite")
    ap.add_argument("--img-size", type=int, default=224)
    ap.add_argument("--alpha", type=float, default=1.0, help="MobileNetV2 width")
    ap.add_argument("--base-weights", default="imagenet", choices=["imagenet", "none"])
    ap.add_argument("--epochs", type=int, default=8, help="head-only epochs")
    ap.add_argument("--fine-tune-epochs", type=int, default=4)
    ap.add_argument("--batch", type=int, default=32)
    ap.add_argument("--quant", default="int8", choices=["int8", "float16"])
    ap.add_argument("--val-frac", type=float, default=0.15)
    ap.add_argument("--test-frac", type=float, default=0.15)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--skip-mendeley", action="store_true", help="do not try the Mexico HLB set")
    ap.add_argument("--no-public", action="store_true", help="train on --extra only")
    return ap.parse_args(argv)


if __name__ == "__main__":
    run(parse_args())
