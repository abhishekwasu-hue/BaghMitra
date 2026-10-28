import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/lab_tests/data/lab_parameters.dart';
import 'package:bagmitra/features/lab_tests/data/lab_report_files.dart';
import 'package:bagmitra/features/lab_tests/data/lab_test_repository.dart';
import 'package:bagmitra/features/lab_tests/domain/lab_test.dart';
import 'package:bagmitra/features/lab_tests/presentation/lab_test_screens.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/features/tasks/domain/farm_task.dart';
import 'package:bagmitra/l10n/app_localizations_en.dart';
import 'package:bagmitra/sync/account_guard.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import '../scouting/scouting_test.dart' show FakePhotos;

LabTest labTest(
  String id, {
  String type = 'soil',
  DateTime? sampled,
  String? report,
  List<LabReading> readings = const [
    LabReading(parameter: 'pH', value: '7.9'),
    LabReading(parameter: 'EC', value: '0.42', unit: 'dS/m'),
    LabReading(parameter: 'सेंद्रिय कर्ब', value: '<0.5', unit: '%'),
  ],
}) => LabTest(
  id: id,
  plotId: 'p1',
  testType: type,
  sampledOn: sampled ?? DateTime(2026, 10),
  labName: 'District soil testing lab',
  reportedOn: DateTime(2026, 10, 9),
  readings: readings,
  note: 'मृदा आरोग्य पत्रिका',
  reportPath: report,
);

Future<void> seedLabTest(AppDatabase db) async {
  await seedPlot(db);
  await LabTestRepository(db).save(labTest('l1'));
  await LabTestRepository(db).save(
    labTest(
      'l2',
      type: 'water',
      sampled: DateTime(2026, 4, 2),
      readings: const [],
    ),
  );
}

