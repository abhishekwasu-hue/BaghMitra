# BagMitra — Agronomy Knowledge Base & Advice Safety Addendum (Spec v1.3)

This addendum extends `bagmitra_spec_v1.md` (esp. §5 "Agronomy content rules") and `bagmitra_billing_addendum.md`, and **replaces v1.2 of this file**. Where it conflicts, this addendum wins for anything that tells a grower what to spray, apply or do. Same standing rules as the main spec §0: English only in code/docs/prompts (user-facing text via i18n), test-first, contract-first API, small PRs with self-review checklist, no hardcoded business values, never stop to wait for the owner (log questions in `docs/OPEN_QUESTIONS.md` with a provisional default and continue), never deploy to production.

Research basis: a web audit on 2026-10-12 of Indian and worldwide citrus sources. Everything marked **[V]** below was fetched and read during that audit; **[S]** was seen only in search results or fetch-blocked; **[UV]** could not be verified. Re-verify at ingestion time; nothing here is to be copied into cards without the pipeline in §5 and the review in §6.

---

## 1. Why this exists (verified findings)

1. ICAR-CCRI Nagpur publishes month-wise citrus guidelines (`https://ccri.icar.gov.in/site/assets/files/1223/<month>.pdf`, january…december) [V]. They are the closest thing to an official Nagpur-mandarin calendar of operations, but they are **undated, unauthored, and still recommend chemicals that are now illegal on citrus in India**: benomyl (April PDF), dichlorvos (Jan/Feb/Apr/May), dicofol (Sep–Dec), chlorpyriphos (April) and dimethoate (psylla). Also an evident typo (October drip table "13 L for 10+ yr" vs 105 L elsewhere).
2. The CCRI website has **no publications page**; CCRI bulletins surface only through the ICAR KRISHI repository, and the Nagpur-mandarin "Calendar of Operations" PDF was not found online. The owner should request it (and a data-sharing arrangement) directly from ICAR-CCRI.
3. The best foreign sources (UF/IFAS, UC IPM, NSW DPI, Fundecitrus, CRI) are excellent for biology, diagnosis, monitoring and models, but their **product tables are foreign registrations** and several are licensed **non-commercial / no-derivatives or all-rights-reserved**. They may inform reviewed cards and be cited; they may not be copied.
4. Indian label claims rarely say "mandarin"; most say "citrus" or "acid lime". Expect many cases where **no legal product exists** for a given pest on Nagpur mandarin — the app must say so rather than improvise.
5. Therefore every chemical passes a **legal gate** against current CIB&RC / FSSAI data, and every card is **expert-reviewed, dated, versioned and licence-tagged**.

---

## 2. Source registry (seed `kb_sources` with these; tier and licence are mandatory fields)

### Tier 1 — Indian scientific / institutional (primary for agronomy)
| Source | URL | Notes |
|---|---|---|
| ICAR-CCRI monthly guidelines (12 PDFs) [V] | `https://ccri.icar.gov.in/site/assets/files/1223/<month>.pdf` | Irrigation L/tree/day by age, fertiliser, bahar ops, sanitation, pest/disease. Undated; contains banned chemicals → gate. |
| ICAR-CCRI greening advisory [V] | https://ccri.icar.gov.in/site/assets/files/1167/advgde.pdf | HLB: certified budwood, psylla control, nutrition. |
| ICAR-CCRI technologies list [V] | https://ccri.icar.gov.in/site/assets/files/1307/technologies_1.pdf | INM, fertigation savings, leaf-miner lure, fruit-sucking-moth sachet (phorate — banned). |
| ICAR KRISHI repository (CCRI bulletins) [V] | https://krishi.icar.gov.in/jspui/handle/123456789/5451 (rootstock bulletin, 2011) | "All rights reserved unless indicated"; some items carry ICAR Data Use Licence. |
| PDKV Akola AICRP (Citrus) [V] | https://www.pdkv.ac.in/?p=4604 | Nagpur-mandarin-specific: Mrig stress 50 d, Cycocel/Cultar, fertiliser, drip by pan-evaporation, *Pseudomonas*, fruit-drop sprays. Page partly garbled; data 2004–09. |
| PDKV Research Recommendations 2017 [V] | https://www.pdkv.ac.in/Circulars/Recom-2017English.pdf | PDKV Mandarin-5, 5-split fertiliser (Ambia), post-harvest UV-C/hypochlorite + wax. |
| NIPHM AESA-based IPM package: Citrus (2014) [V] | https://niphm.gov.in/IPMPackages/Citrus.pdf | Official IPM: traps, bioagents, cultural, trunk paint; chemicals need gate. |
| PAU "Fruit drop in citrus" (2019) [V] | https://www.pau.edu/content/ccil/pf/FruitDropCitrus.pdf | Causes and timing (Punjab/Kinnow). |
| ICAR journals (IJAgS, Indian Phytopathology, J. Hortl. Sci.) [V] | epubs.icar.org.in, akmu.iihr.res.in | Trials cited in §3; many CC BY-NC-SA. |
| ICAR-NBAIR [V] | https://nbair.res.in/ ; https://databases.nbair.res.in/AICRP/index.php | Biocontrol compendium, AICRP-Biocontrol DB; no citrus page. |
| NHB Citrus PHT [V, undated] | https://www.nhb.gov.in/pdf/fruits/citrus/cit009.pdf | Pack sizes, storage 6–7 °C / 85–90 % RH. |
| Agmark mandarin grades (via WDRA) [V] | https://wdra.gov.in/documents/d/wdra/kinnow_agmark | Size classes A–E (54–85+ mm), TSS ≥10, ratio ≥12:1. |
| Kisan Call Centre transcripts (OGD) [V] | https://www.data.gov.in/resource/kisan-call-centre-kcc-transcripts-farmers-queries-answers | District/month Q&A; API not working; licence likely GODL — confirm. Use for *question mining*, not answers. |
| Vikaspedia citrus pages [S], MPKV Rahuri [UV], mKisan / KVK portals [UV], NHB fruit guide [UV] | — | Blocked from this environment; verify manually. |

