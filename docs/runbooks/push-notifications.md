# Push सूचना (Firebase Cloud Messaging) — चालू करणे (audit BG-01, OPEN_QUESTIONS Q32)

सध्या push **बंद** आहे: सर्व्हरवर FCM ची माहिती नाही आणि APK `PUSH=true` शिवाय बांधलेले आहे. तोपर्यंत
शेतकऱ्यासाठी काहीही बदलत नाही (कामांच्या आठवणी फोनवरच येत राहतात; हवामान धोका ॲपच्या हवामान कार्डवर
दिसतो). खालील पायऱ्या झाल्यावर दोन प्रकारच्या सूचना फोनवर येतात:

- हवामान धोका सूचना (`push.deliver`, रोज 07:07 IST, रोजच्या हवामान ओढणीनंतर), शेतकऱ्याच्या भाषेत;
- सरकारी योजनांच्या आठवणी (`feed.alert_job`, आधीचे quiet hours / आठवड्याची मर्यादा तसेच लागू).

काहीही git मध्ये जात नाही: `google-services.json` आणि service-account key दोन्ही git बाहेर.

## १. Firebase project तयार करा (एकदाच, तुम्ही)

1. https://console.firebase.google.com → **Add project** → नाव उदा. `bagmitra` → Google Analytics
   **बंद** ठेवा (आपण analytics वापरत नाही) → Create.
2. Project Overview → **Android** चिन्ह → Android package name: **`app.bagmitra.bagmitra`** (बरोबर हेच;
   `app/android/app/build.gradle.kts` मधील `applicationId`) → App nickname `BagMitra` → Register app.
3. **`google-services.json` डाउनलोड करा.** पुढची "Add Firebase SDK" पायरी वगळा (ते आधीच कोडमध्ये आहे).
4. Project settings (⚙) → General → **Project ID** लिहून ठेवा (उदा. `bagmitra-12ab3`). हेच
   `FCM_PROJECT_ID`.
5. Project settings → **Cloud Messaging** → "Firebase Cloud Messaging API (V1)" **Enabled** आहे का पाहा
   (नसेल तर तिथल्या ⋮ मधून Google Cloud Console मध्ये Enable करा). जुनी "Legacy API" लागत नाही.

FCM मोफत आहे; यासाठी billing / कार्ड लागत नाही.

## २. Service-account key डाउनलोड करा (सर्व्हरसाठी, गुप्त)

1. Project settings → **Service accounts** → "Firebase Admin SDK" → **Generate new private key** →
   Generate key. एक `.json` फाइल डाउनलोड होते.
2. ही फाइल **गुप्त** आहे (password सारखी): chat, email, git, screenshot मध्ये कधीही नको. फक्त
   तुमच्या संगणकावरून थेट VPS वर.
3. चुकून उघड झाली तर: याच पानावर Google Cloud Console → IAM → Service accounts → ती key **Delete**
   करा आणि नवी बनवा.

## ३. VPS वर key ठेवा आणि push चालू करा (तुम्ही, एक block)

तुमच्या संगणकावरून key VPS वर पाठवा (उदा. `scp ~/Downloads/bagmitra-*.json root@<VPS>:/root/fcm-key.json`),
मग VPS वर हा एकच block चालवा (`<PROJECT_ID>` बदला):

```bash
cd /opt/bagmitra && \
KEY_B64="$(base64 -w0 /root/fcm-key.json)" && \
sed -i '/^FCM_PROJECT_ID=/d;/^FCM_SERVICE_ACCOUNT_B64=/d' deploy/.env && \
printf 'FCM_PROJECT_ID=%s\nFCM_SERVICE_ACCOUNT_B64=%s\n' '<PROJECT_ID>' "$KEY_B64" >> deploy/.env && \
unset KEY_B64 && shred -u /root/fcm-key.json && chmod 600 deploy/.env && \
nohup bash deploy/deploy.sh > /tmp/bagmitra-deploy.log 2>&1 &
```

नंतर `tail -n 20 /tmp/bagmitra-deploy.log` मध्ये `weather alert pushes (01:37 UTC = 07:07 IST) cron line added`
दिसले पाहिजे. key `.env` मध्ये एका base64 ओळीत राहते (deploy.sh `.env` कधी छापत नाही, API ती log मध्ये
लिहीत नाही) आणि मूळ फाइल पुसली जाते.

तपासणी (VPS वर; JSON सारांश, त्यात token किंवा key नसते):

```bash
cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.push.deliver
```

