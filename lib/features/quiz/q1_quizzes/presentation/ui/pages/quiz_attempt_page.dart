/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_attempt_page.dart
/// Purpose: Declares `QuizAttemptPage` — the rules, the countdown, the
///          questions and the result, in one screen driven by the stage.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:asec/core/settings/capture_context.dart';
import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/enums/quiz_window_state.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/controller/quiz_attempt_cubit.dart';
import 'package:asec/features/quiz/q1_quizzes/data/quiz_integrity_monitor.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_integrity_event.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_text_direction.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_meta.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_result_export.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class QuizAttemptPage extends StatelessWidget {
  const QuizAttemptPage({super.key, required this.quiz, required this.user});

  final Quiz quiz;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return CaptureTag(
      page: 'Quiz',
      course: <String>[
        if (quiz.course.isNotEmpty) quiz.course,
        if (quiz.section.isNotEmpty) quiz.section,
      ].join(' › '),
      detail: quiz.title,
      child: BlocProvider<QuizAttemptCubit>(
      create: (_) => QuizAttemptCubit(
        quiz: quiz,
        userId: user.uid,
        userName: user.displayName,
        userEmail: user.email,
      )..load(),
      child: const _AttemptView(),
    ),
    );
  }
}

class _AttemptView extends StatelessWidget {
  const _AttemptView();

  /// The reading width for a question. Wider than this and the eye loses the
  /// start of the next line, whatever the window is.
  static const double _contentWidth = 760;

  Future<void> _confirmLeave(BuildContext context) async {
    final S s = S.of(context);
    final NavigatorState navigator = Navigator.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.leaveExamQuestion,
      subtitle: s.leaveExamBody,
      confirmLabel: s.leave,
      cancelLabel: s.keepGoing,
      onConfirm: navigator.pop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return BlocConsumer<QuizAttemptCubit, QuizAttemptState>(
      listenWhen: (QuizAttemptState a, QuizAttemptState b) =>
          a.failure != b.failure && b.failure != null,
      listener: (BuildContext context, QuizAttemptState state) {
        AppMessenger.of(context).show(
          AppMessage(content: Text(FormatHelper.capitalize(state.failure!.message(context)))),
        );
      },
      builder: (BuildContext context, QuizAttemptState state) {
        final bool running = state.stage == AttemptStage.running ||
            state.stage == AttemptStage.submitting;

        return PopScope(
          // Leaving mid-quiz throws the sitting away, so it asks first.
          canPop: !running,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) _confirmLeave(context);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                FormatHelper.capitalize(state.quiz.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize16Weight600,
              ),
              actions: <Widget>[
                if (running && state.remaining != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: AppPadding.h),
                    child: Center(
                      child: CountdownPill(
                        remaining: state.remaining!,
                        urgent: state.isRunningOut,
                      ),
                    ),
                  ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _contentWidth.w),
                child: _body(context, state, s),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, QuizAttemptState state, S s) {
    switch (state.stage) {
      case AttemptStage.loading:
        return const AppLoading();
      case AttemptStage.unavailable:
        return _Unavailable(state: state);
      case AttemptStage.intro:
        return _Intro(state: state);
      case AttemptStage.running:
      case AttemptStage.submitting:
        return _Questions(state: state);
      case AttemptStage.finished:
        return _Result(state: state);
      case AttemptStage.failure:
        return AppErrorView(message: s.errUnknown, error: state.failure);
    }
  }
}

// ── Closed, or not open yet ─────────────────────────────────────────────────

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.state});

  final QuizAttemptState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final String subtitle;
    switch (state.window) {
      case QuizWindowState.notOpenYet:
        subtitle = s.quizNotOpenYet(
          AppDates.dateTime(context, state.quiz.opensAt),
        );
      case QuizWindowState.closed:
        subtitle = s.quizClosed;
      case QuizWindowState.open:
        subtitle = s.errNoQuestions;
    }

    return AppEmptyView(title: s.quizWindowClosedBody, subtitle: subtitle);
  }
}

// ── The rules, and the button that starts the clock ─────────────────────────
// 16/11/2026: laid out as ENGX — one rule per line with its icon, then Start.

