// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'बागमित्र';

  @override
  String get greetingHello => 'नमस्कार';

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

    return 'कमाल $degreesString°';
  }

  @override
  String soilMoisture(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'मातीतील ओलावा $percentString%';
  }

  @override
  String get stageDays => 'दिवस';

  @override
  String nextStage(String stage, int days, String month) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'पुढचा टप्पा: $stage · अंदाजे $daysString दिवसांत · तोडणी $month';
  }

  @override
  String get todaysTasks => 'आजची कामे';

  @override
  String get seeAll => 'सर्व पहा';

  @override
  String marketTitle(String market) {
    return '$market बाजार';
  }

  @override
  String get sevenDayTrend => '७ दिवसांचा कल';

  @override
  String get homeWeatherNeedsLocation => 'बागेचे ठिकाण जोडा, इथे हवामान दिसेल.';

  @override
  String minTemperature(int degrees) {
    final intl.NumberFormat degreesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String degreesString = degreesNumberFormat.format(degrees);

    return 'किमान $degreesString°';
  }

  @override
  String homeNextStage(String stage, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'पुढचा टप्पा: $stage · $daysString दिवसांत';
  }

  @override
  String homeHarvestMonth(String month) {
    return 'तोडणी $month';
  }

  @override
  String get homeStageAddDates => 'टप्प्यांच्या तारखा लिहा, इथे दिवस दिसतील.';

  @override
  String get homeOpenMarket => 'बाजारभाव पहा';

  @override
  String get choosePlot => 'बाग निवडा';

  @override
  String get onboardingSaveFailed => 'कृपया पुन्हा \"पुढे\" दाबा.';

  @override
  String get perQuintal => 'प्रति क्विंटल';

  @override
  String get vsLastWeek => 'गेल्या आठवड्यापेक्षा';

  @override
  String get takePhoto => 'कीड-रोग फोटो';

  @override
  String get navHome => 'मुख्य पान';

  @override
  String get navOrchard => 'बाग';

  @override
  String get navAccounts => 'हिशोब';

  @override
  String get navAsk => 'विचारा';

  @override
  String get taskDone => 'पूर्ण';

  @override
  String get markTaskDone => 'काम पूर्ण झाले';

  @override
  String get syncFailed =>
      'तुमच्या नोंदी या फोनवर सुरक्षित आहेत. ॲप आपोआप पुन्हा पाठवायचा प्रयत्न करेल.';

  @override
  String get loginTitle => 'तुमच्या मोबाईल नंबरने सुरू करा';

  @override
  String get loginPhoneLabel => 'मोबाईल नंबर';

  @override
  String get loginSendOtp => 'OTP पाठवा';

  @override
  String get loginOr => 'किंवा';

  @override
  String get loginGoogle => 'Google ने लॉगिन करा';

  @override
  String get loginGoogleFailed =>
      'कृपया Google लॉगिन पुन्हा करून पहा; इंटरनेट चालू आहे का ते तपासा.';

  @override
  String loginOtpTitle(String phone) {
    return '$phone वर आलेला OTP टाका';
  }

  @override
  String get loginOtpLabel => '६ अंकी OTP';

  @override
  String get loginVerify => 'तपासा';

  @override
  String get loginInvalidPhone => '१० अंकी योग्य मोबाईल नंबर टाका';

  @override
  String get loginInvalidOtp => 'SMS मधील नवीन ६ अंकी OTP टाका';

  @override
  String get loginDemoNotice => 'डेमो मोड: कोणतेही ६ अंक चालतील';

  @override
  String get voiceInput => 'बोला';

  @override
  String get galleryTitle => 'घटक संग्रह';

  @override
  String adminTitle(String product) {
    return '$product प्रशासन';
  }

  @override
  String get adminCropTemplates => 'पीक टप्पा साचे';

  @override
  String get adminRiskRules => 'धोका नियम';

  @override
  String get adminPrompts => 'AI प्रॉम्प्ट साचे';

  @override
  String get adminTranslations => 'भाषांतरे';

  @override
  String get adminAiUsage => 'AI वापर';

  @override
  String adminComingSoon(int milestone) {
    return 'संपादन टप्पा $milestone मध्ये येईल.';
  }

  @override
  String get demoDataNotice => 'नमुना माहिती';

  @override
  String get myOrchard => 'माझी बाग';

  @override
  String get addPlot => 'बाग जोडा';

  @override
  String get plotsEmptyTitle => 'तुमची पहिली बाग जोडा';

  @override
  String get plotsEmptyBody =>
      'प्रत्येक बागेसाठी बहार कॅलेंडर आणि रोजची कामे मिळतील.';

  @override
  String get plotName => 'बागेचे नाव';

  @override
  String get plotNameHint => 'उदा. बाग १';

  @override
  String get plotCrop => 'पीक';

  @override
  String get plotVariety => 'वाण (ऐच्छिक)';

  @override
  String get plotAreaAcres => 'क्षेत्र (एकर)';

  @override
  String get plotTreeCount => 'झाडांची संख्या (ऐच्छिक)';

  @override
  String get plotPlantingYear => 'लागवडीचे वर्ष (ऐच्छिक)';

  @override
  String get save => 'जतन करा';

  @override
  String get fieldRequired => 'आवश्यक';

  @override
  String get invalidNumber => 'योग्य संख्या टाका';

  @override
  String plotAcres(String area) {
    return '$area एकर';
  }

  @override
  String plotTrees(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString झाडे';
  }

  @override
  String get plotSaved => 'जतन झाले.';

  @override
  String get deletePlot => 'बाग काढून टाका';

  @override
  String deletePlotConfirm(String name) {
    return '$name काढून टाकायची? तुमच्या इतर फोनवरूनही ती जाईल.';
  }

  @override
  String get cancel => 'रद्द करा';

  @override
  String get delete => 'काढून टाका';

  @override
  String get startBahar => 'बहार सुरू करा';

  @override
  String get baharEmptyTitle => 'पहिला बहार ठरवा';

  @override
  String get baharEmptyBody =>
      'बहार निवडा. प्रत्येक टप्प्यासाठी सार्वजनिक स्रोतांतून सुचवलेला काळ दिसतो; प्रत्येक तारीख तुम्ही बदलू शकता.';

  @override
  String get baharWhich => 'कोणता बहार?';

  @override
  String get baharSeason => 'हंगाम';

  @override
  String get baharDates => 'तुमच्या तारखा (ऐच्छिक)';

  @override
  String get baharPickDate => 'तारीख निवडा';

  @override
  String get baharStatusPlanned => 'ठरवलेला';

  @override
  String get baharStatusActive => 'चालू';

  @override
  String get baharStatusCompleted => 'पूर्ण';

  @override
  String get baharStatusAbandoned => 'थांबवलेला';

  @override
  String get adminCards => 'माहिती कार्डे';

  @override
  String get adminImports => 'आयात';

  @override
  String get adminAlerts => 'सूचना';

  @override
  String get adminSources => 'स्रोत';

  @override
  String get adminPublish => 'प्रकाशित करा';

  @override
  String get adminApprove => 'मंजूर करा';

  @override
  String get adminChemical => 'रसायन';

  @override
  String get adminImport => 'आयात करा';

  @override
  String get adminImportSource => 'स्रोत की';

  @override
  String get adminImportCsv => 'CSV (हाताने तपासलेली)';

  @override
  String get adminImportClaims => 'लेबल क्लेम';

  @override
  String get adminImportRestrictions => 'बंदी आणि निर्बंध';

  @override
  String adminImportResult(
    int added,
    int changed,
    int removed,
    int unchanged,
    int pulled,
  ) {
    return 'नवीन $added · बदललेले $changed · काढलेले $removed · तसेच $unchanged · मागे घेतलेली कार्डे $pulled';
  }

  @override
  String get adminResolve => 'निकाली काढा';

  @override
  String get adminNoAlerts => 'उघड्या सूचना इथे दिसतील';

  @override
  String get adminNoCards => 'कार्डे जोडल्यावर इथे दिसतील';

  @override
  String get adminSignInRequired =>
      'हा विभाग वापरण्यासाठी माहिती-कोश अॅडमिन खात्याने साइन इन करा.';

  @override
  String get adminDone => 'झाले';

  @override
  String get adminSignIn => 'साइन इन करा';

  @override
  String get adminEmail => 'ईमेल';

  @override
  String get adminPassword => 'पासवर्ड';

  @override
  String get adminSignInFailed => 'ईमेल किंवा पासवर्ड चुकीचा आहे.';

  @override
  String get adminSignOut => 'साइन आउट';

  @override
  String get adminNotConfigured =>
      'अॅडमिन साइन-इनसाठी SUPABASE_URL आणि SUPABASE_ANON_KEY हवे.';

  @override
  String get adminFeed => 'सरकारी संदेश';

  @override
  String get adminFeedQueue => 'तपासणी रांग';

  @override
  String get adminFeedUpload => 'अपलोड';

  @override
  String get adminFeedSources => 'संदेश स्रोत';

  @override
  String get adminFeedStatusInReview => 'तपासणीत';

  @override
  String get adminFeedStatusDraft => 'मसुदा';

  @override
  String get adminFeedStatusPublished => 'प्रकाशित';

  @override
  String get adminFeedStatusWithdrawn => 'मागे घेतले';

  @override
  String get adminFeedNoItems => 'ही यादी रिकामी आहे';

  @override
  String get adminFeedApproved => 'मंजूर';

  @override
  String adminFeedIssueCount(int count) {
    return '$count तपासणी मुद्दे';
  }

  @override
  String get adminFeedAiOff => 'AI सेट करायचे बाकी आहे';

  @override
  String get adminFeedSourceLink => 'मूळ दस्तऐवज';

  @override
  String adminFeedReplacedByValue(String id) {
    return '$id ने बदलले';
  }

  @override
  String get adminFeedWithdraw => 'मागे घ्या';

  @override
  String get adminFeedAiDraft => 'AI मसुदा';

  @override
  String get adminFeedCheckIssues => 'आउटपुट-तपासणी मुद्दे';

  @override
  String get adminFeedNoIssues => 'सर्व तपासण्या ठीक आहेत';

  @override
  String get adminFeedTextPreview => 'काढलेला मजकूर';

  @override
  String get adminFeedTexts => 'शीर्षक आणि सारांश';

  @override
  String get adminFeedDates => 'तारखा';

  @override
  String get adminFeedDeadline => 'शेवटची तारीख';

  @override
  String get adminFeedPayment => 'पैसे मिळण्याची तारीख';

  @override
  String get adminFeedValidFrom => 'पासून लागू';

  @override
  String get adminFeedValidTo => 'पर्यंत लागू';

  @override
  String get adminFeedDatesNote =>
      'तारखा मूळ मजकुराशी तपासल्या जातात. प्रसिद्ध बाबीत बदल जतन केल्यास ती पुन्हा पुनरावलोकनात जाते.';

  @override
  String get adminFeedPickDate => 'तारीख निवडा';

  @override
  String get adminFeedClearDate => 'काढा';

  @override
  String get adminFeedSaveDates => 'तारखा जतन करा';

  @override
  String get adminFeedCardNew => 'योजना कार्ड';

  @override
  String get adminFeedCardNote =>
      'प्रत्येक रकाना: दस्तऐवजात लिहिलेली किंमत व तिचे पान, किंवा \"दस्तऐवजात रिकामे\".';

  @override
  String get adminFeedNotStated => 'दस्तऐवजात रिकामे';

  @override
  String get adminFeedCardValue => 'किंमत';

  @override
  String get adminFeedCardPage => 'पान (उदा. p. 2)';

  @override
  String get adminFeedSaveCard => 'कार्ड जतन करा';

  @override
  String get adminFeedCardEmpty =>
      'किमान एक रकाना भरा किंवा \"दस्तऐवजात रिकामे\" निवडा.';

  @override
  String get adminFeedFullText => 'साठवलेला मजकूर (आउटपुट तपासणी हाच वाचते):';

  @override
  String get adminFeedTextTruncated =>
      'फक्त पहिले 200 KB दाखवले आहेत; साठवलेला मजकूर त्याहून मोठा आहे.';

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
      'मजकूर साठवला आहे (आउटपुट तपासणी व AI मसुद्यासाठी).';

  @override
  String get adminFeedNoText =>
      'यासाठी वापरण्याजोगा मजकूर हवा: मजकूर पेस्ट करून पुन्हा अपलोड करा, किंवा टिप्पणीसह मुद्दे स्वीकारा.';

  @override
  String get adminFeedUnusedText =>
      'बाजूला ठेवलेला मजकूर (बिघडलेला मजकूर-स्तर किंवा OCR):';

  @override
  String get adminFeedTitle => 'शीर्षक';

  @override
  String get adminFeedSummary => 'सारांश (2 ओळी)';

  @override
  String get adminFeedSave => 'जतन करा';

  @override
  String get adminFeedBadNumber => 'हेक्टर आकड्यात लिहा.';

  @override
  String get adminFeedTargetsNote =>
      'रिकामे क्षेत्र म्हणजे कोणतेही. जुळणी नेहमी फक्त \"पात्र असू शकता\" असेच म्हणते.';

  @override
  String get adminFeedDistrict => 'जिल्हा';

  @override
  String get adminFeedCrop => 'पीक';

  @override
  String get adminFeedMinHa => 'किमान हे.';

  @override
  String get adminFeedMaxHa => 'कमाल हे.';

  @override
  String get adminFeedRemove => 'काढा';

  @override
  String get adminFeedAddTarget => 'लक्ष्य जोडा';

  @override
  String get adminFeedSaveTargets => 'लक्ष्य जतन करा';

  @override
  String get adminFeedAcceptTitle => 'उघडे तपासणी मुद्दे स्वीकारायचे?';

  @override
  String adminFeedAcceptBody(int count) {
    return 'या बाबीत $count उघडे तपासणी मुद्दे आहेत. तरीही मंजूर करायचे असल्यास कारणाची टिप्पणी लिहा.';
  }

  @override
  String get adminFeedComment => 'टिप्पणी (का)';

  @override
  String get adminFeedCancel => 'रद्द करा';

  @override
  String get adminFeedAcceptApprove => 'स्वीकारा आणि मंजूर करा';

  @override
  String get adminFeedWithdrawTitle => 'बाब मागे घ्या';

  @override
  String get adminFeedReason => 'कारण';

  @override
  String get adminFeedReplacedBy => 'याने बदलले';

  @override
  String get adminFeedNoReplacement => 'फक्त मागे घ्या';

  @override
  String get adminFeedRequiredMissing =>
      'स्रोत की, दस्तऐवज URL आणि प्रकाशन तारीख आवश्यक आहेत.';

  @override
  String get adminFeedBadDate => 'तारखा YYYY-MM-DD अशा लिहा.';

  @override
  String adminFeedCreated(String status, int count) {
    return 'तयार: $status, $count तपासणी मुद्दे';
  }

  @override
  String get adminFeedDateHint => 'YYYY-MM-DD';

  @override
  String get adminFeedUploadNote =>
      'GR दस्तऐवज निवडा (सर्व्हर त्याचा हॅश ठेवतो व मजकूर वाचतो) आणि / किंवा त्यातील मजकूर पेस्ट करा (पेस्ट केलेला मजकूर ग्राह्य). अधिकृत URL नेहमी हवा.';

  @override
  String get adminFeedPickDocument => 'दस्तऐवज निवडा (PDF किंवा HTML)';

  @override
  String get adminFeedNoDocument => 'दस्तऐवज निवडा';

  @override
  String adminFeedDocument(String name, int kb) {
    return '$name · $kb KB';
  }

  @override
  String adminFeedTooLarge(int mb) {
    return 'दस्तऐवज $mb MB पेक्षा मोठा आहे.';
  }

  @override
  String get adminFeedBadType => 'फक्त .pdf, .html किंवा .htm फाइल.';

  @override
  String get adminFeedExtraction => 'मजकूर काढण्याचा निकाल';

  @override
  String get adminFeedSourceKey => 'स्रोत की';

  @override
  String get adminFeedPublishedAt => 'प्रकाशन तारीख';

  @override
  String get adminFeedUrl => 'दस्तऐवज URL';

  @override
  String get adminFeedExternalId => 'बाह्य ID (GR कोड)';

  @override
  String get adminFeedGrNumber => 'GR क्रमांक';

  @override
  String get adminFeedDepartment => 'विभाग';

  @override
  String get adminFeedPastedText => 'दस्तऐवजातील मजकूर (पेस्ट केलेला)';

  @override
  String get adminFeedSubmit => 'तपासणीला पाठवा';

  @override
  String get adminFeedOpen => 'बाब उघडा';

  @override
  String get adminFeedTerms => 'अटी';

  @override
  String get adminFeedTermsUnknown => 'अस्पष्ट';

  @override
  String get adminFeedTermsAllowed => 'परवानगी';

  @override
  String get adminFeedTermsDisallowed => 'वापरास मनाई';

  @override
  String get adminFeedTermsNote => 'टीप (काय वाचले)';

  @override
  String get accountsTitle => 'हिशोब';

  @override
  String get addExpense => 'खर्च जोडा';

  @override
  String get addSale => 'विक्री नोंदवा';

  @override
  String get expenseCategory => 'कशासाठी खर्च?';

  @override
  String get amountRupees => 'रक्कम (₹)';

  @override
  String get noteOptional => 'टीप (ऐच्छिक)';

  @override
  String get accountsExpenses => 'खर्च';

  @override
  String get accountsIncome => 'उत्पन्न';

  @override
  String get accountsProfit => 'नफा';

  @override
  String get accountsDues => 'व्यापाऱ्यांकडे बाकी';

  @override
  String get costPerAcre => 'एकरी खर्च';

  @override
  String get costPerTree => 'झाडामागे खर्च';

  @override
  String get costPerTonne => 'टनामागे खर्च';

  @override
  String get allBahars => 'सर्व';

  @override
  String get saleBuyer => 'व्यापारी';

  @override
  String get saleKg => 'वजन (किलो)';

  @override
  String get saleRate => 'दर (₹ प्रति क्विंटल)';

  @override
  String get saleDeductions => 'कपात (₹, ऐच्छिक)';

  @override
  String get salePaid => 'आतापर्यंत मिळाले (₹)';

  @override
  String get accountsEmpty => 'तुमचा पहिला खर्च किंवा विक्री नोंदवा.';

  @override
  String saleBy(String buyer, String kg) {
    return '$buyer · $kg किलो';
  }

  @override
  String get sprayLogTitle => 'फवारणी नोंदी';

  @override
  String get addSpray => 'फवारणी नोंदवा';

  @override
  String get spraysEmpty => 'पहिल्या फवारणीची नोंद इथे करा.';

  @override
  String get sprayProduct => 'औषधाचे नाव';

  @override
  String get sprayProductOptional => 'औषधाचे नाव (ऐच्छिक)';

  @override
  String get sprayActive => 'सक्रिय घटक (लेबलवर)';

  @override
  String get sprayActiveType => 'प्रकार (बुरशीनाशक, कीटकनाशक ...)';

  @override
  String get sprayActivePick => 'यादीतून निवडा';

  @override
  String get sprayActiveOther => 'इतर';

  @override
  String get sprayActiveOtherHelp => 'लेबलवर छापलेले नाव लिहा.';

  @override
  String get sprayActiveSearch => 'शोधा';

  @override
  String get sprayActiveNoMatch => 'दुसरे नाव लिहिण्यासाठी \'इतर\' निवडा.';

  @override
  String get sprayDose => 'मात्रा (ऐच्छिक)';

  @override
  String get sprayWater => 'पाणी (लिटर, ऐच्छिक)';

  @override
  String get sprayArea => 'फवारलेले क्षेत्र (एकर, ऐच्छिक)';

  @override
  String get sprayCost => 'खर्च (₹, ऐच्छिक)';

  @override
  String get sprayOperator => 'फवारणी करणारा (ऐच्छिक)';

  @override
  String get sprayPhi => 'तोडणीपूर्वीचे दिवस, PHI (ऐच्छिक)';

  @override
  String get sprayTarget => 'कोणत्या कीड/रोगासाठी (ऐच्छिक)';

  @override
  String get sprayDate => 'तारीख';

  @override
  String get sprayWhichBahar => 'कोणता बहार? (तोडणीची तारीख तपासण्यासाठी)';

  @override
  String get sprayWarnBannedTitle => 'मान्य यादीबाहेरील घटक';

  @override
  String sprayWarnBannedBody(String notification) {
    return 'हा घटक शासनाच्या मान्य यादीबाहेर आहे ($notification). नोंदणीकृत पर्याय लेबल माहितीत पाहा.';
  }

  @override
  String get sprayWarnRestrictedTitle => 'या पिकासाठी मान्य यादीबाहेर';

  @override
  String sprayWarnRestrictedBody(String notification) {
    return 'या पिकासाठी हा घटक मान्य यादीबाहेर आहे ($notification). लेबल माहिती पाहा.';
  }

  @override
  String get sprayWarnPhiTitle => 'प्रतीक्षा कालावधी';

  @override
  String sprayWarnPhiBody(String date) {
    return 'प्रतीक्षा कालावधी संपण्यापूर्वी तोडणी ठरवलेली आहे. $date पासून तोडणी सुरक्षित.';
  }

  @override
  String get fieldLogTitle => 'शेतातील नोंदी';

  @override
  String get addInput => 'खत जोडा';

  @override
  String get logIrrigation => 'पाणी नोंदवा';

  @override
  String get inputKind => 'काय दिले?';

  @override
  String get inputProduct => 'उत्पादनाचे नाव';

  @override
  String get inputQuantity => 'प्रमाण (ऐच्छिक)';

  @override
  String get inputUnit => 'एकक';

  @override
  String get inputCost => 'खर्च (₹, ऐच्छिक)';

  @override
  String get irrigationTitle => 'पाणी देणे';

  @override
  String get irrigationHours => 'तास (ऐच्छिक)';

  @override
  String get irrigationLitres => 'पाणी लिटरमध्ये (ऐच्छिक)';

  @override
  String get fieldLogEmpty => 'खताची किंवा पाण्याची पहिली नोंद जोडा.';

  @override
  String inputLine(String quantity, String unit) {
    return '$quantity $unit';
  }

  @override
  String irrigationHoursLine(String hours) {
    return '$hours तास';
  }

  @override
  String get labourTitle => 'मजुरी';

  @override
  String get labourAddDay => 'मजुराचा दिवस जोडा';

  @override
  String get labourWorker => 'मजुराचे नाव';

  @override
  String get labourTask => 'केलेले काम';

  @override
  String get labourWage => 'मजुरी (₹)';

  @override
  String get labourAdvance => 'आगाऊ दिलेले (₹, ऐच्छिक)';

  @override
  String get labourPaidNow => 'आज पूर्ण दिले';

  @override
  String get labourSettled => 'हिशोब झाला';

  @override
  String get labourMarkPaid => 'पूर्ण दिले';

  @override
  String get labourEmpty => 'मजुरीची पहिली नोंद जोडा.';

  @override
  String get labourTotalDue => 'मजुरांना देणे';

  @override
  String labourDue(String amount) {
    return 'बाकी $amount';
  }

  @override
  String get harvestTitle => 'तोडणी';

  @override
  String get harvestAdd => 'तोडणी जोडा';

  @override
  String get harvestKg => 'वजन (किलो)';

  @override
  String get harvestGrade => 'ग्रेड (ऐच्छिक)';

  @override
  String get harvestSize => 'आकार (ऐच्छिक)';

  @override
  String get harvestEmpty => 'तोडणीची पहिली नोंद जोडा.';

  @override
  String harvestTotal(String kg) {
    return 'एकूण $kg किलो';
  }

  @override
  String get moreMenu => 'आणखी';

  @override
  String harvestKgValue(String kg) {
    return '$kg किलो';
  }

  @override
  String get compareTitle => 'हंगामांची तुलना';

  @override
  String get compareEmpty =>
      'बहार सुरू करा आणि नोंदी जोडा, मग हंगामांची तुलना दिसेल.';

  @override
  String compareVs(String bahar, String change) {
    return '$bahar च्या तुलनेत: $change';
  }

  @override
  String compareMore(String amount) {
    return '$amount जास्त';
  }

  @override
  String compareLess(String amount) {
    return '$amount कमी';
  }

  @override
  String get compareSame => 'सारखेच';

  @override
  String get exportShare => 'स्प्रेडशीट शेअर करा';

  @override
  String get exportDate => 'तारीख';

  @override
  String get exportType => 'प्रकार';

  @override
  String get exportDetails => 'तपशील';

  @override
  String get exportTypeExpense => 'खर्च';

  @override
  String get exportTypeSale => 'विक्री';

  @override
  String get exportTypeSpray => 'फवारणी';

  @override
  String get exportTypeInput => 'खत / निविष्ठा';

  @override
  String get exportTypeLabour => 'मजुरी';

  @override
  String get exportKg => 'किलो';

  @override
  String get exportSharePdf => 'PDF शेअर करा';

  @override
  String get onboardingWelcome => 'बागमित्रमध्ये आपले स्वागत';

  @override
  String get onboardingLanguage => 'आपली भाषा निवडा';

  @override
  String get onboardingName => 'आपले नाव (ऐच्छिक)';

  @override
  String get onboardingVillage => 'गाव (ऐच्छिक)';

  @override
  String get onboardingTaluka => 'तालुका (ऐच्छिक)';

  @override
  String get onboardingDistrict => 'जिल्हा (ऐच्छिक)';

  @override
  String get onboardingConsentData =>
      'ॲप चालवण्यासाठी बागमित्रने माझ्या बागेच्या नोंदी साठवल्या तर माझी संमती आहे.';

  @override
  String get onboardingConsentWhatsapp =>
      'मला WhatsApp वर आठवणी पाठवा (ऐच्छिक).';

  @override
  String get onboardingContinue => 'पुढे';

  @override
  String get profileTitle => 'माझी माहिती';

  @override
  String get profileConsentDataNote =>
      'तुमच्या नोंदी साठवण्यासाठी आणि सुरक्षित ठेवण्यासाठी ही संमती लागते, म्हणून ती नेहमी चालू राहते.';

  @override
  String get profilePhoneSignedIn => 'या नंबरने तुम्ही लॉगिन करता.';

  @override
  String get profileAddPhone => 'मोबाईल नंबर जोडा (ऐच्छिक)';

  @override
  String get profilePhoneContactOnly =>
      'फक्त तुमच्याशी संपर्कासाठी. लॉगिन नेहमीप्रमाणे Google नेच होईल.';

  @override
  String get profileSaved => 'जतन झाले.';

  @override
  String get profileSignOut => 'लॉगआउट';

  @override
  String get profileSignOutTitle => 'लॉगआउट करायचे?';

  @override
  String get profileSignOutBody =>
      'तुमच्या नोंदी या फोनवरच राहतील. पुन्हा लॉगिन केल्यावर दिसतील.';

  @override
  String get profilePrivacy => 'गोपनीयता धोरण';

  @override
  String get profilePrivacyHint =>
      'दुवा कॉपी करण्यासाठी दाबा, मग ब्राउझरमध्ये उघडा';

  @override
  String get profileDeleteAccount => 'माझे खाते आणि माहिती काढून टाका';

  @override
  String get profileDeleteTitle => 'खाते काढून टाकायचे?';

  @override
  String profileDeleteBody(String word) {
    return 'तुमच्या सर्व नोंदी, फोटो आणि इतिहास सर्व्हरवरून आणि या फोनवरून पुसले जातील आणि तुम्ही लॉगआउट व्हाल. हे कायमचे आहे. खात्रीसाठी $word लिहा.';
  }

  @override
  String get profileDeleteWord => 'काढा';

  @override
  String get profileDeleteConfirm => 'कायमचे काढा';

  @override
  String get profileDeleteFailed =>
      'थोड्या वेळाने पुन्हा प्रयत्न करा: खाते काढण्यासाठी इंटरनेट आणि सर्व्हर लागतो. तुमची सर्व माहिती अजून जशीच्या तशी आहे.';

  @override
  String get boundaryWalk => 'चालत जाऊन सीमा नोंदवा';

  @override
  String get boundaryTitle => 'बागेची सीमा नोंदवा';

  @override
  String get boundaryHelp =>
      'बागेच्या एका कोपऱ्यात उभे राहा आणि “हा कोपरा जोडा” दाबा. प्रत्येक कोपऱ्यावर जाऊन असेच करा. किमान ३ कोपरे हवेत.';

  @override
  String get boundaryAdd => 'हा कोपरा जोडा';

  @override
  String get boundaryUndo => 'शेवटचा कोपरा काढा';

  @override
  String get boundaryDone => 'झाले';

  @override
  String boundaryCorners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कोपरे',
      one: '१ कोपरा',
    );
    return '$_temp0';
  }

  @override
  String boundaryArea(String acres) {
    return 'क्षेत्र सुमारे $acres एकर';
  }

  @override
  String boundaryAccuracy(String metres) {
    return '±$metres मी';
  }

  @override
  String get boundaryServiceOff => 'फोनमधील लोकेशन (GPS) चालू करा.';

  @override
  String get boundaryDenied => 'सीमा नोंदवण्यासाठी लोकेशनला परवानगी द्या.';

  @override
  String get boundaryDeniedForever =>
      'फोनच्या ॲप सेटिंगमध्ये लोकेशनला परवानगी द्या.';

  @override
  String get boundaryFailed =>
      'ठिकाण मिळवण्यासाठी मोकळ्या जागेत जाऊन पुन्हा प्रयत्न करा.';

  @override
  String boundaryMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कोपरे',
      one: '१ कोपरा',
    );
    return 'सीमा नोंदवली: $_temp0';
  }

  @override
  String get loginTryWithout => 'आधी ॲप वापरून पहा';

  @override
  String get localModeBanner =>
      'ऑफलाइन चाचणी मोड: तुमची माहिती या फोनमध्येच राहते';

  @override
  String testBuildBadge(String sha) {
    return 'चाचणी बिल्ड $sha';
  }

  @override
  String get settingsTitle => 'सेटिंग्ज';

  @override
  String get sendLogs => 'लॉग पाठवा';

  @override
  String get updateAvailable => 'नवीन आवृत्ती उपलब्ध — डाउनलोड करा';

  @override
  String get updateDismiss => 'बंद करा';

  @override
  String get updateDownload => 'डाउनलोड करा';

  @override
  String get updateRequiredTitle => 'नवीन आवृत्ती आवश्यक';

  @override
  String get updateRequiredBody =>
      'बागमित्र वापरत राहण्यासाठी नवीन आवृत्ती डाउनलोड करून इन्स्टॉल करा.';

  @override
  String updateLinkCopied(String url) {
    return 'लिंक कॉपी केली. ब्राउझरमध्ये पेस्ट करून डाउनलोड करा: $url';
  }

  @override
  String settingsVersion(String name, String code) {
    return 'आवृत्ती $name ($code)';
  }

  @override
  String get walkthroughSkip => 'वगळा';

  @override
  String get walkthroughNext => 'पुढे';

  @override
  String get walkthroughStart => 'सुरू करा';

  @override
  String get walkthroughPlotsTitle => 'तुमच्या बागा आणि बहार कॅलेंडर';

  @override
  String get walkthroughPlotsBody =>
      'तुमच्या बागा जोडा. प्रत्येक बहारसाठी हंगामाचे कॅलेंडर आणि करायच्या कामांची यादी दिसेल.';

  @override
  String get walkthroughWeatherTitle => 'तुमच्या बागेसाठी हवामान सूचना';

  @override
  String get walkthroughWeatherBody =>
      'तुमच्या बागेवरचे हवामान पहा. पाऊस किंवा उन्हाकडे लक्ष द्यायची गरज असेल तेव्हा सूचना मिळेल.';

  @override
  String get walkthroughMarketTitle => 'देशभरातील बाजारभाव';

  @override
  String get walkthroughMarketBody =>
      'तुमच्या पिकाचे भारतभरातील बाजारांमधले अलीकडचे भाव पहा.';

  @override
  String get walkthroughRecordsTitle => 'तुमच्या नोंदी आणि हिशोब';

  @override
  String get walkthroughRecordsBody =>
      'फवारणी, खर्च, मजुरी आणि विक्रीची नोंद ठेवा आणि हिशोब पहा. नेट बंद असले तरी ॲप चालते; नेटवर्क आल्यावर नोंदी पाठवल्या जातात.';

  @override
  String get settingsShowWalkthrough => 'ॲपची ओळख पुन्हा पहा';

  @override
  String get settingsNotifications => 'सूचना';

  @override
  String get settingsPushArticles => 'लेख';

  @override
  String get settingsPushArticlesHint => 'नवीन लेख आल्यावर';

  @override
  String get settingsPushMarket => 'बाजारभाव';

  @override
  String get settingsPushMarketHint => 'तुमच्या पिकाचा बाजारभाव बदलल्यावर';

  @override
  String get settingsPushWeather => 'हवामान बदल';

  @override
  String get settingsPushWeatherHint => 'बागेजवळचे हवामान अचानक बदलल्यावर';

  @override
  String get settingsPhotoMobileData => 'मोबाईल डेटावरही फोटोचा बॅकअप घ्या';

  @override
  String get settingsPhotoMobileDataHint =>
      'पाहणी व बिलांच्या फोटोंचा बॅकअप वाय-फायवर होतो. मोबाईल डेटाही वापरायचा असेल तर हे चालू करा.';

  @override
  String get settingsModelSources => 'फोटो मॉडेलचे डेटा स्रोत';

  @override
  String get settingsModelSourcesIntro =>
      'फोनवरील फोटो तपासणीचे मॉडेल या सार्वजनिक फोटो-संचांवर शिकवले आहे (शिकवण्यासाठी फोटोंचा आकार बदलला). परवाना: CC BY 4.0 (creativecommons.org/licenses/by/4.0).';

  @override
  String buildLabel(String sha) {
    return 'चाचणी बिल्ड $sha';
  }

  @override
  String get seedOrchard => 'नमुना बाग जोडा';

  @override
  String get seedOrchardDone => 'नमुना बाग जोडली';

  @override
  String get voiceUnavailable =>
      'कृपया इथे टाइप करा; आवाजाने लिहिणे त्याची सोय असलेल्या फोनवर चालते';

  @override
  String get voiceListening => 'ऐकत आहे… थांबवण्यासाठी दाबा';

  @override
  String get tasksTitle => 'कामे';

  @override
  String get addTask => 'काम जोडा';

  @override
  String get taskWhat => 'काय करायचे आहे?';

  @override
  String get taskKind => 'प्रकार';

  @override
  String get taskDue => 'कधी';

  @override
  String get dueToday => 'आज';

  @override
  String get dueTomorrow => 'उद्या';

  @override
  String get pickDate => 'तारीख निवडा';

  @override
  String get tasksEmpty => '+ बटणाने पहिले काम जोडा.';

  @override
  String get tasksOverdue => 'राहिलेली';

  @override
  String get tasksToday => 'आज';

  @override
  String get tasksUpcoming => 'पुढची';

  @override
  String get tasksDone => 'पूर्ण';

  @override
  String get noTasksToday => 'आजचा दिवस मोकळा';

  @override
  String get taskOverdue => 'आजच करा';

  @override
  String dueInDays(int n) {
    return '$n दिवसांत';
  }

  @override
  String get editPlot => 'बागेची माहिती बदला';

  @override
  String get plotOpenRecords => 'बहार, फवारणी आणि हिशोब';

  @override
  String get plotBoundaryNone => 'सीमा नोंदवा';

  @override
  String get plotCentre => 'मध्यबिंदू';

  @override
  String get plotLocation => 'ठिकाण';

  @override
  String get plotPointCapture => 'मी बागेत आहे — ठिकाण घ्या';

  @override
  String get plotPointWhy =>
      'या बागेच्या हवामान व इशाऱ्यांसाठी. ठिकाण फक्त आत्ता एकदाच घेतले जाते.';

  @override
  String get plotPointReading => 'ठिकाण घेत आहे…';

  @override
  String get plotPointTake => 'ठिकाण घ्या';

  @override
  String get plotPointRetake => 'ठिकाण पुन्हा घ्या';

  @override
  String get plotPointDenied =>
      'बागेचे ठिकाण जतन करण्यासाठी लोकेशनला परवानगी द्या.';

  @override
  String get plotPointOpenSettings => 'सेटिंग्ज उघडा';

  @override
  String get plotPointTryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get plotPointLater => 'बाग आत्ता जतन करा; ठिकाण नंतर कधीही घेता येईल.';

  @override
  String get boundaryWalkOptional => 'सीमा चालत नोंदवा (ऐच्छिक)';

  @override
  String get calendarTitle => 'हंगामाचे कॅलेंडर';

  @override
  String get calendarIntro =>
      'पुढील बारा महिन्यांतील तुमच्या बहाराच्या तारखा आणि कामे, तुम्ही नोंदवलेल्या माहितीवरून.';

  @override
  String get calendarMonthEmpty => 'हा महिना मोकळा आहे.';

  @override
  String get calendarStagePlanned => 'नियोजित';

  @override
  String get calendarStageDone => 'झाले';

  @override
  String get calendarOpen => 'हंगामाचे कॅलेंडर';

  @override
  String get baharCompareTitle => 'बहारांची तुलना';

  @override
  String get baharCompareIntro =>
      'प्रत्येक बहाराचा विचार करण्यासाठी प्रकाशित स्रोतांमधील मुद्दे. निर्णय तुमचाच; स्रोतांमध्ये कधी कधी मतभेद असतात.';

  @override
  String baharCompareLast(String bahar) {
    return 'या बागेतील मागील बहार: $bahar';
  }

  @override
  String get baharCompareNoLast =>
      'या बागेचा पहिला बहार नोंदवा, मग तो इथे दिसेल.';

  @override
  String baharCompareSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get baharCompareNoPoints =>
      'या बहाराची माहिती तयार झाल्यावर इथे दिसेल.';

  @override
  String get baharCompareUse => 'हा बहार निवडा';

  @override
  String get weatherTitle => 'हवामान';

  @override
  String weatherAsOf(String date) {
    return 'अद्ययावत: $date';
  }

  @override
  String get weatherStale =>
      'शेवटचे जतन केलेले दिवस दाखवत आहोत; पुढच्या वेळी हवामान मिळाल्यावर ते अद्ययावत होईल.';

  @override
  String get weatherNone => 'फोन ऑनलाइन असताना हवामान येईल.';

  @override
  String weatherRain(String mm) {
    return '$mm मि.मी. पाऊस';
  }

  @override
  String weatherSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get alertSwitchOff => 'हा अलर्ट बंद करा';

  @override
  String get alertSwitchOn => 'हा अलर्ट चालू करा';

  @override
  String alertTypeOff(String name) {
    return '$name अलर्ट बंद';
  }

  @override
  String get alertThisOff => 'हा अलर्ट बंद';

  @override
  String get alertNameHeat => 'उष्णता';

  @override
  String get alertNamePsylla => 'सायला';

  @override
  String get alertNameHail => 'गारपीट व वादळ';

  @override
  String get alertNameWind => 'जोरदार वारा';

  @override
  String get alertNameHeavyRain => 'मुसळधार पाऊस';

  @override
  String get alertNameUnseasonalRain => 'अवकाळी पाऊस';

  @override
  String get alertNameColdWave => 'थंडीची लाट';

  @override
  String get alertNameHumidity => 'दमट हवामान';

  @override
  String get weatherForecastTitle => 'हवामान अंदाज';

  @override
  String weatherForecastNext(String days) {
    return 'पुढील $days दिवस';
  }

  @override
  String get weatherColDay => 'दिवस';

  @override
  String get weatherColTemp => 'तापमान';

  @override
  String get weatherColRain => 'पाऊस';

  @override
  String get weatherColWind => 'वारा';

  @override
  String get weatherColHumidity => 'आर्द्रता';

  @override
  String get weatherUnitTemp => 'कमाल/किमान';

  @override
  String get weatherUnitRain => 'मि.मी./%';

  @override
  String get weatherUnitWind => 'किमी/तास';

  @override
  String get weatherLegendRain => 'पावसाची शक्यता';

  @override
  String weatherLegendHeat(String deg) {
    return '$deg° व अधिक';
  }

  @override
  String get weatherSkyClear => 'निरभ्र आकाश';

  @override
  String get weatherSkyCloudy => 'ढगाळ';

  @override
  String get weatherSkyRain => 'पाऊस';

  @override
  String get weatherSkyStorm => 'मेघगर्जनेसह पाऊस';

  @override
  String get weatherNowLabel => 'आत्ता';

  @override
  String weatherReadingAt(String time) {
    return '$time ला';
  }

  @override
  String weatherTodayMax(int degrees) {
    final intl.NumberFormat degreesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String degreesString = degreesNumberFormat.format(degrees);

    return 'आज कमाल $degreesString°';
  }

  @override
  String get weatherTodayMaxLabel => 'आज कमाल';

  @override
  String get weatherSkyClearNight => 'निरभ्र रात्र';

  @override
  String get labelInfoTitle => 'लेबल माहिती';

  @override
  String get labelInfoBanner =>
      'ही माहिती नोंदणीकृत लेबलवर (CIB&RC) छापलेली आहे; ती फक्त लेबलवरील माहिती आहे, शिफारस नाही. कोणताही वापर करण्यापूर्वी उत्पादनाचे लेबल वाचा आणि तुमच्या कृषी विज्ञान केंद्राकडून (KVK) किंवा कृषी अधिकाऱ्याकडून खात्री करून घ्या.';

  @override
  String get labelInfoEmpty =>
      'नोंदणीकृत लेबलची माहिती उपलब्ध झाल्यावर इथे दिसेल.';

  @override
  String labelInfoUpdated(String date) {
    return 'अद्ययावत: $date';
  }

  @override
  String get labelInfoDose => 'लेबलवरील मात्रा:';

  @override
  String labelInfoInterval(String days) {
    return 'दोन फवारण्यांमधील अंतर: $days दिवस';
  }

  @override
  String labelInfoPhi(String days) {
    return 'तोडणीपूर्वीचे $days दिवस (PHI)';
  }

  @override
  String labelInfoMaxSprays(String count) {
    return 'जास्तीत जास्त फवारण्या: $count';
  }

  @override
  String labelInfoCrop(String crop) {
    return 'लेबलवरील पीक: $crop';
  }

  @override
  String labelInfoSource(String title) {
    return 'स्रोत: $title';
  }

  @override
  String get marketPricesTitle => 'बाजारभाव';

  @override
  String get marketOpen => 'बाजारभाव';

  @override
  String get marketScopeAll => 'सर्व';

  @override
  String get marketScopeLocal => 'माझ्या जवळ';

  @override
  String get marketScopeMajor => 'मोठ्या बाजारपेठा';

  @override
  String get marketTagLocal => 'जवळची बाजारपेठ';

  @override
  String get marketTagMajor => 'मोठी बाजारपेठ';

  @override
  String get marketPerQuintal => 'प्रति क्विंटल';

  @override
  String marketRange(String min, String max) {
    return 'किमान–कमाल: $min – $max';
  }

  @override
  String marketVariety(String variety) {
    return 'वाण: $variety';
  }

  @override
  String marketUpdated(String date) {
    return 'अद्ययावत: $date';
  }

  @override
  String get marketTrendOpen => 'भावाचा कल';

  @override
  String marketTrendTitle(String market) {
    return 'भावाचा कल: $market';
  }

  @override
  String get marketTrendRange15 => '१५ दिवस';

  @override
  String get marketTrendRange30 => '१ महिना';

  @override
  String get marketTrendRange90 => '३ महिने';

  @override
  String get marketTrendHigh => 'सर्वाधिक';

  @override
  String get marketTrendLow => 'सर्वात कमी';

  @override
  String get marketTrendChange15 => '१५ दिवसांत';

  @override
  String get marketTrendChange30 => '१ महिन्यात';

  @override
  String get marketTrendHint =>
      'प्रत्येक दिवसाचा भाव पाहण्यासाठी चार्टवर बोट फिरवा.';

  @override
  String get marketTrendCollecting =>
      'भाव दररोज साठवला जातो; चार्ट दिवसागणिक भरत जातो.';

  @override
  String marketTrendSemantics(
    String range,
    String high,
    String low,
    String latest,
  ) {
    return 'भावाचा कल, $range: सर्वाधिक $high, सर्वात कमी $low, ताजा $latest प्रति क्विंटल';
  }

  @override
  String marketStale(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'source_not_configured': 'बाजारभाव सेवा लवकरच सुरू होईल.',
      'other': 'शेवटचे जतन केलेले भाव दाखवत आहोत; पुढच्या वेळी भाव मिळाल्यावर ते अद्ययावत होतील.',
    });
    return '$_temp0';
  }

  @override
  String get marketStaleNoReason =>
      'शेवटची जतन केलेली यादी दाखवत आहोत; पुढच्या वेळी भाव मिळाल्यावर ती अद्ययावत होईल.';

  @override
  String get marketEmpty =>
      'फोन ऑनलाइन असताना आणि बाजारभाव सेवा सुरू असताना भाव इथे दिसतील.';

  @override
  String get marketCrop => 'पीक';

  @override
  String marketCropSoon(String crop) {
    return '$crop पिकाचे भाव लवकरच इथे दिसतील. बाजारभाव दर ६ तासांनी आपोआप अद्ययावत होतात.';
  }

  @override
  String get marketSearchOpen => 'मंडी शोधा';

  @override
  String get marketSearchClose => 'शोध बंद करा';

  @override
  String get marketSearchHint => 'मंडी, जिल्हा किंवा राज्य';

  @override
  String get marketSearchClear => 'पुसा';

  @override
  String marketSearchEmpty(String query) {
    return '“$query” ऐवजी दुसरे मंडी, जिल्हा किंवा राज्याचे नाव लिहून पाहा.';
  }

  @override
  String get practicesOpen => 'बाग व्यवस्थापन पद्धती (रसायनविरहित)';

  @override
  String get practicesTitle => 'बाग व्यवस्थापन पद्धती';

  @override
  String practicesSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get practicesEvidenceOfficial => 'शासकीय';

  @override
  String get practicesEvidenceUniversity => 'विद्यापीठ';

  @override
  String get practicesEvidenceResearch => 'संशोधन निष्कर्ष';

  @override
  String get practicesEvidenceInferred => 'अनुमानित';

  @override
  String get practicesGapsTitle => 'यांसाठी रसायनविरहित उपाय अजून शोधायचा आहे';

  @override
  String get practicesSourcesLine =>
      'स्रोत: NHB आणि डॉ. पंदेकृवि, अकोला. प्रत्येक पद्धतीखाली तपशील.';

  @override
  String get scoutingTitle => 'पाहणी नोंद';

  @override
  String get scoutingAdd => 'पाहणी नोंदवा';

  @override
  String get scoutingEmpty => 'पहिली पाहणी नोंदवा: या बागेत काय दिसले ते लिहा.';

  @override
  String get scoutingDate => 'तारीख';

  @override
  String get scoutingWhat => 'काय पाहिले?';

  @override
  String get scoutingSeverity => 'किती प्रमाणात?';

  @override
  String get scoutingNote => 'टीप (ऐच्छिक)';

  @override
  String get scoutingPhoto => 'फोटो (ऐच्छिक)';

  @override
  String get scoutingPhotoBackedUp => 'फोटोचा बॅकअप झाला';

  @override
  String get scoutingCamera => 'कॅमेरा';

  @override
  String get scoutingGallery => 'गॅलरी';

  @override
  String get scoutingRemovePhoto => 'फोटो हटवा';

  @override
  String get scoutingPhotoFailed => 'कृपया फोटो पुन्हा घ्या.';

  @override
  String get scoutingPickOne => 'एक निवडा';

  @override
  String get scoutingItemPsylla => 'सिट्रस सायला';

  @override
  String get scoutingItemLeafMiner => 'पाने पोखरणारी अळी';

  @override
  String get scoutingItemMitesThrips => 'कोळी / फुलकिडे';

  @override
  String get scoutingItemFruitDrop => 'फळगळ';

  @override
  String get scoutingItemGummosis => 'डिंक्या / साल';

  @override
  String get scoutingItemDieBack => 'फांद्या वाळणे (डायबॅक)';

  @override
  String get scoutingItemOther => 'इतर';

  @override
  String get scoutingSeverityNone => 'शून्य';

  @override
  String get scoutingSeverityLow => 'कमी';

  @override
  String get scoutingSeverityMedium => 'मध्यम';

  @override
  String get scoutingSeverityHigh => 'जास्त';

  @override
  String get irrigationOpen => 'ओलित तक्ता';

  @override
  String get irrigationGuideTitle => 'ओलित तक्ता';

  @override
  String get irrigationCaveat =>
      'पाण्याचे प्रमाण जमीन, झाडाचा घेर आणि हवामानावर अवलंबून असते.';

  @override
  String get irrigationCropLabel => 'पीक';

  @override
  String get irrigationAgeLabel => 'झाडाचे वय';

  @override
  String irrigationPlanted(String year, String years) {
    return 'लागवड $year: सुमारे $years वर्षांची झाडे';
  }

  @override
  String get irrigationNoPlantingYear =>
      'झाडाचे वय निवडा, किंवा या बागेचे लागवड वर्ष भरा.';

  @override
  String get irrigationNoRows => 'या वयासाठीचा आकडा अजून स्रोतात शोधायचा आहे.';

  @override
  String get irrigationStagesTitle => 'फुलोरा, फळ आणि बहाराचा ताण';

  @override
  String get irrigationGapsTitle => 'स्रोतात अजून शोधायचे आहे';

  @override
  String get irrigationSourcesLine =>
      'स्रोत: NHB, डॉ. पंदेकृवि अकोला आणि प्रकाशित लिंबूवर्गीय संशोधन. प्रत्येक मुद्द्याखाली तपशील.';

  @override
  String get feedTitle => 'सरकारी संदेश';

  @override
  String get feedOpenHint => 'अधिकृत GR, योजना आणि शेवटच्या तारखा';

  @override
  String get feedFilterAll => 'सर्व';

  @override
  String get feedFilterOfficial => 'अधिकृत';

  @override
  String get feedFilterSchemes => 'योजना';

  @override
  String get feedFilterDeadlines => 'शेवटच्या तारखा';

  @override
  String get feedFilterNews => 'बातम्या';

  @override
  String get feedFilterKnowledge => 'ज्ञान';

  @override
  String get feedBadgeKnowledge => 'ज्ञान लेख';

  @override
  String get feedKnowledgeOpenCard => 'उपाय व माहिती पहा';

  @override
  String get feedKnowledgeNote =>
      'ही सर्वसाधारण माहिती आहे. कृती करण्यापूर्वी आपल्या KVK किंवा कृषी अधिकाऱ्याला विचारा.';

  @override
  String get feedBadgeOfficial => 'अधिकृत';

  @override
  String get feedLevelCentral => 'केंद्र शासन';

  @override
  String get feedLevelState => 'महाराष्ट्र शासन';

  @override
  String get feedArticleKeyPoints => 'मुख्य मुद्दे';

  @override
  String get feedAiTag => 'AI ने निर्मित';

  @override
  String get feedArticleFacts => 'एका नजरेत';

  @override
  String get feedArticleKeyDates => 'महत्त्वाच्या तारखा';

  @override
  String get feedArticleSources => 'स्रोत';

  @override
  String feedGrNumber(String number) {
    return 'GR क्र. $number';
  }

  @override
  String get feedBadgeNews => 'बातमी';

  @override
  String feedReplacedBy(String replacement) {
    return 'मागे घेतले. याच्या जागी आता: $replacement';
  }

  @override
  String feedExpired(String date) {
    return '$date ला संपले';
  }

  @override
  String feedMayBeEligible(String reason) {
    return 'तुम्ही पात्र असू शकता कारण $reason';
  }

  @override
  String get feedFooter =>
      'कोणतीही कृती करण्यापूर्वी अधिकृत शासन निर्णय (GR) / पोर्टल तपासा.';

  @override
  String feedDeadline(String date) {
    return 'शेवटची तारीख: $date';
  }

  @override
  String feedUpdated(String date) {
    return '$date ला अद्ययावत';
  }

  @override
  String get feedEmpty => 'फोन ऑनलाइन असताना संदेश येतील.';

  @override
  String get feedEmptyAll => 'नवीन संदेश आल्यावर इथे दिसतील.';

  @override
  String get feedEmptyOfficial =>
      'अधिकृत शासन निर्णय व सूचना आल्यावर इथे दिसतील.';

  @override
  String get feedEmptySchemes => 'नवीन योजना आल्यावर इथे दिसतील.';

  @override
  String get feedEmptyDeadlines =>
      'अर्जाच्या शेवटच्या तारखा आल्यावर इथे दिसतील.';

  @override
  String get feedEmptyNews => 'नवीन बातम्या आल्यावर इथे दिसतील.';

  @override
  String get feedEmptyKnowledge => 'ज्ञान लेख परिस्थितीनुसार इथे येतील.';

  @override
  String get feedRemindMe => 'मला आठवण करा';

  @override
  String feedReminderAdded(String date) {
    return '$date साठी तुमच्या कामांत जोडले';
  }

  @override
  String get feedReminderExists => 'आधीच तुमच्या कामांत आहे';

  @override
  String get feedShare => 'पाठवा';

  @override
  String get feedCopyLink => 'स्रोताची लिंक कॉपी करा';

  @override
  String get feedLinkCopied => 'लिंक कॉपी झाली. ब्राउझरमध्ये उघडा.';

  @override
  String feedSource(String url) {
    return 'स्रोत: $url';
  }

  @override
  String get feedNotFound => 'हा संदेश जतन यादीतून काढला गेला आहे.';

  @override
  String get feedUnseen => 'नवीन';

  @override
  String feedThreadCount(String count) {
    return '$count बातम्या';
  }

  @override
  String feedThreadLatest(String date) {
    return 'ताजी बातमी: $date';
  }

  @override
  String get feedThreadTimeline => 'सर्व बातम्या, क्रमाने (जुनी आधी)';

  @override
  String get feedThreadOpenItem => 'पूर्ण बातमी वाचा';

  @override
  String get feedDismiss => 'माझ्या यादीतून काढा';

  @override
  String get feedDismissed => 'तुमच्या यादीतून काढले.';

  @override
  String get feedPrefsTitle => 'सूचना सेटिंग';

  @override
  String get feedPrefsQuietTitle => 'शांत वेळ (सूचना शांत राहतील)';

  @override
  String get feedPrefsQuietStart => 'पासून';

  @override
  String get feedPrefsQuietEnd => 'पर्यंत';

  @override
  String feedPrefsWeeklyCap(String count) {
    return 'आठवड्यात जास्तीत जास्त $count सूचना';
  }

  @override
  String get feedPrefsCapLess => 'कमी';

  @override
  String get feedPrefsCapMore => 'जास्त';

  @override
  String get feedPrefsCategoriesTitle => 'या गोष्टींच्या सूचना पाठवा';

  @override
  String get feedPrefsCatDeadline => 'जवळ आलेल्या शेवटच्या तारखा';

  @override
  String get feedPrefsCatPayment => 'पैसे जमा झाल्याची माहिती';

  @override
  String get feedPrefsCatWindowOpen => 'अर्ज सुरू झाले';

  @override
  String get feedPrefsDigest => 'आठवड्याचा सारांश';

  @override
  String get feedPrefsDigestHint => 'आठवड्यातून एकदा नवीन माहितीचा एक संदेश.';

  @override
  String get feedPrefsSave => 'जतन करा';

  @override
  String get feedPrefsSaved => 'सेटिंग जतन झाली.';

  @override
  String get feedPrefsSaveFailed => 'इंटरनेट आल्यावर पुन्हा जतन करा.';

  @override
  String get feedPrefsOffline =>
      'ही तुमची शेवटची जतन केलेली सेटिंग आहे. बदल जतन करायला इंटरनेट चालू करा.';

  @override
  String get feedCheckTitle => 'संदेश तपासा';

  @override
  String get feedCheckIntro =>
      'WhatsApp वर GR किंवा योजनेचा संदेश आला? इथे पेस्ट करा, आम्ही अधिकृत GR शोधू.';

  @override
  String get feedCheckHint => 'संदेश इथे पेस्ट करा';

  @override
  String get feedCheckPaste => 'पेस्ट करा';

  @override
  String get feedCheckButton => 'तपासा';

  @override
  String get feedCheckFailed =>
      'तपासणीसाठी इंटरनेट लागते; इंटरनेट आल्यावर पुन्हा प्रयत्न करा.';

  @override
  String get feedCheckOfficial => 'अधिकृत GR सापडला';

  @override
  String get feedCheckPossible => 'कदाचित संबंधित अधिकृत संदेश';

  @override
  String get feedCheckNoMatch => 'जुळणारा अधिकृत संदेश सापडला नाही.';

  @override
  String get feedCheckPortal => 'काही करण्याआधी अधिकृत पोर्टल तपासा.';

  @override
  String get shareAction => 'पाठवा';

  @override
  String get speakAction => 'वाचून दाखवा';

  @override
  String get speakUnavailable =>
      'मोठ्याने वाचण्यासाठी फोनवर या भाषेचा आवाज लागतो.';

  @override
  String shareSentFrom(String app) {
    return '$app ॲपवरून पाठवले';
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
  String get taskDetails => 'कामाची माहिती';

  @override
  String tasksTodayShare(String date) {
    return 'आजची कामे ($date)';
  }

  @override
  String get loadingLabel => 'माहिती येत आहे';

  @override
  String get accountSwitchTitle => 'दुसऱ्या खात्याच्या नोंदी';

  @override
  String get accountSwitchBody =>
      'या फोनवर दुसऱ्या खात्याच्या नोंदी आहेत. पुढे गेल्यास त्या या फोनवरून काढल्या जातील (सर्व्हरवर सुरक्षित राहतील) आणि तुमच्या नोंदी डाउनलोड होतील.';

  @override
  String get accountSwitchContinue => 'पुढे जा';

  @override
  String get accountBlockedTitle => 'या फोनवर पाठवायच्या बाकी नोंदी';

  @override
  String accountBlockedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आधीच्या खात्याच्या $count नोंदी अजून पाठवायच्या बाकी आहेत.',
      one: 'आधीच्या खात्याची १ नोंद अजून पाठवायची बाकी आहे.',
    );
    return '$_temp0 त्या खात्याने पुन्हा लॉगिन करा आणि इंटरनेट चालू ठेवून ॲप उघडा, म्हणजे त्या पाठवल्या जातील. मग या खात्याने लॉगिन करा.';
  }

  @override
  String accountPreviousPhone(String phone) {
    return 'आधीचे खाते: $phone';
  }

  @override
  String get insuranceTitle => 'पीक विमा';

  @override
  String get insuranceEmpty =>
      'या बागेसाठी घेतलेला पीक विमा नोंदवा, किंवा नुकसान झाल्यावर नुकसान नोंद किट उघडा.';

  @override
  String get insurancePoliciesNone => 'पहिली विमा पॉलिसी नोंदवा.';

  @override
  String get insuranceAdd => 'विमा नोंदवा';

  @override
  String get insuranceEdit => 'विमा नोंद बदला';

  @override
  String get insuranceScheme => 'योजना';

  @override
  String get insuranceSchemePmfby => 'प्रधानमंत्री पीक विमा (PMFBY)';

  @override
  String get insuranceSchemeRwbcis => 'हवामान आधारित फळपीक विमा (RWBCIS)';

  @override
  String get insuranceSchemeOther => 'इतर';

  @override
  String get insuranceSchemeUnknown => 'तपासायचे आहे';

  @override
  String get insuranceSeason => 'बहार';

  @override
  String get insuranceSeasonAmbia => 'आंबिया बहार';

  @override
  String get insuranceSeasonMrig => 'मृग बहार';

  @override
  String get insuranceSeasonYear => 'वर्ष (ऐच्छिक)';

  @override
  String get insuranceInsurer => 'विमा कंपनी (ऐच्छिक)';

  @override
  String get insurancePolicyNumber => 'पॉलिसी किंवा अर्ज क्रमांक (ऐच्छिक)';

  @override
  String get insuranceSumInsured => 'विमा संरक्षित रक्कम ₹ (ऐच्छिक)';

  @override
  String get insurancePremium => 'भरलेला हप्ता ₹ (ऐच्छिक)';

  @override
  String get insuranceAmountsHint => 'रक्कम फक्त पावतीवर छापल्याप्रमाणे लिहा.';

  @override
  String get insuranceEnrolledOn => 'नोंदणीची तारीख';

  @override
  String get insuranceNotSet => 'भरायची आहे';

  @override
  String get insuranceNote => 'टीप (ऐच्छिक)';

  @override
  String insurancePolicyNo(String number) {
    return 'क्र. $number';
  }

  @override
  String insuranceEnrolled(String date) {
    return 'नोंदणी $date';
  }

  @override
  String insurancePremiumLine(String amount) {
    return 'भरलेला हप्ता $amount';
  }

  @override
  String insuranceSumLine(String amount) {
    return 'विमा रक्कम $amount';
  }

  @override
  String insuranceDeadline(String date) {
    return 'नोंदणीची अंतिम मुदत: $date';
  }

  @override
  String get insuranceDeadlineNote =>
      'प्रकाशित अधिकृत सूचनेनुसार. काही करण्याआधी सूचना तपासा.';

  @override
  String get insuranceDeletePolicy => 'विमा नोंद हटवा';

  @override
  String get insuranceDeleteConfirm => 'ही विमा नोंद हटवायची?';

  @override
  String get insuranceClaims => 'नुकसान नोंदी';

  @override
  String insuranceClaimLine(String date, String count) {
    return 'नुकसान $date · फोटो: $count';
  }

  @override
  String get claimKitTitle => 'नुकसान नोंद किट';

  @override
  String get claimKitFromAlert => 'नुकसानीचे फोटो · नुकसान नोंद किट';

  @override
  String get claimKitPlot => 'बाग';

  @override
  String get claimKitPickPlot => 'बाग निवडा';

  @override
  String get claimKitDate => 'नुकसानीची तारीख';

  @override
  String get claimKitPhotos => 'नुकसानीचे फोटो (तारीख व GPS जोडले जातात)';

  @override
  String get claimKitNoPhotos => 'नुकसानीचे फोटो घ्या; ते इथे दिसतील.';

  @override
  String get claimKitNoGps => 'GPS शिवाय';

  @override
  String get claimKitRemovePhoto => 'फोटो हटवा';

  @override
  String get claimKitNote => 'काय झाले? (ऐच्छिक)';

  @override
  String get claimKitChecklist => 'तपासणी यादी';

  @override
  String get claimKitCheckPolicy =>
      'ही फक्त सर्वसाधारण माहिती आहे. नियम व मुदत पॉलिसीनुसार बदलतात: तुमची पॉलिसी, बँक किंवा CSC कडे तपासा.';

  @override
  String get claimCheckInform72h =>
      'नुकसानीची माहिती विमा कंपनी, तुमची बँक किंवा CSC केंद्राला शक्य तितक्या लवकर द्या; किती दिवसांत कळवायचे ते तुमच्या पॉलिसीत तपासा.';

  @override
  String get claimCheckPhotos =>
      'नुकसानीचे तारीख असलेले फोटो बागेच्या वेगवेगळ्या बाजूंनी काढा.';

  @override
  String get claimCheckPanchnama =>
      'पंचनामा करून घ्या आणि त्याची प्रत जपून ठेवा.';

  @override
  String get claimCheckPolicyCopy =>
      'पॉलिसी किंवा अर्जाची पावती आणि बँक पासबुकची प्रत तयार ठेवा.';

  @override
  String get claimCheckAcknowledgement =>
      'कळवताना मिळालेला तक्रार / डॉकेट क्रमांक लिहून ठेवा.';

  @override
  String get claimCheckKeepFruit =>
      'पाहणी होईपर्यंत खराब फळे व झाडे तशीच ठेवा; वेगळे सांगितले असल्यास त्याप्रमाणे करा.';

  @override
  String get claimKitShare => 'PDF पाठवा';

  @override
  String get claimKitShareFailed => 'कृपया PDF पुन्हा तयार करा.';

  @override
  String get claimKitDelete => 'नुकसान नोंद हटवा';

  @override
  String get claimKitDeleteConfirm =>
      'ही नुकसान नोंद व तिचे फोटो या फोनवरून हटवायचे?';

  @override
  String get claimPdfTitle => 'पीक नुकसान नोंद';

  @override
  String get claimPdfPlotGps => 'बागेचे ठिकाण (GPS)';

  @override
  String get claimPdfNoGps => 'नोंदवायचे आहे';

  @override
  String get claimPdfPolicy => 'विमा';

  @override
  String get claimPdfPhotos => 'फोटो';

  @override
  String get claimPdfNote => 'टीप';

  @override
  String get claimPdfDone => 'केले';

  @override
  String get claimPdfNotDone => 'बाकी';

  @override
  String claimPdfMade(String date) {
    return '$date रोजी तयार. शेतकऱ्याने ठेवलेली नोंद, विमा कंपनीचे कागदपत्र नाही.';
  }

  @override
  String get insurancePolicies => 'विमा नोंदी';

  @override
  String get labTestsTitle => 'माती, पाणी व पान तपासणी';

  @override
  String get labTestsEmpty =>
      'प्रयोगशाळेच्या अहवालातून किंवा मृदा आरोग्य पत्रिकेतून या बागेची पहिली तपासणी नोंदवा.';

  @override
  String get labTestAdd => 'तपासणी नोंदवा';

  @override
  String get labTestEdit => 'तपासणी बदला';

  @override
  String get labTestType => 'कशाची तपासणी';

  @override
  String get labTestTypeSoil => 'माती';

  @override
  String get labTestTypeWater => 'पाणी';

  @override
  String get labTestTypeLeaf => 'पान';

  @override
  String get labTestTitleSoil => 'माती तपासणी';

  @override
  String get labTestTitleWater => 'पाणी तपासणी';

  @override
  String get labTestTitleLeaf => 'पान तपासणी';

  @override
  String get labTestSampledOn => 'नमुना घेतल्याची तारीख';

  @override
  String get labTestReportedOn => 'अहवालाची तारीख';

  @override
  String get labTestLab => 'प्रयोगशाळेचे नाव';

  @override
  String get labTestReadings => 'अहवालातील आकडे';

  @override
  String get labTestReadingsHint =>
      'अहवालात जसे लिहिले आहे तसेच प्रत्येक आकडा लिहा.';

  @override
  String get labTestParameter => 'नाव (pH, EC …)';

  @override
  String get labTestValue => 'आकडा';

  @override
  String get labTestUnit => 'एकक';

  @override
  String get labTestAddReading => 'आकडा जोडा';

  @override
  String get labTestRemoveReading => 'हा आकडा काढा';

  @override
  String get labTestSuggestions => 'बहुतेक अहवालांतील नावे (जोडण्यासाठी दाबा)';

  @override
  String get labTestReadingIncomplete => 'नाव व आकडा दोन्ही लिहा';

  @override
  String get labTestNote => 'टीप';

  @override
  String get labTestReport => 'अहवालाचा फोटो किंवा फाइल';

  @override
  String get labTestReportFile => 'फाइल (PDF)';

  @override
  String get labTestReportRemove => 'काढा';

  @override
  String get labTestReportFailed => 'अहवाल पुन्हा जोडून पहा.';

  @override
  String get labTestReportMissing => 'अहवालाची फाइल पुन्हा जोडा.';

  @override
  String get labTestShareReport => 'अहवाल पाठवा';

  @override
  String get labTestAskExpert =>
      'हा अहवाल तज्ज्ञांकडून वाचून घ्या; ते आकड्यांचा अर्थ समजावून सांगतील.';

  @override
  String get labTestNextDue => 'पुढील तपासणी (आठवण)';

  @override
  String get labTestNextDueHint => 'आठवणीचे काम हवे असेल तरच तारीख निवडा.';

  @override
  String get labTestNextDueClear => 'आठवणीची तारीख काढा';

  @override
  String get labTestReminderSoil => 'पुढील माती तपासणी';

  @override
  String get labTestReminderWater => 'पुढील पाणी तपासणी';

  @override
  String get labTestReminderLeaf => 'पुढील पान तपासणी';

  @override
  String get labTestDelete => 'तपासणी नोंद काढा';

  @override
  String get labTestDeleteConfirm =>
      'ही तपासणी नोंद व तिचा अहवाल या फोनवरून काढायचा?';

  @override
  String labTestSampledLine(String date) {
    return 'नमुना $date';
  }

  @override
  String labTestReportedLine(String date) {
    return 'अहवाल $date';
  }

  @override
  String labTestLabLine(String name) {
    return 'प्रयोगशाळा: $name';
  }

  @override
  String labTestValuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आकडे',
      one: '१ आकडा',
      zero: 'आकडे लिहा',
    );
    return '$_temp0';
  }

  @override
  String get labTestNoValues => 'अहवालातील आकडे इथे लिहा.';

  @override
  String get labTestEditAction => 'बदला';

  @override
  String get schemesTitle => 'योजना व कागदपत्रे';

  @override
  String get schemesHomeHint =>
      'कोण अर्ज करू शकतो, कोणती कागदपत्रे तयार ठेवावी';

  @override
  String get schemesIntro =>
      'तयारीसाठी सर्वसाधारण माहिती. रक्कम आणि अटी अधिकृत पानावर पहा आणि मगच अर्ज करा.';

  @override
  String get schemeVisitSetu =>
      'अर्ज, कागदपत्रे आणि अधिक माहितीसाठी जवळच्या सेतू केंद्राला (आपले सरकार सेवा केंद्र / CSC) भेट द्या.';

  @override
  String get schemeWho => 'कोण अर्ज करू शकतो';

  @override
  String get schemeDocuments => 'सहसा लागणारी कागदपत्रे';

  @override
  String get schemeDocumentsHint => 'जे आधीच आहे त्यावर खूण करा.';

  @override
  String schemeDocsReady(int have, int total) {
    return '$total पैकी $have तयार';
  }

  @override
  String get schemeNotConfirmed => 'अधिकृत पानावर एकदा खात्री करून घ्या';

  @override
  String get schemeWhereToApply => 'कुठे अर्ज करावा';

  @override
  String get schemeFeedItems => 'संबंधित शासकीय सूचना';

  @override
  String schemeShareDocs(String scheme) {
    return '$scheme साठी कागदपत्रे:';
  }

  @override
  String get schemeShareHave => 'आहे';

  @override
  String get schemeShareMissing => 'मिळवायचे';

  @override
  String get lookalikesTitle => 'सारखी दिसणारी लक्षणे';

  @override
  String get lookalikesOpen => 'सारखी दिसणारी लक्षणे';

  @override
  String get lookalikesIntro =>
      'बागेतील अनेक समस्या सारख्याच दिसतात; ही कार्डे तुम्हाला जे दिसते ते नेमके सांगायला मदत करतात.';

  @override
  String get lookalikesSee => 'काय दिसू शकते';

  @override
  String get lookalikesConfusedWith => 'यासारखे दिसणारे';

  @override
  String get lookalikesConfirm => 'खात्री कोण करू शकते';

  @override
  String get lookalikesCheckLine =>
      'खात्री हवी? फोटो घ्या, पाहणी नोंदीत लिहा आणि निर्णय घेण्याआधी प्रयोगशाळा किंवा तज्ज्ञांकडून तपासून घ्या.';

  @override
  String get lookalikesLogThis => 'पाहणी नोंदीत लिहा';

  @override
  String get lookalikesFindLab => 'प्रयोगशाळा / तज्ज्ञ शोधा';

  @override
  String get lookalikesSources => 'स्रोत';

  @override
  String get lookalikesDraft => 'मसुदा: एक स्रोत अजून तपासायचा आहे';

  @override
  String get lookalikesEmpty => 'कार्डे इथे दिसतील.';

  @override
  String get labsTitle => 'प्रयोगशाळा व तज्ज्ञ';

  @override
  String get labsOpen => 'प्रयोगशाळा व तज्ज्ञ';

  @override
  String get marketDirectoryTitle => 'बाजार व खरेदीदार';

  @override
  String get marketDirectoryOpen => 'बाजार व खरेदीदार';

  @override
  String get directoryAll => 'सर्व';

  @override
  String get directoryUnverified => 'अधिकृत पानावर एकदा खात्री करून घ्या';

  @override
  String get directoryCopyNumber => 'नंबर कॉपी करा';

  @override
  String get directoryNumberCopied => 'नंबर कॉपी झाला';

  @override
  String get directoryCopyLink => 'लिंक कॉपी करा';

  @override
  String directoryWebPage(Object url) {
    return 'संकेतस्थळ: $url';
  }

  @override
  String directoryPhone(Object phone) {
    return 'फोन: $phone';
  }

  @override
  String directoryDetailsFrom(Object url) {
    return 'माहितीचा स्रोत: $url';
  }

  @override
  String get directoryCheckLine =>
      'माहिती अधिकृत पानांवरून घेतली आहे. प्रवासापूर्वी फोन करून किंवा पान पाहून खात्री करा.';

  @override
  String get directoryEmpty => 'नोंदी इथे दिसतील.';

  @override
  String get directoryKindResearch => 'संशोधन संस्था';

  @override
  String get directoryKindUniversity => 'कृषी विद्यापीठ';

  @override
  String get directoryKindKvk => 'कृषी विज्ञान केंद्र';

  @override
  String get directoryKindSoilLab => 'माती परीक्षण';

  @override
  String get directoryKindPortal => 'बाजारभाव व आवक';

  @override
  String get directoryKindApmc => 'बाजार समिती (APMC)';

  @override
  String get directoryKindExport => 'निर्यात';

  @override
  String get directoryKindProcessor => 'प्रक्रिया उद्योग';

  @override
  String get exportInfoTitle => 'निर्यात माहिती';

  @override
  String get exportInfoNote =>
      'माहितीसाठी. निर्यातीचा व्यवहार तुमच्या व निर्यातदाराच्या दरम्यान.';

  @override
  String get exportSectionDestinations => 'फळ कुठे जाते';

  @override
  String get exportSectionSeason => 'बहार व निर्यात (निर्यातदाराच्या मते)';

  @override
  String get exportSectionSpecs => 'खरेदीदारांची मागणी (सांगितल्याप्रमाणे)';

  @override
  String get exportSectionRules => 'शेतकऱ्याला लागू नियम';

  @override
  String get exportLinksTitle => 'अधिकृत संकेतस्थळे';

  @override
  String get exportRecordTitle => 'निर्यात नोंद';

  @override
  String get exportRecordAction => 'निर्यात नोंद (PDF) बनवा';

  @override
  String get exportRecordPlot => 'बाग';

  @override
  String get exportRecordBahar => 'बहार';

  @override
  String get exportRecordAllBahars => 'सर्व फवारण्या';

  @override
  String exportRecordCount(String count) {
    return '$count फवारण्या';
  }

  @override
  String exportRecordLastPhi(String date) {
    return 'शेवटचा PHI कालावधी $date ला संपतो';
  }

  @override
  String get exportRecordShare => 'PDF शेअर करा';

  @override
  String get exportRecordNoPlot => 'आधी बाग जोडा; तिची फवारणी नोंद इथे दिसेल.';

  @override
  String get exportRecordEmpty =>
      'या बहाराच्या फवारण्या नोंदवल्यावर इथे दिसतील.';

  @override
  String get exportRecordDate => 'तारीख';

  @override
  String get exportRecordProduct => 'औषध · घटक · मात्रा';

  @override
  String get exportRecordLabel => 'लेबल तपासणी';

  @override
  String get exportRecordPhiEnd => 'PHI संपते';

  @override
  String get exportLabelListed => 'या पिकासाठी लेबलवर';

  @override
  String get exportLabelCheck => 'लेबल तपासा';

  @override
  String exportRecordMade(String date) {
    return '$date रोजी शेतकऱ्याच्या स्वतःच्या फवारणी नोंदीतून तयार.';
  }

  @override
  String get exportRecordFooter => 'माहितीसाठी नोंद, प्रमाणपत्र नाही.';

  @override
  String fairPriceMandi(Object date, Object market, Object price) {
    return '$market बाजार, $date: सर्वसाधारण भाव $price प्रति क्विंटल';
  }

  @override
  String fairPriceAbove(Object percent) {
    return 'तुमचा दर बाजाराच्या सर्वसाधारण भावापेक्षा $percent% जास्त आहे.';
  }

  @override
  String fairPriceBelow(Object percent) {
    return 'तुमचा दर बाजाराच्या सर्वसाधारण भावापेक्षा $percent% कमी आहे.';
  }

  @override
  String get fairPriceSame => 'तुमचा दर बाजाराच्या सर्वसाधारण भावाइतकाच आहे.';

  @override
  String get loginPhoneUnavailable => 'आत्ता Google ने लॉगिन करा';

  @override
  String get loginResendOtp => 'OTP पुन्हा पाठवा';

  @override
  String loginResendIn(int seconds) {
    return '$seconds सेकंदांनी OTP पुन्हा मागवता येईल';
  }

  @override
  String get loginOtpResent => 'नवीन OTP पाठवला आहे';

  @override
  String get loginChangeNumber => 'नंबर बदला';

  @override
  String get loginTitleGoogle => 'Google खात्याने सुरू करा';

  @override
  String get netOffline => 'इंटरनेट तपासा आणि पुन्हा प्रयत्न करा';

  @override
  String get netServer =>
      'सर्व्हर थोडा व्यस्त आहे; थोड्या वेळाने पुन्हा प्रयत्न करा';

  @override
  String get netSignedOut => 'नवीन माहितीसाठी पुन्हा लॉगिन करा';

  @override
  String get netRetry => 'पुन्हा प्रयत्न करा';

  @override
  String get signInAgain => 'लॉगिन करा';

  @override
  String get syncSignedOutBanner => 'नोंदी पाठवण्यासाठी पुन्हा लॉगिन करा';

  @override
  String syncRejectedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नोंदी तपासायच्या आहेत',
      one: '१ नोंद तपासायची आहे',
    );
    return '$_temp0';
  }

  @override
  String get syncReview => 'पहा';

  @override
  String get syncRejectedTitle => 'तपासायच्या नोंदी';

  @override
  String get syncRejectedHelp =>
      'प्रत्येक नोंद पुन्हा पाठवा किंवा या यादीतून हटवा; फोनवरील माहिती तशीच राहते.';

  @override
  String get syncRejectedDone => 'सर्व नोंदी व्यवस्थित आहेत';

  @override
  String get syncResend => 'पुन्हा पाठवा';

  @override
  String get syncDelete => 'हटवा';

  @override
  String syncEntryName(String entity) {
    String _temp0 = intl.Intl.selectLogic(entity, {
      'farmer_profile': 'प्रोफाइल',
      'plot': 'बाग',
      'bahar_cycle': 'बहार',
      'expense': 'खर्च',
      'income': 'विक्री',
      'spray_record': 'फवारणी',
      'input_record': 'खत / निविष्ठा',
      'irrigation_record': 'पाणी',
      'harvest_record': 'तोडणी',
      'labour_record': 'मजुरी',
      'farm_task': 'काम',
      'scouting_record': 'पाहणी',
      'insurance_policy': 'विमा',
      'lab_test': 'माती / पाणी तपासणी',
      'other': 'नोंद',
    });
    return '$_temp0';
  }

  @override
  String get refreshOffline => 'इंटरनेट तपासा';

  @override
  String get refreshServer => 'सर्व्हर थोडा व्यस्त आहे';

  @override
  String get homeQuickTitle => 'झटपट कामे';

  @override
  String get moreTitle => 'सर्व सुविधा';

  @override
  String get moreSectionRecords => 'बागेच्या नोंदी';

  @override
  String get moreSectionWork => 'कामे व हंगाम';

  @override
  String get moreSectionHelp => 'माहिती व मदत';

  @override
  String get moreSectionMarket => 'बाजार';

  @override
  String get moreSectionGovt => 'सरकारी मदत';

  @override
  String get moreSectionAccount => 'माझे खाते';

  @override
  String get plotTileBahar => 'बहार';

  @override
  String get baharRecordsMenu => 'नोंदी';

  @override
  String tasksDoneShow(String count) {
    return 'दाखवा ($count)';
  }

  @override
  String get tasksDoneHide => 'लपवा';

  @override
  String tasksDoneLatest(String count) {
    return 'शेवटची $count दाखवत आहोत';
  }

  @override
  String get requiredPlotName => 'बागेचे नाव लिहा';

  @override
  String get requiredTaskTitle => 'काय करायचे ते लिहा';

  @override
  String get requiredWorker => 'मजुराचे नाव लिहा';

  @override
  String get requiredSprayProduct => 'औषधाचे नाव किंवा सक्रिय घटक लिहा';

  @override
  String get requiredInputProduct => 'उत्पादनाचे नाव लिहा';

  @override
  String get requiredBuyer => 'व्यापाऱ्याचे नाव लिहा';

  @override
  String get claimKitGpsOk => 'ठिकाण जोडले';

  @override
  String priceChangeUp(String pct) {
    return 'गेल्या आठवड्यापेक्षा $pct वाढ';
  }

  @override
  String priceChangeDown(String pct) {
    return 'गेल्या आठवड्यापेक्षा $pct घट';
  }

  @override
  String generalInfoSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get sourcesShow => 'स्रोत पहा';

  @override
  String get sourcesTitle => 'स्रोत';

  @override
  String sourcesTitleCount(String count) {
    return 'स्रोत ($count)';
  }

  @override
  String get sourcesHide => 'स्रोत लपवा';

  @override
  String get labelReadNote => 'फवारणीपूर्वी पाकिटावरील लेबल वाचा.';

  @override
  String baharSuggestedWindow(String from, String to) {
    return 'सुचवलेला काळ: $from – $to';
  }

  @override
  String get baharNoWindow =>
      'तुमची तारीख नोंदवा: स्रोतांमध्ये फक्त इतर टप्प्यांचा काळ दिला आहे';

  @override
  String get baharFillSuggested => 'सुचवलेल्या तारखा भरा';

  @override
  String get baharSuggestedHelp =>
      'सुचवलेला काळ सार्वजनिक स्रोतांतून आहे. तुमच्या बागेनुसार कोणतीही तारीख बदला.';

  @override
  String get baharStressBySoil =>
      'ताण किती दिवस द्यायचा हे जमिनीवर अवलंबून: हलक्या जमिनीत कमी दिवस, भारी जमिनीत जास्त.';

  @override
  String get practicesSee => 'काय दिसते';

  @override
  String get practicesWhen => 'केव्हा येते';

  @override
  String get figureGum => 'डिंक येतो';

  @override
  String get figureWetPatches => 'पाणथळ चट्टे';

  @override
  String get figureBarkPeels => 'साल उभ्या पट्ट्यांत सुटते';

  @override
  String get figureYellowLeaves => 'पिवळी पाने';

  @override
  String figureWidthCm(String cm) {
    return '$cm सें.मी.';
  }

  @override
  String figureDepthCm(String cm) {
    return '$cm सें.मी. खोल';
  }

  @override
  String get figureDrainsAway => 'पाणी झाडांपासून दूर वाहून जाते';

  @override
  String get figureDry => 'कोरडे';

  @override
  String get figureWaterHere => 'पाणी इथे';

  @override
  String get figureTopView => 'वरून दृश्य';

  @override
  String get figureDeadPart => 'वाळलेला भाग';

  @override
  String get figureCutHere => 'इथे कापा';

  @override
  String figureHealthyCm(String cm) {
    return '$cm सें.मी. निरोगी भागासह';
  }

  @override
  String figureSunDays(String from, String to) {
    return '$from–$to दिवस ऊन';
  }

  @override
  String get figureCutRotten => 'कुजलेली मुळे कापा';

  @override
  String get figureWithBand => 'निरोगी पट्टीसह काढा';

  @override
  String get figureDiseasedBark => 'रोगट साल';

  @override
  String get figureRains => 'पावसाळा';

  @override
  String get figureBeforeRains => 'पावसाळ्यापूर्वी';

  @override
  String get figureAfterRains => 'पावसाळ्यानंतर';

  @override
  String figureInnerRingCm(String cm) {
    return 'आतले आळे $cm सें.मी.';
  }

  @override
  String get figureYellowTrap => 'पिवळा चिकट सापळा';

  @override
  String figureHeightM(String m) {
    return 'जमिनीपासून $m मी.';
  }

  @override
  String get figureBudUnion => 'डोळ्याचा जोड';

  @override
  String figureHeightRangeCm(String from, String to) {
    return 'जमिनीपासून $from–$to सें.मी.';
  }

  @override
  String figureStickyBand(String cm) {
    return '$cm सें.मी. चिकट पट्टा';
  }

  @override
  String get figureAnts => 'मुंग्या';

  @override
  String get figureLureTrap => 'ल्युअर सापळा';

  @override
  String figureRenewDays(String from, String to) {
    return 'ल्युअर दर $from–$to दिवसांनी बदला';
  }

  @override
  String get figureShadyFirst => 'सावलीची बाजू: आधी इथे पाहा';

  @override
  String get figureSunnySide => 'उन्हाची बाजू';

  @override
  String get figureOpenCentre => 'मध्य मोकळा: हवा खेळती';

  @override
  String get figureCutCrowded => 'दाट फुटवे कापा';

  @override
  String get figureRootZone => 'सक्रिय मुळांचा भाग';

  @override
  String get figureManureHere => 'खत इथे, मातीने झाका';

  @override
  String get figCankerSpots => 'उंचवट्याचे, खरबरीत, तपकिरी डाग';

  @override
  String get figCankerHalo => 'पिवळे वलय';

  @override
  String get figCankerFruit => 'फळावर: डाग सालीतच राहतात';

  @override
  String get figMildewPowder => 'पांढरी भुकटी';

  @override
  String get figMildewCurl => 'पाने वळतात व गुंडाळतात';

  @override
  String get figAnthPatch => 'फिकट तपकिरी चट्टा, कडा जांभळी';

  @override
  String get figAnthDots => 'बारीक काळे ठिपके';

  @override
  String get figAnthTwig => 'मेलेली काडी: चंदेरी राखाडी';

  @override
  String get figGreeningLeaf => 'हिरव्या बेटांसारखे चट्टे असलेले पिवळे पान';

  @override
  String get figGreeningFruit => 'फळ लहान, एका बाजूला वाढलेले, हिरवे';

  @override
  String get figPsyllaNymphs => 'शेंड्यांवर पिवळी-नारिंगी पिल्ले';

  @override
  String get figPsyllaThreads => 'पांढरे मेणचट धागे';

  @override
  String get figPsyllaCurl => 'नवीन पाने गुंडाळतात';

  @override
  String get figAphidColony => 'काळ्या किंवा तपकिरी माव्याच्या वसाहती';

  @override
  String get figAphidCup => 'वाटीसारखी, सुरकुतलेली पाने';

  @override
  String get figMealyClusters => 'पांढरे, कापसासारखे पुंजके';

  @override
  String get figSootyMould => 'काळी बुरशी';

  @override
  String get figMinerMines => 'चंदेरी, नागमोडी बोगदे';

  @override
  String get figMinerDistort => 'पान वेडेवाकडे, चुरगळलेले होते';

  @override
  String get figMitesVeins => 'शिरांच्या बाजूने फिकट पिवळे भाग';

  @override
  String get figMitesWeb => 'बारीक जाळे: पाने धुळकट';

  @override
  String get figMitesRind => 'खरबरीत साल (रसेटिंग)';

  @override
  String get figThripsRing => 'देठाभोवती गोल व्रणासारखा डाग';

  @override
  String get figThripsPatches => 'सालीवर अनियमित चट्टे';

  @override
  String get figHeatSummer => 'उन्हाळ्याची उष्णता';

  @override
  String get figHeatDrop => 'फळगळीची दुसरी लाट';

  @override
  String get practicesScout => 'पाहणी कशी करावी';

  @override
  String get practicesActionLevel => 'नुकसान पातळी';

  @override
  String get practicesNoActionLevel =>
      'नुकसान पातळीसाठी आपल्या KVK ला विचारा; वाचलेल्या स्रोतांत तिचा उल्लेख अजून सापडायचा आहे.';

  @override
  String get practicesWhatToDo => 'काय करावे';

  @override
  String get practicesBioTitle => 'सेंद्रिय / जैविक';

  @override
  String get practicesBioRegistered =>
      'नोंदणीकृत उत्पादन: मात्रा फक्त त्याच्या लेबलवरूनच.';

  @override
  String get practicesBioHome => 'घरगुती, प्रकाशित पद्धतीप्रमाणे';

  @override
  String get practicesHowToPrepare => 'कसे तयार करावे';

  @override
  String get practicesLabelLink => 'लेबलप्रमाणे मंजूर औषधे पहा';

  @override
  String get practicesKnowledgeCard => 'ज्ञान कार्ड वाचा';

  @override
  String get knowledgeTitle => 'ज्ञान कार्ड';

  @override
  String get knowledgeIntro =>
      'बहार, कीड, रोग, पोषण, पाणी आणि तोडणी यांवर थोडक्यात माहिती. उत्पादने व मात्रा लेबल स्क्रीनवर पाहा.';

  @override
  String get knowledgeEmpty => 'फोन ऑनलाइन झाल्यावर ज्ञान कार्ड येथे दिसतील.';

  @override
  String get knowledgeWarnings => 'काळजी घ्या';

  @override
  String get knowledgeCallExpert => 'तज्ज्ञांना केव्हा विचारावे';

  @override
  String get knowledgeSources => 'स्रोत';

  @override
  String get practicesSourcesLineAll =>
      'स्रोत: NHB, NIPHM, ICAR, डॉ. पंदेकृवि, MPKV, TNAU व इतर. प्रत्येक पद्धतीखाली तपशील.';

  @override
  String get schemeGeneralSource => 'शेवटी दिलेली अधिकृत पाने';

  @override
  String get schemeFacts => 'अधिकृत पानावरील मुख्य माहिती';

  @override
  String schemeFactSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get labNormsTitle => 'मृदा आरोग्य पत्रिकेतील श्रेणी';

  @override
  String get labNormsHint => 'आपल्या अहवालातील आकडा या श्रेणींशी जुळवून पाहा.';

  @override
  String get labelInfoChemical => 'रासायनिक';

  @override
  String get labelInfoBio => '🌿 जैविक (नोंदणीकृत जैविक कीटकनाशके)';

  @override
  String labelInfoDilution(String value) {
    return 'लेबलवरील पाणी: $value लिटर प्रति हेक्टर';
  }

  @override
  String labelInfoDilutionPrinted(String value) {
    return 'लेबलवरील पाणी: $value';
  }

  @override
  String labelInfoBrands(String names) {
    return 'बाजारातील नावे (अकारविल्हे, फक्त यादी): $names';
  }

  @override
  String get labelInfoMakerPage => 'उत्पादकाचे उत्पादन पान';

  @override
  String labelInfoTargetPrinted(String target) {
    return 'लेबलवरील कीड/रोग: $target';
  }

  @override
  String labelInfoPage(String page) {
    return 'स्रोतातील पान: $page';
  }

  @override
  String labelInfoNoClaim(String target) {
    return '$target: लिंबूवर्गीय पिकांसाठी नोंदणीकृत लेबल माहिती नाही.';
  }

  @override
  String get labelInfoBanned => 'मान्य यादीबाहेर';

  @override
  String get labelInfoRestricted => 'या पिकासाठी मान्य यादीबाहेर';

  @override
  String get labelInfoAllTargets => 'सर्व कीड व रोग';

  @override
  String labelInfoOpenFor(String target) {
    return 'लेबल माहिती: $target';
  }

  @override
  String labelInfoSources(String count) {
    return 'माहितीचे स्रोत ($count)';
  }

  @override
  String get labelInfoOpenDetails => 'लेबलची पूर्ण माहिती पाहण्यासाठी दाबा';

  @override
  String get labelInfoDetailsTitle => 'लेबलवरील पूर्ण माहिती';

  @override
  String get noPlotTitle => 'आधी तुमची बाग जोडा';

  @override
  String get noPlotBody =>
      'प्रत्येक नोंद बागेनुसार ठेवली जाते. एकदा बाग जोडून जतन केली की हे लगेच उघडेल.';

  @override
  String plotAddressNear(String place) {
    return 'जवळचे ठिकाण: $place';
  }

  @override
  String plotAddressDistrict(String district) {
    return 'जि. $district';
  }

  @override
  String get plotAddressLooking => 'गावाचे नाव शोधत आहे…';

  @override
  String get plotAddressMissing =>
      'ठिकाण जतन होईल. गावाचे नाव पाहण्यासाठी नेट सुरू ठेवून \'ठिकाण पुन्हा घ्या\' दाबा.';

  @override
  String get onboardingNameHint => 'तुमचे नाव मराठीत लिहा (उदा. अभिषेक)';

  @override
  String get nameScriptPromptTitle => 'तुमचे नाव मराठीत लिहा';

  @override
  String get nameScriptFieldLabel => 'नाव (उदा. अभिषेक)';

  @override
  String get nameScriptLater => 'नको';

  @override
  String get adminMlQueue => 'तपासणी रांग';

  @override
  String get adminMlTags => 'रेटिंग टॅग';

  @override
  String get adminMlLotSettings => 'विक्री फॉर्म';

  @override
  String get adminMlLotSettingsNote =>
      'प्रत्येक पिकासाठी प्रति क्विंटल आणि प्रति क्रेट दराची मर्यादा, शेतकऱ्याच्या अपेक्षित दरासाठी आणि व्यापाऱ्याच्या ऑफरसाठी; आणि शेतकऱ्याने निवडलेल्या सुरुवातीनंतर तोडणीचा काळ किती दिवसांचा धरायचा. रिकामे = राखाडी दिसणारे मूळ मूल्य; सर्व्हर दर पुन्हा तपासतो.';

  @override
  String get adminMlQuintalMin => 'प्रति क्विंटल: किमान ₹';

  @override
  String get adminMlQuintalMax => 'प्रति क्विंटल: कमाल ₹';

  @override
  String get adminMlCrateMin => 'प्रति क्रेट: किमान ₹';

  @override
  String get adminMlCrateMax => 'प्रति क्रेट: कमाल ₹';

  @override
  String get adminMlHarvestDays => 'तोडणीचा काळ (दिवस)';

  @override
  String get adminMlCropSantra => 'संत्रा';

  @override
  String get adminMlCropMosambi => 'मोसंबी';

  @override
  String get adminMlAll => 'सर्व';

  @override
  String get adminMlBuyer => 'व्यापारी';

  @override
  String get adminMlBroker => 'मध्यस्थ (दलाल)';

  @override
  String get adminMlProvider => 'सेवा देणारे';

  @override
  String get adminMlQueueEmpty => 'सर्वांची तपासणी झाली';

  @override
  String adminMlWaitingSince(String date) {
    return '$date पासून थांबले';
  }

  @override
  String get adminMlFields => 'दिलेली माहिती';

  @override
  String get adminMlDocuments => 'कागदपत्रे';

  @override
  String get adminMlNoDocuments => 'पाठवलेली कागदपत्रे इथे दिसतील';

  @override
  String adminMlDocument(int n) {
    return 'कागदपत्र $n';
  }

  @override
  String get adminMlReject => 'नाकारा';

  @override
  String get adminMlRejectTitle => 'कारण देऊन नाकारा';

  @override
  String get adminMlBadgeNote =>
      'मंजुरीनंतरच तपासलेले चिन्ह दिसते; नंतर नाकारल्यास ते लगेच निघते.';

  @override
  String get adminMlStatusPending => 'प्रतीक्षेत';

  @override
  String get adminMlStatusApproved => 'तपासले';

  @override
  String get adminMlStatusRejected => 'नाकारले';

  @override
  String adminMlCheckedBy(String who) {
    return 'तपासणारे $who';
  }

  @override
  String get adminMlTagsEmpty => 'रेटिंग टॅग इथे दिसतील';

  @override
  String get adminMlTagsNote =>
      'मसुदा टॅग भाषा तपासणीसाठी थांबतात; फक्त चालू टॅग ॲपमध्ये दिसतात.';

  @override
  String get adminMlTagDraft => 'मसुदा';

  @override
  String get adminMlTagActive => 'चालू';

  @override
  String get adminMlTagRetired => 'बंद';

  @override
  String get adminMlPositive => 'चांगले';

  @override
  String get adminMlNegative => 'तक्रार';

  @override
  String get adminMlEditTag => 'टॅग बदला';

  @override
  String get adminMlLabelEn => 'इंग्रजी';

  @override
  String get adminMlLabelMr => 'मराठी';

  @override
  String get adminMlLabelHi => 'हिंदी';

  @override
  String get adminMlYes => 'हो';

  @override
  String get adminMlNo => 'नाही';

  @override
  String get adminMlFieldName => 'नाव';

  @override
  String get adminMlFieldFirm => 'फर्म';

  @override
  String get adminMlFieldPhone => 'मोबाईल नंबर';

  @override
  String get adminMlFieldMarkets => 'बाजार';

  @override
  String get adminMlFieldDistrict => 'जिल्हा';

  @override
  String get adminMlFieldTaluka => 'तालुका';

  @override
  String get adminMlFieldVillage => 'गाव';

  @override
  String get adminMlFieldCrops => 'पिके';

  @override
  String get adminMlFieldServiceAreas => 'सेवा क्षेत्र';

  @override
  String get adminMlFieldApmc => 'APMC परवाना क्र.';

  @override
  String get adminMlFieldGst => 'GST क्र.';

  @override
  String get adminMlFieldKind => 'सेवा';

  @override
  String get adminMlFieldCertValidUntil => 'प्रमाणपत्र वैध तारीख';

  @override
  String get adminMlFieldVehicles => 'वाहन क्रमांक';

  @override
  String get adminMlFieldCapacity => 'क्षमता (टन)';

  @override
  String get adminMlFieldRefrigerated => 'रेफ्रिजरेटेड वाहन';

  @override
  String get adminMlFieldCarrierReg => 'वाहतूकदार नोंदणी क्र.';

  @override
  String get adminMlKindWeighbridge => 'वजनकाटा';

  @override
  String get adminMlKindTransporter => 'वाहतूकदार';

  @override
  String get adminMlKindLabourGang => 'मजूर टोळी';

  @override
  String get adminMlKindCrateSupplier => 'क्रेट पुरवठादार';

  @override
  String get adminMlChecks => 'तपासण्या';

  @override
  String get adminMlChecksNote =>
      'अधिकृत पान उघडा, नंबर पेस्ट करा (तो कॉपी झालेला असतो), स्वतः तपासा आणि निकाल नोंदवा. बॅज फक्त काय व कधी तपासले ते सांगतो.';

  @override
  String get adminMlOpenPage => 'अधिकृत पान उघडा';

  @override
  String get adminMlCallNow => 'फोन करा';

  @override
  String get adminMlRecordResult => 'निकाल नोंदवा';

  @override
  String adminMlNumberCopied(String number) {
    return 'नंबर कॉपी झाला: $number';
  }

  @override
  String get adminMlResultPassed => 'योग्य आढळले';

  @override
  String get adminMlResultFailed => 'चुकीचे आढळले';

  @override
  String get adminMlResultCancelled => 'रद्द / बंद';

  @override
  String get adminMlRegisteredYear => 'GST नोंदणी वर्ष (ऐच्छिक)';

  @override
  String get adminMlNoChecks => 'नोंदलेल्या तपासण्या इथे दिसतील';

  @override
  String get adminMlCheckApmc => 'APMC परवाना';

  @override
  String get adminMlCheckPhoneCall => 'फोन कॉल';

  @override
  String get adminMlCheckPlacePhoto => 'ठिकाणाचा फोटो';

  @override
  String adminMlRegisteredSince(String year) {
    return 'नोंदणी $year';
  }

  @override
  String get adminMlFlags => 'मंजुरीआधी पाहा';

  @override
  String get adminMlFlagDuplicate => 'हाच नंबर दुसऱ्या प्रोफाइलवर';

  @override
  String get adminMlFlagReturning => 'निलंबित प्रोफाइलशी जुळते';

  @override
  String get adminMlFlagMock => 'ठिकाण बनावट (mock) दिसले';

  @override
  String get adminMlFlagOtherDistrict => 'सांगितलेल्या जिल्ह्याबाहेरून नोंदणी';

  @override
  String get adminMlFlagNoPlace => 'फोनकडून ठिकाणाचे नाव रिकामे';

  @override
  String get adminMlWhyName => 'तेच नाव';

  @override
  String get adminMlWhyGps => 'जवळून नोंदणी';

  @override
  String get adminMlWhyAccount => 'तेच खाते';

  @override
  String get adminMlRechecks => 'पुन्हा तपासायचे';

  @override
  String get adminMlRechecksEmpty => 'सर्व वार्षिक पुन्हा तपासण्या पूर्ण';

  @override
  String adminMlLastChecked(String date) {
    return 'मागील तपासणी $date';
  }

  @override
  String adminMlDocumentCount(int n) {
    return 'कागदपत्रे: $n';
  }

  @override
  String get mlRolesTitle => 'तुमची भूमिका निवडा';

  @override
  String get mlRolesIntro =>
      'सर्व भूमिकांसाठी एकच साइन-इन. भूमिका कधीही बदलता येते.';

  @override
  String get mlRoleGrower => 'शेतकरी';

  @override
  String get mlRoleTrader => 'व्यापारी';

  @override
  String get mlRoleBroker => 'मध्यस्थ (दलाल)';

  @override
  String get mlRoleExporter => 'निर्यातदार';

  @override
  String get mlRoleProvider => 'सेवा देणारे';

  @override
  String get mlRoleProviderKinds => 'वजनकाटा, वाहतूक, मजूर, क्रेट';

  @override
  String get mlRoleCurrent => 'सध्याची भूमिका';

  @override
  String get mlSwitchRole => 'भूमिका बदला';

  @override
  String get mlHomeLinkTitle => 'बाजार जोडणी';

  @override
  String get mlHomeLinkHint =>
      'व्यापारी, मध्यस्थ, निर्यातदार, सेवा: भूमिका निवडा';

  @override
  String get mlTermsTitle => 'सुरू करण्यापूर्वी';

  @override
  String mlTermsRole(String role) {
    return 'भूमिका: $role';
  }

  @override
  String get mlTermsIntroOnly =>
      'BagMitra फक्त माहिती देते आणि तुमची व्यापारी, मध्यस्थ (दलाल) व बाजाराशी ओळख करून देते.';

  @override
  String get mlTermsNotParty =>
      'BagMitra खरेदीदार, विक्रेता, कमिशन एजंट किंवा वाहतूकदार नाही.';

  @override
  String get mlTermsNoMoney =>
      'ते कोणतेही पैसे ठेवत नाही आणि पैसे मिळण्याची किंवा मालाच्या दर्जाची हमी देत नाही.';

  @override
  String get mlTermsNoGainLoss =>
      'तुमच्या व्यवहारात या ॲपचा कोणताही लाभ किंवा नुकसान नाही.';

  @override
  String get mlTermsNoPart =>
      'तुमच्या व्यवहारात किंवा कोणत्याही वादात BagMitra भाग घेत नाही.';

  @override
  String get mlTermsAfterDeal => 'व्यवहारानंतर काय नोंदवायचे ते तुमची इच्छा.';

  @override
  String get mlTermsPublicPhone =>
      'तुमचा फोन नंबर तुमच्या प्रोफाइलवर सर्वांना दिसेल, म्हणजे शेतकरी तुम्हाला थेट फोन करू शकतील.';

  @override
  String get mlTermsGpsOnce =>
      'नोंदणीच्या वेळी फसवणूक टाळण्यासाठी तुमचे ठिकाण (GPS) एकदाच घेतले जाईल.';

  @override
  String get mlTermsFull => 'वापराच्या पूर्ण अटी';

  @override
  String get mlTermsAdult => 'मी १८ वर्षांपेक्षा मोठा आहे';

  @override
  String get mlTermsAgree => 'मी वाचले व मान्य करतो';

  @override
  String get mlTermsAccept => 'मान्य करा व पुढे चला';

  @override
  String get mlTermsBack => 'मागे';

  @override
  String get mlSafetyNotice =>
      'BagMitra कधीही पैसे, OTP किंवा बँक तपशील मागत नाही.';

  @override
  String get mlGrievanceTitle => 'तक्रार अधिकारी';

  @override
  String get mlGrievanceOwner => 'BagMitra चे मालक';

  @override
  String mlGrievanceContact(String contact) {
    return 'संपर्क: $contact';
  }

  @override
  String get mlGrievanceTimes =>
      'तक्रारीची पोच 24 तासांत आणि निवारण 15 दिवसांत.';

  @override
  String get mlKindWeighbridge => 'वजनकाटा';

  @override
  String get mlKindTransporter => 'वाहतूकदार';

  @override
  String get mlKindLabourGang => 'मजूर टोळी';

  @override
  String get mlKindCrateSupplier => 'क्रेट पुरवठादार';

  @override
  String get mlRegisterTrader => 'व्यापारी नोंदणी';

  @override
  String get mlRegisterExporter => 'निर्यातदार नोंदणी';

  @override
  String get mlRegisterBroker => 'मध्यस्थ (दलाल) नोंदणी';

  @override
  String get mlRegisterProvider => 'सेवा देणारे नोंदणी';

  @override
  String get mlRegisterAs => 'नोंदणी करा';

  @override
  String get mlFixTitle => 'नोंदणीच्या ठिकाणाचे स्थान';

  @override
  String get mlFixWhy =>
      'नोंदणी पूर्ण करण्यासाठी फोन तुमचे सध्याचे स्थान एकदा घेतो. यामुळे बनावट नोंदणी दूर राहते.';

  @override
  String get mlFixOnce =>
      'स्थान फक्त एकदा, आत्ता घेतले जाते. सार्वजनिक प्रोफाइलवर फक्त गाव, तालुका व जिल्हा दिसतो; अचूक स्थान फक्त BagMitra च्या तपासणीसाठी.';

  @override
  String get mlPhonePublicNote =>
      'तपासणीनंतर तुमचे नाव, फर्म व संपर्क क्रमांक नोंदणीकृत शेतकऱ्यांना दिसतात.';

  @override
  String get mlFixTake => 'स्थान घ्या';

  @override
  String get mlFixTaking => 'स्थान घेत आहे…';

  @override
  String get mlFixDenied => 'नोंदणी पूर्ण करण्यासाठी लोकेशनला परवानगी द्या.';

  @override
  String mlFixTaken(String place, String metres) {
    return 'स्थान घेतले: $place (±$metres मी.)';
  }

  @override
  String get mlPickKind => 'तुम्ही कोणती सेवा देता?';

  @override
  String get mlFieldName => 'नाव';

  @override
  String get mlFieldPhone => 'संपर्क क्रमांक';

  @override
  String get mlFieldFirm => 'फर्मचे नाव (ऐच्छिक)';

  @override
  String get mlFieldVillage => 'गाव';

  @override
  String get mlFieldTaluka => 'तालुका';

  @override
  String get mlFieldDistrict => 'जिल्हा';

  @override
  String get mlFieldMarkets => 'बाजार / गावे (मध्ये स्वल्पविराम)';

  @override
  String get mlFieldAreas => 'सेवा देणारी गावे / भाग (मध्ये स्वल्पविराम)';

  @override
  String get mlFieldCrops => 'पिके';

  @override
  String get mlFieldAddress => 'पत्ता (ऐच्छिक)';

  @override
  String get mlFieldGst => 'GSTIN';

  @override
  String get mlFieldApmc => 'APMC परवाना क्र.';

  @override
  String get mlFieldFssai => 'FSSAI परवाना क्र.';

  @override
  String get mlFieldIec => 'IEC क्र.';

  @override
  String get mlFieldApeda => 'APEDA नोंदणी क्र.';

  @override
  String get mlFieldVehicles => 'वाहन क्रमांक (मध्ये स्वल्पविराम)';

  @override
  String get mlFieldCapacity => 'क्षमता (टन)';

  @override
  String get mlFieldRefrigerated => 'शीत वाहन';

  @override
  String get mlFieldCertUntil => 'प्रमाणपत्र वैध तारीख';

  @override
  String mlCertUntilValue(String date) {
    return 'प्रमाणपत्र $date पर्यंत वैध';
  }

  @override
  String get mlNumbersNote =>
      'किमान एक लिहा: GSTIN, APMC परवाना किंवा IEC. BagMitra तो अधिकृत सार्वजनिक नोंदीवर तपासते.';

  @override
  String get mlIecRequired => 'निर्यातदार नोंदणीसाठी IEC क्रमांक लागतो.';

  @override
  String get mlBrokerCallNote =>
      'तपासणी पूर्ण करण्यासाठी BagMitra या क्रमांकावर तुम्हाला फोन करेल.';

  @override
  String get mlErrPhone => '10 अंकी मोबाईल क्रमांक लिहा';

  @override
  String get mlErrGst => '15 अक्षरी GSTIN लिहा';

  @override
  String get mlErrIec => '10 अक्षरी IEC लिहा';

  @override
  String get mlErrFssai => '14 अंकी FSSAI क्रमांक लिहा';

  @override
  String get mlErrCapacity => 'क्षमता टनात लिहा (100 पर्यंत)';

  @override
  String get mlErrOneNumber => 'GSTIN, APMC परवाना किंवा IEC क्रमांक लिहा';

  @override
  String get mlErrPickKind => 'तुमची सेवा निवडा';

  @override
  String get mlErrCertDate => 'प्रमाणपत्राची वैध तारीख निवडा';

  @override
  String get mlErrFixStale => 'स्थान पुन्हा घ्या आणि मग पाठवा';

  @override
  String get mlErrExists =>
      'या भूमिकेत तुमची नोंदणी आधीच आहे; माझी बाजार नोंदणी पहा';

  @override
  String get mlErrCheckFields => 'माहिती तपासा व पुन्हा पाठवा';

  @override
  String get mlSubmit => 'नोंदणी पाठवा';

  @override
  String get mlSubmitted => 'नोंदणी पाठवली. BagMitra तपासणी करेल.';

  @override
  String get mlOffline => 'हे पाहण्यासाठी इंटरनेट सुरू करा';

  @override
  String get mlServerBusy =>
      'सर्व्हर व्यस्त आहे; थोड्या वेळाने पुन्हा प्रयत्न करा';

  @override
  String get mlRetry => 'पुन्हा प्रयत्न करा';

  @override
  String get mlMyProfilesTitle => 'माझी बाजार नोंदणी';

  @override
  String get mlMyProfilesEmpty =>
      'खाली व्यापारी, निर्यातदार, मध्यस्थ किंवा सेवा देणारे म्हणून नोंदणी करा.';

  @override
  String get mlStatusPending => 'तपासणी बाकी';

  @override
  String get mlStatusApproved => 'BagMitra ने तपासले';

  @override
  String get mlStatusRejected => 'परत पाठवले; कारण पहा';

  @override
  String get mlCheckNote =>
      'BagMitra च्या तपासणीनंतर तुमची प्रोफाइल शेतकऱ्यांना दिसते. कागदपत्रांचे फोटो तपासणीला मदत करतात.';

  @override
  String mlDocsCount(String count) {
    return 'कागदपत्रांचे फोटो: $count';
  }

  @override
  String get mlDocCertificate => 'वजनकाटा प्रमाणपत्र';

  @override
  String mlCertExpired(String date) {
    return 'प्रमाणपत्राची तारीख संपली ($date)';
  }

  @override
  String get mlAddressAdd => 'पत्ता लिहा';

  @override
  String get mlAddressEdit => 'पत्ता बदला';

  @override
  String get mlCancel => 'रद्द करा';

  @override
  String get mlSave => 'जतन करा';

  @override
  String get mlPeopleTitle => 'व्यापारी व मध्यस्थ';

  @override
  String get mlPeopleEmpty =>
      'या भागातील तपासलेले व्यापारी व मध्यस्थ येथे दिसतील.';

  @override
  String mlAreaTaluka(String taluka) {
    return 'तालुका $taluka';
  }

  @override
  String mlAreaDistrict(String district) {
    return 'जिल्हा $district';
  }

  @override
  String get mlSortRating => 'रेटिंगनुसार';

  @override
  String get mlSortDeals => 'व्यवहारांनुसार';

  @override
  String mlDeals(String count) {
    return '$count पूर्ण व्यवहार';
  }

  @override
  String mlStars(String average, String count) {
    return '$average/५ ($count)';
  }

  @override
  String mlDistanceKm(String km) {
    return '$km कि.मी.';
  }

  @override
  String mlBadgeChecked(String date) {
    return 'BagMitra ने $date रोजी तपासले';
  }

  @override
  String mlBadgeRegisteredFrom(String place, String date) {
    return '$place येथून $date रोजी नोंदणी';
  }

  @override
  String mlBadgePlacePhoto(String date) {
    return 'BagMitra प्रतिनिधीने $date रोजी ठिकाणाचा फोटो घेतला';
  }

  @override
  String get mlBadgeNote =>
      'बॅज BagMitra ने काय व कधी तपासले ते सांगतो. व्यवहाराच्या अटी तुम्ही थेट आपसात ठरवता.';

  @override
  String get mlCall => 'फोन करा';

  @override
  String mlCallNumber(String phone) {
    return '$phone वर फोन करा';
  }

  @override
  String get mlRatingsTitle => 'रेटिंग';

  @override
  String get mlQTraderOnDate => 'ठरलेल्या तोडणी तारखेला आले';

  @override
  String get mlQTraderWeighing => 'वजन / क्रेट मोजणी बरोबर';

  @override
  String get mlQTraderPaid => 'ठरल्याप्रमाणे उचल व बाकी पैसे दिले';

  @override
  String get mlQTraderConditions => 'इतर अटी पाळल्या';

  @override
  String get mlQBrokerHonest => 'व्यवहार प्रामाणिकपणे सांगितला';

  @override
  String get mlQBrokerTraderKept => 'आणलेल्या व्यापाऱ्याने व्यवहार पाळला';

  @override
  String get mlAreaAll => 'सर्व भाग';

  @override
  String get mlMarkets => 'बाजार / गावे';

  @override
  String get mlAreas => 'सेवा भाग';

  @override
  String get mlServicesTitle => 'सेवा देणारे';

  @override
  String get mlServicesEmpty =>
      'जवळचे तपासलेले वजनकाटे, वाहतूक, मजूर टोळ्या व क्रेट पुरवठादार येथे दिसतील.';

  @override
  String get mlServicesNote =>
      'फोन करून थेट ठरवा; दर व पैसे तुमच्या आपसातील विषय.';

  @override
  String mlNearPlot(String name) {
    return '$name जवळ';
  }

  @override
  String get mlDisclaimerShort =>
      'बागमित्र खरेदीदार, विक्रेता, मध्यस्थ (दलाल) किंवा वाहतूकदार नाही; पैसे ठेवत नाही; पैशांची किंवा दर्जाची हमी देत नाही.';

  @override
  String get mlOpen => 'माल विक्रीसाठी दाखवा';

  @override
  String get mlMyLotsTitle => 'माझा विक्रीचा माल';

  @override
  String get mlLotsEmpty =>
      'फोटोसह तुमचा माल येथे दाखवा; तपासलेले व्यापारी व मध्यस्थ (दलाल) तो पाहतात.';

  @override
  String get mlLotFormTitle => 'विक्रीचा माल';

  @override
  String get mlNoPlot => 'आधी तुमची बाग जोडा.';

  @override
  String get mlPlot => 'बाग';

  @override
  String get mlBahar => 'बहार';

  @override
  String get mlQuantity => 'अंदाजे माल (टन)';

  @override
  String get mlQuality => 'आकार व दर्जा';

  @override
  String get mlHarvestWindow => 'तोडणीचा काळ';

  @override
  String mlWindowRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get mlBasis => 'विक्रीची पद्धत';

  @override
  String get mlBasisPerQuintal => 'प्रति क्विंटल';

  @override
  String get mlBasisPerCrate => 'प्रति क्रेट';

  @override
  String get mlBasisLumpSum => 'संपूर्ण बाग';

  @override
  String get mlAskingRate => 'अपेक्षित दर ₹ (ऐच्छिक)';

  @override
  String get mlHarvestFrom => 'तोडणी कधीपासून';

  @override
  String get mlHarvestTo => 'कधीपर्यंत';

  @override
  String get mlHarvestPickDate => 'तारीख निवडा';

  @override
  String mlHarvestFromBahar(String date) {
    return '$date (बहारप्रमाणे)';
  }

  @override
  String mlHarvestAutoEnd(String days) {
    return 'कधीपर्यंत: सुरुवातीपासून $days दिवस आपोआप धरले आहेत; हवे तर बदला.';
  }

  @override
  String get mlHarvestChangeEnd => 'बदला';

  @override
  String get mlAskingRatePerQuintal => 'अपेक्षित दर ₹ / क्विंटल (ऐच्छिक)';

  @override
  String get mlAskingRatePerCrate => 'अपेक्षित दर ₹ / क्रेट (ऐच्छिक)';

  @override
  String get mlAskingRateLumpSum => 'अपेक्षित दर ₹ संपूर्ण बागेसाठी (ऐच्छिक)';

  @override
  String mlRateRangePerQuintal(String min, String max) {
    return '$min – $max प्रति क्विंटल';
  }

  @override
  String mlRateRangePerCrate(String min, String max) {
    return '$min – $max प्रति क्रेट';
  }

  @override
  String mlRateOutOfRange(String min, String max) {
    return 'कृपया दर $min ते $max या दरम्यान लिहा.';
  }

  @override
  String get mlPublishRateRange =>
      'अपेक्षित दर दिलेल्या मर्यादेत लिहा, मग पुन्हा पाठवा.';

  @override
  String get mlOfferRateRange => 'दर दिलेल्या मर्यादेत लिहा, मग पुन्हा पाठवा.';

  @override
  String get mlPhotos => 'फोटो';

  @override
  String mlPhotosHint(String min, String max) {
    return 'ॲपच्या कॅमेऱ्याने $min ते $max फोटो';
  }

  @override
  String get mlAddPhoto => 'फोटो काढा';

  @override
  String get mlRemovePhoto => 'फोटो काढून टाका';

  @override
  String get mlPhotoNoGps =>
      'GPS चालू करून पुन्हा फोटो काढा: प्रत्येक फोटोला ठिकाण लागते.';

  @override
  String get mlPrivacy =>
      'व्यापाऱ्यांना फक्त गाव, तालुका व जिल्हा दिसतो; तुमचे नाव, फोन व बागेचे ठिकाण गुप्त राहते.';

  @override
  String get mlSaveDraft => 'मसुदा जतन करा';

  @override
  String get mlPublish => 'व्यापाऱ्यांना दाखवा';

  @override
  String get mlClose => 'दाखवणे बंद करा';

  @override
  String get mlStatusDraft => 'मसुदा';

  @override
  String get mlStatusPublished => 'व्यापाऱ्यांना दिसतो';

  @override
  String get mlStatusReview => 'तपासणी बाकी';

  @override
  String get mlStatusClosed => 'बंद';

  @override
  String mlTonnes(String value) {
    return '$value टन';
  }

  @override
  String mlRatePerQuintal(String rate) {
    return '$rate प्रति क्विंटल';
  }

  @override
  String mlRatePerCrate(String rate) {
    return '$rate प्रति क्रेट';
  }

  @override
  String mlRateLumpSum(String rate) {
    return 'संपूर्ण बागेसाठी $rate';
  }

  @override
  String get mlPublished =>
      'तपासलेल्या व्यापारी व मध्यस्थांना (दलाल) माल दिसू लागला.';

  @override
  String get mlClosed => 'माल व्यापाऱ्यांच्या यादीतून काढला.';

  @override
  String get mlPublishOffline =>
      'यासाठी इंटरनेट लागते. मसुदा जतन आहे; इंटरनेट आल्यावर पुन्हा करा.';

  @override
  String mlPublishNeedPhotos(String min, String max) {
    return 'आधी $min ते $max फोटो जोडा.';
  }

  @override
  String get mlPublishPhotoMissing =>
      'तो फोटो काढून टाका व पुन्हा काढा: त्याची फाईल या फोनवरून हरवली आहे.';

  @override
  String get mlPublishNotAccepted => 'आधी शेतकरी अटी मान्य करा, मग पुन्हा करा.';

  @override
  String get mlPublishFailed => 'थोड्या वेळाने पुन्हा करा.';

  @override
  String get mlChooseOne => 'एक निवडा';

  @override
  String get mlDeleteDraft => 'मसुदा हटवा';

  @override
  String get mlNoContacts =>
      'येथे फक्त मालाबद्दल लिहा; फोन नंबर व लिंक ऑफर स्वीकारल्यानंतर मिळतात.';

  @override
  String get mlPublishOrchardCheck =>
      'माल नोंदवला; फोटो नोंदवलेल्या बागेच्या हद्दीबाहेर काढले आहेत, म्हणून तपासणीनंतर व्यापाऱ्यांना दिसेल.';

  @override
  String get mlSize => 'आकार';

  @override
  String get mlGrade => 'दर्जा';

  @override
  String get mlQualityLine => 'थोडक्यात माहिती (ऐच्छिक)';

  @override
  String get mlSafetyReport => 'तक्रार करा';

  @override
  String get mlSafetyReportTitle => 'बागमित्रकडे तक्रार';

  @override
  String get mlSafetyReportWhy => 'कारण निवडा';

  @override
  String get mlSafetyReportNote =>
      'बागमित्र फक्त ओळख करून देते. खोटी ओळख, खोटा माल, बागमित्र असल्याचे भासवणे, खोटे रेटिंग किंवा गैरवर्तन यासाठी तक्रार करा; व्यवहारातील पैसे, वजन आणि दर्जा तुम्ही आपसात ठरवा.';

  @override
  String get mlSafetyPhoto => 'फोटो जोडा (हवा असल्यास)';

  @override
  String get mlSafetyPhotoAdded => 'फोटो जोडला';

  @override
  String get mlSafetySend => 'तक्रार पाठवा';

  @override
  String get mlSafetySent => 'तक्रार मिळाली. बागमित्र तपासेल.';

  @override
  String get mlSafetyRetry => 'नेट तपासून पुन्हा प्रयत्न करा';

  @override
  String get mlReasonFakeIdentity => 'खोटी ओळख';

  @override
  String get mlReasonFakeLot => 'खोटा माल किंवा दुसऱ्या बागेचे फोटो';

  @override
  String get mlReasonImpersonation => 'बागमित्र असल्याचे भासवते';

  @override
  String get mlReasonFakeRating => 'खोटे रेटिंग';

  @override
  String get mlReasonAbuse => 'अपमानास्पद वागणूक';

  @override
  String get mlReasonDuplicateUser => 'एकाच व्यक्तीची दोन खाती';

  @override
  String get mlReasonChecksPassed => 'तपासणी पूर्ण';

  @override
  String get mlReasonAppealUpheld => 'अपील मान्य';

  @override
  String get mlActionVerify => 'पडताळणी झाली';

  @override
  String get mlActionWarn => 'इशारा';

  @override
  String get mlActionHide => 'यादीतून लपवले';

  @override
  String get mlActionSuspend => 'खाते तात्पुरते थांबवले';

  @override
  String get mlActionRestore => 'पुन्हा सुरू';

  @override
  String get mlAppealIdentityGenuine => 'माझी ओळख खरी आहे';

  @override
  String get mlAppealLotGenuine => 'माझा माल आणि फोटो खरे आहेत';

  @override
  String get mlAppealRatingGenuine => 'हे रेटिंग खऱ्या व्यवहाराचे आहे';

  @override
  String get mlAppealBehaviourProper => 'माझे वागणे योग्य होते';

  @override
  String get mlAppealNotDuplicate => 'हे माझे एकमेव खाते आहे';

  @override
  String get mlAppealStateAppealed => 'अपील तक्रार अधिकाऱ्याकडे';

  @override
  String get mlAppealStateUpheld => 'अपील मान्य';

  @override
  String get mlAppealStateRejected => 'निर्णय कायम';

  @override
  String get mlActionsTitle => 'माझ्या खात्यावरील कारवाई';

  @override
  String get mlActionsEmpty => 'तुमचे खाते सुरळीत आहे.';

  @override
  String mlActionReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String mlActionDate(String date) {
    return '$date रोजी';
  }

  @override
  String get mlAppeal => 'अपील करा';

  @override
  String get mlAppealTitle => 'अपील (एकदाच)';

  @override
  String get mlAppealNote =>
      'तक्रार अधिकारी २४ तासांत पोच देतील आणि १५ दिवसांत निर्णय देतील.';

  @override
  String get mlAppealSend => 'अपील पाठवा';

  @override
  String get mlAppealSent => 'अपील मिळाले';

  @override
  String get mlGrievanceDefault => 'बागमित्रचे मालक';

  @override
  String get mlBlock => 'ब्लॉक करा';

  @override
  String get mlUnblock => 'ब्लॉक काढा';

  @override
  String get mlBlockTitle => 'या व्यक्तीला ब्लॉक करायचे?';

  @override
  String get mlBlockNote =>
      'तुम्ही दोघे एकमेकांच्या यादीतून आणि मागणीतून दूर राहाल. कधीही ब्लॉक काढता येईल.';

  @override
  String get mlBlocked => 'ब्लॉक केले';

  @override
  String get mlUnblocked => 'ब्लॉक काढला';

  @override
  String get mlMoreOptions => 'आणखी पर्याय';

  @override
  String get adminMlReports => 'तक्रारी';

  @override
  String get adminMlAppeals => 'अपील';

  @override
  String get adminMlReportsEmpty => 'सर्व तक्रारी हाताळल्या';

  @override
  String get adminMlAppealsEmpty => 'सर्व अपील निकाली';

  @override
  String get adminMlAckOverdue => 'पोच: २४ तास उलटले';

  @override
  String get adminMlCloseOverdue => 'निर्णय: १५ दिवस उलटले';

  @override
  String get adminMlAcknowledge => 'पोच द्या';

  @override
  String get adminMlAct => 'कारवाई करा';

  @override
  String get adminMlDismiss => 'फेटाळा';

  @override
  String get adminMlUphold => 'अपील मान्य करा';

  @override
  String get adminMlKeepDecision => 'निर्णय कायम ठेवा';

  @override
  String get adminMlActionTitle => 'कारण-संकेतासह कारवाई';

  @override
  String get adminMlActionNote =>
      'फक्त प्लॅटफॉर्मचे नियम: खोटी किंवा दुहेरी खाती, खोटा माल, भासवणे, गैरवर्तन. पैसे, वजन, दर्जा यांचे वाद पक्षांमध्येच राहतात.';

  @override
  String get adminMlStatusOpen => 'खुली';

  @override
  String get adminMlStatusActioned => 'कारवाई झाली';

  @override
  String get adminMlStatusDismissed => 'फेटाळली';

  @override
  String get adminMlTargetLot => 'माल (लॉट)';

  @override
  String get adminMlTargetRating => 'रेटिंग';

  @override
  String get adminMlTargetUser => 'वापरकर्ता';

  @override
  String adminMlReceived(String date) {
    return '$date रोजी आली';
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
  String get mlBrowseTitle => 'विक्रीसाठी माल';

  @override
  String get mlBrowseEmpty => 'शेतकऱ्यांनी दाखवलेला माल येथे दिसेल.';

  @override
  String get mlNotVerified =>
      'BagMitra ने तुमची नोंदणी तपासल्यावर माल येथे दिसेल.';

  @override
  String get mlMyOffersTitle => 'माझ्या ऑफर';

  @override
  String get mlMyOffersEmpty => 'मालावर दिलेल्या तुमच्या ऑफर येथे दिसतील.';

  @override
  String get mlOfferOpen => 'शेतकऱ्याच्या निर्णयाची वाट';

  @override
  String get mlOfferAccepted => 'स्वीकारली';

  @override
  String get mlOfferClosed =>
      'बंद: शेतकऱ्याने दुसरी ऑफर निवडली किंवा माल यादीतून काढला.';

  @override
  String mlHarvestOn(String date) {
    return 'तोडणी $date';
  }

  @override
  String get mlMakeOffer => 'ऑफर द्या';

  @override
  String get mlOfferTitle => 'तुमची ऑफर';

  @override
  String get mlOfferRate => 'दर ₹';

  @override
  String get mlOfferQuantity => 'माल टनात (ऐच्छिक)';

  @override
  String get mlOfferHarvestDate => 'प्रस्तावित तोडणी तारीख';

  @override
  String get mlOfferThroughBroker => 'मध्यस्थ (दलाल) मार्फत';

  @override
  String get mlOfferForTrader => 'कोणत्या व्यापाऱ्यासाठी';

  @override
  String get mlOfferDirect => 'थेट';

  @override
  String get mlOfferOnlyThese =>
      'शेतकऱ्याला फक्त दर, माल व तारीख जाते; बाकी सर्व समोरासमोर ठरवा.';

  @override
  String get mlOfferSend => 'ऑफर पाठवा';

  @override
  String get mlOfferSent =>
      'ऑफर पाठवली. शेतकऱ्याने निर्णय घेतल्यावर सूचना येईल.';

  @override
  String get mlErrRate => 'दर रुपयांत लिहा';

  @override
  String get mlErrQuantity => 'टन लिहा (10,000 पर्यंत)';

  @override
  String get mlErrPickTrader => 'व्यापारी निवडा';

  @override
  String get mlErrLotGone => 'हा माल यादीतून काढला आहे.';

  @override
  String get mlOffersTitle => 'तुमच्या मालावरील ऑफर';

  @override
  String get mlOffersEmpty =>
      'तपासलेल्या व्यापाऱ्यांच्या ऑफर येथे शेजारी-शेजारी दिसतील.';

  @override
  String get mlSeeOffers => 'ऑफर पहा';

  @override
  String mlYourAsk(String rate) {
    return 'तुमचा अपेक्षित दर: $rate';
  }

  @override
  String get mlAcceptPick => 'निवडण्यासाठी एका ऑफरवर टॅप करा';

  @override
  String get mlAccept => 'निवडलेली ऑफर स्वीकारा';

  @override
  String get mlAcceptConfirmTitle => 'ही ऑफर स्वीकारायची?';

  @override
  String get mlAcceptConfirmBody =>
      'या व्यापाऱ्याला (व नाव दिलेल्या मध्यस्थाला) तुमचे नाव, फोन व बागेचे ठिकाण दिसेल. इतर ऑफर बंद होतील. पुढील व्यवहार तुम्ही थेट आपसात ठरवा.';

  @override
  String get mlAcceptYes => 'स्वीकारा';

  @override
  String get mlAccepted => 'स्वीकारली. आता दोघांना एकमेकांचे संपर्क दिसतात.';

  @override
  String get mlAcceptChanged => 'ऑफर बदलली आहे; यादी पुन्हा उघडा.';

  @override
  String get mlIntroOpen => 'संपर्क पहा';

  @override
  String get mlIntroTitle => 'संपर्क';

  @override
  String get mlIntroGrower => 'शेतकरी';

  @override
  String get mlIntroOpenMap => 'बाग नकाशावर उघडा';

  @override
  String mlIntroAcceptedOn(String date) {
    return '$date रोजी स्वीकारली';
  }

  @override
  String get mlIntroOffApp =>
      'आता वजन, क्रेट, वाहतूक व पैसे हा व्यवहार तुम्ही आपसात ठरवता.';

  @override
  String get mlDealDone => 'व्यवहार झाला';

  @override
  String get mlDealDoneAsk => 'व्यवहार झाला असे नोंदवायचे?';

  @override
  String get mlDealDoneAskBody =>
      'तुमच्यातील व्यवहार पूर्ण झाल्यावरच दाबा. शेतकरी व व्यापारी दोघांनी दाबल्यावर रेटिंग उघडते.';

  @override
  String get mlDealSaidDone => 'व्यवहार झाला म्हणाले';

  @override
  String get mlDealNotYet => 'वाट पाहत आहे';

  @override
  String get mlDealWaitOther =>
      'दुसऱ्या बाजूनेही “व्यवहार झाला” दाबल्यावर रेटिंग उघडेल.';

  @override
  String get mlDealWaitBoth =>
      'शेतकरी व व्यापारी दोघांनी “व्यवहार झाला” दाबल्यावर रेटिंग उघडेल.';

  @override
  String get mlRateOpen => 'रेटिंग द्या';

  @override
  String mlRateUntil(String date) {
    return '$date पर्यंत देता किंवा बदलता येईल';
  }

  @override
  String mlRateLocked(String date) {
    return 'रेटिंग $date ला बंद झाले';
  }

  @override
  String get mlRateNoText => 'फक्त स्टार द्या व खुणा करा.';

  @override
  String mlRateStarsOf(int count) {
    return '५ पैकी $count स्टार';
  }

  @override
  String get mlRateSave => 'रेटिंग जतन करा';

  @override
  String get mlRateAnswerAll => 'प्रत्येक ओळीला स्टार द्या';

  @override
  String get mlRateSaved => 'रेटिंग जतन झाले';

  @override
  String get mlRateRefused =>
      'दोघांनी “व्यवहार झाला” दाबल्यानंतर ७ दिवसांतच रेटिंग जतन होते.';

  @override
  String get mlRateSameDevice =>
      'रेटिंग वेगवेगळ्या फोनवरील खात्यांमध्येच देता येते.';

  @override
  String get mlQGrowerProduce => 'माल फोटो व वर्णनाप्रमाणे होता';

  @override
  String get mlQGrowerReady => 'ठरलेल्या तारखेला माल तयार होता';

  @override
  String get mlCopyToAccounts => 'माझ्या हिशोबात नोंदवा';

  @override
  String mlBadgeGstChecked(String date) {
    return 'GST $date रोजी तपासला';
  }

  @override
  String mlBadgeGstSince(String date, String year) {
    return 'GST $date रोजी तपासला · $year पासून नोंदणी';
  }

  @override
  String mlBadgeApmcSeen(String date) {
    return 'APMC परवाना $date रोजी पाहिला';
  }

  @override
  String mlBadgeFssaiChecked(String date) {
    return 'FSSAI $date रोजी तपासले';
  }

  @override
  String mlBadgeIecActive(String date) {
    return 'IEC चालू, $date रोजी तपासले';
  }

  @override
  String mlBadgeApedaListed(String date) {
    return 'APEDA यादीत, $date रोजी तपासले';
  }

  @override
  String mlPackageActiveUntil(String date) {
    return 'पॅकेज $date पर्यंत चालू';
  }

  @override
  String get mlPackageNotActive => 'पॅकेज चालू नाही';

  @override
  String get mlPackageHiddenNow => 'व्यापाऱ्यांना सध्या दिसत नाही';

  @override
  String get billingTitle => 'सदस्यता';

  @override
  String billingPerMonth(String price) {
    return '$price दरमहा';
  }

  @override
  String get billingIncluded => 'संपूर्ण BagMitra app, सर्व सुविधा.';

  @override
  String get billingTerms =>
      'Google Play द्वारे दर महिन्याला आपोआप नूतनीकरण. Google Play मधून कधीही रद्द करा; तुमच्या स्वतःच्या नोंदी नेहमी वाचता व export करता येतात.';

  @override
  String get billingSubscribe => 'सदस्यता घ्या';

  @override
  String get billingRestore => 'सदस्यता परत मिळवा';

  @override
  String get billingManage => 'सदस्यता व्यवस्थापन';

  @override
  String get billingActive => 'तुमची सदस्यता सुरू आहे.';

  @override
  String get billingPending => 'Google Play कडून पुष्टीची वाट पाहत आहे.';

  @override
  String get billingVerifying => 'BagMitra Google Play कडे तपासत आहे…';

  @override
  String get billingRetry =>
      'पुन्हा प्रयत्न करा, किंवा \'सदस्यता परत मिळवा\' दाबा.';

  @override
  String get billingNeedsPlay => 'हे पान Google Play असलेल्या फोनवर उघडा.';

  @override
  String get billingChangeTitle => 'तुमच्या सदस्यतेत बदल';

  @override
  String billingChangeBody(String date) {
    return '$date पासून तुमच्या सदस्यतेचा नवीन मासिक दर Google Play मध्ये आहे. सदस्यता सुरू ठेवण्यासाठी Google Play मध्ये पाहून स्वीकारा.';
  }

  @override
  String billingChangeConfirmedBody(String date) {
    return '$date पासून तुमची सदस्यता Google Play मधील नवीन मासिक दराने सुरू राहील. तुम्ही तो आधीच स्वीकारला आहे.';
  }

  @override
  String get billingOpenPlay => 'Google Play उघडा';

  @override
  String get feedbackTitle => 'अभिप्राय द्या';

  @override
  String get feedbackKindProblem => 'अडचण';

  @override
  String get feedbackKindSuggestion => 'सूचना';

  @override
  String get feedbackKindQuestion => 'प्रश्न';

  @override
  String get feedbackHint => 'काय झाले किंवा काय हवे ते लिहा किंवा बोला.';

  @override
  String get feedbackAddScreenshot => 'screenshot जोडा';

  @override
  String get feedbackScreenshotAdded => 'screenshot जोडला';

  @override
  String get feedbackIncluded => 'app version व फोनचे मॉडेल सोबत जाते.';

  @override
  String get feedbackSend => 'पाठवा';

  @override
  String get feedbackSent => 'मिळाले, धन्यवाद!';

  @override
  String get feedbackThanks => 'धन्यवाद!';

  @override
  String mlLoginRole(String role) {
    return 'भूमिका: $role';
  }

  @override
  String get expenseElsewhere =>
      'फवारणी (मजुरीसह), मजुरी आणि खतांचा खर्च त्यांच्या नोंदीत लिहा; हिशोबात तो आपोआप जोडला जातो.';

  @override
  String get expenseGoSpray => 'फवारणी';

  @override
  String get expenseGoLabour => 'मजुरी';

  @override
  String get expenseGoInputs => 'खते व शेणखत';

  @override
  String get mlWelcomeTitle => 'बागमित्र मध्ये आपले स्वागत';

  @override
  String get mlWelcomeLine =>
      'बागेच्या नोंदी, आजचे बाजारभाव आणि व्यापारी, एकाच ॲपमध्ये.';

  @override
  String get photoCheckOpen => 'फोटोवरून ओळखा';

  @override
  String get photoCheckHint => 'पान, फळ किंवा खोडाचा जवळून, उजेडात फोटो घ्या.';

  @override
  String get photoCheckPart => 'कोणता भाग? (ऐच्छिक)';

  @override
  String get photoCheckPartLeaf => 'पान';

  @override
  String get photoCheckPartFruit => 'फळ';

  @override
  String get photoCheckPartTrunk => 'खोड';

  @override
  String get photoCheckPartWholeTree => 'पूर्ण झाड';

  @override
  String get photoCheckRetry => 'पुन्हा तपासा';

  @override
  String get photoCheckBusy =>
      'फोटो तपासत आहोत… याला एक मिनिटापर्यंत वेळ लागू शकतो.';

  @override
  String get photoCheckChange => 'दुसरा फोटो';

  @override
  String get photoCheckBack => 'नोंदीकडे परत';

  @override
  String get photoCheckLikelyHigh => 'जास्त शक्यता';

  @override
  String get photoCheckLikelyMedium => 'मध्यम शक्यता';

  @override
  String get photoCheckLikelyLow => 'कमी शक्यता';

  @override
  String get photoCheckSigns => 'फोटोत दिसलेले';

  @override
  String get photoCheckSignsEnglish => 'फोटोत दिसलेले (इंग्रजीत)';

  @override
  String get photoCheckOpenCard => 'उपाय व माहिती पहा';

  @override
  String get photoCheckUnsure =>
      'अधिक स्पष्ट फोटो मदत करेल. उजेडात, जवळून दुसरा फोटो घ्या किंवा कार्डांतील लक्षणे पाहा.';

  @override
  String get photoCheckHealthy => 'छान! फोटोतील झाड निरोगी दिसते.';

  @override
  String get photoCheckNote =>
      'हा फोटोवरून दिलेला अंदाज आहे; सविस्तर माहिती कार्डात आहे.';

  @override
  String get photoCheckSeeCards => 'सर्व उपाय पहा';

  @override
  String get photoCheckOffline =>
      'फोटो तपासणीसाठी इंटरनेट लागते. फोटो इथेच ठेवला आहे; इंटरनेट सुरू झाल्यावर \'पुन्हा तपासा\' दाबा.';

  @override
  String get photoCheckFailed =>
      'थोड्या वेळाने पुन्हा तपासा. फोटो इथेच ठेवला आहे.';

  @override
  String get photoCheckUnavailable =>
      'फोटो तपासणी सध्या थांबली आहे; तोपर्यंत कार्डांतील लक्षणे पाहा.';

  @override
  String get photoCheckRefused => 'कृपया दुसरा फोटो घ्या.';

  @override
  String get photoCheckSignedOut => 'फोटो तपासण्यासाठी पुन्हा लॉगिन करा.';

  @override
  String get photoCheckDelete => 'हा फोटो हटवा';

  @override
  String get photoCheckDeleted => 'फोटो सर्व्हरवरून हटवला.';

  @override
  String get photoCheckDeleteFailed =>
      'इंटरनेट सुरू असताना \'हा फोटो हटवा\' पुन्हा दाबा.';

  @override
  String photoCheckLimitDaily(String count) {
    return 'आजचे $count फोटो पूर्ण झाले; उद्या पुन्हा वापरता येईल.';
  }

  @override
  String photoCheckLimitDailyAt(String count, String when) {
    return 'आजचे $count फोटो पूर्ण झाले; $when नंतर पुन्हा वापरता येईल.';
  }

  @override
  String photoCheckLimitMonthly(String count, String when) {
    return 'या महिन्याचे $count फोटो पूर्ण झाले; $when पासून पुन्हा वापरता येईल.';
  }

  @override
  String get photoCheckLimitTotal =>
      'आजच्या फोटो तपासण्या पूर्ण झाल्या; उद्या पुन्हा वापरता येईल.';

  @override
  String photoCheckLimitTotalAt(String when) {
    return 'आजच्या फोटो तपासण्या पूर्ण झाल्या; $when नंतर पुन्हा वापरता येईल.';
  }

  @override
  String photoOfflineLead(String what, String likely) {
    return 'फोनवरच्या प्राथमिक तपासणीनुसार: $what ($likely)';
  }

  @override
  String photoOfflineAlso(String what, String likely) {
    return 'किंवा: $what ($likely)';
  }

  @override
  String get photoOfflineCanker => 'कँकरसारखी लक्षणे';

  @override
  String get photoOfflineGreening => 'ग्रीनिंगसारखी लक्षणे';

  @override
  String get photoOfflineHealthy =>
      'फोनवरच्या प्राथमिक तपासणीनुसार: पान निरोगी दिसते.';

  @override
  String get photoOfflineUnclear =>
      'स्पष्ट ओळखीसाठी या फोटोची पूर्ण तपासणी लागेल. इंटरनेट आल्यावर \'पुन्हा तपासा\' दाबा.';

  @override
  String get photoOfflineNote =>
      'फोनवरचा अंदाज; इंटरनेट आल्यावर पूर्ण तपासणी करता येईल.';

  @override
  String get photoOfflinePcr =>
      'ग्रीनिंगची खात्री फक्त प्रयोगशाळेतील PCR चाचणीने होते; ग्रीनिंगसाठी \"उपाय व माहिती पहा\" दाबा.';

  @override
  String get billPhoto => 'बिलाचा फोटो';

  @override
  String get billPhotoOpen => 'बिलाचा फोटो मोठा पाहा';

  @override
  String get billFill => 'बिलावरून भरा';

  @override
  String get billReading => 'बिल वाचत आहे…';

  @override
  String get billUnsure => 'बिल नीट वाचता आले नाही; माहिती हाताने भरा.';

  @override
  String billFilled(String fields) {
    return 'बिलावरून भरले: $fields. एकदा तपासा.';
  }

  @override
  String get billNothingFilled => 'हे रकाने आधीच भरलेले होते; ते तसेच ठेवले.';

  @override
  String get billOffline => 'बिल वाचण्यासाठी इंटरनेट लागते.';

  @override
  String get billFailed =>
      'थोड्या वेळाने पुन्हा \'बिलावरून भरा\' दाबा; फोटो इथेच आहे.';

  @override
  String get billUnavailable =>
      'बिल वाचणे सध्या थांबले आहे; माहिती हाताने भरा.';

  @override
  String get billRefused => 'कृपया बिलाचा दुसरा फोटो घ्या.';

  @override
  String get billSignedOut => 'बिल वाचण्यासाठी पुन्हा लॉगिन करा.';

  @override
  String billLimitDaily(String count) {
    return 'आजची $count बिले वाचून झाली; उद्या पुन्हा वापरता येईल.';
  }

  @override
  String billLimitDailyAt(String count, String when) {
    return 'आजची $count बिले वाचून झाली; $when नंतर पुन्हा वापरता येईल.';
  }

  @override
  String billLimitMonthly(String count, String when) {
    return 'या महिन्याची $count बिले वाचून झाली; $when पासून पुन्हा वापरता येईल.';
  }

  @override
  String get billLimitTotal =>
      'आजची बिल वाचणी पूर्ण झाली; उद्या पुन्हा वापरता येईल.';

  @override
  String billLimitTotalAt(String when) {
    return 'आजची बिल वाचणी पूर्ण झाली; $when नंतर पुन्हा वापरता येईल.';
  }

  @override
  String get billPickTitle => 'बिलातील ओळ निवडा';

  @override
  String get billTotal => 'बिलाची एकूण रक्कम';

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
  String get billFieldProduct => 'औषधाचे नाव';

  @override
  String get billFieldActive => 'सक्रिय घटक';

  @override
  String get billFieldDose => 'मात्रा';

  @override
  String get billFieldCost => 'खर्च';

  @override
  String get billFieldAmount => 'रक्कम';

  @override
  String get billFieldDate => 'तारीख';

  @override
  String get billFieldNote => 'टीप';

  @override
  String sprayProductHeading(String n) {
    return 'घटक $n';
  }

  @override
  String get sprayAddProduct => '+ आणखी घटक जोडा';

  @override
  String sprayRemoveProduct(String n) {
    return 'घटक $n काढा';
  }

  @override
  String get spraySharedHeading => 'संपूर्ण फवारणीसाठी';

  @override
  String sprayMix(String names) {
    return 'मिश्रण: $names';
  }

  @override
  String get sprayMixHeading => 'मिश्रण:';

  @override
  String sprayMixTotal(String amount) {
    return 'एकूण खर्च $amount';
  }

  @override
  String sprayMixPhi(String days) {
    return 'मिश्रणाचा प्रतीक्षा कालावधी: $days दिवस (सर्वांत जास्त)';
  }

  @override
  String sprayPhiDays(String days) {
    return 'PHI $days दिवस';
  }

  @override
  String get sprayDetailTitle => 'फवारणी नोंद';

  @override
  String sprayDetailWater(String litres) {
    return 'पाणी $litres लिटर';
  }

  @override
  String sprayDetailArea(String acres) {
    return '$acres एकर';
  }

  @override
  String sprayDetailOperator(String name) {
    return 'फवारणी करणारा: $name';
  }

  @override
  String get sprayDetailProducts => 'टाकीतील घटक';

  @override
  String get billPickManyTitle => 'या फवारणीत मिसळलेल्या बिलातील ओळी निवडा';

  @override
  String billPickMany(String count) {
    return 'निवडलेल्या $count ओळी भरा';
  }

  @override
  String get sprayLabour => 'फवारणी मजुरी (₹, ऐच्छिक)';

  @override
  String get sprayLabourHelp =>
      'मजुरी नोंदीत (फवारणी काम) आधीच लिहिली असल्यास हा रकाना रिकामा ठेवा.';

  @override
  String sprayCostSplit(String products, String labour) {
    return 'एकूण खर्च = औषधे $products + मजुरी $labour';
  }

  @override
  String get askTitle => 'प्रश्न विचारा';

  @override
  String get askHint => 'तुमचा प्रश्न लिहा किंवा बोला';

  @override
  String get askSearch => 'उत्तर शोधा';

  @override
  String get askRelated => 'संबंधित प्रश्न';

  @override
  String get askCloser => 'हे जवळचे प्रश्न पाहा:';

  @override
  String get askNoMatch =>
      'या प्रश्नासाठी खालील मार्गदर्शक पाहा किंवा आपल्या KVK ला विचारा.';

  @override
  String get askOpenCard => 'उपाय व माहिती पहा';

  @override
  String get reactionsArticleTitle => 'हा लेख कसा वाटला?';

  @override
  String get reactionsAnswerTitle => 'हे उत्तर कसे वाटले?';

  @override
  String get reactionUseful => 'उपयोगी';

  @override
  String get reactionThanks => 'धन्यवाद';

  @override
  String get reactionLiked => 'आवडले';

  @override
  String get reactionOkay => 'ठीक';

  @override
  String get reactionUnclear => 'समजले नाही';

  @override
  String get reactionThanksToast => 'धन्यवाद!';

  @override
  String reactionChipSemantics(String label, int count) {
    return '$label, $count';
  }

  @override
  String get adminFeedReactions => 'प्रतिसाद';

  @override
  String get adminReactionsMost => 'सर्वात उपयोगी';

  @override
  String get adminReactionsLeast => 'सर्वात कमी उपयोगी';

  @override
  String adminReactionsTotals(int targets, int total) {
    return '$targets विषय · $total प्रतिसाद';
  }

  @override
  String get adminReactionsNone => 'प्रतिसाद आल्यावर इथे दिसतील.';

  @override
  String get adminReactionsQa => 'प्रश्नोत्तर';

  @override
  String get plotOtherCrops => 'इतर पिके';

  @override
  String get plotCropName => 'पिकाचे नाव';

  @override
  String get plotCropNameHint => 'उदा. टोमॅटो, झेंडू';

  @override
  String get requiredCropName => 'पिकाचे नाव लिहा';

  @override
  String get homePlotOpen => 'नोंदी उघडा';
}
