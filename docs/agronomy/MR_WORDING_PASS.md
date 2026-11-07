# Marathi / Hindi wording pass (audit M6 + M7)

Native-speaker pass over `app/lib/l10n/app_mr.arb` and `app_hi.arb`. English strings, keys, ICU placeholders and
plural / select structures are unchanged. Admin-only strings were not touched. Binding terms: docs/agronomy/GLOSSARY_mr.md.

Reasons: **calque** = word-for-word English; **positive** = calm, action-first wording (real warnings kept clear);
**glossary** = GLOSSARY_mr.md term or unit; **consistency** = one term per thing across screens; **grammar**; **jargon** =
English / developer words; **word** = Marathi word in Hindi text; **punctuation** = । instead of . in Hindi.

| Lang | Reason | Changed |
|---|---|---|
| hi | consistency | 11 |
| hi | grammar | 1 |
| hi | jargon | 2 |
| hi | positive | 7 |
| hi | punctuation | 14 |
| hi | word | 9 |
| mr | calque | 5 |
| mr | consistency | 18 |
| mr | glossary | 4 |
| mr | grammar | 3 |
| mr | jargon | 5 |
| mr | positive | 7 |

Total: 42 mr, 44 hi strings.

Warning meaning kept as it was: `sprayWarnBannedBody` / `sprayWarnRestrictedBody` (spelling only) and `sprayWarnPhiTitle`;
`feedCheckNoMatch` (tells the grower a forwarded message is not confirmed), `claimPdfMade` (legal note). The
"not a recommendation" sense of `labelInfoBanner` is kept, with the information first. Not in the arb (left for its
owner, audit C1): the demo home stage chip still says काढणी (`app/assets/demo/home_demo.json`).

## Changes

