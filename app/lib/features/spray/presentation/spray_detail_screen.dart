import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bills/data/bill_photos.dart';
import '../../bills/presentation/bill_photo_field.dart';
import '../domain/spray_check.dart';
import '../domain/spray_record.dart';
import 'spray_warnings.dart';

/// "मिश्रण: Captan + Imidacloprid" for a tank mix (Q142), the product's name otherwise.
String sprayTitle(AppLocalizations t, SprayRecord s) =>
    s.isMix ? t.sprayMix(s.productsLabel) : s.productName;

/// One spray as recorded: the spray's own facts, then each product of the tank with its
/// ingredient, dose, cost, PHI and its own ban / PHI note (offline, from the cached list).
class SprayDetailScreen extends ConsumerWidget {
  const SprayDetailScreen({
    required this.plotId,
    required this.sprayId,
    super.key,
  });

  final String plotId;
  final String sprayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final loaded = ref.watch(spraysProvider(plotId));
    final s = loaded.value?.where((r) => r.id == sprayId).firstOrNull;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: AppBarTitle(t.sprayDetailTitle)),
        body: loaded.isLoading && !loaded.hasValue
            ? LoadingState(label: t.loadingLabel)
            : EmptyState(glyph: BmGlyph.spray, message: t.spraysEmpty),
      );
    }
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull;
    final cycles = ref.watch(baharCyclesProvider(plotId)).value ?? const [];
    final bahars = ref.watch(baharOptionsProvider).value;
    final rules =
        ref.watch(restrictionsProvider).value ?? RestrictionList.empty();
    final cycle = cycles.where((cy) => cy.id == s.baharCycleId).firstOrNull;
    final products = s.products;
    final notes = checkSprayProducts(
      products,
      sprayedOn: s.sprayedOn,
      plannedHarvest: cycle?.planned['harvest'],
      crop: cropRulesFor(ref, plot?.crop),
      rules: rules,
    );
    final meta = BmType.meta.copyWith(color: c.inkMuted);
    final facts = [
      formatDate(s.sprayedOn, lang),
      if (cycle != null)
        '${bahars?.baharLabel(cycle.bahar, lang) ?? cycle.bahar} '
            '${formatYear(cycle.seasonYear, lang)}',
      if (s.waterLitres case final w?)
        t.sprayDetailWater(formatDecimal(w, lang)),
      if (s.areaAcres case final a?) t.sprayDetailArea(formatDecimal(a, lang)),
    ];
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.sprayDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          0,
          BmSpace.lg,
          BmSpace.xl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sprayTitle(t, s),
                      key: const Key('spray-detail-title'),
                      style: BmType.section.copyWith(color: c.ink),
                    ),
                    Text(facts.join(' · '), style: meta),
                    if (s.target != null) Text(s.target!, style: meta),
                    if (s.operator != null)
                      Text(t.sprayDetailOperator(s.operator!), style: meta),
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
          if (s.totalPaise > 0) ...[
            const SizedBox(height: BmSpace.sm),
            Text(
              (s.labourPaise ?? 0) > 0
                  ? t.sprayCostSplit(
                      formatPaise(s.costPaise, lang),
                      formatPaise(s.labourPaise!, lang),
                    )
                  : s.isMix
                  ? t.sprayMixTotal(formatPaise(s.costPaise, lang))
                  : formatPaise(s.costPaise, lang),
              key: const Key('spray-detail-cost'),
              style: BmType.bodyStrong.copyWith(color: c.ink),
            ),
          ],
          if (s.isMix && s.phiDays != null)
            InfoNote(
              t.sprayMixPhi(formatInt(s.phiDays!, lang)),
              key: const Key('spray-detail-phi'),
            ),
          const SizedBox(height: BmSpace.md),
          Text(
            t.sprayDetailProducts,
            style: BmType.section.copyWith(color: c.brandStrong),
          ),
          const SizedBox(height: BmSpace.xs),
          for (final (i, p) in products.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: BmSpace.sm),
              child: BmCard(
                key: Key('spray-detail-product-$i'),
                elevated: false,
                radius: BmRadius.card,
                padding: const EdgeInsets.all(BmSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p.productName,
                            style: BmType.bodyStrong.copyWith(color: c.ink),
                          ),
                        ),
                        if (p.costPaise > 0)
                          Text(
                            formatPaise(p.costPaise, lang),
                            style: BmType.bodyStrong.copyWith(color: c.ink),
                          ),
                      ],
                    ),
                    if ([?p.activeIngredient, ?p.dose] case final line
                        when line.isNotEmpty)
                      Text(line.join(' · '), style: meta),
                    if (p.phiDays case final phi?)
                      Text(t.sprayPhiDays(formatInt(phi, lang)), style: meta),
                    for (final w in notes[i]) ...[
                      const SizedBox(height: BmSpace.xs),
                      Builder(
                        builder: (_) {
                          final (title, body) = warningText(t, w, lang);
                          return Column(
                            key: Key('spray-detail-note-$i-${w.kind.name}'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: BmType.label.copyWith(color: c.inkMuted),
                              ),
                              InfoNote(body),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
