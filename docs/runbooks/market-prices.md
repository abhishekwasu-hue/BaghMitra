# Mandi prices: Agmarknet pull and manual upload

`GET /v1/market/prices?crop=santra|mosambi` serves **stored** prices only; a farmer's request
never calls Agmarknet (audit BG-04). Prices come in through the scheduled pull below and the
manual upload. `MARKET_API_KEY` is a VPS secret (OPEN_QUESTIONS Q26), never in git. No price is
ever invented.

## Scheduled pull
```
python -m bagmitra_api.market.pull_job     # JSON summary per commodity; exit 1 if one failed
```
Fetches every commodity in `MARKET_COMMODITIES` India-wide (at most `MARKET_MAX_PAGES` pages of
500 rows, each request bounded by `MARKET_TIMEOUT_SECONDS`, default 15 s), stores the rows and
records each outcome in table `market_pulls` (migration `0026`). Every request carries `MARKET_USER_AGENT`
(default `BagMitra/1.0 (+https://bagmitra.aialgodesk.org)`): data.gov.in answers `HTTP 502` to the
default `python-httpx` agent (checked from the VPS: curl 200 in 0.4 s, python-httpx 502 after 60 s). One failing commodity does not
stop the others. Two runs never overlap: a Postgres advisory lock is held for the whole run, and
a second run exits at once with `"skipped_reason": "another market pull is running"`. Without
`MARKET_API_KEY` it does nothing.

`deploy/deploy.sh` adds the cron line while `MARKET_API_KEY` is set (and removes it when the
key is emptied): every 6 hours at 02:35, 08:35, 14:35 and 20:35 UTC (08:05, 14:05, 20:05,
02:05 IST), log `/var/log/bagmitra-market-pull.log`. After setting the key, run it once by
hand (`cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.market.pull_job`)
so prices show before the first scheduled run.

## 90-day backfill (Q130)
One-off fill of the price trend chart (`GET /v1/market/prices/history`, at most 90 days) from
the data.gov.in "Variety-wise Daily Market Prices" archive (`MARKET_ARCHIVE_RESOURCE_ID`,
default `35985678-0d79-46b4-9ed6-6f13308a1d24`; same `MARKET_API_KEY`, `MARKET_USER_AGENT` and
`MARKET_TIMEOUT_SECONDS`). Per commodity in `MARKET_COMMODITIES` it reads every row with
`Arrival_Date` in the last N days (pages of 1000, at most 100 pages) and:
- stores a row only when its (commodity, market, variety, grade) is already stored from the
  daily pull (`source: agmarknet`). Archive market names can differ (`Pune(Moshi) APMC` vs
  `Pune(Moshi)`) and are never mapped by guess, so no duplicate mandi appears in the list;
- never overwrites a day that already has a row for that mandi; inserts only missing days,
  as `source: agmarknet` (so Agmarknet still wins over a manual row);
- counts the rest (`unmatched`) and names the top 10 unmatched markets; they are not stored.

A page that does not answer (network error, timeout, non-200) is asked again after 10 s and 30 s
before that fruit counts as `source_unreachable`; each page may take up to
`MARKET_ARCHIVE_TIMEOUT_SECONDS` (default 90). A failed fruit is simply run again later.
It holds the market pull lock (exits with `skipped_reason` if a pull is running: run it again),
does not touch `market_pulls`, and is safe to repeat. Exit 2 without `MARKET_API_KEY`, 1 when
a commodity failed. Paste on the VPS (deploy, then the backfill, all in the background, so a
closed SSH session does not stop it):
```
nohup bash -c 'cd /opt/bagmitra && bash deploy/deploy.sh > /root/market_backfill_deploy.log 2>&1 && cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.market.backfill' > /root/market_backfill.log 2>&1 &
```
`--days N` (1..90, default 90) after `backfill` for a shorter window. Result (deploy tail, then
one JSON line per commodity: `read`, `stored`, `skipped_existing`, `unmatched`,
`top_unmatched_markets`, `error`; empty while it still runs):
```
tail -n 3 /root/market_backfill_deploy.log; cat /root/market_backfill.log
```

## Read rule (fallback) and `reason`
`reason` is a stable code the app translates; the technical detail goes to the job log, never
to the farmer.
- `MARKET_API_KEY` empty: stored rows (e.g. manual ones), `stale: true`, `source_not_configured`.
- Every commodity of the crop had a successful pull within `MARKET_MAX_AGE_HOURS` (12; with a
  pull every 6 h one missed run stays inside): `stale: false`. A successful pull that found no
  rows (off season) gives an empty list, not an error.
- Otherwise the stored rows with `stale: true` and the commodity's last failure
  (`source_unreachable`, `source_bad_response`), `source_not_pulled_yet` (no pull has run yet)
  or `source_pull_overdue` (the pulls stopped: check the cron line and the log).

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
