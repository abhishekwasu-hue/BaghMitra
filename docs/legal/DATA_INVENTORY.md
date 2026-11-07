# Data inventory (basis of the privacy policy at `GET /privacy`)

Every row is what the code does today; references are `file:line` from the repository root.
"Config" means it depends on the operator's live settings, which this document cannot see.
Policy text: `api/src/bagmitra_api/public_pages/privacy.py`. Keep both in step.

## 1. Account and profile

| Data | Where / how | Reference |
|---|---|---|
| Phone number + SMS OTP | Supabase Auth sends the OTP through the SMS provider chosen in Supabase (Twilio, MessageBird, Textlocal or Vonage) | `app/lib/features/auth/infra/supabase_auth_repository.dart:30,41`; `docs/runbooks/supabase-setup.md:35-38` |
| Google sign-in | Supabase OAuth in the external browser, no extra scopes requested (Supabase defaults); Google shares its consent-screen details with Supabase Auth | `app/lib/features/auth/infra/supabase_auth_repository.dart:60-64`; `docs/runbooks/supabase-setup.md:39-49` |
| What the API reads from the token | user id (`sub`), phone, `app_metadata` roles; no email | `api/src/bagmitra_api/auth/jwt.py:29-34,107-118` |
| Profile (`farmers`) | phone, display name, language, village, taluka, district, `consent_data_processing`, `consent_whatsapp` | `api/src/bagmitra_api/db/models/farmer.py:17-25`; `api/src/bagmitra_api/sync/payloads.py:25-34` |
| Phone on profile | a phone sign-in's own number always wins; a Google account may add one | `api/src/bagmitra_api/sync/registry.py:166-169` |
| Data-processing consent | required to finish onboarding; shown read-only in Profile ("cannot be turned off here") | `app/lib/app/providers.dart:175-180`; `app/lib/features/profile/presentation/profile_screen.dart:218-228`; `app/lib/l10n/app_en.arb:525,529` |
| WhatsApp consent | stored only; no WhatsApp sending code exists in the API | `app/lib/features/profile/presentation/profile_screen.dart:230-240`; grep `whatsapp` in `api/src` finds only the consent field |
| Profile use | district + plot crop / area pick the govt notices for the grower | `api/src/bagmitra_api/routers/feed.py:5,126-128` |

## 2. Orchard records (synced to the server, owner-only)

| Entity | Personal / sensitive fields | Reference |
|---|---|---|
| Plot | name, crop, area, spacing, irrigation, water, soil, **GPS centroid and GeoJSON boundary** | `api/src/bagmitra_api/db/models/plot.py:11-31` |
| Spray, input, irrigation, harvest | products, doses, quantities, costs | `api/src/bagmitra_api/db/models/accounts.py:45-106` |
| Labour | **worker name**, wage, advance, settled date | `api/src/bagmitra_api/db/models/accounts.py:109-123` |
| Expense / sale (income) | amounts; sale **buyer name**, rate, payment status | `api/src/bagmitra_api/db/models/accounts.py:17-42` |
| Scouting | item, severity, note, `photo_key` | `api/src/bagmitra_api/db/models/scouting.py:18-30` |
| Insurance policy | insurer, **policy number**, sum insured, premium | `api/src/bagmitra_api/db/models/insurance.py:17-31` |
| Lab test | lab name, typed values | `api/src/bagmitra_api/db/models/lab_test.py:17-28` |
| Bahar cycle, farm task | dates, titles, notes | `api/src/bagmitra_api/db/models/bahar.py:32-43`; `api/src/bagmitra_api/db/models/tasks.py:15-27` |
| **Deletes are soft** | a delete sets `deleted_at`; the row stays on the server | `api/src/bagmitra_api/sync/registry.py:248-252`; `api/src/bagmitra_api/db/base.py:49-56` |
| **Sync audit log** | applied and stale writes keep their payload in `sync_mutations`; rejected ones keep only `{sha256, bytes}`. A payload over 64 KiB is rejected, a batch over 2 MiB of payloads is refused (413). Retention (LD-09): a nightly job replaces the payload of every write older than `SYNC_PAYLOAD_RETENTION_DAYS` (default 90) with its `{sha256, bytes}` digest and sets `payload_purged_at`; the row (ids, entity, op, times, status) stays for the duplicate check and the pull cursor | `api/src/bagmitra_api/sync/service.py` (`payload_digest`, `payload_size`); `api/src/bagmitra_api/sync/retention.py`; `api/src/bagmitra_api/core/settings.py` (`sync_max_payload_bytes`, `sync_payload_retention_days`); `deploy/deploy.sh` (cron, `CRON_SYNC_RETENTION`) |
| Ownership | API checks owner in code; Postgres RLS as second wall | `api/src/bagmitra_api/db/rls.py:1-4` |

