// List screens show a loading state until their first data arrives, never a flash of
// their empty state ("no tasks yet") while the records are still being read.
import 'dart:async';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/design_system/empty_state.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:bagmitra/features/plots/presentation/plots_screen.dart';
import 'package:bagmitra/features/tasks/domain/farm_task.dart';
import 'package:bagmitra/features/tasks/presentation/tasks_screen.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides,
) async {
  final db = memoryDb();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), ...overrides],
      child: MaterialApp(
        theme: BmTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('tasks: loading first, then the empty state', (tester) async {
    final tasks = StreamController<List<FarmTask>>();
    addTearDown(tasks.close);
    await _pump(tester, const TasksScreen(), [
      tasksProvider.overrideWith((ref) => tasks.stream),
      taskKindsProvider.overrideWith((ref) async => const []),
    ]);
    expect(find.byType(LoadingState), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);

    tasks.add(const []);
    await tester.pump();
    expect(find.byType(LoadingState), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('plots: loading first, then the empty state', (tester) async {
    final plots = StreamController<List<Plot>>();
    addTearDown(plots.close);
    await _pump(tester, const PlotsScreen(), [
      plotsProvider.overrideWith((ref) => plots.stream),
      cropsProvider.overrideWith((ref) async => const []),
    ]);
    expect(find.byType(LoadingState), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);

    plots.add(const []);
    await tester.pump();
    expect(find.byType(LoadingState), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
