// Settings -> सूचना (owner 2026-11-12, Q147): the three update-push switches on a 360 px
// phone, Marathi, 1.3x text, light and dark; the market switch turned off.
// Regenerate with:
//   flutter test --update-goldens test/goldens/settings_notifications_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/plots/plots_screen_test.dart' show settle;
import '../features/push/push_topics_test.dart' show FakeTopicsApi;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

void main() {
  final cases = <String, ThemeMode>{
    'settings_notifications_mr_light_360_x13': ThemeMode.light,
    'settings_notifications_mr_dark_360_x13': ThemeMode.dark,
  };
  for (final MapEntry(key: name, value: mode) in cases.entries) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/settings',
        size: _phone,
        overrides: [pushTopicsApiProvider.overrideWithValue(FakeTopicsApi())],
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('push-topic-market')));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('push-topic-weather')));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
