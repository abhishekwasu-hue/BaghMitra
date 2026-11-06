// Push alerts (audit BG-01): the build flag gating, token registration with the API, and
// taking the phone off the list at sign-out. Fakes only: no Firebase, no server.
import 'dart:async';
import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/core/app_log.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/features/push/data/push_device_api.dart';
import 'package:bagmitra/features/push/domain/push.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import '../profile/profile_screen_test.dart' show seedProfile, tapKey;

class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.available = true, this.currentToken = 'tok-1'});

  final bool available;
  String? currentToken;
  int starts = 0;
  final refresh = StreamController<String>.broadcast();
  final notes = StreamController<PushNote>.broadcast();
  final shown = <PushNote>[];

  @override
  Future<bool> start() async {
    starts++;
    return available;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get tokenRefresh => refresh.stream;

  @override
  Stream<PushNote> get foregroundNotes => notes.stream;

  @override
  Future<void> show(PushNote note) async => shown.add(note);

  Future<void> close() async {
    await refresh.close();
    await notes.close();
  }
}

class RecordingDeviceApi implements PushDeviceApi {
  final calls = <String>[];
  bool fail = false;

  @override
  Future<void> register(String token) async {
    calls.add('register $token');
    if (fail) throw const PushDeviceException(503);
  }

  @override
  Future<void> unregister(String token) async {
    calls.add('unregister $token');
    if (fail) throw const PushDeviceException(503);
  }
}

class _HangingApi implements PushDeviceApi {
  @override
  Future<void> register(String token) async {}

  @override
  Future<void> unregister(String token) => Completer<void>().future;
}

const _online = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'https://api.example.test',
  supabaseUrl: 'https://project.supabase.test',
  supabaseAnonKey: 'anon',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
);

