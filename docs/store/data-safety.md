# Google Play Data safety form: answers for BagMitra

Draft answers for Play Console → Policy → App content → Data safety. Derived only from
`docs/legal/DATA_INVENTORY.md` (what the code does; section numbers below as "DI §n") and the privacy page
`https://bagmitra.aialgodesk.org/privacy`. Nothing is submitted. When the code or the server settings change,
update DATA_INVENTORY first, then this file, then the form. A lawyer reviews the form together with the
privacy policy before launch (OPEN_QUESTIONS Q52).

Play's terms used here: **collected** = sent off the phone (to our API / Supabase); **shared** = given to a
third party, *except* a service provider that processes it for us, or a transfer the user starts himself
(for example the share sheet). Data processed only on the phone is not collected.

## 1. Overview questions

| Question | Answer | Basis |
|---|---|---|
| Does the app collect or share any of the required user data types? | **Yes** | DI §1–§2 |
| Is all of the user data collected by the app encrypted in transit? | **Yes** | App ↔ API over HTTPS (Caddy TLS, `deploy/Caddyfile`); app ↔ Supabase over HTTPS; the release manifest allows no cleartext traffic (no `usesCleartextTraffic`, no network security config, targetSdk 36). The Release APK's `API_BASE_URL` secret must be an `https://` address. |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In the app: Profile → "Delete my account and data" (`DELETE /v1/me`, DI §7). Without the app: by email (privacy page §7). |
| Delete account URL (Play → App content → Data deletion) | `https://bagmitra.aialgodesk.org/privacy#en-delete` | Privacy page §7 describes both ways. Needs `PRIVACY_CONTACT_EMAIL` set on the server, or the page shows no contact. |
| Account creation | Users can create an account: phone OTP *(only when `PHONE_LOGIN=true`)* and / or Google sign-in (OAuth) | DI §1 |
| Is data collected required, or can users choose? | Per type, see §2 | |

## 2. Data types

Purposes use Play's names: *App functionality*, *Account management*. No type is used for *Analytics*,
*Developer communications*, *Advertising or marketing*, *Fraud prevention, security, and compliance* or
*Personalization*, except where the row says so. **Shared: No** for every row (see §3).

