import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// What CIB&RC registered labels say for the plot's crop, grouped by target. Label
/// information only, never a recommendation: the banner stays pinned above the list, every
/// field is shown exactly as the API gives it and nothing is added by the app.
class LabelInfoScreen extends ConsumerWidget {
  const LabelInfoScreen({required this.plotId, super.key});

  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final crop = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull
        ?.crop;
    final cached = crop == null
        ? null
        : ref.watch(labelClaimsProvider(crop)).value;
    final claims = cached?.claims ?? const <LabelClaimOut>[];
    final byTarget = <String, List<LabelClaimOut>>{};
    for (final cl in claims) {
      (byTarget[cl.target] ??= []).add(cl);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.labelInfoTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BmSpace.lg,
              BmSpace.xs,
              BmSpace.lg,
              BmSpace.xs,
            ),
            child: DecoratedBox(
              key: const Key('label-banner'),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c.warnBg),
                border: Border.all(color: c.warnBorder, width: 1.5),
                borderRadius: BorderRadius.circular(BmRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(BmSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: c.warnTitle),
                    const SizedBox(width: BmSpace.sm),
                    Expanded(
                      child: Text(
                        t.labelInfoBanner,
                        style: BmType.bodyStrong.copyWith(color: c.warnBody),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                if (cached != null)
                  Text(
                    t.labelInfoUpdated(
                      formatDate(cached.savedAt.toLocal(), lang),
                    ),
                    style: BmType.meta,
                  ),
                if (claims.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: BmSpace.xl),
                    child: Text(t.labelInfoEmpty, style: BmType.body),
                  ),
                for (final MapEntry(key: target, value: group)
                    in byTarget.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: BmSpace.md,
                      bottom: BmSpace.xs,
                    ),
                    child: Text(
                      target,
                      style: BmType.section.copyWith(color: c.brand),
                    ),
                  ),
                  for (final cl in group) _ClaimCard(claim: cl, lang: lang),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.lang});

  final LabelClaimOut claim;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final meta = BmType.meta.copyWith(color: c.inkMuted);
    String n(int v) => formatInt(v, lang);
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: BmCard(
        elevated: false,
        radius: BmRadius.card,
        padding: const EdgeInsets.all(BmSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${claim.activeIngredient} ${claim.formulation}',
              style: BmType.bodyStrong.copyWith(color: c.ink),
            ),
            Wrap(
              spacing: BmSpace.xxs,
              children: [
                Text(t.labelInfoDose, style: meta),
                Text(claim.dose, style: BmType.body),
              ],
            ),
            if (claim.intervalDays != null)
              Text(t.labelInfoInterval(n(claim.intervalDays!)), style: meta),
            if (claim.phiDays != null)
              Text(t.labelInfoPhi(n(claim.phiDays!)), style: meta),
            if (claim.maxSprays != null)
              Text(t.labelInfoMaxSprays(n(claim.maxSprays!)), style: meta),
            Text(t.labelInfoCrop(claim.labelCrop), style: meta),
            Text(t.labelInfoSource(claim.sourceTitle), style: meta),
            SelectableText(claim.sourceUrl, style: meta),
          ],
        ),
      ),
    );
  }
}
