# Google Play store listing texts (en, mr, hi)

Draft for the owner to paste into Play Console → Grow → Store presence → Main store listing (one
translation per language: English (India) `en-IN`, Marathi `mr-IN`, Hindi `hi-IN`). Nothing here is
submitted anywhere. Limits: title ≤ 30, short description ≤ 80, full description ≤ 4000 characters
(Play counts characters, not bytes). Measured lengths are in the table at the end.

Written only from what the app does today (sources: `app/lib/features/more/presentation/more_screen.dart`
for the screens, `docs/legal/DATA_INVENTORY.md` for data). Rules kept: no chemical names, doses or
spray advice; no yield, income or "expert-approved" claims; no ranking words ("best", "No. 1"),
which Play's metadata policy does not allow.

**Before pasting, check the optional parts** (marked *[if on]* / *[if off]*; delete the markers, keep the
lines that match the release):
- *Sarkari Sandesh* (government notices and "Check a message") is in the release only when the Release
  APK run used `sarkari_sandesh: on`. If it was `off`, delete those lines.
- *Market prices* show data only when `MARKET_API_KEY` is set on the server (`vps-deploy.md` §४).
- *Phone (OTP) login* is shown only when the build has `PHONE_LOGIN=true` (an SMS provider is set up in
  Supabase, `test-apk.md` §1a). If not, the sign-in line must say Google only (alternative lines below it).
- Photo backup to the server is not promised in the texts (it depends on `PHOTO_STORAGE_*`).

---

## English (en-IN)

**Title (30 max)**

```
BagMitra: Orange Orchard Diary
```

**Short description (80 max)**

```
Bahar-wise records, tasks, spray log, accounts and mandi prices for your orchard
```

**Full description**

```
BagMitra is an orchard diary for Nagpur orange (santra) and sweet lime (mosambi) growers. Keep every record of your orchard in one place, bahar by bahar, in Marathi, Hindi or English.

WORKS WITHOUT INTERNET
Write your records in the field even with no signal. When the phone is online again, they are sent to your account and appear on your other phone too.

YOUR ORCHARD AND BAHAR
• Add each plot: crop, area, trees, spacing, irrigation, water source and soil
• Mark the plot boundary by walking its corners with the phone's location
• Start a bahar and compare one bahar with another
• Weather for your plot

RECORDS
• Spray log, fertiliser and other inputs, irrigation and harvest
• Labour: worker, wage and advance
• Accounts: expenses and sales, with buyer, rate and payment status
• Scouting notes with photos
• Crop insurance policies and a claim kit (photos and notes kept on the phone)
• Soil, water and leaf test values

WORK AND SEASON
• Tasks with reminders on the phone
• A season calendar for the next twelve months, from your own bahar dates and tasks

GUIDES AND HELP
• Orchard practice guides (non-chemical), each with its published source
• Look-alike symptom cards that help you describe what you see to a lab or an expert
• Irrigation guide, and a list of labs and experts
• Government schemes and the documents to keep ready, with links to the official pages

MARKET
• Mandi prices from Agmarknet (data.gov.in)
• Markets and buyers list

[if on] GOVERNMENT NOTICES (SARKARI SANDESH)
[if on] • Official GRs and notices for your district, checked by our team before they are shown
[if on] • "Check a message": compare a forwarded message with the published official notices

EASY TO USE
• Voice typing in the fields, and read-aloud
• Share your accounts as CSV and reports as PDF

YOUR DATA
[if on] • Sign in with your mobile number or Google
[if off] • Sign in with your Google account
• No ads and no advertising or analytics trackers
• Each account sees only its own records; data travels over HTTPS
• Delete your account and data any time from Profile in the app
• Privacy policy: https://bagmitra.aialgodesk.org/privacy

BagMitra keeps your records and shows general information. It does not recommend chemicals or doses; for those, ask your agriculture officer, KVK or a qualified expert.
```

---

## मराठी (mr-IN)

**शीर्षक (30 max)**

```
बागमित्र: संत्रा बाग डायरी
```

**छोटे वर्णन (80 max)**

```
बहारनुसार बागेच्या नोंदी, कामे, फवारणी नोंद, हिशोब आणि बाजारभाव एका ठिकाणी
```

