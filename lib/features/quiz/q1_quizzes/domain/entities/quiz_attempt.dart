/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_attempt.dart
/// Purpose: Declares `QuizAttempt` — one member's run at one quiz.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_integrity_event.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';

/// Stored at `attempts/{quizId}_{uid}` — one per member per quiz, so the id
/// itself enforces "one attempt" and the rules can read the owner off the path.
class QuizAttempt {
  final String id;
  final String quizId;
  final String quizTitle;
  final String userId;
  final String userName;

  /// Stored on the attempt rather than looked up later: the admin's results
  /// table must still name the person after the account is gone.
  final String userEmail;

  /// question id -> the index the member chose. A question they skipped is
  /// simply absent.
  final Map<String, int> answers;

  final int score;
  final int totalPoints;
  final int correctCount;
  final int questionCount;

  final DateTime? startedAt;
  final DateTime? submittedAt;

  /// True when the countdown ran out and the app submitted for them.
  final bool autoSubmitted;

  /// Certificate quizzes: the score reached [Quiz.passPercent]. A passed
  /// attempt is final — it is the certificate.
  final bool passed;

  /// Certificate quizzes: how many times the member has sat it (1 = first).
  final int tries;

  /// 13/11/2026: screenshots / screen recordings during the quiz.
  final int screenshots;
  final int recordings;

  /// Times the member left the quiz (minimised, switched app or window,
  /// locked the phone) and the total time away.
  final int leftApp;
  final int awaySeconds;

  /// What happened, oldest first (the first 100).
  final List<QuizIntegrityEvent> events;

  bool get hasWarnings => screenshots > 0 || recordings > 0 || leftApp > 0;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    this.quizTitle = '',
    this.userName = '',
    this.userEmail = '',
    this.answers = const <String, int>{},
    this.score = 0,
    this.totalPoints = 0,
    this.correctCount = 0,
    this.questionCount = 0,
    this.startedAt,
    this.submittedAt,
    this.autoSubmitted = false,
    this.passed = false,
    this.tries = 1,
    this.screenshots = 0,
    this.recordings = 0,
    this.leftApp = 0,
    this.awaySeconds = 0,
    this.events = const <QuizIntegrityEvent>[],
  });

  double get percent => totalPoints == 0 ? 0 : (score / totalPoints) * 100;

  /// How long the sitting actually took. Null until both ends are known.
  Duration? get timeTaken => startedAt == null || submittedAt == null
      ? null
      : submittedAt!.difference(startedAt!);

  /// Questions they never touched — a blank is wrong, but it is a different
  /// kind of wrong and the admin can see which.
  int blanksIn(List<String> questionIds) =>
      questionIds.where((String id) => !answers.containsKey(id)).length;

  /// Marks [answers] against [quiz]. The client computes this for the result
  /// screen; `firestore.rules` treats the stored score as a claim the admin
  /// can always re-check against the same answers.
  factory QuizAttempt.marked({
    required Quiz quiz,
    required String userId,
    required String userName,
    required String userEmail,
    required Map<String, int> answers,
    required DateTime startedAt,
    required DateTime submittedAt,
    bool autoSubmitted = false,
    int tries = 1,
    int screenshots = 0,
    int recordings = 0,
    int leftApp = 0,
    int awaySeconds = 0,
    List<QuizIntegrityEvent> events = const <QuizIntegrityEvent>[],
  }) {
    int score = 0;
    int correct = 0;
    for (final QuizQuestion question in quiz.questions) {
      if (question.isCorrect(answers[question.id])) {
        score += question.points;
        correct++;
      }
    }
    return QuizAttempt(
      id: '',
      quizId: quiz.id,
      quizTitle: quiz.title,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      answers: answers,
      score: score,
      totalPoints: quiz.totalPoints,
      correctCount: correct,
      questionCount: quiz.questionCount,
      startedAt: startedAt,
      submittedAt: submittedAt,
      autoSubmitted: autoSubmitted,
      passed: quiz.totalPoints > 0 &&
          score * 100 >= Quiz.passPercent * quiz.totalPoints,
      tries: tries,
      screenshots: screenshots,
      recordings: recordings,
      leftApp: leftApp,
      awaySeconds: awaySeconds,
      events: events,
    );
  }
}