| Lang | Key | Old | New | Reason |
|---|---|---|---|---|
| mr | `soilMoisture` | माती ओली {percent}% | मातीतील ओलावा {percent}% | calque |
| mr | `navHome` | घर | मुख्य पान | calque |
| mr | `seeAll` | सगळी पाहा | सर्व पहा | consistency: सर्व / पहा as on the other screens |
| mr | `homeOpenMarket` | बाजारभाव पाहा | बाजारभाव पहा | consistency: पहा (9 uses) over पाहा (3) |
| mr | `sprayWarnBannedBody` | हा घटक बंदी असलेला आहे ({notification}). तो वापरू नका. जवळच्या KVK किंवा तज्ञांना विचारा. | हा घटक बंदी असलेला आहे ({notification}). तो वापरू नका. जवळच्या KVK किंवा तज्ज्ञांना विचारा. | glossary: तज्ञ → तज्ज्ञ; warning text kept |
| mr | `sprayWarnRestrictedBody` | या पिकासाठी हा घटक प्रतिबंधित आहे ({notification}). लेबल पाहा आणि स्थानिक तज्ञांना विचारा. | या पिकासाठी हा घटक प्रतिबंधित आहे ({notification}). लेबल पहा आणि स्थानिक तज्ज्ञांना विचारा. | glossary: तज्ञ → तज्ज्ञ, पाहा → पहा |
| mr | `baharEmptyBody` | बहार निवडा आणि तुमच्या तारखा लिहा. तज्ञांनी तपासलेले कॅलेंडर तयार झाल्यावर सुचवलेल्या तारखा मिळतील. | बहार निवडा आणि तुमच्या तारखा लिहा. तज्ज्ञांनी तपासलेले कॅलेंडर तयार झाल्यावर सुचवलेल्या तारखा मिळतील. | glossary: तज्ञ → तज्ज्ञ |
| mr | `plotOpenRecords` | बहार, फवारणी आणि हिशेब | बहार, फवारणी आणि हिशोब | consistency: हिशोब, as on the Accounts tab |
| mr | `plotBoundaryNone` | हद्द नोंदवा | सीमा नोंदवा | consistency: सीमा, as on the boundary screen |
| mr | `boundaryDeniedForever` | लोकेशन बंद केलेले आहे. फोनच्या अॅप सेटिंगमध्ये परवानगी द्या. | फोनच्या ॲप सेटिंगमध्ये लोकेशनला परवानगी द्या. | positive: action first; ॲप spelling |
| mr | `settingsPhotoMobileData` | मोबाइल डेटावरही फोटोचा बॅकअप घ्या | मोबाईल डेटावरही फोटोचा बॅकअप घ्या | consistency: मोबाईल, as on the login screen |
| mr | `settingsPhotoMobileDataHint` | पाहणीच्या फोटोंचा बॅकअप वाय-फायवर होतो. मोबाइल डेटाही वापरायचा असेल तर हे चालू करा. | पाहणीच्या फोटोंचा बॅकअप वाय-फायवर होतो. मोबाईल डेटाही वापरायचा असेल तर हे चालू करा. | consistency: मोबाईल, as on the login screen |
| mr | `weatherRain` | {mm} मिमी पाऊस | {mm} मि.मी. पाऊस | glossary: unit मि.मी. |
| mr | `harvestKg` | प्रमाण (किलो) | वजन (किलो) | consistency: वजन, as in the sale form |
| mr | `labourAddDay` | मजूर दिवस जोडा | मजुराचा दिवस जोडा | calque |
| mr | `profileConsentDataNote` | तुमच्या नोंदी साठवण्यासाठी आणि सुरक्षित ठेवण्यासाठी ही संमती लागते. ती इथे बंद करता येत नाही. | तुमच्या नोंदी साठवण्यासाठी आणि सुरक्षित ठेवण्यासाठी ही संमती लागते, म्हणून ती नेहमी चालू राहते. | positive: "stays on" instead of "cannot be turned off" |
| mr | `seedOrchard` | नमुना बाग भरा | नमुना बाग जोडा | grammar: बाग is feminine; जोडा as elsewhere |
| mr | `seedOrchardDone` | नमुना बाग भरला | नमुना बाग जोडली | grammar: बाग is feminine (भरला → जोडली) |
| mr | `tasksOverdue` | उशीर झालेली | राहिलेली | positive: calm wording for the overdue group |
| mr | `taskOverdue` | उशीर | आजच करा | positive: action first (audit M6) |
| mr | `editPlot` | बाग संपादित करा | बागेची माहिती बदला | calque: संपादित is bookish |
| mr | `plotPointCapture` | मी बागेत उभा आहे — ठिकाण घ्या | मी बागेत आहे — ठिकाण घ्या | grammar: उभा is male-only; neutral for every grower |
| mr | `plotPointWhy` | या भागाच्या हवामान व इशाऱ्यांसाठी. फक्त आत्ता एकदाच घेतले जाते. | या बागेच्या हवामान व इशाऱ्यांसाठी. ठिकाण फक्त आत्ता एकदाच घेतले जाते. | consistency: भाग → बाग; clear subject |
| mr | `plotPointDenied` | भागाचे ठिकाण घेण्यासाठी परवानगी द्या. | बागेचे ठिकाण जतन करण्यासाठी लोकेशनला परवानगी द्या. | consistency: भाग → बाग |
| mr | `plotPointLater` | भाग आत्ता जतन करा; ठिकाण नंतर कधीही घेता येईल. | बाग आत्ता जतन करा; ठिकाण नंतर कधीही घेता येईल. | consistency: भाग → बाग |
| mr | `calendarTitle` | हंगाम दिनदर्शिका | हंगामाचे कॅलेंडर | consistency: कॅलेंडर, as in the walkthrough and bahar screens |
| mr | `calendarOpen` | हंगाम दिनदर्शिका | हंगामाचे कॅलेंडर | consistency: कॅलेंडर, as in the walkthrough and bahar screens |
| mr | `labelInfoBanner` | ही माहिती नोंदणीकृत लेबलवर (CIB&RC) छापलेली आहे. ही शिफारस नाही. कोणताही वापर करण्यापूर्वी उत्पादनाचे लेबल वाचा आणि तुमच्या कृषी विज्ञान केंद्र (KVK) किंवा कृषी अधिकाऱ्याकडून खात्री करून घ्या. | ही माहिती नोंदणीकृत लेबलवर (CIB&RC) छापलेली आहे; ती फक्त लेबलवरील माहिती आहे, शिफारस नाही. कोणताही वापर करण्यापूर्वी उत्पादनाचे लेबल वाचा आणि तुमच्या कृषी विज्ञान केंद्राकडून (KVK) किंवा कृषी अधिकाऱ्याकडून खात्री करून घ्या. | positive: information first, "not a recommendation" kept; case ending on केंद्राकडून |
| mr | `plotVariety` | जात (ऐच्छिक) | वाण (ऐच्छिक) | consistency: वाण, as in market prices |
| mr | `marketEmpty` | फोन ऑनलाइन असताना आणि भावांचा स्रोत जोडलेला असताना भाव येतील. | फोन ऑनलाइन असताना आणि बाजारभाव सेवा सुरू असताना भाव इथे दिसतील. | jargon: "price source connected" was developer text |
| mr | `scoutingRemovePhoto` | फोटो काढा | फोटो हटवा | consistency: काढा also means "take" (फोटो काढा); हटवा as in the claim kit |
| mr | `claimKitTitle` | क्लेम किट | नुकसान नोंद किट | jargon: क्लेम (audit M7) |
| mr | `claimKitFromAlert` | नुकसानीचे फोटो · क्लेम किट | नुकसानीचे फोटो · नुकसान नोंद किट | jargon: follows claimKitTitle |
| mr | `insuranceEmpty` | या बागेसाठी घेतलेला पीक विमा नोंदवा, किंवा नुकसान झाल्यावर क्लेम किट उघडा. | या बागेसाठी घेतलेला पीक विमा नोंदवा, किंवा नुकसान झाल्यावर नुकसान नोंद किट उघडा. | jargon: follows claimKitTitle |
| mr | `claimKitNoGps` | GPS अनुपलब्ध | GPS शिवाय | positive: neutral fact instead of "unavailable" |
| mr | `feedCheckPrivacy` | हा मजकूर तुमच्या फोनवर जतन होत नाही. | हा मजकूर फक्त तपासणीसाठी वापरला जातो; तो फोनवर साठवला जात नाही. | positive: purpose first; privacy fact kept |
| mr | `loadingLabel` | लोड होत आहे | माहिती येत आहे | jargon: लोड (audit M7) |
| mr | `accountBlockedBody` | {count, plural, =1{आधीच्या खात्याची १ नोंद अजून पाठवायची बाकी आहे.} other{आधीच्या खात्याच्या {count} नोंदी अजून पाठवायच्या बाकी आहेत.}} त्या खात्याने पुन्हा साइन इन करा आणि इंटरनेट चालू ठेवून ॲप उघडा, म्हणजे त्या पाठवल्या जातील. मग या खात्याने साइन इन करा. | {count, plural, =1{आधीच्या खात्याची १ नोंद अजून पाठवायची बाकी आहे.} other{आधीच्या खात्याच्या {count} नोंदी अजून पाठवायच्या बाकी आहेत.}} त्या खात्याने पुन्हा लॉगिन करा आणि इंटरनेट चालू ठेवून ॲप उघडा, म्हणजे त्या पाठवल्या जातील. मग या खात्याने लॉगिन करा. | consistency: साइन इन → लॉगिन, as on every other screen |
| mr | `labTestNextDueHint` | आठवण कार्य हवे असेल तरच तारीख निवडा. | आठवणीचे काम हवे असेल तरच तारीख निवडा. | calque: आठवण कार्य was a calque of "reminder task" |
| mr | `lookalikesCheckLine` | खात्री हवी? फोटो घ्या, निरीक्षण नोंदीत लिहा आणि निर्णय घेण्याआधी प्रयोगशाळा किंवा तज्ज्ञांकडून तपासून घ्या. | खात्री हवी? फोटो घ्या, पाहणी नोंदीत लिहा आणि निर्णय घेण्याआधी प्रयोगशाळा किंवा तज्ज्ञांकडून तपासून घ्या. | consistency: निरीक्षण नोंद → पाहणी नोंद (the scouting log name) |
| mr | `lookalikesLogThis` | निरीक्षण नोंदीत लिहा | पाहणी नोंदीत लिहा | consistency: पाहणी नोंद is the scouting log name |
| mr | `feedFilterAll` | सगळे | सर्व | consistency: सर्व, as in every other filter |
| hi | `spraysEmpty` | पहले छिड़काव की नोंद यहाँ करें। | पहले छिड़काव का रिकॉर्ड यहाँ दर्ज करें। | word: नोंद is Marathi; रिकॉर्ड as elsewhere in hi |
| hi | `fieldLogTitle` | खेत की नोंदें | खेत के रिकॉर्ड | word: नोंद is Marathi |
| hi | `fieldLogEmpty` | खाद या सिंचाई की पहली नोंद जोड़ें। | खाद या सिंचाई का पहला रिकॉर्ड जोड़ें। | word: नोंद is Marathi |
| hi | `labourEmpty` | मज़दूरी की पहली नोंद जोड़ें। | मज़दूरी का पहला रिकॉर्ड जोड़ें। | word: नोंद is Marathi |
| hi | `harvestEmpty` | तुड़ाई की पहली नोंद जोड़ें। | तुड़ाई का पहला रिकॉर्ड जोड़ें। | word: नोंद is Marathi |
| hi | `compareEmpty` | बहार शुरू करें और नोंदें जोड़ें, फिर सीज़न की तुलना दिखेगी। | बहार शुरू करें और रिकॉर्ड जोड़ें, फिर सीज़न की तुलना दिखेगी। | word: नोंद is Marathi |
| hi | `onboardingConsentData` | ऐप चलाने के लिए बागमित्र मेरे बाग की नोंदें सहेजे, इसकी मेरी सहमति है। | ऐप चलाने के लिए बागमित्र मेरे बाग के रिकॉर्ड सहेजे, इसकी मेरी सहमति है। | word: नोंद is Marathi |
| hi | `directoryEmpty` | नोंदें यहाँ दिखेंगी। | जानकारी यहाँ दिखेगी। | word: नोंद is Marathi |
| hi | `scoutingTitle` | निरीक्षण नोंद | निरीक्षण रिकॉर्ड | word: नोंद is Marathi; matches lookalikes text |
| hi | `walkthroughPlotsTitle` | आपके प्लॉट और बहार कैलेंडर | आपके बाग और बहार कैलेंडर | consistency: प्लॉट → बाग |
| hi | `walkthroughPlotsBody` | अपने प्लॉट जोड़ें। हर बहार के लिए मौसम का कैलेंडर और करने वाले कामों की सूची दिखेगी। | अपने बाग जोड़ें। हर बहार के लिए मौसम का कैलेंडर और करने वाले कामों की सूची दिखेगी। | consistency: प्लॉट → बाग |
| hi | `walkthroughWeatherTitle` | आपके प्लॉट के लिए मौसम सूचना | आपके बाग के लिए मौसम सूचना | consistency: प्लॉट → बाग |
| hi | `walkthroughWeatherBody` | अपने प्लॉट का मौसम देखें। बारिश या धूप पर ध्यान देना हो तब सूचना मिलेगी। | अपने बाग का मौसम देखें। बारिश या धूप पर ध्यान देना हो तब सूचना मिलेगी। | consistency: प्लॉट → बाग |
| hi | `syncEntryName` | {entity, select, farmer_profile{प्रोफ़ाइल} plot{प्लॉट} bahar_cycle{बहार} expense{खर्च} income{बिक्री} spray_record{छिड़काव} input_record{खाद / इनपुट} irrigation_record{सिंचाई} harvest_record{तुड़ाई} labour_record{मज़दूरी} farm_task{काम} scouting_record{निरीक्षण} insurance_policy{बीमा} lab_test{लैब जाँच} other{एंट्री}} | {entity, select, farmer_profile{प्रोफ़ाइल} plot{बाग} bahar_cycle{बहार} expense{खर्च} income{बिक्री} spray_record{छिड़काव} input_record{खाद / इनपुट} irrigation_record{सिंचाई} harvest_record{तुड़ाई} labour_record{मज़दूरी} farm_task{काम} scouting_record{निरीक्षण} insurance_policy{बीमा} lab_test{लैब जाँच} other{एंट्री}} | consistency: plot{प्लॉट} → plot{बाग}; select unchanged |
| hi | `plotPointCapture` | मैं बाग में खड़ा हूँ — जगह लें | मैं बाग में हूँ — जगह लें | grammar: खड़ा is male-only |
| hi | `plotPointWhy` | इस हिस्से के मौसम और चेतावनियों के लिए। केवल अभी एक बार ली जाती है। | इस बाग के मौसम और चेतावनियों के लिए। जगह केवल अभी एक बार ली जाती है। | consistency: हिस्सा → बाग |
| hi | `plotPointDenied` | हिस्से की जगह सेव करने के लिए अनुमति दें। | बाग की जगह सेव करने के लिए अनुमति दें। | consistency: हिस्सा → बाग |
| hi | `plotPointLater` | हिस्सा अभी सेव करें; जगह बाद में कभी भी ले सकते हैं। | बाग अभी सेव करें; जगह बाद में कभी भी ले सकते हैं। | consistency: हिस्सा → बाग |
| hi | `tasksOverdue` | देर हो चुकी | बाकी | positive: calm wording |
| hi | `taskOverdue` | देर | आज ही करें | positive: action first |
| hi | `harvestKg` | मात्रा (किलो) | वज़न (किलो) | consistency: as in the sale form |
| hi | `loadingLabel` | लोड हो रहा है | जानकारी आ रही है | jargon: लोड |
| hi | `claimKitNoGps` | GPS अनुपलब्ध | GPS के बिना | positive: neutral fact |
| hi | `profileConsentDataNote` | आपके रिकॉर्ड सहेजने और सुरक्षित रखने के लिए यह सहमति ज़रूरी है। इसे यहाँ बंद नहीं किया जा सकता। | आपके रिकॉर्ड सहेजने और सुरक्षित रखने के लिए यह सहमति ज़रूरी है, इसलिए यह हमेशा चालू रहती है। | positive: "stays on" |
| hi | `labelInfoBanner` | यह जानकारी पंजीकृत लेबल (CIB&RC) पर छपी है। यह सिफ़ारिश नहीं है। किसी भी उपयोग से पहले उत्पाद का लेबल पढ़ें और अपने कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से पुष्टि करें। | यह जानकारी पंजीकृत लेबल (CIB&RC) पर छपी है; यह केवल लेबल की जानकारी है, सिफ़ारिश नहीं। किसी भी उपयोग से पहले उत्पाद का लेबल पढ़ें और अपने कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से पुष्टि करें। | positive: information first; disclaimer kept |
| hi | `marketEmpty` | फ़ोन ऑनलाइन होने और भाव का स्रोत जुड़ने पर भाव आएँगे। | फ़ोन ऑनलाइन होने और मंडी भाव सेवा चालू होने पर भाव यहाँ दिखेंगे। | jargon: developer text |
| hi | `boundaryDeniedForever` | लोकेशन बंद है। फ़ोन की ऐप सेटिंग में अनुमति दें। | फ़ोन की ऐप सेटिंग में लोकेशन की अनुमति दें। | positive: action first |
| hi | `accountBlockedBody` | {count, plural, =1{पिछले खाते का 1 रिकॉर्ड अभी भेजना बाकी है।} other{पिछले खाते के {count} रिकॉर्ड अभी भेजने बाकी हैं।}} उस खाते से फिर से साइन इन करें और इंटरनेट चालू रखकर ऐप खोलें ताकि वे भेजे जाएँ। फिर इस खाते से साइन इन करें। | {count, plural, =1{पिछले खाते का 1 रिकॉर्ड अभी भेजना बाकी है।} other{पिछले खाते के {count} रिकॉर्ड अभी भेजने बाकी हैं।}} उस खाते से फिर से लॉगिन करें और इंटरनेट चालू रखकर ऐप खोलें ताकि वे भेजे जाएँ। फिर इस खाते से लॉगिन करें। | consistency: साइन इन → लॉगिन |
| hi | `feedCheckPrivacy` | यह पाठ आपके फ़ोन पर सहेजा नहीं जाता. | यह पाठ केवल जाँच के लिए इस्तेमाल होता है; यह फ़ोन पर सहेजा नहीं जाता। | positive: purpose first; । ending |
| hi | `takePhoto` | फोटो लें | फ़ोटो लें | consistency: फ़ोटो spelling used everywhere else in hi |
| hi | `feedReplacedBy` | वापस लिया गया. इसकी जगह अब: {replacement} | वापस लिया गया। इसकी जगह अब: {replacement} | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedFooter` | कुछ भी करने से पहले आधिकारिक GR/पोर्टल देखें. | कुछ भी करने से पहले आधिकारिक GR/पोर्टल देखें। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedEmpty` | फ़ोन ऑनलाइन होने पर संदेश आएँगे. | फ़ोन ऑनलाइन होने पर संदेश आएँगे। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedLinkCopied` | लिंक कॉपी हो गया. ब्राउज़र में खोलें. | लिंक कॉपी हो गया। ब्राउज़र में खोलें। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedNotFound` | यह संदेश सहेजी सूची से हट गया है. | यह संदेश सहेजी सूची से हट गया है। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedDismissed` | आपकी सूची से हटा दिया. | आपकी सूची से हटा दिया। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedPrefsDigestHint` | हफ़्ते में एक बार नई जानकारी का एक संदेश. | हफ़्ते में एक बार नई जानकारी का एक संदेश। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedPrefsSaved` | सेटिंग सहेज ली गई. | सेटिंग सहेज ली गई। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedPrefsSaveFailed` | इंटरनेट आने पर फिर से सहेजें. | इंटरनेट आने पर फिर से सहेजें। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedPrefsOffline` | ये आपकी आख़िरी सहेजी सेटिंग हैं. बदलाव सहेजने के लिए इंटरनेट चालू करें. | ये आपकी आख़िरी सहेजी सेटिंग हैं। बदलाव सहेजने के लिए इंटरनेट चालू करें। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedCheckIntro` | WhatsApp पर GR या योजना का संदेश आया? यहाँ पेस्ट करें, हम आधिकारिक GR ढूँढेंगे. | WhatsApp पर GR या योजना का संदेश आया? यहाँ पेस्ट करें, हम आधिकारिक GR ढूँढेंगे। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedCheckFailed` | जाँच के लिए इंटरनेट चाहिए; इंटरनेट आने पर फिर कोशिश करें. | जाँच के लिए इंटरनेट चाहिए; इंटरनेट आने पर फिर कोशिश करें। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedCheckNoMatch` | मेल खाता आधिकारिक संदेश नहीं मिला. | मेल खाता आधिकारिक संदेश नहीं मिला। | punctuation: । instead of . (the rest of hi uses ।) |
| hi | `feedCheckPortal` | कुछ करने से पहले आधिकारिक पोर्टल जाँचें. | कुछ करने से पहले आधिकारिक पोर्टल जाँचें। | punctuation: । instead of . (the rest of hi uses ।) |

