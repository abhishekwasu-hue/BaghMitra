# Supabase setup

Development and every integration test use a **local Supabase stack**. The hosted project is
created by the owner later; switching only changes environment variables (no code change).

## Local stack (developers and CI)

Needs Docker and the Supabase CLI (`npx supabase` works).
```
supabase start                      # uses supabase/config.toml
supabase status -o env              # API_URL, ANON_KEY (or PUBLISHABLE_KEY), DB_URL, JWT_SECRET
cd api
export SUPABASE_URL=http://127.0.0.1:54321
export SUPABASE_ANON_KEY=<ANON_KEY or PUBLISHABLE_KEY from status>
export SUPABASE_DB_URL=postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres
export SUPABASE_JWT_SECRET=<JWT_SECRET from status>        # projects that sign with the shared secret
pytest -m supabase --no-cov
supabase stop
```
The test signs in two growers by phone OTP (`+919800000001`, `+919800000002`, fixed code `123456`,
set in `supabase/config.toml`; no SMS is sent), applies the Alembic migrations to the stack's
database, then pushes and pulls through the API. It accepts whichever token scheme the stack
uses: shared secret (HS256) or the published asymmetric keys (ES256 / RS256, via
`SUPABASE_JWKS_URL = $SUPABASE_URL/auth/v1/.well-known/jwks.json`). CI runs the same job
(`.github/workflows/supabase.yml`).

To run the app against the local stack: `flutter run --dart-define=SUPABASE_URL=http://10.0.2.2:54321
--dart-define=SUPABASE_ANON_KEY=<key>` (10.0.2.2 is the host as seen from the Android emulator;
sign in with `9800000001` and OTP `123456`).

## Hosted project: steps for the owner (Supabase dashboard)

1. **Create the project.** Region **ap-south-1 (Mumbai)**. Choose a strong database password and
   keep it in your password manager.
2. **Phone sign-in.** Authentication → Sign In / Providers → **Phone**: enable, pick an SMS
   provider (Twilio, MessageBird, Textlocal or Vonage) and enter its credentials. Sending SMS to
   Indian numbers needs a registered DLT sender and template with the provider. Set the OTP
   length (6) and expiry (e.g. 300 s). Leave *confirm phone* on.
3. **Signing keys.** Settings → JWT Keys: use the asymmetric signing keys (recommended) and note
   the JWKS URL `https://<ref>.supabase.co/auth/v1/.well-known/jwks.json`; if you stay on the
   legacy shared secret instead, copy the JWT secret. The API accepts either.
4. **Database schema and RLS.** Never create tables in the dashboard. From a checkout, run the
   migrations (they enable row-level security on every table with its policies):
   `cd api && DATABASE_URL=postgresql+asyncpg://postgres:<password>@db.<ref>.supabase.co:5432/postgres alembic upgrade head`
   (use the *direct* connection string, not the pooler, for migrations).
5. **Storage buckets** (all **private**; created later when features need them):
   `plot-photos`, `diagnosis-photos`, `voice-notes`, `kb-documents` (admin only), `exports`.
   Each gets an owner-only policy (`(storage.foldername(name))[1] = auth.uid()::text`) added by a
   migration, not by hand.
6. **Staff roles.** Give an admin or reviewer their role through the Auth admin API with the
   service-role key (roles live in `app_metadata`, which users cannot edit):
   `PUT /auth/v1/admin/users/<user id>` with `{"app_metadata": {"roles": ["kb_admin"]}}`
   (reviewers: `["kb_reviewer"]` and `"reviewer_role": "agronomist"`).
7. **Secrets.** Put these in GitHub → Settings → Secrets and variables → Actions (and in the API
   host's environment). Never commit them:

   | Name | Where it comes from | Used by |
   |---|---|---|
   | `SUPABASE_URL` | Project settings → API | app (dart-define), API, CI |
   | `SUPABASE_ANON_KEY` | publishable / anon key | app (dart-define), CI |
   | `SUPABASE_SERVICE_ROLE_KEY` | secret / service-role key | staff-role script only, **never the app** |
   | `SUPABASE_JWT_SECRET` | JWT Keys (legacy secret) | API (if not using JWKS) |
   | `SUPABASE_JWKS_URL` | JWT Keys | API |
   | `DATABASE_URL` | Database → Connection string (direct, with `postgresql+asyncpg://`) | API, migrations |

8. **App build.** `flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
   (and `--dart-define-from-file=product.env`). With `SUPABASE_URL` unset the app runs in demo mode.
