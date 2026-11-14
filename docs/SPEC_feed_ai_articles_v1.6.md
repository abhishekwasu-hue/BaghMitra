# BagMitra — AI News Articles from Government Sources (Spec v1.6, addendum to v1.4)

Owner decisions 2026-11-09 (OPEN_QUESTIONS Q126, Q127): agriculture news of the Central and
Maharashtra governments is shown in the app; an AI (Claude, owner's API key `FEED_AI_API_KEY`)
writes each item as a **professional, data-rich news article** in Marathi, Hindi and English and
**publishes it without a human review**. Same standing rules as the main spec §0 and v1.4 §6
(neutral, factual, no political content, the source one tap away).

## 1. What changes from v1.4
| v1.4 | v1.6 |
|---|---|
| News: headline + link + our own 2-line summary written by a person | AI article: headline, standfirst, key points, sections, facts table, charts, key dates, sources |
| Every item waits for a `feed_admin` approval | Auto-publish when every automated check passes; anything that fails is **held** (never shown) and listed in the admin queue |
| Article text never fetched | The article page of an allowed source is fetched, its visible text is sent to the model once, then dropped (only SHA-256 and size kept) |

"Editorial" here means a professional explainer in a news-desk style: what was decided, who it
affects, the numbers, what a farmer can do next, background — **all from the source**. No opinion,
no praise or criticism of any government, party or person, no forecast the source does not make.

## 2. Pipeline (server)
1. `feed.news_job` (cron every 6 h) reads each RSS source whose terms are `allowed` and robots allow.
   New entries → item `fetched`.
2. **Fetch article** (same host spacing and robots rules as v1.4 §3): visible text via `feed/extract.py`
   (HTML). Over `FEED_AI_MAX_SOURCE_CHARS` → cut. Fetch failure → item `held: fetch_failed`.
3. **Classify** (cheap model, `FEED_CLASSIFY_MODEL`): `relevant` (changes something for farmers),
   `political` (party / election / praise or criticism content), `kind`, crops, districts.
   Not relevant or political → `draft` (not shown, not counted further).
4. **Write** (stronger model, `FEED_SUMMARISE_MODEL`): one JSON object in the schema of §3 for
   `mr`, `hi`, `en`.
5. **Check** (§4). All pass → `published` (event `auto_published`, actor null). Any fail →
   `held` with the reasons (admin queue).
6. Daily cap `FEED_AI_DAILY_ITEMS` (default 30) items sent to the model per UTC day; the rest wait for
   the next run. No key → nothing is written; items stay `fetched`.

## 3. Article schema (per language; JSON from the model)
```
{"relevant": true, "political": false, "level": "central" | "state",
 "lang": {"mr": ARTICLE, "hi": ARTICLE, "en": ARTICLE}}
ARTICLE = {
  "headline": ≤ 90 chars, "standfirst": one sentence ≤ 200 chars,
  "key_points": 3–5 strings,
  "sections": [{"heading": str, "body": 1–3 short paragraphs}]  // 3–5 sections, from:
      what was decided · who benefits · amounts and dates · what farmers can do next · background
  "facts": [{"label": str, "value": str}]   // 3–8 rows; value "not_stated" allowed, then omitted
  "charts": [CHART]                          // 0–2; only when the source has the numbers
  "key_dates": [{"date": "YYYY-MM-DD", "label": str}],
  "sources": [{"title": str, "url": str}]    // the source page; links the source itself gives
}
CHART = {"type": "bar" | "pie", "title": str, "unit": str,
         "data": [{"label": str, "value": number}]}   // 2–8 points
```
Length: 250–450 words of section text per language. Marathi uses the app glossary (व्यवहार, never
सौदा; मध्यस्थ (दलाल)); numbers may be Devanagari or Latin.

## 4. Automated checks (all must pass to publish)
- **Source match:** every number, amount, percentage, date and scheme name in headline, standfirst,
  key points, sections, facts, chart values and key dates — in every language — appears in the
  source text (normalised as in `feed/output_check.py`: Devanagari digits, lakh / crore, date formats).
- **Same facts in all languages:** the set of normalised numbers and dates is equal across mr / hi / en.
- **Charts:** 2–8 points, finite values ≥ 0, unit set; a pie only for parts of one whole: parts sum to
  100 % (± 1) or to a total the source states.
- **Links:** only URLs on the source's host or official government hosts (`*.gov.in`, `*.nic.in`).
- **Shape and length:** schema valid; limits of §3; no phone numbers or e-mails the source does not
  contain.
- **Political flag** false (classifier) and no party names from a configured list in any text.

## 5. App
- Feed list: headline, standfirst, badge (Official / News · केंद्र शासन / महाराष्ट्र शासन · date).
- Article screen: headline, standfirst (the label "BagMitra बातमी कक्ष · शासकीय स्रोतांवरून AI ने लिहिलेले"
  was removed by the owner 2026-11-14, Q156: no byline vouching for the text; instead a small
  neutral chip "AI ने निर्मित" under the article),
  key points, sections, facts table, charts (bar / pie drawn in Flutter, no new package; values and labels
  also read out as text for accessibility), key-dates timeline, sources, footer "कोणतीही कृती
  करण्याआधी अधिकृत स्रोत तपासा". Share = headline + standfirst + source link.
- Offline: the last 50 articles cached with their charts (no images).
- Old items (v1.4 summaries) keep working.

## 6. Storage
`feed_item_i18n.article` (JSON, migration 0041) per language; `feed_items.status` adds `held`;
the source text is not stored (hash, size, fetched_at only). Erasure, RLS and retention unchanged
(feed items hold no personal data).

## 7. Tests
Fakes only (Google / Anthropic never called in CI): schema parsing; each check with a failing case
(invented amount, mismatch between languages, pie not summing, foreign link, political flag); daily
cap; held items never in `GET /v1/feed`; app article screen + chart goldens (Marathi, light + dark,
1.3× text); offline cache.

## 8. Risks the owner accepted (Q127)
An AI article can still state a true number in a misleading way; automated checks cover numbers,
dates, names and links, not meaning. Mitigations: neutral prompt, source link on every article,
"check the official source" footer, `held` queue the owner can read in the admin web, and a switch
`FEED_AUTO_PUBLISH=false` that returns to human approval.

## 9. Milestones (one PR each)
A1 server: article schema, prompts, checks, auto-publish, cap, migration 0041 ·
A2 app: article screen, table, bar / pie charts, goldens · A3 Mahasamvad source (after the VPS
terms / feed check) · A4 Release 1.0.3 with the feed on.