## Market linkage rating tags (draft, for native review)

Source: `api/src/bagmitra_api/market_link/seed_data/rating_tags.json` (spec v1.5 §3A, Q66). Seeded as `draft`; the
admin activates each tag after review. New terms: GLOSSARY_mr.md (व्यापारी, दलाल, व्यवहार, ठरलेल्या अटी, माल, उचल, वजन /
क्रेट मोजणी).

| Question | Positive (mr / hi) | Negative (mr / hi) |
|---|---|---|
| trader_on_date | ठरलेल्या तारखेला आले / तय तारीख पर आए | उशिरा आले / देर से आए |
| trader_weighing_correct | वजन / क्रेट मोजणी बरोबर / वज़न / क्रेट गिनती सही | वजन / क्रेट मोजणीत फरक / वज़न / क्रेट गिनती में फ़र्क |
| trader_paid_as_agreed | उचल व बाकी पैसे ठरल्याप्रमाणे / अग्रिम और बाकी भुगतान तय अनुसार | पैसे उशिरा / भुगतान में देरी |
| trader_kept_conditions | ठरलेल्या अटी पाळल्या / तय शर्तें निभाईं | ठरलेल्या अटी पाळल्या नाहीत / तय शर्तें नहीं निभाईं |
| broker_honest | व्यवहार प्रामाणिकपणे सांगितला / सौदा ईमानदारी से बताया | व्यवहाराची चुकीची माहिती दिली / सौदे की गलत जानकारी दी |
| broker_trader_kept_deal | आणलेल्या व्यापाऱ्याने व्यवहार पाळला / लाए गए व्यापारी ने सौदा निभाया | आणलेल्या व्यापाऱ्याने व्यवहार मोडला / लाए गए व्यापारी ने सौदा तोड़ा |
| grower_produce_matched | माल फोटो व वर्णनाप्रमाणे / माल फ़ोटो और विवरण जैसा | माल फोटोपेक्षा वेगळा / माल फ़ोटो से अलग |
| grower_ready_on_date | ठरलेल्या तारखेला माल तयार / तय तारीख पर माल तैयार | ठरलेल्या तारखेला माल तयार नव्हता / तय तारीख पर माल तैयार नहीं था |

