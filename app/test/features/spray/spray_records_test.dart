import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/accounts/domain/accounts_summary.dart';
import 'package:bagmitra/features/spray/data/restrictions_cache.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';
import '../accounts/accounts_summary_test.dart' show exp;

SprayRecord spray(String id, {int cost = 240000, String? cycle}) => SprayRecord(
  id: id,
  plotId: 'p1',
  baharCycleId: cycle,
  sprayedOn: DateTime(2026, 11, 2),
  productName: 'Imida 17.8 SL',
  activeIngredient: 'imidacloprid',
  dose: '0.3 ml per litre',
  waterLitres: 600,
  areaAcres: 4,
  costPaise: cost,
  operator: 'Ramesh',
  phiDays: 15,
  target: 'psylla',
);

void main() {
  test('payload matches the API contract and round-trips', () {
    final s = spray('s1', cycle: 'b1');
    final p = s.toPayload();
    expect(p['sprayed_on'], '2026-11-02');
    expect(p['cost_paise'], 240000);
    expect(p['phi_days'], 15);
    expect(SprayRecord.fromPayload('s1', p).toPayload(), p);
    final bare = SprayRecord(
      id: 's2',
      plotId: 'p1',
      sprayedOn: DateTime(2026, 11, 3),
      productName: 'Neem oil',
    );
    expect(bare.toPayload()['active_ingredient'], isNull);
    expect(SprayRecord.fromPayload('s2', bare.toPayload()).costPaise, 0);
  });

  test('repository queues spray_record mutations and applies remote', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final repo = SprayRepository(db, clock: TestClock().call);
    await repo.save(spray('s1'));
    final queued = await db.select(db.outboxEntries).get();
    expect(queued.single.entity, 'spray_record');
    expect(jsonDecode(queued.single.payload), spray('s1').toPayload());
    expect((await repo.watchForPlot('p1').first).single.phiDays, 15);

    await repo.applyRemote(
      RemoteChange(
        entity: 'spray_record',
        entityId: 's2',
        data: spray('s2').toPayload(),
        updatedAt: DateTime.utc(2026, 11, 3),
      ),
    );
    expect(await repo.watchForPlot('p1').first, hasLength(2));
    await repo.delete('s1');
    expect((await repo.watchForPlot('p1').first).single.id, 's2');
    expect((await db.select(db.outboxEntries).get()).last.op, 'delete');
    await repo.applyRemote(
      RemoteChange(
        entity: 'spray_record',
        entityId: 's2',
        data: const {},
        updatedAt: DateTime.utc(2026, 11, 4),
        deleted: true,
      ),
    );
    expect(await repo.watchForPlot('p1').first, isEmpty);
  });

  test('spray cost counts in the bahar summary under "spray"', () {
    final s = AccountsSummary.of(
      expenses: [exp('e1', 'labour', 100000, cycle: 'b1')],
      sprays: [
        spray('s1', cycle: 'b1'),
        spray('s2', cost: 10, cycle: 'b2'),
      ],
      incomes: const [],
      areaAcres: 4,
      treeCount: null,
      baharCycleId: 'b1',
    );
    expect(s.expensePaise, 340000);
    expect(s.byCategory, {'labour': 100000, 'spray': 240000});
  });

  test('restrictions cache: refresh stores, load works offline', () async {
    final db = memoryDb();
    addTearDown(db.close);
    var online = true;
    final api = createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => 't',
      httpClient: MockClient((req) async {
        if (!online) throw http.ClientException('offline');
        return http.Response(
          jsonEncode({
            'restrictions': [
              {
                'active_ingredient': 'dicofol',
                'kind': 'banned',
                'crops': <String>[],
                'crop_groups': <String>[],
                'notification': 'S.O. 4294(E)',
                'effective_from': '2023-10-03T00:00:00Z',
              },
            ],
            'synonyms': <Object>[],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final cache = RestrictionsCache(db, api: api);
    expect((await cache.load()).rules, isEmpty); // nothing cached yet
    expect(await cache.refresh(), isTrue);
    online = false;
    expect(await cache.refresh(), isFalse); // failure is quiet, cache kept
    expect((await cache.load()).rules.single.activeIngredient, 'dicofol');
  });
}
