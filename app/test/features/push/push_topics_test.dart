// Update-push switches (Settings -> सूचना, Q147) and where a tapped push opens. Fakes only.
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/push/data/push_topics_store.dart';
import 'package:bagmitra/features/push/domain/push_links.dart';
import 'package:bagmitra/features/push/domain/push_topics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../plots/plots_screen_test.dart' show settle;

const _id = '6f1c2a3b-4d5e-4f60-8a9b-0c1d2e3f4a5b';
const _thread = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d';

/// The server: answers with what it holds, or fails while [offline].
class FakeTopicsApi implements PushTopicsApi {
  FakeTopicsApi([this.held = PushTopics.defaults]);

  PushTopics held;
  bool offline = false;
  final calls = <String>[];

  @override
  Future<PushTopics> load() async {
    calls.add('get');
    if (offline) throw const PushTopicsUnavailable(503);
    return held;
  }

  @override
  Future<PushTopics> save(PushTopics topics) async {
    calls.add('put ${topics.toJson()}');
    if (offline) throw const PushTopicsUnavailable(503);
    return held = topics;
  }
}

void main() {
  group('pushLink', () {
    test('article, feed, market, weather and risk-alert pushes', () {
      expect(
        pushLink({'kind': 'article', 'item_id': _id})?.route,
        '/feed/$_id',
      );
      expect(
        pushLink({'kind': 'article', 'item_id': _id, 'thread_id': _thread})
            ?.route,
        '/feed-thread/$_thread',
      );
      expect(
        pushLink({'kind': 'article', 'items': '$_id,$_id'})?.route,
        '/feed',
      );
      expect(
        pushLink({'kind': 'feed_alert', 'item_id': _id})?.route,
        '/feed/$_id',
      );
      expect(pushLink({'kind': 'feed_digest', 'items': _id})?.route, '/feed');
      expect(pushLink({'kind': 'market', 'crop': 'santra'}), (
        route: '/market',
        crop: 'santra',
      ));
      expect(
        pushLink({'kind': 'weather_change', 'plot_id': _id})?.route,
        '/plots/$_id/weather',
      );
      expect(
        pushLink({'plot_id': _id, 'rule_key': 'heat_fruit_drop'})?.route,
        '/plots/$_id/weather',
      );
      expect(
        pushLink({
          'plot_id': _id,
          'rule_key': 'heavy_rain',
          'action': 'claim_kit',
        })?.route,
        '/claim-kit?plot=$_id',
      );
    });

    test('anything unknown or malformed opens nothing', () {
      expect(pushLink({}), isNull);
      expect(pushLink({'kind': 'other'}), isNull);
      expect(pushLink({'kind': 'weather_change'}), isNull);
      expect(
        pushLink({'kind': 'weather_change', 'plot_id': '../../x'}),
        isNull,
      );
      expect(
        pushLink({'kind': 'article', 'item_id': '/settings'})?.route,
        '/feed',
      );
      expect(pushLink({'kind': 'market', 'crop': 'Bad Crop!'}), (
        route: '/market',
        crop: null,
      ));
      expect(
        pushLink({'plot_id': _id}),
        isNull,
        reason: 'no rule: not a risk alert',
      );
    });
  });

  group('PushTopicsStore', () {
    late AppDatabase db;
    late FakeTopicsApi api;
    setUp(() {
      db = memoryDb();
      api = FakeTopicsApi();
    });
    tearDown(() => db.close());

    test('all on by default; a change reaches the server', () async {
      final store = PushTopicsStore(db, userId: 'u1', api: api);
      expect(await store.local(), PushTopics.defaults);
      final after = await store.set(PushTopic.market, on: false);
      expect(after.market, isFalse);
      expect(api.held.market, isFalse);
      expect(await store.pending(), isFalse);
    });

    test('offline: kept on the phone, pending, sent on the next sync', () async {
      api.offline = true;
      final store = PushTopicsStore(db, userId: 'u1', api: api);
      final after = await store.set(PushTopic.weather, on: false);
      expect(after.weather, isFalse, reason: 'the switch moves at once');
      expect(await store.pending(), isTrue);
      expect(api.held.weather, isTrue, reason: 'the server has not heard yet');
      api.offline = false;
      await store.sync();
      expect(api.held.weather, isFalse);
      expect(await store.pending(), isFalse);
      // Nothing pending: the server's copy (changed on another phone) is taken.
      api.held = const PushTopics(articles: false);
      expect((await store.sync()).articles, isFalse);
    });

    test("another account's copy and no API (demo) are handled", () async {
      final mine = PushTopicsStore(db, userId: 'u1', api: api);
      await mine.set(PushTopic.articles, on: false);
      final other = PushTopicsStore(db, userId: 'u2', api: FakeTopicsApi());
      expect(await other.local(), PushTopics.defaults);
      final demo = PushTopicsStore(db, userId: 'u1');
      expect((await demo.set(PushTopic.market, on: false)).market, isFalse);
      expect(await demo.pending(), isFalse);
    });
  });

  testWidgets('Settings -> सूचना: three switches, on by default, saved', (
    tester,
  ) async {
    final api = FakeTopicsApi()..offline = true;
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [pushTopicsApiProvider.overrideWithValue(api)],
    );
    await settle(tester);
    expect(find.text('सूचना'), findsOneWidget);
    for (final topic in PushTopic.values) {
      final tile = find.byKey(Key('push-topic-${topic.name}'));
      expect(tile, findsOneWidget);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    }
    expect(find.text('लेख'), findsOneWidget);
    expect(find.text('बाजारभाव'), findsOneWidget);
    expect(find.text('हवामान बदल'), findsOneWidget);
    await tester.tap(find.byKey(const Key('push-topic-market')));
    await settle(tester);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('push-topic-market')))
          .value,
      isFalse,
    );
    expect(
      api.calls.last,
      startsWith('put'),
      reason: 'tried, offline: kept pending',
    );
    expect(api.held.market, isTrue);
    await unmountApp(tester);
  });
}