## Market linkage L1 role entry and acceptance (draft, for native review)

Source: `app/lib/l10n/app_mr.arb` / `app_hi.arb` keys `ml*` (spec v1.5 §2.1, §4C, §5). The disclaimer lines follow the
owner's own words; "तुमच्या व्यवहारात या ॲपचा कोणताही लाभ किंवा नुकसान नाही" and "व्यवहारानंतर काय नोंदवायचे ते तुमची
इच्छा" are verbatim. The negatives there (and in the fixed notice "BagMitra कधीही पैसे, OTP किंवा बँक तपशील मागत नाही")
are the legal point and are allow-listed in `positive_wording_test.dart`.

| Key | mr | hi | To check |
|---|---|---|---|
| `mlRoleBroker` | मध्यस्थ (दलाल) | मध्यस्थ (दलाल) | never अडत्या |
| `mlRoleProviderKinds` | वजनकाटा, वाहतूक, मजूर, क्रेट | धर्मकांटा, परिवहन, मज़दूर, क्रेट | hi word for weighbridge |
| `mlTermsNotParty` | BagMitra खरेदीदार, विक्रेता, कमिशन एजंट किंवा वाहतूकदार नाही. | … कमीशन एजेंट या ट्रांसपोर्टर नहीं है। | "कमिशन एजंट" vs a Marathi term other than अडत्या |
| `mlTermsAdult` | मी १८ वर्षांपेक्षा मोठा आहे | मेरी उम्र 18 वर्ष से अधिक है | owner's text uses Devanagari digits (the rest of the arb uses 0-9); gender-neutral form? |
| `mlTermsAgree` | मी वाचले व मान्य करतो | मैंने पढ़ा और मैं सहमत हूँ | gender-neutral form? |
| `mlTermsGpsOnce` | नोंदणीच्या वेळी फसवणूक टाळण्यासाठी तुमचे ठिकाण (GPS) एकदाच घेतले जाईल. | … | — |
| `mlGrievanceTimes` | तक्रारीची पोच 24 तासांत आणि निवारण 15 दिवसांत. | … | — |
## Market linkage admin web (L0b, draft, for native review)
Keys `adminMl*` in `app/lib/l10n/app_mr.arb` / `app_hi.arb`: तपासणी रांग, सेवा देणारे, दिलेली माहिती, कागदपत्रे,
प्रतीक्षेत / तपासले / नाकारले, कारण देऊन नाकारा, रेटिंग टॅग (मसुदा / चालू / बंद), APMC परवाना क्र., प्रमाणपत्र वैध तारीख,
वाहन क्रमांक, रेफ्रिजरेटेड वाहन, वाहतूकदार नोंदणी क्र., वजनकाटा, वाहतूकदार, मजूर टोळी, क्रेट पुरवठादार. Hindi: तहसील for
taluka, धर्मकांटा for weighbridge.
## Market linkage report, block and appeal (L6, draft, for native review)
Keys `ml*` and `adminMlReports` ... `adminMlAppealReason` in `app/lib/l10n/app_mr.arb` / `app_hi.arb`: बागमित्रकडे तक्रार,
कारण निवडा, खोटी ओळख, खोटा माल किंवा दुसऱ्या बागेचे फोटो, बागमित्र असल्याचे भासवते, खोटे रेटिंग, अपमानास्पद वागणूक,
एकाच व्यक्तीची दोन खाती, माझ्या खात्यावरील कारवाई, तक्रार अधिकारी, अपील (एकदाच), निर्णय कायम, पोच द्या, फेटाळा, ब्लॉक करा.
"व्यवहार" is used for the deal (never "सौदा"); the broker stays "मध्यस्थ (दलाल)".

