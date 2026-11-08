# Running the BagMitra API on a Hostinger VPS (Ubuntu)

मराठीत पायऱ्या; कमांड जशाच्या तशा कॉपी करा. सर्व्हरवर तुम्ही स्वतः चालवता; या प्रोजेक्टचा कोणताही भाग मी तुमच्या सर्व्हरवर परस्पर चालवत नाही.

**काय चालते:** `api` (FastAPI) + `caddy` (HTTPS आपोआप). डेटा आणि लॉगिन Supabase मध्ये (डेटाबेस तिथलाच, किंवा पर्यायाने याच सर्व्हरवर).
**लागते:** VPS (Ubuntu, ४ GB RAM पुरेशी), एक डोमेन/सबडोमेन (उदा. `api.तुमचे-डोमेन.com`), Supabase प्रोजेक्ट (`docs/runbooks/supabase-setup.md`).

## १. डोमेन सर्व्हरकडे दाखवा
डोमेनच्या DNS मध्ये एक **A record** जोडा: नाव `api`, किंमत = VPS चा IP पत्ता. (Hostinger मध्ये: Domains → DNS / Nameservers → Add record.) १०–३० मिनिटांत सक्रिय होते.

## २. सर्व्हरमध्ये जा आणि तयारी करा
Windows मध्ये Command Prompt: `ssh root@<VPS-IP>` (किंवा hPanel चे Browser terminal).
```
apt update && apt -y upgrade
apt -y install git ufw
ufw allow OpenSSH && ufw allow 80 && ufw allow 443 && ufw --force enable
curl -fsSL https://get.docker.com | sh
```
**आधी दुसरी वेबसाइट/सेवा याच सर्व्हरवर चालत असेल** आणि ती पोर्ट 80 किंवा 443 वापरत असेल (nginx, Apache, CyberPanel, Coolify), तर Caddy सुरू होणार नाही. तेव्हा थांबा आणि मला सांगा; वेगळी जोडणी करू.

## ३. कोड सर्व्हरवर आणा (खाजगी रेपॉझिटरी, फक्त-वाचन key)
```
ssh-keygen -t ed25519 -f ~/.ssh/bagmitra_deploy -N ""
cat ~/.ssh/bagmitra_deploy.pub
```
छापलेली ओळ कॉपी करा. GitHub → रेपॉझिटरी → Settings → **Deploy keys** → Add deploy key (Allow write access **नको**) → पेस्ट करा.
```
git config --global core.sshCommand "ssh -i ~/.ssh/bagmitra_deploy -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
git clone git@github.com:abhishekwasu-hue/BaghMitra.git /opt/bagmitra
```

## ४. सेटिंग्ज भरा
```
cd /opt/bagmitra/deploy
cp .env.example .env
nano .env          # भरा, Ctrl+O, Enter, Ctrl+X
chmod 600 .env
```
`.env` मध्ये: `API_DOMAIN`, `DATABASE_URL` (Supabase → Connect → **Session pooler** चा connection string, port `5432`, user `postgres.<project-ref>`; सुरुवातीचे `postgresql://` बदलून `postgresql+asyncpg://` करा. Transaction pooler (port `6543`) नको. Pool चा आकार `DB_POOL_SIZE` / `DB_MAX_OVERFLOW`, default 5 + 5, `.env.example` पाहा), `SUPABASE_JWKS_URL`, `ENTITLEMENT_SIGNING_KEY` (`openssl rand -base64 32 | tr '+/' '-_' | tr -d '='` ने बनवा). **`.env` कुणालाही पाठवू नका आणि GitHub वर टाकू नका.**

ऐच्छिक (नसले तरी API चालते): `MARKET_API_KEY` (data.gov.in वरची मोफत key, बाजारभावासाठी). हवामानाला key लागत नाही (मोफत Open-Meteo; व्यावसायिक प्लॅन घेतल्यावर `WEATHER_BASE_URL` + `WEATHER_API_KEY`, Q25). `SENTRY_DSN` (त्रुटी अहवाल, पायरी ६अ-२; रिकामा = बंद).

