import 'dart:typed_data';
import 'dart:ui' as ui show FlutterView, Image, instantiateImageCodec;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../core/formatting.dart';
import '../features/export/data/pdf_builder.dart';
import '../features/export/presentation/report_page.dart'
    show renderWidgetToPng, reportPageSize;
import '../theme/app_theme.dart';
import 'package_strings.dart';

/// Saves a file in the admin's browser (a download); tests pass a fake.
typedef SaveFile = Future<void> Function(String name, Uint8List bytes);

Future<void> savePdf(String name, Uint8List bytes) async {
  await FilePicker.saveFile(
    fileName: name,
    bytes: bytes,
    mimeType: 'application/pdf',
  );
}

String _d(DateTime d) => d.toIso8601String().substring(0, 10);

/// One A4 page drawn by Flutter (Devanagari names shape correctly) and put in a PDF, like
/// the accounts report (`pdfFromPngPages`).
Future<Uint8List> printPage(Widget page, ui.FlutterView view) async =>
    pdfFromPngPages([
      await renderWidgetToPng(
        Directionality(textDirection: TextDirection.ltr, child: page),
        view: view,
        size: reportPageSize,
      ),
    ]);

/// Decodes an image before an off-screen page draws it (no frame waits for it there).
Future<ui.Image> decodeImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

TextStyle _text({double size = 12, bool bold = false, Color? colour}) =>
    TextStyle(
      fontFamily: BmFonts.body,
      fontSize: size,
      height: 1.35,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: colour ?? BmColors.light.ink,
    );

/// The package receipt (spec v1.5 §4E): company profile, receipt number, grower, amount,
/// GST line only when the server sends one (GSTIN and rate set), payment reference and
/// validity. Admin web only.
class ReceiptSheet extends StatelessWidget {
  const ReceiptSheet(this.r, this.s, {super.key});
  final ReceiptOut r;
  final PackageStrings s;

  @override
  Widget build(BuildContext context) {
    const c = BmColors.light;
    String money(int paise) => formatPaise(paise, 'en');
    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: _text(colour: c.inkMuted)),
          ),
          Expanded(
            child: Text(value, style: _text(bold: bold)),
          ),
        ],
      ),
    );
    final gst = r.gst;
    return Container(
      color: BmPalette.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.legalName, style: _text(size: 18, bold: true)),
          if (r.tradeName case final t?) Text(t, style: _text()),
          Text(r.address, style: _text(colour: c.inkMuted)),
          if (r.gstin case final g?) Text('GSTIN $g', style: _text()),
          if (r.pan case final p?) Text('PAN $p', style: _text()),
          const SizedBox(height: 16),
          Container(height: 2, color: c.brand),
          const SizedBox(height: 16),
          Text(s['receipt_title'], style: _text(size: 16, bold: true)),
          if (r.revoked)
            Text(s['revoked'], style: _text(bold: true, colour: c.danger)),
          const SizedBox(height: 8),
          row(s['receipt_no'], r.receiptNo, bold: true),
          row(s['issued_on'], _d(r.issuedOn)),
          row(s['received_from'], [?r.growerName, ?r.growerPhone].join(' · ')),
          row(s['for'], '${s['service']} · ${r.lot ?? s['all_lots']}'),
          row(s['method'], s[r.method]),
          row(s['payment_ref'], r.paymentRef),
          row(s['paid_on'], _d(r.paidOn)),
          row(s['validity'], '${_d(r.validFrom)} – ${_d(r.validUntil)}'),
          const SizedBox(height: 12),
          Container(height: 1, color: c.line),
          if (gst != null) ...[
            row(s['taxable'], money(gst.taxablePaise)),
            row(s.fill('gst_line', gst.ratePercent), money(gst.gstPaise)),
          ],
          row(s['total'], money(r.amountPaise), bold: true),
        ],
      ),
    );
  }
}

/// The representatives' printed card (admin web only, never an app screen): company name,
/// UPI ID and the bank's merchant QR image.
class QrCardSheet extends StatelessWidget {
  const QrCardSheet({
    required this.company,
    required this.qr,
    required this.s,
    super.key,
  });
  final PackageCompanyOut company;

  /// The merchant QR, decoded ([decodeImage]).
  final ui.Image qr;
  final PackageStrings s;

  @override
  Widget build(BuildContext context) {
    const c = BmColors.light;
    return Container(
      color: BmPalette.white,
      padding: const EdgeInsets.all(48),
      alignment: Alignment.topCenter,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: c.brand, width: 2),
          borderRadius: BorderRadius.circular(BmRadius.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              company.tradeName ?? company.legalName ?? '',
              textAlign: TextAlign.center,
              style: _text(size: 20, bold: true, colour: c.brand),
            ),
            if (company.tradeName != null && company.legalName != null)
              Text(company.legalName!, style: _text(colour: c.inkMuted)),
            const SizedBox(height: 16),
            RawImage(image: qr, width: 280, height: 280, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text(
              'UPI ID: ${company.upiId ?? ''}',
              style: _text(size: 16, bold: true),
            ),
            const SizedBox(height: 4),
            Text(s['qr_scan'], style: _text(colour: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}
