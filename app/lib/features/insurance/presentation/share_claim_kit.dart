import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../export/presentation/report_page.dart';
import '../data/claim_pdf.dart';
import '../domain/claim_kit.dart';
import 'claim_report_page.dart';
import 'insurance_screens.dart';

String claimChecklistLabel(AppLocalizations t, String key) => switch (key) {
  'inform_72h' => t.claimCheckInform72h,
  'photos' => t.claimCheckPhotos,
  'panchnama' => t.claimCheckPanchnama,
  'policy_copy' => t.claimCheckPolicyCopy,
  'acknowledgement' => t.claimCheckAcknowledgement,
  _ => t.claimCheckKeepFruit,
};

/// Reads a provider (a widget's `ref.read` or a container's `read`).
typedef ProviderRead = T Function<T>(ProviderListenable<T> provider);

/// The first PDF page's content for [kit], in the grower's language: plot, plot GPS, date
/// of loss, recorded policies, note, checklist and the photo stamps. Only what the grower
/// entered; no amounts or rules are added.
Future<ClaimReportContent> claimReportContent(
  ProviderRead read,
  AppLocalizations t,
  String lang,
  ClaimKit kit,
) async {
  final plots = await read(plotRepositoryProvider).watchAll().first;
  final plot = plots.where((p) => p.id == kit.plotId).firstOrNull;
  final crops = await read(cropsProvider.future);
  final crop = [
    for (final k in crops)
      if (k.slug == plot?.crop) k.label(lang),
  ].firstOrNull;
  final policies = await read(insuranceRepositoryProvider)
      .watchForPlot(kit.plotId)
      .first;
  final gps = plot?.centroidLat != null && plot?.centroidLon != null
      ? '${plot!.centroidLat!.toStringAsFixed(5)}, '
            '${plot.centroidLon!.toStringAsFixed(5)}'
      : t.claimPdfNoGps;
  return ClaimReportContent(
    title: t.claimPdfTitle,
    rows: [
      (t.claimKitPlot, [plot?.name ?? kit.plotId, ?crop].join(' · ')),
      (t.claimPdfPlotGps, gps),
      (t.claimKitDate, formatDate(kit.lossOn, lang)),
      for (final p in policies) (t.claimPdfPolicy, policySummary(t, p, lang)),
    ],
    noteTitle: t.claimPdfNote,
    note: kit.note,
    checklistTitle: t.claimKitChecklist,
    checklist: [
      for (final k in claimChecklist)
        (
          claimChecklistLabel(t, k),
          kit.done.contains(k) ? t.claimPdfDone : t.claimPdfNotDone,
        ),
    ],
    photosTitle: t.claimPdfPhotos,
    photoStamps: [for (final p in kit.photos) p.stamp(noGps: t.claimKitNoGps)],
    checkPolicy: t.claimKitCheckPolicy,
    footer: t.claimPdfMade(formatDate(read(clockProvider)(), lang)),
  );
}

/// Builds the claim kit PDF (summary page + one page per photo) and opens the share sheet.
/// Everything is read from this phone, so it works offline.
Future<void> shareClaimKit(
  BuildContext context,
  WidgetRef ref,
  ClaimKit kit,
) async {
  final t = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final view = View.of(context);
  final content = await claimReportContent(ref.read, t, lang, kit);
  final summary = await renderWidgetToPng(
    ClaimReportPage(content),
    view: view,
    size: reportPageSize,
  );
  final read = ref.read(claimPhotoBytesProvider);
  final photos = <ClaimPdfPhoto>[];
  for (final p in kit.photos) {
    final bytes = await read(p.path);
    if (bytes != null) {
      photos.add((bytes: bytes, caption: p.stamp(noGps: 'no GPS')));
    }
  }
  final d = kit.lossOn;
  final day =
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  await ref
      .read(fileSharerProvider)
      .share(
        fileName: 'bagmitra-claim-${kit.plotId}-$day.pdf',
        bytes: await claimKitPdf(summaryPng: summary, photos: photos),
        mimeType: 'application/pdf',
      );
}
