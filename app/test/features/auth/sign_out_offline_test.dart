import 'dart:convert';

import 'package:bagmitra/features/auth/infra/supabase_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../helpers/pump_app.dart' show unmountApp;
import '../plots/plots_screen_test.dart' show settle;
import '../profile/profile_screen_test.dart' show openProfile, tapKey;

/// A Supabase client whose every request fails as it does in airplane mode. Nothing leaves
/// the test: the host is never reached.
Future<SupabaseAuthRepository> offlineRepo(List<String> log) async {
  final client = sb.SupabaseClient(
    'https://supabase.example.test',
    'anon',
    httpClient: MockClient(
      (_) async => throw http.ClientException('Failed host lookup'),
    ),
    authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
  );
  await client.auth.setInitialSession(
    jsonEncode({
      'access_token': 'token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh',
      'user': {
        'id': 'u1',
        'aud': 'authenticated',
        'phone': '919800000000',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
      },
    }),
  );
  addTearDown(client.dispose);
  return SupabaseAuthRepository(client, log: log.add);
}

void main() {
  test('offline sign-out does not throw and ends the local session', () async {
    final log = <String>[];
    final repo = await offlineRepo(log);
    expect(repo.current?.userId, 'u1');
    final ended = expectLater(repo.sessions(), emitsThrough(isNull));
    await repo.signOut();
    await ended;
    expect(repo.current, isNull);
    expect(log.single, startsWith('auth: sign-out kept local only'));
    expect(log.single, isNot(contains('token')));
  });

  testWidgets('offline sign-out from the profile lands on the login screen', (
    tester,
  ) async {
    final log = <String>[];
    final repo = (await tester.runAsync(() => offlineRepo(log)))!;
    await openProfile(tester, session: repo.current!, auth: repo);
    await tapKey(tester, 'sign-out');
    await tester.tap(find.byKey(const Key('sign-out-confirm')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('My profile'), findsNothing);
    expect(find.text('Mobile number'), findsOneWidget); // the login screen
    expect(repo.current, isNull);
    await unmountApp(tester);
  });
}
