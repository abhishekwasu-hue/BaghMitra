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
import '../../bills/data/bill_photos.dart';
import '../../bills/presentation/bill_photo_field.dart';
import '../domain/spray_check.dart';
import 'spray_detail_screen.dart';
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
    final loaded = ref.watch(spraysProvider(plotId));
    final sprays = loaded.value ?? const [];
    final cycles = ref.watch(baharCyclesProvider(plotId)).value ?? const [];
    final rules =
        ref.watch(restrictionsProvider).value ?? RestrictionList.empty();
    final crop = cropRulesFor(ref, plot?.crop);
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle('${t.sprayLogTitle} · ${plot?.name ?? ''}'),
      ),
      body: loaded.isLoading && !loaded.hasValue
          ? LoadingState(label: t.loadingLabel)
          : sprays.isEmpty
          ? EmptyState(glyph: BmGlyph.spray, message: t.spraysEmpty)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                120,
              ),
              itemCount: sprays.length,
              itemBuilder: (context, i) {
                final s = sprays[i];
                final harvest = cycles
                    .where((cy) => cy.id == s.baharCycleId)
                    .firstOrNull
                    ?.planned['harvest'];
                // Each product's own check (a tank mix, Q142); a note kind once per card.
                final notes = {
                  for (final ws in checkSprayProducts(
                    s.products,
                    sprayedOn: s.sprayedOn,
                    plannedHarvest: harvest,
                    crop: crop,
                    rules: rules,
                  ))
                    for (final w in ws) warningText(t, w, lang).$1,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: BmSpace.sm),
                  child: InkWell(
                    key: Key('spray-open-${s.id}'),
                    borderRadius: BorderRadius.circular(BmRadius.card),
                    onTap: () => context.push(Routes.spray(plotId, s.id)),
                    child: BmCard(
                      elevated: false,
                      radius: BmRadius.card,
                      padding: const EdgeInsets.all(BmSpace.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sprayTitle(t, s),
                                  style: BmType.section.copyWith(color: c.ink),
                                ),
                                Text(
                                  [
                                    formatDate(s.sprayedOn, lang),
                                    if (s.target != null) s.target!,
                                    if (s.totalPaise > 0)
                                      formatPaise(s.totalPaise, lang),
                                  ].join(' · '),
                                  style: BmType.meta.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                                for (final title in notes)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: BmSpace.xs,
                                    ),
                                    child: Text(
                                      title,
                                      style: BmType.meta.copyWith(
                                        color: c.inkMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (s.hasBillPhoto) ...[
                            const SizedBox(width: BmSpace.sm),
                            RecordBillThumb(
                              kind: BillKind.spray,
                              recordId: s.id,
                              path: s.billPhotoPath,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomActions(
        stacked: true,
        children: [
          OutlinedButton.icon(
            key: const Key('open-labels'),
            onPressed: () => context.push(Routes.labels(plotId)),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(t.labelInfoTitle),
          ),
          FilledButton(
            onPressed: () => context.push(Routes.addSpray(plotId)),
            child: Text(t.addSpray),
          ),
        ],
      ),
    );
  }
}
