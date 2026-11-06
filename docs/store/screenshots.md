# Play Store screenshot shot-list

Play needs 2–8 phone screenshots per language (PNG or JPEG, 16:9 or 9:16, each side 320–3840 px; a
1080 × 1920 or 1080 × 2400 capture from a real phone is fine), plus a **feature graphic** 1024 × 500 and the
**app icon** 512 × 512 (scale the master image in `app/assets/icon/`, drawn by
`app/tool/make_launcher_icon.py`). Take the set three times: app language Marathi (`mr-IN` listing), Hindi
(`hi-IN`), English (`en-IN`).

## Rules for every shot

- Use a **Release APK** build (no TEST BUILD badge, no dev gallery), signed in to a **staff test account**,
  never a real grower's account: no real names, phone numbers, policy numbers, buyer names or plot locations.
  Type made-up values (worker "Ramesh", buyer "Krishi Traders", policy "TEST-0001").
- Nothing on the screen may give a chemical name with a dose or a spray recommendation. Spray-log shots show a
  record the grower typed; use a plain product name such as "Spray 1" or leave the product field short.
- Status bar clean (full battery, no notifications), phone time any, light theme, font size default.
- No "sample data" chip in a shot: if a screen still shows sample data, skip that screen.
- No text overlays that claim results ("double your yield", "best app"); short captions naming the screen are
  fine (e.g. "Bahar-wise records").

## The shots (in this order)

| # | Screen (route) | What to set up first | Caption idea (en / mr) |
|---|---|---|---|
| 1 | My orchard (`/plots`) | 2 plots entered, a bahar started (Home only if it shows no sample data) | Your orchard at a glance / तुमची बाग एका नजरेत |
| 2 | Plot detail with weather (`/plots/:id`) | Plot with a location; online once so weather loaded | Weather for your plot / तुमच्या प्लॉटचे हवामान |
| 3 | Boundary walk (`/plots/new/boundary`) | Three or four corners marked (test location, not a real farm) | Mark the plot boundary / प्लॉटची हद्द नोंदवा |
| 4 | Bahar screen or bahar compare (`/plots/:id/bahar`, `/bahar/compare`) | Two bahar cycles with dates | Bahar by bahar / बहारनुसार नोंदी |
| 5 | Accounts (`/plots/:id/accounts`) | A few expenses and one sale | Expenses and sales / खर्च आणि विक्री |
| 6 | Tasks with a reminder (`/tasks`) | Three tasks, one with a reminder | Tasks and reminders / कामे आणि आठवण |
| 7 | Market prices (`/market`) | Server has `MARKET_API_KEY`; prices loaded | Mandi prices / बाजारभाव |
| 8 | Orchard practices or look-alike cards (`/practices`, `/lookalikes`) | none | Guides with sources / स्रोतांसह माहिती |

Spares (use if one above is weak): scouting log with a photo (`/plots/:id/scouting`), crop insurance
(`/plots/:id/insurance`), season calendar (`/calendar`), schemes (`/schemes`), the login page.
*[if on]* Sarkari Sandesh list (`/feed`) only when the release has it on and at least one approved notice is
published.

## Feature graphic (1024 × 500)

App icon on the left, the product name in the listing's language (BagMitra / बागमित्र), one line such as
"Orchard diary for santra and mosambi" / "संत्रा व मोसंबी बागेची डायरी". No price, no "No. 1", no
screenshots of other apps, no Google Play badge.

## After taking them

Check each image on a phone screen for cut-off text and contrast (OWNER_RULES D.3). Keep the files outside the
public repository (they are store assets, not source).
