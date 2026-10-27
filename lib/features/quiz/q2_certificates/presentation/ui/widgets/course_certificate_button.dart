/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: course_certificate_button.dart
/// Purpose: Declares `CourseCertificateButton` — the "Certificate" button a
///          member ALWAYS sees inside a course. Earned (exam passed, or
///          issued by the admin) → opens the certificate. Not yet → locked;
///          tapping it opens the course's final exam page, which says what
///          is left to do.
/// Author: ASEC team
/// Created: 20/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q2_certificates/data/issued_certificates.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_page.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_quizzes_page.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/network/shared_stream.dart';

class CourseCertificateButton extends StatefulWidget {
  const CourseCertificateButton({super.key, required this.user, required this.course});

  final AppUser user;
  final String course;

  @override
  State<CourseCertificateButton> createState() => _CourseCertificateButtonState();
}

class _Earned {
  const _Earned({this.quiz, this.attempt, this.issued});

  final Quiz? quiz;
  final QuizAttempt? attempt;
  final IssuedCertificate? issued;

  bool get earned => issued != null || (quiz != null && attempt != null);
}

class _CourseCertificateButtonState extends State<CourseCertificateButton> {
  final QuizRepository _quizzes = QuizRepository();

  late final Stream<_Earned> _state = shared(() => combineLatest<Object, _Earned>(
    <Stream<Object>>[
      IssuedCertificates.watchFor(widget.user.uid),
      _quizzes.watchPublished().handleError((Object _) {}),
      _quizzes.watchMyAttempts(widget.user.uid).handleError((Object _) {}),
    ],
    (List<Object> v) {
      final String key = widget.course.trim().toLowerCase();
      IssuedCertificate? issued;
      for (final IssuedCertificate c in v[0] as List<IssuedCertificate>) {
        if (c.course.trim().toLowerCase() == key) issued = c;
      }
      Quiz? exam;
      for (final Quiz q in v[1] as List<Quiz>) {
        if (q.certificate && q.course.trim().toLowerCase() == key) exam = q;
      }
      QuizAttempt? passed;
      if (exam != null) {
        for (final QuizAttempt a in v[2] as List<QuizAttempt>) {
          if (a.quizId == exam.id && a.passed) passed = a;
        }
      }
      return _Earned(quiz: passed == null ? null : exam, attempt: passed, issued: issued);
    },
  ));

  void _open(_Earned e) {
    if (e.quiz != null && e.attempt != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => CertificatePage(quiz: e.quiz!, attempt: e.attempt!),
      ));
    } else if (e.issued != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => CertificatePage.of(data: e.issued!.data),
      ));
    } else {
      // Not earned yet: the exam page shows what is left (lessons, exam).
      PushedSectionPage.open(context, CertificateQuizzesPage(user: widget.user));
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<_Earned>(
      stream: _state,
      builder: (BuildContext context, AsyncSnapshot<_Earned> snap) {
        final _Earned e = snap.data ?? const _Earned();
        final bool earned = e.earned;
        final Color color = earned ? AppColors.green : AppColors.secondaryText;
        return Material(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: () => _open(e),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    earned ? Icons.workspace_premium_rounded : Icons.lock_rounded,
                    size: 18,
                    color: earned ? AppColors.green : AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      FormatHelper.capitalize(earned ? s.viewCertificate : s.certButtonLocked),
                      style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
