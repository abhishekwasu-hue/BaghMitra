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
