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

    return 'माती ओली $percentString%';
  }

  @override
  String get stageDays => 'दिवस';

  @override
  String nextStage(String stage, int days, String month) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'पुढचा टप्पा: $stage · अंदाजे $daysString दिवसांत · काढणी $month';
  }

  @override
  String get todaysTasks => 'आजची कामं';

  @override
  String get seeAll => 'सगळी पाहा';

  @override
  String marketTitle(String market) {
    return '$market बाजार';
  }

  @override
  String get sevenDayTrend => '७ दिवसांचा कल';

  @override
  String get perQuintal => 'प्रति क्विंटल';

  @override
  String get vsLastWeek => 'गेल्या आठवड्यापेक्षा';

  @override
  String get takePhoto => 'फोटो काढा';

  @override
  String get navHome => 'घर';

  @override
  String get navOrchard => 'बाग';

  @override
  String get navAccounts => 'हिशोब';

  @override
  String get navAsk => 'विचारा';

  @override
  String get taskDone => 'पूर्ण';

  @override
  String get markTaskDone => 'काम पूर्ण झालं';

  @override
  String get offlineBanner =>
      'नेटवर्क नाही. तुमची नोंद जतन झाली आहे, नंतर पाठवली जाईल.';

  @override
  String pendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नोंदी पाठवायच्या बाकी',
      one: '१ नोंद पाठवायची बाकी',
    );
    return '$_temp0';
  }

  @override
  String get syncFailed => 'पाठवणं जमलं नाही. आपोआप पुन्हा प्रयत्न होईल.';

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
      'Google लॉगिन उघडता आले नाही. इंटरनेट तपासून पुन्हा प्रयत्न करा.';

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
  String get loginInvalidOtp => 'OTP चुकीचा आहे किंवा मुदत संपली';

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
  String get plotsEmptyTitle => 'अजून बाग जोडलेली नाही';

  @override
  String get plotsEmptyBody =>
      'बहार कॅलेंडर आणि रोजची कामं मिळवण्यासाठी पहिली बाग जोडा.';

  @override
  String get plotName => 'बागेचं नाव';

  @override
  String get plotNameHint => 'उदा. बाग १';

  @override
  String get plotCrop => 'पीक';

  @override
  String get plotVariety => 'जात (ऐच्छिक)';

  @override
  String get plotAreaAcres => 'क्षेत्र (एकर)';

  @override
  String get plotTreeCount => 'झाडांची संख्या (ऐच्छिक)';

  @override
  String get plotPlantingYear => 'लागवडीचं वर्ष (ऐच्छिक)';

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

    return '$countString झाडं';
  }

  @override
  String get plotSaved => 'जतन झालं. नेट आल्यावर पाठवलं जाईल.';

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
  String get baharEmptyTitle => 'अजून बहार ठरवलेला नाही';

  @override
  String get baharEmptyBody =>
      'बहार निवडा आणि तुमच्या तारखा लिहा. तज्ञांनी तपासलेलं कॅलेंडर तयार झाल्यावर सुचवलेल्या तारखा मिळतील.';

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
  String get adminNoAlerts => 'कोणतीही सूचना बाकी नाही';

  @override
  String get adminNoCards => 'अजून कार्डे नाहीत';

  @override
  String get adminSignInRequired =>
      'हा विभाग वापरण्यासाठी माहिती-कोश अॅडमिन खात्याने साइन इन करा.';

  @override
  String get adminDone => 'झालं';

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
  String get adminFeedNoItems => 'या यादीत काही नाही';

  @override
  String get adminFeedApproved => 'मंजूर';

  @override
  String adminFeedIssueCount(int count) {
    return '$count तपासणी मुद्दे';
  }

  @override
  String get adminFeedAiOff => 'AI सेट केलेले नाही';

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
  String get adminFeedNoIssues => 'तपासणी मुद्दे नाहीत';

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
      'प्रत्येक रकाना: दस्तऐवजात लिहिलेली किंमत व तिचे पान, किंवा \"नमूद नाही\".';

  @override
  String get adminFeedNotStated => 'नमूद नाही';

  @override
  String get adminFeedCardValue => 'किंमत';

  @override
  String get adminFeedCardPage => 'पान (उदा. p. 2)';

  @override
  String get adminFeedSaveCard => 'कार्ड जतन करा';

  @override
  String get adminFeedCardEmpty =>
      'किमान एक रकाना भरा किंवा \"नमूद नाही\" निवडा.';

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
      'वापरण्याजोगा मजकूर नाही: मजकूर पेस्ट करून पुन्हा अपलोड करा, किंवा टिप्पणीसह मुद्दे स्वीकारा.';

  @override
  String get adminFeedUnusedText =>
      'न वापरलेला मजकूर (बिघडलेला मजकूर-स्तर किंवा OCR):';

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
      'रिकामे क्षेत्र म्हणजे कोणतेही. जुळणी \"पात्र असू शकता\" म्हणते, \"मिळेल\" कधीच नाही.';

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
  String get adminFeedNoReplacement => 'बदली नाही';

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
  String get adminFeedNoDocument => 'दस्तऐवज निवडलेला नाही';

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
  String get adminFeedTermsUnknown => 'माहीत नाही';

  @override
  String get adminFeedTermsAllowed => 'परवानगी';

  @override
  String get adminFeedTermsDisallowed => 'परवानगी नाही';

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
  String get accountsEmpty => 'अजून नोंद नाही. खर्च किंवा विक्री जोडा.';

  @override
  String saleBy(String buyer, String kg) {
    return '$buyer · $kg किलो';
  }

  @override
  String get sprayLogTitle => 'फवारणी नोंदी';

  @override
  String get addSpray => 'फवारणी नोंदवा';

  @override
  String get spraysEmpty => 'अजून फवारणीची नोंद नाही.';

  @override
  String get sprayProduct => 'औषधाचं नाव';

  @override
  String get sprayActive => 'सक्रिय घटक (लेबलवर)';

  @override
  String get sprayDose => 'मात्रा (ऐच्छिक)';

  @override
  String get sprayWater => 'पाणी (लिटर, ऐच्छिक)';

  @override
  String get sprayArea => 'फवारलेलं क्षेत्र (एकर, ऐच्छिक)';

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
  String get sprayWarnBannedTitle => 'बंदी असलेलं रसायन';

  @override
  String sprayWarnBannedBody(String notification) {
    return 'हा घटक बंदी असलेला आहे ($notification). तो वापरू नका. जवळच्या KVK किंवा तज्ञांना विचारा.';
  }

  @override
  String get sprayWarnRestrictedTitle => 'या पिकासाठी निर्बंध';

  @override
  String sprayWarnRestrictedBody(String notification) {
    return 'या पिकासाठी हा घटक प्रतिबंधित आहे ($notification). लेबल पाहा आणि स्थानिक तज्ञांना विचारा.';
  }

  @override
  String get sprayWarnPhiTitle => 'तोडणी खूप लवकर';

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
  String get fieldLogEmpty => 'अजून नोंदी नाहीत. खत जोडा किंवा पाणी नोंदवा.';

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
  String get labourAddDay => 'मजूर दिवस जोडा';

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
  String get labourEmpty => 'अजून मजुरीच्या नोंदी नाहीत. एक जोडा.';

  @override
  String get labourTotalDue => 'मजुरांना देणे';

  @override
  String labourDue(String amount) {
    return 'बाकी $amount';
  }

  @override
  String get harvestTitle => 'काढणी';

  @override
  String get harvestAdd => 'काढणी जोडा';

  @override
  String get harvestKg => 'प्रमाण (किलो)';

  @override
  String get harvestGrade => 'ग्रेड (ऐच्छिक)';

  @override
  String get harvestSize => 'आकार (ऐच्छिक)';

  @override
  String get harvestEmpty => 'अजून काढणी नोंदवलेली नाही. एक नोंद जोडा.';

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
  String get compareSame => 'बदल नाही';

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
      'तुमच्या नोंदी साठवण्यासाठी आणि सुरक्षित ठेवण्यासाठी ही संमती लागते. ती इथे बंद करता येत नाही.';

  @override
  String get profilePhoneSignedIn => 'या नंबरने तुम्ही लॉगिन करता.';

  @override
  String get profileAddPhone => 'मोबाईल नंबर जोडा (ऐच्छिक)';

  @override
  String get profilePhoneContactOnly =>
      'फक्त तुमच्याशी संपर्कासाठी. यानं लॉगिन होत नाही; लॉगिन Google नेच होईल.';

  @override
  String get profileSaved => 'जतन झालं.';

  @override
  String get profileSignOut => 'लॉगआउट';

  @override
  String get profileSignOutTitle => 'लॉगआउट करायचं?';

  @override
  String get profileSignOutBody =>
      'तुमच्या नोंदी या फोनवरच राहतील. पुन्हा लॉगिन केल्यावर दिसतील.';

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
      'लोकेशन बंद केलेले आहे. फोनच्या अॅप सेटिंगमध्ये परवानगी द्या.';

  @override
  String get boundaryFailed =>
      'आपले ठिकाण मिळाले नाही. मोकळ्या जागेत पुन्हा प्रयत्न करा.';

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
  String get loginTryWithout => 'खात्याशिवाय वापरून पहा';

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
  String get walkthroughSkip => 'वगळा';

  @override
  String get walkthroughNext => 'पुढे';

  @override
  String get walkthroughStart => 'सुरू करा';

  @override
  String get walkthroughPlotsTitle => 'तुमचे प्लॉट आणि बहार कॅलेंडर';

  @override
  String get walkthroughPlotsBody =>
      'तुमचे प्लॉट जोडा. प्रत्येक बहारसाठी हंगामाचं कॅलेंडर आणि करायच्या कामांची यादी दिसेल.';

  @override
  String get walkthroughWeatherTitle => 'तुमच्या प्लॉटसाठी हवामान सूचना';

  @override
  String get walkthroughWeatherBody =>
      'तुमच्या प्लॉटवरचं हवामान पहा. पाऊस, ऊन किंवा थंडीकडे लक्ष द्यायची गरज असेल तेव्हा सूचना मिळेल.';

  @override
  String get walkthroughMarketTitle => 'देशभरातील बाजारभाव';

  @override
  String get walkthroughMarketBody =>
      'तुमच्या पिकाचे भारतभरातील बाजारांमधले अलीकडचे भाव पहा.';

  @override
  String get walkthroughRecordsTitle => 'तुमच्या नोंदी आणि हिशोब';

  @override
  String get walkthroughRecordsBody =>
      'फवारणी, खर्च, मजुरी आणि विक्रीची नोंद ठेवा आणि हिशोब पहा. इंटरनेट नसलं तरी चालतं; नेटवर्क आल्यावर नोंदी पाठवल्या जातात.';

  @override
  String get settingsShowWalkthrough => 'ॲपची ओळख पुन्हा पहा';

  @override
  String get settingsPhotoMobileData => 'मोबाइल डेटावरही फोटोचा बॅकअप घ्या';

  @override
  String get settingsPhotoMobileDataHint =>
      'पाहणीच्या फोटोंचा बॅकअप वाय-फायवर होतो. मोबाइल डेटाही वापरायचा असेल तर हे चालू करा.';

  @override
  String buildLabel(String sha) {
    return 'चाचणी बिल्ड $sha';
  }

  @override
  String get seedOrchard => 'नमुना बाग भरा';

  @override
  String get seedOrchardDone => 'नमुना बाग भरला';

  @override
  String get voiceUnavailable => 'या फोनवर आवाजाने लिहिणे उपलब्ध नाही';

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
  String get tasksEmpty => 'अजून कामे नाहीत. + बटणाने जोडा.';

  @override
  String get tasksOverdue => 'उशीर झालेली';

  @override
  String get tasksToday => 'आज';

  @override
  String get tasksUpcoming => 'पुढची';

  @override
  String get tasksDone => 'पूर्ण';

  @override
  String get noTasksToday => 'आज काही बाकी नाही';

  @override
  String get taskOverdue => 'उशीर';

  @override
  String dueInDays(int n) {
    return '$n दिवसांत';
  }

  @override
  String get editPlot => 'बाग संपादित करा';

  @override
  String get plotOpenRecords => 'बहार, फवारणी आणि हिशेब';

  @override
  String get plotBoundaryNone => 'हद्द अजून नोंदवलेली नाही';

  @override
  String get plotCentre => 'मध्यबिंदू';

  @override
  String get calendarTitle => 'हंगाम दिनदर्शिका';

  @override
  String get calendarIntro =>
      'पुढील बारा महिन्यांतील तुमच्या बहाराच्या तारखा आणि कामे, तुम्ही नोंदवलेल्या माहितीवरून.';

  @override
  String get calendarMonthEmpty => 'या महिन्यात काही नोंद नाही.';

  @override
  String get calendarStagePlanned => 'नियोजित';

  @override
  String get calendarStageDone => 'झाले';

  @override
  String get calendarOpen => 'हंगाम दिनदर्शिका';

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
  String get baharCompareNoLast => 'या बागेत अजून कोणताही बहार नोंदलेला नाही.';

  @override
  String baharCompareSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get baharCompareNoPoints => 'या बहारासाठी अजून तपासलेली माहिती नाही.';

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
      'हवामान अद्ययावत होऊ शकले नाही; शेवटचे जतन केलेले दिवस दाखवत आहोत.';

  @override
  String get weatherNone => 'अजून हवामान नाही. फोन ऑनलाइन असताना ते येईल.';

  @override
  String weatherRain(String mm) {
    return '$mm मिमी पाऊस';
  }

  @override
  String weatherSource(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get labelInfoTitle => 'लेबल माहिती';

  @override
  String get labelInfoBanner =>
      'ही माहिती नोंदणीकृत लेबलवर (CIB&RC) छापलेली आहे. ही शिफारस नाही. कोणताही वापर करण्यापूर्वी उत्पादनाचे लेबल वाचा आणि तुमच्या कृषी विज्ञान केंद्र (KVK) किंवा कृषी अधिकाऱ्याकडून खात्री करून घ्या.';

  @override
  String get labelInfoEmpty => 'नोंदणीकृत लेबलची माहिती अजून उपलब्ध नाही.';

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
    return 'काढणीपूर्वी $days दिवस (PHI)';
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
  String marketStale(String reason) {
    return 'भाव अद्ययावत होऊ शकले नाहीत: $reason';
  }

  @override
  String get marketStaleNoReason =>
      'भाव अद्ययावत होऊ शकले नाहीत; शेवटची जतन केलेली यादी दाखवत आहोत.';

  @override
  String get marketEmpty =>
      'अजून भाव नाहीत. फोन ऑनलाइन असताना आणि भावांचा स्रोत जोडलेला असताना ते येतील.';

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
  String get practicesGapsTitle => 'यांसाठी अजून रसायनविरहित उपाय सापडला नाही';

  @override
  String get practicesSourcesLine =>
      'स्रोत: NHB आणि डॉ. पंदेकृवि, अकोला. प्रत्येक पद्धतीखाली तपशील.';

  @override
  String get scoutingTitle => 'पाहणी नोंद';

  @override
  String get scoutingAdd => 'पाहणी नोंदवा';

  @override
  String get scoutingEmpty =>
      'अजून पाहणी नोंदवलेली नाही. या बागेत काय दिसले ते नोंदवा.';

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
  String get scoutingRemovePhoto => 'फोटो काढा';

  @override
  String get scoutingPhotoFailed => 'फोटो घेता आला नाही. पुन्हा प्रयत्न करा.';

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
  String get scoutingSeverityNone => 'दिसले नाही';

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
      'पाण्याचे प्रमाण जमीन, झाडाचा घेर आणि हवामानावर अवलंबून असते. पाणी देणे बदलण्याआधी आपल्या कृषी विज्ञान केंद्राला (KVK) विचारा.';

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
      'या बागेचे लागवड वर्ष भरलेले नाही. झाडाचे वय निवडा.';

  @override
  String get irrigationNoRows => 'या वयासाठी स्रोतात अजून आकडा नाही.';

  @override
  String get irrigationStagesTitle => 'फुलोरा, फळ आणि बहाराचा ताण';

  @override
  String get irrigationGapsTitle => 'स्रोतात अजून सापडले नाही';

  @override
  String get irrigationSourcesLine =>
      'स्रोत: NHB, डॉ. पंदेकृवि अकोला आणि प्रकाशित लिंबूवर्गीय संशोधन. प्रत्येक मुद्द्याखाली तपशील.';

  @override
  String get feedTitle => 'सरकारी संदेश';

  @override
  String get feedOpenHint => 'अधिकृत GR, योजना आणि शेवटच्या तारखा';

  @override
  String get feedFilterAll => 'सगळे';

  @override
  String get feedFilterOfficial => 'अधिकृत';

  @override
  String get feedFilterSchemes => 'योजना';

  @override
  String get feedFilterDeadlines => 'शेवटच्या तारखा';

  @override
  String get feedFilterNews => 'बातम्या';

  @override
  String get feedBadgeOfficial => 'अधिकृत';

  @override
  String feedGrNumber(String number) {
    return 'GR क्र. $number';
  }

  @override
  String get feedBadgeNews => 'बातमी — अधिकृत नाही';

  @override
  String feedReplacedBy(String replacement) {
    return 'मागे घेतले. याच्या जागी आता: $replacement';
  }

  @override
  String feedExpired(String date) {
    return 'आता लागू नाही ($date ला संपले)';
  }

  @override
  String feedMayBeEligible(String reason) {
    return 'तुम्ही पात्र असू शकता कारण $reason';
  }

  @override
  String get feedFooter => 'काही करण्याआधी अधिकृत GR/पोर्टल तपासा.';

  @override
  String feedDeadline(String date) {
    return 'शेवटची तारीख: $date';
  }

  @override
  String feedUpdated(String date) {
    return '$date ला अद्ययावत';
  }

  @override
  String get feedEmpty => 'अजून संदेश नाहीत. फोन ऑनलाइन असताना येतील.';

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
  String get feedNotFound => 'हा संदेश आता जतन यादीत नाही.';

  @override
  String get feedUnseen => 'नवीन';

  @override
  String get feedDismiss => 'माझ्या यादीतून काढा';

  @override
  String get feedDismissed => 'तुमच्या यादीतून काढले.';

  @override
  String get feedPrefsTitle => 'सूचना सेटिंग';

  @override
  String get feedPrefsQuietTitle => 'शांत वेळ (सूचना नाहीत)';

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
  String get feedPrefsSaveFailed =>
      'जतन झाले नाही. इंटरनेट आल्यावर पुन्हा करा.';

  @override
  String get feedPrefsOffline =>
      'इंटरनेट नाही. ही तुमची शेवटची जतन केलेली सेटिंग आहे. जतन करायला इंटरनेट लागेल.';

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
  String get feedCheckPrivacy => 'हा मजकूर तुमच्या फोनवर जतन होत नाही.';

  @override
  String get feedCheckFailed => 'तपासता आले नाही. यासाठी इंटरनेट लागेल.';

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
  String get speakUnavailable => 'या फोनवर या भाषेचा आवाज अजून नाही.';

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
    return 'आजची कामं ($date)';
  }

  @override
  String get loadingLabel => 'लोड होत आहे';

  @override
  String get accountSwitchTitle => 'दुसऱ्या खात्याच्या नोंदी';

  @override
  String get accountSwitchBody =>
      'या फोनवर दुसऱ्या खात्याच्या नोंदी आहेत. पुढे गेल्यास त्या या फोनवरून काढल्या जातील (सर्व्हरवर सुरक्षित राहतील) आणि तुमच्या नोंदी डाउनलोड होतील.';

  @override
  String get accountSwitchContinue => 'पुढे जा';

  @override
  String get accountBlockedTitle => 'या फोनवर न पाठवलेल्या नोंदी';

  @override
  String accountBlockedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आधीच्या खात्याच्या $count नोंदी अजून पाठवलेल्या नाहीत.',
      one: 'आधीच्या खात्याची १ नोंद अजून पाठवलेली नाही.',
    );
    return '$_temp0 त्या खात्याने पुन्हा साइन इन करा आणि इंटरनेट चालू ठेवून ॲप उघडा, म्हणजे त्या पाठवल्या जातील. मग या खात्याने साइन इन करा.';
  }

  @override
  String accountPreviousPhone(String phone) {
    return 'आधीचे खाते: $phone';
  }

  @override
  String get insuranceTitle => 'पीक विमा';

  @override
  String get insuranceEmpty =>
      'या बागेसाठी अजून विमा नोंद नाही. घेतलेला पीक विमा नोंदवा, किंवा नुकसान झाल्यावर क्लेम किट उघडा.';

  @override
  String get insurancePoliciesNone => 'अजून विमा नोंद नाही.';

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
  String get insuranceSchemeUnknown => 'माहीत नाही';

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
  String get insuranceNotSet => 'दिलेली नाही';

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
  String get claimKitTitle => 'क्लेम किट';

  @override
  String get claimKitFromAlert => 'नुकसानीचे फोटो · क्लेम किट';

  @override
  String get claimKitPlot => 'बाग';

  @override
  String get claimKitPickPlot => 'बाग निवडा';

  @override
  String get claimKitDate => 'नुकसानीची तारीख';

  @override
  String get claimKitPhotos => 'नुकसानीचे फोटो (तारीख व GPS जोडले जातात)';

  @override
  String get claimKitNoPhotos => 'अजून फोटो नाहीत.';

  @override
  String get claimKitNoGps => 'GPS मिळाले नाही';

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
      'नुकसानीची माहिती विमा कंपनी, तुमची बँक किंवा CSC केंद्राला लवकर द्या. अनेक पॉलिसींमध्ये ७२ तासांच्या आत कळवावे लागते.';

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
      'पाहणी होण्याआधी खराब फळे किंवा झाडे हटवू नका, वेगळे सांगितले नसल्यास.';

  @override
  String get claimKitShare => 'PDF पाठवा';

  @override
  String get claimKitShareFailed => 'PDF तयार झाली नाही. पुन्हा प्रयत्न करा.';

  @override
  String get claimKitDelete => 'नुकसान नोंद हटवा';

  @override
  String get claimKitDeleteConfirm =>
      'ही नुकसान नोंद व तिचे फोटो या फोनवरून हटवायचे?';

  @override
  String get claimKitLocalOnly =>
      'फोटो व टीप या फोनवरच राहतात. गरज असेल तेव्हा PDF पाठवा.';

  @override
  String get claimPdfTitle => 'पीक नुकसान नोंद';

  @override
  String get claimPdfPlotGps => 'बागेचे ठिकाण (GPS)';

  @override
  String get claimPdfNoGps => 'नोंदवलेले नाही';

  @override
  String get claimPdfPolicy => 'विमा';

  @override
  String get claimPdfPhotos => 'फोटो';

  @override
  String get claimPdfNote => 'टीप';

  @override
  String get claimPdfDone => 'केले';

  @override
  String get claimPdfNotDone => 'अजून नाही';

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
  String get labTestReportLocal => 'अहवाल याच फोनवर राहतो.';

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
  String get labTestNextDueHint => 'आठवण कार्य हवे असेल तरच तारीख निवडा.';

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
  String get schemeWhoCheck => 'सर्वसाधारण माहिती. अधिकृत पान तपासा.';

  @override
  String get schemeDocuments => 'सहसा लागणारी कागदपत्रे';

  @override
  String get schemeDocumentsHint =>
      'जे आधीच आहे त्यावर खूण करा. फक्त याच फोनवर राहते.';

  @override
  String schemeDocsReady(int have, int total) {
    return '$total पैकी $have तयार';
  }

  @override
  String get schemeNotConfirmed => 'अधिकृत पानावर एकदा खात्री करून घ्या';

  @override
  String get schemeWhereToApply => 'कुठे अर्ज करावा';

  @override
  String schemeSources(String date) {
    return 'स्रोत ($date रोजी तपासले)';
  }

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
      'बागेतील अनेक समस्या सारख्याच दिसतात. ही कार्डे तुम्हाला जे दिसते ते नेमके सांगायला मदत करतात; समस्या नक्की कोणती हे ती सांगत नाहीत.';

  @override
  String get lookalikesSee => 'काय दिसू शकते';

  @override
  String get lookalikesConfusedWith => 'यासारखे दिसणारे';

  @override
  String get lookalikesConfirm => 'खात्री कोण करू शकते';

  @override
  String get lookalikesCheckLine =>
      'खात्री नाही? अंदाज लावू नका. फोटो घ्या, निरीक्षण नोंदीत लिहा आणि प्रयोगशाळा किंवा तज्ज्ञांकडून तपासून घ्या.';

  @override
  String get lookalikesLogThis => 'निरीक्षण नोंदीत लिहा';

  @override
  String get lookalikesFindLab => 'प्रयोगशाळा / तज्ज्ञ शोधा';

  @override
  String get lookalikesSources => 'स्रोत';

  @override
  String get lookalikesDraft => 'मसुदा: एक स्रोत अजून तपासलेला नाही';

  @override
  String get lookalikesEmpty => 'अजून कार्डे नाहीत.';

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
  String get directoryUnverified => 'अधिकृत पानावर अजून तपासलेले नाही';

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
  String directoryChecked(Object date) {
    return 'तपासले $date';
  }

  @override
  String get directoryCheckLine =>
      'माहिती दाखवलेल्या तारखेला अधिकृत पानांवरून घेतली आहे. प्रवासापूर्वी फोन करून किंवा पान पाहून खात्री करा.';

  @override
  String get directoryEmpty => 'अजून काही नोंद नाही.';

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
}
