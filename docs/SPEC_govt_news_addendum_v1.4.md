# BagMitra — Government GR, Scheme & News Feed Addendum (Spec v1.4)

Same standing rules as the main spec §0 (English only in this file; the app shows Marathi/Hindi/English; test-first; small PRs with self-review; offline-first; never stop to wait — log questions in `docs/OPEN_QUESTIONS.md` with a default and continue; follow `docs/research/RESEARCH_DIGEST.md` and the token-efficiency rules). Build this after the current work-queue item 8 (weather alerts) because it reuses the alert engine, push, i18n and the review UI.

## 1. Goal
Farmers receive timely, **trustworthy** information on agricultural policy: Maharashtra Government Resolutions (GRs) and circulars, scheme openings and deadlines, payment/relief releases, crop-insurance windows, regulatory changes (e.g. pesticide bans), and a small curated news feed — filtered to *this* farmer (district, crop, land size) and explained in simple Marathi/Hindi/English with the source one tap away.

## 2. Content types and trust badges
| Type | Source rule | Badge |
|---|---|---|
| GR / circular / notification | Official government source only | "Official" + GR number, date, department |
| Scheme card (what, who is eligible, documents, how/where to apply, deadline) | Built from the official GR/portal page; every field cites its source | "Official" |
| Alert (deadline soon, payment released, window open) | Derived from an Official item with a date | "Official" |
| News | Headline + link + our own 2-line summary; never copy article text or images | "News — not official" |
| Community/WhatsApp forwards | **Not ingested.** Provide a "Check this message" feature later (user pastes text → we say whether a matching official item exists) | — |

Fake or forwarded "GR" messages are a known problem; the Official badge only ever appears for items fetched from an official source and stored with its hash.

## 3. Sources (register in `kb_sources`-style table `feed_sources` with tier, licence/terms, fetch method, last_ok)
Verify each source's terms of use and robots/ToS before fetching; record the result in the table. If a fetch is blocked or disallowed, record `fetch_failed`/`disallowed`, do not retry, and continue (owner can upload manually through admin).
- Maharashtra GR portal (maharashtra.gov.in GR search; there is an official DIT mobile app "Maharashtra Govt. Resolutions" that searches by department, keyword, date and unique GR code and notifies on new GRs) — filter Agriculture, Horticulture, Co-operation, Revenue & Forest (relief), Water Resources, Rural Development. No public API was found [UV]; the portal page was not fetchable from the research environment [UV]. Build a polite, rate-limited fetcher behind an adapter interface and a manual-upload fallback.
- MahaDBT portal (mahadbt.maharashtra.gov.in) scheme pages and notices; Agriculture Commissionerate; Directorate of Horticulture; PM-KISAN; PIB agriculture releases; PMFBY crop-insurance notices; ICAR/CCRI advisories; State pesticide/fertiliser notices; IMD agromet advisories (already in weather).
- News: only sources with RSS/API terms that permit headline+link use; start with PIB and official department feeds, add 2–3 mainstream Marathi agriculture outlets after checking terms. Never scrape paywalled or terms-restricted sites.
- Known scheme context to seed as draft scheme cards (verify against official GRs before publishing; third-party summaries only): Namo Shetkari Mahasanman Nidhi (₹6,000 state top-up to PM-KISAN), Mukhyamantri Baliraja free power for agri pumps, Bhausaheb Fundkar Falbag Lagvad (perennial fruit planting subsidy over 3 years, DBT, survival 80 %/90 %, via MahaDBT; check the GR for whether Nagpur mandarin is covered), MIDH horticulture, PMKSY Per Drop More Crop, farm-road scheme, loan-waiver 2026. These come from secondary pages and are not verified.

