# Google Play pre-launch checklist (owner)

The store kit in this folder: [`listing.md`](listing.md) (title, short and full description in en / mr / hi),
[`data-safety.md`](data-safety.md) (Data safety form answers), [`screenshots.md`](screenshots.md) (shot-list).
Nothing in this folder submits anything; every step below is done by the owner in Play Console.
Tick a line only after checking it on the real setting (Play Console, server `.env`, GitHub secrets).

## A. Build and signing

- [ ] **Target SDK 36** (Android 16), required for new apps and updates since 31 Aug 2026. Pinned in
      `app/android/app/build.gradle.kts` (`compileSdk 36`, `targetSdk 36`, `minSdk 24`) and checked by
      `app/test/android/release_config_test.dart`. Each August Google raises the level: check
      developer.android.com/google/play/requirements/target-sdk before every yearly release.
- [x] **App bundle.** Play accepts only an Android App Bundle (`.aab`) for a new app. The Release APK workflow
      also builds `bagmitra-play-<name>-<code>.aab` (same key, run number and dart-defines; signature, certificate
      and version code checked) as a 30-day run artifact; upload steps in `docs/runbooks/release-apk.md` §५.
- [ ] **Signing key.** The release keystore exists, two offline copies are kept (`docs/runbooks/release-apk.md` §१).
      In Play Console → App integrity → Play App Signing choose **"Use existing app signing key"** and upload
      this same release key (Google's PEPK tool). If Google generates a new key instead, the Play app and the
      side-loaded release APK have different signatures, and a phone with the APK cannot update from Play.
- [ ] **Version code.** Play needs a higher code on every upload. The code is the Release APK run number
      (`release-apk.md` §३); upload only builds from that workflow.
- [ ] **Application id** `app.bagmitra.bagmitra` is final: it can never change after the first upload.
- [ ] Permissions in the release: INTERNET, precise + approximate location, microphone, notifications,
      start at boot (each explained in `app/android/app/src/main/AndroidManifest.xml`). None needs a Play
      permission declaration (no background location, SMS, call log, all-files or exact-alarm permission).

## B. Policy pages and contact

- [ ] Privacy policy URL: `https://bagmitra.aialgodesk.org/privacy` opens and shows Marathi and English.
- [ ] `PRIVACY_CONTACT_EMAIL` is set in the server `.env` and appears on the privacy page (§11), then
      `bash deploy/deploy.sh`. Without it the page says the contact is not published.
- [ ] Data deletion URL (App content → Data deletion): `https://bagmitra.aialgodesk.org/privacy#en-delete`;
      the in-app path Profile → "Delete my account and data" works on a test account.
- [ ] Developer contact email and (for an organisation account) the D-U-N-S number in Play Console.
- [ ] **Lawyer review** of the privacy policy and the Data safety answers together, before production
      (OPEN_QUESTIONS Q52; DPDP Act 2023).

## C. App content declarations (Play Console → Policy → App content)

- [ ] **Data safety**: from `data-safety.md` §5 (check the server settings first).
- [ ] **Content rating** (IARC questionnaire): category *Utility / Productivity*; no violence, sexual content,
      gambling, drugs or bad language; users cannot talk to or share content with other users; no digital
      purchases; shares location with no other user. Expected rating: 3+ / Everyone (the questionnaire decides).
- [ ] **Target audience**: 18 and over only (privacy page §8); the app is not designed for children.
- [ ] **Ads**: "No, my app does not contain ads".
- [ ] **App access**: give the review team a working sign-in (a staff test Google account, or a test phone
      number with a fixed OTP set in Supabase → Auth → Phone → test numbers). Without it the review fails.
- [ ] **Financial features**: the app keeps the grower's own accounts; it offers no loans, payments, trading or
      banking. Answer that it provides none of the listed financial features.
- [ ] **Government information** *(if Sarkari Sandesh is on)*: every notice links its official source and the
      app does not claim to be a government app; the listing says the notices are checked by our team.
- [ ] **News app** declaration: No (PIB headlines only appear inside Sarkari Sandesh, if on).

## D. Store listing

- [ ] Texts from `listing.md` in en-IN, mr-IN, hi-IN, with the *[if on]* / *[if off]* lines resolved for this
      release (Sarkari Sandesh, phone login, market prices).
- [ ] App category: *Productivity* (alternative *Tools*); tags: farming / agriculture where offered.
- [ ] Screenshots, feature graphic and 512 × 512 icon from `screenshots.md`, per language.
- [ ] No chemical names, doses or yield / income claims anywhere in the listing or the images.

## E. Testing track before production

- [ ] A **personal** developer account created after Nov 2023 must run a **closed test with at least 12
      testers for 14 days in a row** before it can apply for production. Plan the testers (growers, family,
      staff) early. An organisation account does not have this rule.
- [ ] Internal testing first: install from Play on two phones (one 32-bit if possible), sign in, sync, set a
      reminder, restart the phone (reminder still comes), delete a test account.
- [ ] Pre-launch report (Play runs it on test devices): read the crashes and accessibility warnings.

## F. Open items found while writing this kit (not built)

1. ~~`.aab` output for Play (§A).~~ Done: the Release APK workflow builds the bundle on every run
   (`docs/runbooks/release-apk.md` §५).
2. Push notifications: when they ship, the Data safety form gets "Device or other IDs" (`data-safety.md` §2).
