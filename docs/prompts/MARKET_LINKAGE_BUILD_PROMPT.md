# Build prompt — Market linkage module (L0–L6)

Owner approved the spec on 2026-11-07 ("suru kara"). Paste this whole message into the BagMitra Claude Code session.

```
TASK: Build the BagMitra market linkage module (milestones L0–L6) end to end, exactly as
docs/SPEC_market_linkage_addendum_v1.5.md says. The owner approved the spec on 2026-11-07.
Work continuously; never stop to wait for the owner.

0. READ FIRST (use grep -n and read only the parts you need; save tokens)
- OWNER_RULES.md (binding), docs/PROGRESS.md resume block, docs/research/RESEARCH_DIGEST.md.
- docs/SPEC_market_linkage_addendum_v1.5.md — the authority for this task. Read it in full once.
- docs/OPEN_QUESTIONS.md Q61–Q66 (all decided by the owner) and Q47, Q48.
- docs/research/MARKET_LINKAGE_RESEARCH.md §1 only when a legal / fact point comes up.
- docs/design/DESIGN_SYSTEM.md, docs/adr/0003 (sync), 0004 (i18n), 0006 (admin UI), 0007 (illustration),
  docs/agronomy/GLOSSARY_mr.md, docs/runbooks/git-and-prs.md, docs/legal/DATA_INVENTORY.md,
  docs/store/data-safety.md.

1. AUDIT BEFORE CODE (write the result as 10–15 lines in docs/PROGRESS.md, then start L0)
Find and reuse, do not rebuild:
- Accounts sales and buyer dues: app/lib/features/accounts/ (accounts.dart, accounts_repository.dart).
- Fair-price check vs the day's mandi modal price (Q48): app/lib/features/accounts/domain/fair_price.dart
  and app/lib/features/market/.
- In-app camera + photo backup by signed URLs: app/lib/features/scouting/data/ (scouting_photos.dart,
  photo_backup.dart), api routers/scouting_photos.py, migration 0021. Scouting stores the date only;
  lots need capture time + GPS (new).
- Bahar stages (harvest window default): app/lib/features/bahar/, api/src/bagmitra_api/bahar/.
- PDF export with embedded Marathi fonts: app/lib/features/export/.
- Admin web: app/lib/main_admin.dart, app/lib/admin/ (feed_pages.dart pattern), api routers/admin_*.py
  with require_role (auth/jwt.py), roles in auth/grant_roles.py KNOWN_ROLES.
- RLS helpers: api/src/bagmitra_api/db/rls.py; latest migration is 0028 (next is 0029).
- Flags: server bools in core/settings.py; app dart-define flags in app/lib/core/config.dart
  (same pattern as SARKARI_SANDESH).
- Push: api push module and app/lib/features/push/.
- Design components: app/lib/design_system/ (BmCard, SectionHeader, PriceHeroCard, BottomActions,
  EmptyState, SyncBanner, AlertBanner, GlyphIcon, InfoNote, SourcesDisclosure).
Log every gap or doubt in docs/OPEN_QUESTIONS.md (next free number) with a provisional default, and go on.

2. OWNER DECISIONS — NON-NEGOTIABLE (each one gets a test)
a) BagMitra never buys, sells, stores or owns produce and never holds or moves money. No payment
   gateway, no escrow, no wallet. Payments are buyer -> grower directly; the grower only records them.
b) Roles: grower, trader (buyer), broker (dalal), service provider (weighbridge, transporter, labour
   gang, crate supplier), admin.
c) No field, column, API key, screen text or PDF line anywhere holds a broker's commission or anyone's
   income (Q64). Add a schema test that fails if a market-link table has a column matching
   /commission|brokerage|income|dalali/ and an API test that rejects such keys.
d) Ratings: stars 1–5 per question + optional ticks from the admin-edited `rating_tags` table only.
   NO free text, no comment, no reply anywhere in ratings (Q66). The ratings table has no text column;
   the API rejects any text field and any tag id not in rating_tags.
e) Only a party to a completed deal can rate, once per deal. Rating opens at deal completion, can be
   given or changed for 7 days from completion, then is locked (Q66).
f) What the trader does after buying (onward sale, mandi dispatch) is outside the app (Q65). Do not
   build it.
g) Trader and broker public profiles: name, firm, village/market, contact number, crops, areas,
   completed-deal count, average stars per question, count of each ticked tag; list per taluka sorted
   by rating or deals. Grower profiles are never public; a grower's name, phone and plot pin are shown
   only to parties of an accepted deal.
h) Only admin-verified traders/brokers see lots. Nothing shows "verified" without a verification record.
i) No fee for anyone (Q62). No growth features from spec §9 (not decided).
j) Legal gate: server flag `market_link_enabled` (default False) and app flag `MARKET_LINK` (dart-define,
   default off). With the flag off every /v1/market-link/* endpoint returns 404 and no screen or menu
   entry appears. Test builds may turn it on; production stays off until the owner records the legal
   and CA opinions (spec §5) — do not turn it on in production.
k) Disclaimer on every lot, offer and deal screen and on the deal-sheet PDF, mr/hi/en: BagMitra is not
   a buyer, seller, commission agent or transporter, does not hold money and does not guarantee payment
   or quality.
l) No price advice, no forecasts, no invented numbers: the mandi price shown is the stored modal price
   with market and date (Q48 logic).
m) No chart-reading or trading logic of any kind belongs here; this is a records-and-matching module.
n) Deal completion is not defined by the owner: default "deal completes when the grower marks the
   balance received, or all parties mark the deal closed"; log it as a question and continue.

3. MILESTONES (one feature per PR, ≤ 400 production lines; split a milestone into a/b if needed)
L0  Flags; migration 0029 with every spec §6 table (market_lots, market_lot_photos, buyer_profiles,
    broker_profiles, deal_parties, party_verifications, market_offers, market_deals (versioned terms),
    deal_confirmations, deal_events (append-only), service_providers, service_requests, weigh_slips,
    deal_payments, ratings, rating_tags, disputes); RLS per spec §6 with tests per role; role
    `market_link_admin` in KNOWN_ROLES; admin verification queue API + admin web page (approve / reject
    with reason, who and when). Seed rating_tags with draft mr/hi/en tags matching the spec §3A
    questions (both positive and negative tag per question), status draft, for native-speaker review.
L1  Service providers: self-registration and admin-add; types weighbridge / transporter / labour gang /
    crate supplier; fields per spec §4; weighbridge Legal Metrology certificate photo + valid-until
    date, warning to both parties when expired; directory near a plot (district/taluka filter, distance
    when coordinates exist).
L2  Trader and broker registration (existing phone OTP / sign-in), documents by signed-URL upload (reuse
    photo backup), admin verification, public profiles and taluka list (decision g).
L3  Grower lot: pick plot + bahar; crop/variety from plot; tonnes, size/quality, harvest window
    (default from bahar stage), basis (per tonne / per crate / lump sum for the whole orchard), optional
    asking rate; 3–8 photos from the in-app camera only, with capture time + GPS; the day's mandi modal
    price beside the asking rate; draft offline, publish when online; buyer/broker view hides the
    grower's identity.
L4  Offers (direct or through a named broker; spec §3 step 3 fields); grower's side-by-side compare
    (rate, terms, verified badge, deals, stars, mandi price); accept -> deal; other offers closed with a
    notice; contacts and plot pin revealed to deal parties; deal versions confirmed by every party; deal
    sheet PDF mr/hi/en (spec §3 step 5, broker name only); attach a photo of a paper note.
L5  Service requests from a deal to listed providers (push now; SMS / WhatsApp link behind config, off
    by default); provider confirm/decline; weigh slip photo with gross/tare/net confirmed by both;
    truck number and dispatch time.
L6  Payment records (advance, balance) by the grower flowing into Accounts sales and buyer dues with a
    reminder on the balance date; deal completion (decision n); ratings (decisions d, e) and profile
    aggregates; disputes with photos to admin only; a trader with an open non-payment dispute is hidden
    from new lots until admin decides; "disputed" badge on ratings under an open dispute.
After L6: update DATA_INVENTORY.md and data-safety.md for every new data item; update RESEARCH_DIGEST
index and PROGRESS resume block.

4. UI — OWNER'S WORDS: "UI match karne, user friendly asawe, sutsutit pna asawa"
(match the existing UI, user friendly, neat and uncluttered)
- Use only app/lib/design_system components and theme tokens; no hand-styled widgets, no new colours.
  New screens must look like the existing ones (same app bar, cards, chips, BottomActions, 18 dp radius,
  56 dp main buttons, 48 dp tap targets, Baloo 2 + Mukta).
- Uncluttered: one main action per screen in BottomActions; at most one hero element per card; numbers
  first (rate ₹/t, tonnes, dates) with Indian digit grouping; short labels; explanations folded behind
  InfoNote / details, never long paragraphs; colour by meaning only (green good / red late or disputed /
  santra for the main action).
- User friendly for growers: big tappable choices instead of typing where possible (basis, harvest window,
  who pays, tags); voice mic on free-text fields per DESIGN_SYSTEM (never on ratings — there is no text);
  every list has an EmptyState; offline shows SyncBanner; Marathi first.
- Phone check every screen at 360 dp width, Marathi at 1.3x text size, light and dark: no overflow, no
  cut-off text, contrast passes ui_guidelines_test.dart.
- Every UI PR includes goldens and phone-size screenshots (Marathi, light + dark) — the owner accepts
  screenshots as proof, not numbers alone.
- Strings: English source, mr/hi via l10n with GLOSSARY_mr.md terms; add new Marathi terms to the
  glossary and to docs/agronomy/MR_WORDING_PASS.md for native review.

5. QUALITY AND PROCESS (every PR)
- Tests first. Before pushing API: ruff check ., ruff format --check ., mypy src tests alembic,
  bandit -q -c pyproject.toml -r src, pytest. App: dart format --output=none --set-exit-if-changed lib
  test tool, flutter analyze, flutter test --coverage, dart run tool/coverage_gate.dart 80.
- Self-review every diff before pushing (read it line by line against section 2); write the checklist in
  the PR description; merge your own PR only when every check is green; never skip or disable a test.
- Identifiers (SHAs, PR numbers) from tools only. One feature per PR. A new dependency is named in the
  PR with what it pulls in.
- English only in code, specs, commits and PRs; app text through l10n.
- Never stop to wait: log questions with a default in OPEN_QUESTIONS and continue; multitask while CI
  runs; after a usage-limit pause, resume from the PROGRESS resume block.
- Report at the end (and after each milestone in PROGRESS): what merged (PR numbers), screenshots, open
  questions added.
```

