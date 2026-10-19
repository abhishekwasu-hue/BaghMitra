import 'dart:convert';

import 'package:bagmitra/features/accounts/domain/accounts_summary.dart';
import 'package:bagmitra/features/field_work/data/field_work_options.dart';
import 'package:bagmitra/features/field_work/data/field_work_repository.dart';
import 'package:bagmitra/features/field_work/domain/field_work.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../accounts/accounts_summary_test.dart' show exp;

HarvestRecord lot(String id, {String? grade = 'grade_a', double kg = 1250.5}) =>
    HarvestRecord(
      id: id,
      plotId: 'p1',
      harvestedOn: DateTime(2027, 1, 20),
      grade: grade,
      sizeClass: 'large',
      quantityKg: kg,
    );

LabourRecord day(
  String id, {
  int wage = 40000,
  int advance = 10000,
  DateTime? settledOn,
  String? cycle,
}) => LabourRecord(
  id: id,
  plotId: 'p1',
  baharCycleId: cycle,
  workerName: 'Sunita',
  workedOn: DateTime(2026, 11, 5),
  task: 'weeding',
  wagePaise: wage,
  advancePaise: advance,
  settledOn: settledOn,
);

void main() {
  test('payloads match the API contract and round-trip', () {
    final h = lot('h1');
    expect(h.toPayload()['harvested_on'], '2027-01-20');
    expect(h.toPayload()['quantity_kg'], 1250.5);
    expect(
      HarvestRecord.fromPayload('h1', h.toPayload()).toPayload(),
      h.toPayload(),
    );

    final l = day('l1', settledOn: DateTime(2026, 11, 30));
    expect(l.toPayload()['worked_on'], '2026-11-05');
    expect(l.toPayload()['settled_on'], '2026-11-30');
    expect(l.toPayload()['wage_paise'], 40000);
    expect(
      LabourRecord.fromPayload('l1', l.toPayload()).toPayload(),
      l.toPayload(),
    );
    expect(day('l2').toPayload()['settled_on'], isNull);
  });

  test('a labour day knows what is still due', () {
    expect(day('l1').duePaise, 30000);
    expect(
      day('l2', advance: 50000).duePaise,
      0,
    ); // advance above wage: nothing due
    expect(day('l3', settledOn: DateTime(2026, 11, 30)).duePaise, 0);
    expect(day('l4').settled, isFalse);
    expect(day('l5', settledOn: DateTime(2026, 11, 30)).settled, isTrue);
  });

  test(
    'repository queues mutations atomically and applies remote changes',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = FieldWorkRepository(db, clock: TestClock().call);
      await repo.saveHarvest(lot('h1'));
      await repo.saveLabour(day('l1'));
      final queued = await db.select(db.outboxEntries).get();
      expect(queued.map((q) => q.entity), ['harvest_record', 'labour_record']);
      expect(jsonDecode(queued.last.payload), day('l1').toPayload());
      expect((await repo.watchHarvests('p1').first).single.quantityKg, 1250.5);
      expect((await repo.watchLabour('p1').first).single.workerName, 'Sunita');

      await repo.applyRemoteHarvest(
        RemoteChange(
          entity: 'harvest_record',
          entityId: 'h2',
          data: lot('h2', grade: null).toPayload(),
          updatedAt: DateTime.utc(2027, 1, 21),
        ),
      );
      expect(await repo.watchHarvests('p1').first, hasLength(2));
      await repo.applyRemoteLabour(
        RemoteChange(
          entity: 'labour_record',
          entityId: 'l2',
          data: day('l2').toPayload(),
          updatedAt: DateTime.utc(2026, 11, 6),
        ),
      );
      expect(await repo.watchLabour('p1').first, hasLength(2));

      await repo.deleteHarvest('h1');
      await repo.deleteLabour('l1');
      expect((await repo.watchHarvests('p1').first).single.id, 'h2');
      expect((await repo.watchLabour('p1').first).single.id, 'l2');
      expect((await db.select(db.outboxEntries).get()).last.op, 'delete');
      await repo.applyRemoteLabour(
        RemoteChange(
          entity: 'labour_record',
          entityId: 'l2',
          data: const {},
          updatedAt: DateTime.utc(2026, 11, 7),
          deleted: true,
        ),
      );
      await repo.applyRemoteHarvest(
        RemoteChange(
          entity: 'harvest_record',
          entityId: 'h2',
          data: const {},
          updatedAt: DateTime.utc(2027, 1, 22),
          deleted: true,
        ),
      );
      expect(await repo.watchLabour('p1').first, isEmpty);
      expect(await repo.watchHarvests('p1').first, isEmpty);
    },
  );

  test('wages count under labour in the bahar summary', () {
    final s = AccountsSummary.of(
      expenses: [exp('e1', 'transport', 5000, cycle: 'b1')],
      labour: [
        day('l1', cycle: 'b1'),
        day('l2', wage: 7, cycle: 'b2'),
        day('l3', wage: 0, cycle: 'b1'),
      ],
      incomes: const [],
      areaAcres: 4,
      treeCount: null,
      baharCycleId: 'b1',
    );
    expect(s.byCategory, {'transport': 5000, 'labour': 40000});
    expect(s.expensePaise, 45000);
  });

  test('grades, size classes and tasks come from config with labels', () async {
    final cfg = await FieldWorkOptions(bundle: FileAssetBundle()).load();
    expect(cfg.grades.map((g) => g.slug), contains('grade_a'));
    expect(cfg.sizeClasses.map((g) => g.slug), contains('large'));
    expect(cfg.tasks.map((g) => g.slug), contains('weeding'));
    expect(cfg.tasks.first.label('mr'), isNotEmpty);
    expect(cfg.tasks.first.label('hi'), isNotEmpty);
  });
}
