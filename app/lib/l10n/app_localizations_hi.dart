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
}
