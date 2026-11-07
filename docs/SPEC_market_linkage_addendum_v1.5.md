# BagMitra — Market Linkage Addendum (Spec v1.5)

Same standing rules as the main spec §0 and OWNER_RULES.md (English only in this file; the app shows
Marathi / Hindi / English; test-first; PRs ≤ 400 production lines with self-review; offline-first;
log questions in `docs/OPEN_QUESTIONS.md` with a default and continue). Research behind every fact
here: `docs/research/MARKET_LINKAGE_RESEARCH.md`. **Status: draft for owner review — not built.**

## 1. Owner decision (2026-11-07)
- BagMitra has **no capital**. It never buys, sells, owns or stores produce and never holds money.
- BagMitra is only the **link**: registered growers show their produce (photos and details), mandi
  traders reach them directly, and the work in between is done by **third parties** who already
  exist locally but are not organised — truck owners, weighbridges, and the like. BagMitra
  organises them in one place.
- Goal: more growers register because the app brings them buyers and services.
- This replaces OPEN_QUESTIONS Q47 "no in-app trading or offers" for this module only.

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
| Broker (dalal) | Local or nearby broker who brings traders to orchards | Self-registers; admin verifies |
| Service provider | Weighbridge, transporter / truck owner, harvest labour gang, crate / packing supplier | Self-registers or admin adds; admin verifies |
| Admin (BagMitra) | Owner / staff | Admin web (ADR 0006) |

## 3. Flow
1. **Lot** — grower picks a plot and bahar; crop and variety come from the plot. Fields: estimated
   quantity (tonnes), size / quality description, harvest window (defaults from the bahar stage),
   sale basis (per tonne / per crate / whole orchard on tree), optional asking rate, 3–8 photos
   taken **in the app camera only** (reusing the scouting photo capture, which today stores only
   the date — lots add capture time and GPS, new). The lot
   screen shows the day's mandi modal price (Q48 fair-price check) beside the asking rate.
2. **Visibility** — only verified buyers and brokers see lots. They see village / taluka, never the
   grower's phone, name or plot pin until the grower accepts an offer. A grower can also invite a
   chosen broker or trader straight from their public profile (§3A).
3. **Offer** — a buyer sends, directly or **through a broker** (the broker is named on the offer
   and the deal): rate and basis, quantity, harvest date, weighing place (a listed
   weighbridge), who pays harvest labour / crates / transport, advance amount and date, balance
   date, rejection rule (free text). Several offers per lot.
4. **Compare and accept** — grower sees offers side by side (rate, terms, buyer's verified badge,
   past deals and ratings, mandi price that day). Accepting one creates a **Deal**; contacts and plot
   pin are revealed to both; other offers are closed with a notice.
5. **Deal sheet** (replaces the rough paper) — fields: grower, trader, broker (if any; name only,
   **no commission field anywhere** — §1.1), basis (per tonne / per crate / lump sum), rate or
   lump-sum amount,
   harvest date, weighing place, who pays labour / crates / transport, advance and balance dates,
   other agreed conditions (free text). Every party on the deal confirms the same version in the
   app; a PDF deal sheet (mr / hi / en) is generated for all of them. A photo of a paper note can
   be attached. Any later change is a new version all confirm.
6. **Services** — from the deal, either side requests listed providers near the plot: weighbridge,
   truck, labour gang, crates. The request goes to the provider (push / SMS / WhatsApp link); the
   provider confirms or declines in the app. **Providers set their own rates and are paid directly**
   by whoever the deal names. BagMitra does not set or collect service charges.
7. **Weighing and dispatch** — the weighbridge slip photo is uploaded (gross, tare, net entered by
   hand and confirmed by both), truck number and dispatch time recorded.
8. **Payment record** — advance and balance are paid buyer → grower directly. The grower marks
   each payment received; entries flow into the existing Accounts sale and buyer-dues ledger with
   reminders on the balance date. BagMitra never receives the money (RBI PA Directions 2025, §1.3
   of the research).
9. **Close** — every party rates the others and each provider used (§3A). A dispute can be
   logged with photos; admin reviews. A buyer with an unresolved non-payment dispute is hidden from
   new lots until the admin decides.

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
- Rating opens when the deal is completed (§3 step 9). It can be given or changed for **7 days from
  the deal's completion**; after that it is locked (owner decision 2026-11-07, Q66). Ratings under an open dispute show "disputed".
  A rated person who disagrees uses the dispute flow (§3 step 9), which goes to admin, not public.

## 4. Verification
- **Buyer**: name, firm, phone (OTP), market(s) and district, APMC licence number and copy (if
  held), GST number (if held), photo of shop / office. Badge only after admin check.
- **Broker**: name, phone (OTP), village and service area, photo ID shown to admin only.
- **Weighbridge**: location, owner phone, Legal Metrology verification certificate photo and
  valid-until date. The app warns both parties when the date has passed.
- **Transporter**: vehicle number(s), capacity, refrigerated yes / no, owner phone; common-carrier
  registration number when held (Carriage by Road Act 2007).
- **Labour gang / crate supplier**: leader name, phone, village, service area.
- Verification state, who checked and when are stored; nothing is shown as "verified" without it.

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
`market_lots`, `market_lot_photos`, `buyer_profiles`, `broker_profiles`, `deal_parties` (grower,
trader, broker — no commission column), `party_verifications` (buyer or provider,
documents, checked_by, checked_at, status), `market_offers`, `market_deals` (versioned terms),
`deal_confirmations`, `deal_events` (append-only), `service_providers`, `service_requests`,
`weigh_slips`, `deal_payments` (links to Accounts incomes), `ratings` (stars and tag ids only, no text column), `rating_tags`, `disputes`. RLS: a grower
sees own lots and offers on them; a buyer sees published lots and own offers; a provider sees only
requests sent to them; contact fields are unlocked by an accepted deal. Update
`docs/legal/DATA_INVENTORY.md` and the Play data-safety form for the new data.

## 7. Tests (CI)
Unverified buyer sees no lot; grower contact hidden until acceptance; accepting closes other
offers; deal change needs every party's confirmation; only deal parties can rate, once per
deal; the rating API rejects any text and any tag not in the config list; no schema field, API field, screen or PDF holds a broker commission or income; expired weighbridge certificate warns; payment
entries reach Accounts; flag off hides every screen and endpoint; RLS tests per role; Marathi /
Hindi / English goldens at phone size.

## 8. Milestones (each ≤ 400 production lines)
| # | Scope |
|---|---|
| L0 | Flag, data model, RLS, admin verification queue |
| L1 | Service-provider registration and directory near a plot |
| L2 | Trader and broker registration, verification, public profiles |
| L3 | Grower lot with in-app photos and mandi price beside the asking rate |
| L4 | Offers, compare, accept, deal sheet PDF |
| L5 | Service requests, weigh slip, dispatch |
| L6 | Payment record into Accounts, ratings (§3A), disputes |

## 9. Suggestions for the owner (OWNER_RULES D.1 — not part of the build until decided)
- **Village coordinator**: one trusted person per village / weighbridge who helps growers create
  lots (DeHaat grew this way: field trust first, then local centres — research §1.7).
- **Weighbridges and truck owners as promoters**: every grower meets them at harvest; a BagMitra QR
  poster at the weighbridge links to grower sign-up.
- **Buyer demand board**: verified buyers post what they need (variety, size, tonnes, week);
  matching growers get a push — demand-first, as Vegrow works.
- **Referral**: a grower who brings another grower gets a visible badge or a month of the paid plan.
