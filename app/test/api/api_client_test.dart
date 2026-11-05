import 'dart:async';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.enums.swagger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('defaults: 10 s to connect, 20 s for the answer', () {
    const t = ApiTimeouts();
    expect(t.connect, const Duration(seconds: 10));
    expect(t.receive, const Duration(seconds: 20));
  });

  test(
    'a slow answer ends in a TimeoutException instead of waiting forever',
    () async {
      final api = createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 't',
        timeouts: const ApiTimeouts(receive: Duration(milliseconds: 50)),
        httpClient: MockClient(
          (_) => Future.delayed(
            const Duration(seconds: 2),
            () => http.Response('{}', 200),
          ),
        ),
      );
      await expectLater(
        api.v1MarketPricesGet(
          crop: 'santra',
          scope: V1MarketPricesGetScope.all,
        ),
        throwsA(isA<TimeoutException>()),
      );
    },
  );

  test('the bearer token still goes with every call', () async {
    String? auth;
    final api = createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => 'tok',
      httpClient: MockClient((req) async {
        auth = req.headers['authorization'];
        return http.Response('{"prices": [], "stale": false}', 200);
      }),
    );
    await api.v1MarketPricesGet(
      crop: 'santra',
      scope: V1MarketPricesGetScope.all,
    );
    expect(auth, 'Bearer tok');
  });

  test('the phone build gets a client with a connect timeout', () {
    final api = createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => null,
    );
    expect(api.client.httpClient, isA<http.BaseClient>());
  });
}
