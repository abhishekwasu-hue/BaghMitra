@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market_link/terms_acceptance_test.dart' show marketConfig;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

void main() {
  // Sign-in after a role card (market link builds), Marathi, light and dark.
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = mode == ThemeMode.light ? 'light' : 'dark';
    testWidgets('login_role_mr_$name', (tester) async {
      await pumpApp(
        tester,
        session: null,
        themeMode: mode,
        config: marketConfig,
      );
      await tester.tap(find.byKey(const Key('role-trader')));
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('login_role_mr_$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
