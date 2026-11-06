# Admin web (`/admin/`) — production मध्ये वापरणे (OPS-02)

Feed, KB आणि बाजारभाव admin आता ब्राउझरमध्ये `https://<API_DOMAIN>/admin/` वर उघडतात. हे पान
API च स्वतः देते (तोच domain), त्यामुळे CORS बदलायची गरज नाही (`CORS_ORIGINS` रिकामेच राहू द्या).
लॉगिन Supabase (email + password) ने होते आणि प्रत्येक admin API call वर API स्वतः role तपासते
(`feed_admin`, `kb_admin`, `market_admin` ...). पान उघडता आले तरी role नसेल तर काहीही बदलता येत नाही.

## १. हे कसे चालते (थोडक्यात)
- GitHub वरील **Admin web** workflow (`.github/workflows/admin-web.yml`) "BagMitra App" checks
  पास झाल्यावर (किंवा हाताने Run केल्यावर) `app/lib/main_admin.dart` चे web build बनवतो आणि ते
  `admin-web-build` branch वर एकाच commit मध्ये ठेवतो (force-push; इतिहास वाढत नाही).
- `deploy/deploy.sh` तो branch server च्या read-only deploy key ने fetch करतो आणि
  `deploy/admin-web/` मध्ये उघडतो. ते फोल्डर API container मध्ये read-only जोडलेले आहे
  (`deploy/docker-compose.yml`, `ADMIN_WEB_DIR=/srv/admin-web`).
- build मध्ये कोणतीही key / पत्ता नाही. पान उघडल्यावर ते `/admin/config.json` मागते; API तिथे
  `.env` मधील `ADMIN_WEB_SUPABASE_URL` आणि `ADMIN_WEB_SUPABASE_ANON_KEY` देते. ही दोन्ही
  सार्वजनिक मूल्ये आहेत (anon / publishable key प्रत्येक app build मध्येही असते).
  **service role key कधीही `.env` च्या या ओळींत किंवा पानात नाही.**
- branch अजून नसेल किंवा build नसेल तर `/admin/` 404 देते; बाकी API नेहमीसारखे चालते.
- Server वर Flutter build का नाही: या build ला 4 vCPU मशीनवर ~70 सेकंद आणि काही GB RAM लागली,
  Flutter SDK image अनेक GB आहे; 2-vCPU VPS वर ते API च्या शेजारी चालवणे धोक्याचे. CI build
  ~44 MB चे आहे (त्यापैकी ~37 MB renderer फाइल्स, CDN शिवाय) आणि API image चा आकार बदलत नाही.

## २. एकदाच: GitHub
1. GitHub → **Actions → Admin web → Run workflow** (main). हिरवे झाल्यावर `admin-web-build`
   branch दिसतो. पुढे app मध्ये बदल main वर आला की तो आपोआप पुन्हा बनतो.
2. जर repository मध्ये "सर्व branches" साठी protection rule असेल तर `admin-web-build` ला
   GitHub Actions चे force-push चालू द्या (main चा rule बदलू नका).

## ३. एकदाच: Supabase
1. **Email login चालू:** Authentication → Sign In / Providers → **Email** enabled.
2. **Staff खाते:** Authentication → Users → **Add user → Create new user**: तुमचा email आणि
   मजबूत password, "Auto Confirm User" ✓. (स्वतःहून sign-up ने role मिळत नाही.)
3. **Redirect URL:** Authentication → **URL Configuration → Redirect URLs** मध्ये जोडा:
   `https://<API_DOMAIN>/admin/`
   - email + password लॉगिनला redirect लागत नाही (`signInWithPassword`); ही ओळ password reset /
     invite email मधील link admin पानावर परत यावी म्हणून आहे.
   - **Site URL** बदलू नका (फोन app चे लॉगिन त्यावर अवलंबून असू शकते); आधीची
     `app.bagmitra.bagmitra://login-callback` ओळ तशीच ठेवा.
4. **दोन मूल्ये लिहून ठेवा** (Project Settings → API): Project URL
   (`https://<ref>.supabase.co`) आणि **anon / publishable** key. आणि role देण्यासाठी
   **service_role / secret** key — ती फक्त खालील block मध्ये टाइप करायची, कुठेही साठवायची नाही.

## ४. एकदाच: VPS वर एक block
`<...>` भरून हा पूर्ण block एकदम paste करा. शेवटचा prompt service role key मागतो (टाइप करताना
दिसत नाही, history मध्ये जात नाही, script ती छापत नाही).

```bash
cd /opt/bagmitra
grep -q '^ADMIN_WEB_SUPABASE_URL=' deploy/.env || printf '\nADMIN_WEB_SUPABASE_URL=%s\nADMIN_WEB_SUPABASE_ANON_KEY=%s\n' 'https://<ref>.supabase.co' '<anon-key>' >> deploy/.env
bash deploy/deploy.sh
cd /opt/bagmitra/deploy
read -rsp 'Supabase service role key: ' SUPABASE_SERVICE_ROLE_KEY; echo; export SUPABASE_SERVICE_ROLE_KEY
docker compose exec -T -e SUPABASE_SERVICE_ROLE_KEY api python -m bagmitra_api.auth.grant_roles --supabase-url 'https://<ref>.supabase.co' --email '<तुमचा-email>'
unset SUPABASE_SERVICE_ROLE_KEY
curl -s -o /dev/null -w 'admin page: %{http_code}\n' "https://$(grep '^API_DOMAIN=' .env | cut -d= -f2)/admin/"
```

अपेक्षित: deploy मध्ये `admin web: Admin web build of <sha>`, script मध्ये
`roles [] -> ['feed_admin', 'kb_admin', 'market_admin']`, आणि `admin page: 200`.
Migration: नाही. मागे जाणे: `bash deploy/deploy.sh --revert` (admin पान नवीनतम build वरच राहते).

