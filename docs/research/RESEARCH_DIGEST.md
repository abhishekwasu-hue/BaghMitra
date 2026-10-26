# Research Digest — BagMitra, ATP Journal, company setup
Last updated: 2026-10-26. Owner: Abhi. Purpose: one compact place for every research finding and decision, so sessions read this instead of re-researching or re-reading long specs. Each line points to the full source when detail is needed. Tags: [V] verified from an official/primary page on the date shown; [S] secondary source; [UV] not verified (fetch blocked or not checked); [D] decision taken.

## 0. File index (read the full file only when the task needs it)
| File | What it holds | Read when |
|---|---|---|
| `bagmitra_spec_v1.md` | Main BagMitra spec: §0 engineering rules, §1 product, §2 stack + language plan, §3 domain model, §4 milestones M0–M8, §4A UI/design, §5 agronomy rules | Starting a milestone |
| `bagmitra_billing_addendum.md` | Play Billing replaces Razorpay-in-app; entitlement layer; M6a–M6d | At M6 |
| `bagmitra_knowledge_addendum.md` (v1.3) | Source registry with URLs/tiers/licences, ~80 seed facts, legal-status table, safety gate, review workflow, K0–K4 | Any agronomy/advice/KB work |
| `bagmitra_unblock_message.md` | Decisions for Q3/Q4/Q5/Q10/Q12/Q13/Q17 + 10-item work queue | Planning next PR |
| `bagmitra_phone_testing_message.md` | Test APK workflow, test flavour, demo mode, runbook | Release/test build work |
| `bagmitra_home_mockup.html/.png` | Reference home screen | UI work |
| `ATP_journal_module_spec_FULL.md` | ATP F&O Journal module spec (v1 + v1.1 merged; addendum wins) | ATP journal work |

## 1. BagMitra — product and stack [D]
- Android-first app for fruit-orchard growers, Nagpur mandarin (santra) first. Owner's orchard: Shindi Khurd, Chandur Bazar, Amravati.
- Stack: Flutter + Riverpod + go_router + Drift/SQLite (offline-first, outbox sync); FastAPI + Pydantic v2 + SQLAlchemy async + Alembic; Supabase (Postgres/PostGIS, phone-OTP auth, Storage, RLS); ARQ/Redis jobs; Claude API vision; Open-Meteo weather; Agmarknet prices; FCM push (WhatsApp/SMS later behind config); MQTT for IoT later. OpenAPI-first with a generated Dart client.
- Quality gates: TDD; coverage backend ≥85 %, app ≥80 %, safety gate/filter ≥90 %, billing server ≥90 %; mypy strict, ruff, bandit; PRs ≤400 lines with a self-review checklist; golden tests; 2 GB-RAM device performance budget.
- Languages: launch mr/hi/en; wave 2 te/kn/ta/ml; wave 3 gu/bn/pa/or/as.
- UI tokens: leaf #1F4D2B/#2E6B3C, light leaf #9BC79A, santra #F28C28/#FFB15C, sun #FFC857, soil #6B4A2B, sky #CFE8F3, bg #F3F7EE, ink #1B2A1E; fonts Baloo 2 + Mukta.
- App name is **BagMitra**; GitHub repo is `abhishekwasu-hue/BaghMitra` (spelling differs; renaming the repo was suggested, owner has not decided).

## 2. AI vision cost [V 2026-10]
- Image tokens ≈ ceil(w/28) × ceil(h/28). Two-stage diagnosis: Haiku screens, Sonnet only when needed.
- Approx. cost per photo at ₹83/$: Haiku ≈ ₹0.04, Sonnet ≈ ₹0.70. Use prompt caching for the system/KB prefix and the Batch API for non-urgent work. Downscale photos on device before upload.

