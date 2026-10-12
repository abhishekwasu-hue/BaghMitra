# Open questions

Each item has a provisional default that the work proceeds on. Owner: answer inline or in a PR.

| # | Question | Provisional default |
|---|---|---|
| Q1 | The spec asks for a new `bagmitra` repo; this session could only write to `trade`. Create a separate repo? | **Resolved 2026-10-12:** moved to `abhishekwasu-hue/BaghMitra` with full history (ADR 0001). |
| Q2 | M0 is one PR well over the 400-line rule (foundation spans API, app, CI, docs). | Accept for M0 only; from M1 on, one feature per PR ≤ 400 production lines. |
| Q3 | Supabase project, JWT secret and anon key are not available yet. | API verifies HS256 tokens from env; app runs in **demo mode** (local OTP, no backend) when `SUPABASE_URL` is unset. |
| Q4 | Android emulator demo (DoD) cannot run in this cloud container (no KVM/Android SDK). | Demo executed via widget/golden tests at phone size plus a web build; APK built in CI. Emulator run to be recorded by the first session that has one. |
| Q5 | STT/TTS provider: Bhashini, Sarvam or Google? | Decide in M3; keep adapter interface. Mic buttons exist in the design system but are not wired on screens until STT works (no dead buttons). |
| Q6 | Default app language when the device language is unsupported. | English (spec: fall back to English). Onboarding (M1) asks the grower to pick their language explicitly, Marathi first. |
| Q7 | Home must fit without scrolling on a 5.5" screen; at 393×851 dp the market card is just below the fold. | Tighten header/stage-card heights in the M1 design-system pass and add a golden that asserts it. |
| Q8 | Demo "today's orchard" content (tasks, alert, price) is sample data. | Shipped as a language-keyed asset with a visible "Sample data" chip; replaced by real data as M1–M5 land. Not used by any logic. |
| Q9 | Repository is named **BaghMitra**; the spec and app say **BagMitra**. Which spelling is the product name? | **Resolved 2026-10-12:** the product is **BagMitra** in every language, written **बागमित्र** in Marathi and Hindi. Display name = `appName` in `app/lib/l10n/app_<lang>.arb` (app title) + `android/app/src/main/res/values*/strings.xml` (launcher label; a test keeps them in sync). `product.env` holds the Latin name for the API and admin. The repository keeps the name BaghMitra. iOS localized launcher names come with iOS work. |
