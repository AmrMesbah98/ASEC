/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_view.dart
/// Purpose: Declares `CertificateView` — the ASEC certificate on screen. Drawn
///          on a fixed A4-landscape canvas and scaled to fit, so it looks the
///          same on a phone and a desktop, and matches the PDF.
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:flutter/material.dart';

import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class CertificateView extends StatelessWidget {
  const CertificateView({super.key, required this.data});

  final CertificateData data;

  static const Color _navy = Color(0xFF1F2A6B);
  static const Color _blue = Color(0xFF3355D6);
  static const Color _red = Color(0xFFD6002A);
  static const Color _ink = Color(0xFF2B2F3A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFDF8);

  Widget _line(String text, double size,
      {Color color = _ink, bool bold = false, double spacing = 0}) {
    return Text(
      FormatHelper.capitalize(text),
      textAlign: TextAlign.center,
      textDirection: CertificateData.isArabic(text) ? TextDirection.rtl : TextDirection.ltr,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        letterSpacing: spacing,
        height: 1.35,
      ),
    );
  }

  /// ——— ◆ ——— under the title.
  Widget _ornament() => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(width: 90, height: 1.2, color: _red),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 8,
            height: 8,
            transform: Matrix4.rotationZ(0.785398),
            transformAlignment: Alignment.center,
            color: _red,
          ),
          Container(width: 90, height: 1.2, color: _red),
        ],
      );

  Widget _footer(String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _line(value, 13, color: _navy, bold: true),
          Container(width: 160, height: 1, color: _muted, margin: const EdgeInsets.symmetric(vertical: 4)),
          _line(label, 10, color: _muted),
          // 03/11/2026: English only — no Arabic line.
        ],
      );

  /// One box of the quiz data row: value over label.
  Widget _stat(String label, String value) => Container(
        width: 112,
        padding: const EdgeInsets.symmetric(vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: _navy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _line(value, 15, color: _navy, bold: true),
            _line(label, 10, color: _muted),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 842 / 595,
      child: FittedBox(
        child: SizedBox(
          width: 842,
          height: 595,
          child: Container(
            color: _paper,
            padding: const EdgeInsets.all(18),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: _navy, width: 5)),
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: _red, width: 1.2)),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                child: Column(
                  children: <Widget>[
                    // 03/11/2026: bigger text, spread down the page, with a
                    // divider, a recognition paragraph, a signature line and
                    // a verify line — no empty middle.
                    Image.asset('assets/certificate/asec_logo.png', width: 52, height: 56),
                    _line('ASEC', 14, color: _navy, bold: true, spacing: 6),
                    const SizedBox(height: 6),
                    _line('CERTIFICATE OF COMPLETION', 32, color: _navy, bold: true, spacing: 2),
                    const SizedBox(height: 4),
                    _ornament(),
                    const Spacer(),
                    _line('This is to certify that', 15, color: _muted),
                    const SizedBox(height: 2),
                    _line(data.name, 36, color: _blue, bold: true),
                    Container(width: 420, height: 1.4, color: _red, margin: const EdgeInsets.only(top: 2, bottom: 8)),
                    _line(data.completedLine, 15, color: _muted),
                    const SizedBox(height: 2),
                    _line(data.course, 26, color: _red, bold: true),
                    // Issued by the admin (no exam) → no score line.
                    if (data.percent != null) ...<Widget>[
                      const SizedBox(height: 4),
                      _line(data.scoreLine, 15),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 560,
                      child: _line(
                        'in recognition of the dedication, effort and engineering skills shown '
                        'throughout the program, delivered by ASEC Engineering Consultants.',
                        12,
                        color: _muted,
                      ),
                    ),
                    // The quiz's data (10/11/2026): score, correct answers,
                    // points, time taken and attempt.
                    if (data.hasDetails) ...<Widget>[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final (String label, String value) in data.details) _stat(label, value),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _footer('Date', data.dateLabel),
                        // The office stamp (03/11/2026), tilted a little like
                        // a real one.
                        Transform.rotate(
                          angle: -0.12,
                          child: Opacity(
                            opacity: 0.92,
                            child: Image.asset('assets/certificate/certificate_stamp.png', width: 104, height: 104),
                          ),
                        ),
                        // Eng. Ahmed Shuhayb's signature above the line.
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Image.asset('assets/certificate/certificate_signature.png', height: 50),
                            Container(width: 160, height: 1, color: _muted, margin: const EdgeInsets.symmetric(vertical: 4)),
                            _line('Eng. Ahmed Shuhayb', 12, color: _navy, bold: true),
                            _line('Authorized Signature', 10, color: _muted),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _line('Certificate No. ${data.number} · verify at asecbim.com', 10, color: _muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
