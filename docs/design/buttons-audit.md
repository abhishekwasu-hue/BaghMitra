# Buttons audit and rules (2026-11-12)

Owner, 2026-11-12 (dark-mode screenshot of a ज्ञान लेख): "कार्ड उघडा" says nothing; buttons must
*feel* like buttons (they matched the background); green would be better; every button
highlighted and bold, everywhere; audit first.

Same PR: article reading (owner, same day: "multi colour, highlight the important words").

## 1. Audit (main before this PR)

398 button-like controls in `app/lib` (326 grower app, 72 admin):

| Type | Count | Role in practice | Light (before) | Dark (before) |
|---|---:|---|---|---|
| `FilledButton` (+ `.icon`, 3 `.tonal`) | 106 | main commit: Save / Add / Send in `BottomActions`, dialog confirm, camera | santra fill, dark ink, 56 dp | same; stands out |
| `OutlinedButton` (+ `.icon`) | 73 | secondary (Gallery, Paste, Copy link, Settings), but also the only action of a card ("कार्ड उघडा") and removals ("माझ्या यादीतून काढा") | no fill, 1.5 px leaf-2 outline, w600 | no fill, outline on the page colour: **reads as a text box** |
| `TextButton` (+ `.icon`) | 80 | secondary (Cancel, Skip, Change, Resend OTP), dialog Delete, "कार्ड उघडा" on Q&A, links (terms, maker page), section "see all" | green text only | green text only: **looks like plain text** |
| `IconButton` | 45 | app-bar actions (21), icon-only content actions (speak, share, copy number, trend, details, call), field clear / remove X, rating stars | bare icon | bare icon |
| `InkWell` rows | 27 | list rows, cards and banners that open something (19), link rows that copy a URL (4), pickers (4) | row / card | row / card |
| `GestureDetector` | 8 | home header (forecast, profile), home price / stage cards, test badge, chart scrub | tile | tile |
| `ActionChip` | 6 | value pickers (date, trader, category, report name) | chip | chip |
| `FilterChip` / `ChoiceChip` | 3 / 50 | selection inputs, not actions | chip (santra when picked) | chip |

<details><summary>Per file (main before this PR)</summary>

