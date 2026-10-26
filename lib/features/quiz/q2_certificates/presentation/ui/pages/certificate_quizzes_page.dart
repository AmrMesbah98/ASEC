/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_quizzes_page.dart
/// Purpose: Declares `CertificateQuizzesPage` — the member's "Certificate
///          quiz" tab: one card per course with its final exam.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// A COURSE IS A VIDEO CATEGORY (a Drive sub-folder). Its final exam is the
/// published certificate quiz whose `course` names it. The exam:
///   * stays LOCKED until every lesson of the course is watched to the end
///     (watch progress is kept on this device — VideoWatchStore);
///   * may be retaken until the member scores 70% or more;
///   * once passed, opens the member's ASEC certificate.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_attempt_page.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_page.dart';
import 'package:asec/features/quiz/q2_certificates/data/issued_certificates.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/features/video/v1_videos/presentation/controller/member_videos.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

enum _ExamStatus { noExam, locked, ready, failed, passed }

class _Feed {
  const _Feed(this.videos, this.quizzes, this.attempts, this.issued);

  final List<VideoItem> videos;
  final List<Quiz> quizzes;
  final Map<String, QuizAttempt> attempts;

  /// lower-cased course → the certificate the admin issued by hand.
  final Map<String, IssuedCertificate> issued;
}

class CertificateQuizzesPage extends StatefulWidget {
  const CertificateQuizzesPage({super.key, required this.user});

  final AppUser user;

  @override
  State<CertificateQuizzesPage> createState() => _CertificateQuizzesPageState();
}

class _CertificateQuizzesPageState extends State<CertificateQuizzesPage> {
  final QuizRepository _quizzes = QuizRepository();

  late final Stream<_Feed> _feed = combineLatest<Object, _Feed>(
    <Stream<Object>>[
      MemberVideos.watch(),
      _quizzes.watchPublished(),
      _quizzes.watchMyAttempts(widget.user.uid),
      IssuedCertificates.watchFor(widget.user.uid),
    ],
    (List<Object> v) => _Feed(
      v[0] as List<VideoItem>,
      v[1] as List<Quiz>,
      <String, QuizAttempt>{
        for (final QuizAttempt a in v[2] as List<QuizAttempt>) a.quizId: a,
      },
      <String, IssuedCertificate>{
        for (final IssuedCertificate c in v[3] as List<IssuedCertificate>)
          c.course.trim().toLowerCase(): c,
      },
    ),
  );

