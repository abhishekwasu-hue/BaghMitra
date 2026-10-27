# Progress

## Resume point (keep ≤ 15 lines)
- Read first: this block, `docs/research/RESEARCH_DIGEST.md`, then only the spec section the item needs (`grep -n`).
- Done 2026-10-26: #60 CI efficiency; #61 season calendar; #62 bahar compare (Q24); M4: #63 Open-Meteo adapter (Q25), #64 risk engine (`risk/rules.json`: heat, psylla DD; drafts, no chemicals), #65 `weather_daily` + `GET /v1/plots/{id}/weather`, #66 plot weather card (offline cache); M5: #67 Agmarknet adapter (Q26, needs `MARKET_API_KEY`).
- Also done 2026-10-26: #69 India-wide mandi prices + `GET /v1/market/prices` (Q27), #70 label-claims API (label information only, Q28), #71 app price screen, #72 `docs/agronomy/DRAFT_ipm_practices.md` (70 non-chemical practices, NHB + PDKV), #73 app label-information screen.
- Also done 2026-10-26/27: #75 IPM practice cards (Q29/Q30), #76 draft lines removed (Q31), #77 daily weather pull job + stored `plot_risk_alerts` (one per plot and rule per window), #78 push devices + alert delivery (no sender until FCM, Q32).
- Next 3: (1) manual mandi price upload fallback (PLAN item 9); (2) once the owner gives them: CIB&RC label claims + CCRI PDFs import, FCM sender + app registration + cron line (Q32); (3) goldens + 2 GB device check.
- Then: photos + scouting log, irrigation tables, first-run walkthrough, mic on more forms.
- Blockers (owner, none block development): hosted Supabase + VPS hostname for real login/sync; CCRI PDFs; expert reviewer; consent legal review.
- Actions minutes: repo is public (no minute cap) since 2026-10-20; record usage weekly here anyway.
- History: `docs/progress/archive-2026-10.md`.