| File | Filled | Outlined | Text | Icon | InkWell | Gesture | ActionChip | FilterChip | ChoiceChip |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `admin/admin_app.dart` |  |  |  | 1 |  |  |  |  |  |
| `admin/admin_sign_in.dart` | 1 |  |  |  |  |  |  |  |  |
| `admin/billing_pages.dart` | 3 | 1 | 2 | 1 |  |  |  |  |  |
| `admin/billing_photo_limits.dart` | 1 |  |  |  |  |  |  |  |  |
| `admin/feed_pages.dart` | 4 | 5 | 8 | 4 |  |  |  | 1 |  |
| `admin/feedback_admin.dart` |  |  | 2 |  |  |  |  |  | 1 |
| `admin/kb_pages.dart` | 2 | 1 | 1 |  |  |  |  |  |  |
| `admin/lot_settings_page.dart` | 1 |  |  |  |  |  |  |  |  |
| `admin/market_link_appeals_page.dart` | 1 | 1 | 1 |  |  |  |  |  |  |
| `admin/market_link_checks.dart` | 1 | 2 | 1 |  |  |  |  |  |  |
| `admin/market_link_pages.dart` | 3 | 2 | 2 |  |  |  |  |  |  |
| `admin/market_link_safety_pages.dart` | 2 | 1 | 3 |  |  |  |  |  | 1 |
| `admin/package_activation_page.dart` | 3 |  | 4 |  |  |  |  |  |  |
| `admin/package_pages.dart` | 2 | 1 | 1 |  |  |  |  |  |  |
| `design_system/alert_banner.dart` |  |  |  |  | 1 |  |  |  |  |
| `design_system/cards.dart` |  |  | 1 |  |  |  |  |  |  |
| `design_system/navigation.dart` |  |  |  |  |  | 1 |  |  |  |
| `design_system/share_speak.dart` |  |  |  | 1 |  |  |  |  |  |
| `design_system/sources_disclosure.dart` |  |  |  |  | 1 |  |  |  |  |
| `design_system/sync_banner.dart` |  |  | 1 |  |  |  |  |  |  |
| `design_system/task_tile.dart` |  |  |  |  | 1 |  |  |  |  |
| `design_system/weather_header.dart` |  |  |  |  |  | 2 |  |  |  |
| `features/accounts/presentation/accounts_screen.dart` | 1 | 1 |  | 3 |  |  |  |  | 2 |
| `features/accounts/presentation/add_entry_screens.dart` | 2 |  |  |  |  |  | 1 |  | 2 |
| `features/app_update/presentation/app_update_gate.dart` | 1 |  |  | 1 | 1 |  |  |  |  |
| `features/ask/presentation/ask_box.dart` |  |  | 1 | 1 | 1 |  |  |  |  |
| `features/auth/presentation/account_switch_screen.dart` | 2 | 1 |  |  |  |  |  |  |  |
| `features/auth/presentation/login_screens.dart` | 3 | 2 | 3 |  |  |  |  |  |  |
| `features/bahar/presentation/bahar_compare_screen.dart` |  | 1 |  |  |  |  |  |  | 1 |
| `features/bahar/presentation/bahar_screen.dart` | 2 |  |  |  |  |  |  |  |  |
| `features/bahar/presentation/cycle_chips.dart` |  |  |  |  |  |  |  |  | 1 |
| `features/bahar/presentation/start_bahar_screen.dart` | 1 |  | 2 |  |  |  |  |  | 1 |
| `features/billing/presentation/subscription_screen.dart` | 1 | 2 | 1 |  |  |  |  |  |  |
| `features/bills/presentation/bill_photo_field.dart` | 1 | 3 | 1 |  | 1 |  |  |  |  |
| `features/dev/component_gallery_screen.dart` | 1 |  |  |  |  |  |  |  |  |
| `features/directory/presentation/directory_screen.dart` |  |  |  | 1 | 1 |  |  |  | 2 |
| `features/export_info/presentation/export_info_screen.dart` | 1 |  |  |  |  |  |  |  | 1 |
| `features/export_info/presentation/export_record_screen.dart` | 1 |  |  |  |  |  |  |  | 3 |
| `features/feed/presentation/feed_article_view.dart` |  | 1 |  |  | 1 |  |  |  |  |
| `features/feed/presentation/feed_check_screen.dart` | 1 | 1 | 1 |  |  |  |  |  |  |
| `features/feed/presentation/feed_preferences_screen.dart` | 1 |  |  | 2 |  |  |  |  |  |
| `features/feed/presentation/feed_screen.dart` | 1 | 2 |  | 2 | 2 |  |  |  | 1 |
| `features/feed/presentation/feed_thread_screen.dart` |  |  |  |  | 2 |  |  |  |  |
| `features/feedback/presentation/feedback_screen.dart` | 1 | 1 |  |  |  |  |  |  | 1 |
| `features/field_work/presentation/harvest_screen.dart` | 1 |  |  |  |  |  |  |  |  |
| `features/field_work/presentation/labour_screens.dart` | 3 |  |  |  |  | 1 |  |  | 2 |
| `features/home/presentation/home_screen.dart` | 2 | 1 | 2 |  | 1 | 3 |  |  |  |
| `features/inputs/presentation/add_input_screens.dart` | 2 |  |  |  |  |  |  |  | 3 |
| `features/inputs/presentation/field_log_screen.dart` | 1 | 1 |  |  |  |  |  |  |  |
| `features/insurance/presentation/claim_kit_screen.dart` | 1 | 3 | 2 | 2 |  |  |  |  |  |
| `features/insurance/presentation/insurance_screens.dart` | 2 | 1 | 2 | 1 | 1 |  |  |  | 1 |
| `features/lab_tests/presentation/lab_test_screens.dart` | 2 | 4 | 5 | 3 | 1 |  | 1 |  | 1 |
| `features/labels/presentation/label_info_screen.dart` |  | 1 | 2 |  | 1 |  |  |  | 1 |
| `features/lookalikes/presentation/lookalikes_screen.dart` |  | 2 |  | 1 |  |  |  |  |  |
| `features/market/presentation/market_prices_screen.dart` |  |  |  | 4 |  |  |  |  | 1 |
| `features/market/presentation/price_trend_sheet.dart` |  |  |  |  |  | 1 |  |  | 1 |
| `features/market_link/presentation/deal_done_card.dart` | 3 |  | 2 |  |  |  |  |  |  |
| `features/market_link/presentation/introduction_screen.dart` | 1 |  | 1 |  |  |  |  |  |  |
| `features/market_link/presentation/lot_form_screen.dart` | 3 | 3 | 2 |  | 1 |  |  |  | 3 |
| `features/market_link/presentation/lot_offers_screen.dart` | 3 |  | 1 |  | 1 |  |  |  |  |
| `features/market_link/presentation/lot_photo_strip.dart` |  |  |  | 1 |  |  |  |  |  |
| `features/market_link/presentation/my_lots_screen.dart` | 1 |  | 1 |  | 1 |  |  |  |  |
| `features/market_link/presentation/my_profiles_screen.dart` | 1 |  | 2 |  |  |  | 1 |  |  |
| `features/market_link/presentation/offer_screens.dart` | 3 | 1 | 1 |  |  |  | 2 |  | 1 |
| `features/market_link/presentation/people_screen.dart` | 1 |  |  |  |  |  |  |  | 5 |
| `features/market_link/presentation/profile_widgets.dart` |  |  |  | 2 | 1 |  |  |  |  |
| `features/market_link/presentation/rating_screen.dart` | 1 |  |  | 1 |  |  |  | 1 |  |
| `features/market_link/presentation/registration_screen.dart` | 2 | 1 | 1 |  | 1 |  |  | 1 |  |
| `features/market_link/presentation/role_home_screen.dart` |  |  |  | 1 |  |  |  |  |  |
| `features/market_link/presentation/services_screen.dart` |  |  |  |  |  |  |  |  | 3 |
| `features/market_link/presentation/terms_acceptance_screen.dart` | 1 | 1 | 1 |  |  |  |  |  |  |
| `features/market_link/safety/account_actions_screen.dart` |  | 1 |  |  |  |  |  |  |  |
| `features/market_link/safety/safety_screens.dart` | 2 | 1 | 2 |  |  |  |  |  | 1 |
| `features/photo_analysis/presentation/photo_analysis_screen.dart` | 4 | 4 | 2 |  |  |  |  |  | 1 |
| `features/plots/presentation/add_plot_screen.dart` | 1 | 1 | 2 | 1 |  |  |  |  | 1 |
| `features/plots/presentation/boundary_screen.dart` | 2 | 1 |  |  |  |  |  |  |  |
| `features/plots/presentation/plot_detail_screen.dart` |  |  |  | 1 | 1 |  |  |  |  |
| `features/plots/presentation/plot_point.dart` | 1 | 3 | 1 |  |  |  |  |  |  |
| `features/plots/presentation/plots_screen.dart` | 2 |  |  |  | 1 |  |  |  |  |
| `features/practices/presentation/irrigation_guide_screen.dart` |  |  |  |  |  |  |  |  | 2 |
| `features/practices/presentation/practices_screen.dart` |  | 2 |  | 3 |  |  |  |  |  |
| `features/profile/presentation/name_script_prompt.dart` | 1 |  | 1 |  |  |  |  |  |  |
| `features/profile/presentation/onboarding_screen.dart` | 1 |  |  |  |  |  |  |  | 1 |
| `features/profile/presentation/profile_screen.dart` | 3 | 2 | 3 |  |  |  |  |  | 1 |
| `features/schemes/presentation/scheme_screens.dart` |  |  |  |  | 2 |  |  |  |  |
| `features/scouting/presentation/scouting_screens.dart` | 2 | 4 | 1 | 1 |  |  |  |  | 1 |
| `features/settings/presentation/settings_screen.dart` | 1 | 4 |  |  |  |  |  |  |  |
| `features/spray/presentation/add_spray_screen.dart` | 1 | 1 |  | 1 |  |  |  |  | 1 |
| `features/spray/presentation/spray_ingredient_picker.dart` |  |  |  |  | 1 |  |  |  |  |
| `features/spray/presentation/spray_log_screen.dart` | 1 | 1 |  |  | 1 |  |  |  |  |
| `features/tasks/presentation/add_task_screen.dart` | 1 |  |  |  |  |  | 1 |  | 2 |
| `features/tasks/presentation/tasks_screen.dart` | 1 |  | 1 | 3 |  |  |  |  |  |
| `features/voice/presentation/voice_mic_button.dart` |  |  |  | 1 |  |  |  |  |  |
| `features/walkthrough/presentation/walkthrough_screen.dart` | 2 |  | 1 |  |  |  |  |  |  |
| `features/weather/presentation/plot_weather_card.dart` |  |  | 2 | 1 |  |  |  |  |  |
| `sync/presentation/refresh_note.dart` |  |  | 2 |  |  |  |  |  |  |
| `sync/presentation/sync_status_banner.dart` | 1 |  | 1 |  |  |  |  |  |  |
| **Total** | **106** | **73** | **80** | **45** | **27** | **8** | **6** | **3** | **50** |

