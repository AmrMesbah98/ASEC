/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: admin_quizzes_page.dart
/// Purpose: Declares `AdminQuizzesPage` — every quiz, drafts included, with
///          the way in to the editor and to the results.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 1/10/2026 - `certificate: true` makes it the "Certificate
///          quizzes" tab: only courses' final exams, created with a course.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_attempts_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_editor_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_card.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_page.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/network/shared_stream.dart';

class AdminQuizzesPage extends StatefulWidget {
  const AdminQuizzesPage({
    super.key,
    required this.adminUid,
    this.certificate = false,
  });

  final String adminUid;

  /// True = the "Certificate quizzes" tab; false = the ordinary quizzes.
  final bool certificate;

  @override
  State<AdminQuizzesPage> createState() => _AdminQuizzesPageState();
}

class _AdminQuizzesPageState extends State<AdminQuizzesPage> {
  final QuizBaseRepository _repository = QuizRepository();
  late final Stream<List<Quiz>> _quizzes = shared(() => _repository.watchAll());

  AppUser get _me => SessionController.to.current;

  Future<void> _openEditor([Quiz? quiz]) => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => QuizEditorPage(
            quiz: quiz,
            adminUid: widget.adminUid,
            certificate: widget.certificate,
          ),
        ),
      );

  Future<void> _confirmDelete(Quiz quiz) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.deleteQuestion(quiz.title),
      subtitle: s.deleteQuizBody,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      onConfirm: () async {
        final AppMessenger messenger = AppMessenger.of(context);
        final String deleted = s.deleted;
        await _repository.delete(quiz.id);
        messenger.show(AppMessage(content: Text(FormatHelper.capitalize(deleted))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool cert = widget.certificate;
    final String title = cert ? s.certificateQuizzes : s.quizzes;
    final String subtitle = cert ? s.certificateQuizzesAdminSub : s.quizzesAdminSub;
    // CERTIFICATE QUIZZES: see what the member's certificate looks like.
    final List<Widget> actions = !cert
        ? const <Widget>[]
        : <Widget>[
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CertificatePage.of(data: CertificateData.sample(), sample: true),
              )),
              icon: AppIcon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
              label: Text(FormatHelper.capitalize(s.certPreview)),
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      // Quizzes → Create (Certificate quizzes need that action too).
      floatingActionButton: !SessionController.to.current.canDo(AdminAction.quizzesCreate)
          ? null
          : FloatingActionButton.extended(
        // Unique per section: see the videos FAB for why.
        heroTag: cert ? 'asec_fab_cert_quizzes' : 'asec_fab_quizzes',
        onPressed: _openEditor,
        backgroundColor: AppColors.primary,
        icon: AppIcon(
          cert ? Icons.workspace_premium_rounded : Icons.add_rounded,
          color: AppColors.textButton,
        ),
        label: Text(
          FormatHelper.capitalize(cert ? s.newCertificateQuiz : s.newQuiz),
          style: StyleText.fontSize14Weight600.copyWith(color: AppColors.textButton),
        ),
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: _quizzes,
        builder: (BuildContext context, AsyncSnapshot<List<Quiz>> snapshot) {
          if (snapshot.hasError) {
            return AppErrorView(
              message: S.of(context).errUnknown,
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
          }
          if (!snapshot.hasData) return const AppLoading();

          // Each tab shows its own kind.
          final List<Quiz> quizzes = snapshot.data!
              .where((Quiz q) => q.certificate == cert)
              .toList();
          if (quizzes.isEmpty) {
            return ConsolePage(
              title: title,
              subtitle: subtitle,
              actions: actions,
              child: AppEmptyView(
                title: cert ? s.noCertificateQuizzesTitle : s.noQuizzesTitle,
                subtitle: cert ? s.noCertificateQuizzesAdminSub : s.noQuizzesAdminSub,
              ),
            );
          }

          return ConsolePage(
            title: title,
            subtitle: subtitle,
            actions: actions,
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GridView.builder(
                padding: EdgeInsets.only(bottom: 96.h),
                gridDelegate: CrossAxisCountHelper.gridDelegate(
                  context,
                  mainAxisExtent: 112,
                  minCellWidth: 320,
                  availableWidth: constraints.maxWidth,
                ),
                itemCount: quizzes.length,
                itemBuilder: (BuildContext context, int index) {
                  final Quiz quiz = quizzes[index];
                  return FadeSlideIn(delay: staggerDelay(index, stepMs: 55), child: HoverLift(child: QuizCard(
                    quiz: quiz,
                    onTap: _me.canDo(AdminAction.quizzesEdit)
                        ? () => _openEditor(quiz)
                        : null,
                    trailing: _QuizMenu(
                      quiz: quiz,
                      canEdit: _me.canDo(AdminAction.quizzesEdit),
                      canOpen: _me.canDo(AdminAction.quizzesOpen),
                      canDelete: _me.canDo(AdminAction.quizzesDelete),
                      onEdit: () => _openEditor(quiz),
                      onResults: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuizAttemptsPage(quiz: quiz),
                        ),
                      ),
                      onTogglePublished: () => _repository.setPublished(
                        quiz.id,
                        !quiz.published,
                      ),
                      onDelete: () => _confirmDelete(quiz),
                    ),
                  )));
                },
              );
            },
          ),
          );
        },
      ),
    );
  }
}

enum _QuizAction { edit, results, publish, delete }

class _QuizMenu extends StatelessWidget {
  const _QuizMenu({
    required this.quiz,
    required this.canEdit,
    required this.canOpen,
    required this.canDelete,
    required this.onEdit,
    required this.onResults,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final Quiz quiz;
  final bool canEdit;
  final bool canOpen;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onResults;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return PopupMenuButton<_QuizAction>(
      icon: AppIcon(Icons.more_vert_rounded, size: 20.sp),
      onSelected: (_QuizAction action) {
        switch (action) {
          case _QuizAction.edit:
            onEdit();
          case _QuizAction.results:
            onResults();
          case _QuizAction.publish:
            onTogglePublished();
          case _QuizAction.delete:
            onDelete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_QuizAction>>[
        if (canEdit)
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.edit,
          child: Text(FormatHelper.capitalize(s.edit)),
        ),
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.results,
          child: Text(FormatHelper.capitalize(s.results)),
        ),
        if (canOpen)
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.publish,
          child: Text(FormatHelper.capitalize(quiz.published ? s.switchOff : s.publish)),
        ),
        if (canDelete)
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.delete,
          child: Text(
            FormatHelper.capitalize(s.delete),
            style: StyleText.fontSize14Weight500.copyWith(color: AppColors.red),
          ),
        ),
      ],
    );
  }
}
