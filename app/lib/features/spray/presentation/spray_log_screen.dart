import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/spray_check.dart';
import 'spray_warnings.dart';

/// Spray history of one block, newest first, with offline ban / PHI flags per record.
class SprayLogScreen extends ConsumerWidget {
  const SprayLogScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull;
    final sprays = ref.watch(spraysProvider(plotId)).value ?? const [];
    final cycles = ref.watch(baharCyclesProvider(plotId)).value ?? const [];
    final rules =
        ref.watch(restrictionsProvider).value ?? RestrictionList.empty();
    final crop = cropRulesFor(ref, plot?.crop);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(
          '${t.sprayLogTitle} · ${plot?.name ?? ''}',
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: sprays.isEmpty
          ? Center(child: Text(t.spraysEmpty, style: BmType.body))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                120,
              ),
              children: [
                for (final s in sprays)
                  Padding(
                    padding: const EdgeInsets.only(bottom: BmSpace.sm),
                    child: BmCard(
                      elevated: false,
                      radius: BmRadius.card,
                      padding: const EdgeInsets.all(BmSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.productName,
                            style: BmType.section.copyWith(color: c.ink),
                          ),
                          Text(
                            [
                              formatDate(s.sprayedOn, lang),
                              if (s.target != null) s.target!,
                              if (s.costPaise > 0)
                                formatPaise(s.costPaise, lang),
                            ].join(' · '),
                            style: BmType.meta.copyWith(color: c.inkMuted),
                          ),
                          for (final w in checkSpray(
                            activeIngredient: s.activeIngredient,
                            sprayedOn: s.sprayedOn,
                            phiDays: s.phiDays,
                            plannedHarvest: cycles
                                .where((cy) => cy.id == s.baharCycleId)
                                .firstOrNull
                                ?.planned['harvest'],
                            crop: crop,
                            rules: rules,
                          ))
                            Padding(
                              padding: const EdgeInsets.only(top: BmSpace.xs),
                              child: Text(
                                warningText(t, w, lang).$1,
                                style: BmType.bodyStrong.copyWith(
                                  color: c.danger,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                key: const Key('open-labels'),
                onPressed: () => context.push(Routes.labels(plotId)),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(t.labelInfoTitle),
              ),
              const SizedBox(height: BmSpace.xs),
              FilledButton(
                onPressed: () => context.push(Routes.addSpray(plotId)),
                child: Text(t.addSpray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