**पूर्ण वर्णन**

```
बागमित्र ही नागपुरी संत्रा आणि मोसंबी बागायतदारांसाठी बागेची डायरी आहे. तुमच्या बागेच्या सर्व नोंदी बहारनुसार एका ठिकाणी ठेवा, मराठी, हिंदी किंवा इंग्रजीत.

इंटरनेटशिवायही चालते
शेतात रेंज नसतानाही नोंदी लिहा. फोन पुन्हा ऑनलाइन आला की त्या तुमच्या खात्यात जातात आणि तुमच्या दुसऱ्या फोनवरही दिसतात.

तुमची बाग आणि बहार
• प्रत्येक प्लॉट जोडा: पीक, क्षेत्र, झाडे, अंतर, ओलित, पाण्याचा स्रोत आणि माती
• फोनच्या लोकेशनने कोपऱ्यांवरून चालत प्लॉटची हद्द नोंदवा
• बहार सुरू करा आणि एका बहाराची दुसऱ्याशी तुलना करा
• तुमच्या प्लॉटचे हवामान

नोंदी
• फवारणी नोंद, खते व इतर निविष्ठा, ओलित आणि तोडणी
• मजुरी: मजूर, मजुरी आणि उचल
• हिशोब: खर्च आणि विक्री, खरेदीदार, दर आणि पैसे मिळाले की नाही
• फोटोसह पाहणी नोंद
• पीक विमा पॉलिसी आणि क्लेम किट (फोटो व नोंदी फोनवरच राहतात)
• माती, पाणी व पान तपासणीचे आकडे

कामे व हंगाम
• फोनवर आठवण देणारी कामे
• तुमच्या बहार तारखा व कामांवरून पुढच्या बारा महिन्यांची हंगाम दिनदर्शिका

माहिती व मदत
• बाग व्यवस्थापन पद्धती (रसायनांशिवाय), प्रत्येकीसोबत प्रकाशित स्रोत
• सारखी दिसणारी लक्षणे: जे दिसते ते प्रयोगशाळेला किंवा तज्ज्ञाला नीट सांगण्यासाठी कार्ड
• ओलित तक्ता, आणि प्रयोगशाळा व तज्ज्ञांची यादी
• सरकारी योजना आणि तयार ठेवायची कागदपत्रे, अधिकृत पानांच्या लिंकसह

बाजार
• Agmarknet (data.gov.in) वरील बाजारभाव
• बाजार व खरेदीदारांची यादी

[if on] सरकारी संदेश
[if on] • तुमच्या जिल्ह्यासाठीचे अधिकृत GR व सूचना, आमच्या टीमने तपासून मगच दाखवलेले
[if on] • "संदेश तपासा": आलेला forward संदेश प्रकाशित अधिकृत सूचनांशी जुळवून पाहा

वापरायला सोपे
• रकान्यांमध्ये बोलून लिहा, आणि मजकूर ऐका
• हिशोब CSV आणि अहवाल PDF म्हणून पाठवा

तुमची माहिती
[if on] • मोबाइल नंबर किंवा Google ने लॉगिन
[if off] • Google खात्याने लॉगिन
• जाहिराती नाहीत, जाहिरात किंवा analytics tracker नाहीत
• प्रत्येक खात्याला फक्त स्वतःच्या नोंदी दिसतात; माहिती HTTPS ने जाते
• ॲपमधील माझी माहिती (Profile) मधून खाते आणि माहिती कधीही पुसा
• गोपनीयता धोरण: https://bagmitra.aialgodesk.org/privacy

बागमित्र तुमच्या नोंदी ठेवते आणि सर्वसाधारण माहिती दाखवते. ते रसायने किंवा मात्रा सुचवत नाही; त्यासाठी कृषी अधिकारी, KVK किंवा पात्र तज्ज्ञांचा सल्ला घ्या.
```

---

## हिन्दी (hi-IN)

**शीर्षक (30 max)**

```
बागमित्र: संतरा बाग डायरी
```

**छोटा विवरण (80 max)**

```
बहार के अनुसार रिकॉर्ड, काम, छिड़काव रिकॉर्ड, हिसाब और मंडी भाव, आपके बाग के लिए
```

**पूरा विवरण**

