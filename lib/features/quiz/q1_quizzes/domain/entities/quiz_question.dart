/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_question.dart
/// Purpose: Declares `QuizQuestion` — one multiple-choice question.
/// Author: ASEC team
/// Created: 19/9/2026

/// Multiple choice, exactly one right answer, marked by the app.
///
/// [correctIndex] is an index into [options] rather than a copy of the right
/// answer's text: editing an option's wording then cannot silently make a
/// question unmarkable.
class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final int points;

  /// The question text WITH its formatting (bold, colours, sizes, lists…),
  /// as a Quill delta (16/11/2026, as ENGX). [text] keeps the plain words for
  /// exports, search and older app versions. Empty = plain [text] only.
  final List<dynamic> rich;

  /// Pictures shown with the question: R2 keys (`lessons/quiz_…`).
  final List<String> images;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.correctIndex = 0,
    this.points = 1,
    this.rich = const <dynamic>[],
    this.images = const <String>[],
  });

  /// A blank question, ready for the editor. [id] must be unique within the
  /// quiz — the answers map on an attempt is keyed by it.
  factory QuizQuestion.blank(String id) => QuizQuestion(
        id: id,
        text: '',
        options: const <String>['', ''],
      );

  /// Everything filled in and the correct answer pointing at a real option.
  bool get isComplete =>
      (text.trim().isNotEmpty || images.isNotEmpty) &&
      options.length >= 2 &&
      options.every((String o) => o.trim().isNotEmpty) &&
      correctIndex >= 0 &&
      correctIndex < options.length;

  bool isCorrect(int? answerIndex) => answerIndex == correctIndex;

  QuizQuestion copyWith({
    String? text,
    List<String>? options,
    int? correctIndex,
    int? points,
    List<dynamic>? rich,
    List<String>? images,
  }) {
    final List<String> nextOptions = options ?? this.options;
    int nextCorrect = correctIndex ?? this.correctIndex;
    // An option removed from under the marker must not leave it dangling.
    if (nextCorrect >= nextOptions.length) {
      nextCorrect = nextOptions.isEmpty ? 0 : nextOptions.length - 1;
    }
    return QuizQuestion(
      id: id,
      text: text ?? this.text,
      options: nextOptions,
      correctIndex: nextCorrect,
      points: points ?? this.points,
      rich: rich ?? this.rich,
      images: images ?? this.images,
    );
  }
}
