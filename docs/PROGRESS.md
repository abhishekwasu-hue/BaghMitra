# Progress

## M0 — Foundation · 2026-10-12

### Delivered
- **API** (`api/`): settings from env + `product.env`, JSON logs with request ids, uniform error
  envelope, `/health/live`, `/health/ready`, Supabase JWT verification, `GET /v1/me`,
  `POST /v1/sync/push` / `GET /v1/sync/pull` (idempotent, last-writer-wins, full audit log),
  OpenAPI export, Sentry hook behind `SENTRY_DSN`, Dockerfile.
- **DB:** `farmers`, `sync_mutations`; Alembic 0001 with owner-only RLS (ENABLE + FORCE).
- **App** (`app/`): Riverpod + go_router; theme tokens from the reference mockup (light + dark);
  Baloo 2 + Mukta bundled; i18n `en` / `mr` / `hi`; Drift DB + outbox + sync engine (batching,
  backoff with jitter, offline/signed-out states, pull cursor); generated API client; HTTP sync
  transport; phone-OTP login (Supabase adapter + demo mode); Home "today's orchard" built from
  design-system components; painted glyph illustration set; component gallery behind
  `DEV_GALLERY`; admin web shell (`lib/main_admin.dart`).
- **CI:** `.github/workflows/api.yml` (ruff, format, mypy strict, bandit, pytest ≥ 85%,
  OpenAPI drift, Postgres migration + RLS job), `.github/workflows/app.yml` (codegen drift,
  format, analyze `--fatal-infos`, tests incl. goldens, logic coverage ≥ 80%, release APK artifact).
- **Docs:** PLAN, ADRs 0001–0007, DESIGN_SYSTEM (with screenshots), OPEN_QUESTIONS, runbook.

### DoD checklist (verified in the build session)
| Item | Result |
|---|---|
| ruff / ruff format / mypy --strict / bandit | clean |
| pytest | 30 passed, 1 Postgres-only; coverage **95.9%** (gate 85%) |
| Postgres: upgrade → downgrade → upgrade, RLS on every table, cross-user read/insert blocked | passed (postgis/postgis:16-3.4) |
| API smoke on Postgres: migrate, push profile, `GET /v1/me` (Marathi), JSON access logs | passed |
| dart format / flutter analyze | zero issues |
| flutter test | 55 passed (unit, widget, offline→online sync, l10n completeness, no-inline-colours, goldens) |
| App logic coverage | **91.2%** (gate 80%) |
| Goldens | Home mr light/dark, hi, en, offline banner; login; gallery |
| `flutter build web` (app + admin) | passed |
| OpenAPI exported, Dart client generated | yes; CI checks drift |
| APK build | CI job (no Android SDK in the build container) |
| Emulator demo checklist | **not run** — no KVM/Android SDK in the cloud container (OPEN_QUESTIONS Q4) |
| `make dev` (Docker compose) | **not verified** — Docker Hub returned 429 for `python:3.12-slim`; the same steps passed without Docker (above) |

### Demo checklist (run on an emulator when one is available)
1. Fresh install → login screen in device language (Marathi device → Marathi).
2. Invalid number shows error; valid number → OTP screen; wrong OTP error; correct OTP → Home.
3. Home: weather header, stage card with day count in Devanagari digits, alert, tasks, price.
4. Tick a task → animated check; dark mode via system setting.
5. Airplane mode → offline banner; edits queue; network back → banner clears.

### Known gaps carried into M1
Home slightly exceeds one 5.5" screen (Q7); mic not wired until STT (Q5); performance budget
measurement on a 2 GB device profile not yet automated.

---

## Status after M1 / K0 / K1 / M2 (first slices) · 2026-10-20