```
बागमित्र नागपुरी संतरा और मोसंबी बागवानों के लिए बाग की डायरी है। अपने बाग के सभी रिकॉर्ड बहार के अनुसार एक जगह रखें, मराठी, हिंदी या अंग्रेज़ी में।

बिना इंटरनेट के भी चलता है
खेत में नेटवर्क न हो तब भी रिकॉर्ड लिखें। फ़ोन फिर से ऑनलाइन होने पर वे आपके खाते में जाते हैं और आपके दूसरे फ़ोन पर भी दिखते हैं।

आपका बाग और बहार
• हर प्लॉट जोड़ें: फसल, क्षेत्र, पेड़, दूरी, सिंचाई, पानी का स्रोत और मिट्टी
• फ़ोन की लोकेशन से कोनों पर चलकर प्लॉट की सीमा दर्ज करें
• बहार शुरू करें और एक बहार की दूसरे से तुलना करें
• आपके प्लॉट का मौसम

रिकॉर्ड
• छिड़काव रिकॉर्ड, खाद व अन्य इनपुट, सिंचाई और तुड़ाई
• मज़दूरी: मज़दूर, मज़दूरी और अग्रिम
• हिसाब: खर्च और बिक्री, खरीदार, दर और भुगतान की स्थिति
• फ़ोटो के साथ निरीक्षण रिकॉर्ड
• फसल बीमा पॉलिसी और क्लेम किट (फ़ोटो व नोट फ़ोन पर ही रहते हैं)
• मिट्टी, पानी और पत्ती जाँच के आँकड़े

काम और मौसम
• फ़ोन पर रिमाइंडर वाले काम
• आपकी बहार तारीखों और कामों से अगले बारह महीनों का मौसम कैलेंडर

जानकारी और मदद
• बाग प्रबंधन के तरीके (बिना रसायन), हर एक के साथ प्रकाशित स्रोत
• मिलते-जुलते लक्षण: जो दिखे उसे प्रयोगशाला या विशेषज्ञ को ठीक से बताने के लिए कार्ड
• सिंचाई तालिका, और प्रयोगशालाओं व विशेषज्ञों की सूची
• सरकारी योजनाएँ और तैयार रखने वाले दस्तावेज़, आधिकारिक पेज की लिंक के साथ

बाज़ार
• Agmarknet (data.gov.in) से मंडी भाव
• बाज़ार और खरीदारों की सूची

[if on] सरकारी संदेश
[if on] • आपके ज़िले के आधिकारिक GR और सूचनाएँ, हमारी टीम की जाँच के बाद ही दिखाई जाती हैं
[if on] • "संदेश जाँचें": आया हुआ फ़ॉरवर्ड संदेश प्रकाशित आधिकारिक सूचनाओं से मिलाकर देखें

इस्तेमाल में आसान
• फ़ील्ड में बोलकर लिखें, और पढ़कर सुनें
• हिसाब CSV और रिपोर्ट PDF के रूप में भेजें

आपका डेटा
[if on] • मोबाइल नंबर या Google से लॉगिन
[if off] • Google खाते से लॉगिन
• कोई विज्ञापन नहीं, कोई विज्ञापन या analytics ट्रैकर नहीं
• हर खाते को सिर्फ़ अपने रिकॉर्ड दिखते हैं; डेटा HTTPS से जाता है
• ऐप में प्रोफ़ाइल से खाता और डेटा कभी भी मिटाएँ
• गोपनीयता नीति: https://bagmitra.aialgodesk.org/privacy

बागमित्र आपके रिकॉर्ड रखता है और सामान्य जानकारी दिखाता है। यह रसायन या मात्रा की सलाह नहीं देता; उसके लिए कृषि अधिकारी, KVK या योग्य विशेषज्ञ से पूछें।
```

---

## Measured lengths (characters; full text with the *[if on]* lines kept / with the *[if off]* lines kept)

| | Title (≤ 30) | Short (≤ 80) | Full (≤ 4000) |
|---|---|---|---|
| en-IN | 30 | 80 | 2238 / 2019 |
| mr-IN | 26 | 74 | 1980 / 1804 |
| hi-IN | 25 | 80 | 2013 / 1824 |

Re-measure after any edit (Python `len()` on the pasted text; Play shows its own counter too).
