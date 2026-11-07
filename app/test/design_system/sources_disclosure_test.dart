import 'package:bagmitra/design_system/sources_disclosure.dart';
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

const _sources = SourcesDisclosure(
  notes: ['Source: C02 "Foot Rot or Gummosis" p.4'],
  sources: [
    SourceRef(
      'NHB Citrus: Diseases',
      url: 'https://www.nhb.gov.in/cit002.pdf',
      publisher: 'NHB',
      checked: '26 Oct 2026',
    ),
    SourceRef('PDKV recommendations', publisher: 'Dr. PDKV'),
    SourceRef('A page with only a title'),
  ],
  kinds: ['Official', 'University'],
);

void main() {
  testWidgets('collapsed by default: one quiet line with the count', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_sources, const Locale('en')));
    expect(find.text('See sources (3)'), findsOneWidget);
    expect(find.text('NHB Citrus: Diseases'), findsNothing);
    expect(find.textContaining('Foot Rot'), findsNothing);
    expect(find.text('Official'), findsNothing);
    // 48 dp tap target and a button label for screen readers.
    final toggle = find.byKey(const Key('sources-toggle'));
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(toggle.first),
      matchesSemantics(
        label: 'See sources (3)',
        isButton: true,
        hasExpandedState: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('one tap shows every source; a second tap folds it again', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_sources, const Locale('en')));
    await tester.tap(find.byKey(const Key('sources-toggle')));
    await tester.pump();
    expect(find.text('Hide sources'), findsOneWidget);
    expect(find.text('Source: C02 "Foot Rot or Gummosis" p.4'), findsOneWidget);
    expect(find.text('NHB Citrus: Diseases'), findsOneWidget);
    expect(find.text('NHB · read 26 Oct 2026'), findsOneWidget);
    expect(find.text('https://www.nhb.gov.in/cit002.pdf'), findsOneWidget);
    expect(find.text('PDKV recommendations'), findsOneWidget);
    expect(find.text('Dr. PDKV'), findsOneWidget);
    expect(find.text('A page with only a title'), findsOneWidget);
    expect(find.text('Official'), findsOneWidget);
    expect(find.text('University'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sources-toggle')));
    await tester.pump();
    expect(find.text('See sources (3)'), findsOneWidget);
    expect(find.text('NHB Citrus: Diseases'), findsNothing);
  });

  testWidgets('Marathi: count in Marathi digits, plain label without a list', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            _sources,
            SourcesDisclosure(notes: ['स्रोत: ICAR-CCRI']),
          ],
        ),
        const Locale('mr'),
      ),
    );
    expect(find.text('स्रोत पहा (३)'), findsOneWidget);
    expect(find.text('स्रोत पहा'), findsOneWidget);
    await tester.tap(find.text('स्रोत पहा'));
    await tester.pump();
    expect(find.text('स्रोत: ICAR-CCRI'), findsOneWidget);
    expect(find.text('स्रोत लपवा'), findsOneWidget);
  });

  testWidgets('nothing to show: no line at all', (tester) async {
    await tester.pumpWidget(
      _host(const SourcesDisclosure(), const Locale('en')),
    );
    expect(find.byKey(const Key('sources-toggle')), findsNothing);
  });
}
