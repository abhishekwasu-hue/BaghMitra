import 'dart:io';

import 'package:bagmitra/app/app.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/core/app_log.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/accounts/data/expense_categories.dart';
import 'package:bagmitra/features/auth/data/demo_auth_repository.dart';
import 'package:bagmitra/features/auth/domain/auth.dart';
import 'package:bagmitra/features/bahar/data/bahar_catalog.dart';
import 'package:bagmitra/features/export/data/file_sharer.dart';
import 'package:bagmitra/features/field_work/data/field_work_options.dart';
import 'package:bagmitra/features/home/data/demo_home_repository.dart';
import 'package:bagmitra/features/inputs/data/input_kinds.dart';
import 'package:bagmitra/features/lab_tests/data/lab_parameters.dart';
import 'package:bagmitra/features/plots/data/crop_catalog.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/practices/data/irrigation_guide.dart';
import 'package:bagmitra/features/practices/data/practice_cards.dart';
import 'package:bagmitra/features/profile/data/language_catalog.dart';
import 'package:bagmitra/features/schemes/data/scheme_catalog.dart';
import 'package:bagmitra/features/scouting/data/scouting_photos.dart';
import 'package:bagmitra/features/tasks/data/task_kinds.dart';
import 'package:bagmitra/features/voice/domain/speech.dart';
import 'package:bagmitra/features/walkthrough/data/walkthrough_flag.dart';
import 'package:bagmitra/sync/account_guard.dart';
import 'package:bagmitra/sync/sync_engine.dart';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

const testConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: true,
  testBuild: '',
  speechEngine: 'on_device',
);

/// Serves assets straight from disk, synchronously, so screens render in one pump.
class FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      SynchronousFuture(ByteData.sublistView(File(key).readAsBytesSync()));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(File(key).readAsStringSync());
}

/// A recogniser that says whatever the test tells it to, then finishes.
class FakeRecognizer implements SpeechRecognizer {
  FakeRecognizer({this.available = true, this.words = const []});

  final bool available;
  final List<SpeechResult> words;
  String? heardLocale;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<SpeechResult> listen({required String localeId}) {
    heardLocale = localeId;
    return Stream.fromIterable(words);
  }

  @override
  Future<void> stop() async {}
}

/// Remembers what the app tried to share instead of opening a share sheet.
class RecordingSharer implements FileSharer {
  final shared = <({String fileName, Uint8List bytes, String mimeType})>[];

  @override
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async =>
      shared.add((fileName: fileName, bytes: bytes, mimeType: mimeType));
}

const signedIn = AuthSession(
  userId: 'u1',
  phone: '+919800000000',
  accessToken: 't',
);

/// A Pixel-5-ish phone: 393 x 851 logical px.
const phoneSize = Size(393, 851);

Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Locale? locale = const Locale('mr'),
  ThemeMode themeMode = ThemeMode.light,
  AuthSession? session = signedIn,
  String? initialLocation,
  SyncStatus? syncStatus,
  Future<void> Function(AppDatabase db)? seed,
  FileSharer? sharer,
  bool onboarded = true,
  bool walkthroughSeen = true,
  LocationService? location,
  AppConfig config = testConfig,
  AppLog? log,
  SpeechRecognizer? recognizer,
  ScoutingPhotos? photos,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = phoneSize * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 24 * 3);
  addTearDown(tester.view.reset);
  final db = memoryDb();
  addTearDown(db.close);
  if (onboarded && session != null) {
    // Most tests are about what comes after setup, so they start with a finished profile.
    // Written straight to the table: it is setup, not something the grower queued for sync.
    await tester.runAsync(
      () => db
          .into(db.farmerProfiles)
          .insert(
            FarmerProfilesCompanion.insert(
              id: session.userId,
              language: 'en',
              consentDataProcessing: const Value(true),
              clientUpdatedAt: DateTime.utc(2026),
            ),
          ),
    );
  }
  // The first-run walkthrough is about a brand-new phone; other tests start past it.
  if (walkthroughSeen) await tester.runAsync(WalkthroughFlag(db).markSeen);
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        if (log != null) appLogProvider.overrideWithValue(log),
        if (recognizer != null)
          speechRecognizerProvider.overrideWithValue(recognizer),
        fileSharerProvider.overrideWithValue(sharer ?? RecordingSharer()),
        if (photos != null) scoutingPhotosProvider.overrideWithValue(photos),
        if (location != null)
          locationServiceProvider.overrideWithValue(location),
        databaseProvider.overrideWithValue(db),
        // Real photo folders are not touched in widget tests.
        accountGuardProvider.overrideWithValue(AccountGuard(db)),
        authRepositoryProvider.overrideWithValue(
          DemoAuthRepository(initial: session),
        ),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13, 6)),
        baharCatalogProvider.overrideWithValue(
          BaharCatalog(bundle: FileAssetBundle()),
        ),
        inputKindsCatalogProvider.overrideWithValue(
          InputKinds(bundle: FileAssetBundle()),
        ),
        languageCatalogProvider.overrideWithValue(
          LanguageCatalog(bundle: FileAssetBundle()),
        ),
        fieldWorkOptionsCatalogProvider.overrideWithValue(
          FieldWorkOptions(bundle: FileAssetBundle()),
        ),
        expenseCategoriesCatalogProvider.overrideWithValue(
          ExpenseCategories(bundle: FileAssetBundle()),
        ),
        taskKindsCatalogProvider.overrideWithValue(
          TaskKinds(bundle: FileAssetBundle()),
        ),
        cropCatalogProvider.overrideWithValue(
          CropCatalog(bundle: FileAssetBundle()),
        ),
        practiceCardsConfigProvider.overrideWithValue(
          PracticeCardsConfig(bundle: FileAssetBundle()),
        ),
        irrigationGuideConfigProvider.overrideWithValue(
          IrrigationGuideConfig(bundle: FileAssetBundle()),
        ),
        labParametersCatalogProvider.overrideWithValue(
          LabParameters(bundle: FileAssetBundle()),
        ),
        schemeCatalogProvider.overrideWithValue(
          SchemeCatalog(bundle: FileAssetBundle()),
        ),
        homeRepositoryProvider.overrideWithValue(
          DemoHomeRepository(bundle: FileAssetBundle()),
        ),
        if (syncStatus != null)
          syncStatusProvider.overrideWithValue(AsyncData(syncStatus)),
        ...overrides,
      ],
      child: BagMitraApp(
        locale: locale,
        themeMode: themeMode,
        initialLocation: initialLocation,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  // A language switch (from a saved profile) reloads the language-keyed screens; give that a
  // moment of real time instead of asserting on the very first frame.
  for (var i = 0; i < 15; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    find.byType(CircularProgressIndicator),
    findsNothing,
    reason: 'screen must be fully loaded before assertions/goldens',
  );
  return db;
}

/// Unmounts the app and flushes Drift's stream-cleanup timer. Call at the end of any
/// test whose screens watch Drift queries, or the test binding reports a pending Timer.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}
