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
`.env` मध्ये: `API_DOMAIN`, `DATABASE_URL` (Supabase चा direct connection string, सुरुवात `postgresql+asyncpg://`), `SUPABASE_JWKS_URL`, `ENTITLEMENT_SIGNING_KEY` (`openssl rand -base64 32 | tr '+/' '-_' | tr -d '='` ने बनवा). **`.env` कुणालाही पाठवू नका आणि GitHub वर टाकू नका.**

ऐच्छिक (नसले तरी API चालते): `MARKET_API_KEY` (data.gov.in वरची मोफत key, बाजारभावासाठी). हवामानाला key लागत नाही (मोफत Open-Meteo; व्यावसायिक प्लॅन घेतल्यावर `WEATHER_BASE_URL` + `WEATHER_API_KEY`, Q25).

## ५. सुरू करा
```
docker compose up -d --build
docker compose ps
curl https://api.तुमचे-डोमेन.com/health/live
```
पहिल्यांदा ५–१० मिनिटे लागतात. `{"status":"ok",...}` दिसले की API चालू आहे. अडल्यास: `docker compose logs --tail 100 api`.

## ६. नंतर अपडेट (एक कमांड)
```
cd /opt/bagmitra && bash deploy/deploy.sh
```
ही script `.env` तपासते (मूल्ये छापत नाही), नवीन कोड आणते, containers पुन्हा बांधून सुरू करते, `https://API_DOMAIN/health/live` उत्तर देईपर्यंत थांबते आणि हवामानाची cron ओळ एकदाच जोडते. काही बिघडले तर मागच्या आवृत्तीवर परत: `bash deploy/deploy.sh --revert`. पहिल्यांदाही (पायरी ४ नंतर) हीच कमांड चालते.
टेबलचे बदल (migration) प्रत्येक सुरुवातीला आपोआप होतात.

## ६अ. रोजचे हवामान आणि सूचना (cron)
API चालू झाल्यावर एकदाच `crontab -e` करून ही ओळ टाका (रोज सकाळी ५:३० IST = ००:०० UTC):
```
0 0 * * * cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.weather.pull_job >> /var/log/bagmitra-weather-pull.log 2>&1
```
आधी एकदा हाताने चालवून पाहा (वरची कमांड `0 0 * * *` शिवाय). तपशील: `docs/runbooks/weather-pull.md`. फोनवर push सूचना Firebase key मिळाल्यावरच (Q32).

## ६ब. बाजारभाव हाताने भरणारी व्यक्ती
Supabase → Authentication → Users → त्या व्यक्तीचे `app_metadata` = `{"roles": ["market_admin"]}` (service role नेच बदलता येते). पायऱ्या: `docs/runbooks/market-prices.md`.

## ६क. deploy आधीची यादी
- [ ] DNS A record काम करतो (`ping api.तुमचे-डोमेन.com` ने VPS चा IP दिसतो)
- [ ] `.env` भरलेली, `chmod 600`, GitHub वर नाही
- [ ] `docker compose ps` मध्ये `api` healthy, `curl https://api.तुमचे-डोमेन.com/health/live` → `ok`
- [ ] `docker compose logs api | grep -i "alembic"` मध्ये migration त्रुटी नाही
- [ ] हवामान cron ओळ टाकली आणि हाताने एकदा चालवली (`new_alerts`, `failed_cells: 0`)
- [ ] (ऐच्छिक) `MARKET_API_KEY` टाकून ॲपमध्ये बाजारभाव दिसतात
- [ ] GitHub secrets `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` टाकून नवीन test APK

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

## ७. बॅकअप
- **Supabase चा डेटाबेस वापरत असाल तर:** बॅकअप तिथल्या प्लॅननुसार (मोफत प्लॅनमध्ये मर्यादित). महत्त्वाचा डेटा असेल तर Settings → Database → Backups तपासा.
- **याच सर्व्हरवरचा डेटाबेस** (`docker compose --profile localdb up -d`) वापरल्यास बॅकअप तुमची जबाबदारी: रोज `docker compose exec -T db pg_dump -U postgres bagmitra | gzip > /root/bagmitra-$(date +%F).sql.gz` (cron) आणि फाइल दुसरीकडे कॉपी करा.

## ८. अॅपला जोडणे
API चालू झाले की test APK build ला API पत्ता (`API_BASE_URL=https://api.तुमचे-डोमेन.com`) आणि Supabase चाव्या द्याव्या लागतात (GitHub secrets `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`). तोपर्यंत APK ऑफलाइन चाचणी मोडमध्येच राहतो.
