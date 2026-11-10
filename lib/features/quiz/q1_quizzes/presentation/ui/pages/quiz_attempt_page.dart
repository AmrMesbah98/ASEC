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

import 'package:asec/core/settings/capture_context.dart';
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

class _Intro extends StatelessWidget {
  const _Intro({required this.state});

  final QuizAttemptState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Quiz quiz = state.quiz;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 24.h),
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
                style: StyleText.fontSize14Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: <Widget>[
                QuizChip(
                  icon: Icons.rule_rounded,
                  label: s.questionsCount('${quiz.questionCount}'),
                ),
                QuizChip(
                  icon: Icons.timer_outlined,
                  label: quiz.isTimed
                      ? s.minutesShort('${quiz.durationMinutes}')
                      : s.untimed,
                ),
                QuizWindowLabel(quiz: quiz),
                if (quiz.certificate)
                  QuizChip(
                    icon: Icons.workspace_premium_rounded,
                    label: s.passMark,
                  ),
              ],
            ),
            if (state.previous != null) ...<Widget>[
              SizedBox(height: 16.h),
              InfoBanner.error(
                s.lastTry('${state.previous!.percent.round()}'),
              ),
            ],
            SizedBox(height: 16.h),
            InfoBanner(
              icon: Icons.info_outline_rounded,
              message: quiz.isTimed
                  ? s.quizRulesTimed(
                      '${quiz.questionCount}',
                      '${quiz.durationMinutes}',
                    )
                  : s.quizRulesUntimed('${quiz.questionCount}'),
            ),
            SizedBox(height: 20.h),
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
    final QuizAttemptCubit cubit = context.read<QuizAttemptCubit>();
    final Quiz quiz = state.quiz;
    final QuizQuestion question = quiz.questions[state.currentIndex];
    final int? chosen = state.answers[question.id];
    final bool busy = state.stage == AttemptStage.submitting;

    return Column(
      children: <Widget>[
        // Progress: how far along, and how many are answered.
        Padding(
          padding: EdgeInsets.fromLTRB(AppPadding.h, 12.h, AppPadding.h, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    FormatHelper.capitalize(s.questionNofM(
                      '${state.currentIndex + 1}',
                      '${quiz.questionCount}',
                    )),
                    style: StyleText.fontSize13Weight600,
                  ),
                  const Spacer(),
                  Text(
                    FormatHelper.capitalize('${s.answered}: ${state.answeredCount}/${quiz.questionCount}'),
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: AppRadius.buttonR,
                child: LinearProgressIndicator(
                  value: (state.currentIndex + 1) / quiz.questionCount,
                  minHeight: 5.h,
                  backgroundColor: AppColors.chip,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 16.h),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(FormatHelper.capitalize(question.text), style: StyleText.fontSize18Weight600),
                  SizedBox(height: 16.h),
                  for (int i = 0; i < question.options.length; i++)
                    _OptionTile(
                      label: question.options[i],
                      selected: chosen == i,
                      onTap: busy
                          ? null
                          : () => cubit.answer(question.id, i),
                    ),
                ],
              ),
            ),
          ),
        ),
        // The pager: previous / next, and Submit on the last question.
        SafeArea(
          top: false,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(AppPadding.h, 8.h, AppPadding.h, 12.h),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: s.previous,
                    icon: Icons.chevron_left_rounded,
                    kind: AppButtonKind.outlined,
                    onPressed:
                        state.currentIndex == 0 || busy ? null : cubit.previous,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: state.isLastQuestion
                      ? AppButton(
                          label: s.submit,
                          icon: Icons.done_all_rounded,
                          loading: busy,
                          onPressed: () => _confirmSubmit(context),
                        )
                      : AppButton(
                          label: s.next,
                          icon: Icons.chevron_right_rounded,
                          onPressed: busy ? null : cubit.next,
                        ),
                ),
              ],
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
    final Color color = selected ? AppColors.primary : AppColors.borderGrey;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: selected ? AppColors.chip : AppColors.transparent,
        borderRadius: AppRadius.containerR,
        child: InkWell(
          borderRadius: AppRadius.containerR,
          onTap: onTap,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: AppRadius.containerR,
              border: Border.all(color: color, width: selected ? 1.6 : 1),
            ),
            child: Row(
              children: <Widget>[
                AppIcon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20.sp,
                  color: selected ? AppColors.primary : AppColors.secondaryText,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(label),
                    style: selected
                        ? StyleText.fontSize15Weight600
                            .copyWith(color: AppColors.primary)
                        : StyleText.fontSize15Weight400,
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

class _Result extends StatelessWidget {
  const _Result({required this.state});

  final QuizAttemptState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizAttempt attempt = state.attempt!;
    final Quiz quiz = state.quiz;
    final double percent = attempt.percent;
    final bool cert = quiz.certificate;
    // 09/11/2026: EVERY quiz finished with a pass (Quiz.passPercent or more)
    // earns the ASEC certificate — the same design as the certificate exams.
    final bool earned = cert ? attempt.passed : percent >= Quiz.passPercent;
    final Color color = cert
        ? (attempt.passed ? AppColors.green : AppColors.red)
        : percent >= 80
            ? AppColors.green
            : (percent >= 50 ? AppColors.statusPending : AppColors.red);
    final String heading = cert
        ? (attempt.passed ? s.passedTitle : s.failedTitle)
        : (attempt.autoSubmitted ? s.timeUp : s.submittedTitle);
    final String sub = cert
        ? (attempt.passed ? s.yourScore : s.failedBody)
        : (state.wasAlreadyTaken ? s.alreadyTakenBody : s.yourScore);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (cert)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Icon(
                      attempt.passed
                          ? Icons.workspace_premium_rounded
                          : Icons.refresh_rounded,
                      size: 44,
                      color: color,
                    ),
                  ),
                Text(
                  FormatHelper.capitalize(heading),
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize20Weight600,
                ),
                SizedBox(height: 4.h),
                Text(
                  FormatHelper.capitalize(sub),
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize13Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  width: 128.r,
                  height: 128.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: percent / 100,
                          strokeWidth: 8.r,
                          backgroundColor: AppColors.chip,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            FormatHelper.capitalize('${percent.round()}%'),
                            style: StyleText.fontSize26Weight600
                                .copyWith(color: color),
                          ),
                          Text(
                            FormatHelper.capitalize('${attempt.score}/${attempt.totalPoints}'),
                            style: StyleText.fontSize13Weight500
                                .copyWith(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  FormatHelper.capitalize(s.correctOfTotal(
                    '${attempt.correctCount}',
                    '${attempt.questionCount}',
                  )),
                  style: StyleText.fontSize14Weight600,
                ),
                SizedBox(height: 18.h),
                // 10/11/2026: the member's grade as a PDF or Excel sheet.
                // A final exam that can still be retaken leaves out the key.
                QuizResultExportButtons(
                  quiz: quiz,
                  attempt: attempt,
                  showKey: !cert || attempt.passed,
                ),
                SizedBox(height: 10.h),
                if (earned) ...<Widget>[
                  AppButton(
                    label: s.viewCertificate,
                    icon: Icons.workspace_premium_rounded,
                    expand: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CertificatePage(quiz: quiz, attempt: attempt),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
                if (cert && !attempt.passed) ...<Widget>[
                  AppButton(
                    label: s.tryAgain,
                    icon: Icons.refresh_rounded,
                    expand: true,
                    onPressed: context.read<QuizAttemptCubit>().retake,
                  ),
                  SizedBox(height: 10.h),
                ],
                AppButton(
                  label: s.backToQuizzes,
                  icon: Icons.arrow_back_rounded,
                  kind: AppButtonKind.subtle,
                  expand: true,
                  onPressed: () => Navigator.of(context).maybePop(),
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.index,
    required this.question,
    required this.answer,
  });

  final int index;
  final QuizQuestion question;
  final int? answer;

  String _optionAt(int? i) =>
      i != null && i >= 0 && i < question.options.length
          ? question.options[i]
          : '';

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool correct = question.isCorrect(answer);
    final Color color = correct ? AppColors.green : AppColors.red;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
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
            _ReviewLine(
              label: s.yourAnswer,
              value: answer == null ? s.noAnswer : _optionAt(answer),
              color: color,
            ),
            if (!correct) ...<Widget>[
              SizedBox(height: 4.h),
              _ReviewLine(
                label: s.correctAnswer,
                value: _optionAt(question.correctIndex),
                color: AppColors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          FormatHelper.capitalize('$label: '),
          style: StyleText.fontSize13Weight400
              .copyWith(color: AppColors.secondaryText),
        ),
        Expanded(
          child: Text(
            FormatHelper.capitalize(value),
            style: StyleText.fontSize13Weight600.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
