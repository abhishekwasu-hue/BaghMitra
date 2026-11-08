# ADR 0008 — Subscription billing through Google Play (addendum §0, §7)

Status: Accepted · 2026-11-08

## Facts re-verified on 2026-11-08 (billing addendum §0)
Sources read on this date: developer.android.com `google/play/billing/price-changes`,
`deprecation-faq`, `play-developer-apis-deprecations`, `rtdn-reference`; the androidpublisher v3
discovery document (revision 20261105); pub.dev `in_app_purchase_android` changelog.
support.google.com (Payments policy, service fees) could not be reached from the build session:
the owner checks those in Play Console (runbook `billing-play.md` §१).

1. Play Billing Library: new apps and updates must use version **8 or later** since
   31 Aug 2026 (extension ended 1 Nov 2026); version 8 is deprecated on 31 Aug 2027.
   `in_app_purchase_android` 0.5.5 bundles Billing Library **9.1.0** (min Android SDK 23).
2. Server APIs: `purchases.subscriptionsv2.get` (v1 `subscriptions.get` / `refund` / `revoke`
   deprecated since May 2025, shut down 31 Aug 2027; v1 `cancel` / `defer` deprecated since
   19 May 2026). `purchases.subscriptions.acknowledge` is **not** deprecated. Prices:
   `monetization.subscriptions.patch` (`updateMask`, `regionsVersion.version`), existing
   subscribers: `basePlans.migratePrices` (`PRICE_INCREASE_TYPE_OPT_IN` / `_OPT_OUT`).
   Voided purchases: `purchases.voidedpurchases.list` (`type=1` includes subscriptions, at most
   30 days back).
3. Price increases: opt-in by default; the user is charged after a **37-day** notice; Play
   notifies from 30 days before the charge (7 days after the change starts); a user who does not
   accept is cancelled at that renewal. Decreases reach existing subscribers at the next payment.
   Opt-out increases need an in-app notice; for opt-in, the app should tell users to accept
   (Play's in-app messaging can show it).
4. RTDN: Pub/Sub push, base64 `DeveloperNotification`; subscription types (1)–(13), (17)–(20);
   `SUBSCRIPTION_PRICE_CHANGE_CONFIRMED` replaced by `SUBSCRIPTION_PRICE_CHANGE_UPDATED` (19);
   `subscriptionId` deprecated with no replacement; `voidedPurchaseNotification` for refunds.

## Decisions
- **Play is the only purchase path in the Android app** (addendum §1). No price, payment, UPI or
  QR wording in the app outside the Play paywall, which shows Play's own localized price.
- **Admin switch** `billing_settings.enabled`, default OFF (§7). OFF or before the start date:
  the full app for everyone. **Nothing is locked even when ON** until the owner names what a
  plan unlocks (OPEN_QUESTIONS Q118); the gate map `GATED_FEATURES` stays empty.
- **One monthly product per role** `PLAY_PRODUCT_PREFIX + role` with base plan
  `PLAY_BASE_PLAN_ID`; the admin's amount is written to Play first, then stored as Play reports
  it. Existing subscribers move only by the admin's confirmed `migratePrices` (opt-in).
- **The server acknowledges** a purchase after `subscriptionsv2.get` confirmed it; the app never
  acknowledges. The app passes `obfuscatedAccountId` = SHA-256 of `bagmitra-play:<user id>`;
  the server checks it.
- **Purchase tokens are stored only as SHA-256 hashes** (addendum §3). Consequence: the server
  cannot re-ask Play about a token on its own schedule. Truth arrives by (a) the app's
  verify call on purchase, restore and every app start, (b) RTDN, which carries the token,
  (c) the daily voided-purchases poll, which carries the token. The daily job also lists drift
  (rows past their end without an update). OPEN_QUESTIONS Q120.
- **RTDN** authenticated by the Google-signed OIDC token of the push subscription (audience and
  push service account checked); idempotent on the Pub/Sub message id; a notification is only a
  hint, the state always comes from `subscriptionsv2.get`.
- **Credentials only from the server environment**: `PLAY_SERVICE_ACCOUNT_B64`,
  `PLAY_PACKAGE_NAME` (secret store on the VPS). Google is never called in tests or CI.
- **Fees are for using the app only**, never a charge on any deal; a user's own records stay
  readable and exportable whatever the plan state.
- **Before the switch is first turned ON**: a CA's GST opinion (owner), the Play Console
  products and the service account per `docs/runbooks/billing-play.md`.
