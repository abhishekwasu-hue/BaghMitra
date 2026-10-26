# BagMitra — Delivery Plan

> Before any spec reading or web research, read `docs/research/RESEARCH_DIGEST.md` (owner's research digest; append one dated, tagged line per new durable finding). Resume point: `docs/PROGRESS.md`.

Source of truth for requirements: [`SPEC_v1.md`](SPEC_v1.md), extended by the
[knowledge base & advice-safety addendum v1.3](SPEC_knowledge_addendum_v1.3.md), which wins
for anything that tells a grower what to spray, apply or do. This plan maps every spec
section to concrete files and milestones. Each milestone has a Definition of Done (DoD)
that must be met before the next one starts. Progress is tracked in
[`PROGRESS.md`](PROGRESS.md); unresolved points live in
[`OPEN_QUESTIONS.md`](OPEN_QUESTIONS.md) with a provisional default.

The product name is configurable in one place: [`../product.env`](../product.env)
(`PRODUCT_NAME`, `PRODUCT_SLUG`). The API reads it through settings; the app receives it
via `--dart-define-from-file=product.env`.

## Repository layout

```
<repo root>/
  product.env              # product name / slug (single place)
  api/                     # FastAPI backend (Python 3.12)
    src/bagmitra_api/
      core/                # settings, logging, request ids, errors
      auth/                # Supabase JWT verification, current-user dependency
      db/                  # SQLAlchemy base, session, models
      routers/             # health, me, sync, (later: plots, bahars, ...)
      sync/                # outbox ingestion: idempotency, LWW + audit
      ai/                  # (M3) Claude service behind an interface
      weather/, market/, messaging/, risk/   # (M4–M5) provider adapters
    alembic/               # migrations (reversible, RLS policies included)
    tests/
  app/                     # Flutter app (Android first, iOS + PWA) + admin web entrypoint
    lib/
      theme/               # ALL design tokens (colours, spacing, radii, type, elevation)
      l10n/                # ARB files (en source; mr, hi launch; te, kn, ta, ml wave 2)
      core/                # config, connectivity, result types
      data/local/          # Drift database, tables, DAOs
      sync/                # outbox engine, backoff, transport interface
      features/<feature>/  # presentation + domain per feature
      design_system/       # reusable widgets (cards, chips, banners, timeline, ...)
      admin/               # admin web shell (main_admin.dart)
    test/                  # unit, widget, golden tests
    integration_test/      # offline -> online sync, perf budget
  infra/                   # docker-compose, Supabase SQL helpers, deployment notes
  docs/                    # PLAN, PROGRESS, OPEN_QUESTIONS, adr/, agronomy/, api/, runbooks/, design/
```

CI: `.github/workflows/api.yml` and `.github/workflows/app.yml` (path-filtered to `api/**`
and `app/**`). PR template: `.github/pull_request_template.md`.

## Spec → files map

| Spec § | Topic | Where |
|---|---|---|
| 0.1 | Test-first, coverage gates | `api/pyproject.toml` (`--cov-fail-under=85`), `app/tool/coverage_gate.dart` (≥80% on `lib/core`, `lib/data`, `lib/sync`, `features/*/domain`) |
| 0.2 | Strict typing & linting | `api/pyproject.toml` (mypy strict, ruff, bandit), `app/analysis_options.yaml` |
| 0.3 | Contract-first API | `api/src/bagmitra_api/export_openapi.py` → `docs/api/openapi.json`; `app/openapi/` + `swagger_dart_code_generator` → `app/lib/api/generated/`; CI fails on drift |
| 0.4 | Small PRs + self-review | `.github/pull_request_template.md` |
| 0.5 | No hardcoded business values | DB config tables (`crop_stage_templates`, `risk_rules`, `app_config`, ...) + admin UI; lint test `app/test/architecture/` |
| 0.6 | Offline-first | `app/lib/data/local`, `app/lib/sync`, `api/src/bagmitra_api/sync`; `app/test/sync/offline_online_test.dart` |
| 0.7 | DoD per milestone | this file; `PROGRESS.md` |
| 0.8 | Continuous work | `OPEN_QUESTIONS.md` |
| 0.9 | Security | Alembic RLS policies, `.env.example`, Pydantic validation, rate limits (M3), signed URLs (M3) |
| 0.10 | Observability | `api/src/bagmitra_api/core/logging.py`, request-id middleware, `/health/*`, Sentry hook behind `SENTRY_DSN`; app sync status banner |
| 2 | Stack | ADRs 0001–0006 |
| 2 i18n | Languages | `app/l10n.yaml`, `app/lib/l10n/*.arb`, `docs/adr/0004-i18n.md` |
| 3 | Domain model | `api/src/bagmitra_api/db/models/`, migrations per milestone |
| 4 | Features | milestones below |
| 4A | Visual design | `app/lib/theme/`, `app/lib/design_system/`, `docs/design/DESIGN_SYSTEM.md`, golden tests |
| 5 | Agronomy content | `docs/agronomy/` (citations), seed data in migrations with `source` column |
| 6 | Documentation | `docs/*`, `README.md` |

## Milestones

### M0 — Foundation

Scope:
1. Repo layout, `product.env`, README with one-command local setup (`make dev`).
2. API skeleton: settings, JSON logs with request ids, error envelope, `/health/live`,
   `/health/ready`, Supabase JWT verification, `GET/PUT /v1/me` (farmer profile),
   `POST /v1/sync/push` + `GET /v1/sync/pull` (generic outbox ingestion with idempotency,
   last-writer-wins + audit), OpenAPI export.
3. DB: SQLAlchemy models `farmers`, `sync_mutations`; Alembic migration 0001 with RLS
   (owner-only) on every table; CI migration job against Postgres (upgrade → downgrade → upgrade).
4. App skeleton: Riverpod, go_router, theme tokens from the reference mockup (light + dark),
   bundled Baloo 2 + Mukta, i18n plumbing (`en` source, `mr`, `hi`), Drift DB + outbox +
   sync engine with exponential backoff, offline/sync banner, phone-OTP login flow behind an
   `AuthRepository` interface, Home screen ("today's orchard") built from design-system widgets
   with demo fixture data, component gallery behind `DEV_GALLERY`, admin web shell.
5. CI: lint, format, type, test, coverage gates, OpenAPI drift + Dart client generation,
   golden tests, APK build artifact.
6. Docs: ADRs, DESIGN_SYSTEM.md (initial), runbook for local dev.

DoD:
- [ ] `ruff`, `ruff format --check`, `mypy --strict`, `bandit`, `pytest` (≥85%) green.
- [ ] `dart format`, `dart analyze` (zero issues), `flutter test` green, logic coverage ≥80%.
- [ ] Golden tests for Home (mr, light + dark) committed and passing.
- [ ] Migration reversible against Postgres in CI; RLS enabled on every table.
- [ ] OpenAPI exported and Dart client generated with no drift.
- [ ] APK artifact built in CI.
- [ ] Demo checklist executed and recorded in `PROGRESS.md` (emulator, or documented substitute).
- [ ] ADRs written for every architectural choice.

### M1 — Orchard & bahar core

Files: `api/.../models/{plots,trees,bahar_cycles,crop_stage_templates,tasks}.py`, routers,
seed migration from `docs/agronomy/santra_*.md`; app `features/onboarding`, `features/plots`
(GPS walk/draw, area entry), `features/bahar` (cycle creation, stage calendar, bahar
selection assistant — rule config), `features/tasks` (+ reminders via push; WhatsApp/SMS adapters
stubbed behind interface). Wave-2 locales (`te`, `kn`, `ta`, `ml`) added as ARB + font-on-demand.
DoD: all writes offline + synced (integration test), goldens for each screen, design system doc
with gallery screenshots completed before UI work, agronomy citations reviewed.

### M2 — Records & accounts

Spray/input/irrigation/labour/expense/income/harvest records, voice-note quick entry, PHI/MRL
check, cost & profit per bahar, YoY, buyer dues, PDF/Excel export (Marathi fonts embedded).
DoD: calculations unit-tested with fixtures, exports golden-tested, offline entry tested.

### M3 — Photos & AI

Camera + compression (≤1000 px, q≈75), offline photo queue (metadata first, then bytes),
gallery; `api/.../ai/` two-stage Haiku → Sonnet diagnosis, prompt templates in DB (versioned),
prompt caching, Batch API for nightly jobs, per-user cost caps and `ai_usage`; voice assistant
via STT/TTS adapter, grounded answers with citations of records; admin usage dashboard;
rate limits on AI endpoints; signed photo URLs.
DoD: AI service tested with recorded fixtures (no live calls in CI), cost caps enforced.

### M4 — Weather & risk alerts

Open-Meteo adapter, per-plot pulls (ARQ jobs), history; configurable risk engine; alert
delivery (WhatsApp/SMS/push) with templates per language; morning brief; irrigation advisory.
DoD: rule engine property-tested; no rule constants in code.

### M5 — Market, schemes, community

Agmarknet adapter + community prices with moderation, trend chart, harvest-sell planner,
buyers & credit ledger, schemes directory with eligibility checklist, groups.

### M6 — Consultant/FPO mode & billing

Grants, consultant dashboard, broadcasts, comments, plans & Razorpay subscriptions/webhooks,
traceability QR report.

### M7 — IoT ingestion

MQTT → ingestion API → time-series table → risk engine; device registry/provisioning,
health alerts, sensor charts, sensor-based irrigation advisory.

### M8 — Hardening & launch

Low-end device profiling, size/battery/data audits, accessibility pass, store assets,
privacy policy, DPDP export/delete, load tests, backups, runbooks.

## Knowledge base & advice safety (addendum v1.3) — interleaved milestones

Hard rule until K1 is done: **no chemical name, dose or spray instruction reaches a grower** —
not in cards, task templates, alerts, AI answers or voice. Until a real expert reviewer is
attached (§6), only the safe subset ships: cultural practices, record-keeping, bahar calendar
dates, irrigation tables and weather risk alerts without chemical advice.

### K0 — Knowledge data model & source registry (with M1)
Files: `api/src/bagmitra_api/kb/` (models: `kb_sources`, `kb_topics`, `kb_cards`,
`kb_label_claims`, `kb_restrictions`, `kb_mrl`, `kb_models`, `kb_reviews`, `kb_conflicts`;
all content language-keyed with a human-review flag), migration with RLS (reference tables:
read for signed-in users, write for privileged roles), seed of `kb_sources` from addendum §2
with mandatory **tier** and **licence/allowed_use**, admin UI skeleton for sources and cards,
CCRI monthly calendar / irrigation-by-age / fertiliser tables loaded as **draft** cards.
DoD: every seeded source has tier + licence; licence rule enforced in code (no verbatim text
from `summarise_cite`/`cite_only` sources in user-visible fields; `internal_only` never reaches
growers) with tests; cards cannot be published without an expert review record.

### K1 — Legal & safety gate (before any chemical text ships)
Files: `api/src/bagmitra_api/kb/gate.py`, `kb/importers/` (CIB&RC major-uses, banned/
restricted list, FSSAI MRL; manual-upload fallback; dated, diffed), `kb/output_filter.py`
(active-ingredient + synonym/brand dictionary), nightly re-gate job.
DoD: addendum §9 gate tests (benomyl, dichlorvos, dicofol, phorate, chlorpyrifos on citrus,
dimethoate on raw-eaten fruit never appear; no label claim → suppressed; PHI vs planned
harvest blocks; a new ban pulls published cards; "ICAR-recommended, no label claim" renders
only as a reviewer-approved caution note); red-team tests; coverage ≥ 90 % on gate, filter and
model modules.

### K2 — Retrieval-grounded AI (with M3)
Postgres full-text + pgvector retrieval over published cards + the grower's records; answers
cite card ids; no card → "no verified answer" + expert escalation; photo diagnosis maps to
`kb_topics` and shows only gated cards; output filter on every AI/alert/voice text.
DoD: golden Q&A set (150+, mr/hi/en) with regression threshold gating merges.

### K3 — Weather-risk models (with M4)
`kb_models` with per-taluka calibration: heat/fruit-drop, psylla window + ACP degree-day model,
Alter-Rater, canker storm + flush, Phytophthora rainfall/soil.
DoD: model tests against hand-computed fixtures; alerts reviewed and gated.

### K4 — Ongoing
Reviewer onboarding, review-expiry automation (12 months; 6 for chemical cards), outcome
feedback loop, consented field image dataset, quarterly source re-verification.

### Impact on earlier M1 work
- `crop_stage_templates` (PR #7) stay as the bahar-calendar mechanism; their content will be
  generated from reviewed K0 cards (CCRI monthly guidance + PDKV), never from unreviewed text.
- `docs/agronomy/DRAFT_santra_mosambi_bahar_stages.md` is superseded as a source list by
  addendum §2–§3 (fetched and read, marked [V]); it remains as a cross-check only.

## Work queue from the owner's unblock message (2026-10-20)

Standing rule (spec §0 rule 8): when something is blocked, log it in `OPEN_QUESTIONS.md` with a
provisional default and move to the next unblocked item; "waiting for the owner" is not a state.
One PR per item, tests first, DoD checked at the end and recorded in `PROGRESS.md`.

| # | Item | Definition of Done |
|---|---|---|
| 1 | Register sources, seed draft cards from addendum v1.3 (K0 completion) | `kb_sources` seeded with tier, licence, allowed_use, URL, fetch date, hash (`fetch_failed` where blocked); §3 facts as **draft** cards with citations; no verbatim spans from `summarise_cite`/`cite_only` sources; nothing publishes |
| 2 | Local Supabase stack, runbook, end-to-end auth + sync tests (Q3) | `supabase start` config in repo, `docs/runbooks/supabase-setup.md` for the owner, real login and sync pass against the local stack in CI |
| 3 | Entitlement layer M6a | plans, `plan_entitlements`, `subscriptions`, `billing_events`, pure `compute_entitlements` with table-driven tests for every state, admin plan config, manual grants, app-side signed-snapshot cache and feature gating; no Play code |
| 4 | Headless emulator CI job (Q4) | emulator job installs the CI APK, runs integration tests (offline→online sync, add plot, GPS boundary with mocked fix, PDF export, share) and uploads screenshots |
| 5 | STT/TTS adapters and voice entry (Q5) | adapter interface, on-device adapter, cloud adapter stub behind config, voice-note → fields → confirm on records |
| 6 | Stage and monthly task templates from CCRI PDFs; season calendar, bahar selection assistant, tasks and reminders (push only) | templates tagged `CCRI monthly guidelines (interim)`; banned chemicals filtered by the gate; WhatsApp/SMS adapters stubbed behind config |
| 7 | Plot edit (with boundary), plot detail screen | edit saves offline; boundary re-walk; detail shows block summary |
| 8 | Weather adapter (Open-Meteo), forecast/history storage, M4 rule engine with v1.3 §3.7 models as `kb_models` | models table-driven tests against hand-computed fixtures; alerts via push; no chemical advice in alerts |
| 9 | Market prices adapter + price screen (M5 start) | Agmarknet adapter with manual-upload fallback; price screen offline |
| 10 | Design-system pass against §4A | goldens, screenshots in the PR, 2 GB device profile numbers in `PROGRESS.md` |

Billing (M6b–M6d) follows [`SPEC_billing_addendum.md`](SPEC_billing_addendum.md) after the policy
re-verification ADR.

### Re-prioritised 2026-10-20 (owner): a complete app in the test APK first, Play Store later
Items 1–5 are done (voice entry: PR #50 in review). The owner does not need a Play Store release
now; the goal is a **feature-complete app installable from the test-APK releases** for the owner
and a few growers to use. So the order is: 6 → 7 → 8 → 9 → 10, then M3 (photos, scouting log) and
the safe parts of M4/M5 (weather, price, irrigation tables, record templates, reminders), then
polish and the first-run walkthrough. **Parked until asked:** M6b–M6d (Play Billing, consultant
portal, hardening), Play Console / release runbook, store listing. Hard limits stay: no chemical
advice until the knowledge base has expert review and the legal gate (Q12), and real login and
sync wait for the hosted Supabase project (Q3), so the test build runs in offline test mode.

