# Citrus leaf classifier `citrus_v1.tflite` — model card

- Date (UTC): 2026-11-11 05:39
- Commit: 9a39f3abd11f
- Base: Keras MobileNetV2 (alpha 1.0, imagenet weights), transfer learning (8 head epochs + 4 fine-tune epochs max, early stopping)
- File: `citrus_v1.tflite` — int8 quantized, 2,735,448 bytes, sha256 `16aa44825c822aec906a13bb0514d29db920666234799b127e09dd5f243ae29a`
- Input: 1 x 224 x 224 x 3 float32, RGB 0..255 (whole photo resized, no crop; scaling to -1..1 is inside the model). Output: 1 x 4 float32 probabilities in `labels.txt` order.
- TensorFlow 2.21.0, Keras 3.15.1

## Data sources

| Source | Licence | Status | Images used (raw label: count) | Where taken |
|---|---|---|---|---|
| Rauf et al. 2019, citrus leaves (TensorFlow Datasets `citrus_leaves`) — https://data.mendeley.com/datasets/3f83gxmv57/2 | CC BY 4.0 (stated in the TFDS builder: creativecommons.org/licenses/by/4.0) | used: TFDS 0.1.2: 594 leaf images; TFDS drops the 13 melanose leaves and all fruit images. | Black spot: 169, canker: 163, greening: 204, healthy: 58 (after removing repeats: 594) | Field (orchards), Sargodha, Pakistan; DSLR |
| Orange leaves images dataset for the detection of HLB (Mendeley `jgkh2jxbwt`) — https://data.mendeley.com/datasets/jgkh2jxbwt | CC BY 4.0 (used only if the Mendeley API states it in the runner) | used: version 3; licence field: 01d9c749-3c4d-4431-9df3-620b2dcfe144 | You can share, copy and modify this dataset so long as you give appropriate credi; skipped unmatched folders {'Database_HLB_and_Healthy_-_Final-20250130T195640Z-002/Database HLB and Healthy - Final/Healty Leaves/Raw Images Healthy ': 129, 'Database_HLB_and_Healthy_-_Final-20250130T195640Z-002/Database HLB and Healthy - Final/Healty Leaves/preprocessed_images': 129, 'Database_HLB_and_Healthy_-_Final-20250130T195640Z-002/Database HLB and Healthy - Final/Healty Leaves/visualizations': 129, 'Database_HLB_and_Healthy_-_Final-20250130T195640Z-002/Database HLB and Healthy - Final/Symptoms HLB Leaves/preprocessed_images': 195, 'Database_HLB_and_Healthy_-_Final-20250130T195640Z-002/Database HLB and Healthy - Final/Symptoms HLB Leaves/visualizations': 48} | HOJAS CON SINTOMAS: 270, HOJAS SANAS: 379 (after removing repeats: 649) | San Luis Potosi, Mexico; leaves on a white sheet (controlled) |

Citations: Rauf H.T. et al., A citrus fruits and leaves dataset for detection and classification of citrus diseases through machine learning, Data in Brief 26 (2019) 104340, doi 10.1016/j.dib.2019.104340; Orange Leaves Images Dataset for the Detection of HLB, Data 10(5):56 (2025), Mendeley doi 10.17632/jgkh2jxbwt

## Classes (`ml/labels_map.json`)

- `canker` <- citrus_leaves/canker
- `greening` <- citrus_leaves/greening, mendeley_hlb_mexico/HOJAS CON SINTOMAS
- `healthy` <- citrus_leaves/healthy, mendeley_hlb_mexico/HOJAS SANAS
- `other` <- citrus_leaves/Black spot

## Split (per class and source, seed 42)

0 repeated photos removed and 0 photos dropped whose copies carried two different classes (256-bit difference hash, copies = at most 12 bits apart).

| Class | Train | Val | Test |
|---|---|---|---|
| canker | 115 | 24 | 24 |
| greening | 332 | 71 | 71 |
| healthy | 305 | 66 | 66 |
| other | 119 | 25 | 25 |
| **total** | 871 | 186 | 186 |

## Held-out test set (the exported .tflite file)

| Class | Test images | Correct | Accuracy (recall) |
|---|---|---|---|
| canker | 24 | 22 | 91.7 % |
| greening | 71 | 64 | 90.1 % |
| healthy | 66 | 60 | 90.9 % |
| other | 25 | 13 | 52.0 % |
| **all** | 186 | 159 | 85.5 % |

Float Keras model before export, same test set: 83.3 %.

Confusion matrix (rows = true, columns = predicted):

| true \ pred | canker | greening | healthy | other |
|---|---|---|---|---|
| canker | 22 | 2 | 0 | 0 |
| greening | 0 | 64 | 5 | 2 |
| healthy | 0 | 6 | 60 | 0 |
| other | 0 | 11 | 1 | 13 |

Test accuracy per source:

| Source | Test images | Accuracy |
|---|---|---|
| citrus_leaves | 89 | 76.4 % |
| mendeley_hlb_mexico | 97 | 93.8 % |

## Limits

- Test images come from the same sets as the training images (same-dataset numbers). They do not predict accuracy on a Vidarbha grower's phone photo: studies found lab-to-field accuracy dropping to 23-31 %. Field photos from the app (stage 2, `--extra`) are the fix; report the test accuracy of the `extra` source once it exists.
- From the public sets, `other` is black spot only (TFDS drops the 13 melanose leaves). Out-of-scope photos (not citrus, fruit, trunk, blurred) still get one of the classes; the app needs a confidence threshold.
- No Nagpur mandarin or mosambi images; no psylla, mites, thrips, gummosis or nutrient-deficiency classes.
- Greening vs zinc / other deficiencies is a known look-alike; only PCR confirms greening.
- Test sets are small; one image changes a class's accuracy by several points.
