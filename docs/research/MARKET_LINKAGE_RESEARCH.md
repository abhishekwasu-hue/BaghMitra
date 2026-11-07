# Market linkage (farmer → mandi trader) — research for an owner decision

Date: 2026-11-07. Status: **research only, nothing built** (discuss-then-build, OWNER_RULES A.6).
Tags as in `RESEARCH_DIGEST.md`: [V] read on an official / primary page on this date, [S] secondary
source (press, company profile), [UV] not verified. Decision questions: `../OPEN_QUESTIONS.md` Q61.

## 0. Owner request (2026-11-07, translated from Marathi)

BagMitra should act as a consultancy / middleman between registered growers and big traders in
mandis: growers upload photos of their produce, BagMitra markets it, the produce reaches the
traders directly, BagMitra sets up everything in between (transport etc.), and the grower gets a
fair price.

Conflict with the current build: OPEN_QUESTIONS Q47 (market directory) says "no in-app trading or
offers". This request changes that; the spec is not changed until the owner decides Q61.

## 1. Facts found

### 1.1 Law — Maharashtra APMC Act 1963, consolidated "as on 25th March 2026" [V]
Source: https://www.indiacode.nic.in/bitstream/123456789/15835/1/apmc_2026_updated.pdf
- **s.6(2A)** (inserted Mah. 7 of 2017; substituted **Mah. 52 of 2025**): marketing of fruits
  (Schedule item VII) and vegetables (item VIII) by any person outside a s.5 market "shall require
  licence as provided in section 5D or licence or permission from the Market Committee"; "no market
  fees shall be chargeable from such licensee by the Market Committee". The 2017–2025 wording said
  such persons "shall not require any licence or permission". → Buying santra outside the market
  yard as a business now needs a licence.
- **s.2(1)(ea)** "direct marketing" = purchase of produce directly from agriculturists by a
  direct marketing licence (DML) holder under s.5D(1).
- **s.5D(6)(b)**: DML holders pay the s.31 market fee to the State Marketing Board (MSAMB). How this
  sits with the "no market fee" clause of s.6(2A) is not clear from the text [UV — lawyer].
- **s.2(1)(f-1c)**: an "electronic trading platform" is one set up by the State Government or
  Government agencies. A private app is therefore not an e-trading platform under the Act [UV —
  interpretation]. **s.5J(1)**: on such a platform the seller is paid the same day, at the latest
  the next day.
- The 2016 ordinance (Ord. 15 of 2016) first freed fruits and vegetables traded outside the yard
  from licence and fee; the 2025 amendment above reversed the licence part [V, PRS copy of Ord.].
- Maharashtra's 2021 bills (7-day payment rule, min. 3 years' jail for non-payment) were introduced
  in July 2021; no evidence found that they became law [V PRS brief; status UV].

