# Daily weather pull and risk alerts

`python -m bagmitra_api.weather.pull_job` pulls weather once per location cell for every
plot with a location (deleted plots skipped), evaluates the risk rules (`risk/rules.json`)
and stores new alerts in `plot_risk_alerts` (one row per plot, rule and first day; a re-run
stores nothing twice). It prints one JSON line (`cells`, `plots`, `new_alerts`,
`failed_cells`, `stale_cells`, `failures`) and exits 1 if any cell failed; other cells still run.

Push delivery is not built yet: rows keep `notified_at` empty until a later step sends them.

## Schedule on the VPS (you run this; nothing is run on the server for you)

`deploy/docker-compose.yml` has no job service, so use the host's cron and the running `api`
container. Daily at 05:30 IST = 00:00 UTC (check the server clock with `date`; it is UTC on a
fresh Ubuntu VPS). `crontab -e` and add one line:
```
0 0 * * * cd /opt/bagmitra/deploy && docker compose exec -T api python -m bagmitra_api.weather.pull_job >> /var/log/bagmitra-weather-pull.log 2>&1
```
Run it once by hand (same command without the schedule) to check the output line.
To stop: delete the line with `crontab -e`.
