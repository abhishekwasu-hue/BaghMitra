import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/market_link/data/market_link_store.dart';
import 'package:bagmitra/features/market_link/domain/market_link.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';

/// The server's `GET /v1/market-link/terms` answer with [privacy] as the privacy version.
String termsJson({String privacy = '1', String? contact}) => jsonEncode({
  'documents': [
    {'kind': 'terms', 'version': '1', 'url': null},
    {'kind': 'privacy', 'version': privacy, 'url': '/privacy'},
    {'kind': 'disclaimer', 'version': '1', 'url': null},
  ],
  'grievance_officer': {'name': null, 'contact': contact},
});

/// A fake market-link server: [up] false answers like a phone with no network.
class FakeServer {
  bool up = true;
  String privacy = '1';
  List<String> serverRoles = [];
  final posted = <Map<String, Object?>>[];

  Future<http.Response> handle(http.Request r) async {
    if (!up) throw http.ClientException('offline');
    final mine = jsonEncode({'roles': serverRoles, 'acceptances': <Object>[]});
    return switch ((r.method, r.url.path)) {
      ('GET', '/v1/market-link/terms') => http.Response(
        termsJson(privacy: privacy, contact: 'help@example.test'),
        200,
      ),
      ('GET', '/v1/market-link/me/acceptances') => http.Response(mine, 200),
      ('POST', '/v1/market-link/terms/accept') => _accept(r),
      _ => http.Response('{}', 404),
    };
  }

  http.Response _accept(http.Request r) {
    final body = (jsonDecode(r.body) as Map).cast<String, Object?>();
    if (body['privacy_version'] != privacy) {
      return http.Response('{"error":{"code":"terms_version_changed"}}', 409);
    }
    posted.add(body);
    return http.Response(
      jsonEncode({
        'roles': [body['role']],
        'acceptances': <Object>[],
      }),
      200,
    );
  }
}

void main() {
  late FakeServer server;
  late MarketLinkStore store;

  setUp(() {
    server = FakeServer();
    final db = memoryDb();
    addTearDown(db.close);
    store = MarketLinkStore(
      db,
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'tok',
        httpClient: MockClient(server.handle),
      ),
    );
  });

  test(
    'bundled terms until the server answers, then the server copy',
    () async {
      expect((await store.terms()).versions, MarketTerms.bundled.versions);
      expect(await store.sync('u1'), isTrue);
      final terms = await store.terms();
      expect(terms.grievanceContact, 'help@example.test');
      expect(terms.privacyUrl, '/privacy');
      expect(terms.termsUrl, isNull);
      expect(store.synced, isTrue);
    },
  );

  test(
    'acceptance posts the versions read, with the 18+ declaration',
    () async {
      await store.sync('u1');
      await store.accept('u1', MarketRole.trader);
      expect(await store.isAccepted('u1', MarketRole.trader), isTrue);
      expect(await store.isAccepted('u1', MarketRole.broker), isFalse);
      expect(await store.isAccepted('u2', MarketRole.trader), isFalse);
      expect(server.posted, [
        {
          'adult_declared': true,
          'disclaimer_version': '1',
          'privacy_version': '1',
          'role': 'trader',
          'terms_version': '1',
        },
      ]);
    },
  );

  test(
    'offline acceptance counts on the phone and is posted once online',
    () async {
      server.up = false;
      await store.accept('u1', MarketRole.broker);
      expect(await store.isAccepted('u1', MarketRole.broker), isTrue);
      expect(server.posted, isEmpty);
      server.up = true;
      await store.sync('u1');
      expect(server.posted.single['role'], 'broker');
      // Posted once only.
      await store.sync('u1');
      expect(server.posted, hasLength(1));
    },
  );

  test('a version change shows the terms again', () async {
    server.up = false;
    await store.accept('u1', MarketRole.exporter);
    server
      ..up = true
      ..privacy = '2';
    await store.sync('u1');
    // The old version was refused (409) and the new one is not accepted yet.
    expect(server.posted, isEmpty);
    expect(await store.isAccepted('u1', MarketRole.exporter), isFalse);
    await store.accept('u1', MarketRole.exporter);
    expect(server.posted.single['privacy_version'], '2');
    expect(await store.isAccepted('u1', MarketRole.exporter), isTrue);
  });

  test('roles accepted on another phone count here after a sync', () async {
    server.serverRoles = ['provider', 'representative'];
    await store.sync('u1');
    expect(await store.isAccepted('u1', MarketRole.provider), isTrue);
    expect(await store.isAccepted('u1', MarketRole.trader), isFalse);
  });

  test('the active role is remembered on the phone', () async {
    expect(await store.activeRole(), isNull);
    await store.setActiveRole(MarketRole.provider);
    expect(await store.activeRole(), MarketRole.provider);
    expect(MarketRole.fromName('admin'), isNull);
  });
}
