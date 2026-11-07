# In-app assistant (chatbot) — research and proposal, 2026-11-07

Owner request (translated): can BagMitra have a chatbot that gives correct guidance, at no or very low
cost? Status: **research and proposal; nothing built** (discuss-then-build). Tags as in RESEARCH_DIGEST.

## 1. What the repo already has [V, repo]
- Knowledge base: 27 topics / 27 cards (`api/src/bagmitra_api/kb/seed_data/knowledge.json`), source
  list, CIB&RC label claims and restrictions, a legal gate (`kb/gate.py`) and the grower view
  (`kb/grower_view.py`): growers see general information only — no product names, no doses (Q57).
- An Anthropic adapter in `feed/ai.py` (off unless `FEED_AI_API_KEY` is set), used for the GR feed,
  with an output check and human review before anything is published.
- SPEC_v1 §M5 already plans a voice assistant "grounded in the grower's own records" via Claude.

## 2. Free / cheap AI options [V where marked]
| Option | Free part | Paid beyond | Data use |
|---|---|---|---|
| Google Gemini 2.0 Flash-Lite [V ai.google.dev pricing] | free tier: input and output free (rate-limited) | $0.075 / 1M input, $0.30 / 1M output | **Free tier: "Used to improve our products: Yes"**; paid: No |
| Cloudflare Workers AI [V developers.cloudflare.com pricing] | 10,000 neurons / day on Free and Paid plans | $0.011 / 1,000 neurons | not read [UV] |
| Claude (repo's current provider) | none | per-token | not used for training by default [UV here] |

Worked figure for Workers AI, llama-3.1-8b-instruct-fp8-fast (4,119 neurons / 1M input, 34,868 / 1M
output): one answer with ~1,500 input tokens (question + knowledge text) and ~300 output tokens ≈ 17
neurons → about 600 answers a day inside the free 10,000 neurons. Marathi answer quality of an 8B
model is not known — must be tested before use [UV].

Free-tier Gemini is ruled out for growers' questions: Google states free-tier content is used to
improve its products, which clashes with the DPDP minimum-data promise in DATA_INVENTORY.

## 3. Risk that decides the design
A chatbot that writes free answers can invent a pesticide, a dose or a date. The app already forbids
that for growers (Q57, legal gate, CIB&RC). So any answer must come only from checked knowledge, and the
"no product name, no dose" filter must run on every answer.

## 4. Proposal
**Level 1 — "प्रश्न विचारा" without AI (₹0, offline, no wrong advice):**
- The grower types or speaks (the phone keyboard's own voice typing, free) a question.
- The app searches its own knowledge cards and app help on the phone (Marathi / Hindi / English words
  and the glossary's alternate words) and shows the best 1–3 cards, each with its source.
- Ready-made question buttons for the plot's current bahar stage ("या टप्प्यावर काय करावे?",
  "पाने पिवळी का?", …) open the matching card.
- No match → "हा प्रश्न तज्ज्ञांना पाठवा / KVK शी बोला" with the KVK directory; unanswered questions are
  logged (no personal data) so the owner sees which cards to add.

**Level 2 — AI wording on top, later, behind an admin switch (default OFF):**
- Same search first; the AI may only rephrase the matched card text into a short answer in the
  grower's language, quoting the card; nothing outside the card; the grower-view filter (no product,
  no dose) and the output check run on the answer; card link always shown.
- Admin settings: ON / OFF, provider (Cloudflare Workers AI free allocation, or a paid provider that
  does not train on the data), per-grower daily limit, overall daily cap; usage shown in admin.
- Never the free Gemini tier (data used for training).

## 5. What the data does not show
- Marathi quality of free small models; Cloudflare's data-use terms; how many questions growers ask.
