import 'dart:async';
import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.enums.swagger.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/app/refresh.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/core/net_failure.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market/data/market_prices_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/market/market_prices_test.dart' show samplePrices;
import '../helpers/pump_app.dart' show testConfig;
import '../helpers/test_db.dart';

const _online = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'https://api.example.test',
  supabaseUrl: 'https://project.supabase.test',
  supabaseAnonKey: 'anon',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
);

const _all = V1MarketPricesGetScope.all;
final _key = MarketPricesCache.keyFor('santra', _all);

/// A server whose next answer the test decides: a body, a status, an error, or held open.
class _Server {
  int calls = 0;
  int status = 200;
  Object? error;
  int modal = 3300;
  Completer<void>? hold;

  Future<http.Response> handle(http.Request req) async {
    calls++;
    if (hold case final h?) await h.future;
    if (error case final e?) throw e;
    final body = samplePrices();
    ((body['prices']! as List).first as Map)['modal_rs_per_quintal'] = modal;
    return http.Response(jsonEncode(body), status);
  }
}

void main() {
  late AppDatabase db;
  late _Server server;
  late TestClock clock;
  late ProviderContainer container;

  Future<void> seed(DateTime savedAt, {int modal = 1000}) {
    final body = samplePrices();
    ((body['prices']! as List).first as Map)['modal_rs_per_quintal'] = modal;
    return db.writeMeta(
      _key,
      jsonEncode({'saved_at': savedAt.toIso8601String(), 'prices': body}),
    );
  }

  ProviderContainer build({AppConfig config = _online}) => ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock.call),
      apiProvider.overrideWithValue(
        createApi(
          baseUrl: Uri.parse('https://api.example.test'),
          token: () => 't',
          httpClient: MockClient(server.handle),
        ),
      ),
    ],
  );

  Future<int?> modal() async =>
      (await container.read(marketPricesProvider(('santra', _all)).future))
          ?.prices
          .prices
          .first
          .modalRsPerQuintal;

  NetFailure? failure() => container.read(refreshStateProvider(_key)).failure;

  setUp(() {
    db = memoryDb();
    server = _Server();
    clock = TestClock(DateTime.utc(2026, 10, 25, 12));
    container = build();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('nothing saved yet: the first answer is awaited and saved', () async {
    expect(await modal(), 3300);
    expect(server.calls, 1);
    expect(failure(), isNull);
  });

  test(
    'an old saved copy shows at once while the server is still answering',
    () async {
      await seed(clock.now.subtract(const Duration(hours: 2)));
      server.hold = Completer<void>();
      expect(await modal(), 1000, reason: 'the saved copy, not a spinner');
      await pumpEventQueue();
      expect(server.calls, 1, reason: 'refreshing in the background');
      expect(container.read(refreshStateProvider(_key)).busy, isTrue);

      server.hold!.complete();
      await pumpEventQueue(times: 50);
      expect(await modal(), 3300, reason: 'reloaded with the new copy');
      expect(failure(), isNull);
    },
  );

  test('a recent saved copy is used as it is', () async {
    await seed(clock.now.subtract(const Duration(minutes: 5)));
    expect(await modal(), 1000);
    await pumpEventQueue();
    expect(server.calls, 0);
  });

  test(
    'offline: the saved copy stays and the retry brings the new one',
    () async {
      await seed(clock.now.subtract(const Duration(hours: 2)));
      server.error = http.ClientException('no network');
      expect(await modal(), 1000);
      await pumpEventQueue(times: 50);
      expect(failure(), NetFailure.offline);
      expect(await modal(), 1000);

      server.error = null;
      await container.read(refresherProvider).marketPrices('santra', _all);
      expect(failure(), isNull);
      expect(await modal(), 3300);
    },
  );

  test('server errors and an ended session are told apart', () async {
    await seed(clock.now.subtract(const Duration(hours: 2)));
    server.status = 503;
    await container.read(refresherProvider).marketPrices('santra', _all);
    expect(failure(), NetFailure.server);
    server.status = 401;
    await container.read(refresherProvider).marketPrices('santra', _all);
    expect(failure(), NetFailure.signedOut);
    server
      ..status = 200
      ..error = TimeoutException('slow');
    await container.read(refresherProvider).marketPrices('santra', _all);
    expect(failure(), NetFailure.server);
    expect(await modal(), 1000, reason: 'the saved copy is kept throughout');
  });

  test(
    'back to the front: refreshed only when the copy is older than 30 min',
    () async {
      await seed(clock.now.subtract(const Duration(minutes: 1)));
      expect(await modal(), 1000);
      container.read(refresherProvider).onResume();
      expect(await modal(), 1000);
      await pumpEventQueue();
      expect(server.calls, 0);

      clock.advance(const Duration(minutes: 30));
      container.read(refresherProvider).onResume();
      expect(await modal(), 1000);
      await pumpEventQueue(times: 50);
      expect(server.calls, 1);
      expect(await modal(), 3300);
    },
  );

  test('demo mode never fetches', () async {
    container.dispose();
    container = build(config: testConfig);
    expect(await modal(), isNull);
    await container.read(refresherProvider).marketPrices('santra', _all);
    expect(server.calls, 0);
  });
}
