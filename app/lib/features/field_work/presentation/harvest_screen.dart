import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/data/bahar_catalog.dart';

/// Harvest lots for one block, newest first, with the total weight picked.
class HarvestScreen extends ConsumerWidget {
  const HarvestScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final lots = ref.watch(harvestsProvider(plotId)).value ?? const [];
    final opts = ref.watch(fieldWorkOptionsProvider).value;
    final total = lots.fold(0.0, (a, l) => a + l.quantityKg);
    String name(List<LabeledOption>? items, String slug) =>
        items?.where((x) => x.slug == slug).firstOrNull?.label(lang) ?? slug;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(
          t.harvestTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: lots.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(BmSpace.lg),
              child: Text(
                t.harvestEmpty,
                style: BmType.body.copyWith(color: c.inkMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                120,
              ),
              children: [
                BmCard(
                  elevated: false,
                  radius: BmRadius.card,
                  padding: const EdgeInsets.all(BmSpace.md),
                  child: Text(
                    t.harvestTotal(formatDecimal(total, lang)),
                    style: BmType.section.copyWith(color: c.brand),
                  ),
                ),
                const SizedBox(height: BmSpace.sm),
                for (final l in lots)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      [
                        if (l.grade != null) name(opts?.grades, l.grade!),
                        if (l.sizeClass != null)
                          name(opts?.sizeClasses, l.sizeClass!),
                        if (l.grade == null && l.sizeClass == null)
                          t.harvestTitle,
                      ].join(' · '),
                      style: BmType.body,
                    ),
                    subtitle: Text(formatDate(l.harvestedOn, lang)),
                    trailing: Text(
                      t.harvestKgValue(formatDecimal(l.quantityKg, lang)),
                      style: BmType.bodyStrong,
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: FilledButton(
            onPressed: () => context.push(Routes.addHarvest(plotId)),
            child: Text(t.harvestAdd),
          ),
        ),
      ),
    );
  }
}
