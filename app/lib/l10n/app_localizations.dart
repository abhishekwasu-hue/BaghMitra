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

  /// No description provided for @homeWeatherNeedsLocation.
  ///
  /// In en, this message translates to:
  /// **'Add the block\'s location to see its weather here.'**
  String get homeWeatherNeedsLocation;

  /// No description provided for @minTemperature.
  ///
  /// In en, this message translates to:
  /// **'Min {degrees}°'**
  String minTemperature(int degrees);

  /// No description provided for @homeNextStage.
  ///
  /// In en, this message translates to:
  /// **'Next: {stage} in {days} days'**
  String homeNextStage(String stage, int days);

  /// No description provided for @homeHarvestMonth.
  ///
  /// In en, this message translates to:
  /// **'Harvest {month}'**
  String homeHarvestMonth(String month);

  /// No description provided for @homeStageAddDates.
  ///
  /// In en, this message translates to:
  /// **'Write the stage dates to see the days here.'**
  String get homeStageAddDates;

  /// No description provided for @homeOpenMarket.
  ///
  /// In en, this message translates to:
  /// **'See market prices'**
  String get homeOpenMarket;

  /// No description provided for @choosePlot.
  ///
  /// In en, this message translates to:
  /// **'Choose a block'**
  String get choosePlot;

  /// No description provided for @onboardingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Please tap Continue again.'**
  String get onboardingSaveFailed;

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
  /// **'Pest/disease photo'**
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
  /// **'Your entries are saved on this phone; they will sync when the network is back.'**
  String get offlineBanner;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String pendingSync(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Your records are safe on this phone. The app will try sending again on its own.'**
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
  /// **'Please try Google sign-in again; check the internet.'**
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
  /// **'Enter the latest 6-digit OTP from the SMS'**
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
  /// **'Add your first orchard block'**
  String get plotsEmptyTitle;

  /// No description provided for @plotsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Each block gets a bahar calendar and daily tasks.'**
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
  /// **'Saved.'**
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
  /// **'Plan your first bahar'**
  String get baharEmptyTitle;

  /// No description provided for @baharEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a bahar. Each stage shows a suggested window from public sources; every date stays yours to change.'**
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
  /// **'Open alerts appear here'**
  String get adminNoAlerts;

  /// No description provided for @adminNoCards.
  ///
  /// In en, this message translates to:
  /// **'Cards appear here once added'**
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

  /// No description provided for @adminFeed.
  ///
  /// In en, this message translates to:
  /// **'Govt feed'**
  String get adminFeed;

  /// No description provided for @adminFeedQueue.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get adminFeedQueue;

  /// No description provided for @adminFeedUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get adminFeedUpload;

  /// No description provided for @adminFeedSources.
  ///
  /// In en, this message translates to:
  /// **'Feed sources'**
  String get adminFeedSources;

  /// No description provided for @adminFeedStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get adminFeedStatusInReview;

  /// No description provided for @adminFeedStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get adminFeedStatusDraft;

  /// No description provided for @adminFeedStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminFeedStatusPublished;

  /// No description provided for @adminFeedStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get adminFeedStatusWithdrawn;

  /// No description provided for @adminFeedNoItems.
  ///
  /// In en, this message translates to:
  /// **'This list is empty'**
  String get adminFeedNoItems;

  /// No description provided for @adminFeedApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminFeedApproved;

  /// No description provided for @adminFeedIssueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} check issues'**
  String adminFeedIssueCount(int count);

  /// No description provided for @adminFeedAiOff.
  ///
  /// In en, this message translates to:
  /// **'AI is still to be set up'**
  String get adminFeedAiOff;

  /// No description provided for @adminFeedSourceLink.
  ///
  /// In en, this message translates to:
  /// **'Source document'**
  String get adminFeedSourceLink;

  /// No description provided for @adminFeedReplacedByValue.
  ///
  /// In en, this message translates to:
  /// **'Replaced by {id}'**
  String adminFeedReplacedByValue(String id);

  /// No description provided for @adminFeedWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get adminFeedWithdraw;

  /// No description provided for @adminFeedAiDraft.
  ///
  /// In en, this message translates to:
  /// **'AI draft'**
  String get adminFeedAiDraft;

  /// No description provided for @adminFeedCheckIssues.
  ///
  /// In en, this message translates to:
  /// **'Output-check issues'**
  String get adminFeedCheckIssues;

  /// No description provided for @adminFeedNoIssues.
  ///
  /// In en, this message translates to:
  /// **'All checks passed'**
  String get adminFeedNoIssues;

  /// No description provided for @adminFeedTextPreview.
  ///
  /// In en, this message translates to:
  /// **'Extracted text'**
  String get adminFeedTextPreview;

  /// No description provided for @adminFeedTexts.
  ///
  /// In en, this message translates to:
  /// **'Title and summary'**
  String get adminFeedTexts;

  /// No description provided for @adminFeedDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get adminFeedDates;

  /// No description provided for @adminFeedDeadline.
  ///
  /// In en, this message translates to:
  /// **'Last date'**
  String get adminFeedDeadline;

  /// No description provided for @adminFeedPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get adminFeedPayment;

  /// No description provided for @adminFeedValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get adminFeedValidFrom;

  /// No description provided for @adminFeedValidTo.
  ///
  /// In en, this message translates to:
  /// **'Valid to'**
  String get adminFeedValidTo;

  /// No description provided for @adminFeedDatesNote.
  ///
  /// In en, this message translates to:
  /// **'Dates are output-checked against the source text. Saving a change to a published item sends it back to review.'**
  String get adminFeedDatesNote;

  /// No description provided for @adminFeedPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get adminFeedPickDate;

  /// No description provided for @adminFeedClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get adminFeedClearDate;

  /// No description provided for @adminFeedSaveDates.
  ///
  /// In en, this message translates to:
  /// **'Save dates'**
  String get adminFeedSaveDates;

  /// No description provided for @adminFeedCardNew.
  ///
  /// In en, this message translates to:
  /// **'Scheme card'**
  String get adminFeedCardNew;

  /// No description provided for @adminFeedCardNote.
  ///
  /// In en, this message translates to:
  /// **'Each field: the value as written in the document with its page, or \"Blank in document\".'**
  String get adminFeedCardNote;

  /// No description provided for @adminFeedNotStated.
  ///
  /// In en, this message translates to:
  /// **'Blank in document'**
  String get adminFeedNotStated;

  /// No description provided for @adminFeedCardValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get adminFeedCardValue;

  /// No description provided for @adminFeedCardPage.
  ///
  /// In en, this message translates to:
  /// **'Page (e.g. p. 2)'**
  String get adminFeedCardPage;

  /// No description provided for @adminFeedSaveCard.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get adminFeedSaveCard;

  /// No description provided for @adminFeedCardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fill at least one field or mark it \"Blank in document\".'**
  String get adminFeedCardEmpty;

  /// No description provided for @adminFeedFullText.
  ///
  /// In en, this message translates to:
  /// **'Stored text (what the output check reads):'**
  String get adminFeedFullText;

  /// No description provided for @adminFeedTextTruncated.
  ///
  /// In en, this message translates to:
  /// **'Only the first 200 KB are shown; the stored text is longer.'**
  String get adminFeedTextTruncated;

  /// No description provided for @adminFeedCard.
  ///
  /// In en, this message translates to:
  /// **'Scheme card v{version}'**
  String adminFeedCard(int version);

  /// No description provided for @adminFeedTargets.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get adminFeedTargets;

  /// No description provided for @adminFeedHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get adminFeedHistory;

  /// No description provided for @adminFeedHasText.
  ///
  /// In en, this message translates to:
  /// **'Text is stored (used by the output check and the AI draft).'**
  String get adminFeedHasText;

  /// No description provided for @adminFeedNoText.
  ///
  /// In en, this message translates to:
  /// **'This needs usable text: upload again with the text pasted, or accept the issues with a comment.'**
  String get adminFeedNoText;

  /// No description provided for @adminFeedUnusedText.
  ///
  /// In en, this message translates to:
  /// **'Text set aside (broken text layer or OCR):'**
  String get adminFeedUnusedText;

  /// No description provided for @adminFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminFeedTitle;

  /// No description provided for @adminFeedSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary (2 lines)'**
  String get adminFeedSummary;

  /// No description provided for @adminFeedSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminFeedSave;

  /// No description provided for @adminFeedBadNumber.
  ///
  /// In en, this message translates to:
  /// **'Hectares must be numbers.'**
  String get adminFeedBadNumber;

  /// No description provided for @adminFeedTargetsNote.
  ///
  /// In en, this message translates to:
  /// **'Empty fields mean any. Matching only ever says \"may be eligible\".'**
  String get adminFeedTargetsNote;

  /// No description provided for @adminFeedDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get adminFeedDistrict;

  /// No description provided for @adminFeedCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get adminFeedCrop;

  /// No description provided for @adminFeedMinHa.
  ///
  /// In en, this message translates to:
  /// **'Min ha'**
  String get adminFeedMinHa;

  /// No description provided for @adminFeedMaxHa.
  ///
  /// In en, this message translates to:
  /// **'Max ha'**
  String get adminFeedMaxHa;

  /// No description provided for @adminFeedRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminFeedRemove;

  /// No description provided for @adminFeedAddTarget.
  ///
  /// In en, this message translates to:
  /// **'Add target'**
  String get adminFeedAddTarget;

  /// No description provided for @adminFeedSaveTargets.
  ///
  /// In en, this message translates to:
  /// **'Save targets'**
  String get adminFeedSaveTargets;

  /// No description provided for @adminFeedAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept open check issues?'**
  String get adminFeedAcceptTitle;

  /// No description provided for @adminFeedAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'This item has {count} open check issues. Approve it anyway only with a comment saying why.'**
  String adminFeedAcceptBody(int count);

  /// No description provided for @adminFeedComment.
  ///
  /// In en, this message translates to:
  /// **'Comment (why)'**
  String get adminFeedComment;

  /// No description provided for @adminFeedCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminFeedCancel;

  /// No description provided for @adminFeedAcceptApprove.
  ///
  /// In en, this message translates to:
  /// **'Accept and approve'**
  String get adminFeedAcceptApprove;

  /// No description provided for @adminFeedWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw item'**
  String get adminFeedWithdrawTitle;

  /// No description provided for @adminFeedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminFeedReason;

  /// No description provided for @adminFeedReplacedBy.
  ///
  /// In en, this message translates to:
  /// **'Replaced by'**
  String get adminFeedReplacedBy;

  /// No description provided for @adminFeedNoReplacement.
  ///
  /// In en, this message translates to:
  /// **'Withdraw only'**
  String get adminFeedNoReplacement;

  /// No description provided for @adminFeedRequiredMissing.
  ///
  /// In en, this message translates to:
  /// **'Source key, document URL and published date are required.'**
  String get adminFeedRequiredMissing;

  /// No description provided for @adminFeedBadDate.
  ///
  /// In en, this message translates to:
  /// **'Write dates as YYYY-MM-DD.'**
  String get adminFeedBadDate;

  /// No description provided for @adminFeedCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {status}, {count} check issues'**
  String adminFeedCreated(String status, int count);

  /// No description provided for @adminFeedDateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get adminFeedDateHint;

  /// No description provided for @adminFeedUploadNote.
  ///
  /// In en, this message translates to:
  /// **'Choose the GR document (the server keeps its hash and reads its text) and / or paste the text copied from it (pasted text wins). The official URL is always needed.'**
  String get adminFeedUploadNote;

  /// No description provided for @adminFeedPickDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose document (PDF or HTML)'**
  String get adminFeedPickDocument;

  /// No description provided for @adminFeedNoDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose a document'**
  String get adminFeedNoDocument;

  /// No description provided for @adminFeedDocument.
  ///
  /// In en, this message translates to:
  /// **'{name} · {kb} KB'**
  String adminFeedDocument(String name, int kb);

  /// No description provided for @adminFeedTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The document is larger than {mb} MB.'**
  String adminFeedTooLarge(int mb);

  /// No description provided for @adminFeedBadType.
  ///
  /// In en, this message translates to:
  /// **'Only .pdf, .html or .htm files.'**
  String get adminFeedBadType;

  /// No description provided for @adminFeedExtraction.
  ///
  /// In en, this message translates to:
  /// **'Extraction result'**
  String get adminFeedExtraction;

  /// No description provided for @adminFeedSourceKey.
  ///
  /// In en, this message translates to:
  /// **'Source key'**
  String get adminFeedSourceKey;

  /// No description provided for @adminFeedPublishedAt.
  ///
  /// In en, this message translates to:
  /// **'Published on'**
  String get adminFeedPublishedAt;

  /// No description provided for @adminFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Document URL'**
  String get adminFeedUrl;

  /// No description provided for @adminFeedExternalId.
  ///
  /// In en, this message translates to:
  /// **'External ID (GR code)'**
  String get adminFeedExternalId;

  /// No description provided for @adminFeedGrNumber.
  ///
  /// In en, this message translates to:
  /// **'GR number'**
  String get adminFeedGrNumber;

  /// No description provided for @adminFeedDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get adminFeedDepartment;

  /// No description provided for @adminFeedPastedText.
  ///
  /// In en, this message translates to:
  /// **'Text from the document (pasted)'**
  String get adminFeedPastedText;

  /// No description provided for @adminFeedSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send to review'**
  String get adminFeedSubmit;

  /// No description provided for @adminFeedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open item'**
  String get adminFeedOpen;

  /// No description provided for @adminFeedTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get adminFeedTerms;

  /// No description provided for @adminFeedTermsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get adminFeedTermsUnknown;

  /// No description provided for @adminFeedTermsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get adminFeedTermsAllowed;

  /// No description provided for @adminFeedTermsDisallowed.
  ///
  /// In en, this message translates to:
  /// **'Disallowed'**
  String get adminFeedTermsDisallowed;

  /// No description provided for @adminFeedTermsNote.
  ///
  /// In en, this message translates to:
  /// **'Note (what you read)'**
  String get adminFeedTermsNote;

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
  /// **'Add your first expense or sale.'**
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
  /// **'Record your first spray here.'**
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

  /// No description provided for @sprayActiveType.
  ///
  /// In en, this message translates to:
  /// **'Type (fungicide, insecticide ...)'**
  String get sprayActiveType;

  /// No description provided for @sprayActivePick.
  ///
  /// In en, this message translates to:
  /// **'Choose from the list'**
  String get sprayActivePick;

  /// No description provided for @sprayActiveOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sprayActiveOther;

  /// No description provided for @sprayActiveOtherHelp.
  ///
  /// In en, this message translates to:
  /// **'Write the name as printed on the label.'**
  String get sprayActiveOtherHelp;

  /// No description provided for @sprayActiveSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get sprayActiveSearch;

  /// No description provided for @sprayActiveNoMatch.
  ///
  /// In en, this message translates to:
  /// **'To write another name, choose Other.'**
  String get sprayActiveNoMatch;

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
  /// **'Outside the approved list'**
  String get sprayWarnBannedTitle;

  /// No description provided for @sprayWarnBannedBody.
  ///
  /// In en, this message translates to:
  /// **'This ingredient is outside the government\'s approved list ({notification}). See the label information for registered options.'**
  String sprayWarnBannedBody(String notification);

  /// No description provided for @sprayWarnRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Outside the approved list for this crop'**
  String get sprayWarnRestrictedTitle;

  /// No description provided for @sprayWarnRestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'For this crop, this ingredient is outside the approved list ({notification}). See the label information.'**
  String sprayWarnRestrictedBody(String notification);

  /// No description provided for @sprayWarnPhiTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting period'**
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
  /// **'Add your first fertiliser or irrigation entry.'**
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
  /// **'Add your first worker day.'**
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
  /// **'Record your first harvest lot.'**
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
  /// **'same'**
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

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @profileConsentDataNote.
  ///
  /// In en, this message translates to:
  /// **'This is needed so the app can save and back up your records. It cannot be turned off here.'**
  String get profileConsentDataNote;

  /// No description provided for @profilePhoneSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You sign in with this number.'**
  String get profilePhoneSignedIn;

  /// No description provided for @profileAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add mobile number (optional)'**
  String get profileAddPhone;

  /// No description provided for @profilePhoneContactOnly.
  ///
  /// In en, this message translates to:
  /// **'Only so we can contact you. You sign in with Google, as before.'**
  String get profilePhoneContactOnly;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get profileSaved;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your records stay on this phone. Sign in again to see them.'**
  String get profileSignOutBody;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profilePrivacy;

  /// No description provided for @profilePrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy the link, then open it in your browser'**
  String get profilePrivacyHint;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account and data'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get profileDeleteTitle;

  /// Account deletion confirmation; {word} is the word the grower must type.
  ///
  /// In en, this message translates to:
  /// **'All your records, photos and history are erased from the server and from this phone, and you are signed out. This is permanent. To confirm, type {word}.'**
  String profileDeleteBody(String word);

  /// No description provided for @profileDeleteWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get profileDeleteWord;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete for ever'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a while: deleting needs the internet and the server. All your data is still kept.'**
  String get profileDeleteFailed;

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
  /// **'Please try again in an open place to get your location.'**
  String get boundaryFailed;

  /// No description provided for @boundaryMarked.
  ///
  /// In en, this message translates to:
  /// **'Boundary marked: {count, plural, =1{1 corner} other{{count} corners}}'**
  String boundaryMarked(int count);

  /// No description provided for @loginTryWithout.
  ///
  /// In en, this message translates to:
  /// **'Try the app first'**
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

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available — download'**
  String get updateAvailable;

  /// No description provided for @updateDismiss.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get updateDismiss;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Please update the app'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Download and install the new version to keep using BagMitra.'**
  String get updateRequiredBody;

  /// No description provided for @updateLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Paste it in the browser to download: {url}'**
  String updateLinkCopied(String url);

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {name} ({code})'**
  String settingsVersion(String name, String code);

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
  /// **'See the weather at your plot and get an alert when rain or heat may need your attention.'**
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
  /// **'Note sprays, expenses, labour and sales, and see your accounts. Works offline too; records are sent when the network is back.'**
  String get walkthroughRecordsBody;

  /// No description provided for @settingsShowWalkthrough.
  ///
  /// In en, this message translates to:
  /// **'See the app introduction again'**
  String get settingsShowWalkthrough;

  /// No description provided for @settingsPhotoMobileData.
  ///
  /// In en, this message translates to:
  /// **'Back up photos on mobile data'**
  String get settingsPhotoMobileData;

  /// No description provided for @settingsPhotoMobileDataHint.
  ///
  /// In en, this message translates to:
  /// **'Scouting and bill photos are backed up on Wi-Fi. Turn this on to use mobile data too.'**
  String get settingsPhotoMobileDataHint;

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
  /// **'Please type here; voice typing works on phones that support it'**
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
  /// **'Add your first task with the + button.'**
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
  /// **'Today is clear'**
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
  /// **'Mark the boundary'**
  String get plotBoundaryNone;

  /// No description provided for @plotCentre.
  ///
  /// In en, this message translates to:
  /// **'Centre point'**
  String get plotCentre;

  /// No description provided for @plotLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get plotLocation;

  /// No description provided for @plotPointCapture.
  ///
  /// In en, this message translates to:
  /// **'I am in the orchard — take location'**
  String get plotPointCapture;

  /// No description provided for @plotPointWhy.
  ///
  /// In en, this message translates to:
  /// **'For this block\'s weather and alerts. Read once, only now.'**
  String get plotPointWhy;

  /// No description provided for @plotPointReading.
  ///
  /// In en, this message translates to:
  /// **'Taking location…'**
  String get plotPointReading;

  /// No description provided for @plotPointTake.
  ///
  /// In en, this message translates to:
  /// **'Take location'**
  String get plotPointTake;

  /// No description provided for @plotPointRetake.
  ///
  /// In en, this message translates to:
  /// **'Take location again'**
  String get plotPointRetake;

  /// No description provided for @plotPointDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location to save where this block is.'**
  String get plotPointDenied;

  /// No description provided for @plotPointOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get plotPointOpenSettings;

  /// No description provided for @plotPointTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get plotPointTryAgain;

  /// No description provided for @plotPointLater.
  ///
  /// In en, this message translates to:
  /// **'Save the block now; take the location any time later.'**
  String get plotPointLater;

  /// No description provided for @boundaryWalkOptional.
  ///
  /// In en, this message translates to:
  /// **'Walk the boundary (optional)'**
  String get boundaryWalkOptional;

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
  /// **'This month is clear.'**
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
  /// **'Record this block\'s first bahar to see it here.'**
  String get baharCompareNoLast;

  /// No description provided for @baharCompareSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String baharCompareSource(String source);

  /// No description provided for @baharCompareNoPoints.
  ///
  /// In en, this message translates to:
  /// **'Checked information for this bahar appears here once it is ready.'**
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
  /// **'Showing the last saved days; the weather updates on the next successful load.'**
  String get weatherStale;

  /// No description provided for @weatherNone.
  ///
  /// In en, this message translates to:
  /// **'Weather loads when the phone is online.'**
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

  /// No description provided for @alertSwitchOff.
  ///
  /// In en, this message translates to:
  /// **'Turn this alert off'**
  String get alertSwitchOff;

  /// No description provided for @alertSwitchOn.
  ///
  /// In en, this message translates to:
  /// **'Turn this alert on'**
  String get alertSwitchOn;

  /// No description provided for @alertTypeOff.
  ///
  /// In en, this message translates to:
  /// **'{name} alert off'**
  String alertTypeOff(String name);

  /// No description provided for @alertThisOff.
  ///
  /// In en, this message translates to:
  /// **'This alert is off'**
  String get alertThisOff;

  /// No description provided for @alertNameHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get alertNameHeat;

  /// No description provided for @alertNamePsylla.
  ///
  /// In en, this message translates to:
  /// **'Psylla'**
  String get alertNamePsylla;

  /// No description provided for @alertNameHail.
  ///
  /// In en, this message translates to:
  /// **'Hail and storm'**
  String get alertNameHail;

  /// No description provided for @alertNameWind.
  ///
  /// In en, this message translates to:
  /// **'Strong wind'**
  String get alertNameWind;

  /// No description provided for @alertNameHeavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get alertNameHeavyRain;

  /// No description provided for @alertNameUnseasonalRain.
  ///
  /// In en, this message translates to:
  /// **'Unseasonal rain'**
  String get alertNameUnseasonalRain;

  /// No description provided for @alertNameColdWave.
  ///
  /// In en, this message translates to:
  /// **'Cold wave'**
  String get alertNameColdWave;

  /// No description provided for @alertNameHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humid weather'**
  String get alertNameHumidity;

  /// No description provided for @weatherForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather forecast'**
  String get weatherForecastTitle;

  /// No description provided for @weatherForecastNext.
  ///
  /// In en, this message translates to:
  /// **'Next {days} days'**
  String weatherForecastNext(String days);

  /// No description provided for @weatherColDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get weatherColDay;

  /// No description provided for @weatherColTemp.
  ///
  /// In en, this message translates to:
  /// **'Temp.'**
  String get weatherColTemp;

  /// No description provided for @weatherColRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherColRain;

  /// No description provided for @weatherColWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherColWind;

  /// No description provided for @weatherColHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherColHumidity;

  /// No description provided for @weatherUnitTemp.
  ///
  /// In en, this message translates to:
  /// **'max/min'**
  String get weatherUnitTemp;

  /// No description provided for @weatherUnitRain.
  ///
  /// In en, this message translates to:
  /// **'mm/%'**
  String get weatherUnitRain;

  /// No description provided for @weatherUnitWind.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get weatherUnitWind;

  /// No description provided for @weatherLegendRain.
  ///
  /// In en, this message translates to:
  /// **'Rain likely'**
  String get weatherLegendRain;

  /// No description provided for @weatherLegendHeat.
  ///
  /// In en, this message translates to:
  /// **'{deg}° and above'**
  String weatherLegendHeat(String deg);

  /// No description provided for @weatherSkyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get weatherSkyClear;

  /// No description provided for @weatherSkyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherSkyCloudy;

  /// No description provided for @weatherSkyRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherSkyRain;

  /// No description provided for @weatherSkyStorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherSkyStorm;

  /// No description provided for @weatherNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get weatherNowLabel;

  /// No description provided for @weatherReadingAt.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String weatherReadingAt(String time);

  /// No description provided for @weatherTodayMax.
  ///
  /// In en, this message translates to:
  /// **'Today\'s max {degrees}°'**
  String weatherTodayMax(int degrees);

  /// No description provided for @weatherTodayMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s max'**
  String get weatherTodayMaxLabel;

  /// No description provided for @weatherSkyClearNight.
  ///
  /// In en, this message translates to:
  /// **'Clear night'**
  String get weatherSkyClearNight;

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
  /// **'Registered label information appears here once it is available.'**
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

  /// No description provided for @marketTrendOpen.
  ///
  /// In en, this message translates to:
  /// **'Price trend'**
  String get marketTrendOpen;

  /// No description provided for @marketTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Price trend: {market}'**
  String marketTrendTitle(String market);

  /// No description provided for @marketTrendRange15.
  ///
  /// In en, this message translates to:
  /// **'15 days'**
  String get marketTrendRange15;

  /// No description provided for @marketTrendRange30.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get marketTrendRange30;

  /// No description provided for @marketTrendRange90.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get marketTrendRange90;

  /// No description provided for @marketTrendHigh.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get marketTrendHigh;

  /// No description provided for @marketTrendLow.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get marketTrendLow;

  /// No description provided for @marketTrendChange15.
  ///
  /// In en, this message translates to:
  /// **'Since 15 days'**
  String get marketTrendChange15;

  /// No description provided for @marketTrendChange30.
  ///
  /// In en, this message translates to:
  /// **'Since 1 month'**
  String get marketTrendChange30;

  /// No description provided for @marketTrendHint.
  ///
  /// In en, this message translates to:
  /// **'Slide a finger on the chart to see each day’s price.'**
  String get marketTrendHint;

  /// No description provided for @marketTrendCollecting.
  ///
  /// In en, this message translates to:
  /// **'Prices are saved every day; the chart fills in day by day.'**
  String get marketTrendCollecting;

  /// No description provided for @marketTrendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Price trend, {range}: highest {high}, lowest {low}, latest {latest} per quintal'**
  String marketTrendSemantics(
    String range,
    String high,
    String low,
    String latest,
  );

  /// No description provided for @marketStale.
  ///
  /// In en, this message translates to:
  /// **'{reason, select, source_not_configured{Mandi prices are coming soon.} other{Showing the last saved prices; they update on the next successful load.}}'**
  String marketStale(String reason);

  /// No description provided for @marketStaleNoReason.
  ///
  /// In en, this message translates to:
  /// **'Showing the last saved list; prices update on the next successful load.'**
  String get marketStaleNoReason;

  /// No description provided for @marketEmpty.
  ///
  /// In en, this message translates to:
  /// **'Prices load when the phone is online and the price source is connected.'**
  String get marketEmpty;

  /// No description provided for @marketCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get marketCrop;

  /// No description provided for @marketCropSoon.
  ///
  /// In en, this message translates to:
  /// **'{crop} prices will show here soon. Mandi prices update on their own every 6 hours.'**
  String marketCropSoon(String crop);

  /// No description provided for @marketSearchOpen.
  ///
  /// In en, this message translates to:
  /// **'Find a mandi'**
  String get marketSearchOpen;

  /// No description provided for @marketSearchClose.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get marketSearchClose;

  /// No description provided for @marketSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Mandi, district or state'**
  String get marketSearchHint;

  /// No description provided for @marketSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get marketSearchClear;

  /// No description provided for @marketSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Try another mandi, district or state name instead of “{query}”.'**
  String marketSearchEmpty(String query);

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
  /// **'A non-chemical practice is still to be found for these'**
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
  /// **'Record your first scouting: note what you saw on this plot.'**
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
  /// **'Photo (optional)'**
  String get scoutingPhoto;

  /// No description provided for @scoutingPhotoBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Photo backed up'**
  String get scoutingPhotoBackedUp;

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
  /// **'Please take the photo again.'**
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
  /// **'Zero'**
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
  /// **'Amounts depend on your soil, the tree\'s canopy and the weather.'**
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
  /// **'Choose the tree age, or add the planting year to this block.'**
  String get irrigationNoPlantingYear;

  /// No description provided for @irrigationNoRows.
  ///
  /// In en, this message translates to:
  /// **'A figure for this tree age is still to be found in the sources.'**
  String get irrigationNoRows;

  /// No description provided for @irrigationStagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Flowering, fruit and bahar rest'**
  String get irrigationStagesTitle;

  /// No description provided for @irrigationGapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Still to be found in the sources'**
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

  /// No description provided for @feedFilterKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get feedFilterKnowledge;

  /// No description provided for @feedBadgeKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge article'**
  String get feedBadgeKnowledge;

  /// No description provided for @feedKnowledgeByline.
  ///
  /// In en, this message translates to:
  /// **'BagMitra · written by AI only from checked cards and their open sources; every number checked against the source'**
  String get feedKnowledgeByline;

  /// No description provided for @feedKnowledgeOpenCard.
  ///
  /// In en, this message translates to:
  /// **'Open the card'**
  String get feedKnowledgeOpenCard;

  /// No description provided for @feedKnowledgeNote.
  ///
  /// In en, this message translates to:
  /// **'General information. Ask your KVK or agriculture officer before acting.'**
  String get feedKnowledgeNote;

  /// No description provided for @feedBadgeOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get feedBadgeOfficial;

  /// No description provided for @feedLevelCentral.
  ///
  /// In en, this message translates to:
  /// **'Government of India'**
  String get feedLevelCentral;

  /// No description provided for @feedLevelState.
  ///
  /// In en, this message translates to:
  /// **'Government of Maharashtra'**
  String get feedLevelState;

  /// No description provided for @feedArticleByline.
  ///
  /// In en, this message translates to:
  /// **'BagMitra news desk · written by AI from official government sources'**
  String get feedArticleByline;

  /// No description provided for @feedArticleKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'Key points'**
  String get feedArticleKeyPoints;

  /// No description provided for @feedArticleFacts.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get feedArticleFacts;

  /// No description provided for @feedArticleKeyDates.
  ///
  /// In en, this message translates to:
  /// **'Key dates'**
  String get feedArticleKeyDates;

  /// No description provided for @feedArticleSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get feedArticleSources;

  /// No description provided for @feedGrNumber.
  ///
  /// In en, this message translates to:
  /// **'GR {number}'**
  String feedGrNumber(String number);

  /// No description provided for @feedBadgeNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get feedBadgeNews;

  /// No description provided for @feedReplacedBy.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn. Replaced by {replacement}'**
  String feedReplacedBy(String replacement);

  /// No description provided for @feedExpired.
  ///
  /// In en, this message translates to:
  /// **'Ended on {date}'**
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
  /// **'Messages load when the phone is online.'**
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
  /// **'This message was removed from the saved list.'**
  String get feedNotFound;

  /// No description provided for @feedUnseen.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get feedUnseen;

  /// No description provided for @feedThreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reports'**
  String feedThreadCount(String count);

  /// No description provided for @feedThreadLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest: {date}'**
  String feedThreadLatest(String date);

  /// No description provided for @feedThreadTimeline.
  ///
  /// In en, this message translates to:
  /// **'All reports, oldest first'**
  String get feedThreadTimeline;

  /// No description provided for @feedThreadOpenItem.
  ///
  /// In en, this message translates to:
  /// **'Read the full report'**
  String get feedThreadOpenItem;

  /// No description provided for @feedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Hide from my list'**
  String get feedDismiss;

  /// No description provided for @feedDismissed.
  ///
  /// In en, this message translates to:
  /// **'Hidden from your list.'**
  String get feedDismissed;

  /// No description provided for @feedPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert settings'**
  String get feedPrefsTitle;

  /// No description provided for @feedPrefsQuietTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours (alerts stay silent)'**
  String get feedPrefsQuietTitle;

  /// No description provided for @feedPrefsQuietStart.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get feedPrefsQuietStart;

  /// No description provided for @feedPrefsQuietEnd.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get feedPrefsQuietEnd;

  /// No description provided for @feedPrefsWeeklyCap.
  ///
  /// In en, this message translates to:
  /// **'At most {count} alerts a week'**
  String feedPrefsWeeklyCap(String count);

  /// No description provided for @feedPrefsCapLess.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get feedPrefsCapLess;

  /// No description provided for @feedPrefsCapMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get feedPrefsCapMore;

  /// No description provided for @feedPrefsCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Send me alerts for'**
  String get feedPrefsCategoriesTitle;

  /// No description provided for @feedPrefsCatDeadline.
  ///
  /// In en, this message translates to:
  /// **'Last dates coming up'**
  String get feedPrefsCatDeadline;

  /// No description provided for @feedPrefsCatPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment updates'**
  String get feedPrefsCatPayment;

  /// No description provided for @feedPrefsCatWindowOpen.
  ///
  /// In en, this message translates to:
  /// **'Applications open'**
  String get feedPrefsCatWindowOpen;

  /// No description provided for @feedPrefsDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get feedPrefsDigest;

  /// No description provided for @feedPrefsDigestHint.
  ///
  /// In en, this message translates to:
  /// **'One message a week with what is new.'**
  String get feedPrefsDigestHint;

  /// No description provided for @feedPrefsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get feedPrefsSave;

  /// No description provided for @feedPrefsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get feedPrefsSaved;

  /// No description provided for @feedPrefsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Please save again when online.'**
  String get feedPrefsSaveFailed;

  /// No description provided for @feedPrefsOffline.
  ///
  /// In en, this message translates to:
  /// **'These are your last saved settings. Connect to the internet to save changes.'**
  String get feedPrefsOffline;

  /// No description provided for @feedCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check a message'**
  String get feedCheckTitle;

  /// No description provided for @feedCheckIntro.
  ///
  /// In en, this message translates to:
  /// **'Got a message about a GR or scheme on WhatsApp? Paste it here to look for the official GR.'**
  String get feedCheckIntro;

  /// No description provided for @feedCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the message here'**
  String get feedCheckHint;

  /// No description provided for @feedCheckPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get feedCheckPaste;

  /// No description provided for @feedCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get feedCheckButton;

  /// No description provided for @feedCheckPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The text is not saved on your phone.'**
  String get feedCheckPrivacy;

  /// No description provided for @feedCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Checking needs internet; please try again when online.'**
  String get feedCheckFailed;

  /// No description provided for @feedCheckOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official GR found'**
  String get feedCheckOfficial;

  /// No description provided for @feedCheckPossible.
  ///
  /// In en, this message translates to:
  /// **'Possibly related official items'**
  String get feedCheckPossible;

  /// No description provided for @feedCheckNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching official item was found.'**
  String get feedCheckNoMatch;

  /// No description provided for @feedCheckPortal.
  ///
  /// In en, this message translates to:
  /// **'Check the official portal before acting.'**
  String get feedCheckPortal;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @speakAction.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get speakAction;

  /// No description provided for @speakUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reading aloud needs a voice for this language on this phone.'**
  String get speakUnavailable;

  /// No description provided for @shareSentFrom.
  ///
  /// In en, this message translates to:
  /// **'Shared from the {app} app'**
  String shareSentFrom(String app);

  /// No description provided for @shareSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String shareSource(String source);

  /// No description provided for @marketShareLine.
  ///
  /// In en, this message translates to:
  /// **'{market}: {price} per quintal'**
  String marketShareLine(String market, String price);

  /// No description provided for @taskDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String taskDueOn(String date);

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get taskDetails;

  /// No description provided for @tasksTodayShare.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks ({date})'**
  String tasksTodayShare(String date);

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// No description provided for @accountSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Another account\'s records'**
  String get accountSwitchTitle;

  /// No description provided for @accountSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'This phone holds the records of another account. If you continue, they are removed from this phone (they stay safe on the server) and your own records are downloaded.'**
  String get accountSwitchBody;

  /// No description provided for @accountSwitchContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get accountSwitchContinue;

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Records waiting to send on this phone'**
  String get accountBlockedTitle;

  /// No description provided for @accountBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record of the previous account is still waiting to send.} other{{count} records of the previous account are still waiting to send.}} Sign in again with that account and open the app with internet on so they are sent. Then sign in with this account.'**
  String accountBlockedBody(int count);

  /// No description provided for @accountPreviousPhone.
  ///
  /// In en, this message translates to:
  /// **'Previous account: {phone}'**
  String accountPreviousPhone(String phone);

  /// No description provided for @insuranceTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop insurance'**
  String get insuranceTitle;

  /// No description provided for @insuranceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add the crop insurance you took for this plot, or open the claim kit after a loss.'**
  String get insuranceEmpty;

  /// No description provided for @insurancePoliciesNone.
  ///
  /// In en, this message translates to:
  /// **'Add your first policy.'**
  String get insurancePoliciesNone;

  /// No description provided for @insuranceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add policy'**
  String get insuranceAdd;

  /// No description provided for @insuranceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit policy'**
  String get insuranceEdit;

  /// No description provided for @insuranceScheme.
  ///
  /// In en, this message translates to:
  /// **'Scheme'**
  String get insuranceScheme;

  /// No description provided for @insuranceSchemePmfby.
  ///
  /// In en, this message translates to:
  /// **'PM crop insurance (PMFBY)'**
  String get insuranceSchemePmfby;

  /// No description provided for @insuranceSchemeRwbcis.
  ///
  /// In en, this message translates to:
  /// **'Weather-based fruit crop (RWBCIS)'**
  String get insuranceSchemeRwbcis;

  /// No description provided for @insuranceSchemeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get insuranceSchemeOther;

  /// No description provided for @insuranceSchemeUnknown.
  ///
  /// In en, this message translates to:
  /// **'To check'**
  String get insuranceSchemeUnknown;

  /// No description provided for @insuranceSeason.
  ///
  /// In en, this message translates to:
  /// **'Bahar'**
  String get insuranceSeason;

  /// No description provided for @insuranceSeasonAmbia.
  ///
  /// In en, this message translates to:
  /// **'Ambia bahar'**
  String get insuranceSeasonAmbia;

  /// No description provided for @insuranceSeasonMrig.
  ///
  /// In en, this message translates to:
  /// **'Mrig bahar'**
  String get insuranceSeasonMrig;

  /// No description provided for @insuranceSeasonYear.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get insuranceSeasonYear;

  /// No description provided for @insuranceInsurer.
  ///
  /// In en, this message translates to:
  /// **'Insurance company (optional)'**
  String get insuranceInsurer;

  /// No description provided for @insurancePolicyNumber.
  ///
  /// In en, this message translates to:
  /// **'Policy or application number (optional)'**
  String get insurancePolicyNumber;

  /// No description provided for @insuranceSumInsured.
  ///
  /// In en, this message translates to:
  /// **'Sum insured ₹ (optional)'**
  String get insuranceSumInsured;

  /// No description provided for @insurancePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium paid ₹ (optional)'**
  String get insurancePremium;

  /// No description provided for @insuranceAmountsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amounts only as printed on your receipt.'**
  String get insuranceAmountsHint;

  /// No description provided for @insuranceEnrolledOn.
  ///
  /// In en, this message translates to:
  /// **'Enrolment date'**
  String get insuranceEnrolledOn;

  /// No description provided for @insuranceNotSet.
  ///
  /// In en, this message translates to:
  /// **'To add'**
  String get insuranceNotSet;

  /// No description provided for @insuranceNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get insuranceNote;

  /// No description provided for @insurancePolicyNo.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String insurancePolicyNo(String number);

  /// No description provided for @insuranceEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled {date}'**
  String insuranceEnrolled(String date);

  /// No description provided for @insurancePremiumLine.
  ///
  /// In en, this message translates to:
  /// **'Premium paid {amount}'**
  String insurancePremiumLine(String amount);

  /// No description provided for @insuranceSumLine.
  ///
  /// In en, this message translates to:
  /// **'Sum insured {amount}'**
  String insuranceSumLine(String amount);

  /// No description provided for @insuranceDeadline.
  ///
  /// In en, this message translates to:
  /// **'Enrolment deadline: {date}'**
  String insuranceDeadline(String date);

  /// No description provided for @insuranceDeadlineNote.
  ///
  /// In en, this message translates to:
  /// **'From a published official notice. Check the notice before acting.'**
  String get insuranceDeadlineNote;

  /// No description provided for @insuranceDeletePolicy.
  ///
  /// In en, this message translates to:
  /// **'Delete policy'**
  String get insuranceDeletePolicy;

  /// No description provided for @insuranceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this policy record?'**
  String get insuranceDeleteConfirm;

  /// No description provided for @insuranceClaims.
  ///
  /// In en, this message translates to:
  /// **'Loss records'**
  String get insuranceClaims;

  /// No description provided for @insuranceClaimLine.
  ///
  /// In en, this message translates to:
  /// **'Loss on {date} · photos: {count}'**
  String insuranceClaimLine(String date, String count);

  /// No description provided for @claimKitTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim kit'**
  String get claimKitTitle;

  /// No description provided for @claimKitFromAlert.
  ///
  /// In en, this message translates to:
  /// **'Take loss photos · claim kit'**
  String get claimKitFromAlert;

  /// No description provided for @claimKitPlot.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get claimKitPlot;

  /// No description provided for @claimKitPickPlot.
  ///
  /// In en, this message translates to:
  /// **'Pick a plot'**
  String get claimKitPickPlot;

  /// No description provided for @claimKitDate.
  ///
  /// In en, this message translates to:
  /// **'Date of loss'**
  String get claimKitDate;

  /// No description provided for @claimKitPhotos.
  ///
  /// In en, this message translates to:
  /// **'Loss photos (date and GPS are added)'**
  String get claimKitPhotos;

  /// No description provided for @claimKitNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'Take loss photos; they appear here.'**
  String get claimKitNoPhotos;

  /// No description provided for @claimKitNoGps.
  ///
  /// In en, this message translates to:
  /// **'GPS unavailable'**
  String get claimKitNoGps;

  /// No description provided for @claimKitRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get claimKitRemovePhoto;

  /// No description provided for @claimKitNote.
  ///
  /// In en, this message translates to:
  /// **'What happened? (optional)'**
  String get claimKitNote;

  /// No description provided for @claimKitChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get claimKitChecklist;

  /// No description provided for @claimKitCheckPolicy.
  ///
  /// In en, this message translates to:
  /// **'General guidance only. Rules and time limits differ by policy: check your policy, bank or CSC.'**
  String get claimKitCheckPolicy;

  /// No description provided for @claimCheckInform72h.
  ///
  /// In en, this message translates to:
  /// **'Inform the insurer, your bank or the CSC about the loss as soon as possible; check your policy for the time limit.'**
  String get claimCheckInform72h;

  /// No description provided for @claimCheckPhotos.
  ///
  /// In en, this message translates to:
  /// **'Take dated photos of the damage from several sides of the plot.'**
  String get claimCheckPhotos;

  /// No description provided for @claimCheckPanchnama.
  ///
  /// In en, this message translates to:
  /// **'Ask for the panchnama (loss survey) and keep a copy.'**
  String get claimCheckPanchnama;

  /// No description provided for @claimCheckPolicyCopy.
  ///
  /// In en, this message translates to:
  /// **'Keep your policy or application receipt and a bank passbook copy ready.'**
  String get claimCheckPolicyCopy;

  /// No description provided for @claimCheckAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'Write down the complaint or docket number you get when you inform.'**
  String get claimCheckAcknowledgement;

  /// No description provided for @claimCheckKeepFruit.
  ///
  /// In en, this message translates to:
  /// **'Keep the damaged fruit and trees as they are until the survey, unless you are told otherwise.'**
  String get claimCheckKeepFruit;

  /// No description provided for @claimKitShare.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get claimKitShare;

  /// No description provided for @claimKitShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Please try making the PDF again.'**
  String get claimKitShareFailed;

  /// No description provided for @claimKitDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete loss record'**
  String get claimKitDelete;

  /// No description provided for @claimKitDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this loss record and its photos from this phone?'**
  String get claimKitDeleteConfirm;

  /// No description provided for @claimKitLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Photos and notes stay on this phone. Share the PDF when you need it.'**
  String get claimKitLocalOnly;

  /// No description provided for @claimPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop loss record'**
  String get claimPdfTitle;

  /// No description provided for @claimPdfPlotGps.
  ///
  /// In en, this message translates to:
  /// **'Plot location (GPS)'**
  String get claimPdfPlotGps;

  /// No description provided for @claimPdfNoGps.
  ///
  /// In en, this message translates to:
  /// **'To be marked'**
  String get claimPdfNoGps;

  /// No description provided for @claimPdfPolicy.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get claimPdfPolicy;

  /// No description provided for @claimPdfPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get claimPdfPhotos;

  /// No description provided for @claimPdfNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get claimPdfNote;

  /// No description provided for @claimPdfDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get claimPdfDone;

  /// No description provided for @claimPdfNotDone.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get claimPdfNotDone;

  /// No description provided for @claimPdfMade.
  ///
  /// In en, this message translates to:
  /// **'Made on {date}. A record kept by the grower, not an insurer\'s document.'**
  String claimPdfMade(String date);

  /// No description provided for @insurancePolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get insurancePolicies;

  /// No description provided for @labTestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil, water and leaf tests'**
  String get labTestsTitle;

  /// No description provided for @labTestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add this plot\'s first test from your lab report or Soil Health Card.'**
  String get labTestsEmpty;

  /// No description provided for @labTestAdd.
  ///
  /// In en, this message translates to:
  /// **'Add test'**
  String get labTestAdd;

  /// No description provided for @labTestEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit test'**
  String get labTestEdit;

  /// No description provided for @labTestType.
  ///
  /// In en, this message translates to:
  /// **'Test of'**
  String get labTestType;

  /// No description provided for @labTestTypeSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get labTestTypeSoil;

  /// No description provided for @labTestTypeWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get labTestTypeWater;

  /// No description provided for @labTestTypeLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get labTestTypeLeaf;

  /// No description provided for @labTestTitleSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil test'**
  String get labTestTitleSoil;

  /// No description provided for @labTestTitleWater.
  ///
  /// In en, this message translates to:
  /// **'Water test'**
  String get labTestTitleWater;

  /// No description provided for @labTestTitleLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf test'**
  String get labTestTitleLeaf;

  /// No description provided for @labTestSampledOn.
  ///
  /// In en, this message translates to:
  /// **'Sample taken on'**
  String get labTestSampledOn;

  /// No description provided for @labTestReportedOn.
  ///
  /// In en, this message translates to:
  /// **'Report date'**
  String get labTestReportedOn;

  /// No description provided for @labTestLab.
  ///
  /// In en, this message translates to:
  /// **'Lab name'**
  String get labTestLab;

  /// No description provided for @labTestReadings.
  ///
  /// In en, this message translates to:
  /// **'Values from the report'**
  String get labTestReadings;

  /// No description provided for @labTestReadingsHint.
  ///
  /// In en, this message translates to:
  /// **'Type each value as it is written on the report.'**
  String get labTestReadingsHint;

  /// No description provided for @labTestParameter.
  ///
  /// In en, this message translates to:
  /// **'Name (pH, EC …)'**
  String get labTestParameter;

  /// No description provided for @labTestValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get labTestValue;

  /// No description provided for @labTestUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get labTestUnit;

  /// No description provided for @labTestAddReading.
  ///
  /// In en, this message translates to:
  /// **'Add a value'**
  String get labTestAddReading;

  /// No description provided for @labTestRemoveReading.
  ///
  /// In en, this message translates to:
  /// **'Remove this value'**
  String get labTestRemoveReading;

  /// No description provided for @labTestSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Names on most reports (tap to add)'**
  String get labTestSuggestions;

  /// No description provided for @labTestReadingIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Type the name and the value'**
  String get labTestReadingIncomplete;

  /// No description provided for @labTestNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get labTestNote;

  /// No description provided for @labTestReport.
  ///
  /// In en, this message translates to:
  /// **'Report photo or file'**
  String get labTestReport;

  /// No description provided for @labTestReportFile.
  ///
  /// In en, this message translates to:
  /// **'File (PDF)'**
  String get labTestReportFile;

  /// No description provided for @labTestReportRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get labTestReportRemove;

  /// No description provided for @labTestReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Please try adding the report again.'**
  String get labTestReportFailed;

  /// No description provided for @labTestReportLocal.
  ///
  /// In en, this message translates to:
  /// **'The report stays on this phone.'**
  String get labTestReportLocal;

  /// No description provided for @labTestReportMissing.
  ///
  /// In en, this message translates to:
  /// **'Please attach the report file again.'**
  String get labTestReportMissing;

  /// No description provided for @labTestShareReport.
  ///
  /// In en, this message translates to:
  /// **'Share the report'**
  String get labTestShareReport;

  /// No description provided for @labTestAskExpert.
  ///
  /// In en, this message translates to:
  /// **'Ask an expert to read this report; they can explain what the values mean.'**
  String get labTestAskExpert;

  /// No description provided for @labTestNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next test due (reminder)'**
  String get labTestNextDue;

  /// No description provided for @labTestNextDueHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a date only if you want a reminder task.'**
  String get labTestNextDueHint;

  /// No description provided for @labTestNextDueClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the reminder date'**
  String get labTestNextDueClear;

  /// No description provided for @labTestReminderSoil.
  ///
  /// In en, this message translates to:
  /// **'Next soil test due'**
  String get labTestReminderSoil;

  /// No description provided for @labTestReminderWater.
  ///
  /// In en, this message translates to:
  /// **'Next water test due'**
  String get labTestReminderWater;

  /// No description provided for @labTestReminderLeaf.
  ///
  /// In en, this message translates to:
  /// **'Next leaf test due'**
  String get labTestReminderLeaf;

  /// No description provided for @labTestDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete test'**
  String get labTestDelete;

  /// No description provided for @labTestDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this test record and its report from this phone?'**
  String get labTestDeleteConfirm;

  /// No description provided for @labTestSampledLine.
  ///
  /// In en, this message translates to:
  /// **'Sample {date}'**
  String labTestSampledLine(String date);

  /// No description provided for @labTestReportedLine.
  ///
  /// In en, this message translates to:
  /// **'Report {date}'**
  String labTestReportedLine(String date);

  /// No description provided for @labTestLabLine.
  ///
  /// In en, this message translates to:
  /// **'Lab: {name}'**
  String labTestLabLine(String name);

  /// No description provided for @labTestValuesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add values} =1{1 value} other{{count} values}}'**
  String labTestValuesCount(int count);

  /// No description provided for @labTestNoValues.
  ///
  /// In en, this message translates to:
  /// **'Type the values from the report here.'**
  String get labTestNoValues;

  /// No description provided for @labTestEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get labTestEditAction;

  /// No description provided for @schemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Schemes and documents'**
  String get schemesTitle;

  /// No description provided for @schemesHomeHint.
  ///
  /// In en, this message translates to:
  /// **'Who can apply, documents to keep ready'**
  String get schemesHomeHint;

  /// No description provided for @schemesIntro.
  ///
  /// In en, this message translates to:
  /// **'General information to help you get ready. See the amount and rules on the official page, then apply.'**
  String get schemesIntro;

  /// Nudge to visit the nearest Setu / Aaple Sarkar Seva Kendra (CSC); shown on the scheme list and each scheme.
  ///
  /// In en, this message translates to:
  /// **'Visit your nearest Setu Kendra (Aaple Sarkar Seva Kendra / CSC) to apply, get documents and ask questions.'**
  String get schemeVisitSetu;

  /// No description provided for @schemeWho.
  ///
  /// In en, this message translates to:
  /// **'Who can apply'**
  String get schemeWho;

  /// No description provided for @schemeDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents usually needed'**
  String get schemeDocuments;

  /// No description provided for @schemeDocumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Tick what you already have. Kept on this phone only.'**
  String get schemeDocumentsHint;

  /// No description provided for @schemeDocsReady.
  ///
  /// In en, this message translates to:
  /// **'{have} of {total} ready'**
  String schemeDocsReady(int have, int total);

  /// No description provided for @schemeNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm on the official page'**
  String get schemeNotConfirmed;

  /// No description provided for @schemeWhereToApply.
  ///
  /// In en, this message translates to:
  /// **'Where to apply'**
  String get schemeWhereToApply;

  /// No description provided for @schemeSources.
  ///
  /// In en, this message translates to:
  /// **'Sources (checked on {date})'**
  String schemeSources(String date);

  /// No description provided for @schemeFeedItems.
  ///
  /// In en, this message translates to:
  /// **'Related govt notices'**
  String get schemeFeedItems;

  /// No description provided for @schemeShareDocs.
  ///
  /// In en, this message translates to:
  /// **'Documents for {scheme}:'**
  String schemeShareDocs(String scheme);

  /// No description provided for @schemeShareHave.
  ///
  /// In en, this message translates to:
  /// **'have'**
  String get schemeShareHave;

  /// No description provided for @schemeShareMissing.
  ///
  /// In en, this message translates to:
  /// **'to get'**
  String get schemeShareMissing;

  /// No description provided for @lookalikesTitle.
  ///
  /// In en, this message translates to:
  /// **'Look-alike symptoms'**
  String get lookalikesTitle;

  /// No description provided for @lookalikesOpen.
  ///
  /// In en, this message translates to:
  /// **'Look-alike symptoms'**
  String get lookalikesOpen;

  /// No description provided for @lookalikesIntro.
  ///
  /// In en, this message translates to:
  /// **'Many orchard problems look alike; these cards help you describe exactly what you see.'**
  String get lookalikesIntro;

  /// No description provided for @lookalikesSee.
  ///
  /// In en, this message translates to:
  /// **'What you may see'**
  String get lookalikesSee;

  /// No description provided for @lookalikesConfusedWith.
  ///
  /// In en, this message translates to:
  /// **'Can be confused with'**
  String get lookalikesConfusedWith;

  /// No description provided for @lookalikesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Who can confirm it'**
  String get lookalikesConfirm;

  /// No description provided for @lookalikesCheckLine.
  ///
  /// In en, this message translates to:
  /// **'Want to be sure? Take a photo, log it in scouting and get it checked by a lab or an expert before you decide.'**
  String get lookalikesCheckLine;

  /// No description provided for @lookalikesLogThis.
  ///
  /// In en, this message translates to:
  /// **'Log this in scouting'**
  String get lookalikesLogThis;

  /// No description provided for @lookalikesFindLab.
  ///
  /// In en, this message translates to:
  /// **'Find a lab or expert'**
  String get lookalikesFindLab;

  /// No description provided for @lookalikesSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get lookalikesSources;

  /// No description provided for @lookalikesDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft: a source is still to be checked'**
  String get lookalikesDraft;

  /// No description provided for @lookalikesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cards appear here.'**
  String get lookalikesEmpty;

  /// No description provided for @labsTitle.
  ///
  /// In en, this message translates to:
  /// **'Labs and experts'**
  String get labsTitle;

  /// No description provided for @labsOpen.
  ///
  /// In en, this message translates to:
  /// **'Labs and experts'**
  String get labsOpen;

  /// No description provided for @marketDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Markets and buyers'**
  String get marketDirectoryTitle;

  /// No description provided for @marketDirectoryOpen.
  ///
  /// In en, this message translates to:
  /// **'Markets and buyers'**
  String get marketDirectoryOpen;

  /// No description provided for @directoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get directoryAll;

  /// No description provided for @directoryUnverified.
  ///
  /// In en, this message translates to:
  /// **'Please confirm on the official page'**
  String get directoryUnverified;

  /// No description provided for @directoryCopyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get directoryCopyNumber;

  /// No description provided for @directoryNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get directoryNumberCopied;

  /// No description provided for @directoryCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get directoryCopyLink;

  /// No description provided for @directoryWebPage.
  ///
  /// In en, this message translates to:
  /// **'Web page: {url}'**
  String directoryWebPage(Object url);

  /// No description provided for @directoryPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String directoryPhone(Object phone);

  /// No description provided for @directoryDetailsFrom.
  ///
  /// In en, this message translates to:
  /// **'Details from: {url}'**
  String directoryDetailsFrom(Object url);

  /// No description provided for @directoryChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked {date}'**
  String directoryChecked(Object date);

  /// No description provided for @directoryCheckLine.
  ///
  /// In en, this message translates to:
  /// **'Details are copied from official pages on the date shown. Call or visit the page to confirm before you travel.'**
  String get directoryCheckLine;

  /// No description provided for @directoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Entries appear here.'**
  String get directoryEmpty;

  /// No description provided for @directoryKindResearch.
  ///
  /// In en, this message translates to:
  /// **'Research institute'**
  String get directoryKindResearch;

  /// No description provided for @directoryKindUniversity.
  ///
  /// In en, this message translates to:
  /// **'Agricultural university'**
  String get directoryKindUniversity;

  /// No description provided for @directoryKindKvk.
  ///
  /// In en, this message translates to:
  /// **'Krishi Vigyan Kendra'**
  String get directoryKindKvk;

  /// No description provided for @directoryKindSoilLab.
  ///
  /// In en, this message translates to:
  /// **'Soil testing'**
  String get directoryKindSoilLab;

  /// No description provided for @directoryKindPortal.
  ///
  /// In en, this message translates to:
  /// **'Prices and arrivals'**
  String get directoryKindPortal;

  /// No description provided for @directoryKindApmc.
  ///
  /// In en, this message translates to:
  /// **'Market committee (APMC)'**
  String get directoryKindApmc;

  /// No description provided for @directoryKindExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get directoryKindExport;

  /// No description provided for @directoryKindProcessor.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get directoryKindProcessor;

  /// Export information page title (market-link module, information only).
  ///
  /// In en, this message translates to:
  /// **'Export information'**
  String get exportInfoTitle;

  /// Always-visible note: the page is information; BagMitra takes no part in the export deal.
  ///
  /// In en, this message translates to:
  /// **'For information. The export deal is between you and the exporter.'**
  String get exportInfoNote;

  /// No description provided for @exportSectionDestinations.
  ///
  /// In en, this message translates to:
  /// **'Where it goes'**
  String get exportSectionDestinations;

  /// No description provided for @exportSectionSeason.
  ///
  /// In en, this message translates to:
  /// **'Season fit (exporter\'s view)'**
  String get exportSectionSeason;

  /// No description provided for @exportSectionSpecs.
  ///
  /// In en, this message translates to:
  /// **'What buyers ask (as quoted)'**
  String get exportSectionSpecs;

  /// No description provided for @exportSectionRules.
  ///
  /// In en, this message translates to:
  /// **'Rules a grower meets'**
  String get exportSectionRules;

  /// No description provided for @exportLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Official pages'**
  String get exportLinksTitle;

  /// No description provided for @exportRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Export record'**
  String get exportRecordTitle;

  /// No description provided for @exportRecordAction.
  ///
  /// In en, this message translates to:
  /// **'Make export record (PDF)'**
  String get exportRecordAction;

  /// No description provided for @exportRecordPlot.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get exportRecordPlot;

  /// No description provided for @exportRecordBahar.
  ///
  /// In en, this message translates to:
  /// **'Bahar'**
  String get exportRecordBahar;

  /// No description provided for @exportRecordAllBahars.
  ///
  /// In en, this message translates to:
  /// **'All sprays'**
  String get exportRecordAllBahars;

  /// No description provided for @exportRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sprays'**
  String exportRecordCount(String count);

  /// No description provided for @exportRecordLastPhi.
  ///
  /// In en, this message translates to:
  /// **'Last PHI ends {date}'**
  String exportRecordLastPhi(String date);

  /// No description provided for @exportRecordShare.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get exportRecordShare;

  /// No description provided for @exportRecordNoPlot.
  ///
  /// In en, this message translates to:
  /// **'Add a plot first; its spray record appears here.'**
  String get exportRecordNoPlot;

  /// No description provided for @exportRecordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Sprays of this bahar appear here once recorded.'**
  String get exportRecordEmpty;

  /// No description provided for @exportRecordDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportRecordDate;

  /// No description provided for @exportRecordProduct.
  ///
  /// In en, this message translates to:
  /// **'Product · ingredient · dose'**
  String get exportRecordProduct;

  /// No description provided for @exportRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Label check'**
  String get exportRecordLabel;

  /// No description provided for @exportRecordPhiEnd.
  ///
  /// In en, this message translates to:
  /// **'PHI ends'**
  String get exportRecordPhiEnd;

  /// No description provided for @exportLabelListed.
  ///
  /// In en, this message translates to:
  /// **'On the label for this crop'**
  String get exportLabelListed;

  /// No description provided for @exportLabelCheck.
  ///
  /// In en, this message translates to:
  /// **'Check the label'**
  String get exportLabelCheck;

  /// No description provided for @exportRecordMade.
  ///
  /// In en, this message translates to:
  /// **'Made on {date} from the grower\'s own spray log.'**
  String exportRecordMade(String date);

  /// Export record PDF footer (spec v1.5 §4A): information only, no compliance claim. Keeps the negative on purpose.
  ///
  /// In en, this message translates to:
  /// **'Information record, not a certificate.'**
  String get exportRecordFooter;

  /// No description provided for @fairPriceMandi.
  ///
  /// In en, this message translates to:
  /// **'{market} mandi, {date}: modal price {price} per quintal'**
  String fairPriceMandi(Object date, Object market, Object price);

  /// No description provided for @fairPriceAbove.
  ///
  /// In en, this message translates to:
  /// **'Your rate is {percent}% above the mandi modal price.'**
  String fairPriceAbove(Object percent);

  /// No description provided for @fairPriceBelow.
  ///
  /// In en, this message translates to:
  /// **'Your rate is {percent}% below the mandi modal price.'**
  String fairPriceBelow(Object percent);

  /// No description provided for @fairPriceSame.
  ///
  /// In en, this message translates to:
  /// **'Your rate is the same as the mandi modal price.'**
  String get fairPriceSame;

  /// No description provided for @loginPhoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Please sign in with Google for now'**
  String get loginPhoneUnavailable;

  /// No description provided for @loginResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get loginResendOtp;

  /// No description provided for @loginResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds} s'**
  String loginResendIn(int seconds);

  /// No description provided for @loginOtpResent.
  ///
  /// In en, this message translates to:
  /// **'A new OTP has been sent'**
  String get loginOtpResent;

  /// No description provided for @loginChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get loginChangeNumber;

  /// No description provided for @loginTitleGoogle.
  ///
  /// In en, this message translates to:
  /// **'Start with your Google account'**
  String get loginTitleGoogle;

  /// No description provided for @netOffline.
  ///
  /// In en, this message translates to:
  /// **'Check the internet and try again'**
  String get netOffline;

  /// No description provided for @netServer.
  ///
  /// In en, this message translates to:
  /// **'The server is busy; try again in a little while'**
  String get netServer;

  /// No description provided for @netSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in again for the latest information'**
  String get netSignedOut;

  /// No description provided for @netRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get netRetry;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAgain;

  /// No description provided for @syncServerBanner.
  ///
  /// In en, this message translates to:
  /// **'Your entries are safe on this phone; they will be sent once the server is back.'**
  String get syncServerBanner;

  /// No description provided for @syncSignedOutBanner.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to send your entries'**
  String get syncSignedOutBanner;

  /// No description provided for @syncRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry to check} other{{count} entries to check}}'**
  String syncRejectedBanner(int count);

  /// No description provided for @syncReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get syncReview;

  /// No description provided for @syncRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Entries to check'**
  String get syncRejectedTitle;

  /// No description provided for @syncRejectedHelp.
  ///
  /// In en, this message translates to:
  /// **'Send each entry again, or remove it from this list; the record on the phone stays as it is.'**
  String get syncRejectedHelp;

  /// No description provided for @syncRejectedDone.
  ///
  /// In en, this message translates to:
  /// **'All entries are in order'**
  String get syncRejectedDone;

  /// No description provided for @syncResend.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get syncResend;

  /// No description provided for @syncDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get syncDelete;

  /// No description provided for @syncEntryName.
  ///
  /// In en, this message translates to:
  /// **'{entity, select, farmer_profile{Profile} plot{Plot} bahar_cycle{Bahar} expense{Expense} income{Sale} spray_record{Spray} input_record{Input} irrigation_record{Irrigation} harvest_record{Harvest} labour_record{Labour} farm_task{Task} scouting_record{Scouting} insurance_policy{Insurance} lab_test{Lab test} other{Entry}}'**
  String syncEntryName(String entity);

  /// No description provided for @refreshOffline.
  ///
  /// In en, this message translates to:
  /// **'Check the internet'**
  String get refreshOffline;

  /// No description provided for @refreshServer.
  ///
  /// In en, this message translates to:
  /// **'The server is busy'**
  String get refreshServer;

  /// No description provided for @homeQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickTitle;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'All features'**
  String get moreTitle;

  /// No description provided for @moreSectionRecords.
  ///
  /// In en, this message translates to:
  /// **'Orchard records'**
  String get moreSectionRecords;

  /// No description provided for @moreSectionWork.
  ///
  /// In en, this message translates to:
  /// **'Work and season'**
  String get moreSectionWork;

  /// No description provided for @moreSectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Guides and help'**
  String get moreSectionHelp;

  /// No description provided for @moreSectionMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get moreSectionMarket;

  /// No description provided for @moreSectionGovt.
  ///
  /// In en, this message translates to:
  /// **'Government help'**
  String get moreSectionGovt;

  /// No description provided for @moreSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get moreSectionAccount;

  /// No description provided for @plotTileBahar.
  ///
  /// In en, this message translates to:
  /// **'Bahar'**
  String get plotTileBahar;

  /// No description provided for @baharRecordsMenu.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get baharRecordsMenu;

  /// No description provided for @tasksDoneShow.
  ///
  /// In en, this message translates to:
  /// **'Show ({count})'**
  String tasksDoneShow(String count);

  /// No description provided for @tasksDoneHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get tasksDoneHide;

  /// No description provided for @tasksDoneLatest.
  ///
  /// In en, this message translates to:
  /// **'Showing the latest {count}'**
  String tasksDoneLatest(String count);

  /// No description provided for @requiredPlotName.
  ///
  /// In en, this message translates to:
  /// **'Write the block name'**
  String get requiredPlotName;

  /// No description provided for @requiredTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Write what needs doing'**
  String get requiredTaskTitle;

  /// No description provided for @requiredWorker.
  ///
  /// In en, this message translates to:
  /// **'Write the worker\'s name'**
  String get requiredWorker;

  /// No description provided for @requiredSprayProduct.
  ///
  /// In en, this message translates to:
  /// **'Write the product name'**
  String get requiredSprayProduct;

  /// No description provided for @requiredInputProduct.
  ///
  /// In en, this message translates to:
  /// **'Write the product name'**
  String get requiredInputProduct;

  /// No description provided for @requiredBuyer.
  ///
  /// In en, this message translates to:
  /// **'Write the buyer\'s name'**
  String get requiredBuyer;

  /// No description provided for @claimKitGpsOk.
  ///
  /// In en, this message translates to:
  /// **'Location added'**
  String get claimKitGpsOk;

  /// No description provided for @priceChangeUp.
  ///
  /// In en, this message translates to:
  /// **'{pct} up from last week'**
  String priceChangeUp(String pct);

  /// No description provided for @priceChangeDown.
  ///
  /// In en, this message translates to:
  /// **'{pct} down from last week'**
  String priceChangeDown(String pct);

  /// No description provided for @generalInfoSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source} · checked {date}'**
  String generalInfoSource(String source, String date);

  /// No description provided for @sourcesShow.
  ///
  /// In en, this message translates to:
  /// **'See sources'**
  String get sourcesShow;

  /// No description provided for @sourcesShowCount.
  ///
  /// In en, this message translates to:
  /// **'See sources ({count})'**
  String sourcesShowCount(String count);

  /// No description provided for @sourcesHide.
  ///
  /// In en, this message translates to:
  /// **'Hide sources'**
  String get sourcesHide;

  /// No description provided for @sourcesChecked.
  ///
  /// In en, this message translates to:
  /// **'read {date}'**
  String sourcesChecked(String date);

  /// No description provided for @labelReadNote.
  ///
  /// In en, this message translates to:
  /// **'Read the label on the packet before spraying.'**
  String get labelReadNote;

  /// No description provided for @baharSuggestedWindow.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {from} – {to}'**
  String baharSuggestedWindow(String from, String to);

  /// No description provided for @baharNoWindow.
  ///
  /// In en, this message translates to:
  /// **'Enter your own date: the sources give windows for the other stages only'**
  String get baharNoWindow;

  /// No description provided for @baharFillSuggested.
  ///
  /// In en, this message translates to:
  /// **'Fill in the suggested dates'**
  String get baharFillSuggested;

  /// No description provided for @baharSuggestedHelp.
  ///
  /// In en, this message translates to:
  /// **'Suggested windows are from public sources. Change any date to suit your orchard.'**
  String get baharSuggestedHelp;

  /// No description provided for @baharStressBySoil.
  ///
  /// In en, this message translates to:
  /// **'How long the stress lasts depends on the soil: fewer days in light soil, more in heavy soil.'**
  String get baharStressBySoil;

  /// No description provided for @practicesSee.
  ///
  /// In en, this message translates to:
  /// **'What you see'**
  String get practicesSee;

  /// No description provided for @practicesWhen.
  ///
  /// In en, this message translates to:
  /// **'When it comes'**
  String get practicesWhen;

  /// No description provided for @figureGum.
  ///
  /// In en, this message translates to:
  /// **'Gum oozes'**
  String get figureGum;

  /// No description provided for @figureWetPatches.
  ///
  /// In en, this message translates to:
  /// **'Water-soaked patches'**
  String get figureWetPatches;

  /// No description provided for @figureBarkPeels.
  ///
  /// In en, this message translates to:
  /// **'Bark peels in vertical strips'**
  String get figureBarkPeels;

  /// No description provided for @figureYellowLeaves.
  ///
  /// In en, this message translates to:
  /// **'Yellow leaves'**
  String get figureYellowLeaves;

  /// No description provided for @figureWidthCm.
  ///
  /// In en, this message translates to:
  /// **'{cm} cm'**
  String figureWidthCm(String cm);

  /// No description provided for @figureDepthCm.
  ///
  /// In en, this message translates to:
  /// **'{cm} cm deep'**
  String figureDepthCm(String cm);

  /// No description provided for @figureDrainsAway.
  ///
  /// In en, this message translates to:
  /// **'Water drains away from the trees'**
  String get figureDrainsAway;

  /// No description provided for @figureDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get figureDry;

  /// No description provided for @figureWaterHere.
  ///
  /// In en, this message translates to:
  /// **'Water here'**
  String get figureWaterHere;

  /// No description provided for @figureTopView.
  ///
  /// In en, this message translates to:
  /// **'Seen from above'**
  String get figureTopView;

  /// No description provided for @figureDeadPart.
  ///
  /// In en, this message translates to:
  /// **'Dried part'**
  String get figureDeadPart;

  /// No description provided for @figureCutHere.
  ///
  /// In en, this message translates to:
  /// **'Cut here'**
  String get figureCutHere;

  /// No description provided for @figureHealthyCm.
  ///
  /// In en, this message translates to:
  /// **'with {cm} cm of healthy wood'**
  String figureHealthyCm(String cm);

  /// No description provided for @figureSunDays.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} days of sun'**
  String figureSunDays(String from, String to);

  /// No description provided for @figureCutRotten.
  ///
  /// In en, this message translates to:
  /// **'Cut out rotten roots'**
  String get figureCutRotten;

  /// No description provided for @figureWithBand.
  ///
  /// In en, this message translates to:
  /// **'Remove with a healthy strip'**
  String get figureWithBand;

  /// No description provided for @figureDiseasedBark.
  ///
  /// In en, this message translates to:
  /// **'Diseased bark'**
  String get figureDiseasedBark;

  /// No description provided for @figureRains.
  ///
  /// In en, this message translates to:
  /// **'Monsoon'**
  String get figureRains;

  /// No description provided for @figureBeforeRains.
  ///
  /// In en, this message translates to:
  /// **'Before the monsoon'**
  String get figureBeforeRains;

  /// No description provided for @figureAfterRains.
  ///
  /// In en, this message translates to:
  /// **'After the monsoon'**
  String get figureAfterRains;

  /// No description provided for @figureInnerRingCm.
  ///
  /// In en, this message translates to:
  /// **'Inner ring {cm} cm'**
  String figureInnerRingCm(String cm);

  /// No description provided for @figureYellowTrap.
  ///
  /// In en, this message translates to:
  /// **'Yellow sticky trap'**
  String get figureYellowTrap;

  /// No description provided for @figureHeightM.
  ///
  /// In en, this message translates to:
  /// **'{m} m above ground'**
  String figureHeightM(String m);

  /// No description provided for @figureBudUnion.
  ///
  /// In en, this message translates to:
  /// **'Bud union'**
  String get figureBudUnion;

  /// No description provided for @figureHeightRangeCm.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} cm above ground'**
  String figureHeightRangeCm(String from, String to);

  /// No description provided for @figureStickyBand.
  ///
  /// In en, this message translates to:
  /// **'Sticky barrier {cm} cm'**
  String figureStickyBand(String cm);

  /// No description provided for @figureAnts.
  ///
  /// In en, this message translates to:
  /// **'Ants'**
  String get figureAnts;

  /// No description provided for @figureLureTrap.
  ///
  /// In en, this message translates to:
  /// **'Lure trap'**
  String get figureLureTrap;

  /// No description provided for @figureRenewDays.
  ///
  /// In en, this message translates to:
  /// **'Renew the lure every {from}–{to} days'**
  String figureRenewDays(String from, String to);

  /// No description provided for @figureShadyFirst.
  ///
  /// In en, this message translates to:
  /// **'Shady side: look here first'**
  String get figureShadyFirst;

  /// No description provided for @figureSunnySide.
  ///
  /// In en, this message translates to:
  /// **'Sunny side'**
  String get figureSunnySide;

  /// No description provided for @figureOpenCentre.
  ///
  /// In en, this message translates to:
  /// **'Open centre: air flows'**
  String get figureOpenCentre;

  /// No description provided for @figureCutCrowded.
  ///
  /// In en, this message translates to:
  /// **'Cut crowded shoots'**
  String get figureCutCrowded;

  /// No description provided for @figureRootZone.
  ///
  /// In en, this message translates to:
  /// **'Active root zone'**
  String get figureRootZone;

  /// No description provided for @figureManureHere.
  ///
  /// In en, this message translates to:
  /// **'Manure here, cover with soil'**
  String get figureManureHere;

  /// No description provided for @figCankerSpots.
  ///
  /// In en, this message translates to:
  /// **'Raised, rough, brown corky spots'**
  String get figCankerSpots;

  /// No description provided for @figCankerHalo.
  ///
  /// In en, this message translates to:
  /// **'Yellow halo'**
  String get figCankerHalo;

  /// No description provided for @figCankerFruit.
  ///
  /// In en, this message translates to:
  /// **'On fruit: spots stay in the rind'**
  String get figCankerFruit;

  /// No description provided for @figMildewPowder.
  ///
  /// In en, this message translates to:
  /// **'White powder'**
  String get figMildewPowder;

  /// No description provided for @figMildewCurl.
  ///
  /// In en, this message translates to:
  /// **'Leaves twist and curl'**
  String get figMildewCurl;

  /// No description provided for @figAnthPatch.
  ///
  /// In en, this message translates to:
  /// **'Light-tan patch, purple edge'**
  String get figAnthPatch;

  /// No description provided for @figAnthDots.
  ///
  /// In en, this message translates to:
  /// **'Tiny black dots'**
  String get figAnthDots;

  /// No description provided for @figAnthTwig.
  ///
  /// In en, this message translates to:
  /// **'Dead twig: silvery grey'**
  String get figAnthTwig;

  /// No description provided for @figGreeningLeaf.
  ///
  /// In en, this message translates to:
  /// **'Yellow leaf with green islands'**
  String get figGreeningLeaf;

  /// No description provided for @figGreeningFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit small, lopsided, green'**
  String get figGreeningFruit;

  /// No description provided for @figPsyllaNymphs.
  ///
  /// In en, this message translates to:
  /// **'Yellow-orange nymphs on shoot tips'**
  String get figPsyllaNymphs;

  /// No description provided for @figPsyllaThreads.
  ///
  /// In en, this message translates to:
  /// **'White waxy threads'**
  String get figPsyllaThreads;

  /// No description provided for @figPsyllaCurl.
  ///
  /// In en, this message translates to:
  /// **'New leaves curl'**
  String get figPsyllaCurl;

  /// No description provided for @figAphidColony.
  ///
  /// In en, this message translates to:
  /// **'Black or brown aphid colonies'**
  String get figAphidColony;

  /// No description provided for @figAphidCup.
  ///
  /// In en, this message translates to:
  /// **'Cup-shaped, crinkled leaves'**
  String get figAphidCup;

  /// No description provided for @figMealyClusters.
  ///
  /// In en, this message translates to:
  /// **'White cottony clusters'**
  String get figMealyClusters;

  /// No description provided for @figSootyMould.
  ///
  /// In en, this message translates to:
  /// **'Sooty mould'**
  String get figSootyMould;

  /// No description provided for @figMinerMines.
  ///
  /// In en, this message translates to:
  /// **'Silvery zig-zag mines'**
  String get figMinerMines;

  /// No description provided for @figMinerDistort.
  ///
  /// In en, this message translates to:
  /// **'Leaf distorts and crumples'**
  String get figMinerDistort;

  /// No description provided for @figMitesVeins.
  ///
  /// In en, this message translates to:
  /// **'Pale yellow along the veins'**
  String get figMitesVeins;

  /// No description provided for @figMitesWeb.
  ///
  /// In en, this message translates to:
  /// **'Fine webbing: dusty look'**
  String get figMitesWeb;

  /// No description provided for @figMitesRind.
  ///
  /// In en, this message translates to:
  /// **'Rough rind (russeting)'**
  String get figMitesRind;

  /// No description provided for @figThripsRing.
  ///
  /// In en, this message translates to:
  /// **'Ring-like scar round the stalk'**
  String get figThripsRing;

  /// No description provided for @figThripsPatches.
  ///
  /// In en, this message translates to:
  /// **'Irregular patches on the rind'**
  String get figThripsPatches;

  /// No description provided for @figHeatSummer.
  ///
  /// In en, this message translates to:
  /// **'Hot summer'**
  String get figHeatSummer;

  /// No description provided for @figHeatDrop.
  ///
  /// In en, this message translates to:
  /// **'Second wave of fruit drop'**
  String get figHeatDrop;

  /// No description provided for @practicesScout.
  ///
  /// In en, this message translates to:
  /// **'How to scout'**
  String get practicesScout;

  /// No description provided for @practicesActionLevel.
  ///
  /// In en, this message translates to:
  /// **'Action level'**
  String get practicesActionLevel;

  /// No description provided for @practicesNoActionLevel.
  ///
  /// In en, this message translates to:
  /// **'Ask your KVK for the action level: the sources read so far are silent on it.'**
  String get practicesNoActionLevel;

  /// No description provided for @practicesWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get practicesWhatToDo;

  /// No description provided for @practicesBioTitle.
  ///
  /// In en, this message translates to:
  /// **'Organic / bio'**
  String get practicesBioTitle;

  /// No description provided for @practicesBioRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered product: the dose comes only from its label.'**
  String get practicesBioRegistered;

  /// No description provided for @practicesBioHome.
  ///
  /// In en, this message translates to:
  /// **'Home-made, as published'**
  String get practicesBioHome;

  /// No description provided for @practicesHowToPrepare.
  ///
  /// In en, this message translates to:
  /// **'How to prepare'**
  String get practicesHowToPrepare;

  /// No description provided for @practicesLabelLink.
  ///
  /// In en, this message translates to:
  /// **'Label-approved products'**
  String get practicesLabelLink;

  /// No description provided for @practicesKnowledgeCard.
  ///
  /// In en, this message translates to:
  /// **'Knowledge card'**
  String get practicesKnowledgeCard;

  /// No description provided for @knowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge cards'**
  String get knowledgeTitle;

  /// No description provided for @knowledgeIntro.
  ///
  /// In en, this message translates to:
  /// **'Short notes on bahar, pests, diseases, feeding, water and harvest. Products and doses are on the label screen.'**
  String get knowledgeIntro;

  /// No description provided for @knowledgeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Knowledge cards appear here once the phone has been online.'**
  String get knowledgeEmpty;

  /// No description provided for @knowledgeWarnings.
  ///
  /// In en, this message translates to:
  /// **'Take care'**
  String get knowledgeWarnings;

  /// No description provided for @knowledgeCallExpert.
  ///
  /// In en, this message translates to:
  /// **'When to ask an expert'**
  String get knowledgeCallExpert;

  /// No description provided for @knowledgeSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get knowledgeSources;

  /// No description provided for @practicesSourcesLineAll.
  ///
  /// In en, this message translates to:
  /// **'Sources: NHB, NIPHM, ICAR, Dr. PDKV, MPKV, TNAU and others. Details under each practice.'**
  String get practicesSourcesLineAll;

  /// No description provided for @schemeGeneralSource.
  ///
  /// In en, this message translates to:
  /// **'the official pages listed at the end'**
  String get schemeGeneralSource;

  /// No description provided for @schemeFacts.
  ///
  /// In en, this message translates to:
  /// **'Key facts from the official page'**
  String get schemeFacts;

  /// No description provided for @schemeFactSource.
  ///
  /// In en, this message translates to:
  /// **'From: {source}'**
  String schemeFactSource(String source);

  /// No description provided for @labNormsTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil Health Card rating ranges'**
  String get labNormsTitle;

  /// No description provided for @labNormsHint.
  ///
  /// In en, this message translates to:
  /// **'Compare the value on your report with these ranges.'**
  String get labNormsHint;

  /// No description provided for @labelInfoChemical.
  ///
  /// In en, this message translates to:
  /// **'Chemical'**
  String get labelInfoChemical;

  /// No description provided for @labelInfoBio.
  ///
  /// In en, this message translates to:
  /// **'🌿 Organic / bio (registered biopesticides)'**
  String get labelInfoBio;

  /// No description provided for @labelInfoDilution.
  ///
  /// In en, this message translates to:
  /// **'Water on label: {value} L per hectare'**
  String labelInfoDilution(String value);

  /// No description provided for @labelInfoDilutionPrinted.
  ///
  /// In en, this message translates to:
  /// **'Water on label: {value}'**
  String labelInfoDilutionPrinted(String value);

  /// No description provided for @labelInfoBrands.
  ///
  /// In en, this message translates to:
  /// **'Brand names (A–Z, a plain list): {names}'**
  String labelInfoBrands(String names);

  /// No description provided for @labelInfoMakerPage.
  ///
  /// In en, this message translates to:
  /// **'Maker\'s product page'**
  String get labelInfoMakerPage;

  /// No description provided for @labelInfoTargetPrinted.
  ///
  /// In en, this message translates to:
  /// **'Target on label: {target}'**
  String labelInfoTargetPrinted(String target);

  /// No description provided for @labelInfoPage.
  ///
  /// In en, this message translates to:
  /// **'Page in source: {page}'**
  String labelInfoPage(String page);

  /// No description provided for @labelInfoNoClaim.
  ///
  /// In en, this message translates to:
  /// **'No registered label claim for {target} on citrus.'**
  String labelInfoNoClaim(String target);

  /// No description provided for @labelInfoBanned.
  ///
  /// In en, this message translates to:
  /// **'Outside the approved list'**
  String get labelInfoBanned;

  /// No description provided for @labelInfoRestricted.
  ///
  /// In en, this message translates to:
  /// **'Outside the approved list for this crop'**
  String get labelInfoRestricted;

  /// No description provided for @labelInfoAllTargets.
  ///
  /// In en, this message translates to:
  /// **'All pests and diseases'**
  String get labelInfoAllTargets;

  /// No description provided for @labelInfoOpenFor.
  ///
  /// In en, this message translates to:
  /// **'Label information: {target}'**
  String labelInfoOpenFor(String target);

  /// No description provided for @labelInfoSources.
  ///
  /// In en, this message translates to:
  /// **'Source documents ({count})'**
  String labelInfoSources(String count);

  /// No description provided for @labelInfoOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to see the full label details'**
  String get labelInfoOpenDetails;

  /// No description provided for @labelInfoDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Full label details'**
  String get labelInfoDetailsTitle;

  /// Bottom sheet title when a per-block action is tapped with no block yet.
  ///
  /// In en, this message translates to:
  /// **'Add your orchard block first'**
  String get noPlotTitle;

  /// Bottom sheet body under noPlotTitle; after saving the block the requested action opens.
  ///
  /// In en, this message translates to:
  /// **'Every record is kept for a block. Save your block once, and this opens straight after.'**
  String get noPlotBody;

  /// Add-block form: the place the phone geocoder names for the location. Display only, never stored.
  ///
  /// In en, this message translates to:
  /// **'Nearby place: {place}'**
  String plotAddressNear(String place);

  /// District part of the nearby-place line.
  ///
  /// In en, this message translates to:
  /// **'Dist. {district}'**
  String plotAddressDistrict(String district);

  /// Add-block form: while the place name is being looked up.
  ///
  /// In en, this message translates to:
  /// **'Finding the place name…'**
  String get plotAddressLooking;

  /// Add-block form: no place name (offline / no result); saving is not blocked.
  ///
  /// In en, this message translates to:
  /// **'The location will be saved. For the place name, turn on the internet and tap \'Take location again\'.'**
  String get plotAddressMissing;

  /// Helper under the name field: asks for the name in the app language script. Empty in English (no helper shown).
  ///
  /// In en, this message translates to:
  /// **''**
  String get onboardingNameHint;

  /// Home card when a Marathi/Hindi user saved a name in Latin letters: write it in the language script.
  ///
  /// In en, this message translates to:
  /// **'Write your name in your language'**
  String get nameScriptPromptTitle;

  /// Name field label in the home name card, with an example in the script.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameScriptFieldLabel;

  /// Hides the home name card for this language.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get nameScriptLater;

  /// No description provided for @adminMlQueue.
  ///
  /// In en, this message translates to:
  /// **'Verification queue'**
  String get adminMlQueue;

  /// No description provided for @adminMlTags.
  ///
  /// In en, this message translates to:
  /// **'Rating tags'**
  String get adminMlTags;

  /// No description provided for @adminMlLotSettings.
  ///
  /// In en, this message translates to:
  /// **'Lot form'**
  String get adminMlLotSettings;

  /// No description provided for @adminMlLotSettingsNote.
  ///
  /// In en, this message translates to:
  /// **'The rate range for each crop, per quintal and per crate, for the grower\'s asking rate and a trader\'s offer (the whole orchard has none), and how many days the harvest window runs after the start the grower picks. Empty = the default shown in grey; the server checks the rate again.'**
  String get adminMlLotSettingsNote;

  /// No description provided for @adminMlQuintalMin.
  ///
  /// In en, this message translates to:
  /// **'Per quintal: lowest ₹'**
  String get adminMlQuintalMin;

  /// No description provided for @adminMlQuintalMax.
  ///
  /// In en, this message translates to:
  /// **'Per quintal: highest ₹'**
  String get adminMlQuintalMax;

  /// No description provided for @adminMlCrateMin.
  ///
  /// In en, this message translates to:
  /// **'Per crate: lowest ₹'**
  String get adminMlCrateMin;

  /// No description provided for @adminMlCrateMax.
  ///
  /// In en, this message translates to:
  /// **'Per crate: highest ₹'**
  String get adminMlCrateMax;

  /// No description provided for @adminMlHarvestDays.
  ///
  /// In en, this message translates to:
  /// **'Harvest window (days)'**
  String get adminMlHarvestDays;

  /// No description provided for @adminMlCropSantra.
  ///
  /// In en, this message translates to:
  /// **'Santra (orange)'**
  String get adminMlCropSantra;

  /// No description provided for @adminMlCropMosambi.
  ///
  /// In en, this message translates to:
  /// **'Mosambi (sweet lime)'**
  String get adminMlCropMosambi;

  /// No description provided for @adminMlAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminMlAll;

  /// No description provided for @adminMlBuyer.
  ///
  /// In en, this message translates to:
  /// **'Trader'**
  String get adminMlBuyer;

  /// No description provided for @adminMlBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get adminMlBroker;

  /// No description provided for @adminMlProvider.
  ///
  /// In en, this message translates to:
  /// **'Service provider'**
  String get adminMlProvider;

  /// No description provided for @adminMlQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Everyone is checked'**
  String get adminMlQueueEmpty;

  /// No description provided for @adminMlWaitingSince.
  ///
  /// In en, this message translates to:
  /// **'Waiting since {date}'**
  String adminMlWaitingSince(String date);

  /// No description provided for @adminMlFields.
  ///
  /// In en, this message translates to:
  /// **'Submitted details'**
  String get adminMlFields;

  /// No description provided for @adminMlDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get adminMlDocuments;

  /// No description provided for @adminMlNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents appear here once sent'**
  String get adminMlNoDocuments;

  /// No description provided for @adminMlDocument.
  ///
  /// In en, this message translates to:
  /// **'Document {n}'**
  String adminMlDocument(int n);

  /// No description provided for @adminMlReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminMlReject;

  /// No description provided for @adminMlRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject with a reason'**
  String get adminMlRejectTitle;

  /// No description provided for @adminMlBadgeNote.
  ///
  /// In en, this message translates to:
  /// **'The verified badge shows only after approval; a later rejection removes it at once.'**
  String get adminMlBadgeNote;

  /// No description provided for @adminMlStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get adminMlStatusPending;

  /// No description provided for @adminMlStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get adminMlStatusApproved;

  /// No description provided for @adminMlStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminMlStatusRejected;

  /// No description provided for @adminMlCheckedBy.
  ///
  /// In en, this message translates to:
  /// **'by {who}'**
  String adminMlCheckedBy(String who);

  /// No description provided for @adminMlTagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Rating tags appear here'**
  String get adminMlTagsEmpty;

  /// No description provided for @adminMlTagsNote.
  ///
  /// In en, this message translates to:
  /// **'Drafts wait for a native-speaker check; only active tags reach the app.'**
  String get adminMlTagsNote;

  /// No description provided for @adminMlTagDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get adminMlTagDraft;

  /// No description provided for @adminMlTagActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminMlTagActive;

  /// No description provided for @adminMlTagRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get adminMlTagRetired;

  /// No description provided for @adminMlPositive.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get adminMlPositive;

  /// No description provided for @adminMlNegative.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get adminMlNegative;

  /// No description provided for @adminMlEditTag.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get adminMlEditTag;

  /// No description provided for @adminMlLabelEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get adminMlLabelEn;

  /// No description provided for @adminMlLabelMr.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get adminMlLabelMr;

  /// No description provided for @adminMlLabelHi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get adminMlLabelHi;

  /// No description provided for @adminMlYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get adminMlYes;

  /// No description provided for @adminMlNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get adminMlNo;

  /// No description provided for @adminMlFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminMlFieldName;

  /// No description provided for @adminMlFieldFirm.
  ///
  /// In en, this message translates to:
  /// **'Firm'**
  String get adminMlFieldFirm;

  /// No description provided for @adminMlFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get adminMlFieldPhone;

  /// No description provided for @adminMlFieldMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get adminMlFieldMarkets;

  /// No description provided for @adminMlFieldDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get adminMlFieldDistrict;

  /// No description provided for @adminMlFieldTaluka.
  ///
  /// In en, this message translates to:
  /// **'Taluka'**
  String get adminMlFieldTaluka;

  /// No description provided for @adminMlFieldVillage.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get adminMlFieldVillage;

  /// No description provided for @adminMlFieldCrops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get adminMlFieldCrops;

  /// No description provided for @adminMlFieldServiceAreas.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get adminMlFieldServiceAreas;

  /// No description provided for @adminMlFieldApmc.
  ///
  /// In en, this message translates to:
  /// **'APMC licence no.'**
  String get adminMlFieldApmc;

  /// No description provided for @adminMlFieldGst.
  ///
  /// In en, this message translates to:
  /// **'GST no.'**
  String get adminMlFieldGst;

  /// No description provided for @adminMlFieldKind.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get adminMlFieldKind;

  /// No description provided for @adminMlFieldCertValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Certificate valid until'**
  String get adminMlFieldCertValidUntil;

  /// No description provided for @adminMlFieldVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicle numbers'**
  String get adminMlFieldVehicles;

  /// No description provided for @adminMlFieldCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity (t)'**
  String get adminMlFieldCapacity;

  /// No description provided for @adminMlFieldRefrigerated.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated'**
  String get adminMlFieldRefrigerated;

  /// No description provided for @adminMlFieldCarrierReg.
  ///
  /// In en, this message translates to:
  /// **'Carrier registration no.'**
  String get adminMlFieldCarrierReg;

  /// No description provided for @adminMlKindWeighbridge.
  ///
  /// In en, this message translates to:
  /// **'Weighbridge'**
  String get adminMlKindWeighbridge;

  /// No description provided for @adminMlKindTransporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get adminMlKindTransporter;

  /// No description provided for @adminMlKindLabourGang.
  ///
  /// In en, this message translates to:
  /// **'Labour gang'**
  String get adminMlKindLabourGang;

  /// No description provided for @adminMlKindCrateSupplier.
  ///
  /// In en, this message translates to:
  /// **'Crate supplier'**
  String get adminMlKindCrateSupplier;

  /// No description provided for @adminMlChecks.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get adminMlChecks;

  /// No description provided for @adminMlChecksNote.
  ///
  /// In en, this message translates to:
  /// **'Open the official page, paste the number (it is copied), check by hand and record the result. A badge says only what was checked and when.'**
  String get adminMlChecksNote;

  /// No description provided for @adminMlOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Open official page'**
  String get adminMlOpenPage;

  /// No description provided for @adminMlCallNow.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get adminMlCallNow;

  /// No description provided for @adminMlRecordResult.
  ///
  /// In en, this message translates to:
  /// **'Record result'**
  String get adminMlRecordResult;

  /// No description provided for @adminMlNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied: {number}'**
  String adminMlNumberCopied(String number);

  /// No description provided for @adminMlResultPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get adminMlResultPassed;

  /// No description provided for @adminMlResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminMlResultFailed;

  /// No description provided for @adminMlResultCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled / deactivated'**
  String get adminMlResultCancelled;

  /// No description provided for @adminMlRegisteredYear.
  ///
  /// In en, this message translates to:
  /// **'GST registration year (optional)'**
  String get adminMlRegisteredYear;

  /// No description provided for @adminMlNoChecks.
  ///
  /// In en, this message translates to:
  /// **'Checks you record show here'**
  String get adminMlNoChecks;

  /// No description provided for @adminMlCheckApmc.
  ///
  /// In en, this message translates to:
  /// **'APMC licence'**
  String get adminMlCheckApmc;

  /// No description provided for @adminMlCheckPhoneCall.
  ///
  /// In en, this message translates to:
  /// **'Phone call'**
  String get adminMlCheckPhoneCall;

  /// No description provided for @adminMlCheckPlacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Place photo'**
  String get adminMlCheckPlacePhoto;

  /// No description provided for @adminMlRegisteredSince.
  ///
  /// In en, this message translates to:
  /// **'registered {year}'**
  String adminMlRegisteredSince(String year);

  /// No description provided for @adminMlFlags.
  ///
  /// In en, this message translates to:
  /// **'Look before approving'**
  String get adminMlFlags;

  /// No description provided for @adminMlFlagDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Same number on another profile'**
  String get adminMlFlagDuplicate;

  /// No description provided for @adminMlFlagReturning.
  ///
  /// In en, this message translates to:
  /// **'Matches a suspended profile'**
  String get adminMlFlagReturning;

  /// No description provided for @adminMlFlagMock.
  ///
  /// In en, this message translates to:
  /// **'Location looked fake (mock)'**
  String get adminMlFlagMock;

  /// No description provided for @adminMlFlagOtherDistrict.
  ///
  /// In en, this message translates to:
  /// **'Registered outside the stated district'**
  String get adminMlFlagOtherDistrict;

  /// No description provided for @adminMlFlagNoPlace.
  ///
  /// In en, this message translates to:
  /// **'Place name blank from the phone'**
  String get adminMlFlagNoPlace;

  /// No description provided for @adminMlWhyName.
  ///
  /// In en, this message translates to:
  /// **'same name'**
  String get adminMlWhyName;

  /// No description provided for @adminMlWhyGps.
  ///
  /// In en, this message translates to:
  /// **'registered nearby'**
  String get adminMlWhyGps;

  /// No description provided for @adminMlWhyAccount.
  ///
  /// In en, this message translates to:
  /// **'same sign-in'**
  String get adminMlWhyAccount;

  /// No description provided for @adminMlRechecks.
  ///
  /// In en, this message translates to:
  /// **'Re-checks due'**
  String get adminMlRechecks;

  /// No description provided for @adminMlRechecksEmpty.
  ///
  /// In en, this message translates to:
  /// **'All yearly re-checks are done'**
  String get adminMlRechecksEmpty;

  /// No description provided for @adminMlLastChecked.
  ///
  /// In en, this message translates to:
  /// **'last checked {date}'**
  String adminMlLastChecked(String date);

  /// No description provided for @adminMlDocumentCount.
  ///
  /// In en, this message translates to:
  /// **'Documents: {n}'**
  String adminMlDocumentCount(int n);

  /// No description provided for @mlRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get mlRolesTitle;

  /// No description provided for @mlRolesIntro.
  ///
  /// In en, this message translates to:
  /// **'One sign-in for every role. You can switch the role any time.'**
  String get mlRolesIntro;

  /// No description provided for @mlRoleGrower.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get mlRoleGrower;

  /// No description provided for @mlRoleTrader.
  ///
  /// In en, this message translates to:
  /// **'Trader'**
  String get mlRoleTrader;

  /// No description provided for @mlRoleBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get mlRoleBroker;

  /// No description provided for @mlRoleExporter.
  ///
  /// In en, this message translates to:
  /// **'Exporter'**
  String get mlRoleExporter;

  /// No description provided for @mlRoleProvider.
  ///
  /// In en, this message translates to:
  /// **'Service provider'**
  String get mlRoleProvider;

  /// No description provided for @mlRoleProviderKinds.
  ///
  /// In en, this message translates to:
  /// **'Weighbridge, transport, labour, crates'**
  String get mlRoleProviderKinds;

  /// No description provided for @mlRoleCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current role'**
  String get mlRoleCurrent;

  /// No description provided for @mlSwitchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch role'**
  String get mlSwitchRole;

  /// No description provided for @mlHomeLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Market link'**
  String get mlHomeLinkTitle;

  /// No description provided for @mlHomeLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Trader, broker, exporter, services: choose a role'**
  String get mlHomeLinkHint;

  /// No description provided for @mlTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get mlTermsTitle;

  /// Acceptance screen: the role being accepted.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String mlTermsRole(String role);

  /// No description provided for @mlTermsIntroOnly.
  ///
  /// In en, this message translates to:
  /// **'BagMitra only gives information and introduces you to traders, brokers and the market.'**
  String get mlTermsIntroOnly;

  /// No description provided for @mlTermsNotParty.
  ///
  /// In en, this message translates to:
  /// **'BagMitra is not a buyer, seller, commission agent or transporter.'**
  String get mlTermsNotParty;

  /// No description provided for @mlTermsNoMoney.
  ///
  /// In en, this message translates to:
  /// **'It holds no money and guarantees no payment or quality.'**
  String get mlTermsNoMoney;

  /// Owner's disclaimer (mr verbatim). Uses 'transaction' (व्यवहार), never सौदा.
  ///
  /// In en, this message translates to:
  /// **'This app has no gain or loss in your transaction.'**
  String get mlTermsNoGainLoss;

  /// No description provided for @mlTermsNoPart.
  ///
  /// In en, this message translates to:
  /// **'It takes no part in your transaction or in any dispute.'**
  String get mlTermsNoPart;

  /// No description provided for @mlTermsAfterDeal.
  ///
  /// In en, this message translates to:
  /// **'What to record after a transaction is your choice.'**
  String get mlTermsAfterDeal;

  /// No description provided for @mlTermsPublicPhone.
  ///
  /// In en, this message translates to:
  /// **'Your phone number is shown publicly on your profile, so growers can call you directly.'**
  String get mlTermsPublicPhone;

  /// No description provided for @mlTermsGpsOnce.
  ///
  /// In en, this message translates to:
  /// **'Your location (GPS) is taken once, at registration, to prevent fraud.'**
  String get mlTermsGpsOnce;

  /// No description provided for @mlTermsFull.
  ///
  /// In en, this message translates to:
  /// **'Full terms of use'**
  String get mlTermsFull;

  /// No description provided for @mlTermsAdult.
  ///
  /// In en, this message translates to:
  /// **'I am over 18 years of age'**
  String get mlTermsAdult;

  /// No description provided for @mlTermsAgree.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree'**
  String get mlTermsAgree;

  /// No description provided for @mlTermsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get mlTermsAccept;

  /// No description provided for @mlTermsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mlTermsBack;

  /// Fixed notice on every market-link role home (spec v1.5 §4C).
  ///
  /// In en, this message translates to:
  /// **'BagMitra never asks for money, OTP or bank details.'**
  String get mlSafetyNotice;

  /// No description provided for @mlGrievanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Grievance officer'**
  String get mlGrievanceTitle;

  /// No description provided for @mlGrievanceOwner.
  ///
  /// In en, this message translates to:
  /// **'BagMitra owner'**
  String get mlGrievanceOwner;

  /// Role home: the grievance officer's phone or email.
  ///
  /// In en, this message translates to:
  /// **'Contact: {contact}'**
  String mlGrievanceContact(String contact);

  /// No description provided for @mlGrievanceTimes.
  ///
  /// In en, this message translates to:
  /// **'Complaints are acknowledged within 24 hours and resolved within 15 days.'**
  String get mlGrievanceTimes;

  /// No description provided for @mlKindWeighbridge.
  ///
  /// In en, this message translates to:
  /// **'Weighbridge'**
  String get mlKindWeighbridge;

  /// No description provided for @mlKindTransporter.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get mlKindTransporter;

  /// No description provided for @mlKindLabourGang.
  ///
  /// In en, this message translates to:
  /// **'Labour gang'**
  String get mlKindLabourGang;

  /// No description provided for @mlKindCrateSupplier.
  ///
  /// In en, this message translates to:
  /// **'Crate supplier'**
  String get mlKindCrateSupplier;

  /// No description provided for @mlRegisterTrader.
  ///
  /// In en, this message translates to:
  /// **'Trader registration'**
  String get mlRegisterTrader;

  /// No description provided for @mlRegisterExporter.
  ///
  /// In en, this message translates to:
  /// **'Exporter registration'**
  String get mlRegisterExporter;

  /// No description provided for @mlRegisterBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker registration'**
  String get mlRegisterBroker;

  /// No description provided for @mlRegisterProvider.
  ///
  /// In en, this message translates to:
  /// **'Service provider registration'**
  String get mlRegisterProvider;

  /// No description provided for @mlRegisterAs.
  ///
  /// In en, this message translates to:
  /// **'Register as'**
  String get mlRegisterAs;

  /// No description provided for @mlFixTitle.
  ///
  /// In en, this message translates to:
  /// **'Location at registration'**
  String get mlFixTitle;

  /// No description provided for @mlFixWhy.
  ///
  /// In en, this message translates to:
  /// **'To finish registration, the phone takes your current location once. This keeps fake registrations away.'**
  String get mlFixWhy;

  /// No description provided for @mlFixOnce.
  ///
  /// In en, this message translates to:
  /// **'Taken once, right now. Your public profile shows only village, taluka and district; the exact point is for BagMitra\'s check.'**
  String get mlFixOnce;

  /// No description provided for @mlPhonePublicNote.
  ///
  /// In en, this message translates to:
  /// **'After the check, your name, firm and contact number are shown to registered growers.'**
  String get mlPhonePublicNote;

  /// No description provided for @mlFixTake.
  ///
  /// In en, this message translates to:
  /// **'Take location'**
  String get mlFixTake;

  /// No description provided for @mlFixTaking.
  ///
  /// In en, this message translates to:
  /// **'Taking location…'**
  String get mlFixTaking;

  /// No description provided for @mlFixDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location to finish registration.'**
  String get mlFixDenied;

  /// No description provided for @mlFixTaken.
  ///
  /// In en, this message translates to:
  /// **'Location taken: {place} (±{metres} m)'**
  String mlFixTaken(String place, String metres);

  /// No description provided for @mlPickKind.
  ///
  /// In en, this message translates to:
  /// **'What service do you give?'**
  String get mlPickKind;

  /// No description provided for @mlFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get mlFieldName;

  /// No description provided for @mlFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact number'**
  String get mlFieldPhone;

  /// No description provided for @mlFieldFirm.
  ///
  /// In en, this message translates to:
  /// **'Firm name (optional)'**
  String get mlFieldFirm;

  /// No description provided for @mlFieldVillage.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get mlFieldVillage;

  /// No description provided for @mlFieldTaluka.
  ///
  /// In en, this message translates to:
  /// **'Taluka'**
  String get mlFieldTaluka;

  /// No description provided for @mlFieldDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get mlFieldDistrict;

  /// No description provided for @mlFieldMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets / villages (comma between)'**
  String get mlFieldMarkets;

  /// No description provided for @mlFieldAreas.
  ///
  /// In en, this message translates to:
  /// **'Areas you serve (comma between)'**
  String get mlFieldAreas;

  /// No description provided for @mlFieldCrops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get mlFieldCrops;

  /// No description provided for @mlFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get mlFieldAddress;

  /// No description provided for @mlFieldGst.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get mlFieldGst;

  /// No description provided for @mlFieldApmc.
  ///
  /// In en, this message translates to:
  /// **'APMC licence no.'**
  String get mlFieldApmc;

  /// No description provided for @mlFieldFssai.
  ///
  /// In en, this message translates to:
  /// **'FSSAI licence no.'**
  String get mlFieldFssai;

  /// No description provided for @mlFieldIec.
  ///
  /// In en, this message translates to:
  /// **'IEC no.'**
  String get mlFieldIec;

  /// No description provided for @mlFieldApeda.
  ///
  /// In en, this message translates to:
  /// **'APEDA registration no.'**
  String get mlFieldApeda;

  /// No description provided for @mlFieldVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicle numbers (comma between)'**
  String get mlFieldVehicles;

  /// No description provided for @mlFieldCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity (tonnes)'**
  String get mlFieldCapacity;

  /// No description provided for @mlFieldRefrigerated.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated vehicle'**
  String get mlFieldRefrigerated;

  /// No description provided for @mlFieldCertUntil.
  ///
  /// In en, this message translates to:
  /// **'Certificate valid until'**
  String get mlFieldCertUntil;

  /// No description provided for @mlCertUntilValue.
  ///
  /// In en, this message translates to:
  /// **'Certificate valid until {date}'**
  String mlCertUntilValue(String date);

  /// No description provided for @mlNumbersNote.
  ///
  /// In en, this message translates to:
  /// **'Give at least one: GSTIN, APMC licence or IEC. BagMitra checks it on the official public register.'**
  String get mlNumbersNote;

  /// No description provided for @mlIecRequired.
  ///
  /// In en, this message translates to:
  /// **'An exporter registers with an IEC number.'**
  String get mlIecRequired;

  /// No description provided for @mlBrokerCallNote.
  ///
  /// In en, this message translates to:
  /// **'BagMitra calls you on this number to complete the check.'**
  String get mlBrokerCallNote;

  /// No description provided for @mlErrPhone.
  ///
  /// In en, this message translates to:
  /// **'Write a 10-digit mobile number'**
  String get mlErrPhone;

  /// No description provided for @mlErrGst.
  ///
  /// In en, this message translates to:
  /// **'Write the 15-character GSTIN'**
  String get mlErrGst;

  /// No description provided for @mlErrIec.
  ///
  /// In en, this message translates to:
  /// **'Write the 10-character IEC'**
  String get mlErrIec;

  /// No description provided for @mlErrFssai.
  ///
  /// In en, this message translates to:
  /// **'Write the 14-digit FSSAI number'**
  String get mlErrFssai;

  /// No description provided for @mlErrCapacity.
  ///
  /// In en, this message translates to:
  /// **'Write the capacity in tonnes (up to 100)'**
  String get mlErrCapacity;

  /// No description provided for @mlErrOneNumber.
  ///
  /// In en, this message translates to:
  /// **'Write a GSTIN, APMC licence or IEC number'**
  String get mlErrOneNumber;

  /// No description provided for @mlErrPickKind.
  ///
  /// In en, this message translates to:
  /// **'Pick the service you give'**
  String get mlErrPickKind;

  /// No description provided for @mlErrCertDate.
  ///
  /// In en, this message translates to:
  /// **'Pick the certificate\'s valid-until date'**
  String get mlErrCertDate;

  /// No description provided for @mlErrFixStale.
  ///
  /// In en, this message translates to:
  /// **'Take the location again, then send'**
  String get mlErrFixStale;

  /// No description provided for @mlErrExists.
  ///
  /// In en, this message translates to:
  /// **'You are already registered in this role; see My market registration'**
  String get mlErrExists;

  /// No description provided for @mlErrCheckFields.
  ///
  /// In en, this message translates to:
  /// **'Check the entries and send again'**
  String get mlErrCheckFields;

  /// No description provided for @mlSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send registration'**
  String get mlSubmit;

  /// No description provided for @mlSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Registration sent. BagMitra will check it.'**
  String get mlSubmitted;

  /// No description provided for @mlOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to see this'**
  String get mlOffline;

  /// No description provided for @mlServerBusy.
  ///
  /// In en, this message translates to:
  /// **'The server is busy; try again in a while'**
  String get mlServerBusy;

  /// No description provided for @mlRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get mlRetry;

  /// No description provided for @mlMyProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'My market registration'**
  String get mlMyProfilesTitle;

  /// No description provided for @mlMyProfilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Register below as a trader, exporter, broker or service provider.'**
  String get mlMyProfilesEmpty;

  /// No description provided for @mlStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Check pending'**
  String get mlStatusPending;

  /// No description provided for @mlStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Checked by BagMitra'**
  String get mlStatusApproved;

  /// No description provided for @mlStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Sent back; see the reason'**
  String get mlStatusRejected;

  /// No description provided for @mlCheckNote.
  ///
  /// In en, this message translates to:
  /// **'Your profile is shown to growers after BagMitra\'s check. Document photos help the check.'**
  String get mlCheckNote;

  /// No description provided for @mlDocsCount.
  ///
  /// In en, this message translates to:
  /// **'Document photos: {count}'**
  String mlDocsCount(String count);

  /// No description provided for @mlDocCertificate.
  ///
  /// In en, this message translates to:
  /// **'Weighbridge certificate'**
  String get mlDocCertificate;

  /// No description provided for @mlCertExpired.
  ///
  /// In en, this message translates to:
  /// **'Certificate date passed ({date})'**
  String mlCertExpired(String date);

  /// No description provided for @mlAddressAdd.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get mlAddressAdd;

  /// No description provided for @mlAddressEdit.
  ///
  /// In en, this message translates to:
  /// **'Change address'**
  String get mlAddressEdit;

  /// No description provided for @mlCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mlCancel;

  /// No description provided for @mlSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mlSave;

  /// No description provided for @mlPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Traders and brokers'**
  String get mlPeopleTitle;

  /// No description provided for @mlPeopleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Checked traders and brokers of this area will show here.'**
  String get mlPeopleEmpty;

  /// No description provided for @mlAreaTaluka.
  ///
  /// In en, this message translates to:
  /// **'Taluka {taluka}'**
  String mlAreaTaluka(String taluka);

  /// No description provided for @mlAreaDistrict.
  ///
  /// In en, this message translates to:
  /// **'District {district}'**
  String mlAreaDistrict(String district);

  /// No description provided for @mlSortRating.
  ///
  /// In en, this message translates to:
  /// **'By rating'**
  String get mlSortRating;

  /// No description provided for @mlSortDeals.
  ///
  /// In en, this message translates to:
  /// **'By deals'**
  String get mlSortDeals;

  /// No description provided for @mlDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals done: {count}'**
  String mlDeals(String count);

  /// No description provided for @mlStars.
  ///
  /// In en, this message translates to:
  /// **'{average}/5 ({count})'**
  String mlStars(String average, String count);

  /// No description provided for @mlDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String mlDistanceKm(String km);

  /// No description provided for @mlBadgeChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked by BagMitra on {date}'**
  String mlBadgeChecked(String date);

  /// No description provided for @mlBadgeRegisteredFrom.
  ///
  /// In en, this message translates to:
  /// **'Registered from {place} on {date}'**
  String mlBadgeRegisteredFrom(String place, String date);

  /// No description provided for @mlBadgePlacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Place photo by a BagMitra representative on {date}'**
  String mlBadgePlacePhoto(String date);

  /// No description provided for @mlBadgeNote.
  ///
  /// In en, this message translates to:
  /// **'A badge says what BagMitra checked and when. You settle the deal terms directly with each other.'**
  String get mlBadgeNote;

  /// No description provided for @mlCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get mlCall;

  /// No description provided for @mlCallNumber.
  ///
  /// In en, this message translates to:
  /// **'Call {phone}'**
  String mlCallNumber(String phone);

  /// No description provided for @mlRatingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get mlRatingsTitle;

  /// No description provided for @mlQTraderOnDate.
  ///
  /// In en, this message translates to:
  /// **'Came on the agreed harvest date'**
  String get mlQTraderOnDate;

  /// No description provided for @mlQTraderWeighing.
  ///
  /// In en, this message translates to:
  /// **'Weighing / crate count correct'**
  String get mlQTraderWeighing;

  /// No description provided for @mlQTraderPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid advance and balance as agreed'**
  String get mlQTraderPaid;

  /// No description provided for @mlQTraderConditions.
  ///
  /// In en, this message translates to:
  /// **'Kept the other conditions'**
  String get mlQTraderConditions;

  /// No description provided for @mlQBrokerHonest.
  ///
  /// In en, this message translates to:
  /// **'Represented the deal honestly'**
  String get mlQBrokerHonest;

  /// No description provided for @mlQBrokerTraderKept.
  ///
  /// In en, this message translates to:
  /// **'The trader they brought kept the deal'**
  String get mlQBrokerTraderKept;

  /// No description provided for @mlAreaAll.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get mlAreaAll;

  /// No description provided for @mlMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets / villages'**
  String get mlMarkets;

  /// No description provided for @mlAreas.
  ///
  /// In en, this message translates to:
  /// **'Areas served'**
  String get mlAreas;

  /// No description provided for @mlServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Service providers'**
  String get mlServicesTitle;

  /// No description provided for @mlServicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Checked weighbridges, transport, labour gangs and crate suppliers near you will show here.'**
  String get mlServicesEmpty;

  /// No description provided for @mlServicesNote.
  ///
  /// In en, this message translates to:
  /// **'Call them and agree directly; rates and payment are between you.'**
  String get mlServicesNote;

  /// No description provided for @mlNearPlot.
  ///
  /// In en, this message translates to:
  /// **'Near {name}'**
  String mlNearPlot(String name);

  /// No description provided for @mlDisclaimerShort.
  ///
  /// In en, this message translates to:
  /// **'BagMitra is not a buyer, seller, middleman (broker) or transporter, does not hold money and does not guarantee payment or quality.'**
  String get mlDisclaimerShort;

  /// No description provided for @mlOpen.
  ///
  /// In en, this message translates to:
  /// **'Show produce for sale'**
  String get mlOpen;

  /// No description provided for @mlMyLotsTitle.
  ///
  /// In en, this message translates to:
  /// **'My produce for sale'**
  String get mlMyLotsTitle;

  /// No description provided for @mlLotsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Show your produce here with photos; verified traders and middlemen (brokers) see it.'**
  String get mlLotsEmpty;

  /// No description provided for @mlLotFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Produce for sale'**
  String get mlLotFormTitle;

  /// No description provided for @mlNoPlot.
  ///
  /// In en, this message translates to:
  /// **'Add your orchard first.'**
  String get mlNoPlot;

  /// No description provided for @mlPlot.
  ///
  /// In en, this message translates to:
  /// **'Orchard'**
  String get mlPlot;

  /// No description provided for @mlBahar.
  ///
  /// In en, this message translates to:
  /// **'Bahar'**
  String get mlBahar;

  /// No description provided for @mlQuantity.
  ///
  /// In en, this message translates to:
  /// **'Estimated quantity (tonnes)'**
  String get mlQuantity;

  /// No description provided for @mlQuality.
  ///
  /// In en, this message translates to:
  /// **'Size and quality'**
  String get mlQuality;

  /// No description provided for @mlHarvestWindow.
  ///
  /// In en, this message translates to:
  /// **'Harvest window'**
  String get mlHarvestWindow;

  /// No description provided for @mlWindowRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String mlWindowRange(String from, String to);

  /// No description provided for @mlBasis.
  ///
  /// In en, this message translates to:
  /// **'Sale basis'**
  String get mlBasis;

  /// No description provided for @mlBasisPerQuintal.
  ///
  /// In en, this message translates to:
  /// **'Per quintal'**
  String get mlBasisPerQuintal;

  /// No description provided for @mlBasisPerCrate.
  ///
  /// In en, this message translates to:
  /// **'Per crate'**
  String get mlBasisPerCrate;

  /// No description provided for @mlBasisLumpSum.
  ///
  /// In en, this message translates to:
  /// **'Whole orchard'**
  String get mlBasisLumpSum;

  /// No description provided for @mlAskingRate.
  ///
  /// In en, this message translates to:
  /// **'Asking rate in ₹ (optional)'**
  String get mlAskingRate;

  /// No description provided for @mlHarvestFrom.
  ///
  /// In en, this message translates to:
  /// **'Harvest from'**
  String get mlHarvestFrom;

  /// No description provided for @mlHarvestTo.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get mlHarvestTo;

  /// No description provided for @mlHarvestPickDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get mlHarvestPickDate;

  /// No description provided for @mlHarvestFromBahar.
  ///
  /// In en, this message translates to:
  /// **'{date} (bahar)'**
  String mlHarvestFromBahar(String date);

  /// No description provided for @mlHarvestAutoEnd.
  ///
  /// In en, this message translates to:
  /// **'Until is set {days} days after the start; change it if you like.'**
  String mlHarvestAutoEnd(String days);

  /// No description provided for @mlHarvestChangeEnd.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get mlHarvestChangeEnd;

  /// No description provided for @mlAskingRatePerQuintal.
  ///
  /// In en, this message translates to:
  /// **'Asking rate ₹ / quintal (optional)'**
  String get mlAskingRatePerQuintal;

  /// No description provided for @mlAskingRatePerCrate.
  ///
  /// In en, this message translates to:
  /// **'Asking rate ₹ / crate (optional)'**
  String get mlAskingRatePerCrate;

  /// No description provided for @mlAskingRateLumpSum.
  ///
  /// In en, this message translates to:
  /// **'Asking rate ₹ for the whole orchard (optional)'**
  String get mlAskingRateLumpSum;

  /// No description provided for @mlRateRangePerQuintal.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max} per quintal'**
  String mlRateRangePerQuintal(String min, String max);

  /// No description provided for @mlRateRangePerCrate.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max} per crate'**
  String mlRateRangePerCrate(String min, String max);

  /// No description provided for @mlRateOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Please write a rate from {min} to {max}.'**
  String mlRateOutOfRange(String min, String max);

  /// No description provided for @mlPublishRateRange.
  ///
  /// In en, this message translates to:
  /// **'Please keep the asking rate within the range shown, then send again.'**
  String get mlPublishRateRange;

  /// No description provided for @mlOfferRateRange.
  ///
  /// In en, this message translates to:
  /// **'Please keep the rate within the range shown, then send again.'**
  String get mlOfferRateRange;

  /// No description provided for @mlPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get mlPhotos;

  /// No description provided for @mlPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} photos from the app camera'**
  String mlPhotosHint(String min, String max);

  /// No description provided for @mlAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get mlAddPhoto;

  /// No description provided for @mlRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get mlRemovePhoto;

  /// No description provided for @mlPhotoNoGps.
  ///
  /// In en, this message translates to:
  /// **'Turn on GPS and take the photo again: each photo needs its location.'**
  String get mlPhotoNoGps;

  /// No description provided for @mlPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Traders see only your village, taluka and district; your name, phone and orchard location stay private.'**
  String get mlPrivacy;

  /// No description provided for @mlSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get mlSaveDraft;

  /// No description provided for @mlPublish.
  ///
  /// In en, this message translates to:
  /// **'Show to traders'**
  String get mlPublish;

  /// No description provided for @mlClose.
  ///
  /// In en, this message translates to:
  /// **'Stop showing'**
  String get mlClose;

  /// No description provided for @mlStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get mlStatusDraft;

  /// No description provided for @mlStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Shown to traders'**
  String get mlStatusPublished;

  /// No description provided for @mlStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for check'**
  String get mlStatusReview;

  /// No description provided for @mlStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get mlStatusClosed;

  /// No description provided for @mlTonnes.
  ///
  /// In en, this message translates to:
  /// **'{value} t'**
  String mlTonnes(String value);

  /// No description provided for @mlRatePerQuintal.
  ///
  /// In en, this message translates to:
  /// **'{rate} per quintal'**
  String mlRatePerQuintal(String rate);

  /// No description provided for @mlRatePerCrate.
  ///
  /// In en, this message translates to:
  /// **'{rate} per crate'**
  String mlRatePerCrate(String rate);

  /// No description provided for @mlRateLumpSum.
  ///
  /// In en, this message translates to:
  /// **'{rate} for the orchard'**
  String mlRateLumpSum(String rate);

  /// No description provided for @mlPublished.
  ///
  /// In en, this message translates to:
  /// **'Now shown to verified traders and middlemen (brokers).'**
  String get mlPublished;

  /// No description provided for @mlClosed.
  ///
  /// In en, this message translates to:
  /// **'Taken off the traders\' list.'**
  String get mlClosed;

  /// No description provided for @mlPublishOffline.
  ///
  /// In en, this message translates to:
  /// **'This needs internet. Your draft is saved; try again when online.'**
  String get mlPublishOffline;

  /// No description provided for @mlPublishNeedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add {min} to {max} photos first.'**
  String mlPublishNeedPhotos(String min, String max);

  /// No description provided for @mlPublishPhotoMissing.
  ///
  /// In en, this message translates to:
  /// **'Remove that photo and take it again: its file is missing on this phone.'**
  String get mlPublishPhotoMissing;

  /// No description provided for @mlPublishNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accept the grower terms first, then try again.'**
  String get mlPublishNotAccepted;

  /// No description provided for @mlPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Try again in a little while.'**
  String get mlPublishFailed;

  /// No description provided for @mlChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose one'**
  String get mlChooseOne;

  /// No description provided for @mlDeleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get mlDeleteDraft;

  /// No description provided for @mlNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Write only about the produce here; phone numbers and links are shared after you accept an offer.'**
  String get mlNoContacts;

  /// No description provided for @mlPublishOrchardCheck.
  ///
  /// In en, this message translates to:
  /// **'Published; traders see it after a check, because the photos were taken outside your mapped orchard.'**
  String get mlPublishOrchardCheck;

  /// No description provided for @mlSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get mlSize;

  /// No description provided for @mlGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get mlGrade;

  /// No description provided for @mlQualityLine.
  ///
  /// In en, this message translates to:
  /// **'A short line (optional)'**
  String get mlQualityLine;

  /// No description provided for @mlSafetyReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get mlSafetyReport;

  /// No description provided for @mlSafetyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report to BagMitra'**
  String get mlSafetyReportTitle;

  /// No description provided for @mlSafetyReportWhy.
  ///
  /// In en, this message translates to:
  /// **'Choose the reason'**
  String get mlSafetyReportWhy;

  /// No description provided for @mlSafetyReportNote.
  ///
  /// In en, this message translates to:
  /// **'BagMitra only introduces people. Report a fake identity, a fake lot, someone pretending to be BagMitra, a fake rating or abuse; payment, weight and quality are settled between you.'**
  String get mlSafetyReportNote;

  /// No description provided for @mlSafetyPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo (if you wish)'**
  String get mlSafetyPhoto;

  /// No description provided for @mlSafetyPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get mlSafetyPhotoAdded;

  /// No description provided for @mlSafetySend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get mlSafetySend;

  /// No description provided for @mlSafetySent.
  ///
  /// In en, this message translates to:
  /// **'Report received. BagMitra will check it.'**
  String get mlSafetySent;

  /// No description provided for @mlSafetyRetry.
  ///
  /// In en, this message translates to:
  /// **'Check the internet and try again'**
  String get mlSafetyRetry;

  /// No description provided for @mlReasonFakeIdentity.
  ///
  /// In en, this message translates to:
  /// **'Fake identity'**
  String get mlReasonFakeIdentity;

  /// No description provided for @mlReasonFakeLot.
  ///
  /// In en, this message translates to:
  /// **'Fake lot or photos from another orchard'**
  String get mlReasonFakeLot;

  /// No description provided for @mlReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Pretends to be BagMitra'**
  String get mlReasonImpersonation;

  /// No description provided for @mlReasonFakeRating.
  ///
  /// In en, this message translates to:
  /// **'Fake rating'**
  String get mlReasonFakeRating;

  /// No description provided for @mlReasonAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abusive behaviour'**
  String get mlReasonAbuse;

  /// No description provided for @mlReasonDuplicateUser.
  ///
  /// In en, this message translates to:
  /// **'Same person, two accounts'**
  String get mlReasonDuplicateUser;

  /// No description provided for @mlReasonChecksPassed.
  ///
  /// In en, this message translates to:
  /// **'Checks passed'**
  String get mlReasonChecksPassed;

  /// No description provided for @mlReasonAppealUpheld.
  ///
  /// In en, this message translates to:
  /// **'Appeal accepted'**
  String get mlReasonAppealUpheld;

  /// No description provided for @mlActionVerify.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get mlActionVerify;

  /// No description provided for @mlActionWarn.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get mlActionWarn;

  /// No description provided for @mlActionHide.
  ///
  /// In en, this message translates to:
  /// **'Hidden from lists'**
  String get mlActionHide;

  /// No description provided for @mlActionSuspend.
  ///
  /// In en, this message translates to:
  /// **'Account paused'**
  String get mlActionSuspend;

  /// No description provided for @mlActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get mlActionRestore;

  /// No description provided for @mlAppealIdentityGenuine.
  ///
  /// In en, this message translates to:
  /// **'My identity is genuine'**
  String get mlAppealIdentityGenuine;

  /// No description provided for @mlAppealLotGenuine.
  ///
  /// In en, this message translates to:
  /// **'My lot and photos are genuine'**
  String get mlAppealLotGenuine;

  /// No description provided for @mlAppealRatingGenuine.
  ///
  /// In en, this message translates to:
  /// **'This rating is from a real deal'**
  String get mlAppealRatingGenuine;

  /// No description provided for @mlAppealBehaviourProper.
  ///
  /// In en, this message translates to:
  /// **'My behaviour was proper'**
  String get mlAppealBehaviourProper;

  /// No description provided for @mlAppealNotDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This is my only account'**
  String get mlAppealNotDuplicate;

  /// No description provided for @mlAppealStateAppealed.
  ///
  /// In en, this message translates to:
  /// **'Appeal with the grievance officer'**
  String get mlAppealStateAppealed;

  /// No description provided for @mlAppealStateUpheld.
  ///
  /// In en, this message translates to:
  /// **'Appeal accepted'**
  String get mlAppealStateUpheld;

  /// No description provided for @mlAppealStateRejected.
  ///
  /// In en, this message translates to:
  /// **'Decision stays'**
  String get mlAppealStateRejected;

  /// No description provided for @mlActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My account actions'**
  String get mlActionsTitle;

  /// No description provided for @mlActionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your account is in good standing.'**
  String get mlActionsEmpty;

  /// No description provided for @mlActionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String mlActionReason(String reason);

  /// No description provided for @mlActionDate.
  ///
  /// In en, this message translates to:
  /// **'On {date}'**
  String mlActionDate(String date);

  /// No description provided for @mlAppeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get mlAppeal;

  /// No description provided for @mlAppealTitle.
  ///
  /// In en, this message translates to:
  /// **'Appeal (once)'**
  String get mlAppealTitle;

  /// No description provided for @mlAppealNote.
  ///
  /// In en, this message translates to:
  /// **'The grievance officer acknowledges within 24 hours and decides within 15 days.'**
  String get mlAppealNote;

  /// No description provided for @mlAppealSend.
  ///
  /// In en, this message translates to:
  /// **'Send appeal'**
  String get mlAppealSend;

  /// No description provided for @mlAppealSent.
  ///
  /// In en, this message translates to:
  /// **'Appeal received'**
  String get mlAppealSent;

  /// No description provided for @mlGrievanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Owner of BagMitra'**
  String get mlGrievanceDefault;

  /// No description provided for @mlBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get mlBlock;

  /// No description provided for @mlUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get mlUnblock;

  /// No description provided for @mlBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this person?'**
  String get mlBlockTitle;

  /// No description provided for @mlBlockNote.
  ///
  /// In en, this message translates to:
  /// **'You and this person stay out of each other\'s lists and interests. Unblock any time.'**
  String get mlBlockNote;

  /// No description provided for @mlBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get mlBlocked;

  /// No description provided for @mlUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Unblocked'**
  String get mlUnblocked;

  /// No description provided for @mlMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get mlMoreOptions;

  /// No description provided for @adminMlReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminMlReports;

  /// No description provided for @adminMlAppeals.
  ///
  /// In en, this message translates to:
  /// **'Appeals'**
  String get adminMlAppeals;

  /// No description provided for @adminMlReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every report is handled'**
  String get adminMlReportsEmpty;

  /// No description provided for @adminMlAppealsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every appeal is decided'**
  String get adminMlAppealsEmpty;

  /// No description provided for @adminMlAckOverdue.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge: over 24 h'**
  String get adminMlAckOverdue;

  /// No description provided for @adminMlCloseOverdue.
  ///
  /// In en, this message translates to:
  /// **'Close: over 15 days'**
  String get adminMlCloseOverdue;

  /// No description provided for @adminMlAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get adminMlAcknowledge;

  /// No description provided for @adminMlAct.
  ///
  /// In en, this message translates to:
  /// **'Act'**
  String get adminMlAct;

  /// No description provided for @adminMlDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminMlDismiss;

  /// No description provided for @adminMlUphold.
  ///
  /// In en, this message translates to:
  /// **'Accept appeal'**
  String get adminMlUphold;

  /// No description provided for @adminMlKeepDecision.
  ///
  /// In en, this message translates to:
  /// **'Keep decision'**
  String get adminMlKeepDecision;

  /// No description provided for @adminMlActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Action with a reason code'**
  String get adminMlActionTitle;

  /// No description provided for @adminMlActionNote.
  ///
  /// In en, this message translates to:
  /// **'Platform rules only: fake or duplicate users, fake lots, impersonation, abuse. Payment, weight and quality quarrels stay with the parties.'**
  String get adminMlActionNote;

  /// No description provided for @adminMlStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminMlStatusOpen;

  /// No description provided for @adminMlStatusActioned.
  ///
  /// In en, this message translates to:
  /// **'Actioned'**
  String get adminMlStatusActioned;

  /// No description provided for @adminMlStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get adminMlStatusDismissed;

  /// No description provided for @adminMlTargetLot.
  ///
  /// In en, this message translates to:
  /// **'Lot'**
  String get adminMlTargetLot;

  /// No description provided for @adminMlTargetRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get adminMlTargetRating;

  /// No description provided for @adminMlTargetUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminMlTargetUser;

  /// No description provided for @adminMlReceived.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String adminMlReceived(String date);

  /// No description provided for @adminMlPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo {n}'**
  String adminMlPhoto(int n);

  /// No description provided for @adminMlAppealReason.
  ///
  /// In en, this message translates to:
  /// **'Appeal: {reason}'**
  String adminMlAppealReason(String reason);

  /// No description provided for @mlBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Produce on sale'**
  String get mlBrowseTitle;

  /// No description provided for @mlBrowseEmpty.
  ///
  /// In en, this message translates to:
  /// **'Produce shown by growers appears here.'**
  String get mlBrowseEmpty;

  /// No description provided for @mlNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Produce shows here once BagMitra has checked your registration.'**
  String get mlNotVerified;

  /// No description provided for @mlMyOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'My offers'**
  String get mlMyOffersTitle;

  /// No description provided for @mlMyOffersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Offers you make on produce appear here.'**
  String get mlMyOffersEmpty;

  /// No description provided for @mlOfferOpen.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the grower'**
  String get mlOfferOpen;

  /// No description provided for @mlOfferAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get mlOfferAccepted;

  /// No description provided for @mlOfferClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed: the grower chose another offer or took the produce off the list.'**
  String get mlOfferClosed;

  /// No description provided for @mlHarvestOn.
  ///
  /// In en, this message translates to:
  /// **'Harvest {date}'**
  String mlHarvestOn(String date);

  /// No description provided for @mlMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an offer'**
  String get mlMakeOffer;

  /// No description provided for @mlOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get mlOfferTitle;

  /// No description provided for @mlOfferRate.
  ///
  /// In en, this message translates to:
  /// **'Rate ₹'**
  String get mlOfferRate;

  /// No description provided for @mlOfferQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity in tonnes (optional)'**
  String get mlOfferQuantity;

  /// No description provided for @mlOfferHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Proposed harvest date'**
  String get mlOfferHarvestDate;

  /// No description provided for @mlOfferThroughBroker.
  ///
  /// In en, this message translates to:
  /// **'Through a middleman (broker)'**
  String get mlOfferThroughBroker;

  /// No description provided for @mlOfferForTrader.
  ///
  /// In en, this message translates to:
  /// **'For which trader'**
  String get mlOfferForTrader;

  /// No description provided for @mlOfferDirect.
  ///
  /// In en, this message translates to:
  /// **'Directly'**
  String get mlOfferDirect;

  /// No description provided for @mlOfferOnlyThese.
  ///
  /// In en, this message translates to:
  /// **'Only the rate, quantity and date go to the grower; settle everything else face to face.'**
  String get mlOfferOnlyThese;

  /// No description provided for @mlOfferSend.
  ///
  /// In en, this message translates to:
  /// **'Send offer'**
  String get mlOfferSend;

  /// No description provided for @mlOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent. A notice comes when the grower decides.'**
  String get mlOfferSent;

  /// No description provided for @mlErrRate.
  ///
  /// In en, this message translates to:
  /// **'Write the rate in rupees'**
  String get mlErrRate;

  /// No description provided for @mlErrQuantity.
  ///
  /// In en, this message translates to:
  /// **'Write the tonnes (up to 10,000)'**
  String get mlErrQuantity;

  /// No description provided for @mlErrPickTrader.
  ///
  /// In en, this message translates to:
  /// **'Pick the trader'**
  String get mlErrPickTrader;

  /// No description provided for @mlErrLotGone.
  ///
  /// In en, this message translates to:
  /// **'This produce has left the list.'**
  String get mlErrLotGone;

  /// No description provided for @mlOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers on your produce'**
  String get mlOffersTitle;

  /// No description provided for @mlOffersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Offers from checked traders appear here, one beside the other.'**
  String get mlOffersEmpty;

  /// No description provided for @mlSeeOffers.
  ///
  /// In en, this message translates to:
  /// **'See offers'**
  String get mlSeeOffers;

  /// No description provided for @mlYourAsk.
  ///
  /// In en, this message translates to:
  /// **'Your asking rate: {rate}'**
  String mlYourAsk(String rate);

  /// No description provided for @mlAcceptPick.
  ///
  /// In en, this message translates to:
  /// **'Tap one offer to choose it'**
  String get mlAcceptPick;

  /// No description provided for @mlAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept chosen offer'**
  String get mlAccept;

  /// No description provided for @mlAcceptConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this offer?'**
  String get mlAcceptConfirmTitle;

  /// No description provided for @mlAcceptConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This trader (and the middleman, if named) will see your name, phone and orchard location. The other offers close. You settle the rest of the transaction directly.'**
  String get mlAcceptConfirmBody;

  /// No description provided for @mlAcceptYes.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get mlAcceptYes;

  /// No description provided for @mlAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted. You both see each other\'s contacts now.'**
  String get mlAccepted;

  /// No description provided for @mlAcceptChanged.
  ///
  /// In en, this message translates to:
  /// **'The offer changed; open the list again.'**
  String get mlAcceptChanged;

  /// No description provided for @mlIntroOpen.
  ///
  /// In en, this message translates to:
  /// **'See contacts'**
  String get mlIntroOpen;

  /// No description provided for @mlIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get mlIntroTitle;

  /// No description provided for @mlIntroGrower.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get mlIntroGrower;

  /// No description provided for @mlIntroOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open orchard on map'**
  String get mlIntroOpenMap;

  /// No description provided for @mlIntroAcceptedOn.
  ///
  /// In en, this message translates to:
  /// **'Accepted on {date}'**
  String mlIntroAcceptedOn(String date);

  /// No description provided for @mlIntroOffApp.
  ///
  /// In en, this message translates to:
  /// **'From here on, weighing, crates, transport and payment are settled between you.'**
  String get mlIntroOffApp;

  /// No description provided for @mlDealDone.
  ///
  /// In en, this message translates to:
  /// **'Deal done'**
  String get mlDealDone;

  /// No description provided for @mlDealDoneAsk.
  ///
  /// In en, this message translates to:
  /// **'Mark the deal as done?'**
  String get mlDealDoneAsk;

  /// No description provided for @mlDealDoneAskBody.
  ///
  /// In en, this message translates to:
  /// **'Tap only once the deal between you is settled. Rating opens when both the grower and the trader tap.'**
  String get mlDealDoneAskBody;

  /// No description provided for @mlDealSaidDone.
  ///
  /// In en, this message translates to:
  /// **'said deal done'**
  String get mlDealSaidDone;

  /// No description provided for @mlDealNotYet.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get mlDealNotYet;

  /// No description provided for @mlDealWaitOther.
  ///
  /// In en, this message translates to:
  /// **'Rating opens when the other side also taps “Deal done”.'**
  String get mlDealWaitOther;

  /// No description provided for @mlDealWaitBoth.
  ///
  /// In en, this message translates to:
  /// **'Rating opens when both the grower and the trader tap “Deal done”.'**
  String get mlDealWaitBoth;

  /// No description provided for @mlRateOpen.
  ///
  /// In en, this message translates to:
  /// **'Give rating'**
  String get mlRateOpen;

  /// No description provided for @mlRateUntil.
  ///
  /// In en, this message translates to:
  /// **'Can be given or changed until {date}'**
  String mlRateUntil(String date);

  /// No description provided for @mlRateLocked.
  ///
  /// In en, this message translates to:
  /// **'Rating closed on {date}'**
  String mlRateLocked(String date);

  /// No description provided for @mlRateNoText.
  ///
  /// In en, this message translates to:
  /// **'Only stars and ticks.'**
  String get mlRateNoText;

  /// No description provided for @mlRateStarsOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of 5 stars'**
  String mlRateStarsOf(int count);

  /// No description provided for @mlRateSave.
  ///
  /// In en, this message translates to:
  /// **'Save rating'**
  String get mlRateSave;

  /// No description provided for @mlRateAnswerAll.
  ///
  /// In en, this message translates to:
  /// **'Give stars on every line'**
  String get mlRateAnswerAll;

  /// No description provided for @mlRateSaved.
  ///
  /// In en, this message translates to:
  /// **'Rating saved'**
  String get mlRateSaved;

  /// No description provided for @mlRateRefused.
  ///
  /// In en, this message translates to:
  /// **'Rating is saved only within 7 days after both tap “Deal done”.'**
  String get mlRateRefused;

  /// No description provided for @mlRateSameDevice.
  ///
  /// In en, this message translates to:
  /// **'Ratings are given between accounts on different phones.'**
  String get mlRateSameDevice;

  /// No description provided for @mlQGrowerProduce.
  ///
  /// In en, this message translates to:
  /// **'Produce matched the photos and description'**
  String get mlQGrowerProduce;

  /// No description provided for @mlQGrowerReady.
  ///
  /// In en, this message translates to:
  /// **'Produce ready on the agreed date'**
  String get mlQGrowerReady;

  /// No description provided for @mlCopyToAccounts.
  ///
  /// In en, this message translates to:
  /// **'Note in my accounts'**
  String get mlCopyToAccounts;

  /// No description provided for @mlBadgeGstChecked.
  ///
  /// In en, this message translates to:
  /// **'GST checked on {date}'**
  String mlBadgeGstChecked(String date);

  /// No description provided for @mlBadgeGstSince.
  ///
  /// In en, this message translates to:
  /// **'GST checked on {date} · registered since {year}'**
  String mlBadgeGstSince(String date, String year);

  /// No description provided for @mlBadgeApmcSeen.
  ///
  /// In en, this message translates to:
  /// **'APMC licence seen on {date}'**
  String mlBadgeApmcSeen(String date);

  /// No description provided for @mlBadgeFssaiChecked.
  ///
  /// In en, this message translates to:
  /// **'FSSAI checked on {date}'**
  String mlBadgeFssaiChecked(String date);

  /// No description provided for @mlBadgeIecActive.
  ///
  /// In en, this message translates to:
  /// **'IEC active, checked on {date}'**
  String mlBadgeIecActive(String date);

  /// No description provided for @mlBadgeApedaListed.
  ///
  /// In en, this message translates to:
  /// **'APEDA listed, checked on {date}'**
  String mlBadgeApedaListed(String date);

  /// Season sale package chip on a published lot (spec v1.5 §4E). Dates only: never a price, amount, UPI, QR or pay text.
  ///
  /// In en, this message translates to:
  /// **'Package active until {date}'**
  String mlPackageActiveUntil(String date);

  /// No description provided for @mlPackageNotActive.
  ///
  /// In en, this message translates to:
  /// **'Package not active'**
  String get mlPackageNotActive;

  /// Lot status chip when the season package switch is ON and no active package covers a published lot (traders do not see it). No price, pay, UPI or QR words.
  ///
  /// In en, this message translates to:
  /// **'Not shown to traders now'**
  String get mlPackageHiddenNow;

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get billingTitle;

  /// Paywall: Play's own localized price text (never built by the app), billing addendum §1.
  ///
  /// In en, this message translates to:
  /// **'{price} a month'**
  String billingPerMonth(String price);

  /// No description provided for @billingIncluded.
  ///
  /// In en, this message translates to:
  /// **'The whole BagMitra app, every feature.'**
  String get billingIncluded;

  /// No description provided for @billingTerms.
  ///
  /// In en, this message translates to:
  /// **'Renews every month through Google Play. Cancel any time in Google Play; your own records always stay readable and exportable.'**
  String get billingTerms;

  /// No description provided for @billingSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get billingSubscribe;

  /// No description provided for @billingRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore subscription'**
  String get billingRestore;

  /// No description provided for @billingManage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get billingManage;

  /// No description provided for @billingActive.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is active.'**
  String get billingActive;

  /// No description provided for @billingPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Google Play to confirm.'**
  String get billingPending;

  /// No description provided for @billingVerifying.
  ///
  /// In en, this message translates to:
  /// **'BagMitra is checking with Google Play…'**
  String get billingVerifying;

  /// No description provided for @billingRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again, or tap Restore subscription.'**
  String get billingRetry;

  /// No description provided for @billingNeedsPlay.
  ///
  /// In en, this message translates to:
  /// **'Open this screen on a phone with Google Play.'**
  String get billingNeedsPlay;

  /// No description provided for @billingChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change to your subscription'**
  String get billingChangeTitle;

  /// Required in-app notice of a Play price increase (addendum §7); no amount, the user sees it in Google Play.
  ///
  /// In en, this message translates to:
  /// **'Google Play has a new monthly rate for your subscription from {date}. To keep the subscription, review and accept it in Google Play.'**
  String billingChangeBody(String date);

  /// Notice of a Play price increase the user already accepted (CONFIRMED, audit L3); no amount.
  ///
  /// In en, this message translates to:
  /// **'From {date} your subscription renews at its new monthly rate in Google Play. You have already accepted it.'**
  String billingChangeConfirmedBody(String date);

  /// No description provided for @billingOpenPlay.
  ///
  /// In en, this message translates to:
  /// **'Open Google Play'**
  String get billingOpenPlay;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackKindProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get feedbackKindProblem;

  /// No description provided for @feedbackKindSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackKindSuggestion;

  /// No description provided for @feedbackKindQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get feedbackKindQuestion;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Write or speak what happened, or what you would like.'**
  String get feedbackHint;

  /// No description provided for @feedbackAddScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Add a screenshot'**
  String get feedbackAddScreenshot;

  /// No description provided for @feedbackScreenshotAdded.
  ///
  /// In en, this message translates to:
  /// **'Screenshot added'**
  String get feedbackScreenshotAdded;

  /// No description provided for @feedbackIncluded.
  ///
  /// In en, this message translates to:
  /// **'The app version and the phone model go with it.'**
  String get feedbackIncluded;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Received. Thank you!'**
  String get feedbackSent;

  /// No description provided for @feedbackQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved on the phone; it goes when the internet is back.'**
  String get feedbackQueued;

  /// Sign-in screen (market link builds): the role card the user picked, with a link back to the five cards.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String mlLoginRole(String role);

  /// No description provided for @expenseElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Spray (with its labour), labour and fertiliser costs go in their own records and are added to the accounts automatically.'**
  String get expenseElsewhere;

  /// No description provided for @expenseGoSpray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get expenseGoSpray;

  /// No description provided for @expenseGoLabour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get expenseGoLabour;

  /// No description provided for @expenseGoInputs.
  ///
  /// In en, this message translates to:
  /// **'Fertiliser and manure'**
  String get expenseGoInputs;

  /// No description provided for @mlWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BagMitra'**
  String get mlWelcomeTitle;

  /// No description provided for @mlWelcomeLine.
  ///
  /// In en, this message translates to:
  /// **'Orchard records, today\'s market prices and buyers, in one app.'**
  String get mlWelcomeLine;

  /// No description provided for @photoCheckOpen.
  ///
  /// In en, this message translates to:
  /// **'Identify from photo'**
  String get photoCheckOpen;

  /// No description provided for @photoCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Take a close photo of the leaf, fruit or trunk in good light.'**
  String get photoCheckHint;

  /// No description provided for @photoCheckPart.
  ///
  /// In en, this message translates to:
  /// **'Which part? (optional)'**
  String get photoCheckPart;

  /// No description provided for @photoCheckPartLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get photoCheckPartLeaf;

  /// No description provided for @photoCheckPartFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get photoCheckPartFruit;

  /// No description provided for @photoCheckPartTrunk.
  ///
  /// In en, this message translates to:
  /// **'Trunk'**
  String get photoCheckPartTrunk;

  /// No description provided for @photoCheckPartWholeTree.
  ///
  /// In en, this message translates to:
  /// **'Whole tree'**
  String get photoCheckPartWholeTree;

  /// No description provided for @photoCheckRetry.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get photoCheckRetry;

  /// No description provided for @photoCheckBusy.
  ///
  /// In en, this message translates to:
  /// **'Checking the photo… this can take up to a minute.'**
  String get photoCheckBusy;

  /// No description provided for @photoCheckChange.
  ///
  /// In en, this message translates to:
  /// **'Another photo'**
  String get photoCheckChange;

  /// No description provided for @photoCheckBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the record'**
  String get photoCheckBack;

  /// No description provided for @photoCheckLikelyHigh.
  ///
  /// In en, this message translates to:
  /// **'Quite likely'**
  String get photoCheckLikelyHigh;

  /// No description provided for @photoCheckLikelyMedium.
  ///
  /// In en, this message translates to:
  /// **'Possible'**
  String get photoCheckLikelyMedium;

  /// No description provided for @photoCheckLikelyLow.
  ///
  /// In en, this message translates to:
  /// **'Less likely'**
  String get photoCheckLikelyLow;

  /// No description provided for @photoCheckSigns.
  ///
  /// In en, this message translates to:
  /// **'Seen in the photo'**
  String get photoCheckSigns;

  /// No description provided for @photoCheckSignsEnglish.
  ///
  /// In en, this message translates to:
  /// **'Seen in the photo (in English)'**
  String get photoCheckSignsEnglish;

  /// No description provided for @photoCheckOpenCard.
  ///
  /// In en, this message translates to:
  /// **'Open card'**
  String get photoCheckOpenCard;

  /// No description provided for @photoCheckUnsure.
  ///
  /// In en, this message translates to:
  /// **'A clearer photo will help. Take one closer, in good light, or compare the signs on the cards.'**
  String get photoCheckUnsure;

  /// No description provided for @photoCheckHealthy.
  ///
  /// In en, this message translates to:
  /// **'Good news: the photo looks like a healthy tree.'**
  String get photoCheckHealthy;

  /// No description provided for @photoCheckNote.
  ///
  /// In en, this message translates to:
  /// **'A suggestion from the photo; the card has the details.'**
  String get photoCheckNote;

  /// No description provided for @photoCheckSeeCards.
  ///
  /// In en, this message translates to:
  /// **'See the cards'**
  String get photoCheckSeeCards;

  /// No description provided for @photoCheckOffline.
  ///
  /// In en, this message translates to:
  /// **'Photo check needs the internet. Your photo is kept here; tap Check again once you are online.'**
  String get photoCheckOffline;

  /// No description provided for @photoCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Please check again in a little while. Your photo is kept here.'**
  String get photoCheckFailed;

  /// No description provided for @photoCheckUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo check is paused for now. Meanwhile you can compare the signs on the cards.'**
  String get photoCheckUnavailable;

  /// No description provided for @photoCheckRefused.
  ///
  /// In en, this message translates to:
  /// **'Please take another photo.'**
  String get photoCheckRefused;

  /// No description provided for @photoCheckSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to check photos.'**
  String get photoCheckSignedOut;

  /// No description provided for @photoCheckDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo'**
  String get photoCheckDelete;

  /// No description provided for @photoCheckDeleted.
  ///
  /// In en, this message translates to:
  /// **'The photo was deleted from the server.'**
  String get photoCheckDeleted;

  /// No description provided for @photoCheckDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Tap Delete this photo again once you are online.'**
  String get photoCheckDeleteFailed;

  /// No description provided for @photoCheckLimitDaily.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {count} photos are used; you can check again tomorrow.'**
  String photoCheckLimitDaily(String count);

  /// No description provided for @photoCheckLimitDailyAt.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {count} photos are used; you can check again after {when}.'**
  String photoCheckLimitDailyAt(String count, String when);

  /// No description provided for @photoCheckLimitMonthly.
  ///
  /// In en, this message translates to:
  /// **'This month\'s {count} photos are used; you can check again from {when}.'**
  String photoCheckLimitMonthly(String count, String when);

  /// No description provided for @photoCheckLimitTotal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s photo checks are full; you can check again tomorrow.'**
  String get photoCheckLimitTotal;

  /// No description provided for @photoCheckLimitTotalAt.
  ///
  /// In en, this message translates to:
  /// **'Today\'s photo checks are full; you can check again after {when}.'**
  String photoCheckLimitTotalAt(String when);

  /// No description provided for @billPhoto.
  ///
  /// In en, this message translates to:
  /// **'Bill photo'**
  String get billPhoto;

  /// No description provided for @billPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'The shop bill\'s photo stays with this record on the phone.'**
  String get billPhotoHint;

  /// No description provided for @billPhotoOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the bill photo'**
  String get billPhotoOpen;

  /// No description provided for @billFill.
  ///
  /// In en, this message translates to:
  /// **'Fill from bill'**
  String get billFill;

  /// No description provided for @billReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the bill…'**
  String get billReading;

  /// No description provided for @billUnsure.
  ///
  /// In en, this message translates to:
  /// **'Could not read the bill clearly; fill in the details by hand.'**
  String get billUnsure;

  /// No description provided for @billFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled from the bill: {fields}. Please check once.'**
  String billFilled(String fields);

  /// No description provided for @billNothingFilled.
  ///
  /// In en, this message translates to:
  /// **'These fields were already filled; they are kept as they were.'**
  String get billNothingFilled;

  /// No description provided for @billOffline.
  ///
  /// In en, this message translates to:
  /// **'Reading the bill needs internet. The photo is saved with this record on the phone.'**
  String get billOffline;

  /// No description provided for @billFailed.
  ///
  /// In en, this message translates to:
  /// **'Try \'Fill from bill\' again in a while; the photo stays here.'**
  String get billFailed;

  /// No description provided for @billUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bill reading is paused for now; fill in the details by hand.'**
  String get billUnavailable;

  /// No description provided for @billRefused.
  ///
  /// In en, this message translates to:
  /// **'Please take another photo of the bill.'**
  String get billRefused;

  /// No description provided for @billSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to read the bill.'**
  String get billSignedOut;

  /// No description provided for @billLimitDaily.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {count} bill readings are used; you can read again tomorrow.'**
  String billLimitDaily(String count);

  /// No description provided for @billLimitDailyAt.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {count} bill readings are used; you can read again after {when}.'**
  String billLimitDailyAt(String count, String when);

  /// No description provided for @billLimitMonthly.
  ///
  /// In en, this message translates to:
  /// **'This month\'s {count} bill readings are used; you can read again from {when}.'**
  String billLimitMonthly(String count, String when);

  /// No description provided for @billLimitTotal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s bill readings are full; you can read again tomorrow.'**
  String get billLimitTotal;

  /// No description provided for @billLimitTotalAt.
  ///
  /// In en, this message translates to:
  /// **'Today\'s bill readings are full; you can read again after {when}.'**
  String billLimitTotalAt(String when);

  /// No description provided for @billPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a line from the bill'**
  String get billPickTitle;

  /// No description provided for @billTotal.
  ///
  /// In en, this message translates to:
  /// **'Bill total'**
  String get billTotal;

  /// No description provided for @billLabelShopNo.
  ///
  /// In en, this message translates to:
  /// **'{shop} bill #{no}'**
  String billLabelShopNo(String shop, String no);

  /// No description provided for @billLabelShop.
  ///
  /// In en, this message translates to:
  /// **'{shop} bill'**
  String billLabelShop(String shop);

  /// No description provided for @billLabelNo.
  ///
  /// In en, this message translates to:
  /// **'Bill #{no}'**
  String billLabelNo(String no);

  /// No description provided for @billFieldProduct.
  ///
  /// In en, this message translates to:
  /// **'product name'**
  String get billFieldProduct;

  /// No description provided for @billFieldActive.
  ///
  /// In en, this message translates to:
  /// **'active ingredient'**
  String get billFieldActive;

  /// No description provided for @billFieldDose.
  ///
  /// In en, this message translates to:
  /// **'quantity'**
  String get billFieldDose;

  /// No description provided for @billFieldCost.
  ///
  /// In en, this message translates to:
  /// **'cost'**
  String get billFieldCost;

  /// No description provided for @billFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'amount'**
  String get billFieldAmount;

  /// No description provided for @billFieldDate.
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get billFieldDate;

  /// No description provided for @billFieldNote.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get billFieldNote;

  /// No description provided for @sprayProductHeading.
  ///
  /// In en, this message translates to:
  /// **'Product {n}'**
  String sprayProductHeading(String n);

  /// No description provided for @sprayAddProduct.
  ///
  /// In en, this message translates to:
  /// **'+ Add another product'**
  String get sprayAddProduct;

  /// No description provided for @sprayRemoveProduct.
  ///
  /// In en, this message translates to:
  /// **'Remove product {n}'**
  String sprayRemoveProduct(String n);

  /// No description provided for @spraySharedHeading.
  ///
  /// In en, this message translates to:
  /// **'For the whole spray'**
  String get spraySharedHeading;

  /// No description provided for @sprayMix.
  ///
  /// In en, this message translates to:
  /// **'Mix: {names}'**
  String sprayMix(String names);

  /// No description provided for @sprayMixHeading.
  ///
  /// In en, this message translates to:
  /// **'Mix:'**
  String get sprayMixHeading;

  /// No description provided for @sprayMixTotal.
  ///
  /// In en, this message translates to:
  /// **'Total cost {amount}'**
  String sprayMixTotal(String amount);

  /// No description provided for @sprayMixPhi.
  ///
  /// In en, this message translates to:
  /// **'Waiting period of the mix: {days} days (the longest)'**
  String sprayMixPhi(String days);

  /// No description provided for @sprayPhiDays.
  ///
  /// In en, this message translates to:
  /// **'PHI {days} days'**
  String sprayPhiDays(String days);

  /// No description provided for @sprayDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Spray record'**
  String get sprayDetailTitle;

  /// No description provided for @sprayDetailWater.
  ///
  /// In en, this message translates to:
  /// **'Water {litres} L'**
  String sprayDetailWater(String litres);

  /// No description provided for @sprayDetailArea.
  ///
  /// In en, this message translates to:
  /// **'{acres} acres'**
  String sprayDetailArea(String acres);

  /// No description provided for @sprayDetailOperator.
  ///
  /// In en, this message translates to:
  /// **'Sprayed by {name}'**
  String sprayDetailOperator(String name);

  /// No description provided for @sprayDetailProducts.
  ///
  /// In en, this message translates to:
  /// **'Products in the tank'**
  String get sprayDetailProducts;

  /// No description provided for @billPickManyTitle.
  ///
  /// In en, this message translates to:
  /// **'Tick the bill lines mixed in this spray'**
  String get billPickManyTitle;

  /// No description provided for @billPickMany.
  ///
  /// In en, this message translates to:
  /// **'Fill {count} selected'**
  String billPickMany(String count);

  /// No description provided for @sprayLabour.
  ///
  /// In en, this message translates to:
  /// **'Spraying labour (₹, optional)'**
  String get sprayLabour;

  /// No description provided for @sprayLabourHelp.
  ///
  /// In en, this message translates to:
  /// **'If it is already in the labour register (spraying), leave this empty.'**
  String get sprayLabourHelp;

  /// No description provided for @sprayCostSplit.
  ///
  /// In en, this message translates to:
  /// **'Total cost = products {products} + labour {labour}'**
  String sprayCostSplit(String products, String labour);
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
