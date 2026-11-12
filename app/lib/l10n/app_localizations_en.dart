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
  String get homeWeatherNeedsLocation =>
      'Add the block\'s location to see its weather here.';

  @override
  String minTemperature(int degrees) {
    final intl.NumberFormat degreesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String degreesString = degreesNumberFormat.format(degrees);

    return 'Min $degreesString°';
  }

  @override
  String homeNextStage(String stage, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Next: $stage in $daysString days';
  }

  @override
  String homeHarvestMonth(String month) {
    return 'Harvest $month';
  }

  @override
  String get homeStageAddDates => 'Write the stage dates to see the days here.';

  @override
  String get homeOpenMarket => 'See market prices';

  @override
  String get choosePlot => 'Choose a block';

  @override
  String get onboardingSaveFailed => 'Please tap Continue again.';

  @override
  String get perQuintal => 'per quintal';

  @override
  String get vsLastWeek => 'vs last week';

  @override
  String get takePhoto => 'Pest/disease photo';

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
      'Your entries are saved on this phone; they will sync when the network is back.';

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
  String get syncFailed =>
      'Your records are safe on this phone. The app will try sending again on its own.';

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
      'Please try Google sign-in again; check the internet.';

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
  String get loginInvalidOtp => 'Enter the latest 6-digit OTP from the SMS';

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
  String get plotsEmptyTitle => 'Add your first orchard block';

  @override
  String get plotsEmptyBody =>
      'Each block gets a bahar calendar and daily tasks.';

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
  String get plotSaved => 'Saved.';

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
  String get baharEmptyTitle => 'Plan your first bahar';

  @override
  String get baharEmptyBody =>
      'Choose a bahar. Each stage shows a suggested window from public sources; every date stays yours to change.';

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
  String get adminNoAlerts => 'Open alerts appear here';

  @override
  String get adminNoCards => 'Cards appear here once added';

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
  String get adminFeedNoItems => 'This list is empty';

  @override
  String get adminFeedApproved => 'Approved';

  @override
  String adminFeedIssueCount(int count) {
    return '$count check issues';
  }

  @override
  String get adminFeedAiOff => 'AI is still to be set up';

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
  String get adminFeedNoIssues => 'All checks passed';

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
      'Each field: the value as written in the document with its page, or \"Blank in document\".';

  @override
  String get adminFeedNotStated => 'Blank in document';

  @override
  String get adminFeedCardValue => 'Value';

  @override
  String get adminFeedCardPage => 'Page (e.g. p. 2)';

  @override
  String get adminFeedSaveCard => 'Save card';

  @override
  String get adminFeedCardEmpty =>
      'Fill at least one field or mark it \"Blank in document\".';

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
      'This needs usable text: upload again with the text pasted, or accept the issues with a comment.';

  @override
  String get adminFeedUnusedText =>
      'Text set aside (broken text layer or OCR):';

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
      'Empty fields mean any. Matching only ever says \"may be eligible\".';

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
  String get adminFeedNoReplacement => 'Withdraw only';

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
  String get adminFeedNoDocument => 'Choose a document';

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
  String get accountsEmpty => 'Add your first expense or sale.';

  @override
  String saleBy(String buyer, String kg) {
    return '$buyer · $kg kg';
  }

  @override
  String get sprayLogTitle => 'Spray log';

  @override
  String get addSpray => 'Add spray';

  @override
  String get spraysEmpty => 'Record your first spray here.';

  @override
  String get sprayProduct => 'Product name';

  @override
  String get sprayProductOptional => 'Product name (optional)';

  @override
  String get sprayActive => 'Active ingredient (on the label)';

  @override
  String get sprayActiveType => 'Type (fungicide, insecticide ...)';

  @override
  String get sprayActivePick => 'Choose from the list';

  @override
  String get sprayActiveOther => 'Other';

  @override
  String get sprayActiveOtherHelp => 'Write the name as printed on the label.';

  @override
  String get sprayActiveSearch => 'Search';

  @override
  String get sprayActiveNoMatch => 'To write another name, choose Other.';

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
  String get sprayWarnBannedTitle => 'Outside the approved list';

  @override
  String sprayWarnBannedBody(String notification) {
    return 'This ingredient is outside the government\'s approved list ($notification). See the label information for registered options.';
  }

  @override
  String get sprayWarnRestrictedTitle =>
      'Outside the approved list for this crop';

  @override
  String sprayWarnRestrictedBody(String notification) {
    return 'For this crop, this ingredient is outside the approved list ($notification). See the label information.';
  }

  @override
  String get sprayWarnPhiTitle => 'Waiting period';

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
  String get fieldLogEmpty => 'Add your first fertiliser or irrigation entry.';

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
  String get labourEmpty => 'Add your first worker day.';

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
  String get harvestEmpty => 'Record your first harvest lot.';

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
  String get compareSame => 'same';

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
      'Only so we can contact you. You sign in with Google, as before.';

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
  String get profilePrivacy => 'Privacy policy';

  @override
  String get profilePrivacyHint =>
      'Tap to copy the link, then open it in your browser';

  @override
  String get profileDeleteAccount => 'Delete my account and data';

  @override
  String get profileDeleteTitle => 'Delete your account?';

  @override
  String profileDeleteBody(String word) {
    return 'All your records, photos and history are erased from the server and from this phone, and you are signed out. This is permanent. To confirm, type $word.';
  }

  @override
  String get profileDeleteWord => 'DELETE';

  @override
  String get profileDeleteConfirm => 'Delete for ever';

  @override
  String get profileDeleteFailed =>
      'Please try again in a while: deleting needs the internet and the server. All your data is still kept.';

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
      'Please try again in an open place to get your location.';

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
  String get loginTryWithout => 'Try the app first';

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
  String get updateAvailable => 'New version available — download';

  @override
  String get updateDismiss => 'Close';

  @override
  String get updateDownload => 'Download';

  @override
  String get updateRequiredTitle => 'Please update the app';

  @override
  String get updateRequiredBody =>
      'Download and install the new version to keep using BagMitra.';

  @override
  String updateLinkCopied(String url) {
    return 'Link copied. Paste it in the browser to download: $url';
  }

  @override
  String settingsVersion(String name, String code) {
    return 'Version $name ($code)';
  }

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
      'See the weather at your plot and get an alert when rain or heat may need your attention.';

  @override
  String get walkthroughMarketTitle => 'Mandi prices across India';

  @override
  String get walkthroughMarketBody =>
      'Check recent mandi prices for your crop in markets across India.';

  @override
  String get walkthroughRecordsTitle => 'Your records and accounts';

  @override
  String get walkthroughRecordsBody =>
      'Note sprays, expenses, labour and sales, and see your accounts. Works offline too; records are sent when the network is back.';

  @override
  String get settingsShowWalkthrough => 'See the app introduction again';

  @override
  String get settingsPhotoMobileData => 'Back up photos on mobile data';

  @override
  String get settingsPhotoMobileDataHint =>
      'Scouting and bill photos are backed up on Wi-Fi. Turn this on to use mobile data too.';

  @override
  String get settingsModelSources => 'Photo model data sources';

  @override
  String get settingsModelSourcesIntro =>
      'The phone\'s photo check model is trained on these public photo sets (photos resized for training). Licence: CC BY 4.0 (creativecommons.org/licenses/by/4.0).';

  @override
  String buildLabel(String sha) {
    return 'Test build $sha';
  }

  @override
  String get seedOrchard => 'Add sample orchard';

  @override
  String get seedOrchardDone => 'Sample orchard added';

  @override
  String get voiceUnavailable =>
      'Please type here; voice typing works on phones that support it';

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
  String get tasksEmpty => 'Add your first task with the + button.';

  @override
  String get tasksOverdue => 'Overdue';

  @override
  String get tasksToday => 'Today';

  @override
  String get tasksUpcoming => 'Coming up';

  @override
  String get tasksDone => 'Done';

  @override
  String get noTasksToday => 'Today is clear';

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
  String get plotBoundaryNone => 'Mark the boundary';

  @override
  String get plotCentre => 'Centre point';

  @override
  String get plotLocation => 'Location';

  @override
  String get plotPointCapture => 'I am in the orchard — take location';

  @override
  String get plotPointWhy =>
      'For this block\'s weather and alerts. Read once, only now.';

  @override
  String get plotPointReading => 'Taking location…';

  @override
  String get plotPointTake => 'Take location';

  @override
  String get plotPointRetake => 'Take location again';

  @override
  String get plotPointDenied => 'Allow location to save where this block is.';

  @override
  String get plotPointOpenSettings => 'Open settings';

  @override
  String get plotPointTryAgain => 'Try again';

  @override
  String get plotPointLater =>
      'Save the block now; take the location any time later.';

  @override
  String get boundaryWalkOptional => 'Walk the boundary (optional)';

  @override
  String get calendarTitle => 'Season calendar';

  @override
  String get calendarIntro =>
      'Your bahar dates and tasks for the next twelve months, from what you entered.';

  @override
  String get calendarMonthEmpty => 'This month is clear.';

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
  String get baharCompareNoLast =>
      'Record this block\'s first bahar to see it here.';

  @override
  String baharCompareSource(String source) {
    return 'Source: $source';
  }

  @override
  String get baharCompareNoPoints =>
      'Checked information for this bahar appears here once it is ready.';

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
      'Showing the last saved days; the weather updates on the next successful load.';

  @override
  String get weatherNone => 'Weather loads when the phone is online.';

  @override
  String weatherRain(String mm) {
    return '$mm mm rain';
  }

  @override
  String weatherSource(String source) {
    return 'Source: $source';
  }

  @override
  String get alertSwitchOff => 'Turn this alert off';

  @override
  String get alertSwitchOn => 'Turn this alert on';

  @override
  String alertTypeOff(String name) {
    return '$name alert off';
  }

  @override
  String get alertThisOff => 'This alert is off';

  @override
  String get alertNameHeat => 'Heat';

  @override
  String get alertNamePsylla => 'Psylla';

  @override
  String get alertNameHail => 'Hail and storm';

  @override
  String get alertNameWind => 'Strong wind';

  @override
  String get alertNameHeavyRain => 'Heavy rain';

  @override
  String get alertNameUnseasonalRain => 'Unseasonal rain';

  @override
  String get alertNameColdWave => 'Cold wave';

  @override
  String get alertNameHumidity => 'Humid weather';

  @override
  String get weatherForecastTitle => 'Weather forecast';

  @override
  String weatherForecastNext(String days) {
    return 'Next $days days';
  }

  @override
  String get weatherColDay => 'Day';

  @override
  String get weatherColTemp => 'Temp.';

  @override
  String get weatherColRain => 'Rain';

  @override
  String get weatherColWind => 'Wind';

  @override
  String get weatherColHumidity => 'Humidity';

  @override
  String get weatherUnitTemp => 'max/min';

  @override
  String get weatherUnitRain => 'mm/%';

  @override
  String get weatherUnitWind => 'km/h';

  @override
  String get weatherLegendRain => 'Rain likely';

  @override
  String weatherLegendHeat(String deg) {
    return '$deg° and above';
  }

  @override
  String get weatherSkyClear => 'Clear sky';

  @override
  String get weatherSkyCloudy => 'Cloudy';

  @override
  String get weatherSkyRain => 'Rain';

  @override
  String get weatherSkyStorm => 'Thunderstorm';

  @override
  String get weatherNowLabel => 'Now';

  @override
  String weatherReadingAt(String time) {
    return 'at $time';
  }

  @override
  String weatherTodayMax(int degrees) {
    final intl.NumberFormat degreesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String degreesString = degreesNumberFormat.format(degrees);

    return 'Today\'s max $degreesString°';
  }

  @override
  String get weatherTodayMaxLabel => 'Today\'s max';

  @override
  String get weatherSkyClearNight => 'Clear night';

  @override
  String get labelInfoTitle => 'Label information';

  @override
  String get labelInfoBanner =>
      'This is information printed on registered labels (CIB&RC). It is not a recommendation. Read the product label and confirm with your KVK or agriculture officer before any use.';

  @override
  String get labelInfoEmpty =>
      'Registered label information appears here once it is available.';

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
  String get marketTrendOpen => 'Price trend';

  @override
  String marketTrendTitle(String market) {
    return 'Price trend: $market';
  }

  @override
  String get marketTrendRange15 => '15 days';

  @override
  String get marketTrendRange30 => '1 month';

  @override
  String get marketTrendRange90 => '3 months';

  @override
  String get marketTrendHigh => 'Highest';

  @override
  String get marketTrendLow => 'Lowest';

  @override
  String get marketTrendChange15 => 'Since 15 days';

  @override
  String get marketTrendChange30 => 'Since 1 month';

  @override
  String get marketTrendHint =>
      'Slide a finger on the chart to see each day’s price.';

  @override
  String get marketTrendCollecting =>
      'Prices are saved every day; the chart fills in day by day.';

  @override
  String marketTrendSemantics(
    String range,
    String high,
    String low,
    String latest,
  ) {
    return 'Price trend, $range: highest $high, lowest $low, latest $latest per quintal';
  }

  @override
  String marketStale(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'source_not_configured': 'Mandi prices are coming soon.',
      'other': 'Showing the last saved prices; they update on the next successful load.',
    });
    return '$_temp0';
  }

  @override
  String get marketStaleNoReason =>
      'Showing the last saved list; prices update on the next successful load.';

  @override
  String get marketEmpty =>
      'Prices load when the phone is online and the price source is connected.';

  @override
  String get marketCrop => 'Crop';

  @override
  String marketCropSoon(String crop) {
    return '$crop prices will show here soon. Mandi prices update on their own every 6 hours.';
  }

  @override
  String get marketSearchOpen => 'Find a mandi';

  @override
  String get marketSearchClose => 'Close search';

  @override
  String get marketSearchHint => 'Mandi, district or state';

  @override
  String get marketSearchClear => 'Clear';

  @override
  String marketSearchEmpty(String query) {
    return 'Try another mandi, district or state name instead of “$query”.';
  }

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
  String get practicesGapsTitle =>
      'A non-chemical practice is still to be found for these';

  @override
  String get practicesSourcesLine =>
      'Sources: NHB and Dr. PDKV, Akola. Details under each practice.';

  @override
  String get scoutingTitle => 'Scouting log';

  @override
  String get scoutingAdd => 'Add scouting';

  @override
  String get scoutingEmpty =>
      'Record your first scouting: note what you saw on this plot.';

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
  String get scoutingPhotoFailed => 'Please take the photo again.';

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
  String get scoutingSeverityNone => 'Zero';

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
      'Amounts depend on your soil, the tree\'s canopy and the weather.';

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
      'Choose the tree age, or add the planting year to this block.';

  @override
  String get irrigationNoRows =>
      'A figure for this tree age is still to be found in the sources.';

  @override
  String get irrigationStagesTitle => 'Flowering, fruit and bahar rest';

  @override
  String get irrigationGapsTitle => 'Still to be found in the sources';

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
  String get feedFilterKnowledge => 'Knowledge';

  @override
  String get feedBadgeKnowledge => 'Knowledge article';

  @override
  String get feedKnowledgeByline =>
      'BagMitra · written by AI only from checked cards and their open sources; every number checked against the source';

  @override
  String get feedKnowledgeOpenCard => 'Open the card';

  @override
  String get feedKnowledgeNote =>
      'General information. Ask your KVK or agriculture officer before acting.';

  @override
  String get feedBadgeOfficial => 'Official';

  @override
  String get feedLevelCentral => 'Government of India';

  @override
  String get feedLevelState => 'Government of Maharashtra';

  @override
  String get feedArticleByline =>
      'BagMitra news desk · written by AI from official government sources';

  @override
  String get feedArticleKeyPoints => 'Key points';

  @override
  String get feedArticleFacts => 'At a glance';

  @override
  String get feedArticleKeyDates => 'Key dates';

  @override
  String get feedArticleSources => 'Sources';

  @override
  String feedGrNumber(String number) {
    return 'GR $number';
  }

  @override
  String get feedBadgeNews => 'News';

  @override
  String feedReplacedBy(String replacement) {
    return 'Withdrawn. Replaced by $replacement';
  }

  @override
  String feedExpired(String date) {
    return 'Ended on $date';
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
  String get feedEmpty => 'Messages load when the phone is online.';

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
  String get feedNotFound => 'This message was removed from the saved list.';

  @override
  String get feedUnseen => 'New';

  @override
  String feedThreadCount(String count) {
    return '$count reports';
  }

  @override
  String feedThreadLatest(String date) {
    return 'Latest: $date';
  }

  @override
  String get feedThreadTimeline => 'All reports, oldest first';

  @override
  String get feedThreadOpenItem => 'Read the full report';

  @override
  String get feedDismiss => 'Hide from my list';

  @override
  String get feedDismissed => 'Hidden from your list.';

  @override
  String get feedPrefsTitle => 'Alert settings';

  @override
  String get feedPrefsQuietTitle => 'Quiet hours (alerts stay silent)';

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
  String get feedPrefsSaveFailed => 'Please save again when online.';

  @override
  String get feedPrefsOffline =>
      'These are your last saved settings. Connect to the internet to save changes.';

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
  String get feedCheckFailed =>
      'Checking needs internet; please try again when online.';

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
      'Reading aloud needs a voice for this language on this phone.';

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
  String get accountBlockedTitle => 'Records waiting to send on this phone';

  @override
  String accountBlockedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count records of the previous account are still waiting to send.',
      one: '1 record of the previous account is still waiting to send.',
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
      'Add the crop insurance you took for this plot, or open the claim kit after a loss.';

  @override
  String get insurancePoliciesNone => 'Add your first policy.';

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
  String get insuranceSchemeUnknown => 'To check';

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
  String get insuranceNotSet => 'To add';

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
  String get claimKitNoPhotos => 'Take loss photos; they appear here.';

  @override
  String get claimKitNoGps => 'GPS unavailable';

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
      'Inform the insurer, your bank or the CSC about the loss as soon as possible; check your policy for the time limit.';

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
      'Keep the damaged fruit and trees as they are until the survey, unless you are told otherwise.';

  @override
  String get claimKitShare => 'Share PDF';

  @override
  String get claimKitShareFailed => 'Please try making the PDF again.';

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
  String get claimPdfNoGps => 'To be marked';

  @override
  String get claimPdfPolicy => 'Insurance';

  @override
  String get claimPdfPhotos => 'Photos';

  @override
  String get claimPdfNote => 'Note';

  @override
  String get claimPdfDone => 'Done';

  @override
  String get claimPdfNotDone => 'Pending';

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
      'Add this plot\'s first test from your lab report or Soil Health Card.';

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
  String get labTestReportFailed => 'Please try adding the report again.';

  @override
  String get labTestReportLocal => 'The report stays on this phone.';

  @override
  String get labTestReportMissing => 'Please attach the report file again.';

  @override
  String get labTestShareReport => 'Share the report';

  @override
  String get labTestAskExpert =>
      'Ask an expert to read this report; they can explain what the values mean.';

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
      zero: 'Add values',
    );
    return '$_temp0';
  }

  @override
  String get labTestNoValues => 'Type the values from the report here.';

  @override
  String get labTestEditAction => 'Edit';

  @override
  String get schemesTitle => 'Schemes and documents';

  @override
  String get schemesHomeHint => 'Who can apply, documents to keep ready';

  @override
  String get schemesIntro =>
      'General information to help you get ready. See the amount and rules on the official page, then apply.';

  @override
  String get schemeVisitSetu =>
      'Visit your nearest Setu Kendra (Aaple Sarkar Seva Kendra / CSC) to apply, get documents and ask questions.';

  @override
  String get schemeWho => 'Who can apply';

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
  String get schemeNotConfirmed => 'Please confirm on the official page';

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

  @override
  String get lookalikesTitle => 'Look-alike symptoms';

  @override
  String get lookalikesOpen => 'Look-alike symptoms';

  @override
  String get lookalikesIntro =>
      'Many orchard problems look alike; these cards help you describe exactly what you see.';

  @override
  String get lookalikesSee => 'What you may see';

  @override
  String get lookalikesConfusedWith => 'Can be confused with';

  @override
  String get lookalikesConfirm => 'Who can confirm it';

  @override
  String get lookalikesCheckLine =>
      'Want to be sure? Take a photo, log it in scouting and get it checked by a lab or an expert before you decide.';

  @override
  String get lookalikesLogThis => 'Log this in scouting';

  @override
  String get lookalikesFindLab => 'Find a lab or expert';

  @override
  String get lookalikesSources => 'Sources';

  @override
  String get lookalikesDraft => 'Draft: a source is still to be checked';

  @override
  String get lookalikesEmpty => 'Cards appear here.';

  @override
  String get labsTitle => 'Labs and experts';

  @override
  String get labsOpen => 'Labs and experts';

  @override
  String get marketDirectoryTitle => 'Markets and buyers';

  @override
  String get marketDirectoryOpen => 'Markets and buyers';

  @override
  String get directoryAll => 'All';

  @override
  String get directoryUnverified => 'Please confirm on the official page';

  @override
  String get directoryCopyNumber => 'Copy number';

  @override
  String get directoryNumberCopied => 'Number copied';

  @override
  String get directoryCopyLink => 'Copy link';

  @override
  String directoryWebPage(Object url) {
    return 'Web page: $url';
  }

  @override
  String directoryPhone(Object phone) {
    return 'Phone: $phone';
  }

  @override
  String directoryDetailsFrom(Object url) {
    return 'Details from: $url';
  }

  @override
  String directoryChecked(Object date) {
    return 'Checked $date';
  }

  @override
  String get directoryCheckLine =>
      'Details are copied from official pages on the date shown. Call or visit the page to confirm before you travel.';

  @override
  String get directoryEmpty => 'Entries appear here.';

  @override
  String get directoryKindResearch => 'Research institute';

  @override
  String get directoryKindUniversity => 'Agricultural university';

  @override
  String get directoryKindKvk => 'Krishi Vigyan Kendra';

  @override
  String get directoryKindSoilLab => 'Soil testing';

  @override
  String get directoryKindPortal => 'Prices and arrivals';

  @override
  String get directoryKindApmc => 'Market committee (APMC)';

  @override
  String get directoryKindExport => 'Export';

  @override
  String get directoryKindProcessor => 'Processing';

  @override
  String get exportInfoTitle => 'Export information';

  @override
  String get exportInfoNote =>
      'For information. The export deal is between you and the exporter.';

  @override
  String get exportSectionDestinations => 'Where it goes';

  @override
  String get exportSectionSeason => 'Season fit (exporter\'s view)';

  @override
  String get exportSectionSpecs => 'What buyers ask (as quoted)';

  @override
  String get exportSectionRules => 'Rules a grower meets';

  @override
  String get exportLinksTitle => 'Official pages';

  @override
  String get exportRecordTitle => 'Export record';

  @override
  String get exportRecordAction => 'Make export record (PDF)';

  @override
  String get exportRecordPlot => 'Plot';

  @override
  String get exportRecordBahar => 'Bahar';

  @override
  String get exportRecordAllBahars => 'All sprays';

  @override
  String exportRecordCount(String count) {
    return '$count sprays';
  }

  @override
  String exportRecordLastPhi(String date) {
    return 'Last PHI ends $date';
  }

  @override
  String get exportRecordShare => 'Share PDF';

  @override
  String get exportRecordNoPlot =>
      'Add a plot first; its spray record appears here.';

  @override
  String get exportRecordEmpty =>
      'Sprays of this bahar appear here once recorded.';

  @override
  String get exportRecordDate => 'Date';

  @override
  String get exportRecordProduct => 'Product · ingredient · dose';

  @override
  String get exportRecordLabel => 'Label check';

  @override
  String get exportRecordPhiEnd => 'PHI ends';

  @override
  String get exportLabelListed => 'On the label for this crop';

  @override
  String get exportLabelCheck => 'Check the label';

  @override
  String exportRecordMade(String date) {
    return 'Made on $date from the grower\'s own spray log.';
  }

  @override
  String get exportRecordFooter => 'Information record, not a certificate.';

  @override
  String fairPriceMandi(Object date, Object market, Object price) {
    return '$market mandi, $date: modal price $price per quintal';
  }

  @override
  String fairPriceAbove(Object percent) {
    return 'Your rate is $percent% above the mandi modal price.';
  }

  @override
  String fairPriceBelow(Object percent) {
    return 'Your rate is $percent% below the mandi modal price.';
  }

  @override
  String get fairPriceSame => 'Your rate is the same as the mandi modal price.';

  @override
  String get loginPhoneUnavailable => 'Please sign in with Google for now';

  @override
  String get loginResendOtp => 'Resend OTP';

  @override
  String loginResendIn(int seconds) {
    return 'Resend OTP in $seconds s';
  }

  @override
  String get loginOtpResent => 'A new OTP has been sent';

  @override
  String get loginChangeNumber => 'Change number';

  @override
  String get loginTitleGoogle => 'Start with your Google account';

  @override
  String get netOffline => 'Check the internet and try again';

  @override
  String get netServer => 'The server is busy; try again in a little while';

  @override
  String get netSignedOut => 'Sign in again for the latest information';

  @override
  String get netRetry => 'Try again';

  @override
  String get signInAgain => 'Sign in';

  @override
  String get syncServerBanner =>
      'Your entries are safe on this phone; they will be sent once the server is back.';

  @override
  String get syncSignedOutBanner => 'Sign in again to send your entries';

  @override
  String syncRejectedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries to check',
      one: '1 entry to check',
    );
    return '$_temp0';
  }

  @override
  String get syncReview => 'Review';

  @override
  String get syncRejectedTitle => 'Entries to check';

  @override
  String get syncRejectedHelp =>
      'Send each entry again, or remove it from this list; the record on the phone stays as it is.';

  @override
  String get syncRejectedDone => 'All entries are in order';

  @override
  String get syncResend => 'Send again';

  @override
  String get syncDelete => 'Delete';

  @override
  String syncEntryName(String entity) {
    String _temp0 = intl.Intl.selectLogic(entity, {
      'farmer_profile': 'Profile',
      'plot': 'Plot',
      'bahar_cycle': 'Bahar',
      'expense': 'Expense',
      'income': 'Sale',
      'spray_record': 'Spray',
      'input_record': 'Input',
      'irrigation_record': 'Irrigation',
      'harvest_record': 'Harvest',
      'labour_record': 'Labour',
      'farm_task': 'Task',
      'scouting_record': 'Scouting',
      'insurance_policy': 'Insurance',
      'lab_test': 'Lab test',
      'other': 'Entry',
    });
    return '$_temp0';
  }

  @override
  String get refreshOffline => 'Check the internet';

  @override
  String get refreshServer => 'The server is busy';

  @override
  String get homeQuickTitle => 'Quick actions';

  @override
  String get moreTitle => 'All features';

  @override
  String get moreSectionRecords => 'Orchard records';

  @override
  String get moreSectionWork => 'Work and season';

  @override
  String get moreSectionHelp => 'Guides and help';

  @override
  String get moreSectionMarket => 'Market';

  @override
  String get moreSectionGovt => 'Government help';

  @override
  String get moreSectionAccount => 'My account';

  @override
  String get plotTileBahar => 'Bahar';

  @override
  String get baharRecordsMenu => 'Records';

  @override
  String tasksDoneShow(String count) {
    return 'Show ($count)';
  }

  @override
  String get tasksDoneHide => 'Hide';

  @override
  String tasksDoneLatest(String count) {
    return 'Showing the latest $count';
  }

  @override
  String get requiredPlotName => 'Write the block name';

  @override
  String get requiredTaskTitle => 'Write what needs doing';

  @override
  String get requiredWorker => 'Write the worker\'s name';

  @override
  String get requiredSprayProduct =>
      'Write the product name or the active ingredient';

  @override
  String get requiredInputProduct => 'Write the product name';

  @override
  String get requiredBuyer => 'Write the buyer\'s name';

  @override
  String get claimKitGpsOk => 'Location added';

  @override
  String priceChangeUp(String pct) {
    return '$pct up from last week';
  }

  @override
  String priceChangeDown(String pct) {
    return '$pct down from last week';
  }

  @override
  String generalInfoSource(String source, String date) {
    return 'Source: $source · checked $date';
  }

  @override
  String get sourcesShow => 'See sources';

  @override
  String sourcesShowCount(String count) {
    return 'See sources ($count)';
  }

  @override
  String get sourcesHide => 'Hide sources';

  @override
  String sourcesChecked(String date) {
    return 'read $date';
  }

  @override
  String get labelReadNote => 'Read the label on the packet before spraying.';

  @override
  String baharSuggestedWindow(String from, String to) {
    return 'Suggested: $from – $to';
  }

  @override
  String get baharNoWindow =>
      'Enter your own date: the sources give windows for the other stages only';

  @override
  String get baharFillSuggested => 'Fill in the suggested dates';

  @override
  String get baharSuggestedHelp =>
      'Suggested windows are from public sources. Change any date to suit your orchard.';

  @override
  String get baharStressBySoil =>
      'How long the stress lasts depends on the soil: fewer days in light soil, more in heavy soil.';

  @override
  String get practicesSee => 'What you see';

  @override
  String get practicesWhen => 'When it comes';

  @override
  String get figureGum => 'Gum oozes';

  @override
  String get figureWetPatches => 'Water-soaked patches';

  @override
  String get figureBarkPeels => 'Bark peels in vertical strips';

  @override
  String get figureYellowLeaves => 'Yellow leaves';

  @override
  String figureWidthCm(String cm) {
    return '$cm cm';
  }

  @override
  String figureDepthCm(String cm) {
    return '$cm cm deep';
  }

  @override
  String get figureDrainsAway => 'Water drains away from the trees';

  @override
  String get figureDry => 'Dry';

  @override
  String get figureWaterHere => 'Water here';

  @override
  String get figureTopView => 'Seen from above';

  @override
  String get figureDeadPart => 'Dried part';

  @override
  String get figureCutHere => 'Cut here';

  @override
  String figureHealthyCm(String cm) {
    return 'with $cm cm of healthy wood';
  }

  @override
  String figureSunDays(String from, String to) {
    return '$from–$to days of sun';
  }

  @override
  String get figureCutRotten => 'Cut out rotten roots';

  @override
  String get figureWithBand => 'Remove with a healthy strip';

  @override
  String get figureDiseasedBark => 'Diseased bark';

  @override
  String get figureRains => 'Monsoon';

  @override
  String get figureBeforeRains => 'Before the monsoon';

  @override
  String get figureAfterRains => 'After the monsoon';

  @override
  String figureInnerRingCm(String cm) {
    return 'Inner ring $cm cm';
  }

  @override
  String get figureYellowTrap => 'Yellow sticky trap';

  @override
  String figureHeightM(String m) {
    return '$m m above ground';
  }

  @override
  String get figureBudUnion => 'Bud union';

  @override
  String figureHeightRangeCm(String from, String to) {
    return '$from–$to cm above ground';
  }

  @override
  String figureStickyBand(String cm) {
    return 'Sticky barrier $cm cm';
  }

  @override
  String get figureAnts => 'Ants';

  @override
  String get figureLureTrap => 'Lure trap';

  @override
  String figureRenewDays(String from, String to) {
    return 'Renew the lure every $from–$to days';
  }

  @override
  String get figureShadyFirst => 'Shady side: look here first';

  @override
  String get figureSunnySide => 'Sunny side';

  @override
  String get figureOpenCentre => 'Open centre: air flows';

  @override
  String get figureCutCrowded => 'Cut crowded shoots';

  @override
  String get figureRootZone => 'Active root zone';

  @override
  String get figureManureHere => 'Manure here, cover with soil';

  @override
  String get figCankerSpots => 'Raised, rough, brown corky spots';

  @override
  String get figCankerHalo => 'Yellow halo';

  @override
  String get figCankerFruit => 'On fruit: spots stay in the rind';

  @override
  String get figMildewPowder => 'White powder';

  @override
  String get figMildewCurl => 'Leaves twist and curl';

  @override
  String get figAnthPatch => 'Light-tan patch, purple edge';

  @override
  String get figAnthDots => 'Tiny black dots';

  @override
  String get figAnthTwig => 'Dead twig: silvery grey';

  @override
  String get figGreeningLeaf => 'Yellow leaf with green islands';

  @override
  String get figGreeningFruit => 'Fruit small, lopsided, green';

  @override
  String get figPsyllaNymphs => 'Yellow-orange nymphs on shoot tips';

  @override
  String get figPsyllaThreads => 'White waxy threads';

  @override
  String get figPsyllaCurl => 'New leaves curl';

  @override
  String get figAphidColony => 'Black or brown aphid colonies';

  @override
  String get figAphidCup => 'Cup-shaped, crinkled leaves';

  @override
  String get figMealyClusters => 'White cottony clusters';

  @override
  String get figSootyMould => 'Sooty mould';

  @override
  String get figMinerMines => 'Silvery zig-zag mines';

  @override
  String get figMinerDistort => 'Leaf distorts and crumples';

  @override
  String get figMitesVeins => 'Pale yellow along the veins';

  @override
  String get figMitesWeb => 'Fine webbing: dusty look';

  @override
  String get figMitesRind => 'Rough rind (russeting)';

  @override
  String get figThripsRing => 'Ring-like scar round the stalk';

  @override
  String get figThripsPatches => 'Irregular patches on the rind';

  @override
  String get figHeatSummer => 'Hot summer';

  @override
  String get figHeatDrop => 'Second wave of fruit drop';

  @override
  String get practicesScout => 'How to scout';

  @override
  String get practicesActionLevel => 'Action level';

  @override
  String get practicesNoActionLevel =>
      'Ask your KVK for the action level: the sources read so far are silent on it.';

  @override
  String get practicesWhatToDo => 'What to do';

  @override
  String get practicesBioTitle => 'Organic / bio';

  @override
  String get practicesBioRegistered =>
      'Registered product: the dose comes only from its label.';

  @override
  String get practicesBioHome => 'Home-made, as published';

  @override
  String get practicesHowToPrepare => 'How to prepare';

  @override
  String get practicesLabelLink => 'Label-approved products';

  @override
  String get practicesKnowledgeCard => 'Knowledge card';

  @override
  String get knowledgeTitle => 'Knowledge cards';

  @override
  String get knowledgeIntro =>
      'Short notes on bahar, pests, diseases, feeding, water and harvest. Products and doses are on the label screen.';

  @override
  String get knowledgeEmpty =>
      'Knowledge cards appear here once the phone has been online.';

  @override
  String get knowledgeWarnings => 'Take care';

  @override
  String get knowledgeCallExpert => 'When to ask an expert';

  @override
  String get knowledgeSources => 'Sources';

  @override
  String get practicesSourcesLineAll =>
      'Sources: NHB, NIPHM, ICAR, Dr. PDKV, MPKV, TNAU and others. Details under each practice.';

  @override
  String get schemeGeneralSource => 'the official pages listed at the end';

  @override
  String get schemeFacts => 'Key facts from the official page';

  @override
  String schemeFactSource(String source) {
    return 'From: $source';
  }

  @override
  String get labNormsTitle => 'Soil Health Card rating ranges';

  @override
  String get labNormsHint =>
      'Compare the value on your report with these ranges.';

  @override
  String get labelInfoChemical => 'Chemical';

  @override
  String get labelInfoBio => '🌿 Organic / bio (registered biopesticides)';

  @override
  String labelInfoDilution(String value) {
    return 'Water on label: $value L per hectare';
  }

  @override
  String labelInfoDilutionPrinted(String value) {
    return 'Water on label: $value';
  }

  @override
  String labelInfoBrands(String names) {
    return 'Brand names (A–Z, a plain list): $names';
  }

  @override
  String get labelInfoMakerPage => 'Maker\'s product page';

  @override
  String labelInfoTargetPrinted(String target) {
    return 'Target on label: $target';
  }

  @override
  String labelInfoPage(String page) {
    return 'Page in source: $page';
  }

  @override
  String labelInfoNoClaim(String target) {
    return 'No registered label claim for $target on citrus.';
  }

  @override
  String get labelInfoBanned => 'Outside the approved list';

  @override
  String get labelInfoRestricted => 'Outside the approved list for this crop';

  @override
  String get labelInfoAllTargets => 'All pests and diseases';

  @override
  String labelInfoOpenFor(String target) {
    return 'Label information: $target';
  }

  @override
  String labelInfoSources(String count) {
    return 'Source documents ($count)';
  }

  @override
  String get labelInfoOpenDetails => 'Tap to see the full label details';

  @override
  String get labelInfoDetailsTitle => 'Full label details';

  @override
  String get noPlotTitle => 'Add your orchard block first';

  @override
  String get noPlotBody =>
      'Every record is kept for a block. Save your block once, and this opens straight after.';

  @override
  String plotAddressNear(String place) {
    return 'Nearby place: $place';
  }

  @override
  String plotAddressDistrict(String district) {
    return 'Dist. $district';
  }

  @override
  String get plotAddressLooking => 'Finding the place name…';

  @override
  String get plotAddressMissing =>
      'The location will be saved. For the place name, turn on the internet and tap \'Take location again\'.';

  @override
  String get onboardingNameHint => '';

  @override
  String get nameScriptPromptTitle => 'Write your name in your language';

  @override
  String get nameScriptFieldLabel => 'Name';

  @override
  String get nameScriptLater => 'Later';

  @override
  String get adminMlQueue => 'Verification queue';

  @override
  String get adminMlTags => 'Rating tags';

  @override
  String get adminMlLotSettings => 'Lot form';

  @override
  String get adminMlLotSettingsNote =>
      'The rate range for each crop, per quintal and per crate, for the grower\'s asking rate and a trader\'s offer (the whole orchard has none), and how many days the harvest window runs after the start the grower picks. Empty = the default shown in grey; the server checks the rate again.';

  @override
  String get adminMlQuintalMin => 'Per quintal: lowest ₹';

  @override
  String get adminMlQuintalMax => 'Per quintal: highest ₹';

  @override
  String get adminMlCrateMin => 'Per crate: lowest ₹';

  @override
  String get adminMlCrateMax => 'Per crate: highest ₹';

  @override
  String get adminMlHarvestDays => 'Harvest window (days)';

  @override
  String get adminMlCropSantra => 'Santra (orange)';

  @override
  String get adminMlCropMosambi => 'Mosambi (sweet lime)';

  @override
  String get adminMlAll => 'All';

  @override
  String get adminMlBuyer => 'Trader';

  @override
  String get adminMlBroker => 'Broker';

  @override
  String get adminMlProvider => 'Service provider';

  @override
  String get adminMlQueueEmpty => 'Everyone is checked';

  @override
  String adminMlWaitingSince(String date) {
    return 'Waiting since $date';
  }

  @override
  String get adminMlFields => 'Submitted details';

  @override
  String get adminMlDocuments => 'Documents';

  @override
  String get adminMlNoDocuments => 'Documents appear here once sent';

  @override
  String adminMlDocument(int n) {
    return 'Document $n';
  }

  @override
  String get adminMlReject => 'Reject';

  @override
  String get adminMlRejectTitle => 'Reject with a reason';

  @override
  String get adminMlBadgeNote =>
      'The verified badge shows only after approval; a later rejection removes it at once.';

  @override
  String get adminMlStatusPending => 'Waiting';

  @override
  String get adminMlStatusApproved => 'Verified';

  @override
  String get adminMlStatusRejected => 'Rejected';

  @override
  String adminMlCheckedBy(String who) {
    return 'by $who';
  }

  @override
  String get adminMlTagsEmpty => 'Rating tags appear here';

  @override
  String get adminMlTagsNote =>
      'Drafts wait for a native-speaker check; only active tags reach the app.';

  @override
  String get adminMlTagDraft => 'Draft';

  @override
  String get adminMlTagActive => 'Active';

  @override
  String get adminMlTagRetired => 'Retired';

  @override
  String get adminMlPositive => 'Good';

  @override
  String get adminMlNegative => 'Problem';

  @override
  String get adminMlEditTag => 'Edit tag';

  @override
  String get adminMlLabelEn => 'English';

  @override
  String get adminMlLabelMr => 'Marathi';

  @override
  String get adminMlLabelHi => 'Hindi';

  @override
  String get adminMlYes => 'Yes';

  @override
  String get adminMlNo => 'No';

  @override
  String get adminMlFieldName => 'Name';

  @override
  String get adminMlFieldFirm => 'Firm';

  @override
  String get adminMlFieldPhone => 'Phone';

  @override
  String get adminMlFieldMarkets => 'Markets';

  @override
  String get adminMlFieldDistrict => 'District';

  @override
  String get adminMlFieldTaluka => 'Taluka';

  @override
  String get adminMlFieldVillage => 'Village';

  @override
  String get adminMlFieldCrops => 'Crops';

  @override
  String get adminMlFieldServiceAreas => 'Service area';

  @override
  String get adminMlFieldApmc => 'APMC licence no.';

  @override
  String get adminMlFieldGst => 'GST no.';

  @override
  String get adminMlFieldKind => 'Service';

  @override
  String get adminMlFieldCertValidUntil => 'Certificate valid until';

  @override
  String get adminMlFieldVehicles => 'Vehicle numbers';

  @override
  String get adminMlFieldCapacity => 'Capacity (t)';

  @override
  String get adminMlFieldRefrigerated => 'Refrigerated';

  @override
  String get adminMlFieldCarrierReg => 'Carrier registration no.';

  @override
  String get adminMlKindWeighbridge => 'Weighbridge';

  @override
  String get adminMlKindTransporter => 'Transporter';

  @override
  String get adminMlKindLabourGang => 'Labour gang';

  @override
  String get adminMlKindCrateSupplier => 'Crate supplier';

  @override
  String get adminMlChecks => 'Checks';

  @override
  String get adminMlChecksNote =>
      'Open the official page, paste the number (it is copied), check by hand and record the result. A badge says only what was checked and when.';

  @override
  String get adminMlOpenPage => 'Open official page';

  @override
  String get adminMlCallNow => 'Call';

  @override
  String get adminMlRecordResult => 'Record result';

  @override
  String adminMlNumberCopied(String number) {
    return 'Number copied: $number';
  }

  @override
  String get adminMlResultPassed => 'Passed';

  @override
  String get adminMlResultFailed => 'Failed';

  @override
  String get adminMlResultCancelled => 'Cancelled / deactivated';

  @override
  String get adminMlRegisteredYear => 'GST registration year (optional)';

  @override
  String get adminMlNoChecks => 'Checks you record show here';

  @override
  String get adminMlCheckApmc => 'APMC licence';

  @override
  String get adminMlCheckPhoneCall => 'Phone call';

  @override
  String get adminMlCheckPlacePhoto => 'Place photo';

  @override
  String adminMlRegisteredSince(String year) {
    return 'registered $year';
  }

  @override
  String get adminMlFlags => 'Look before approving';

  @override
  String get adminMlFlagDuplicate => 'Same number on another profile';

  @override
  String get adminMlFlagReturning => 'Matches a suspended profile';

  @override
  String get adminMlFlagMock => 'Location looked fake (mock)';

  @override
  String get adminMlFlagOtherDistrict =>
      'Registered outside the stated district';

  @override
  String get adminMlFlagNoPlace => 'Place name blank from the phone';

  @override
  String get adminMlWhyName => 'same name';

  @override
  String get adminMlWhyGps => 'registered nearby';

  @override
  String get adminMlWhyAccount => 'same sign-in';

  @override
  String get adminMlRechecks => 'Re-checks due';

  @override
  String get adminMlRechecksEmpty => 'All yearly re-checks are done';

  @override
  String adminMlLastChecked(String date) {
    return 'last checked $date';
  }

  @override
  String adminMlDocumentCount(int n) {
    return 'Documents: $n';
  }

  @override
  String get mlRolesTitle => 'Choose your role';

  @override
  String get mlRolesIntro =>
      'One sign-in for every role. You can switch the role any time.';

  @override
  String get mlRoleGrower => 'Farmer';

  @override
  String get mlRoleTrader => 'Trader';

  @override
  String get mlRoleBroker => 'Broker';

  @override
  String get mlRoleExporter => 'Exporter';

  @override
  String get mlRoleProvider => 'Service provider';

  @override
  String get mlRoleProviderKinds => 'Weighbridge, transport, labour, crates';

  @override
  String get mlRoleCurrent => 'Current role';

  @override
  String get mlSwitchRole => 'Switch role';

  @override
  String get mlHomeLinkTitle => 'Market link';

  @override
  String get mlHomeLinkHint =>
      'Trader, broker, exporter, services: choose a role';

  @override
  String get mlTermsTitle => 'Before you start';

  @override
  String mlTermsRole(String role) {
    return 'Role: $role';
  }

  @override
  String get mlTermsIntroOnly =>
      'BagMitra only gives information and introduces you to traders, brokers and the market.';

  @override
  String get mlTermsNotParty =>
      'BagMitra is not a buyer, seller, commission agent or transporter.';

  @override
  String get mlTermsNoMoney =>
      'It holds no money and guarantees no payment or quality.';

  @override
  String get mlTermsNoGainLoss =>
      'This app has no gain or loss in your transaction.';

  @override
  String get mlTermsNoPart =>
      'It takes no part in your transaction or in any dispute.';

  @override
  String get mlTermsAfterDeal =>
      'What to record after a transaction is your choice.';

  @override
  String get mlTermsPublicPhone =>
      'Your phone number is shown publicly on your profile, so growers can call you directly.';

  @override
  String get mlTermsGpsOnce =>
      'Your location (GPS) is taken once, at registration, to prevent fraud.';

  @override
  String get mlTermsFull => 'Full terms of use';

  @override
  String get mlTermsAdult => 'I am over 18 years of age';

  @override
  String get mlTermsAgree => 'I have read and agree';

  @override
  String get mlTermsAccept => 'Accept and continue';

  @override
  String get mlTermsBack => 'Back';

  @override
  String get mlSafetyNotice =>
      'BagMitra never asks for money, OTP or bank details.';

  @override
  String get mlGrievanceTitle => 'Grievance officer';

  @override
  String get mlGrievanceOwner => 'BagMitra owner';

  @override
  String mlGrievanceContact(String contact) {
    return 'Contact: $contact';
  }

  @override
  String get mlGrievanceTimes =>
      'Complaints are acknowledged within 24 hours and resolved within 15 days.';

  @override
  String get mlKindWeighbridge => 'Weighbridge';

  @override
  String get mlKindTransporter => 'Transport';

  @override
  String get mlKindLabourGang => 'Labour gang';

  @override
  String get mlKindCrateSupplier => 'Crate supplier';

  @override
  String get mlRegisterTrader => 'Trader registration';

  @override
  String get mlRegisterExporter => 'Exporter registration';

  @override
  String get mlRegisterBroker => 'Broker registration';

  @override
  String get mlRegisterProvider => 'Service provider registration';

  @override
  String get mlRegisterAs => 'Register as';

  @override
  String get mlFixTitle => 'Location at registration';

  @override
  String get mlFixWhy =>
      'To finish registration, the phone takes your current location once. This keeps fake registrations away.';

  @override
  String get mlFixOnce =>
      'Taken once, right now. Your public profile shows only village, taluka and district; the exact point is for BagMitra\'s check.';

  @override
  String get mlPhonePublicNote =>
      'After the check, your name, firm and contact number are shown to registered growers.';

  @override
  String get mlFixTake => 'Take location';

  @override
  String get mlFixTaking => 'Taking location…';

  @override
  String get mlFixDenied => 'Allow location to finish registration.';

  @override
  String mlFixTaken(String place, String metres) {
    return 'Location taken: $place (±$metres m)';
  }

  @override
  String get mlPickKind => 'What service do you give?';

  @override
  String get mlFieldName => 'Name';

  @override
  String get mlFieldPhone => 'Contact number';

  @override
  String get mlFieldFirm => 'Firm name (optional)';

  @override
  String get mlFieldVillage => 'Village';

  @override
  String get mlFieldTaluka => 'Taluka';

  @override
  String get mlFieldDistrict => 'District';

  @override
  String get mlFieldMarkets => 'Markets / villages (comma between)';

  @override
  String get mlFieldAreas => 'Areas you serve (comma between)';

  @override
  String get mlFieldCrops => 'Crops';

  @override
  String get mlFieldAddress => 'Address (optional)';

  @override
  String get mlFieldGst => 'GSTIN';

  @override
  String get mlFieldApmc => 'APMC licence no.';

  @override
  String get mlFieldFssai => 'FSSAI licence no.';

  @override
  String get mlFieldIec => 'IEC no.';

  @override
  String get mlFieldApeda => 'APEDA registration no.';

  @override
  String get mlFieldVehicles => 'Vehicle numbers (comma between)';

  @override
  String get mlFieldCapacity => 'Capacity (tonnes)';

  @override
  String get mlFieldRefrigerated => 'Refrigerated vehicle';

  @override
  String get mlFieldCertUntil => 'Certificate valid until';

  @override
  String mlCertUntilValue(String date) {
    return 'Certificate valid until $date';
  }

  @override
  String get mlNumbersNote =>
      'Give at least one: GSTIN, APMC licence or IEC. BagMitra checks it on the official public register.';

  @override
  String get mlIecRequired => 'An exporter registers with an IEC number.';

  @override
  String get mlBrokerCallNote =>
      'BagMitra calls you on this number to complete the check.';

  @override
  String get mlErrPhone => 'Write a 10-digit mobile number';

  @override
  String get mlErrGst => 'Write the 15-character GSTIN';

  @override
  String get mlErrIec => 'Write the 10-character IEC';

  @override
  String get mlErrFssai => 'Write the 14-digit FSSAI number';

  @override
  String get mlErrCapacity => 'Write the capacity in tonnes (up to 100)';

  @override
  String get mlErrOneNumber => 'Write a GSTIN, APMC licence or IEC number';

  @override
  String get mlErrPickKind => 'Pick the service you give';

  @override
  String get mlErrCertDate => 'Pick the certificate\'s valid-until date';

  @override
  String get mlErrFixStale => 'Take the location again, then send';

  @override
  String get mlErrExists =>
      'You are already registered in this role; see My market registration';

  @override
  String get mlErrCheckFields => 'Check the entries and send again';

  @override
  String get mlSubmit => 'Send registration';

  @override
  String get mlSubmitted => 'Registration sent. BagMitra will check it.';

  @override
  String get mlOffline => 'Connect to the internet to see this';

  @override
  String get mlServerBusy => 'The server is busy; try again in a while';

  @override
  String get mlRetry => 'Try again';

  @override
  String get mlMyProfilesTitle => 'My market registration';

  @override
  String get mlMyProfilesEmpty =>
      'Register below as a trader, exporter, broker or service provider.';

  @override
  String get mlStatusPending => 'Check pending';

  @override
  String get mlStatusApproved => 'Checked by BagMitra';

  @override
  String get mlStatusRejected => 'Sent back; see the reason';

  @override
  String get mlCheckNote =>
      'Your profile is shown to growers after BagMitra\'s check. Document photos help the check.';

  @override
  String mlDocsCount(String count) {
    return 'Document photos: $count';
  }

  @override
  String get mlDocCertificate => 'Weighbridge certificate';

  @override
  String mlCertExpired(String date) {
    return 'Certificate date passed ($date)';
  }

  @override
  String get mlAddressAdd => 'Add address';

  @override
  String get mlAddressEdit => 'Change address';

  @override
  String get mlCancel => 'Cancel';

  @override
  String get mlSave => 'Save';

  @override
  String get mlPeopleTitle => 'Traders and brokers';

  @override
  String get mlPeopleEmpty =>
      'Checked traders and brokers of this area will show here.';

  @override
  String mlAreaTaluka(String taluka) {
    return 'Taluka $taluka';
  }

  @override
  String mlAreaDistrict(String district) {
    return 'District $district';
  }

  @override
  String get mlSortRating => 'By rating';

  @override
  String get mlSortDeals => 'By deals';

  @override
  String mlDeals(String count) {
    return 'Deals done: $count';
  }

  @override
  String mlStars(String average, String count) {
    return '$average/5 ($count)';
  }

  @override
  String mlDistanceKm(String km) {
    return '$km km';
  }

  @override
  String mlBadgeChecked(String date) {
    return 'Checked by BagMitra on $date';
  }

  @override
  String mlBadgeRegisteredFrom(String place, String date) {
    return 'Registered from $place on $date';
  }

  @override
  String mlBadgePlacePhoto(String date) {
    return 'Place photo by a BagMitra representative on $date';
  }

  @override
  String get mlBadgeNote =>
      'A badge says what BagMitra checked and when. You settle the deal terms directly with each other.';

  @override
  String get mlCall => 'Call';

  @override
  String mlCallNumber(String phone) {
    return 'Call $phone';
  }

  @override
  String get mlRatingsTitle => 'Ratings';

  @override
  String get mlQTraderOnDate => 'Came on the agreed harvest date';

  @override
  String get mlQTraderWeighing => 'Weighing / crate count correct';

  @override
  String get mlQTraderPaid => 'Paid advance and balance as agreed';

  @override
  String get mlQTraderConditions => 'Kept the other conditions';

  @override
  String get mlQBrokerHonest => 'Represented the deal honestly';

  @override
  String get mlQBrokerTraderKept => 'The trader they brought kept the deal';

  @override
  String get mlAreaAll => 'All areas';

  @override
  String get mlMarkets => 'Markets / villages';

  @override
  String get mlAreas => 'Areas served';

  @override
  String get mlServicesTitle => 'Service providers';

  @override
  String get mlServicesEmpty =>
      'Checked weighbridges, transport, labour gangs and crate suppliers near you will show here.';

  @override
  String get mlServicesNote =>
      'Call them and agree directly; rates and payment are between you.';

  @override
  String mlNearPlot(String name) {
    return 'Near $name';
  }

  @override
  String get mlDisclaimerShort =>
      'BagMitra is not a buyer, seller, middleman (broker) or transporter, does not hold money and does not guarantee payment or quality.';

  @override
  String get mlOpen => 'Show produce for sale';

  @override
  String get mlMyLotsTitle => 'My produce for sale';

  @override
  String get mlLotsEmpty =>
      'Show your produce here with photos; verified traders and middlemen (brokers) see it.';

  @override
  String get mlLotFormTitle => 'Produce for sale';

  @override
  String get mlNoPlot => 'Add your orchard first.';

  @override
  String get mlPlot => 'Orchard';

  @override
  String get mlBahar => 'Bahar';

  @override
  String get mlQuantity => 'Estimated quantity (tonnes)';

  @override
  String get mlQuality => 'Size and quality';

  @override
  String get mlHarvestWindow => 'Harvest window';

  @override
  String mlWindowRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get mlBasis => 'Sale basis';

  @override
  String get mlBasisPerQuintal => 'Per quintal';

  @override
  String get mlBasisPerCrate => 'Per crate';

  @override
  String get mlBasisLumpSum => 'Whole orchard';

  @override
  String get mlAskingRate => 'Asking rate in ₹ (optional)';

  @override
  String get mlHarvestFrom => 'Harvest from';

  @override
  String get mlHarvestTo => 'Until';

  @override
  String get mlHarvestPickDate => 'Choose a date';

  @override
  String mlHarvestFromBahar(String date) {
    return '$date (bahar)';
  }

  @override
  String mlHarvestAutoEnd(String days) {
    return 'Until is set $days days after the start; change it if you like.';
  }

  @override
  String get mlHarvestChangeEnd => 'Change';

  @override
  String get mlAskingRatePerQuintal => 'Asking rate ₹ / quintal (optional)';

  @override
  String get mlAskingRatePerCrate => 'Asking rate ₹ / crate (optional)';

  @override
  String get mlAskingRateLumpSum =>
      'Asking rate ₹ for the whole orchard (optional)';

  @override
  String mlRateRangePerQuintal(String min, String max) {
    return '$min – $max per quintal';
  }

  @override
  String mlRateRangePerCrate(String min, String max) {
    return '$min – $max per crate';
  }

  @override
  String mlRateOutOfRange(String min, String max) {
    return 'Please write a rate from $min to $max.';
  }

  @override
  String get mlPublishRateRange =>
      'Please keep the asking rate within the range shown, then send again.';

  @override
  String get mlOfferRateRange =>
      'Please keep the rate within the range shown, then send again.';

  @override
  String get mlPhotos => 'Photos';

  @override
  String mlPhotosHint(String min, String max) {
    return '$min to $max photos from the app camera';
  }

  @override
  String get mlAddPhoto => 'Take photo';

  @override
  String get mlRemovePhoto => 'Remove photo';

  @override
  String get mlPhotoNoGps =>
      'Turn on GPS and take the photo again: each photo needs its location.';

  @override
  String get mlPrivacy =>
      'Traders see only your village, taluka and district; your name, phone and orchard location stay private.';

  @override
  String get mlSaveDraft => 'Save draft';

  @override
  String get mlPublish => 'Show to traders';

  @override
  String get mlClose => 'Stop showing';

  @override
  String get mlStatusDraft => 'Draft';

  @override
  String get mlStatusPublished => 'Shown to traders';

  @override
  String get mlStatusReview => 'Waiting for check';

  @override
  String get mlStatusClosed => 'Closed';

  @override
  String mlTonnes(String value) {
    return '$value t';
  }

  @override
  String mlRatePerQuintal(String rate) {
    return '$rate per quintal';
  }

  @override
  String mlRatePerCrate(String rate) {
    return '$rate per crate';
  }

  @override
  String mlRateLumpSum(String rate) {
    return '$rate for the orchard';
  }

  @override
  String get mlPublished =>
      'Now shown to verified traders and middlemen (brokers).';

  @override
  String get mlClosed => 'Taken off the traders\' list.';

  @override
  String get mlPublishOffline =>
      'This needs internet. Your draft is saved; try again when online.';

  @override
  String mlPublishNeedPhotos(String min, String max) {
    return 'Add $min to $max photos first.';
  }

  @override
  String get mlPublishPhotoMissing =>
      'Remove that photo and take it again: its file is missing on this phone.';

  @override
  String get mlPublishNotAccepted =>
      'Accept the grower terms first, then try again.';

  @override
  String get mlPublishFailed => 'Try again in a little while.';

  @override
  String get mlChooseOne => 'Choose one';

  @override
  String get mlDeleteDraft => 'Delete draft';

  @override
  String get mlNoContacts =>
      'Write only about the produce here; phone numbers and links are shared after you accept an offer.';

  @override
  String get mlPublishOrchardCheck =>
      'Published; traders see it after a check, because the photos were taken outside your mapped orchard.';

  @override
  String get mlSize => 'Size';

  @override
  String get mlGrade => 'Grade';

  @override
  String get mlQualityLine => 'A short line (optional)';

  @override
  String get mlSafetyReport => 'Report';

  @override
  String get mlSafetyReportTitle => 'Report to BagMitra';

  @override
  String get mlSafetyReportWhy => 'Choose the reason';

  @override
  String get mlSafetyReportNote =>
      'BagMitra only introduces people. Report a fake identity, a fake lot, someone pretending to be BagMitra, a fake rating or abuse; payment, weight and quality are settled between you.';

  @override
  String get mlSafetyPhoto => 'Add a photo (if you wish)';

  @override
  String get mlSafetyPhotoAdded => 'Photo added';

  @override
  String get mlSafetySend => 'Send report';

  @override
  String get mlSafetySent => 'Report received. BagMitra will check it.';

  @override
  String get mlSafetyRetry => 'Check the internet and try again';

  @override
  String get mlReasonFakeIdentity => 'Fake identity';

  @override
  String get mlReasonFakeLot => 'Fake lot or photos from another orchard';

  @override
  String get mlReasonImpersonation => 'Pretends to be BagMitra';

  @override
  String get mlReasonFakeRating => 'Fake rating';

  @override
  String get mlReasonAbuse => 'Abusive behaviour';

  @override
  String get mlReasonDuplicateUser => 'Same person, two accounts';

  @override
  String get mlReasonChecksPassed => 'Checks passed';

  @override
  String get mlReasonAppealUpheld => 'Appeal accepted';

  @override
  String get mlActionVerify => 'Verified';

  @override
  String get mlActionWarn => 'Warning';

  @override
  String get mlActionHide => 'Hidden from lists';

  @override
  String get mlActionSuspend => 'Account paused';

  @override
  String get mlActionRestore => 'Restored';

  @override
  String get mlAppealIdentityGenuine => 'My identity is genuine';

  @override
  String get mlAppealLotGenuine => 'My lot and photos are genuine';

  @override
  String get mlAppealRatingGenuine => 'This rating is from a real deal';

  @override
  String get mlAppealBehaviourProper => 'My behaviour was proper';

  @override
  String get mlAppealNotDuplicate => 'This is my only account';

  @override
  String get mlAppealStateAppealed => 'Appeal with the grievance officer';

  @override
  String get mlAppealStateUpheld => 'Appeal accepted';

  @override
  String get mlAppealStateRejected => 'Decision stays';

  @override
  String get mlActionsTitle => 'My account actions';

  @override
  String get mlActionsEmpty => 'Your account is in good standing.';

  @override
  String mlActionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String mlActionDate(String date) {
    return 'On $date';
  }

  @override
  String get mlAppeal => 'Appeal';

  @override
  String get mlAppealTitle => 'Appeal (once)';

  @override
  String get mlAppealNote =>
      'The grievance officer acknowledges within 24 hours and decides within 15 days.';

  @override
  String get mlAppealSend => 'Send appeal';

  @override
  String get mlAppealSent => 'Appeal received';

  @override
  String get mlGrievanceDefault => 'Owner of BagMitra';

  @override
  String get mlBlock => 'Block';

  @override
  String get mlUnblock => 'Unblock';

  @override
  String get mlBlockTitle => 'Block this person?';

  @override
  String get mlBlockNote =>
      'You and this person stay out of each other\'s lists and interests. Unblock any time.';

  @override
  String get mlBlocked => 'Blocked';

  @override
  String get mlUnblocked => 'Unblocked';

  @override
  String get mlMoreOptions => 'More options';

  @override
  String get adminMlReports => 'Reports';

  @override
  String get adminMlAppeals => 'Appeals';

  @override
  String get adminMlReportsEmpty => 'Every report is handled';

  @override
  String get adminMlAppealsEmpty => 'Every appeal is decided';

  @override
  String get adminMlAckOverdue => 'Acknowledge: over 24 h';

  @override
  String get adminMlCloseOverdue => 'Close: over 15 days';

  @override
  String get adminMlAcknowledge => 'Acknowledge';

  @override
  String get adminMlAct => 'Act';

  @override
  String get adminMlDismiss => 'Dismiss';

  @override
  String get adminMlUphold => 'Accept appeal';

  @override
  String get adminMlKeepDecision => 'Keep decision';

  @override
  String get adminMlActionTitle => 'Action with a reason code';

  @override
  String get adminMlActionNote =>
      'Platform rules only: fake or duplicate users, fake lots, impersonation, abuse. Payment, weight and quality quarrels stay with the parties.';

  @override
  String get adminMlStatusOpen => 'Open';

  @override
  String get adminMlStatusActioned => 'Actioned';

  @override
  String get adminMlStatusDismissed => 'Dismissed';

  @override
  String get adminMlTargetLot => 'Lot';

  @override
  String get adminMlTargetRating => 'Rating';

  @override
  String get adminMlTargetUser => 'User';

  @override
  String adminMlReceived(String date) {
    return 'Received $date';
  }

  @override
  String adminMlPhoto(int n) {
    return 'Photo $n';
  }

  @override
  String adminMlAppealReason(String reason) {
    return 'Appeal: $reason';
  }

  @override
  String get mlBrowseTitle => 'Produce on sale';

  @override
  String get mlBrowseEmpty => 'Produce shown by growers appears here.';

  @override
  String get mlNotVerified =>
      'Produce shows here once BagMitra has checked your registration.';

  @override
  String get mlMyOffersTitle => 'My offers';

  @override
  String get mlMyOffersEmpty => 'Offers you make on produce appear here.';

  @override
  String get mlOfferOpen => 'Waiting for the grower';

  @override
  String get mlOfferAccepted => 'Accepted';

  @override
  String get mlOfferClosed =>
      'Closed: the grower chose another offer or took the produce off the list.';

  @override
  String mlHarvestOn(String date) {
    return 'Harvest $date';
  }

  @override
  String get mlMakeOffer => 'Make an offer';

  @override
  String get mlOfferTitle => 'Your offer';

  @override
  String get mlOfferRate => 'Rate ₹';

  @override
  String get mlOfferQuantity => 'Quantity in tonnes (optional)';

  @override
  String get mlOfferHarvestDate => 'Proposed harvest date';

  @override
  String get mlOfferThroughBroker => 'Through a middleman (broker)';

  @override
  String get mlOfferForTrader => 'For which trader';

  @override
  String get mlOfferDirect => 'Directly';

  @override
  String get mlOfferOnlyThese =>
      'Only the rate, quantity and date go to the grower; settle everything else face to face.';

  @override
  String get mlOfferSend => 'Send offer';

  @override
  String get mlOfferSent =>
      'Offer sent. A notice comes when the grower decides.';

  @override
  String get mlErrRate => 'Write the rate in rupees';

  @override
  String get mlErrQuantity => 'Write the tonnes (up to 10,000)';

  @override
  String get mlErrPickTrader => 'Pick the trader';

  @override
  String get mlErrLotGone => 'This produce has left the list.';

  @override
  String get mlOffersTitle => 'Offers on your produce';

  @override
  String get mlOffersEmpty =>
      'Offers from checked traders appear here, one beside the other.';

  @override
  String get mlSeeOffers => 'See offers';

  @override
  String mlYourAsk(String rate) {
    return 'Your asking rate: $rate';
  }

  @override
  String get mlAcceptPick => 'Tap one offer to choose it';

  @override
  String get mlAccept => 'Accept chosen offer';

  @override
  String get mlAcceptConfirmTitle => 'Accept this offer?';

  @override
  String get mlAcceptConfirmBody =>
      'This trader (and the middleman, if named) will see your name, phone and orchard location. The other offers close. You settle the rest of the transaction directly.';

  @override
  String get mlAcceptYes => 'Accept';

  @override
  String get mlAccepted => 'Accepted. You both see each other\'s contacts now.';

  @override
  String get mlAcceptChanged => 'The offer changed; open the list again.';

  @override
  String get mlIntroOpen => 'See contacts';

  @override
  String get mlIntroTitle => 'Contacts';

  @override
  String get mlIntroGrower => 'Farmer';

  @override
  String get mlIntroOpenMap => 'Open orchard on map';

  @override
  String mlIntroAcceptedOn(String date) {
    return 'Accepted on $date';
  }

  @override
  String get mlIntroOffApp =>
      'From here on, weighing, crates, transport and payment are settled between you.';

  @override
  String get mlDealDone => 'Deal done';

  @override
  String get mlDealDoneAsk => 'Mark the deal as done?';

  @override
  String get mlDealDoneAskBody =>
      'Tap only once the deal between you is settled. Rating opens when both the grower and the trader tap.';

  @override
  String get mlDealSaidDone => 'said deal done';

  @override
  String get mlDealNotYet => 'waiting';

  @override
  String get mlDealWaitOther =>
      'Rating opens when the other side also taps “Deal done”.';

  @override
  String get mlDealWaitBoth =>
      'Rating opens when both the grower and the trader tap “Deal done”.';

  @override
  String get mlRateOpen => 'Give rating';

  @override
  String mlRateUntil(String date) {
    return 'Can be given or changed until $date';
  }

  @override
  String mlRateLocked(String date) {
    return 'Rating closed on $date';
  }

  @override
  String get mlRateNoText => 'Only stars and ticks.';

  @override
  String mlRateStarsOf(int count) {
    return '$count of 5 stars';
  }

  @override
  String get mlRateSave => 'Save rating';

  @override
  String get mlRateAnswerAll => 'Give stars on every line';

  @override
  String get mlRateSaved => 'Rating saved';

  @override
  String get mlRateRefused =>
      'Rating is saved only within 7 days after both tap “Deal done”.';

  @override
  String get mlRateSameDevice =>
      'Ratings are given between accounts on different phones.';

  @override
  String get mlQGrowerProduce => 'Produce matched the photos and description';

  @override
  String get mlQGrowerReady => 'Produce ready on the agreed date';

  @override
  String get mlCopyToAccounts => 'Note in my accounts';

  @override
  String mlBadgeGstChecked(String date) {
    return 'GST checked on $date';
  }

  @override
  String mlBadgeGstSince(String date, String year) {
    return 'GST checked on $date · registered since $year';
  }

  @override
  String mlBadgeApmcSeen(String date) {
    return 'APMC licence seen on $date';
  }

  @override
  String mlBadgeFssaiChecked(String date) {
    return 'FSSAI checked on $date';
  }

  @override
  String mlBadgeIecActive(String date) {
    return 'IEC active, checked on $date';
  }

  @override
  String mlBadgeApedaListed(String date) {
    return 'APEDA listed, checked on $date';
  }

  @override
  String mlPackageActiveUntil(String date) {
    return 'Package active until $date';
  }

  @override
  String get mlPackageNotActive => 'Package not active';

  @override
  String get mlPackageHiddenNow => 'Not shown to traders now';

  @override
  String get billingTitle => 'Subscription';

  @override
  String billingPerMonth(String price) {
    return '$price a month';
  }

  @override
  String get billingIncluded => 'The whole BagMitra app, every feature.';

  @override
  String get billingTerms =>
      'Renews every month through Google Play. Cancel any time in Google Play; your own records always stay readable and exportable.';

  @override
  String get billingSubscribe => 'Subscribe';

  @override
  String get billingRestore => 'Restore subscription';

  @override
  String get billingManage => 'Manage subscription';

  @override
  String get billingActive => 'Your subscription is active.';

  @override
  String get billingPending => 'Waiting for Google Play to confirm.';

  @override
  String get billingVerifying => 'BagMitra is checking with Google Play…';

  @override
  String get billingRetry => 'Try again, or tap Restore subscription.';

  @override
  String get billingNeedsPlay =>
      'Open this screen on a phone with Google Play.';

  @override
  String get billingChangeTitle => 'Change to your subscription';

  @override
  String billingChangeBody(String date) {
    return 'Google Play has a new monthly rate for your subscription from $date. To keep the subscription, review and accept it in Google Play.';
  }

  @override
  String billingChangeConfirmedBody(String date) {
    return 'From $date your subscription renews at its new monthly rate in Google Play. You have already accepted it.';
  }

  @override
  String get billingOpenPlay => 'Open Google Play';

  @override
  String get feedbackTitle => 'Send feedback';

  @override
  String get feedbackKindProblem => 'Problem';

  @override
  String get feedbackKindSuggestion => 'Suggestion';

  @override
  String get feedbackKindQuestion => 'Question';

  @override
  String get feedbackHint =>
      'Write or speak what happened, or what you would like.';

  @override
  String get feedbackAddScreenshot => 'Add a screenshot';

  @override
  String get feedbackScreenshotAdded => 'Screenshot added';

  @override
  String get feedbackIncluded =>
      'The app version and the phone model go with it.';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackSent => 'Received. Thank you!';

  @override
  String get feedbackQueued =>
      'Saved on the phone; it goes when the internet is back.';

  @override
  String mlLoginRole(String role) {
    return 'Role: $role';
  }

  @override
  String get expenseElsewhere =>
      'Spray (with its labour), labour and fertiliser costs go in their own records and are added to the accounts automatically.';

  @override
  String get expenseGoSpray => 'Spray';

  @override
  String get expenseGoLabour => 'Labour';

  @override
  String get expenseGoInputs => 'Fertiliser and manure';

  @override
  String get mlWelcomeTitle => 'Welcome to BagMitra';

  @override
  String get mlWelcomeLine =>
      'Orchard records, today\'s market prices and buyers, in one app.';

  @override
  String get photoCheckOpen => 'Identify from photo';

  @override
  String get photoCheckHint =>
      'Take a close photo of the leaf, fruit or trunk in good light.';

  @override
  String get photoCheckPart => 'Which part? (optional)';

  @override
  String get photoCheckPartLeaf => 'Leaf';

  @override
  String get photoCheckPartFruit => 'Fruit';

  @override
  String get photoCheckPartTrunk => 'Trunk';

  @override
  String get photoCheckPartWholeTree => 'Whole tree';

  @override
  String get photoCheckRetry => 'Check again';

  @override
  String get photoCheckBusy =>
      'Checking the photo… this can take up to a minute.';

  @override
  String get photoCheckChange => 'Another photo';

  @override
  String get photoCheckBack => 'Back to the record';

  @override
  String get photoCheckLikelyHigh => 'Quite likely';

  @override
  String get photoCheckLikelyMedium => 'Possible';

  @override
  String get photoCheckLikelyLow => 'Less likely';

  @override
  String get photoCheckSigns => 'Seen in the photo';

  @override
  String get photoCheckSignsEnglish => 'Seen in the photo (in English)';

  @override
  String get photoCheckOpenCard => 'Open card';

  @override
  String get photoCheckUnsure =>
      'A clearer photo will help. Take one closer, in good light, or compare the signs on the cards.';

  @override
  String get photoCheckHealthy =>
      'Good news: the photo looks like a healthy tree.';

  @override
  String get photoCheckNote =>
      'A suggestion from the photo; the card has the details.';

  @override
  String get photoCheckSeeCards => 'See the cards';

  @override
  String get photoCheckOffline =>
      'Photo check needs the internet. Your photo is kept here; tap Check again once you are online.';

  @override
  String get photoCheckFailed =>
      'Please check again in a little while. Your photo is kept here.';

  @override
  String get photoCheckUnavailable =>
      'Photo check is paused for now. Meanwhile you can compare the signs on the cards.';

  @override
  String get photoCheckRefused => 'Please take another photo.';

  @override
  String get photoCheckSignedOut => 'Please sign in again to check photos.';

  @override
  String get photoCheckDelete => 'Delete this photo';

  @override
  String get photoCheckDeleted => 'The photo was deleted from the server.';

  @override
  String get photoCheckDeleteFailed =>
      'Tap Delete this photo again once you are online.';

  @override
  String photoCheckLimitDaily(String count) {
    return 'Today\'s $count photos are used; you can check again tomorrow.';
  }

  @override
  String photoCheckLimitDailyAt(String count, String when) {
    return 'Today\'s $count photos are used; you can check again after $when.';
  }

  @override
  String photoCheckLimitMonthly(String count, String when) {
    return 'This month\'s $count photos are used; you can check again from $when.';
  }

  @override
  String get photoCheckLimitTotal =>
      'Today\'s photo checks are full; you can check again tomorrow.';

  @override
  String photoCheckLimitTotalAt(String when) {
    return 'Today\'s photo checks are full; you can check again after $when.';
  }

  @override
  String photoOfflineLead(String what, String likely) {
    return 'First check on the phone: $what ($likely)';
  }

  @override
  String photoOfflineAlso(String what, String likely) {
    return 'or: $what ($likely)';
  }

  @override
  String get photoOfflineCanker => 'signs like canker';

  @override
  String get photoOfflineGreening => 'signs like greening';

  @override
  String get photoOfflineHealthy =>
      'First check on the phone: the leaf looks healthy.';

  @override
  String get photoOfflineUnclear =>
      'For a clear answer this photo needs the full check. Tap Check again once the internet is back.';

  @override
  String get photoOfflineNote =>
      'An estimate on the phone; the full check can run once the internet is back.';

  @override
  String get photoOfflinePcr =>
      'Only a lab PCR test can confirm greening; see the greening card.';

  @override
  String get billPhoto => 'Bill photo';

  @override
  String get billPhotoHint =>
      'The shop bill\'s photo stays with this record on the phone.';

  @override
  String get billPhotoOpen => 'Open the bill photo';

  @override
  String get billFill => 'Fill from bill';

  @override
  String get billReading => 'Reading the bill…';

  @override
  String get billUnsure =>
      'Could not read the bill clearly; fill in the details by hand.';

  @override
  String billFilled(String fields) {
    return 'Filled from the bill: $fields. Please check once.';
  }

  @override
  String get billNothingFilled =>
      'These fields were already filled; they are kept as they were.';

  @override
  String get billOffline =>
      'Reading the bill needs internet. The photo is saved with this record on the phone.';

  @override
  String get billFailed =>
      'Try \'Fill from bill\' again in a while; the photo stays here.';

  @override
  String get billUnavailable =>
      'Bill reading is paused for now; fill in the details by hand.';

  @override
  String get billRefused => 'Please take another photo of the bill.';

  @override
  String get billSignedOut => 'Sign in again to read the bill.';

  @override
  String billLimitDaily(String count) {
    return 'Today\'s $count bill readings are used; you can read again tomorrow.';
  }

  @override
  String billLimitDailyAt(String count, String when) {
    return 'Today\'s $count bill readings are used; you can read again after $when.';
  }

  @override
  String billLimitMonthly(String count, String when) {
    return 'This month\'s $count bill readings are used; you can read again from $when.';
  }

  @override
  String get billLimitTotal =>
      'Today\'s bill readings are full; you can read again tomorrow.';

  @override
  String billLimitTotalAt(String when) {
    return 'Today\'s bill readings are full; you can read again after $when.';
  }

  @override
  String get billPickTitle => 'Pick a line from the bill';

  @override
  String get billTotal => 'Bill total';

  @override
  String billLabelShopNo(String shop, String no) {
    return '$shop bill #$no';
  }

  @override
  String billLabelShop(String shop) {
    return '$shop bill';
  }

  @override
  String billLabelNo(String no) {
    return 'Bill #$no';
  }

  @override
  String get billFieldProduct => 'product name';

  @override
  String get billFieldActive => 'active ingredient';

  @override
  String get billFieldDose => 'quantity';

  @override
  String get billFieldCost => 'cost';

  @override
  String get billFieldAmount => 'amount';

  @override
  String get billFieldDate => 'date';

  @override
  String get billFieldNote => 'note';

  @override
  String sprayProductHeading(String n) {
    return 'Product $n';
  }

  @override
  String get sprayAddProduct => '+ Add another product';

  @override
  String sprayRemoveProduct(String n) {
    return 'Remove product $n';
  }

  @override
  String get spraySharedHeading => 'For the whole spray';

  @override
  String sprayMix(String names) {
    return 'Mix: $names';
  }

  @override
  String get sprayMixHeading => 'Mix:';

  @override
  String sprayMixTotal(String amount) {
    return 'Total cost $amount';
  }

  @override
  String sprayMixPhi(String days) {
    return 'Waiting period of the mix: $days days (the longest)';
  }

  @override
  String sprayPhiDays(String days) {
    return 'PHI $days days';
  }

  @override
  String get sprayDetailTitle => 'Spray record';

  @override
  String sprayDetailWater(String litres) {
    return 'Water $litres L';
  }

  @override
  String sprayDetailArea(String acres) {
    return '$acres acres';
  }

  @override
  String sprayDetailOperator(String name) {
    return 'Sprayed by $name';
  }

  @override
  String get sprayDetailProducts => 'Products in the tank';

  @override
  String get billPickManyTitle => 'Tick the bill lines mixed in this spray';

  @override
  String billPickMany(String count) {
    return 'Fill $count selected';
  }

  @override
  String get sprayLabour => 'Spraying labour (₹, optional)';

  @override
  String get sprayLabourHelp =>
      'If it is already in the labour register (spraying), leave this empty.';

  @override
  String sprayCostSplit(String products, String labour) {
    return 'Total cost = products $products + labour $labour';
  }
}
