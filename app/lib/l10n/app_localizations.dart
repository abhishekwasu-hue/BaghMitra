import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// Product name shown as the app title and in admin. Brand: BagMitra; Devanagari in mr/hi.
  ///
  /// In en, this message translates to:
  /// **'BagMitra'**
  String get appName;

  /// Home header greeting line above the farmer's name.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get greetingHello;

  /// Respectful form of the farmer's name.
  ///
  /// In en, this message translates to:
  /// **'{name} ji'**
  String greetingName(String name);

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'{degrees}°'**
  String temperature(int degrees);

  /// No description provided for @maxTemperature.
  ///
  /// In en, this message translates to:
  /// **'Max {degrees}°'**
  String maxTemperature(int degrees);

  /// No description provided for @soilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Soil moisture {percent}%'**
  String soilMoisture(int percent);

  /// Unit under the big bahar day counter.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get stageDays;

  /// No description provided for @nextStage.
  ///
  /// In en, this message translates to:
  /// **'Next stage: {stage} · in about {days} days · harvest {month}'**
  String nextStage(String stage, int days, String month);

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks'**
  String get todaysTasks;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @marketTitle.
  ///
  /// In en, this message translates to:
  /// **'{market} market'**
  String marketTitle(String market);

  /// No description provided for @sevenDayTrend.
  ///
  /// In en, this message translates to:
  /// **'7-day trend'**
  String get sevenDayTrend;

  /// No description provided for @perQuintal.
  ///
  /// In en, this message translates to:
  /// **'per quintal'**
  String get perQuintal;

  /// No description provided for @vsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get vsLastWeek;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrchard.
  ///
  /// In en, this message translates to:
  /// **'Orchard'**
  String get navOrchard;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get navAsk;

  /// No description provided for @taskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskDone;

  /// No description provided for @markTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Mark task done'**
  String get markTaskDone;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your entries are saved and will sync.'**
  String get offlineBanner;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String pendingSync(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Will retry automatically.'**
  String get syncFailed;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your mobile number'**
  String get loginTitle;

  /// No description provided for @loginPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get loginPhoneLabel;

  /// No description provided for @loginSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get loginSendOtp;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOr;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginGoogle;

  /// No description provided for @loginGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google sign-in. Check the internet and try again.'**
  String get loginGoogleFailed;

  /// No description provided for @loginOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to {phone}'**
  String loginOtpTitle(String phone);

  /// No description provided for @loginOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP'**
  String get loginOtpLabel;

  /// No description provided for @loginVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get loginVerify;

  /// No description provided for @loginInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get loginInvalidPhone;

  /// No description provided for @loginInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'The OTP is incorrect or expired'**
  String get loginInvalidOtp;

  /// No description provided for @loginDemoNotice.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: any 6 digits will work'**
  String get loginDemoNotice;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get voiceInput;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get galleryTitle;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'{product} Admin'**
  String adminTitle(String product);

  /// No description provided for @adminCropTemplates.
  ///
  /// In en, this message translates to:
  /// **'Crop stage templates'**
  String get adminCropTemplates;

  /// No description provided for @adminRiskRules.
  ///
  /// In en, this message translates to:
  /// **'Risk rules'**
  String get adminRiskRules;

  /// No description provided for @adminPrompts.
  ///
  /// In en, this message translates to:
  /// **'AI prompt templates'**
  String get adminPrompts;

  /// No description provided for @adminTranslations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get adminTranslations;

  /// No description provided for @adminAiUsage.
  ///
  /// In en, this message translates to:
  /// **'AI usage'**
  String get adminAiUsage;

  /// No description provided for @adminComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Editing arrives in Milestone {milestone}.'**
  String adminComingSoon(int milestone);

  /// No description provided for @demoDataNotice.
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get demoDataNotice;

  /// No description provided for @myOrchard.
  ///
  /// In en, this message translates to:
  /// **'My orchard'**
  String get myOrchard;

  /// No description provided for @addPlot.
  ///
  /// In en, this message translates to:
  /// **'Add orchard block'**
  String get addPlot;

  /// No description provided for @plotsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orchard blocks yet'**
  String get plotsEmptyTitle;

  /// No description provided for @plotsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first block to get a bahar calendar and daily tasks.'**
  String get plotsEmptyBody;

  /// No description provided for @plotName.
  ///
  /// In en, this message translates to:
  /// **'Block name'**
  String get plotName;

  /// No description provided for @plotNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bag 1'**
  String get plotNameHint;

  /// No description provided for @plotCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get plotCrop;

  /// No description provided for @plotVariety.
  ///
  /// In en, this message translates to:
  /// **'Variety (optional)'**
  String get plotVariety;

  /// No description provided for @plotAreaAcres.
  ///
  /// In en, this message translates to:
  /// **'Area (acres)'**
  String get plotAreaAcres;

  /// No description provided for @plotTreeCount.
  ///
  /// In en, this message translates to:
  /// **'Number of trees (optional)'**
  String get plotTreeCount;

  /// No description provided for @plotPlantingYear.
  ///
  /// In en, this message translates to:
  /// **'Planting year (optional)'**
  String get plotPlantingYear;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @plotAcres.
  ///
  /// In en, this message translates to:
  /// **'{area} acres'**
  String plotAcres(String area);

  /// No description provided for @plotTrees.
  ///
  /// In en, this message translates to:
  /// **'{count} trees'**
  String plotTrees(int count);

  /// No description provided for @plotSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. It will sync when you are online.'**
  String get plotSaved;

  /// No description provided for @deletePlot.
  ///
  /// In en, this message translates to:
  /// **'Delete block'**
  String get deletePlot;

  /// No description provided for @deletePlotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This also removes it from your other devices.'**
  String deletePlotConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @startBahar.
  ///
  /// In en, this message translates to:
  /// **'Start a bahar'**
  String get startBahar;

  /// No description provided for @baharEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bahar planned yet'**
  String get baharEmptyTitle;

  /// No description provided for @baharEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a bahar and write down your own dates. Suggested dates will come once an expert-checked calendar is ready.'**
  String get baharEmptyBody;

  /// No description provided for @baharWhich.
  ///
  /// In en, this message translates to:
  /// **'Which bahar?'**
  String get baharWhich;

  /// No description provided for @baharSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get baharSeason;

  /// No description provided for @baharDates.
  ///
  /// In en, this message translates to:
  /// **'Your dates (optional)'**
  String get baharDates;

  /// No description provided for @baharPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get baharPickDate;

  /// No description provided for @baharStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get baharStatusPlanned;

  /// No description provided for @baharStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get baharStatusActive;

  /// No description provided for @baharStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get baharStatusCompleted;

  /// No description provided for @baharStatusAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get baharStatusAbandoned;

  /// No description provided for @adminCards.
  ///
  /// In en, this message translates to:
  /// **'Knowledge cards'**
  String get adminCards;

  /// No description provided for @adminImports.
  ///
  /// In en, this message translates to:
  /// **'Imports'**
  String get adminImports;

  /// No description provided for @adminAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get adminAlerts;

  /// No description provided for @adminSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get adminSources;

  /// No description provided for @adminPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get adminPublish;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminChemical.
  ///
  /// In en, this message translates to:
  /// **'Chemical'**
  String get adminChemical;

  /// No description provided for @adminImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get adminImport;

  /// No description provided for @adminImportSource.
  ///
  /// In en, this message translates to:
  /// **'Source key'**
  String get adminImportSource;

  /// No description provided for @adminImportCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV (checked by hand)'**
  String get adminImportCsv;

  /// No description provided for @adminImportClaims.
  ///
  /// In en, this message translates to:
  /// **'Label claims'**
  String get adminImportClaims;

  /// No description provided for @adminImportRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Bans and restrictions'**
  String get adminImportRestrictions;

  /// No description provided for @adminImportResult.
  ///
  /// In en, this message translates to:
  /// **'Added {added} · Changed {changed} · Removed {removed} · Unchanged {unchanged} · Cards pulled {pulled}'**
  String adminImportResult(
    int added,
    int changed,
    int removed,
    int unchanged,
    int pulled,
  );

  /// No description provided for @adminResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get adminResolve;

  /// No description provided for @adminNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No open alerts'**
  String get adminNoAlerts;

  /// No description provided for @adminNoCards.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get adminNoCards;

  /// No description provided for @adminSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a knowledge-base admin account to use this section.'**
  String get adminSignInRequired;

  /// No description provided for @adminDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminDone;

  /// No description provided for @adminSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get adminSignIn;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminEmail;

  /// No description provided for @adminPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminPassword;

  /// No description provided for @adminSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Email or password is wrong.'**
  String get adminSignInFailed;

  /// No description provided for @adminSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get adminSignOut;

  /// No description provided for @adminNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Admin sign-in needs SUPABASE_URL and SUPABASE_ANON_KEY.'**
  String get adminNotConfigured;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @addSale.
  ///
  /// In en, this message translates to:
  /// **'Record a sale'**
  String get addSale;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get expenseCategory;

  /// No description provided for @amountRupees.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amountRupees;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @accountsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get accountsExpenses;

  /// No description provided for @accountsIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get accountsIncome;

  /// No description provided for @accountsProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get accountsProfit;

  /// No description provided for @accountsDues.
  ///
  /// In en, this message translates to:
  /// **'Buyers owe'**
  String get accountsDues;

  /// No description provided for @costPerAcre.
  ///
  /// In en, this message translates to:
  /// **'Cost per acre'**
  String get costPerAcre;

  /// No description provided for @costPerTree.
  ///
  /// In en, this message translates to:
  /// **'Cost per tree'**
  String get costPerTree;

  /// No description provided for @costPerTonne.
  ///
  /// In en, this message translates to:
  /// **'Cost per tonne'**
  String get costPerTonne;

  /// No description provided for @allBahars.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allBahars;

  /// No description provided for @saleBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get saleBuyer;

  /// No description provided for @saleKg.
  ///
  /// In en, this message translates to:
  /// **'Quantity (kg)'**
  String get saleKg;

  /// No description provided for @saleRate.
  ///
  /// In en, this message translates to:
  /// **'Rate (₹ per quintal)'**
  String get saleRate;

  /// No description provided for @saleDeductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions (₹, optional)'**
  String get saleDeductions;

  /// No description provided for @salePaid.
  ///
  /// In en, this message translates to:
  /// **'Received so far (₹)'**
  String get salePaid;

  /// No description provided for @accountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Add an expense or a sale.'**
  String get accountsEmpty;

  /// No description provided for @saleBy.
  ///
  /// In en, this message translates to:
  /// **'{buyer} · {kg} kg'**
  String saleBy(String buyer, String kg);

  /// No description provided for @sprayLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Spray log'**
  String get sprayLogTitle;

  /// No description provided for @addSpray.
  ///
  /// In en, this message translates to:
  /// **'Add spray'**
  String get addSpray;

  /// No description provided for @spraysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sprays recorded yet.'**
  String get spraysEmpty;

  /// No description provided for @sprayProduct.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get sprayProduct;

  /// No description provided for @sprayActive.
  ///
  /// In en, this message translates to:
  /// **'Active ingredient (on the label)'**
  String get sprayActive;

  /// No description provided for @sprayDose.
  ///
  /// In en, this message translates to:
  /// **'Dose (optional)'**
  String get sprayDose;

  /// No description provided for @sprayWater.
  ///
  /// In en, this message translates to:
  /// **'Water (litres, optional)'**
  String get sprayWater;

  /// No description provided for @sprayArea.
  ///
  /// In en, this message translates to:
  /// **'Area sprayed (acres, optional)'**
  String get sprayArea;

  /// No description provided for @sprayCost.
  ///
  /// In en, this message translates to:
  /// **'Cost (₹, optional)'**
  String get sprayCost;

  /// No description provided for @sprayOperator.
  ///
  /// In en, this message translates to:
  /// **'Sprayed by (optional)'**
  String get sprayOperator;

  /// No description provided for @sprayPhi.
  ///
  /// In en, this message translates to:
  /// **'Days before harvest, PHI (optional)'**
  String get sprayPhi;

  /// No description provided for @sprayTarget.
  ///
  /// In en, this message translates to:
  /// **'For which pest or disease (optional)'**
  String get sprayTarget;

  /// No description provided for @sprayDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sprayDate;

  /// No description provided for @sprayWhichBahar.
  ///
  /// In en, this message translates to:
  /// **'Which bahar? (to check harvest date)'**
  String get sprayWhichBahar;

  /// No description provided for @sprayWarnBannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Banned chemical'**
  String get sprayWarnBannedTitle;

  /// No description provided for @sprayWarnBannedBody.
  ///
  /// In en, this message translates to:
  /// **'This ingredient is banned ({notification}). Do not use it. Ask your local KVK or expert.'**
  String sprayWarnBannedBody(String notification);

  /// No description provided for @sprayWarnRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restricted for this crop'**
  String get sprayWarnRestrictedTitle;

  /// No description provided for @sprayWarnRestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'This ingredient is restricted for this crop ({notification}). Check the label and ask your local expert.'**
  String sprayWarnRestrictedBody(String notification);

  /// No description provided for @sprayWarnPhiTitle.
  ///
  /// In en, this message translates to:
  /// **'Harvest too soon'**
  String get sprayWarnPhiTitle;

  /// No description provided for @sprayWarnPhiBody.
  ///
  /// In en, this message translates to:
  /// **'Harvest is planned before the waiting period ends. Safe to harvest from {date}.'**
  String sprayWarnPhiBody(String date);

  /// No description provided for @fieldLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Field log'**
  String get fieldLogTitle;

  /// No description provided for @addInput.
  ///
  /// In en, this message translates to:
  /// **'Add fertiliser'**
  String get addInput;

  /// No description provided for @logIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Log irrigation'**
  String get logIrrigation;

  /// No description provided for @inputKind.
  ///
  /// In en, this message translates to:
  /// **'What did you apply?'**
  String get inputKind;

  /// No description provided for @inputProduct.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get inputProduct;

  /// No description provided for @inputQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity (optional)'**
  String get inputQuantity;

  /// No description provided for @inputUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get inputUnit;

  /// No description provided for @inputCost.
  ///
  /// In en, this message translates to:
  /// **'Cost (₹, optional)'**
  String get inputCost;

  /// No description provided for @irrigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigationTitle;

  /// No description provided for @irrigationHours.
  ///
  /// In en, this message translates to:
  /// **'Hours (optional)'**
  String get irrigationHours;

  /// No description provided for @irrigationLitres.
  ///
  /// In en, this message translates to:
  /// **'Water in litres (optional)'**
  String get irrigationLitres;

  /// No description provided for @fieldLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Add fertiliser or log irrigation.'**
  String get fieldLogEmpty;

  /// No description provided for @inputLine.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit}'**
  String inputLine(String quantity, String unit);

  /// No description provided for @irrigationHoursLine.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String irrigationHoursLine(String hours);

  /// No description provided for @labourTitle.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get labourTitle;

  /// No description provided for @labourAddDay.
  ///
  /// In en, this message translates to:
  /// **'Add worker day'**
  String get labourAddDay;

  /// No description provided for @labourWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker name'**
  String get labourWorker;

  /// No description provided for @labourTask.
  ///
  /// In en, this message translates to:
  /// **'Work done'**
  String get labourTask;

  /// No description provided for @labourWage.
  ///
  /// In en, this message translates to:
  /// **'Wage (₹)'**
  String get labourWage;

  /// No description provided for @labourAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance paid (₹, optional)'**
  String get labourAdvance;

  /// No description provided for @labourPaidNow.
  ///
  /// In en, this message translates to:
  /// **'Paid in full today'**
  String get labourPaidNow;

  /// No description provided for @labourSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get labourSettled;

  /// No description provided for @labourMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get labourMarkPaid;

  /// No description provided for @labourEmpty.
  ///
  /// In en, this message translates to:
  /// **'No worker days yet. Add one.'**
  String get labourEmpty;

  /// No description provided for @labourTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total owed to workers'**
  String get labourTotalDue;

  /// No description provided for @labourDue.
  ///
  /// In en, this message translates to:
  /// **'Due {amount}'**
  String labourDue(String amount);

  /// No description provided for @harvestTitle.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get harvestTitle;

  /// No description provided for @harvestAdd.
  ///
  /// In en, this message translates to:
  /// **'Add harvest'**
  String get harvestAdd;

  /// No description provided for @harvestKg.
  ///
  /// In en, this message translates to:
  /// **'Quantity (kg)'**
  String get harvestKg;

  /// No description provided for @harvestGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade (optional)'**
  String get harvestGrade;

  /// No description provided for @harvestSize.
  ///
  /// In en, this message translates to:
  /// **'Size (optional)'**
  String get harvestSize;

  /// No description provided for @harvestEmpty.
  ///
  /// In en, this message translates to:
  /// **'No harvest recorded yet. Add a lot.'**
  String get harvestEmpty;

  /// No description provided for @harvestTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {kg} kg'**
  String harvestTotal(String kg);

  /// No description provided for @moreMenu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreMenu;

  /// No description provided for @harvestKgValue.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg'**
  String harvestKgValue(String kg);

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare seasons'**
  String get compareTitle;

  /// No description provided for @compareEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start a bahar and add records to compare seasons.'**
  String get compareEmpty;

  /// No description provided for @compareVs.
  ///
  /// In en, this message translates to:
  /// **'vs {bahar}: {change}'**
  String compareVs(String bahar, String change);

  /// No description provided for @compareMore.
  ///
  /// In en, this message translates to:
  /// **'{amount} more'**
  String compareMore(String amount);

  /// No description provided for @compareLess.
  ///
  /// In en, this message translates to:
  /// **'{amount} less'**
  String compareLess(String amount);

  /// No description provided for @compareSame.
  ///
  /// In en, this message translates to:
  /// **'no change'**
  String get compareSame;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Share spreadsheet'**
  String get exportShare;

  /// No description provided for @exportDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportDate;

  /// No description provided for @exportType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get exportType;

  /// No description provided for @exportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get exportDetails;

  /// No description provided for @exportTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get exportTypeExpense;

  /// No description provided for @exportTypeSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get exportTypeSale;

  /// No description provided for @exportTypeSpray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get exportTypeSpray;

  /// No description provided for @exportTypeInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get exportTypeInput;

  /// No description provided for @exportTypeLabour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get exportTypeLabour;

  /// No description provided for @exportKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get exportKg;

  /// No description provided for @exportSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get exportSharePdf;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BagMitra'**
  String get onboardingWelcome;

  /// No description provided for @onboardingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguage;

  /// No description provided for @onboardingName.
  ///
  /// In en, this message translates to:
  /// **'Your name (optional)'**
  String get onboardingName;

  /// No description provided for @onboardingVillage.
  ///
  /// In en, this message translates to:
  /// **'Village (optional)'**
  String get onboardingVillage;

  /// No description provided for @onboardingTaluka.
  ///
  /// In en, this message translates to:
  /// **'Taluka (optional)'**
  String get onboardingTaluka;

  /// No description provided for @onboardingDistrict.
  ///
  /// In en, this message translates to:
  /// **'District (optional)'**
  String get onboardingDistrict;

  /// No description provided for @onboardingConsentData.
  ///
  /// In en, this message translates to:
  /// **'I agree that BagMitra stores my orchard records to run the app.'**
  String get onboardingConsentData;

  /// No description provided for @onboardingConsentWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send me reminders on WhatsApp (optional).'**
  String get onboardingConsentWhatsapp;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @boundaryWalk.
  ///
  /// In en, this message translates to:
  /// **'Mark boundary by walking'**
  String get boundaryWalk;

  /// No description provided for @boundaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk the boundary'**
  String get boundaryTitle;

  /// No description provided for @boundaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Stand at a corner of the block and tap “Add this corner”. Walk to each corner and repeat. You need at least 3.'**
  String get boundaryHelp;

  /// No description provided for @boundaryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add this corner'**
  String get boundaryAdd;

  /// No description provided for @boundaryUndo.
  ///
  /// In en, this message translates to:
  /// **'Remove last corner'**
  String get boundaryUndo;

  /// No description provided for @boundaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get boundaryDone;

  /// No description provided for @boundaryCorners.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 corner} other{{count} corners}}'**
  String boundaryCorners(int count);

  /// No description provided for @boundaryArea.
  ///
  /// In en, this message translates to:
  /// **'Area about {acres} acres'**
  String boundaryArea(String acres);

  /// No description provided for @boundaryAccuracy.
  ///
  /// In en, this message translates to:
  /// **'±{metres} m'**
  String boundaryAccuracy(String metres);

  /// No description provided for @boundaryServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location (GPS) on your phone.'**
  String get boundaryServiceOff;

  /// No description provided for @boundaryDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location to mark the boundary.'**
  String get boundaryDenied;

  /// No description provided for @boundaryDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked. Allow it in the phone\'s app settings.'**
  String get boundaryDeniedForever;

  /// No description provided for @boundaryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Try again outside.'**
  String get boundaryFailed;

  /// No description provided for @boundaryMarked.
  ///
  /// In en, this message translates to:
  /// **'Boundary marked: {count, plural, =1{1 corner} other{{count} corners}}'**
  String boundaryMarked(int count);

  /// No description provided for @loginTryWithout.
  ///
  /// In en, this message translates to:
  /// **'Try without account'**
  String get loginTryWithout;

  /// No description provided for @localModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline test mode: your data stays on this phone'**
  String get localModeBanner;

  /// No description provided for @testBuildBadge.
  ///
  /// In en, this message translates to:
  /// **'TEST BUILD {sha}'**
  String testBuildBadge(String sha);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sendLogs.
  ///
  /// In en, this message translates to:
  /// **'Send logs'**
  String get sendLogs;

  /// No description provided for @walkthroughSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get walkthroughSkip;

  /// No description provided for @walkthroughNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get walkthroughNext;

  /// No description provided for @walkthroughStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get walkthroughStart;

  /// No description provided for @walkthroughPlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plots and bahar calendar'**
  String get walkthroughPlotsTitle;

  /// No description provided for @walkthroughPlotsBody.
  ///
  /// In en, this message translates to:
  /// **'Add your plots. For each bahar you see a season calendar and a list of tasks.'**
  String get walkthroughPlotsBody;

  /// No description provided for @walkthroughWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather alerts for your plot'**
  String get walkthroughWeatherTitle;

  /// No description provided for @walkthroughWeatherBody.
  ///
  /// In en, this message translates to:
  /// **'See the weather at your plot and get an alert when rain, heat or cold may need your attention.'**
  String get walkthroughWeatherBody;

  /// No description provided for @walkthroughMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Mandi prices across India'**
  String get walkthroughMarketTitle;

  /// No description provided for @walkthroughMarketBody.
  ///
  /// In en, this message translates to:
  /// **'Check recent mandi prices for your crop in markets across India.'**
  String get walkthroughMarketBody;

  /// No description provided for @walkthroughRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your records and accounts'**
  String get walkthroughRecordsTitle;

  /// No description provided for @walkthroughRecordsBody.
  ///
  /// In en, this message translates to:
  /// **'Note sprays, expenses, labour and sales, and see your accounts. Works without internet; records are sent when the network is back.'**
  String get walkthroughRecordsBody;

  /// No description provided for @settingsShowWalkthrough.
  ///
  /// In en, this message translates to:
  /// **'See the app introduction again'**
  String get settingsShowWalkthrough;

  /// No description provided for @buildLabel.
  ///
  /// In en, this message translates to:
  /// **'Test build {sha}'**
  String buildLabel(String sha);

  /// No description provided for @seedOrchard.
  ///
  /// In en, this message translates to:
  /// **'Add sample orchard'**
  String get seedOrchard;

  /// No description provided for @seedOrchardDone.
  ///
  /// In en, this message translates to:
  /// **'Sample orchard added'**
  String get seedOrchardDone;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available on this phone'**
  String get voiceUnavailable;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… tap to stop'**
  String get voiceListening;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get addTask;

  /// No description provided for @taskWhat.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get taskWhat;

  /// No description provided for @taskKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get taskKind;

  /// No description provided for @taskDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get taskDue;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dueTomorrow;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet. Add one with the + button.'**
  String get tasksEmpty;

  /// No description provided for @tasksOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tasksOverdue;

  /// No description provided for @tasksToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tasksToday;

  /// No description provided for @tasksUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get tasksUpcoming;

  /// No description provided for @tasksDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tasksDone;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get noTasksToday;

  /// No description provided for @taskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskOverdue;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'In {n} days'**
  String dueInDays(int n);

  /// No description provided for @editPlot.
  ///
  /// In en, this message translates to:
  /// **'Edit block'**
  String get editPlot;

  /// No description provided for @plotOpenRecords.
  ///
  /// In en, this message translates to:
  /// **'Bahar, sprays and accounts'**
  String get plotOpenRecords;

  /// No description provided for @plotBoundaryNone.
  ///
  /// In en, this message translates to:
  /// **'Boundary not marked yet'**
  String get plotBoundaryNone;

  /// No description provided for @plotCentre.
  ///
  /// In en, this message translates to:
  /// **'Centre point'**
  String get plotCentre;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Season calendar'**
  String get calendarTitle;

  /// No description provided for @calendarIntro.
  ///
  /// In en, this message translates to:
  /// **'Your bahar dates and tasks for the next twelve months, from what you entered.'**
  String get calendarIntro;

  /// No description provided for @calendarMonthEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing dated this month.'**
  String get calendarMonthEmpty;

  /// No description provided for @calendarStagePlanned.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get calendarStagePlanned;

  /// No description provided for @calendarStageDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get calendarStageDone;

  /// No description provided for @calendarOpen.
  ///
  /// In en, this message translates to:
  /// **'Season calendar'**
  String get calendarOpen;

  /// No description provided for @baharCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare bahars'**
  String get baharCompareTitle;

  /// No description provided for @baharCompareIntro.
  ///
  /// In en, this message translates to:
  /// **'Points from published sources to help you weigh each bahar. The decision is yours; sources sometimes disagree.'**
  String get baharCompareIntro;

  /// No description provided for @baharCompareLast.
  ///
  /// In en, this message translates to:
  /// **'Last bahar on this block: {bahar}'**
  String baharCompareLast(String bahar);

  /// No description provided for @baharCompareNoLast.
  ///
  /// In en, this message translates to:
  /// **'No bahar recorded on this block yet.'**
  String get baharCompareNoLast;

  /// No description provided for @baharCompareSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String baharCompareSource(String source);

  /// No description provided for @baharCompareNoPoints.
  ///
  /// In en, this message translates to:
  /// **'No checked information for this bahar yet.'**
  String get baharCompareNoPoints;

  /// No description provided for @baharCompareUse.
  ///
  /// In en, this message translates to:
  /// **'Use this bahar'**
  String get baharCompareUse;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherTitle;

  /// No description provided for @weatherAsOf.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String weatherAsOf(String date);

  /// No description provided for @weatherStale.
  ///
  /// In en, this message translates to:
  /// **'Weather could not be updated; showing the last saved days.'**
  String get weatherStale;

  /// No description provided for @weatherNone.
  ///
  /// In en, this message translates to:
  /// **'No weather yet. It loads when the phone is online.'**
  String get weatherNone;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'{mm} mm rain'**
  String weatherRain(String mm);

  /// No description provided for @weatherSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String weatherSource(String source);

  /// No description provided for @labelInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Label information'**
  String get labelInfoTitle;

  /// No description provided for @labelInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'This is information printed on registered labels (CIB&RC). It is not a recommendation. Read the product label and confirm with your KVK or agriculture officer before any use.'**
  String get labelInfoBanner;

  /// No description provided for @labelInfoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No registered label information is available yet.'**
  String get labelInfoEmpty;

  /// No description provided for @labelInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String labelInfoUpdated(String date);

  /// No description provided for @labelInfoDose.
  ///
  /// In en, this message translates to:
  /// **'Dose on label:'**
  String get labelInfoDose;

  /// No description provided for @labelInfoInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval: {days} days'**
  String labelInfoInterval(String days);

  /// No description provided for @labelInfoPhi.
  ///
  /// In en, this message translates to:
  /// **'PHI: {days} days before harvest'**
  String labelInfoPhi(String days);

  /// No description provided for @labelInfoMaxSprays.
  ///
  /// In en, this message translates to:
  /// **'Max sprays: {count}'**
  String labelInfoMaxSprays(String count);

  /// No description provided for @labelInfoCrop.
  ///
  /// In en, this message translates to:
  /// **'Label crop: {crop}'**
  String labelInfoCrop(String crop);

  /// No description provided for @labelInfoSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {title}'**
  String labelInfoSource(String title);

  /// No description provided for @marketPricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Market prices'**
  String get marketPricesTitle;

  /// No description provided for @marketOpen.
  ///
  /// In en, this message translates to:
  /// **'Market prices'**
  String get marketOpen;

  /// No description provided for @marketScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get marketScopeAll;

  /// No description provided for @marketScopeLocal.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get marketScopeLocal;

  /// No description provided for @marketScopeMajor.
  ///
  /// In en, this message translates to:
  /// **'Major mandis'**
  String get marketScopeMajor;

  /// No description provided for @marketTagLocal.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get marketTagLocal;

  /// No description provided for @marketTagMajor.
  ///
  /// In en, this message translates to:
  /// **'Major mandi'**
  String get marketTagMajor;

  /// No description provided for @marketPerQuintal.
  ///
  /// In en, this message translates to:
  /// **'per quintal'**
  String get marketPerQuintal;

  /// No description provided for @marketRange.
  ///
  /// In en, this message translates to:
  /// **'Min–max: {min} – {max}'**
  String marketRange(String min, String max);

  /// No description provided for @marketVariety.
  ///
  /// In en, this message translates to:
  /// **'Variety: {variety}'**
  String marketVariety(String variety);

  /// No description provided for @marketUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String marketUpdated(String date);

  /// No description provided for @marketStale.
  ///
  /// In en, this message translates to:
  /// **'Prices could not be updated: {reason}'**
  String marketStale(String reason);

  /// No description provided for @marketStaleNoReason.
  ///
  /// In en, this message translates to:
  /// **'Prices could not be updated; showing the last saved list.'**
  String get marketStaleNoReason;

  /// No description provided for @marketEmpty.
  ///
  /// In en, this message translates to:
  /// **'No prices yet. They load when the phone is online and the price source is connected.'**
  String get marketEmpty;

  /// No description provided for @practicesOpen.
  ///
  /// In en, this message translates to:
  /// **'Orchard practices (non-chemical)'**
  String get practicesOpen;

  /// No description provided for @practicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Orchard practices'**
  String get practicesTitle;

  /// No description provided for @practicesSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String practicesSource(String source);

  /// No description provided for @practicesEvidenceOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get practicesEvidenceOfficial;

  /// No description provided for @practicesEvidenceUniversity.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get practicesEvidenceUniversity;

  /// No description provided for @practicesEvidenceResearch.
  ///
  /// In en, this message translates to:
  /// **'Research finding'**
  String get practicesEvidenceResearch;

  /// No description provided for @practicesEvidenceInferred.
  ///
  /// In en, this message translates to:
  /// **'Inferred'**
  String get practicesEvidenceInferred;

  /// No description provided for @practicesGapsTitle.
  ///
  /// In en, this message translates to:
  /// **'No non-chemical practice found yet'**
  String get practicesGapsTitle;

  /// No description provided for @practicesSourcesLine.
  ///
  /// In en, this message translates to:
  /// **'Sources: NHB and Dr. PDKV, Akola. Details under each practice.'**
  String get practicesSourcesLine;

  /// No description provided for @scoutingTitle.
  ///
  /// In en, this message translates to:
  /// **'Scouting log'**
  String get scoutingTitle;

  /// No description provided for @scoutingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add scouting'**
  String get scoutingAdd;

  /// No description provided for @scoutingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scouting recorded yet. Note what you saw on this plot.'**
  String get scoutingEmpty;

  /// No description provided for @scoutingDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get scoutingDate;

  /// No description provided for @scoutingWhat.
  ///
  /// In en, this message translates to:
  /// **'What did you look at?'**
  String get scoutingWhat;

  /// No description provided for @scoutingSeverity.
  ///
  /// In en, this message translates to:
  /// **'How much?'**
  String get scoutingSeverity;

  /// No description provided for @scoutingNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get scoutingNote;

  /// No description provided for @scoutingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo (optional, stays on this phone)'**
  String get scoutingPhoto;

  /// No description provided for @scoutingCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get scoutingCamera;

  /// No description provided for @scoutingGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get scoutingGallery;

  /// No description provided for @scoutingRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get scoutingRemovePhoto;

  /// No description provided for @scoutingPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get the photo. Try again.'**
  String get scoutingPhotoFailed;

  /// No description provided for @scoutingPickOne.
  ///
  /// In en, this message translates to:
  /// **'Choose one'**
  String get scoutingPickOne;

  /// No description provided for @scoutingItemPsylla.
  ///
  /// In en, this message translates to:
  /// **'Psylla'**
  String get scoutingItemPsylla;

  /// No description provided for @scoutingItemLeafMiner.
  ///
  /// In en, this message translates to:
  /// **'Leaf miner'**
  String get scoutingItemLeafMiner;

  /// No description provided for @scoutingItemMitesThrips.
  ///
  /// In en, this message translates to:
  /// **'Mites / thrips'**
  String get scoutingItemMitesThrips;

  /// No description provided for @scoutingItemFruitDrop.
  ///
  /// In en, this message translates to:
  /// **'Fruit drop'**
  String get scoutingItemFruitDrop;

  /// No description provided for @scoutingItemGummosis.
  ///
  /// In en, this message translates to:
  /// **'Gummosis / bark'**
  String get scoutingItemGummosis;

  /// No description provided for @scoutingItemDieBack.
  ///
  /// In en, this message translates to:
  /// **'Die-back'**
  String get scoutingItemDieBack;

  /// No description provided for @scoutingItemOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get scoutingItemOther;

  /// No description provided for @scoutingSeverityNone.
  ///
  /// In en, this message translates to:
  /// **'Not seen'**
  String get scoutingSeverityNone;

  /// No description provided for @scoutingSeverityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get scoutingSeverityLow;

  /// No description provided for @scoutingSeverityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get scoutingSeverityMedium;

  /// No description provided for @scoutingSeverityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get scoutingSeverityHigh;

  /// No description provided for @irrigationOpen.
  ///
  /// In en, this message translates to:
  /// **'Irrigation guide (ओलित तक्ता)'**
  String get irrigationOpen;

  /// No description provided for @irrigationGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Irrigation guide'**
  String get irrigationGuideTitle;

  /// No description provided for @irrigationCaveat.
  ///
  /// In en, this message translates to:
  /// **'Amounts depend on your soil, the tree\'s canopy and the weather. Check with your KVK before you change your watering.'**
  String get irrigationCaveat;

  /// No description provided for @irrigationCropLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get irrigationCropLabel;

  /// No description provided for @irrigationAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Tree age'**
  String get irrigationAgeLabel;

  /// No description provided for @irrigationPlanted.
  ///
  /// In en, this message translates to:
  /// **'Planted in {year}: about {years} years old'**
  String irrigationPlanted(String year, String years);

  /// No description provided for @irrigationNoPlantingYear.
  ///
  /// In en, this message translates to:
  /// **'Planting year not entered for this block. Choose the tree age.'**
  String get irrigationNoPlantingYear;

  /// No description provided for @irrigationNoRows.
  ///
  /// In en, this message translates to:
  /// **'No figure in the sources for this tree age yet.'**
  String get irrigationNoRows;

  /// No description provided for @irrigationStagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Flowering, fruit and bahar rest'**
  String get irrigationStagesTitle;

  /// No description provided for @irrigationGapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Not found in the sources yet'**
  String get irrigationGapsTitle;

  /// No description provided for @irrigationSourcesLine.
  ///
  /// In en, this message translates to:
  /// **'Sources: NHB, Dr. PDKV Akola and published citrus research. Details under each point.'**
  String get irrigationSourcesLine;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sarkari Sandesh'**
  String get feedTitle;

  /// No description provided for @feedOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Official GRs, schemes and last dates'**
  String get feedOpenHint;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @feedFilterOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get feedFilterOfficial;

  /// No description provided for @feedFilterSchemes.
  ///
  /// In en, this message translates to:
  /// **'Schemes'**
  String get feedFilterSchemes;

  /// No description provided for @feedFilterDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get feedFilterDeadlines;

  /// No description provided for @feedFilterNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get feedFilterNews;

  /// No description provided for @feedBadgeOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get feedBadgeOfficial;

  /// No description provided for @feedGrNumber.
  ///
  /// In en, this message translates to:
  /// **'GR {number}'**
  String feedGrNumber(String number);

  /// No description provided for @feedBadgeNews.
  ///
  /// In en, this message translates to:
  /// **'News — not official'**
  String get feedBadgeNews;

  /// No description provided for @feedReplacedBy.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn. Replaced by {replacement}'**
  String feedReplacedBy(String replacement);

  /// No description provided for @feedExpired.
  ///
  /// In en, this message translates to:
  /// **'No longer valid (ended {date})'**
  String feedExpired(String date);

  /// No description provided for @feedMayBeEligible.
  ///
  /// In en, this message translates to:
  /// **'You may be eligible because {reason}'**
  String feedMayBeEligible(String reason);

  /// No description provided for @feedFooter.
  ///
  /// In en, this message translates to:
  /// **'Check the official GR/portal before acting.'**
  String get feedFooter;

  /// No description provided for @feedDeadline.
  ///
  /// In en, this message translates to:
  /// **'Last date: {date}'**
  String feedDeadline(String date);

  /// No description provided for @feedUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String feedUpdated(String date);

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. They load when the phone is online.'**
  String get feedEmpty;

  /// No description provided for @feedRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get feedRemindMe;

  /// No description provided for @feedReminderAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to your tasks for {date}'**
  String feedReminderAdded(String date);

  /// No description provided for @feedReminderExists.
  ///
  /// In en, this message translates to:
  /// **'Already in your tasks'**
  String get feedReminderExists;

  /// No description provided for @feedShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get feedShare;

  /// No description provided for @feedCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy source link'**
  String get feedCopyLink;

  /// No description provided for @feedLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Open it in your browser.'**
  String get feedLinkCopied;

  /// No description provided for @feedSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {url}'**
  String feedSource(String url);

  /// No description provided for @feedNotFound.
  ///
  /// In en, this message translates to:
  /// **'This message is no longer in the saved list.'**
  String get feedNotFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
