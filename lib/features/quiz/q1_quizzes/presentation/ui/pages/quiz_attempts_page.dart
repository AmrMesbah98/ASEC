/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_attempts_page.dart
/// Purpose: Declares `QuizAttemptsPage` — who has taken one quiz and how they
///          did.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/attempt_detail_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_meta.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class QuizAttemptsPage extends StatelessWidget {
  QuizAttemptsPage({super.key, required this.quiz});

  final Quiz quiz;
  final QuizBaseRepository _repository = QuizRepository();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(FormatHelper.capitalize(quiz.title), style: StyleText.fontSize18Weight600),
            Text(
              FormatHelper.capitalize(s.attemptsSub),
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<QuizAttempt>>(
        stream: _repository.watchAttemptsFor(quiz.id),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<QuizAttempt>> snapshot,
        ) {
          if (snapshot.hasError) {
            return AppErrorView(
              message: s.errUnknown,
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
          }
          if (!snapshot.hasData) return const AppLoading();

          final List<QuizAttempt> attempts = snapshot.data!;
          if (attempts.isEmpty) {
            return AppEmptyView(
              title: s.noAttemptsYet,
              subtitle: s.noAttemptsYetSub,
            );
          }

          final double average = attempts
                  .map((QuizAttempt a) => a.percent)
                  .fold<double>(0, (double sum, double p) => sum + p) /
              attempts.length;

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 16.h,
            ),
            itemCount: attempts.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return FadeSlideIn(child: AppCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _Stat(
                          label: s.attempts,
                          value: '${attempts.length}',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: s.average,
                          value: '${average.round()}%',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: s.pointsTotal('${quiz.totalPoints}'),
                          value: '${quiz.questionCount}',
                        ),
                      ),
                    ],
                  ),
                ));
              }
              final QuizAttempt attempt = attempts[index - 1];
              return FadeSlideIn(delay: staggerDelay(index, stepMs: 40), child: _AttemptRow(
                attempt: attempt,
                // The row answers "how did they do"; the page behind it
                // answers "what did they actually put".
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AttemptDetailPage(
                      quiz: quiz,
                      attempt: attempt,
                    ),
                  ),
                ),
              ));
            },
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(FormatHelper.capitalize(value), style: StyleText.fontSize20Weight600),
        SizedBox(height: 2.h),
        Text(
          FormatHelper.capitalize(label),
          textAlign: TextAlign.center,
          style: StyleText.fontSize12Weight400
              .copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt, this.onTap});

  final QuizAttempt attempt;
  final VoidCallback? onTap;

  /// Green at 80, amber at 50, red below — the same three bands the member's
  /// own result screen uses, so a score never changes colour between screens.
  static Color colorFor(double percent) {
    if (percent >= 80) return AppColors.green;
    if (percent >= 50) return AppColors.statusPending;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Color color = colorFor(attempt.percent);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AppCard(
        child: Row(
          children: <Widget>[
            AppAvatar(name: attempt.userName, size: 38),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    FormatHelper.capitalize(attempt.userName.isEmpty ? attempt.userId : attempt.userName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize14Weight600,
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _Meta(
                        icon: Icons.play_circle_outline_rounded,
                        text: AppDates.dateTime(context, attempt.startedAt),
                      ),
                      _Meta(
                        icon: Icons.done_all_rounded,
                        text: AppDates.dateTime(context, attempt.submittedAt),
                      ),
                      if (attempt.timeTaken != null)
                        _Meta(
                          icon: Icons.timer_outlined,
                          text: s.minutesSeconds(
                            '${attempt.timeTaken!.inMinutes}',
                            '${attempt.timeTaken!.inSeconds.remainder(60)}',
                          ),
                        ),
                      if (attempt.autoSubmitted)
                        QuizChip(
                          icon: Icons.timer_outlined,
                          label: s.autoSubmitted,
                          color: AppColors.statusPending,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize('${attempt.score}/${attempt.totalPoints}'),
                  style: StyleText.fontSize16Weight700.copyWith(color: color),
                ),
                Text(
                  FormatHelper.capitalize('${attempt.percent.round()}%'),
                  style: StyleText.fontSize12Weight500
                      .copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
            SizedBox(width: 4.w),
            AppIcon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: AppColors.secondaryText,
              semanticLabel: s.openAttempt,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small icon-and-text pair for the row's timing line.
class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIcon(icon, size: 12.sp, color: AppColors.secondaryText),
        SizedBox(width: 4.w),
        Text(
          FormatHelper.capitalize(text),
          style: StyleText.fontSize11Weight400
              .copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