## Market linkage lot screens (L3, draft, for native review)

Strings `ml*` in `app/lib/l10n/app_{mr,hi,en}.arb`. Brokers are "मध्यस्थ (दलाल)" (owner, spec v1.5 §2.1); never अडत्या.

| Key | mr | hi |
|---|---|---|
| mlOpen | माल विक्रीसाठी दाखवा | माल बिक्री के लिए दिखाएँ |
| mlMyLotsTitle / mlLotFormTitle | माझा विक्रीचा माल / विक्रीचा माल | मेरा बिक्री का माल / बिक्री का माल |
| mlDisclaimerShort (decision k) | बागमित्र खरेदीदार, विक्रेता, मध्यस्थ (दलाल) किंवा वाहतूकदार नाही; पैसे ठेवत नाही; पैशांची किंवा दर्जाची हमी देत नाही. | बागमित्र ख़रीदार, विक्रेता, मध्यस्थ (दलाल) या ट्रांसपोर्टर नहीं है; पैसा नहीं रखता; भुगतान या गुणवत्ता की गारंटी नहीं देता। |
| mlQuantity / mlQuality / mlQualityLine | अंदाजे माल (टन) / आकार व दर्जा / थोडक्यात माहिती (ऐच्छिक) | अनुमानित माल (टन) / आकार और गुणवत्ता / छोटी जानकारी (वैकल्पिक) |
| mlHarvestWindow / mlWindowPick | तोडणीचा काळ / तारखा निवडा | तुड़ाई का समय / तारीखें चुनें |
| mlBasis + chips | विक्रीची पद्धत: प्रति टन / प्रति क्रेट / संपूर्ण बाग | बिक्री का तरीका: प्रति टन / प्रति क्रेट / पूरा बाग |
| mlAskingRate | अपेक्षित दर ₹ (ऐच्छिक) | अपेक्षित दर ₹ (वैकल्पिक) |
| mlPhotosHint / mlAddPhoto | ॲपच्या कॅमेऱ्याने {min} ते {max} फोटो / फोटो काढा | ऐप के कैमरे से {min} से {max} फ़ोटो / फ़ोटो लें |
| mlPhotoNoGps | GPS चालू करून पुन्हा फोटो काढा: प्रत्येक फोटोला ठिकाण लागते. | GPS चालू करके फिर से फ़ोटो लें: हर फ़ोटो के साथ जगह चाहिए। |
| mlNoContacts | येथे फक्त मालाबद्दल लिहा; फोन नंबर व लिंक ऑफर स्वीकारल्यानंतर मिळतात. | यहाँ सिर्फ़ माल के बारे में लिखें; फ़ोन नंबर और लिंक ऑफ़र स्वीकार करने के बाद मिलते हैं। |
| mlPrivacy | व्यापाऱ्यांना फक्त गाव, तालुका व जिल्हा दिसतो; तुमचे नाव, फोन व बागेचे ठिकाण गुप्त राहते. | व्यापारियों को सिर्फ़ गाँव, तहसील और ज़िला दिखता है; आपका नाम, फ़ोन और बाग की जगह गुप्त रहती है। |
| mlPublish / mlSaveDraft / mlClose | व्यापाऱ्यांना दाखवा / मसुदा जतन करा / दाखवणे बंद करा | व्यापारियों को दिखाएँ / मसौदा सहेजें / दिखाना बंद करें |
| mlStatus* | मसुदा / व्यापाऱ्यांना दिसतो / तपासणी बाकी / बंद | मसौदा / व्यापारियों को दिखता है / जाँच बाकी / बंद |
| mlPublishOrchardCheck | माल नोंदवला; फोटो नोंदवलेल्या बागेच्या हद्दीबाहेर काढले आहेत, म्हणून तपासणीनंतर व्यापाऱ्यांना दिसेल. | माल दर्ज हुआ; फ़ोटो नक्शे वाले बाग के बाहर ली गईं, इसलिए जाँच के बाद व्यापारियों को दिखेगा। |
| mlLotsEmpty | फोटोसह तुमचा माल येथे दाखवा; तपासलेले व्यापारी व मध्यस्थ (दलाल) तो पाहतात. | फ़ोटो के साथ अपना माल यहाँ दिखाएँ; जाँचे गए व्यापारी और मध्यस्थ (दलाल) उसे देखते हैं। |

