// One printed page of the export record PDF (market linkage L8), Marathi. Regenerate with:
//   flutter test --update-goldens test/goldens/export_record_page_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/features/export/presentation/report_page.dart';
import 'package:bagmitra/features/export_info/domain/export_record.dart';
import 'package:bagmitra/features/export_info/presentation/export_record_page.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('export_record_page_mr', (tester) async {
    await initializeDateFormatting('mr');
    final t = await AppLocalizations.delegate.load(const Locale('mr'));
    tester.view
      ..physicalSize = reportPageSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pages = exportRecordPages(
      t: t,
      lang: 'mr',
      heading: [
        (t.exportRecordPlot, 'बाग १ · संत्रा'),
        (t.exportRecordBahar, 'आंबिया बहार २०२६'),
      ],
      rows: [
        ExportRecordRow(
          sprayedOn: DateTime(2026, 10, 20),
          product: 'Dithane M-45',
          activeIngredient: 'Mancozeb',
          dose: '2 g/L',
          status: LabelStatus.listed,
          phiEnd: DateTime(2026, 10, 27),
        ),
        ExportRecordRow(
          sprayedOn: DateTime(2026, 11, 2),
          product: 'Imida 17.8 SL',
          activeIngredient: 'imidacloprid',
          dose: '0.3 ml/L',
          status: LabelStatus.check,
          phiEnd: DateTime(2026, 11, 17),
        ),
        ExportRecordRow(
          sprayedOn: DateTime(2026, 11, 2),
          product: 'Old product',
          activeIngredient: 'Kelthane',
          status: LabelStatus.banned,
        ),
      ],
      made: DateTime(2026, 11, 7),
    );
    await tester.pumpWidget(ExportRecordPage(pages.single));
    await expectLater(
      find.byType(ExportRecordPage),
      matchesGoldenFile('export_record_page_mr.png'),
    );
  });
}
