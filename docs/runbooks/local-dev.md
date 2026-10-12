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

**Changing the API:** edit code + tests → `make openapi` (exports the spec, copies it into the app,
regenerates the Dart client) → commit all three.

**Goldens:** `cd app && flutter test --update-goldens test/goldens`, then look at every changed PNG
before committing.

**Demo mode:** without `SUPABASE_URL`/`SUPABASE_ANON_KEY` the app signs in locally with any
6-digit OTP and keeps writes queued (no backend calls). Dev gallery: `--dart-define=DEV_GALLERY=true`.
Admin web: `flutter run -d chrome -t lib/main_admin.dart`.
