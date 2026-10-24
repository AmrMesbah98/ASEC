/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: section_quizzes.dart
/// Purpose: Declares `SectionQuizzes` — the quizzes at the end of one course
///          section (a Drive sub-folder) in the Videos page.
/// Author: ASEC team
/// Created: 15/10/2026
///
/// A SECTION QUIZ is an ordinary quiz whose `course` (and `section`) name a
/// video folder. Any course you upload gets them the same way: open the
/// section in Videos (admin) → "Add a quiz for this section".
///
///  * MEMBER: published quizzes of the section, LOCKED until every lesson of
///    the section is watched; then tap to take it. Score shown once taken.
///  * ADMIN: every quiz of the section (drafts too) to edit, plus the button
///    that creates a new one already linked to the section.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_attempt_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_editor_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_card.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class SectionQuizzes extends StatefulWidget {
  /// For a member: unlocked once the section's lessons are all watched.
  const SectionQuizzes.member({
    super.key,
    required this.course,
    required this.sections,
    required this.user,
    required this.unlocked,
  })  : adminUid = null;

  /// For the admin: edit the section's quizzes and add new ones.
  const SectionQuizzes.admin({
    super.key,
    required this.course,
    required this.sections,
    required String this.adminUid,
  })  : user = null,
        unlocked = true;

  /// The course (top Drive folder) name.
  final String course;

  /// The section names this view covers. Usually one; when the course has
  /// no sub-folder screen, every section of it plus ''. The FIRST one is
  /// what a new quiz is linked to.
  final List<String> sections;

  final AppUser? user;
  final String? adminUid;
  final bool unlocked;

  bool get isAdmin => adminUid != null;

  @override
  State<SectionQuizzes> createState() => _SectionQuizzesState();
}

class _SectionQuizzesState extends State<SectionQuizzes> {
  final QuizRepository _repository = QuizRepository();

  late final Stream<(List<Quiz>, Map<String, QuizAttempt>)> _feed = widget.isAdmin
      ? _repository.watchAll().map((List<Quiz> q) => (q, <String, QuizAttempt>{}))
      : combineLatest<Object, (List<Quiz>, Map<String, QuizAttempt>)>(
          <Stream<Object>>[
            _repository.watchPublished(),
            _repository.watchMyAttempts(widget.user!.uid),
          ],
          (List<Object> v) => (
            v[0] as List<Quiz>,
            <String, QuizAttempt>{
              for (final QuizAttempt a in v[1] as List<QuizAttempt>) a.quizId: a,
            },
          ),
        );

  bool _mine(Quiz q) => widget.sections
      .any((String section) => q.closesSection(widget.course, section));

  Future<void> _open(Quiz quiz) async {
    final S s = S.of(context);
    if (widget.isAdmin) {
      await Navigator.of(context).push(MaterialPageRoute<bool>(
        builder: (_) => QuizEditorPage(quiz: quiz, adminUid: widget.adminUid!),
      ));
      return;
    }
    if (!widget.unlocked) {
      AppMessenger.of(context)
        ..hide()
        ..show(AppMessage(content: Text(FormatHelper.capitalize(s.sectionQuizLocked))));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => QuizAttemptPage(quiz: quiz, user: widget.user!),
    ));
  }

  Future<void> _add() => Navigator.of(context).push(MaterialPageRoute<bool>(
        builder: (_) => QuizEditorPage(
          adminUid: widget.adminUid!,
          course: widget.course,
          section: widget.sections.isEmpty ? '' : widget.sections.first,
        ),
      ));

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    if (widget.course.trim().isEmpty) return const SizedBox.shrink();

    return StreamBuilder<(List<Quiz>, Map<String, QuizAttempt>)>(
      stream: _feed,
      builder: (BuildContext context,
          AsyncSnapshot<(List<Quiz>, Map<String, QuizAttempt>)> snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final List<Quiz> quizzes = snap.data!.$1
            .where((Quiz q) => _mine(q) && (widget.isAdmin || q.questionCount > 0))
            .toList()
          ..sort((Quiz a, Quiz b) => (a.createdAt ?? DateTime(0))
              .compareTo(b.createdAt ?? DateTime(0)));
        final Map<String, QuizAttempt> attempts = snap.data!.$2;

        // A member with nothing to take sees nothing.
        if (quizzes.isEmpty && !widget.isAdmin) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    widget.unlocked ? Icons.quiz_outlined : Icons.lock_outline_rounded,
                    size: 18.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(FormatHelper.capitalize(s.sectionQuizzesTitle),
                        style: StyleText.fontSize14Weight600),
                  ),
                  // Quizzes → Create.
                  if (widget.isAdmin &&
                      SessionController.to.current.canDo(AdminAction.quizzesCreate))
                    AppButton(
                      label: s.addSectionQuiz,
                      icon: Icons.add_rounded,
                      kind: AppButtonKind.subtle,
                      dense: true,
                      onPressed: _add,
                    ),
                ],
              ),
              if (!widget.isAdmin && !widget.unlocked) ...<Widget>[
                SizedBox(height: 4.h),
                Text(
                  FormatHelper.capitalize(s.sectionQuizLocked),
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
              ],
              for (final Quiz q in quizzes) ...<Widget>[
                SizedBox(height: 10.h),
                Opacity(
                  opacity: widget.unlocked ? 1 : 0.55,
                  child: QuizCard(
                    quiz: q,
                    // The admin opens the editor only with Quizzes → Edit.
                    onTap: widget.isAdmin &&
                            !SessionController.to.current.canDo(AdminAction.quizzesEdit)
                        ? null
                        : () => _open(q),
                    trailing: _badge(q, attempts[q.id]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget? _badge(Quiz quiz, QuizAttempt? attempt) {
    final S s = S.of(context);
    final String? text = widget.isAdmin
        ? (quiz.published ? null : s.draft)
        : (attempt == null ? null : '${attempt.score}/${attempt.totalPoints}');
    if (text == null) {
      return widget.unlocked || widget.isAdmin
          ? null
          : Icon(Icons.lock_outline_rounded, size: 18.sp, color: AppColors.secondaryText);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        FormatHelper.capitalize(text),
        style: StyleText.fontSize13Weight600.copyWith(color: AppColors.onChip),
      ),
    );
  }
}
