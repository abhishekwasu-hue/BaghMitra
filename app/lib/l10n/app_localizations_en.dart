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
  String get loginOr => 'or';

  @override
  String get loginGoogle => 'Sign in with Google';

  @override
  String get loginGoogleFailed =>
      'Could not open Google sign-in. Check the internet and try again.';

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
  String get adminFeed => 'Govt feed';

  @override
  String get adminFeedQueue => 'Review queue';

  @override
  String get adminFeedUpload => 'Upload';

  @override
  String get adminFeedSources => 'Feed sources';

  @override
  String get adminFeedStatusInReview => 'In review';

  @override
  String get adminFeedStatusDraft => 'Draft';

  @override
  String get adminFeedStatusPublished => 'Published';

  @override
  String get adminFeedStatusWithdrawn => 'Withdrawn';

  @override
  String get adminFeedNoItems => 'Nothing in this list';

  @override
  String get adminFeedApproved => 'Approved';

  @override
  String adminFeedIssueCount(int count) {
    return '$count check issues';
  }

  @override
  String get adminFeedAiOff => 'AI not configured';

  @override
  String get adminFeedSourceLink => 'Source document';

  @override
  String adminFeedReplacedByValue(String id) {
    return 'Replaced by $id';
  }

  @override
  String get adminFeedWithdraw => 'Withdraw';

  @override
  String get adminFeedAiDraft => 'AI draft';

  @override
  String get adminFeedCheckIssues => 'Output-check issues';

  @override
  String get adminFeedNoIssues => 'No check issues';

  @override
  String get adminFeedTextPreview => 'Extracted text';

  @override
  String get adminFeedTexts => 'Title and summary';

  @override
  String get adminFeedDates => 'Dates';

  @override
  String get adminFeedDeadline => 'Last date';

  @override
  String get adminFeedPayment => 'Payment date';

  @override
  String get adminFeedValidFrom => 'Valid from';

  @override
  String get adminFeedValidTo => 'Valid to';

  @override
  String get adminFeedDatesNote =>
      'Dates are output-checked against the source text. Saving a change to a published item sends it back to review.';

  @override
  String get adminFeedPickDate => 'Pick date';

  @override
  String get adminFeedClearDate => 'Clear';

  @override
  String get adminFeedSaveDates => 'Save dates';

  @override
  String get adminFeedCardNew => 'Scheme card';

  @override
  String get adminFeedCardNote =>
      'Each field: the value as written in the document with its page, or \"Not stated\".';

  @override
  String get adminFeedNotStated => 'Not stated';

  @override
  String get adminFeedCardValue => 'Value';

  @override
  String get adminFeedCardPage => 'Page (e.g. p. 2)';

  @override
  String get adminFeedSaveCard => 'Save card';

  @override
  String get adminFeedCardEmpty =>
      'Fill at least one field or mark it Not stated.';

  @override
  String get adminFeedFullText => 'Stored text (what the output check reads):';

  @override
  String get adminFeedTextTruncated =>
      'Only the first 200 KB are shown; the stored text is longer.';

  @override
  String adminFeedCard(int version) {
    return 'Scheme card v$version';
  }

  @override
  String get adminFeedTargets => 'Targets';

  @override
  String get adminFeedHistory => 'History';

  @override
  String get adminFeedHasText =>
      'Text is stored (used by the output check and the AI draft).';

  @override
  String get adminFeedNoText =>
      'No usable text stored: upload again with the text pasted, or accept the issues with a comment.';

  @override
  String get adminFeedUnusedText => 'Text not used (broken text layer or OCR):';

  @override
  String get adminFeedTitle => 'Title';

  @override
  String get adminFeedSummary => 'Summary (2 lines)';

  @override
  String get adminFeedSave => 'Save';

  @override
  String get adminFeedBadNumber => 'Hectares must be numbers.';

  @override
  String get adminFeedTargetsNote =>
      'Empty fields mean any. Matching says \"may be eligible\", never \"will receive\".';

  @override
  String get adminFeedDistrict => 'District';

  @override
  String get adminFeedCrop => 'Crop';

  @override
  String get adminFeedMinHa => 'Min ha';

  @override
  String get adminFeedMaxHa => 'Max ha';

  @override
  String get adminFeedRemove => 'Remove';

  @override
  String get adminFeedAddTarget => 'Add target';

  @override
  String get adminFeedSaveTargets => 'Save targets';

  @override
  String get adminFeedAcceptTitle => 'Accept open check issues?';

  @override
  String adminFeedAcceptBody(int count) {
    return 'This item has $count open check issues. Approve it anyway only with a comment saying why.';
  }

  @override
  String get adminFeedComment => 'Comment (why)';

  @override
  String get adminFeedCancel => 'Cancel';

  @override
  String get adminFeedAcceptApprove => 'Accept and approve';

  @override
  String get adminFeedWithdrawTitle => 'Withdraw item';

  @override
  String get adminFeedReason => 'Reason';

  @override
  String get adminFeedReplacedBy => 'Replaced by';

  @override
  String get adminFeedNoReplacement => 'No replacement';

  @override
  String get adminFeedRequiredMissing =>
      'Source key, document URL and published date are required.';

  @override
  String get adminFeedBadDate => 'Write dates as YYYY-MM-DD.';

  @override
  String adminFeedCreated(String status, int count) {
    return 'Created: $status, $count check issues';
  }

  @override
  String get adminFeedDateHint => 'YYYY-MM-DD';

  @override
  String get adminFeedUploadNote =>
      'Choose the GR document (the server keeps its hash and reads its text) and / or paste the text copied from it (pasted text wins). The official URL is always needed.';

  @override
  String get adminFeedPickDocument => 'Choose document (PDF or HTML)';

  @override
  String get adminFeedNoDocument => 'No document chosen';

  @override
  String adminFeedDocument(String name, int kb) {
    return '$name · $kb KB';
  }

  @override
  String adminFeedTooLarge(int mb) {
    return 'The document is larger than $mb MB.';
  }

  @override
  String get adminFeedBadType => 'Only .pdf, .html or .htm files.';

  @override
  String get adminFeedExtraction => 'Extraction result';

  @override
  String get adminFeedSourceKey => 'Source key';

  @override
  String get adminFeedPublishedAt => 'Published on';

  @override
  String get adminFeedUrl => 'Document URL';

  @override
  String get adminFeedExternalId => 'External ID (GR code)';

  @override
  String get adminFeedGrNumber => 'GR number';

  @override
  String get adminFeedDepartment => 'Department';

  @override
  String get adminFeedPastedText => 'Text from the document (pasted)';

  @override
  String get adminFeedSubmit => 'Send to review';

  @override
  String get adminFeedOpen => 'Open item';

  @override
  String get adminFeedTerms => 'Terms';

  @override
  String get adminFeedTermsUnknown => 'Unknown';

  @override
  String get adminFeedTermsAllowed => 'Allowed';

  @override
  String get adminFeedTermsDisallowed => 'Disallowed';

  @override
  String get adminFeedTermsNote => 'Note (what you read)';

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
  String get profileTitle => 'My profile';

  @override
  String get profileConsentDataNote =>
      'This is needed so the app can save and back up your records. It cannot be turned off here.';

  @override
  String get profilePhoneSignedIn => 'You sign in with this number.';

  @override
  String get profileAddPhone => 'Add mobile number (optional)';

  @override
  String get profilePhoneContactOnly =>
      'Only so we can contact you. It is not for signing in; you still sign in with Google.';

  @override
  String get profileSaved => 'Saved.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutBody =>
      'Your records stay on this phone. Sign in again to see them.';

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
  String get settingsPhotoMobileData => 'Back up photos on mobile data';

  @override
  String get settingsPhotoMobileDataHint =>
      'Scouting photos are backed up on Wi-Fi. Turn this on to use mobile data too.';

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
  String get scoutingTitle => 'Scouting log';

  @override
  String get scoutingAdd => 'Add scouting';

  @override
  String get scoutingEmpty =>
      'No scouting recorded yet. Note what you saw on this plot.';

  @override
  String get scoutingDate => 'Date';

  @override
  String get scoutingWhat => 'What did you look at?';

  @override
  String get scoutingSeverity => 'How much?';

  @override
  String get scoutingNote => 'Note (optional)';

  @override
  String get scoutingPhoto => 'Photo (optional)';

  @override
  String get scoutingPhotoBackedUp => 'Photo backed up';

  @override
  String get scoutingCamera => 'Camera';

  @override
  String get scoutingGallery => 'Gallery';

  @override
  String get scoutingRemovePhoto => 'Remove photo';

  @override
  String get scoutingPhotoFailed => 'Could not get the photo. Try again.';

  @override
  String get scoutingPickOne => 'Choose one';

  @override
  String get scoutingItemPsylla => 'Psylla';

  @override
  String get scoutingItemLeafMiner => 'Leaf miner';

  @override
  String get scoutingItemMitesThrips => 'Mites / thrips';

  @override
  String get scoutingItemFruitDrop => 'Fruit drop';

  @override
  String get scoutingItemGummosis => 'Gummosis / bark';

  @override
  String get scoutingItemDieBack => 'Die-back';

  @override
  String get scoutingItemOther => 'Other';

  @override
  String get scoutingSeverityNone => 'Not seen';

  @override
  String get scoutingSeverityLow => 'Low';

  @override
  String get scoutingSeverityMedium => 'Medium';

  @override
  String get scoutingSeverityHigh => 'High';

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

  @override
  String get feedTitle => 'Sarkari Sandesh';

  @override
  String get feedOpenHint => 'Official GRs, schemes and last dates';

  @override
  String get feedFilterAll => 'All';

  @override
  String get feedFilterOfficial => 'Official';

  @override
  String get feedFilterSchemes => 'Schemes';

  @override
  String get feedFilterDeadlines => 'Deadlines';

  @override
  String get feedFilterNews => 'News';

  @override
  String get feedBadgeOfficial => 'Official';

  @override
  String feedGrNumber(String number) {
    return 'GR $number';
  }

  @override
  String get feedBadgeNews => 'News — not official';

  @override
  String feedReplacedBy(String replacement) {
    return 'Withdrawn. Replaced by $replacement';
  }

  @override
  String feedExpired(String date) {
    return 'No longer valid (ended $date)';
  }

  @override
  String feedMayBeEligible(String reason) {
    return 'You may be eligible because $reason';
  }

  @override
  String get feedFooter => 'Check the official GR/portal before acting.';

  @override
  String feedDeadline(String date) {
    return 'Last date: $date';
  }

  @override
  String feedUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get feedEmpty =>
      'No messages yet. They load when the phone is online.';

  @override
  String get feedRemindMe => 'Remind me';

  @override
  String feedReminderAdded(String date) {
    return 'Added to your tasks for $date';
  }

  @override
  String get feedReminderExists => 'Already in your tasks';

  @override
  String get feedShare => 'Share';

  @override
  String get feedCopyLink => 'Copy source link';

  @override
  String get feedLinkCopied => 'Link copied. Open it in your browser.';

  @override
  String feedSource(String url) {
    return 'Source: $url';
  }

  @override
  String get feedNotFound => 'This message is no longer in the saved list.';

  @override
  String get feedUnseen => 'New';

  @override
  String get feedDismiss => 'Hide from my list';

  @override
  String get feedDismissed => 'Hidden from your list.';

  @override
  String get feedPrefsTitle => 'Alert settings';

  @override
  String get feedPrefsQuietTitle => 'Quiet hours (no alerts)';

  @override
  String get feedPrefsQuietStart => 'From';

  @override
  String get feedPrefsQuietEnd => 'Until';

  @override
  String feedPrefsWeeklyCap(String count) {
    return 'At most $count alerts a week';
  }

  @override
  String get feedPrefsCapLess => 'Fewer';

  @override
  String get feedPrefsCapMore => 'More';

  @override
  String get feedPrefsCategoriesTitle => 'Send me alerts for';

  @override
  String get feedPrefsCatDeadline => 'Last dates coming up';

  @override
  String get feedPrefsCatPayment => 'Payment updates';

  @override
  String get feedPrefsCatWindowOpen => 'Applications open';

  @override
  String get feedPrefsDigest => 'Weekly summary';

  @override
  String get feedPrefsDigestHint => 'One message a week with what is new.';

  @override
  String get feedPrefsSave => 'Save';

  @override
  String get feedPrefsSaved => 'Settings saved.';

  @override
  String get feedPrefsSaveFailed => 'Could not save. Try again when online.';

  @override
  String get feedPrefsOffline =>
      'You are offline. These are your last saved settings. Saving needs internet.';

  @override
  String get feedCheckTitle => 'Check a message';

  @override
  String get feedCheckIntro =>
      'Got a message about a GR or scheme on WhatsApp? Paste it here to look for the official GR.';

  @override
  String get feedCheckHint => 'Paste the message here';

  @override
  String get feedCheckPaste => 'Paste';

  @override
  String get feedCheckButton => 'Check';

  @override
  String get feedCheckPrivacy => 'The text is not saved on your phone.';

  @override
  String get feedCheckFailed => 'Could not check. This needs internet.';

  @override
  String get feedCheckOfficial => 'Official GR found';

  @override
  String get feedCheckPossible => 'Possibly related official items';

  @override
  String get feedCheckNoMatch => 'No matching official item was found.';

  @override
  String get feedCheckPortal => 'Check the official portal before acting.';

  @override
  String get shareAction => 'Share';

  @override
  String get speakAction => 'Read aloud';

  @override
  String get speakUnavailable =>
      'This phone has no voice for this language yet.';

  @override
  String shareSentFrom(String app) {
    return 'Shared from the $app app';
  }

  @override
  String shareSource(String source) {
    return 'Source: $source';
  }

  @override
  String marketShareLine(String market, String price) {
    return '$market: $price per quintal';
  }

  @override
  String taskDueOn(String date) {
    return 'Due: $date';
  }

  @override
  String get taskDetails => 'Task details';

  @override
  String tasksTodayShare(String date) {
    return 'Today\'s tasks ($date)';
  }

  @override
  String get loadingLabel => 'Loading';

  @override
  String get accountSwitchTitle => 'Another account\'s records';

  @override
  String get accountSwitchBody =>
      'This phone holds the records of another account. If you continue, they are removed from this phone (they stay safe on the server) and your own records are downloaded.';

  @override
  String get accountSwitchContinue => 'Continue';

  @override
  String get accountBlockedTitle => 'Unsent records on this phone';

  @override
  String accountBlockedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records of the previous account are not sent yet.',
      one: '1 record of the previous account is not sent yet.',
    );
    return '$_temp0 Sign in again with that account and open the app with internet on so they are sent. Then sign in with this account.';
  }

  @override
  String accountPreviousPhone(String phone) {
    return 'Previous account: $phone';
  }

  @override
  String get insuranceTitle => 'Crop insurance';

  @override
  String get insuranceEmpty =>
      'No policy recorded for this plot yet. Add the crop insurance you took, or open the claim kit after a loss.';

  @override
  String get insurancePoliciesNone => 'No policy recorded yet.';

  @override
  String get insuranceAdd => 'Add policy';

  @override
  String get insuranceEdit => 'Edit policy';

  @override
  String get insuranceScheme => 'Scheme';

  @override
  String get insuranceSchemePmfby => 'PM crop insurance (PMFBY)';

  @override
  String get insuranceSchemeRwbcis => 'Weather-based fruit crop (RWBCIS)';

  @override
  String get insuranceSchemeOther => 'Other';

  @override
  String get insuranceSchemeUnknown => 'Don\'t know';

  @override
  String get insuranceSeason => 'Bahar';

  @override
  String get insuranceSeasonAmbia => 'Ambia bahar';

  @override
  String get insuranceSeasonMrig => 'Mrig bahar';

  @override
  String get insuranceSeasonYear => 'Year (optional)';

  @override
  String get insuranceInsurer => 'Insurance company (optional)';

  @override
  String get insurancePolicyNumber => 'Policy or application number (optional)';

  @override
  String get insuranceSumInsured => 'Sum insured ₹ (optional)';

  @override
  String get insurancePremium => 'Premium paid ₹ (optional)';

  @override
  String get insuranceAmountsHint =>
      'Enter amounts only as printed on your receipt.';

  @override
  String get insuranceEnrolledOn => 'Enrolment date';

  @override
  String get insuranceNotSet => 'Not set';

  @override
  String get insuranceNote => 'Note (optional)';

  @override
  String insurancePolicyNo(String number) {
    return 'No. $number';
  }

  @override
  String insuranceEnrolled(String date) {
    return 'Enrolled $date';
  }

  @override
  String insurancePremiumLine(String amount) {
    return 'Premium paid $amount';
  }

  @override
  String insuranceSumLine(String amount) {
    return 'Sum insured $amount';
  }

  @override
  String insuranceDeadline(String date) {
    return 'Enrolment deadline: $date';
  }

  @override
  String get insuranceDeadlineNote =>
      'From a published official notice. Check the notice before acting.';

  @override
  String get insuranceDeletePolicy => 'Delete policy';

  @override
  String get insuranceDeleteConfirm => 'Delete this policy record?';

  @override
  String get insuranceClaims => 'Loss records';

  @override
  String insuranceClaimLine(String date, String count) {
    return 'Loss on $date · photos: $count';
  }

  @override
  String get claimKitTitle => 'Claim kit';

  @override
  String get claimKitFromAlert => 'Take loss photos · claim kit';

  @override
  String get claimKitPlot => 'Plot';

  @override
  String get claimKitPickPlot => 'Pick a plot';

  @override
  String get claimKitDate => 'Date of loss';

  @override
  String get claimKitPhotos => 'Loss photos (date and GPS are added)';

  @override
  String get claimKitNoPhotos => 'No photos yet.';

  @override
  String get claimKitNoGps => 'GPS not available';

  @override
  String get claimKitRemovePhoto => 'Remove photo';

  @override
  String get claimKitNote => 'What happened? (optional)';

  @override
  String get claimKitChecklist => 'Checklist';

  @override
  String get claimKitCheckPolicy =>
      'General guidance only. Rules and time limits differ by policy: check your policy, bank or CSC.';

  @override
  String get claimCheckInform72h =>
      'Inform the insurer, your bank or the CSC about the loss soon. Many policies ask for this within 72 hours.';

  @override
  String get claimCheckPhotos =>
      'Take dated photos of the damage from several sides of the plot.';

  @override
  String get claimCheckPanchnama =>
      'Ask for the panchnama (loss survey) and keep a copy.';

  @override
  String get claimCheckPolicyCopy =>
      'Keep your policy or application receipt and a bank passbook copy ready.';

  @override
  String get claimCheckAcknowledgement =>
      'Write down the complaint or docket number you get when you inform.';

  @override
  String get claimCheckKeepFruit =>
      'Do not clear the damaged fruit or trees before the survey, unless you are told otherwise.';

  @override
  String get claimKitShare => 'Share PDF';

  @override
  String get claimKitShareFailed => 'Could not make the PDF. Try again.';

  @override
  String get claimKitDelete => 'Delete loss record';

  @override
  String get claimKitDeleteConfirm =>
      'Delete this loss record and its photos from this phone?';

  @override
  String get claimKitLocalOnly =>
      'Photos and notes stay on this phone. Share the PDF when you need it.';

  @override
  String get claimPdfTitle => 'Crop loss record';

  @override
  String get claimPdfPlotGps => 'Plot location (GPS)';

  @override
  String get claimPdfNoGps => 'Not marked';

  @override
  String get claimPdfPolicy => 'Insurance';

  @override
  String get claimPdfPhotos => 'Photos';

  @override
  String get claimPdfNote => 'Note';

  @override
  String get claimPdfDone => 'Done';

  @override
  String get claimPdfNotDone => 'Not yet';

  @override
  String claimPdfMade(String date) {
    return 'Made on $date. A record kept by the grower, not an insurer\'s document.';
  }

  @override
  String get insurancePolicies => 'Policies';

  @override
  String get labTestsTitle => 'Soil, water and leaf tests';

  @override
  String get labTestsEmpty =>
      'No test recorded for this plot yet. Add one from your lab report or Soil Health Card.';

  @override
  String get labTestAdd => 'Add test';

  @override
  String get labTestEdit => 'Edit test';

  @override
  String get labTestType => 'Test of';

  @override
  String get labTestTypeSoil => 'Soil';

  @override
  String get labTestTypeWater => 'Water';

  @override
  String get labTestTypeLeaf => 'Leaf';

  @override
  String get labTestTitleSoil => 'Soil test';

  @override
  String get labTestTitleWater => 'Water test';

  @override
  String get labTestTitleLeaf => 'Leaf test';

  @override
  String get labTestSampledOn => 'Sample taken on';

  @override
  String get labTestReportedOn => 'Report date';

  @override
  String get labTestLab => 'Lab name';

  @override
  String get labTestReadings => 'Values from the report';

  @override
  String get labTestReadingsHint =>
      'Type each value as it is written on the report.';

  @override
  String get labTestParameter => 'Name (pH, EC …)';

  @override
  String get labTestValue => 'Value';

  @override
  String get labTestUnit => 'Unit';

  @override
  String get labTestAddReading => 'Add a value';

  @override
  String get labTestRemoveReading => 'Remove this value';

  @override
  String get labTestSuggestions => 'Names on most reports (tap to add)';

  @override
  String get labTestReadingIncomplete => 'Type the name and the value';

  @override
  String get labTestNote => 'Note';

  @override
  String get labTestReport => 'Report photo or file';

  @override
  String get labTestReportFile => 'File (PDF)';

  @override
  String get labTestReportRemove => 'Remove';

  @override
  String get labTestReportFailed => 'Could not add the report. Try again.';

  @override
  String get labTestReportLocal => 'The report stays on this phone.';

  @override
  String get labTestReportMissing => 'The report file is not on this phone.';

  @override
  String get labTestShareReport => 'Share the report';

  @override
  String get labTestAskExpert =>
      'Ask an expert to read this report. BagMitra does not judge these values.';

  @override
  String get labTestNextDue => 'Next test due (reminder)';

  @override
  String get labTestNextDueHint =>
      'Pick a date only if you want a reminder task.';

  @override
  String get labTestNextDueClear => 'Clear the reminder date';

  @override
  String get labTestReminderSoil => 'Next soil test due';

  @override
  String get labTestReminderWater => 'Next water test due';

  @override
  String get labTestReminderLeaf => 'Next leaf test due';

  @override
  String get labTestDelete => 'Delete test';

  @override
  String get labTestDeleteConfirm =>
      'Delete this test record and its report from this phone?';

  @override
  String labTestSampledLine(String date) {
    return 'Sample $date';
  }

  @override
  String labTestReportedLine(String date) {
    return 'Report $date';
  }

  @override
  String labTestLabLine(String name) {
    return 'Lab: $name';
  }

  @override
  String labTestValuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count values',
      one: '1 value',
      zero: 'No values typed',
    );
    return '$_temp0';
  }

  @override
  String get labTestNoValues => 'No values typed yet.';

  @override
  String get labTestEditAction => 'Edit';

  @override
  String get schemesTitle => 'Schemes and documents';

  @override
  String get schemesHomeHint => 'Who can apply, documents to keep ready';

  @override
  String get schemesIntro =>
      'General information to help you get ready. No amounts are shown. Always check the official page before you apply.';

  @override
  String get schemeVisitSetu =>
      'Visit your nearest Setu Kendra (Aaple Sarkar Seva Kendra / CSC) to apply, get documents and ask questions.';

  @override
  String get schemeWho => 'Who can apply';

  @override
  String get schemeWhoCheck => 'In general terms. Check the official page.';

  @override
  String get schemeDocuments => 'Documents usually needed';

  @override
  String get schemeDocumentsHint =>
      'Tick what you already have. Kept on this phone only.';

  @override
  String schemeDocsReady(int have, int total) {
    return '$have of $total ready';
  }

  @override
  String get schemeNotConfirmed => 'Not yet confirmed on an official page';

  @override
  String get schemeWhereToApply => 'Where to apply';

  @override
  String schemeSources(String date) {
    return 'Sources (checked on $date)';
  }

  @override
  String get schemeFeedItems => 'Related govt notices';

  @override
  String schemeShareDocs(String scheme) {
    return 'Documents for $scheme:';
  }

  @override
  String get schemeShareHave => 'have';

  @override
  String get schemeShareMissing => 'to get';
}