## Addendum 2026-11-07 (after L0a, PR #155) — paste this too

```
ADDENDUM to the market linkage build (owner decisions 2026-11-07). Pull main and re-read
docs/SPEC_market_linkage_addendum_v1.5.md §4 (rewritten) and §4A (new), and §8 rows L7 and L8.
1. Verification is zero-cost only: no paid KYC vendor, no Aadhaar number / card image / OTP anywhere,
   no DigiLocker now, no automation or scraping of government portals. The admin page opens the
   official public page (GST Search Taxpayer, DGFT View IEC Status, FoSCoS, APEDA exporter directory)
   for the number entered and the admin records the result, who and when. Badges say what was checked
   and the date, never "guaranteed". Turnover is never collected or shown. Verified rule and broker rule
   as in §4. Report-fraud button with predefined reasons only (no free text), admin suspend, yearly
   re-check. Add tests: no Aadhaar-like field (/aadhaar|uid/) in any market-link table or API; badge
   text never contains "guarantee".
2. If L2 (registration) already collects a "photo ID" for brokers, replace it with the §4 broker rule
   (phone OTP + place photo + admin call) before L2 merges.
3. Export (§4A) is information only: export page per crop with sourced, dated facts from
   docs/research/MARKET_LINKAGE_RESEARCH.md §4; exporters are the existing exporter buyer type with IEC
   required; official link-outs; foreign prices only after the publisher's reuse terms are recorded
   (QG1 pattern), never UN Comtrade data; export record PDF from the grower's spray log, label-claim and
   PHI data, with no compliance claim.
4. Build L7 and L8 after L6, same rules as the main prompt (tests first, ≤ 400 lines per PR, self-review,
   Marathi phone screenshots light + dark, match the existing UI, uncluttered).
```

