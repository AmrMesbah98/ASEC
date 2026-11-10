/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_data.dart
/// Purpose: Declares `CertificateData` — what an ASEC certificate says, taken
///          from a passed certificate quiz attempt. One source for the
///          on-screen certificate and the PDF, so the two never disagree.
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:intl/intl.dart';

import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';

class CertificateData {
  const CertificateData({
    required this.name,
    required this.course,
    required this.examTitle,
    this.percent,
    required this.date,
    required this.number,
    this.finalExam = true,
    this.subject = '',
    this.correct,
    this.questions,
    this.points,
    this.totalPoints,
    this.duration,
    this.tries,
  });

  /// Any passed quiz (10/11/2026): a course's final exam names the course;
  /// any other quiz names the quiz, with its course under it. Both carry
  /// the attempt's data — score, correct answers, points, time, attempt.
  factory CertificateData.from(Quiz quiz, QuizAttempt attempt) {
    final bool finalExam = quiz.certificate;
    final String course = finalExam
        ? (quiz.course.trim().isNotEmpty ? quiz.course.trim() : quiz.title.trim())
        : quiz.title.trim();
    return CertificateData(
      finalExam: finalExam,
      subject: finalExam || quiz.course.trim() == quiz.title.trim() ? '' : quiz.course.trim(),
      correct: attempt.correctCount,
      questions: attempt.questionCount,
      points: attempt.score,
      totalPoints: attempt.totalPoints,
      duration: attempt.timeTaken,
      tries: attempt.tries,
      name: attempt.userName.trim().isNotEmpty
          ? attempt.userName.trim()
          : attempt.userEmail.split('@').first,
      course: course,
      examTitle: quiz.title.trim(),
      percent: attempt.percent.round(),
      date: attempt.submittedAt ?? DateTime.now(),
      number: numberFor('${quiz.id}_${attempt.userId}'),
    );
  }

  /// A certificate the admin issued to a member by hand — no exam.
  factory CertificateData.issued({
    required String name,
    required String course,
    required String uid,
    DateTime? date,
  }) =>
      CertificateData(
        name: name.trim(),
        course: course.trim(),
        examTitle: course.trim(),
        date: date ?? DateTime.now(),
        number: numberFor('issued_${course.trim().toLowerCase()}_$uid'),
      );

  /// What the admin's "Preview certificate" shows.
  factory CertificateData.sample({String course = 'AutoCAD'}) => CertificateData(
        name: 'Ahmed Mohamed',
        course: course,
        examTitle: course,
        percent: 92,
        date: DateTime.now(),
        number: numberFor('sample_$course'),
        correct: 23,
        questions: 25,
        points: 46,
        totalPoints: 50,
        duration: const Duration(minutes: 18, seconds: 40),
        tries: 1,
      );

  final String name;
  final String course;
  final String examTitle;

  /// The exam score; null for a certificate the admin issued by hand.
  final int? percent;
  final DateTime date;

  /// "ASEC-7K2Q9XA" — stable for one member and one exam.
  final String number;

  /// True: a course's final exam (or issued by hand). False: any other
  /// quiz the member passed.
  final bool finalExam;

  /// A quiz's course, shown under the quiz title. Empty for a final exam.
  final String subject;

  final int? correct;
  final int? questions;
  final int? points;
  final int? totalPoints;
  final Duration? duration;
  final int? tries;

  /// The attempt's data is known (not issued by hand, not the preview).
  bool get hasDetails => percent != null && questions != null;

  String get completedLine => finalExam
      ? 'has successfully completed the course'
      : 'has successfully passed the quiz';

  String get scoreLine => finalExam
      ? 'and passed the final exam with a score of $percent%'
      : subject.isEmpty
          ? 'with a score of $percent%'
          : 'of the $subject course with a score of $percent%';

  /// "12m 05s", "1h 02m", or "—" when the time is unknown.
  String get timeLabel {
    final Duration? d = duration;
    if (d == null || d.isNegative) return '—';
    final String m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}h ${m}m';
    return '${d.inMinutes}m ${sec}s';
  }

  /// Label → value, in the order the certificate shows them.
  List<(String, String)> get details => <(String, String)>[
        ('Score', '$percent%'),
        ('Correct Answers', '${correct ?? 0}/${questions ?? 0}'),
        if ((totalPoints ?? 0) > 0) ('Points', '${points ?? 0}/$totalPoints'),
        ('Time Taken', timeLabel),
        if (tries != null) ('Attempt', '$tries'),
      ];

  String get dateLabel => DateFormat('d MMMM yyyy', 'en').format(date);

  String get fileName => 'ASEC-Certificate-$number.pdf';

  static bool isArabic(String text) => RegExp(r'[؀-ۿ]').hasMatch(text);

  /// FNV-1a of the attempt id, in base 36.
  static String numberFor(String key) {
    int hash = 0x811c9dc5;
    for (final int unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'ASEC-${hash.toRadixString(36).toUpperCase().padLeft(7, '0')}';
  }
}
