# Photo model: on-device citrus leaf classifier (OPEN_QUESTIONS Q135)

Owner decision 2026-11-11: photo diagnosis runs **on the phone** (offline, no per-photo cost).
This runbook covers the training pipeline (stages 1 and 3) and the model in the app (§3).

| Item | Value |
|---|---|
| Workflow | `.github/workflows/train-photo-model.yml` (manual only, no secrets) |
| Script | `ml/train_citrus.py`, pins in `ml/requirements.txt` (Python 3.12) |
| Model | Keras MobileNetV2, ImageNet weights, transfer learning, image 224 |
| Output | `citrus_v1.tflite` (int8, float I/O), `labels.txt`, `model_card.md` |
| Classes | `ml/labels_map.json`: canker, greening, healthy, other |
| Smoke test | `ml/test_pipeline.py` (synthetic images, no downloads) |

## 1. Run the workflow

GitHub → Actions → **Train photo model** → Run workflow (choose the branch). Inputs: head epochs
(default 8), fine-tune epochs (default 4), `int8` or `float16`, skip the Mexico set. From a
terminal:

```
gh api -X POST repos/abhishekwasu-hue/BaghMitra/actions/workflows/train-photo-model.yml/dispatches -f ref=main
```

The run (CPU, timeout 90 min) runs the smoke test, downloads the data, trains, exports, and
evaluates the **exported `.tflite`** on the held-out test set. Results:

