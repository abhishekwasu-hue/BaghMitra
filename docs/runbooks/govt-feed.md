# Government feed (Sarkari Sandesh): sources, manual GR upload, review and AI

Addendum v1.4 G0/G1 (server). Information, not advice: every feed response ends with
"Check the official GR/portal before acting." Nothing reaches growers without a person
approving it.

## 1. Give someone the `feed_admin` role
Roles live in Supabase **`app_metadata`** (server-set; signing in alone grants nothing). In the
Supabase dashboard → Authentication → the user → `app_metadata`, or with the service role:
```json
{"roles": ["feed_admin"]}
```
Keep any roles already there (e.g. `["kb_admin", "feed_admin"]`). The user signs out and in
again to get a token with the new role.

## 2. Sources and terms
`GET /v1/admin/feed/sources` lists the registry (addendum §3, seeded by migration 0019). A
source starts with `terms_status: unknown`, so **nothing is fetched automatically**
(OPEN_QUESTIONS QG1), unless the seed records the owner's decision: Mahasamvad (Q129) and, since
2026-11-12, the official portals and a few agriculture news outlets (Q145, §14; a deploy updates
rows still `unknown`, never an admin's own decision). After reading a source's terms of use and robots.txt:
```
PUT /v1/admin/feed/sources/mh_gr_portal/terms
{"terms_status": "allowed", "notes": "ToS read 2026-11-02: listing + link allowed"}
```
`disallowed` stops fetching for good; setting the terms again also clears a recorded
`fetch_failed`, so the next run tries once more. A blocked fetch (404/403/robots) is recorded
once and never retried; upload by hand instead.

## 3. Upload a GR by hand
`POST /v1/admin/feed/items` (JSON). The document is optional, base64 in `document_base64`
with `document_type` `pdf` or `html`; only its SHA-256 and size are kept (QG1). Without
`extracted_text` the server extracts the text itself (§3a).
```json
{"source_key": "mh_gr_portal", "type": "scheme", "published_at": "2026-10-26T00:00:00Z",
 "url": "https://gr.maharashtra.gov.in/...pdf", "external_id": "<GR unique code>",
 "gr_number": "<as printed>", "department": "Agriculture", "deadline": "2026-12-31",
 "extracted_text": "<text copied from the PDF>", "document_base64": "...", "document_type": "pdf",
 "texts": {"en": {"title": "...", "summary": "..."}, "mr": {"title": "...", "summary": "..."}},
 "card": {"amount": {"value": "₹1,00,000 per ha", "page": "p. 2"}},
 "targets": [{"district": "Nagpur", "crop": "santra", "min_ha": 1, "max_ha": 5}]}
```
Rules: types `gr | circular | scheme | alert | news`. `Official` trust only for a source with
tier `official`. **News** keeps headline + link + our own summary: no `extracted_text`, no
document, no card. Scheme cards: each stated field cites its page, otherwise `not_stated`.
Targets: empty fields mean "any"; matching says "may be eligible", never "will receive".

## 3a. Text extraction and OCR (QG2)
When a document is uploaded **without** `extracted_text`, the server reads it: a PDF's text
layer (`pypdf`, pages separated by a form feed) or an HTML page's visible text (scripts and
styles dropped). The result is judged: `ok`, `empty` (scanned PDF, no text layer) or `broken`
(legacy non-Unicode Marathi fonts such as Kruti Dev / Shree-Lipi: Latin garbage, private-use
or control characters, vowel signs out of order). Only `ok` text is stored as the item's text
(the source of the output check and of the AI draft). Text pasted by the admin always wins.

Everything is recorded in the item's `extracted` review event (`GET .../items/{id}` → events):
`method` (`pdf_text | html | none`), `quality`, `devanagari_ratio`, `pages`, `reason`, `used`
(`pdf_text | html | ocr | null`), the unused text (`text_layer`, or `ocr.text`) and `ocr`
(`confidence` 0–100, quality, or `error`). A missing / broken text shows as a check issue
`text_empty` / `text_broken` (low OCR confidence: `ocr_low_confidence`), so the item **stays in
review**: upload again with the text pasted, or approve with `accept_check_issues` and a comment.

