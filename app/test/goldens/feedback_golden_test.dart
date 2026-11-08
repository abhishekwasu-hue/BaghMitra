@Tags(['golden'])
library;

import 'package:bagmitra/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/feedback/feedback_test.dart'
    show FakeFeedbackServer, feedbackOverrides;
import '../helpers/pump_app.dart';

void main() {
  // Marathi phone screenshots of "अभिप्राय द्या" (owner 2026-11-08).
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = mode == ThemeMode.light ? 'light' : 'dark';
    testWidgets('feedback_mr_$name', (tester) async {
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: Routes.feedback,
        overrides: feedbackOverrides(FakeFeedbackServer()),
      );
      await tester.enterText(
        find.byKey(const Key('feedback-text')),
        'हवामान कार्ड उघडायला वेळ लागतो.',
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('feedback_mr_$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
