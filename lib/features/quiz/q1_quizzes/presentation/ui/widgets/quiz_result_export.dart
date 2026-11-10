/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_result_export.dart
/// Purpose: Declares `QuizResultExport` and `QuizResultExportButtons` — one
///          member's quiz result (their grade) as a PDF or an Excel sheet:
///          the member, the quiz, the score, and the answer sheet.
/// Author: ASEC team
/// Created: 10/11/2026
///
/// Same ASEC report as the calculators (`CalcExport`). Used on the member's
/// result screen and on the admin's attempt page.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';
import 'package:asec/features/tools/t2_engineering_calc/data/calc_export.dart';
import 'package:asec/generated/l10n.dart';

abstract final class QuizResultExport {
  const QuizResultExport._();

  /// [showKey] false hides the correct answers — a final exam the member
  /// can still retake must not hand out its key.
  static CalcReport report(
    BuildContext context,
    Quiz quiz,
    QuizAttempt attempt, {
    bool showKey = true,
  }) {
    final S s = S.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    String t(String en, String arText) => ar ? arText : en;

    final String name = attempt.userName.trim().isNotEmpty
        ? attempt.userName.trim()
        : attempt.userEmail.split('@').first;
    final Duration? d = attempt.timeTaken;
    final String time = d == null
        ? '—'
        : s.minutesSeconds('${d.inMinutes}', '${d.inSeconds.remainder(60)}');
    final List<String> ids = <String>[for (final QuizQuestion q in quiz.questions) q.id];
    final int blanks = attempt.blanksIn(ids);
    final int wrong = (attempt.questionCount - attempt.correctCount - blanks).clamp(0, 1 << 30);
    final bool passed =
        quiz.certificate ? attempt.passed : attempt.percent >= Quiz.passPercent;

    String option(QuizQuestion q, int? i) =>
        i != null && i >= 0 && i < q.options.length ? q.options[i] : '';

    return CalcReport(
      id: 'Quiz-Result',
      title: quiz.title,
      subtitle: name,
      discipline: s.quizzes,
      arabic: ar,
      inputs: <CalcRow>[
        CalcRow(label: s.member, text: name),
        if (attempt.userEmail.isNotEmpty) CalcRow(label: s.email, text: attempt.userEmail),
        CalcRow(label: s.quizLabel, text: quiz.title),
        if (quiz.course.trim().isNotEmpty) CalcRow(label: s.courseLabel, text: quiz.course.trim()),
        CalcRow(label: s.finishedAt, text: AppDates.dateTime(context, attempt.submittedAt)),
        CalcRow(label: s.timeTaken, text: time),
        if (quiz.certificate) CalcRow(label: t('Attempt', 'المحاولة'), text: '${attempt.tries}'),
      ],
      results: <CalcRow>[
        CalcRow(label: t('Grade', 'الدرجة'), text: '${attempt.percent.round()}%', primary: true),
        CalcRow(label: s.points, text: '${attempt.score}/${attempt.totalPoints}'),
        CalcRow(label: t('Correct answers', 'إجابات صحيحة'), text: '${attempt.correctCount}/${attempt.questionCount}'),
        CalcRow(label: t('Wrong answers', 'إجابات خاطئة'), text: '$wrong'),
        CalcRow(label: t('Left blank', 'بدون إجابة'), text: '$blanks'),
        CalcRow(label: s.status, text: passed ? t('Passed', 'ناجح') : t('Not passed', 'لم ينجح'), primary: true),
      ],
      formula: '',
      note: s.passMark,
      extraTitle: s.answerSheet,
      extraHeaders: <String>[
        '#',
        t('Question', 'السؤال'),
        s.yourAnswer,
        if (showKey) s.correctAnswer,
        s.points,
        t('Result', 'النتيجة'),
      ],
      extraRows: <List<String>>[
        for (int i = 0; i < quiz.questions.length; i++)
          () {
            final QuizQuestion q = quiz.questions[i];
            final int? a = attempt.answers[q.id];
            final bool ok = q.isCorrect(a);
            return <String>[
              '${i + 1}',
              q.text,
              a == null ? s.noAnswer : option(q, a),
              if (showKey) option(q, q.correctIndex),
              '${ok ? q.points : 0}/${q.points}',
              a == null
                  ? t('Blank', 'فارغ')
                  : ok
                      ? t('Correct', 'صحيح')
                      : t('Wrong', 'خطأ'),
            ];
          }(),
      ],
      labels: CalcReportLabels(
        inputs: t('Member and quiz', 'العضو والاختبار'),
        results: t('Grade', 'الدرجة'),
        method: s.calcFormula,
        item: s.calcItem,
        value: s.calcValue,
        unit: s.calcUnit,
        date: s.calcDate,
        disclaimer: '',
      ),
    );
  }

  /// Builds the file and opens the save dialog / share sheet.
  static Future<void> save(
    BuildContext context,
    Quiz quiz,
    QuizAttempt attempt, {
    required bool excel,
    bool showKey = true,
  }) async {
    final S s = S.of(context);
    final AppMessenger messenger = AppMessenger.of(context);
    final CalcReport r = report(context, quiz, attempt, showKey: showKey);
    final String name = '${r.fileBase}.${excel ? 'xlsx' : 'pdf'}';
    try {
      final String? saved = excel
          ? await CalcExport.saveExcel(r, fileName: name, dialogTitle: s.calcExportExcel)
          : await CalcExport.savePdf(r, fileName: name, dialogTitle: s.calcExportPdf);
      if (saved != null) {
        messenger
          ..hide()
          ..show(AppMessage(content: Text(FormatHelper.capitalize(s.calcSaved(saved)))));
      }
    } catch (e) {
      messenger.show(AppMessage(
        content: Text(FormatHelper.capitalize(kDebugMode ? '${s.errUnknown}\n$e' : s.errUnknown)),
      ));
    }
  }
}

/// "Export PDF" and "Export Excel" side by side.
class QuizResultExportButtons extends StatefulWidget {
  const QuizResultExportButtons({
    super.key,
    required this.quiz,
    required this.attempt,
    this.showKey = true,
    this.dense = false,
  });

  final Quiz quiz;
  final QuizAttempt attempt;
  final bool showKey;
  final bool dense;

  @override
  State<QuizResultExportButtons> createState() => _QuizResultExportButtonsState();
}

class _QuizResultExportButtonsState extends State<QuizResultExportButtons> {
  bool _busy = false;

  Future<void> _run(bool excel) async {
    if (_busy) return;
    setState(() => _busy = true);
    await QuizResultExport.save(
      context,
      widget.quiz,
      widget.attempt,
      excel: excel,
      showKey: widget.showKey,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Widget pdf = AppButton(
      label: s.calcExportPdf,
      icon: Icons.picture_as_pdf_rounded,
      kind: AppButtonKind.subtle,
      dense: widget.dense,
      expand: !widget.dense,
      loading: _busy,
      onPressed: () => _run(false),
    );
    final Widget excel = AppButton(
      label: s.calcExportExcel,
      icon: Icons.table_view_rounded,
      kind: AppButtonKind.subtle,
      dense: widget.dense,
      expand: !widget.dense,
      loading: _busy,
      onPressed: () => _run(true),
    );
    if (widget.dense) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[pdf, SizedBox(width: 8.w), excel],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: pdf),
        SizedBox(width: 10.w),
        Expanded(child: excel),
      ],
    );
  }
}