Everything below is merged to `main` with CI green (API: ruff, format, mypy strict incl.
alembic, bandit, pytest ≥ 85 %, kb/* ≥ 90 %, OpenAPI drift, Postgres migration + RLS; app:
codegen drift, format, analyze, tests + goldens, logic coverage ≥ 80 %, APK). Nothing is
deployed. All screens are checked as goldens at phone size; **no emulator run has been done**
(Q4), so the demo checklists below are covered by widget tests, not by a device.

### M1 — Orchard & bahar core · partly done
| Done | Not done |
|---|---|
| Plots API + app (add / list / delete), offline + synced | Editing the boundary of an existing plot; boundary on a map (needs a map provider) |
| GPS boundary when adding a plot: stand at each corner and tap; area and centroid computed on the phone, saved as a GeoJSON polygon (Android location permission; position read only on tap) | |
| Bahar cycles API + app ("start a bahar" with the grower's own dates) | Stage calendar and bahar selection assistant (needs verified templates, Q10) |
| Crop stage templates as reference data (none published) | Tasks and reminders (push, WhatsApp / SMS) |
| Sync appliers for plot and bahar so other devices' changes arrive | Voice-guided onboarding (needs STT, Q5); wave-2 locales |
| Onboarding: language (Marathi first, switches the app at once), optional name and place, required data consent and optional WhatsApp consent (draft wording, Q17); saved offline, router gates the app until done | |

### K0 / K1 — Knowledge base and legal gate · done in code, no content yet
Source registry (51 sources, tier + licence), card lifecycle (draft → expert_reviewed →
published, expert review record required, review expiry), licence rules enforced in code,
legal gate (ban, crop restriction, no label claim, PHI), output filter, CSV importers with dated
diffs and end-dating, nightly re-gate, admin alerts, admin API and web screens with staff
sign-in. 27 draft cards and 7 recorded source conflicts are seeded from addendum v1.3 §3 (chemical
options carry no dose; none can pass the gate until label claims are imported), and source
documents are tracked by fetch status (all 38 fetches were blocked from the dev environment, see
`runbooks/kb-sources.md`). **No card is published and no label claims are loaded**, so no chemical advice can
reach a grower (blockers: Q12 expert reviewer, Q13 CCRI calendar, Q10 source PDFs).

### M2 — Records & accounts · partly done
| Done | Not done |
|---|---|
| Expenses and incomes (API + app), exact paise, buyer dues | |
| Cost and profit per plot / bahar; per acre, tree, tonne | |
| Season-by-season comparison per bahar (cost, income, profit and change vs the same bahar a season earlier) | |
| Spray records (API + app) with offline ban / PHI warning from a cached gazette list | Voice-note quick entry (needs STT, Q5) |
| Accounts export as a spreadsheet (CSV with Marathi header, plain-decimal money) and as a PDF report (Flutter-rendered, so Marathi is shaped correctly), shared via the phone's share sheet | Selectable-text PDF and a true .xlsx (Q16, only if asked) |
| Fertiliser / manure and irrigation records (API + app, field log screen); input cost counted under its kind | |
| Labour register (wages, advances, settlement) and harvest records (API + app); wages counted under labour | |
| Warnings are facts only and never block recording | |

### Known gaps
- Home still shows sample data ("Sample data" chip): weather, tasks and price come in M4 / M5.
- The restrictions feed is only as good as the seeded list (8 entries, checked 2026-10-12); the
  PPQS importer (CSV upload) is how it gets completed.
- Warnings use the label aliases in `assets/config/crops.json` (owner-confirmed, Q15).
- Performance budget (2 GB device, first frame < 1 s) is not measured yet.

### Owner actions outstanding (none of them blocks development)
Hosted Supabase project, an expert reviewer, the official CCRI Calendar of Operations, a legal
review of the consent wording, a real-phone check before Play release, Play Console setup
(billing runbooks). Decisions from the owner's unblock message of 2026-10-20 are recorded in
`OPEN_QUESTIONS.md` and the work queue is in `PLAN.md`; development continues on the local Supabase
stack, the on-device voice adapter, a headless emulator in CI, interim CCRI templates and draft
knowledge cards.
