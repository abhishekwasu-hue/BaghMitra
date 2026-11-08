# HANDOVER_NOW — resume here in a fresh session

Read first: `OWNER_RULES.md`, the "Resume — market link" block in `docs/PROGRESS.md`, then this file.
Reports to Abhi in plain Marathi. Never run anything on the VPS; give him ONE command block.

## In flight (owner task "audit of 2026-11-07", verbatim below) — owner: take no new work, finish what is running
| Step | PRs / branches | State |
|---|---|---|
| 1. Visibility enforcement | #230, #232, #233, #234 ✅ merged | Done. |
| 2. Test APK `MARKET_LINK` | #231, #239 ✅ merged | Done. Owner turned the market link ON (Q117, verbatim "Market link स्विच ऑन करा"): VPS `.env` `MARKET_LINK_ENABLED=true` deployed; repo variable `MARKET_LINK=true`; Test APK and admin web build with it. Spec v1.5 §5 legal-gate records not yet in admin (owner knows). |
| Extra | #240 ✅ merged | Market prices "मोठ्या बाजारपेठा": Bhopal and every mandi in `MARKET_MAJOR_STATES` (Kerala, Karnataka). |
| 3. Subscription billing | merged: #242 seed on start, #243 billing-1, #244 billing-2; chain (merge in order, each built on the previous): #246 billing-3 verify (migration 0038) → #247 billing-4 RTDN → #248 billing-5 reconcile job → #249 / #250 admin web page → #251 / #252-fix app adapter → #253 subscription page; docs: ADR 0008 + `docs/runbooks/billing-play.md` (this PR) | See "Billing status" below. |

## Billing status (2026-11-08)
- Done on main: migration 0037 (switch default OFF, start date, per-role amounts), Play price push + confirmed migrate, plans seeded on every API start (kb.seed), test fixes #245 (date) / #252 (flake).
- In the chain (draft PRs, CI per PR): server verify (0038), RTDN with OIDC (`PLAY_RTDN_AUDIENCE`, `PLAY_RTDN_PUSHER`), daily `billing.reconcile_job` (voided purchases + drift; cron once `PLAY_PACKAGE_NAME` is set), admin web "सदस्यता" page (role `billing_admin`), app `in_app_purchase` adapter (Billing Library 9.1.0, CI check ≥ 8), subscription page + price-increase notice + Manage subscription.
- Google facts re-verified 2026-11-08 (ADR 0008); support.google.com unreachable from the session (owner checks fees / policy in Play Console).
- Owner questions: Q119 role detection, Q120 tokens hashed only, Q121 paywall wording; Q118 nothing locked. CA GST opinion before the first switch ON.
- Still open: `docs/runbooks/play-billing-testing.md` (licence testers, accelerated renewals), revenue dashboard, M6c/M6d (parked).

Decisions made in step 1 (state them in the report): a suspended user keeps block / unblock, appeals, accepting terms and closing an own lot; every other write → 403 `suspended` (code renamed from `account_suspended`, unused anywhere).

## After the steps
- Update the PROGRESS resume block when each step is done.
- Test APK: builds automatically after the "BagMitra App" workflow on `main` (`release-test-apk.yml`); give Abhi the release link.
- ONE VPS block: `cd /opt/bagmitra && bash deploy/deploy.sh && bash deploy/deploy.sh status` (deploy.sh pulls main, runs migrations — through 0037 now, 0038 once #246 merges — and installs the cron lines incl. `CRON_MARKET_LINK_ERASE` and `CRON_ML_RECHECK`). Production `MARKET_LINK_ENABLED` is ON since 2026-11-07 (owner, Q117). Revert: `bash deploy/deploy.sh --revert`.
- Owner decisions 2026-11-07: Q116 = keep `device_sightings` and `package_grants` after deletion (privacy text must say so before go-live, lawyer review Q52); Q117 = market link ON; Q118 = nothing locked by a plan (gate map empty). Still open: Q99–Q115 (defaults built).

## Owner task, verbatim (2026-11-07)

> TASK: Fix the findings of the independent audit of 2026-11-07, in this order. Read OWNER_RULES.md and the PROGRESS resume block first. Work continuously; log any doubt in docs/OPEN_QUESTIONS.md with a default and carry on.
>
> 1. CRITICAL — enforce hide / suspend / delete / block in every market-link endpoint.
> The helpers in api/src/bagmitra_api/market_link/visibility.py (visible, not_blocked, hidden_user_ids, is_suspended, require_not_suspended) are unit-tested on SQL, but NO router uses them. The audit reproduced this through the real API:
> (a) a grower blocks a trader, and the trader still sees the grower's lot in GET /v1/market-link/lots;
> (b) an admin suspends a verified trader, and that trader still gets 200 on GET /lots and can send interests;
> (c) an admin hides a lot (reason fake_lot), and another verified trader still sees it in GET /lots.
> Fix all of these:
> - GET /lots: add visible("lot", MarketLot.id, MarketLot.owner_id) and not_blocked(viewer, MarketLot.owner_id). Do this inside the one rule, so lot_shown(), lot photo URLs and send_interest all use it. Make lot_shown take the viewer id.
> - is_verified_viewer: false when the user is suspended, or the buyer / broker profile is hidden, or the account is waiting for erasure.
> - Every write in the module (register, publish, interest, accept, deal done, rate, report) calls require_not_suspended. A suspended user gets 403 "suspended", with the reason visible in "My account actions".
> - send_interest: refuse (404 lot_not_found) when either side blocked the other. A broker-brought trader who is blocked also counts.
> - GET /profiles, GET /profiles/{type}/{id}, GET /providers: apply visible() for the profile kind and not_blocked(viewer, user_id).
> - GET /lots/{id}/interests for the grower: hide interests from blocked or suspended users.
> - Ratings and profile aggregates: ratings by suspended or deleted users still count, but are shown without a name (Q68).
> Tests: API-level tests (through httpx, not helper-only) for each case above, both directions of block, and restore bringing everything back. Add a guard test that lists every market-link router function returning other people's rows and fails if one does not go through the visibility rule.
>
> 2. Owner testing build.
> In release-test-apk.yml add --dart-define=MARKET_LINK=${{ vars.MARKET_LINK || 'false' }}, the same pattern as PHONE_LOGIN. The production release-apk.yml stays without it. The server flag MARKET_LINK_ENABLED stays OFF in production (legal gate, spec v1.5 §5). Log a question for the owner: turn it on only on a test server, or on the VPS for testing only. Default: OFF. In docs/runbooks/vps-deploy.md write the exact .env line and the repo variable the owner sets for a test.
>
> 3. Subscription billing.
> Then execute docs/prompts/SUBSCRIPTION_BUILD_PROMPT.md end to end (billing spec §7: admin ON/OFF switch, default OFF; per-role monthly fee set by the admin and pushed to Play; M6b Play Billing). The audit found nothing of it built, and FeatureGate (app/lib/features/billing/presentation/feature_gate.dart) is used nowhere. Do NOT decide yourself which features or market-link information a plan unlocks; the owner will specify that. Build the switch, the prices and the Play flow, keep every feature open while the switch is OFF, and log the question "which information each role sees only with a plan" with the default "nothing locked".
>
> Rules: tests first; one feature per PR, ≤ 400 production lines; self-review every diff against the spec before pushing; run the repo checks; merge only when green; Marathi phone screenshots (light + dark) for any UI change. Update the PROGRESS resume block when each step is done.
