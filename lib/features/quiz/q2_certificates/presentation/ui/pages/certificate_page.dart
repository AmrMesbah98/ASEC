/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_page.dart
/// Purpose: Declares `CertificatePage` — a member's ASEC certificate for one
///          course, with "Download PDF".
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';
import 'package:asec/features/quiz/q2_certificates/data/certificate_pdf.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/widgets/certificate_view.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class CertificatePage extends StatefulWidget {
  const CertificatePage({super.key, required Quiz this.quiz, required QuizAttempt this.attempt})
      : data = null,
        sample = false;

  /// A certificate the admin issued by hand, or the admin's preview.
  const CertificatePage.of({super.key, required CertificateData this.data, this.sample = false})
      : quiz = null,
        attempt = null;

  final Quiz? quiz;
  final QuizAttempt? attempt;
  final CertificateData? data;

  /// The admin's preview: says so above the certificate.
  final bool sample;

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  late final CertificateData _data =
      widget.data ?? CertificateData.from(widget.quiz!, widget.attempt!);
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    final AppMessenger messenger = AppMessenger.of(context);
    final String failed = S.of(context).errUnknown;
    try {
      await CertificatePdf.share(_data);
    } catch (e) {
      messenger.show(AppMessage(content: Text(FormatHelper.capitalize(failed))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          FormatHelper.capitalize(widget.sample ? s.certPreview : s.certificateTitle),
          style: StyleText.fontSize18Weight600,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 20.h),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (widget.sample) ...<Widget>[
                  Text(
                    FormatHelper.capitalize(s.certPreviewNote),
                    textAlign: TextAlign.center,
                    style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
                  ),
                  SizedBox(height: 12.h),
                ],
                DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CertificateView(data: _data),
                ),
                SizedBox(height: 20.h),
                Center(
                  child: _busy
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : customButton(
                          title: s.downloadPdf,
                          function: _download,
                          wrapContent: true,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
