/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_pdf.dart
/// Purpose: Declares `CertificatePdf` — draws the ASEC certificate as an A4
///          landscape PDF and hands it to the system to save / share / print
///          (the `printing` package: a share sheet on phones and the Mac, a
///          download on the web).
/// Author: ASEC team
/// Created: 1/10/2026
///
/// The layout mirrors `CertificateView` (the on-screen certificate). Cairo is
/// used for every line because it has both Latin and Arabic letters, so an
/// Arabic name or course prints correctly.

import 'dart:typed_data';

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';

abstract final class CertificatePdf {
  static const PdfColor _navy = PdfColor.fromInt(0xFF1F2A6B);
  static const PdfColor _blue = PdfColor.fromInt(0xFF3355D6);
  static const PdfColor _red = PdfColor.fromInt(0xFFD6002A);
  static const PdfColor _ink = PdfColor.fromInt(0xFF2B2F3A);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _paper = PdfColor.fromInt(0xFFFFFDF8);

  static Future<Uint8List> build(CertificateData d) async {
    final pw.Font regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Regular.ttf'));
    final pw.Font bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Bold.ttf'));
    final pw.MemoryImage logo = pw.MemoryImage(
        (await rootBundle.load('assets/certificate/asec_logo.png')).buffer.asUint8List());
    final pw.MemoryImage stamp = pw.MemoryImage(
        (await rootBundle.load('assets/certificate/certificate_stamp.png')).buffer.asUint8List());
    final pw.MemoryImage signature = pw.MemoryImage(
        (await rootBundle.load('assets/certificate/certificate_signature.png')).buffer.asUint8List());

    final pw.Document doc = pw.Document(
      title: 'ASEC Certificate — ${d.course}',
      author: 'ASEC',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    pw.Widget line(String text, double size,
        {PdfColor color = _ink, bool isBold = false, double spacing = 0}) {
      final bool ar = CertificateData.isArabic(text);
      // Same wording rule as the app (03/11/2026): Title Case, with small
      // words (of, in, for, on…) kept small — the PDF matches the screen.
      return pw.Text(
        FormatHelper.capitalize(text),
        textAlign: pw.TextAlign.center,
        textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        style: pw.TextStyle(
          fontSize: size,
          color: color,
          font: isBold ? bold : regular,
          letterSpacing: spacing,
        ),
      );
    }

    pw.Widget footerItem(String label, String value) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: <pw.Widget>[
            line(value, 12, color: _navy, isBold: true),
            pw.Container(width: 150, height: 0.8, color: _muted, margin: const pw.EdgeInsets.symmetric(vertical: 4)),
            line(label, 9, color: _muted),
            // 03/11/2026: English only — no Arabic line.
          ],
        );

    pw.Widget stat(String label, String value) => pw.Container(
          width: 108,
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          margin: const pw.EdgeInsets.symmetric(horizontal: 5),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF0F1F7),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: <pw.Widget>[
              line(value, 14, color: _navy, isBold: true),
              line(label, 9, color: _muted),
            ],
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) => pw.Container(
          color: _paper,
          padding: const pw.EdgeInsets.all(18),
          child: pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _navy, width: 5)),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _red, width: 1.2)),
              padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 22),
              child: pw.Column(
                children: <pw.Widget>[
                  // 03/11/2026: same layout as the screen — no empty middle.
                  pw.Image(logo, width: 52, height: 56),
                  pw.SizedBox(height: 4),
                  line('ASEC', 13, color: _navy, isBold: true, spacing: 6),
                  pw.SizedBox(height: 6),
                  line('CERTIFICATE OF COMPLETION', 30, color: _navy, isBold: true, spacing: 2),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: <pw.Widget>[
                      pw.Container(width: 90, height: 1.2, color: _red),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                        child: pw.Transform.rotateBox(
                          angle: 0.785398,
                          child: pw.Container(width: 7, height: 7, color: _red),
                        ),
                      ),
                      pw.Container(width: 90, height: 1.2, color: _red),
                    ],
                  ),
                  pw.Spacer(),
                  line('This is to certify that', 14, color: _muted),
                  pw.SizedBox(height: 2),
                  line(d.name, 34, color: _blue, isBold: true),
                  pw.Container(width: 420, height: 1.2, color: _red, margin: const pw.EdgeInsets.only(top: 2, bottom: 8)),
                  line(d.completedLine, 14, color: _muted),
                  pw.SizedBox(height: 2),
                  line(d.course, 24, color: _red, isBold: true),
                  if (d.percent != null) ...<pw.Widget>[
                    pw.SizedBox(height: 4),
                    line(d.scoreLine, 14, color: _ink),
                  ],
                  pw.SizedBox(height: 12),
                  pw.SizedBox(
                    width: 560,
                    child: line(
                      'in recognition of the dedication, effort and engineering skills shown '
                      'throughout the program, delivered by ASEC Engineering Consultants.',
                      11,
                      color: _muted,
                    ),
                  ),
                  if (d.hasDetails) ...<pw.Widget>[
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: <pw.Widget>[
                        for (final (String label, String value) in d.details) stat(label, value),
                      ],
                    ),
                  ],
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: <pw.Widget>[
                      footerItem('Date', d.dateLabel),
                      // The office stamp, tilted a little like a real one.
                      pw.Transform.rotateBox(
                        angle: 0.12,
                        child: pw.Opacity(
                          opacity: 0.92,
                          child: pw.Image(stamp, width: 100, height: 100),
                        ),
                      ),
                      // Eng. Ahmed Shuhayb's signature above the line.
                      pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: <pw.Widget>[
                          pw.Image(signature, height: 48),
                          pw.Container(width: 150, height: 0.8, color: _muted, margin: const pw.EdgeInsets.symmetric(vertical: 4)),
                          line('Eng. Ahmed Shuhayb', 11, color: _navy, isBold: true),
                          line('Authorized Signature', 9, color: _muted),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  line('Certificate No. ${d.number} · verify at asecbim.com', 9, color: _muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return doc.save();
  }

  /// Builds the PDF and opens the system's save / share sheet.
  static Future<void> share(CertificateData d) async {
    final Uint8List bytes = await build(d);
    await Printing.sharePdf(bytes: bytes, filename: d.fileName);
  }
}