## 3. Photos and files

| Item | Behaviour | Reference |
|---|---|---|
| Scouting photos | on the phone; backup only when `PHOTO_STORAGE_URL` + `PHOTO_STORAGE_SERVICE_KEY` are set (config), else 503 | `api/src/bagmitra_api/core/settings.py:153-166`; `api/src/bagmitra_api/routers/scouting_photos.py:1-6` |
| Backup path | private bucket, object `<owner_id>/<record_id>.jpg`, signed upload URL; download URL expires (default 300 s) | `api/src/bagmitra_api/routers/scouting_photos.py:39-40`; `api/src/bagmitra_api/core/settings.py:157` |
| Upload network | Wi-Fi, or any network if the grower turns on "Back up photos on mobile data" (default off) | `app/lib/features/scouting/data/photo_backup.dart:26-31` |
| Stored photo removal | the storage client has only sign-upload / sign-download; no API path deletes a stored photo | `api/src/bagmitra_api/photos/storage.py:38-40,76,86` |
| Claim kit (photos, notes, GPS stamp) | phone only, not synced | `app/lib/features/insurance/data/claim_kit_repository.dart:11-12`; OPEN_QUESTIONS Q37 |
| Lab report photo / file | phone only, path never synced | `app/lib/features/lab_tests/data/lab_report_files.dart:3-5`; `api/src/bagmitra_api/db/models/lab_test.py:1-4` |

## 3A. Market linkage data model (migrations 0029–0033; off in production: `market_link_enabled`)

| Item | Behaviour | Reference |
|---|---|---|
| Introduction only | no deal terms, payments, weigh slips, service bookings or disputes are stored (dropped in 0030); `market_deals` holds accepted / "deal done" times only | `api/alembic/versions/0030_market_link_introduction_only.py`; `api/tests/test_market_link_schema.py` |
| Trader / exporter / broker / provider profiles | name, phone, place, crops / areas; GSTIN, APMC licence, IEC (exporter); optional address with who / when; **no Aadhaar, commission or income** | `api/src/bagmitra_api/market_link/models.py` |
| **Registration GPS fix (precise location)** | table ready (`registration_fixes`): one fix per registration, exact coordinates admin-only, own row readable by the registrant; collected from L2 | `api/src/bagmitra_api/market_link/models.py` (`RegistrationFix`) |
| Representative uploads | place photo (capture time + GPS) and / or address, with who and when | `RepresentativeUpload` |
| Reports, admin actions, blocks, terms acceptances | predefined reason codes only (no text); acceptances are versioned and time-stamped with the 18+ declaration | `FraudReport`, `AdminAction`, `UserBlock`, `TermsAcceptance` |
| Report and appeal photos (L6) | optional, at most `MARKET_LINK_REPORT_MAX_PHOTOS` (default 3) each; uploaded through the API, which strips EXIF (GPS, phone, time) before storing in the private bucket under the user's folder; shown to admin only by a short-lived link | `api/src/bagmitra_api/market_link/safety.py` (`store_photo`); `api/src/bagmitra_api/market_link/photos.py` |
| Admin action log (L6) | every verify / warn / hide / suspend / restore with reason code, actor and time; Postgres refuses edits of the action and any delete (only the one appeal moves: reason code, photos, acknowledged / decided times); kept after an account deletion (user id only) | `api/alembic/versions/0033_market_link_safety.py`; `api/src/bagmitra_api/routers/admin_market_link_safety.py` |
| **Account deletion, market link (Q68)** | at `DELETE /v1/me` the user's market-link data is hidden at once (`deferred_erasures`, published lots withdrawn); after `MARKET_LINK_ERASE_AFTER_DAYS` (default 180) a nightly job erases profiles, verification records and documents, registration fixes, representative uploads, terms acceptances, blocks, reports, lot photos and lots without an introduction; a lot with an introduction stays without its photos and text; ratings given stay, shown without name | `api/src/bagmitra_api/market_link/erasure.py`; `api/src/bagmitra_api/market_link/erase_job.py`; `deploy/deploy.sh` (`CRON_MARKET_LINK_ERASE`) |

