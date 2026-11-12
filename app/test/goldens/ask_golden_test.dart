// The विचारा tab with a stored answer (owner 2026-11-12, Q144): a 360 px phone, Marathi,
// 1.3x text, light and dark; and the close-questions state.
// Regenerate with:
//   flutter test --update-goldens test/goldens/ask_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/ask/ask_tab_test.dart' show ask;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

void main() {
  final cases = <String, (String, ThemeMode)>{
    'ask_answer_mr_light_360_x13': ('सायलाची लक्षणे काय?', ThemeMode.light),
    'ask_answer_mr_dark_360_x13': ('सायलाची लक्षणे काय?', ThemeMode.dark),
    'ask_close_mr_light_360_x13': ('झाडाची पाने', ThemeMode.light),
  };
  for (final MapEntry(key: name, value: (question, mode)) in cases.entries) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/ask',
        size: _phone,
      );
      await settle(tester);
      await ask(tester, question);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
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