## ५. सुरू करा
```
docker compose up -d --build
docker compose ps
curl https://api.तुमचे-डोमेन.com/health/ready
```
पहिल्यांदा ५–१० मिनिटे लागतात. `{"status":"ok","database":"ok"}` दिसले की API आणि database दोन्ही चालू आहेत (`/health/ready`; फक्त API साठी `/health/live`). अडल्यास: `docker compose logs --tail 100 api`.

## ६. नंतर अपडेट (एक कमांड)
```
cd /opt/bagmitra && bash deploy/deploy.sh
```
ही script `.env` तपासते (मूल्ये छापत नाही), नवीन कोड आणते, containers पुन्हा बांधून सुरू करते, `https://API_DOMAIN/health/ready` (API + database) उत्तर देईपर्यंत थांबते, cron ओळी एकदाच जोडते (हवामान, बॅकअप, आणि `.env` मध्ये चालू केलेली कामे — पायरी ६अ) आणि `/etc/logrotate.d/bagmitra` लिहिते (cron log फाइली आठवड्याला किंवा 10 MB झाल्यावर फिरवल्या जातात, ८ जुन्या प्रती; root म्हणून चालवा). काही बिघडले तर मागच्या आवृत्तीवर परत: `bash deploy/deploy.sh --revert`. पहिल्यांदाही (पायरी ४ नंतर) हीच कमांड चालते.
टेबलचे बदल (migration) प्रत्येक सुरुवातीला आपोआप होतात.

## ६अ. ठरलेल्या वेळची कामे (cron)
`bash deploy/deploy.sh` प्रत्येक वेळी cron तपासतो: हवी ती ओळ नसेल तर एकदाच जोडतो, आधीच असेल तर पुन्हा जोडत
नाही. तुमच्या इतर cron ओळींना हात लावत नाही. `.env` मधील मूल्ये कुठेही छापली जात नाहीत. सर्व्हरचे घड्याळ UTC
आहे; खाली IST वेळही दिली आहे.

| काम | केव्हा चालू | वेळ (UTC = IST) | log |
|---|---|---|---|
| हवामान व धोका सूचना (`weather.pull_job`) | नेहमी | रोज 00:00 = 05:30 | `/var/log/bagmitra-weather-pull.log` |
| database बॅकअप (`deploy/backup.sh`) | नेहमी | रोज 21:40 = 03:10 | `/var/log/bagmitra-backup.log` |
| बाजारभाव ओढणे (`market.pull_job`) | `MARKET_API_KEY` भरलेली असेल तर | दर ६ तासांनी 02:35, 08:35, 14:35, 20:35 = 08:05, 14:05, 20:05, 02:05 | `/var/log/bagmitra-market-pull.log` |
| हवामान धोका सूचना फोनवर पाठवणे (`push.deliver`) | `FCM_PROJECT_ID` भरलेले असेल तर (runbook `push-notifications.md`) | रोज 01:37 = 07:07 | `/var/log/bagmitra-push-deliver.log` |
| KB कार्डांची रात्रीची फेरतपासणी (`kb.regate`) | नेहमी (बंद: `CRON_KB_REGATE=off`) | रोज 20:50 = 02:20 | `/var/log/bagmitra-kb-regate.log` |
| सरकारी सूचनांच्या आठवणी (`feed.alert_job`) | नेहमी (बंद: `CRON_FEED_ALERTS=off`) | रोज 03:17 व 11:17 = 08:47 व 16:47 | `/var/log/bagmitra-feed-alerts.log` |
| बातम्यांचे मथळे (`feed.news_job`) | नेहमी (बंद: `CRON_FEED_NEWS=off`); अटी `allowed` असलेल्या स्रोतांकडूनच मथळे येतात | दर ६ तासांनी 01:23, 07:23, 13:23, 19:23 | `/var/log/bagmitra-feed-news.log` |
| sync इतिहासातील जुना मजकूर पुसणे (`sync.retention`) | नेहमी (बंद: `CRON_SYNC_RETENTION=off`); `SYNC_PAYLOAD_RETENTION_DAYS` (default 90) दिवसांपेक्षा जुन्या बदलांचा मजकूर hash मध्ये बदलतो | रोज 22:13 = 03:43 | `/var/log/bagmitra-sync-retention.log` |
| खाते काढलेल्या व्यक्तीची बाजार-जोडणी माहिती पुसणे (`market_link.erase_job`) | नेहमी (बंद: `CRON_MARKET_LINK_ERASE=off`); माहिती लगेच लपते आणि `MARKET_LINK_ERASE_AFTER_DAYS` (default 180) दिवसांनी पुसली जाते | रोज 22:41 = 04:11 | `/var/log/bagmitra-market-link-erase.log` |
| बाजार जोडणी: वर्षाने पुन्हा तपासायच्या नोंदींची यादी (`market_link.recheck_job`) | नेहमी (बंद: `CRON_ML_RECHECK=off`); `MARKET_LINK_ENABLED` बंद असताना काहीच करत नाही; `MARKET_LINK_RECHECK_DAYS` (default 365) दिवसांपेक्षा जुन्या तपासण्या admin च्या यादीत येतात | रोज 23:19 = 04:49 | `/var/log/bagmitra-ml-recheck.log` |

