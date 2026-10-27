# Mandi prices: Agmarknet pull and manual upload

`GET /v1/market/prices?crop=santra|mosambi` pulls India-wide from Agmarknet (data.gov.in)
when stored prices are older than `MARKET_MAX_AGE_HOURS`. It needs `MARKET_API_KEY` as a VPS
secret (OPEN_QUESTIONS Q26), never in git. Without the key, or when the source is down, the
app shows the stored prices marked stale; no price is ever invented.

## Manual upload (fallback)

When a mandi's rate is missing on Agmarknet, a person with the `market_admin` role types it
in from the mandi's published rate list. The role goes in Supabase **`app_metadata`**
(`{"roles": ["market_admin"]}`, set with the service role; signing in alone grants nothing).

`POST /v1/admin/market/prices` with up to 500 rows:
```json
{"prices": [{"day": "2026-10-25", "market": "Katol", "state": "Maharashtra",
  "district": "Nagpur", "commodity": "Orange", "variety": "Nagpuri",
  "min_rs_per_quintal": 2600, "max_rs_per_quintal": 3600, "modal_rs_per_quintal": 3100}]}
```
Rules: rupees per quintal; `min <= modal <= max`; no day after today; `commodity` must be one
configured in `MARKET_COMMODITIES` (spelled as on Agmarknet, e.g. `Orange`). The same day, mandi,
variety and grade replaces an earlier manual row. Rows show with `source: manual`; on the same
day an Agmarknet row wins.