| Play category → type | Collected | Required / optional | Purposes | Processed ephemerally | What it is (DI ref) |
|---|---|---|---|---|---|
| Location → **Precise location** | Yes | Optional (a plot can be saved without a location); *required for a market-link trader / exporter / broker / provider registration, only when `MARKET_LINK` is in the release* | App functionality; *Fraud prevention, security, and compliance* (market link only) | No | Plot GPS point and boundary, read once when the grower asks (DI §2, §4). Market link: one foreground fix at registration, collected once, exact point admin-only; the GPS point of each lot photo (in-app camera), used to check the lot is at the mapped plot and never sent to traders (DI §3A "Lot photos"). |
| Location → **Approximate location** | Yes | Optional | App functionality | No | Declared because the app asks `ACCESS_COARSE_LOCATION` with the precise one; the server derives a ~1 km rounded point for weather (DI §5). |
| Personal info → **Name** | Yes | Optional (onboarding name is optional) | App functionality, Account management | No | Profile display name; worker and buyer names the grower types in labour and sales (DI §1, §2). *Market link: a trader / exporter / broker / provider's name (and firm) is shown on the public profile once verified; traders see a grower's first name on a lot, and the profile name only after the grower accepts their interest (DI §3A).* |
| Personal info → **Email address** | Yes *(Google sign-in)* | Optional (only with Google sign-in) | Account management | No | Google shares it with Supabase Auth; our API does not read it (DI §1). |
| Personal info → **User IDs** | Yes | Required | Account management, App functionality | No | Supabase account id on every record (DI §1). |
| Personal info → **Phone number** | Yes | Required for phone sign-in; optional on a Google account | Account management, App functionality | No | Sign-in number and profile phone (DI §1). *Market link (only when `MARKET_LINK` is in the release): a trader / exporter / broker / provider's contact number is required and shown to other signed-in users once verified (DI §3A); answer the "data shared" section accordingly. A grower's profile phone and plot location are shown to the trader and broker of an offer the grower accepts (DI §3A, L4).* |
| Personal info → **Address** | Yes | Optional (onboarding place fields are optional) | App functionality | No | Village, taluka, district; district picks the government notices (DI §1). |
| Financial info → **Other financial info** | Yes | Optional | App functionality | No | Expenses, sales (rate, payment status), wages and advances, input costs, insurance policy number, sum insured, premium (DI §2). No card or bank data (DI §5 "Payments"; Play subscriptions: Purchase history below). *Market link: the grower's own asking rate on a lot and the rate in a trader's interest (crop sale terms between users, not a payment to us; DI §3A).* |
| Photos and videos → **Photos** | Yes *(only when photo backup is on on the server, `PHOTO_STORAGE_*`)* | Optional | App functionality | No | Scouting photos, and bill photos kept with a spray record or an expense (Q136), backed up to private Supabase Storage only when the farmer's photo backup runs (DI §3); erased with the account. Market link: document / certificate photos, EXIF stripped by the API, admin-only (DI §3A). Claim-kit and lab-report photos stay on the phone and are not collected. Market link (only when it is in the release): optional report / appeal photos, EXIF stripped on the server; 3 to 8 lot photos per published lot, EXIF stripped, shown to verified traders (DI §3A). If photo backup is off in production, answer **No** for this type. |
| Photos and videos → **Photos** *(crop photo analysis, Q135)* | Yes *(only when `PHOTO_AI_API_KEY` or `FEED_AI_API_KEY` is set on the server and the app has the stage 3 screen)* | Optional | App functionality | No | A crop photo the farmer sends to identify a disease or pest: metadata stripped on the server, analysed by Anthropic (service provider), kept as a training sample for `PHOTO_AI_RETENTION_DAYS` (default 730) in the user's own folder; deletable with "Delete this photo" on the result screen or with the account (DI §3 "Crop photo analysis"). |
| Messages → **Other in-app messages** | Yes *(only when Sarkari Sandesh is in the release)* | Optional | App functionality | **Yes** | "Check a message": pasted text compared in memory, not stored (DI §6). |
| App activity → **App interactions** | Yes *(only when Sarkari Sandesh is in the release)* | Optional | App functionality | No | Which government notices the grower saw, dismissed or asked to be reminded of; notification preferences (privacy page §2 "Other"). |
| App activity → **Other user-generated content** | Yes | Optional | App functionality | No | Orchard records: plots, bahar cycles, tasks, spray / input / irrigation / harvest logs, scouting notes, lab test values (DI §2). *Market link (only when `MARKET_LINK` is in the release): lots (crop, tonnes, quality, harvest window), interests, reports and blocks (fixed reason codes, no text); "deal done" taps and ratings (stars and ticks from a fixed list, no text) between the parties of an introduction; shown to others only as profile averages and counts (DI "Deal done" and ratings (L5)).* |
| Financial info → **Purchase history** | Yes *(owner decision 2026-11-08, Q122)* | Required for a subscription (only when the subscription switch is ON) | App functionality | No | Google Play subscription: product, state, period, auto-renew, a SHA-256 of the purchase token (never the token) and Play's pending price change; kept after account deletion as the billing ledger (DI §5 "Payments"). Payment itself is taken by Google Play; no card, bank or UPI data. |
| Photos and videos → **Photos** *(bill reading, Q136)* | Yes *(only when `PHOTO_AI_API_KEY` or `FEED_AI_API_KEY` is set on the server and the app has the bill photo button)* | Optional | App functionality | No | A photo of an agri-input shop bill the farmer chooses to read on the spray record or Add expense: metadata stripped on the server, sent to Anthropic (service provider) only to read it; the photo and the result are **not kept on the server** (processed ephemerally), only a count row for the limits; the photo stays on the phone and is backed up only by the optional photo backup (row above; DI §3 "Bill reading", "Bill photos"). |
| Photos and videos → **Photos** *(in-app feedback)* | Yes | Optional | App functionality | No | An optional screenshot with in-app feedback ("अभिप्राय द्या"), JPEG with metadata stripped, in the user's own folder; erased with the account (DI §7 "In-app feedback"). |
| App activity → **Other user-generated content** *(in-app feedback)* | Yes | Optional | App functionality | No | The feedback text (typed or spoken) and its kind (problem / suggestion / question), sent only when the user taps Send; read by the feedback admin; erased with the account (DI §7). |
| App info and performance → **Other app performance data** *(in-app feedback)* | Yes | Optional | App functionality | No | App version and phone model sent with a feedback message (DI §7). |
| App info and performance → **Diagnostics** | Yes *(only when `SENTRY_DSN` is set on the server)* | — | App functionality | No | Server-side error reports without user ids, IPs or bodies (DI §5). The on-phone log leaves the phone only when the grower taps "Send logs" (user-initiated, not collected, DI §4). If `SENTRY_DSN` is empty, answer **No**. |
| Device or other IDs | **No** while the release APK is built without `PUSH=true`; **Yes** when push is in the release | Optional | App functionality; *Fraud prevention, security, and compliance* (market link only) | No | The FCM registration token, sent to our API only when push is on (DI §5 "FCM", §7 `push_devices`). *Market link (only when `MARKET_LINK_ENABLED` is on): the API also keeps a SHA-256 of that token per account (`device_sightings`, never the token) so two accounts on one phone cannot rate each other; it is not erased with the account (DI §3A "Kept after deletion").* |

