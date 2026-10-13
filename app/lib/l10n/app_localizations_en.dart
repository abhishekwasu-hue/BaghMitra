// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BagMitra';

  @override
  String get greetingHello => 'Namaste';

  @override
  String greetingName(String name) {
    return '$name ji';
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

    return 'Max $degreesString°';
  }

  @override
  String soilMoisture(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Soil moisture $percentString%';
  }

  @override
  String get stageDays => 'days';

  @override
  String nextStage(String stage, int days, String month) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Next stage: $stage · in about $daysString days · harvest $month';
  }

  @override
  String get todaysTasks => 'Today\'s tasks';

  @override
  String get seeAll => 'See all';

  @override
  String marketTitle(String market) {
    return '$market market';
  }

  @override
  String get sevenDayTrend => '7-day trend';

  @override
  String get perQuintal => 'per quintal';

  @override
  String get vsLastWeek => 'vs last week';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get navHome => 'Home';

  @override
  String get navOrchard => 'Orchard';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navAsk => 'Ask';

  @override
  String get taskDone => 'Done';

  @override
  String get markTaskDone => 'Mark task done';

  @override
  String get offlineBanner =>
      'You are offline. Your entries are saved and will sync.';

  @override
  String pendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncFailed => 'Sync failed. Will retry automatically.';

  @override
  String get loginTitle => 'Sign in with your mobile number';

  @override
  String get loginPhoneLabel => 'Mobile number';

  @override
  String get loginSendOtp => 'Send OTP';

  @override
  String loginOtpTitle(String phone) {
    return 'Enter the OTP sent to $phone';
  }

  @override
  String get loginOtpLabel => '6-digit OTP';

  @override
  String get loginVerify => 'Verify';

  @override
  String get loginInvalidPhone => 'Enter a valid 10-digit mobile number';

  @override
  String get loginInvalidOtp => 'The OTP is incorrect or expired';

  @override
  String get loginDemoNotice => 'Demo mode: any 6 digits will work';

  @override
  String get voiceInput => 'Speak';

  @override
  String get galleryTitle => 'Component gallery';

  @override
  String adminTitle(String product) {
    return '$product Admin';
  }

  @override
  String get adminCropTemplates => 'Crop stage templates';

  @override
  String get adminRiskRules => 'Risk rules';

  @override
  String get adminPrompts => 'AI prompt templates';

  @override
  String get adminTranslations => 'Translations';

  @override
  String get adminAiUsage => 'AI usage';

  @override
  String adminComingSoon(int milestone) {
    return 'Editing arrives in Milestone $milestone.';
  }

  @override
  String get demoDataNotice => 'Sample data';

  @override
  String get myOrchard => 'My orchard';

  @override
  String get addPlot => 'Add orchard block';

  @override
  String get plotsEmptyTitle => 'No orchard blocks yet';

  @override
  String get plotsEmptyBody =>
      'Add your first block to get a bahar calendar and daily tasks.';

  @override
  String get plotName => 'Block name';

  @override
  String get plotNameHint => 'e.g. Bag 1';

  @override
  String get plotCrop => 'Crop';

  @override
  String get plotVariety => 'Variety (optional)';

  @override
  String get plotAreaAcres => 'Area (acres)';

  @override
  String get plotTreeCount => 'Number of trees (optional)';

  @override
  String get plotPlantingYear => 'Planting year (optional)';

  @override
  String get save => 'Save';

  @override
  String get fieldRequired => 'Required';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String plotAcres(String area) {
    return '$area acres';
  }

  @override
  String plotTrees(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString trees';
  }

  @override
  String get plotSaved => 'Saved. It will sync when you are online.';

  @override
  String get deletePlot => 'Delete block';

  @override
  String deletePlotConfirm(String name) {
    return 'Delete $name? This also removes it from your other devices.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get startBahar => 'Start a bahar';

  @override
  String get baharEmptyTitle => 'No bahar planned yet';

  @override
  String get baharEmptyBody =>
      'Choose a bahar and write down your own dates. Suggested dates will come once an expert-checked calendar is ready.';

  @override
  String get baharWhich => 'Which bahar?';

  @override
  String get baharSeason => 'Season';

  @override
  String get baharDates => 'Your dates (optional)';

  @override
  String get baharPickDate => 'Pick a date';

  @override
  String get baharStatusPlanned => 'Planned';

  @override
  String get baharStatusActive => 'Running';

  @override
  String get baharStatusCompleted => 'Completed';

  @override
  String get baharStatusAbandoned => 'Stopped';

  @override
  String get adminCards => 'Knowledge cards';

  @override
  String get adminImports => 'Imports';

  @override
  String get adminAlerts => 'Alerts';

  @override
  String get adminSources => 'Sources';

  @override
  String get adminPublish => 'Publish';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminChemical => 'Chemical';

  @override
  String get adminImport => 'Import';

  @override
  String get adminImportSource => 'Source key';

  @override
  String get adminImportCsv => 'CSV (checked by hand)';

  @override
  String get adminImportClaims => 'Label claims';

  @override
  String get adminImportRestrictions => 'Bans and restrictions';

  @override
  String adminImportResult(
    int added,
    int changed,
    int removed,
    int unchanged,
    int pulled,
  ) {
    return 'Added $added · Changed $changed · Removed $removed · Unchanged $unchanged · Cards pulled $pulled';
  }

  @override
  String get adminResolve => 'Resolve';

  @override
  String get adminNoAlerts => 'No open alerts';

  @override
  String get adminNoCards => 'No cards yet';

  @override
  String get adminSignInRequired =>
      'Sign in with a knowledge-base admin account to use this section.';

  @override
  String get adminDone => 'Done';

  @override
  String get adminSignIn => 'Sign in';

  @override
  String get adminEmail => 'Email';

  @override
  String get adminPassword => 'Password';

  @override
  String get adminSignInFailed => 'Email or password is wrong.';

  @override
  String get adminSignOut => 'Sign out';

  @override
  String get adminNotConfigured =>
      'Admin sign-in needs SUPABASE_URL and SUPABASE_ANON_KEY.';
}