- ही पाचही कामे (सूचना, बातम्या, sync पुसणे, बाजार-जोडणी पुसणे, पुन्हा तपासणी यादी) default चालू आहेत: `.env` मध्ये काहीही न लिहिता `bash deploy/deploy.sh` ने ओळी लागतात
  ("... cron line added").
- बंद करणे: `deploy/.env` मध्ये उदा. `CRON_FEED_NEWS=off` (`off` / `false` / `no` / `0` चालते) लिहा आणि पुन्हा
  deploy: "... cron line removed" दिसते.
- तपासणे: `crontab -l | grep bagmitra`. एखादे काम हाताने आत्ता चालवायचे असेल तर, उदा.
  `cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.market.pull_job`
  (शेवटी JSON सारांश; बाजारभाव key टाकल्यावर एकदा असे चालवा म्हणजे पहिल्या ठरलेल्या वेळेआधीच भाव दिसतात).
- हवामान: `docs/runbooks/weather-pull.md`. बाजारभाव: `docs/runbooks/market-prices.md`. सरकारी सूचना व बातम्या:
  `docs/runbooks/govt-feed.md` §8–§9. फोनवर push सूचना Firebase key मिळाल्यावरच (Q32); तोपर्यंत आठवणींचे काम
  फक्त नियोजन करते.

## ६अ-२. त्रुटी अहवाल (ऐच्छिक, Sentry)
`SENTRY_DSN` रिकामा असेल (मूळ स्थिती) तर कोणताही त्रुटी अहवाल कुठेही जात नाही. Sentry (किंवा स्वतः चालवलेला
GlitchTip सारखा Sentry-सुसंगत सर्व्हर) वापरायचा असेल तर तिथे प्रकल्प बनवा, त्याचा DSN `deploy/.env` मध्ये
`SENTRY_DSN=` ला टाका आणि `bash deploy/deploy.sh` चालवा. फक्त API च्या त्रुटी जातात: वापरकर्त्याचा id, IP,
cookies, विनंतीचा मजकूर (शेतकऱ्यांच्या नोंदी), Authorization / API key headers आणि query आधीच काढून टाकले
जातात. DSN ही गुप्त माहिती आहे: git किंवा chat मध्ये टाकू नका. बंद करण्यासाठी ओळ रिकामी करा आणि पुन्हा deploy.

## ६अ-१. मुख्य पान, गोपनीयता धोरण आणि Google लॉगिन प्रसिद्ध करणे
1. (ऐच्छिक, पण Google / Play Store साठी हवे) `.env` मध्ये `PRIVACY_CONTACT_EMAIL=` प्रकल्पाचा ईमेल टाका आणि `bash deploy/deploy.sh` चालवा.
2. deploy नंतर फोन / ब्राउझरमध्ये उघडा: `https://<API_DOMAIN>/` (मुख्य पान) आणि `https://<API_DOMAIN>/privacy` (गोपनीयता धोरण, मराठी + English; फक्त English: `/privacy?lang=en`). संपर्क ईमेल दिसतो का ते पाहा.
3. Google Cloud → **Google Auth Platform → Branding**: App home page = `https://<API_DOMAIN>/`, Privacy policy = `https://<API_DOMAIN>/privacy`, Authorized domains = तुमचे डोमेन (उदा. `तुमचे-डोमेन.com`) आणि `<ref>.supabase.co` (Supabase प्रकल्पाचा ref). Save.
4. **Audience → Publish app** (Testing मधून In production). यानंतर कोणतेही Google खाते लॉगिन करू शकते.
5. Play Store आधी: धोरणाचा मजकूर वकिलाकडून तपासून घ्या (Q52). तपशील: `docs/legal/DATA_INVENTORY.md`.

