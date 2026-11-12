/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_integrity_event.dart
/// Purpose: Declares `QuizIntegrityEvent` — a screenshot, a screen recording
///          or leaving the app during a quiz, saved on the attempt so the
///          admin sees it.
/// Created: 13/11/2026

class QuizIntegrityEvent {
  const QuizIntegrityEvent({required this.type, required this.at, this.seconds = 0});

  /// 'screenshot', 'recording' or 'left_app'.
  final String type;
  final DateTime at;

  /// For 'left_app': how long they stayed away.
  final int seconds;

  /// What happened, in the app's language.
  String label(bool arabic) => switch (type) {
        'screenshot' => arabic ? 'حاول أخذ لقطة شاشة' : 'Tried to take a screenshot',
        'recording' => arabic ? 'بدأ تسجيل الشاشة' : 'Started a screen recording',
        'left_app' => seconds > 0
            ? (arabic ? 'خرج من الاختبار لمدة ${formatAwayTime(seconds)}' : 'Left the quiz for ${formatAwayTime(seconds)}')
            : (arabic ? 'خرج من الاختبار' : 'Left the quiz'),
        _ => type,
      };
}

/// "1m 05s" — how long someone was away from a quiz.
String formatAwayTime(int seconds) =>
    seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}m ${(seconds % 60).toString().padLeft(2, '0')}s';
