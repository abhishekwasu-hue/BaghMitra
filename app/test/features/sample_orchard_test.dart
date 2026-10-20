import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/dev/sample_orchard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import 'test_build_test.dart' show TestBuildConfigX, testBuildConfig;

void main() {
  testWidgets('Settings adds the sample orchard once, however often tapped', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      config: testBuildConfig,
      initialLocation: '/settings',
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );

    await tester.tap(find.byKey(const Key('seed-orchard')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.tap(find.byKey(const Key('seed-orchard')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Sample orchard added'), findsWidgets);

    final plots = await tester.runAsync(
      () => container.read(plotRepositoryProvider).watchAll().first,
    );
    expect(plots!.single.id, SampleOrchard.plotId);
    expect(plots.single.crop, 'santra');
    expect(plots.single.boundary, isNotNull);

    Future<T?> first<T>(Stream<T> s) => tester.runAsync(() => s.first);
    final cycles = await first(
      container
          .read(baharRepositoryProvider)
          .watchForPlot(SampleOrchard.plotId),
    );
    expect(cycles!.single.bahar, 'mrig');
    expect(cycles.single.status, 'active');
    expect(
      (await first(
        container
            .read(accountsRepositoryProvider)
            .watchExpenses(SampleOrchard.plotId),
      ))!.length,
      1,
    );
    expect(
      (await first(
        container
            .read(fieldWorkRepositoryProvider)
            .watchHarvests(SampleOrchard.plotId),
      ))!.length,
      1,
    );
    await unmountApp(tester);
  });

  testWidgets('no seed button when a backend is configured', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/settings',
      config: testBuildConfig.withBackend(),
    );
    expect(find.byKey(const Key('seed-orchard')), findsNothing);
    expect(find.byKey(const Key('send-logs')), findsOneWidget);
    await unmountApp(tester);
  });
}