## 3. Google Play [V 2026-10-12 unless marked]
- Developer account $25 one-time. Personal account: closed test with 12 testers for 14 continuous days before production. Organisation account: needs D-U-N-S. [D pending: owner to choose; Pvt Ltd company planned → organisation account.]
- Payments policy: in-app subscriptions (including cloud/business software) must use Play Billing; no B2B exemption; no steering links. India: Play Billing, user-choice billing (fee 4 pp lower) or consumption-only model (2023 announcement — re-verify in Play Console).
- Play Billing Library 8+ required (deadline 31 Aug 2026, extension to 1 Nov 2026). Use `purchases.subscriptionsv2` and `Orders.refund`; v1 subscription APIs are deprecated. Subscription fee reported as 15 % [S].
- [D] Grower plans via Play Billing only. B2B (consultant/FPO) = consumption-only in app + separate web portal with Razorpay/invoices, never linked from the app. Data never held hostage (records stay readable/exportable on Free).

## 4. Agronomy knowledge — the essentials (full detail in knowledge addendum v1.3)
- Tier 1 India: ICAR-CCRI monthly PDFs `https://ccri.icar.gov.in/site/assets/files/1223/<month>.pdf`, CCRI greening advisory, PDKV Akola AICRP, PDKV recommendations 2017, NIPHM citrus IPM, PAU fruit drop, NHB PHT, Agmark grades, KCC transcripts (question mining only).
- Tier 2 legal gate (official only): CIB&RC Major Uses PDFs (PPQS), banned/restricted list, FSSAI MRLs, Codex (export reference).
- International (summarise + cite only, never copy): UF/IFAS CG101 (CC BY-NC-ND), UC IPM, NSW DPI image guide, EPPO, Fundecitrus, Embrapa, CRI Sargodha, PlantwisePlus.
- Legal status highlights [V 2026-10-12, re-verify]: benomyl, phorate, methyl parathion, dichlorvos banned (S.O. 3951(E) 2018); dicofol banned (S.O. 4294(E) 2023); chlorpyrifos prohibited on citrus; dimethoate not for raw-eaten fruit → not usable on mandarin; 2,4-D and GA3 have no citrus label; copper oxychloride and streptomycin+tetracycline have citrus canker labels; imidacloprid citrus label (PHI 15 d).
- [D] Older official Indian guidance still names banned chemicals → every chemical suggestion passes the legal gate; chemical cards stay `draft` until an expert reviewer approves. AI answers are RAG-only with an output filter.
- Weather-risk models (starting points, calibrate locally): heat 35–40 °C → fruit-drop alert; Asian citrus psylla degree-days base 11.11 °C, ≈580 DD per generation; Alter-Rater for Alternaria; canker = storm + new flush; Phytophthora = rainfall + soil wetness.

## 5. IoT hardware (later phase) [D]
- Solar LoRa node: soil moisture/temperature, air temp/RH, leaf wetness; target ₹3–4k per node; optional camera/smart trap later. Manufacturing and installation outsourced.

## 6. Backend hosting — Supabase [D 2026-10-20]
- Development and CI use a **local Supabase stack**; hosted project created later; switching is config only.
- Hosted plan when needed: region ap-south-1 (Mumbai). Free tier pauses after inactivity → Pro (~$25/month) once real testers exist [UV price]. Phone OTP needs an SMS provider (MSG91/Twilio) and Indian DLT registration; use test numbers or email login early.
- Create hosted project only when real login/sync across phones or Play closed testing is needed.

## 7. Test APK and repo [state as of 2026-10-20]
- Merged: #44 emulator CI, #46 test-APK workflow (R8 rules, INTERNET permission fix), #47 test badge/offline mode/"Try without account"/Send logs, #48 sample orchard seed. #49 (release-APK smoke test on emulator) was in CI.
- Release pattern: GitHub pre-release `test-YYYYMMDD-<short-sha>`, file `bagmitra-test-…-universal.apk`. First: `test-20261020-50f48bb`.
- Until the four secrets `TEST_KEYSTORE_BASE64`, `TEST_KEYSTORE_PASSWORD`, `TEST_KEY_ALIAS`, `TEST_KEY_PASSWORD` are added (commands in `docs/runbooks/test-apk.md`), APKs are debug-signed → each update needs uninstall (data lost).
- Repo is **private** (2026-10-20). GitHub Free private = 2,000 Actions min/month; Pro ($4/month) = 3,000 min and enables branch protection/rulesets on private repos.
- Update 2026-10-26 [V]: repo is **public** (owner switched it on 2026-10-20 after private-repo Actions minutes ran out); public repos have no Actions minute cap, so §8 of the efficiency rules is applied for speed, not quota. Merged since: #49–#58 (release smoke test, voice entry, tasks + stage reminders, plot detail/edit, phone reminders). Latest test APK seen: `test-20261020-bd0ce53`; the 4 keystore secrets are added (owner, 2026-10-20).
- Recommended ruleset for `main`: block deletion, block force push, require status checks; **no required approvals** (session self-merges) and **no "require up to date"** (saves emulator minutes). Enable "Automatically delete head branches".

