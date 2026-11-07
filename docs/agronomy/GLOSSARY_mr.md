# Marathi glossary: one term per concept (grower-facing text)

> Status: DRAFT (audit C6). Applies to every Marathi string in `app/assets/config/*.json` and the alert texts in
> `api/src/bagmitra_api/risk/rules.json`. A test enforces the "not" column for the configs
> (`app/test/architecture/config_content_test.dart`) and for the alerts (`api/tests/test_risk_rules_content.py`).
> The arb files are outside this change; the strings that still differ are listed at the end for the merger.
> A native agri-extension writer reviews this list (docs/agronomy/EXPERT_REVIEW_LIST.md, item 13).

| Concept (en) | Use (mr) | Not | Reason |
|---|---|---|---|
| Harvest (fruit picking) | तोडणी; तोडणीपूर्व, तोडणीनंतर | काढणी | Citrus fruit is cut or picked from the tree; काढणी is the word for crops that are pulled or dug. तोडणी was already used in 7 practice items, `bahars.json` and `bahar_compare.json`. |
| Pre-harvest interval (PHI) | तोडणीपूर्वीचे दिवस (PHI) | काढणीपूर्वी … | Follows the harvest term. arb only (see below). |
| Plot / orchard | बाग | प्लॉट | बाग is used on every other screen and in all configs; प्लॉट is an English loan used only in the walkthrough. arb only. |
| Citrus psylla | सायला (सिट्रस सायला) | सिल्ला | सायला is already used in the configs, `rules.json` and the arb; सिल्ला appears only in the mr demo file. Hindi keeps सिल्ला. |
| New flush | नवती | नवीन पालवी | नवती is the citrus word already used in the practice and look-alike cards; पालवी was used only in one alert. |
| Evaporation (pan) | बाष्पीभवन; पॅन बाष्पीभवन | — | Literal meaning; used where the source says evaporation or ER (SH14, P2 2016, MP25, ML19, GP). |
| Evapotranspiration (ET) | बाष्पपर्णोत्सर्जन (ET) | बाष्पीभवन | ET is evaporation plus transpiration; the PDKV English text (R15 no. 14) says "evapotrans-replenishment", so it must not be shown as plain evaporation (audit C4). |
| Basin | आळे | — | The grower's word for the ring of soil round the tree. |
| Double-ring basin (water kept off the trunk) | दुहेरी आळे (डबल रिंग) | "आळ्याऐवजी … गोल" | The irrigation guide names it दुहेरी आळे; practice item 20 said "instead of the basin", which contradicted it (audit C6). |
| Irrigation (the act) | ओलित, पाणी देणे | सिंचन (alone) | The guide is titled ओलित तक्ता; सिंचन stays only inside fixed names: ठिबक सिंचन, तुषार सिंचन and scheme names. |
| Drip / sprinkler | ठिबक / तुषार | — | Already used everywhere. |
| Decline (citrus decline) | ऱ्हास (बागेचा ऱ्हास) | खंगणे, खंगलेली | ऱ्हास is the noun for the condition; खंगणे is a verb ("to waste away"). The look-alike card already used ऱ्हास. |
| Dieback | फांदीमर (डाय-बॅक) | शेंडेमर | फांदीमर says what is seen (branches dying) and is the look-alike card title. Item 43 had used शेंडेमर for twig blight, a different disease. |
| Twig blight | काडी करपा | फांदी करपा | Twig = काडी, branch = फांदी; the look-alike card already used काडी करपा. |
| Canker | कँकर | कॅन्कर | The spelling used in 4 practice items and section titles. |
| Bark borer (bark-eating caterpillar) | साल खाणारी अळी | साल पोखरणारी अळी | Matches the usual Indian English name (bark-eating caterpillar) and keeps पोखरणारी for the leaf miner (पाने पोखरणारी अळी), so the two pests are not confused. |
| Root rot / foot rot | मूळकूज / खोडकूज | मुळकुज, मुळकूज | One spelling with the full noun मूळ, as in the look-alike cards; खोडकूज follows the same pattern. |
| Gummosis (Phytophthora) | डिंक्या | — | Already used in all files. |
| Brown rot (Phytophthora fruit rot) | तपकिरी फळकूज | — | Label target (CIB&RC); follows the -कूज pattern of मूळकूज / खोडकूज. |
| Leaf spot | पानांवरील ठिपके | — | Label target; plain description of what is seen. |
| Greasy spot | ग्रीसी स्पॉट (पानांवरील तेलकट ठिपके) | — | Label target; the English name is kept because growers see it on the label, with a plain description. |
| Post-harvest fruit rot | तोडणीनंतरची फळकूज | काढणीनंतर … | Follows the harvest term तोडणी. |
| Weeds | तण | — | The everyday word. |
| Snails and slugs | गोगलगाय | — | Label target (metaldehyde); the everyday word. |
| Free lime / CaCO3 in soil | मुक्त चुना (CaCO3) | चुनखडी (for CaCO3 %) | The soil report shortcut in `lab_parameters.json` is मुक्त चुना, so the grower can match the number on the report. चुनखडीचे खडे stays for lime nodules (item 1). |
| Bloom vs bahar | बहर = flowering; बहार = the crop season (आंबिया / मृग / हस्त बहार) | — | Two different words; both are correct where used. |
| KVK | कृषी विज्ञान केंद्र (KVK); short: KVK | केव्हीके | Full name once, then the abbreviation the grower sees on boards. "Ask your KVK" = "आपल्या KVK ला विचारा". |
| PDKV | डॉ. पंदेकृवि | — | The university's own short name. |
| Units | सें.मी., मि.मी., कि.मी., लिटर, % / टक्के | सेंमी, मिमी, किमी | Dotted abbreviations are the majority form (19 uses); the alerts and the irrigation guide now match. |
| Trader (buyer of produce) | व्यापारी | खरेदीदार (for a person) | Market linkage (spec v1.5); Accounts already shows व्यापारी for the sale buyer (`saleBuyer`). खरेदीदार stays only in the directory title "बाजार व खरेदीदार". Draft, for native review. |
| Broker | दलाल | एजंट, मध्यस्थ | The grower's own word (spec v1.5 §1.1). The app never shows a broker's commission (Q64). Draft. |
| Deal (grower–trader agreement) | व्यवहार | सौदा (mr), डील | Rating tags use व्यवहार; Hindi keeps सौदा. Draft. |
| Agreed terms / conditions | ठरलेल्या अटी; ठरल्याप्रमाणे | शर्ती | Rating tags "ठरलेल्या अटी पाळल्या". Draft. |
| Produce on sale | माल | — | Everyday market word (उत्पादन stays for yield) ("माल फोटो व वर्णनाप्रमाणे"). Draft. |
| Advance payment / balance | उचल / बाकी पैसे | अॅडव्हान्स | उचल is the village word for money paid before harvest; to confirm by the native reviewer. Draft. |
| Weighing / crate count | वजन / क्रेट मोजणी; weighbridge: वजनकाटा | — | Rating tags and later the weigh slip (L5). Draft. |
| Service provider kinds | वजनकाटा, वाहतूकदार, मजूर टोळी, क्रेट पुरवठादार (सेवा देणारे) | — | Market linkage admin (L0b) and the provider directory (L1). Hindi: धर्मकांटा, ट्रांसपोर्टर, मज़दूर टोली, क्रेट आपूर्तिकर्ता. Draft. |
| Rating tag; draft / active / retired | रेटिंग टॅग; मसुदा / चालू / बंद | — | Admin web only (L0b). Draft. |