## ५. role देणे / तपासणे (script)
`python -m bagmitra_api.auth.grant_roles` (`api/src/bagmitra_api/auth/grant_roles.py`):
- `--email` (आवश्यक), `--supabase-url` (किंवा `SUPABASE_URL` env), `--roles` (comma ने;
  default `feed_admin,market_admin,kb_admin`; फक्त API ओळखते ते: `billing_admin`, `feed_admin`,
  `kb_admin`, `kb_reviewer`, `market_admin`), `--dry-run` (फक्त बदल दाखवते).
- key फक्त `SUPABASE_SERVICE_ROLE_KEY` env मधून (argument नाही). जुनी JWT `service_role` key
  आणि नवी `sb_secret_...` key दोन्ही पाठवण्याची सोय आहे; खऱ्या Supabase वर हे फक्त वरील block
  ने तपासले जाईल (repo च्या tests मध्ये mocked HTTP).
- आधीचे roles आणि `app_metadata` मधील इतर keys तशाच राहतात; पुन्हा चालवले तरी काही बिघडत नाही
  ("nothing changed").
- role काढणे: `--remove --roles <role>` (खाली §५अ). `--remove` ला `--roles` आवश्यक आहे.
- role दिल्यावर / काढल्यावर admin पानात **Sign out करून पुन्हा Sign in** करा. जुना access token
  संपेपर्यंत (Supabase JWT expiry) जुने roles चालू राहतात (audit LG-07).

## ५अ. Staff roles: कोणते आहेत, देणे, काढणे (LG-07)

**कोणते roles.** Role हे Supabase खात्याच्या `app_metadata.roles` मध्ये असतात. ते फक्त service role key
नेच बदलता येतात; ॲपमध्ये लॉगिन करून कोणालाही role मिळत नाही. API प्रत्येक admin call वर role तपासते
(`require_role`, `api/src/bagmitra_api/routers/admin_*.py`). Role नसेल तर उत्तर `403`.

| Role | काय करू शकतो |
|---|---|
| `feed_admin` | सरकारी संदेश (Govt feed): GR / बातमी टाकणे, मजकूर, तारखा, लक्ष्य शेतकरी, approve, publish, withdraw |
| `kb_admin` | माहिती कार्ड (KB): स्रोत दस्तऐवज टाकणे, import, कार्ड publish करणे, KB alerts सोडवणे |
| `kb_reviewer` | KB कार्डचे तज्ज्ञ परीक्षण. सोबत `app_metadata.reviewer_role` = `agronomist`, `plant_pathologist` किंवा `entomologist` हवे; ते नसेल तर review ला `403` (हे script देत नाही: supabase-setup.md मधील `PUT /auth/v1/admin/users/<id>` पद्धत) |
| `market_admin` | Agmarknet वर नसलेला बाजारभाव हाताने भरणे (`market-prices.md`) |
| `billing_admin` | प्लॅन व सदस्यता (billing) पाहणे, प्लॅन बदलणे, खात्याला सुविधा देणे / परत घेणे (grants) |

**देणे.** §४ चा block, फक्त `--roles` बदलून (उदा. `--roles market_admin`). आधीचे roles तसेच राहतात.

**काढणे.** तोच block, शेवटी `--remove --roles <role>` जोडून:

```bash
cd /opt/bagmitra/deploy
read -rsp 'Supabase service role key: ' SUPABASE_SERVICE_ROLE_KEY; echo; export SUPABASE_SERVICE_ROLE_KEY
docker compose exec -T -e SUPABASE_SERVICE_ROLE_KEY api python -m bagmitra_api.auth.grant_roles --supabase-url 'https://<ref>.supabase.co' --email '<त्या-व्यक्तीचा-email>' --remove --roles '<role>'
unset SUPABASE_SERVICE_ROLE_KEY
```

अपेक्षित: `roles ['feed_admin', 'kb_admin'] -> ['feed_admin']` असे. फक्त नाव दिलेले role जातात, बाकीचे
roles आणि `app_metadata` मधील इतर keys राहतात. आधी पाहायचे असेल तर शेवटी `--dry-run` जोडा (काही लिहीत नाही).

**बदल कधी लागू होतो (token).** Role access token मध्ये असतो. Token लॉगिनच्या वेळी (आणि ॲप / पान तो
आपोआप refresh करते तेव्हा) बनतो. म्हणून:
- role दिल्यावर: त्या व्यक्तीने admin पानात **Sign out → पुन्हा Sign in** करावे; तेव्हाच नवा role चालतो.
- role काढल्यावर: जुना token संपेपर्यंत (Supabase → Authentication मधील JWT expiry; Supabase चा
  default 1 तास, या project चे खरे मूल्य तिथेच पाहा) तो role चालू राहू शकतो. त्यानंतरचा नवा token
  role शिवाय येतो.
- कोणाला कोणता role कधी दिला / काढला याची नोंद script ठेवत नाही; वरील block ची output (`roles … -> …`)
  तारखेसह स्वतःच्या नोंदवहीत ठेवा.

## ६. तपासणी
- `https://<API_DOMAIN>/admin/` → लॉगिन पान; role असलेल्या खात्याने लॉगिन → Govt feed / KB विभाग.
- पान "demo" सारखे दिसले (Supabase नाही असा संदेश): `.env` मधील दोन `ADMIN_WEB_...` ओळी तपासा,
  मग `bash deploy/deploy.sh`.
- `/admin/` 404: `admin-web-build` branch आहे का (§२) आणि deploy log मध्ये `admin web:` ओळ आली का.
