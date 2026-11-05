import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/generated/bagmitra.swagger.dart' show V1MarketPricesGetScope;
import '../core/net_failure.dart';
import '../features/feed/data/feed_cache.dart';
import '../features/market/data/market_prices_cache.dart';
import '../features/weather/data/plot_weather_cache.dart';
import '../sync/account_guard.dart';
import '../sync/sync_engine.dart';
import 'providers.dart';

/// When saved server answers (weather, prices, feed) are fetched again. Overridden in tests.
class RefreshPolicy {
  const RefreshPolicy({
    this.refreshAfter = const Duration(minutes: 30),
    this.firstPullWait = const Duration(seconds: 15),
  });

  /// How long a phone that has never pulled waits for the first pull before deciding
  /// whether the grower still needs onboarding (a returning grower on a new phone).
  final Duration firstPullWait;

  /// A saved copy older than this is refreshed in the background when a screen opens it
  /// and when the app comes back to the front. Pull-to-refresh always fetches.
  final Duration refreshAfter;

  bool isDue(DateTime savedAt, DateTime now) =>
      now.difference(savedAt) >= refreshAfter;
}

final refreshPolicyProvider = Provider<RefreshPolicy>(
  (ref) => const RefreshPolicy(),
);

/// How the last fetch of one saved answer went: still [busy], or the [failure] that kept
/// the saved copy on screen (null after a success).
class RefreshState {
  const RefreshState({this.busy = false, this.failure});

  final bool busy;
  final NetFailure? failure;
}

/// Refresh state per cache key (the keys of [PlotWeatherCache], [MarketPricesCache] and
/// [FeedCache]). Concurrent fetches of one key share one call.
class RefreshBoard extends Notifier<Map<String, RefreshState>> {
  final _inFlight = <String, Future<NetFailure?>>{};

  @override
  Map<String, RefreshState> build() => const {};

  Future<NetFailure?> run(
    String key,
    Future<NetFailure?> Function() fetch,
  ) => _inFlight[key] ??= _run(key, fetch).whenComplete(() {
    // A block body: returning the removed future would make it wait for itself.
    _inFlight.remove(key);
  });

  Future<NetFailure?> _run(
    String key,
    Future<NetFailure?> Function() fetch,
  ) async {
    // Never change this state while another provider is still building.
    await Future<void>.value();
    _set(key, RefreshState(busy: true, failure: state[key]?.failure));
    final failure = await fetch();
    _set(key, RefreshState(failure: failure));
    return failure;
  }

  void _set(String key, RefreshState s) {
    if (ref.mounted) state = {...state, key: s};
  }
}

final refreshBoardProvider =
    NotifierProvider<RefreshBoard, Map<String, RefreshState>>(RefreshBoard.new);

/// The refresh state of one cache key, for a screen's "updated" line and retry action.
final refreshStateProvider = Provider.family<RefreshState, String>(
  (ref, key) =>
      ref.watch(refreshBoardProvider.select((m) => m[key])) ??
      const RefreshState(),
);

/// Fetches saved server answers again: from pull-to-refresh, a retry button, or when the app
/// comes back to the front. Screens and the home screen call these; each one waits for the
/// fetch and then reloads the provider, so the screen shows the new copy.
class Refresher {
  Refresher(this._ref);

  final Ref _ref;

  bool get _demo => _ref.read(appConfigProvider).demoMode;

  RefreshBoard get _board => _ref.read(refreshBoardProvider.notifier);

  Future<void> plotWeather(String plotId, String lang) async {
    if (_demo) return;
    final cache = _ref.read(plotWeatherCacheProvider);
    final failure = await _board.run(
      PlotWeatherCache.keyFor(plotId, lang),
      () => cache.refreshOrFailure(plotId, lang),
    );
    if (failure == null) _ref.invalidate(plotWeatherProvider((plotId, lang)));
  }

  Future<void> marketPrices(String crop, V1MarketPricesGetScope scope) async {
    if (_demo) return;
    final cache = _ref.read(marketPricesCacheProvider);
    final failure = await _board.run(
      MarketPricesCache.keyFor(crop, scope),
      () => cache.refreshOrFailure(crop, scope),
    );
    if (failure == null) _ref.invalidate(marketPricesProvider((crop, scope)));
  }

  Future<void> feed(String lang) async {
    final cache = _ref.read(feedCacheProvider);
    final failure = await _board.run(
      FeedCache.keyFor(lang),
      () => cache.refreshOrFailure(lang),
    );
    if (failure == null) _ref.invalidate(feedProvider(lang));
  }

  /// Sends queued entries and pulls the latest records (orchard and task lists). Does
  /// nothing in demo mode or before the phone's records are known to be this account's.
  Future<void> records() async {
    if (_demo) return;
    final gate = _ref.read(accountGateProvider).value;
    if (gate != AccountCheck.same) return;
    await _ref.read(syncEngineProvider).sync();
  }

  /// The app came back to the front: reload weather, prices and feed (each provider fetches
  /// again only when its saved copy is older than [RefreshPolicy.refreshAfter]), and sync.
  void onResume() {
    _ref
      ..invalidate(plotWeatherProvider)
      ..invalidate(marketPricesProvider)
      ..invalidate(feedProvider);
    unawaited(records());
  }
}

final refresherProvider = Provider<Refresher>(Refresher.new);

/// Done once this phone has pulled from the server at least once for the signed-in account,
/// or the first pull ended (offline, error, or [RefreshPolicy.firstPullWait] passed).
/// Onboarding waits for it, so a returning grower's profile arrives first (audit LG-05).
final firstPullProvider = FutureProvider<void>((ref) async {
  if (ref.watch(appConfigProvider).demoMode) return;
  final own = ref.watch(
    accountGateProvider.select(
      (g) => !g.isLoading && g.value == AccountCheck.same,
    ),
  );
  if (!own) return;
  final db = ref.watch(databaseProvider);
  if (await db.readMeta(SyncEngine.cursorKey) != null) return;
  final engine = ref.read(syncEngineProvider);
  await engine.sync().timeout(
    ref.read(refreshPolicyProvider).firstPullWait,
    onTimeout: () => const SyncRunResult(offline: true),
  );
});

/// Shared by the weather, market and feed providers: the saved copy comes first; when
/// there is none, the first fetch is awaited (bounded by the API timeouts); when it is older
/// than the policy allows, it is fetched again in the background and the provider reloads
/// once the new copy is stored. A failed fetch keeps the saved copy and is recorded on the
/// [RefreshBoard] for the screen's retry action.
Future<T?> cacheFirst<T>(
  Ref ref, {
  required String key,
  required Future<T?> Function() load,
  required DateTime Function(T cached) savedAt,
  required Future<NetFailure?> Function() fetch,
  bool fetchAllowed = true,
}) async {
  final cached = await load();
  if (!fetchAllowed) return cached;
  final board = ref.read(refreshBoardProvider.notifier);
  if (cached == null) {
    await board.run(key, fetch);
    return load();
  }
  final now = ref.read(clockProvider)();
  if (ref.read(refreshPolicyProvider).isDue(savedAt(cached), now)) {
    unawaited(
      board.run(key, fetch).then((failure) {
        if (failure == null && ref.mounted) ref.invalidateSelf();
      }),
    );
  }
  return cached;
}
