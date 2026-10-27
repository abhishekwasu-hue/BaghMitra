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

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get addExpense => 'Add expense';

  @override
  String get addSale => 'Record a sale';

  @override
  String get expenseCategory => 'What was it for?';

  @override
  String get amountRupees => 'Amount (₹)';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get accountsExpenses => 'Expenses';

  @override
  String get accountsIncome => 'Income';

  @override
  String get accountsProfit => 'Profit';

  @override
  String get accountsDues => 'Buyers owe';

  @override
  String get costPerAcre => 'Cost per acre';

  @override
  String get costPerTree => 'Cost per tree';

  @override
  String get costPerTonne => 'Cost per tonne';

  @override
  String get allBahars => 'All';

  @override
  String get saleBuyer => 'Buyer';

  @override
  String get saleKg => 'Quantity (kg)';

  @override
  String get saleRate => 'Rate (₹ per quintal)';

  @override
  String get saleDeductions => 'Deductions (₹, optional)';

  @override
  String get salePaid => 'Received so far (₹)';

  @override
  String get accountsEmpty => 'No entries yet. Add an expense or a sale.';

  @override
  String saleBy(String buyer, String kg) {
    return '$buyer · $kg kg';
  }

  @override
  String get sprayLogTitle => 'Spray log';

  @override
  String get addSpray => 'Add spray';

  @override
  String get spraysEmpty => 'No sprays recorded yet.';

  @override
  String get sprayProduct => 'Product name';

  @override
  String get sprayActive => 'Active ingredient (on the label)';

  @override
  String get sprayDose => 'Dose (optional)';

  @override
  String get sprayWater => 'Water (litres, optional)';

  @override
  String get sprayArea => 'Area sprayed (acres, optional)';

  @override
  String get sprayCost => 'Cost (₹, optional)';

  @override
  String get sprayOperator => 'Sprayed by (optional)';

  @override
  String get sprayPhi => 'Days before harvest, PHI (optional)';

  @override
  String get sprayTarget => 'For which pest or disease (optional)';

  @override
  String get sprayDate => 'Date';

  @override
  String get sprayWhichBahar => 'Which bahar? (to check harvest date)';

  @override
  String get sprayWarnBannedTitle => 'Banned chemical';

  @override
  String sprayWarnBannedBody(String notification) {
    return 'This ingredient is banned ($notification). Do not use it. Ask your local KVK or expert.';
  }

  @override
  String get sprayWarnRestrictedTitle => 'Restricted for this crop';

  @override
  String sprayWarnRestrictedBody(String notification) {
    return 'This ingredient is restricted for this crop ($notification). Check the label and ask your local expert.';
  }

  @override
  String get sprayWarnPhiTitle => 'Harvest too soon';

  @override
  String sprayWarnPhiBody(String date) {
    return 'Harvest is planned before the waiting period ends. Safe to harvest from $date.';
  }

  @override
  String get fieldLogTitle => 'Field log';

  @override
  String get addInput => 'Add fertiliser';

  @override
  String get logIrrigation => 'Log irrigation';

  @override
  String get inputKind => 'What did you apply?';

  @override
  String get inputProduct => 'Product name';

  @override
  String get inputQuantity => 'Quantity (optional)';

  @override
  String get inputUnit => 'Unit';

  @override
  String get inputCost => 'Cost (₹, optional)';

  @override
  String get irrigationTitle => 'Irrigation';

  @override
  String get irrigationHours => 'Hours (optional)';

  @override
  String get irrigationLitres => 'Water in litres (optional)';

  @override
  String get fieldLogEmpty =>
      'No entries yet. Add fertiliser or log irrigation.';

  @override
  String inputLine(String quantity, String unit) {
    return '$quantity $unit';
  }

  @override
  String irrigationHoursLine(String hours) {
    return '$hours h';
  }

  @override
  String get labourTitle => 'Labour';

  @override
  String get labourAddDay => 'Add worker day';

  @override
  String get labourWorker => 'Worker name';

  @override
  String get labourTask => 'Work done';

  @override
  String get labourWage => 'Wage (₹)';

  @override
  String get labourAdvance => 'Advance paid (₹, optional)';

  @override
  String get labourPaidNow => 'Paid in full today';

  @override
  String get labourSettled => 'Settled';

  @override
  String get labourMarkPaid => 'Mark paid';

  @override
  String get labourEmpty => 'No worker days yet. Add one.';

  @override
  String get labourTotalDue => 'Total owed to workers';

  @override
  String labourDue(String amount) {
    return 'Due $amount';
  }

  @override
  String get harvestTitle => 'Harvest';

  @override
  String get harvestAdd => 'Add harvest';

  @override
  String get harvestKg => 'Quantity (kg)';

  @override
  String get harvestGrade => 'Grade (optional)';

  @override
  String get harvestSize => 'Size (optional)';

  @override
  String get harvestEmpty => 'No harvest recorded yet. Add a lot.';

  @override
  String harvestTotal(String kg) {
    return 'Total $kg kg';
  }

  @override
  String get moreMenu => 'More';

  @override
  String harvestKgValue(String kg) {
    return '$kg kg';
  }

  @override
  String get compareTitle => 'Compare seasons';

  @override
  String get compareEmpty =>
      'Start a bahar and add records to compare seasons.';

  @override
  String compareVs(String bahar, String change) {
    return 'vs $bahar: $change';
  }

  @override
  String compareMore(String amount) {
    return '$amount more';
  }

  @override
  String compareLess(String amount) {
    return '$amount less';
  }

  @override
  String get compareSame => 'no change';

  @override
  String get exportShare => 'Share spreadsheet';

  @override
  String get exportDate => 'Date';

  @override
  String get exportType => 'Type';

  @override
  String get exportDetails => 'Details';

  @override
  String get exportTypeExpense => 'Expense';

  @override
  String get exportTypeSale => 'Sale';

  @override
  String get exportTypeSpray => 'Spray';

  @override
  String get exportTypeInput => 'Input';

  @override
  String get exportTypeLabour => 'Labour';

  @override
  String get exportKg => 'kg';

  @override
  String get exportSharePdf => 'Share PDF';

  @override
  String get onboardingWelcome => 'Welcome to BagMitra';

  @override
  String get onboardingLanguage => 'Choose your language';

  @override
  String get onboardingName => 'Your name (optional)';

  @override
  String get onboardingVillage => 'Village (optional)';

  @override
  String get onboardingTaluka => 'Taluka (optional)';

  @override
  String get onboardingDistrict => 'District (optional)';

  @override
  String get onboardingConsentData =>
      'I agree that BagMitra stores my orchard records to run the app.';

  @override
  String get onboardingConsentWhatsapp =>
      'Send me reminders on WhatsApp (optional).';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get boundaryWalk => 'Mark boundary by walking';

  @override
  String get boundaryTitle => 'Walk the boundary';

  @override
  String get boundaryHelp =>
      'Stand at a corner of the block and tap “Add this corner”. Walk to each corner and repeat. You need at least 3.';

  @override
  String get boundaryAdd => 'Add this corner';

  @override
  String get boundaryUndo => 'Remove last corner';

  @override
  String get boundaryDone => 'Done';

  @override
  String boundaryCorners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count corners',
      one: '1 corner',
    );
    return '$_temp0';
  }

  @override
  String boundaryArea(String acres) {
    return 'Area about $acres acres';
  }

  @override
  String boundaryAccuracy(String metres) {
    return '±$metres m';
  }

  @override
  String get boundaryServiceOff => 'Turn on location (GPS) on your phone.';

  @override
  String get boundaryDenied => 'Allow location to mark the boundary.';

  @override
  String get boundaryDeniedForever =>
      'Location is blocked. Allow it in the phone\'s app settings.';

  @override
  String get boundaryFailed =>
      'Could not get your location. Try again outside.';

  @override
  String boundaryMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count corners',
      one: '1 corner',
    );
    return 'Boundary marked: $_temp0';
  }

  @override
  String get loginTryWithout => 'Try without account';

  @override
  String get localModeBanner =>
      'Offline test mode: your data stays on this phone';

  @override
  String testBuildBadge(String sha) {
    return 'TEST BUILD $sha';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sendLogs => 'Send logs';

  @override
  String get walkthroughSkip => 'Skip';

  @override
  String get walkthroughNext => 'Next';

  @override
  String get walkthroughStart => 'Start';

  @override
  String get walkthroughPlotsTitle => 'Your plots and bahar calendar';

  @override
  String get walkthroughPlotsBody =>
      'Add your plots. For each bahar you see a season calendar and a list of tasks.';

  @override
  String get walkthroughWeatherTitle => 'Weather alerts for your plot';

  @override
  String get walkthroughWeatherBody =>
      'See the weather at your plot and get an alert when rain, heat or cold may need your attention.';

  @override
  String get walkthroughMarketTitle => 'Mandi prices across India';

  @override
  String get walkthroughMarketBody =>
      'Check recent mandi prices for your crop in markets across India.';

  @override
  String get walkthroughRecordsTitle => 'Your records and accounts';

  @override
  String get walkthroughRecordsBody =>
      'Note sprays, expenses, labour and sales, and see your accounts. Works without internet; records are sent when the network is back.';

  @override
  String get settingsShowWalkthrough => 'See the app introduction again';

  @override
  String buildLabel(String sha) {
    return 'Test build $sha';
  }

  @override
  String get seedOrchard => 'Add sample orchard';

  @override
  String get seedOrchardDone => 'Sample orchard added';

  @override
  String get voiceUnavailable => 'Voice input is not available on this phone';

  @override
  String get voiceListening => 'Listening… tap to stop';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get addTask => 'Add a task';

  @override
  String get taskWhat => 'What needs doing?';

  @override
  String get taskKind => 'Kind';

  @override
  String get taskDue => 'Due';

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get tasksEmpty => 'No tasks yet. Add one with the + button.';

  @override
  String get tasksOverdue => 'Overdue';

  @override
  String get tasksToday => 'Today';

  @override
  String get tasksUpcoming => 'Coming up';

  @override
  String get tasksDone => 'Done';

  @override
  String get noTasksToday => 'Nothing due today';

  @override
  String get taskOverdue => 'Overdue';

  @override
  String dueInDays(int n) {
    return 'In $n days';
  }

  @override
  String get editPlot => 'Edit block';

  @override
  String get plotOpenRecords => 'Bahar, sprays and accounts';

  @override
  String get plotBoundaryNone => 'Boundary not marked yet';

  @override
  String get plotCentre => 'Centre point';

  @override
  String get calendarTitle => 'Season calendar';

  @override
  String get calendarIntro =>
      'Your bahar dates and tasks for the next twelve months, from what you entered.';

  @override
  String get calendarMonthEmpty => 'Nothing dated this month.';

  @override
  String get calendarStagePlanned => 'planned';

  @override
  String get calendarStageDone => 'done';

  @override
  String get calendarOpen => 'Season calendar';

  @override
  String get baharCompareTitle => 'Compare bahars';

  @override
  String get baharCompareIntro =>
      'Points from published sources to help you weigh each bahar. The decision is yours; sources sometimes disagree.';

  @override
  String baharCompareLast(String bahar) {
    return 'Last bahar on this block: $bahar';
  }

  @override
  String get baharCompareNoLast => 'No bahar recorded on this block yet.';

  @override
  String baharCompareSource(String source) {
    return 'Source: $source';
  }

  @override
  String get baharCompareNoPoints =>
      'No checked information for this bahar yet.';

  @override
  String get baharCompareUse => 'Use this bahar';

  @override
  String get weatherTitle => 'Weather';

  @override
  String weatherAsOf(String date) {
    return 'Updated $date';
  }

  @override
  String get weatherStale =>
      'Weather could not be updated; showing the last saved days.';

  @override
  String get weatherNone =>
      'No weather yet. It loads when the phone is online.';

  @override
  String weatherRain(String mm) {
    return '$mm mm rain';
  }

  @override
  String weatherSource(String source) {
    return 'Source: $source';
  }

  @override
  String get labelInfoTitle => 'Label information';

  @override
  String get labelInfoBanner =>
      'This is information printed on registered labels (CIB&RC). It is not a recommendation. Read the product label and confirm with your KVK or agriculture officer before any use.';

  @override
  String get labelInfoEmpty =>
      'No registered label information is available yet.';

  @override
  String labelInfoUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get labelInfoDose => 'Dose on label:';

  @override
  String labelInfoInterval(String days) {
    return 'Interval: $days days';
  }

  @override
  String labelInfoPhi(String days) {
    return 'PHI: $days days before harvest';
  }

  @override
  String labelInfoMaxSprays(String count) {
    return 'Max sprays: $count';
  }

  @override
  String labelInfoCrop(String crop) {
    return 'Label crop: $crop';
  }

  @override
  String labelInfoSource(String title) {
    return 'Source: $title';
  }

  @override
  String get marketPricesTitle => 'Market prices';

  @override
  String get marketOpen => 'Market prices';

  @override
  String get marketScopeAll => 'All';

  @override
  String get marketScopeLocal => 'Near me';

  @override
  String get marketScopeMajor => 'Major mandis';

  @override
  String get marketTagLocal => 'Near you';

  @override
  String get marketTagMajor => 'Major mandi';

  @override
  String get marketPerQuintal => 'per quintal';

  @override
  String marketRange(String min, String max) {
    return 'Min–max: $min – $max';
  }

  @override
  String marketVariety(String variety) {
    return 'Variety: $variety';
  }

  @override
  String marketUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String marketStale(String reason) {
    return 'Prices could not be updated: $reason';
  }

  @override
  String get marketStaleNoReason =>
      'Prices could not be updated; showing the last saved list.';

  @override
  String get marketEmpty =>
      'No prices yet. They load when the phone is online and the price source is connected.';

  @override
  String get practicesOpen => 'Orchard practices (non-chemical)';

  @override
  String get practicesTitle => 'Orchard practices';

  @override
  String practicesSource(String source) {
    return 'Source: $source';
  }

  @override
  String get practicesEvidenceOfficial => 'Official';

  @override
  String get practicesEvidenceUniversity => 'University';

  @override
  String get practicesEvidenceResearch => 'Research finding';

  @override
  String get practicesEvidenceInferred => 'Inferred';

  @override
  String get practicesGapsTitle => 'No non-chemical practice found yet';

  @override
  String get practicesSourcesLine =>
      'Sources: NHB and Dr. PDKV, Akola. Details under each practice.';

  @override
  String get irrigationOpen => 'Irrigation guide (ओलित तक्ता)';

  @override
  String get irrigationGuideTitle => 'Irrigation guide';

  @override
  String get irrigationCaveat =>
      'Amounts depend on your soil, the tree\'s canopy and the weather. Check with your KVK before you change your watering.';

  @override
  String get irrigationCropLabel => 'Crop';

  @override
  String get irrigationAgeLabel => 'Tree age';

  @override
  String irrigationPlanted(String year, String years) {
    return 'Planted in $year: about $years years old';
  }

  @override
  String get irrigationNoPlantingYear =>
      'Planting year not entered for this block. Choose the tree age.';

  @override
  String get irrigationNoRows =>
      'No figure in the sources for this tree age yet.';

  @override
  String get irrigationStagesTitle => 'Flowering, fruit and bahar rest';

  @override
  String get irrigationGapsTitle => 'Not found in the sources yet';

  @override
  String get irrigationSourcesLine =>
      'Sources: NHB, Dr. PDKV Akola and published citrus research. Details under each point.';
}
