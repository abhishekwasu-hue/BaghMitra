import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One A4 PDF whose pages are the given PNG images, edge to edge.
///
/// The pages are drawn by Flutter's own text engine (so Marathi / Hindi conjuncts are shaped
/// correctly) and only embedded here: the `pdf` package does not shape Devanagari reliably.
Future<Uint8List> pdfFromPngPages(List<Uint8List> pngPages) async {
  final doc = pw.Document(creator: 'BagMitra', producer: 'BagMitra');
  for (final png in pngPages) {
    final image = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }
  return doc.save();
}
