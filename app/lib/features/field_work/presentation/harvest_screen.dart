import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
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
    final loaded = ref.watch(harvestsProvider(plotId));
    final lots = loaded.value ?? const [];
    final opts = ref.watch(fieldWorkOptionsProvider).value;
    final total = lots.fold(0.0, (a, l) => a + l.quantityKg);
    String name(List<LabeledOption>? items, String slug) =>
        items?.where((x) => x.slug == slug).firstOrNull?.label(lang) ?? slug;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.harvestTitle)),
      body: loaded.isLoading && !loaded.hasValue
          ? LoadingState(label: t.loadingLabel)
          : lots.isEmpty
          ? EmptyState(glyph: BmGlyph.orange, message: t.harvestEmpty)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                120,
              ),
              itemCount: lots.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: BmSpace.sm),
                    child: BmCard(
                      elevated: false,
                      radius: BmRadius.card,
                      padding: const EdgeInsets.all(BmSpace.md),
                      child: Text(
                        t.harvestTotal(formatDecimal(total, lang)),
                        style: BmType.section.copyWith(color: c.brand),
                      ),
                    ),
                  );
                }
                final l = lots[i - 1];
                return ListTile(
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
                );
              },
            ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: () => context.push(Routes.addHarvest(plotId)),
            child: Text(t.harvestAdd),
          ),
        ],
      ),
    );
  }
}
