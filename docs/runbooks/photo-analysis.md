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
- The farmer deletes one with `DELETE /v1/photo-analysis/{photo_id}` (the app calls it when the
  scouting entry is deleted, stage 3); account deletion (`DELETE /v1/me`) erases all of them and
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
- No queue: offline or a server failure shows a calm line, and the photo stays for a one-tap retry.
- Delete: "हा फोटो हटवा" on the result calls `DELETE /v1/photo-analysis/{photo_id}`; results are not
  stored with scouting entries (OPEN_QUESTIONS Q135, open point a).