### Tier 2 — legal / compliance (hard gate; official documents only)
| Source | URL | Notes |
|---|---|---|
| CIB&RC Major Uses of Pesticides — fungicides (as on 31.03.2024) [V] | https://ppqs.gov.in/sites/default/files/fungicides_31.03.2024.pdf | Crop-pest-dose-PHI label claims. |
| CIB&RC Major Uses — bio-insecticides (31.03.2024) [V] | https://ppqs.gov.in/sites/default/files/major_uses_of_pesticides_insecticides_bio_insecticides_as_on_31.03.2024.pdf | e.g. *Verticillium lecanii* citrus mealybug; Nemastin. |
| CIB&RC Major Uses — insecticides / PGRs [S] | PPQS site (HTML index blocked); CIB notice 14 Jun 2023 https://ppqs.gov.in/sites/default/files/public_notice-updation.pdf [V] | Get current PDFs manually; keep manual-upload importer. |
| Banned / restricted / refused list [S] | https://ppqs.gov.in/sites/default/files/list_of_pesticides_which_are_banned_refused_registration_and_restricted_in_use_0.pdf | Operative notifications: S.O. 3951(E) 8 Aug 2018; S.O. 4294(E) 3 Oct 2023; S.O. 1196(E) 2020 (dichlorvos export-only); S.O. 1482(E) 2005 (monocrotophos veg). Also mirrored at IISR: https://spices.res.in/pages/pesticides-formulations-banned-in-india and …/pesticides-restricted-for-use-in-the-country [V]. |
| FSSAI contaminants/residues compendium (MRLs, v.2020) [V] | https://www.fssai.gov.in/upload/uploadfiles/files/Compendium_Contaminants_Regulations_20_08_2020.pdf | Check later amendments. |
| Codex pesticide residues DB [V] | https://www.fao.org/fao-who-codexalimentarius/codex-texts/dbs/pestres/en/ | Export reference only; no API. |
| EU pesticides DB [V] / US EPA tolerances [V] | ec.europa.eu … / https://www.epa.gov/pesticide-tolerances | Comparison only; never shown to growers. |
| JAU compilation of CIB label claims (30.09.2025) [V] | https://new.jau.in/storage/document/dynamic_document//residue_insecticide_30092025_20251226_783.pdf | Secondary compilation — use to locate, confirm against PPQS. |

### Tier 1-international — science, diagnosis, models (cite/summarise; never copy product tables)
| Source | URL | Licence / caveat |
|---|---|---|
| UF/IFAS Florida Citrus Production Guide 2026–29 [V] | https://ask.ifas.ufl.edu/publication/CG101 (chapters e.g. CG021 Alternaria, CG097 ACP) | **CC BY-NC-ND 4.0** → summarise + cite only; humid Florida ≠ semi-arid Vidarbha; US products only. |
| UC IPM Citrus Pest Management Guidelines [V] | https://ipm.ucanr.edu/agriculture/citrus/ | © UC Regents; monitoring methods/thresholds transferable; US products only. |
| NSW DPI citrus (incl. *Pests, beneficials, diseases and disorders in citrus* image guide) [V] | https://www.dpi.nsw.gov.au/agriculture/horticulture/citrus | Licence likely CC BY 4.0 — confirm; best image-based diagnostic reference. |
| EPPO Global Database datasheets [V] | https://gd.eppo.int/taxon/LIBEAS , /XANTCI , /DIAACI | © EPPO; biology/detection authoritative; EU phytosanitary parts irrelevant. |
| Fundecitrus (Brazil) [V] | https://www.fundecitrus.com.br/ | Portuguese; all rights reserved; best area-wide HLB practice. |
| Embrapa Infoteca-e [V] | https://www.infoteca.cnptia.embrapa.br/ | CC BY-NC-ND 4.0; Portuguese. |
| Citrus Research International (South Africa) [V] | https://www.citrusres.com/ | Members-only; do not ingest. |
| CRI Sargodha annual report 2019-20 (Pakistan) [V] | https://aari.punjab.gov.pk/system/files/CRI-SGD%20Annual%20Report%202019-20.pdf.pdf | Closest agro-climate (Kinnow, semi-arid Punjab). |
| ACIAR Aik Saath citrus training (Urdu/English) [V] | https://research.aciar.gov.au/aik-saath/citrus | © ACIAR. |
| PlantwisePlus Knowledge Bank (CABI) [V] | https://plantwiseplusknowledgebank.org/ | India-aware factsheets/PMDGs; licence not stated — confirm before ingest. CABI Compendium datasheets largely paywalled [UV]. |
| FAO Knowledge Repository / AGRIS [V] | https://openknowledge.fao.org/ ; https://agris.fao.org/ | Licence per document. |
| Citrus Research Board (CA) [V], CRDF (FL) [V], Hort Innovation (AU) [V], Citrus Australia [V], DAFF AU canker page [V] | citrusresearch.org, citrusrdf.org, horticulture.com.au, citrusaustralia.com.au, agriculture.gov.au | Background/R&D; mostly all-rights-reserved. |
| IVIA Spain [UV], Queensland DAF [UV] | — | Fetch blocked. |