  /// Watch progress lives on the device, not in Firestore, so nothing
  /// streams when a lesson is finished in the Videos tab — re-read it now
  /// and then while this tab is alive.
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _open(_CourseExam exam) async {
    final S s = S.of(context);
    switch (exam.status) {
      case _ExamStatus.noExam:
        return;
      case _ExamStatus.locked:
        AppMessenger.of(context)
          ..hide()
          ..show(AppMessage(content: Text(FormatHelper.capitalize(s.certLockedSnack))));
        return;
      case _ExamStatus.ready:
      case _ExamStatus.failed:
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => QuizAttemptPage(quiz: exam.quiz!, user: widget.user),
        ));
      case _ExamStatus.passed:
        final bool byExam =
            exam.quiz != null && exam.attempt != null && exam.attempt!.passed;
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => byExam
              ? CertificatePage(quiz: exam.quiz!, attempt: exam.attempt!)
              : CertificatePage.of(data: exam.issued!.data),
        ));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<_Feed>(
        stream: _feed,
        builder: (BuildContext context, AsyncSnapshot<_Feed> snapshot) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown, error: snapshot.error, stackTrace: snapshot.stackTrace);
          if (!snapshot.hasData) return const AppLoading();
          final _Feed feed = snapshot.data!;

          final List<VideoItem> videos = feed.videos
              .where((VideoItem v) => v.hasFile && widget.user.canSeeCourse(v.category))
              .toList()
            ..sort((VideoItem a, VideoItem b) => (a.createdAt ?? DateTime(0))
                .compareTo(b.createdAt ?? DateTime(0)));
          final List<Quiz> exams = feed.quizzes
              .where((Quiz q) => q.certificate && q.questionCount > 0)
              .toList();

          final List<_CourseExam> rows = <_CourseExam>[
            for (final VideoCategory c in VideoCategory.group(videos))
              if (c.name.isNotEmpty)
                _CourseExam.of(
                  c,
                  _examFor(exams, c.name),
                  feed.attempts,
                  feed.issued[c.name.trim().toLowerCase()],
                ),
          ];

          if (rows.isEmpty) {
            return ConsolePage(
              title: s.certificateQuiz,
              subtitle: s.certificateQuizzesUserSub,
              child: AppEmptyView(title: s.noCoursesTitle, subtitle: s.noCoursesUserSub),
            );
          }

          return ConsolePage(
            title: s.certificateQuiz,
            subtitle: s.certificateQuizzesUserSub,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GridView.builder(
                  padding: EdgeInsets.only(bottom: 24.h),
                  gridDelegate: CrossAxisCountHelper.gridDelegate(
                    context,
                    mainAxisExtent: 158,
                    minCellWidth: 320,
                    availableWidth: constraints.maxWidth,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (BuildContext context, int index) => FadeSlideIn(
                    delay: staggerDelay(index, stepMs: 55),
                    child: HoverLift(
                      child: _ExamCard(exam: rows[index], onTap: () => _open(rows[index])),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static Quiz? _examFor(List<Quiz> exams, String course) {
    final String key = course.trim().toLowerCase();
    for (final Quiz q in exams) {
      if (q.course.trim().toLowerCase() == key) return q;
    }
    return null;
  }
}

class _CourseExam {
  const _CourseExam({
    required this.category,
    required this.quiz,
    required this.attempt,
    required this.watched,
    required this.status,
    this.issued,
  });

  factory _CourseExam.of(
    VideoCategory category,
    Quiz? quiz,
    Map<String, QuizAttempt> attempts, [
    IssuedCertificate? issued,
  ]) {
    final int watched = category.watched;
    final QuizAttempt? attempt = quiz == null ? null : attempts[quiz.id];
    final _ExamStatus status;
    if (issued != null && !(attempt?.passed ?? false)) {
      // Issued by the admin by hand: a certificate without the exam.
      status = _ExamStatus.passed;
    } else if (quiz == null) {
      status = _ExamStatus.noExam;
    } else if (attempt != null && attempt.passed) {
      // A pass stays a pass, even on a device that has not watched the
      // lessons.
      status = _ExamStatus.passed;
    } else if (watched < category.videos.length) {
      status = _ExamStatus.locked;
    } else if (attempt != null) {
      status = _ExamStatus.failed;
    } else {
      status = _ExamStatus.ready;
    }
    return _CourseExam(
      category: category,
      quiz: quiz,
      attempt: attempt,
      watched: watched,
      status: status,
      issued: issued,
    );
  }

  final VideoCategory category;
  final Quiz? quiz;
  final QuizAttempt? attempt;
  final int watched;
  final _ExamStatus status;
  final IssuedCertificate? issued;

  int get total => category.videos.length;
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onTap});

  final _CourseExam exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final String percent = exam.attempt == null ? '' : '${exam.attempt!.percent.round()}';

    final (IconData icon, Color color, String label) = switch (exam.status) {
      _ExamStatus.noExam => (Icons.hourglass_empty_rounded, AppColors.secondaryText, s.certNoExam),
      _ExamStatus.locked => (Icons.lock_rounded, AppColors.secondaryText, s.certLocked(exam.watched, exam.total)),
      _ExamStatus.ready => (Icons.play_circle_fill_rounded, AppColors.primary, s.certReady),
      _ExamStatus.failed => (Icons.refresh_rounded, AppColors.red, s.certFailed(percent)),
      _ExamStatus.passed => (
          Icons.workspace_premium_rounded,
          AppColors.green,
          percent.isEmpty || !(exam.attempt?.passed ?? false) ? s.certIssued : s.certPassed(percent),
        ),
    };
    final double progress = exam.total == 0 ? 0 : exam.watched / exam.total;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      exam.status == _ExamStatus.passed
                          ? Icons.workspace_premium_rounded
                          : Icons.school_rounded,
                      color: exam.status == _ExamStatus.passed ? AppColors.green : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          FormatHelper.capitalize(exam.category.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
                        ),
                        Text(
                          FormatHelper.capitalize(exam.quiz?.title ?? s.videoCount(exam.total)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  if (exam.status == _ExamStatus.passed)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        FormatHelper.capitalize(s.certificateBadge),
                        style: StyleText.fontSize11Weight700.copyWith(color: AppColors.green),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6.h,
                        backgroundColor: AppColors.secondaryText.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1 ? AppColors.green : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    FormatHelper.capitalize('${exam.watched}/${exam.total}'),
                    style: StyleText.fontSize12Weight600.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: color),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      FormatHelper.capitalize(label),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize13Weight600.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
