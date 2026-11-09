import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market/data/price_history_cache.dart';
import 'package:bagmitra/features/market/domain/price_trend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'market_prices_test.dart' show seedPrices;

/// The prices list's Warud row (santra, Nagpuri, FAQ) names this series.
const warud = (
  crop: 'santra',
  market: 'Warud',
  variety: 'Nagpuri',
  grade: 'FAQ',
);

Map<String, Object?> day(String d, int modal, {int? min, int? max}) => {
  'day': d,
  'min_rs_per_quintal': min ?? modal - 400,
  'max_rs_per_quintal': max ?? modal + 400,
  'modal_rs_per_quintal': modal,
  'source': 'agmarknet',
};

/// Three months up to the widget tests' clock (2026-10-13), with a gap of more than three
/// days in September (no price published).
Map<String, Object?> historyBody() => {
  'market': 'Warud',
  'variety': 'Nagpuri',
  'grade': 'FAQ',
  'days': [
    day('2026-07-10', 2600),
    day('2026-08-10', 2800),
    day('2026-08-25', 3000),
    day('2026-09-12', 3200),
    day('2026-09-13', 3100),
    day('2026-09-20', 3000),
    day('2026-09-28', 3500),
    day('2026-10-01', 3300),
    day('2026-10-06', 3600),
    day('2026-10-11', 3400),
    day('2026-10-12', 3500),
  ],
  'stale': false,
};

Future<void> seedHistory(AppDatabase db, {Map<String, Object?>? body}) =>
    db.writeMeta(
      PriceHistoryCache.keyFor(warud),
      jsonEncode({
        'saved_at': '2026-10-13T05:00:00.000Z',
        'history': body ?? historyBody(),
      }),
    );

List<PriceDay> points() => [
  for (final d in historyBody()['days']! as List)
    PriceDay.fromJson((d as Map).cast<String, dynamic>()),
];

void main() {
  final today = DateTime.utc(2026, 10, 13, 6);

  test('ranges cut the series back from today', () {
    expect(pointsIn(points(), TrendRange.months3, today), hasLength(10));
    expect(
      pointsIn(points(), TrendRange.month1, today).first.day,
      DateTime(2026, 9, 20),
    );
    expect(pointsIn(points(), TrendRange.days15, today), hasLength(4));
  });

  test('high, low and the change since 15 days and 1 month', () {
    final s = TrendStats.of(pointsIn(points(), TrendRange.months3, today))!;
    expect(s.high.modalRsPerQuintal, 3600);
    expect(s.low.modalRsPerQuintal, 2800);
    expect(s.latest.day, DateTime(2026, 10, 12));
    // 3500 against 3000 on 2026-09-20 (last price on or before 2026-09-27): +17 %.
    expect(s.change15, 17);
    // 3500 against 3200 on 2026-09-12 (on or before 2026-09-12): +9 %.
    expect(s.change30, 9);
    final short = TrendStats.of(pointsIn(points(), TrendRange.days15, today))!;
    expect(short.change15, isNull, reason: 'no earlier price inside the range');
    expect(TrendStats.of(const []), isNull);
  });

  test(
    'days further apart than three are not joined (no price was published)',
    () {
      final p = points();
      expect(joined(p[3], p[4]), isTrue);
      expect(joined(p[6], p[7]), isTrue, reason: 'three days apart');
      expect(joined(p[4], p[5]), isFalse, reason: 'seven days apart');
    },
  );

  test('the cache asks for 90 days of one mandi and works offline', () async {
    final db = memoryDb();
    addTearDown(db.close);
    var online = true;
    final requested = <Uri>[];
    final api = createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => 't',
      httpClient: MockClient((req) async {
        requested.add(req.url);
        if (!online) throw http.ClientException('offline');
        return http.Response(jsonEncode(historyBody()), 200);
      }),
    );
    final cache = PriceHistoryCache(db, api: api, clock: () => today);
    expect(await cache.load(warud), isNull);
    expect(await cache.refreshOrFailure(warud), isNull);
    expect(requested.single.path, '/v1/market/prices/history');
    expect(requested.single.queryParameters, {
      'crop': 'santra',
      'market': 'Warud',
      'variety': 'Nagpuri',
      'grade': 'FAQ',
      'days': '90',
    });
    online = false;
    expect(await cache.refreshOrFailure(warud), isNotNull);
    final cached = (await cache.load(warud))!;
    expect(cached.history.days, hasLength(11));
    expect(cached.savedAt, today);
  });

  testWidgets(
    'the chart opens from a price, changes range and follows the finger',
    (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/market',
        seed: (db) async {
          await seedPrices(db);
          await seedHistory(db);
        },
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('market-trend-Warud')));
      await settle(tester);

      expect(find.text('Price trend: Warud'), findsOneWidget);
      expect(find.text('₹3,600'), findsOneWidget, reason: 'highest');
      expect(find.text('₹2,800'), findsOneWidget, reason: 'lowest');
      expect(find.text('+17%'), findsOneWidget);
      expect(find.text('+9%'), findsOneWidget);
      // The latest day is shown until the grower touches the chart.
      final selected = find.byKey(const Key('trend-selected'));
      expect(
        find.descendant(of: selected, matching: find.text('₹3,500')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: selected, matching: find.text('12 Oct 2026')),
        findsOneWidget,
      );

      // A finger at the left edge picks the first day of the range.
      final chart = find.byKey(const Key('trend-chart'));
      await tester.tapAt(tester.getTopLeft(chart) + const Offset(2, 40));
      await tester.pump();
      expect(
        find.descendant(of: selected, matching: find.text('10 Aug 2026')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: selected,
          matching: find.textContaining('₹2,400 – ₹3,200'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('trend-range-15')));
      await settle(tester);
      expect(
        find.text('+17%'),
        findsNothing,
        reason: 'no price 15 days before',
      );
      expect(find.text('₹3,600'), findsWidgets);
      await unmountApp(tester);
    },
  );

  testWidgets(
    'a mandi without saved history says the chart fills in day by day',
    (tester) async {
      await pumpApp(tester, initialLocation: '/market', seed: seedPrices);
      await settle(tester);
      await tester.tap(find.byKey(const Key('market-trend-Warud')));
      await settle(tester);
      expect(find.byKey(const Key('trend-empty')), findsOneWidget);
      expect(
        find.text('भाव दररोज साठवला जातो; चार्ट दिवसागणिक भरत जातो.'),
        findsOneWidget,
      );
      await unmountApp(tester);
    },
  );
}