</details>

## 2. Rules (built in `theme/app_theme.dart` and `theme/button_styles.dart`)

Screens pick a widget; the theme gives the look. `BmButtonStyle` holds the roles a widget
cannot express on its own.

| Role | How | Light | Dark | Contrast (label on fill / edge on page) |
|---|---|---|---|---|
| **Main commit** (Save, Add, Send, dialog confirm, camera) | `FilledButton` (theme) | santra `#F28C28`, ink label, deep-santra edge, bold, 56 dp | santra, ink label | 6.1:1 / edge 5.5:1 |
| **Primary in a card or section** (see practices, try again, open settings, call) | `FilledButton` + `BmButtonStyle.primary` | leaf `#1F4D2B`, white bold label, icon, 48 dp | leaf-3 `#9BC79A`, ink bold label | 9.7:1 (light), 7.9:1 (dark) / fill ≥ 8:1 |
| **Secondary** | `OutlinedButton`, `TextButton` (theme) | leaf tint `#D4EBCF` fill, 1.5 px leaf-2 border, leaf bold label | leaf-2 `#2E6B3C` fill, 1.5 px leaf-3 border, light bold label | 7.7:1 (light), 5.5:1 (dark) / border 5.9:1, 9.4:1 |
| **Destructive** (delete, remove, hide) | any button + `BmButtonStyle.destructive` | warm tint, amber border, caution ink; no red fill | dark amber tint, amber ink | 6.2:1, 9.0:1 |
| **Icon-only** (speak, share, copy number, trend, details) | `IconButton` + `BmButtonStyle.icon` + tooltip | tonal circle with border, 48 dp | same, dark tones | ≥ 4.5:1 |
| **Icon-only main** (call) | `IconButton` + `BmButtonStyle.iconPrimary` | green circle | light-green circle | ≥ 4.5:1 |
| **Link** (terms, maker page, source links) | `TextButton` + `BmButtonStyle.link`; link rows underlined | leaf-2, underlined | leaf-3, underlined | ≥ 4.5:1 on page and card |

