// Q133 (owner request): the ⚠ tile on a risk alert is an on/off button for that alert
// type. A type switched off shows one muted line with the same button; the setting is kept
// on the phone per rule key and is shared by home and the plot weather card.
import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/design_system/alert_banner.dart';
import 'package:bagmitra/features/weather/data/alert_switches.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../home/home_seed.dart';
import '../plots/plots_screen_test.dart' show settle;

Map<String, Object?> _alert(String key, String text) => {
  'rule_key': key,
  'first_day': '2026-10-14',
  'value': 35.0,
  'units': null,
  'text': text,
  'source': 'ICAR-CCRI Nagpur',
  'status': 'reviewed',
};

/// Saved weather for [plotId] with a heat alert first and a psylla alert second.
Future<void> seedTwoAlerts(
  AppDatabase db, {
  String plotId = 'p1',
  String lang = 'mr',
}) => db.writeMeta(
  PlotWeatherCache.keyFor(plotId, lang),
  jsonEncode({
    'saved_at': '2026-10-13T05:00:00.000Z',
    'weather': {
      'days': [
        for (var i = 0; i < 4; i++)
          {
            'day': '2026-10-${13 + i}',
            't_max_c': 35.0 + i,
            't_min_c': 21.0,
            'precip_mm': 0.0,
            'rh_mean_pct': 50.0,
            'wind_gust_kmh': 20.0,
          },
      ],
      'alerts': [
        _alert('heat_fruit_drop', 'Heat alert text'),
        _alert('psylla_degree_days', 'Psylla alert text'),
      ],
      'stale': false,
    },
  }),
);

void main() {
  test(
    'the off setting is kept per rule key and survives a new store',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final store = AlertSwitches(db);
      expect(await store.load(), isEmpty);
      await store.setOn('psylla_degree_days', on: false);
      await store.setOn('heat_fruit_drop', on: false);
      expect(await AlertSwitches(db).load(), {
        'psylla_degree_days',
        'heat_fruit_drop',
      });
      await store.setOn('heat_fruit_drop', on: true);
      expect(await AlertSwitches(db).load(), {'psylla_degree_days'});
      expect(await AlertSwitches(db).watch().first, {'psylla_degree_days'});
    },
  );

  testWidgets('home: the ⚠ button switches the alert type off and on again', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = await pumpApp(tester);
    await settle(tester);
    final toggle = find.byKey(const Key('home-alert-toggle-heat_fruit_drop'));
    expect(find.byType(AlertBanner), findsOneWidget);
    expect(toggle, findsOneWidget);
    expect(find.bySemanticsLabel('हा अलर्ट बंद करा'), findsOneWidget);
    final size = tester.getSize(toggle);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(toggle);
    await settle(tester);
    expect(find.byType(AlertBanner), findsNothing);
    final line = find.byKey(const Key('home-alert-off-heat_fruit_drop'));
    expect(line, findsOneWidget);
    expect(find.text('उष्णता अलर्ट बंद'), findsOneWidget);
    expect(find.bySemanticsLabel('हा अलर्ट चालू करा'), findsOneWidget);
    expect(await AlertSwitches(db).load(), {'heat_fruit_drop'});
    final onButton = find.byKey(const Key('home-alert-on-heat_fruit_drop'));
    final onSize = tester.getSize(onButton);
    expect(onSize.width, greaterThanOrEqualTo(48));
    expect(onSize.height, greaterThanOrEqualTo(48));

    await tester.tap(onButton);
    await settle(tester);
    expect(find.byType(AlertBanner), findsOneWidget);
    expect(line, findsNothing);
    expect(await AlertSwitches(db).load(), isEmpty);
    await unmountApp(tester);
    handle.dispose();
  });

  testWidgets(
    'home: a saved off setting holds at start; other types still show',
    (tester) async {
      await pumpApp(
        tester,
        config: realConfig,
        syncStatus: const SyncStatus(connectivity: Connectivity.online),
        seed: (db) async {
          await seedHomeData(db);
          await seedTwoAlerts(db);
          await AlertSwitches(db).setOn('heat_fruit_drop', on: false);
        },
      );
      await settle(tester);
      expect(find.text('Heat alert text'), findsNothing);
      expect(find.text('Psylla alert text'), findsOneWidget);
      expect(
        find.byKey(const Key('home-alert-toggle-psylla_degree_days')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('home-alert-off-heat_fruit_drop')),
        findsOneWidget,
      );
      expect(find.text('उष्णता अलर्ट बंद'), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('plot weather card follows the same setting', (tester) async {
    final db = await pumpApp(
      tester,
      initialLocation: '/plots/p1',
      seed: (db) async {
        await seedPlot(db, lat: 21.2468, lon: 77.7512);
        await seedTwoAlerts(db);
        await AlertSwitches(db).setOn('heat_fruit_drop', on: false);
      },
    );
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('plot-weather')), 200);
    expect(find.text('Heat alert text'), findsNothing);
    expect(
      find.byKey(const Key('weather-alert-off-heat_fruit_drop')),
      findsOneWidget,
    );
    expect(find.text('Psylla alert text'), findsOneWidget);

    final psylla = find.byKey(
      const Key('weather-alert-toggle-psylla_degree_days'),
    );
    await tester.ensureVisible(psylla);
    expect(tester.getSize(psylla).height, greaterThanOrEqualTo(48));
    await tester.tap(psylla);
    await settle(tester);
    expect(find.text('Psylla alert text'), findsNothing);
    expect(find.text('सायला अलर्ट बंद'), findsOneWidget);
    expect(await AlertSwitches(db).load(), {
      'heat_fruit_drop',
      'psylla_degree_days',
    });

    final heatOn = find.byKey(const Key('weather-alert-on-heat_fruit_drop'));
    await tester.ensureVisible(heatOn);
    await tester.tap(heatOn);
    await settle(tester);
    expect(find.text('Heat alert text'), findsOneWidget);
    expect(await AlertSwitches(db).load(), {'psylla_degree_days'});
    await unmountApp(tester);
  });

  testWidgets('an unknown rule key falls back to "this alert is off"', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/plots/p1',
      seed: (db) async {
        await seedPlot(db, lat: 21.2468, lon: 77.7512);
        await db.writeMeta(
          PlotWeatherCache.keyFor('p1', 'mr'),
          jsonEncode({
            'saved_at': '2026-10-13T05:00:00.000Z',
            'weather': {
              'days': <Object?>[],
              'alerts': [_alert('new_rule', 'New rule text')],
              'stale': false,
            },
          }),
        );
        await AlertSwitches(db).setOn('new_rule', on: false);
      },
    );
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('plot-weather')), 200);
    expect(find.text('हा अलर्ट बंद'), findsOneWidget);
    await unmountApp(tester);
  });
}
