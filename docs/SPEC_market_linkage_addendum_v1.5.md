# BagMitra — Market Linkage Addendum (Spec v1.5)

Same standing rules as the main spec §0 and OWNER_RULES.md (English only in this file; the app shows
Marathi / Hindi / English; test-first; PRs ≤ 400 production lines with self-review; offline-first;
log questions in `docs/OPEN_QUESTIONS.md` with a default and continue). Research behind every fact
here: `docs/research/MARKET_LINKAGE_RESEARCH.md`. **Status: approved by the owner 2026-11-07; building (L0a merged, #155). Introduction-only revision 2026-11-07 (§1 core principle).** Audit 2026-11-07:
research §6.

## 1. Owner decision (2026-11-07)
- BagMitra has **no capital**. It never buys, sells, owns or stores produce and never holds money.
- BagMitra is only the **link**: registered growers show their produce (photos and details), mandi
  traders reach them directly, and the work in between is done by **third parties** who already
  exist locally but are not organised — truck owners, weighbridges, and the like. BagMitra
  organises them in one place.
- Goal: more growers register because the app brings them buyers and services.
- **Business model (owner 2026-11-07)**: monthly subscription fee per user for using the app — never a
  commission or share of any deal. Tiers designed later: low for growers, low for brokers, higher for
  exporters (Q62). Build no fee until then; it will use the billing addendum's entitlement layer.
- This replaces OPEN_QUESTIONS Q47 "no in-app trading or offers" for this module only.
- **Core principle (owner, 2026-11-07, restated firmly): BagMitra only introduces grower, trader and
  broker to each other. It never enters their transaction or their disputes — weighing, transport,
  payment and any quarrel are settled by them locally. The app is made strong against fake users and
  fraud on the platform, nothing more.** Where an older line below says otherwise, this line wins.

### 1.1 How the trade works today (owner's village, stated 2026-11-07)
Background only (owner, 2026-11-07): this is the owner's example, not a list of app rules. The app
covers only the grower ↔ trader deal (with a broker when there is one). **What the trader does with
the produce after buying it is outside BagMitra entirely** (Q65).

1. A local or nearby **broker (dalal)** brings a **trader** to the orchard, shows it, and negotiates
   with the grower. The broker takes a commission (owner: usually 2 %). **Owner decision
   2026-11-07: the app never records, asks for or shows a broker's commission or income** — it is
   their private matter, and recording it would bring income-tax / GST worries that make brokers
   avoid the app.
2. The trader fixes a **harvest date** and the **deal basis**: by the tonne, by the crate (crates
   filled and counted), or one lump sum for the whole orchard.
3. The deal and the agreed give-and-take conditions are written on **rough paper** (no bond paper).
4. After harvest the trader either sells on the spot to a **bigger trader** or sends the fruit by
   transport to a **mandi**.

Owner's aim: bring **trader, broker and grower onto one platform**, so good traders meet good
growers, good brokers get more work, and each broker and trader has a public profile — name,
contact number and ratings — that a grower can read easily. This narrows the gap between them.

## 2. Roles
| Role | Who | Joins by |
|---|---|---|
| Grower | Existing BagMitra user with a plot and bahar | Already registered |
| Buyer (trader) | Village / mandi trader, bigger trader, commission agent, exporter, processor | Self-registers; admin verifies before any lot is visible |
| Broker — app label **"मध्यस्थ (दलाल)"** (hi "मध्यस्थ (दलाल)", en "Broker") | Local or nearby broker who brings traders to orchards | Self-registers; admin verifies |
| Service provider | Weighbridge, transporter / truck owner, harvest labour gang, crate / packing supplier | Self-registers or admin adds; admin verifies |
| Admin (BagMitra) | Owner / staff | Admin web (ADR 0006) |
| BagMitra representative | Field person appointed by admin | Admin grants the role; can only add a place photo and address to a trader / broker / exporter / provider profile they visited; every upload records who and when |

### 2.1 Sign-in and role entry (decided 2026-11-07)
- **One sign-in for everyone** (the existing phone OTP / Google). The first screen shows **five** large
  role cards (owner 2026-11-07: "5 darvaje"): **शेतकरी**, **व्यापारी**, **मध्यस्थ (दलाल)**,
  **निर्यातदार**, **सेवा देणारे** (वजनकाटा, वाहतूक, मजूर, क्रेट). The card picks the role; the sign-in
  after it is the same.
- One person may hold several roles (one account, one phone, one set of registration numbers); a role
  switch sits in the app bar. Each role has its own home screen and its own verification state.
- Why not separate logins: one person in two roles would need two accounts, ratings would split, and the
  "one registration number, one profile" fraud check would break; the existing OTP sign-in is tested.
- "मध्यस्थ" is used, not "अडत्या" (the APMC Act term for a licensed commission agent — using it would
  suggest BagMitra deals with licensed adat) and not "दलाल" alone (carries a negative sense in speech);
  "(दलाल)" is shown under it so growers recognise the role.

## 3. Flow (introduction only)
1. **Lot** — grower picks a plot and bahar; crop and variety come from the plot. Fields: estimated
   quantity (tonnes), size / quality (chips to tick plus a short line), harvest window (one start
   date, defaulting from the bahar stage; the end follows by the admin's number of days, default 15,
   and can be changed, Q138), sale basis (per quintal / per crate / whole orchard on tree; per quintal
   is the mandi price's unit, Q138), optional asking rate (inside the admin's range per crop, per quintal /
   per crate, Q138; a trader's offer is checked against the same range),
   3–8 photos taken **in the app camera only**, each with capture time and GPS. The lot screen shows
   the day's mandi modal price (Q48 fair-price check) beside the asking rate.
2. **Visibility** — only verified traders, exporters and brokers see lots. They see village / taluka,
   never the grower's name, phone or plot pin. A grower can also invite a chosen trader or broker from
   their public profile (§3A).
3. **Interest (offer)** — a trader sends, directly or through a named broker: rate and basis, quantity,
   proposed harvest date. That is all; everything else they settle face to face. Several per lot.
4. **Accept = introduction** — the grower compares interests (rate, verified badges, deal count,
   stars, mandi price that day) and accepts one or more. Accepting reveals both sides' name, phone and
   the plot pin to each other. Nothing else is recorded about their deal.
5. **Off the app** — weighing, crates, labour, transport, payment and any dispute are between them and
   settled locally. BagMitra does not record, confirm, guarantee or judge any of it.
6. **Service directory** — listed weighbridges, transporters, labour gangs and crate suppliers near the
   plot, with phone numbers to call. No booking through the app; they agree and pay among themselves.
7. **"Deal done"** — when both the grower and the trader tap "deal done", rating opens for both (and
   for the broker, if named) for 7 days from that tap (Q66). The grower may copy the sale into their
   own Accounts book (their private record, as today). If one side never taps, there is no rating.

## 3A. Public profiles and ratings (owner request)
- Every verified **trader** and **broker** has a profile any registered grower can open: name, firm
  (if any), village / market, **contact number**, crops and areas, number of completed deals,
  average rating per question and the count of each ticked tag. A list per taluka, sortable by
  rating and deals.
- Grower profiles are not public; a grower's contact is shown only to parties of an accepted deal.
- **Only a party to a completed deal can rate**, once per deal, so ratings come from real trades.
- **No typing in ratings (owner decision 2026-11-07).** A rater only gives stars and ticks tags from
  a list BagMitra defines, so abusive words can never appear and the admin does not read each
  rating. There is no free-text field, no comment and no public reply anywhere in ratings.
- Rating questions follow the deal terms the owner listed, each 1–5 stars:
  - Trader: came on the agreed harvest date; weighing / crate count was correct; paid advance and
    balance as agreed; kept the other conditions.
  - Broker: represented the deal honestly; the trader they brought kept the deal.
  - Grower: produce matched the photos and description; ready on the agreed date.
- **Tags**: under each question an optional set of predefined tags to tick (for example "came on
  the agreed date" / "came late", "payment on time" / "payment late"). The tag list is a server
  table `rating_tags` (mr / hi / en, one Marathi term per concept per GLOSSARY_mr.md) that only
  admin edits in the admin web; the app caches it offline and shows only tags from that list.
- Rating opens when both sides tap "deal done" (§3 step 7) and can be given or changed for **7 days**
  from that tap; then it is locked (Q66). A person who thinks a rating is fake uses "report" (§4,
  reason "fake rating"); admin checks only whether the deal and the people are real, never who was
  right in a business quarrel.

## 4. Verification — zero-cost checks only (owner decision 2026-11-07)
Owner: BagMitra is a startup; no paid third-party KYC. Use only free official public checks, done by
the admin by hand from a link the admin page opens. Research: MARKET_LINKAGE_RESEARCH.md §5.
- **No Aadhaar** number, card image or OTP is collected anywhere (Aadhaar authentication by a private
  entity needs government approval; DPDP Rules 2025). DigiLocker consent pull is a later option once
  BagMitra has its registered company and GSTIN (API Setu verifies the entity's GSTN) — not built now.
- **Never automate** the government portals (they use captchas; no scraping). The admin page shows a
  button that opens the official page with the number to check; the admin records the result.
- Checks and the badge each one gives (badge text says what was checked and on which date — "checked
  on the public register on <date>", never "guaranteed"):

| Check (free) | Who | How the admin checks | Badge |
|---|---|---|---|
| Phone OTP | all | sign-in (exists) | — (required) |
| GSTIN | trader, exporter (if held) | GST portal public "Search Taxpayer": legal name matches, active (not cancelled), registration date, return-filing record | "GST checked" + registered since <year> |
| APMC trader licence | trader (if held) | licence copy; market committee contact from MSAMB profile | "APMC licence seen" |
| FSSAI licence | trader, exporter (if held) | FoSCoS public check | "FSSAI checked" |
| IEC | exporter (required for the exporter type) | DGFT "View IEC Status": name matches, Active | "IEC active" |
| APEDA registration | exporter (if held) | APEDA exporter directory | "APEDA listed" |
| **Registration GPS (required)** | trader, broker, exporter, service provider, representative | captured automatically by the phone at the moment of registration (foreground, one fix, after a clear permission screen); the nearest place is named by the phone's own geocoder (reuse `features/plots/data/place_geocoder.dart`); mock-location flag stored when the location plugin reports it | "Registered from <village / taluka> on <date>" |
| Place address + photo (**optional**) | all | the person enters / updates the address themselves, or a BagMitra representative visits, takes the photo (in-app camera, time + GPS) and uploads it | "Place photo" + who took it and when |
| Track record | all | computed: completed BagMitra deals and ratings | deal count, stars |

- **Registration GPS (owner decision 2026-11-07)**: registration cannot finish without a location fix
  taken at that moment; no background or repeated tracking. Stored: latitude, longitude, accuracy,
  time, the geocoder's place / district / state / PIN, and the mock-location flag. Public profile shows
  only village / taluka / district; exact coordinates are visible to admin and to parties of an
  accepted deal only. A fix flagged as mock, or far from the stated area, goes to the admin queue
  before the badge. The self-entered address (optional) is shown beside it so the admin sees both.
  GPS can be faked on a phone; it is one check among the others, never proof by itself.
- **Turnover is not collected or shown** (not on any public register; self-declared figures cannot be
  checked). Business age = GST registration date; activity = public return-filing record.
- A trader / exporter is "verified" (sees lots) after phone OTP + admin check of at least one of
  GSTIN / APMC licence / IEC (exporter: IEC required). A broker: phone OTP + admin phone call
  (place photo optional).
- **Report** button on every profile and lot → admin queue, predefined reasons only (fake identity, fake
  lot / photos not from the orchard, impersonating BagMitra, fake rating, abusive behaviour); photos optional; no free text. Admin acts **only on platform rules** (fake or duplicate users, fake lots, impersonation, abuse) by warning, hiding or suspending, with a reason code the user sees, and one appeal through the grievance officer. Admin never decides payment, weight or quality quarrels.
- Re-check yearly; GST "cancelled" or IEC "deactivated" found on re-check removes the badge.
- **Weighbridge**: location, owner phone, Legal Metrology verification certificate photo and
  valid-until date. The app warns both parties when the date has passed.
- **Transporter**: vehicle number(s), capacity, refrigerated yes / no, owner phone; common-carrier
  registration number when held (Carriage by Road Act 2007).
- **Labour gang / crate supplier**: leader name, phone, village, service area.
- Verification state, what was checked, by whom and when are stored; nothing is shown as "verified"
  without it.

## 4A. Export information (information only — owner 2026-11-07: BagMitra takes no part in any trade)
- **Export page per crop**: destinations with value share, source and year; season fit (Ambia vs
  Mrig as quoted by an exporter); buyer specs as quoted (size, look); rules a grower meets (HortiNet
  farm registration through the State Horticulture Department, APEDA-approved packhouse, residue test
  at an accredited lab, phytosanitary certificate). Every line shows its source and date; facts from
  research §4 only; folded behind details per the UI rules.
- **Exporters** join as the existing "exporter" buyer type (IEC required, §4). No new trade flow.
- **Official links**: APEDA exporter directory, HortiNet, DGFT IEC status (open in browser).
- **Foreign prices**: none stored until the publisher's reuse terms are checked and recorded (same
  rule as the GR feed, QG1). Kalimati (Nepal, official committee) is the first candidate; until terms
  are recorded, show only a link-out. **Never UN Comtrade data** (licence bars commercial reuse).
- **Export record PDF**: from the grower's own spray log, label-claim check and PHI dates already in
  the app — a dated record the grower can hand to an exporter. Information only; no compliance claim.

## 4B. Fixes from the 2026-11-07 audit (enforce decisions already taken)
- **No plot location before acceptance**: EXIF is stripped from every uploaded photo; lot photo
  lat/lon and the plot pin never appear in any API response to a buyer or broker before the grower
  accepts their offer (research §6.2-1).
- **No contact details in lot text**: lot text fields refuse phone-number and URL patterns, so the
  grower's identity stays hidden (§6.2-2).
- Data model also holds: registration GPS fields (§4), exporter IEC, `market_link_rep` role uploads,
  fraud reports (predefined reasons, photos, status, admin decision).

## 4C. Trust and safety (audit 2026-11-07, research §6.3–6.4; owner: "default yes")
- **Real orchard check**: a lot's photos must be captured inside or near the grower's mapped plot;
  otherwise the lot waits in the admin queue.
- **No fake deals for ratings**: parties on the same phone / device cannot rate each other; a pair of
  accounts that only ever trade with each other is flagged to admin.
- **One registration number, one profile**: GSTIN, IEC and APMC licence numbers are unique across
  profiles; a second claim goes to admin.
- **Suspended users returning**: a new registration whose name, registration numbers or registration
  GPS matches a suspended profile goes to admin before any badge.
- **Real BagMitra representatives only**: representatives appear in the app with a badge a user can
  check; a fixed notice on every role home: "BagMitra never asks for money, OTP or bank details."
- **Open admin actions**: every verify / warn / hide / suspend / restore is logged (`admin_actions`) with
  a reason code shown to the user; one appeal through the grievance officer.
- **Legal duties**: terms of use and privacy notice accepted (versioned, time-stamped) before a role is
  used, with clear notice that a trader / broker / exporter / provider phone number is shown publicly
  and that one GPS fix is taken at registration (DPDP); 18+ declaration for every market-link role
  (minors cannot contract); a **grievance officer** shown in the app (name and contact set in admin
  settings; default the owner) — complaints acknowledged within 24 h and closed within 15 days (IT Rules
  2021); yearly notice of terms / privacy changes; in-app report and block of users (Google Play UGC).
- **Account deletion (Q68)**: profile and contact data are hidden at once and erased after **180 days**
  (IT Rules 2021 retention); ratings already given stay, shown without name.

## 4D. Season sale package — APPROVED by the owner 2026-11-07 (research §7; architecture §4E)
Owner idea 2026-11-07: in the sale season growers look for traders and traders look for good santra; a
grower pays a **one-time** fee (not monthly) to have a lot shown to traders; paid by UPI straight to the
company account, not through Google. Traders keep their monthly subscription.
- **What a trader sees in a packaged lot**: grower's first name only (no surname), crop / variety,
  orchard area (acres, from the plot), estimated tonnes, quality ticks, photos (EXIF stripped), harvest
  window, **district only**. Hidden: surname, phone, village, plot pin. Contact appears only after the
  grower accepts that trader's interest (§3 step 4).
- **Admin settings**: package ON / OFF (default OFF = every lot visible free), price (₹), validity
  (days); a lot without an active package is not shown to traders while the switch is ON.
- **Payment, consumption-only** (§7.1): the app shows no price, no pay button, no payment link or
  instruction. The grower pays outside the app (company UPI QR carried by a BagMitra representative, the
  company website, or the office). The admin activates the package against the grower's phone number in
  the admin web (reuses the billing manual-grant path, provider `manual_grant`, with payment reference,
  amount, date, admin id). A ₹2,000-or-lower price has zero UPI MDR (§7.2).
- Fee is for the listing service only — never a share of the sale (§1).
- Needs before go-live: registered company, current account + merchant QR, CA view on GST and invoice,
  Play Console check that consumption-only still applies.

## 4E. Season sale package — architecture (approved 2026-11-07)

### Admin settings (admin web, `market_link_admin`)
- **Company profile** (owner fills after company registration and GST number): legal name, trade name,
  address, GSTIN, PAN, bank account name / IFSC / last 4 digits only, UPI ID (VPA), merchant QR image,
  invoice prefix, GST rate % for the package (empty until the CA advises). All fields start empty.
- **Package settings**: switch ON / OFF (default **OFF**), price ₹, validity days, start date.
- **Guard**: the switch cannot be turned ON while legal name, GSTIN, UPI ID or price is empty; the admin
  page says which field is missing. Every settings change is written to `admin_actions` (old / new,
  who, when).

### Visibility rule (server, one function `lot_visible_to_traders(lot, now)`)
- Switch OFF → every published lot is visible (today's behaviour).
- Switch ON → a lot is visible to traders, exporters and brokers only while its grower has an active
  package covering that lot (`activated_at <= now < valid_until`). Expired → the lot hides; the grower
  keeps the lot, its photos and all interests already received.
- Traders always see only: first name (no surname), crop / variety, orchard acres, estimated tonnes,
  quality ticks, photos (EXIF stripped), harvest window, district. Surname, phone, village and plot pin
  only after the grower accepts that trader's interest (§3 step 4). Table-driven tests for every case.

### Payment and activation (consumption-only, research §7.1)
- **Nothing about price or payment inside the Android app**: no amount, no pay button, no UPI ID, no QR,
  no link, no "pay at…" text — including in the representative role screens. The grower only sees
  "Package active until <date>" or "Not active". (CI test: no price or UPI string in the app bundle's
  l10n for this feature.)
- The grower pays outside the app: a printed company QR card carried by representatives, the company
  website, or the office.
- **Admin activation**: admin web → find grower by phone → choose lot (or "all lots this season") →
  enter amount, payment method (UPI / cash / bank), payment reference (UTR, unique), paid date → save.
  Creates a `package_grants` row and a receipt; the grower gets a push "Your sale package is active
  until <date>".
- **Receipt / invoice PDF** (admin web, downloadable and sent to the grower's phone by the admin):
  company profile, receipt number (prefix + running number), grower name, phone, amount, GST line only
  when GSTIN and GST rate are set, payment reference, validity. Never generated while the company
  profile is empty.
- **Printable QR card** in the admin web (company name, UPI ID, merchant QR) for representatives — a
  print file, not an app screen.
- Refunds are not built (no rule from the owner); an admin can revoke a grant with a reason (logged).

### Data model (next migration)
`company_profile` (single row; fields above), `season_package_settings` (switch, price, validity_days,
starts_at), `package_grants` (id, grower_id, lot_id nullable = all lots, amount_paise, method,
payment_ref unique, paid_on, activated_at, valid_until, receipt_no unique, revoked_at, revoked_reason,
admin_id). RLS: grower reads own grants (status and dates only); admin full; traders none.

### Tests
Switch OFF shows all lots; switch ON hides lots without an active grant; expiry hides; revoke hides;
guard blocks ON with empty company fields; duplicate UTR refused; receipt numbers unique and gapless per
prefix; no price / UPI / QR anywhere in the app; trader view never contains surname, phone, village or
coordinates before acceptance; admin actions logged.

### Milestone
L9a: settings, company profile, guard, visibility rule, grants API + admin activation page.
L9b: receipt PDF, printable QR card, grower status chip and push, tests above.

## 5. Legal gate (must hold before production)
- Feature flag `MARKET_LINK_ENABLED` (default **off** in production; on in test builds).
- It is switched on only after the owner records in admin: (a) a written legal opinion on
  Maharashtra APMC Act s.6(2A) as substituted by Mah. 52 of 2025 and s.5D for this link-only model;
  (b) a CA opinion on GST for any fee; (c) the terms of use for growers, buyers, brokers and
  providers; (d) the lawyer's view on public named ratings (intermediary duties under the IT Act
  and its rules, defamation risk) [UV].
- In-app wording on every lot, offer and deal: BagMitra is not a buyer, seller, commission agent or
  transporter, does not hold money and does not guarantee payment or quality.
- No e-way bill flow (fresh citrus is exempt) — confirm before go-live.

## 6. Data model (additions)
Keep: `market_lots`, `market_lot_photos`, `buyer_profiles` (trader / exporter, with IEC), `broker_profiles`,
`service_providers`, `party_verifications`, `market_offers` (interest: rate, basis, quantity, proposed
harvest date, broker), `market_deals` (introduction record: lot, offer, accepted_at, both "deal done" taps,
completed_at — no terms), `deal_parties` (no commission column), `deal_events` (append-only), `ratings`
(stars + tag ids, no text), `rating_tags`. Add: registration GPS fields, `fraud_reports`, `admin_actions`,
`terms_acceptances`, `user_blocks`, representative uploads. **Drop** (BagMitra stays out of the
transaction, §1 core principle): `market_deal_versions`, `deal_confirmations`, `weigh_slips`,
`deal_payments`, `service_requests`, `disputes`, and offer columns for labour / crates / transport payer,
advance, balance, weighing place and rejection rule. RLS as before; contacts and plot pin unlocked only by
an accepted interest. Update `docs/legal/DATA_INVENTORY.md` and the Play data-safety form.

## 7. Tests (CI)
Unverified trader / exporter / broker sees no lot; grower identity, photo GPS / EXIF and plot pin hidden
until acceptance; lot text refuses phone numbers and URLs; rating only after both "deal done" taps, once
per deal, locked after 7 days, no text accepted, unknown tags refused; same-device parties cannot rate
each other; duplicate GSTIN / IEC / APMC number goes to admin; no field anywhere holds a commission, income,
Aadhaar number or deal payment; dropped tables are gone; flag off hides every screen and endpoint; RLS per
role; terms accepted before a role is used; Marathi / Hindi / English goldens at phone size.

## 8. Milestones (each ≤ 400 production lines)
| # | Scope |
|---|---|
| L0 | Flag, data model, RLS, admin verification queue (L0a merged #155; L0b: roles, follow-up migration that drops the §6 tables and adds the new ones) |
| L1 | Five-card role entry (§2.1), role switch, terms / privacy / 18+ acceptance |
| L2 | Trader, exporter, broker, provider registration with GPS; verification; public profiles; service directory |
| L3 | Grower lot with in-app photos, real-orchard check, mandi price beside the asking rate |
| L4 | Interests, compare, accept = introduction (contacts revealed) |
| L5 | "Deal done", ratings (§3A), copy to own Accounts |
| L6 | Report / block, admin actions log with reasons, appeal via grievance officer, account deletion (§4C) |
| L7 | Verification badges, duplicate / returning-user checks, yearly re-check |
| L8 | Export information page, official links, export record PDF (§4A) |

## 9. Suggestions for the owner (OWNER_RULES D.1 — not part of the build until decided)
- **Village coordinator**: one trusted person per village / weighbridge who helps growers create
  lots (DeHaat grew this way: field trust first, then local centres — research §1.7).
- **Weighbridges and truck owners as promoters**: every grower meets them at harvest; a BagMitra QR
  poster at the weighbridge links to grower sign-up.
- **Buyer demand board**: verified buyers post what they need (variety, size, tonnes, week);
  matching growers get a push — demand-first, as Vegrow works.
- **Referral**: a grower who brings another grower gets a visible badge or a month of the paid plan.
