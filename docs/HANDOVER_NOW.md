# HANDOVER_NOW — resume here in a fresh session

Read first: `OWNER_RULES.md`, the "Resume — market link" block in `docs/PROGRESS.md`, then this file.
Reports to Abhi in plain Marathi. Never run anything on the VPS; give him ONE command block.

## In flight (owner task "audit of 2026-11-07", verbatim below) — owner: take no new work, finish what is running
| Step | PRs / branches | State |
|---|---|---|
| 1. Visibility enforcement | #230, #232, #233, #234 ✅ merged | Done. |
| 2. Test APK `MARKET_LINK` | #231 ✅ merged | Done. Q117 open (default OFF everywhere). |
| 3. Subscription billing | `billing-1` ef3416a (from main) → `billing-2` 3a8b2ed → `billing-3` f4cd0ec — API only, NOT reviewed, no PRs | See "Billing status" below. |

## Billing status (sub-agent report; stopped on the owner's order)
- billing-1 (400 prod lines): migration 0037; admin ON/OFF switch (default OFF), start date, monthly amount per role; `GET/PUT /v1/admin/billing/settings` (logged in `billing_events`); `GET /v1/billing/plan`. Switch OFF / before start / no amount ⇒ everything open; gate map empty ⇒ nothing locks even when ON.
- billing-2 (~360): `PUT /v1/admin/billing/roles/{role}/amount` → Play `monetization.subscriptions.patch` (India monthly), stores Play's price; 503 not set up / 502 refused ⇒ nothing saved; `POST …/migrate-prices` needs `confirm: true`. Env names only: `PLAY_SERVICE_ACCOUNT_B64`, `PLAY_PACKAGE_NAME` (`deploy/.env.example`).
- billing-3 (345): migration 0038 (`subscriptions.price_change`); `POST /v1/billing/google/verify` (Play is the truth, 8 states mapped, token stored hashed, 409 / 403 on misuse, acknowledge, rate limit); `/plan` returns the account id + pending price change.
- Tests: 110 passed on billing-3 (fake publisher, mocked HTTP; Google never called). Three M6a tests in `test_billing_api.py` changed to "full app while the switch is OFF" (addendum §7).
- Check before merging: migration numbers 0037 / 0038 against main; **Q117 is used twice** (owner decided the plan question 2026-11-07: nothing locked — now Q118 on main; renumber the billing branches' Q117 → Q118 decided, Q118 → Q119) (Test APK question in #231 and the billing "which information each role sees only with a plan" question) — renumber the billing ones (and Q118 "how a user's role is known": default from market-link registrations, grower if a plot or no other role).
- Production risk: deploy never runs `python -m bagmitra_api.billing.seed`; an empty plans table breaks `GET /v1/billing/entitlements`. Add the seed to the deploy step / runbook.
- Not built yet: admin web page (switch, amounts, price-change rules, confirmed migrate) + goldens; app `in_app_purchase` adapter + fake, purchase / restore / startup reconcile, Billing Library ≥ 8 CI check; paywall with Play's localized price, price-increase notice, Manage subscription link (Marathi screenshots light + dark); RTDN endpoint (OIDC), reconciliation job, voided-purchases poll; `docs/runbooks/billing-play.md` (CA GST opinion before the first switch ON) and an ADR; re-check Google policy / API shapes (developers.google.com was blocked in this session).

Decisions made in step 1 (state them in the report): a suspended user keeps block / unblock, appeals, accepting terms and closing an own lot; every other write → 403 `suspended` (code renamed from `account_suspended`, unused anywhere).

## After the steps
- Update the PROGRESS resume block when each step is done.
- Test APK: builds automatically after the "BagMitra App" workflow on `main` (`release-test-apk.yml`); give Abhi the release link.
- ONE VPS block: `cd /opt/bagmitra && bash deploy/deploy.sh && bash deploy/deploy.sh status` (deploy.sh pulls main, runs migrations — now through 0036 — and installs the cron lines incl. `CRON_MARKET_LINK_ERASE` and `CRON_ML_RECHECK`). Production `MARKET_LINK_ENABLED` stays OFF. Revert: `bash deploy/deploy.sh --revert`.
- Owner decisions open: Q99–Q117 in `docs/OPEN_QUESTIONS.md` (Q115 pair-only rating flag, Q116 data kept after deletion, Q117 where to test the market link); plus the billing question "which information each role sees only with a plan" (default: nothing locked).

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
