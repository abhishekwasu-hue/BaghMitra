import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/design_system/sync_banner.dart';
import 'package:bagmitra/features/auth/data/demo_auth_repository.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/sync/outbox.dart';
import 'package:bagmitra/sync/presentation/sync_status_banner.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late FakeSyncServer server;
  late SyncEngine engine;
  late DemoAuthRepository auth;

  setUp(() {
    db = memoryDb();
    server = FakeSyncServer();
    engine = SyncEngine(db: db, transport: server, appliers: const {});
    auth = DemoAuthRepository(initial: signedIn);
  });

  tearDown(() async {
    await engine.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester, SyncStatus status) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          databaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(auth),
          syncEngineProvider.overrideWithValue(engine),
          syncStatusProvider.overrideWithValue(AsyncData(status)),
        ],
        child: MaterialApp(
          theme: BmTheme.light(),
          locale: const Locale('mr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SyncStatusBanner()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offline, server down and all-sent each read differently', (
    tester,
  ) async {
    await pump(tester, const SyncStatus(connectivity: Connectivity.offline));
    expect(find.byKey(const Key('sync-banner-offline')), findsOneWidget);

    await pump(
      tester,
      const SyncStatus(connectivity: Connectivity.serverError),
    );
    expect(find.byKey(const Key('sync-banner-server')), findsOneWidget);
    expect(
      find.text(
        'तुमच्या नोंदी फोनवर सुरक्षित आहेत; सर्व्हर तयार झाल्यावर त्या आपोआप पाठवल्या जातील.',
      ),
      findsOneWidget,
    );

    await pump(tester, const SyncStatus(connectivity: Connectivity.online));
    expect(find.byType(SyncBanner), findsNothing);
  });

  testWidgets('401: a sign-in-again banner whose action signs out', (
    tester,
  ) async {
    await pump(
      tester,
      const SyncStatus(connectivity: Connectivity.signedOut, pending: 2),
    );
    expect(find.byKey(const Key('sync-banner-signed-out')), findsOneWidget);
    expect(find.text('नोंदी पाठवण्यासाठी पुन्हा लॉगिन करा'), findsOneWidget);
    expect(auth.current, isNotNull);
    await tester.tap(find.byKey(const Key('sync-banner-action')));
    await tester.pump();
    expect(auth.current, isNull);
  });

  testWidgets('turned-down entries: a sheet to send again or delete each', (
    tester,
  ) async {
    late String plotWrite;
    late String sprayWrite;
    await tester.runAsync(() async {
      final outbox = Outbox(db);
      plotWrite = await outbox.enqueue(
        entity: 'plot',
        entityId: 'p1',
        payload: {'name': 'A'},
        clientUpdatedAt: DateTime.utc(2026, 10, 20, 6),
      );
      sprayWrite = await outbox.enqueue(
        entity: 'spray_record',
        entityId: 's1',
        payload: {'x': 1},
        clientUpdatedAt: DateTime.utc(2026, 10, 21, 6),
      );
      server.knownEntities.remove('plot');
      await engine.sync();
    });
    await pump(
      tester,
      const SyncStatus(connectivity: Connectivity.online, rejected: 2),
    );
    expect(find.byKey(const Key('sync-banner-rejected')), findsOneWidget);
    expect(find.text('2 नोंदी तपासायच्या आहेत'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sync-banner-action')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rejected-writes-sheet')), findsOneWidget);
    expect(find.text('तपासायच्या नोंदी'), findsOneWidget);
    expect(find.text('बाग'), findsOneWidget);
    expect(find.text('फवारणी'), findsOneWidget);
    expect(find.text('पुन्हा पाठवा'), findsNWidgets(2));
    expect(find.text('हटवा'), findsNWidgets(2));

    // Send the plot again (the server takes it now); delete the spray entry.
    server.knownEntities.addAll({'plot', 'spray_record'});
    await tester.tap(find.byKey(Key('rejected-resend-$plotWrite')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.tap(find.byKey(Key('rejected-delete-$sprayWrite')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(server.row('plot', 'p1'), {'name': 'A'});
    final left = await tester.runAsync(() => db.select(db.outboxEntries).get());
    expect(left, isEmpty);
    expect(find.text('सर्व नोंदी व्यवस्थित आहेत'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