OCR (off by default; local, free, nothing leaves the server) runs only for PDFs whose text is
broken or empty. To enable it on the VPS (Abhi runs the block; restart afterwards):
```
sudo apt install -y tesseract-ocr tesseract-ocr-mar poppler-utils
tesseract --list-langs | grep -x mar     # must print: mar
echo FEED_OCR_ENABLED=true >> .env       # then restart the API
```
If the API runs in Docker, the image needs the same packages: uncomment the `RUN apt-get …`
line in `api/Dockerfile` and rebuild. Without `tesseract`, the `mar` language or `pdftoppm`,
OCR stays off (logged `feed.ocr.not_installed` / `feed.ocr.language_missing`). Settings:
`FEED_OCR_LANG` (`mar`), `FEED_OCR_DPI` (300), `FEED_OCR_MAX_PAGES` (40),
`FEED_OCR_TIMEOUT_SECONDS` (120), `FEED_OCR_MIN_CONFIDENCE` (70). Failures OCR cannot fix go
to the reviewer (a vision model is not wired; QG2 default).

## 4. Review and publish
- Queue: `GET /v1/admin/feed/items` (default `status=in_review`); detail with texts, card,
  targets, output-check issues and the append-only event trail: `GET /v1/admin/feed/items/{id}`.
- Output check: every number, amount (₹, lakh, crore), date and scheme name in titles,
  summaries, card fields and the deadline/validity dates must appear in the source text.
  Mismatches show in `check_issues`; fix the text (`PUT .../texts/{en|mr|hi}`, `PUT .../card`,
  `PUT .../dates`, `PUT .../targets`; see §4a) or approve with `{"accept_check_issues": true, "comment": "why"}`.
- `POST .../approve`, then `POST .../publish`. Publishing is refused without an approval after
  the last change, without English text, for an official item without a document hash, or
  after `valid_to`. Any edit sends a published item back to review. Publishing writes the item's
  dates to `feed_deadlines`: `deadline` → apply_by, `valid_from` → window_open, `valid_to` →
  window_close, `payment_date` (optional upload field, output-checked like the others) → payment.
- Superseded GR: `POST .../withdraw {"reason": "...", "replaced_by_id": "<new item>"}`; the app
  shows "Replaced by …". Expired schemes (validity or deadline passed) are never listed.

