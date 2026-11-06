# Knowledge-base source documents

Every registered source (`kb_sources`, addendum v1.3 §2) carries a fetch status:
`not_fetched`, `ok` (downloaded by the server), `uploaded` (an admin supplied it) or
`fetch_failed` (with the reason). Only the SHA-256, size and time are stored, never the text
(several licences forbid redistribution). Image datasets and `internal_only` pages are not fetched.

## Fetch from the server

```
cd api
python -m bagmitra_api.kb.fetch_sources                # every fetchable source
python -m bagmitra_api.kb.fetch_sources --only ccri_monthly_march ppqs_banned_restricted
```
Exit code 1 if any source failed. A failure keeps the last good hash.

## Upload by hand (when the server cannot reach the host)

Download the document yourself, then, signed in as a `kb_admin`:
```
curl -X PUT "$API/v1/admin/kb/sources/<source key>/document" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/pdf" \
  --data-binary @file.pdf
```
The source becomes `uploaded` with the document's hash. Limit: 20 MiB.

## Hosts blocked from the development environment (2026-10-20)

All 38 fetchable sources failed with `ProxyError: 403 Forbidden` from the cloud development
environment (its network policy allows package registries only). To fetch from there, add these
hosts under **Allowed domains** in the environment's network settings, or upload by hand:

`ccri.icar.gov.in` (14 documents), `ppqs.gov.in` (4), `www.pdkv.ac.in` (2), `niphm.gov.in`,
`www.pau.edu`, `www.nhb.gov.in`, `wdra.gov.in`, `www.fssai.gov.in`, `krishi.icar.gov.in`,
`epubs.icar.org.in`, `nbair.res.in`, `aari.punjab.gov.pk`, `ask.ifas.ufl.edu`, `ipm.ucanr.edu`,
`www.dpi.nsw.gov.au`, `gd.eppo.int`, `www.fundecitrus.com.br`, `www.infoteca.cnptia.embrapa.br`,
`plantwiseplusknowledgebank.org`, `openknowledge.fao.org`, `research.aciar.gov.au`.

Until a document is fetched or uploaded the draft cards built from it rest on addendum v1.3 §3
(which was read and verified on 2026-10-12) and every card says so in its source locator.

## Citrus label claims (WP4, owner decision Q57)

`api/src/bagmitra_api/kb/seed_data/label_claims_citrus.csv` is the checked extract of every
citrus row of the CIB&RC / PPQS "Major Uses of Pesticides" documents (insecticides,
fungicides, bio-pesticides). Columns: `source_key, edition, page_ref, crop` (as printed),
`target, active_ingredient, formulation, category` (`chemical` | `bio`), `formulation_qty,
dose_ai` (or `dose` as printed), `dilution` (water L/ha), `interval_days, phi_days,
max_sprays, description` (mode of action from the label / official source), `brand_names`
(`;`-separated; shown A–Z), `maker_url, photo_url` (https only; no copied images).
Rows for acid lime / lemon are left out. A row is added only from a document whose status in
`label_claims_fetch_log.json` is `read`; brand names and maker links only from an official
registrant list or the maker's own product page (a test enforces the source rule).

`python -m bagmitra_api.kb.seed` imports the file through `kb/importers.py`, one source at a
time; only sources that have rows are touched, so an empty file never end-dates an admin's
upload. Admin upload of the same CSV: `POST /v1/admin/kb/imports/claims`.

State on 2026-11-06: every PPQS document answered HTTP 403 to the development environment,
so the file holds the header only and all four documents are `fetch_failed` in the log.
To fill it, download the PDFs where ppqs.gov.in answers (a browser in India), then either
upload them to a session for extraction or upload each with the "Upload by hand" step above.
