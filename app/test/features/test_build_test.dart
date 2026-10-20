import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/core/app_log.dart';
import 'package:bagmitra/core/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

const testBuildConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: true,
  testBuild: 'abc1234',
  speechEngine: 'on_device',
);

extension TestBuildConfigX on AppConfig {
  AppConfig withBackend() => AppConfig(
    productName: productName,
    apiBaseUrl: apiBaseUrl,
    supabaseUrl: 'https://x.supabase.co',
    supabaseAnonKey: 'anon',
    devGallery: devGallery,
    testBuild: testBuild,
    speechEngine: speechEngine,
  );
}

void main() {
  testWidgets('"Try without account" signs in locally and goes to setup', (
    tester,
  ) async {
    await pumpApp(tester, locale: const Locale('en'), session: null);
    expect(find.text('Try without account'), findsOneWidget);
    await tester.tap(find.byKey(const Key('try-without-account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome to BagMitra'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a test build shows its badge, says data stays on the phone and '
      'sends the log from Settings', (tester) async {
    final sharer = RecordingSharer();
    final log = MemoryAppLog()..log('hello from the test');
    await pumpApp(
      tester,
      locale: const Locale('en'),
      config: testBuildConfig,
      sharer: sharer,
      log: log,
    );
    expect(find.text('TEST BUILD abc1234'), findsOneWidget);
    expect(
      find.text('Offline test mode: your data stays on this phone'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('test-badge')));
    await tester.pumpAndSettle();
    expect(find.text('Test build abc1234'), findsOneWidget);

    await tester.tap(find.byKey(const Key('send-logs')));
    await tester.pump();
    final shared = sharer.shared.single;
    expect(shared.fileName, 'bagmitra-logs.txt');
    expect(utf8.decode(shared.bytes), contains('hello from the test'));
    await unmountApp(tester);
  });

  testWidgets('real builds have no badge and no settings route', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/settings',
      config: const AppConfig(
        productName: 'BagMitra',
        apiBaseUrl: 'http://localhost:8000',
        supabaseUrl: '',
        supabaseAnonKey: '',
        devGallery: false,
        testBuild: '',
        speechEngine: 'on_device',
      ),
    );
    expect(find.byKey(const Key('test-badge')), findsNothing);
    expect(find.byKey(const Key('send-logs')), findsNothing);
    await unmountApp(tester);
  });

  test('the file log appends, survives a missing file and stays small', () {
    final dir = Directory.systemTemp.createTempSync('bm-log');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/sub/bagmitra.log');
    final log = FileAppLog(file, maxBytes: 400, now: () => DateTime.utc(2026));
    log.log('first');
    expect(file.readAsStringSync(), '2026-01-01T00:00:00.000Z first\n');
    for (var i = 0; i < 40; i++) {
      log.log('line number $i');
    }
    final text = file.readAsStringSync();
    expect(text.length, lessThan(400));
    expect(text, contains('line number 39'));
    expect(text, isNot(contains('first')));
  });
}
