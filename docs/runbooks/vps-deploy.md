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

## ५. सुरू करा
```
docker compose up -d --build
docker compose ps
curl https://api.तुमचे-डोमेन.com/health/live
```
पहिल्यांदा ५–१० मिनिटे लागतात. `{"status":"ok",...}` दिसले की API चालू आहे. अडल्यास: `docker compose logs --tail 100 api`.

## ६. नंतर अपडेट
```
cd /opt/bagmitra && git pull && cd deploy && docker compose up -d --build
```
टेबलचे बदल (migration) प्रत्येक सुरुवातीला आपोआप होतात.

## ७. बॅकअप
- **Supabase चा डेटाबेस वापरत असाल तर:** बॅकअप तिथल्या प्लॅननुसार (मोफत प्लॅनमध्ये मर्यादित). महत्त्वाचा डेटा असेल तर Settings → Database → Backups तपासा.
- **याच सर्व्हरवरचा डेटाबेस** (`docker compose --profile localdb up -d`) वापरल्यास बॅकअप तुमची जबाबदारी: रोज `docker compose exec -T db pg_dump -U postgres bagmitra | gzip > /root/bagmitra-$(date +%F).sql.gz` (cron) आणि फाइल दुसरीकडे कॉपी करा.

## ८. अॅपला जोडणे
API चालू झाले की test APK build ला API पत्ता (`API_BASE_URL=https://api.तुमचे-डोमेन.com`) आणि Supabase चाव्या द्याव्या लागतात (GitHub secrets `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`). तोपर्यंत APK ऑफलाइन चाचणी मोडमध्येच राहतो.