## 8. Company and brand [state 2026-10-22]
- [D] Register a **Private Limited** company (2 directors/shareholders: owner + wife; ≥1 Indian resident director; ₹1 lakh authorised capital typical). Process: DSC → name (RUN or SPICe+ Part A) → SPICe+ with AGILE-PRO-S (PAN/TAN/GST/EPFO/ESIC/bank) → MoA/AoA + Maharashtra stamp duty → office proof + NOC → bank account and capital. Professional fee ≈ ₹7–15k + govt fees [UV]. Then DPIIT Startup India recognition; annual ROC/audit/ITR.
- Name checks the owner must do: MCA RUN, IP India trademark (Class 42 and Class 9), domain (.in/.com).
- English name shortlist ("… Technologies Private Limited"). Web search found no company for: Northbound, Alder, Quillon, Zenvora, Lumenor, Ardent, Tilth, Sapling, Graft. Not web-checked: Larkspur, Wrenfield, Ironwood, Hearthstone, Bellwether, Keystroke, Evergreen, Altavo, Corvane, Elvora, Navaro, Velora, Kyvora, Solvane, Tenvora. Avoid (existing companies): Kestrel Labs, Brightloom, Vantora, Axiom Forge, Rootstock Labs, Cairn Labs, Furrow, Setu, Aarambh, Srujan (≈ Srijan Technologies), Shivar (≈ Shivlab). Domain/MCA availability **not** verified (registry lookups blocked from the workspace).
- [D] House-of-brands: one company; each app has its own name and domain. Buy now: `bagmitra.in` (+ `.com` if cheap), company `.in` + `.com`. Subdomains only for technical use (`api.`, `app.`, `admin.`). Each app has its own privacy-policy URL and support email. Domains auto-renew, WHOIS privacy on, move to the company once registered.
- ATP domain ideas (from the claude.ai "Price action trading strategy" chat): algotradeai.com (first pick), aialgotrade.in, algotrade.ai; English: zonereader.com, chartsense.com, pricestory.com, tradelens.com, trendzone.com, chartcraft.com, swingdesk.com, setupwatch.com; Marathi-style: chartmitra.com. ATP does not need a public domain while it is for the owner's use only.
- Regulatory caution: selling/operating an algo or "AI bot" for others raises SEBI algo-provider/RA registration questions; avoid "signals/tips/advisory/profit" in trading brand names; confirm with a CA/lawyer.

## 9. ATP Journal module (summary; full spec in `ATP_journal_module_spec_FULL.md`)
- Inside ATP (FastAPI + React). Broker sync + file import (Zerodha, Upstox, Angel, Groww, Dhan, Fyers); FIFO positions → strategy grouping; config-driven Indian charges engine; compliant vs non-compliant P&L; rulesets/checklists; Claude text+vision trade review; trade plan vs actual; alert-only guardrails; Telegram/email; tax report; mentor mode. Plans Free / Pro ₹299 / Coach ₹599. ADR-0006: AI never trades.

## 10. Owner-side open items
1. Add the 4 test keystore secrets (Codespaces, runbook commands) before walking the real boundary.
2. Install APK, test: Marathi text clipping, GPS boundary walk, low-network speed; send logs + badge code on bugs.
3. Decide GitHub Pro + ruleset; enable auto-delete branches.
4. Pick company name → MCA RUN / trademark / domain checks → CA.
5. Later: hosted Supabase, expert reviewer (ICAR-CCRI/PDKV/KVK), CCRI Calendar of Operations, consent-text legal review, Play account (organisation), real-phone check before release.