### 1.2 MSAMB licence guidelines [V]
- **Direct Marketing Licence** (https://www.msamb.com/Documents/DML_GL_English.pdf): any person
  buying directly from agriculturists in one or more market areas. Bank guarantee ₹5 lakh
  (statewide / more than one division / one of Konkan, Pune, Nashik); Nagpur and Amravati
  divisions shown as ₹2–3 lakh (the page lists Nagpur under both figures — confirm). Licence fee
  ₹500 per division, ₹1,000 statewide. Documents include solvency certificate, **last 3 years'
  income-tax returns**, project report with photos, **list of farmers in contact**, declaration of
  not being a director/partner of a private market. Apply to Director of Marketing, Pune. Validity,
  farmer-payment timing and fee duty are not on the page.
- **Private Market Licence** (https://www.msamb.com/Documents/PML_GL_English.pdf): 5 acres
  (10 acres in a municipal-corporation area), auction hall, godowns, roads, water, toilets,
  fire-fighting, rest rooms; fee ₹25,000 / ₹50,000; bank guarantee ₹5 lakh / ₹20 lakh; CA-made
  project report, 3 years' ITR. Not relevant for a first phase.

### 1.3 Payments — RBI Payment Aggregator Master Direction, 15 Sep 2025 [S, law-firm summary]
Source: https://indiacorplaw.in/2025/10/09/decoding-rbis-overhaul-of-the-payment-aggregator-directions/
- A payment aggregator needs RBI authorisation; net worth ₹15 crore at application, ₹25 crore by
  year 3; funds in escrow; **PAs are prohibited from running marketplaces**; merchant KYC via CKYCR.
- Consequence: BagMitra cannot itself collect a buyer's money and pay it out to growers as a
  service; it would use an authorised PA / bank escrow product as a merchant [UV — exact product
  and structure for a CA / lawyer].

### 1.4 Tax [UV]
GST Notification 12/2017-CT(Rate) exempts some services relating to agricultural produce
(commission agent, loading, packing, storage, transport). A Haryana AAR treated a facilitator
earning brokerage as an "intermediary", not a commission agent. Whether BagMitra's fee is exempt
depends on the structure — a CA must confirm before any fee is charged.

### 1.5 Orange (santra) market — Vidarbha [S unless marked]
- Area: Amravati ~78,000 ha, Nagpur ~45,000 ha; main belts Warud, Morshi (Amravati), Katol,
  Narkhed, Kalmeshwar (Nagpur) — Hitavada, 9 Jun 2026.
- Bangladesh is the largest export market; its duty rose from ₹20/kg to ₹63/kg and at times above
  ₹100/kg; Maharashtra withdrew its 50 % import-duty refund scheme in June 2026 (low uptake,
  benefit went to traders); LC delays and trucks held for weeks at the West Bengal border; export
  value down 90 % from 2020-21 (Co-operative Dept survey) — Hitavada, 9 Jun 2026.
- Export volume figures disagree between sources (≈2.5 lakh t/season to Bangladesh per Nagpur
  Today, Aug 2024; 1,800–2,000 MT falling to 200–300 MT per India Seatrade News, Dec 2023) — not
  resolved.
- Gulf: 100–200 MT/season, target 500 MT; APEDA is developing Nagpur as an orange export cluster
  and has identified 15,000+ farmers in Nagpur and Amravati (India Seatrade News, Dec 2023).
- Domestic buyers: Karnataka, Kerala, Tamil Nadu, Gujarat, MP, Telangana, AP, Delhi (Down To
  Earth, NOGA). Pune Market Yard, 30 Nov 2024: Amravati oranges ₹15–40/kg, Rajasthani ₹20–50/kg,
  30–40 t/day arriving from Amravati (Punekar News).
- Gaps named in the sources: storage, refrigerated transport, high per-truck cost for small
  volumes (Down To Earth).
- ~90 % of orange trade was in cash (Countercurrents, 2016). Farm-gate rates in that article:
  ₹10–15k/t (2015), ₹25–30k/t (2016) — old, for context only.
- **Not found in a citable source in this pass:** today's farm-gate rate per tonne, the on-tree
  ("bagh") sale practice and its terms, commission % at Kalamna / Vashi / Azadpur. The owner's
  first-hand knowledge or a field survey is needed here.
- Kisan Rail: first orange Kisan Rail carried 205 t Nagpur → Delhi in Oct 2020 (Hitavada); South
  Western Railway later cancelled its Bengaluru–Delhi Kisan Rail for low patronage. Current Nagpur
  status not found [UV].
- Trader fraud risk exists (press headlines: Navi Mumbai APMC strawberry farmer cheated of
  ₹57 lakh; Osmanabad trader case ₹2 crore; MP cases after 2020 outside-mandi sales) [S].

### 1.6 Comparable platforms [S]
- **Vegrow** (fruit B2B): demand first — collects buyer orders, then finds farms whose grade
  matches; grading, packing, storage, loading and logistics; instant digital payment to farmers.
  FY23: revenue ₹361 cr, total costs ₹481.6 cr (₹1.33 spent per ₹1 of revenue), procurement 62.6 %
  of costs, transport ₹55 cr; funding $86.5 M (Lapaas Voice profile).
- **Ninjacart** pivoted B2C → B2B; **DeHaat** full-stack, low margins (Inc42 / YourStory headlines).
- **e-NAM inter-state**: a Pune trader bought 11.6 t of apples and pears from Shopian (J&K) by
  e-auction, ₹11.76 lakh, e-payment through commission agents (Punekar News, 10 Aug 2025).
- **AI grading from phone photos** exists commercially (Intello Labs, $5.9 M Series A).

### 1.7 Third-party services (owner decision 2026-11-07: no capital, BagMitra only links) [S unless marked]
- **Weighbridges** — Legal Metrology Act 2009 + state enforcement rules: weighing instruments used in
  trade must be verified and stamped; the verification certificate of a weighbridge must be
  displayed by the user; electronic / platform machines are valid one year, re-verification by
  calendar quarter (Delhi Legal Metrology FAQ,
  https://weightnmeasures.delhi.gov.in/sites/default/files/inline-files/w_m_manual_17-faqs.pdf).
  Maharashtra's own validity period not read [UV].
- **E-way bill** — fresh citrus (HSN 0805) is in the Rule 138(14) exempt list, so no e-way bill
  for fresh santra (Tally summary, https://tallysolutions.com/gst/eway-bill-exemption-list/;
  confirm against the state notification) [S].
- **Transport liability** — Carriage by Road Act 2007: a common carrier (including booking agents
  and brokers) needs registration; consignor gives a goods forwarding note, carrier a goods
  receipt; liability for loss capped at 10× freight and not above declared value; transit period
  plus 3 days (IES Arthapedia, https://ies.gov.in/arthapedia/concept/carriage-road-act-2007). If
  BagMitra books trucks as an agent/broker it may itself fall in the definition [UV — lawyer].
- **Grower acquisition precedent** — DeHaat began with field officers building trust in villages,
  then local micro-entrepreneur centres: 168 centres / ~65,000 farmers in 2019, 11,000+ centres,
  1.8 M+ farmers, 11,000+ institutional buyers now (NITI Frontier Tech,
  https://frontiertech.niti.gov.in/story/dehaats-ai-enabled-agriculture-network-driving-market-access-and-efficiency-for-1-8-million-farmers/).

### 1.8 Owner's field observation (his village, stated 2026-11-07) [owner]
Local / nearby broker (dalal) brings the trader, shows the orchard, negotiates, takes 2 %
commission; trader fixes harvest date and basis (per tonne, per crate, or lump sum); terms written
on rough paper, no bond paper; trader then sells on the spot to a bigger trader or sends the fruit
to a mandi. This fills part of the "on-tree sale practice" gap in §2 (who pays the 2 % is not
stated). Owner decision 2026-11-07: the app never records a broker's commission or income (Q64).

## 2. What the data does not show
- Whether a pure listing / lead service (BagMitra never buys, never holds money) needs a s.5D
  licence or Market Committee permission under the new s.6(2A). Needs a written legal opinion.
- Today's santra farm-gate prices, traders' buying terms (advance, weighing, rejection), and
  traders' willingness to buy through an app.
- Freight rates Vidarbha → Delhi / Kolkata / Bengaluru / Hyderabad per tonne (no citable figure).
- Whether a company without 3 years of ITR can get a DML (guideline lists it as a document).

## 3. Models for the owner to choose from

| | A. Listing + verified buyers | B. Managed facilitation (consultancy) | C. Trader (buy and resell) |
|---|---|---|---|
| What BagMitra does | Grower posts lot (photos, variety, bahar, est. tonnes, size, harvest window, village). Verified traders see it and make offers; deal and payment between them | A + field check of the lot, buyer pays into a PA escrow before dispatch, BagMitra books harvest labour, crates, weighbridge and truck; grower paid on weighbridge slip + buyer acceptance window | Buys from grower, owns the fruit, sells to mandi traders / exporters |
| Money held by BagMitra | None | None (escrow at a licensed PA / bank) | Yes — working capital |
| Licence (§1.1–1.2) | Legal opinion needed | Likely s.5D or Market Committee permission — legal opinion | DML + bank guarantee required |
| Main risk | Buyer default stays with grower | Quality / weight disputes, transit loss, staff cost | Price and quality risk; Vegrow data shows losses |
| Revenue | Buyer subscription / listing fee | Commission or fixed ₹ per tonne (GST to confirm) | Trading margin |

Sequence supported by §1: A first (no licence-holding, no money held, uses existing BagMitra
data: plots, bahar, harvest window, prices, buyer ledger), then B once the legal opinion, PA
partner, transport partners and field staff exist. C needs capital and a DML and the one
comparable fruit platform's figures show it spending more than it earns.

Building blocks either model needs (candidates, not approved): trader KYC (GST, APMC licence copy,
bank account), lot photos with GPS and time from the existing scouting camera, size grading
(Claude vision, later), harvest-window from the bahar module, the Q48 fair-price check against
the day's mandi modal price, written deal terms (rate basis, weighing place, rejection rule,
payment date), and per-deal ratings of traders and growers.

## 4. Export linkage — research 2026-11-07 (owner: BagMitra only gives information; it takes no part in any trade)

### 4.1 Where Indian citrus goes and what is known about prices
- India's HS 0805 (citrus) exports 2023: US$25 M — Bangladesh 58 % ($14.9 M), Nepal 28 % ($7.21 M),
  UAE 6 % ($1.53 M), Bhutan, Kuwait, Qatar, Oman, Iraq, Bahrain, Saudi Arabia (TrendEconomy, from UN
  Comtrade, https://trendeconomy.com/data/h2/India/0805) [S].
- **UN Comtrade licence: commercial exploitation, redistribution and publication are prohibited
  without written UN permission** (https://comtrade.un.org/licenseagreement.html) [V] → do not put
  Comtrade-derived numbers in the app.
- Exporter view (FreshPlaza, 8 Dec 2025, Moghesia Global Venture): Bangladesh dominates, Nepal second,
  Gulf wants uniform size, shelf life, looks; farm-gate US$0.20–0.25/kg mid-Sep → 0.44–0.60/kg Dec 2025;
  Ambia (mid-Sep–Dec) perishable, not for cold storage; Mrig (end Jan–mid Apr) sweeter, suits
  long-distance and cold storage; buyers want 150–225 g, shiny, uniform skin; competitors South
  Africa, Egypt, Bhutan [S].
- Bangladesh: total import duty on oranges 121.78 %; imported "malta" Tk 350–400/kg retail, Badamtali
  wholesale (Dhaka) Tk 4,100–4,400 per 15 kg carton (FreshPlaza, 16 Oct 2026, quoting the Bangladesh
  Fresh Fruits Importers Association) [S]. No official daily Bangladesh price source found.
- Nepal: Kalimati Fruits and Vegetables Market Development Committee publishes daily wholesale prices;
  "Orange (Indian)" NPR 150–200/kg, average 175, on 3 Nov 2026 (via Ratopati,
  https://english.ratopati.com/story/85501/) [S]. The committee is official; its terms for reuse not
  read [UV].
- Gulf (UAE etc.): no official free wholesale price source found [UV].
- First Nagpur orange consignment to Dubai, 13 Feb 2020: 1,500 crates of 10 kg, bought from Warud
  growers, graded at the APEDA-funded VHT facility, Vashi, refrigerated container (FreshPlaza) [S].

### 4.2 Export rules a grower meets [V unless marked]
- **HortiNet** (APEDA traceability) covers citrus among other fruits; farms are registered by the
  State Horticulture Department; for vegetables the exporter may only export from registered farms;
  lots go through an APEDA-approved packhouse, residue testing at an accredited lab, and a
  phytosanitary certificate (https://apeda.gov.in/hortinet-static).
- **Packhouses**: EU-bound fruit is inspected at packhouses approved jointly by NPPO and APEDA;
  traceability records required (APEDA note on pack houses).
- APEDA and ICAR-CCRI Nagpur MoU (2021): traceability, market intelligence cell, export SOP with
  residue control, GI Nagpur Orange promotion, FPO linkage, pest-free areas (KNN, Oct 2021) [S].
- APEDA site has an exporter directory (filter by state, type, product; data source "Export
  Return"; result fields and reuse terms not read) [UV].

### 4.3 What BagMitra can do without taking part
Information only: an export page per crop (destinations with source and year, season fit, buyer
specs as quoted, rules: HortiNet farm registration, packhouse, residue testing, phytosanitary);
a link to the official exporter directory; verified exporters can join as buyers in the existing
market-linkage module (spec v1.5 already lists "exporter" as a buyer type); the grower's spray log,
PHI and label-claim checks already in the app can produce an "export record" PDF the grower hands to
an exporter. Foreign prices only from an official publisher whose terms allow reuse, otherwise a
link-out; never Comtrade data.

## 5. Stopping fake traders and exporters — research 2026-11-07

### 5.1 What can legally be checked [V unless marked]
- **Aadhaar authentication** by a private entity needs Central Government approval of a proposal
  through a Ministry, assessed by UIDAI (Aadhaar Authentication for Good Governance Amendment Rules,
  31 Jan 2025; Khaitan & Co summary) [S]. Not available to BagMitra now.
- **DigiLocker (Entity Locker / API Setu)**: an organisation can pull, with the user's consent,
  e-Aadhaar XML and PAN details; the entity's **GSTN is verified at API Setu sign-up**; Aadhaar PDF not
  given "due to DPDP rules" (DigiLocker onboarding FAQ). BagMitra needs its registered company and
  GSTIN first. Licensed KYC vendors also resell DigiLocker flows (paid) [S].
- **GSTIN public search** (no login): legal name, trade name, registration date, constitution,
  principal place of business, cancellation date, return-filing record by year. **Turnover is not
  shown publicly** (GST portal manual).
- **IEC** (exporters): DGFT "View IEC Status" is public: name and status (Active / Deactivated)
  (Skydo summary) [S].
- **FSSAI licence**: public check on FoSCoS (several secondary guides) [S].
- **APMC trader licence**: copy + market committee record (MSAMB profile pages give committee
  contacts) [V, §1.2].
- **DPDP Rules 2025** notified Nov 2025, phased over 12–18 months; consent and notice duties; breach
  notice to users and the Board; penalties up to ₹250 crore (YourStory) [S]. Collect the minimum,
  never store a full Aadhaar number.

### 5.2 What the data does not give
- No public register shows a trader's or exporter's turnover or transaction history. GST return
  filing regularity and registration date show only that a business exists and files.
- Self-declared turnover cannot be verified by BagMitra.

## 6. Audit of the market-linkage work — 2026-11-07

Scope read: spec v1.5 (as of #159), this research file, docs/prompts/MARKET_LINKAGE_BUILD_PROMPT.md,
migration 0029 (#155), api tests test_market_link_*, OPEN_QUESTIONS Q61–Q71, PROGRESS audit block.

### 6.1 Checked and in line with owner decisions [V, from the repo]
- No money held; flags default off (`market_link_enabled`, `MARKET_LINK`); RLS per role on every table.
- No commission column; test refuses commission / brokerage / income / dalali keys.
- `ratings` has stars + tag_ids only, no text column; `rating_tags` admin table seeded.
- Deal terms versioned (`market_deal_versions`), append-only `deal_events`; disputes have kind,
  photos, status; admin-only `decision_note`.

### 6.2 Gaps against decisions already taken (fix, no new decision needed)
1. **Plot location leak**: `market_lot_photos` stores lat/lon and photos may carry EXIF GPS. The spec
   promises the plot pin stays hidden until a deal is accepted → photo GPS and EXIF must never reach
   buyers / brokers before acceptance (strip EXIF on upload; lat/lon not in the pre-deal API).
2. **Identity leak through free text**: lot `quality` (500 chars) is shown to every verified buyer;
   a phone number typed there defeats the hidden-identity rule → reject phone-number / URL patterns
   in lot text.
3. Spec status line still says "draft — not built"; §6 data model and §7 tests lack the §4 additions
   (registration GPS, exporter IEC, representative role, fraud reports).
4. `market_link_admin` role not yet in KNOWN_ROLES (planned L0b) — keep on the list.

### 6.3 Legal / policy duties found [V or S as marked]
- **IT (Intermediary) Rules 2021** (iPleaders summary) [S]: publish a grievance officer's name and
  contact; acknowledge complaints within 24 h and resolve within 15 days; inform users at least yearly
  of terms / privacy changes; remove unlawful content within 36 h of a court / government order;
  **keep registration records 180 days after a user cancels registration** — bears on Q68 deletion.
- **Google Play UGC policy** [V, support.google.com/googleplay/android-developer/answer/9876937]: users
  accept terms before posting; in-app reporting of content and users; apps with 1:1 interaction need
  in-app blocking; ongoing moderation; act on complaints.
- **DPDP Rules 2025** (§5.1): notice and consent per purpose (public phone number on profiles,
  registration GPS), breach notice, minimum data.
- **Contracts by minors are void** in India (Indian Contract Act 1872, s.11 — competence requires
  majority) [stated as law; lawyer to confirm use]: market-link registration should be 18+ by
  declaration.

### 6.4 Fraud paths not yet covered (proposals, owner decides)
- Fake **grower** lots (fraud against traders): no check that the lot belongs to a real orchard.
  Zero-cost check: lot photos' capture GPS must fall inside / near the grower's mapped plot.
- **Fake deals to inflate ratings** (two accounts trading with each other): count a deal toward
  ratings only when it has a weigh slip photo and a dispatch record; parties on the same phone /
  device cannot rate each other.
- **One registration number, many profiles**: GSTIN / IEC / APMC licence number unique across
  profiles; a second claim goes to admin.
- **Banned users returning** under a new number: registration GPS + name + registration numbers
  compared with suspended profiles → admin queue.
- **Fake "BagMitra representative"** asking for money: rep profiles with a verifiable in-app badge;
  a fixed safety notice "BagMitra never asks for money, OTP or bank details".
- **Opaque admin actions**: every verify / suspend / un-suspend logged with reason code; the user sees
  the reason and can appeal once through the grievance path.