### Tier 3 — field experience
NOGA, progressive growers, consultants, KVK staff — stored as labelled "field experience" cards, never merged into scientific cards.

### Tier 4 — image datasets (prototyping only; none are Nagpur-mandarin field images)
| Dataset | URL | Size / type | Licence |
|---|---|---|---|
| Rauf et al., citrus fruits & leaves (Sargodha, PK) [V] | https://data.mendeley.com/datasets/3f83gxmv57/2 | 759 imgs, 6 classes, 256 px, mixed | not stated |
| AgML `citrus_fruit_leaf_disease_classification` [V] | https://huggingface.co/datasets/Project-AgML/citrus_fruit_leaf_disease_classification | 759 imgs | CC BY 4.0 |
| AgML `orange_leaf_disease_classification` [V] | https://huggingface.co/datasets/Project-AgML/orange_leaf_disease_classification | 5.8k imgs | not shown |
| Roboflow CitrusAnnotation [V] | https://universe.roboflow.com/university-x9v5e/citrusannotation | 609 leaf imgs | CC BY 4.0 |
| CitDet (HLB orchard, Florida) [V] | https://arxiv.org/abs/2309.05645v3 | 579 hi-res, 32k fruit boxes, field | not stated |
| HLB orange leaves, Mexico [V] | https://data.mendeley.com/datasets/jgkh2jxbwt/1 | 649 smartphone, white background | not stated |
| PlantVillage (orange HLB class) [V] | https://github.com/spMohanty/PlantVillage-Dataset | lab images | no licence file |
Rule: do not redistribute datasets with missing licences; use only for internal evaluation. The real set is §8.

---

## 3. Seed facts for the knowledge base (draft cards; each goes through §4 gate and §6 review)

Doses are quoted exactly as the source states them; "L/tree/day" = litres per tree per day. Sources abbreviated: CCRI-<Mon> = monthly PDF; PDKV = AICRP page; NIPHM = IPM package; PPQS-F = fungicide label list.

