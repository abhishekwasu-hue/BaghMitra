import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../accounts/accounts_screen_test.dart' show seedAccounts;
import '../plots/plots_screen_test.dart' show settle;

void main() {
  testWidgets('sharing the accounts hands a UTF-8 CSV to the share sheet', (
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
    await tester.tap(find.byTooltip('Share spreadsheet'));
    await settle(tester);
    final file = sharer.shared.single;
    expect(file.fileName, 'bagmitra-accounts-p1-2026-10-13.csv');
    expect(file.mimeType, 'text/csv');
    final text = utf8.decode(file.bytes);
    expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]); // UTF-8 byte-order mark
    expect(text, contains('Expenses,40000.00'));
    expect(text, contains('2026-10-10,Expense,Fertiliser,-25000.00'));
    expect(text, contains('Sale'));
    await unmountApp(tester);
  });

  testWidgets('the spreadsheet follows the grower language', (tester) async {
    final sharer = RecordingSharer();
    await pumpApp(
      tester,
      initialLocation: '/plots/p1/accounts',
      seed: seedAccounts,
      sharer: sharer,
    );
    await settle(tester);
    await tester.tap(find.byTooltip('स्प्रेडशीट शेअर करा'));
    await settle(tester);
    final text = utf8.decode(sharer.shared.single.bytes);
    expect(text, contains('तारीख,प्रकार,तपशील'));
    expect(text, contains('खर्च'));
    // Money stays plain digits so a spreadsheet can add it up.
    expect(text, contains('-25000.00'));
    await unmountApp(tester);
  });
}
