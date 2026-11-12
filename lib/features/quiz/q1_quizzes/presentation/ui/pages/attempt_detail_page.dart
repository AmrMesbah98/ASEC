/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: attempt_detail_page.dart
/// Purpose: Declares `AttemptDetailPage` — one member's sitting in full: who
///          they are, when they started and finished, and every answer they
///          gave against the right one.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:flutter/material.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_integrity_event.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_text_direction.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_meta.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_result_export.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// THE MARKING IS RE-RUN HERE, NOT READ OFF THE ATTEMPT.
///
/// The score stored on the attempt was computed on the member's device, so the
/// admin's view marks the stored ANSWERS against the quiz again. If a question
/// was edited after the sitting, this screen shows what the answers are worth
/// now — and the mismatch is visible rather than hidden.
class AttemptDetailPage extends StatelessWidget {
  const AttemptDetailPage({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  final Quiz quiz;
  final QuizAttempt attempt;

  static Color colorFor(double percent) {
    if (percent >= 80) return AppColors.green;
    if (percent >= 50) return AppColors.statusPending;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Color color = colorFor(attempt.percent);
    final int blanks = attempt.blanksIn(
      quiz.questions.map((QuizQuestion q) => q.id).toList(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              FormatHelper.capitalize(attempt.userName.isEmpty ? attempt.userId : attempt.userName),
              style: StyleText.fontSize18Weight600,
            ),
            Text(
              FormatHelper.capitalize(quiz.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
        // 10/11/2026: this member's grade as a PDF or Excel sheet.
        actions: <Widget>[
          QuizResultExportButtons(quiz: quiz, attempt: attempt, dense: true),
          SizedBox(width: 12.w),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 820.w),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 16.h,
            ),
            children: <Widget>[
              // ── Who, and what they scored ────────────────────────────────
              AppCard(
                child: Row(
                  children: <Widget>[
                    AppAvatar(name: attempt.userName, size: 52),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            FormatHelper.capitalize(attempt.userName.isEmpty
                                ? attempt.userId
                                : attempt.userName),
                            style: StyleText.fontSize16Weight600,
                          ),
                          if (attempt.userEmail.isNotEmpty) ...<Widget>[
                            SizedBox(height: 2.h),
                            Text(
                              FormatHelper.capitalize(attempt.userEmail),
                              style: StyleText.fontSize12Weight400
                                  .copyWith(color: AppColors.secondaryText),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          FormatHelper.capitalize('${attempt.score}/${attempt.totalPoints}'),
                          style: StyleText.fontSize22Weight700
                              .copyWith(color: color),
                        ),
                        Text(
                          FormatHelper.capitalize('${attempt.percent.round()}%'),
                          style: StyleText.fontSize12Weight500
                              .copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // ── When ─────────────────────────────────────────────────────
              AppCard(
                title: s.takenOn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Row(
                      icon: Icons.play_circle_outline_rounded,
                      label: s.startedAt,
                      value: AppDates.dateTime(context, attempt.startedAt),
                    ),
                    _Row(
                      icon: Icons.done_all_rounded,
                      label: s.finishedAt,
                      value: AppDates.dateTime(context, attempt.submittedAt),
                    ),
                    _Row(
                      icon: Icons.timer_outlined,
                      label: s.timeTaken,
                      value: _duration(context, attempt.timeTaken),
                    ),
                    _Row(
                      icon: Icons.rule_rounded,
                      label: s.correctOfTotal(
                        '${attempt.correctCount}',
                        '${attempt.questionCount}',
                      ),
                      value: blanks == 0 ? '—' : s.blanksCount('$blanks'),
                    ),
                    if (attempt.autoSubmitted)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: QuizChip(
                            icon: Icons.timer_outlined,
                            label: s.autoSubmitted,
                            color: AppColors.statusPending,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // ── 13/11/2026: screenshots and leaving the quiz ─────────────
              _Behaviour(attempt: attempt),
              SizedBox(height: 18.h),

              // ── Every question, and what they chose ──────────────────────
              AppSectionHeader(
                title: s.answerSheet,
                caption: s.questionsTotal(
                  '${quiz.questionCount}',
                  '${quiz.totalPoints}',
                ),
              ),
              SizedBox(height: 10.h),
              for (int i = 0; i < quiz.questions.length; i++)
                Directionality(
                  textDirection: quizTextDirection(quiz.questions[i].text),
                  child: _QuestionSheet(
                    index: i,
                    question: quiz.questions[i],
                    chosen: attempt.answers[quiz.questions[i].id],
                  ),
                ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  static String _duration(BuildContext context, Duration? d) {
    if (d == null) return '—';
    final S s = S.of(context);
    return s.minutesSeconds(
      '${d.inMinutes}',
      '${d.inSeconds.remainder(60)}',
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: <Widget>[
          AppIcon(icon, size: 16.sp, color: AppColors.secondaryText),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              FormatHelper.capitalize(label),
              style: StyleText.fontSize13Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
          ),
          Text(FormatHelper.capitalize(value), style: StyleText.fontSize13Weight600),
        ],
      ),
    );
  }
}

/// One question with every option shown: the right one, and the one they
/// picked — which is the whole point of this screen.
class _QuestionSheet extends StatelessWidget {
  const _QuestionSheet({
    required this.index,
    required this.question,
    required this.chosen,
  });

  final int index;
  final QuizQuestion question;

  /// Null when they never answered it.
  final int? chosen;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool correct = question.isCorrect(chosen);
    final Color verdict = correct ? AppColors.green : AppColors.red;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppIcon(
                  correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18.sp,
                  color: verdict,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        FormatHelper.capitalize(s.questionNumber('${index + 1}')),
                        style: StyleText.fontSize11Weight600
                            .copyWith(color: AppColors.secondaryText),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        FormatHelper.capitalize(question.text),
                        style: StyleText.fontSize14Weight600,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  FormatHelper.capitalize(s.pointsEarned(
                    '${correct ? question.points : 0}',
                    '${question.points}',
                  )),
                  style: StyleText.fontSize12Weight600.copyWith(color: verdict),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            for (int i = 0; i < question.options.length; i++)
              _OptionRow(
                label: question.options[i],
                isCorrect: i == question.correctIndex,
                isChosen: i == chosen,
              ),
            if (chosen == null) ...<Widget>[
              SizedBox(height: 4.h),
              Text(
                FormatHelper.capitalize(s.noAnswer),
                style: StyleText.fontSize12Weight600
                    .copyWith(color: AppColors.statusPending),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.isCorrect,
    required this.isChosen,
  });

  final String label;
  final bool isCorrect;
  final bool isChosen;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    // Four states, and the colour says which: the right answer is always
    // green, a wrong pick is red, everything else stays quiet.
    final Color tint = isCorrect
        ? AppColors.green
        : (isChosen ? AppColors.red : AppColors.secondaryText);
    final bool highlight = isCorrect || isChosen;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: highlight ? AppColors.chip : AppColors.transparent,
          borderRadius: AppRadius.containerR,
          border: Border.all(
            color: highlight ? tint.withOpacity(0.4) : AppColors.borderGrey,
          ),
        ),
        child: Row(
          children: <Widget>[
            AppIcon(
              isCorrect
                  ? Icons.check_circle_rounded
                  : (isChosen
                      ? Icons.cancel_rounded
                      : Icons.radio_button_unchecked_rounded),
              size: 16.sp,
              color: tint,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                FormatHelper.capitalize(label),
                style: highlight
                    ? StyleText.fontSize13Weight600.copyWith(color: AppColors.onChip)
                    : StyleText.fontSize13Weight400,
              ),
            ),
            if (isChosen)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.buttonR,
                ),
                child: Text(
                  FormatHelper.capitalize(s.theirAnswer),
                  style: StyleText.fontSize10Weight600.copyWith(color: AppColors.onChip),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 13/11/2026: what the member did during the quiz — screenshots, times
/// they left the app, time away, and when each happened.
class _Behaviour extends StatelessWidget {
  const _Behaviour({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final QuizAttempt a = attempt;
    final DateTime? start = a.startedAt;
    Widget stat(IconData icon, String label, String value, bool bad) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(icon, size: 22.sp, color: bad ? AppColors.red : AppColors.secondaryText),
              SizedBox(height: 6.h),
              Text(value,
                  style: StyleText.fontSize18Weight600.copyWith(color: bad ? AppColors.red : null)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText)),
            ],
          ),
        );
    return AppCard(
      title: ar ? 'أثناء الاختبار' : 'During the quiz',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              stat(Icons.camera_alt_rounded, ar ? 'لقطات الشاشة' : 'Screenshots', '${a.screenshots}', a.screenshots > 0),
              if (a.recordings > 0)
                stat(Icons.videocam_rounded, ar ? 'تسجيل الشاشة' : 'Screen recordings', '${a.recordings}', true),
              stat(Icons.logout_rounded, ar ? 'الخروج من التطبيق' : 'Left the app', '${a.leftApp}', a.leftApp > 0),
              stat(Icons.timer_outlined, ar ? 'وقت الخروج' : 'Time away',
                  a.awaySeconds == 0 ? '0s' : formatAwayTime(a.awaySeconds), a.awaySeconds > 0),
            ],
          ),
          SizedBox(height: 12.h),
          if (a.events.isEmpty)
            Text(
              ar ? 'بقي في الاختبار طوال الوقت — لم تُرصد لقطات شاشة.' : 'Stayed in the quiz the whole time — no screenshots detected.',
              textAlign: TextAlign.center,
              style: StyleText.fontSize13Weight400.copyWith(color: AppColors.secondaryText),
            )
          else
            for (final QuizIntegrityEvent e in a.events)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  children: <Widget>[
                    AppIcon(
                      e.type == 'left_app' ? Icons.logout_rounded : Icons.camera_alt_rounded,
                      size: 16.sp,
                      color: AppColors.red,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(e.label(ar), style: StyleText.fontSize13Weight400)),
                    Text(
                      start == null
                          ? AppDates.dateTime(context, e.at)
                          : '${AppDates.dateTime(context, e.at)} · ${formatAwayTime(e.at.difference(start).inSeconds.clamp(0, 1 << 30))}',
                      style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
          SizedBox(height: 6.h),
          Text(
            ar
                ? 'تُرصد لقطات الشاشة على أندرويد 14+ وآيفون؛ وعلى ويندوز/ماك زر Print Screen فقط. المحاولات قبل هذا التحديث تظهر 0.'
                : 'Screenshots are detected on Android 14+ and iPhone; on Windows / Mac only the Print Screen key. Attempts from before this update show 0.',
            style: StyleText.fontSize11Weight400.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
