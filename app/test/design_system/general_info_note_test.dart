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
  testWidgets(
    'shows the general-information line and the source with its date',
    (tester) async {
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
      expect(
        find.textContaining('General information from public sources'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Source: ICAR-CCRI Nagpur · checked 6 Nov 2026'),
        findsOneWidget,
      );
    },
  );

  testWidgets('without a source only the general line shows (Marathi)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const GeneralInfoNote(), const Locale('mr')));
    await tester.pumpAndSettle();
    expect(find.textContaining('सर्वसाधारण माहिती'), findsOneWidget);
    expect(find.textContaining('स्रोत:'), findsNothing);
  });
}