## ६ब. बाजारभाव हाताने भरणारी व्यक्ती
`market_admin` role script ने द्या: `docs/runbooks/admin-web.md` §५अ (सर्व staff roles, देणे / काढणे, नवे लॉगिन). पायऱ्या: `docs/runbooks/market-prices.md`. Admin पान (`/admin/`) आणि role देणारी script: `docs/runbooks/admin-web.md`.

## ६क. deploy आधीची यादी
- [ ] DNS A record काम करतो (`ping api.तुमचे-डोमेन.com` ने VPS चा IP दिसतो)
- [ ] `.env` भरलेली, `chmod 600`, GitHub वर नाही
- [ ] `docker compose ps` मध्ये `api` healthy (database सह), `curl https://api.तुमचे-डोमेन.com/health/ready` → `"database":"ok"`
- [ ] `docker compose logs api | grep -i "alembic"` मध्ये migration त्रुटी नाही
- [ ] `crontab -l | grep bagmitra` मध्ये हवामान व बॅकअप ओळी (deploy नंतर आपोआप); हवामान हाताने एकदा चालवले (`new_alerts`, `failed_cells: 0`)
- [ ] नियोजित कामे (पायरी ६अ) default चालू; नको असलेले `off` करा
- [ ] (ऐच्छिक) `MARKET_API_KEY` टाकून deploy, `market.pull_job` एकदा हाताने चालवला, ॲपमध्ये बाजारभाव दिसतात
- [ ] `https://<API_DOMAIN>/` आणि `/privacy` उघडतात; Google Branding मध्ये दोन्ही दुवे टाकले (पायरी ६अ-१)
- [ ] GitHub secrets `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` टाकून नवीन test APK
- [ ] (शेतकऱ्यांसाठी) release key चे ४ secrets, Release APK, `/srv/bagmitra-apk/bagmitra.apk` आणि `APP_LATEST_VERSION_*` (पायरी ६इ)

## ६ड. एकाच सर्व्हरवर दुसरा प्रकल्प (उदा. ट्रेडिंग प्लॅटफॉर्म ATP) असेल तर
ATP चा `atp-caddy-1` आधीच पोर्ट 80/443 वापरतो. मग बागमित्र स्वतःचा Caddy चालवत नाही; ATP चाच Caddy
`bagmitra.तुमचे-डोमेन.com` बागमित्रकडे पाठवतो. दोघांमध्ये फक्त `edge` नावाचे छोटे नेटवर्क असते — ATP चा
डेटाबेस/redis बागमित्रला दिसत नाहीत. हे **बाजार बंद असताना** करा (Caddy reload मध्ये ATP बंद होत नाही,
तरी काळजी म्हणून).

1. DNS: नवीन A record `bagmitra` → VPS चा IP.
2. `.env` (पायरी ४) मध्ये `API_DOMAIN=bagmitra.तुमचे-डोमेन.com` आणि एक ओळ जास्त: `EDGE_NETWORK=edge`.
3. नेटवर्क बनवा आणि ATP चा Caddy त्याला जोडा:
```
docker network create edge
docker network connect edge atp-caddy-1
```
4. ATP ची Caddyfile कुठे आहे ते पाहा:
```
docker inspect atp-caddy-1 --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
```
`/etc/caddy/Caddyfile` च्या समोर जो Source पत्ता दिसेल ती फाइल `nano` ने उघडा आणि **शेवटी** हे जोडा
(बाकी काहीही बदलू नका):
```
bagmitra.तुमचे-डोमेन.com {
	encode gzip
	request_body {
		max_size 50MB
	}
	reverse_proxy bagmitra-api:8000
}
```
5. तपासून reload करा (ATP चालूच राहतो):
```
docker exec atp-caddy-1 caddy validate --config /etc/caddy/Caddyfile
docker exec atp-caddy-1 caddy reload --config /etc/caddy/Caddyfile
```
`validate` मध्ये त्रुटी आली तर reload करू नका; जोडलेल्या ओळी काढा आणि मला संदेश पाठवा.
6. बागमित्र सुरू करा: `cd /opt/bagmitra && bash deploy/deploy.sh` → शेवटी "API is up".

