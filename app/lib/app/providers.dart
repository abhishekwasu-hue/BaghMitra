import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/generated/bagmitra.swagger.dart';
import '../core/clock.dart';
import '../core/config.dart';
import '../data/local/database.dart';
import '../features/accounts/data/accounts_repository.dart';
import '../features/accounts/data/expense_categories.dart';
import '../features/accounts/domain/accounts.dart';
import '../features/auth/domain/auth.dart';
import '../features/bahar/data/bahar_catalog.dart';
import '../features/bahar/data/bahar_repository.dart';
import '../features/bahar/domain/bahar_cycle.dart';
import '../features/field_work/data/field_work_options.dart';
import '../features/field_work/data/field_work_repository.dart';
import '../features/field_work/domain/field_work.dart';
import '../features/home/data/demo_home_repository.dart';
import '../features/home/domain/home_snapshot.dart';
import '../features/inputs/data/input_kinds.dart';
import '../features/inputs/data/inputs_repository.dart';
import '../features/inputs/domain/field_records.dart';
import '../features/plots/data/crop_catalog.dart';
import '../features/plots/data/plot_repository.dart';
import '../features/plots/domain/plot.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/spray/data/restrictions_cache.dart';
import '../features/spray/data/spray_repository.dart';
import '../features/spray/domain/spray_check.dart';
import '../features/spray/domain/spray_record.dart';
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

final baharCatalogProvider = Provider<BaharCatalog>((ref) => BaharCatalog());

final baharOptionsProvider = FutureProvider<BaharCatalogData>(
  (ref) => ref.watch(baharCatalogProvider).load(),
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
