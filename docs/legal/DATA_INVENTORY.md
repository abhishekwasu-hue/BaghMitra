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
| Bill photos (spray record, expense; Q136) | on the phone (`bill_photos/`); same optional backup and network rule as scouting photos, object `<owner_id>/bill-<record_id>.jpg`, key `bill_photo_key` synced; removed with the account | `api/src/bagmitra_api/routers/bill_photos.py`; `api/src/bagmitra_api/account/erase.py`; migration 0044 |
| Stored photo removal | a scouting backup photo has no single-photo delete path (it goes with the account); an analysed crop photo is deleted by `DELETE /v1/photo-analysis/{photo_id}`, by the nightly retention job, or with the account | `api/src/bagmitra_api/photos/storage.py:38-40,76,86` |
| **Crop photo analysis** (Q135; only when `PHOTO_AI_API_KEY` or `FEED_AI_API_KEY` is set) | the farmer sends one JPEG / PNG of their own plot (`POST /v1/plots/{plot_id}/photo-analysis`, optional plant part and scouting item). The API strips EXIF / XMP / comments (JPEG) and text / EXIF / time chunks (PNG) first, then sends the photo, the part and the practice-card texts to Anthropic; no name, phone, plot or GPS. Consent: the one given at signup (privacy policy); no prompt per photo (owner decision). Kept as a **training sample**: `photo_analysis_samples` (owner, plot id, part, scouting item, model, candidates, unsure, time, photo key, label, label source; RLS owner) and the photo at `<owner_id>/analysis-<id>.jpg|png` (config: photo storage). Read by role `kb_admin` (export of labelled samples with a 1-hour signed link, no owner id). Deleted: by the farmer (`DELETE /v1/photo-analysis/{photo_id}`), with the account, and after `PHOTO_AI_RETENTION_DAYS` (default 730, nightly job, `CRON_PHOTO_AI_RETENTION`). Per-farmer limits are admin settings (billing settings / role plans) | `api/src/bagmitra_api/routers/photo_analysis.py`; `api/src/bagmitra_api/photo_ai/`; `api/src/bagmitra_api/photos/exif.py`; migration 0043; `deploy/deploy.sh` |
| Claim kit (photos, notes, GPS stamp) | phone only, not synced | `app/lib/features/insurance/data/claim_kit_repository.dart:11-12`; OPEN_QUESTIONS Q37 |
| Lab report photo / file | phone only, path never synced | `app/lib/features/lab_tests/data/lab_report_files.dart:3-5`; `api/src/bagmitra_api/db/models/lab_test.py:1-4` |

## 3A. Market linkage data model (migrations 0029–0035; off in production: `MARKET_LINK_ENABLED` / app `MARKET_LINK`)

Server flag `MARKET_LINK_ENABLED` (`market_link_enabled`, default off: every market-link path answers 404); app build
flag `MARKET_LINK` (dart-define, default off).

Purpose of every row below: introducing a grower to a verified trader / exporter / broker / service provider (spec
v1.5, introduction only), and the checks that keep fake profiles and fake ratings out. Who can see it: the RLS
policies of migrations 0029–0035 plus the API responses named in the row. Retention: kept while the account exists
(the code has no time-based deletion of market-link rows); after `DELETE /v1/me`, see the "Account deletion" and "Kept
after deletion" rows.