### 3.1 Bahar regulation
- Ambia: withhold irrigation from November; if stress inadequate, Cycocel 2 ml/L in December; restart irrigation in January; GA3 1.5 g + urea 1 kg / 100 L at flush/fruit set (Jan–Feb). Harvest Oct – first week Dec. [CCRI-Nov/Dec/Jan/Feb]
- Research: 40–50 days of withheld irrigation in Nov–Dec induces flowering (CCRI SDI trial, Meshram et al., Front. Hortic. 2025, https://www.frontiersin.org/journals/horticulture/articles/10.3389/fhort.2025.1552283/pdf).
- Mrig: ~50 days of soil-moisture stress on medium soils (May) is sufficient; break with irrigation in June if rain is late; Cycocel (CCC) 1000 ppm once at start of stress induces Mrig flowering; paclobutrazol (Cultar) 3000 ppm in first fortnight of May on black cotton soils when pre-monsoon rain weakens stress; chlormequat 2 ml/L repeated after 20 days if rain falls during stress. Harvest Feb–Mar. [PDKV; CCRI-May/Jun]
- Breaking Ambia stress on 1 Jan gave significantly lower psylla than 10/20/30 Jan; 6×6 m spacing had less psylla than 3×3 m; vermicompost 10 kg/tree best manure (Rao et al., IJAgS 83(10) 2013, https://krishi.icar.gov.in/ohs-2.3.1/index.php/record/view/80586).
- Mosambi: three flushes (ambia, mrig, hasta); fruit set → harvest ≈234–244 days for Ambia in Marathwada (Ladaniya & Mahalle IJAgS 2011; Patil & Panchal J. Hortl. Sci. 2016).
- **Gap:** no ICAR/SAU Hasta schedule for Nagpur mandarin found (only acid lime) → card stays draft, log question.
- Legal flags: Cycocel/chlormequat and paclobutrazol — confirm citrus PGR label claim in CIB&RC PGR list before showing; GA3 and 2,4-D have **no citrus label claim** found (GA3 grapefruit only) → show as "ICAR-recommended; label status caution; consult expert", never as a plain instruction.

### 3.2 Fruit drop
- Causes: physiological (heat, water stress, nutrient → ethylene/ABA), pathological (*Colletotrichum gloeosporioides*, *Diplodia natalensis*, *Alternaria citri*; peak mid-Sep to mid-Oct), entomological (fruit fly, fruit-sucking moth) [PAU 2019].
- CCRI Ambia schedule: Mar 2,4-D 1.5 g + urea 1 kg /100 L; at sudden rise to 35–40 °C use 2,4-D 1.5 g + KNO3 1 kg /100 L; Apr–Aug 2,4-D or GA3 1.5 g + carbendazim 50 WP 100 g + urea 1 kg /100 L, repeat at 15 days if drop continues (April text says benomyl — banned; use the May–Sep carbendazim wording); Sep carbendazim 100 g + GA3/2,4-D/NAA 1.5 g /100 L; Oct 2,4-D 1.5 g + urea 1 % then GA3 1.5 g after 15 days. [CCRI-Mar…Oct]
- PDKV: 3 monthly sprays from July of copper oxychloride 0.3 % or carbendazim 0.1 % for Ambia drop.
- Trials: carbendazim lowest fungal drop (11.6 %), COC 12.3 %, *Bacillus subtilis* 0.5 % cut drop 35.5 % (Mohod et al. 2019, https://agris.fao.org/search/en/records/65de5e227c7033e84beab6d9); Kinnow: 2,4-D 20 ppm + KNO3 1 % + Curzate M8 0.25 % in Sep & Oct cut drop 26 % → 10.2 % (Kumar et al. 2018, https://thaiscience.info/Journals/Article/WJST/10990601.pdf).
- Fruit-sucking-moth drop: CCRI sachet technology used phorate/acephate — phorate **banned**; card must use neem oil 10 ml/L at colour break, bait traps, burying fallen fruit, smoke 7–8 pm, light trap (CCRI-Aug/Sep/Oct; NIPHM).

### 3.3 Diseases
- **HLB/greening:** certified/indexed budwood (CCRI PCR-tested mother trees), psylla control, nutrition, water management; CCRI spray tetracycline HCl 600 ppm + ZnSO4 200 g + FeSO4 200 g (advgde.pdf) — antibiotic use must pass gate; NIPHM: bud high 30–46 cm, keep water off trunk, trunk paint Bordeaux or ZnSO4:CuSO4:lime 5:1:4 to 60 cm yearly. No cure; infected trees removed.
- **Canker:** prune/burn affected parts; COC 180 g + streptocycline 6 g / 60 L, 3–4 sprays at 30-day intervals Jun–Sep [CCRI]; NIPHM COC 0.3 % / Bordeaux 1 % / chlorothalonil 0.2 % at 15-day intervals. Label claims exist: COC 50 WP (canker); streptomycin 90 % + tetracycline 10 % SP 50–100 ppm, repeat 15–20 d [PPQS-F]. Bioagent evidence: *Bacillus amyloliquefaciens* vs *X. citri* (DOI 10.3390/microorganisms11122928, CC BY; DOI 10.1186/s41938-024-00795-3, CC BY) — research level, not a label claim.
- **Phytophthora gummosis / root rot:** scrape gum, wash KMnO4 10 g/L, paste Mefenoxam MZ-68 or fosetyl-Al; canopy spray/drench 2.5 g/L; Bordeaux paste (1 kg CuSO4 + 1 kg lime, each soaked in 5 L overnight, mixed, used within 12 h) on trunk to 60 cm pre- and post-monsoon; brown rot on Ambia fruit: 2 sprays Mefenoxam MZ 2.5 g + carbendazim 1 g /L, 30 d apart [CCRI]. PDKV: drench 0.2 % metalaxyl MZ 10–20 L/plant; *Pseudomonas fluorescens* outperformed *Trichoderma viride* in greenhouse. PAU: *Trichoderma asperellum* talc 15 g/kg gave 83 % control vs Ridomil Gold 79 % (Choudhary et al. IJAgS 2022, DOI 10.56093/ijas.v92i9.122917, CC BY-NC-SA). Label claims found: metalaxyl 3.3 % + chlorothalonil 33.1 % SC 200 ml/100 L, 5 L/tree drench, PHI 51 d; cymoxanil 8 % + mancozeb 64 % WP 250 g/100 L, 10 L/tree, PHI 82 d; aureofungin 1 % drench, PHI 30 d [PPQS-F]. **Metalaxyl+mancozeb and fosetyl-Al: no citrus row found** → gate decides.
- **Twig blight / dieback (Colletotrichum):** prune 2 cm below dead wood, carbendazim 1 g/L (Nov/Dec/Apr) [CCRI]; label: carbendazim 12 % + mancozeb 63 % WP 0.3 % on mandarin, PHI 30 d [PPQS-F].
- **Powdery mildew:** wettable sulphur 80 WP label 3.13 kg/ha [PPQS-F]. **Tristeza:** CTV-free budwood, tolerant rootstock, aphid control [NIPHM; PDKV]. **Alternaria:** no Indian dose source → draft only; use Alter-Rater model (§3.7) for risk.

### 3.4 Pests (IPM first, chemicals only via gate)
- **Psylla:** spray at bud burst/flush, repeat 10–15 d, rotate groups [CCRI]. Best research module: thiamethoxam 0.008 % 20 d before flush, then abamectin 0.0006 % + imidacloprid 0.009 % during flush (Rao et al. IJAgS 2017); bio-rationals abamectin 0.38 ml/L, petroleum spray oil 5.9 ml/L, novaluron 0.55 ml/L (Rao & Shivankar IJAgS 2011). Label claims: imidacloprid 17.8 SL (PHI 15 d), cyantraniliprole 10.26 OD 600 ml/ha (PHI 5 d), spirotetramat 15.31 OD 6 ml/10 L (PHI 30 d) [JAU compilation → confirm on PPQS]. Dimethoate/chlorpyriphos **not usable** (§3.8).
- **Leaf miner:** pluck/destroy affected flush; CCRI pheromone lure (up to 55 % reduction); fish-oil rosin soap 25 g/L [NIPHM]; imidacloprid label (leaf miner).
- **Blackfly/whitefly:** neem oil 1 % emulsified best botanical [PDKV]; azadirachtin 1500 ppm at 50 % egg hatch + 15 d; yellow sticky / water-pan traps 4–5 per acre [NIPHM].
- **Mealybug:** destroy ant nests; *Cryptolaemus* 10 beetles/tree [NIPHM]; *Verticillium lecanii* 1.15 % WP 2500 g/ha label [PPQS bio]. Chlorpyriphos/dichlorvos **illegal**.
- **Mites ("lalya"):** wettable sulphur 3 g/L; propargite 1 ml/L and ethion 2 ml/L listed by CCRI but citrus label not confirmed; diafenthiuron 50 WP 2 g/L label (PHI 30 d) [JAU → confirm]. Dicofol **banned**.
- **Fruit fly:** methyl eugenol traps 20/ha from 60 d before harvest, lure change 30 d; bury fallen fruit ≥60 cm [CCRI; PAU].
- **Bark-eating caterpillar:** remove frass, plug tunnels; CCRI's dichlorvos injection is **illegal** → card shows mechanical control + "consult expert for a registered alternative".
- **Nematodes:** Nemastin (bio) 2 kg/plant in FYM label; carbofuran 3 % CG 12 kg/ha label [PPQS].
- Entomopathogens (*Metarhizium*, *Beauveria*) vs psylla: foreign trials only (e.g. DOI 10.1017/S1742758412000069, paywalled); no Indian citrus label → research card, not a recommendation.

### 3.5 Nutrition
- CCRI bearing tree (soil, Nov): urea 500 g + SSP 600 g + MOP 150 g + 100 g each FeSO4/MnSO4/ZnSO4 + borax 50 g per tree; Ambia July top-up MOP 180 g; young trees (×1–4 by age): urea 108 g (or amm. sulphate 250 g) + SSP 157 g + 25 g each ZnSO4/FeSO4/MnSO4 (Apr & Aug) + FYM 20–25 kg [CCRI-Nov/Jul/Apr/Aug].
- PDKV full-grown tree: 1200 g N + 400 g P2O5 + 400 g K2O per year; 600 g N + all P & K at stress release, remaining N two months after fruit set; ZnSO4 200 g/tree soil; alternative 800:300:600 + 7.5 kg neem cake [PDKV]. (**Conflict** with CCRI dose — reviewer decides; show both with source.)
- Fertigation RDF 600:100:200 g N:P2O5:K2O/plant; 80 % ER irrigation + 80 % RDF → 19.2 t/ha (Shirgure et al. IJAgS 2016); Zn fertigation 200 g ZnSO4/tree in 4 pulses at 40-day intervals from 40 DAA → 16.4 t/ha (Shirgure & Srivastava IJAgS 2022).
- DRIS optimum leaf ranges (Nagpur mandarin, 57 orchards): N 1.70–2.81 %, P 0.09–0.15 %, K 1.02–2.59 %, Ca 1.80–3.25 %, Mg 0.43–0.92 %, Fe 74.9–113.4, Mn 54.8–84.6, Cu 9.8–17.6, Zn 13.6–29.6 ppm (Srivastava & Singh IJAgS 2007, https://krishi.icar.gov.in/ohs-2.3.1/index.php/record/view/74968). INM cuts fertiliser 25 %; fertigation cuts fertiliser 30 %, water 40 % [CCRI technologies].

### 3.6 Irrigation
- CCRI drip L/tree/day (Nagpur mandarin / sweet orange): Jan 7–30 (1–4 yr), 44–72 (5–7), 82–102 (8+); Feb 9–40 / 60–96 / 108–137; Mar 12–53 / 78–127 / 145–180; Apr 163 (8 yr), 204 (10+); May 17 (1 yr), 102 (5), 188 (8), 235 (10+), every 4–5 d at up to 47 °C; Sep 8/45/87/108; Oct 9 (1 yr), 40 (4), 105 (8); Nov 8/36/85/105; Dec 41 (6 yr), 82 (10+). Acid lime ≈ half. [CCRI monthly] (Oct "13 L" is a typo → 105 L.)
- 80 % pan-evaporation replenishment in all stages: 16.1 t/ha vs 7.8 t/ha at 30 %; May–June most critical (Shirgure et al. IJAgS 2014). Kc ≈0.60 flowering, 1.10–1.20 fruit development; subsurface drip 46 L/d (Jan–Feb) to 86 L/d (May–Jun) vs surface 115–216 L/d, +25 % yield, 60 % water saving (Meshram et al. 2025).
- Mulch 5–10 cm straw or 100-micron black polythene [CCRI]; 5 cm straw conserved 17.6 % more moisture [PDKV]; basin irrigation at 40 % depletion ≈ 60 mm CPE [PDKV]; drainage channels every 2 rows, 30 cm deep [CCRI-Jun].

### 3.7 Weather → risk rules (for M4 alert cards; parameters are starting points for local calibration)
- Heat/fruit-drop: CCRI triggers KNO3 + 2,4-D spray at sudden rise to 35–40 °C (March) → alert "heat wave, fruit-drop risk, irrigate, avoid midday spraying".
- Psylla: development favoured 25–30 °C with humidity + dry spells; peaks Feb–Mar and Aug–Sep tracking new flush, lows May–Jun and Dec (Wankhade et al., IJAR, https://arccjournals.com/journal/indian-journal-of-agricultural-research/A-4305; Rao & Shivankar 2011); egg-laying optimum 25–30 °C, <16 °C slows, >34 °C shortens life (UF/IFAS CG097). **ACP degree-day model**: lower threshold 11.11 °C, upper ≈32 °C; egg 60 DD, nymph 180 DD, generation ≈580 DD (Coop & McRoberts 2013 working doc, https://hopper.science.oregonstate.edu/wea/ACP_phenology_model1.pdf, after Liu & Tsai 2000).
- Leaf miner: starts SMW 36, peaks SMW 42 (Nagpur nursery), r = +0.56 with evaporation (Lavhe et al. 2024, https://www.phytojournal.com/archives/2024/vol13issue2/PartC/13-2-5-117.pdf).
- Alternaria brown spot: **Alter-Rater** (Timmer et al. 2000, Plant Disease 84:638–643, DOI 10.1094/PDIS.2000.84.6.638; UF/IFAS PP-147/CG021): daily points from rain yes/no, leaf wetness <10 h / >10 h, mean temp <20 / 20–28 / >28 °C; spray at 50–150 accumulated points. Adapt with local calibration; needs leaf-wetness sensor or estimate (M7).
- Canker: spread by wind-driven rain; symptoms ~107 d after storm (Gottwald et al. 2002); new flush most susceptible; numeric thresholds **[UV]** → alert on "storm + flush present".
- Phytophthora: thrives 29–32 °C, saturated/low-lying soil; CCRI timing trunk paste pre-monsoon (May–Jun) and post-monsoon (Oct–Nov). No operational leaf-wetness model exists anywhere → rule-based on rainfall + soil type.

### 3.8 Legal status of commonly recommended chemicals (checked 2026-10-12; re-verify against gazette)
| Chemical | Status in India |
|---|---|
| Benomyl, phorate, methyl parathion | **Banned** — S.O. 3951(E) 8 Aug 2018 |
| Dichlorvos (DDVP) | **Banned** for use — S.O. 3951(E); export-only manufacture S.O. 1196(E) 2020 |
| Dicofol | **Banned** — S.O. 4294(E) 3 Oct 2023 |
| Chlorpyrifos | **Prohibited on citrus**, ber, tobacco — S.O. 4294(E) |
| Dimethoate | Prohibited on fruits/vegetables eaten raw — S.O. 4294(E) → treat as **not usable on mandarin** |
| Monocrotophos | Banned on vegetables (S.O. 1482(E) 2005); 36 % SL phase-out (S.O. 4294(E)) |
| Mancozeb | Restricted on guava/jowar/tapioca; citrus label only in combinations |
| Quinalphos, malathion | Restricted on specific other crops; citrus label limited (quinalphos: scale, butterfly) |
| Carbendazim, 2,4-D, thiophanate-methyl | Not banned; were in the 14 May 2020 **draft** 27-pesticide list (not finalised); 2,4-D has **no citrus PGR label** |
| GA3 | Registered; **no citrus label** (grapefruit only) |
| Copper oxychloride; streptomycin + tetracycline | Registered **with citrus canker label** |
| Imidacloprid | Registered, citrus label (psylla, leaf miner), PHI 15 d |
| Metalaxyl+mancozeb, fosetyl-Al | Not banned; **no citrus row found** in fungicide list (metalaxyl+chlorothalonil has one) |
| Thiamethoxam, ethion, propargite, spiromesifen, abamectin, diafenthiuron, cyantraniliprole, spirotetramat | Registered; citrus label claim **to be confirmed on PPQS** (seen only in secondary compilations) |

### 3.9 Rootstock, planting, HDP, harvest, post-harvest
- Rangpur lime best of 18 rootstocks (156 kg/tree) vs rough lemon 102, Cleopatra 55 (Gupta et al., Trop. Agric. 2008); PDKV: Rangpur lime/Jamberi, 6×6 m for Vidarbha. Pits 75 cm³ at 6×6 m (May); fill 2 soil : 1 sand : 1 FYM + 1 kg SSP + 1 kg neem cake (CCRI's "100 g chlorpyrifos powder" is now illegal → omit); plant July, bud union 20–25 cm above ground; site: clay <60 %, pH <8.3, CaCO3 <12 %, water table >2 m [CCRI-May/Jun/Jul]. HDP on Rangpur lime: 6×3 m best B:C 6.36 at year 5 (Ladaniya et al., Sci. Rep. 2021, DOI 10.1038/s41598-021-89221-4).
- Maturity (Ambia, NRCC): TSS 11.2 %, acidity 0.69 %, juice 43 %, fruit 114 g (Ram & Kumar IJAgS 2012). Agmark grades A 54–61, B 62–69, C 70–77, D 78–85, E >85 mm; min TSS 10 °Brix, TSS:acid ≥12:1, juice ≥40 %. Industry 70 mm norm fell to 60 mm in the 2026 drought (FreshPlaza). Storage 6–7 °C, 85–90 % RH; export 10 kg CFB 49.5×29.5×17.5 cm [NHB]. Pre-harvest colour: ethephon 250 ppm + Ca-acetate 1 % + carbendazim 500 ppm advanced colour ~20 d (Sonkar & Ladaniya 1999) — gate. Degreening parameters and APEDA residue protocol for Nagpur mandarin: **[UV]**.

### 3.10 Conflicts recorded for reviewers
1. Fertiliser N: CCRI ~230 g N/tree vs PDKV 1200 g vs fertigation RDF 600 g vs Zn-trial base 450/500 g.
2. CCRI-Apr benomyl vs May–Sep carbendazim.
3. CCRI-Oct drip typo (13 vs 105 L).
4. Meshram 2025 Kc 0.30–1.10 (methods) vs 0.20–1.10 (results).
5. Psylla peaks differ by region (Vidarbha Feb–Mar/Aug–Sep vs Meghalaya June).
6. Ambia harvest window: Sep–Dec (Wikipedia) vs Oct–Nov (NIT paper) vs "finish by first week Dec" (CCRI).
7. CCRI still lists dicofol, dichlorvos, chlorpyriphos, dimethoate, phorate (banned/restricted).

---

## 4. The legal and safety gate (non-negotiable)

A chemical (including antibiotics and PGRs) can appear in any card, alert, AI answer, task template or voice reply **only if all hold at display time**:
1. Active ingredient + formulation has a CIB&RC label claim for that **crop (citrus/mandarin/acid lime as applicable) and target pest/disease** (`kb_label_claims`).
2. It is not banned, withdrawn, refused, or restricted for that crop (`kb_restrictions`).
3. Dose, interval, number of sprays and PHI shown come from the label claim (not from older guidance); PHI vs planned harvest date is checked; MRL / export constraints checked where applicable.
4. The card is `published` with a valid, unexpired expert review.
If any check fails the chemical is suppressed, the card shows only cultural/organic options plus "consult your local expert/KVK", and an admin task is created. An "ICAR-recommended but no label claim" case (e.g. 2,4-D, GA3) is shown **only** as a clearly labelled caution note approved by a reviewer, never as a dose instruction. Re-run the gate nightly and on every data import; when status changes (new ban), affected published cards are automatically pulled and an admin alert is raised.
Never show brand names or "where to buy". Every chemical suggestion carries: "Read the label; follow PHI; wear protective gear; verify with a local expert."

---

## 5. Knowledge model and ingestion pipeline

Tables (all content language-keyed; English source + `mr`/`hi`/… with a human-review flag): `kb_sources` (title, publisher, URL, fetch date, hash, **tier**, **licence**, allowed_use enum: `copy | summarise_cite | cite_only | internal_only`), `kb_topics`, `kb_cards` (symptoms + reference photos, cause, cultural practice, organic/biological option with evidence level, chemical option as active ingredient + formulation + dose + interval + PHI + max sprays, resistance note, warnings, when-to-call-expert, sources with page/section, status draft → expert_reviewed → published → retired, reviewer, reviewed_at, review_due_at, version), `kb_label_claims`, `kb_restrictions`, `kb_mrl`, `kb_models` (weather-risk model parameters, e.g. Alter-Rater points, ACP DD thresholds, with calibration fields per taluka), `kb_reviews`, `kb_conflicts`.
- Licence rule enforced in code: cards derived from `summarise_cite` or `cite_only` sources (UF/IFAS NC-ND, UC IPM, EPPO, Fundecitrus, CRI) store only our own wording plus citation; raw text from such sources is never stored in a user-visible field. `internal_only` sources never reach growers.
- Ingest Tier 1/2 documents (PDF/HTML) into `kb_sources`; extract text; let Claude draft **candidate cards** with page-level citations and a conflict list; drafts never auto-publish.
- Month-wise CCRI guidelines seed stage templates, monthly task templates, irrigation-by-age tables and fertiliser schedules as configurable data with citations, after gate + review.
- CIB&RC / banned-list / FSSAI importers for the official PDFs with a manual-upload fallback; version-dated; diff report on each import.
- Conflict detection: when sources differ, store both, flag, require reviewer choice; log the question.
- Every card shows its source and review date to the grower ("Based on ICAR-CCRI guidance, reviewed by <reviewer>, <month year>").

## 6. Expert review workflow (admin web UI)
Reviewer roles (agronomist, plant pathologist, entomologist) with queue, side-by-side source excerpt and drafted card, approve / edit / reject with comments, review-expiry reminders (default 12 months; 6 months for chemical cards; configurable). Until a real reviewer is attached, cards stay `draft` and the app ships only the safe subset: cultural practices, record-keeping templates, bahar calendar dates, irrigation tables, and weather risk alerts **without chemical advice**. Log this as a launch dependency.

## 7. How AI uses the knowledge base
- Retrieval-grounded only: Claude answers from `published` cards plus the grower's own records; retrieval via Postgres full-text + pgvector (ADR). Answers cite card ids; no supporting card → "I don't have a verified answer; here is who to ask" + expert escalation.
- Photo diagnosis returns *suspected issues with confidence* mapped to `kb_topics`; shown advice is the mapped card after the gate; low confidence or high severity → "send to expert" with photos and plot context. Never state a diagnosis as certain.
- Bahar treatment is decision support (compare ambia/mrig/hasta by water availability, last bahar, market timing; show CCRI calendar for stage and tree age; local expert overrides per taluka), not a prescription.
- Post-generation **output filter** scans every AI response, alert, notification and voice script for active-ingredient names (maintain a synonym/brand → AI dictionary) and removes anything failing the gate before display.
- Prompt templates, thresholds and disclaimer texts live in the DB.

## 8. Feedback and data flywheel
After a recommended action, ask the grower (voice/icons) whether it worked and prompt a follow-up photo; store outcome with the card version used; aggregate (anonymised, per taluka/week) for outbreak detection and to show experts which cards under-perform. Outcomes create review tasks; they never change published cards automatically. Field image dataset: consented, geotagged, stage-tagged photos from the owner's orchard, early users and partner FPOs; expert-labelled; held-out evaluation split; accuracy tracked per issue and device class; private by default; research use only with explicit consent.

## 9. Tests (mandatory, in CI)
- Gate tests (table-driven): benomyl, dichlorvos, dicofol, phorate, chlorpyrifos (citrus), dimethoate (raw-eaten fruit) never appear for citrus anywhere; a product with no citrus label for the given pest is suppressed; PHI conflicts block; a new ban imported tonight pulls affected cards; "no label claim" ICAR items render only as reviewer-approved caution notes.
- Licence tests: cards citing `summarise_cite`/`cite_only` sources contain no verbatim spans > N words from the source text.
- Golden Q&A set: 150+ expert-approved questions (disease, bahar timing, fruit drop, nutrition, irrigation, organic options) in Marathi/Hindi/English with expected cards and forbidden outputs; regression threshold gates merges.
- Red-team tests: brand names, banned chemicals, off-label mixes, dosage escalation must be refused or redirected.
- Pipeline tests: PDF extraction fixtures (including the CCRI PDFs), citation presence, conflict detection, review-expiry, importer diffing. Model tests: Alter-Rater point accumulation and ACP DD accumulation against hand-computed fixtures.
- Coverage ≥ 90 % on gate, filter and model modules.

## 10. Milestones (interleave with main spec)
- **K0 (with M0/M1):** data model, source registry seeded from §2 with tier/licence, admin UI skeleton, CCRI monthly calendar + irrigation/fertiliser tables as *draft*, cultural-only subset publishable.
- **K1 (before any chemical text ships):** CIB&RC label-claim, restrictions and MRL importers; gate; output filter; §9 tests.
- **K2 (with M3):** retrieval, cited AI answers, photo-diagnosis mapping, expert-escalation flow.
- **K3 (with M4):** weather-risk cards and `kb_models` (heat/fruit-drop, psylla window + DD model, Alter-Rater, canker storm+flush, Phytophthora rainfall/soil), reviewed and gated.
- **K4 (ongoing):** reviewer onboarding, review-expiry automation, feedback loop, field dataset growth, quarterly re-verification of sources, request CCRI Calendar of Operations and data-sharing (owner).
Write the Definition of Done for each in `docs/PLAN.md` and execute the demo checklist at the end of each, recording results in `docs/PROGRESS.md`.