### Market linkage L2 (registration, public profiles, service directory) — for native review

| Key | Marathi | Note |
|---|---|---|
| mlFixWhy / mlFixOnce | नोंदणी पूर्ण करण्यासाठी फोन तुमचे सध्याचे स्थान एकदा घेतो… | One GPS fix at registration (addendum 3). |
| mlBadgeChecked / mlBadgeRegisteredFrom / mlBadgePlacePhoto | BagMitra ने {date} रोजी तपासले; {place} येथून {date} रोजी नोंदणी; BagMitra प्रतिनिधीने {date} रोजी ठिकाणाचा फोटो घेतला | Never हमी / खात्रीशीर. |
| mlKindLabourGang / mlKindCrateSupplier / mlFieldRefrigerated | मजूर टोळी; क्रेट पुरवठादार; शीत वाहन | Check the village words. |
| mlQTraderPaid | ठरल्याप्रमाणे उचल व बाकी पैसे दिले | Glossary: उचल / बाकी पैसे. |

## Market linkage export information and export record (L8, draft, for native review)

Keys `exportInfo*`, `exportSection*`, `exportLinksTitle`, `exportRecord*`, `exportLabel*` in
`app/lib/l10n/app_mr.arb`, and the fact lines in `app/assets/config/export_info.json` (mr / hi).
New terms to check: निर्यात नोंद (export record), निर्यातदार (exporter), हॉर्टिनेट (HortiNet),
पॅकहाउस (packhouse), अवशेष चाचणी (residue test), फायटोसॅनिटरी प्रमाणपत्र (phytosanitary certificate),
PHI संपते (PHI ends), लेबल तपासा (check the label), "माहितीसाठी नोंद, प्रमाणपत्र नाही" (footer).
A deal is व्यवहार in Marathi (glossary), never सौदा.