/// A plot with one soil test (photo report) and its open "next test due" task.
Future<void> seedWithReminder(AppDatabase db) async {
  await seedPlot(db);
  await LabTestRepository(db)
      .save(labTest('l1', report: '/docs/lab_reports/l1.jpg'));
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

class FakeReportPicker implements ReportFilePicker {
  FakeReportPicker([this.path = '/tmp/report.pdf']);

  final String? path;
  int calls = 0;

  @override
  Future<String?> pick() async {
    calls++;
    return path;
  }
}

/// Keeps reports under `/docs/lab_reports/`, like the real folder, without file IO.
class FakeReportFiles extends FakePhotos {
  FakeReportFiles({super.picked = '/tmp/report.jpg'});

  @override
  Future<String> keep(String pickedPath, String recordId) async {
    final ext = pickedPath.substring(pickedPath.lastIndexOf('.'));
    final path = '/docs/$labReportFolder/$recordId$ext';
    kept[pickedPath] = path;
    return path;
  }
}

List<Override> fakeFiles(FakeReportFiles files, [FakeReportPicker? picker]) => [
  labReportFilesProvider.overrideWithValue(files),
  reportFilePickerProvider.overrideWithValue(picker ?? FakeReportPicker()),
];

Future<List<OutboxEntry>> outbox(AppDatabase db) => (db.select(
  db.outboxEntries,
)..where((t) => t.entity.equals(LabTestRepository.entity))).get();

void main() {
  test('the lab test payload matches the API contract', () {
    final p = labTest('l1', report: '/docs/lab_reports/l1.jpg').toPayload();
    expect(p, {
      'plot_id': 'p1',
      'test_type': 'soil',
      'sampled_on': '2026-10-01',
      'lab_name': 'District soil testing lab',
      'reported_on': '2026-10-09',
      'readings': [
        {'parameter': 'pH', 'value': '7.9', 'unit': null},
        {'parameter': 'EC', 'value': '0.42', 'unit': 'dS/m'},
        {'parameter': 'सेंद्रिय कर्ब', 'value': '<0.5', 'unit': '%'},
      ],
      'note': 'मृदा आरोग्य पत्रिका',
    });
    expect(p.containsKey('report_path'), isFalse, reason: 'phone only');
    expect(LabTest.fromPayload('l1', p).toPayload(), p);
    expect(isImagePath('/a/B.JPG'), isTrue);
    expect(isImagePath('/a/b.pdf'), isFalse);
    expect(isImagePath(null), isFalse);
  });

  test('tests are queued for sync; server upserts keep the report', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final files = FakeReportFiles();
    final repo = LabTestRepository(db, clock: TestClock().call, files: files);
    await repo.save(labTest('l1', report: '/docs/lab_reports/l1.jpg'));
    await repo.save(labTest('l2', sampled: DateTime(2026, 11, 2)));
    expect(
      [for (final t in await repo.watchForPlot('p1').first) t.id],
      ['l2', 'l1'],
    );
    final queued = await outbox(db);
    expect(queued, hasLength(2));
    expect(jsonDecode(queued.first.payload), labTest('l1').toPayload());

    await repo.applyRemote(
      RemoteChange(
        entity: LabTestRepository.entity,
        entityId: 'l1',
        data: labTest('l1', type: 'leaf').toPayload(),
        updatedAt: DateTime.utc(2026, 10, 12),
      ),
    );
    final l1 = (await repo.find('l1'))!;
    expect(l1.testType, 'leaf');
    expect(l1.reportPath, '/docs/lab_reports/l1.jpg');
    expect(l1.readings[2].valueWithUnit, '<0.5 %');

    // Replacing the report drops the old file; a server delete drops the record's file.
    await repo.save(l1.withReportPath('/docs/lab_reports/l1.pdf'));
    expect(files.discarded, ['/docs/lab_reports/l1.jpg']);
    await repo.applyRemote(
      RemoteChange(
        entity: LabTestRepository.entity,
        entityId: 'l1',
        data: const {},
        updatedAt: DateTime.utc(2026, 10, 13),
        deleted: true,
      ),
    );
    expect(await repo.find('l1'), isNull);
    expect(files.discarded.last, '/docs/lab_reports/l1.pdf');
    await repo.delete('l2');
    final last = (await outbox(db)).last;
    expect((last.op, last.entityId), ('delete', 'l2'));
  });

  test('parameter suggestions are names and units only', () async {
    final raw = jsonDecode(
      File(LabParameters.asset).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(raw['status'], 'draft');
    final types = raw['types'] as Map<String, dynamic>;
    expect(types.keys.toSet(), labTestTypes.toSet());
    for (final list in types.values) {
      for (final p in (list as List).cast<Map<String, dynamic>>()) {
        expect(
          p.keys.toSet().difference({'key', 'labels', 'unit'}),
          isEmpty,
          reason: 'no value, range or rating in ${p['key']}',
        );
        expect((p['labels'] as Map).keys.toSet(), {'en', 'mr', 'hi'});
      }
    }
    final loaded = await LabParameters(bundle: FileAssetBundle()).load();
    final soil = {for (final p in loaded['soil']!) p.key};
    expect(soil, containsAll(['ph', 'ec', 'oc', 'n', 'p', 'k']));
    expect(loaded['water']!.first.label('mr'), 'सामू (pH)');
  });

  test('report photos and files are kept in their own folder', () async {
    expect(AccountGuard.photoFolders, contains(labReportFolder));
    expect(const [
      'pdf',
      'jpg',
      'jpeg',
      'png',
    ], containsAll(labReportExtensions));
  });

  test('the share text says what was typed and to ask an expert', () async {
    await initializeDateFormatting('en');
    final t = AppLocalizationsEn();
    final text = labTestShareText(t, labTest('l1'), 'en', 'BagMitra');
    expect(text, contains('Soil test · Sample 1 Oct 2026'));
    expect(text, contains('EC: 0.42 dS/m'));
    expect(text, contains('Lab: District soil testing lab'));
    expect(text, contains(t.labTestAskExpert));
    expect(text.toLowerCase(), isNot(contains('low')));
    expect(labTestReminderTitle(t, 'leaf'), 'Next leaf test due');
    expect(labTestTypeLabel(t, 'water'), 'Water');
  });

  testWidgets('a plot without tests shows the empty state', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests',
      seed: seedPlot,
      overrides: fakeFiles(FakeReportFiles()),
    );
    await settle(tester);
    expect(find.textContaining('first test from your lab report'), findsOne);
    await unmountApp(tester);
  });

  testWidgets('the list shows tests newest first; detail shows typed values', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests',
      seed: seedLabTest,
      overrides: fakeFiles(FakeReportFiles()),
    );
    await settle(tester);
    expect(find.text('Sample 1 Oct 2026 · 3 values'), findsOne);
    expect(find.text('Sample 2 Apr 2026 · Add values'), findsOne);
    await tester.tap(find.byKey(const Key('lab-test-l1')));
    await settle(tester);
    expect(find.byKey(const Key('lab-ask-expert')), findsOne);
    expect(find.text('<0.5 %'), findsOne);
    expect(find.text('0.42 dS/m'), findsOne);
    expect(find.text('7.9'), findsOne);
    expect(find.byKey(const Key('lab-test-share')), findsOne);
    await unmountApp(tester);
  });

  testWidgets('grower records a test from suggestions, report and reminder', (
    tester,
  ) async {
    final files = FakeReportFiles();
    final picker = FakeReportPicker();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests',
      seed: seedPlot,
      overrides: fakeFiles(files, picker),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('add-lab-test')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('save-lab-test')));
    await settle(tester);
    expect(find.text('Choose one'), findsOne);

    await tester.tap(find.byKey(const Key('lab-type-soil')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('lab-suggest-ph')));
    await tester.tap(find.byKey(const Key('lab-suggest-ph')));
    await settle(tester);
    expect(find.byKey(const Key('lab-suggest-ph')), findsNothing);
    await tester.enterText(find.byKey(const Key('lab-value-0')), '8.1');
    await tester.ensureVisible(find.byKey(const Key('lab-suggest-ec')));
    await tester.tap(find.byKey(const Key('lab-suggest-ec')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('lab-value-1')), '0.3');
    // A half-typed row is refused, a blank row is dropped.
    await tester.ensureVisible(find.byKey(const Key('lab-add-reading')));
    await tester.tap(find.byKey(const Key('lab-add-reading')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('lab-param-2')), 'Zn');
    await tester.tap(find.byKey(const Key('save-lab-test')));
    await settle(tester);
    expect(find.text('Type the name and the value'), findsOne);
    await tester.enterText(find.byKey(const Key('lab-param-2')), '');
    await tester.ensureVisible(find.byKey(const Key('lab-add-reading')));
    await tester.tap(find.byKey(const Key('lab-add-reading')));
    await settle(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('lab-report-file')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('lab-report-file')));
    await settle(tester);
    expect(picker.calls, 1);
    expect(find.text('report.pdf'), findsOne);

    await tester.scrollUntilVisible(
      find.byKey(const Key('lab-next-due')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('lab-next-due')));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('save-lab-test')));
    await settle(tester);

    final saved = await tester.runAsync(
      () => LabTestRepository(db).watchForPlot('p1').first,
    );
    final test = saved!.single;
    expect(test.testType, 'soil');
    expect(test.sampledOn, DateTime(2026, 10, 13));
    expect(test.labName, isNull);
    expect(
      [for (final r in test.readings) r.valueWithUnit],
      ['8.1', '0.3 dS/m'],
    );
    expect(test.readings.first.parameter, 'pH');
    expect(test.reportPath, '/docs/lab_reports/${test.id}.pdf');
    final reminder = await tester.runAsync(
      () => TasksRepository(db).findBySource(labTestReminderSource(test.id)),
    );
    expect(reminder!.title, 'Next soil test due');
    expect(reminder.plotId, 'p1');
    expect(reminder.dueOn, DateTime(2026, 10, 13));
    expect(find.byKey(Key('lab-test-${test.id}')), findsOne);
    await unmountApp(tester);
  });

  testWidgets('no reminder task unless a date is picked', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests/new',
      seed: seedPlot,
      overrides: fakeFiles(FakeReportFiles()),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('lab-type-leaf')));
    await tester.tap(find.byKey(const Key('save-lab-test')));
    await settle(tester);
    expect(
      (await tester.runAsync(
        () => LabTestRepository(db).watchForPlot('p1').first,
      ))!.single.testType,
      'leaf',
    );
    expect(
      await tester.runAsync(() => TasksRepository(db).watchAll().first),
      isEmpty,
    );
    await unmountApp(tester);
  });

  testWidgets('editing shows the reminder; clearing the date removes it', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests/l1/edit',
      seed: seedWithReminder,
      overrides: fakeFiles(FakeReportFiles()),
    );
    await settle(tester);
    expect(find.text('District soil testing lab'), findsOne);
    expect(find.text('<0.5'), findsOne);
    await tester.scrollUntilVisible(
      find.byKey(const Key('lab-next-due-clear')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 Apr 2027'), findsOne);
    await tester.tap(find.byKey(const Key('lab-next-due-clear')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('save-lab-test')));
    await settle(tester);
    expect(
      await tester.runAsync(() => TasksRepository(db).watchAll().first),
      isEmpty,
    );
    await unmountApp(tester);
  });

  testWidgets('a photo report is kept', (tester) async {
    final files = FakeReportFiles();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests/new',
      seed: seedPlot,
      overrides: fakeFiles(files),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('lab-type-water')));
    await tester.enterText(find.byKey(const Key('lab-name')), 'KVK lab');
    await tester.scrollUntilVisible(
      find.byKey(const Key('lab-report-gallery')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('lab-report-gallery')));
    await settle(tester);
    expect(find.byKey(const Key('lab-remove-report')), findsOne);
    await tester.tap(find.byKey(const Key('save-lab-test')));
    await settle(tester);
    final test = (await tester.runAsync(
      () => LabTestRepository(db).watchForPlot('p1').first,
    ))!.single;
    expect(test.reportPath, '/docs/lab_reports/${test.id}.jpg');
    expect(test.labName, 'KVK lab');
    await unmountApp(tester);
  });

  testWidgets('deleting a test drops its file and its open reminder', (
    tester,
  ) async {
    final files = FakeReportFiles();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests/l1/edit',
      seed: seedWithReminder,
      overrides: fakeFiles(files),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('delete-lab-test')));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.textContaining('first test from your lab report'), findsOne);
    expect(
      await tester.runAsync(() => TasksRepository(db).watchAll().first),
      isEmpty,
    );
    expect(files.discarded, ['/docs/lab_reports/l1.jpg']);
    await unmountApp(tester);
  });

  testWidgets('the kept report can be shared from the detail view', (
    tester,
  ) async {
    final sharer = RecordingSharer();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests/l1',
      sharer: sharer,
      seed: (db) async {
        await seedPlot(db);
        await LabTestRepository(db)
            .save(labTest('l1', report: '/docs/lab_reports/l1.pdf'));
      },
      overrides: [
        ...fakeFiles(FakeReportFiles()),
        claimPhotoBytesProvider.overrideWithValue(
          (path) async => path.endsWith('l1.pdf') ? Uint8List(3) : null,
        ),
      ],
    );
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('lab-share-report')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('lab-share-report')));
    await settle(tester);
    expect(sharer.shared.single.fileName, 'l1.pdf');
    expect(sharer.shared.single.mimeType, 'application/pdf');
    await unmountApp(tester);
  });

  testWidgets('the plot screen opens the lab test log', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: seedPlot,
      overrides: fakeFiles(FakeReportFiles()),
    );
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-lab-tests')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('open-lab-tests')));
    await settle(tester);
    expect(find.text('Soil, water and leaf tests'), findsWidgets);
    await unmountApp(tester);
  });
}
