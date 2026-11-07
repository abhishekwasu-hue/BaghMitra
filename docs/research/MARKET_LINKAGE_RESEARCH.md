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
