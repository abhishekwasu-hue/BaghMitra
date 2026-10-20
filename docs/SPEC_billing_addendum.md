# BagMitra — Billing & Android Release Addendum (Spec v1.1, billing)

This addendum **replaces** every mention of Razorpay-in-app billing in `bagmitra_spec_v1.md` (§2 stack, §3 `plans/subscriptions/payments`, §4 Milestone M6 "Consultant/FPO mode & billing"). All other sections stay. Same standing rules as the main spec (§0): English only, test-first, contract-first API, small PRs with self-review checklist, offline-first, no hardcoded business values, never stop to wait for the owner (log questions in `docs/OPEN_QUESTIONS.md` with a provisional default and continue), never deploy to production.

Start this work when you reach M6. Before writing any billing code, do step 0 below.

---

## 0. Re-verify policy first (mandatory, before coding)

Billing policy changes often. At the start of M6, re-read these official sources and write the current facts, with the date, into `docs/adr/00NN-billing.md`. If anything below has changed, follow the current official text and log the difference in `OPEN_QUESTIONS.md`.

- Google Play Payments policy: https://support.google.com/googleplay/android-developer/answer/9858738
- Play Developer API deprecations: https://developer.android.com/google/play/billing/play-developer-apis-deprecations
- Play Billing Library release notes and Play Billing docs on developer.android.com
- Google Play service fees and India programs in Play Console (current rates, user choice billing, alternative billing, consumption-only model)

Facts verified on 2026-10-12 (re-check them):
1. Apps that charge for in-app features, services or digital content — explicitly including subscriptions and cloud software such as business productivity tools — must use Google Play's billing system. The policy text has no explicit B2B exemption.
2. Apps must not steer users to other payment methods through listings, in-app promotions, webviews, buttons, links, ads or sign-up flows, except under the alternative-billing / external-link programs where the developer is enrolled and the country is eligible.
3. India: a 2023 Google announcement describes three options — Google Play Billing; alternative billing alongside Play Billing (user choice billing, fee 4 percentage points lower); or a consumption-only model with no in-app purchase and no service fee. Confirm in Play Console that these still apply to India and what enrolment requires.
4. New apps and updates must use Play Billing Library 8 or later (deadline 31 Aug 2026, extension to 1 Nov 2026 available).
5. Deprecated subscription APIs (v1 `purchases.subscriptions.get/refund/revoke/cancel/defer`) are replaced by `purchases.subscriptionsv2` (`get`, `revoke`, `cancel`, `defer`) and `Orders.refund`. Use v2 only. The RTDN field `SubscriptionNotification.subscriptionId` is deprecated with no replacement; `SUBSCRIPTION_PRICE_CHANGE_CONFIRMED` is replaced by `SUBSCRIPTION_PRICE_CHANGE_UPDATED`.
6. Service fee for auto-renewing subscriptions was reported as 15% (third-party source, Oct 2026). Confirm the exact rate and any programme discounts in Play Console; make the fee percentage a config value used only for revenue reporting.

---

## 1. Product decisions (defaults; change only through an ADR)

- **Grower plans (Free / Grower Pro)** are sold **only through Google Play Billing** as auto-renewing subscriptions: monthly and annual base plans, optional free-trial / introductory offers. No Razorpay, UPI link or "pay on our website" text anywhere inside the app for these plans.
- **Consultant / FPO plans (B2B)** default to the **consumption-only model**: the Android app has *no* purchase UI, no prices and no external-payment links for these plans. Organisations buy through a separate **web portal with invoicing (Razorpay or bank transfer)**; the owner activates the plan (manual grant, §3). Consultant users simply log in to the app and see features their organisation's entitlement allows. Log the question "Is consumption-only still valid for India, and may the app mention that a plan exists elsewhere?" in `OPEN_QUESTIONS.md` with default = show nothing about purchasing for these plans. Keep the entitlement layer provider-agnostic so this can be switched to Play Billing or user-choice billing later without a rewrite.
- **Course bundle / promo access:** students of the owner's course get Grower Pro through server-side manual grants (§3) or Play promo codes. Never through an external payment path inside the app.
- **Data is never held hostage:** when a subscription lapses, premium *features* lock, but the grower's own records stay readable and exportable (PDF/Excel) on the Free tier at all times.
- **Prices live in Play Console** (source of truth). The app shows `ProductDetails` localized prices and never hardcodes amounts. Pricing text in the app must match the Play billing UI exactly.

---

## 2. Architecture

### 2.1 Entitlement layer (provider-agnostic)
Tables (tenant-scoped with RLS): `plans`, `plan_entitlements` (plan → feature keys and limits, config, admin-editable), `subscriptions` (farmer or organisation, `provider` enum: `google_play | web_invoice | manual_grant`, `provider_product_id`, `purchase_token_hash` unique, `state`, `period_start`, `period_end`, `auto_renew`, `grace_until`, `last_verified_at`), `billing_events` (append-only ledger of every Play notification and verification result, idempotent on notification id), `entitlement_snapshots` (computed result the app downloads).
A single function `compute_entitlements(subject, now)` is the only place that decides what a user may use. It is a pure function over subscription rows and plan config, covered by table-driven tests for every state below.

### 2.2 Subscription state machine
Map Play `subscriptionState` and RTDN types to internal states with explicit, tested transitions: `PENDING`, `ACTIVE`, `IN_GRACE_PERIOD` (keep access), `ON_HOLD` (suspend access, keep data), `PAUSED`, `CANCELED` (access until `period_end`), `EXPIRED`, `REVOKED`/voided (immediate loss), plus upgrade/downgrade/re-subscribe via `linkedPurchaseToken`. Notifications are only hints: on every RTDN, re-fetch the truth from `purchases.subscriptionsv2.get` and recompute.

