import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One loss photo for the PDF: the kept image file's bytes and its stamp line.
typedef ClaimPdfPhoto = ({Uint8List bytes, String caption});

/// The claim kit as one A4 PDF: the summary page (drawn by Flutter so Marathi / Hindi are
/// shaped correctly, passed in as PNG) and then one page per photo, embedded as is (JPEG
/// stays small) with its stamp underneath. Captions are Latin-only (date, GPS, numbers)
/// because the built-in PDF font cannot shape Devanagari. A photo that cannot be read is
/// left out rather than failing the whole PDF.
Future<Uint8List> claimKitPdf({
  required Uint8List summaryPng,
  required List<ClaimPdfPhoto> photos,
}) async {
  final doc = pw.Document(creator: 'BagMitra', producer: 'BagMitra');
  final summary = pw.MemoryImage(summaryPng);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(summary, fit: pw.BoxFit.fill),
    ),
  );
  for (final (i, photo) in photos.indexed) {
    final pw.ImageProvider image;
    try {
      image = pw.MemoryImage(photo.bytes);
    } on Object {
      continue;
    }
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: pw.Center(child: pw.Image(image))),
            pw.SizedBox(height: 12),
            pw.Text(
              'Photo ${i + 1} / ${photos.length} - ${photo.caption}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
  return doc.save();
}
