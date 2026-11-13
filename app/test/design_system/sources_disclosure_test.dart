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
  testWidgets('collapsed by default: one green "Sources (n)" header', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_sources, const Locale('en')));
    expect(find.text('Sources (3)'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    expect(find.text('NHB Citrus: Diseases'), findsNothing);
    expect(find.textContaining('Foot Rot'), findsNothing);
    expect(find.text('Official'), findsNothing);
    // 48 dp tap target and a button label for screen readers.
    final toggle = find.byKey(const Key('sources-toggle'));
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(toggle.first),
      matchesSemantics(
        label: 'Sources (3)',
        hint: 'See sources',
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
    // The header stays; the chevron and the screen-reader hint turn.
    expect(find.text('Sources (3)'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('sources-toggle'))),
      matchesSemantics(
        label: 'Sources (3)',
        hint: 'Hide sources',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
      ),
    );
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
    expect(find.text('Sources (3)'), findsOneWidget);
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
    expect(find.text('स्रोत (३)'), findsOneWidget);
    expect(find.text('स्रोत'), findsOneWidget);
    await tester.tap(find.text('स्रोत'));
    await tester.pump();
    expect(find.text('स्रोत: ICAR-CCRI'), findsOneWidget);
    expect(find.text('स्रोत (३)'), findsOneWidget);
  });

  testWidgets('link cards: counted, hidden until opened, a tap still opens', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _host(
        SourcesDisclosure(
          links: [
            for (final i in [1, 2])
              TextButton(
                key: Key('card-$i'),
                onPressed: () => opened = i,
                child: Text('Card $i'),
              ),
          ],
        ),
        const Locale('hi'),
      ),
    );
    // Hindi reads Latin digits (the app's number format for hi).
    expect(find.text('स्रोत (2)'), findsOneWidget);
    expect(find.byKey(const Key('card-1')), findsNothing);
    await tester.tap(find.byKey(const Key('sources-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('card-2')));
    expect(opened, 2);
    await tester.tap(find.byKey(const Key('sources-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('card-2')), findsNothing);
  });

  testWidgets('actions sit below the cards when open and are not counted', (
    tester,
  ) async {
    var copied = false;
    await tester.pumpWidget(
      _host(
        SourcesDisclosure(
          links: const [Text('Card')],
          actions: [
            TextButton(
              key: const Key('copy'),
              onPressed: () => copied = true,
              child: const Text('Copy link'),
            ),
          ],
        ),
        const Locale('en'),
      ),
    );
    expect(find.text('Sources (1)'), findsOneWidget);
    expect(find.byKey(const Key('copy')), findsNothing);
    await tester.tap(find.byKey(const Key('sources-toggle')));
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const Key('copy'))).dy,
      greaterThan(tester.getTopLeft(find.text('Card')).dy),
    );
    await tester.tap(find.byKey(const Key('copy')));
    expect(copied, isTrue);
  });

  testWidgets('header is green and bold in both themes', (tester) async {
    for (final theme in [BmTheme.light(), BmTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: _sources),
        ),
      );
      final c = tester.element(find.text('Sources (3)')).bm;
      final text = tester.widget<Text>(find.text('Sources (3)'));
      expect(text.style?.color, c.link);
      expect(text.style?.fontWeight, FontWeight.w700);
    }
  });

  testWidgets('nothing to show: no line at all', (tester) async {
    await tester.pumpWidget(
      _host(const SourcesDisclosure(), const Locale('en')),
    );
    expect(find.byKey(const Key('sources-toggle')), findsNothing);
  });
}
