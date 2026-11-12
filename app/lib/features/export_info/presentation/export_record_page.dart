import 'package:flutter/material.dart';

import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../export/presentation/report_page.dart' show reportPageSize;
import '../domain/export_record.dart';

/// Rows that fit on a page: the first page also holds the heading.
const exportRecordFirstRows = 16;
const exportRecordOtherRows = 22;

/// One printed line, already in the grower's language.
typedef ExportRecordLine = ({
  String date,
  String product,
  String label,
  LabelStatus status,
  String phiEnd,
});

/// Everything one page of the export record says, already in the grower's language.
class ExportRecordContent {
  const ExportRecordContent({
    required this.title,
    required this.heading,
    required this.columns,
    required this.lines,
    required this.made,
    required this.footer,
    required this.pageLabel,
    this.empty,
  });

  final String title;

  /// (label, value): plot · crop, bahar; only on the first page.
  final List<(String, String)>? heading;

  /// Date, product, label check, PHI end.
  final (String, String, String, String) columns;
  final List<ExportRecordLine> lines;

  /// Shown when the record has no sprays.
  final String? empty;
  final String made;

  /// "Information record, not a certificate."
  final String footer;
  final String pageLabel;
}

/// A printed page of the export record: plain widgets on a fixed A4 canvas, like the
/// accounts report, drawn by Flutter's text engine so Marathi is shaped by the app's fonts.
class ExportRecordPage extends StatelessWidget {
  const ExportRecordPage(this.content, {super.key});

  final ExportRecordContent content;

  @override
  Widget build(BuildContext context) {
    const c = BmColors.light;
    final body = TextStyle(
      fontFamily: BmFonts.body,
      fontSize: 11,
      color: c.ink,
      height: 1.3,
    );
    final strong = body.copyWith(fontWeight: FontWeight.w700);
    final muted = body.copyWith(color: c.inkMuted);
    final k = content;
    // Owner 2026-11-10: out-of-list rows are calm, muted text.
    Color tone(LabelStatus s) => s == LabelStatus.listed ? c.brand : c.inkMuted;
    Widget row(
      String a,
      String b,
      String d,
      String e, {
      TextStyle? style,
      Color? labelColor,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 78, child: Text(a, style: style ?? body)),
          Expanded(child: Text(b, style: style ?? body)),
          SizedBox(
            width: 120,
            child: Text(d, style: (style ?? body).copyWith(color: labelColor)),
          ),
          SizedBox(
            width: 78,
            child: Text(e, style: style ?? body, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.fromSize(
        size: reportPageSize,
        child: ColoredBox(
          color: c.card,
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (k.heading case final heading?) ...[
                  Text(
                    k.title,
                    style: TextStyle(
                      fontFamily: BmFonts.display,
                      fontSize: 20,
                      color: c.brand,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final (label, value) in heading)
                    Text('$label: $value', style: body),
                  const SizedBox(height: 12),
                ],
                row(
                  k.columns.$1,
                  k.columns.$2,
                  k.columns.$3,
                  k.columns.$4,
                  style: strong,
                ),
                Divider(height: 8, color: c.line),
                for (final l in k.lines)
                  row(
                    l.date,
                    l.product,
                    l.label,
                    l.phiEnd,
                    labelColor: tone(l.status),
                  ),
                if (k.empty case final e? when k.lines.isEmpty)
                  Text(e, style: muted),
                const Spacer(),
                Text(k.made, style: muted),
                Text(k.footer, style: strong),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('BagMitra · ${k.pageLabel}', style: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String labelStatusText(AppLocalizations t, LabelStatus s) => switch (s) {
  LabelStatus.listed => t.exportLabelListed,
  LabelStatus.check => t.exportLabelCheck,
  LabelStatus.banned => t.sprayWarnBannedTitle,
  LabelStatus.restricted => t.sprayWarnRestrictedTitle,
};

/// The export record's printed pages for [rows], in the grower's language.
List<ExportRecordContent> exportRecordPages({
  required AppLocalizations t,
  required String lang,
  required List<(String, String)> heading,
  required List<ExportRecordRow> rows,
  required DateTime made,
}) {
  final pages = paginate(
    rows,
    first: exportRecordFirstRows,
    other: exportRecordOtherRows,
    // A mix prints its "Mix:" line and a line per product.
    weight: (r) => r.isMix ? r.products.length + 1 : 1,
  );
  return [
    for (var i = 0; i < pages.length; i++)
      ExportRecordContent(
        title: t.exportRecordTitle,
        heading: i == 0 ? heading : null,
        columns: (
          t.exportRecordDate,
          t.exportRecordProduct,
          t.exportRecordLabel,
          t.exportRecordPhiEnd,
        ),
        lines: [
          for (final r in pages[i])
            (
              date: formatDate(r.sprayedOn, lang),
              product: r.isMix
                  ? [
                      t.sprayMixHeading,
                      for (final p in r.products)
                        [
                          p.productName,
                          ?p.activeIngredient,
                          ?p.dose,
                        ].join(' · '),
                    ].join('\n')
                  : [r.product, ?r.activeIngredient, ?r.dose].join(' · '),
              label: labelStatusText(t, r.status),
              status: r.status,
              phiEnd: r.phiEnd == null ? '–' : formatDate(r.phiEnd!, lang),
            ),
        ],
        empty: t.exportRecordEmpty,
        made: t.exportRecordMade(formatDate(made, lang)),
        footer: t.exportRecordFooter,
        pageLabel:
            '${formatInt(i + 1, lang)} / ${formatInt(pages.length, lang)}',
      ),
  ];
}