`"skipped_reason": null` आले म्हणजे सर्व्हरची बाजू चालू. `"skipped_reason": "no push sender configured ..."`
म्हणजे `.env` मधील दोन्ही ओळी तपासा. key चुकीची असेल तर job स्पष्ट error देऊन थांबतो (key चा मजकूर न छापता).

पर्याय (Docker शिवाय चालवणाऱ्यांसाठी): `FCM_SERVICE_ACCOUNT_FILE=/path/key.json` (API ला वाचता येईल असा
मार्ग). दोन्ही दिले तर `FCM_SERVICE_ACCOUNT_B64` जिंकते.

## ४. Push असलेले APK बांधा

1. `google-services.json` ठेवा: `app/android/app/google-services.json` (हा मार्ग `.gitignore` मध्ये
   आहे; commit करू नका). ही फाइल असेल तेव्हाच Gradle चा Google services plugin लागतो; नसेल तर build
   आधीसारखेच होते.
2. build मध्ये `--dart-define=PUSH=true` जोडा, उदा.
   `flutter build apk --release --dart-define-from-file=../product.env --dart-define=PUSH=true ...`
   (बाकीचे `API_BASE_URL`, `SUPABASE_*` नेहमीप्रमाणे).
3. CI (GitHub Actions) मधून बांधायचे असेल तर: repo Settings → Secrets → `GOOGLE_SERVICES_JSON_B64`
   (= `base64 -w0 google-services.json`) आणि release workflow मध्ये build आधी ती फाइल लिहिणारी पायरी +
   `PUSH=true` — ही workflow पायरी अजून जोडलेली नाही (OPEN_QUESTIONS Q32).

`PUSH=true` असूनही फाइल नसेल तर ॲप Firebase सुरू करू शकत नाही, log मध्ये `push off: firebase did not
start` लिहिते आणि push शिवाय नेहमीसारखे चालते.

## ५. फोनवर काय होते

- साइन-इन झाल्यावर (आणि फोनवरची माहिती याच खात्याची आहे हे तपासल्यावर) ॲप फोनचा push token
  `POST /v1/me/devices` ला पाठवतो. Android 13+ वर notification परवानगी विचारली जाते.
- साइन-आउटच्या आधी token `DELETE /v1/me/devices` ने काढला जातो; खाते काढले तर सर्व्हरवरील token पुसले जातात.
- ॲप उघडे असताना आलेली सूचना फोनच्या notification मध्ये दाखवली जाते ("Alerts" channel); ॲप बंद
  असताना Android स्वतः दाखवते.
- फोनवरून ॲप काढले / token बदलला तर FCM `UNREGISTERED` सांगते आणि सर्व्हर तो token `push_devices`
  मधून काढतो. FCM बंद / व्यस्त असेल तर सूचना पुढच्या फेरीत (48 तासांच्या आत) पुन्हा पाठवली जाते;
  `notified_at` फक्त किमान एका फोनला पोहोचल्यावरच लिहिले जाते.

## ६. बंद करणे

`deploy/.env` मधून `FCM_PROJECT_ID` आणि `FCM_SERVICE_ACCOUNT_B64` च्या ओळी काढा आणि पुन्हा deploy:
`... cron line removed` दिसते; feed आठवण job फक्त नियोजन करतो. (गरज असल्यास Firebase मध्ये key Delete करा.)

## Technical notes (English)

- Sender: `api/src/bagmitra_api/push/fcm.py`. OAuth: a self-signed RS256 service-account JWT
  (scope `firebase.messaging`) exchanged at the key's `token_uri`; the access token is reused until
  2 minutes before expiry; a 401 refreshes it once. Message: `notification` (title, body), `data`,
  `android.priority=high`, `android.notification.channel_id=alerts`, `icon=ic_stat_notify`.
- Error mapping: 404 / `UNREGISTERED` / `SENDER_ID_MISMATCH` / `INVALID_ARGUMENT` on the token ->
  token deleted; everything else (429, 5xx, auth, other 400) -> `PushUnavailableError`, retried
  next run. Logs carry only HTTP status and FCM error code.
- Settings: `FCM_PROJECT_ID`, `FCM_SERVICE_ACCOUNT_B64` | `FCM_SERVICE_ACCOUNT_FILE`,
  `FCM_BASE_URL` (tests), `FCM_TIMEOUT_SECONDS` (default 15).
- App: `app/lib/features/push/` (`PushRegistrar`, `FirebasePushMessaging`, `HttpPushDeviceApi`);
  `AppConfig.pushEnabled` = `PUSH=true` and not demo mode.
