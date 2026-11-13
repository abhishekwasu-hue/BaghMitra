# Reassurance audit (owner 2026-11-13)

Owner, on the Home strip "तुमच्या नोंदी फोनवर सुरक्षित आहेत; सर्व्हर तयार झाल्यावर त्या आपोआप
पाठवल्या जातील." (translated): "Why show this foolish message? That records are safe belongs once in
the privacy policy, not shown again and again." Then: "there will be many such messages in other
places too; remove them all." (OPEN_QUESTIONS Q148.)

Rule applied: a screen shows a line only when the grower must act (sign in, review, permission,
error with a retry), when it is a legally required consent shown once, or when it is a plain fact
needed at that moment (a result's source or date, what a dialog's button will do). Lines that only
reassure ("saved on the phone", "safe", "will be sent when the network or server is back", "stays
only on this phone", "not stored") are removed; the privacy page says it once
(`api/src/bagmitra_api/public_pages/privacy.py`, §2 and §3).

Method: every value in `app/lib/l10n/app_mr.arb` searched for फोन / सुरक्षित / जतन / पाठव /
इंटरनेट / नेटवर्क / सर्व्हर / ऑफलाइन / साठव / गुप्त / गोपनीय / कधीही / आपोआप, and each hit traced
to the screen that shows it. Admin-only strings (admin web) and button labels ("जतन करा") are left
out. `app/test/l10n/no_reassurance_test.dart` keeps the removed lines from coming back (mr, en, hi).

Sync behaviour is unchanged: entries are still saved on the phone first and sent by the sync
engine on its own; only the strips and notes are gone. The shared sync strip
(`buildSyncStatusBanner`) now shows only "sign in again" and "entries to check" (plus the
local-only line on test builds without a backend).

Privacy page additions (mr + en): §3 "first on your phone; the app sends your records to the
server on its own whenever it is online"; §2 the scheme document ticks stay on the phone only
(added to the existing claim / lab report line). The other removed facts were already there.

| Key | Marathi text (before) | Where shown | Decision | Reason |
|---|---|---|---|---|
| `offlineBanner` | तुमच्या नोंदी या फोनवर जतन झाल्या आहेत; नेटवर्क आल्यावर त्या पाठवल्या जातील. | Home, Market lots, Lot form (shared sync strip) | Removed | Shown on every screen while offline; sync retries quietly. Privacy page §3 now says it once. |
| `syncServerBanner` | तुमच्या नोंदी फोनवर सुरक्षित आहेत; सर्व्हर तयार झाल्यावर त्या आपोआप पाठवल्या जातील. | Home, Market lots, Lot form (shared sync strip) | Removed | The strip the owner flagged; no action possible. Privacy page §3. |
| `pendingSync` | {count, plural, =1{१ नोंद पाठवायची बाकी} other{{count} नोंदी पाठवायच्या बाकी}} | Home, Market lots, Lot form (shared sync strip) | Removed | Count of entries still waiting; no action possible; they go on their own. |
| `reactionPending` | फोनवर ठेवले; इंटरनेट आल्यावर जाईल. | Reaction bar (articles, Q&A answers) | Removed | Owner named it; the reaction waits and goes quietly. |
| `feedbackQueued` | फोनवर जतन केले; नेट आल्यावर जाईल. | Feedback screen toast (offline send) | Removed | Same "kept on the phone; goes later" line; replaced by a plain thank-you (feedbackThanks). |
| `claimKitLocalOnly` | फोटो व टीप या फोनवरच राहतात. गरज असेल तेव्हा PDF पाठवा. | Crop-loss claim kit, under the checklist | Removed | Storage note under a form; privacy page §2 already says claim photos and notes stay on the phone. |
| `labTestReportLocal` | अहवाल याच फोनवर राहतो. | Lab test form and lab test detail | Removed | Storage note shown twice; privacy page §2 already says lab report files stay on the phone. |
| `billPhotoHint` | दुकानाच्या बिलाचा फोटो या नोंदीसोबत फोनवर राहतो. | Bill photo field (spray and expense forms) | Removed | Storage note under a form; privacy page §2 covers bill photos (and their backup). |
| `feedCheckPrivacy` | हा मजकूर फक्त तपासणीसाठी वापरला जातो; तो फोनवर साठवला जात नाही. | "Check a message" screen, under the text box | Removed | Privacy promise; privacy page §2 already says the pasted text is not stored anywhere. |
| `schemeDocumentsHint` | जे आधीच आहे त्यावर खूण करा. फक्त याच फोनवर राहते. | Scheme detail, documents checklist | Shortened | Kept "tick what you already have" (the instruction); dropped "kept on this phone only" (added to privacy page §2). |
| `billOffline` | बिल वाचण्यासाठी इंटरनेट लागते. फोटो या नोंदीसोबत फोनवर जतन होतो. | Bill photo field, while offline | Shortened | Kept "reading the bill needs internet" (why the button is missing); dropped "the photo is saved on the phone". |
| `localModeBanner` | ऑफलाइन चाचणी मोड: तुमची माहिती या फोनमध्येच राहते | Shared sync strip, test builds without a backend only | Kept | Test builds only (TEST_BUILD is set only by the Test APK workflow; release-apk.yml never sets it). |
| `syncSignedOutBanner` | नोंदी पाठवण्यासाठी पुन्हा लॉगिन करा | Shared sync strip | Kept | Action: sign in again (nothing syncs until then). |
| `syncRejectedBanner` | {count, plural, =1{१ नोंद तपासायची आहे} other{{count} नोंदी तपासायच्या आहेत}} | Shared sync strip | Kept | Action: review the entries the server turned down. |
| `syncRejectedHelp` | प्रत्येक नोंद पुन्हा पाठवा किंवा या यादीतून हटवा; फोनवरील माहिती तशीच राहते. | Turned-down entries sheet | Kept — owner to decide | Action sheet; its tail "the phone data stays as it is" tells what Delete does (only the list entry goes). Remove the tail? |
| `syncFailed` | तुमच्या नोंदी या फोनवर सुरक्षित आहेत. ॲप आपोआप पुन्हा पाठवायचा प्रयत्न करेल. | Home, only when the home data fails to load (error state) | Kept — owner to decide | Rare error state with no retry button; wording is reassurance ("safe on this phone"). Replace with a plain retry line? |
| `profileDeleteFailed` | थोड्या वेळाने पुन्हा प्रयत्न करा: खाते काढण्यासाठी इंटरनेट आणि सर्व्हर लागतो. तुमची सर्व माहिती अजून जशीच्या तशी आहे. | Profile, account delete failed (toast) | Kept — owner to decide | Error + retry; tail "all your data is still as it was" is reassurance but tells the result of a failed delete. |
| `walkthroughRecordsBody` | फवारणी, खर्च, मजुरी आणि विक्रीची नोंद ठेवा आणि हिशोब पहा. नेट बंद असले तरी ॲप चालते; नेटवर्क आल्यावर नोंदी पाठवल्या जातात. | First-run walkthrough (shown once) | Kept — owner to decide | Shown once; "works without internet; entries go when the network comes" is a feature fact. Keep or trim? |
| `mlPrivacy` | व्यापाऱ्यांना फक्त गाव, तालुका व जिल्हा दिसतो; तुमचे नाव, फोन व बागेचे ठिकाण गुप्त राहते. | Market link lot form | Kept — owner to decide | What traders see of the grower (village, taluka, district only); a disclosure at the moment of publishing, and the privacy page has no market-link section yet. |
| `profileSignOutBody` | तुमच्या नोंदी या फोनवरच राहतील. पुन्हा लॉगिन केल्यावर दिसतील. | Sign-out confirm dialog | Kept | Fact needed for the decision (records stay; they show after signing in). |
| `profileConsentDataNote` | तुमच्या नोंदी साठवण्यासाठी आणि सुरक्षित ठेवण्यासाठी ही संमती लागते, म्हणून ती नेहमी चालू राहते. | Profile, consent switch (locked on) | Kept | Consent text: why this consent stays on. |
| `onboardingConsentData` | ॲप चालवण्यासाठी बागमित्रने माझ्या बागेच्या नोंदी साठवल्या तर माझी संमती आहे. | Onboarding consent (once) | Kept | Legally required consent text. |
| `profileDeleteBody` | तुमच्या सर्व नोंदी, फोटो आणि इतिहास सर्व्हरवरून आणि या फोनवरून पुसले जातील आणि तुम्ही लॉगआउट व्हाल. हे कायमचे आहे. खात्रीसाठी {word} लिहा. | Delete account dialog | Kept | Legal / decision fact (what is erased). |
| `accountSwitchBody` | या फोनवर दुसऱ्या खात्याच्या नोंदी आहेत. पुढे गेल्यास त्या या फोनवरून काढल्या जातील (सर्व्हरवर सुरक्षित राहतील) आणि तुमच्या नोंदी डाउनलोड होतील. | Account switch screen | Kept | Fact needed for the decision (records leave this phone, stay on the server). |
| `accountBlockedBody` | {count, plural, =1{आधीच्या खात्याची १ नोंद अजून पाठवायची बाकी आहे.} other{आधीच्या खात्याच्या {count} नोंदी अजून पाठवायच्या बाकी आहेत.}} त्या खात्याने पुन्हा लॉगिन करा आणि इंटरनेट चालू ठेवून ॲप उघडा, म्हणजे त्या पाठवल्या जातील. मग या खात्याने लॉगिन करा. | Account switch screen | Kept | Action: sign in with the old account so its entries go first. |
| `feedPrefsOffline` | ही तुमची शेवटची जतन केलेली सेटिंग आहे. बदल जतन करायला इंटरनेट चालू करा. | Notice preferences, offline | Kept | Action: changes need internet to save. |
| `feedPrefsSaveFailed` | इंटरनेट आल्यावर पुन्हा जतन करा. | Notice preferences, save failed | Kept | Action: save again when online. |
| `feedCheckFailed` | तपासणीसाठी इंटरनेट लागते; इंटरनेट आल्यावर पुन्हा प्रयत्न करा. | "Check a message", offline | Kept | Action: try again when online. |
| `mlPublishOffline` | यासाठी इंटरनेट लागते. मसुदा जतन आहे; इंटरनेट आल्यावर पुन्हा करा. | Market link lot form, publish offline | Kept | Action: publishing needs internet; try again. |
| `photoCheckOffline` | फोटो तपासणीसाठी इंटरनेट लागते. फोटो इथेच ठेवला आहे; इंटरनेट सुरू झाल्यावर 'पुन्हा तपासा' दाबा. | Photo check, offline | Kept | Action: tap "check again" when online. |
| `photoOfflineUnclear` | स्पष्ट ओळखीसाठी या फोटोची पूर्ण तपासणी लागेल. इंटरनेट आल्यावर 'पुन्हा तपासा' दाबा. | Photo check, on-phone result unclear | Kept | Action: full check when online. |
| `photoOfflineNote` | फोनवरचा अंदाज; इंटरनेट आल्यावर पूर्ण तपासणी करता येईल. | Photo check, on-phone result | Kept | Fact about the result shown (an on-phone estimate). |
| `billFailed` | थोड्या वेळाने पुन्हा 'बिलावरून भरा' दाबा; फोटो इथेच आहे. | Bill photo field, read failed | Kept | Action: try "fill from bill" again. |
| `plotAddressMissing` | ठिकाण जतन होईल. गावाचे नाव पाहण्यासाठी नेट सुरू ठेवून 'ठिकाण पुन्हा घ्या' दाबा. | Plot location | Kept | Action: retake the location online to get the village name. |
| `weatherStale` | शेवटचे जतन केलेले दिवस दाखवत आहोत; पुढच्या वेळी हवामान मिळाल्यावर ते अद्ययावत होईल. | Weather card / forecast | Kept | Fact: the days shown are the last saved ones. |
| `weatherNone` | फोन ऑनलाइन असताना हवामान येईल. | Home, weather card / forecast (empty) | Kept | Empty state: when weather will appear. |
| `marketStale` | {reason, select, source_not_configured{बाजारभाव सेवा लवकरच सुरू होईल.} other{शेवटचे जतन केलेले भाव दाखवत आहोत; पुढच्या वेळी भाव मिळाल्यावर ते अद्ययावत होतील.}} | Market prices | Kept | Fact: prices shown are the last saved ones. |
| `marketStaleNoReason` | शेवटची जतन केलेली यादी दाखवत आहोत; पुढच्या वेळी भाव मिळाल्यावर ती अद्ययावत होईल. | Market prices | Kept | Fact: the list shown is the last saved one. |
| `marketEmpty` | फोन ऑनलाइन असताना आणि बाजारभाव सेवा सुरू असताना भाव इथे दिसतील. | Home, market prices (empty) | Kept | Empty state. |
| `marketTrendCollecting` | भाव दररोज साठवला जातो; चार्ट दिवसागणिक भरत जातो. | Price trend sheet | Kept | Fact: why the chart is short. |
| `feedEmpty` | फोन ऑनलाइन असताना संदेश येतील. | Sarkari Sandesh feed (empty) | Kept | Empty state. |
| `knowledgeEmpty` | फोन ऑनलाइन झाल्यावर ज्ञान कार्ड येथे दिसतील. | Knowledge cards (empty) | Kept | Empty state. |
| `askStoredNote` | ही माहिती ॲपमध्ये साठवलेल्या तपासलेल्या स्रोतांवरून आहे. | Ask answer | Kept | Source of the answer (fact at that moment). |
| `feedbackIncluded` | app version व फोनचे मॉडेल सोबत जाते. | Feedback form | Kept | Disclosure at the moment of sending (app version and phone model go along). |
| `settingsPhotoMobileDataHint` | पाहणी व बिलांच्या फोटोंचा बॅकअप वाय-फायवर होतो. मोबाईल डेटाही वापरायचा असेल तर हे चालू करा. | Settings, photo backup on mobile data | Kept | Explains the switch beside it. |
| `deletePlotConfirm` | {name} काढून टाकायची? तुमच्या इतर फोनवरूनही ती जाईल. | Delete plot dialog | Kept | Fact for the decision (it goes from other phones too). |
| `claimKitDeleteConfirm` | ही नुकसान नोंद व तिचे फोटो या फोनवरून हटवायचे? | Delete loss record dialog | Kept | Fact for the decision. |
| `labTestDeleteConfirm` | ही तपासणी नोंद व तिचा अहवाल या फोनवरून काढायचा? | Delete lab test dialog | Kept | Fact for the decision. |
| `mlTermsPublicPhone` | तुमचा फोन नंबर तुमच्या प्रोफाइलवर सर्वांना दिसेल, म्हणजे शेतकरी तुम्हाला थेट फोन करू शकतील. | Market link terms (once) | Kept | Consent text. |
| `mlAcceptConfirmBody` | या व्यापाऱ्याला (व नाव दिलेल्या मध्यस्थाला) तुमचे नाव, फोन व बागेचे ठिकाण दिसेल. इतर ऑफर बंद होतील. पुढील व्यवहार तुम्ही थेट आपसात ठरवा. | Accept offer dialog | Kept | Consent / decision fact (what the trader will see). |
| `mlSafetyNotice` | BagMitra कधीही पैसे, OTP किंवा बँक तपशील मागत नाही. | Market link role home | Kept | Safety warning (never asks for money, OTP or bank details). |
| `billingTerms` | Google Play द्वारे दर महिन्याला आपोआप नूतनीकरण. Google Play मधून कधीही रद्द करा; तुमच्या स्वतःच्या नोंदी नेहमी वाचता व export करता येतात. | Subscription screen | Kept | Required billing terms. |
