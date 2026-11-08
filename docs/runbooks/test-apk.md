# Test APK: install BagMitra on your phone

A signed release-mode APK is built for every commit on `main` that passes the app checks
(format, analyze, tests, goldens, emulator). It is published as a GitHub **pre-release** named
`test-YYYYMMDD-<short-sha>`. You can also start a build by hand: GitHub → Actions → "Test APK" →
Run workflow.

Files in each release: `bagmitra-test-<version>-<sha>-universal.apk` (works on every phone, use this
one) and smaller per-CPU files (`arm64-v8a`, `armeabi-v7a`, `x86_64`).

The Test APK checks its own GitHub pre-releases (at most every 6 hours, on start) and shows "नवीन आवृत्ती उपलब्ध — डाउनलोड करा" when a newer test build exists; the button opens our own address `https://<domain>/app/test` (the universal APK; GitHub only when the build has no https server), then Android asks to install it. With `TEST_APK_MIRROR=on` in `deploy/.env`, a VPS cron (`deploy/fetch_test_apk.sh`, every 15 minutes) copies each newer Test APK to `/srv/bagmitra-apk/bagmitra-test.apk` (served at `/app/test`), so the link sent to testers and the update button always give the newest test build. The Release APK lives in its own file (`bagmitra.apk`, served at `/app`, `RELEASE_APK_MIRROR=on`); the two never replace each other, because a test-key APK cannot install over a release-key APK or the other way round (audit H1). Each release title ends with `· code <run number>` (the APKs' version code); releases made before this have no code and are skipped.

Only commits that change `app/**`, `docs/api/**`, `product.env` or the app workflow produce a new
test APK, because the gate workflow only runs for those paths.

## 1. One-time: add the signing secrets (owner)

The test build is signed with a **test-only** key so each new APK installs over the previous one and
keeps your data. The Google Play upload key is a different key (Play App Signing) and is never used here.
Until the four secrets exist, the workflow signs with the debug key: still installable, but the
signature can change between machines, so update by uninstalling first.

Run on your computer (needs a JDK; keep the `.jks` file and the passwords somewhere safe, never commit them):

```bash
keytool -genkeypair -v -keystore bagmitra-test.jks -alias bagmitra-test \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 bagmitra-test.jks > bagmitra-test.jks.b64     # on macOS: base64 -i bagmitra-test.jks -o bagmitra-test.jks.b64
```

Then in GitHub: repository → Settings → Secrets and variables → Actions → New repository secret, four times:

| Secret | Value |
| --- | --- |
| `TEST_KEYSTORE_BASE64` | the content of `bagmitra-test.jks.b64` |
| `TEST_KEYSTORE_PASSWORD` | the keystore password you typed |
| `TEST_KEY_ALIAS` | `bagmitra-test` |
| `TEST_KEY_PASSWORD` | the key password you typed (same as the keystore password if you pressed Enter) |

(Or with the GitHub CLI: `gh secret set TEST_KEYSTORE_BASE64 < bagmitra-test.jks.b64`, and so on.)

## 1a. Connect the APK to the live server and login (owner)

Without these three secrets the APK runs in the offline test mode. Add them the same way:

| Secret | Value |
|---|---|
| `API_BASE_URL` | the deployed API, e.g. `https://bagmitra.<your-domain>` (no trailing `/`) |
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase → Project Settings → API Keys → the `anon` / publishable key (never the service-role key) |

The next test build (after a push to main, or Actions → Test APK → Run workflow) carries them.

**Phone OTP login (`PHONE_LOGIN`).** The login page offers Google only until an SMS provider is
set up on the Supabase project (supabase-setup.md step 2). Once it is, build with
`--dart-define=PHONE_LOGIN=true` (a repository variable passed by the build workflow); the
phone number and OTP fields then return. The offline test mode (no Supabase secrets) always
shows the phone path, since any six digits sign in locally there.

## 2. Install on the phone

1. On the phone open the repository's **Releases** page, pick the newest `test-…` release, download
   `…-universal.apk` (or copy the file over WhatsApp / Google Drive).
2. Android asks to allow **Install unknown apps** for the browser or file manager: allow it once.
3. Open the downloaded file and tap Install.
4. To update, install the newer APK over the old one. Same test key means your data stays.

मराठी: फोनवर GitHub चे Releases पान उघडा, सर्वात नवीन `test-…` रिलीजमधील `…-universal.apk` डाउनलोड करा
(किंवा WhatsApp / Drive ने फोनवर पाठवा). "Install unknown apps" ला परवानगी द्या आणि फाइल उघडून Install करा.
अपडेटसाठी नवीन APK जुन्यावरच इन्स्टॉल करा; डेटा तसाच राहील.

**Version code (BG-08).** Every APK of one Test APK run (universal and per-CPU) carries the same version code:
that run's number, which only rises. So any newer test APK installs over any older one, whichever file you
picked each time (a phone that has the `arm64-v8a` file can take the next `universal` file and the other way
round). The run checks this before it publishes. The Release APK follows the same rule with its own run number
(`release-apk.md` §3); a test APK and a release APK never install over each other because their keys differ (§5).

**Once, after this change:** a phone that has an older *per-CPU* test file (`arm64-v8a`, `armeabi-v7a` or
`x86_64`; those carried 1000 × CPU + run number) refuses the next test APK as a downgrade ("App not installed").
On that phone only: let everything sync, uninstall, install the newest `universal` file, sign in again. Phones
with the `universal` file are not affected.

मराठी: एकाच run मधील सर्व test APK (universal आणि CPU नुसार) यांचा version code एकच (run चा नंबर) असतो,
म्हणून कोणताही नवा test APK कोणत्याही जुन्यावर install होतो. ज्या फोनवर आधी CPU नुसारची (`arm64-v8a` इ.)
जुनी फाइल आहे, तिथे **एकदाच**: sync होऊ द्या, uninstall करा, नवी `universal` फाइल install करून लॉगिन करा.

## 3. Permissions the app asks for

- **Location** (precise and approximate): only when you tap "Add this corner" while walking the boundary of a block. Nothing is tracked in the background.
- **Microphone**: only when you tap the microphone next to a field; the phone's speech recogniser turns speech into text. The app does not record or store audio.
- **Notifications** (Android 13+): when the first task reminder is set. Reminders are local to the phone and come back after a restart (a "run at startup" permission that is not asked).
- **Internet**: the server and sync.
- Not asked at all: camera (a photo opens the phone's own camera app), storage (photo picker and the share sheet for PDF / CSV), exact alarms, background location. The list is checked by `app/test/android/release_config_test.dart`.

## 4. Reporting a bug

Open Settings → "Send logs", add a screenshot, and tell which test build you have (the small
"TEST BUILD <sha>" badge on the home screen).

## 5. Known limits of the test build

- No server sync until the hosted Supabase project exists (`docs/runbooks/supabase-setup.md`): use "Try without account"; data stays on the phone.
- No payments, no WhatsApp or SMS reminders.
- Knowledge cards are drafts and are not shown to growers; no chemical advice.
- Test builds show the component gallery and the TEST BUILD badge; real releases do not
  (production build: `docs/runbooks/release-apk.md`).
- Test builds do not check for app updates, and a test APK cannot be installed over a release APK or the
  other way round (different keys). Moving a phone to the release APK: sync, uninstall, install, sign in
  once (`release-apk.md` §4).
