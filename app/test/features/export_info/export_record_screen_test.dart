import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/export_info/presentation/export_record_screen.dart';
import 'package:bagmitra/features/labels/data/label_claims_cache.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../labels/label_info_test.dart' show sampleClaims;
import '../plots/plots_screen_test.dart' show settle;
import '../spray/spray_records_test.dart' show SprayTestCopy, spray;
import '../spray/spray_screen_test.dart' show seedPlotAndBanList;
import 'export_info_test.dart' show exportInfoAsset, linkOn;
import 'export_record_test.dart' show mancozebSpray;

/// A santra plot with the ban list, an Ambia bahar, three sprays and saved label rows.
Future<void> seedRecord(AppDatabase db) async {
  await seedPlotAndBanList(db);
  final repo = SprayRepository(db);
  await repo.save(spray('s1', cycle: 'b1'));
  await repo.save(spray('s2').copyWithActive('Kelthane'));
  await repo.save(mancozebSpray('s3', DateTime(2026, 10, 20)));
  await db.writeMeta(
    LabelClaimsCache.keyFor('santra'),
    jsonEncode({
      'saved_at': '2026-10-26T06:00:00.000Z',
      'response': sampleClaims(),
    }),
  );
}

void main() {
  group('export record screen', () {
    Future<RecordingSharer> pump(WidgetTester tester) async {
      final sharer = RecordingSharer();
      await pumpApp(
        tester,
        locale: const Locale('en'),
        config: linkOn,
        initialLocation: '/market/export',
        seed: seedRecord,
        sharer: sharer,
        overrides: [exportInfoAsset],
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('export-record-open')));
      await settle(tester);
      return sharer;
    }

    testWidgets('opens from the export page; counts follow the bahar', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(ExportRecordScreen), findsOneWidget);
      expect(find.text('3 sprays'), findsOneWidget);
      expect(find.text('1 · On the label for this crop'), findsOneWidget);
      expect(find.text('1 · Banned chemical'), findsOneWidget);
      await tester.tap(find.byKey(const Key('record-bahar-b1')));
      await settle(tester);
      expect(find.text('2 sprays'), findsOneWidget);
      expect(find.textContaining('Last PHI ends'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('shares one PDF of the chosen plot', (tester) async {
      final sharer = await pump(tester);
      await tester.tap(find.byKey(const Key('record-share')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await settle(tester);
      final file = sharer.shared.single;
      expect(file.fileName, 'bagmitra-export-record-p1-2026-10-13.pdf');
      expect(file.mimeType, 'application/pdf');
      expect(ascii.decode(file.bytes.take(5).toList()), '%PDF-');
      await unmountApp(tester);
    });

    testWidgets('with no plot it says to add one', (tester) async {
      await pumpApp(
        tester,
        config: linkOn,
        initialLocation: '/market/export/record',
      );
      await settle(tester);
      expect(find.byType(ExportRecordScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('not reachable with the flag off', (tester) async {
      await pumpApp(tester, initialLocation: '/market/export/record');
      await settle(tester);
      expect(find.byType(ExportRecordScreen), findsNothing);
      await unmountApp(tester);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('fits a 360 dp phone at x$scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          config: linkOn,
          initialLocation: '/market/export/record',
          seed: seedRecord,
          size: const Size(360, 800),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        await unmountApp(tester);
      });
    }
  });
}