- Artifact **citrus-photo-model** (30 days): `citrus_v1.tflite`, `labels.txt`, `model_card.md`.
- Job log: `model_card.md`, `labels.txt`, the sha256 and the model as base64 between
  `BEGIN_TFLITE_BASE64` / `END_TFLITE_BASE64` (collapsed groups). To rebuild the file from the log:
  save the job log (`gh api repos/abhishekwasu-hue/BaghMitra/actions/jobs/<job id>/logs > job.log`),
  then

  ```
  awk '/ BEGIN_TFLITE_BASE64$/{f=1;next} / END_TFLITE_BASE64$/{f=0} f' job.log \
    | sed 's/^[^ ]* //' | base64 -d > citrus_v1.tflite && sha256sum citrus_v1.tflite
  ```

  (the `sed` strips the log's timestamps) and compare the sha256 with the log.

## 2. Data (only licence-confirmed public sets)

| Source | Licence | What |
|---|---|---|
| Rauf et al. 2019, TFDS `citrus_leaves` (Mendeley 3f83gxmv57) | CC BY 4.0 | 594 leaves, field, Pakistan: black spot, canker, greening, healthy (TFDS drops the 13 melanose leaves) |
| Mexico HLB, Mendeley `jgkh2jxbwt` | CC BY 4.0 | HLB and control leaves on a white sheet. Used only if the runner reads the licence from the Mendeley API as CC BY 4.0 and the download works; otherwise skipped and the model card says why |

Mexico archive labels come from folder names (`ml/labels_map.json`): an image takes the class of
its nearest folder that matches a key; a folder whose name matches two classes (e.g. "HLB and
Healthy") labels nothing, and skipped folders are listed in the log and the model card. The log
prints the archive's whole folder tree (`[mendeley] tree:`) so the map can be extended. Repeated
photos (the same photo in two zips, resaved or rescaled) are removed before the split, so no copy
of a test photo is trained on; copies carrying two classes are dropped.

Mexico archive (version 3) as read in the runner: `Database HLB Sanas Final/HOJAS CON SINTOMAS`
(270, → greening) and `HOJAS SANAS` (379, → healthy) are the raw photos (the paper's 270 HLB / 379
control). The second zip holds `preprocessed_images` and `visualizations` of the same photos;
they are **not used**: the first run that used them labelled healthy from raw photos and greening
from processed ones, and the model scored 100 % on that source — it can learn the processing
instead of the disease.

Sets whose licence is not confirmed (Bangladesh sweet orange, MNIT, lemon sets, Hugging Face
mirrors, Kaggle copies) are **not** used. Attribution (CC BY): the model card lists the citations;
the app shows them under Settings → photo model data sources (§3).

### First model (workflow run 42966101512, 2026-11-11, commit 9a39f3a)

`citrus_v1.tflite` int8, 2,735,448 bytes, sha256 `16aa4482…3ae29a`. 1,243 photos (Rauf 594 +
Mexico 649, no repeats found), split 871 / 186 / 186. Held-out test, exported file
(same-dataset numbers, see §6):

| Class | Test | Accuracy |
|---|---|---|
| canker | 24 | 91.7 % |
| greening | 71 | 90.1 % |
| healthy | 66 | 90.9 % |
| other (black spot) | 25 | 52.0 % (11 of 25 called greening) |
| **all** | 186 | **85.5 %** |

Per source: Pakistan field photos 76.4 % (89), Mexico white-sheet photos 93.8 % (97).

## 3. The model in the app (offline path of "फोटोवरून ओळखा")

| Item | Value |
|---|---|
| Files | `app/assets/models/citrus_v1.tflite`, `citrus_v1_labels.txt` (copy of `labels.txt`), `citrus_v1_model_card.md` (repo only, not in the APK) |
| Package | `tflite_flutter` 0.12.1, exact pin (LiteRT 1.4.0, 16 KB page aligned). `libtensorflowlite_gpu_jni.so` is excluded in `android/app/build.gradle.kts` (CPU only) |
| Code | `lib/features/photo_analysis/domain/offline_check.dart` (constants, output → verdict), `data/offline_leaf_model.dart` (preprocessing, `LeafModel` interface, `TfliteLeafModel`) |
| Threshold | `OfflineModel.minConfidence` = 0.60 (provisional, Q135 (d)); second disease named from `OfflineModel.secondFrom` = 0.25 |
| When it runs | Only when the online check fails with `PhotoProblem.offline`; never online, never on a server error, timeout or limit; never counted against limits |

Input: one RGB photo (the prepared JPEG the online check would send), upright, resized to
224 x 224 (whole photo, no crop) with the same resize as training (PIL bilinear, re-implemented in
Dart; matches PIL within 1 level on a lossless test picture), float32 0..255; the scaling is inside
the model. Output: probabilities in `labels.txt` order. Class names equal the practice-card keys
(`canker`, `greening`) so a result can open that card; `healthy` and `other` have no card. The
interpreter is created, run and closed in a background isolate per photo.

Tests: the real interpreter cannot run in `flutter test` (the TFLite native library is only
packaged for Android / iOS), so `offlineLeafCheckProvider` is null there and widget tests use a
fake `LeafModel`. Unit tests cover preprocessing, the output mapping and threshold, the labels
order against `ml/labels_map.json`, and the model file's size and sha256 against the model card.
Goldens: `photo_check_on_phone_mr_{light,dark}_x13.png`.

**New model:** replace the three files together (a new class changes `labels.txt` order), update
the size / sha256 expectations in `test/features/photo_analysis/offline_check_test.dart`, and
re-check the threshold on field photos. Attribution: Settings → photo model data sources
(`offlineModelCitations`); add any new data set there.

## 4. Add field photos (stage 2, `--extra`)

The server's labelled samples (exported by an admin endpoint, built separately) go in one folder
with one subfolder per class:

```
field_photos/
  canker/    *.jpg
  greening/  *.jpg
  healthy/   *.jpg
  other/     *.jpg
```

- A subfolder name must be a class in `ml/labels_map.json` `classes`, or an alias under
  `sources.extra` (e.g. `black_spot` → `other`). Any other name stops the run with an error, so
  no photo is silently mislabelled.
- New class (e.g. `psylla`, `mites`): add the practice-card key to `classes` (the order is the
  `labels.txt` order, so the app must take the new labels file with the new model).
- Run locally (the workflow has no secret and no photo store, so field photos are trained
  locally or on a machine that holds them):

```
python3.12 -m venv .venv && .venv/bin/pip install -r ml/requirements.txt
.venv/bin/python ml/train_citrus.py --extra /path/to/field_photos --out ml/out
# field photos only:  add --no-public
```

The model card reports test accuracy **per source**; the `extra` row is the number that counts
for Vidarbha.

## 5. Smoke test

```
.venv/bin/python -m pytest -q ml/test_pipeline.py
```

It also runs as the first step of the training workflow. It is not wired into the per-PR CI:
installing TensorFlow (~600 MB) on every PR is not cheap.

## 6. Honest limits

- The test numbers are same-dataset numbers (test photos come from the same sets as training).
  Studies found lab-to-field accuracy dropping to **23–31 %** (PlantVillage → other sources,
  PlantVillage → PlantDoc). Pakistan field and Mexico white-sheet photos may not transfer to a
  Vidarbha grower's phone photo. **Field photos from the app (stage 2) are the fix**, and the test
  set for any shipped claim must be Vidarbha field photos.
- No Nagpur mandarin or mosambi images; no psylla, mites, thrips, gummosis or deficiency classes.
- `other` is black spot only from the public data. A photo that is not a citrus leaf still gets a
  class: the app needs a confidence threshold set from field test photos and a "not sure" path.
- Greening vs zinc / other deficiencies is a known look-alike; only PCR confirms greening
  (ICAR-CCRI Nagpur, `app/assets/config/lab_directory.json`).
- All Mexico photos (both classes) are single leaves on a white sheet; the Pakistan photos are
  not. Background and camera differ by source, so the model may partly learn the source; the
  per-source test table shows each source separately.
- Classes are small (original Rauf set: healthy 58, canker 163 leaves); one test image moves a class's accuracy by
  several points.