**लक्षात ठेवा:** ATP चा Caddy container पुन्हा बनवला (ATP update) की `docker network connect edge atp-caddy-1`
परत चालवावे लागते, आणि ATP ची Caddyfile git मधून बदलत असेल तर वरचा block तिथेही (ATP रेपोमध्ये) टाकावा
लागेल. कायमचा उपाय: ATP च्या compose मध्ये caddy ला `edge` नेटवर्क आणि Caddyfile मध्ये हा block — हा बदल
ATP प्रकल्पात करायचा (बागमित्र रेपोमध्ये नाही).
बागमित्र स्थिती: `bash deploy/deploy.sh status`. परत जाणे: `bash deploy/deploy.sh --revert`. नवीन deploy ने database migration जोडली असेल तर `--revert` आधी database त्या मागच्या migration पर्यंत खाली नेते (उदा. 0021 मागे घेतल्यास scouting फोटोचे `photo_key` पुसले जातात), मग जुना कोड सुरू करते.

## ६इ. नवीन APK शेतकऱ्यांना देणे (ॲप अपडेट)
ॲप सुरू होताना (दिवसातून जास्तीत जास्त एकदा) `https://<API_DOMAIN>/v1/app/version` विचारते. फोनवरची आवृत्ती
जुनी असेल तर वर छोटी पट्टी "नवीन आवृत्ती उपलब्ध — डाउनलोड करा" दिसते; ती दाबली की `https://<API_DOMAIN>/app`
वरून APK उतरतो. इंटरनेट नसेल तर ॲप काहीच दाखवत नाही.

**सोपा मार्ग (2026-11-08 पासून):** `deploy/.env` मध्ये एकदा `RELEASE_APK_MIRROR=on` ठेवा आणि `bash deploy/deploy.sh` चालवा. मग प्रत्येक वेळी
फक्त GitHub → Actions → **Release APK** चालवायचे: १५ मिनिटांत VPS चे काम (`deploy/fetch_test_apk.sh`) नवीन arm64-v8a APK `/app` वर
ठेवते आणि `release.json` लिहिते; `/v1/app/version` तेच आकडे सांगतो. खालच्या पायऱ्या २–४ (scp, `.env` मध्ये आकडे) लागत नाहीत.
`.env` मध्ये `APP_LATEST_VERSION_CODE` ठेवला असेल तर तोच वापरला जातो (हाताचा मार्ग चालू राहतो).

हाताचा मार्ग:
1. GitHub → Actions → **Release APK** चालवा (`docs/runbooks/release-apk.md`). Summary मधील **version code** आणि
   **version name** लिहून ठेवा. Releases पानावरून `bagmitra-<name>-<code>-arm64-v8a.apk` तुमच्या कॉम्प्युटरवर उतरवा.
2. तुमच्या कॉम्प्युटरवरून सर्व्हरवर पाठवा (फाइलचे नाव तुमच्या फाइलप्रमाणे):
```
ssh root@<VPS-IP> "mkdir -p /srv/bagmitra-apk"
scp bagmitra-1.0.0-3-arm64-v8a.apk root@<VPS-IP>:/srv/bagmitra-apk/bagmitra.apk.new
ssh root@<VPS-IP> "mv /srv/bagmitra-apk/bagmitra.apk.new /srv/bagmitra-apk/bagmitra.apk && chmod 644 /srv/bagmitra-apk/bagmitra.apk"
```
   (आधी `.new` नावाने पाठवून मग `mv`: पाठवणे मध्येच तुटले तरी शेतकऱ्यांना अर्धी फाइल मिळत नाही.)
3. सर्व्हरवर `.env` (`nano /opt/bagmitra/deploy/.env`) मध्ये पायरी १ चे आकडे:
```
APP_LATEST_VERSION_CODE=3
APP_LATEST_VERSION_NAME=1.0.0
APP_MIN_VERSION_CODE=0
```
   `APP_MIN_VERSION_CODE` फक्त जुने ॲप पूर्ण थांबवायचे असेल तेव्हाच वाढवा (त्याखालच्या ॲपवर "नवीन आवृत्ती आवश्यक"
   पडदा येतो आणि ॲप वापरता येत नाही). तो `APP_LATEST_VERSION_CODE` पेक्षा मोठा ठेवला तर API सुरूच होत नाही.
