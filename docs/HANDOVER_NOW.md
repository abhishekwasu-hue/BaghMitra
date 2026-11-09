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
- Q123–Q125 answered yes and built (#295–#297). VPS deployed (Test APK 173 at `/app/test`). The release key is pinned by default; a repository variable `RELEASE_CERT_SHA256` overrides it only after a key change.

## Government news and illustrated cards (2026-11-09)
- AI articles: `docs/SPEC_feed_ai_articles_v1.6.md`; news cron every 6 h reads Mahasamvad (`mahasamvad_news`, allowed, Q129) and writes mr / hi / en articles with structured outputs; `FEED_AI_API_KEY` is set on the VPS (owner, checked `grep -c` = 1). Published only when every check passes (Q127); held items listed in the admin web (status `held`). PIB answers 403 to the VPS. Manual run: `docker compose -f deploy/docker-compose.yml exec -T api python -m bagmitra_api.feed.news_job` (log `/var/log/bagmitra-news-now.log` when started with nohup).
- Release 1.0.3 (code 4) turns Sarkari Sandesh on; 1.0.4 adds every card drawing. GitHub releases flakiness on 2026-11-09 (sqlite3 hook hash, Gradle 504) needed reruns.
- Cards: drawings in `app/lib/features/practices/presentation/practice_figure_view.dart` + `symptom_figures_{a,b,c}.dart`; every measure drawn must be in the practice text (test). Next: AI check of every card point against its source (Q128).

## Card check, price trend, Play bundle (2026-11-09, after #309)
| PR | What |
|---|---|
| #310 | `api/src/bagmitra_api/kb/card_check.py`: AI check of every practice-card point against its cited sources (Q128). Number check (no AI) plus a structured-output verdict `supported` / `contradicted` / `not_found` with a verbatim quote; Markdown report, failing points first; no card is changed. Runbook `kb-sources.md`. First VPS run: 162 points, 59 passed, 7 contradicted, 96 not_found, no errors, all sources read. |
| #311 | Card check: each point's citation note is sent to the model, quotes shortened with "…" are accepted, a quote not in the source is reported as `unverified_quote`, the report shows characters read per source. **Not re-run on the VPS since.** |
| #312 | `GET /v1/market/prices/history` (Q130): stored modal / min / max per day for one mandi, `days` 1–90 (default 90), Agmarknet row over manual, no estimates, never fetches from Agmarknet. |
| #313 | App price-trend chart sheet (Q130): chart icon on each mandi price, 15 days / 1 month / 3 months, scrub cursor, high / low and changes, last 90-day series kept offline. **Not yet in a release APK** (Release 1.0.5 was built before it was merged). |
| #314 | Release workflow also builds the Play App Bundle as a 30-day workflow artifact (`bagmitra-play-<name>-<code>.aab`), checked against `RELEASE_CERT_SHA256`; never on the public release, nothing uploads to Play. Runbook `release-apk.md` §५. |
- Releases 2026-11-09: 1.0.3 (code 4) and 1.0.4 (code 5) published earlier in the day; Release 1.0.5 (code 6), run 42615392236, artifact `bagmitra-play-1.0.5-6.aab`, certificate SHA-256 `C4:90:F1:8E:7B:80:C1:B3:1D:50:9B:C9:26:1C:5E:DF:1B:E4:31:74:30:3E:47:B0:B0:56:0A:BE:15:6A:A8:BA`.
- In flight: 90-day market price backfill on branch `market-backfill`. The archive resource 35985678 was verified live; mandi names can differ from the current feed, so only matching keys are stored.
- Next:
  1. Run the backfill on the VPS once its PR merges.
  2. Release 1.0.6 so the trend chart reaches phones.
  3. Re-run the card check on the VPS and fix the cards that fail.
  4. Check the reason for the one held news item.
  5. Upload the `.aab` to Play Console (owner).

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
