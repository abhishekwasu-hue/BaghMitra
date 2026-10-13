# Local development

Prerequisites: Docker, Python 3.12, Flutter 3.47.5 (stable; goldens are rendered with it).

```bash
cd bagmitra
make dev          # Postgres+PostGIS and the API on :8000 (migrations run on start)
make api-check    # ruff, format, mypy --strict, bandit, pytest (coverage ≥ 85%)
make app-check    # dart format, analyze, flutter test (goldens), logic coverage ≥ 80%
make app          # run the app on an Android emulator against the local API
```

API without Docker: `cd api && python3.12 -m venv .venv && . .venv/bin/activate &&
pip install -e ".[dev]" && cp ../.env.example .env && alembic upgrade head &&
uvicorn bagmitra_api.asgi:app --reload`.

Postgres-only tests (RLS, reversible migrations):
`POSTGRES_TEST_URL=postgresql+asyncpg://postgres:postgres@localhost:54322/bagmitra pytest -m postgres --no-cov`.

**Reference data:** `python -m bagmitra_api.kb.seed` (idempotent) loads the knowledge-base
source registry (addendum v1.3 §2) and the banned/restricted pesticide list (§3.8) from
`api/src/bagmitra_api/kb/seed_data/`. `make dev` runs it on start.

**Label claims and restrictions (manual upload):** an admin checks a CSV by hand, then
`python -m bagmitra_api.kb.importers claims cibrc_insecticides_pgr claims.csv` (or
`restrictions ppqs_banned_restricted bans.csv`). Any bad row rejects the whole file. The
output is a diff (added / changed / removed / unchanged); changed and removed claims are
end-dated, never deleted; restrictions are never removed by an upload. Each import re-gates
published cards. Nightly: `python -m bagmitra_api.kb.regate` pulls any published card that
now fails the gate back to draft and writes a `kb_admin_alerts` row (service-only table).

**Knowledge-base admin API** (`/v1/admin/kb/*`): sources, cards, card reviews, publish,
CSV imports and alerts. Access comes from Supabase **`app_metadata`** (only the service role
can set it; `user_metadata` never grants anything): `{"roles": ["kb_admin"]}` to import,
publish and resolve alerts; `{"roles": ["kb_reviewer"], "reviewer_role": "agronomist"}`
(or `plant_pathologist` / `entomologist`, see `KB_REVIEWER_ROLES`) to review. Publishing
re-runs the legal gate on the card's chemical options and returns 409 with the reasons.

**Changing the API:** edit code + tests → `make openapi` (exports the spec, copies it into the app,
regenerates the Dart client) → commit all three.

**Goldens:** `cd app && flutter test --update-goldens test/goldens`, then look at every changed PNG
before committing.

**Demo mode:** without `SUPABASE_URL`/`SUPABASE_ANON_KEY` the app signs in locally with any
6-digit OTP and keeps writes queued (no backend calls). Dev gallery: `--dart-define=DEV_GALLERY=true`.
Admin web: `flutter run -d chrome -t lib/main_admin.dart`.
