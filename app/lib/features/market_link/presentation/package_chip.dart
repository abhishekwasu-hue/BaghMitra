import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/package_status.dart';
import 'lot_widgets.dart';

/// "पॅकेज `date` पर्यंत चालू" / "पॅकेज चालू नाही" on a published lot, only while the season
/// package switch is ON (spec v1.5 §4E). Dates only: never a price, pay button or UPI text.
class PackageChip extends ConsumerWidget {
  const PackageChip(this.lotId, {super.key});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(packageStatusProvider).value;
    if (status == null || !status.switchOn) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final until = status.untilFor(lotId);
    final (label, fg, bg, icon) = until == null
        ? (
            t.mlPackageNotActive,
            c.inkMuted,
            c.card,
            Icons.remove_circle_outline,
          )
        : (
            t.mlPackageActiveUntil(formatDate(until.toLocal(), lang)),
            c.brandStrong,
            c.doneTint,
            Icons.verified_rounded,
          );
    return Container(
      key: Key('package-$lotId'),
      margin: const EdgeInsets.only(top: BmSpace.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: BmSpace.sm,
        vertical: BmSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: BmSpace.xxs),
          Flexible(
            child: Text(label, style: BmType.label.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

/// The lot's status chip, told whether the season package hides a published lot from
/// traders (switch ON and no active package for it): then it reads "not shown to traders
/// now" instead of "shown to traders". Unknown status (offline) keeps the plain chip.
class PackagedLotStatusChip extends ConsumerWidget {
  const PackagedLotStatusChip(
    this.lotId,
    this.status, {
    this.awaitingCheck = false,
    super.key,
  });
  final String lotId;
  final String status;
  final bool awaitingCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final package = ref.watch(packageStatusProvider).value;
    final hidden =
        status == 'published' &&
        package != null &&
        package.switchOn &&
        package.untilFor(lotId) == null;
    return LotStatusChip(
      status,
      awaitingCheck: awaitingCheck,
      hiddenByPackage: hidden,
    );
  }
}
