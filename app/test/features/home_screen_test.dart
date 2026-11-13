import 'package:bagmitra/design_system/navigation.dart';
import 'package:bagmitra/design_system/sync_banner.dart';
import 'package:bagmitra/design_system/task_tile.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('shows the key home sections in Marathi', (tester) async {
    await pumpApp(tester);
    expect(find.text('आजची कामे'), findsOneWidget);
    expect(find.text('फळधारणा सुरू'), findsOneWidget);
    expect(find.text('६८'), findsOneWidget);
    expect(find.text('कीड-रोग फोटो'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('ticking a task toggles it', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));
    final spray = find.widgetWithText(TaskTile, 'Psylla check — 10 trees');
    expect(tester.widget<TaskTile>(spray).done, isFalse);
    await tester.ensureVisible(spray);
    await tester.pump();
    await tester.tap(spray);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<TaskTile>(spray).done, isTrue);
    await unmountApp(tester);
  });

  testWidgets('offline, server down and waiting entries show no strip', (
    tester,
  ) async {
    // Owner (2026-11-13): sync retries quietly; a strip only when the grower must act.
    for (final status in const [
      SyncStatus(connectivity: Connectivity.offline, pending: 2),
      SyncStatus(connectivity: Connectivity.serverError, pending: 2),
      SyncStatus(connectivity: Connectivity.online, pending: 3),
    ]) {
      await pumpApp(tester, locale: const Locale('en'), syncStatus: status);
      expect(find.byType(SyncBanner), findsNothing, reason: '$status');
      await unmountApp(tester);
    }
  });

  testWidgets('rejected writes surface a failure banner', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      syncStatus: const SyncStatus(
        connectivity: Connectivity.online,
        rejected: 1,
      ),
    );
    // Home shows the shared sync strip: the count to check and a way to review them.
    expect(find.byKey(const Key('sync-banner-rejected')), findsOneWidget);
    expect(find.textContaining('1 entry to check'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'a long press on the camera opens the dev gallery in dev builds',
    (tester) async {
      await pumpApp(tester, locale: const Locale('en'));
      await tester.longPress(find.byType(CameraButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Component gallery'), findsOneWidget);
      await unmountApp(tester);
    },
  );
}
