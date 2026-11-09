# Release APK: the production build for growers

शेतकऱ्यांसाठीचा (production) APK. Test APK (`docs/runbooks/test-apk.md`) परीक्षकांसाठी तसाच चालू राहतो.
The production APK for growers. The Test APK (`docs/runbooks/test-apk.md`) stays as it is for testers.

| | Test APK | Release APK |
|---|---|---|
| Workflow | "Test APK" (आपोआप, main वर) | "Release APK" (फक्त हाताने, main वरून) |
| Key | test key | **release key** (तुमची, नसेल तर build थांबतो) |
| Dev gallery / TEST BUILD badge | आहे | नाही |
| Files | universal + 3 CPU | फक्त `arm64-v8a` आणि `armeabi-v7a` |
| Update notice | नाही | आहे (`/v1/app/version`) |

## १. एकदाच: release keystore बनवा / One time: create the release keystore

**मराठी:** ही key हरवली तर याच ॲपचे पुढचे अपडेट कधीच देता येणार नाहीत (शेतकऱ्यांना ॲप काढून नवीन टाकावे लागेल).
म्हणून ती एकदाच बनवा आणि **दोन ऑफलाइन प्रती** ठेवा (उदा. दोन वेगवेगळे पेन-ड्राइव्ह, एक घरी एक दुसरीकडे). पासवर्ड
कागदावर किंवा password manager मध्ये. `.jks` फाइल किंवा पासवर्ड कधीही GitHub, WhatsApp, ईमेल किंवा चॅटमध्ये टाकू नका.

**English:** If this key is lost, this app can never be updated again (growers would have to uninstall and
reinstall). Create it once and keep **two offline copies** (e.g. two USB drives in two places). Keep the
passwords on paper or in a password manager. Never put the `.jks` file or the passwords in GitHub, WhatsApp,
email or chat.

Your computer needs a JDK (`keytool`). Run once:

```bash
keytool -genkeypair -v -keystore bagmitra-release.jks -alias bagmitra \
  -keyalg RSA -keysize 4096 -validity 10000
```

It asks for a keystore password and your name / organisation (any honest values). Then make the text copy
GitHub needs:

```bash
base64 -w0 bagmitra-release.jks > bagmitra-release.jks.b64     # macOS: base64 -i bagmitra-release.jks -o bagmitra-release.jks.b64
```

Copy `bagmitra-release.jks` to the two offline drives now. Delete `bagmitra-release.jks.b64` after step 2.

## २. GitHub secrets (एकदाच) / GitHub secrets (once)

GitHub → repository → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `RELEASE_KEYSTORE_BASE64` | content of `bagmitra-release.jks.b64` |
| `RELEASE_KEYSTORE_PASSWORD` | the keystore password |
| `RELEASE_KEY_ALIAS` | `bagmitra` |
| `RELEASE_KEY_PASSWORD` | the key password (same as the keystore password if you pressed Enter) |

`API_BASE_URL`, `SUPABASE_URL` and `SUPABASE_ANON_KEY` must also be set (`test-apk.md` §1a). If any of these
seven is missing, the Release APK run stops with a red error naming it; it never signs with the debug key.

Pin the release key (audit L5): set the repository **variable** `RELEASE_CERT_SHA256` (GitHub → Settings → Secrets and
variables → Actions → Variables) to the release certificate's SHA-256 (colons allowed) only if the key changes: the workflow already defaults to the
owner's release key `C4:90:…:A8:BA` (Q125). The run fails if an APK is signed with any other key. The VPS mirror serves an APK only
when its SHA-256 equals GitHub's asset digest.

(GitHub CLI: `gh secret set RELEASE_KEYSTORE_BASE64 < bagmitra-release.jks.b64`, and so on.)

## ३. Release बनवा / Run the release

1. main वर सर्व checks हिरवे आहेत याची खात्री करा. / Check that main is green.
2. GitHub → Actions → **Release APK** → Run workflow → branch `main`:
   - `version_name`: शेतकऱ्यांना दिसणारी आवृत्ती, उदा. `1.0.0` (पुढच्या वेळी `1.0.1`, `1.1.0` …).
   - `sarkari_sandesh`: `off` (default) जोपर्यंत सरकारी संदेश सर्व्हर feed चालू नाही.
3. Run संपल्यावर Summary मध्ये **version code** दिसतो (उदा. `3`). Releases पानावर `release-<name>-<code>` मध्ये दोन फाइली:
   `bagmitra-<name>-<code>-arm64-v8a.apk` (जवळजवळ सर्व फोन) आणि `…-armeabi-v7a.apk` (जुने ३२-bit फोन).
4. सर्व्हरवर APK: `RELEASE_APK_MIRROR=on` असेल तर १५ मिनिटांत आपोआप `/app` वर (आणि update सूचनेचे आकडे); नाहीतर `docs/runbooks/vps-deploy.md` → "६इ. नवीन APK शेतकऱ्यांना देणे".