## 4. Pipeline
1. **Fetch** (scheduled, e.g. every few hours; adapter per source; store raw PDF/HTML, URL, fetched_at, SHA-256).
2. **Extract**: PDF text; if text layer is missing or broken Marathi (common), OCR with a Marathi-capable OCR; keep both and the confidence.
3. **Classify and filter** (cheap model, Haiku): is it relevant to farmers? which crops/districts/categories? is it a deadline, a payment, a new scheme, an amendment, a cancellation? Discard the rest (most GRs are irrelevant — administrative transfers, budgets, etc.).
4. **Summarise** (Sonnet only when the cheap pass flags relevance): produce structured JSON — title, one-line summary, who benefits, eligibility, documents, how to apply, deadline, amount, GR number/date, source URL, page references. **Every claim must quote or point to its source page**; if a field is not in the document, output `not_stated` — never infer.
5. **Human review gate (v1)**: items go to a review queue in the admin UI (reuse the K-review UI). Auto-publish is allowed only for low-risk types (new GR listed with title, date, department and link, no eligibility claims) until the reviewer has approved enough items to calibrate. Scheme eligibility and deadline cards always require review.
6. **Translate**: generate mr/hi/en text from the approved structured card; keep the English as source of truth; glossary for scheme names; golden tests.
7. **Match to farmers**: rules, not LLM guesses — district/taluka, crop, land hectares (from plot records), farmer category, and a transparent "You may be eligible because…" with a "Check the official GR" link. Wording is always "may be eligible", never "you will receive".
8. **Deliver**: in-app "Sarkari Sandesh" tab (newest first, filters: Official / Schemes / Deadlines / News), push for deadline and payment alerts (quiet hours, max N per week, per-category opt-out), digest option (weekly), offline cache of last 50 items with PDFs lazily downloaded on Wi-Fi.
9. **Follow-ups**: "Remind me" on a deadline → creates a task in the existing task/reminder system; "Share" produces a short Marathi text + source link (no forwarding of unverified content).

## 5. Data model (additions)
`feed_sources`, `feed_items` (type, source_id, external_id/GR number, department, published_at, url, raw_hash, extracted_text, status draft/in_review/published/withdrawn, trust_level), `feed_item_i18n`, `feed_scheme_cards` (structured fields + source page refs + version), `feed_deadlines`, `feed_item_targets` (district/crop/min-max hectares), `feed_receipts` (per-farmer seen/dismissed/reminded), `feed_review_events` (append-only). Withdrawn/superseded GRs show a visible "Replaced by …" banner.

## 6. Safety, neutrality and legal
- Information, not advice: standard footer "Check the official GR/portal before acting." No political commentary or party content; neutral wording; no opinion pieces. Government actions are reported factually with the source.
- Never present a scheme as available if the GR is expired, superseded, or the application window is closed; store `valid_from/valid_to` and re-check status on every fetch.
- Respect each source's terms of use; store only what is needed (PDF copy for official government documents after confirming reuse is permitted; for news, headline + link + own summary).
- Personal data: matching uses on-device or server-side profile fields only; never share farmer data with sources or advertisers. No ads and no sponsored items in this feed.
- The AI summariser runs with a "quote or `not_stated`" prompt and an output check that every number, date and scheme name in the summary appears in the source text; mismatches go to review automatically.

## 7. Tests (CI)
- Adapter contract tests against recorded fixtures (portal list page, PDF with text layer, scanned PDF, broken Unicode Marathi, 404/blocked).
- Golden tests for extraction + structured summary on 15–20 real GRs/notices (agriculture, horticulture, relief, insurance, a superseded GR), with reviewer-approved expected JSON.
- Output-check tests: injected hallucinated amount/date must be caught.
- Matching rule tests (table-driven): district/crop/hectare edge cases.
- Alert tests: dedupe, quiet hours, weekly cap, deadline reminders at T-7/T-2/T-0, withdrawn item cancels reminders.
- i18n tests (mr/hi/en) and golden screenshots for the feed tab (light/dark, 2 GB device budget).
- Coverage gates as in main spec; matching and output-check modules ≥ 90 %.

## 8. Milestones
- **G0** feed tables, source registry, manual-upload importer, review queue reuse, feed tab (static items) behind a flag.
- **G1** GR adapter + extraction + classify + summarise + review + publish; Official badge; offline cache.
- **G2** matching to farmer profile; deadline alerts and reminders; digest.
- **G3** curated news (headline + link + own summary) from sources whose terms allow it; "Check this message" for pasted forwards.
- Write Definition of Done per milestone in `docs/PLAN.md`; record emulator demo and test results in `docs/PROGRESS.md`.

## 9. Open questions to log with defaults
- Q-G1: Does the Maharashtra GR portal's terms allow automated fetching and republishing PDFs? Default: fetch metadata + link; store PDF only after terms are confirmed; manual upload fallback.
- Q-G2: Which Marathi OCR (on-server) meets quality on scanned GRs? Default: try open-source OCR first; send only failures to a vision model.
- Q-G3: Who reviews scheme cards? Default: owner + one agriculture-office contact/KVK; items stay `in_review` until approved.