Types answered **No**: Health and fitness, Contacts, Calendar (tasks live in the app, not in the phone
calendar), Files and docs (lab-report files stay on the phone, DI §3), Audio (voice typing goes to the phone's
own speech service, never to our API, DI §4), Web browsing, Installed apps, Emails, SMS or MMS, Credit score, Race / religion / political / sexual orientation, Crash logs from the app (no crash SDK).

Season sale package (spec v1.5 §4E, off by default): the grower pays the company **outside the app** (UPI /
cash / bank); an admin records the payment in the admin web. The app collects no payment, amount, UPI ID or
receipt and shows only "package active until <date>" / "not active", so the package adds nothing to
**Financial info → Purchase history / Payment info** (Purchase history is **Yes** for Play subscriptions only, see above; Payment info stays **No**). Confirm before the switch is turned ON in
production (Play Console check, spec §4D "Needs before go-live"). The Android app shows nothing about the package
price or any payment (no price, amount, ₹, pay button, UPI ID, QR or link); the admin web's package strings are kept
out of the app bundle, and a CI test checks both (`app/test/l10n/package_consumption_only_test.dart`). The payment
record (`package_grants`) is entered by an admin in the admin web, not collected by the app (DI §3A).

## 2A. Market link: what other users see (only when it is in the release)

The market link is off in production (`MARKET_LINK_ENABLED` off, app built without `MARKET_LINK`). Before it is
turned on, decide with the lawyer how these user-to-user displays are answered in the "Data shared" section (Q52):

| Data | Shown to | DI ref |
|---|---|---|
| Trader / exporter / broker / provider name, firm, contact phone, place + registration date, verification badges, rating averages | signed-in users, once the admin has verified the profile (registration numbers, documents and the exact GPS fix: admin only) | DI §3A |
| Grower's lot: first name, crop / variety, acres, tonnes, quality, photos, harvest window, district | admin-verified traders and brokers (with the season package ON: only lots with an active grant) | DI §3A "What traders see of a lot" |
| Grower's profile name, profile phone, village / taluka / district, plot name and plot pin | only the trader and broker of an interest the grower accepted | DI §3A "Interests and introductions (L4)" |
| Ratings (stars, fixed tags, no text) | the rater and the ratee; everyone else sees averages and counts | DI §3A "Deal done" and ratings (L5) |

## 3. Why every row says "Shared: No"

| Recipient | Why it is not "sharing" in Play's sense | DI ref |
|---|---|---|
| Supabase (auth, database, storage), the VPS host | Service providers that store / run it for us | DI §5 |
| SMS provider (OTP) | Service provider chosen in Supabase, sends the OTP for us | DI §1 |
| Open-Meteo | Gets only a ~1 km rounded point with no user id, to fetch weather for us | DI §5 |
| Sentry *(if on)* | Service provider for error reports, no user ids | DI §5 |
| data.gov.in, government sites | Receive no user data | DI §5 |
| Anthropic *(if on)* | Service provider: summarises government documents (no user data) and analyses the crop photos farmers send and reads the shop bill photos they choose to read, for us (metadata stripped; no name, phone or location; bill photos not kept) | DI §3, §5 |
| CSV / PDF export, "Send logs" | Started by the user through the share sheet | DI §4 |

## 4. Security practices section

- Data is encrypted in transit: **Yes**.
- Users can request deletion: **Yes** (in the app and by email).
- Committed to the Play Families policy: **No** (the app is for adult growers; privacy page §8).
- Independent security review: **No** (not done; do not tick).

## 5. Owner checks before submitting the form

1. In production: is photo backup on (`PHOTO_STORAGE_*`)? Is `SENTRY_DSN` set? Is Sarkari Sandesh on in the
   Release APK? Is `PHONE_LOGIN=true`? Each answer changes one row above.
2. `PRIVACY_CONTACT_EMAIL` is set and the privacy page shows it.
3. The form, this file, DATA_INVENTORY and the privacy page say the same thing (Q52 lawyer review).
