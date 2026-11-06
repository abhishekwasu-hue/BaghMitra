import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/billing/data/entitlements_cache.dart';
import 'package:bagmitra/features/billing/data/snapshot_signature.dart';
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

  // Signed by the API's own `billing/signing.py` with the test seed bytes 0..31 (no real key).
  const publicKey = 'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg';
  const signature =
      'uHqY_uSo5BVJeDh7hOPLXlJOxxcNGibX7pAqO35yG_GgMsn0p56NcHxy6YHBSkw89e5FPua8CqaMNEx7fWSeCw';
  Map<String, Object?> payload() => {
    'plans': ['sanman'],
    'features': {
      'ai': {'enabled': true, 'limit': 300},
      'calendar': {'enabled': true, 'limit': null},
      'photos': {'enabled': false, 'limit': 0},
      'records': {'enabled': true, 'limit': null},
    },
    'valid_until': '2030-01-08T00:00:00Z',
    'computed_at': '2030-01-01T00:00:00Z',
  };

  test('canonical JSON matches the server byte form', () {
    expect(
      utf8.decode(canonicalJson(payload())),
      '{"computed_at":"2030-01-01T00:00:00Z","features":{"ai":{"enabled":true,'
      '"limit":300},"calendar":{"enabled":true,"limit":null},"photos":{"enabled":'
      'false,"limit":0},"records":{"enabled":true,"limit":null}},"plans":["sanman"],'
      '"valid_until":"2030-01-08T00:00:00Z"}',
    );
  });

  test(
    'verifier accepts the server signature and rejects anything else',
    () async {
      final v = SnapshotVerifier(publicKey);
      expect(await v.verify(payload(), signature), isTrue);
      final edited = payload()..['plans'] = ['sanman', 'grower_pro'];
      expect(await v.verify(edited, signature), isFalse);
      expect(await v.verify(payload(), null), isFalse);
      expect(await v.verify(payload(), 'not-a-signature'), isFalse);
      expect(await SnapshotVerifier('').verify(payload(), signature), isFalse);
      expect(
        await SnapshotVerifier('%%').verify(payload(), signature),
        isFalse,
      );
    },
  );

  group('cache', () {
    late AppDatabase db;
    var online = true;
    String? served = signature;

    EntitlementsCache build({String key = publicKey}) => EntitlementsCache(
      db,
      verifier: SnapshotVerifier(key),
      api: createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 't',
        httpClient: MockClient((req) async {
          if (!online) throw http.ClientException('offline');
          return http.Response(
            jsonEncode({'entitlements': payload(), 'signature': served}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    setUp(() {
      db = memoryDb();
      online = true;
      served = signature;
    });
    tearDown(() => db.close());

    test(
      'refresh stores the signed snapshot, load verifies it offline',
      () async {
        final cache = build();
        expect(await cache.load(), isNull);
        expect(await cache.refresh(), isTrue);
        online = false;
        expect(await cache.refresh(), isFalse);
        final stored = (await cache.load())!;
        expect(stored.features, {'ai': 300, 'calendar': null, 'records': null});
        expect(stored.plans, ['sanman']);
        expect((await cache.rules()).graceHours, 72);
      },
    );

    test('a snapshot edited on the phone is no entitlement', () async {
      final cache = build();
      await cache.refresh();
      final raw =
          jsonDecode((await db.readMeta(EntitlementsCache.metaKey))!) as Map;
      ((raw['entitlements'] as Map)['features'] as Map)['photos'] = {
        'enabled': true,
        'limit': null,
      };
      await db.writeMeta(EntitlementsCache.metaKey, jsonEncode(raw));
      expect(await cache.load(), isNull);
    });

    test(
      'unsigned, unverifiable, old-format or broken caches are no entitlement',
      () async {
        served = null;
        expect(await build().refresh(), isTrue);
        expect(await build().load(), isNull);
        served = signature;
        await build().refresh();
        expect(await build(key: '').load(), isNull);
        await db.writeMeta(
          EntitlementsCache.metaKey,
          jsonEncode(snapshot().toJson()),
        );
        expect(await build().load(), isNull);
        await db.writeMeta(EntitlementsCache.metaKey, '{broken');
        expect(await build().load(), isNull);
      },
    );
  });
}
