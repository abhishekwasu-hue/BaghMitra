# Build prompt — subscription billing (M6b + admin switch and per-role prices)

```
TASK: Build subscription billing per docs/SPEC_billing_addendum.md, including the new §7 (owner decisions
2026-11-07). Read OWNER_RULES.md, the PROGRESS resume block, the billing addendum (all of it once: §0 says
re-verify Play policy first and record the result), and the existing M6a code in
api/src/bagmitra_api/billing/ and routers/admin_billing.py.
Build:
1. Admin settings: global switch subscriptions_enabled (default OFF) + optional start date, and one
   monthly ₹ amount per role (grower, trader, broker, exporter, service provider), empty by default. OFF or
   empty amount = free. Every change logged in billing_events with admin id and old / new values.
2. Saving an amount calls the Play Developer API monetization.subscriptions.patch for that role's monthly
   base plan (India); show the price Play returns. Behind an adapter with a fake for CI; never call Google in
   CI; credentials from env only. Show Play's price-change rules (spec §7) on the page before saving; a
   separate, confirmed action runs basePlans.migratePrices for existing subscribers.
3. compute_entitlements: switch OFF -> full features for all; ON -> role plan required for paid features; a
   multi-role user needs one plan (the higher-priced role covers both). Table-driven tests for every case.
4. M6b as the addendum describes: Play Billing client (Billing Library 8+ check in CI), server verify,
   RTDN with OIDC check, reconciliation job, voided purchases poll, paywall with Play's localized price, the
   required in-app price-increase notice with a deep link to Play's subscription page, Restore, Manage
   subscription link.
5. Never: a fee on any deal, a hardcoded price, an external payment link inside the app, locking a user's own
   records (they stay readable and exportable on free).
6. Write docs/runbooks/billing-play.md with the owner-side steps (Play Console products per role, service
   account, Pub/Sub, secrets) and mark the CA GST opinion as required before the first switch ON.
Quality: tests first; ≤ 400 production lines per PR; self-review every diff; run the repo checks; merge only
when green; match the existing UI (design_system), uncluttered; Marathi phone screenshots (light + dark) for
every UI PR. Log questions in OPEN_QUESTIONS.md with a default and continue. Run this alongside the market
linkage build only if it does not block it; otherwise finish the current market-linkage PR first.
```
