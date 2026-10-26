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
  String get baharCompareDraft =>
      'मसुदा: तज्ज्ञांनी अजून तपासलेले नाही. स्थानिक तज्ज्ञांकडून खात्री करा.';

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
}
