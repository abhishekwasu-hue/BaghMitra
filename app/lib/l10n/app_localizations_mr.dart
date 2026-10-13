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
}
