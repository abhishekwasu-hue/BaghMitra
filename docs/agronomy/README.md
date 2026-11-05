# Agronomy content

Rules (spec §5): every crop, stage, disease or bahar fact used by the app is sourced (ICAR-CCRI
Nagpur, MSKVV/PDKV Akola, state agriculture department, peer-reviewed work) and cited here, one
file per topic (e.g. `santra_mrig_bahar.md`), before it is seeded into config tables. Where
sources differ, both values are stored and the admin chooses; the conflict is logged in
`../OPEN_QUESTIONS.md`. Recommendations stay at practice / generic active-ingredient level and
chemical actions carry a "verify with local expert" line.

M0 contains no agronomy data. The Home screen's sample content (`app/assets/demo/home_demo.json`)
is illustrative only, labelled "Sample data" in the UI, and not used by any logic. Seeding the
santra/mosambi stage templates with citations is the first M1 task.

## Index

| File | Status |
|---|---|
| [DRAFT_santra_mosambi_bahar_stages.md](DRAFT_santra_mosambi_bahar_stages.md) | **Draft, unverified.** Bahar calendars for Nagpur mandarin and mosambi, built from search excerpts of CCRI, NHB, ICAR-journal and extension sources, with confidence labels, conflicts and gaps. Needs primary-source verification (OPEN_QUESTIONS Q10). |
| [DRAFT_irrigation.md](DRAFT_irrigation.md) | **Draft, not expert-reviewed.** Irrigation guide (ओलित तक्ता) per crop, tree age and season from NHB, Dr. PDKV, CCRI/NRCC papers and ICAR-NIASM, with disagreements and unverified items kept apart. Feeds `app/assets/config/irrigation_guide.json` (OPEN_QUESTIONS Q35). |
| [GLOSSARY_mr.md](GLOSSARY_mr.md) | **Draft.** One Marathi term per concept for all grower-facing config and alert text, with the reason; enforced by `app/test/architecture/config_content_test.dart` and `api/tests/test_risk_rules_content.py` (audit C6). |
| [EXPERT_REVIEW_LIST.md](EXPERT_REVIEW_LIST.md) | **Open.** What an agronomist / KVK, a soil scientist, an insurance contact and a native Marathi writer must check before launch, per asset and item id. |