const _pushOn = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'https://api.example.test',
  supabaseUrl: 'https://project.supabase.test',
  supabaseAnonKey: 'anon',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
  push: true,
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('build flag', () {
    test(
      'push is off unless the build turns it on, and never in demo mode',
      () {
        expect(AppConfig.fromEnvironment().push, isFalse);
        expect(_online.pushEnabled, isFalse);
        expect(_pushOn.pushEnabled, isTrue);
        const demo = AppConfig(
          productName: 'BagMitra',
          apiBaseUrl: 'http://localhost',
          supabaseUrl: '',
          supabaseAnonKey: '',
          devGallery: false,
          testBuild: '',
          speechEngine: 'on_device',
          push: true,
        );
        expect(demo.pushEnabled, isFalse);
      },
    );

    test('the default push service never starts', () async {
      const off = NoPushMessaging();
      expect(await off.start(), isFalse);
      expect(await off.token(), isNull);
      expect(await off.tokenRefresh.isEmpty, isTrue);
      expect(await off.foregroundNotes.isEmpty, isTrue);
      await off.show(const PushNote(title: 't', body: 'b'));
    });
  });

  group('PushRegistrar', () {
    late FakePushMessaging messaging;
    late RecordingDeviceApi api;
    late MemoryAppLog log;
    late PushRegistrar registrar;

    setUp(() {
      messaging = FakePushMessaging();
      api = RecordingDeviceApi();
      log = MemoryAppLog();
      registrar = PushRegistrar(messaging: messaging, api: api, log: log);
    });
    tearDown(() async {
      await registrar.dispose();
      await messaging.close();
    });

    test('registers the token once per signed-in account', () async {
      await registrar.signedIn('u1');
      await registrar.signedIn('u1');
      expect(api.calls, ['register tok-1']);
      expect(registrar.registeredToken, 'tok-1');
      expect(messaging.starts, 1);
      await registrar.signedIn('u2'); // the server moves the token to u2
      expect(api.calls, ['register tok-1', 'register tok-1']);
    });

    test('a service that cannot start registers nothing', () async {
      final off = FakePushMessaging(available: false);
      final r = PushRegistrar(messaging: off, api: api, log: log);
      await r.signedIn('u1');
      await r.signedIn('u1');
      expect(api.calls, isEmpty);
      expect(off.starts, 1, reason: 'start is tried once');
      await r.beforeSignOut();
      expect(api.calls, isEmpty);
      await r.dispose();
    });

    test('no token yet: nothing is sent', () async {
      messaging.currentToken = null;
      await registrar.signedIn('u1');
      expect(api.calls, isEmpty);
    });

    test('a refreshed token is registered while signed in only', () async {
      messaging.refresh.add('early');
      await _flush();
      expect(api.calls, isEmpty);
      await registrar.signedIn('u1');
      messaging.refresh
        ..add('tok-1')
        ..add('tok-2');
      await _flush();
      expect(api.calls, ['register tok-1', 'register tok-2']);
      expect(registrar.registeredToken, 'tok-2');
    });

    test('a failed registration is logged and tried again next time', () async {
      api.fail = true;
      await registrar.signedIn('u1');
      expect(registrar.registeredToken, isNull);
      expect(await log.read(), contains('push register: PushDeviceException'));
      expect(await log.read(), isNot(contains('tok-1')));
      api.fail = false;
      await registrar.signedIn('u1');
      expect(api.calls, ['register tok-1', 'register tok-1']);
      expect(registrar.registeredToken, 'tok-1');
    });

    test('sign-out removes the token, even when the call fails', () async {
      await registrar.signedIn('u1');
      await registrar.beforeSignOut();
      expect(api.calls, ['register tok-1', 'unregister tok-1']);
      expect(registrar.registeredToken, isNull);
      await registrar.beforeSignOut(); // nothing registered any more
      expect(api.calls, hasLength(2));

      await registrar.signedIn('u1');
      api.fail = true;
      await registrar.beforeSignOut();
      expect(
        await log.read(),
        contains('push unregister: PushDeviceException'),
      );
      messaging.refresh.add('tok-3'); // signed out: not registered
      await _flush();
      expect(api.calls.last, 'unregister tok-1');
    });

    test('a session that ended without sign-out registers again', () async {
      await registrar.signedIn('u1');
      registrar.signedOut(); // e.g. account deleted: the server rows are gone
      expect(registrar.registeredToken, isNull);
      await registrar.signedIn('u1');
      expect(api.calls, ['register tok-1', 'register tok-1']);
    });

    test('a slow unregister does not hold up sign-out', () async {
      final r = PushRegistrar(
        messaging: messaging,
        api: _HangingApi(),
        log: log,
        unregisterTimeout: const Duration(milliseconds: 10),
      );
      await r.signedIn('u1');
      await r.beforeSignOut();
      expect(await log.read(), contains('push unregister: TimeoutException'));
      expect(r.registeredToken, isNull);
      await r.dispose();
    });

    test('a push that arrives in the foreground is shown', () async {
      await registrar.signedIn('u1');
      messaging.notes.add(const PushNote(title: 'Alert', body: 'Check'));
      await _flush();
      await _flush();
      expect(messaging.shown.single.body, 'Check');
    });
  });

  group('HttpPushDeviceApi', () {
    test('posts and deletes the token on /v1/me/devices', () async {
      final seen = <String>[];
      final api = createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'jwt',
        httpClient: MockClient((req) async {
          seen.add('${req.method} ${req.url.path} ${req.body}');
          return http.Response('', 204);
        }),
      );
      final devices = HttpPushDeviceApi(api);
      await devices.register('tok-1');
      await devices.unregister('tok-1');
      expect(seen[0], startsWith('POST /v1/me/devices '));
      expect(jsonDecode(seen[0].split(' ').skip(2).join(' ')), {
        'token': 'tok-1',
        'platform': 'android',
      });
      expect(seen[1], startsWith('DELETE /v1/me/devices '));
      expect(jsonDecode(seen[1].split(' ').skip(2).join(' ')), {
        'token': 'tok-1',
      });
    });

    test('a refused call throws with its status', () async {
      final api = createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'jwt',
        httpClient: MockClient((_) async => http.Response('{}', 401)),
      );
      final devices = HttpPushDeviceApi(api);
      await expectLater(
        devices.register('t'),
        throwsA(
          isA<PushDeviceException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => '$e', 'text', 'PushDeviceException(401)'),
        ),
      );
      await expectLater(
        devices.unregister('t'),
        throwsA(isA<PushDeviceException>()),
      );
    });
  });

  group('app root', () {
    testWidgets('push off (default build): Firebase is never started', (
      tester,
    ) async {
      final messaging = FakePushMessaging();
      final api = RecordingDeviceApi();
      await pumpApp(
        tester,
        config: _online,
        overrides: [
          pushMessagingProvider.overrideWithValue(messaging),
          pushDeviceApiProvider.overrideWithValue(api),
        ],
      );
      await settle(tester);
      expect(messaging.starts, 0);
      expect(api.calls, isEmpty);
      await unmountApp(tester);
    });

    testWidgets('push on: the signed-in phone registers, and sign-out '
        'removes it', (tester) async {
      final messaging = FakePushMessaging();
      final api = RecordingDeviceApi();
      await pumpApp(
        tester,
        locale: const Locale('en'),
        config: _pushOn,
        onboarded: false,
        seed: seedProfile,
        overrides: [
          pushMessagingProvider.overrideWithValue(messaging),
          pushDeviceApiProvider.overrideWithValue(api),
        ],
      );
      await settle(tester);
      expect(api.calls, ['register tok-1']);

      await tester.tap(find.byKey(const Key('open-profile')));
      await settle(tester);
      await tapKey(tester, 'sign-out');
      await tester.tap(find.byKey(const Key('sign-out-confirm')));
      await settle(tester);
      expect(api.calls, ['register tok-1', 'unregister tok-1']);
      await unmountApp(tester);
    });
  });
}