## 4. Device features

| Item | Behaviour | Reference |
|---|---|---|
| Location | one reading when the grower asks (plot point / boundary, claim photo stamp); no background tracking | `app/lib/features/plots/data/location_service.dart:20-21`; `app/lib/features/plots/presentation/boundary_screen.dart:32`; `app/lib/features/insurance/presentation/claim_kit_screen.dart:114` |
| Voice (STT) | Android recogniser via `speech_to_text`; `SpeechListenOptions` sets only `localeId` (no on-device flag), so the phone's recognition service (Google on most phones) may process audio online. Audio never reaches our API. Cloud engine is a stub | `app/lib/features/voice/data/on_device_speech.dart:8-10,29-31`; `app/lib/features/voice/data/cloud_speech.dart:3-15` |
| Text-to-speech | `flutter_tts` on the phone | `app/lib/features/voice/data/on_device_speech.dart:47-50` |
| Reminders | local notifications scheduled on the phone | `app/lib/features/reminders/data/local_notifications.dart:7-9` |
| Permissions | INTERNET, fine / coarse location, RECORD_AUDIO, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED (plus VIBRATE from the notifications plugin); no camera, storage or exact-alarm permission | `app/android/app/src/main/AndroidManifest.xml` (`uses-permission`); `app/test/android/release_config_test.dart` |
| Android backup | off: `android:allowBackup="false"`, and backup / device-transfer rules exclude every domain, so no app data goes to Google backup | `app/android/app/src/main/AndroidManifest.xml`; `app/android/app/src/main/res/xml/` |
| On-phone log | newest 256 KB, leaves the phone only through "Send logs" (share sheet) | `app/lib/core/app_log.dart:3,20`; `app/lib/features/settings/presentation/settings_screen.dart:49-58` |
| Exports | accounts CSV and PDF reports through the share sheet | `app/lib/features/export/data/file_sharer.dart:5-6`; `app/lib/features/export/domain/accounts_csv.dart` |

## 5. Server-side services and third parties

| Party | What it receives | Reference |
|---|---|---|
| Supabase | auth (phone / Google identity), PostgreSQL data, photo storage (config); region ap-south-1 (Mumbai) per setup guide (live project not visible here) | `docs/runbooks/supabase-setup.md:33`; `deploy/.env.example` (`DATABASE_URL`) |
| Local database option | `--profile localdb` keeps the data on the VPS instead (config) | `deploy/docker-compose.yml:36-39`; `docs/runbooks/vps-deploy.md:116-118` |
| VPS (Hostinger, Ubuntu) | runs the API container and Caddy (TLS) | `docs/runbooks/vps-deploy.md:1,9`; `deploy/Caddyfile:2-5` |
| Open-Meteo | plot centroid **rounded to 2 decimals (~1 km)**; no user id | `api/src/bagmitra_api/routers/weather.py:81`; `api/src/bagmitra_api/weather/service.py:60-61,99-103`; `api/src/bagmitra_api/weather/open_meteo.py:76-87`; `api/src/bagmitra_api/core/settings.py:45` |
| data.gov.in (Agmarknet) | commodity / market / state filters only; the route ignores the user (`_user`) | `api/src/bagmitra_api/routers/market.py:44-50`; `api/src/bagmitra_api/market/agmarknet.py:119-121` |
| Anthropic (only if `FEED_AI_API_KEY`) | extracted text of government documents for classify / summarise; no grower data | `api/src/bagmitra_api/feed/ai.py:1-6,172`; `api/src/bagmitra_api/feed/service.py:528,545`; `api/src/bagmitra_api/core/settings.py:110-111` |
| Google Firebase Cloud Messaging (processor; only when `FCM_PROJECT_ID` + a service-account key are set on the server and the APK is built with `PUSH=true` and `google-services.json`; off by default) | the phone's FCM registration token and, per push, the title, body and data (`plot_id`, `rule_key`, `first_day`, `action`; feed items: item id / stage): risk label or scheme reminder text, no name, phone, GPS or record contents. The app sends its token to our API only (`POST /v1/me/devices`); Google issues the token on the phone. The service-account key stays in the VPS `.env`, never in git or logs | `api/src/bagmitra_api/push/fcm.py`; `api/src/bagmitra_api/push/deliver.py`; `api/src/bagmitra_api/feed/alerts.py`; `app/lib/features/push/`; `docs/runbooks/push-notifications.md` |
| Sentry (only if `SENTRY_DSN` is set; off by default) | error reports without user ids, IPs, cookies, bodies, local variables, auth headers or query strings | `api/src/bagmitra_api/core/observability.py` |
| Govt sites (GR portal, PIB) | API fetches public pages; no user data | `api/src/bagmitra_api/feed/news_job.py:57`; `api/src/bagmitra_api/kb/fetch_sources.py:15` |
| Payments | none collected; subscriptions are manual grants (`provider` google_play / web_invoice reserved); purchase tokens would be stored hashed | `api/src/bagmitra_api/billing/models.py:52-55`; `api/src/bagmitra_api/billing/service.py:171` |
| Ads / analytics SDKs | none in `app/pubspec.yaml` | `app/pubspec.yaml:9-33` |

