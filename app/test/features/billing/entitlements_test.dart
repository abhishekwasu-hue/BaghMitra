import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/billing/data/entitlements_cache.dart';
import 'package:bagmitra/features/billing/domain/entitlements.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';

const rules = EntitlementRules(
  always: {'records', 'accounts', 'export'},
  graceHours: 72,
);

EntitlementSnapshot snapshot({DateTime? validUntil}) => EntitlementSnapshot(
  features: const {'records': null, 'calendar': null, 'ai': 300, 'photos': 20},
  plans: const ['free', 'grower_pro'],
  computedAt: DateTime.utc(2026, 11),
  validUntil: validUntil ?? DateTime.utc(2026, 11, 2),
);

void main() {
  final now = DateTime.utc(2026, 11, 1, 12);

  test('a fresh snapshot allows its features and reports limits', () {
    final e = Entitlements(snapshot(), rules, now);
    expect(e.has('calendar'), isTrue);
    expect(e.has('roster'), isFalse);
    expect(e.limitOf('ai'), 300);
    expect(e.limitOf('calendar'), isNull);
    expect(e.isAtLimit('ai', 299), isFalse);
    expect(e.isAtLimit('ai', 300), isTrue);
    expect(e.isAtLimit('calendar', 99999), isFalse);
  });

  test('past valid_until the offline grace margin still honours it', () {
    final snap = snapshot(validUntil: DateTime.utc(2026, 11));
    expect(
      Entitlements(snap, rules, DateTime.utc(2026, 11, 3, 23)).has('calendar'),
      isTrue,
    );
    expect(
      Entitlements(snap, rules, DateTime.utc(2026, 11, 4, 1)).has('calendar'),
      isFalse,
    );
  });

  test('records, accounts and export are never locked', () {
    for (final e in [
      Entitlements(null, rules, now),
      Entitlements(snapshot(validUntil: DateTime.utc(2020)), rules, now),
    ]) {
      expect(e.has('records') && e.has('accounts') && e.has('export'), isTrue);
      expect(e.has('calendar'), isFalse);
      expect(e.limitOf('ai'), isNull);
    }
  });

  test('snapshot survives a JSON round trip', () {
    final back = EntitlementSnapshot.fromJson(
      jsonDecode(jsonEncode(snapshot().toJson())) as Map<String, Object?>,
    );
    expect(back.features, snapshot().features);
    expect(back.plans, snapshot().plans);
    expect(back.validUntil, snapshot().validUntil);
  });

  test('cache: refresh stores the snapshot, load works offline', () async {
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
            'entitlements': {
              'computed_at': '2026-11-01T00:00:00Z',
              'features': {'records': null, 'ai': 300},
              'plans': ['free', 'grower_pro'],
              'valid_until': '2026-11-02T00:00:00Z',
            },
            'signature': 'sig',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final cache = EntitlementsCache(db, api: api);
    expect(await cache.load(), isNull);
    expect(await cache.refresh(), isTrue);
    online = false;
    expect(await cache.refresh(), isFalse);
    final stored = (await cache.load())!;
    expect(stored.features['ai'], 300);
    expect(stored.plans, ['free', 'grower_pro']);
    expect((await cache.rules()).graceHours, 72);
  });
}
