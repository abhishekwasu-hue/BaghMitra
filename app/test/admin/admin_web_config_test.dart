import 'dart:convert';

import 'package:bagmitra/admin/admin_web_config.dart';
import 'package:bagmitra/core/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _base = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://10.0.2.2:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
);

final _page = Uri.parse('https://bagmitra.example.com/admin/#/feed');

void main() {
  test(
    'reads config.json next to the page and uses the page origin as API',
    () async {
      Uri? asked;
      final client = MockClient((req) async {
        asked = req.url;
        return http.Response(
          jsonEncode({
            'supabase_url': 'https://ref.supabase.co',
            'supabase_anon_key': 'anon',
          }),
          200,
        );
      });
      final config = await resolveAdminConfig(
        _base,
        isWeb: true,
        pageUri: _page,
        client: client,
      );
      expect(
        asked,
        Uri.parse('https://bagmitra.example.com/admin/config.json'),
      );
      expect(config.demoMode, isFalse);
      expect(config.supabaseUrl, 'https://ref.supabase.co');
      expect(config.supabaseAnonKey, 'anon');
      expect(config.apiBaseUrl, 'https://bagmitra.example.com');
    },
  );

  test('keeps build-time defines and never asks off the web', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    const defined = AppConfig(
      productName: 'BagMitra',
      apiBaseUrl: 'https://api.example.com',
      supabaseUrl: 'https://ref.supabase.co',
      supabaseAnonKey: 'anon',
      devGallery: false,
      testBuild: '',
      speechEngine: 'on_device',
    );
    expect(
      await resolveAdminConfig(
        defined,
        isWeb: true,
        pageUri: _page,
        client: client,
      ),
      same(defined),
    );
    expect(
      await resolveAdminConfig(
        _base,
        isWeb: false,
        pageUri: _page,
        client: client,
      ),
      same(_base),
    );
    expect(calls, 0);
  });

  test(
    'stays in demo mode when the server is not configured or answers badly',
    () async {
      for (final response in [
        http.Response('{"error":{}}', 404),
        http.Response('not json', 200),
        http.Response('[]', 200),
        http.Response(
          jsonEncode({'supabase_url': '', 'supabase_anon_key': 'x'}),
          200,
        ),
      ]) {
        final client = MockClient((_) async => response);
        final config = await resolveAdminConfig(
          _base,
          isWeb: true,
          pageUri: _page,
          client: client,
        );
        expect(config, same(_base));
      }
      final failing = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      expect(
        await resolveAdminConfig(
          _base,
          isWeb: true,
          pageUri: _page,
          client: failing,
        ),
        same(_base),
      );
    },
  );
}
