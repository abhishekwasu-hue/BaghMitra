# Offline questions and answers ("विचारा" tab, OPEN_QUESTIONS Q144)

Owner 2026-11-12: farmers' questions are answered in detail even without internet, only from
authoritative, checked sources, in calm Marathi, with no frightening words and no product
names or doses beyond our checked cards and label claims.

## 1. What the app does

- The "विचारा" tab starts with a question box ("प्रश्न विचारा") above the practices guide. The
  farmer types or speaks (the same microphone as other forms) and taps search.
- The answer comes **at once from the asset bundled in the app** (`app/assets/config/qa_kb.json.gz`),
  offline and online alike: before this, the tab had no question box and no online AI (it was the
  practices guide only), so there is no online answer to prefer; online behaviour is otherwise
  unchanged (the guide below the box is the same).
- Shown: the stored question, the answer as short lines, "स्रोत पहा (n)" (titles and links as
  text), the muted line "ही माहिती ॲपमध्ये साठवलेल्या तपासलेल्या स्रोतांवरून आहे.", "कार्ड उघडा"
  when the answer comes from a practice card, and up to 3 related questions (tap = that answer).
- Matching (`app/lib/features/ask/`): Marathi, Hindi, English and romanised text ("santra
  falgal", "sayla"). Words are normalised (Devanagari digits, nukta, chandrabindu, one case
  ending such as "साठी" / "chi"); a word counts fully when stored, 0.85 when one word starts with
  the other, 0.8 when only the sound key matches ("falgal" = "फळगळ"), 0.65 for a sound-key prefix;
  rare words weigh more. Score ≥ 0.45: answer; 0.2–0.45: "हे जवळचे प्रश्न पाहा"; below: "खालील
  मार्गदर्शक पाहा किंवा आपल्या KVK ला विचारा".
- The generator writes the same search keys (`api/src/bagmitra_api/kb/qa_text.py`); the fixture
  `app/test/fixtures/qa_normalise_cases.json` and a word-list test keep both sides equal.

## 2. What the asset holds

- Until the first generation run: the **seed**, 51 questions made without a model from the card
  texts only (each answer line is a checked card text, word for word; a test checks it):
  signs, season, scouting and what to do for each pest / disease card. Rebuild it with
  `python -m bagmitra_api.kb.qa_build seed --out ../app/assets/config/qa_kb.json.gz`.
- After a run: the generated questions and answers (kind `generated`), which replace the seed.

## 3. How the generator works (`python -m bagmitra_api.kb.qa_build build`)

Inputs (the ONLY material the model may use):
- every practice-card section, the home-made preparations, and each bahar stage of आंबिया and
  मृग for santra and mosambi (stress start, irrigation restart, flowering, harvest): the checked
  card points plus passages of the sources they cite, read exactly as the knowledge articles
  read them (`feed.knowledge.cards_input`: points citing a newspaper, points whose sources cannot
  be read and points whose numbers are not in their cited text are left out; at most 8,000
  characters per source); pest / disease sections also carry the cards' "not in the sources
  read" lines (action levels → ask the KVK);
- the CIB&RC label claims for citrus (`label_claims_citrus.csv`), as printed: spray safety,
  interval, waiting period / PHI;
- the FCO 1985 Schedule I grades extract, as data only (which grades, which reference);
- the app's own screen strings (mr / en / hi) for: record a spray, bill photo, sale lot, photo
  check;
- with `--schemes` only (needs the feed database, i.e. the VPS): official, published scheme /
  GR items that are still open, from their own checked text.

Steps (each resumable, see §5):
1. **Questions**: the strong model (`FEED_SUMMARISE_MODEL`, default `claude-sonnet-5-5`) drafts
   the questions farmers ask per topic in mr / hi / en (about 3 per card point plus 4, between 6
   and 60 per topic), only questions the input fully answers. Near-duplicates across topics are
   removed (same normalised words, Jaccard ≥ 0.75, the first is kept).
2. **Answers**: the strong model answers up to 5 questions of one topic per request, mr first
   plus hi and en, 4–10 short lines each, and names the source keys it used. The topic's input is
   one cached prompt block (`cache_control`), shared by all requests of the topic; the first
   request of every topic is sent first so the others can read the cache.
