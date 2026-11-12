/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_model.dart
/// Purpose: Declares `QuizModel` and `QuizAttemptModel` — the `quizzes/{id}`
///          and `attempts/{id}` document shapes.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_integrity_event.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';

/// Field names here MUST match the `onlyKeys` lists in firestore.rules.
abstract final class QuizModel {
  const QuizModel._();

  static const String title = 'title';
  static const String description = 'description';
  static const String durationMinutes = 'duration_minutes';
  static const String opensAt = 'opens_at';
  static const String closesAt = 'closes_at';
  static const String questions = 'questions';
  static const String questionCount = 'question_count';
  static const String totalPoints = 'total_points';
  static const String createdBy = 'created_by';
  static const String certificate = 'certificate';
  static const String course = 'course';
  static const String section = 'section';

  // Inside one element of `questions`.
  static const String qId = 'id';
  static const String qText = 'text';
  static const String qOptions = 'options';
  static const String qCorrectIndex = 'correct_index';
  static const String qPoints = 'points';

  static Quiz fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.safeData;
    final Object? rawQuestions = data[questions];

    return Quiz(
      id: doc.id,
      title: data.str(title),
      description: data.str(description),
      durationMinutes: data.integer(durationMinutes),
      opensAt: data.date(opensAt),
      closesAt: data.date(closesAt),
      published: data.boolean(FirebaseCollections.publishedField),
      certificate: data.boolean(certificate),
      course: data.str(course).trim(),
      section: data.str(section).trim(),
      questions: rawQuestions is List
          ? rawQuestions
              .whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> raw) =>
                  _questionFrom(Map<String, dynamic>.from(raw)))
              .toList()
          : const <QuizQuestion>[],
      createdBy: data.str(createdBy),
      createdAt: data.date(FirebaseCollections.createdAtField),
      updatedAt: data.date(FirebaseCollections.updatedAtField),
    );
  }

  static QuizQuestion _questionFrom(Map<String, dynamic> data) {
    final List<String> options = data.stringList(qOptions);
    final int correct = data.integer(qCorrectIndex);
    return QuizQuestion(
      id: data.str(qId),
      text: data.str(qText),
      options: options,
      // A correct_index edited out of range in the console must not crash the
      // marking; it just marks nothing right.
      correctIndex:
          correct >= 0 && correct < options.length ? correct : -1,
      points: data.integer(qPoints, 1),
    );
  }

  /// The whole quiz. Used for create AND update, so an edit can never leave
  /// the denormalised counts disagreeing with the questions.
  static Map<String, dynamic> toMap(Quiz quiz, {bool isCreate = false}) {
    return <String, dynamic>{
      title: quiz.title.trim(),
      description: quiz.description.trim(),
      durationMinutes: quiz.durationMinutes,
      opensAt: quiz.opensAt == null ? null : Timestamp.fromDate(quiz.opensAt!),
      closesAt:
          quiz.closesAt == null ? null : Timestamp.fromDate(quiz.closesAt!),
      FirebaseCollections.publishedField: quiz.published,
      certificate: quiz.certificate,
      course: quiz.course.trim(),
      section: quiz.section.trim(),
      questions: <Map<String, dynamic>>[
        for (final QuizQuestion q in quiz.questions)
          <String, dynamic>{
            qId: q.id,
            qText: q.text.trim(),
            qOptions: <String>[
              for (final String option in q.options) option.trim(),
            ],
            qCorrectIndex: q.correctIndex,
            qPoints: q.points,
          },
      ],
      // Denormalised so a list of quizzes needs no per-quiz maths, and so the
      // rules can bound the size of what is written.
      questionCount: quiz.questionCount,
      totalPoints: quiz.totalPoints,
      createdBy: quiz.createdBy,
      if (isCreate)
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
    };
  }
}

abstract final class QuizAttemptModel {
  const QuizAttemptModel._();

  static const String quizTitle = 'quiz_title';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String answers = 'answers';
  static const String score = 'score';
  static const String totalPoints = 'total_points';
  static const String correctCount = 'correct_count';
  static const String questionCount = 'question_count';
  static const String startedAt = 'started_at';
  static const String autoSubmitted = 'auto_submitted';
  static const String passed = 'passed';
  static const String tries = 'tries';
  static const String screenshots = 'screenshots';
  static const String recordings = 'screen_recordings';
  static const String leftApp = 'left_app';
  static const String awaySeconds = 'away_seconds';
  static const String events = 'events';

  static QuizAttempt fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.safeData;
    final Map<String, dynamic> rawAnswers = data.nested(answers);

    return QuizAttempt(
      id: doc.id,
      quizId: data.str(FirebaseCollections.quizIdField),
      quizTitle: data.str(quizTitle),
      userId: data.str(FirebaseCollections.userIdField),
      userName: data.str(userName),
      userEmail: data.str(userEmail),
      answers: <String, int>{
        for (final MapEntry<String, dynamic> e in rawAnswers.entries)
          if (e.value is num) e.key: (e.value as num).toInt(),
      },
      score: data.integer(score),
      totalPoints: data.integer(totalPoints),
      correctCount: data.integer(correctCount),
      questionCount: data.integer(questionCount),
      startedAt: data.date(startedAt),
      submittedAt: data.date(FirebaseCollections.submittedAtField),
      autoSubmitted: data.boolean(autoSubmitted),
      passed: data.boolean(passed),
      tries: data.integer(tries, 1),
      screenshots: data.integer(screenshots),
      recordings: data.integer(recordings),
      leftApp: data.integer(leftApp),
      awaySeconds: data.integer(awaySeconds),
      events: <QuizIntegrityEvent>[
        if (data[events] is List)
          for (final Object? e in data[events] as List<dynamic>)
            if (e is Map)
              QuizIntegrityEvent(
                type: '${e['type'] ?? ''}',
                at: e['at'] is Timestamp
                    ? (e['at'] as Timestamp).toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0),
                seconds: (e['seconds'] as num?)?.toInt() ?? 0,
              ),
      ],
    );
  }

  static Map<String, dynamic> toMap(QuizAttempt attempt) => <String, dynamic>{
        FirebaseCollections.quizIdField: attempt.quizId,
        quizTitle: attempt.quizTitle,
        FirebaseCollections.userIdField: attempt.userId,
        userName: attempt.userName,
        userEmail: attempt.userEmail,
        answers: attempt.answers,
        score: attempt.score,
        totalPoints: attempt.totalPoints,
        correctCount: attempt.correctCount,
        questionCount: attempt.questionCount,
        startedAt: attempt.startedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(attempt.startedAt!),
        FirebaseCollections.submittedAtField: FieldValue.serverTimestamp(),
        autoSubmitted: attempt.autoSubmitted,
        passed: attempt.passed,
        tries: attempt.tries,
        screenshots: attempt.screenshots,
        recordings: attempt.recordings,
        leftApp: attempt.leftApp,
        awaySeconds: attempt.awaySeconds,
        events: <Map<String, dynamic>>[
          for (final QuizIntegrityEvent e in attempt.events.take(100))
            <String, dynamic>{
              'type': e.type,
              'at': Timestamp.fromDate(e.at),
              if (e.seconds > 0) 'seconds': e.seconds,
            },
        ],
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      };
}
