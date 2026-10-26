import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/data/bahar_catalog.dart';
import '../../plots/domain/plot.dart';
import '../domain/season_calendar.dart';

/// The next twelve months: every bahar stage the grower dated on any block, and their tasks.
class SeasonCalendarScreen extends ConsumerWidget {
  const SeasonCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final options = ref.watch(baharOptionsProvider).value;
    final plots = {
      for (final p in ref.watch(plotsProvider).value ?? const <Plot>[])
        p.id: p.name,
    };
    final months = buildSeasonCalendar(
      cycles: ref.watch(allBaharCyclesProvider).value ?? const [],
      tasks: ref.watch(tasksProvider).value ?? const [],
      from: ref.watch(clockProvider)(),
    );

    String label(List<LabeledOption>? list, String? slug) =>
        [
          for (final o in list ?? const <LabeledOption>[])
            if (o.slug == slug) o.label(lang),
        ].firstOrNull ??
        slug ??
        '';

    String title(CalendarEntry e) => switch (e.kind) {
      CalendarEntryKind.stage =>
        '${label(options?.stages, e.stage)} · ${label(options?.bahars, e.bahar)}',
      CalendarEntryKind.task => e.title ?? '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.calendarTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(t.calendarIntro, style: BmType.meta),
          for (final (month, entries) in months) ...[
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.lg),
              child: Text(
                '${formatMonth(month, lang)} ${formatYear(month.year, lang)}',
                style: BmType.label,
              ),
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
                child: Text(t.calendarMonthEmpty, style: BmType.meta),
              ),
            for (final e in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  e.kind == CalendarEntryKind.stage
                      ? Icons.local_florist_outlined
                      : (e.done ? Icons.check_circle : Icons.event_note),
                  color: e.done ? c.brand : c.inkMuted,
                ),
                title: Text(title(e)),
                subtitle: Text(
                  [
                    formatDate(e.date, lang),
                    ?plots[e.plotId],
                    if (e.kind == CalendarEntryKind.stage)
                      e.done ? t.calendarStageDone : t.calendarStagePlanned,
                  ].join(' · '),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