Version code = the Release APK run number. It only rises, and both APKs of one run carry the same code, so
any newer release installs over any older one (`arm64-v8a` or `armeabi-v7a`, whichever the phone has), and the
update check compares one number (audits R5 / BG-08). The run checks every APK's code before it publishes. Do
not rename or delete this workflow file: the run number would start again from 1. The Test APK uses the same
rule with its own run number (`test-apk.md` §2); test and release APKs never install over each other (§४).
Google Play also needs a rising code per upload, so Play uploads come only from this workflow.

Debug symbols (needed to read an obfuscated crash stack) are kept as the run artifact
`bagmitra-symbols-<name>-<code>` for 7 days; download them if you will need them longer.

## ४. Test APK वरून Release APK वर जाताना / Moving a phone from the test APK to the release APK (BG-07)

**मराठी:** Test APK आणि Release APK वेगवेगळ्या key ने सही केलेले आहेत. Android त्यांना एकमेकांवर install
करू देत नाही ("App not installed"). म्हणून परीक्षकांनी **एकदाच**:
1. Test ॲपमध्ये इंटरनेट चालू ठेवून सर्व नोंदी sync होऊ द्या (Home वर "… sync बाकी" पट्टी दिसू नये).
2. Test ॲप uninstall करा. (Uninstall मध्ये फोनवरचे न पाठवलेले बदल आणि फोटो जातात; म्हणून आधी sync.)
3. Release APK install करून त्याच नंबर / Google खात्याने लॉगिन करा; नोंदी सर्व्हरवरून परत येतात. फोटो फक्त
   सर्व्हरवर photo backup चालू असेल तरच परत येतात (`PHOTO_STORAGE_*`, `docs/runbooks/scouting-photos.md`).

**English:** The test APK and the release APK are signed with different keys, so Android will not install one
over the other ("App not installed"). Testers do this **once**: let everything sync (no "pending" banner),
uninstall the test app (this deletes unsent changes and photos on the phone, hence sync first), install the
release APK and sign in with the same number / Google account; records come back from the server. Photos come
back only if photo backup is on on the server (`PHOTO_STORAGE_*`, `docs/runbooks/scouting-photos.md`).
After that, every newer release APK installs over the previous one and keeps the data.

## ५. Google Play साठी App Bundle (.aab) / The App Bundle for Google Play

**मराठी:** Play Store फक्त `.aab` फाइल घेतो. वरच्या §३ प्रमाणे Release चालवला की तोच run त्याच release key ने,
त्याच version code ने आणि त्याच सेटिंग्जने `.aab` सुद्धा बनवतो. ही फाइल सार्वजनिक Releases पानावर **येत नाही** आणि
workflow ती Play वर पाठवतही **नाही**; ती तुम्ही स्वतः Play Console मध्ये टाकायची.
1. §३ प्रमाणे **Release APK** workflow `main` वरून चालवा (version_name, sarkari_sandesh).
2. Run हिरवा झाल्यावर त्या run चे पान उघडा → Summary मध्ये **Play App Bundle** भाग: फाइलचे नाव, आकार,
   version name / code आणि सही-प्रमाणपत्राचा SHA-256 (हा `C4:90:F1:…:A8:BA` असाच हवा).
3. त्याच पानाच्या खाली **Artifacts** मध्ये `bagmitra-play-<name>-<code>.aab` वर क्लिक करा. एक zip डाउनलोड होते;
   ती उघडून आतली `.aab` फाइल काढा. Artifact **३० दिवस** राहतो; त्याआधी डाउनलोड करा.
4. Play Console → BagMitra → **Test and release** → हवी ती track (आधी Internal testing) → **Create new release**
   → App bundles मध्ये ही `.aab` टाका → release notes (मराठी / हिंदी / English) → Save → Review → Rollout.
5. पहिल्या upload आधी Play App Signing मध्ये **"Use existing app signing key"** निवडून हीच release key द्या
   (`docs/store/pre-launch-checklist.md` §A "Signing key"); नाहीतर Play वरचे ॲप आणि APK एकमेकांवर update होणार
   नाहीत.
6. Play प्रत्येक upload ला मागच्यापेक्षा मोठा version code मागतो; हा run number असल्याने नेहमी वाढतो. एकच
   `.aab` दोनदा upload करता येत नाही: नवीन बदलासाठी workflow पुन्हा चालवा.

**English:** The same Release APK run also builds `app-release.aab` with the same key, version code (run
number) and dart-defines. The run checks it before keeping it: the signature verifies, the debug key is
refused, the certificate matches `RELEASE_CERT_SHA256`, and bundletool reads the expected version code and
name. It is kept only as the workflow artifact `bagmitra-play-<name>-<code>.aab` for 30 days. It is never
attached to the public release, and the workflow never uploads to Play. Download it from the run page and
upload it in Play Console yourself. Its Dart symbols are the artifact `bagmitra-play-symbols-<name>-<code>`,
also kept 30 days. The bundle is built after the APK release is published, so a bundle problem never holds
back the growers' APKs.
