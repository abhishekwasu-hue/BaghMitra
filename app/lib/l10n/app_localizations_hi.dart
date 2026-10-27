// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'बागमित्र';

  @override
  String get greetingHello => 'नमस्ते';

  @override
  String greetingName(String name) {
    return '$name जी';
  }

  @override
  String temperature(int degrees) {
    final intl.NumberFormat degreesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String degreesString = degreesNumberFormat.format(degrees);

    return '$degreesString°';
  }

  @override
  String maxTemperature(int degrees) {
    final intl.NumberFormat degreesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String degreesString = degreesNumberFormat.format(degrees);

    return 'अधिकतम $degreesString°';
  }

  @override
  String soilMoisture(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'मिट्टी की नमी $percentString%';
  }

  @override
  String get stageDays => 'दिन';

  @override
  String nextStage(String stage, int days, String month) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'अगला चरण: $stage · लगभग $daysString दिनों में · तुड़ाई $month';
  }

  @override
  String get todaysTasks => 'आज के काम';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String marketTitle(String market) {
    return '$market मंडी';
  }

  @override
  String get sevenDayTrend => '7 दिन का रुझान';

  @override
  String get perQuintal => 'प्रति क्विंटल';

  @override
  String get vsLastWeek => 'पिछले सप्ताह से';

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get navHome => 'होम';

  @override
  String get navOrchard => 'बाग';

  @override
  String get navAccounts => 'हिसाब';

  @override
  String get navAsk => 'पूछें';

  @override
  String get taskDone => 'पूरा';

  @override
  String get markTaskDone => 'काम पूरा हुआ';

  @override
  String get offlineBanner =>
      'नेटवर्क नहीं है। आपकी एंट्री सहेजी गई है और बाद में भेजी जाएगी।';

  @override
  String pendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बदलाव भेजने बाकी',
      one: '1 बदलाव भेजना बाकी',
    );
    return '$_temp0';
  }

  @override
  String get syncFailed => 'भेजना नहीं हो पाया। अपने आप फिर कोशिश होगी।';

  @override
  String get loginTitle => 'अपने मोबाइल नंबर से शुरू करें';

  @override
  String get loginPhoneLabel => 'मोबाइल नंबर';

  @override
  String get loginSendOtp => 'OTP भेजें';

  @override
  String get loginOr => 'या';

  @override
  String get loginGoogle => 'Google से लॉगिन करें';

  @override
  String get loginGoogleFailed =>
      'Google लॉगिन नहीं खुल सका। इंटरनेट जाँचकर फिर से कोशिश करें।';

  @override
  String loginOtpTitle(String phone) {
    return '$phone पर आया OTP डालें';
  }

  @override
  String get loginOtpLabel => '6 अंकों का OTP';

  @override
  String get loginVerify => 'जाँचें';

  @override
  String get loginInvalidPhone => '10 अंकों का सही मोबाइल नंबर डालें';

  @override
  String get loginInvalidOtp => 'OTP गलत है या समय समाप्त हो गया';

  @override
  String get loginDemoNotice => 'डेमो मोड: कोई भी 6 अंक चलेंगे';

  @override
  String get voiceInput => 'बोलें';

  @override
  String get galleryTitle => 'कंपोनेंट गैलरी';

  @override
  String adminTitle(String product) {
    return '$product एडमिन';
  }

  @override
  String get adminCropTemplates => 'फसल चरण साँचे';

  @override
  String get adminRiskRules => 'जोखिम नियम';

  @override
  String get adminPrompts => 'AI प्रॉम्प्ट साँचे';

  @override
  String get adminTranslations => 'अनुवाद';

  @override
  String get adminAiUsage => 'AI उपयोग';

  @override
  String adminComingSoon(int milestone) {
    return 'संपादन माइलस्टोन $milestone में आएगा।';
  }

  @override
  String get demoDataNotice => 'नमूना जानकारी';

  @override
  String get myOrchard => 'मेरा बाग';

  @override
  String get addPlot => 'बाग जोड़ें';

  @override
  String get plotsEmptyTitle => 'अभी कोई बाग नहीं जोड़ा';

  @override
  String get plotsEmptyBody =>
      'बहार कैलेंडर और रोज़ के काम पाने के लिए पहला बाग जोड़ें।';

  @override
  String get plotName => 'बाग का नाम';

  @override
  String get plotNameHint => 'जैसे बाग 1';

  @override
  String get plotCrop => 'फसल';

  @override
  String get plotVariety => 'किस्म (वैकल्पिक)';

  @override
  String get plotAreaAcres => 'क्षेत्रफल (एकड़)';

  @override
  String get plotTreeCount => 'पेड़ों की संख्या (वैकल्पिक)';

  @override
  String get plotPlantingYear => 'रोपण वर्ष (वैकल्पिक)';

  @override
  String get save => 'सहेजें';

  @override
  String get fieldRequired => 'ज़रूरी';

  @override
  String get invalidNumber => 'सही संख्या डालें';

  @override
  String plotAcres(String area) {
    return '$area एकड़';
  }

  @override
  String plotTrees(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString पेड़';
  }

  @override
  String get plotSaved => 'सहेजा गया। नेटवर्क आने पर भेजा जाएगा।';

  @override
  String get deletePlot => 'बाग हटाएँ';

  @override
  String deletePlotConfirm(String name) {
    return '$name हटाएँ? यह आपके दूसरे फ़ोन से भी हट जाएगा।';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get startBahar => 'बहार शुरू करें';

  @override
  String get baharEmptyTitle => 'अभी कोई बहार तय नहीं';

  @override
  String get baharEmptyBody =>
      'बहार चुनें और अपनी तारीखें लिखें। विशेषज्ञ द्वारा जाँचा गया कैलेंडर तैयार होने पर सुझाई गई तारीखें मिलेंगी।';

  @override
  String get baharWhich => 'कौन सा बहार?';

  @override
  String get baharSeason => 'मौसम';

  @override
  String get baharDates => 'आपकी तारीखें (वैकल्पिक)';

  @override
  String get baharPickDate => 'तारीख चुनें';

  @override
  String get baharStatusPlanned => 'तय';

  @override
  String get baharStatusActive => 'चालू';

  @override
  String get baharStatusCompleted => 'पूरा';

  @override
  String get baharStatusAbandoned => 'रोका गया';

  @override
  String get adminCards => 'जानकारी कार्ड';

  @override
  String get adminImports => 'आयात';

  @override
  String get adminAlerts => 'सूचनाएँ';

  @override
  String get adminSources => 'स्रोत';

  @override
  String get adminPublish => 'प्रकाशित करें';

  @override
  String get adminApprove => 'मंज़ूर करें';

  @override
  String get adminChemical => 'रसायन';

  @override
  String get adminImport => 'आयात करें';

  @override
  String get adminImportSource => 'स्रोत की';

  @override
  String get adminImportCsv => 'CSV (हाथ से जाँची गई)';

  @override
  String get adminImportClaims => 'लेबल क्लेम';

  @override
  String get adminImportRestrictions => 'प्रतिबंध और रोक';

  @override
  String adminImportResult(
    int added,
    int changed,
    int removed,
    int unchanged,
    int pulled,
  ) {
    return 'नए $added · बदले $changed · हटाए $removed · वैसे ही $unchanged · वापस लिए कार्ड $pulled';
  }

  @override
  String get adminResolve => 'निपटाएँ';

  @override
  String get adminNoAlerts => 'कोई खुली सूचना नहीं';

  @override
  String get adminNoCards => 'अभी कोई कार्ड नहीं';

  @override
  String get adminSignInRequired =>
      'इस भाग के लिए जानकारी-कोश एडमिन खाते से साइन इन करें।';

  @override
  String get adminDone => 'हो गया';

  @override
  String get adminSignIn => 'साइन इन करें';

  @override
  String get adminEmail => 'ईमेल';

  @override
  String get adminPassword => 'पासवर्ड';

  @override
  String get adminSignInFailed => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get adminSignOut => 'साइन आउट';

  @override
  String get adminNotConfigured =>
      'एडमिन साइन-इन के लिए SUPABASE_URL और SUPABASE_ANON_KEY चाहिए।';

  @override
  String get accountsTitle => 'हिसाब';

  @override
  String get addExpense => 'खर्च जोड़ें';

  @override
  String get addSale => 'बिक्री दर्ज करें';

  @override
  String get expenseCategory => 'किस लिए खर्च?';

  @override
  String get amountRupees => 'रकम (₹)';

  @override
  String get noteOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get accountsExpenses => 'खर्च';

  @override
  String get accountsIncome => 'आमदनी';

  @override
  String get accountsProfit => 'मुनाफ़ा';

  @override
  String get accountsDues => 'व्यापारियों पर बाकी';

  @override
  String get costPerAcre => 'प्रति एकड़ खर्च';

  @override
  String get costPerTree => 'प्रति पेड़ खर्च';

  @override
  String get costPerTonne => 'प्रति टन खर्च';

  @override
  String get allBahars => 'सभी';

  @override
  String get saleBuyer => 'व्यापारी';

  @override
  String get saleKg => 'वज़न (किलो)';

  @override
  String get saleRate => 'दर (₹ प्रति क्विंटल)';

  @override
  String get saleDeductions => 'कटौती (₹, वैकल्पिक)';

  @override
  String get salePaid => 'अब तक मिले (₹)';

  @override
  String get accountsEmpty => 'अभी कोई प्रविष्टि नहीं। खर्च या बिक्री जोड़ें।';

  @override
  String saleBy(String buyer, String kg) {
    return '$buyer · $kg किलो';
  }

  @override
  String get sprayLogTitle => 'छिड़काव रिकॉर्ड';

  @override
  String get addSpray => 'छिड़काव दर्ज करें';

  @override
  String get spraysEmpty => 'अभी कोई छिड़काव दर्ज नहीं।';

  @override
  String get sprayProduct => 'दवा का नाम';

  @override
  String get sprayActive => 'सक्रिय तत्व (लेबल पर)';

  @override
  String get sprayDose => 'मात्रा (वैकल्पिक)';

  @override
  String get sprayWater => 'पानी (लीटर, वैकल्पिक)';

  @override
  String get sprayArea => 'छिड़का क्षेत्र (एकड़, वैकल्पिक)';

  @override
  String get sprayCost => 'खर्च (₹, वैकल्पिक)';

  @override
  String get sprayOperator => 'छिड़काव करने वाला (वैकल्पिक)';

  @override
  String get sprayPhi => 'कटाई से पहले के दिन, PHI (वैकल्पिक)';

  @override
  String get sprayTarget => 'किस कीट/रोग के लिए (वैकल्पिक)';

  @override
  String get sprayDate => 'तारीख';

  @override
  String get sprayWhichBahar => 'कौन सा बहार? (कटाई की तारीख जाँचने के लिए)';

  @override
  String get sprayWarnBannedTitle => 'प्रतिबंधित रसायन';

  @override
  String sprayWarnBannedBody(String notification) {
    return 'यह तत्व प्रतिबंधित है ($notification)। इसका उपयोग न करें। अपने KVK या विशेषज्ञ से पूछें।';
  }

  @override
  String get sprayWarnRestrictedTitle => 'इस फसल के लिए रोक';

  @override
  String sprayWarnRestrictedBody(String notification) {
    return 'इस फसल के लिए यह तत्व प्रतिबंधित है ($notification)। लेबल देखें और स्थानीय विशेषज्ञ से पूछें।';
  }

  @override
  String get sprayWarnPhiTitle => 'कटाई बहुत जल्दी';

  @override
  String sprayWarnPhiBody(String date) {
    return 'प्रतीक्षा अवधि खत्म होने से पहले कटाई तय है। $date से कटाई सुरक्षित है।';
  }

  @override
  String get fieldLogTitle => 'खेत की नोंदें';

  @override
  String get addInput => 'खाद जोड़ें';

  @override
  String get logIrrigation => 'सिंचाई दर्ज करें';

  @override
  String get inputKind => 'क्या डाला?';

  @override
  String get inputProduct => 'उत्पाद का नाम';

  @override
  String get inputQuantity => 'मात्रा (वैकल्पिक)';

  @override
  String get inputUnit => 'इकाई';

  @override
  String get inputCost => 'खर्च (₹, वैकल्पिक)';

  @override
  String get irrigationTitle => 'सिंचाई';

  @override
  String get irrigationHours => 'घंटे (वैकल्पिक)';

  @override
  String get irrigationLitres => 'पानी लीटर में (वैकल्पिक)';

  @override
  String get fieldLogEmpty =>
      'अभी कोई नोंद नहीं। खाद जोड़ें या सिंचाई दर्ज करें।';

  @override
  String inputLine(String quantity, String unit) {
    return '$quantity $unit';
  }

  @override
  String irrigationHoursLine(String hours) {
    return '$hours घंटे';
  }

  @override
  String get labourTitle => 'मज़दूरी';

  @override
  String get labourAddDay => 'मज़दूर का दिन जोड़ें';

  @override
  String get labourWorker => 'मज़दूर का नाम';

  @override
  String get labourTask => 'किया गया काम';

  @override
  String get labourWage => 'मज़दूरी (₹)';

  @override
  String get labourAdvance => 'अग्रिम दिया (₹, वैकल्पिक)';

  @override
  String get labourPaidNow => 'आज पूरा दिया';

  @override
  String get labourSettled => 'हिसाब हो गया';

  @override
  String get labourMarkPaid => 'पूरा दिया';

  @override
  String get labourEmpty => 'अभी मज़दूरी की कोई नोंद नहीं। एक जोड़ें।';

  @override
  String get labourTotalDue => 'मज़दूरों को देना';

  @override
  String labourDue(String amount) {
    return 'बाकी $amount';
  }

  @override
  String get harvestTitle => 'तुड़ाई';

  @override
  String get harvestAdd => 'तुड़ाई जोड़ें';

  @override
  String get harvestKg => 'मात्रा (किलो)';

  @override
  String get harvestGrade => 'ग्रेड (वैकल्पिक)';

  @override
  String get harvestSize => 'आकार (वैकल्पिक)';

  @override
  String get harvestEmpty => 'अभी तुड़ाई दर्ज नहीं। एक नोंद जोड़ें।';

  @override
  String harvestTotal(String kg) {
    return 'कुल $kg किलो';
  }

  @override
  String get moreMenu => 'और';

  @override
  String harvestKgValue(String kg) {
    return '$kg किलो';
  }

  @override
  String get compareTitle => 'सीज़न की तुलना';

  @override
  String get compareEmpty =>
      'बहार शुरू करें और नोंदें जोड़ें, फिर सीज़न की तुलना दिखेगी।';

  @override
  String compareVs(String bahar, String change) {
    return '$bahar की तुलना में: $change';
  }

  @override
  String compareMore(String amount) {
    return '$amount ज़्यादा';
  }

  @override
  String compareLess(String amount) {
    return '$amount कम';
  }

  @override
  String get compareSame => 'कोई बदलाव नहीं';

  @override
  String get exportShare => 'स्प्रेडशीट शेयर करें';

  @override
  String get exportDate => 'तारीख';

  @override
  String get exportType => 'प्रकार';

  @override
  String get exportDetails => 'विवरण';

  @override
  String get exportTypeExpense => 'खर्च';

  @override
  String get exportTypeSale => 'बिक्री';

  @override
  String get exportTypeSpray => 'छिड़काव';

  @override
  String get exportTypeInput => 'खाद / सामग्री';

  @override
  String get exportTypeLabour => 'मज़दूरी';

  @override
  String get exportKg => 'किलो';

  @override
  String get exportSharePdf => 'PDF शेयर करें';

  @override
  String get onboardingWelcome => 'बागमित्र में आपका स्वागत है';

  @override
  String get onboardingLanguage => 'अपनी भाषा चुनें';

  @override
  String get onboardingName => 'आपका नाम (वैकल्पिक)';

  @override
  String get onboardingVillage => 'गाँव (वैकल्पिक)';

  @override
  String get onboardingTaluka => 'तहसील (वैकल्पिक)';

  @override
  String get onboardingDistrict => 'ज़िला (वैकल्पिक)';

  @override
  String get onboardingConsentData =>
      'ऐप चलाने के लिए बागमित्र मेरे बाग की नोंदें सहेजे, इसकी मेरी सहमति है।';

  @override
  String get onboardingConsentWhatsapp =>
      'मुझे WhatsApp पर याद दिलाएँ (वैकल्पिक)।';

  @override
  String get onboardingContinue => 'आगे बढ़ें';

  @override
  String get boundaryWalk => 'चलकर सीमा दर्ज करें';

  @override
  String get boundaryTitle => 'बाग की सीमा दर्ज करें';

  @override
  String get boundaryHelp =>
      'बाग के एक कोने पर खड़े हों और “यह कोना जोड़ें” दबाएँ। हर कोने पर जाकर यही करें। कम से कम 3 कोने चाहिए।';

  @override
  String get boundaryAdd => 'यह कोना जोड़ें';

  @override
  String get boundaryUndo => 'आख़िरी कोना हटाएँ';

  @override
  String get boundaryDone => 'हो गया';

  @override
  String boundaryCorners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कोने',
      one: '1 कोना',
    );
    return '$_temp0';
  }

  @override
  String boundaryArea(String acres) {
    return 'क्षेत्रफल लगभग $acres एकड़';
  }

  @override
  String boundaryAccuracy(String metres) {
    return '±$metres मी';
  }

  @override
  String get boundaryServiceOff => 'फ़ोन में लोकेशन (GPS) चालू करें।';

  @override
  String get boundaryDenied => 'सीमा दर्ज करने के लिए लोकेशन की अनुमति दें।';

  @override
  String get boundaryDeniedForever =>
      'लोकेशन बंद है। फ़ोन की ऐप सेटिंग में अनुमति दें।';

  @override
  String get boundaryFailed =>
      'आपकी जगह नहीं मिली। खुली जगह में फिर कोशिश करें।';

  @override
  String boundaryMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कोने',
      one: '1 कोना',
    );
    return 'सीमा दर्ज हुई: $_temp0';
  }

  @override
  String get loginTryWithout => 'बिना खाते के आज़माएँ';

  @override
  String get localModeBanner =>
      'ऑफ़लाइन टेस्ट मोड: आपका डेटा इसी फ़ोन में रहता है';

  @override
  String testBuildBadge(String sha) {
    return 'टेस्ट बिल्ड $sha';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get sendLogs => 'लॉग भेजें';

  @override
  String get walkthroughSkip => 'छोड़ें';

  @override
  String get walkthroughNext => 'आगे';

  @override
  String get walkthroughStart => 'शुरू करें';

  @override
  String get walkthroughPlotsTitle => 'आपके प्लॉट और बहार कैलेंडर';

  @override
  String get walkthroughPlotsBody =>
      'अपने प्लॉट जोड़ें। हर बहार के लिए मौसम का कैलेंडर और करने वाले कामों की सूची दिखेगी।';

  @override
  String get walkthroughWeatherTitle => 'आपके प्लॉट के लिए मौसम सूचना';

  @override
  String get walkthroughWeatherBody =>
      'अपने प्लॉट का मौसम देखें। बारिश, धूप या ठंड पर ध्यान देना हो तब सूचना मिलेगी।';

  @override
  String get walkthroughMarketTitle => 'पूरे भारत के मंडी भाव';

  @override
  String get walkthroughMarketBody =>
      'अपनी फसल के देशभर की मंडियों के हाल के भाव देखें।';

  @override
  String get walkthroughRecordsTitle => 'आपके रिकॉर्ड और हिसाब';

  @override
  String get walkthroughRecordsBody =>
      'छिड़काव, खर्च, मजदूरी और बिक्री दर्ज करें और हिसाब देखें। इंटरनेट न हो तब भी चलता है; नेटवर्क आने पर रिकॉर्ड भेज दिए जाते हैं।';

  @override
  String get settingsShowWalkthrough => 'ऐप का परिचय फिर से देखें';

  @override
  String buildLabel(String sha) {
    return 'टेस्ट बिल्ड $sha';
  }

  @override
  String get seedOrchard => 'नमूना बाग जोड़ें';

  @override
  String get seedOrchardDone => 'नमूना बाग जोड़ा गया';

  @override
  String get voiceUnavailable => 'इस फ़ोन पर बोलकर लिखना उपलब्ध नहीं है';

  @override
  String get voiceListening => 'सुन रहा है… रोकने के लिए दबाएँ';

  @override
  String get tasksTitle => 'काम';

  @override
  String get addTask => 'काम जोड़ें';

  @override
  String get taskWhat => 'क्या करना है?';

  @override
  String get taskKind => 'प्रकार';

  @override
  String get taskDue => 'कब';

  @override
  String get dueToday => 'आज';

  @override
  String get dueTomorrow => 'कल';

  @override
  String get pickDate => 'तारीख चुनें';

  @override
  String get tasksEmpty => 'अभी कोई काम नहीं। + बटन से जोड़ें।';

  @override
  String get tasksOverdue => 'देर हो चुकी';

  @override
  String get tasksToday => 'आज';

  @override
  String get tasksUpcoming => 'आगे के';

  @override
  String get tasksDone => 'पूरे';

  @override
  String get noTasksToday => 'आज कुछ बाकी नहीं';

  @override
  String get taskOverdue => 'देर';

  @override
  String dueInDays(int n) {
    return '$n दिन में';
  }

  @override
  String get editPlot => 'बाग बदलें';

  @override
  String get plotOpenRecords => 'बहार, छिड़काव और हिसाब';

  @override
  String get plotBoundaryNone => 'सीमा अभी दर्ज नहीं है';

  @override
  String get plotCentre => 'केंद्र बिंदु';

  @override
  String get calendarTitle => 'मौसम कैलेंडर';

  @override
  String get calendarIntro =>
      'अगले बारह महीनों की आपकी बहार तारीखें और काम, आपकी दर्ज जानकारी से।';

  @override
  String get calendarMonthEmpty => 'इस महीने कुछ दर्ज नहीं।';

  @override
  String get calendarStagePlanned => 'योजना';

  @override
  String get calendarStageDone => 'हो गया';

  @override
  String get calendarOpen => 'मौसम कैलेंडर';

  @override
  String get baharCompareTitle => 'बहारों की तुलना';

  @override
  String get baharCompareIntro =>
      'हर बहार पर विचार करने के लिए प्रकाशित स्रोतों के बिंदु। निर्णय आपका है; स्रोतों में कभी-कभी मतभेद होता है।';

  @override
  String baharCompareLast(String bahar) {
    return 'इस बाग में पिछला बहार: $bahar';
  }

  @override
  String get baharCompareNoLast => 'इस बाग में अभी कोई बहार दर्ज नहीं है।';

  @override
  String baharCompareSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get baharCompareNoPoints =>
      'इस बहार के लिए अभी जाँची हुई जानकारी नहीं है।';

  @override
  String get baharCompareUse => 'यह बहार चुनें';

  @override
  String get weatherTitle => 'मौसम';

  @override
  String weatherAsOf(String date) {
    return 'अद्यतन: $date';
  }

  @override
  String get weatherStale =>
      'मौसम अद्यतन नहीं हो सका; आख़िरी सहेजे दिन दिखा रहे हैं।';

  @override
  String get weatherNone => 'अभी मौसम नहीं है। फ़ोन ऑनलाइन होने पर आएगा।';

  @override
  String weatherRain(String mm) {
    return '$mm मिमी बारिश';
  }

  @override
  String weatherSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get labelInfoTitle => 'लेबल जानकारी';

  @override
  String get labelInfoBanner =>
      'यह जानकारी पंजीकृत लेबल (CIB&RC) पर छपी है। यह सिफ़ारिश नहीं है। किसी भी उपयोग से पहले उत्पाद का लेबल पढ़ें और अपने कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से पुष्टि करें।';

  @override
  String get labelInfoEmpty => 'पंजीकृत लेबल की जानकारी अभी उपलब्ध नहीं है।';

  @override
  String labelInfoUpdated(String date) {
    return 'अद्यतन: $date';
  }

  @override
  String get labelInfoDose => 'लेबल पर मात्रा:';

  @override
  String labelInfoInterval(String days) {
    return 'दो छिड़काव के बीच अंतर: $days दिन';
  }

  @override
  String labelInfoPhi(String days) {
    return 'कटाई से $days दिन पहले (PHI)';
  }

  @override
  String labelInfoMaxSprays(String count) {
    return 'अधिकतम छिड़काव: $count';
  }

  @override
  String labelInfoCrop(String crop) {
    return 'लेबल पर फसल: $crop';
  }

  @override
  String labelInfoSource(String title) {
    return 'स्रोत: $title';
  }

  @override
  String get marketPricesTitle => 'मंडी भाव';

  @override
  String get marketOpen => 'मंडी भाव';

  @override
  String get marketScopeAll => 'सभी';

  @override
  String get marketScopeLocal => 'मेरे पास';

  @override
  String get marketScopeMajor => 'बड़ी मंडियाँ';

  @override
  String get marketTagLocal => 'पास की मंडी';

  @override
  String get marketTagMajor => 'बड़ी मंडी';

  @override
  String get marketPerQuintal => 'प्रति क्विंटल';

  @override
  String marketRange(String min, String max) {
    return 'न्यूनतम–अधिकतम: $min – $max';
  }

  @override
  String marketVariety(String variety) {
    return 'किस्म: $variety';
  }

  @override
  String marketUpdated(String date) {
    return 'अद्यतन: $date';
  }

  @override
  String marketStale(String reason) {
    return 'भाव अद्यतन नहीं हो सके: $reason';
  }

  @override
  String get marketStaleNoReason =>
      'भाव अद्यतन नहीं हो सके; आख़िरी सहेजी सूची दिखा रहे हैं।';

  @override
  String get marketEmpty =>
      'अभी भाव नहीं हैं। फ़ोन ऑनलाइन होने और भाव का स्रोत जुड़ने पर आएँगे।';

  @override
  String get practicesOpen => 'बाग प्रबंधन पद्धतियाँ (रसायन-रहित)';

  @override
  String get practicesTitle => 'बाग प्रबंधन पद्धतियाँ';

  @override
  String practicesSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get practicesEvidenceOfficial => 'सरकारी';

  @override
  String get practicesEvidenceUniversity => 'विश्वविद्यालय';

  @override
  String get practicesEvidenceResearch => 'शोध निष्कर्ष';

  @override
  String get practicesEvidenceInferred => 'अनुमानित';

  @override
  String get practicesGapsTitle => 'इनके लिए अभी रसायन-रहित उपाय नहीं मिला';

  @override
  String get practicesSourcesLine =>
      'स्रोत: NHB और डॉ. पीडीकेवी, अकोला। हर पद्धति के नीचे विवरण।';

  @override
  String get scoutingTitle => 'निरीक्षण नोंद';

  @override
  String get scoutingAdd => 'निरीक्षण जोड़ें';

  @override
  String get scoutingEmpty =>
      'अभी कोई निरीक्षण दर्ज नहीं है। इस बाग में जो दिखा, वह दर्ज करें।';

  @override
  String get scoutingDate => 'तारीख';

  @override
  String get scoutingWhat => 'क्या देखा?';

  @override
  String get scoutingSeverity => 'कितना?';

  @override
  String get scoutingNote => 'टिप्पणी (वैकल्पिक)';

  @override
  String get scoutingPhoto => 'फ़ोटो (वैकल्पिक, सिर्फ़ इसी फ़ोन पर रहती है)';

  @override
  String get scoutingCamera => 'कैमरा';

  @override
  String get scoutingGallery => 'गैलरी';

  @override
  String get scoutingRemovePhoto => 'फ़ोटो हटाएँ';

  @override
  String get scoutingPhotoFailed => 'फ़ोटो नहीं मिल सकी। फिर से कोशिश करें।';

  @override
  String get scoutingPickOne => 'एक चुनें';

  @override
  String get scoutingItemPsylla => 'सिट्रस सिल्ला';

  @override
  String get scoutingItemLeafMiner => 'पत्ती सुरंगक (लीफ माइनर)';

  @override
  String get scoutingItemMitesThrips => 'माइट्स / थ्रिप्स';

  @override
  String get scoutingItemFruitDrop => 'फल गिरना';

  @override
  String get scoutingItemGummosis => 'गोंद रिसना / छाल';

  @override
  String get scoutingItemDieBack => 'टहनियाँ सूखना (डाइबैक)';

  @override
  String get scoutingItemOther => 'अन्य';

  @override
  String get scoutingSeverityNone => 'नहीं दिखा';

  @override
  String get scoutingSeverityLow => 'कम';

  @override
  String get scoutingSeverityMedium => 'मध्यम';

  @override
  String get scoutingSeverityHigh => 'ज़्यादा';

  @override
  String get irrigationOpen => 'सिंचाई तालिका';

  @override
  String get irrigationGuideTitle => 'सिंचाई तालिका';

  @override
  String get irrigationCaveat =>
      'पानी की मात्रा मिट्टी, पेड़ के फैलाव और मौसम पर निर्भर है। पानी देना बदलने से पहले अपने कृषि विज्ञान केंद्र (KVK) से पूछें।';

  @override
  String get irrigationCropLabel => 'फसल';

  @override
  String get irrigationAgeLabel => 'पेड़ की उम्र';

  @override
  String irrigationPlanted(String year, String years) {
    return 'रोपण $year: लगभग $years साल के पेड़';
  }

  @override
  String get irrigationNoPlantingYear =>
      'इस बाग का रोपण वर्ष नहीं भरा है। पेड़ की उम्र चुनें।';

  @override
  String get irrigationNoRows => 'इस उम्र के लिए स्रोत में अभी आँकड़ा नहीं है।';

  @override
  String get irrigationStagesTitle => 'फूल, फल और बहार का तनाव';

  @override
  String get irrigationGapsTitle => 'स्रोत में अभी नहीं मिला';

  @override
  String get irrigationSourcesLine =>
      'स्रोत: NHB, डॉ. पीडीकेवी अकोला और प्रकाशित नींबूवर्गीय शोध। हर बिंदु के नीचे विवरण।';

  @override
  String get feedTitle => 'सरकारी संदेश';

  @override
  String get feedOpenHint => 'आधिकारिक GR, योजनाएँ और आख़िरी तारीख़ें';

  @override
  String get feedFilterAll => 'सभी';

  @override
  String get feedFilterOfficial => 'आधिकारिक';

  @override
  String get feedFilterSchemes => 'योजनाएँ';

  @override
  String get feedFilterDeadlines => 'आख़िरी तारीख़';

  @override
  String get feedFilterNews => 'ख़बरें';

  @override
  String get feedBadgeOfficial => 'आधिकारिक';

  @override
  String feedGrNumber(String number) {
    return 'GR सं. $number';
  }

  @override
  String get feedBadgeNews => 'ख़बर — आधिकारिक नहीं';

  @override
  String feedReplacedBy(String replacement) {
    return 'वापस लिया गया. इसकी जगह अब: $replacement';
  }

  @override
  String feedExpired(String date) {
    return 'अब लागू नहीं ($date को समाप्त)';
  }

  @override
  String feedMayBeEligible(String reason) {
    return 'आप पात्र हो सकते हैं क्योंकि $reason';
  }

  @override
  String get feedFooter => 'कुछ भी करने से पहले आधिकारिक GR/पोर्टल देखें.';

  @override
  String feedDeadline(String date) {
    return 'आख़िरी तारीख़: $date';
  }

  @override
  String feedUpdated(String date) {
    return '$date को अपडेट';
  }

  @override
  String get feedEmpty => 'अभी कोई संदेश नहीं. फ़ोन ऑनलाइन होने पर आएँगे.';

  @override
  String get feedRemindMe => 'मुझे याद दिलाएँ';

  @override
  String feedReminderAdded(String date) {
    return '$date के लिए आपके कामों में जोड़ा';
  }

  @override
  String get feedReminderExists => 'पहले से आपके कामों में है';

  @override
  String get feedShare => 'भेजें';

  @override
  String get feedCopyLink => 'स्रोत लिंक कॉपी करें';

  @override
  String get feedLinkCopied => 'लिंक कॉपी हो गया. ब्राउज़र में खोलें.';

  @override
  String feedSource(String url) {
    return 'स्रोत: $url';
  }

  @override
  String get feedNotFound => 'यह संदेश अब सहेजी सूची में नहीं है.';
}
