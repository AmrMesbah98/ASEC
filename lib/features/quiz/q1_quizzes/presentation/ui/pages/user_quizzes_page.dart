/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: user_quizzes_page.dart
/// Purpose: Declares `UserQuizzesPage` — the quizzes a member can see, with
///          the ones they have already taken marked.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_attempt_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_card.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/shared_stream.dart';

/// The quizzes and this member's attempts, as one value.
class _QuizFeed {
  const _QuizFeed(this.quizzes, this.attempts);

  final List<Quiz> quizzes;
  final Map<String, QuizAttempt> attempts;
}

class UserQuizzesPage extends StatefulWidget {
  const UserQuizzesPage({super.key, required this.user});

  final AppUser user;

  @override
  State<UserQuizzesPage> createState() => _UserQuizzesPageState();
}

class _UserQuizzesPageState extends State<UserQuizzesPage> {
  final QuizBaseRepository _repository = QuizRepository();

  late final Stream<_QuizFeed> _feed = shared(() => combineLatest<Object, _QuizFeed>(
    <Stream<Object>>[
      _repository.watchPublished(),
      _repository.watchMyAttempts(widget.user.uid),
    ],
    (List<Object> values) {
      final List<Quiz> quizzes = values[0] as List<Quiz>;
      final List<QuizAttempt> attempts = values[1] as List<QuizAttempt>;
      return _QuizFeed(
        quizzes,
        <String, QuizAttempt>{
          for (final QuizAttempt a in attempts) a.quizId: a,
        },
      );
    },
  ));

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<_QuizFeed>(
        stream: _feed,
        builder: (BuildContext context, AsyncSnapshot<_QuizFeed> snapshot) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown, error: snapshot.error, stackTrace: snapshot.stackTrace);
          if (!snapshot.hasData) return const AppLoading();

          final _QuizFeed feed = snapshot.data!;
          // A quiz with no questions is a draft in all but name; it never
          // reaches a member's list.
          // Certificate quizzes (courses' final exams) live in their own tab.
          final List<Quiz> quizzes = feed.quizzes
              .where((Quiz q) => q.questionCount > 0 && !q.certificate &&
                  // Section quizzes sit at the end of their section in Videos,
                  // locked until its lessons are watched.
                  !q.isSectionQuiz)
              .toList();

          if (quizzes.isEmpty) {
            return ConsolePage(
              title: s.quizzes,
              subtitle: s.quizzesUserSub,
              child: AppEmptyView(
                title: s.noQuizzesTitle,
                subtitle: s.noQuizzesUserSub,
              ),
            );
          }

          return ConsolePage(
            title: s.quizzes,
            subtitle: s.quizzesUserSub,
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GridView.builder(
                padding: EdgeInsets.only(bottom: 24.h),
                gridDelegate: CrossAxisCountHelper.gridDelegate(
                  context,
                  mainAxisExtent: 112,
                  minCellWidth: 320,
                  availableWidth: constraints.maxWidth,
                ),
                itemCount: quizzes.length,
                itemBuilder: (BuildContext context, int index) {
                  final Quiz quiz = quizzes[index];
                  final QuizAttempt? attempt = feed.attempts[quiz.id];

                  return FadeSlideIn(delay: staggerDelay(index, stepMs: 55), child: HoverLift(child: QuizCard(
                    quiz: quiz,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuizAttemptPage(
                          quiz: quiz,
                          user: widget.user,
                        ),
                      ),
                    ),
                    trailing: attempt == null
                        ? null
                        : _ScoreBadge(attempt: attempt),
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

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.onChip;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        FormatHelper.capitalize('${attempt.score}/${attempt.totalPoints}'),
        style: StyleText.fontSize13Weight600.copyWith(color: color),
      ),
    );
  }
}
