import 'package:bagmitra/features/export_info/domain/export_record.dart';
import 'package:bagmitra/features/export_info/presentation/export_record_page.dart';
import 'package:bagmitra/features/spray/domain/spray_check.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../spray/spray_records_test.dart' show SprayTestCopy, spray;

final _rules = RestrictionList.fromJson({
  'restrictions': [
    {
      'active_ingredient': 'dicofol',
      'kind': 'banned',
      'notification': 'S.O. 4294(E)',
      'effective_from': '2023-10-03T00:00:00Z',
    },
    {
      'active_ingredient': 'monocrotophos',
      'kind': 'restricted',
      'crop_groups': ['citrus'],
      'notification': 'S.O. 1',
      'effective_from': '2020-01-01T00:00:00Z',
    },
  ],
  'synonyms': [
    {'name': 'Kelthane', 'active_ingredient': 'dicofol'},
  ],
});

const _crop = CropRules(labelAliases: {'orange'}, groups: {'citrus'});

SprayRecord mancozebSpray(String id, DateTime on) => SprayRecord(
  id: id,
  plotId: 'p1',
  baharCycleId: 'b1',
  sprayedOn: on,
  productName: 'Dithane M-45',
  activeIngredient: ' MANCOZEB ',
  dose: '2 g/L',
  phiDays: 7,
);

void main() {
  group('export record rows', () {
    final sprays = [
      spray('s1', cycle: 'b1'),
      spray('s2').copyWithActive('Kelthane'),
      mancozebSpray('s3', DateTime(2026, 10, 20)),
      spray('s4', cycle: 'b1').copyWithActive('Monocrotophos'),
    ];

    test('label status as the app checks it; oldest first; PHI end', () {
      final rows = exportRecordRows(
        sprays: sprays,
        baharCycleId: null,
        crop: _crop,
        rules: _rules,
        labelIngredients: ['Mancozeb', 'Azoxystrobin'],
      );
      expect(rows.first.product, 'Dithane M-45');
      expect(rows.first.phiEnd, DateTime(2026, 10, 27));
      expect(
        {for (final r in rows) r.activeIngredient?.trim(): r.status},
        {
          'MANCOZEB': LabelStatus.listed,
          'imidacloprid': LabelStatus.check,
          'Kelthane': LabelStatus.banned,
          'Monocrotophos': LabelStatus.restricted,
        },
      );
      final imida = rows.firstWhere((r) => r.product == 'Imida 17.8 SL');
      expect(imida.phiEnd, DateTime(2026, 11, 17));
      expect(
        rows.firstWhere((r) => r.activeIngredient == 'Kelthane').phiEnd,
        isNull,
      );
    });

    test('one bahar only; no saved label list means "check"', () {
      final rows = exportRecordRows(
        sprays: sprays,
        baharCycleId: 'b1',
        crop: _crop,
        rules: _rules,
        labelIngredients: null,
      );
      expect(rows.map((r) => r.product), ['Dithane M-45', 'Imida 17.8 SL']);
      expect(rows.map((r) => r.status), everyElement(LabelStatus.check));
    });

    test('pages: fewer rows on the first; no rows is one page', () {
      final pages = paginate(List.generate(40, (i) => i), first: 16, other: 22);
      expect(pages.map((p) => p.length), [16, 22, 2]);
      expect(paginate(const <int>[], first: 16, other: 22), [isEmpty]);
    });
  });

  test('every printed page carries the information-only footer', () async {
    await initializeDateFormatting('mr');
    for (final lang in ['en', 'mr', 'hi']) {
      final t = await AppLocalizations.delegate.load(Locale(lang));
      final pages = exportRecordPages(
        t: t,
        lang: lang,
        heading: const [('Plot', 'p1')],
        rows: [
          for (var i = 0; i < 20; i++)
            ExportRecordRow(
              sprayedOn: DateTime(2026, 10, i + 1),
              product: 'P$i',
              status: LabelStatus.listed,
            ),
        ],
        made: DateTime(2026, 11, 7),
      );
      expect(pages, hasLength(2));
      expect(pages.last.heading, isNull);
      for (final p in pages) {
        expect(p.footer, t.exportRecordFooter);
      }
      // No compliance claim anywhere in the record's own words.
      final words = [
        t.exportRecordFooter,
        t.exportLabelListed,
        t.exportRecordMade('x'),
      ];
      for (final w in words) {
        expect(w.toLowerCase(), isNot(contains('certified')));
        expect(w.toLowerCase(), isNot(contains('complian')));
      }
    }
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.exportRecordFooter, 'Information record, not a certificate.');
  });

  testWidgets('the printed page shows the footer and every line', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(595, 842)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ExportRecordPage(
        ExportRecordContent(
          title: 'Export record',
          heading: [('Plot', 'p1')],
          columns: ('Date', 'Product', 'Label', 'PHI'),
          lines: [
            (
              date: '2 Nov 2026',
              product: 'Imida',
              label: 'Check the label',
              status: LabelStatus.check,
              phiEnd: '17 Nov 2026',
            ),
          ],
          made: 'Made on 7 Nov 2026',
          footer: 'Information record, not a certificate.',
          pageLabel: '1 / 1',
        ),
      ),
    );
    expect(find.text('Information record, not a certificate.'), findsOneWidget);
    expect(find.text('17 Nov 2026'), findsOneWidget);
    expect(find.text('Plot: p1'), findsOneWidget);
  });
}
