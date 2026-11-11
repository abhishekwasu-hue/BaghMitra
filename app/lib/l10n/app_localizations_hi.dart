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
  String get homeWeatherNeedsLocation => 'बाग की जगह जोड़ें, यहाँ मौसम दिखेगा।';

  @override
  String minTemperature(int degrees) {
    final intl.NumberFormat degreesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String degreesString = degreesNumberFormat.format(degrees);

    return 'न्यूनतम $degreesString°';
  }

  @override
  String homeNextStage(String stage, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'अगला चरण: $stage · $daysString दिनों में';
  }

  @override
  String homeHarvestMonth(String month) {
    return 'तुड़ाई $month';
  }

  @override
  String get homeStageAddDates => 'चरणों की तारीखें लिखें, यहाँ दिन दिखेंगे।';

  @override
  String get homeOpenMarket => 'मंडी भाव देखें';

  @override
  String get choosePlot => 'बाग चुनें';

  @override
  String get onboardingSaveFailed => 'कृपया फिर से \"आगे बढ़ें\" दबाएँ।';

  @override
  String get perQuintal => 'प्रति क्विंटल';

  @override
  String get vsLastWeek => 'पिछले सप्ताह से';

  @override
  String get takePhoto => 'कीट-रोग फ़ोटो';

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
      'आपकी एंट्री इस फ़ोन पर सहेजी गई है; नेटवर्क आने पर भेजी जाएगी।';

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
  String get syncFailed =>
      'आपके रिकॉर्ड इस फ़ोन पर सुरक्षित हैं। ऐप अपने आप फिर से भेजने की कोशिश करेगा।';

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
      'कृपया Google लॉगिन फिर से करके देखें; इंटरनेट चालू है, यह जाँच लें।';

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
  String get loginInvalidOtp => 'SMS में आया नया 6 अंकों का OTP डालें';

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
  String get plotsEmptyTitle => 'अपना पहला बाग जोड़ें';

  @override
  String get plotsEmptyBody =>
      'हर बाग के लिए बहार कैलेंडर और रोज़ के काम मिलेंगे।';

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
  String get plotSaved => 'सहेजा गया।';

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
  String get baharEmptyTitle => 'पहला बहार तय करें';

  @override
  String get baharEmptyBody =>
      'बहार चुनें। हर चरण के लिए सार्वजनिक स्रोतों से सुझाया समय दिखता है; हर तारीख आप बदल सकते हैं।';

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
  String get adminNoAlerts => 'खुली सूचनाएँ यहाँ दिखेंगी';

  @override
  String get adminNoCards => 'कार्ड जोड़ने पर यहाँ दिखेंगे';

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
  String get adminFeed => 'सरकारी संदेश';

  @override
  String get adminFeedQueue => 'जाँच कतार';

  @override
  String get adminFeedUpload => 'अपलोड';

  @override
  String get adminFeedSources => 'संदेश स्रोत';

  @override
  String get adminFeedStatusInReview => 'जाँच में';

  @override
  String get adminFeedStatusDraft => 'मसौदा';

  @override
  String get adminFeedStatusPublished => 'प्रकाशित';

  @override
  String get adminFeedStatusWithdrawn => 'वापस लिया';

  @override
  String get adminFeedNoItems => 'यह सूची खाली है';

  @override
  String get adminFeedApproved => 'मंज़ूर';

  @override
  String adminFeedIssueCount(int count) {
    return '$count जाँच मुद्दे';
  }

  @override
  String get adminFeedAiOff => 'AI सेट करना बाकी है';

  @override
  String get adminFeedSourceLink => 'मूल दस्तावेज़';

  @override
  String adminFeedReplacedByValue(String id) {
    return '$id से बदला गया';
  }

  @override
  String get adminFeedWithdraw => 'वापस लें';

  @override
  String get adminFeedAiDraft => 'AI मसौदा';

  @override
  String get adminFeedCheckIssues => 'आउटपुट-जाँच मुद्दे';

  @override
  String get adminFeedNoIssues => 'सभी जाँच ठीक हैं';

  @override
  String get adminFeedTextPreview => 'निकाला गया पाठ';

  @override
  String get adminFeedTexts => 'शीर्षक और सारांश';

  @override
  String get adminFeedDates => 'तारीखें';

  @override
  String get adminFeedDeadline => 'अंतिम तारीख';

  @override
  String get adminFeedPayment => 'भुगतान तारीख';

  @override
  String get adminFeedValidFrom => 'से लागू';

  @override
  String get adminFeedValidTo => 'तक लागू';

  @override
  String get adminFeedDatesNote =>
      'तारीखें मूल पाठ से जाँची जाती हैं। प्रकाशित आइटम में बदलाव सहेजने पर वह फिर समीक्षा में जाता है।';

  @override
  String get adminFeedPickDate => 'तारीख चुनें';

  @override
  String get adminFeedClearDate => 'हटाएँ';

  @override
  String get adminFeedSaveDates => 'तारीखें सहेजें';

  @override
  String get adminFeedCardNew => 'योजना कार्ड';

  @override
  String get adminFeedCardNote =>
      'हर फ़ील्ड: दस्तावेज़ में लिखा मान और उसका पेज, या \"दस्तावेज़ में खाली\"।';

  @override
  String get adminFeedNotStated => 'दस्तावेज़ में खाली';

  @override
  String get adminFeedCardValue => 'मान';

  @override
  String get adminFeedCardPage => 'पेज (जैसे p. 2)';

  @override
  String get adminFeedSaveCard => 'कार्ड सहेजें';

  @override
  String get adminFeedCardEmpty =>
      'कम से कम एक फ़ील्ड भरें या \"दस्तावेज़ में खाली\" चुनें।';

  @override
  String get adminFeedFullText => 'सहेजा गया पाठ (आउटपुट जाँच यही पढ़ती है):';

  @override
  String get adminFeedTextTruncated =>
      'केवल पहले 200 KB दिखाए गए हैं; सहेजा गया पाठ इससे लंबा है।';

  @override
  String adminFeedCard(int version) {
    return 'योजना कार्ड v$version';
  }

  @override
  String get adminFeedTargets => 'लक्ष्य';

  @override
  String get adminFeedHistory => 'इतिहास';

  @override
  String get adminFeedHasText =>
      'पाठ सहेजा है (आउटपुट जाँच और AI मसौदे के लिए)।';

  @override
  String get adminFeedNoText =>
      'इसके लिए उपयोगी पाठ चाहिए: पाठ पेस्ट करके फिर अपलोड करें, या टिप्पणी के साथ मुद्दे स्वीकारें।';

  @override
  String get adminFeedUnusedText => 'अलग रखा गया पाठ (बिगड़ी पाठ-परत या OCR):';

  @override
  String get adminFeedTitle => 'शीर्षक';

  @override
  String get adminFeedSummary => 'सारांश (2 पंक्तियाँ)';

  @override
  String get adminFeedSave => 'सहेजें';

  @override
  String get adminFeedBadNumber => 'हेक्टेयर अंकों में लिखें।';

  @override
  String get adminFeedTargetsNote =>
      'खाली फ़ील्ड का अर्थ कोई भी। मिलान हमेशा सिर्फ़ \"पात्र हो सकते हैं\" ही कहता है।';

  @override
  String get adminFeedDistrict => 'ज़िला';

  @override
  String get adminFeedCrop => 'फसल';

  @override
  String get adminFeedMinHa => 'न्यूनतम हे.';

  @override
  String get adminFeedMaxHa => 'अधिकतम हे.';

  @override
  String get adminFeedRemove => 'हटाएँ';

  @override
  String get adminFeedAddTarget => 'लक्ष्य जोड़ें';

  @override
  String get adminFeedSaveTargets => 'लक्ष्य सहेजें';

  @override
  String get adminFeedAcceptTitle => 'खुले जाँच मुद्दे स्वीकारें?';

  @override
  String adminFeedAcceptBody(int count) {
    return 'इस मद में $count खुले जाँच मुद्दे हैं। फिर भी मंज़ूर करना हो तो कारण की टिप्पणी लिखें।';
  }

  @override
  String get adminFeedComment => 'टिप्पणी (क्यों)';

  @override
  String get adminFeedCancel => 'रद्द करें';

  @override
  String get adminFeedAcceptApprove => 'स्वीकारें और मंज़ूर करें';

  @override
  String get adminFeedWithdrawTitle => 'मद वापस लें';

  @override
  String get adminFeedReason => 'कारण';

  @override
  String get adminFeedReplacedBy => 'इससे बदला गया';

  @override
  String get adminFeedNoReplacement => 'सिर्फ़ वापस लें';

  @override
  String get adminFeedRequiredMissing =>
      'स्रोत की, दस्तावेज़ URL और प्रकाशन तारीख ज़रूरी हैं।';

  @override
  String get adminFeedBadDate => 'तारीखें YYYY-MM-DD में लिखें।';

  @override
  String adminFeedCreated(String status, int count) {
    return 'बना: $status, $count जाँच मुद्दे';
  }

  @override
  String get adminFeedDateHint => 'YYYY-MM-DD';

  @override
  String get adminFeedUploadNote =>
      'GR दस्तावेज़ चुनें (सर्वर उसका हैश रखता है और पाठ पढ़ता है) और / या उसका पाठ पेस्ट करें (पेस्ट किया पाठ मान्य)। आधिकारिक URL हमेशा चाहिए।';

  @override
  String get adminFeedPickDocument => 'दस्तावेज़ चुनें (PDF या HTML)';

  @override
  String get adminFeedNoDocument => 'दस्तावेज़ चुनें';

  @override
  String adminFeedDocument(String name, int kb) {
    return '$name · $kb KB';
  }

  @override
  String adminFeedTooLarge(int mb) {
    return 'दस्तावेज़ $mb MB से बड़ा है।';
  }

  @override
  String get adminFeedBadType => 'केवल .pdf, .html या .htm फ़ाइल।';

  @override
  String get adminFeedExtraction => 'पाठ निकालने का नतीजा';

  @override
  String get adminFeedSourceKey => 'स्रोत की';

  @override
  String get adminFeedPublishedAt => 'प्रकाशन तारीख';

  @override
  String get adminFeedUrl => 'दस्तावेज़ URL';

  @override
  String get adminFeedExternalId => 'बाहरी ID (GR कोड)';

  @override
  String get adminFeedGrNumber => 'GR संख्या';

  @override
  String get adminFeedDepartment => 'विभाग';

  @override
  String get adminFeedPastedText => 'दस्तावेज़ का पाठ (पेस्ट किया)';

  @override
  String get adminFeedSubmit => 'जाँच को भेजें';

  @override
  String get adminFeedOpen => 'मद खोलें';

  @override
  String get adminFeedTerms => 'शर्तें';

  @override
  String get adminFeedTermsUnknown => 'अस्पष्ट';

  @override
  String get adminFeedTermsAllowed => 'अनुमति';

  @override
  String get adminFeedTermsDisallowed => 'उपयोग की मनाही';

  @override
  String get adminFeedTermsNote => 'टिप्पणी (क्या पढ़ा)';

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
  String get accountsEmpty => 'अपना पहला खर्च या बिक्री दर्ज करें।';

  @override
  String saleBy(String buyer, String kg) {
    return '$buyer · $kg किलो';
  }

  @override
  String get sprayLogTitle => 'छिड़काव रिकॉर्ड';

  @override
  String get addSpray => 'छिड़काव दर्ज करें';

  @override
  String get spraysEmpty => 'पहले छिड़काव का रिकॉर्ड यहाँ दर्ज करें।';

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
  String get sprayWarnBannedTitle => 'मान्य सूची से बाहर का तत्व';

  @override
  String sprayWarnBannedBody(String notification) {
    return 'यह तत्व सरकार की मान्य सूची से बाहर है ($notification)। पंजीकृत विकल्प लेबल जानकारी में देखें।';
  }

  @override
  String get sprayWarnRestrictedTitle => 'इस फसल के लिए मान्य सूची से बाहर';

  @override
  String sprayWarnRestrictedBody(String notification) {
    return 'इस फसल के लिए यह तत्व मान्य सूची से बाहर है ($notification)। लेबल जानकारी देखें।';
  }

  @override
  String get sprayWarnPhiTitle => 'प्रतीक्षा अवधि';

  @override
  String sprayWarnPhiBody(String date) {
    return 'प्रतीक्षा अवधि खत्म होने से पहले कटाई तय है। $date से कटाई सुरक्षित है।';
  }

  @override
  String get fieldLogTitle => 'खेत के रिकॉर्ड';

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
  String get fieldLogEmpty => 'खाद या सिंचाई का पहला रिकॉर्ड जोड़ें।';

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
  String get labourEmpty => 'मज़दूरी का पहला रिकॉर्ड जोड़ें।';

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
  String get harvestKg => 'वज़न (किलो)';

  @override
  String get harvestGrade => 'ग्रेड (वैकल्पिक)';

  @override
  String get harvestSize => 'आकार (वैकल्पिक)';

  @override
  String get harvestEmpty => 'तुड़ाई का पहला रिकॉर्ड जोड़ें।';

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
      'बहार शुरू करें और रिकॉर्ड जोड़ें, फिर सीज़न की तुलना दिखेगी।';

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
  String get compareSame => 'बराबर';

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
      'ऐप चलाने के लिए बागमित्र मेरे बाग के रिकॉर्ड सहेजे, इसकी मेरी सहमति है।';

  @override
  String get onboardingConsentWhatsapp =>
      'मुझे WhatsApp पर याद दिलाएँ (वैकल्पिक)।';

  @override
  String get onboardingContinue => 'आगे बढ़ें';

  @override
  String get profileTitle => 'मेरी जानकारी';

  @override
  String get profileConsentDataNote =>
      'आपके रिकॉर्ड सहेजने और सुरक्षित रखने के लिए यह सहमति ज़रूरी है, इसलिए यह हमेशा चालू रहती है।';

  @override
  String get profilePhoneSignedIn => 'आप इसी नंबर से लॉगिन करते हैं।';

  @override
  String get profileAddPhone => 'मोबाइल नंबर जोड़ें (वैकल्पिक)';

  @override
  String get profilePhoneContactOnly =>
      'सिर्फ़ आपसे संपर्क के लिए। लॉगिन पहले की तरह Google से ही होगा।';

  @override
  String get profileSaved => 'सहेज लिया।';

  @override
  String get profileSignOut => 'लॉगआउट';

  @override
  String get profileSignOutTitle => 'लॉगआउट करें?';

  @override
  String get profileSignOutBody =>
      'आपके रिकॉर्ड इसी फ़ोन पर रहेंगे। फिर से लॉगिन करने पर दिखेंगे।';

  @override
  String get profilePrivacy => 'गोपनीयता नीति';

  @override
  String get profilePrivacyHint =>
      'लिंक कॉपी करने के लिए दबाएँ, फिर ब्राउज़र में खोलें';

  @override
  String get profileDeleteAccount => 'मेरा खाता और जानकारी हटाएँ';

  @override
  String get profileDeleteTitle => 'खाता हटाना है?';

  @override
  String profileDeleteBody(String word) {
    return 'आपके सभी रिकॉर्ड, फ़ोटो और इतिहास सर्वर और इस फ़ोन से मिटा दिए जाएँगे और आप लॉगआउट हो जाएँगे। यह स्थायी है। पुष्टि के लिए $word लिखें।';
  }

  @override
  String get profileDeleteWord => 'हटाएँ';

  @override
  String get profileDeleteConfirm => 'हमेशा के लिए हटाएँ';

  @override
  String get profileDeleteFailed =>
      'थोड़ी देर बाद फिर कोशिश करें: खाता हटाने के लिए इंटरनेट और सर्वर चाहिए। आपकी सारी जानकारी अभी वैसी ही है।';

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
      'फ़ोन की ऐप सेटिंग में लोकेशन की अनुमति दें।';

  @override
  String get boundaryFailed =>
      'जगह पाने के लिए खुली जगह में जाकर फिर कोशिश करें।';

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
  String get loginTryWithout => 'पहले ऐप आज़माएँ';

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
  String get updateAvailable => 'नया संस्करण उपलब्ध — डाउनलोड करें';

  @override
  String get updateDismiss => 'बंद करें';

  @override
  String get updateDownload => 'डाउनलोड करें';

  @override
  String get updateRequiredTitle => 'नया संस्करण ज़रूरी है';

  @override
  String get updateRequiredBody =>
      'बागमित्र इस्तेमाल करते रहने के लिए नया संस्करण डाउनलोड करके इंस्टॉल करें।';

  @override
  String updateLinkCopied(String url) {
    return 'लिंक कॉपी हो गया। ब्राउज़र में पेस्ट करके डाउनलोड करें: $url';
  }

  @override
  String settingsVersion(String name, String code) {
    return 'संस्करण $name ($code)';
  }

  @override
  String get walkthroughSkip => 'छोड़ें';

  @override
  String get walkthroughNext => 'आगे';

  @override
  String get walkthroughStart => 'शुरू करें';

  @override
  String get walkthroughPlotsTitle => 'आपके बाग और बहार कैलेंडर';

  @override
  String get walkthroughPlotsBody =>
      'अपने बाग जोड़ें। हर बहार के लिए मौसम का कैलेंडर और करने वाले कामों की सूची दिखेगी।';

  @override
  String get walkthroughWeatherTitle => 'आपके बाग के लिए मौसम सूचना';

  @override
  String get walkthroughWeatherBody =>
      'अपने बाग का मौसम देखें। बारिश या धूप पर ध्यान देना हो तब सूचना मिलेगी।';

  @override
  String get walkthroughMarketTitle => 'पूरे भारत के मंडी भाव';

  @override
  String get walkthroughMarketBody =>
      'अपनी फसल के देशभर की मंडियों के हाल के भाव देखें।';

  @override
  String get walkthroughRecordsTitle => 'आपके रिकॉर्ड और हिसाब';

  @override
  String get walkthroughRecordsBody =>
      'छिड़काव, खर्च, मजदूरी और बिक्री दर्ज करें और हिसाब देखें। नेट बंद होने पर भी ऐप चलता है; नेटवर्क आने पर रिकॉर्ड भेज दिए जाते हैं।';

  @override
  String get settingsShowWalkthrough => 'ऐप का परिचय फिर से देखें';

  @override
  String get settingsPhotoMobileData => 'मोबाइल डेटा पर भी फ़ोटो का बैकअप लें';

  @override
  String get settingsPhotoMobileDataHint =>
      'निरीक्षण और बिल की फ़ोटो का बैकअप वाई-फ़ाई पर होता है। मोबाइल डेटा भी इस्तेमाल करना हो तो इसे चालू करें।';

  @override
  String buildLabel(String sha) {
    return 'टेस्ट बिल्ड $sha';
  }

  @override
  String get seedOrchard => 'नमूना बाग जोड़ें';

  @override
  String get seedOrchardDone => 'नमूना बाग जोड़ा गया';

  @override
  String get voiceUnavailable =>
      'कृपया यहाँ टाइप करें; बोलकर लिखना उसकी सुविधा वाले फ़ोन पर चलता है';

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
  String get tasksEmpty => '+ बटन से पहला काम जोड़ें।';

  @override
  String get tasksOverdue => 'बाकी';

  @override
  String get tasksToday => 'आज';

  @override
  String get tasksUpcoming => 'आगे के';

  @override
  String get tasksDone => 'पूरे';

  @override
  String get noTasksToday => 'आज का दिन खाली';

  @override
  String get taskOverdue => 'आज ही करें';

  @override
  String dueInDays(int n) {
    return '$n दिन में';
  }

  @override
  String get editPlot => 'बाग बदलें';

  @override
  String get plotOpenRecords => 'बहार, छिड़काव और हिसाब';

  @override
  String get plotBoundaryNone => 'सीमा दर्ज करें';

  @override
  String get plotCentre => 'केंद्र बिंदु';

  @override
  String get plotLocation => 'जगह';

  @override
  String get plotPointCapture => 'मैं बाग में हूँ — जगह लें';

  @override
  String get plotPointWhy =>
      'इस बाग के मौसम और चेतावनियों के लिए। जगह केवल अभी एक बार ली जाती है।';

  @override
  String get plotPointReading => 'जगह ली जा रही है…';

  @override
  String get plotPointTake => 'जगह लें';

  @override
  String get plotPointRetake => 'जगह फिर से लें';

  @override
  String get plotPointDenied => 'बाग की जगह सेव करने के लिए अनुमति दें।';

  @override
  String get plotPointOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get plotPointTryAgain => 'फिर से कोशिश करें';

  @override
  String get plotPointLater =>
      'बाग अभी सेव करें; जगह बाद में कभी भी ले सकते हैं।';

  @override
  String get boundaryWalkOptional => 'सीमा चलकर दर्ज करें (वैकल्पिक)';

  @override
  String get calendarTitle => 'मौसम कैलेंडर';

  @override
  String get calendarIntro =>
      'अगले बारह महीनों की आपकी बहार तारीखें और काम, आपकी दर्ज जानकारी से।';

  @override
  String get calendarMonthEmpty => 'यह महीना खाली है।';

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
  String get baharCompareNoLast =>
      'इस बाग का पहला बहार दर्ज करें, फिर वह यहाँ दिखेगा।';

  @override
  String baharCompareSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get baharCompareNoPoints =>
      'इस बहार की जाँची हुई जानकारी तैयार होने पर यहाँ दिखेगी।';

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
      'आख़िरी सहेजे दिन दिखा रहे हैं; अगली बार मौसम मिलने पर अद्यतन होगा।';

  @override
  String get weatherNone => 'फ़ोन ऑनलाइन होने पर मौसम आएगा।';

  @override
  String weatherRain(String mm) {
    return '$mm मिमी बारिश';
  }

  @override
  String weatherSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get alertSwitchOff => 'यह अलर्ट बंद करें';

  @override
  String get alertSwitchOn => 'यह अलर्ट चालू करें';

  @override
  String alertTypeOff(String name) {
    return '$name अलर्ट बंद';
  }

  @override
  String get alertThisOff => 'यह अलर्ट बंद है';

  @override
  String get alertNameHeat => 'गर्मी';

  @override
  String get alertNamePsylla => 'सिल्ला';

  @override
  String get alertNameHail => 'ओलावृष्टि और तूफ़ान';

  @override
  String get alertNameWind => 'तेज़ हवा';

  @override
  String get alertNameHeavyRain => 'भारी बारिश';

  @override
  String get alertNameUnseasonalRain => 'बेमौसम बारिश';

  @override
  String get alertNameColdWave => 'शीतलहर';

  @override
  String get alertNameHumidity => 'नम मौसम';

  @override
  String get weatherForecastTitle => 'मौसम पूर्वानुमान';

  @override
  String weatherForecastNext(String days) {
    return 'अगले $days दिन';
  }

  @override
  String get weatherColDay => 'दिन';

  @override
  String get weatherColTemp => 'तापमान';

  @override
  String get weatherColRain => 'बारिश';

  @override
  String get weatherColWind => 'हवा';

  @override
  String get weatherColHumidity => 'नमी';

  @override
  String get weatherUnitTemp => 'अधिक/न्यून';

  @override
  String get weatherUnitRain => 'मिमी/%';

  @override
  String get weatherUnitWind => 'किमी/घं';

  @override
  String get weatherLegendRain => 'बारिश की संभावना';

  @override
  String weatherLegendHeat(String deg) {
    return '$deg° और अधिक';
  }

  @override
  String get weatherSkyClear => 'साफ़ आसमान';

  @override
  String get weatherSkyCloudy => 'बादल';

  @override
  String get weatherSkyRain => 'बारिश';

  @override
  String get weatherSkyStorm => 'गरज के साथ बारिश';

  @override
  String get labelInfoTitle => 'लेबल जानकारी';

  @override
  String get labelInfoBanner =>
      'यह जानकारी पंजीकृत लेबल (CIB&RC) पर छपी है; यह केवल लेबल की जानकारी है, सिफ़ारिश नहीं। किसी भी उपयोग से पहले उत्पाद का लेबल पढ़ें और अपने कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से पुष्टि करें।';

  @override
  String get labelInfoEmpty =>
      'पंजीकृत लेबल की जानकारी उपलब्ध होने पर यहाँ दिखेगी।';

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
  String get marketTrendOpen => 'भाव का रुझान';

  @override
  String marketTrendTitle(String market) {
    return 'भाव का रुझान: $market';
  }

  @override
  String get marketTrendRange15 => '15 दिन';

  @override
  String get marketTrendRange30 => '1 महीना';

  @override
  String get marketTrendRange90 => '3 महीने';

  @override
  String get marketTrendHigh => 'सर्वाधिक';

  @override
  String get marketTrendLow => 'सबसे कम';

  @override
  String get marketTrendChange15 => '15 दिनों में';

  @override
  String get marketTrendChange30 => '1 महीने में';

  @override
  String get marketTrendHint =>
      'हर दिन का भाव देखने के लिए चार्ट पर उंगली फिराएँ।';

  @override
  String get marketTrendCollecting =>
      'भाव हर दिन सहेजा जाता है; चार्ट दिन-ब-दिन भरता है।';

  @override
  String marketTrendSemantics(
    String range,
    String high,
    String low,
    String latest,
  ) {
    return 'भाव का रुझान, $range: सर्वाधिक $high, सबसे कम $low, ताज़ा $latest प्रति क्विंटल';
  }

  @override
  String marketStale(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'source_not_configured': 'मंडी भाव सेवा जल्द शुरू होगी।',
      'other':
          'आख़िरी सहेजे भाव दिखा रहे हैं; अगली बार भाव मिलने पर अद्यतन होंगे।',
    });
    return '$_temp0';
  }

  @override
  String get marketStaleNoReason =>
      'आख़िरी सहेजी सूची दिखा रहे हैं; अगली बार भाव मिलने पर अद्यतन होगी।';

  @override
  String get marketEmpty =>
      'फ़ोन ऑनलाइन होने और मंडी भाव सेवा चालू होने पर भाव यहाँ दिखेंगे।';

  @override
  String get marketCrop => 'फसल';

  @override
  String marketCropSoon(String crop) {
    return '$crop के भाव जल्द ही यहाँ दिखेंगे। मंडी भाव हर 6 घंटे में अपने-आप अपडेट होते हैं।';
  }

  @override
  String get marketSearchOpen => 'मंडी खोजें';

  @override
  String get marketSearchClose => 'खोज बंद करें';

  @override
  String get marketSearchHint => 'मंडी, ज़िला या राज्य';

  @override
  String get marketSearchClear => 'साफ़ करें';

  @override
  String marketSearchEmpty(String query) {
    return '“$query” की जगह कोई दूसरा मंडी, ज़िले या राज्य का नाम लिखकर देखें।';
  }

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
  String get practicesGapsTitle => 'इनके लिए रसायन-रहित उपाय अभी खोजना बाकी है';

  @override
  String get practicesSourcesLine =>
      'स्रोत: NHB और डॉ. पीडीकेवी, अकोला। हर पद्धति के नीचे विवरण।';

  @override
  String get scoutingTitle => 'निरीक्षण रिकॉर्ड';

  @override
  String get scoutingAdd => 'निरीक्षण जोड़ें';

  @override
  String get scoutingEmpty =>
      'पहला निरीक्षण दर्ज करें: इस बाग में जो दिखा, वह लिखें।';

  @override
  String get scoutingDate => 'तारीख';

  @override
  String get scoutingWhat => 'क्या देखा?';

  @override
  String get scoutingSeverity => 'कितना?';

  @override
  String get scoutingNote => 'टिप्पणी (वैकल्पिक)';

  @override
  String get scoutingPhoto => 'फ़ोटो (वैकल्पिक)';

  @override
  String get scoutingPhotoBackedUp => 'फ़ोटो का बैकअप हो गया';

  @override
  String get scoutingCamera => 'कैमरा';

  @override
  String get scoutingGallery => 'गैलरी';

  @override
  String get scoutingRemovePhoto => 'फ़ोटो हटाएँ';

  @override
  String get scoutingPhotoFailed => 'कृपया फ़ोटो फिर से लें।';

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
  String get scoutingSeverityNone => 'शून्य';

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
      'पानी की मात्रा मिट्टी, पेड़ के फैलाव और मौसम पर निर्भर है।';

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
      'पेड़ की उम्र चुनें, या इस बाग का रोपण वर्ष भरें।';

  @override
  String get irrigationNoRows =>
      'इस उम्र का आँकड़ा अभी स्रोत में खोजना बाकी है।';

  @override
  String get irrigationStagesTitle => 'फूल, फल और बहार का तनाव';

  @override
  String get irrigationGapsTitle => 'स्रोत में अभी खोजना बाकी';

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
  String get feedLevelCentral => 'भारत सरकार';

  @override
  String get feedLevelState => 'महाराष्ट्र सरकार';

  @override
  String get feedArticleByline =>
      'BagMitra समाचार कक्ष · सरकारी स्रोतों से AI द्वारा लिखित';

  @override
  String get feedArticleKeyPoints => 'मुख्य बातें';

  @override
  String get feedArticleFacts => 'एक नज़र में';

  @override
  String get feedArticleKeyDates => 'महत्वपूर्ण तारीखें';

  @override
  String get feedArticleSources => 'स्रोत';

  @override
  String feedGrNumber(String number) {
    return 'GR सं. $number';
  }

  @override
  String get feedBadgeNews => 'ख़बर';

  @override
  String feedReplacedBy(String replacement) {
    return 'वापस लिया गया। इसकी जगह अब: $replacement';
  }

  @override
  String feedExpired(String date) {
    return '$date को समाप्त';
  }

  @override
  String feedMayBeEligible(String reason) {
    return 'आप पात्र हो सकते हैं क्योंकि $reason';
  }

  @override
  String get feedFooter =>
      'कोई भी कदम उठाने से पहले आधिकारिक GR / पोर्टल देखें।';

  @override
  String feedDeadline(String date) {
    return 'आख़िरी तारीख़: $date';
  }

  @override
  String feedUpdated(String date) {
    return '$date को अपडेट';
  }

  @override
  String get feedEmpty => 'फ़ोन ऑनलाइन होने पर संदेश आएँगे।';

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
  String get feedLinkCopied => 'लिंक कॉपी हो गया। ब्राउज़र में खोलें।';

  @override
  String feedSource(String url) {
    return 'स्रोत: $url';
  }

  @override
  String get feedNotFound => 'यह संदेश सहेजी सूची से हट गया है।';

  @override
  String get feedUnseen => 'नया';

  @override
  String get feedDismiss => 'मेरी सूची से हटाएँ';

  @override
  String get feedDismissed => 'आपकी सूची से हटा दिया।';

  @override
  String get feedPrefsTitle => 'सूचना सेटिंग';

  @override
  String get feedPrefsQuietTitle => 'शांत समय (सूचनाएँ शांत रहेंगी)';

  @override
  String get feedPrefsQuietStart => 'से';

  @override
  String get feedPrefsQuietEnd => 'तक';

  @override
  String feedPrefsWeeklyCap(String count) {
    return 'हफ़्ते में ज़्यादा से ज़्यादा $count सूचनाएँ';
  }

  @override
  String get feedPrefsCapLess => 'कम';

  @override
  String get feedPrefsCapMore => 'ज़्यादा';

  @override
  String get feedPrefsCategoriesTitle => 'इन बातों की सूचना भेजें';

  @override
  String get feedPrefsCatDeadline => 'नज़दीक आती आख़िरी तारीख़ें';

  @override
  String get feedPrefsCatPayment => 'भुगतान की जानकारी';

  @override
  String get feedPrefsCatWindowOpen => 'आवेदन शुरू हुए';

  @override
  String get feedPrefsDigest => 'हफ़्ते का सार';

  @override
  String get feedPrefsDigestHint => 'हफ़्ते में एक बार नई जानकारी का एक संदेश।';

  @override
  String get feedPrefsSave => 'सहेजें';

  @override
  String get feedPrefsSaved => 'सेटिंग सहेज ली गई।';

  @override
  String get feedPrefsSaveFailed => 'इंटरनेट आने पर फिर से सहेजें।';

  @override
  String get feedPrefsOffline =>
      'ये आपकी आख़िरी सहेजी सेटिंग हैं। बदलाव सहेजने के लिए इंटरनेट चालू करें।';

  @override
  String get feedCheckTitle => 'संदेश जाँचें';

  @override
  String get feedCheckIntro =>
      'WhatsApp पर GR या योजना का संदेश आया? यहाँ पेस्ट करें, हम आधिकारिक GR ढूँढेंगे।';

  @override
  String get feedCheckHint => 'संदेश यहाँ पेस्ट करें';

  @override
  String get feedCheckPaste => 'पेस्ट करें';

  @override
  String get feedCheckButton => 'जाँचें';

  @override
  String get feedCheckPrivacy =>
      'यह पाठ केवल जाँच के लिए इस्तेमाल होता है; यह फ़ोन पर सहेजा नहीं जाता।';

  @override
  String get feedCheckFailed =>
      'जाँच के लिए इंटरनेट चाहिए; इंटरनेट आने पर फिर कोशिश करें।';

  @override
  String get feedCheckOfficial => 'आधिकारिक GR मिला';

  @override
  String get feedCheckPossible => 'शायद जुड़े हुए आधिकारिक संदेश';

  @override
  String get feedCheckNoMatch => 'मेल खाता आधिकारिक संदेश नहीं मिला।';

  @override
  String get feedCheckPortal => 'कुछ करने से पहले आधिकारिक पोर्टल जाँचें।';

  @override
  String get shareAction => 'भेजें';

  @override
  String get speakAction => 'पढ़कर सुनाएँ';

  @override
  String get speakUnavailable =>
      'पढ़कर सुनाने के लिए फ़ोन पर इस भाषा की आवाज़ चाहिए।';

  @override
  String shareSentFrom(String app) {
    return '$app ऐप से भेजा गया';
  }

  @override
  String shareSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String marketShareLine(String market, String price) {
    return '$market: $price प्रति क्विंटल';
  }

  @override
  String taskDueOn(String date) {
    return 'तारीख: $date';
  }

  @override
  String get taskDetails => 'काम की जानकारी';

  @override
  String tasksTodayShare(String date) {
    return 'आज के काम ($date)';
  }

  @override
  String get loadingLabel => 'जानकारी आ रही है';

  @override
  String get accountSwitchTitle => 'दूसरे खाते के रिकॉर्ड';

  @override
  String get accountSwitchBody =>
      'इस फ़ोन पर दूसरे खाते के रिकॉर्ड हैं। आगे बढ़ने पर वे इस फ़ोन से हटा दिए जाएँगे (सर्वर पर सुरक्षित रहेंगे) और आपके रिकॉर्ड डाउनलोड होंगे।';

  @override
  String get accountSwitchContinue => 'आगे बढ़ें';

  @override
  String get accountBlockedTitle => 'इस फ़ोन पर भेजने बाकी रिकॉर्ड';

  @override
  String accountBlockedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'पिछले खाते के $count रिकॉर्ड अभी भेजने बाकी हैं।',
      one: 'पिछले खाते का 1 रिकॉर्ड अभी भेजना बाकी है।',
    );
    return '$_temp0 उस खाते से फिर से लॉगिन करें और इंटरनेट चालू रखकर ऐप खोलें ताकि वे भेजे जाएँ। फिर इस खाते से लॉगिन करें।';
  }

  @override
  String accountPreviousPhone(String phone) {
    return 'पिछला खाता: $phone';
  }

  @override
  String get insuranceTitle => 'फसल बीमा';

  @override
  String get insuranceEmpty =>
      'इस बाग के लिए लिया हुआ फसल बीमा दर्ज करें, या नुकसान होने पर क्लेम किट खोलें।';

  @override
  String get insurancePoliciesNone => 'पहली बीमा पॉलिसी दर्ज करें।';

  @override
  String get insuranceAdd => 'बीमा दर्ज करें';

  @override
  String get insuranceEdit => 'बीमा बदलें';

  @override
  String get insuranceScheme => 'योजना';

  @override
  String get insuranceSchemePmfby => 'प्रधानमंत्री फसल बीमा (PMFBY)';

  @override
  String get insuranceSchemeRwbcis => 'मौसम आधारित फल फसल बीमा (RWBCIS)';

  @override
  String get insuranceSchemeOther => 'अन्य';

  @override
  String get insuranceSchemeUnknown => 'जाँचना है';

  @override
  String get insuranceSeason => 'बहार';

  @override
  String get insuranceSeasonAmbia => 'अंबिया बहार';

  @override
  String get insuranceSeasonMrig => 'मृग बहार';

  @override
  String get insuranceSeasonYear => 'वर्ष (वैकल्पिक)';

  @override
  String get insuranceInsurer => 'बीमा कंपनी (वैकल्पिक)';

  @override
  String get insurancePolicyNumber => 'पॉलिसी या आवेदन नंबर (वैकल्पिक)';

  @override
  String get insuranceSumInsured => 'बीमित राशि ₹ (वैकल्पिक)';

  @override
  String get insurancePremium => 'भरा गया प्रीमियम ₹ (वैकल्पिक)';

  @override
  String get insuranceAmountsHint => 'राशि केवल रसीद पर छपी हुई ही लिखें।';

  @override
  String get insuranceEnrolledOn => 'नामांकन की तारीख';

  @override
  String get insuranceNotSet => 'भरनी है';

  @override
  String get insuranceNote => 'नोट (वैकल्पिक)';

  @override
  String insurancePolicyNo(String number) {
    return 'नं. $number';
  }

  @override
  String insuranceEnrolled(String date) {
    return 'नामांकन $date';
  }

  @override
  String insurancePremiumLine(String amount) {
    return 'भरा प्रीमियम $amount';
  }

  @override
  String insuranceSumLine(String amount) {
    return 'बीमित राशि $amount';
  }

  @override
  String insuranceDeadline(String date) {
    return 'नामांकन की अंतिम तिथि: $date';
  }

  @override
  String get insuranceDeadlineNote =>
      'प्रकाशित आधिकारिक सूचना के अनुसार। कुछ करने से पहले सूचना देखें।';

  @override
  String get insuranceDeletePolicy => 'बीमा हटाएँ';

  @override
  String get insuranceDeleteConfirm => 'यह बीमा रिकॉर्ड हटाएँ?';

  @override
  String get insuranceClaims => 'नुकसान रिकॉर्ड';

  @override
  String insuranceClaimLine(String date, String count) {
    return 'नुकसान $date · फ़ोटो: $count';
  }

  @override
  String get claimKitTitle => 'क्लेम किट';

  @override
  String get claimKitFromAlert => 'नुकसान की फ़ोटो · क्लेम किट';

  @override
  String get claimKitPlot => 'बाग';

  @override
  String get claimKitPickPlot => 'बाग चुनें';

  @override
  String get claimKitDate => 'नुकसान की तारीख';

  @override
  String get claimKitPhotos => 'नुकसान की फ़ोटो (तारीख और GPS जुड़ते हैं)';

  @override
  String get claimKitNoPhotos => 'नुकसान की फ़ोटो लें; वे यहाँ दिखेंगी।';

  @override
  String get claimKitNoGps => 'GPS के बिना';

  @override
  String get claimKitRemovePhoto => 'फ़ोटो हटाएँ';

  @override
  String get claimKitNote => 'क्या हुआ? (वैकल्पिक)';

  @override
  String get claimKitChecklist => 'जाँच सूची';

  @override
  String get claimKitCheckPolicy =>
      'यह केवल सामान्य जानकारी है। नियम और समय-सीमा पॉलिसी के अनुसार अलग होते हैं: अपनी पॉलिसी, बैंक या CSC से जाँचें।';

  @override
  String get claimCheckInform72h =>
      'नुकसान की सूचना बीमा कंपनी, अपने बैंक या CSC केंद्र को जितनी जल्दी हो सके दें; कितने दिनों में बताना है, यह अपनी पॉलिसी में देखें।';

  @override
  String get claimCheckPhotos =>
      'नुकसान की तारीख वाली फ़ोटो बाग की अलग-अलग तरफ़ से लें।';

  @override
  String get claimCheckPanchnama =>
      'पंचनामा (नुकसान सर्वे) करवाएँ और उसकी कॉपी संभाल कर रखें।';

  @override
  String get claimCheckPolicyCopy =>
      'पॉलिसी या आवेदन की रसीद और बैंक पासबुक की कॉपी तैयार रखें।';

  @override
  String get claimCheckAcknowledgement =>
      'सूचना देते समय मिला शिकायत / डॉकेट नंबर लिख कर रखें।';

  @override
  String get claimCheckKeepFruit =>
      'सर्वे होने तक नुकसान वाले फल और पेड़ वैसे ही रखें; अलग से कहा जाए तो उसके अनुसार करें।';

  @override
  String get claimKitShare => 'PDF भेजें';

  @override
  String get claimKitShareFailed => 'कृपया PDF फिर से बनाएँ।';

  @override
  String get claimKitDelete => 'नुकसान रिकॉर्ड हटाएँ';

  @override
  String get claimKitDeleteConfirm =>
      'यह नुकसान रिकॉर्ड और इसकी फ़ोटो इस फ़ोन से हटाएँ?';

  @override
  String get claimKitLocalOnly =>
      'फ़ोटो और नोट इसी फ़ोन पर रहते हैं। ज़रूरत हो तो PDF भेजें।';

  @override
  String get claimPdfTitle => 'फसल नुकसान रिकॉर्ड';

  @override
  String get claimPdfPlotGps => 'बाग का स्थान (GPS)';

  @override
  String get claimPdfNoGps => 'दर्ज करना है';

  @override
  String get claimPdfPolicy => 'बीमा';

  @override
  String get claimPdfPhotos => 'फ़ोटो';

  @override
  String get claimPdfNote => 'नोट';

  @override
  String get claimPdfDone => 'किया';

  @override
  String get claimPdfNotDone => 'बाकी';

  @override
  String claimPdfMade(String date) {
    return '$date को बनाया। किसान का रखा रिकॉर्ड, बीमा कंपनी का दस्तावेज़ नहीं।';
  }

  @override
  String get insurancePolicies => 'बीमा रिकॉर्ड';

  @override
  String get labTestsTitle => 'मिट्टी, पानी और पत्ती जाँच';

  @override
  String get labTestsEmpty =>
      'अपनी लैब रिपोर्ट या मृदा स्वास्थ्य कार्ड से इस बाग़ की पहली जाँच दर्ज करें।';

  @override
  String get labTestAdd => 'जाँच जोड़ें';

  @override
  String get labTestEdit => 'जाँच बदलें';

  @override
  String get labTestType => 'किसकी जाँच';

  @override
  String get labTestTypeSoil => 'मिट्टी';

  @override
  String get labTestTypeWater => 'पानी';

  @override
  String get labTestTypeLeaf => 'पत्ती';

  @override
  String get labTestTitleSoil => 'मिट्टी जाँच';

  @override
  String get labTestTitleWater => 'पानी जाँच';

  @override
  String get labTestTitleLeaf => 'पत्ती जाँच';

  @override
  String get labTestSampledOn => 'नमूना लेने की तारीख';

  @override
  String get labTestReportedOn => 'रिपोर्ट की तारीख';

  @override
  String get labTestLab => 'लैब का नाम';

  @override
  String get labTestReadings => 'रिपोर्ट के मान';

  @override
  String get labTestReadingsHint =>
      'हर मान वैसा ही लिखें जैसा रिपोर्ट में लिखा है।';

  @override
  String get labTestParameter => 'नाम (pH, EC …)';

  @override
  String get labTestValue => 'मान';

  @override
  String get labTestUnit => 'इकाई';

  @override
  String get labTestAddReading => 'मान जोड़ें';

  @override
  String get labTestRemoveReading => 'यह मान हटाएँ';

  @override
  String get labTestSuggestions =>
      'अधिकतर रिपोर्ट के नाम (जोड़ने के लिए दबाएँ)';

  @override
  String get labTestReadingIncomplete => 'नाम और मान दोनों लिखें';

  @override
  String get labTestNote => 'टिप्पणी';

  @override
  String get labTestReport => 'रिपोर्ट की फोटो या फ़ाइल';

  @override
  String get labTestReportFile => 'फ़ाइल (PDF)';

  @override
  String get labTestReportRemove => 'हटाएँ';

  @override
  String get labTestReportFailed => 'रिपोर्ट दोबारा जोड़कर देखें।';

  @override
  String get labTestReportLocal => 'रिपोर्ट इसी फ़ोन पर रहती है।';

  @override
  String get labTestReportMissing => 'रिपोर्ट की फ़ाइल दोबारा जोड़ें।';

  @override
  String get labTestShareReport => 'रिपोर्ट भेजें';

  @override
  String get labTestAskExpert =>
      'यह रिपोर्ट किसी विशेषज्ञ से पढ़वाएँ; वे आँकड़ों का अर्थ समझाएँगे।';

  @override
  String get labTestNextDue => 'अगली जाँच (याद)';

  @override
  String get labTestNextDueHint => 'याद दिलाने वाला काम चाहिए तभी तारीख चुनें।';

  @override
  String get labTestNextDueClear => 'याद की तारीख हटाएँ';

  @override
  String get labTestReminderSoil => 'अगली मिट्टी जाँच';

  @override
  String get labTestReminderWater => 'अगली पानी जाँच';

  @override
  String get labTestReminderLeaf => 'अगली पत्ती जाँच';

  @override
  String get labTestDelete => 'जाँच हटाएँ';

  @override
  String get labTestDeleteConfirm =>
      'यह जाँच और उसकी रिपोर्ट इस फ़ोन से हटाएँ?';

  @override
  String labTestSampledLine(String date) {
    return 'नमूना $date';
  }

  @override
  String labTestReportedLine(String date) {
    return 'रिपोर्ट $date';
  }

  @override
  String labTestLabLine(String name) {
    return 'लैब: $name';
  }

  @override
  String labTestValuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मान',
      one: '1 मान',
      zero: 'आँकड़े लिखें',
    );
    return '$_temp0';
  }

  @override
  String get labTestNoValues => 'रिपोर्ट के आँकड़े यहाँ लिखें।';

  @override
  String get labTestEditAction => 'बदलें';

  @override
  String get schemesTitle => 'योजनाएँ और दस्तावेज़';

  @override
  String get schemesHomeHint =>
      'कौन आवेदन कर सकता है, कौन से दस्तावेज़ तैयार रखें';

  @override
  String get schemesIntro =>
      'तैयारी के लिए सामान्य जानकारी। राशि और शर्तें आधिकारिक पेज पर देखें, फिर आवेदन करें।';

  @override
  String get schemeVisitSetu =>
      'आवेदन, दस्तावेज़ और अधिक जानकारी के लिए अपने नज़दीकी सेतु केंद्र (आपले सरकार सेवा केंद्र / CSC) पर जाएँ।';

  @override
  String get schemeWho => 'कौन आवेदन कर सकता है';

  @override
  String get schemeDocuments => 'आमतौर पर लगने वाले दस्तावेज़';

  @override
  String get schemeDocumentsHint =>
      'जो पहले से है उस पर निशान लगाएँ। सिर्फ़ इसी फ़ोन पर रहता है।';

  @override
  String schemeDocsReady(int have, int total) {
    return '$total में से $have तैयार';
  }

  @override
  String get schemeNotConfirmed => 'आधिकारिक पेज पर एक बार पुष्टि करें';

  @override
  String get schemeWhereToApply => 'कहाँ आवेदन करें';

  @override
  String schemeSources(String date) {
    return 'स्रोत ($date को जाँचे)';
  }

  @override
  String get schemeFeedItems => 'संबंधित सरकारी सूचनाएँ';

  @override
  String schemeShareDocs(String scheme) {
    return '$scheme के लिए दस्तावेज़:';
  }

  @override
  String get schemeShareHave => 'है';

  @override
  String get schemeShareMissing => 'लेना है';

  @override
  String get lookalikesTitle => 'मिलते-जुलते लक्षण';

  @override
  String get lookalikesOpen => 'मिलते-जुलते लक्षण';

  @override
  String get lookalikesIntro =>
      'बाग की कई समस्याएँ एक जैसी दिखती हैं; ये कार्ड जो दिखता है उसे ठीक से बताने में मदद करते हैं।';

  @override
  String get lookalikesSee => 'क्या दिख सकता है';

  @override
  String get lookalikesConfusedWith => 'इससे मिलता-जुलता';

  @override
  String get lookalikesConfirm => 'पुष्टि कौन कर सकता है';

  @override
  String get lookalikesCheckLine =>
      'पक्का करना है? फ़ोटो लें, निरीक्षण रिकॉर्ड में लिखें और फ़ैसले से पहले लैब या विशेषज्ञ से जाँच करवाएँ।';

  @override
  String get lookalikesLogThis => 'निरीक्षण रिकॉर्ड में लिखें';

  @override
  String get lookalikesFindLab => 'लैब / विशेषज्ञ खोजें';

  @override
  String get lookalikesSources => 'स्रोत';

  @override
  String get lookalikesDraft => 'मसौदा: एक स्रोत अभी जाँचना बाकी है';

  @override
  String get lookalikesEmpty => 'कार्ड यहाँ दिखेंगे।';

  @override
  String get labsTitle => 'लैब और विशेषज्ञ';

  @override
  String get labsOpen => 'लैब और विशेषज्ञ';

  @override
  String get marketDirectoryTitle => 'मंडी और खरीदार';

  @override
  String get marketDirectoryOpen => 'मंडी और खरीदार';

  @override
  String get directoryAll => 'सभी';

  @override
  String get directoryUnverified => 'आधिकारिक पेज पर एक बार पुष्टि करें';

  @override
  String get directoryCopyNumber => 'नंबर कॉपी करें';

  @override
  String get directoryNumberCopied => 'नंबर कॉपी हो गया';

  @override
  String get directoryCopyLink => 'लिंक कॉपी करें';

  @override
  String directoryWebPage(Object url) {
    return 'वेब पेज: $url';
  }

  @override
  String directoryPhone(Object phone) {
    return 'फ़ोन: $phone';
  }

  @override
  String directoryDetailsFrom(Object url) {
    return 'जानकारी का स्रोत: $url';
  }

  @override
  String directoryChecked(Object date) {
    return 'जाँचा $date';
  }

  @override
  String get directoryCheckLine =>
      'जानकारी दिखाई गई तारीख को आधिकारिक पेजों से ली गई है। जाने से पहले फ़ोन करके या पेज देखकर पुष्टि करें।';

  @override
  String get directoryEmpty => 'जानकारी यहाँ दिखेगी।';

  @override
  String get directoryKindResearch => 'अनुसंधान संस्थान';

  @override
  String get directoryKindUniversity => 'कृषि विश्वविद्यालय';

  @override
  String get directoryKindKvk => 'कृषि विज्ञान केंद्र';

  @override
  String get directoryKindSoilLab => 'मिट्टी जाँच';

  @override
  String get directoryKindPortal => 'भाव और आवक';

  @override
  String get directoryKindApmc => 'मंडी समिति (APMC)';

  @override
  String get directoryKindExport => 'निर्यात';

  @override
  String get directoryKindProcessor => 'प्रसंस्करण';

  @override
  String get exportInfoTitle => 'निर्यात जानकारी';

  @override
  String get exportInfoNote =>
      'जानकारी के लिए। निर्यात का सौदा आपके और निर्यातक के बीच।';

  @override
  String get exportSectionDestinations => 'फल कहाँ जाता है';

  @override
  String get exportSectionSeason => 'बहार और निर्यात (निर्यातक के अनुसार)';

  @override
  String get exportSectionSpecs => 'ख़रीदारों की माँग (बताए अनुसार)';

  @override
  String get exportSectionRules => 'किसान पर लागू नियम';

  @override
  String get exportLinksTitle => 'आधिकारिक पेज';

  @override
  String get exportRecordTitle => 'निर्यात रिकॉर्ड';

  @override
  String get exportRecordAction => 'निर्यात रिकॉर्ड (PDF) बनाएँ';

  @override
  String get exportRecordPlot => 'बाग';

  @override
  String get exportRecordBahar => 'बहार';

  @override
  String get exportRecordAllBahars => 'सभी छिड़काव';

  @override
  String exportRecordCount(String count) {
    return '$count छिड़काव';
  }

  @override
  String exportRecordLastPhi(String date) {
    return 'आख़िरी PHI $date को समाप्त';
  }

  @override
  String get exportRecordShare => 'PDF शेयर करें';

  @override
  String get exportRecordNoPlot =>
      'पहले बाग जोड़ें; उसका छिड़काव रिकॉर्ड यहाँ दिखेगा।';

  @override
  String get exportRecordEmpty =>
      'इस बहार के छिड़काव दर्ज होने पर यहाँ दिखेंगे।';

  @override
  String get exportRecordDate => 'तारीख';

  @override
  String get exportRecordProduct => 'दवा · घटक · मात्रा';

  @override
  String get exportRecordLabel => 'लेबल जाँच';

  @override
  String get exportRecordPhiEnd => 'PHI समाप्त';

  @override
  String get exportLabelListed => 'इस फसल के लिए लेबल पर';

  @override
  String get exportLabelCheck => 'लेबल जाँचें';

  @override
  String exportRecordMade(String date) {
    return '$date को किसान के अपने छिड़काव रिकॉर्ड से बना।';
  }

  @override
  String get exportRecordFooter => 'जानकारी हेतु रिकॉर्ड, प्रमाणपत्र नहीं।';

  @override
  String fairPriceMandi(Object date, Object market, Object price) {
    return '$market मंडी, $date: मॉडल भाव $price प्रति क्विंटल';
  }

  @override
  String fairPriceAbove(Object percent) {
    return 'आपका भाव मंडी के मॉडल भाव से $percent% ज़्यादा है।';
  }

  @override
  String fairPriceBelow(Object percent) {
    return 'आपका भाव मंडी के मॉडल भाव से $percent% कम है।';
  }

  @override
  String get fairPriceSame => 'आपका भाव मंडी के मॉडल भाव के बराबर है।';

  @override
  String get loginPhoneUnavailable => 'अभी Google से लॉगिन करें';

  @override
  String get loginResendOtp => 'OTP फिर से भेजें';

  @override
  String loginResendIn(int seconds) {
    return '$seconds सेकंड में OTP फिर से माँग सकते हैं';
  }

  @override
  String get loginOtpResent => 'नया OTP भेज दिया गया है';

  @override
  String get loginChangeNumber => 'नंबर बदलें';

  @override
  String get loginTitleGoogle => 'अपने Google खाते से शुरू करें';

  @override
  String get netOffline => 'इंटरनेट जाँचें और फिर से कोशिश करें';

  @override
  String get netServer => 'सर्वर अभी व्यस्त है; थोड़ी देर बाद फिर कोशिश करें';

  @override
  String get netSignedOut => 'नई जानकारी के लिए फिर से लॉगिन करें';

  @override
  String get netRetry => 'फिर से कोशिश करें';

  @override
  String get signInAgain => 'लॉगिन करें';

  @override
  String get syncServerBanner =>
      'आपकी एंट्री फ़ोन पर सुरक्षित हैं; सर्वर तैयार होते ही अपने आप भेजी जाएँगी।';

  @override
  String get syncSignedOutBanner => 'एंट्री भेजने के लिए फिर से लॉगिन करें';

  @override
  String syncRejectedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एंट्री जाँचनी हैं',
      one: '1 एंट्री जाँचनी है',
    );
    return '$_temp0';
  }

  @override
  String get syncReview => 'देखें';

  @override
  String get syncRejectedTitle => 'जाँचने वाली एंट्री';

  @override
  String get syncRejectedHelp =>
      'हर एंट्री फिर से भेजें या इस सूची से हटाएँ; फ़ोन पर जानकारी वैसी ही रहती है।';

  @override
  String get syncRejectedDone => 'सभी एंट्री ठीक हैं';

  @override
  String get syncResend => 'फिर से भेजें';

  @override
  String get syncDelete => 'हटाएँ';

  @override
  String syncEntryName(String entity) {
    String _temp0 = intl.Intl.selectLogic(entity, {
      'farmer_profile': 'प्रोफ़ाइल',
      'plot': 'बाग',
      'bahar_cycle': 'बहार',
      'expense': 'खर्च',
      'income': 'बिक्री',
      'spray_record': 'छिड़काव',
      'input_record': 'खाद / इनपुट',
      'irrigation_record': 'सिंचाई',
      'harvest_record': 'तुड़ाई',
      'labour_record': 'मज़दूरी',
      'farm_task': 'काम',
      'scouting_record': 'निरीक्षण',
      'insurance_policy': 'बीमा',
      'lab_test': 'लैब जाँच',
      'other': 'एंट्री',
    });
    return '$_temp0';
  }

  @override
  String get refreshOffline => 'इंटरनेट जाँचें';

  @override
  String get refreshServer => 'सर्वर अभी व्यस्त है';

  @override
  String get homeQuickTitle => 'झटपट काम';

  @override
  String get moreTitle => 'सभी सुविधाएँ';

  @override
  String get moreSectionRecords => 'बाग के रिकॉर्ड';

  @override
  String get moreSectionWork => 'काम और मौसम';

  @override
  String get moreSectionHelp => 'जानकारी और मदद';

  @override
  String get moreSectionMarket => 'मंडी';

  @override
  String get moreSectionGovt => 'सरकारी मदद';

  @override
  String get moreSectionAccount => 'मेरा खाता';

  @override
  String get plotTileBahar => 'बहार';

  @override
  String get baharRecordsMenu => 'रिकॉर्ड';

  @override
  String tasksDoneShow(String count) {
    return 'दिखाएँ ($count)';
  }

  @override
  String get tasksDoneHide => 'छिपाएँ';

  @override
  String tasksDoneLatest(String count) {
    return 'आख़िरी $count दिखा रहे हैं';
  }

  @override
  String get requiredPlotName => 'बाग का नाम लिखें';

  @override
  String get requiredTaskTitle => 'क्या करना है, लिखें';

  @override
  String get requiredWorker => 'मज़दूर का नाम लिखें';

  @override
  String get requiredSprayProduct => 'दवा का नाम लिखें';

  @override
  String get requiredInputProduct => 'उत्पाद का नाम लिखें';

  @override
  String get requiredBuyer => 'व्यापारी का नाम लिखें';

  @override
  String get claimKitGpsOk => 'जगह जुड़ी';

  @override
  String priceChangeUp(String pct) {
    return 'पिछले सप्ताह से $pct बढ़त';
  }

  @override
  String priceChangeDown(String pct) {
    return 'पिछले सप्ताह से $pct गिरावट';
  }

  @override
  String generalInfoSource(String source, String date) {
    return 'स्रोत: $source · जाँचा $date';
  }

  @override
  String get sourcesShow => 'स्रोत देखें';

  @override
  String sourcesShowCount(String count) {
    return 'स्रोत देखें ($count)';
  }

  @override
  String get sourcesHide => 'स्रोत छिपाएँ';

  @override
  String sourcesChecked(String date) {
    return 'पढ़ा $date';
  }

  @override
  String get labelReadNote => 'छिड़काव से पहले पैकेट पर लिखा लेबल पढ़ें।';

  @override
  String baharSuggestedWindow(String from, String to) {
    return 'सुझाया समय: $from – $to';
  }

  @override
  String get baharNoWindow =>
      'अपनी तारीख दर्ज करें: स्रोतों में केवल दूसरे चरणों का समय दिया है';

  @override
  String get baharFillSuggested => 'सुझाई तारीखें भरें';

  @override
  String get baharSuggestedHelp =>
      'सुझाया समय सार्वजनिक स्रोतों से है। अपने बाग के अनुसार कोई भी तारीख बदलें।';

  @override
  String get baharStressBySoil =>
      'तनाव कितने दिन देना है यह मिट्टी पर निर्भर है: हल्की मिट्टी में कम दिन, भारी मिट्टी में ज़्यादा।';

  @override
  String get practicesSee => 'क्या दिखता है';

  @override
  String get practicesWhen => 'कब आता है';

  @override
  String get figureGum => 'गोंद निकलता है';

  @override
  String get figureWetPatches => 'पानी भरे धब्बे';

  @override
  String get figureBarkPeels => 'छाल खड़ी पट्टियों में उखड़ती है';

  @override
  String get figureYellowLeaves => 'पीली पत्तियाँ';

  @override
  String figureWidthCm(String cm) {
    return '$cm सें.मी.';
  }

  @override
  String figureDepthCm(String cm) {
    return '$cm सें.मी. गहरी';
  }

  @override
  String get figureDrainsAway => 'पानी पेड़ों से दूर बह जाता है';

  @override
  String get figureDry => 'सूखा';

  @override
  String get figureWaterHere => 'पानी यहाँ';

  @override
  String get figureTopView => 'ऊपर से दृश्य';

  @override
  String get figureDeadPart => 'सूखा भाग';

  @override
  String get figureCutHere => 'यहाँ काटें';

  @override
  String figureHealthyCm(String cm) {
    return '$cm सें.मी. स्वस्थ भाग सहित';
  }

  @override
  String figureSunDays(String from, String to) {
    return '$from–$to दिन धूप';
  }

  @override
  String get figureCutRotten => 'सड़ी जड़ें काटें';

  @override
  String get figureWithBand => 'स्वस्थ पट्टी सहित हटाएँ';

  @override
  String get figureDiseasedBark => 'रोगी छाल';

  @override
  String get figureRains => 'बरसात';

  @override
  String get figureBeforeRains => 'बरसात से पहले';

  @override
  String get figureAfterRains => 'बरसात के बाद';

  @override
  String figureInnerRingCm(String cm) {
    return 'भीतरी घेरा $cm सें.मी.';
  }

  @override
  String get figureYellowTrap => 'पीला चिपचिपा ट्रैप';

  @override
  String figureHeightM(String m) {
    return 'ज़मीन से $m मी.';
  }

  @override
  String get figureBudUnion => 'आँख का जोड़';

  @override
  String figureHeightRangeCm(String from, String to) {
    return 'ज़मीन से $from–$to सें.मी.';
  }

  @override
  String figureStickyBand(String cm) {
    return '$cm सें.मी. चिपचिपी पट्टी';
  }

  @override
  String get figureAnts => 'चींटियाँ';

  @override
  String get figureLureTrap => 'ल्यूर ट्रैप';

  @override
  String figureRenewDays(String from, String to) {
    return 'ल्यूर हर $from–$to दिन में बदलें';
  }

  @override
  String get figureShadyFirst => 'छायादार तरफ़: पहले यहाँ देखें';

  @override
  String get figureSunnySide => 'धूप की तरफ़';

  @override
  String get figureOpenCentre => 'बीच खुला: हवा चलती है';

  @override
  String get figureCutCrowded => 'घनी टहनियाँ काटें';

  @override
  String get figureRootZone => 'सक्रिय जड़ क्षेत्र';

  @override
  String get figureManureHere => 'खाद यहाँ, मिट्टी से ढकें';

  @override
  String get figCankerSpots => 'उभरे, खुरदरे, भूरे धब्बे';

  @override
  String get figCankerHalo => 'पीला घेरा';

  @override
  String get figCankerFruit => 'फल पर: धब्बे छिलके तक रहते हैं';

  @override
  String get figMildewPowder => 'सफ़ेद चूर्ण';

  @override
  String get figMildewCurl => 'पत्तियाँ ऐंठती और मुड़ती हैं';

  @override
  String get figAnthPatch => 'हल्का भूरा धब्बा, बैंगनी किनारा';

  @override
  String get figAnthDots => 'बारीक काले बिंदु';

  @override
  String get figAnthTwig => 'मरी टहनी: चाँदी जैसी धूसर';

  @override
  String get figGreeningLeaf => 'हरे द्वीपों वाली पीली पत्ती';

  @override
  String get figGreeningFruit => 'फल छोटा, एक तरफ़ बढ़ा, हरा';

  @override
  String get figPsyllaNymphs => 'सिरों पर पीले-नारंगी शिशु';

  @override
  String get figPsyllaThreads => 'सफ़ेद मोमी धागे';

  @override
  String get figPsyllaCurl => 'नई पत्तियाँ मुड़ती हैं';

  @override
  String get figAphidColony => 'काले या भूरे माहू की कॉलोनियाँ';

  @override
  String get figAphidCup => 'कटोरी जैसी, सिकुड़ी पत्तियाँ';

  @override
  String get figMealyClusters => 'सफ़ेद, रुई जैसे गुच्छे';

  @override
  String get figSootyMould => 'काली फफूंद';

  @override
  String get figMinerMines => 'चाँदी जैसी, टेढ़ी-मेढ़ी सुरंगें';

  @override
  String get figMinerDistort => 'पत्ती बिगड़ती, सिकुड़ती है';

  @override
  String get figMitesVeins => 'नसों के साथ हल्के पीले हिस्से';

  @override
  String get figMitesWeb => 'बारीक जाला: धूल भरी पत्तियाँ';

  @override
  String get figMitesRind => 'खुरदरा छिलका (रसेटिंग)';

  @override
  String get figThripsRing => 'डंठल के चारों ओर छल्ले जैसा निशान';

  @override
  String get figThripsPatches => 'छिलके पर अनियमित धब्बे';

  @override
  String get figHeatSummer => 'गर्मी का मौसम';

  @override
  String get figHeatDrop => 'फल गिरने की दूसरी लहर';

  @override
  String get practicesScout => 'निगरानी कैसे करें';

  @override
  String get practicesActionLevel => 'सीमा-स्तर';

  @override
  String get practicesNoActionLevel =>
      'सीमा-स्तर के लिए अपने KVK से पूछें; पढ़े गए स्रोतों में इसका उल्लेख अभी मिलना बाकी है।';

  @override
  String get practicesWhatToDo => 'क्या करें';

  @override
  String get practicesBioTitle => 'जैविक उपाय';

  @override
  String get practicesBioRegistered =>
      'पंजीकृत उत्पाद: मात्रा केवल उसके लेबल से।';

  @override
  String get practicesBioHome => 'घर पर बना, प्रकाशित विधि अनुसार';

  @override
  String get practicesHowToPrepare => 'कैसे तैयार करें';

  @override
  String get practicesLabelLink => 'लेबल अनुसार स्वीकृत दवाएँ';

  @override
  String get practicesKnowledgeCard => 'ज्ञान कार्ड';

  @override
  String get knowledgeTitle => 'ज्ञान कार्ड';

  @override
  String get knowledgeIntro =>
      'बहार, कीट, रोग, पोषण, पानी और तुड़ाई पर संक्षिप्त जानकारी। उत्पाद और मात्रा लेबल स्क्रीन पर देखें।';

  @override
  String get knowledgeEmpty => 'फ़ोन ऑनलाइन होने पर ज्ञान कार्ड यहाँ दिखेंगे।';

  @override
  String get knowledgeWarnings => 'ध्यान रखें';

  @override
  String get knowledgeCallExpert => 'विशेषज्ञ से कब पूछें';

  @override
  String get knowledgeSources => 'स्रोत';

  @override
  String get practicesSourcesLineAll =>
      'स्रोत: NHB, NIPHM, ICAR, पीडीकेवी, MPKV, TNAU और अन्य। हर पद्धति के नीचे विवरण।';

  @override
  String get schemeGeneralSource => 'अंत में दिए गए आधिकारिक पेज';

  @override
  String get schemeFacts => 'आधिकारिक पेज की मुख्य जानकारी';

  @override
  String schemeFactSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get labNormsTitle => 'मृदा स्वास्थ्य कार्ड की श्रेणियाँ';

  @override
  String get labNormsHint =>
      'अपनी रिपोर्ट का आंकड़ा इन श्रेणियों से मिलाकर देखें।';

  @override
  String get labelInfoChemical => 'रासायनिक';

  @override
  String get labelInfoBio => '🌿 जैविक (पंजीकृत जैव-कीटनाशक)';

  @override
  String labelInfoDilution(String value) {
    return 'लेबल पर पानी: $value लीटर प्रति हेक्टेयर';
  }

  @override
  String labelInfoDilutionPrinted(String value) {
    return 'लेबल पर पानी: $value';
  }

  @override
  String labelInfoBrands(String names) {
    return 'बाज़ार के नाम (वर्णक्रम में, केवल सूची): $names';
  }

  @override
  String get labelInfoMakerPage => 'निर्माता का उत्पाद पेज';

  @override
  String labelInfoTargetPrinted(String target) {
    return 'लेबल पर कीट/रोग: $target';
  }

  @override
  String labelInfoPage(String page) {
    return 'स्रोत में पृष्ठ: $page';
  }

  @override
  String labelInfoNoClaim(String target) {
    return '$target: नींबू वर्गीय फसलों के लिए कोई पंजीकृत लेबल जानकारी नहीं।';
  }

  @override
  String get labelInfoBanned => 'मान्य सूची से बाहर';

  @override
  String get labelInfoRestricted => 'इस फसल के लिए मान्य सूची से बाहर';

  @override
  String get labelInfoAllTargets => 'सभी कीट और रोग';

  @override
  String labelInfoOpenFor(String target) {
    return 'लेबल जानकारी: $target';
  }

  @override
  String labelInfoSources(String count) {
    return 'जानकारी के स्रोत ($count)';
  }

  @override
  String get labelInfoOpenDetails => 'लेबल की पूरी जानकारी देखने के लिए दबाएँ';

  @override
  String get labelInfoDetailsTitle => 'लेबल की पूरी जानकारी';

  @override
  String get noPlotTitle => 'पहले अपना बाग जोड़ें';

  @override
  String get noPlotBody =>
      'हर रिकॉर्ड बाग के अनुसार रखा जाता है। एक बार बाग जोड़कर सहेजें, फिर यह तुरंत खुलेगा।';

  @override
  String plotAddressNear(String place) {
    return 'पास की जगह: $place';
  }

  @override
  String plotAddressDistrict(String district) {
    return 'ज़िला $district';
  }

  @override
  String get plotAddressLooking => 'गाँव का नाम खोज रहे हैं…';

  @override
  String get plotAddressMissing =>
      'जगह सहेजी जाएगी। गाँव का नाम देखने के लिए इंटरनेट चालू रखकर \'जगह फिर से लें\' दबाएँ।';

  @override
  String get onboardingNameHint => 'अपना नाम हिंदी में लिखें (उदा. अभिषेक)';

  @override
  String get nameScriptPromptTitle => 'अपना नाम हिंदी में लिखें';

  @override
  String get nameScriptFieldLabel => 'नाम (उदा. अभिषेक)';

  @override
  String get nameScriptLater => 'बाद में';

  @override
  String get adminMlQueue => 'जाँच कतार';

  @override
  String get adminMlTags => 'रेटिंग टैग';

  @override
  String get adminMlAll => 'सभी';

  @override
  String get adminMlBuyer => 'व्यापारी';

  @override
  String get adminMlBroker => 'दलाल';

  @override
  String get adminMlProvider => 'सेवा प्रदाता';

  @override
  String get adminMlQueueEmpty => 'सभी की जाँच हो चुकी है';

  @override
  String adminMlWaitingSince(String date) {
    return '$date से प्रतीक्षा में';
  }

  @override
  String get adminMlFields => 'दी गई जानकारी';

  @override
  String get adminMlDocuments => 'दस्तावेज़';

  @override
  String get adminMlNoDocuments => 'भेजे गए दस्तावेज़ यहाँ दिखेंगे';

  @override
  String adminMlDocument(int n) {
    return 'दस्तावेज़ $n';
  }

  @override
  String get adminMlReject => 'अस्वीकार करें';

  @override
  String get adminMlRejectTitle => 'कारण देकर अस्वीकार करें';

  @override
  String get adminMlBadgeNote =>
      'मंज़ूरी के बाद ही सत्यापित चिह्न दिखता है; बाद में अस्वीकार करने पर तुरंत हट जाता है।';

  @override
  String get adminMlStatusPending => 'प्रतीक्षा में';

  @override
  String get adminMlStatusApproved => 'सत्यापित';

  @override
  String get adminMlStatusRejected => 'अस्वीकृत';

  @override
  String adminMlCheckedBy(String who) {
    return 'जाँचकर्ता $who';
  }

  @override
  String get adminMlTagsEmpty => 'रेटिंग टैग यहाँ दिखेंगे';

  @override
  String get adminMlTagsNote =>
      'ड्राफ़्ट टैग भाषा जाँच के लिए रुकते हैं; केवल सक्रिय टैग ऐप में दिखते हैं।';

  @override
  String get adminMlTagDraft => 'ड्राफ़्ट';

  @override
  String get adminMlTagActive => 'सक्रिय';

  @override
  String get adminMlTagRetired => 'बंद';

  @override
  String get adminMlPositive => 'अच्छा';

  @override
  String get adminMlNegative => 'शिकायत';

  @override
  String get adminMlEditTag => 'टैग बदलें';

  @override
  String get adminMlLabelEn => 'अंग्रेज़ी';

  @override
  String get adminMlLabelMr => 'मराठी';

  @override
  String get adminMlLabelHi => 'हिंदी';

  @override
  String get adminMlYes => 'हाँ';

  @override
  String get adminMlNo => 'नहीं';

  @override
  String get adminMlFieldName => 'नाम';

  @override
  String get adminMlFieldFirm => 'फ़र्म';

  @override
  String get adminMlFieldPhone => 'मोबाइल नंबर';

  @override
  String get adminMlFieldMarkets => 'मंडी';

  @override
  String get adminMlFieldDistrict => 'ज़िला';

  @override
  String get adminMlFieldTaluka => 'तहसील';

  @override
  String get adminMlFieldVillage => 'गाँव';

  @override
  String get adminMlFieldCrops => 'फ़सलें';

  @override
  String get adminMlFieldServiceAreas => 'सेवा क्षेत्र';

  @override
  String get adminMlFieldApmc => 'APMC लाइसेंस नं.';

  @override
  String get adminMlFieldGst => 'GST नं.';

  @override
  String get adminMlFieldKind => 'सेवा';

  @override
  String get adminMlFieldCertValidUntil => 'प्रमाणपत्र वैध तिथि';

  @override
  String get adminMlFieldVehicles => 'वाहन नंबर';

  @override
  String get adminMlFieldCapacity => 'क्षमता (टन)';

  @override
  String get adminMlFieldRefrigerated => 'रेफ़्रिजरेटेड';

  @override
  String get adminMlFieldCarrierReg => 'कैरियर पंजीकरण नं.';

  @override
  String get adminMlKindWeighbridge => 'धर्मकांटा';

  @override
  String get adminMlKindTransporter => 'ट्रांसपोर्टर';

  @override
  String get adminMlKindLabourGang => 'मज़दूर टोली';

  @override
  String get adminMlKindCrateSupplier => 'क्रेट आपूर्तिकर्ता';

  @override
  String get adminMlChecks => 'जाँच';

  @override
  String get adminMlChecksNote =>
      'आधिकारिक पेज खोलें, नंबर पेस्ट करें (वह कॉपी हो चुका है), ख़ुद जाँचें और नतीजा दर्ज करें। बैज सिर्फ़ बताता है कि क्या और कब जाँचा।';

  @override
  String get adminMlOpenPage => 'आधिकारिक पेज खोलें';

  @override
  String get adminMlCallNow => 'कॉल करें';

  @override
  String get adminMlRecordResult => 'नतीजा दर्ज करें';

  @override
  String adminMlNumberCopied(String number) {
    return 'नंबर कॉपी हुआ: $number';
  }

  @override
  String get adminMlResultPassed => 'सही पाया';

  @override
  String get adminMlResultFailed => 'ग़लत पाया';

  @override
  String get adminMlResultCancelled => 'रद्द / बंद';

  @override
  String get adminMlRegisteredYear => 'GST पंजीकरण वर्ष (वैकल्पिक)';

  @override
  String get adminMlNoChecks => 'दर्ज की गई जाँच यहाँ दिखेंगी';

  @override
  String get adminMlCheckApmc => 'APMC लाइसेंस';

  @override
  String get adminMlCheckPhoneCall => 'फ़ोन कॉल';

  @override
  String get adminMlCheckPlacePhoto => 'जगह की फ़ोटो';

  @override
  String adminMlRegisteredSince(String year) {
    return 'पंजीकरण $year';
  }

  @override
  String get adminMlFlags => 'मंज़ूरी से पहले देखें';

  @override
  String get adminMlFlagDuplicate => 'यही नंबर दूसरी प्रोफ़ाइल पर';

  @override
  String get adminMlFlagReturning => 'निलंबित प्रोफ़ाइल से मेल खाता है';

  @override
  String get adminMlFlagMock => 'जगह नकली (mock) दिखी';

  @override
  String get adminMlFlagOtherDistrict => 'बताए ज़िले के बाहर से पंजीकरण';

  @override
  String get adminMlFlagNoPlace => 'फ़ोन से जगह का नाम खाली';

  @override
  String get adminMlWhyName => 'वही नाम';

  @override
  String get adminMlWhyGps => 'पास से पंजीकरण';

  @override
  String get adminMlWhyAccount => 'वही खाता';

  @override
  String get adminMlRechecks => 'दोबारा जाँचें';

  @override
  String get adminMlRechecksEmpty => 'सभी सालाना दोबारा जाँच पूरी';

  @override
  String adminMlLastChecked(String date) {
    return 'पिछली जाँच $date';
  }

  @override
  String adminMlDocumentCount(int n) {
    return 'दस्तावेज़: $n';
  }

  @override
  String get mlRolesTitle => 'अपनी भूमिका चुनें';

  @override
  String get mlRolesIntro =>
      'हर भूमिका के लिए एक ही साइन-इन। भूमिका कभी भी बदल सकते हैं।';

  @override
  String get mlRoleGrower => 'किसान';

  @override
  String get mlRoleTrader => 'व्यापारी';

  @override
  String get mlRoleBroker => 'मध्यस्थ (दलाल)';

  @override
  String get mlRoleExporter => 'निर्यातक';

  @override
  String get mlRoleProvider => 'सेवा देने वाले';

  @override
  String get mlRoleProviderKinds => 'धर्मकांटा, परिवहन, मज़दूर, क्रेट';

  @override
  String get mlRoleCurrent => 'मौजूदा भूमिका';

  @override
  String get mlSwitchRole => 'भूमिका बदलें';

  @override
  String get mlHomeLinkTitle => 'बाज़ार जुड़ाव';

  @override
  String get mlHomeLinkHint =>
      'व्यापारी, मध्यस्थ, निर्यातक, सेवा: भूमिका चुनें';

  @override
  String get mlTermsTitle => 'शुरू करने से पहले';

  @override
  String mlTermsRole(String role) {
    return 'भूमिका: $role';
  }

  @override
  String get mlTermsIntroOnly =>
      'BagMitra केवल जानकारी देता है और आपको व्यापारियों, मध्यस्थों (दलाल) और बाज़ार से मिलवाता है।';

  @override
  String get mlTermsNotParty =>
      'BagMitra खरीदार, विक्रेता, कमीशन एजेंट या ट्रांसपोर्टर नहीं है।';

  @override
  String get mlTermsNoMoney =>
      'यह कोई पैसा नहीं रखता और भुगतान या माल की गुणवत्ता की गारंटी नहीं देता।';

  @override
  String get mlTermsNoGainLoss =>
      'आपके लेन-देन में इस ऐप का कोई लाभ या नुकसान नहीं है।';

  @override
  String get mlTermsNoPart =>
      'आपके लेन-देन या किसी भी विवाद में BagMitra भाग नहीं लेता।';

  @override
  String get mlTermsAfterDeal =>
      'लेन-देन के बाद क्या दर्ज करना है, यह आपकी इच्छा है।';

  @override
  String get mlTermsPublicPhone =>
      'आपका फ़ोन नंबर आपकी प्रोफ़ाइल पर सबको दिखेगा, ताकि किसान आपको सीधे फ़ोन कर सकें।';

  @override
  String get mlTermsGpsOnce =>
      'पंजीकरण के समय धोखाधड़ी रोकने के लिए आपका स्थान (GPS) एक बार लिया जाएगा।';

  @override
  String get mlTermsFull => 'उपयोग की पूरी शर्तें';

  @override
  String get mlTermsAdult => 'मेरी उम्र 18 वर्ष से अधिक है';

  @override
  String get mlTermsAgree => 'मैंने पढ़ा और मैं सहमत हूँ';

  @override
  String get mlTermsAccept => 'स्वीकार करें और आगे बढ़ें';

  @override
  String get mlTermsBack => 'पीछे';

  @override
  String get mlSafetyNotice =>
      'BagMitra कभी भी पैसे, OTP या बैंक विवरण नहीं माँगता।';

  @override
  String get mlGrievanceTitle => 'शिकायत अधिकारी';

  @override
  String get mlGrievanceOwner => 'BagMitra के मालिक';

  @override
  String mlGrievanceContact(String contact) {
    return 'संपर्क: $contact';
  }

  @override
  String get mlGrievanceTimes =>
      'शिकायत की पावती 24 घंटे में और निपटारा 15 दिन में।';

  @override
  String get mlKindWeighbridge => 'धर्मकांटा';

  @override
  String get mlKindTransporter => 'ट्रांसपोर्टर';

  @override
  String get mlKindLabourGang => 'मज़दूर टोली';

  @override
  String get mlKindCrateSupplier => 'क्रेट आपूर्तिकर्ता';

  @override
  String get mlRegisterTrader => 'व्यापारी पंजीकरण';

  @override
  String get mlRegisterExporter => 'निर्यातक पंजीकरण';

  @override
  String get mlRegisterBroker => 'मध्यस्थ (दलाल) पंजीकरण';

  @override
  String get mlRegisterProvider => 'सेवा देने वाले का पंजीकरण';

  @override
  String get mlRegisterAs => 'पंजीकरण करें';

  @override
  String get mlFixTitle => 'पंजीकरण के स्थान की लोकेशन';

  @override
  String get mlFixWhy =>
      'पंजीकरण पूरा करने के लिए फ़ोन आपकी अभी की लोकेशन एक बार लेता है। इससे नकली पंजीकरण दूर रहते हैं।';

  @override
  String get mlFixOnce =>
      'लोकेशन सिर्फ़ एक बार, अभी ली जाती है। सार्वजनिक प्रोफ़ाइल पर सिर्फ़ गाँव, तहसील और ज़िला दिखता है; सटीक जगह सिर्फ़ BagMitra की जाँच के लिए।';

  @override
  String get mlPhonePublicNote =>
      'जाँच के बाद आपका नाम, फ़र्म और संपर्क नंबर पंजीकृत किसानों को दिखता है।';

  @override
  String get mlFixTake => 'लोकेशन लें';

  @override
  String get mlFixTaking => 'लोकेशन ले रहे हैं…';

  @override
  String get mlFixDenied => 'पंजीकरण पूरा करने के लिए लोकेशन की अनुमति दें।';

  @override
  String mlFixTaken(String place, String metres) {
    return 'लोकेशन ली गई: $place (±$metres मी)';
  }

  @override
  String get mlPickKind => 'आप कौन-सी सेवा देते हैं?';

  @override
  String get mlFieldName => 'नाम';

  @override
  String get mlFieldPhone => 'संपर्क नंबर';

  @override
  String get mlFieldFirm => 'फ़र्म का नाम (वैकल्पिक)';

  @override
  String get mlFieldVillage => 'गाँव';

  @override
  String get mlFieldTaluka => 'तहसील';

  @override
  String get mlFieldDistrict => 'ज़िला';

  @override
  String get mlFieldMarkets => 'मंडी / गाँव (बीच में कॉमा)';

  @override
  String get mlFieldAreas => 'सेवा वाले इलाके (बीच में कॉमा)';

  @override
  String get mlFieldCrops => 'फसलें';

  @override
  String get mlFieldAddress => 'पता (वैकल्पिक)';

  @override
  String get mlFieldGst => 'GSTIN';

  @override
  String get mlFieldApmc => 'APMC लाइसेंस नं.';

  @override
  String get mlFieldFssai => 'FSSAI लाइसेंस नं.';

  @override
  String get mlFieldIec => 'IEC नं.';

  @override
  String get mlFieldApeda => 'APEDA पंजीकरण नं.';

  @override
  String get mlFieldVehicles => 'वाहन नंबर (बीच में कॉमा)';

  @override
  String get mlFieldCapacity => 'क्षमता (टन)';

  @override
  String get mlFieldRefrigerated => 'रेफ्रिजरेटेड वाहन';

  @override
  String get mlFieldCertUntil => 'प्रमाणपत्र वैध तारीख';

  @override
  String mlCertUntilValue(String date) {
    return 'प्रमाणपत्र $date तक वैध';
  }

  @override
  String get mlNumbersNote =>
      'कम से कम एक लिखें: GSTIN, APMC लाइसेंस या IEC। BagMitra उसे आधिकारिक सार्वजनिक रजिस्टर पर जाँचता है।';

  @override
  String get mlIecRequired => 'निर्यातक पंजीकरण के लिए IEC नंबर चाहिए।';

  @override
  String get mlBrokerCallNote =>
      'जाँच पूरी करने के लिए BagMitra इस नंबर पर आपको फ़ोन करेगा।';

  @override
  String get mlErrPhone => '10 अंकों का मोबाइल नंबर लिखें';

  @override
  String get mlErrGst => '15 अक्षरों का GSTIN लिखें';

  @override
  String get mlErrIec => '10 अक्षरों का IEC लिखें';

  @override
  String get mlErrFssai => '14 अंकों का FSSAI नंबर लिखें';

  @override
  String get mlErrCapacity => 'क्षमता टन में लिखें (100 तक)';

  @override
  String get mlErrOneNumber => 'GSTIN, APMC लाइसेंस या IEC नंबर लिखें';

  @override
  String get mlErrPickKind => 'अपनी सेवा चुनें';

  @override
  String get mlErrCertDate => 'प्रमाणपत्र की वैध तारीख चुनें';

  @override
  String get mlErrFixStale => 'लोकेशन फिर से लें, फिर भेजें';

  @override
  String get mlErrExists =>
      'इस भूमिका में आपका पंजीकरण पहले से है; मेरा बाज़ार पंजीकरण देखें';

  @override
  String get mlErrCheckFields => 'जानकारी जाँचें और फिर भेजें';

  @override
  String get mlSubmit => 'पंजीकरण भेजें';

  @override
  String get mlSubmitted => 'पंजीकरण भेजा गया। BagMitra जाँच करेगा।';

  @override
  String get mlOffline => 'इसे देखने के लिए इंटरनेट चालू करें';

  @override
  String get mlServerBusy => 'सर्वर व्यस्त है; थोड़ी देर बाद फिर कोशिश करें';

  @override
  String get mlRetry => 'फिर कोशिश करें';

  @override
  String get mlMyProfilesTitle => 'मेरा बाज़ार पंजीकरण';

  @override
  String get mlMyProfilesEmpty =>
      'नीचे व्यापारी, निर्यातक, मध्यस्थ या सेवा देने वाले के रूप में पंजीकरण करें।';

  @override
  String get mlStatusPending => 'जाँच बाकी';

  @override
  String get mlStatusApproved => 'BagMitra ने जाँचा';

  @override
  String get mlStatusRejected => 'वापस भेजा; कारण देखें';

  @override
  String get mlCheckNote =>
      'BagMitra की जाँच के बाद आपकी प्रोफ़ाइल किसानों को दिखती है। दस्तावेज़ों की फ़ोटो जाँच में मदद करती हैं।';

  @override
  String mlDocsCount(String count) {
    return 'दस्तावेज़ फ़ोटो: $count';
  }

  @override
  String get mlDocCertificate => 'धर्मकांटा प्रमाणपत्र';

  @override
  String mlCertExpired(String date) {
    return 'प्रमाणपत्र की तारीख बीत गई ($date)';
  }

  @override
  String get mlAddressAdd => 'पता लिखें';

  @override
  String get mlAddressEdit => 'पता बदलें';

  @override
  String get mlCancel => 'रद्द करें';

  @override
  String get mlSave => 'सहेजें';

  @override
  String get mlPeopleTitle => 'व्यापारी और मध्यस्थ';

  @override
  String get mlPeopleEmpty =>
      'इस इलाके के जाँचे गए व्यापारी और मध्यस्थ यहाँ दिखेंगे।';

  @override
  String mlAreaTaluka(String taluka) {
    return 'तहसील $taluka';
  }

  @override
  String mlAreaDistrict(String district) {
    return 'ज़िला $district';
  }

  @override
  String get mlSortRating => 'रेटिंग के अनुसार';

  @override
  String get mlSortDeals => 'सौदों के अनुसार';

  @override
  String mlDeals(String count) {
    return '$count पूरे सौदे';
  }

  @override
  String mlStars(String average, String count) {
    return '$average/५ ($count)';
  }

  @override
  String mlDistanceKm(String km) {
    return '$km किमी';
  }

  @override
  String mlBadgeChecked(String date) {
    return 'BagMitra ने $date को जाँचा';
  }

  @override
  String mlBadgeRegisteredFrom(String place, String date) {
    return '$place से $date को पंजीकरण';
  }

  @override
  String mlBadgePlacePhoto(String date) {
    return 'BagMitra प्रतिनिधि ने $date को जगह की फ़ोटो ली';
  }

  @override
  String get mlBadgeNote =>
      'बैज बताता है कि BagMitra ने क्या और कब जाँचा। सौदे की शर्तें आप सीधे आपस में तय करते हैं।';

  @override
  String get mlCall => 'फ़ोन करें';

  @override
  String mlCallNumber(String phone) {
    return '$phone पर फ़ोन करें';
  }

  @override
  String get mlRatingsTitle => 'रेटिंग';

  @override
  String get mlQTraderOnDate => 'तय तुड़ाई तारीख पर आए';

  @override
  String get mlQTraderWeighing => 'तौल / क्रेट गिनती सही';

  @override
  String get mlQTraderPaid => 'तय अनुसार अग्रिम और बाकी पैसे दिए';

  @override
  String get mlQTraderConditions => 'बाकी शर्तें निभाईं';

  @override
  String get mlQBrokerHonest => 'सौदा ईमानदारी से बताया';

  @override
  String get mlQBrokerTraderKept => 'लाए गए व्यापारी ने सौदा निभाया';

  @override
  String get mlAreaAll => 'सभी इलाके';

  @override
  String get mlMarkets => 'मंडी / गाँव';

  @override
  String get mlAreas => 'सेवा इलाके';

  @override
  String get mlServicesTitle => 'सेवा देने वाले';

  @override
  String get mlServicesEmpty =>
      'पास के जाँचे गए धर्मकांटे, परिवहन, मज़दूर टोली और क्रेट आपूर्तिकर्ता यहाँ दिखेंगे।';

  @override
  String get mlServicesNote =>
      'फ़ोन करके सीधे तय करें; दर और भुगतान आपस की बात है।';

  @override
  String mlNearPlot(String name) {
    return '$name के पास';
  }

  @override
  String get mlDisclaimerShort =>
      'बागमित्र ख़रीदार, विक्रेता, मध्यस्थ (दलाल) या ट्रांसपोर्टर नहीं है; पैसा नहीं रखता; भुगतान या गुणवत्ता की गारंटी नहीं देता।';

  @override
  String get mlOpen => 'माल बिक्री के लिए दिखाएँ';

  @override
  String get mlMyLotsTitle => 'मेरा बिक्री का माल';

  @override
  String get mlLotsEmpty =>
      'फ़ोटो के साथ अपना माल यहाँ दिखाएँ; जाँचे गए व्यापारी और मध्यस्थ (दलाल) उसे देखते हैं।';

  @override
  String get mlLotFormTitle => 'बिक्री का माल';

  @override
  String get mlNoPlot => 'पहले अपना बाग जोड़ें।';

  @override
  String get mlPlot => 'बाग';

  @override
  String get mlBahar => 'बहार';

  @override
  String get mlQuantity => 'अनुमानित माल (टन)';

  @override
  String get mlQuality => 'आकार और गुणवत्ता';

  @override
  String get mlHarvestWindow => 'तुड़ाई का समय';

  @override
  String mlWindowFromBahar(String from, String to) {
    return '$from – $to (बहार अनुसार)';
  }

  @override
  String get mlWindowPick => 'तारीखें चुनें';

  @override
  String mlWindowRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get mlBasis => 'बिक्री का तरीका';

  @override
  String get mlBasisPerTonne => 'प्रति टन';

  @override
  String get mlBasisPerCrate => 'प्रति क्रेट';

  @override
  String get mlBasisLumpSum => 'पूरा बाग';

  @override
  String get mlAskingRate => 'अपेक्षित दर ₹ (वैकल्पिक)';

  @override
  String get mlPhotos => 'फ़ोटो';

  @override
  String mlPhotosHint(String min, String max) {
    return 'ऐप के कैमरे से $min से $max फ़ोटो';
  }

  @override
  String get mlAddPhoto => 'फ़ोटो लें';

  @override
  String get mlRemovePhoto => 'फ़ोटो हटाएँ';

  @override
  String get mlPhotoNoGps =>
      'GPS चालू करके फिर से फ़ोटो लें: हर फ़ोटो के साथ जगह चाहिए।';

  @override
  String get mlPrivacy =>
      'व्यापारियों को सिर्फ़ गाँव, तहसील और ज़िला दिखता है; आपका नाम, फ़ोन और बाग की जगह गुप्त रहती है।';

  @override
  String get mlSaveDraft => 'मसौदा सहेजें';

  @override
  String get mlPublish => 'व्यापारियों को दिखाएँ';

  @override
  String get mlClose => 'दिखाना बंद करें';

  @override
  String get mlStatusDraft => 'मसौदा';

  @override
  String get mlStatusPublished => 'व्यापारियों को दिखता है';

  @override
  String get mlStatusReview => 'जाँच बाकी';

  @override
  String get mlStatusClosed => 'बंद';

  @override
  String mlTonnes(String value) {
    return '$value टन';
  }

  @override
  String mlRatePerTonne(String rate) {
    return '$rate प्रति टन';
  }

  @override
  String mlRatePerCrate(String rate) {
    return '$rate प्रति क्रेट';
  }

  @override
  String mlRateLumpSum(String rate) {
    return 'पूरे बाग के लिए $rate';
  }

  @override
  String get mlPublished =>
      'जाँचे गए व्यापारी और मध्यस्थ (दलाल) को माल दिखने लगा।';

  @override
  String get mlClosed => 'माल व्यापारियों की सूची से हटाया गया।';

  @override
  String get mlPublishOffline =>
      'इसके लिए इंटरनेट चाहिए। मसौदा सहेजा है; इंटरनेट आने पर फिर करें।';

  @override
  String mlPublishNeedPhotos(String min, String max) {
    return 'पहले $min से $max फ़ोटो जोड़ें।';
  }

  @override
  String get mlPublishPhotoMissing =>
      'उस फ़ोटो को हटाकर फिर से लें: उसकी फ़ाइल इस फ़ोन से हट गई है।';

  @override
  String get mlPublishNotAccepted => 'पहले किसान शर्तें मानें, फिर कोशिश करें।';

  @override
  String get mlPublishFailed => 'थोड़ी देर बाद फिर करें।';

  @override
  String get mlChooseOne => 'एक चुनें';

  @override
  String get mlDeleteDraft => 'मसौदा हटाएँ';

  @override
  String get mlNoContacts =>
      'यहाँ सिर्फ़ माल के बारे में लिखें; फ़ोन नंबर और लिंक ऑफ़र स्वीकार करने के बाद मिलते हैं।';

  @override
  String get mlPublishOrchardCheck =>
      'माल दर्ज हुआ; फ़ोटो नक्शे वाले बाग के बाहर ली गईं, इसलिए जाँच के बाद व्यापारियों को दिखेगा।';

  @override
  String get mlSize => 'आकार';

  @override
  String get mlGrade => 'ग्रेड';

  @override
  String get mlQualityLine => 'छोटी जानकारी (वैकल्पिक)';

  @override
  String get mlSafetyReport => 'शिकायत करें';

  @override
  String get mlSafetyReportTitle => 'बागमित्र को शिकायत';

  @override
  String get mlSafetyReportWhy => 'कारण चुनें';

  @override
  String get mlSafetyReportNote =>
      'बागमित्र सिर्फ परिचय कराता है। फर्जी पहचान, फर्जी माल, खुद को बागमित्र बताना, फर्जी रेटिंग या दुर्व्यवहार की शिकायत करें; लेन-देन का भुगतान, वजन और गुणवत्ता आप आपस में तय करें।';

  @override
  String get mlSafetyPhoto => 'फोटो जोड़ें (चाहें तो)';

  @override
  String get mlSafetyPhotoAdded => 'फोटो जुड़ा';

  @override
  String get mlSafetySend => 'शिकायत भेजें';

  @override
  String get mlSafetySent => 'शिकायत मिली। बागमित्र जांच करेगा।';

  @override
  String get mlSafetyRetry => 'इंटरनेट जांचकर फिर कोशिश करें';

  @override
  String get mlReasonFakeIdentity => 'फर्जी पहचान';

  @override
  String get mlReasonFakeLot => 'फर्जी माल या दूसरे बाग की फोटो';

  @override
  String get mlReasonImpersonation => 'खुद को बागमित्र बताता है';

  @override
  String get mlReasonFakeRating => 'फर्जी रेटिंग';

  @override
  String get mlReasonAbuse => 'अपमानजनक व्यवहार';

  @override
  String get mlReasonDuplicateUser => 'एक व्यक्ति, दो खाते';

  @override
  String get mlReasonChecksPassed => 'जांच पूरी';

  @override
  String get mlReasonAppealUpheld => 'अपील स्वीकार';

  @override
  String get mlActionVerify => 'सत्यापित';

  @override
  String get mlActionWarn => 'चेतावनी';

  @override
  String get mlActionHide => 'सूची से छिपाया';

  @override
  String get mlActionSuspend => 'खाता कुछ समय के लिए रोका';

  @override
  String get mlActionRestore => 'फिर से चालू';

  @override
  String get mlAppealIdentityGenuine => 'मेरी पहचान सच्ची है';

  @override
  String get mlAppealLotGenuine => 'मेरा माल और फोटो सच्चे हैं';

  @override
  String get mlAppealRatingGenuine => 'यह रेटिंग असली लेन-देन की है';

  @override
  String get mlAppealBehaviourProper => 'मेरा बर्ताव सही था';

  @override
  String get mlAppealNotDuplicate => 'यह मेरा एकमात्र खाता है';

  @override
  String get mlAppealStateAppealed => 'अपील शिकायत अधिकारी के पास';

  @override
  String get mlAppealStateUpheld => 'अपील स्वीकार';

  @override
  String get mlAppealStateRejected => 'निर्णय कायम';

  @override
  String get mlActionsTitle => 'मेरे खाते पर कार्रवाई';

  @override
  String get mlActionsEmpty => 'आपका खाता ठीक है।';

  @override
  String mlActionReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String mlActionDate(String date) {
    return '$date को';
  }

  @override
  String get mlAppeal => 'अपील करें';

  @override
  String get mlAppealTitle => 'अपील (एक बार)';

  @override
  String get mlAppealNote =>
      'शिकायत अधिकारी 24 घंटे में पावती और 15 दिन में निर्णय देंगे।';

  @override
  String get mlAppealSend => 'अपील भेजें';

  @override
  String get mlAppealSent => 'अपील मिली';

  @override
  String get mlGrievanceDefault => 'बागमित्र के मालिक';

  @override
  String get mlBlock => 'ब्लॉक करें';

  @override
  String get mlUnblock => 'ब्लॉक हटाएं';

  @override
  String get mlBlockTitle => 'इस व्यक्ति को ब्लॉक करें?';

  @override
  String get mlBlockNote =>
      'आप दोनों एक-दूसरे की सूची और रुचि से दूर रहेंगे। कभी भी ब्लॉक हटा सकते हैं।';

  @override
  String get mlBlocked => 'ब्लॉक किया';

  @override
  String get mlUnblocked => 'ब्लॉक हटाया';

  @override
  String get mlMoreOptions => 'और विकल्प';

  @override
  String get adminMlReports => 'शिकायतें';

  @override
  String get adminMlAppeals => 'अपीलें';

  @override
  String get adminMlReportsEmpty => 'सभी शिकायतें निपटाईं';

  @override
  String get adminMlAppealsEmpty => 'सभी अपीलें निपटाईं';

  @override
  String get adminMlAckOverdue => 'पावती: 24 घंटे पार';

  @override
  String get adminMlCloseOverdue => 'निर्णय: 15 दिन पार';

  @override
  String get adminMlAcknowledge => 'पावती दें';

  @override
  String get adminMlAct => 'कार्रवाई करें';

  @override
  String get adminMlDismiss => 'खारिज करें';

  @override
  String get adminMlUphold => 'अपील स्वीकार करें';

  @override
  String get adminMlKeepDecision => 'निर्णय कायम रखें';

  @override
  String get adminMlActionTitle => 'कारण-कोड के साथ कार्रवाई';

  @override
  String get adminMlActionNote =>
      'सिर्फ प्लेटफॉर्म के नियम: फर्जी या दोहरे खाते, फर्जी माल, नकल, दुर्व्यवहार। भुगतान, वजन, गुणवत्ता के झगड़े पक्षों के बीच रहते हैं।';

  @override
  String get adminMlStatusOpen => 'खुली';

  @override
  String get adminMlStatusActioned => 'कार्रवाई हुई';

  @override
  String get adminMlStatusDismissed => 'खारिज';

  @override
  String get adminMlTargetLot => 'माल (लॉट)';

  @override
  String get adminMlTargetRating => 'रेटिंग';

  @override
  String get adminMlTargetUser => 'उपयोगकर्ता';

  @override
  String adminMlReceived(String date) {
    return '$date को आई';
  }

  @override
  String adminMlPhoto(int n) {
    return 'फोटो $n';
  }

  @override
  String adminMlAppealReason(String reason) {
    return 'अपील: $reason';
  }

  @override
  String get mlBrowseTitle => 'बिक्री के लिए माल';

  @override
  String get mlBrowseEmpty => 'किसानों का दिखाया माल यहाँ दिखेगा।';

  @override
  String get mlNotVerified =>
      'BagMitra के आपका पंजीकरण जाँचने के बाद माल यहाँ दिखेगा।';

  @override
  String get mlMyOffersTitle => 'मेरे ऑफ़र';

  @override
  String get mlMyOffersEmpty => 'माल पर दिए आपके ऑफ़र यहाँ दिखेंगे।';

  @override
  String get mlOfferOpen => 'किसान के फ़ैसले का इंतज़ार';

  @override
  String get mlOfferAccepted => 'स्वीकार हुआ';

  @override
  String get mlOfferClosed =>
      'बंद: किसान ने दूसरा ऑफ़र चुना या माल सूची से हटाया।';

  @override
  String mlHarvestOn(String date) {
    return 'तुड़ाई $date';
  }

  @override
  String get mlMakeOffer => 'ऑफ़र दें';

  @override
  String get mlOfferTitle => 'आपका ऑफ़र';

  @override
  String get mlOfferRate => 'दर ₹';

  @override
  String get mlOfferQuantity => 'माल टन में (वैकल्पिक)';

  @override
  String get mlOfferHarvestDate => 'प्रस्तावित तुड़ाई तारीख';

  @override
  String get mlOfferThroughBroker => 'मध्यस्थ (दलाल) के ज़रिए';

  @override
  String get mlOfferForTrader => 'किस व्यापारी के लिए';

  @override
  String get mlOfferDirect => 'सीधे';

  @override
  String get mlOfferOnlyThese =>
      'किसान को सिर्फ़ दर, माल और तारीख जाती है; बाकी सब आमने-सामने तय करें।';

  @override
  String get mlOfferSend => 'ऑफ़र भेजें';

  @override
  String get mlOfferSent => 'ऑफ़र भेजा। किसान के फ़ैसले पर सूचना आएगी।';

  @override
  String get mlErrRate => 'दर रुपयों में लिखें';

  @override
  String get mlErrQuantity => 'टन लिखें (10,000 तक)';

  @override
  String get mlErrPickTrader => 'व्यापारी चुनें';

  @override
  String get mlErrLotGone => 'यह माल सूची से हट गया है।';

  @override
  String get mlOffersTitle => 'आपके माल पर ऑफ़र';

  @override
  String get mlOffersEmpty =>
      'जाँचे गए व्यापारियों के ऑफ़र यहाँ साथ-साथ दिखेंगे।';

  @override
  String get mlSeeOffers => 'ऑफ़र देखें';

  @override
  String mlYourAsk(String rate) {
    return 'आपकी अपेक्षित दर: $rate';
  }

  @override
  String get mlAcceptPick => 'चुनने के लिए एक ऑफ़र पर टैप करें';

  @override
  String get mlAccept => 'चुना हुआ ऑफ़र स्वीकार करें';

  @override
  String get mlAcceptConfirmTitle => 'यह ऑफ़र स्वीकार करें?';

  @override
  String get mlAcceptConfirmBody =>
      'इस व्यापारी (और नामित मध्यस्थ) को आपका नाम, फ़ोन और बाग की जगह दिखेगी। बाकी ऑफ़र बंद होंगे। आगे का लेन-देन आप सीधे आपस में तय करें।';

  @override
  String get mlAcceptYes => 'स्वीकार करें';

  @override
  String get mlAccepted =>
      'स्वीकार हुआ। अब दोनों को एक-दूसरे के संपर्क दिखते हैं।';

  @override
  String get mlAcceptChanged => 'ऑफ़र बदल गया है; सूची फिर से खोलें।';

  @override
  String get mlIntroOpen => 'संपर्क देखें';

  @override
  String get mlIntroTitle => 'संपर्क';

  @override
  String get mlIntroGrower => 'किसान';

  @override
  String get mlIntroOpenMap => 'बाग नक्शे पर खोलें';

  @override
  String mlIntroAcceptedOn(String date) {
    return '$date को स्वीकार';
  }

  @override
  String get mlIntroOffApp =>
      'अब तौल, क्रेट, ढुलाई और पैसे का लेन-देन आप आपस में तय करते हैं।';

  @override
  String get mlDealDone => 'लेन-देन हो गया';

  @override
  String get mlDealDoneAsk => 'लेन-देन हो गया, दर्ज करें?';

  @override
  String get mlDealDoneAskBody =>
      'आपस का लेन-देन पूरा होने पर ही दबाएँ। किसान और व्यापारी दोनों के दबाने पर रेटिंग खुलती है।';

  @override
  String get mlDealSaidDone => 'लेन-देन हो गया कहा';

  @override
  String get mlDealNotYet => 'इंतज़ार है';

  @override
  String get mlDealWaitOther =>
      'दूसरी ओर से भी “लेन-देन हो गया” दबाने पर रेटिंग खुलेगी।';

  @override
  String get mlDealWaitBoth =>
      'किसान और व्यापारी दोनों के “लेन-देन हो गया” दबाने पर रेटिंग खुलेगी।';

  @override
  String get mlRateOpen => 'रेटिंग दें';

  @override
  String mlRateUntil(String date) {
    return '$date तक दे या बदल सकते हैं';
  }

  @override
  String mlRateLocked(String date) {
    return 'रेटिंग $date को बंद हुई';
  }

  @override
  String get mlRateNoText => 'सिर्फ़ स्टार दें और निशान लगाएँ।';

  @override
  String mlRateStarsOf(int count) {
    return '5 में से $count स्टार';
  }

  @override
  String get mlRateSave => 'रेटिंग सहेजें';

  @override
  String get mlRateAnswerAll => 'हर पंक्ति को स्टार दें';

  @override
  String get mlRateSaved => 'रेटिंग सहेजी गई';

  @override
  String get mlRateRefused =>
      'दोनों के “लेन-देन हो गया” दबाने के बाद 7 दिनों में ही रेटिंग सहेजी जाती है।';

  @override
  String get mlRateSameDevice =>
      'रेटिंग अलग-अलग फ़ोन वाले खातों के बीच ही दी जाती है।';

  @override
  String get mlQGrowerProduce => 'माल फोटो और विवरण जैसा था';

  @override
  String get mlQGrowerReady => 'तय तारीख पर माल तैयार था';

  @override
  String get mlCopyToAccounts => 'मेरे हिसाब में दर्ज करें';

  @override
  String mlBadgeGstChecked(String date) {
    return 'GST $date को जाँचा';
  }

  @override
  String mlBadgeGstSince(String date, String year) {
    return 'GST $date को जाँचा · $year से पंजीकृत';
  }

  @override
  String mlBadgeApmcSeen(String date) {
    return 'APMC लाइसेंस $date को देखा';
  }

  @override
  String mlBadgeFssaiChecked(String date) {
    return 'FSSAI $date को जाँचा';
  }

  @override
  String mlBadgeIecActive(String date) {
    return 'IEC चालू, $date को जाँचा';
  }

  @override
  String mlBadgeApedaListed(String date) {
    return 'APEDA सूची में, $date को जाँचा';
  }

  @override
  String mlPackageActiveUntil(String date) {
    return 'पैकेज $date तक चालू';
  }

  @override
  String get mlPackageNotActive => 'पैकेज चालू नहीं';

  @override
  String get mlPackageHiddenNow => 'व्यापारियों को अभी नहीं दिखता';

  @override
  String get billingTitle => 'सदस्यता';

  @override
  String billingPerMonth(String price) {
    return '$price प्रति माह';
  }

  @override
  String get billingIncluded => 'पूरा BagMitra app, सभी सुविधाएँ।';

  @override
  String get billingTerms =>
      'Google Play से हर महीने अपने-आप नवीनीकरण। Google Play में कभी भी रद्द करें; आपके अपने रिकॉर्ड हमेशा पढ़े और export किए जा सकते हैं।';

  @override
  String get billingSubscribe => 'सदस्यता लें';

  @override
  String get billingRestore => 'सदस्यता वापस पाएँ';

  @override
  String get billingManage => 'सदस्यता प्रबंधन';

  @override
  String get billingActive => 'आपकी सदस्यता चालू है।';

  @override
  String get billingPending => 'Google Play की पुष्टि का इंतज़ार है।';

  @override
  String get billingVerifying => 'BagMitra Google Play से जाँच रहा है…';

  @override
  String get billingRetry =>
      'फिर से कोशिश करें, या \'सदस्यता वापस पाएँ\' दबाएँ।';

  @override
  String get billingNeedsPlay => 'यह पेज Google Play वाले फ़ोन पर खोलें।';

  @override
  String get billingChangeTitle => 'आपकी सदस्यता में बदलाव';

  @override
  String billingChangeBody(String date) {
    return '$date से आपकी सदस्यता की नई मासिक दर Google Play में है। सदस्यता चालू रखने के लिए Google Play में देखकर स्वीकार करें।';
  }

  @override
  String billingChangeConfirmedBody(String date) {
    return '$date से आपकी सदस्यता Google Play की नई मासिक दर पर चलेगी। आप इसे पहले ही स्वीकार कर चुके हैं।';
  }

  @override
  String get billingOpenPlay => 'Google Play खोलें';

  @override
  String get feedbackTitle => 'प्रतिक्रिया दें';

  @override
  String get feedbackKindProblem => 'समस्या';

  @override
  String get feedbackKindSuggestion => 'सुझाव';

  @override
  String get feedbackKindQuestion => 'प्रश्न';

  @override
  String get feedbackHint => 'क्या हुआ या क्या चाहिए, लिखें या बोलें।';

  @override
  String get feedbackAddScreenshot => 'screenshot जोड़ें';

  @override
  String get feedbackScreenshotAdded => 'screenshot जुड़ा';

  @override
  String get feedbackIncluded => 'app version और फ़ोन का मॉडल साथ जाता है।';

  @override
  String get feedbackSend => 'भेजें';

  @override
  String get feedbackSent => 'मिल गया, धन्यवाद!';

  @override
  String get feedbackQueued => 'फ़ोन पर सहेजा; इंटरनेट आने पर जाएगा।';

  @override
  String mlLoginRole(String role) {
    return 'भूमिका: $role';
  }

  @override
  String get expenseElsewhere =>
      'छिड़काव, मज़दूरी और खाद का खर्च उनकी अपनी प्रविष्टि में लिखें; हिसाब में वह अपने-आप जुड़ जाता है।';

  @override
  String get expenseGoSpray => 'छिड़काव';

  @override
  String get expenseGoLabour => 'मज़दूरी';

  @override
  String get expenseGoInputs => 'खाद और गोबर खाद';

  @override
  String get mlWelcomeTitle => 'बागमित्र में आपका स्वागत है';

  @override
  String get mlWelcomeLine =>
      'बाग के रिकॉर्ड, आज के मंडी भाव और व्यापारी, एक ही ऐप में।';

  @override
  String get photoCheckOpen => 'फ़ोटो से पहचानें';

  @override
  String get photoCheckHint =>
      'पत्ती, फल या तने की पास से, रोशनी में फ़ोटो लें।';

  @override
  String get photoCheckPart => 'कौन-सा हिस्सा? (वैकल्पिक)';

  @override
  String get photoCheckPartLeaf => 'पत्ती';

  @override
  String get photoCheckPartFruit => 'फल';

  @override
  String get photoCheckPartTrunk => 'तना';

  @override
  String get photoCheckPartWholeTree => 'पूरा पेड़';

  @override
  String get photoCheckRetry => 'फिर से जाँचें';

  @override
  String get photoCheckBusy =>
      'फ़ोटो जाँच रहे हैं… इसमें एक मिनट तक लग सकता है।';

  @override
  String get photoCheckChange => 'दूसरी फ़ोटो';

  @override
  String get photoCheckBack => 'रिकॉर्ड पर वापस';

  @override
  String get photoCheckLikelyHigh => 'ज़्यादा संभावना';

  @override
  String get photoCheckLikelyMedium => 'मध्यम संभावना';

  @override
  String get photoCheckLikelyLow => 'कम संभावना';

  @override
  String get photoCheckSigns => 'फ़ोटो में दिखा';

  @override
  String get photoCheckSignsEnglish => 'फ़ोटो में दिखा (अंग्रेज़ी में)';

  @override
  String get photoCheckOpenCard => 'कार्ड खोलें';

  @override
  String get photoCheckUnsure =>
      'और साफ़ फ़ोटो से मदद मिलेगी। रोशनी में, पास से दूसरी फ़ोटो लें या कार्डों के लक्षण देखें।';

  @override
  String get photoCheckHealthy => 'अच्छी बात: फ़ोटो में पेड़ स्वस्थ दिखता है।';

  @override
  String get photoCheckNote =>
      'यह फ़ोटो से दिया गया अंदाज़ा है; पूरी जानकारी कार्ड में है।';

  @override
  String get photoCheckSeeCards => 'कार्ड देखें';

  @override
  String get photoCheckOffline =>
      'फ़ोटो जाँच के लिए इंटरनेट चाहिए। फ़ोटो यहीं रखी है; इंटरनेट चालू होने पर \'फिर से जाँचें\' दबाएँ।';

  @override
  String get photoCheckFailed =>
      'थोड़ी देर बाद फिर से जाँचें। फ़ोटो यहीं रखी है।';

  @override
  String get photoCheckUnavailable =>
      'फ़ोटो जाँच अभी रुकी है; तब तक कार्डों के लक्षण देखें।';

  @override
  String get photoCheckRefused => 'कृपया दूसरी फ़ोटो लें।';

  @override
  String get photoCheckSignedOut => 'फ़ोटो जाँचने के लिए फिर से लॉगिन करें।';

  @override
  String get photoCheckDelete => 'यह फ़ोटो हटाएँ';

  @override
  String get photoCheckDeleted => 'फ़ोटो सर्वर से हटा दी गई।';

  @override
  String get photoCheckDeleteFailed =>
      'इंटरनेट चालू होने पर \'यह फ़ोटो हटाएँ\' फिर से दबाएँ।';

  @override
  String photoCheckLimitDaily(String count) {
    return 'आज की $count फ़ोटो पूरी हुईं; कल फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String photoCheckLimitDailyAt(String count, String when) {
    return 'आज की $count फ़ोटो पूरी हुईं; $when के बाद फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String photoCheckLimitMonthly(String count, String when) {
    return 'इस महीने की $count फ़ोटो पूरी हुईं; $when से फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String get photoCheckLimitTotal =>
      'आज की फ़ोटो जाँच पूरी हुईं; कल फिर से इस्तेमाल कर सकते हैं।';

  @override
  String photoCheckLimitTotalAt(String when) {
    return 'आज की फ़ोटो जाँच पूरी हुईं; $when के बाद फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String get billPhoto => 'बिल की फ़ोटो';

  @override
  String get billPhotoHint =>
      'दुकान के बिल की फ़ोटो इस रिकॉर्ड के साथ फ़ोन पर रहती है।';

  @override
  String get billPhotoOpen => 'बिल की फ़ोटो बड़ी देखें';

  @override
  String get billFill => 'बिल से भरें';

  @override
  String get billReading => 'बिल पढ़ रहे हैं…';

  @override
  String get billUnsure => 'बिल ठीक से पढ़ा नहीं जा सका; जानकारी हाथ से भरें।';

  @override
  String billFilled(String fields) {
    return 'बिल से भरा: $fields. एक बार जाँच लें।';
  }

  @override
  String get billNothingFilled => 'ये खाने पहले से भरे थे; वैसे ही रखे गए।';

  @override
  String get billOffline =>
      'बिल पढ़ने के लिए इंटरनेट चाहिए। फ़ोटो इस रिकॉर्ड के साथ फ़ोन पर सहेजी जाती है।';

  @override
  String get billFailed =>
      'थोड़ी देर बाद फिर से \'बिल से भरें\' दबाएँ; फ़ोटो यहीं है।';

  @override
  String get billUnavailable => 'बिल पढ़ना अभी रुका है; जानकारी हाथ से भरें।';

  @override
  String get billRefused => 'कृपया बिल की दूसरी फ़ोटो लें।';

  @override
  String get billSignedOut => 'बिल पढ़ने के लिए फिर से लॉगिन करें।';

  @override
  String billLimitDaily(String count) {
    return 'आज के $count बिल पढ़े जा चुके; कल फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String billLimitDailyAt(String count, String when) {
    return 'आज के $count बिल पढ़े जा चुके; $when के बाद फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String billLimitMonthly(String count, String when) {
    return 'इस महीने के $count बिल पढ़े जा चुके; $when से फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String get billLimitTotal =>
      'आज की बिल पढ़ाई पूरी हुई; कल फिर से इस्तेमाल कर सकते हैं।';

  @override
  String billLimitTotalAt(String when) {
    return 'आज की बिल पढ़ाई पूरी हुई; $when के बाद फिर से इस्तेमाल कर सकते हैं।';
  }

  @override
  String get billPickTitle => 'बिल की पंक्ति चुनें';

  @override
  String get billTotal => 'बिल का कुल';

  @override
  String billLabelShopNo(String shop, String no) {
    return '$shop बिल #$no';
  }

  @override
  String billLabelShop(String shop) {
    return '$shop बिल';
  }

  @override
  String billLabelNo(String no) {
    return 'बिल #$no';
  }

  @override
  String get billFieldProduct => 'दवा का नाम';

  @override
  String get billFieldActive => 'सक्रिय तत्व';

  @override
  String get billFieldDose => 'मात्रा';

  @override
  String get billFieldCost => 'खर्च';

  @override
  String get billFieldAmount => 'रकम';

  @override
  String get billFieldDate => 'तारीख';

  @override
  String get billFieldNote => 'टिप्पणी';
}
