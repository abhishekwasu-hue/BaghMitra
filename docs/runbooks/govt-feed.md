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
with `document_type` `pdf` or `html`; only its SHA-256 and size are kept (QG1).
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

## 4. Review and publish
- Queue: `GET /v1/admin/feed/items` (default `status=in_review`); detail with texts, card,
  targets, output-check issues and the append-only event trail: `GET /v1/admin/feed/items/{id}`.
- Output check: every number, amount (₹, lakh, crore), date and scheme name in titles,
  summaries, card fields and the deadline/validity dates must appear in the source text.
  Mismatches show in `check_issues`; fix the text (`PUT .../texts/{en|mr|hi}`, `PUT .../card`,
  `PUT .../targets`) or approve with `{"accept_check_issues": true, "comment": "why"}`.
- `POST .../approve`, then `POST .../publish`. Publishing is refused without an approval after
  the last change, without English text, for an official item without a document hash, or
  after `valid_to`. Any edit sends a published item back to review.
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