4. पुन्हा deploy: `cd /opt/bagmitra && bash deploy/deploy.sh`
5. तपासा: `curl https://<API_DOMAIN>/v1/app/version` मध्ये नवीन आकडे, आणि फोनच्या ब्राउझरमध्ये
   `https://<API_DOMAIN>/app` उघडल्यावर `bagmitra.apk` उतरतो.

**लक्षात ठेवा:** Test APK (test key) असलेल्या फोनवर हा APK थेट install होत नाही. परीक्षकांनी एकदाच: sync पूर्ण
होऊ द्या → test ॲप uninstall → हा APK install → त्याच खात्याने लॉगिन (`release-apk.md` §४). त्यानंतरचे सर्व
release APK जुन्यावरच install होतात आणि डेटा राहतो.

## ६ई. Testing the market link (owner only)
बाजार जोडणी (market link) दोन ठिकाणी चालू करावी लागते: सर्व्हर (API) आणि Test APK. दोन्हीपैकी एक बंद असेल तर
market link दिसत नाही.

**production बंदच राहते:** कायदेशीर अट (legal gate, spec v1.5 §5,
[`SPEC_market_linkage_addendum_v1.5.md`](../SPEC_market_linkage_addendum_v1.5.md)) पूर्ण होईपर्यंत शेतकऱ्यांच्या
सर्व्हरवर `MARKET_LINK_ENABLED` बंद. production **Release APK** (`release-apk.yml`) मध्ये `MARKET_LINK` कधीच
नसतो; ही सोय फक्त **Test APK** साठी आहे. चाचणी कोणत्या सर्व्हरवर करायची (वेगळा test सर्व्हर की production VPS
फक्त चाचणीपुरता) हे अजून ठरायचे आहे: `docs/OPEN_QUESTIONS.md` Q117 (default: सगळीकडे बंद).

**चालू करणे:**
1. सर्व्हर: `.env` (`nano /opt/bagmitra/deploy/.env`) मध्ये ही ओळ, मग पुन्हा deploy
   (`cd /opt/bagmitra && bash deploy/deploy.sh`):
```
MARKET_LINK_ENABLED=true
```
2. GitHub → repository **Settings → Secrets and variables → Actions → Variables** → **New repository variable**:
   नाव `MARKET_LINK`, value `true`. यानंतरचा Test APK (main वर push, किंवा Actions → Test APK → Run workflow)
   market link दाखवतो. variable नसेल तर Test APK `MARKET_LINK=false` ने बनतो.
   हाच variable admin web (`admin-web.yml`) मधली market-link पाने (पडताळणी रांग, सुरक्षा, package) दाखवतो; variable
   लावल्यानंतर admin web पुन्हा build झाला पाहिजे (Actions → Admin web → Run workflow, किंवा main वरचा पुढचा App build).

**बंद करणे:**
1. सर्व्हर: `.env` मधील ओळ `MARKET_LINK_ENABLED=false` करा (किंवा काढून टाका), मग पुन्हा deploy. बंद असताना प्रत्येक
   `/v1/market-link/*` 404 देतो.
2. GitHub: `MARKET_LINK` variable `false` करा किंवा delete करा; पुढचा Test APK market link शिवाय बनतो. आधी install
   केलेला Test APK नवीन Test APK install होईपर्यंत market link दाखवतो, पण सर्व्हर बंद असल्याने ते काम करत नाही.

## ७. बॅकअप आणि restore
**रोजचा बॅकअप (आपोआप):** `deploy.sh` पहिल्यांदा चालवल्यावर cron मध्ये एक ओळ टाकतो: रोज रात्री 03:10 IST ला
`deploy/backup.sh` चालते. ते `.env` मधील `DATABASE_URL` च्या database मधील `public` च्या सर्व tables (RLS
नियमांसह) `pg_dump` ने (`postgres:17-alpine` container मधून) काढून `/var/backups/bagmitra/bagmitra-<वेळ>.sql.gz`
मध्ये ठेवते. १४ दिवसांपेक्षा जुन्या फाइल आपोआप पुसल्या जातात. `DATABASE_URL` कुठेही छापला जात नाही.
- हाताने आत्ता बॅकअप: `cd /opt/bagmitra && bash deploy/backup.sh` → शेवटी "backup written".
- नोंद: `tail -n 5 /var/log/bagmitra-backup.log`. फाइली: `ls -lh /var/backups/bagmitra/`.
- हा बॅकअप याच सर्व्हरवर असतो. सर्व्हरच गेला तर तोही जातो: आठवड्यातून एकदा एखादी फाइल दुसरीकडे (उदा. तुमच्या
  laptop वर `scp`) कॉपी करा.
