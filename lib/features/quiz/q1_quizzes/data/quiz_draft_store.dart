/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_draft_store.dart
/// Purpose: "Save for later" on this device — the quiz being written is kept
///          on every change, so closing the editor (or the app) loses
///          nothing. Opening the same quiz, or "New quiz", again offers to
///          continue from it. The server Draft (Save for later button) is
///          separate; this also covers work never saved to the server.
/// Created: 13/11/2026

import 'package:get_storage/get_storage.dart';

import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';

class QuizLocalDraft {
  const QuizLocalDraft({required this.quiz, required this.savedAt});

  final Quiz quiz;
  final DateTime savedAt;
}

abstract final class QuizDraftStore {
  static const String _prefix = 'quiz_draft_v1:';

  static final GetStorage _box = GetStorage();

  /// New quizzes share one slot; existing quizzes use their id.
  static String _key(String quizId) => '$_prefix${quizId.isEmpty ? 'new' : quizId}';

  static Future<void> save(String slotId, Quiz quiz) async {
    try {
      await _box.write(_key(slotId), <String, dynamic>{
        'saved_at': DateTime.now().toIso8601String(),
        'title': quiz.title,
        'description': quiz.description,
        'duration_minutes': quiz.durationMinutes,
        'opens_at': quiz.opensAt?.toIso8601String(),
        'closes_at': quiz.closesAt?.toIso8601String(),
        'certificate': quiz.certificate,
        'course': quiz.course,
        'section': quiz.section,
        'questions': <Map<String, dynamic>>[
          for (final QuizQuestion q in quiz.questions)
            <String, dynamic>{
              'id': q.id,
              'text': q.text,
              'options': q.options,
              'correct_index': q.correctIndex,
              'points': q.points,
            },
        ],
      });
    } catch (_) {
      // Best effort: the server Draft is the real save.
    }
  }

  /// The draft for [slotId], applied on top of [base] (which keeps the id,
  /// published flag and author of the quiz being edited).
  static QuizLocalDraft? load(String slotId, Quiz base) {
    try {
      final Object? raw = _box.read<Object?>(_key(slotId));
      if (raw is! Map) return null;
      final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
      String str(String k) => (m[k] as String?) ?? '';
      final List<QuizQuestion> questions = <QuizQuestion>[
        for (final Object? q in (m['questions'] as List<dynamic>? ?? const <dynamic>[]))
          if (q is Map)
            QuizQuestion(
              id: '${q['id']}',
              text: '${q['text'] ?? ''}',
              options: <String>[for (final Object? o in (q['options'] as List<dynamic>? ?? const <dynamic>[])) '$o'],
              correctIndex: (q['correct_index'] as num?)?.toInt() ?? -1,
              points: (q['points'] as num?)?.toInt() ?? 1,
            ),
      ];
      return QuizLocalDraft(
        quiz: base.copyWith(
          title: str('title'),
          description: str('description'),
          durationMinutes: (m['duration_minutes'] as num?)?.toInt() ?? 0,
          opensAt: DateTime.tryParse(str('opens_at')),
          closesAt: DateTime.tryParse(str('closes_at')),
          certificate: m['certificate'] == true,
          course: str('course'),
          section: str('section'),
          questions: questions,
        ),
        savedAt: DateTime.tryParse(str('saved_at')) ?? DateTime.now(),
      );
    } catch (_) {
      return null; // a broken draft is simply ignored
    }
  }

  static Future<void> clear(String slotId) async {
    try {
      await _box.remove(_key(slotId));
    } catch (_) {}
  }
}