## Addendum 2 2026-11-07 — paste this too

```
ADDENDUM 2 (owner 2026-11-07): office / place address is OPTIONAL for everyone. The person can enter
and update their own address. A new role "BagMitra representative" (granted by admin, role name
market_link_rep) can add a place photo (in-app camera, time + GPS) and address to a profile they
visited; every upload stores who and when; the badge shows it. Brokers no longer need a place photo
(phone OTP + admin call). Re-read spec v1.5 §2 and §4 on main. Tests: profile saves without address;
only market_link_rep or the profile owner can set the address; only market_link_rep can add a
representative photo.
```

## Addendum 3 2026-11-07 — paste this too

```
ADDENDUM 3 (owner 2026-11-07): every market-link registration (trader, broker, exporter, service
provider, representative) REQUIRES a GPS fix taken at the moment of registration — one foreground fix
after a clear permission screen, no background tracking. Store lat, lng, accuracy, time, geocoder place
/ district / state / PIN (reuse app/lib/features/plots/data/place_geocoder.dart, the phone's own
geocoder, no paid API) and the mock-location flag when the location plugin reports it. Public profile
shows village / taluka / district only; exact coordinates to admin and accepted-deal parties only. Mock
flag or a fix far from the stated area -> admin queue before any badge. Re-read spec v1.5 §4 on main.
Update DATA_INVENTORY.md and data-safety.md (precise location, collected once, purpose: fraud
prevention). Tests: registration blocked without a fix; coordinates absent from the public profile
API; mock-flagged registration lands in the admin queue.
```

## Addendum 4 2026-11-07 (audit fixes) — paste this too

```
ADDENDUM 4 (audit 2026-11-07, research §6.2; spec v1.5 §4B): (1) Strip EXIF from every uploaded photo
in the market-link module (server side, before storage) and never return lot photo lat/lon or the plot
pin to a buyer or broker before the grower accepts their offer; test it through the API. (2) Lot text
fields (quality and any other free text a buyer can see before acceptance) reject phone-number and URL
patterns (Devanagari and Latin digits, +91 forms, spaced digits); tests with Marathi samples. (3) Add the
§4 data (registration GPS fields, exporter IEC, market_link_rep uploads, fraud reports) in the next
migration if L0a lacks them. (4) Keep market_link_admin in L0b.
```

