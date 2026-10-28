// Soil / water / leaf test log screens. Regenerate with:
//   flutter test --update-goldens test/goldens/lab_tests_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/lab_tests/data/lab_test_repository.dart';
import 'package:bagmitra/features/lab_tests/domain/lab_test.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/features/tasks/domain/farm_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/lab_tests/lab_tests_test.dart'
    show FakeReportFiles, fakeFiles, labTest, seedLabTest;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

/// A soil test with a PDF report (shown as a file icon) and its reminder.
Future<void> _seedForm(AppDatabase db) async {
  await seedPlot(db);
  await LabTestRepository(db)
      .save(labTest('l1', report: '/docs/lab_reports/l1.pdf'));
  await TasksRepository(db).save(
    FarmTask(
      id: 't1',
      title: 'Next soil test due',
      kind: 'other',
      dueOn: DateTime(2027, 4),
      plotId: 'p1',
      source: labTestReminderSource('l1'),
    ),
  );
}

void main() {
  for (final (name, location, seed) in [
    ('lab_tests_mr_light', '/plots/p1/lab-tests', seedLabTest),
    ('lab_tests_empty_mr_light', '/plots/p1/lab-tests', seedPlot),
    ('lab_test_detail_mr_light', '/plots/p1/lab-tests/l1', seedLabTest),
    ('lab_test_form_mr_light', '/plots/p1/lab-tests/new', seedPlot),
    ('lab_test_edit_mr_light', '/plots/p1/lab-tests/l1/edit', _seedForm),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(
        tester,
        initialLocation: location,
        seed: seed,
        overrides: fakeFiles(FakeReportFiles()),
      );
      await settle(tester);
      if (name == 'lab_test_form_mr_light') {
        await tester.tap(find.byKey(const Key('lab-type-soil')));
        await settle(tester);
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