## 4a. Review in the admin app
Production: `https://<API_DOMAIN>/admin/` ([admin-web.md](admin-web.md)); locally
`flutter run -d chrome -t lib/main_admin.dart` (same defines as the KB admin). Sign in with a
staff account whose `app_metadata.roles` contains `feed_admin` (§1); the **Govt feed** section is
shown only then (the API still checks the role on every call). Three tabs:
- **Review queue**: items by status (In review, Draft, Published, Withdrawn) with type and trust
  badges and the open check-issue count. Tap an item for the detail page: source link, status
  and badges, output-check issues, extracted text (whether text is stored; method / quality /
  pages from the `extracted` event and the unused text layer or OCR text), en / mr / hi title +
  2-line summary editors (Save per language), dates, the scheme card, targets (district / crop /
  min-max ha; empty means any) and the history.
  - **Extracted text**: below the extraction result the full stored text (`extracted_text` of
    `GET .../items/{id}`, the text the output check reads) in a scrollable box. The API returns
    at most the first 200 KB (UTF-8, `MAX_DETAIL_TEXT_BYTES`); a longer text is cut on a
    character boundary with `extracted_text_truncated: true` and the page says so.
  - **Dates**: last date / payment / valid from / valid to, each with a date picker and a clear
    button; **Save dates** sends all four (`PUT .../items/{id}/dates`; a missing or `null` date
    is cleared, `valid_from` after `valid_to` is refused with `invalid_dates`). The dates are
    output-checked against the stored text like on upload (a date not in the text is a check
    issue `where: deadline|payment_date|valid_from|valid_to`). A change clears the approval and
    records an `edited` event with the old / new dates; on a **published** item it also sends
    the item back to **In review** (event detail `reopened: true`) so it leaves the farmer feed
    until it is approved and published again, and publishing rebuilds its `feed_deadlines` rows
    from the new dates (a cleared date's reminder row is removed). Sending the stored dates
    again changes nothing. Withdrawn items: 409.
  - **Scheme card** (scheme items): one row per field (`scheme_name`, `who_benefits`,
    `eligibility`, `documents`, `how_to_apply`, `deadline`, `amount`, `gr_number`, `gr_date`,
    plus any other stored field): the value as written in the document and its page (e.g.
    `p. 2`), or **Not stated** (`not_stated`, no page). Empty rows are left out; **Save card**
    writes a new card version (`PUT .../card`) and the output check runs (a stated value
    without a page is a `missing_page` issue).
  Actions: **Approve** (with open issues a dialog asks to accept them and needs a comment),
  **Publish** (the refusal reason is shown), **Withdraw** (reason + optional replacement picked
  from published / in-review items), **AI draft** ("AI not configured" when the API answers 503).
- **Upload**: **Choose document** picks the GR as `.pdf`, `.html` or `.htm` (up to 20 MB, the
  server's `MAX_DOCUMENT_BYTES`); it is sent base64 in `document_base64` with `document_type`, so
  the server keeps its hash and extracts the text (§3a). Pasting the text is still possible and
  wins over extraction. Also: official URL, source key, type, published date, external id / GR
  number, department, deadline / payment / validity dates (YYYY-MM-DD), English title and
  summary. After sending, the page shows the extraction result (method, quality, unused text)
  and the check issues; **Open item** goes to the detail page. Without a document no hash is
  kept, so an official item cannot be published from a paste-only upload.
- **Feed sources**: each source with its terms status; pick Unknown / Allowed / Disallowed, write
  what you read in the note and Save (same as `PUT .../terms`, §2).

## 5. AI draft (optional, off by default)
Set `FEED_AI_API_KEY` in the VPS `.env` (never in git or chat) and restart. Models:
`FEED_CLASSIFY_MODEL` (default `claude-haiku-5-5`), `FEED_SUMMARISE_MODEL` (default
`claude-sonnet-5-5`). `POST /v1/admin/feed/items/{id}/ai-draft` classifies the stored text;
an irrelevant document moves to `draft`; a relevant one gets an English title/summary (and a
new scheme-card version) written "quote or `not_stated`", then the output check runs. It is a
draft for review only: it never publishes. Paid calls; without the key the endpoint answers 503.

## 6. App
`GET /v1/feed?lang=en|mr|hi&type=official|scheme|deadline|news|knowledge&district=&crop=` (signed in).
`knowledge` lists the ज्ञान लेख (§13); `official` and `news` leave them out.
News items carry `thread_id` and the answer lists their `threads` (§12);
`GET /v1/feed/threads/{id}?lang=` returns one topic, oldest first.

## 7. Farmer state and push settings (G2)
- `GET|PUT /v1/me/feed-preferences`: quiet hours (India time "HH:MM", default 21:00–07:00),
  `weekly_cap` (default 3 alert pushes per rolling 7 days, hard, QG4), `opted_out`
  (`deadline`, `payment`, `window_open`), `digest_weekly` (default on).
- `POST /v1/feed/{id}/seen | /dismiss | /remind`; `GET /v1/feed` items carry `seen`.
  Dismiss stops pushes for the item; "remind" asks for its date reminders even if the item is
  not matched to the farmer's profile (refused for a withdrawn item or one without a date).

## 8. Alert job (cron added by deploy/deploy.sh unless `CRON_FEED_ALERTS=off`)
```
python -m bagmitra_api.feed.alert_job      # prints a JSON summary, exit 1 if pushes failed
```
Per matched farmer and published item date: reminders at T-7 / T-2 / T-0 (apply_by,
window_close), one push on a payment / window-open date (up to 2 days late), each item +
stage once; withdrawn or expired items cancel what was pending; quiet hours hold a push until
their end; the weekly digest lists new items for the farmer from the last 7 days. Text: title,
"Last date: …", "Check the official GR/portal before acting." in the farmer's language
(English fallback). Pushes go through FCM once its credentials are set (runbook
`push-notifications.md`); until then the summary says
`"skipped_reason": "no push sender configured (FCM credentials)"` and nothing is stamped.

Cron on the VPS: on by default; `bash deploy/deploy.sh` adds it (set `CRON_FEED_ALERTS=off` in `deploy/.env` to stop); it
adds this line once (twice a day, outside the default quiet hours; the server clock is UTC, so
03:17 and 11:17 UTC are 08:47 and 16:47 India time):
```
17 3,11 * * * cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.feed.alert_job >> /var/log/bagmitra-feed-alerts.log 2>&1
```
Same layout as docs/runbooks/weather-pull.md. To stop: `CRON_FEED_ALERTS=off` and deploy again (the line is removed). Migration
`0020` must be applied first (it backfills `feed_deadlines` for items already published).

## 9. News headlines (G3; OPEN_QUESTIONS QG5)
Only sources with tier `news` **and** `terms_status: allowed` are read; everything else is
reported `refused` and nothing is requested. Seeded: `pib_agriculture_news` (PIB RSS; terms
`allowed` since the owner's approval of 2026-11-12, Q145) and the agriculture outlets of §14;
RSS 2.0, Atom and Google news sitemaps are read. To stop one source:
`PUT /v1/admin/feed/sources/<key>/terms {"terms_status": "disallowed", "notes": "..."}`.
```
python -m bagmitra_api.feed.news_job       # JSON summary: per source status / added / error
```
The run also registers seeded sources missing from an older database (terms `unknown`). Same
politeness as the GR adapter: robots.txt checked, requests spaced by
`FEED_FETCH_MIN_INTERVAL_SECONDS`, one try; a blocked, failing or unsafe feed (DTD / entity
declarations, over 2 MB, not RSS / Atom) is recorded `fetch_failed` once and skipped until the
terms are set again. Stored per headline: title, link, date, source; never the article text or
images. Each headline is an `in_review` news item: write **our own** two-line summary with
`PUT .../items/{id}/texts/en` (and `mr`, `hi`), then approve and publish; the app shows it as
"News — not official". Duplicates (same guid or link) are not added again.

Cron (every 6 hours, only after the terms are recorded): on by default (`CRON_FEED_NEWS=off` stops it) in
`deploy/.env` and run `bash deploy/deploy.sh`; it adds (01:23, 07:23, 13:23, 19:23 UTC):
```
23 1,7,13,19 * * * cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.feed.news_job >> /var/log/bagmitra-feed-news.log 2>&1
```
No migration is needed. To stop: `CRON_FEED_NEWS=off` and deploy again (or set the source's terms to `disallowed`).

## 10. "Check this message" (G3)
`POST /v1/feed/check?lang=en|mr|hi {"text": "<pasted forward, up to 4000 characters>"}`
(signed in) answers `official_match`, `possible_match` or `no_official_match` with up to three
published official items (`id`, `title`, `gr_number`, `published_at`, `url`, `score`) and a
note that always points to the official portal; it never calls a message fake. Rules
(`feed/check.py`): GR number / unique code, title words (close spellings count), dates,
amounts (₹ / lakh), scheme names; an amount that differs is never an official match. The text
is not stored; the log keeps only its length and the verdict. Limit: `FEED_CHECK_RATE_LIMIT`
checks (default 20) per user per `FEED_CHECK_RATE_WINDOW_SECONDS` (3600), in memory (HTTP 429).

## 11. AI news articles (spec v1.6, owner Q127)
With `FEED_AI_API_KEY` set in the VPS `.env`, the news cron (§9) also writes an article for each new
headline of a source whose terms are `allowed`: it reads the page (robots, spacing, 2 MB limit),
the AI writes the article in mr / hi / en (sections, facts table, bar / pie charts) and the item is
**published without review** when every check passes (`feed/article.py`), otherwise it is `held`
with the reasons (admin web, status filter "held"). The page text is never stored (hash and size only).

| `.env` | Default | Meaning |
|---|---|---|
| `FEED_AI_DAILY_ITEMS` | 30 | Articles requested from the model per UTC day |
| `FEED_AUTO_PUBLISH` | true | `false`: checked articles wait for a `feed_admin` approval |
| `FEED_ARTICLE_MAX_TOKENS` | 16000 | Model output limit per article set (thinking included) |
| `FEED_ARTICLE_TIMEOUT_SECONDS` | 300 | How long one article request may take |

Log: `/var/log/bagmitra-feed-news.log` (second JSON line: published / held / drafted / retry).
Set a monthly spend limit in the Anthropic console.

**Re-check held articles** (owner 2026-11-09; since 2026-11-10 every scheduled news run does this by itself, third JSON line `recheck`): checks every held news
article again against its page and publishes those that now pass. It uses the saved article (no model
call, no cost) and fetches each page once more; items held because the page could not be read are left
as they are. One-off, safe to repeat:
```
cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.feed.recheck_held
```
It prints `{"published": …, "held": …, "retry": …}`; reasons still failing are in admin web (status "held").

## 12. News topic threads (owner Q139)
Mahasamvad publishes one decision from many districts under different links, so related news is
grouped: each **published news item** joins a topic thread (`feed_threads`, migration `0046`) and
the app shows one card per topic ("N बातम्या") that opens as a dated timeline, oldest first. GR,
circular, scheme and alert items are not threaded.

Rule (`feed/threads.py`; conservative, a wrong merge is worse than a duplicate):
- candidates: topics whose latest report is within **30 days** of the new item and that share a
  number (not a year) or two word stems with its checked title / summary; at most 20, newest first;
- no candidate: a new topic, **no model call**;
- otherwise one small structured-output call to `FEED_CLASSIFY_MODEL` (low effort): "same event /
  decision as topic Tn, or new". Only a clear match joins; "new", an unknown answer and every
  model error start a new topic (`threaded` review event: `reason`, `candidates`, `joined`);
- the topic's title / summary are copied from its latest report's checked text, never new text.

**No manual step is needed.** Every scheduled news run (§9), after the article and recheck steps,
threads published news that has no topic yet, oldest first, **at most 50 items per run**
(`THREADS_PER_RUN`). So after deploying 0046 the already published news is threaded by the next
runs on its own (50 per run, every 6 hours), with a bounded cost per run; afterwards each run
threads its new items. Fourth JSON line in `/var/log/bagmitra-feed-news.log`:
`{"threads": {"joined", "new", "model_calls", "ai_errors", "skipped_reason"}}`. Without
`FEED_AI_API_KEY` nothing is threaded (single cards, as before) and the first run with the key
catches up.

Optional, manual use only (threads everything without a topic in one go, no cap; idempotent):
`python -m bagmitra_api.feed.thread_backfill` inside the API container.
A wrong merge is undone in the database only (no admin button yet, OPEN_QUESTIONS Q139): insert a
new `feed_threads` row (title / summary copied from the item's text) and point the item's
`feed_items.thread_id` at it. Setting it to NULL would let the next run ask the model again.

## 13. Knowledge articles, ज्ञान लेख (owner 2026-11-11, OPEN_QUESTIONS Q141)
Owner: farmers should become truly knowledgeable; articles come from the situation, **no fixed
weekly count and no cap**; **no newspaper content** (not even headlines). Feed items of type
`knowledge`, chip "ज्ञान" in the app; never threaded into news topics.

**Triggers** (daily job `python -m bagmitra_api.feed.knowledge`, `feed/knowledge.py`):
- (a) risk: a `plot_risk_alerts` row of a rule with a matching practice card, first day at most
  14 days old or in the forecast: `psylla_degree_days` → card `psylla`, `heat_fruit_drop` →
  `heat_drop`, `high_humidity` → `powdery_mildew` + `anthracnose`. Storm rules (claim kit) and
  `cold_wave` have no card and write nothing. The topic stays current until 14 days after the
  latest alert day.
- (b) bahar stage: a stage window of `bahar/seed_data/stage_templates.json` that **starts within the
  next 14 days**: `stress_start` → `bahar_irrigation`; `irrigation_restart` → `bahar_irrigation` +
  `nutrition`; `flowering` → `fruit_drop` + `thrips`; `fruit_set` → `fruit_drop` + `nutrition`;
  `harvest` → `harvest`. One topic per crop, bahar and stage; current until the window ends.
- (c) scheme: an official, published `scheme` / `gr` item with stored text, published in the last
  30 days and not past its deadline / validity: a "who may be eligible / how to apply" explainer
  from that item's own checked text only (nothing is fetched).

**Input** (the only material the model gets): for (a) / (b) the points of those card sections in
`kb/seed_data/practice_cards.json` (a copy of `app/assets/config/practice_cards.json`; a test keeps
them equal: change the app's file, then copy) plus passages of the sources each point cites, read
like the card check (`card_check.fetch_text`, `passages_for`, at most 8,000 characters per source).
Left out: a point citing a newspaper (publisher Agrowon), a point whose sources cannot be read, a
point with a number not in its cited text. The input is cut to `FEED_AI_MAX_SOURCE_CHARS`.

**Writing and checks**: one structured-output call to `FEED_SUMMARISE_MODEL` (default
`claude-sonnet-5-5`, refusal fallback on): mr / hi / en, a title, one line, 4-8 short sections with
farmer-friendly headings, no product names or doses. The sources list and the card link are
attached by the job (never written by the model). `check_knowledge` (`feed/knowledge_article.py`)
holds the article (status `held`, check issues, `output_check_failed` event; admin web status
filter "held") when any number, amount or date is not in the input (`output_check`), a product
name from our label claims / restrictions / KB cards is not in the input, a phone / e-mail is not in
the input, or the languages state different amounts / dates. Otherwise it is published
(`FEED_AUTO_PUBLISH=false`: waits for approval). Trust `official` when every cited source is on a
`.gov.in` / `.nic.in` / `.ac.in` site (a scheme explainer: the item's trust), else `news`.

**Every run first re-checks held knowledge articles** against their stored input (no model call,
no fetch) and publishes those that now pass.

**Dedupe** (`feed_knowledge_runs`, migration `0048`, service-only): a topic is not written again
while its window is current or within 30 days of its last article, unless its input changed (the
card sections' texts / their source list, or the scheme item's text and titles); a still active
alert extends the window. Then the new article is published and the older one goes to `draft`
(event `superseded`). A model error (`retry`) or unreadable sources (`no_input`) do not count, so
the next run tries again. Safe to run twice a day (idempotent).

**Switches and cost**: off without `FEED_AI_API_KEY`. Kill switch `CRON_FEED_KNOWLEDGE=off` in
`deploy/.env`: deploy removes the cron line and the job itself writes nothing. Cron (added by
`deploy/deploy.sh`, daily after the weather pull):
```
11 2 * * * cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.feed.knowledge >> /var/log/bagmitra-feed-knowledge.log 2>&1
```
The log line is a JSON summary: `topics` (`key=outcome`), `published`, `held`, `review`,
`deduped`, `not_relevant`, `no_input`, `retry`, `recheck_published`, `skipped_reason`.
Estimated cost (estimate, not measured): about $0.15-0.25 per article on Sonnet 5.5 ($2 / $10 per
million tokens; about 15-25k input tokens and 8-15k output tokens with thinking for three
languages). Set a monthly spend limit in the Anthropic console.

Deploy note: `deploy.sh` now runs the pulled copy of itself after `git pull` (`--after-pull`, once,
guarded by `BAGMITRA_DEPLOY_REEXEC`), so a new cron line is added in the same deploy.

## 14. Official portals and agriculture news outlets (owner 2026-11-12, OPEN_QUESTIONS Q145)
Owner: "Build MahaDBT, PM-KISAN, PMFBY too; it need not be a government source — take it from
wherever it is available." And: "many farming articles appeared in the last month, on other
fruits too; find them." The seed (`feed/seed_data/sources.json`) records the decision with each
source's robots.txt result; a deploy carries it onto rows still `unknown` (an admin's own
`allowed` / `disallowed` is never overwritten). The terms gate itself is unchanged.

**How each source was checked:** from a GitHub runner, `card-sources` workflow, `raw: true`
(prints each address's status, robots.txt, feed / sitemap entry counts and date span, a page's
visible text and its document tables; fetched with the feed's own User-Agent). Recorded
2026-11-12; trimmed copies are the contract fixtures (`api/tests/fixtures/feed/*_recorded.*`).

| Key | Address read | Read as | robots.txt (2026-11-12) | Recorded |
|---|---|---|---|---|
| `mh_gr_portal` | gr.maharashtra.gov.in/1145/Government-Resolutions | server-rendered GR table (dept, title, unique code, date, PDF); farm departments only | allows (disallows /admin/, /private/, /tmp/) | 10 GRs of the day, none from a farm department |
| `mh_agri_commissionerate` | krishi.maharashtra.gov.in … ViewGr.aspx (GRs / standing orders) | server-rendered table (subject, date, PDF; no GR number) | none (redirects to an error page) | 5 GRs, newest 24-09-2026 (PKVY), PMFBY 2026-27, fruit-crop insurance 2026-27 |
| `mahadbt` | mahadbt.maharashtra.gov.in/Farmer/AgriLogin/AgriLogin | farmer scheme list (17 schemes, no dates) → each scheme page's "Government Resolution" PDF | none (404) | 17 schemes |
| `pm_kisan` | — | **not readable**: TLS chain incomplete (`CERTIFICATE_VERIFY_FAILED`), http:// times out; verification is never switched off | could not be read | — |
| `pmfby` | — | **not readable**: JavaScript-only app (empty `<div id="app">`); its GRs come through the Commissionerate's page | serves the app shell (no rules) | — |
| `pib_agriculture_news` | pib.gov.in RssMain (ModId=6) | RSS (redirects to the all-ministries Hindi feed, items undated) | serves an error page (no rules) | 20 items; the VPS got 403 earlier |
| `mahasamvad_news` | mahasamvad.in/feed/ (+ `?paged=N` backfill) | RSS (WordPress) | /wp-admin/ only (VPS, Q129) | 403 to the GitHub runner; readable from the VPS |
| `agrowon_mr` | agrowon.esakal.com/news_sitemap.xml (+ daily sitemaps) | news sitemap; web stories / videos skipped | allows (its listed sections skipped) | 57 links, 2026-11-10 → 11-12; daily sitemaps 22–68 links a day |
| `krishijagran_en` | krishijagran.com/feeds/rss | RSS | allows all but /api/ | 99 items, 2026-08-19 → 11-04 |
| `krishijagran_hi` | hindi.krishijagran.com/feeds/googlenews | news sitemap | allows all but /api/ | 50 links, 2026-10-30 → 11-12 |
| `kisantak_hi` | kisantak.in/rssfeeds/news-sitemap.xml | news sitemap | allows /rssfeeds/ | 5 links, 2026-11-11 → 11-12 |
| `businessline_agri` | thehindubusinessline.com/economy/agri-business/feeder/default.rss | RSS | allows (wildcard rules block search / fragments only) | 60 items, 2026-11-05 → 11-11 |
| `krishakjagat_hi` | krishakjagat.org/feed/ | — | **disallows** `*/feed/`: seeded `disallowed`, never fetched | — |

Not added: Krishi Jagran Marathi (`/feeds/rss` last item 2026-03-26: stale), Down To Earth (general
environment outlet, few farm items per day), BusinessLine / Kisan Tak / Krishi Jagran archives
(no titled sitemap or older feed pages; Krishi Jagran's news sitemap is 7 MB without titles).

**Robots** (`gr_portal.robots_allows`, all adapters): read as RFC 9309 — the groups naming our
agent, else the `*` groups merged; `*` and `$` wildcards; the longest matching rule wins, Allow
on a tie (the standard library's parser ignored wildcards, e.g. Krishak Jagat's `*/feed/`). An
HTML page served for /robots.txt has no rules.

**Official portals** (`feed/portal_job.py`, cron below): each official source whose terms are
`allowed` and that has a reader (`portal_list`, `rss`, `scheme_list`; `manual` = no reader, never
requested) is read; new listings of the last 30 days (MahaDBT's undated schemes: every new one,
dated by first sight) become `in_review` items, at most 100 per source and run. Then the AI step
(`feed/official_items.py`) per listing: the document (robots, spacing, 20 MB limit; SHA-256 and
size kept) → text (PDF text layer / HTML; scanned or legacy-font text holds the item for a
person) → classify (`gr | circular | scheme | alert`, categories) → irrelevant: `draft` → the
article set (mr / hi / en, `check_articles`) → a scheme: its card from the summariser (quote or
`not_stated`, page cited) → the output check (`run_output_check`: every number, date, amount and
scheme name in titles, summaries and card against the stored text). Any issue: `held`; otherwise
published (`FEED_AUTO_PUBLISH=false`: waits for approval). Trust `official` only for a document on
a `.gov.in` / `.nic.in` host. At most `FEED_AI_DAILY_ITEMS` attempts per UTC day (counted apart
from the news articles). The stored text also feeds the knowledge trigger (c) (§13).

**News outlets**: the news job (§9, §11) reads them like Mahasamvad: headline + link + date, then
**our own** checked article (the page text is never stored; no images). Relevance (owner
2026-11-12): items that change something for farmers **or** useful farming knowledge for
Maharashtra / Vidarbha farmers (all fruits — mango, banana, pomegranate, grapes, guava, custard
apple … — vegetables, soil, water, weather advisories, pests and diseases, markets,
post-harvest); politics, crime, entertainment stay out; the number / name checks are unchanged.
A dated entry more than 30 days older than its feed's newest entry is not added. Repeats across
outlets are grouped by the topic threads (§12).

**30-day backfill** (`feed/backfill.py`, migration `0053`: `feed_sources.backfill_done_at`,
`backfill_cursor`): on the scheduled runs themselves, once per source, no manual step. Mahasamvad:
older feed pages `?paged=2…15` [UV: not reachable from the runner; the first VPS run shows it];
Agrowon: one daily sitemap per day back 30 days, each new link's page read once for its own
`og:title` and publication time (`article:published_time` or JSON-LD `datePublished`; without
both it is skipped). At most 100 new items and 150 page reads per source and run; the cursor keeps
the last page / day read completely, so the next run continues. Done at the first missing,
empty or older page, or after the last day. Log: the news log's first JSON line, `backfill`.
The official lists take their last 30 days on the first run (their pages show no older items:
the GR portal's archive is an ASP.NET search form, not read).

Cron (on by default; `CRON_FEED_PORTALS=off` in `deploy/.env` removes the line and the job then
fetches nothing), twice a day before the 07:23 / 19:23 news runs (04:43, 16:43 UTC = 10:13, 22:13
IST); added by `deploy/deploy.sh` in the same deploy (it re-runs its pulled copy):
```
43 4,16 * * * cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.feed.portal_job >> /var/log/bagmitra-feed-portals.log 2>&1
```
The log line is a JSON summary: `sources` (per key: `ok | refused | no_reader | skipped |
fetch_failed | disallowed`, `added`, `error`), `added`, `official` (`published`, `held`,
`drafted`, `review`, `retry`, `skipped_reason`). Migration `0053` runs on the API start.

## 14a. Legacy-font official PDFs read by Claude (owner 2026-11-13, OPEN_QUESTIONS Q152)
Many GRs (MahaDBT's scheme PDFs among them) are typed in non-Unicode Marathi fonts (Kruti Dev,
Shree-Lipi …): their text layer is garbage and the listing was held `text_broken` ("almost no
Devanagari in a Marathi document"). Now the portal job (`feed/official_items.py`,
`feed/pdf_transcribe.py`) sends such a PDF to Claude itself — one Messages API request, the PDF as
a `document` block (base64, `application/pdf`) — asking for a faithful Unicode transcription of
the visible text only: no summary, no translation, nothing added; unreadable parts `[अस्पष्ट]`;
structured output `{text, pages_read, legible}`. Streamed (a long GR takes minutes).

- **The transcription is the item's text** (`feed_items.extracted_text`), with provenance: review
  event `pdf_transcribed` (`model`, `pages`, `pages_read`, `chars`, `devanagari_ratio`). Then the
  normal official path runs on it (classify → article set → scheme card → checks). **The "facts in
  the source" checks (`check_articles`, `run_output_check`) then run against the transcription,
  not against the PDF**: a figure the model misread and the writer copied passes the check. The
  admin web shows the stored text; compare with the PDF ("मूळ दस्तऐवज") when in doubt.
- **Not sent:** more than `FEED_PDF_TRANSCRIBE_MAX_PAGES` (default 30) pages or more than 20 MB;
  the item stays held, the issue text says "not sent for transcription: N pages …". A scanned PDF
  (`text_empty`, no text layer) is not sent either (unchanged).
- **One attempt per PDF.** Results in review events `pdf_transcribe` (`detail.result`): `ok`,
  `illegible` (the model says not legible, or the text is still not Marathi), `refused`, `cut_off`
  (longer than `FEED_PDF_TRANSCRIBE_MAX_TOKENS`), `unusable` (answer not in the asked shape),
  `skipped_large` — all final, never asked again; the item stays held with the reason in its
  issue text. Only `retry` (API unreachable: network, 5xx, overload) is asked again on the next
  run. A listing held `text_broken` before this step (the five MahaDBT items on the VPS) gets its
  one transcription on the next run. If the article model is unavailable after a transcription,
  the next run writes from the stored transcription (no second transcription, no new fetch).
  The held re-check (`recheck_held_official`, when merged) needs a stored text and saved
  articles, so it touches a transcribed item only after its article was written and costs no
  request; a listing held for its text is not picked by it.
- **Daily cap:** at most `FEED_PDF_TRANSCRIBE_DAILY` (default 10) requests per UTC day, counted
  from the `pdf_transcribe` events that made a request (all results except `skipped_large`);
  separate from `FEED_AI_DAILY_ITEMS`, which still counts the article attempt that follows. Over
  the cap the listing stays held ("waits for transcription") and is taken on a later day.
- **Model:** `FEED_PDF_TRANSCRIBE_MODEL` (empty = `FEED_SUMMARISE_MODEL`, Claude Sonnet 5.5),
  effort `low` (reading, not reasoning), the server-side refusal fallback on.
- **The PDF bytes are never stored** — only SHA-256 and size, as before; the request carries them
  to the API and nothing else keeps them.
- **Cost (estimate, not measured):** Anthropic's PDF-support docs: each page is sent as text and
  as an image, "typically 1,500–3,000 tokens" of text per page plus image tokens. Taking ~3,000–
  5,000 input and ~1,500–3,000 output tokens per page at Sonnet 5.5's $2 / $10 per million: a
  4-page GR ≈ $0.06–0.16; a 30-page PDF (the cap) ≈ $0.50–1.20. At the daily cap of 10 requests:
  ≈ $0.60–1.60 a day for 4-page GRs, at most ≈ $12 a day for ten 30-page PDFs. The real figure is
  the API usage on the Console after the first runs.
- **Job log:** the portal job's JSON line has `"pdf_transcribe": {"calls", "ok", "illegible",
  "skipped_large", "errors"}` (`errors`: refused / cut off / unusable / unreachable). No migration.