Decision: **santra stays the main commit, green is the primary inside content.** Santra save in
`BottomActions` is the established pattern (106 buttons, M5 "orange means action", camera
button). Green filled marks the one main action of a card or section that is not a commit
(see the practices, try again). Both are filled and bold, so neither reads as text; the colour
tells "save / add" from "go to / do here".

Left as they are, on purpose:
- **App-bar icons** (21): the app bar convention; a filled circle on every bar icon would crowd it.
- **Field clear / remove X, rating stars, +/- steppers**: inline input affordances, not actions.
- **InkWell rows and cards, GestureDetector tiles**: whole rows and cards are the tap target and
  show a chevron or are cards; making them buttons would double the frame.
- **Chips**: `ChoiceChip` / `FilterChip` are selections; `ActionChip` are value pickers that show
  the chosen value like a field.
- **Admin** pages follow the same theme (outlined / text buttons became tonal); no role
  changes there except the market-link Reject button (destructive).

Checks: `test/architecture/ui_guidelines_test.dart` "button labels and shapes stand out" (every
role, both themes: label ≥ 4.5:1 on its fill, edge ≥ 3:1 on page and card, disabled readable,
links ≥ 4.5:1, every label w700), plus the existing 48 dp tap-target and text-contrast checks
on 25 screens.

