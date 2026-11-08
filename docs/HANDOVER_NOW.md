# HANDOVER_NOW — resume here in a fresh session

Read first: `OWNER_RULES.md`, the "Resume — market link" block in `docs/PROGRESS.md`, then this file.
Reports to Abhi in plain Marathi. Never run anything on the VPS; give him ONE command block.

## In flight (owner task "audit of 2026-11-07", verbatim below) — owner: take no new work, finish what is running
| Step | PRs / branches | State |
|---|---|---|
| 1. Visibility enforcement | #230, #232, #233, #234 ✅ merged | Done. |
| 2. Test APK `MARKET_LINK` | #231, #239 ✅ merged | Done. Owner turned the market link ON (Q117, verbatim "Market link स्विच ऑन करा"): VPS `.env` `MARKET_LINK_ENABLED=true` deployed; repo variable `MARKET_LINK=true`; Test APK and admin web build with it. Spec v1.5 §5 legal-gate records not yet in admin (owner knows). |
| Extra | #240 ✅ merged | Market prices "मोठ्या बाजारपेठा": Bhopal and every mandi in `MARKET_MAJOR_STATES` (Kerala, Karnataka). |
| 3. Subscription billing | #242–#254 ✅ merged (verify 0038, RTDN, reconcile job, admin web page, app adapter + subscription page, ADR 0008, runbook) | Done. Switch stays OFF until the owner turns it on in admin (after the CA GST opinion and the Play Console steps in `docs/runbooks/billing-play.md`). |

## Also done 2026-11-08 (owner requests)
| PR | What |
|---|---|
| #256 | Role home of trader / broker / exporter / provider lists its tools (lots, offers, registration, prices, account actions) instead of a "soon" note |
| #257–#259 | In-app feedback "अभिप्राय द्या": API + migration **0039** (`app_feedback`, role `feedback_admin`), app Settings screen (offline queue, optional screenshot, phone model), admin web list |
| #260 | Test APK checks its GitHub pre-releases and shows the update notice (releases titled `· code <run number>`) |
| #261 | Sign-in screen shows the picked role and "भूमिका बदला" (no dead end) |
| #263 | Test APK update picks the highest version code (GitHub's list is not date-ordered) |
| #264 | Expense screen links spray / labour / fertiliser records; category मशागत; labour task गवत कापणी |
| #265 | Update button and shared link on `https://<domain>/app`; VPS cron `deploy/fetch_test_apk.sh` (opt-in `TEST_APK_MIRROR=on`, **on** on the VPS since 2026-11-08) |
| #266 | Home "बाजार जोडणी" card: buttons माल विक्रीसाठी दाखवा, व्यापारी व मध्यस्थ |
| #267 | English role name Farmer (not Grower) |
- Deployed through 0039 (owner, 2026-11-08). Still pending (owner): grant `billing_admin,feedback_admin` — needs the Supabase service role key, which is not on the VPS (runbook `admin-web.md` §५).

## APK distribution (2026-11-08 evening)
- **Release APK live:** `release-1.0.0-1`, then `release-1.0.1-2` (welcome page #273). Release key created on the VPS (`/root/bagmitra-release-key/`, owner to keep an offline copy; fingerprint SHA256 C4:90:F1:8E:…:A8:BA) and set as GitHub secrets from the VPS (gh device login, logged out after).
- VPS `.env`: `TEST_APK_MIRROR=on`, `RELEASE_APK_MIRROR=on` → cron `deploy/fetch_test_apk.sh` serves the newest Release APK (arm64-v8a) at `/app` and writes `release.json` read by `/v1/app/version`; the Test APK no longer replaces it (#265, #270).
- Release APK carries the market link (owner "1 b", #271, Q117). Test APK carries Sarkari Sandesh (#272); Release not yet (`sarkari_sandesh=off`).
- Release workflow is run by hand (or by a session) from main: GitHub → Actions → Release APK, `version_name` next = 1.0.2.
- Still pending (owner): Supabase service role key → grant `billing_admin,feedback_admin,market_link_admin`; VPS reboot (kernel updates); offline copy of the release key.

## Audit 2026-11-08 fixes (all merged)
- One finding per PR: #276 H1, #277 M1, #278 M2, #279 M3, #280 M4, #281 M5, #288 L1, #293 L2, #291 L3, #289 L4, #292 L5, #287 L6, #285 L7, #282 L8, #286 L9, #283 L10, #290 L11; L12 note only (switch stays ON). Owner decisions Q122; open questions Q123–Q125.
- Test APK now updates from `https://<domain>/app/test` (file `bagmitra-test.apk`); `/app` stays the Release APK. The mirror serves a file only when its SHA-256 equals GitHub's asset digest.
- VPS (owner, ONE block): `cd /opt/bagmitra && bash deploy/deploy.sh && bash deploy/fetch_test_apk.sh; ls -l /srv/bagmitra-apk; curl -sI https://bagmitra.aialgodesk.org/app/test | head -3`.
- Owner: set repository variable `RELEASE_CERT_SHA256` (Q125).

## Billing status (2026-11-08)
- Done on main: migration 0037 (switch default OFF, start date, per-role amounts), Play price push + confirmed migrate, plans seeded on every API start (kb.seed), test fixes #245 (date) / #252 (flake).
- Merged: server verify (0038), RTDN with OIDC (`PLAY_RTDN_AUDIENCE`, `PLAY_RTDN_PUSHER`), daily `billing.reconcile_job` (voided purchases + drift; cron once `PLAY_PACKAGE_NAME` is set), admin web "सदस्यता" page (role `billing_admin`), app `in_app_purchase` adapter (Billing Library 9.1.0, CI check ≥ 8), subscription page + price-increase notice + Manage subscription.
- Google facts re-verified 2026-11-08 (ADR 0008); support.google.com unreachable from the session (owner checks fees / policy in Play Console).
- Owner questions: Q119 role detection, Q120 tokens hashed only, Q121 paywall wording; Q118 nothing locked. CA GST opinion before the first switch ON.
- Still open: `docs/runbooks/play-billing-testing.md` (licence testers, accelerated renewals), revenue dashboard, M6c/M6d (parked).

Decisions made in step 1 (state them in the report): a suspended user keeps block / unblock, appeals, accepting terms and closing an own lot; every other write → 403 `suspended` (code renamed from `account_suspended`, unused anywhere).

## After the steps
- Update the PROGRESS resume block when each step is done.
- Test APK: builds automatically after the "BagMitra App" workflow on `main` (`release-test-apk.yml`); give Abhi the release link.
- ONE VPS block: `cd /opt/bagmitra && bash deploy/deploy.sh && bash deploy/deploy.sh status` (deploy.sh pulls main, runs migrations — now through 0039 — and installs the cron lines incl. `CRON_MARKET_LINK_ERASE` and `CRON_ML_RECHECK`). Production `MARKET_LINK_ENABLED` is ON since 2026-11-07 (owner, Q117). Revert: `bash deploy/deploy.sh --revert`.
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