## Market linkage interests and introduction (L4, draft, for native review)

Strings `ml*` in `app/lib/l10n/app_{mr,hi,en}.arb`; व्यवहार only (never सौदा; Hindi लेन-देन); broker "मध्यस्थ (दलाल)".

| Key | mr | hi |
|---|---|---|
| mlBrowseTitle / mlMyOffersTitle / mlOffersTitle | विक्रीसाठी माल / माझ्या ऑफर / तुमच्या मालावरील ऑफर | बिक्री के लिए माल / मेरे ऑफ़र / आपके माल पर ऑफ़र |
| mlMakeOffer / mlOfferSend | ऑफर द्या / ऑफर पाठवा | ऑफ़र दें / ऑफ़र भेजें |
| mlOfferHarvestDate / mlOfferThroughBroker | प्रस्तावित तोडणी तारीख / मध्यस्थ (दलाल) मार्फत | प्रस्तावित तुड़ाई तारीख / मध्यस्थ (दलाल) के ज़रिए |
| mlOfferOnlyThese | शेतकऱ्याला फक्त दर, माल व तारीख जाते; बाकी सर्व समोरासमोर ठरवा. | किसान को सिर्फ़ दर, माल और तारीख जाती है; बाकी सब आमने-सामने तय करें। |
| mlOfferOpen / mlOfferAccepted / mlOfferClosed | शेतकऱ्याच्या निर्णयाची वाट / स्वीकारली / बंद: शेतकऱ्याने दुसरी ऑफर निवडली किंवा माल यादीतून काढला. | किसान के फ़ैसले का इंतज़ार / स्वीकार हुआ / बंद: किसान ने दूसरा ऑफ़र चुना या माल सूची से हटाया। |
| mlAcceptConfirmBody | या व्यापाऱ्याला (व नाव दिलेल्या मध्यस्थाला) तुमचे नाव, फोन व बागेचे ठिकाण दिसेल. इतर ऑफर बंद होतील. पुढील व्यवहार तुम्ही थेट आपसात ठरवा. | … आगे का लेन-देन आप सीधे आपस में तय करें। |
| mlIntroTitle / mlIntroOpenMap | संपर्क / बाग नकाशावर उघडा | संपर्क / बाग नक्शे पर खोलें |
| mlIntroOffApp | आता वजन, क्रेट, वाहतूक व पैसे हा व्यवहार तुम्ही आपसात ठरवता. | अब तौल, क्रेट, ढुलाई और पैसे का लेन-देन आप आपस में तय करते हैं। |
| Pushes (API `market_link/notify.py`) | बागमित्र: नवी ऑफर / ऑफर स्वीकारली / माल बंद | बागमित्र: नया ऑफ़र / ऑफ़र स्वीकार हुआ / माल बंद |