## 3. Changed call sites

| Where | Before | Now |
|---|---|---|
| Knowledge article: practices button | outlined "कार्ड उघडा" | green primary, full width, "उपाय व माहिती पहा" |
| Photo check result (online + offline): practices button | outlined "कार्ड उघडा" | green primary, "उपाय व माहिती पहा" |
| Q&A answer: practices button | text "कार्ड उघडा" | green primary, "उपाय व माहिती पहा" |
| Feed item: "स्रोताची लिंक कॉपी करा" | thin outline | tonal secondary |
| Feed item: "माझ्या यादीतून काढा" | thin outline | calm destructive |
| Speak / share (feed, alerts, prices, tasks) | bare icons | tonal circles, 48 dp, tooltip |
| Copy number (directory, market link), price trend, task details | bare icons | tonal circles |
| Market link call | default filled circle | green circle |
| Refresh line: "पुन्हा प्रयत्न करा" / sign in | text | green primary |
| Location problem: open settings / try again | outlined pair | the fix that helps is green primary |
| Dialog "हटवा" (plot, policy, loss record, lab test) | text | calm destructive |
| Delete account (link + confirm) | red text / red fill | calm destructive |
| Remove photo (scouting, bill, lab report), delete draft, delete analysed photo, resend-queue delete | red / muted text | calm destructive |
| Sync banner action, section header "see all" | coloured text | tonal secondary |
| Terms links, maker page | text | link: underlined |
| Feed source, directory web page rows | coloured text | link colour, underlined |
| Admin market-link Reject | red outline | calm destructive |

## 4. Renamed labels (en / mr / hi)

| Key | Before (mr) | Now (en / mr / hi) |
|---|---|---|
| `feedKnowledgeOpenCard` | कार्ड उघडा | See practices and details / उपाय व माहिती पहा / उपाय व जानकारी देखें |
| `photoCheckOpenCard` | कार्ड उघडा | same |
| `askOpenCard` | कार्ड उघडा | same |
| `photoCheckSeeCards` | कार्डे पाहा | See all practices / सर्व उपाय पहा / सभी उपाय देखें |
| `practicesKnowledgeCard` | ज्ञान कार्ड | Read the knowledge card / ज्ञान कार्ड वाचा / ज्ञान कार्ड पढ़ें |
| `practicesLabelLink` | लेबलप्रमाणे मंजूर औषधे | See label-approved products / लेबलप्रमाणे मंजूर औषधे पहा / लेबल अनुसार स्वीकृत दवाएँ देखें |

## 5. Article reading (knowledge articles, AI news articles, Q&A answers)

`design_system/article_reading.dart`, tones in `BmColors.tone*` (ink + tint, each ≥ 4.5:1):

- **Section cards**: each section is a card with a tinted header strip, a round icon chip and a
  19 sp heading in the tone ink. Heading meaning → icon / tone: काय दिसते / लक्षणे → eye, amber;
  कधी / हंगाम → calendar, blue; तपासावे → search, teal; करावे / उपाय → check, green; सावधगिरी /
  KVK ला विचारा → info, violet; स्रोत → link, grey; anything else → rotating palette.
- **Highlights** (drawn in the app, server text unchanged): numbers with units (२ मीटर, ₹, %,
  दिवस …) bold on a tinted pill; crop, pest, disease and stage names from the app's own cards
  (`core/kb_terms.dart`, each checked against `assets/config`) bold in the tone ink; first
  occurrence only, at most 4 per paragraph.
- **Bullets**: a paragraph of more than two sentences that splits cleanly on "." / ";" / "।" is
  shown as bullets; decimals and abbreviations never split.
- **Top**: a title card (topic icon chip, badge, title, the summary in a tinted box) and the
  "checked sources" byline as a small badge.
- **Bottom**: sources as compact link chips (a tap copies the link, as before) and the full-width
  green "उपाय व माहिती पहा".
- Facts, charts and key dates use the same cards (blue, teal, amber).