## 6. "Check a message" and logs

| Item | Behaviour | Reference |
|---|---|---|
| Pasted text | compared in memory, not stored; only length and verdict logged; 20 checks / user / hour (in memory) | `api/src/bagmitra_api/routers/feed_check.py:4-5,91,124-125`; `api/src/bagmitra_api/core/settings.py:125` |
| API access log | method, path, status, duration, request id (JSON) | `api/src/bagmitra_api/core/middleware.py:33-39` |
| Uvicorn access log | off (`--no-access-log`): no client IP or query string is logged | `deploy/docker-compose.yml` (api command); `api/Dockerfile` |
| HTTP client logs | `httpx` / `httpcore` at WARNING: request URLs (with third-party API keys, photo paths) are never logged | `api/src/bagmitra_api/core/logging.py` (`QUIET_LOGGERS`) |
| Log retention | Docker `json-file` with `max-size 10m`, `max-file 5` per service; Caddy has no `log` directive (no Caddy access log) | `deploy/docker-compose.yml` (`x-logging`); `deploy/Caddyfile` |
| Database backup | nightly `pg_dump` of the `public` tables to `/var/backups/bagmitra` on the server, 14 days | `deploy/backup.sh`; `deploy/deploy.sh` (cron) |

## 7. Account switch, sign-out, deletion, export

| Item | Behaviour | Reference |
|---|---|---|
| Sign-out | only the session ends; records stay on the phone | `app/lib/features/profile/presentation/profile_screen.dart:104-128` |
| Another account on the same phone | blocked while unsent writes exist; otherwise every local table, the outbox, cursor and the previous account's photos are cleared | `app/lib/sync/account_guard.dart:104-125`; OPEN_QUESTIONS Q36 |
| Push token (`push_devices`) | stored per phone (token, platform, owner); registered after sign-in when push is on, moved to whichever account signs in on that phone, removed by `DELETE /v1/me/devices` just before sign-out, deleted when FCM reports it unregistered / invalid, and erased with the account | `app/lib/features/push/domain/push.dart` (`PushRegistrar`); `api/src/bagmitra_api/routers/devices.py`; `api/src/bagmitra_api/push/fcm.py` |
| Account / data deletion | `DELETE /v1/me` erases every owner-scoped table (incl. `sync_mutations`, `push_devices`, `feed_receipts`, `feed_preferences`), the farmer's entitlement snapshot and the photo folder; the Supabase Auth user too when `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` are set, else a follow-up row in `account_deletions`. The billing ledger (`subscriptions`, `billing_events`) is kept. In the app: Profile → delete, typed confirmation, then local wipe and sign-out | `api/src/bagmitra_api/account/erase.py`; `api/src/bagmitra_api/routers/me.py`; `app/lib/features/profile/` |
| Data export endpoint | none on the server; the phone shares CSV / PDF; `GET /v1/me` returns the profile | `api/src/bagmitra_api/routers/me.py:28-37` |

## 8. Points the owner should know

1. Record deletes inside the app stay soft (sync tombstones); account deletion (`DELETE /v1/me`) erases for real. Without
   the service role key the Supabase Auth user is removed by hand from the `account_deletions` follow-up rows.
2. Client IPs are no longer logged, and container logs are capped (OPS-01).
3. Voice typing is not forced on-device; the policy says the phone's speech service may process audio online.
4. Android backup is off (S-09): a new phone starts empty and signed out; records come back through sync.
