# Progress

## Resume point (keep ≤ 15 lines)
- Read first: this block, `docs/research/RESEARCH_DIGEST.md`, then only the spec section the item needs (`grep -n`).
- Done 2026-10-26: #60 CI efficiency; #61 season calendar; #62 bahar compare (Q24); M4: #63 Open-Meteo adapter (Q25), #64 risk engine (`risk/rules.json`: heat, psylla DD; drafts, no chemicals), #65 `weather_daily` + `GET /v1/plots/{id}/weather`, #66 plot weather card (offline cache); M5: #67 Agmarknet adapter (Q26, needs `MARKET_API_KEY`).
- Also done 2026-10-26: #69 India-wide mandi prices + `GET /v1/market/prices` (Q27), #70 label-claims API (label information only, Q28), #71 app price screen, #72 `docs/agronomy/DRAFT_ipm_practices.md` (70 non-chemical practices, NHB + PDKV), #73 app label-information screen.
- Also done 2026-10-26/27: #75 IPM practice cards (Q29/Q30), #76 draft lines removed (Q31), #77 daily weather pull job + stored `plot_risk_alerts` (one per plot and rule per window), #78 push devices + alert delivery (no sender until FCM, Q32).
- Also done 2026-10-27: #80 manual mandi prices, #81/#85 deploy readiness + `deploy/deploy.sh`, #82 first-run walkthrough, #83 more mics, #84 build/ cleanup, #86 irrigation guide (Q35), #87 scouting log (Q34), #88/#89 Sarkari Sandesh feed G0+G1 (spec v1.4; app flag `SARKARI_SANDESH`).
- Next 3: (1) feed G2 (deadline alerts, reminders, digest) and PDF text/OCR (QG2); (2) owner-gated: CIB&RC/CCRI import, FCM sender (Q32), `FEED_AI_API_KEY`, GR portal terms (QG1); (3) goldens + 2 GB device check, photo upload via signed URLs (Q34).
- Then: photos + scouting log, irrigation tables, first-run walkthrough, mic on more forms.
- Blockers (owner, none block development): hosted Supabase + VPS hostname for real login/sync; CCRI PDFs; expert reviewer; consent legal review.
- Actions minutes: repo is public (no minute cap) since 2026-10-20; record usage weekly here anyway.
- History: `docs/progress/archive-2026-10.md`.