### 2.3 Client (Flutter)
- Use the official `in_app_purchase` + `in_app_purchase_android` packages, but **verify the Billing Library version they bundle is 8+**. If the packages lag, write a thin Kotlin platform-channel wrapper around Billing Library 8+ behind a Dart interface, with contract tests. Pin versions; add a CI check that fails if the resolved Billing Library is below 8.
- Flow: load products → show paywall (localized price, billing period, free-trial terms, what is included, how to cancel) → launch billing flow with `obfuscatedAccountId` = stable hash of the farmer id → on purchase, send the purchase token to our API → **only after the server confirms** unlock and call `acknowledgePurchase` (or let the server acknowledge — pick one in the ADR; unacknowledged purchases are refunded by Google after 3 days) → refresh entitlements.
- Handle pending purchases, user cancel, already-owned, network errors, app killed mid-purchase (on startup, query purchases and reconcile), and "Restore" for reinstalls / new phones.
- Offline-first: cache the server-signed entitlement snapshot (with `valid_until` and a grace margin) so features keep working offline; sync on reconnect. The client never decides entitlements by itself.
- Add the required subscription disclosures and a "Manage subscription" deep link to the Play subscriptions page.

### 2.4 Server (FastAPI)
- Endpoints (OpenAPI first): `POST /billing/google/verify`, `GET /billing/entitlements`, `POST /billing/google/rtdn` (Pub/Sub push), admin endpoints for manual grants, plan config and billing event inspection.
- Verification: Google Play Developer API `purchases.subscriptionsv2.get` using a service account with minimum Play Console permissions; credentials from environment/secret store only. Reject a purchase token already bound to a different farmer (unique constraint on `purchase_token_hash`); confirm `externalAccountIdentifiers` matches the caller.
- RTDN: Cloud Pub/Sub push subscription with OIDC token verification; idempotent processing; dead-letter handling; metrics and alerts for failures and lag. Poll the Voided Purchases API on a schedule as a safety net.
- Background reconciliation job: re-verify all subscriptions nearing `period_end` and any stuck in `PENDING`/`ON_HOLD`; log drift.
- Admin: manual grant with plan, expiry, reason and audit trail (used for the course bundle, FPO plans and support); revenue dashboard showing gross, estimated Google fee (config %), net, churn and trial conversion.

### 2.5 Web portal for B2B (separate from the app)
A minimal web portal (same backend) for consultants/FPOs: choose plan and seats, pay by Razorpay or request an invoice, download GST invoices, and see their activation status. Webhooks are verified and idempotent and create `web_invoice` subscriptions. This portal is **never linked from the Android app**.

---

## 3. Testing & quality gates (in addition to §0 of the main spec)

- Unit tests: `compute_entitlements` for every state and transition including grace, hold, upgrade, refund, expiry, clock edges; plan-config edge cases.
- Contract tests for the Play API client against recorded fixtures plus a local fake Play API server for integration tests (verify → entitlement → app snapshot; RTDN → state change; duplicate and out-of-order notifications; replayed token from another account).
- App tests: paywall golden tests (Marathi/Hindi/English, light/dark), purchase flow with a fake billing adapter, interruption recovery, offline entitlement behaviour.
- Manual test plan in `docs/runbooks/play-billing-testing.md`: licence testers, internal testing track, test subscriptions with accelerated renewal, cancel/resume, grace/hold simulation, refund. Record results in `docs/PROGRESS.md`.
- Security review checklist: no secrets in repo, least-privilege service account, token hashing at rest, rate limits on verify, RLS tests for billing tables.
- Coverage gates from the main spec apply; billing modules require ≥ 90% on the server side.

---

## 4. Play Console / release checklist (document in `docs/runbooks/play-release.md`)

Items the **owner** must do are marked (owner); everything else is yours to prepare.
- Developer account type decision: personal (needs a closed test with 12 testers for 14 continuous days) vs organisation (needs D-U-N-S) (owner). Prepare the tester onboarding instructions and an in-app feedback channel.
- Create the app, subscription products, base plans and offers; product IDs must be defined in config and mirrored in the runbook (owner creates in Console; you supply exact names, periods and offer definitions).
- Pub/Sub topic + RTDN configuration, service account and Play Console API access (owner grants; you provide the exact steps and required permissions).
- Privacy policy URL, Data safety form content (list every data type collected: phone number, location/GPS, photos, voice, device ids, payments info handled by Play), permission rationale texts for camera, microphone and location, target-API level compliance, app signing and Play App Signing setup, AAB build in CI.
- Store listing: Marathi, Hindi, English titles/descriptions, screenshots generated from the design system, content rating questionnaire, subscription terms text.
- Staged rollout plan (internal → closed → production at 10%, 50%, 100%) with crash-rate and billing-error gates.

---

## 5. Milestones (replaces old M6)

- **M6a — Entitlements:** tables, `compute_entitlements`, admin plan config UI, manual grants, app-side entitlement cache and feature gating. No Play code yet.
- **M6b — Play Billing:** client integration, server verification, RTDN, reconciliation, voided purchases, paywall UI, full test suite, runbooks.
- **M6c — Consultant/FPO:** roster dashboard (from the main spec) gated by entitlements; web portal with Razorpay/invoices; admin activation.
- **M6d — Hardening:** security review, load test of verify/RTDN paths, failure-injection tests (Play API down, Pub/Sub retries), final Play release checklist dry run.

Definition of Done for each sub-milestone is written in `docs/PLAN.md` before work starts and executed by the session at the end (emulator demo + test results recorded in `docs/PROGRESS.md`).
