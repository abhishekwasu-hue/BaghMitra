@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market_link/terms_acceptance_test.dart' show marketConfig;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

void main() {
  // Home "बाजार जोडणी" card with the two direct buttons (market link builds), Marathi.
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = mode == ThemeMode.light ? 'light' : 'dark';
    testWidgets('home_market_mr_$name', (tester) async {
      await pumpApp(tester, themeMode: mode, config: marketConfig);
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('home-ml-people')));
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('home_market_mr_$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
