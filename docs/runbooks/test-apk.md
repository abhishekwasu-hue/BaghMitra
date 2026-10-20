# Test APK: install BagMitra on your phone

A signed release-mode APK is built for every commit on `main` that passes the app checks
(format, analyze, tests, goldens, emulator). It is published as a GitHub **pre-release** named
`test-YYYYMMDD-<short-sha>`. You can also start a build by hand: GitHub → Actions → "Test APK" →
Run workflow.

Files in each release: `bagmitra-test-<version>-<sha>-universal.apk` (works on every phone, use this
one) and smaller per-CPU files (`arm64-v8a`, `armeabi-v7a`, `x86_64`).

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

## 2. Install on the phone

1. On the phone open the repository's **Releases** page, pick the newest `test-…` release, download
   `…-universal.apk` (or copy the file over WhatsApp / Google Drive).
2. Android asks to allow **Install unknown apps** for the browser or file manager: allow it once.
3. Open the downloaded file and tap Install.
4. To update, install the newer APK over the old one. Same test key means your data stays.

मराठी: फोनवर GitHub चे Releases पान उघडा, सर्वात नवीन `test-…` रिलीजमधील `…-universal.apk` डाउनलोड करा
(किंवा WhatsApp / Drive ने फोनवर पाठवा). "Install unknown apps" ला परवानगी द्या आणि फाइल उघडून Install करा.
अपडेटसाठी नवीन APK जुन्यावरच इन्स्टॉल करा; डेटा तसाच राहील.

## 3. Permissions the app asks for

- **Location**: only when you tap "Add this corner" while walking the boundary of a block. Nothing is tracked in the background.
- **Camera / microphone**: when photo and voice notes arrive in later releases.
- **Storage / share**: through the phone's share sheet when you export a PDF or CSV; no broad storage access.

## 4. Reporting a bug

Open Settings → "Send logs", add a screenshot, and tell which test build you have (the small
"TEST BUILD <sha>" badge on the home screen).

## 5. Known limits of the test build

- No server sync until the hosted Supabase project exists (`docs/runbooks/supabase-setup.md`): use "Try without account"; data stays on the phone.
- No payments, no WhatsApp or SMS reminders.
- Knowledge cards are drafts and are not shown to growers; no chemical advice.
- Test builds show the component gallery and the TEST BUILD badge; real releases will not.
