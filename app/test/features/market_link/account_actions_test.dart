import 'package:bagmitra/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'safety_screens_test.dart';

void main() {
  final en = AppLocalizationsEn();

  testWidgets('account actions: reason codes, appeal once, grievance officer', (
    tester,
  ) async {
    final fake = FakeSafety(
      actions: [
        action('a1', 'hide', 'fake_identity'),
        action('a2', 'verify', 'checks_passed'),
      ],
    );
    await pumpSafety(
      tester,
      fake,
      location: '/market-link/account-actions',
      locale: const Locale('en'),
      officer: (name: 'A. Officer', contact: 'grievance@example.test'),
    );
    expect(find.text('A. Officer'), findsOneWidget);
    expect(find.text('grievance@example.test'), findsOneWidget);
    expect(find.text(en.mlActionHide), findsOneWidget);
    expect(
      find.text(en.mlActionReason(en.mlReasonFakeIdentity)),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('appeal-a1')), findsOneWidget);
    expect(find.byKey(const ValueKey('appeal-a2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('appeal-a1')));
    await settle(tester);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('reason-identity_genuine')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('safety-send')));
    await settle(tester);
    expect(fake.calls, ['appeal a1 identity_genuine null']);
    expect(find.textContaining(en.mlAppealStateAppealed), findsOneWidget);
    expect(find.byKey(const ValueKey('appeal-a1')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets(
    'no actions: the default grievance officer and a calm empty state',
    (tester) async {
      await pumpSafety(
        tester,
        FakeSafety(),
        location: '/market-link/account-actions',
        locale: const Locale('en'),
      );
      expect(find.text(en.mlGrievanceDefault), findsOneWidget);
      expect(find.text(en.mlActionsEmpty), findsOneWidget);
      await unmountApp(tester);
    },
  );
}
