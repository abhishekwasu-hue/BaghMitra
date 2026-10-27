import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/generated/bagmitra.swagger.dart'
    show Bagmitra, V1MarketPricesGetScope;
import '../core/app_log.dart';
import '../core/clock.dart';
import '../core/config.dart';
import '../data/local/database.dart';
import '../features/accounts/data/accounts_repository.dart';
import '../features/accounts/data/expense_categories.dart';
import '../features/accounts/domain/accounts.dart';
import '../features/auth/domain/auth.dart';
import '../features/bahar/data/bahar_catalog.dart';
import '../features/bahar/data/bahar_compare.dart';
import '../features/bahar/data/bahar_repository.dart';
import '../features/bahar/domain/bahar_cycle.dart';
import '../features/billing/data/entitlements_cache.dart';
import '../features/billing/domain/entitlements.dart';
import '../features/dev/sample_orchard.dart';
import '../features/export/data/file_sharer.dart';
import '../features/feed/data/demo_feed_repository.dart';
import '../features/feed/data/feed_cache.dart';
import '../features/feed/data/feed_repository.dart';
import '../features/feed/data/text_sharer.dart';
import '../features/field_work/data/field_work_options.dart';
import '../features/field_work/data/field_work_repository.dart';
import '../features/field_work/domain/field_work.dart';
import '../features/home/data/demo_home_repository.dart';
import '../features/home/domain/home_snapshot.dart';
import '../features/inputs/data/input_kinds.dart';
import '../features/inputs/data/inputs_repository.dart';
import '../features/inputs/domain/field_records.dart';
import '../features/labels/data/label_claims_cache.dart';
import '../features/market/data/market_prices_cache.dart';
import '../features/plots/data/crop_catalog.dart';
import '../features/plots/data/location_service.dart';
import '../features/plots/data/plot_repository.dart';
import '../features/plots/domain/plot.dart';
import '../features/practices/data/irrigation_guide.dart';
import '../features/practices/data/practice_cards.dart';
import '../features/profile/data/language_catalog.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/farmer_profile.dart';
import '../features/reminders/domain/reminders.dart';
import '../features/spray/data/restrictions_cache.dart';
import '../features/spray/data/spray_repository.dart';
import '../features/spray/domain/spray_check.dart';
import '../features/spray/domain/spray_record.dart';
import '../features/tasks/data/cycle_tasks_service.dart';
import '../features/tasks/data/task_kinds.dart';
import '../features/tasks/data/tasks_repository.dart';
import '../features/tasks/domain/farm_task.dart';
import '../features/voice/data/cloud_speech.dart';
import '../features/voice/data/on_device_speech.dart';
import '../features/voice/domain/speech.dart';
import '../features/walkthrough/data/walkthrough_flag.dart';
import '../features/weather/data/plot_weather_cache.dart';
import '../sync/http_transport.dart';
import '../sync/sync_engine.dart';

/// Overridden in main() / tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

/// Overridden in tests for deterministic dates.
final clockProvider = Provider<Clock>((ref) => systemClock);

/// Overridden in main() / tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open('bagmitra');
  ref.onDispose(db.close);
  return db;
});

/// Overridden in main() with the Supabase or demo implementation.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      throw UnimplementedError('authRepositoryProvider must be overridden'),
);

/// The signed-in session, current value first, then every change.
final sessionProvider = StreamProvider<AuthSession?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return Stream.multi((controller) {
    controller.add(auth.current);
    final sub = auth.sessions().listen(controller.add);
    controller.onCancel = sub.cancel;
  });
});

