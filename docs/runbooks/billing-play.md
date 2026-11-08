# Subscription billing (Google Play) — मालकाच्या पायऱ्या

कशासाठी: admin login मधून subscription चा switch ON / OFF करणे आणि प्रत्येक भूमिकेची (शेतकरी,
व्यापारी, मध्यस्थ (दलाल), निर्यातदार, सेवा देणारे) मासिक रक्कम ठरवणे. रक्कम Google Play मध्ये जाते;
app मध्ये Play चीच किंमत दिसते. निर्णय व तथ्ये: `docs/adr/0008-billing-play.md`.

> ⚠️ **Switch पहिल्यांदा ON करण्यापूर्वी CA चे GST मत आवश्यक आहे.** ते मिळेपर्यंत switch OFF ठेवा.
> Switch OFF असताना सगळ्यांना पूर्ण app मिळते. Switch ON असतानाही आज काहीही बंद होत नाही (Q118:
> कोणती माहिती plan शिवाय दिसणार नाही हे तुम्ही सांगेपर्यंत).

## १. Play Console (एकदाच, तुम्ही)
1. Organisation developer account आणि payments profile तयार असल्याची खात्री करा.
2. Play Console → Monetize → Payments policy, service fee (subscription साठीचा दर) व India चे पर्याय
   (user choice billing इ.) आजच्या दिवशी तपासा; वेगळे काही दिसले तर `OPEN_QUESTIONS.md` मध्ये लिहा.
3. Monetize → Subscriptions मध्ये प्रत्येक भूमिकेसाठी **एक** subscription तयार करा:

| Product ID | Base plan ID | कालावधी |
|---|---|---|
| `bagmitra_grower` | `monthly` | 1 महिना, auto-renewing |
| `bagmitra_trader` | `monthly` | 1 महिना, auto-renewing |
| `bagmitra_broker` | `monthly` | 1 महिना, auto-renewing |
| `bagmitra_exporter` | `monthly` | 1 महिना, auto-renewing |
| `bagmitra_provider` | `monthly` | 1 महिना, auto-renewing |

   Base plan सक्रिय (Active) करा; India साठी कोणतीही तात्पुरती किंमत द्या — खरी रक्कम admin page
   मधून बसते. (नावे बदलायची असल्यास `.env` मध्ये `PLAY_PRODUCT_PREFIX`, `PLAY_BASE_PLAN_ID`.)

## २. Service account (एकदाच, तुम्ही) — गुप्त
1. Google Cloud console मध्ये project निवडा → IAM → Service accounts → नवीन (उदा. `bagmitra-billing`).
2. Keys → Add key → JSON. ही फाइल **गुप्त** आहे: chat, email, git मध्ये कधीही नाही.
3. Play Console → Users and permissions → Invite user → त्या service account चा email →
   फक्त या app साठी परवानग्या: "View financial data", "Manage orders and subscriptions",
   आणि subscription किंमत बदलण्यासाठी "Manage store presence" (किमान परवानग्या).
4. Google Cloud मध्ये "Google Play Android Developer API" enable करा.

## ३. Real-time notifications — Pub/Sub (एकदाच, तुम्ही)
1. Google Cloud → Pub/Sub → Topic तयार करा (उदा. `play-rtdn`). Topic च्या permissions मध्ये
   `google-play-developer-notifications@system.gserviceaccount.com` ला **Pub/Sub Publisher** द्या.
2. त्या topic वर **Push** subscription: endpoint `https://bagmitra.aialgodesk.org/v1/billing/google/rtdn`,
   **Enable authentication** चालू, service account = नवा push account (उदा. `rtdn-push@…`),
   audience = तोच endpoint URL. Dead-letter topic चालू करा (max delivery attempts 10).
3. Play Console → Monetization setup → Real-time developer notifications → topic चे पूर्ण नाव
   (`projects/<project>/topics/play-rtdn`) → "Send test notification".

## ४. VPS वर सेटिंग (तुम्ही, एक block)
Key फाइल VPS वर `/root/play-key.json` म्हणून ठेवून (scp ने) हा block एकदाच चालवा:

```bash
cd /opt/bagmitra && \
KEY="$(base64 -w0 /root/play-key.json)" && \
sed -i '/^PLAY_/d' deploy/.env && \
printf 'PLAY_PACKAGE_NAME=%s\nPLAY_SERVICE_ACCOUNT_B64=%s\nPLAY_RTDN_AUDIENCE=%s\nPLAY_RTDN_PUSHER=%s\n' \
  "app.bagmitra.bagmitra" "$KEY" "https://bagmitra.aialgodesk.org/v1/billing/google/rtdn" "<rtdn-push@…>" >> deploy/.env && \
shred -u /root/play-key.json && unset KEY && \
bash deploy/deploy.sh && bash deploy/deploy.sh status
```

बंद करणे: `deploy/.env` मधून `PLAY_` ओळी काढा आणि `bash deploy/deploy.sh`.

## ५. Admin page मधील नियम (रक्कम सेव्ह करण्यापूर्वी page वर दिसतात)
- नवीन खरेदी: नवी किंमत काही तासांत.
- **कमी** केलेली किंमत: जुने subscribers आपोआप जुन्याच (जास्त) किमतीत राहतात; "जुन्या subscribers ना
  नवी किंमत" चालवल्यावरच त्यांच्या पुढच्या payment पासून कमी किंमत (Google email करते; स्वीकार लागत नाही).
- **वाढवलेली** किंमत: जुने subscribers आपोआप जुन्याच किमतीत राहतात. Admin ने "जुन्या subscribers
  ना नवी किंमत" (confirm) चालवले तरच: Google ३७ दिवसांची सूचना देते (चार्जच्या ३० दिवस आधीपासून
  email / push), user ने स्वीकारले नाही तर त्या renewal ला subscription बंद होते; app मध्ये सूचना
  आणि Play च्या subscription पानाचा link दिसतो.
- शुल्क फक्त app वापरासाठी — कोणत्याही व्यवहारावर कधीही नाही. स्वतःच्या नोंदी नेहमी वाचता व export
  करता येतात.

## Technical notes (English)
- Server: `api/src/bagmitra_api/billing/` (`switch.py`, `play.py`, `purchases.py`, `rtdn.py`);
  routers `routers/billing.py`, `routers/admin_billing.py`. Plans are seeded on every API start
  (`python -m bagmitra_api.kb.seed`).
- Env: `PLAY_PACKAGE_NAME`, `PLAY_SERVICE_ACCOUNT_B64` (secret), `PLAY_RTDN_AUDIENCE`,
  `PLAY_RTDN_PUSHER`, optional `PLAY_PRODUCT_PREFIX` (`bagmitra_`), `PLAY_BASE_PLAN_ID`
  (`monthly`), `PLAY_REGIONS_VERSION` (`2022/02`; check Play's "regions version" article when
  Play adds regions).
- Missing Play settings: admin amount saves answer 503 `play_not_set_up` (nothing saved);
  verify answers 503; RTDN answers 503 (Pub/Sub retries, then dead-letter).
- Testing on a phone: Play Console licence testers + internal testing track; test
  subscriptions renew every few minutes (`docs/runbooks/play-billing-testing.md`, to be written
  with the app PRs).