| Item | Behaviour | Reference |
|---|---|---|
| Introduction only | no deal terms, payments, weigh slips, service bookings or disputes are stored (dropped in 0030); `market_deals` holds accepted / "deal done" times only | `api/alembic/versions/0030_market_link_introduction_only.py`; `api/tests/test_market_link_schema.py` |
| Grower lots (L3) | `market_lots`: plot id, bahar cycle id, crop / variety (copied from the plot), tonnes, quality text, harvest window, basis, the grower's own asking rate (paise, optional), village / taluka / district (copied from the grower's profile at publish), status, publish time, orchard check (inside / near / outside / unmapped, from the photo points against the mapped plot). Drafted offline and synced (owner = grower). Visible: the grower (all); admin-verified traders / brokers through the API with the §4E fields only (row "What traders see of a lot"; the asking rate is not in that list, Q103); the parties of an introduction on that lot (RLS `party_read`) | `api/src/bagmitra_api/market_link/models.py` (`MarketLot`); `api/src/bagmitra_api/routers/market_lots.py`; migrations 0029, 0032, 0035 |
| Lot photos (L3) | `market_lot_photos`: in-app camera photo (3 to 8 per lot), capture time and **GPS point** (no accuracy), stored object key. Uploaded through the API, which strips EXIF; stored in the photo bucket under `<owner_id>/<photo_id>.jpg`, opened by signed URL. The points are used for the orchard check and are never in a trader's response (`BuyerLotOut`); traders see the photos only | `MarketLotPhoto`; `api/src/bagmitra_api/routers/market_lots.py` |
| Trader / exporter / broker / provider profiles (L2) | name, firm, **contact phone (shown publicly** to signed-in users once the admin has verified the profile; the registrant is told before submitting), village / markets, taluka, district, crops / service areas; provider kind fields (weighbridge certificate valid-until, transporter vehicles / capacity / refrigerated / carrier registration); optional address with who / when; **no Aadhaar, commission, income or rates** | `api/src/bagmitra_api/market_link/models.py`; `api/src/bagmitra_api/routers/market_link_registration.py` |
| Registration numbers (L2) | GSTIN, APMC licence, FSSAI, IEC (required for an exporter), APEDA; stored for the admin's **manual** check on the official public page (no automation, no paid KYC); never in a public response; indexed, not unique (Q80) | `BuyerProfile`; migration 0031; `api/tests/test_market_link_profiles.py` |
| Document photos (L2) | registration-number documents (trader / exporter) and the weighbridge certificate, taken in the app camera; the API **strips EXIF / metadata before storing** in the private bucket (`market-link/<type>/<id>/...`); admin opens them by short-lived signed URL | `api/src/bagmitra_api/market_link/photos.py`; `api/tests/test_market_link_registration.py` |
| Verification records (L2) | `party_verifications`: subject (buyer / broker / provider) and id, private-bucket document keys, status, reject reason text, the admin who checked and when; the latest row decides whether a profile is verified. RLS: the profile's owner reads the records on it; admin through the admin API; document keys never in a public response | `PartyVerification`; migration 0029; `api/src/bagmitra_api/routers/admin_market_link.py` |
| Public profile aggregates (L2) | completed-deal count, stars per question, tag counts: computed from `market_deals` / `ratings`, nothing stored; badges only from verification records, fixes and representative uploads, with the date | `api/src/bagmitra_api/market_link/profiles.py` |
| **Registration GPS fix (precise location)** | collected **once**, in the foreground after a permission screen, when a trader / exporter / broker / provider registers; **required; purpose: fraud prevention**. Stored in `registration_fixes`: lat, lon, accuracy, time, the phone geocoder's place / district / state / PIN, mock-location flag. Exact coordinates: admin (and the registrant's own view) only; public profiles show place + date only; the directory shows a rounded km from the grower's own plot. No background or repeated tracking | `api/src/bagmitra_api/market_link/registration.py`; `app/lib/features/market_link/`; `api/tests/test_market_link_profiles.py` |
| Per-check records (L7) | each admin check by hand (GSTIN / APMC / FSSAI / IEC / APEDA / phone call / place photo): the number checked, result (passed / failed / cancelled), the official page opened, admin id and time, re-check listing time; badges say what was checked and the date, never "guaranteed"; no turnover; the profile's owner may read the checks on it, nobody else (RLS) | `verification_checks`, migration 0034; `api/src/bagmitra_api/market_link/checks.py`; `api/tests/test_market_link_checks.py` |
| Device sightings (L7) | SHA-256 of the push token per account (never the token), written when a phone registers for push while the market link is on; purpose: fraud prevention (two accounts on one phone cannot rate each other, spec §4C, Q100) | `device_sightings`, migration 0034; `api/src/bagmitra_api/market_link/trust.py` |
| Representative uploads | place photo (capture time + GPS) and / or address, with who and when | `RepresentativeUpload` |
| Interests and introductions (L4) | an interest holds basis, rate (paise), optional tonnes, proposed harvest date, the trader and the named broker (`market_offers`); no other term, no commission. On the grower's acceptance: `market_deals` (accepted time), `deal_parties`, an "accepted" `deal_events` row. **The grower's name, profile phone, village / taluka / district, plot name and plot pin are shown only to that deal's trader and broker** (API `GET /v1/market-link/deals/{id}`); `farmers` / `plots` stay owner-only under RLS. Pushes carry no rate, name or phone | `api/src/bagmitra_api/routers/market_interests.py`; `api/src/bagmitra_api/market_link/notify.py`; `api/tests/test_market_interests.py`, `test_market_interests_rls.py` |
| "Deal done" and ratings (L5) | `market_deals.grower_done_at` / `trader_done_at` / `completed_at` (the two taps; the broker does not tap) and `deal_events` ("done", "completed", "rated", "rating_changed"; append-only, no stars or terms in the detail). `ratings`: rater, ratee and role, question key, 1-5 stars, ticked tag ids; no text. Read by the rater and the ratee only (RLS); the public sees aggregates. Nothing about payment, weighing or disputes. The grower's copy into Accounts is their own sale record (synced like any sale), not market-link data. |
| Reports, admin actions, blocks, terms acceptances | predefined reason codes only (no text); acceptances are versioned and time-stamped with the 18+ declaration | `FraudReport`, `AdminAction`, `UserBlock`, `TermsAcceptance` |
| Report and appeal photos (L6) | optional, at most `MARKET_LINK_REPORT_MAX_PHOTOS` (default 3) each; uploaded through the API, which strips EXIF (GPS, phone, time) before storing in the private bucket under the user's folder; shown to admin only by a short-lived link | `api/src/bagmitra_api/market_link/safety.py` (`store_photo`); `api/src/bagmitra_api/market_link/photos.py` |
| Admin action log (L6) | every verify / warn / hide / suspend / restore with reason code, actor and time; Postgres refuses edits of the action and any delete (only the one appeal moves: reason code, photos, acknowledged / decided times); kept after an account deletion (user id only) | `api/alembic/versions/0033_market_link_safety.py`; `api/src/bagmitra_api/routers/admin_market_link_safety.py` |
| **Account deletion, market link (Q68)** | at `DELETE /v1/me` the user's market-link data is hidden at once (`deferred_erasures`, published lots withdrawn); after `MARKET_LINK_ERASE_AFTER_DAYS` (default 180) a nightly job erases profiles, verification records and documents, registration fixes, representative uploads, terms acceptances, blocks, reports, lot photos and lots without an introduction; a lot with an introduction stays without its photos and text; ratings given stay, shown without name | `api/src/bagmitra_api/market_link/erasure.py`; `api/src/bagmitra_api/market_link/erase_job.py`; `deploy/deploy.sh` (`CRON_MARKET_LINK_ERASE`) |
| Deletion tracker | `deferred_erasures` (private, admin / jobs only): user id, requested time, erase-after time, erased time. The row stays after the erasure so the id remains hidden wherever a kept rating or introduction names it | `api/src/bagmitra_api/account/models.py` (`DeferredErasure`); migration 0033 |
| **Kept after deletion** (what the code does not erase) | neither `DELETE /v1/me` nor the erase job deletes: `admin_actions` (user id only), `ratings` given and received (shown without name), other people's interests / introductions and their `deal_events`, `deal_parties`, the `deferred_erasures` row, `device_sightings` (token hash + user id; no delete path in the code) and `package_grants` (payment record; no delete path in the code). An introduced lot, and a lot a package grant names, stays with quality, village and variety cleared and its photos deleted | `api/src/bagmitra_api/market_link/erasure.py` (`USER_KEYED`, `_erase_lots`); `api/src/bagmitra_api/account/erase.py` (`owner_tables`) |
| What traders see of a lot (spec v1.5 §4E) | grower's **first name only**, crop / variety, orchard acres, tonnes, quality, photos (EXIF stripped), harvest window, **district**; never surname, phone, village, plot or GPS before the grower accepts that trader's interest | `api/src/bagmitra_api/routers/market_lots.py` (`BuyerLotOut`); `api/tests/test_package.py` |
| **Season sale package grants** (migration 0035; switch OFF by default) | per payment the grower made OUTSIDE the app (UPI / cash / bank to the company): grower id, lot (or all lots), amount (paise), method, payment reference (UTR, unique), paid date, validity, receipt number, revoke time and reason, the admin who recorded it. Entered by an admin in the admin web only; the app collects nothing and reads only "active until <date>" / "not active" for its own grower. RLS: grower reads own rows, admin full, traders none. Every grant / revoke is logged in `admin_actions` (old / new, who, when; not shown to the grower) | `api/src/bagmitra_api/market_link/package_models.py`; `api/src/bagmitra_api/routers/admin_package.py`; `api/alembic/versions/0035_season_package.py` |
| Company profile (season package) | the company's legal / trade name, address, GSTIN, PAN, bank account name, IFSC and **last 4 digits only**, UPI ID, merchant QR image, receipt prefix, GST rate; one row, starts empty, admin-only (private RLS), used for receipts and the representatives' printed QR card | `CompanyProfile`, `SeasonPackageSettings` |

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
| Anthropic (only if `FEED_AI_API_KEY`; photos also with `PHOTO_AI_API_KEY`) | extracted text of government documents for classify / summarise (no grower data); and a farmer's crop photo sent for analysis, metadata stripped, with the plant part and the card texts (no name, phone, plot or GPS; §3 "Crop photo analysis") | `api/src/bagmitra_api/feed/ai.py`; `api/src/bagmitra_api/feed/service.py`; `api/src/bagmitra_api/photo_ai/analyse.py`; `api/src/bagmitra_api/core/settings.py` |
| Google Firebase Cloud Messaging (processor; only when `FCM_PROJECT_ID` + a service-account key are set on the server and the APK is built with `PUSH=true` and `google-services.json`; off by default) | the phone's FCM registration token and, per push, the title, body and data (`plot_id`, `rule_key`, `first_day`, `action`; feed items: item id / stage): risk label or scheme reminder text, no name, phone, GPS or record contents. The app sends its token to our API only (`POST /v1/me/devices`); Google issues the token on the phone. The service-account key stays in the VPS `.env`, never in git or logs | `api/src/bagmitra_api/push/fcm.py`; `api/src/bagmitra_api/push/deliver.py`; `api/src/bagmitra_api/feed/alerts.py`; `app/lib/features/push/`; `docs/runbooks/push-notifications.md` |
| Sentry (only if `SENTRY_DSN` is set; off by default) | error reports without user ids, IPs, cookies, bodies, local variables, auth headers or query strings | `api/src/bagmitra_api/core/observability.py` |
| Govt sites (GR portal, PIB) | API fetches public pages; no user data | `api/src/bagmitra_api/feed/news_job.py:57`; `api/src/bagmitra_api/kb/fetch_sources.py:15` |
| Payments | no card, bank or UPI data: Google Play takes the payment. For a Play subscription (`subscriptions`, provider `google_play`, migrations 0037/0038) the server stores per user: the Play product id, state, period start / end, auto-renew, grace end, last check time, the **SHA-256 of the purchase token** (never the token) and Play's pending price change (`price_change`: new price, state, effective time); the ledger `billing_events` holds the Play state and product per event (no token). Manual grants (`provider` manual / web_invoice) keep reason and granting admin. **Kept after account deletion** (billing ledger, see "Account / data deletion") | `api/src/bagmitra_api/billing/models.py:55-95`; `api/src/bagmitra_api/billing/purchases.py:155-187`; `api/src/bagmitra_api/billing/rtdn.py`; `api/src/bagmitra_api/account/erase.py` |
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
| In-app feedback (`app_feedback`, migration 0039) | sent only when the user taps Send: kind (problem / suggestion / question), the typed or spoken text, app version and phone model; an optional screenshot (JPEG, metadata stripped) in the user's own photo folder `<owner_id>/feedback-<id>.jpg`. Read by role `feedback_admin`; erased with the account (rows and folder) | `api/src/bagmitra_api/routers/feedback.py`; `api/src/bagmitra_api/feedback/models.py` |
| Account / data deletion | `DELETE /v1/me` erases every owner-scoped table (incl. `sync_mutations`, `push_devices`, `feed_receipts`, `feed_preferences`, `photo_analysis_samples`), the farmer's entitlement snapshot and the photo folder; the Supabase Auth user too when `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` are set, else a follow-up row in `account_deletions`. The billing ledger (`subscriptions`, `billing_events`) is kept. In the app: Profile → delete, typed confirmation, then local wipe and sign-out | `api/src/bagmitra_api/account/erase.py`; `api/src/bagmitra_api/routers/me.py`; `app/lib/features/profile/` |
| Data export endpoint | none on the server; the phone shares CSV / PDF; `GET /v1/me` returns the profile | `api/src/bagmitra_api/routers/me.py:28-37` |

## 8. Points the owner should know

1. Record deletes inside the app stay soft (sync tombstones); account deletion (`DELETE /v1/me`) erases for real. Without
   the service role key the Supabase Auth user is removed by hand from the `account_deletions` follow-up rows.
2. Client IPs are no longer logged, and container logs are capped (OPS-01).
3. Voice typing is not forced on-device; the policy says the phone's speech service may process audio online.
4. Android backup is off (S-09): a new phone starts empty and signed out; records come back through sync.
5. Market link (§3A): `device_sightings` and `package_grants` have no delete path in the code, so they stay after an
   account deletion; the privacy page and the retention answer must say so, or the erase job must cover them (owner).
   Read from the code, not run: `package_grants.lot_id` references `market_lots.id` without `ON DELETE`, and the erase
   job deletes a lot without an introduction without touching its grants, so such a lot with a grant cannot be erased
   as written (`market_link/erasure.py` `_erase_lots`; `erase_due` catches only `PhotoStorageError`; migration 0035).
