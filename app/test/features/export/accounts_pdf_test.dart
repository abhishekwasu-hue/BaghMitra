import 'dart:convert';
import 'dart:typed_data';

import 'package:bagmitra/features/export/data/pdf_builder.dart';
import 'package:bagmitra/features/export/domain/accounts_csv.dart';
import 'package:bagmitra/features/export/domain/report_pages.dart';
import 'package:bagmitra/features/export/presentation/report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../accounts/accounts_screen_test.dart' show seedAccounts;
import '../plots/plots_screen_test.dart' show settle;

LedgerLine line(int i) => (
  date: DateTime(2026, 11, i + 1),
  type: 'Expense',
  details: 'item $i',
  paise: -100 * i,
);

const pngSignature = [0x89, 0x50, 0x4E, 0x47];

void main() {
  test(
    'rows are split over pages, fewer on the first (it holds the summary)',
    () {
      final lines = [for (var i = 0; i < 25; i++) line(i)];
      final pages = paginateLedger(lines, firstPageRows: 8, otherPageRows: 12);
      expect(pages.map((p) => p.length), [8, 12, 5]);
      expect(pages.expand((p) => p), lines); // nothing lost, order kept
    },
  );

  test('an empty ledger still gives one page (the summary)', () {
    expect(paginateLedger(const [], firstPageRows: 8, otherPageRows: 12), [
      isEmpty,
    ]);
  });

  test('a short ledger fits on the first page', () {
    final pages = paginateLedger(
      [for (var i = 0; i < 3; i++) line(i)],
      firstPageRows: 8,
      otherPageRows: 12,
    );
    expect(pages, hasLength(1));
  });

  testWidgets('a widget is rendered to a PNG of the requested size', (
    tester,
  ) async {
    final png = await tester.runAsync(
      () => renderWidgetToPng(
        const ColoredBox(color: Colors.white, child: SizedBox.expand()),
        view: tester.view,
        size: const Size(100, 200),
      ),
    );
    expect(png!.take(4), pngSignature);
    final image = await tester.runAsync(() => decodeImageFromList(png));
    expect(image!.width, 200);
    expect(image.height, 400);
  });

  testWidgets('PNG pages become the pages of one PDF', (tester) async {
    final pdf = await tester.runAsync(() async {
      Future<Uint8List> page() => renderWidgetToPng(
        const ColoredBox(color: Colors.white, child: SizedBox.expand()),
        view: tester.view,
        size: const Size(595, 842),
        pixelRatio: 1,
      );
      return pdfFromPngPages([await page(), await page()]);
    });
    expect(ascii.decode(pdf!.take(5).toList()), '%PDF-');
    expect(latin1.decode(pdf), contains('/Count 2'));
  });

  testWidgets('sharing the PDF hands one PDF to the share sheet', (
    tester,
  ) async {
    final sharer = RecordingSharer();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts',
      seed: seedAccounts,
      sharer: sharer,
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Share PDF'));
    // Rendering the page is real async work, so let it finish.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await settle(tester);
    final file = sharer.shared.single;
    expect(file.fileName, 'bagmitra-accounts-p1-2026-10-13.pdf');
    expect(file.mimeType, 'application/pdf');
    expect(ascii.decode(file.bytes.take(5).toList()), '%PDF-');
    await unmountApp(tester);
  });
}