- लॉगिन खाती (मोबाइल नंबर) Supabase Auth मध्ये असतात, या बॅकअपमध्ये नाहीत; ती Supabase च्या प्लॅनच्या बॅकअपवर
  अवलंबून (Settings → Database → Backups तपासा). फोटो Supabase Storage मध्ये, या बॅकअपमध्ये नाहीत.
- प्रत्येक नवीन migration असलेल्या deploy आधी `bash deploy/backup.sh` एकदा हाताने चालवा.

**Restore (database खराब झाल्यास / चुकीचे migration).** हे सध्याच्या सर्व नोंदी बॅकअपच्या वेळेच्या नोंदींनी बदलते.
एकच block, `/opt/bagmitra` मध्ये; `FILE=` मध्ये हवी ती फाइल लिहा:
```
cd /opt/bagmitra/deploy && FILE=/var/backups/bagmitra/bagmitra-YYYYMMDDTHHMMSSZ.sql.gz \
&& bash backup.sh \
&& docker compose stop api \
&& docker compose run --rm --no-deps api alembic downgrade base \
&& PGURL="$(grep -E '^DATABASE_URL=' .env | tail -n 1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//' -e 's/postgresql+asyncpg:/postgresql:/')" \
&& export PGURL \
&& docker run --rm -e PGURL postgres:17-alpine sh -c 'psql -q "$PGURL" -c "DROP TABLE IF EXISTS public.alembic_version"' \
&& zcat "$FILE" | docker run --rm -i -e PGURL postgres:17-alpine sh -c 'psql -q -v ON_ERROR_STOP=1 "$PGURL"' > /dev/null \
&& unset PGURL && docker compose start api
```
(पहिली `backup.sh` म्हणजे restore आधीची आजची प्रत; `alembic downgrade base` बागमित्रच्या सर्व tables काढते,
मग बॅकअप त्या परत बनवतो.) शेवटी `curl -fsS https://<API_DOMAIN>/health/ready`. काही `ERROR` आल्यास पुढे जाऊ नका,
संपूर्ण output मला पाठवा. localdb profile वापरत असाल तर दोन्ही `docker run` मध्ये `--network deploy_default` जोडा.

**Restore चाचणी (महिन्यातून एकदा, सध्याच्या database ला हात न लावता):**
```
docker run -d --name bm-restore-test -e POSTGRES_PASSWORD=test postgres:17-alpine && sleep 10 \
&& docker exec bm-restore-test psql -U postgres -qc "CREATE SCHEMA auth; CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS 'SELECT NULL::uuid'" \
&& zcat "$(ls -t /var/backups/bagmitra/bagmitra-*.sql.gz | head -1)" | docker exec -i bm-restore-test psql -U postgres -q -v ON_ERROR_STOP=1 > /dev/null \
&& docker exec bm-restore-test psql -U postgres -tc "SELECT version_num FROM alembic_version" -tc "SELECT count(*) FROM plots" ; docker rm -f bm-restore-test
```
शेवटी migration क्रमांक आणि बागांची संख्या दिसली की बॅकअप वापरता येतो.

**Logs:** API containers चे logs प्रत्येकी जास्तीत जास्त 5 × 10 MB (जुने आपोआप जातात). Uvicorn चा access log बंद
आहे: logs मध्ये IP पत्ते आणि query string नसतात; API स्वतः फक्त method, path, status आणि वेळ नोंदवते.

## ८. अॅपला जोडणे
API चालू झाले की test APK build ला API पत्ता (`API_BASE_URL=https://api.तुमचे-डोमेन.com`) आणि Supabase चाव्या द्याव्या लागतात (GitHub secrets `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`). तोपर्यंत APK ऑफलाइन चाचणी मोडमध्येच राहतो.
