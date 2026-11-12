# Crop photo analysis (Q135, stage 2: server)

The farmer sends one photo (leaf, fruit, trunk or whole tree) of their own plot; Claude names up
to three problems from the practice cards with the visible signs and a calm explanation in
en / mr / hi. Every analysed photo is kept as a training sample. Consent is the one given at
signup through the privacy policy: nothing is asked per photo (owner decision).

## 1. Switch it on

| Setting (`deploy/.env`) | Default | Meaning |
|---|---|---|
| `PHOTO_AI_API_KEY` | empty | Anthropic API key. Empty: `FEED_AI_API_KEY` is used. Both empty: the endpoint answers 503 `analysis_unavailable`. A secret: never in git or chat. |
| `PHOTO_AI_MODEL` | `claude-opus-5-5` | The model. Thinking is not sent (adaptive by default; "disabled" or a budget is a 400 on this model); effort is left at the model default. |
| `PHOTO_AI_MAX_TOKENS` | 8000 | Answer ceiling, thinking included. |
| `PHOTO_AI_TIMEOUT_SECONDS` | 120 | How long the API waits for the model. |
| `PHOTO_AI_RETENTION_DAYS` | 730 | Samples (row and photo) older than this are deleted nightly; the privacy page shows this value. |
| `CRON_PHOTO_AI_RETENTION` | on | `deploy.sh` adds the nightly job `python -m bagmitra_api.photo_ai.retention` (22:29 UTC = 03:59 IST); `off` removes it. |
| `PHOTO_STORAGE_*` | (photo backup) | Where the sample photos go (`<owner_id>/analysis-<id>.jpg|png`, the user's own folder). Without storage the analysis still works and the result is kept without the photo. |
| `PHOTO_MAX_BYTES` | 2 MiB | Largest photo (413 `photo_too_large`). |

The request uses the same Messages API call as the feed (`feed/ai.py: messages_text`): API
version `2026-10-21`, beta `server-side-fallback-2026-07-01` with `fallbacks: "default"`, the
photo as a base64 image block before the text, structured output (`output_config.format`).
The photo's EXIF / PNG text chunks (GPS point, phone, time) are removed before it is sent or
stored. A refusal, a cut-off answer or invalid JSON answers 502 `analysis_failed`; nothing is
stored or counted then.

## 2. Limits (admin web → Subscription / सदस्यता; role `billing_admin`)

Owner 2026-11-11: the limits follow the subscription plan and are set in the admin settings.

| Where | API | Empty means |
|---|---|---|
| Per role plan: photos per day / per month for a farmer on that plan | `PUT /v1/admin/billing/roles/{role}/photo-limits` `{daily, monthly}` | 5 a day / 50 a month |
| Without a plan (also while the subscription switch is off or not started): per day / per month | `PUT /v1/admin/billing/photo-limits` `{free_daily, free_monthly, daily_total}` | 5 a day / 50 a month |
| All farmers together per day (`daily_total`) | same call | no overall cap |

`GET /v1/admin/billing/settings` shows them (`roles[].photo_ai_daily / photo_ai_monthly`,
`photo_limits`). Every change is written to `billing_events` (admin id, old / new).
Days and months are India calendar days and months (Asia/Kolkata midnight). A farmer with
several role plans gets the most generous one. Over a limit: 429 `analysis_limit` with
`error.details = {limit: daily | monthly | total, max, resets_at}` and a `Retry-After` header.

## 3. Cost (Claude Opus 5.5: $4 per million input tokens, $20 per million output tokens)

Estimate from the request shape, not a measured bill:

| Part | Tokens | Cost |
|---|---|---|
| Photo | about 1,500 | $0.006 |
| Card texts and rules (about 7,500 characters) + schema + question | about 2,100 | $0.008 |
| Answer: JSON in three languages + adaptive thinking | about 1,000 to 3,000 | $0.02 to $0.06 |
| **One photo** | | **about $0.035 to $0.075** |
| One farmer at the default monthly limit (50) | | about $1.75 to $3.75 a month |

Check the real numbers in the Anthropic console (usage by model) after the first week and lower
the limits on the Subscription page if needed. Prompt caching of the card texts is not used
yet (the cached prefix would be about 2,000 tokens).

## 4. Training samples

- Table `photo_analysis_samples` (owner data, RLS; migration 0043): id, owner, plot, part,
  scouting item, model, candidates, unsure, created time, photo key, `label`, `label_source`.
- The farmer deletes one with `DELETE /v1/photo-analysis/{photo_id}` (the app's "हा फोटो हटवा" /
  "Delete this photo" button on the result screen, stage 3); account deletion (`DELETE /v1/me`) erases all of them and
  the photos.
- Role `kb_admin`: `GET /v1/admin/photo-analysis/samples` (labelled ones: signed photo link for
  one hour + label; `?labelled=false` for the ones still to label) and
  `PUT /v1/admin/photo-analysis/samples/{photo_id}/label` `{label, source}` with a card key,
  `healthy` or `other`.
- The labelled photos are what the on-device model (stages 1 and 3) is trained on next:
  `ml/train_citrus.py --extra DIR` (`docs/runbooks/photo-model.md`).

## 5. The card texts

`api/src/bagmitra_api/photo_ai/seed_data/disease_profiles.json` is a copy of every disease /
pest / disorder profile in `app/assets/config/practice_cards.json` that has a symptoms text (12
today). The test `test_seed_matches_the_app_cards` fails when the cards change: copy the
changed profile over (same keys and texts).

## 6. The app (stage 3)

- Where: the plot's scouting log → "फोटोवरून ओळखा"; the pest / disease photo form ("कीड-रोग फोटो") →
  after a photo is picked, "फोटोवरून ओळखा" checks that photo (sends the chosen `scouting_item`).
  Route `/plots/<id>/photo-check`; code `app/lib/features/photo_analysis/`.
- Consent: none asked in the app (signup privacy policy). The camera is the phone's camera app through
  `image_picker`, so the app declares no CAMERA permission.
- Upload: the generated client's multipart method sends one JSON part named `body`, which the server
  cannot read, so `HttpPhotoAnalysisApi` builds the request (field `photo`, plus `part`,
  `scouting_item`) on the app's authenticated client, with its own 150 s answer wait (other calls: 20 s).
  The photo is re-encoded on the phone to JPEG, at most 1600 px, under 2 MiB.
- No queue: a server failure shows a calm line, and the photo stays for a one-tap retry. Offline,
  the phone's leaf model gives a first estimate (`docs/runbooks/photo-model.md` §3); the retry
  still runs the full check once online.
- Delete: "हा फोटो हटवा" on the result calls `DELETE /v1/photo-analysis/{photo_id}`; results are not
  stored with scouting entries (OPEN_QUESTIONS Q135, open point a).

## 7. Bill reading (OPEN_QUESTIONS Q136)

Owner 2026-11-11: the farmer photographs the agri-input shop bill on the spray record or on Add
expense, and the products and costs are read from it. Server side only here; the app is its own PR.

- Endpoint: `POST /v1/bills/read` (signed-in farmer; multipart, field `photo`: one JPEG / PNG, at
  most `PHOTO_MAX_BYTES`). Answer: `shop_name`, `bill_date` (`YYYY-MM-DD`), `bill_no`, `items[]`
  (`name`, `active_ingredient`, `quantity`, `unit`, `amount_rs`), `total_rs`, `unsure`; null where
  the bill could not be read. Code: `api/src/bagmitra_api/routers/bills.py`, `bills/`.
- Switch it on: nothing extra. The same key (`PHOTO_AI_API_KEY`, else `FEED_AI_API_KEY`), model
  (`PHOTO_AI_MODEL`), `PHOTO_AI_MAX_TOKENS` and `PHOTO_AI_TIMEOUT_SECONDS` as photo analysis, and
  the same Messages API call (fallback beta, structured output, no `thinking` field). No key: 503
  `analysis_unavailable`.
- The prompt: read only what is printed or written; never guess; null when a field cannot be read;
  product names as printed; the active ingredient only when printed; rupees as numbers; ISO dates;
  Marathi, Hindi or English bills; `unsure` when the photo is unclear or not a bill.
- Server checks on the answer: items without a name dropped, at most 30 items, numbers finite and
  not negative (else null), strings trimmed (shop 120, bill no 40, product 120, active ingredient
  160, unit 16 characters), a `bill_date` more than one day after today (India) set to null.
- Privacy: EXIF / PNG text chunks removed first. The photo and the result are **not stored** on
  the server (no training store, no storage upload). Only `bill_reads` (id, owner, time; RLS
  owner, migration 0044) for the limits, erased with the account. The log line has only `unsure`
  and the number of items.
- Errors (same problem envelope as photo analysis): 413 `photo_too_large`, 415
  `photo_not_supported`, 429 `bill_read_limit` (`error.details {limit: daily | monthly | total,
  max, resets_at}` + `Retry-After`), 502 `analysis_failed` (a refusal, a cut-off answer or invalid
  JSON; nothing counted), 503 `analysis_unavailable`.

### Limits (admin web → Subscription / सदस्यता, card "Bill reading limits"; role `billing_admin`)

Separate from the photo analysis limits, with the same rules (India calendar days and months; a
plan with no value and a farmer without a plan fall back to 5 a day / 50 a month; several plans:
the most generous; empty overall cap = no cap; every change written to `billing_events` as
`bill_limits_changed` / `role_bill_limits_changed`).

| Where | API | Empty means |
|---|---|---|
| Per role plan: bills per day / per month | `PUT /v1/admin/billing/roles/{role}/bill-limits` `{daily, monthly}` | 5 a day / 50 a month |
| Without a plan (also while the subscription switch is off or not started) | `PUT /v1/admin/billing/bill-limits` `{free_daily, free_monthly, daily_total}` | 5 a day / 50 a month |
| All farmers together per day (`daily_total`) | same call | no overall cap |

`GET /v1/admin/billing/settings` shows them as `roles[].bill_read_daily / bill_read_monthly` and
`bill_limits`. Columns: `billing_role_prices.bill_read_daily / bill_read_monthly`,
`billing_settings.bill_read_free_daily / bill_read_free_monthly / bill_read_daily_total`.

Cost: one photo plus a shorter prompt than photo analysis (no card texts) and a short JSON answer;
check the real numbers in the Anthropic console (usage by model) after the first week.