Written register: config texts use the written forms (कामे, झाडे, झाले). The arb uses spoken forms in about 16
strings (कामं, झाडं, झालं).

## arb strings for the merger (not changed here)

- `app_mr.arb:10, 262-267, 389`: काढणी → तोडणी (including the PHI label at 389: "तोडणीपूर्वीचे दिवस").
- `app_mr.arb:328-331` (walkthrough): प्लॉट → बाग.
- `app_mr.arb`: spoken forms (कामं, झालं, झाडं: 16 hits) → written forms (कामे, झाले, झाडे).
- `app_mr.arb:568` / `app_en.arb:869` / `app_hi.arb:568` `claimCheckInform72h` (audit C10): no source for
  "72 hours". Suggested en: "Inform the insurer, your bank or the CSC about the loss as soon as possible; check your
  policy for the time limit." (mr: "नुकसानीची माहिती विमा कंपनी, तुमची बँक किंवा CSC केंद्राला शक्य तितक्या लवकर
  द्या; किती दिवसांत कळवायचे ते तुमच्या पॉलिसीत तपासा.")
- `walkthroughWeatherBody` (`app_en.arb:591`, `app_mr.arb:331`, `app_hi.arb:331`; audit C12): it promises "cold" alerts. Since WP2
  (2026-11-06) `rules.json` has a draft `cold_wave` rule (IMD: minimum 4 °C or less), so the word can stay.
- The mr demo file `app/assets/demo/home_demo.json` uses सिल्ला (audit C1 owns that file).
