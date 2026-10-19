import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/formatting.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../domain/accounts_csv.dart';

/// A4 in logical points (1 pt = 1/72 in), the size every report page is laid out at.
const reportPageSize = Size(595, 842);

/// Rows that fit on a report page, first page (title + summary) and the others.
const reportFirstPageRows = 18;
const reportOtherPageRows = 30;

/// One printed page of the accounts report. Plain widgets on a fixed A4 canvas so the same
/// layout renders identically on every phone (and in golden tests).
class ReportPage extends StatelessWidget {
  const ReportPage({
    required this.title,
    required this.lang,
    required this.labels,
    required this.lines,
    required this.pageLabel,
    this.summary,
    super.key,
  });

  final String title;
  final String lang;
  final ExportLabels labels;
  final List<LedgerLine> lines;

  /// "1 / 3"; shown bottom right.
  final String pageLabel;

  /// Summary rows (label, paise); only on the first page.
  final List<(String, int)>? summary;

  @override
  Widget build(BuildContext context) {
    const c = BmColors.light;
    final body = TextStyle(
      fontFamily: BmFonts.body,
      fontSize: 11,
      color: c.ink,
      height: 1.3,
    );
    // formatPaise puts the sign inside the symbol ("₹-400"); a printed report reads "−₹400".
    String money(int paise) =>
        paise < 0 ? '−${formatPaise(-paise, lang)}' : formatPaise(paise, lang);
    final strong = body.copyWith(fontWeight: FontWeight.w700);
    final muted = body.copyWith(color: c.inkMuted);
    Widget cells(
      String date,
      String type,
      String details,
      String amount, {
      TextStyle? style,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 78, child: Text(date, style: style ?? body)),
          SizedBox(width: 92, child: Text(type, style: style ?? body)),
          Expanded(
            child: Text(
              details,
              style: style ?? body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              amount,
              style: style ?? body,
              textAlign: TextAlign.right,
            ),
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
                if (summary != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: BmFonts.display,
                      fontSize: 20,
                      color: c.brand,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final (label, paise) in summary!)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(label, style: body)),
                          Text(money(paise), style: strong),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                cells(
                  labels.date,
                  labels.type,
                  labels.details,
                  labels.amount,
                  style: strong,
                ),
                Divider(height: 8, color: c.line),
                for (final l in lines)
                  cells(
                    formatDate(l.date, lang),
                    l.type,
                    l.details,
                    money(l.paise),
                  ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('BagMitra · $pageLabel', style: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws [widget] off screen at [size] logical pixels and returns it as PNG bytes, without
/// putting anything on the user's screen. [view] supplies the display it is rendered for.
Future<Uint8List> renderWidgetToPng(
  Widget widget, {
  required ui.FlutterView view,
  required Size size,
  double pixelRatio = 2,
}) async {
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
    ),
    child: RenderPositionedBox(child: boundary),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: widget,
    ),
  ).attachToRenderTree(buildOwner);
  buildOwner
    ..buildScope(root)
    ..finalizeTree();
  pipeline
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
