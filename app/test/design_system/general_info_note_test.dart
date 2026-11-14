import 'package:bagmitra/design_system/general_info_note.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, Locale locale) => MaterialApp(
  theme: BmTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  // Owner 2026-11-10: the cards are checked against official sources, so the old
  // "General information · confirm with your KVK first" line (Q57) is gone; only the
  // folded sources stay.
  testWidgets('shows only the folded sources; no general-information line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const GeneralInfoNote(
          source: 'ICAR-CCRI Nagpur',
          checked: '6 Nov 2026',
        ),
        const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('General information'), findsNothing);
    expect(find.textContaining('KVK'), findsNothing);
    expect(find.textContaining('ICAR-CCRI'), findsNothing);
    await tester.tap(find.text('Sources'));
    await tester.pump();
    expect(
      find.textContaining('Source: ICAR-CCRI Nagpur · read 6 Nov 2026'),
      findsOneWidget,
    );
  });

  testWidgets('without a source it shows nothing (Marathi)', (tester) async {
    await tester.pumpWidget(_host(const GeneralInfoNote(), const Locale('mr')));
    await tester.pumpAndSettle();
    expect(find.textContaining('सर्वसाधारण माहिती'), findsNothing);
    expect(find.textContaining('KVK'), findsNothing);
    expect(find.byKey(const Key('sources-toggle')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(GeneralInfoNote),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
  });
}