final apiProvider = Provider<Bagmitra>((ref) {
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(authRepositoryProvider);
  return createApi(
    baseUrl: Uri.parse(config.apiBaseUrl),
    token: () => auth.current?.accessToken,
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

/// The signed-in grower's profile; null until they finish onboarding.
final profileProvider = StreamProvider<FarmerProfile?>((ref) {
  final user = ref.watch(sessionProvider).value?.userId;
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watch(user);
});

/// Whether the signed-in grower has finished onboarding; null while that is still loading or
/// when nobody is signed in (so the router does not redirect on an unknown).
final onboardedProvider = Provider<bool?>((ref) {
  final session = ref.watch(sessionProvider);
  final profile = ref.watch(profileProvider);
  if (session.value == null || profile.isLoading) return null;
  return profile.value?.consentDataProcessing ?? false;
});

final walkthroughFlagProvider = Provider<WalkthroughFlag>(
  (ref) => WalkthroughFlag(ref.watch(databaseProvider)),
);

/// Whether this phone has shown the first-run walkthrough; loading until the flag is read.
final walkthroughSeenProvider = AsyncNotifierProvider<WalkthroughSeen, bool>(
  WalkthroughSeen.new,
);

class WalkthroughSeen extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(walkthroughFlagProvider).seen();

  Future<void> markSeen() async {
    await ref.read(walkthroughFlagProvider).markSeen();
    state = const AsyncData(true);
  }
}

/// Language chosen on the onboarding screen before it is saved, so the screen switches at once.
final languagePreviewProvider = NotifierProvider<LanguagePreview, String?>(
  LanguagePreview.new,
);

class LanguagePreview extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void set(String? language) => state = language;
}

final languageCatalogProvider = Provider<LanguageCatalog>(
  (ref) => LanguageCatalog(),
);

final languagesProvider = FutureProvider<List<LabeledOption>>(
  (ref) => ref.watch(languageCatalogProvider).load(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final plotRepositoryProvider = Provider<PlotRepository>(
  (ref) => PlotRepository(ref.watch(databaseProvider)),
);

final plotsProvider = StreamProvider<List<Plot>>(
  (ref) => ref.watch(plotRepositoryProvider).watchAll(),
);

final cropCatalogProvider = Provider<CropCatalog>((ref) => CropCatalog());

final cropsProvider = FutureProvider<List<CropOption>>(
  (ref) => ref.watch(cropCatalogProvider).load(),
);

final baharRepositoryProvider = Provider<BaharRepository>(
  (ref) => BaharRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final baharCyclesProvider = StreamProvider.family<List<BaharCycle>, String>(
  (ref, plotId) => ref.watch(baharRepositoryProvider).watchForPlot(plotId),
);

final allBaharCyclesProvider = StreamProvider<List<BaharCycle>>(
  (ref) => ref.watch(baharRepositoryProvider).watchAll(),
);

final baharCatalogProvider = Provider<BaharCatalog>((ref) => BaharCatalog());

final baharOptionsProvider = FutureProvider<BaharCatalogData>(
  (ref) => ref.watch(baharCatalogProvider).load(),
);

final baharCompareProvider = FutureProvider<BaharCompareData>(
  (ref) => BaharCompareConfig().load(),
);

final practiceCardsConfigProvider = Provider<PracticeCardsConfig>(
  (ref) => PracticeCardsConfig(),
);

final practiceCardsProvider = FutureProvider<PracticeCardsData>(
  (ref) => ref.watch(practiceCardsConfigProvider).load(),
);

final irrigationGuideConfigProvider = Provider<IrrigationGuideConfig>(
  (ref) => IrrigationGuideConfig(),
);

final irrigationGuideProvider = FutureProvider<IrrigationGuideData>(
  (ref) => ref.watch(irrigationGuideConfigProvider).load(),
);

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final expensesProvider = StreamProvider.family<List<Expense>, String>(
  (ref, plotId) => ref.watch(accountsRepositoryProvider).watchExpenses(plotId),
);

final incomesProvider = StreamProvider.family<List<Income>, String>(
  (ref, plotId) => ref.watch(accountsRepositoryProvider).watchIncomes(plotId),
);

final expenseCategoriesCatalogProvider = Provider<ExpenseCategories>(
  (ref) => ExpenseCategories(),
);

final expenseCategoriesProvider = FutureProvider<List<LabeledOption>>(
  (ref) => ref.watch(expenseCategoriesCatalogProvider).load(),
);

final sprayRepositoryProvider = Provider<SprayRepository>(
  (ref) => SprayRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final spraysProvider = StreamProvider.family<List<SprayRecord>, String>(
  (ref, plotId) => ref.watch(sprayRepositoryProvider).watchForPlot(plotId),
);

final restrictionsCacheProvider = Provider<RestrictionsCache>(
  (ref) => RestrictionsCache(
    ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
  ),
);

/// The cached ban list. Online (not demo) it is refreshed in the background; the cached
/// copy is always returned first so the check works with no network.
final restrictionsProvider = FutureProvider<RestrictionList>((ref) async {
  final cache = ref.watch(restrictionsCacheProvider);
  final cached = await cache.load();
  if (!ref.watch(appConfigProvider).demoMode) {
    unawaited(cache.refresh());
  }
  return cached;
});

final labelClaimsCacheProvider = Provider<LabelClaimsCache>(
  (ref) => LabelClaimsCache(
    ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// CIB&RC label information for a crop (label facts only, never advice). The cached copy is
/// returned when there is one and refreshed in the background online (not demo); with no
/// cached copy yet the first refresh is awaited so the screen is not empty for nothing.
final labelClaimsProvider = FutureProvider.family<CachedLabelClaims?, String>((
  ref,
  crop,
) async {
  final cache = ref.watch(labelClaimsCacheProvider);
  final cached = await cache.load(crop);
  if (ref.watch(appConfigProvider).demoMode) return cached;
  if (cached != null) {
    unawaited(cache.refresh(crop));
    return cached;
  }
  await cache.refresh(crop);
  return cache.load(crop);
});

final entitlementsCacheProvider = Provider<EntitlementsCache>(
  (ref) => EntitlementsCache(
    ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
  ),
);

/// What the grower's plan allows. The cached snapshot answers first (works offline); online
/// (not demo) it is refreshed in the background and picked up the next time this is read.
final entitlementsProvider = FutureProvider<Entitlements>((ref) async {
  final cache = ref.watch(entitlementsCacheProvider);
  final rules = await cache.rules();
  final snapshot = await cache.load();
  if (!ref.watch(appConfigProvider).demoMode) {
    unawaited(cache.refresh());
  }
  return Entitlements(snapshot, rules, ref.watch(clockProvider)());
});

final sampleOrchardProvider = Provider<SampleOrchard>(
  (ref) => SampleOrchard(
    plots: ref.watch(plotRepositoryProvider),
    bahars: ref.watch(baharRepositoryProvider),
    accounts: ref.watch(accountsRepositoryProvider),
    sprays: ref.watch(sprayRepositoryProvider),
    inputs: ref.watch(inputsRepositoryProvider),
    fieldWork: ref.watch(fieldWorkRepositoryProvider),
  ),
);

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final tasksProvider = StreamProvider<List<FarmTask>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchAll(),
);

final cycleTasksProvider = Provider<CycleTasksService>(
  (ref) => CycleTasksService(ref.watch(tasksRepositoryProvider)),
);

final taskKindsCatalogProvider = Provider<TaskKinds>((ref) => TaskKinds());

final taskKindsProvider = FutureProvider<List<LabeledOption>>(
  (ref) => ref.watch(taskKindsCatalogProvider).load(),
);

final inputsRepositoryProvider = Provider<InputsRepository>(
  (ref) => InputsRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final inputsProvider = StreamProvider.family<List<InputRecord>, String>(
  (ref, plotId) => ref.watch(inputsRepositoryProvider).watchInputs(plotId),
);

final irrigationsProvider =
    StreamProvider.family<List<IrrigationRecord>, String>(
      (ref, plotId) =>
          ref.watch(inputsRepositoryProvider).watchIrrigations(plotId),
    );

final inputKindsCatalogProvider = Provider<InputKinds>((ref) => InputKinds());

final inputKindsProvider = FutureProvider<InputKindsData>(
  (ref) => ref.watch(inputKindsCatalogProvider).load(),
);

final fieldWorkRepositoryProvider = Provider<FieldWorkRepository>(
  (ref) => FieldWorkRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final harvestsProvider = StreamProvider.family<List<HarvestRecord>, String>(
  (ref, plotId) => ref.watch(fieldWorkRepositoryProvider).watchHarvests(plotId),
);

final labourProvider = StreamProvider.family<List<LabourRecord>, String>(
  (ref, plotId) => ref.watch(fieldWorkRepositoryProvider).watchLabour(plotId),
);

final fieldWorkOptionsCatalogProvider = Provider<FieldWorkOptions>(
  (ref) => FieldWorkOptions(),
);

final fieldWorkOptionsProvider = FutureProvider<FieldWorkOptionsData>(
  (ref) => ref.watch(fieldWorkOptionsCatalogProvider).load(),
);

/// Where diagnostics go. `main` swaps in the file-backed log; tests use the in-memory one.
final appLogProvider = Provider<AppLog>((ref) => MemoryAppLog());

/// Speech engines, chosen by `SPEECH_ENGINE` (on_device by default). Tests override these.
final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => ref.watch(appConfigProvider).speechEngine == 'cloud'
      ? const CloudSpeechRecognizer()
      : OnDeviceSpeechRecognizer(),
);

final speechSynthesizerProvider = Provider<SpeechSynthesizer>(
  (ref) => ref.watch(appConfigProvider).speechEngine == 'cloud'
      ? const CloudSpeechSynthesizer()
      : OnDeviceSpeechSynthesizer(),
);

/// Phone notifications for due tasks. `main` swaps in the real scheduler; tests do nothing.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => const NoopReminderScheduler(),
);

/// Keeps the scheduled notifications in step with the task list. Watched once, at the app root.
final reminderSyncProvider = Provider<void>((ref) {
  final tasks = ref.watch(tasksProvider).value;
  if (tasks == null) return;
  final heading = ref.watch(appConfigProvider).productName;
  final plan = planReminders(tasks, DateTime.now());
  unawaited(
    ref
        .read(reminderSchedulerProvider)
        .replaceAll(heading, plan)
        .catchError(
          (Object e) => ref.read(appLogProvider).log('reminders: $e'),
        ),
  );
});

final fileSharerProvider = Provider<FileSharer>(
  (ref) => const SharePlusFileSharer(),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(databaseProvider),
    transport: HttpSyncTransport(ref.watch(apiProvider)),
    appliers: {
      ProfileRepository.entity: ref
          .watch(profileRepositoryProvider)
          .applyRemote,
      PlotRepository.entity: ref.watch(plotRepositoryProvider).applyRemote,
      BaharRepository.entity: ref.watch(baharRepositoryProvider).applyRemote,
      AccountsRepository.expenseEntity: ref
          .watch(accountsRepositoryProvider)
          .applyRemoteExpense,
      AccountsRepository.incomeEntity: ref
          .watch(accountsRepositoryProvider)
          .applyRemoteIncome,
      SprayRepository.entity: ref.watch(sprayRepositoryProvider).applyRemote,
      InputsRepository.inputEntity: ref
          .watch(inputsRepositoryProvider)
          .applyRemoteInput,
      InputsRepository.irrigationEntity: ref
          .watch(inputsRepositoryProvider)
          .applyRemoteIrrigation,
      FieldWorkRepository.harvestEntity: ref
          .watch(fieldWorkRepositoryProvider)
          .applyRemoteHarvest,
      FieldWorkRepository.labourEntity: ref
          .watch(fieldWorkRepositoryProvider)
          .applyRemoteLabour,
      TasksRepository.entity: ref.watch(tasksRepositoryProvider).applyRemote,
    },
  );
  // Demo mode has no backend: writes stay queued locally, nothing is reported as failing.
  if (!ref.watch(appConfigProvider).demoMode) engine.start();
  ref.onDispose(engine.dispose);
  return engine;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return Stream.multi((controller) {
    controller.add(engine.status);
    final sub = engine.statusStream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });
});

final homeRepositoryProvider = Provider<DemoHomeRepository>(
  (ref) => DemoHomeRepository(),
);

final homeSnapshotProvider = FutureProvider.family<HomeSnapshot, String>(
  (ref, languageCode) => ref.watch(homeRepositoryProvider).load(languageCode),
);

/// Task ticks made on the home screen. M1 replaces this with offline-synced task records.
class TaskTicks extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void set(String taskId, bool done) => state = {...state, taskId: done};
}

final taskTicksProvider = NotifierProvider<TaskTicks, Map<String, bool>>(
  TaskTicks.new,
);

final plotWeatherCacheProvider = Provider<PlotWeatherCache>(
  (ref) => PlotWeatherCache(
    ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The cached weather for a plot in a language. Online (not demo) it is refreshed first;
/// offline the cached copy is shown with its date.
final plotWeatherProvider =
    FutureProvider.family<CachedWeather?, (String, String)>((ref, key) async {
      final (plotId, lang) = key;
      final cache = ref.watch(plotWeatherCacheProvider);
      if (!ref.watch(appConfigProvider).demoMode) {
        await cache.refresh(plotId, lang);
      }
      return cache.load(plotId, lang);
    });

final marketPricesCacheProvider = Provider<MarketPricesCache>(
  (ref) => MarketPricesCache(
    ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The crop whose mandi prices the grower sees: their first block's crop, else santra.
final marketCropProvider = Provider<String>(
  (ref) => ref.watch(plotsProvider).value?.firstOrNull?.crop ?? 'santra',
);

/// The cached mandi prices for a crop and scope. Online (not demo) they are refreshed
/// first; offline the cached copy is shown with its date.
final marketPricesProvider =
    FutureProvider.family<
      CachedMarketPrices?,
      (String, V1MarketPricesGetScope)
    >((ref, key) async {
      final (crop, scope) = key;
      final cache = ref.watch(marketPricesCacheProvider);
      if (!ref.watch(appConfigProvider).demoMode) {
        await cache.refresh(crop, scope);
      }
      return cache.load(crop, scope);
    });

/// Where the Sarkari Sandesh feed comes from: the built-in sample feed in demo mode (no
/// backend), else the server's `/v1/feed`. Tests override this.
final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => ref.watch(appConfigProvider).demoMode
      ? DemoFeedRepository(clock: ref.watch(clockProvider))
      : HttpFeedRepository(ref.watch(apiProvider)),
);

final feedCacheProvider = Provider<FeedCache>(
  (ref) => FeedCache(
    ref.watch(databaseProvider),
    repository: ref.watch(feedRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The cached feed for a language. It is refreshed first (best effort); offline the cached
/// copy is shown with its date.
final feedProvider = FutureProvider.family<CachedFeed?, String>((
  ref,
  lang,
) async {
  final cache = ref.watch(feedCacheProvider);
  await cache.refresh(lang);
  return cache.load(lang);
});

final textSharerProvider = Provider<TextSharer>(
  (ref) => const SharePlusTextSharer(),
);
