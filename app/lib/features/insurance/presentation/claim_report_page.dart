import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../export/presentation/report_page.dart' show reportPageSize;

/// Everything the claim PDF's first page says, already in the grower's language.
class ClaimReportContent {
  const ClaimReportContent({
    required this.title,
    required this.rows,
    required this.checklistTitle,
    required this.checklist,
    required this.photosTitle,
    required this.photoStamps,
    required this.checkPolicy,
    required this.footer,
    this.noteTitle,
    this.note,
  });

  final String title;

  /// (label, value) lines: plot, plot GPS, date of loss, insurance.
  final List<(String, String)> rows;
  final String? noteTitle;
  final String? note;
  final String checklistTitle;

  /// (item, status) lines.
  final List<(String, String)> checklist;
  final String photosTitle;
  final List<String> photoStamps;
  final String checkPolicy;
  final String footer;
}

/// The printed summary page of a claim kit. Plain widgets on a fixed A4 canvas, like the
/// accounts report, so it renders the same on every phone and in golden tests.
class ClaimReportPage extends StatelessWidget {
  const ClaimReportPage(this.content, {super.key});

  final ClaimReportContent content;

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
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(text, style: strong.copyWith(color: c.brand, fontSize: 13)),
    );
    Widget pair(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: muted)),
          Expanded(child: Text(value, style: strong)),
        ],
      ),
    );
    final x = content;
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
                Text(
                  x.title,
                  style: TextStyle(
                    fontFamily: BmFonts.display,
                    fontSize: 20,
                    color: c.brand,
                  ),
                ),
                const SizedBox(height: 8),
                for (final (label, value) in x.rows) pair(label, value),
                if (x.note case final note?) ...[
                  heading(x.noteTitle ?? ''),
                  Text(note, style: body, maxLines: 6),
                ],
                heading(x.checklistTitle),
                for (final (item, status) in x.checklist)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(item, style: body)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            status,
                            style: strong,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                heading(x.photosTitle),
                for (final (i, stamp) in x.photoStamps.take(12).indexed)
                  Text('${i + 1}. $stamp', style: body),
                const Spacer(),
                Text(x.checkPolicy, style: strong),
                const SizedBox(height: 4),
                Text(x.footer, style: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
