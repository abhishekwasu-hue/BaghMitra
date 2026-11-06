# WP3 source register: schemes, directories, soil rating norms

Every page below was opened and read itself on **2026-11-06** (no search extracts). "Used for" names the config field it
backs. A page that could not be opened is listed under "Not reached", and what depends on it stays `verified: false`.

## Read

| Source (official) | URL | Used for |
|---|---|---|
| PIB: 22nd instalment of PM-KISAN (Mar 2026) | https://static.pib.gov.in/WriteReadData/specificdocs/documents/2026/mar/doc2026319829701.pdf | `schemes.json` pm_kisan: ₹6,000 / year in 3 × ₹2,000 to an Aadhaar-seeded account; land record, Aadhaar–bank link, e-KYC; portal |
| PM-KISAN operational guidelines (rev. 21.6.2019) | https://fw.pmkisan.gov.in/Documents/Revised%20Operational%20Guidelines%20-%20PM-Kisan%20Scheme.pdf | pm_kisan documents: Aadhaar, bank account, mobile, land records |
| GoI operational guidelines Kharif-23, PMFBY and RWBCIS (6 Nov 2024), on the state agriculture site | https://krishi.maharashtra.gov.in/Site/Upload/GR/ (file "OG titled as Operational Guidelines Kharif 23 …(2).pdf") | crop_insurance: optional for all (loanee opt-out ≥ 7 days before cut-off, 3.1.1.1); tenants / sharecroppers (3.1); Aadhaar mandatory (6.4.1); land record, passbook, sowing certificate (6.3.3); CSC (8.1); NCIP online form; farmer premium ≤ 5% of sum insured for perennial horticulture (13.1) |
| PIB explainer: Kisan Credit Card (11 Mar 2026) | https://www.pib.gov.in/PressNoteDetails.aspx?NoteId=157771&ModuleId=3&reg=48&lang=2 | kcc: collateral-free ₹2 lakh (from 1 Jan 2025); 7% − 3% prompt repayment = 4%; one-page form; land records + crops |
| RBI master circular: KCC (3 Jul 2017) | https://www.rbi.org.in/commonman/english/scripts/Notification.aspx?Id=2311 | kcc "who" (owner cultivators, tenants, oral lessees, sharecroppers, SHG / JLG) |
| MahaDBT home: Department of Agriculture scheme list | https://mahadbt.maharashtra.gov.in/ | apply place for micro_irrigation (PMKSY-PDMC), falbag, midh, smam |
| MahaPoCRA: orchard planting guideline NDKSP 2.0 (rates 2025-26) | https://mahapocra.gov.in/documents/Horticulture_Plantation_Guideline_NDKSP_2.0.pdf | pocra: eligibility 2.1–2.5; santra / mosambi 6 × 6 m, 277 / ha: ₹50,992 + ₹21,668 + ₹18,535 = ₹91,195 / ha; santra 6 × 3 m, 555 / ha: ₹1,35,355; survival 80% / 90% (3.12–3.13); DBT to Aadhaar-linked account; apply on dbt.mahapocra.gov.in (5.1.1) |
| Farm machinery DBT FAQ (GoI) | https://agrimachinery.nic.in/Files/FAQFMDBT.pdf | smam documents (Aadhaar, record of right, passbook) and "who" |
| Parbhani district: Agristack service page | https://parbhani.gov.in/en/service/agristack/ | agristack registry link and Maharashtra help desk 020-25712712 |
| ICAR: KVKs in Maharashtra (page "Last Update on 06-11-2026") | https://icar.org.in/en/node/15040 | `lab_directory.json` new kvk_dudhbardi (address, MAFSU); Kharpudi, Badnapur re-read |
| KVK Nagpur contact + soil test pages | https://www.kvknagpur.org.in/Contact.html, https://www.kvknagpur.org.in/SoilTest.html | kvk_nagpur re-read (page shows 07103-275537-39) |
| Dr. PDKV pages ?page_id=44, 126, 2207 and ?p=2217; KVK Selsura ?page_id=39 | https://www.pdkv.ac.in/ , https://kvkselsura.pdkv.ac.in/?page_id=39 | pdkv_akola, pdkv_ars_katol, pdkv_atic (Thursday 2.30–5.30 pm, 0724-2259262), Ghatkhed, Durgapur, Selsura re-read |
| ICAR institutes list | https://www.icar.org.in/en/institutes-networks | icar_ccri address re-read |
| MSAMB APMC profile (district list + committee record) | https://www.msamb.com/ApmcDetail/Profile ; records `ProfileDetail?apmcId=06390500` (Nagpur), `06390300` (Katol), `06390600` (Narkhed), `05331200` (Warud), `05330900` (Morshi) | `market_directory.json` address, phone, sub-markets, main commodities |
| Soil Health Card Scheme: Manual for District-Level Functionaries (2017), sample card p. 15–16 | https://www.nitiforstates.gov.in/public-assets/Policy/policy-repo/agriculture-and-allied-services/SNC511A000049.pdf | `lab_parameters.json` norms.soil (pH, EC, OC, P, K, S, Zn, Fe, Mn, Cu). Printed "OC High > 7.5" shown as > 0.75 (medium ends at 0.75). No N or B range, no micronutrient unit on the card. The card's colour-code fertiliser dose lines are not used. |

## Not reached (stays unverified)

| Page | Result | What stays open |
|---|---|---|
| soilhealth.dac.gov.in | HTTP 403 | `soil_health_portal` entry; district soil testing lab list |
| krishi.maharashtra.gov.in "मृदा तपासणी प्रयोगशाळा ठिकाणे", "जमीन सुपीकता निर्देशांक" (SHC category) | listed, file returns 404 | district soil labs; state fertility index |
| ataripune.icar.gov.in (KVK contact list) | 502 | phones for KVK Dudhbardi, Kharpudi, Badnapur |
| midh.gov.in, pmksy / pdmc.da.gov.in, agriwelfare.gov.in | 403 | MIDH and drip subsidy rates |
| myscheme.gov.in | page content loads by script only | myScheme pages stay listed, not used for facts |
| pmkisan.gov.in | TLS chain incomplete | FAQ; Farmer ID rule for new registrations |
| MahaDBT scheme detail pages (SchemeData) | HTTP 500 | documents per MahaDBT scheme |
| Bhausaheb Fundkar 2022-23 guideline (krishi site) | legacy-font PDF, text unreadable without OCR | Fundkar rates and documents |
| RWBCIS orange notification / GR (pages 2+ of the crop insurance list) | not reachable by the page's postback | orange sum insured, trigger, dates |
| Drip / sprinkler 55% / 45% up to 5 ha | only on Akashvani News (29 Aug 2026), not on a scheme page | not added (owner decision) |
