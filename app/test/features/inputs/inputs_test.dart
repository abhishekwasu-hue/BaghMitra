import 'dart:convert';

import 'package:bagmitra/features/accounts/domain/accounts_summary.dart';
import 'package:bagmitra/features/inputs/data/input_kinds.dart';
import 'package:bagmitra/features/inputs/data/inputs_repository.dart';
import 'package:bagmitra/features/inputs/domain/field_records.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../accounts/accounts_summary_test.dart' show exp;

InputRecord urea(String id, {int cost = 133000, String? cycle}) => InputRecord(
  id: id,
  plotId: 'p1',
  baharCycleId: cycle,
  appliedOn: DateTime(2026, 11, 5),
  kind: 'fertiliser',
  productName: 'Urea',
  quantity: 50,
  unit: 'kg',
  costPaise: cost,
  note: 'after rain',
);

IrrigationRecord water(String id) => IrrigationRecord(
  id: id,
  plotId: 'p1',
  irrigatedOn: DateTime(2026, 11, 6),
  durationHours: 3.5,
  waterLitres: 40000,
);

void main() {
  test('payloads match the API contract and round-trip', () {
    final i = urea('i1', cycle: 'b1');
    final p = i.toPayload();
    expect(p['applied_on'], '2026-11-05');
    expect(p['kind'], 'fertiliser');
    expect(p['cost_paise'], 133000);
    expect(InputRecord.fromPayload('i1', p).toPayload(), p);
    final bare = InputRecord(
      id: 'i2',
      plotId: 'p1',
      appliedOn: DateTime(2026, 11, 7),
      kind: 'manure',
      productName: 'FYM',
    );
    expect(InputRecord.fromPayload('i2', bare.toPayload()).costPaise, 0);

    final w = water('w1');
    expect(w.toPayload()['irrigated_on'], '2026-11-06');
    expect(w.toPayload()['duration_hours'], 3.5);
    expect(
      IrrigationRecord.fromPayload('w1', w.toPayload()).toPayload(),
      w.toPayload(),
    );
  });

  test(
    'repositories queue mutations atomically and apply remote changes',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = InputsRepository(db, clock: TestClock().call);
      await repo.saveInput(urea('i1'));
      await repo.saveIrrigation(water('w1'));
      final queued = await db.select(db.outboxEntries).get();
      expect(queued.map((q) => q.entity), [
        'input_record',
        'irrigation_record',
      ]);
      expect(jsonDecode(queued.first.payload), urea('i1').toPayload());
      expect((await repo.watchInputs('p1').first).single.productName, 'Urea');
      expect(
        (await repo.watchIrrigations('p1').first).single.durationHours,
        3.5,
      );

      await repo.applyRemoteInput(
        RemoteChange(
          entity: 'input_record',
          entityId: 'i2',
          data: urea('i2').toPayload(),
          updatedAt: DateTime.utc(2026, 11, 8),
        ),
      );
      expect(await repo.watchInputs('p1').first, hasLength(2));
      await repo.deleteInput('i1');
      await repo.deleteIrrigation('w1');
      expect((await repo.watchInputs('p1').first).single.id, 'i2');
      expect(await repo.watchIrrigations('p1').first, isEmpty);
      final last = (await db.select(db.outboxEntries).get()).last;
      expect(last.entity, 'irrigation_record');
      expect(last.op, 'delete');
      await repo.applyRemoteIrrigation(
        RemoteChange(
          entity: 'irrigation_record',
          entityId: 'w9',
          data: water('w9').toPayload(),
          updatedAt: DateTime.utc(2026, 11, 9),
        ),
      );
      await repo.applyRemoteIrrigation(
        RemoteChange(
          entity: 'irrigation_record',
          entityId: 'w9',
          data: const {},
          updatedAt: DateTime.utc(2026, 11, 10),
          deleted: true,
        ),
      );
      expect(await repo.watchIrrigations('p1').first, isEmpty);
    },
  );

  test('input costs count under their kind in the bahar summary', () {
    final s = AccountsSummary.of(
      expenses: [exp('e1', 'labour', 100000, cycle: 'b1')],
      inputs: [
        urea('i1', cycle: 'b1'),
        urea('i2', cost: 5, cycle: 'b2'),
        urea('i3', cost: 0, cycle: 'b1'),
      ],
      incomes: const [],
      areaAcres: 4,
      treeCount: null,
      baharCycleId: 'b1',
    );
    expect(s.byCategory, {'labour': 100000, 'fertiliser': 133000});
    expect(s.expensePaise, 233000);
  });

  test('kinds and units come from config with labels', () async {
    final cfg = await InputKinds(bundle: FileAssetBundle()).load();
    expect(cfg.kinds.map((k) => k.slug), containsAll(['fertiliser', 'manure']));
    expect(cfg.units.map((u) => u.slug), contains('kg'));
    expect(cfg.kinds.first.label('mr'), isNotEmpty);
  });
}