3. **Checks** (an answer that fails is DROPPED, counted by reason in the report):
   `not_answerable` (the model said the input does not answer it), `length` (not 4–10 lines in
   every language), `number` (a number, amount or date not in the input: `output_check`),
   `product` (an active ingredient or brand from our label claims / restrictions / KB that the
   input does not name), `contact` (a phone or e-mail not in the input), `languages_differ`
   (mr / hi / en state different amounts or dates), `alarm_word` (a frightening word the input
   does not use), `missing` (no answer returned). These are the knowledge-article checks
   (`check_knowledge`) plus length, brand and alarm words.
4. **Paraphrases**: the cheaper model (`FEED_CLASSIFY_MODEL`, default `claude-haiku-5-5`, low
   effort) writes 3–6 more ways to ask each kept question (Marathi, romanised Marathi /
   Hinglish, Hindi), used only for matching, never shown.
5. **Asset**: compact JSON, gzipped (no timestamp), with each entry's search keys; plus
   `qa_build_report.md` (counts, drop reasons, unreadable sources, tokens, estimated cost) and
   `qa_build_cost.json` in the work folder.

API use: raw httpx, `anthropic-version: 2026-10-21`, structured outputs, the same headers as
`feed/ai.py`. Mode `batch` (default) uses the Message Batches API (half price; the batch id is
saved before polling). Mode `concurrent` sends 8 requests at a time with retries on 429 / 5xx
and the server-side refusal fallback for the strong model.

## 4. Running it

**Main path: GitHub.** Actions → "Offline Q&A build" → Run workflow (from `main`; mode
`batch`). The first step prints which secret it uses, `ANTHROPIC_API_KEY` or else
`FEED_AI_API_KEY` (the name only), and stops with an error when neither is set. The run fetches
the sources, builds, commits `app/assets/config/qa_kb.json.gz` to the branch `qa-data-<run id>`
and opens a pull request whose body is the report (also in the run summary and the
`qa-build-report` artifact). Review it and merge; the next app build ships the answers.
- A pull request opened by the workflow's token does not start other workflows: to run the
  app checks on it, close and reopen it (or push a commit).
- If the repository does not allow Actions to open pull requests (Settings → Actions →
  General → "Allow GitHub Actions to create and approve pull requests"), the branch is still
  pushed and the run summary gives the compare link to open it by hand.
- Schemes are not included on GitHub (no database there); the report says so.

**Fallback: the VPS** (one background command; it uses `FEED_AI_API_KEY` from `deploy/.env`,
reads the feed database for schemes, and writes the asset into the checkout):
```
cd /opt/bagmitra/deploy && nohup docker compose run --rm -v /opt/bagmitra:/repo -w /repo/api api python -m bagmitra_api.kb.qa_build build --out /repo/app/assets/config/qa_kb.json.gz --work /repo/api/qa_work --app-root /repo/app --schemes > /var/log/bagmitra-qa-build.log 2>&1 &
```
Follow it with `tail -f /var/log/bagmitra-qa-build.log`; the report is
`/opt/bagmitra/api/qa_work/qa_build_report.md`. The asset then has to reach the repository in a
pull request like any other change.

## 5. Resume

Every finished step is appended to `qa_work/qa_work.jsonl` (questions per topic and input,
answers per group, paraphrases per group, each submitted batch, the tokens of every reply).
Running the command again skips finished items, first collects any batch a stopped run had
submitted, and re-sends only what failed or is new. On GitHub the work folder is kept in the
Actions cache (saved also when the run fails). A changed input (card text, source text, prompt
version) makes new requests for that topic only. Delete the work folder to start fresh.

## 6. Cost (estimate, not a bill)

The report prices every reply from list prices (Sonnet 5.5 $2 / $10 per million input / output
tokens, cache write $2.50, cache read $0.10; Haiku 5.5 $0.10 / $0.50; batches half). For the
current inputs (49 topics, about 1,250 questions drafted, about 210 answer requests of 5
questions, inputs of roughly 5–15k tokens per topic): **about $15 in batch mode, about $30 in
concurrent mode; up to about $40 if the model thinks longer** (an estimate from token counts,
not measured). Set a monthly spend limit in the Anthropic console all the same.

## 7. Size

Seed: 23 KB gzipped (97 KB JSON). A full run (about 800–1,100 kept answers with paraphrases):
about 1–1.5 MB gzipped (5–6 MB JSON), estimated from the seed's compression; the report gives the
real size.
