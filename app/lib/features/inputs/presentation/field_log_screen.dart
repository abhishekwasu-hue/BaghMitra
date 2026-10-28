import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/data/bahar_catalog.dart';

/// Fertiliser / manure applications and irrigation for one block, newest first.
class FieldLogScreen extends ConsumerWidget {
  const FieldLogScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull;
    final inputs = ref.watch(inputsProvider(plotId)).value ?? const [];
    final irrigations =
        ref.watch(irrigationsProvider(plotId)).value ?? const [];
    final data = ref.watch(inputKindsProvider).value;
    final units = {
      for (final u in data?.units ?? const <LabeledOption>[]) u.slug: u,
    };

    final rows = <(DateTime, String, String?, String?)>[
      for (final i in inputs)
        (
          i.appliedOn,
          i.productName,
          [
            if (i.quantity != null)
              t
                  .inputLine(
                    formatDecimal(i.quantity!, lang),
                    i.unit == null ? '' : units[i.unit]?.label(lang) ?? i.unit!,
                  )
                  .trim(),
            formatDate(i.appliedOn, lang),
          ].join(' · '),
          i.costPaise > 0 ? formatPaise(i.costPaise, lang) : null,
        ),
      for (final r in irrigations)
        (
          r.irrigatedOn,
          t.irrigationTitle,
          [
            if (r.durationHours != null)
              t.irrigationHoursLine(formatDecimal(r.durationHours!, lang)),
            formatDate(r.irrigatedOn, lang),
          ].join(' · '),
          null,
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return Scaffold(
      appBar: AppBar(title: Text('${t.fieldLogTitle} · ${plot?.name ?? ''}')),
      body: rows.isEmpty
          ? EmptyState(glyph: BmGlyph.drop, message: t.fieldLogEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                120,
              ),
              children: [
                for (final (_, title, subtitle, amount) in rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title, style: BmType.body),
                    subtitle: subtitle == null ? null : Text(subtitle),
                    trailing: amount == null
                        ? null
                        : Text(amount, style: BmType.bodyStrong),
                  ),
              ],
            ),
      bottomNavigationBar: BottomActions(
        children: [
          OutlinedButton(
            onPressed: () => context.push(Routes.addIrrigation(plotId)),
            child: Text(t.logIrrigation),
          ),
          FilledButton(
            onPressed: () => context.push(Routes.addInput(plotId)),
            child: Text(t.addInput),
          ),
        ],
      ),
    );
  }
}
