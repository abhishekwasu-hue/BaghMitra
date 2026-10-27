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
`GET /v1/admin/feed/sources` lists the registry (addendum §3, seeded by migration 0019). Every
source starts with `terms_status: unknown`, so **nothing is fetched automatically**
(OPEN_QUESTIONS QG1). After reading a source's terms of use and robots.txt:
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
  `PUT .../targets`) or approve with `{"accept_check_issues": true, "comment": "why"}`.
- `POST .../approve`, then `POST .../publish`. Publishing is refused without an approval after
  the last change, without English text, for an official item without a document hash, or
  after `valid_to`. Any edit sends a published item back to review. Publishing writes the item's
  dates to `feed_deadlines`: `deadline` → apply_by, `valid_from` → window_open, `valid_to` →
  window_close, `payment_date` (optional upload field, output-checked like the others) → payment.
- Superseded GR: `POST .../withdraw {"reason": "...", "replaced_by_id": "<new item>"}`; the app
  shows "Replaced by …". Expired schemes (validity or deadline passed) are never listed.

## 5. AI draft (optional, off by default)
Set `FEED_AI_API_KEY` in the VPS `.env` (never in git or chat) and restart. Models:
`FEED_CLASSIFY_MODEL` (default `claude-haiku-5-5`), `FEED_SUMMARISE_MODEL` (default
`claude-sonnet-5-5`). `POST /v1/admin/feed/items/{id}/ai-draft` classifies the stored text;
an irrelevant document moves to `draft`; a relevant one gets an English title/summary (and a
new scheme-card version) written "quote or `not_stated`", then the output check runs. It is a
draft for review only: it never publishes. Paid calls; without the key the endpoint answers 503.

## 6. App
`GET /v1/feed?lang=en|mr|hi&type=official|scheme|deadline|news&district=&crop=` (signed in).

## 7. Farmer state and push settings (G2)
- `GET|PUT /v1/me/feed-preferences`: quiet hours (India time "HH:MM", default 21:00–07:00),
  `weekly_cap` (default 3 alert pushes per rolling 7 days, hard, QG4), `opted_out`
  (`deadline`, `payment`, `window_open`), `digest_weekly` (default on).
- `POST /v1/feed/{id}/seen | /dismiss | /remind`; `GET /v1/feed` items carry `seen`.
  Dismiss stops pushes for the item; "remind" asks for its date reminders even if the item is
  not matched to the farmer's profile (refused for a withdrawn item or one without a date).

## 8. Alert job (owner runs it; deploy/deploy.sh is unchanged)
```
python -m bagmitra_api.feed.alert_job      # prints a JSON summary, exit 1 if pushes failed
```
Per matched farmer and published item date: reminders at T-7 / T-2 / T-0 (apply_by,
window_close), one push on a payment / window-open date (up to 2 days late), each item +
stage once; withdrawn or expired items cancel what was pending; quiet hours hold a push until
their end; the weekly digest lists new items for the farmer from the last 7 days. Text: title,
"Last date: …", "Check the official GR/portal before acting." in the farmer's language
(English fallback). Until the FCM sender exists (Q32) the summary says
`"skipped_reason": "no push sender configured (FCM credentials)"` and nothing is stamped.

Suggested cron on the VPS (twice a day, outside the default quiet hours; the server clock is
UTC, so 03:17 and 11:47 UTC are 08:47 and 17:17 India time), with `crontab -e`:
```
17 3 * * *  cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.feed.alert_job >> /var/log/bagmitra-feed-alerts.log 2>&1
47 11 * * * cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.feed.alert_job >> /var/log/bagmitra-feed-alerts.log 2>&1
```
Same layout as docs/runbooks/weather-pull.md. To stop: delete the lines. Migration
`0020` must be applied first (it backfills `feed_deadlines` for items already published).
