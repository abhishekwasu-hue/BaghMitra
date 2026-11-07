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
| Location → **Precise location** | Yes | Optional (a plot can be saved without a location) | App functionality | No | Plot GPS point and boundary, read once when the grower asks (DI §2, §4). |
| Location → **Approximate location** | Yes | Optional | App functionality | No | Declared because the app asks `ACCESS_COARSE_LOCATION` with the precise one; the server derives a ~1 km rounded point for weather (DI §5). |
| Personal info → **Name** | Yes | Optional (onboarding name is optional) | App functionality, Account management | No | Profile display name; worker and buyer names the grower types in labour and sales (DI §1, §2). |
| Personal info → **Email address** | Yes *(Google sign-in)* | Optional (only with Google sign-in) | Account management | No | Google shares it with Supabase Auth; our API does not read it (DI §1). |
| Personal info → **User IDs** | Yes | Required | Account management, App functionality | No | Supabase account id on every record (DI §1). |
| Personal info → **Phone number** | Yes | Required for phone sign-in; optional on a Google account | Account management, App functionality | No | Sign-in number and profile phone (DI §1). |
| Personal info → **Address** | Yes | Optional (onboarding place fields are optional) | App functionality | No | Village, taluka, district; district picks the government notices (DI §1). |
| Financial info → **Other financial info** | Yes | Optional | App functionality | No | Expenses, sales (rate, payment status), wages and advances, input costs, insurance policy number, sum insured, premium (DI §2). No card, bank or purchase data (DI §5 "Payments"). |
| Photos and videos → **Photos** | Yes *(only when photo backup is on on the server, `PHOTO_STORAGE_*`)* | Optional | App functionality | No | Scouting photos backed up to private Supabase Storage (DI §3). Claim-kit and lab-report photos stay on the phone and are not collected. If photo backup is off in production, answer **No** for this type. |
| Messages → **Other in-app messages** | Yes *(only when Sarkari Sandesh is in the release)* | Optional | App functionality | **Yes** | "Check a message": pasted text compared in memory, not stored (DI §6). |
| App activity → **App interactions** | Yes *(only when Sarkari Sandesh is in the release)* | Optional | App functionality | No | Which government notices the grower saw, dismissed or asked to be reminded of; notification preferences (privacy page §2 "Other"). |
| App activity → **Other user-generated content** | Yes | Optional | App functionality | No | Orchard records: plots, bahar cycles, tasks, spray / input / irrigation / harvest logs, scouting notes, lab test values (DI §2). |
| App info and performance → **Diagnostics** | Yes *(only when `SENTRY_DSN` is set on the server)* | — | App functionality | No | Server-side error reports without user ids, IPs or bodies (DI §5). The on-phone log leaves the phone only when the grower taps "Send logs" (user-initiated, not collected, DI §4). If `SENTRY_DSN` is empty, answer **No**. |
| Device or other IDs | **No** today | — | — | — | The push token is not wired (DI §5 "FCM"). **When push notifications ship, change to Yes** (FCM token; App functionality; optional) and update DATA_INVENTORY first. |

Types answered **No**: Health and fitness, Contacts, Calendar (tasks live in the app, not in the phone
calendar), Files and docs (lab-report files stay on the phone, DI §3), Audio (voice typing goes to the phone's
own speech service, never to our API, DI §4), Web browsing, Installed apps, Emails, SMS or MMS, Purchase
history, Credit score, Race / religion / political / sexual orientation, Crash logs from the app (no crash SDK).

Season sale package (spec v1.5 §4E, off by default): the grower pays the company **outside the app** (UPI /
cash / bank); an admin records the payment in the admin web. The app collects no payment, amount, UPI ID or
receipt and shows only "package active until <date>" / "not active", so **Purchase history** and
**Financial info → Purchase history / Payment info** stay **No**. Confirm before the switch is turned ON in
production (Play Console check, spec §4D "Needs before go-live").

## 3. Why every row says "Shared: No"

| Recipient | Why it is not "sharing" in Play's sense | DI ref |
|---|---|---|
| Supabase (auth, database, storage), the VPS host | Service providers that store / run it for us | DI §5 |
| SMS provider (OTP) | Service provider chosen in Supabase, sends the OTP for us | DI §1 |
| Open-Meteo | Gets only a ~1 km rounded point with no user id, to fetch weather for us | DI §5 |
| Sentry *(if on)* | Service provider for error reports, no user ids | DI §5 |
| data.gov.in, government sites, Anthropic *(if on)* | Receive no user data | DI §5 |
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
