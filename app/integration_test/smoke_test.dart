import 'package:bagmitra/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs the real app (demo auth, no network) on an emulator: first-run walkthrough, login,
/// OTP, setup screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a grower signs in with a phone number and reaches setup', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // A fresh install shows the walkthrough once, before sign-in.
    expect(find.byKey(const Key('walkthrough-skip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('walkthrough-skip')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(find.byKey(const Key('phone')), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first);
    // From here the OTP screen runs the one-second "resend in" countdown, so the frame
    // queue never settles: pump for a fixed time instead of pumpAndSettle.
    await pumpFor(tester, const Duration(seconds: 2));

    await tester.enterText(find.byKey(const Key('otp')), '123456');
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byType(FilledButton).first);
    await pumpFor(tester, const Duration(seconds: 3));

    expect(find.byKey(const Key('otp')), findsNothing);
  });
}

/// Pumps frames for [total] in small steps (works while a periodic timer is running).
Future<void> pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}
