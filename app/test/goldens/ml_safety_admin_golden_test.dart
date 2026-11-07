// Admin web: market link reports, the action dialog and appeals (L6), light and dark.
//   flutter test --update-goldens test/goldens/ml_safety_admin_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/l10n/app_localizations_mr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../admin/market_link_safety_admin_test.dart';

Future<void> _shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('$name.png'));

void main() {
  // The admin web follows the browser language; the owner reads Marathi.
  final mr = AppLocalizationsMr();
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('admin_ml_safety_$mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.localesTestValue = const [Locale('mr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpAdmin(tester, FakeSafetyAdmin());
      await tester.tap(find.text(mr.adminMlReports));
      await tester.pumpAndSettle();
      await _shot(tester, 'admin_ml_reports_mr_$mode');
      await tester.tap(find.byKey(const ValueKey('act-r1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(mr.mlActionHide));
      await tester.tap(find.byKey(const ValueKey('code-fake_identity')));
      await tester.pumpAndSettle();
      await _shot(tester, 'admin_ml_action_mr_$mode');
      await tester.tap(find.text(mr.adminFeedCancel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(mr.adminMlAppeals));
      await tester.pumpAndSettle();
      await _shot(tester, 'admin_ml_appeals_mr_$mode');
    });
  }
}