class _Intro extends StatelessWidget {
  const _Intro({required this.state});

  final QuizAttemptState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Quiz quiz = state.quiz;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';

    final List<(IconData, String)> rules = <(IconData, String)>[
      (
        Icons.help_outline_rounded,
        '${s.questionsCount('${quiz.questionCount}')} · ${quiz.totalPoints} ${ar ? 'درجة' : 'points'}'
      ),
      (
        Icons.timer_outlined,
        quiz.isTimed
            ? s.quizRulesTimed('${quiz.questionCount}', '${quiz.durationMinutes}')
            : s.quizRulesUntimed('${quiz.questionCount}')
      ),
      if (quiz.certificate) (Icons.workspace_premium_rounded, s.passMark),
      (
        Icons.verified_rounded,
        ar
            ? 'النجاح بنسبة ${Quiz.passPercent.round()}% أو أكثر يمنحك شهادة ASEC'
            : 'Passing (${Quiz.passPercent.round()}% or more) earns an ASEC certificate'
      ),
      (
        Icons.visibility_outlined,
        ar
            ? 'ابقَ في الاختبار حتى تسلّم: كل لقطة شاشة وكل مرة تخرج فيها من التطبيق (تصغير، أو الانتقال لنافذة أو تطبيق آخر) تُحسب وتظهر للمدرّب.'
            : 'Stay in the quiz until you submit: every screenshot and every time you leave the app (minimise, switch to another window or app) is counted and shown to your instructor.'
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 20.h),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(FormatHelper.capitalize(quiz.title), style: StyleText.fontSize22Weight600),
            if (quiz.description.trim().isNotEmpty) ...<Widget>[
              SizedBox(height: 8.h),
              Text(
                FormatHelper.capitalize(quiz.description),
                style: StyleText.fontSize14Weight400.copyWith(color: AppColors.secondaryText),
              ),
            ],
            if (state.previous != null) ...<Widget>[
              SizedBox(height: 12.h),
              QuizChip(
                icon: Icons.history_rounded,
                label: s.lastTry('${state.previous!.percent.round()}'),
                color: AppColors.statusPending,
              ),
            ],
            SizedBox(height: 16.h),
            for (final (IconData icon, String text) in rules)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppIcon(icon, size: 20.sp, color: AppColors.primary),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(FormatHelper.capitalize(text), style: StyleText.fontSize14Weight400),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: QuizWindowLabel(quiz: quiz),
            ),
            SizedBox(height: 10.h),
            AppButton(
              label: s.startQuiz,
              icon: Icons.play_arrow_rounded,
              expand: true,
              onPressed: context.read<QuizAttemptCubit>().start,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Answering ───────────────────────────────────────────────────────────────
// 16/11/2026: as ENGX — a thin progress line, "Question 3 of 10 · 2 points",
// the question, the options, a grid to jump to any question, and a bottom bar
// with Previous · answered count · Next / Submit.

class _Questions extends StatelessWidget {
  const _Questions({required this.state});

  final QuizAttemptState state;

  Future<void> _confirmSubmit(BuildContext context) async {
    final S s = S.of(context);
    final QuizAttemptCubit cubit = context.read<QuizAttemptCubit>();
    final int blanks = state.quiz.questionCount - state.answeredCount;

    await CustomDialogManager.showConfirm(
      context: context,
      title: s.submitQuestion,
      subtitle: blanks > 0 ? s.submitWithBlanks('$blanks') : s.submitBody,
      confirmLabel: s.submit,
      cancelLabel: s.keepGoing,
      onConfirm: cubit.submit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final QuizAttemptCubit cubit = context.read<QuizAttemptCubit>();
    final Quiz quiz = state.quiz;
    final QuizQuestion question = quiz.questions[state.currentIndex];
    final int? chosen = state.answers[question.id];
    final bool busy = state.stage == AttemptStage.submitting;

    return Column(
      children: <Widget>[
        _IntegrityBar(monitor: cubit.monitor),
        LinearProgressIndicator(
          value: (state.currentIndex + 1) / quiz.questionCount,
          minHeight: 4,
          backgroundColor: AppColors.chip,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 18.h),
            children: <Widget>[
              Text(
                '${FormatHelper.capitalize(s.questionNofM('${state.currentIndex + 1}', '${quiz.questionCount}'))}'
                ' · ${question.points} ${ar ? 'درجة' : (question.points == 1 ? 'point' : 'points')}',
                style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary),
              ),
              SizedBox(height: 10.h),
              // An Arabic question and its options read right to left.
              Directionality(
                textDirection: quizTextDirection(question.text),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(question.text),
                      style: StyleText.fontSize18Weight600.copyWith(height: 1.4),
                    ),
                    SizedBox(height: 18.h),
                    for (int i = 0; i < question.options.length; i++)
                      _OptionTile(
                        label: question.options[i],
                        selected: chosen == i,
                        onTap: busy ? null : () => cubit.answer(question.id, i),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              _QuestionMap(state: state, onTap: busy ? null : cubit.goTo),
            ],
          ),
        ),
        // Previous · answered · Next / Submit.
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.borderGrey)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppPadding.h, 10.h, AppPadding.h, 12.h),
              child: Row(
                children: <Widget>[
                  AppButton(
                    label: s.previous,
                    icon: Icons.chevron_left_rounded,
                    kind: AppButtonKind.outlined,
                    onPressed: state.currentIndex == 0 || busy ? null : cubit.previous,
                  ),
                  const Spacer(),
                  Flexible(
                    flex: 3,
                    child: Text(
                      FormatHelper.capitalize('${state.answeredCount}/${quiz.questionCount} ${s.answered}'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize13Weight400.copyWith(color: AppColors.secondaryText),
                    ),
                  ),
                  const Spacer(),
                  if (state.isLastQuestion)
                    AppButton(
                      label: s.submit,
                      icon: Icons.send_rounded,
                      loading: busy,
                      onPressed: () => _confirmSubmit(context),
                    )
                  else
                    AppButton(
                      label: s.next,
                      icon: Icons.chevron_right_rounded,
                      onPressed: busy ? null : cubit.next,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Numbered squares: the current one filled, answered ones tinted.
class _QuestionMap extends StatelessWidget {
  const _QuestionMap({required this.state, required this.onTap});

  final QuizAttemptState state;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    final Quiz quiz = state.quiz;
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: <Widget>[
        for (int i = 0; i < quiz.questionCount; i++)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap == null ? null : () => onTap!(i),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == state.currentIndex
                    ? AppColors.primary
                    : state.answers.containsKey(quiz.questions[i].id)
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Text(
                '${i + 1}',
                style: StyleText.fontSize13Weight600.copyWith(
                  color: i == state.currentIndex ? Colors.white : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderGrey,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                AppIcon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 20.sp,
                  color: selected ? AppColors.primary : AppColors.secondaryText,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(label),
                    textDirection: quizTextDirection(label),
                    style: StyleText.fontSize15Weight400,
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

// ── The result ──────────────────────────────────────────────────────────────
// 16/11/2026: as ENGX — the animation, the big percentage, Passed / Not
// passed, the numbers as chips, the buttons in a row, then the review.

String _mmss(Duration d) {
  final int h = d.inHours;
  final String m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final String sec = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$sec' : '$m:$sec';
}

class _Result extends StatelessWidget {
  const _Result({required this.state});

  final QuizAttemptState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final QuizAttempt attempt = state.attempt!;
    final Quiz quiz = state.quiz;
    final double percent = attempt.percent;
    final bool cert = quiz.certificate;
    // 09/11/2026: EVERY quiz finished with a pass (Quiz.passPercent or more)
    // earns the ASEC certificate — the same design as the certificate exams.
    final bool earned = cert ? attempt.passed : percent >= Quiz.passPercent;
    final Color color = earned ? AppColors.green : AppColors.red;
    final String heading = cert
        ? (attempt.passed ? s.passedTitle : s.failedTitle)
        : (attempt.autoSubmitted ? s.timeUp : s.submittedTitle);
    final String sub = cert
        ? (attempt.passed ? s.yourScore : s.failedBody)
        : (state.wasAlreadyTaken ? s.alreadyTakenBody : s.yourScore);
    final Duration? taken = attempt.timeTaken;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Lottie.asset(
                  earned ? AppAssets.lottieSuccess : AppAssets.lottieWarning,
                  width: 130,
                  height: 130,
                  repeat: false,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${percent.round()}%',
                  style: StyleText.fontSize26Weight600.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  FormatHelper.capitalize(heading),
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize16Weight600.copyWith(color: color),
                ),
                SizedBox(height: 4.h),
                Text(
                  FormatHelper.capitalize(sub),
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize13Weight400.copyWith(color: AppColors.secondaryText),
                ),
                SizedBox(height: 14.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    QuizChip(
                      icon: Icons.check_rounded,
                      label: FormatHelper.capitalize(
                          s.correctOfTotal('${attempt.correctCount}', '${attempt.questionCount}')),
                      color: AppColors.primary,
                    ),
                    QuizChip(
                      icon: Icons.star_rounded,
                      label: '${attempt.score}/${attempt.totalPoints} ${ar ? 'درجة' : 'points'}',
                      color: AppColors.primary,
                    ),
                    if (taken != null)
                      QuizChip(icon: Icons.timer_outlined, label: _mmss(taken), color: AppColors.primary),
                    if (attempt.autoSubmitted)
                      QuizChip(
                        icon: Icons.timer_off_outlined,
                        label: FormatHelper.capitalize(s.timeUp),
                        color: AppColors.statusPending,
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                _IntegrityChips(attempt: attempt),
                SizedBox(height: 18.h),
                // 10/11/2026: the member's grade as a PDF or Excel sheet.
                // A final exam that can still be retaken leaves out the key.
                QuizResultExportButtons(
                  quiz: quiz,
                  attempt: attempt,
                  showKey: !cert || attempt.passed,
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (earned)
                      AppButton(
                        label: s.viewCertificate,
                        icon: Icons.workspace_premium_rounded,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CertificatePage(quiz: quiz, attempt: attempt),
                          ),
                        ),
                      ),
                    if (cert && !attempt.passed)
                      AppButton(
                        label: s.tryAgain,
                        icon: Icons.replay_rounded,
                        onPressed: context.read<QuizAttemptCubit>().retake,
                      ),
                    AppButton(
                      label: s.backToQuizzes,
                      icon: Icons.arrow_back_rounded,
                      kind: AppButtonKind.outlined,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // A certificate exam that can still be retaken does not reveal its
          // answers — that would turn the retake into copying.
          if (!cert || attempt.passed) ...<Widget>[
            SizedBox(height: 18.h),
            AppSectionHeader(title: s.review),
            SizedBox(height: 10.h),
            for (int i = 0; i < quiz.questions.length; i++)
              _ReviewRow(
                index: i,
                question: quiz.questions[i],
                answer: attempt.answers[quiz.questions[i].id],
              ),
          ],
        ],
      ),
    );
  }
}

/// One question in the review, as ENGX: a green / red card, the member's
/// pick marked ✗, the right answer ✓.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.index,
    required this.question,
    required this.answer,
  });

  final int index;
  final QuizQuestion question;
  final int? answer;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool correct = question.isCorrect(answer);
    final Color color = correct ? AppColors.green : AppColors.red;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Directionality(
        textDirection: quizTextDirection(question.text),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
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
                      size: 20.sp,
                      color: color,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        FormatHelper.capitalize('${index + 1}. ${question.text}'),
                        style: StyleText.fontSize14Weight600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                for (int i = 0; i < question.options.length; i++)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 28.w, bottom: 4.h),
                    child: Text(
                      '${i == question.correctIndex ? '✓ ' : i == answer ? '✗ ' : '•  '}'
                      '${FormatHelper.capitalize(question.options[i])}',
                      style: (i == question.correctIndex || i == answer
                              ? StyleText.fontSize13Weight600
                              : StyleText.fontSize13Weight400)
                          .copyWith(
                        color: i == question.correctIndex
                            ? AppColors.green
                            : i == answer
                                ? AppColors.red
                                : AppColors.secondaryText,
                      ),
                    ),
                  ),
                if (answer == null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 28.w, top: 2.h),
                    child: Text(
                      FormatHelper.capitalize(s.noAnswer),
                      style: StyleText.fontSize12Weight600.copyWith(color: AppColors.statusPending),
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

// ── 13/11/2026: screenshots and leaving the quiz ───────────────────────────

/// Live counts the member sees while answering, and a warning each time.
class _IntegrityBar extends StatefulWidget {
  const _IntegrityBar({required this.monitor});

  final QuizIntegrityMonitor monitor;

  @override
  State<_IntegrityBar> createState() => _IntegrityBarState();
}

class _IntegrityBarState extends State<_IntegrityBar> {
  @override
  void initState() {
    super.initState();
    widget.monitor.onEvent = _warn;
  }

  @override
  void dispose() {
    if (widget.monitor.onEvent == _warn) widget.monitor.onEvent = null;
    super.dispose();
  }

  void _warn(QuizIntegrityEvent e) {
    if (!mounted) return;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final QuizIntegrityMonitor m = widget.monitor;
    final String what = switch (e.type) {
      'screenshot' => ar ? 'تم رصد لقطة شاشة (${m.screenshots})' : 'Screenshot detected (${m.screenshots})',
      'recording' => ar ? 'تم رصد تسجيل للشاشة (${m.recordings})' : 'Screen recording detected (${m.recordings})',
      _ => ar
          ? 'خرجت من الاختبار (${m.leftApp}${e.seconds > 0 ? ' · ${formatAwayTime(e.seconds)}' : ''})'
          : 'You left the quiz (${m.leftApp}${e.seconds > 0 ? ' · ${formatAwayTime(e.seconds)}' : ''})',
    };
    AppMessenger.of(context).show(AppMessage(
      content: Text(ar ? '$what — سيظهر هذا للمدرّب.' : '$what — your instructor will see this.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    return ListenableBuilder(
      listenable: widget.monitor,
      builder: (BuildContext context, _) {
        final QuizIntegrityMonitor m = widget.monitor;
        final int shots = m.screenshots + m.recordings;
        final bool clean = shots == 0 && m.leftApp == 0;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 8.h),
          color: (clean ? AppColors.primary : AppColors.red).withValues(alpha: 0.08),
          child: Wrap(
            spacing: 14.w,
            runSpacing: 4.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _count(Icons.camera_alt_rounded, ar ? 'لقطات الشاشة' : 'Screenshots', '$shots', shots > 0),
              _count(Icons.logout_rounded, ar ? 'الخروج من الاختبار' : 'Left the quiz', '${m.leftApp}', m.leftApp > 0),
              if (m.awaySeconds > 0)
                _count(Icons.timer_outlined, ar ? 'وقت الخروج' : 'Time away', formatAwayTime(m.awaySeconds), true),
              Text(
                ar ? 'يراها المدرّب' : 'Your instructor sees these',
                style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _count(IconData icon, String label, String value, bool bad) {
    final Color c = bad ? AppColors.red : AppColors.secondaryText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIcon(icon, size: 16.sp, color: c),
        SizedBox(width: 5.w),
        Text('$label: $value', style: StyleText.fontSize12Weight600.copyWith(color: c)),
      ],
    );
  }
}

/// On the result: how many screenshots and times they left.
class _IntegrityChips extends StatelessWidget {
  const _IntegrityChips({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final int shots = attempt.screenshots + attempt.recordings;
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: <Widget>[
        QuizChip(
          icon: Icons.camera_alt_rounded,
          label: '${ar ? 'لقطات الشاشة' : 'Screenshots'}: $shots',
          color: shots > 0 ? AppColors.red : AppColors.secondaryText,
        ),
        QuizChip(
          icon: Icons.logout_rounded,
          label: '${ar ? 'الخروج من الاختبار' : 'Left the quiz'}: ${attempt.leftApp}'
              '${attempt.awaySeconds > 0 ? ' (${formatAwayTime(attempt.awaySeconds)})' : ''}',
          color: attempt.leftApp > 0 ? AppColors.red : AppColors.secondaryText,
        ),
      ],
    );
  }
}
