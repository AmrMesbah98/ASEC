/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_editor_cubit.dart
/// Purpose: Declares `QuizEditorCubit` and `QuizEditorState` — the admin's
///          quiz form: questions, the countdown and the open window.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';

enum QuizEditorStatus { editing, saving, saved, failure }

/// What the form got wrong locally, before anything reached Firestore.
enum QuizFormError {
  titleEmpty,
  noQuestions,
  questionsIncomplete,
  windowBackwards,

  /// A certificate quiz must say which course it closes.
  courseMissing,
}

class QuizEditorState {
  final Quiz quiz;
  final QuizEditorStatus status;
  final QuizFormError? formError;
  final AppFailure? failure;

  const QuizEditorState({
    required this.quiz,
    this.status = QuizEditorStatus.editing,
    this.formError,
    this.failure,
  });

  bool get isSaving => status == QuizEditorStatus.saving;

  QuizEditorState copyWith({
    Quiz? quiz,
    QuizEditorStatus? status,
    QuizFormError? formError,
    AppFailure? failure,
    bool clearErrors = false,
  }) {
    return QuizEditorState(
      quiz: quiz ?? this.quiz,
      status: status ?? this.status,
      formError: clearErrors ? null : (formError ?? this.formError),
      failure: clearErrors ? null : (failure ?? this.failure),
    );
  }
}

class QuizEditorCubit extends Cubit<QuizEditorState> {
  QuizEditorCubit({
    Quiz? existing,
    required this.adminUid,
    bool certificate = false,
    String course = '',
    String section = '',
    QuizBaseRepository? repository,
  })  : _repository = repository ?? QuizRepository(),
        _isNew = existing == null,
        super(QuizEditorState(
          quiz: existing ??
              Quiz(
                id: '',
                title: '',
                createdBy: adminUid,
                certificate: certificate,
                course: course,
                section: section,
                questions: <QuizQuestion>[QuizQuestion.blank(_freshId())],
              ),
        ));

  final QuizBaseRepository _repository;
  final String adminUid;

  /// Not final: once a new quiz has been created it HAS an id, and a second
  /// Save must update it rather than create a second copy.
  bool _isNew;

  bool get isNew => _isNew;

  /// Question ids only have to be unique inside one quiz, and they are the
  /// keys of the answers map — a timestamp plus a counter is enough and does
  /// not pull in a uuid package.
  static int _seq = 0;
  static String _freshId() =>
      'q${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  // ── Field edits ──────────────────────────────────────────────────────────

  void setTitle(String value) =>
      emit(state.copyWith(quiz: state.quiz.copyWith(title: value), clearErrors: true));

  void setDescription(String value) =>
      emit(state.copyWith(quiz: state.quiz.copyWith(description: value)));

  /// The countdown, in minutes. 0 = untimed.
  void setDuration(int minutes) {
    final int clamped = minutes < 0
        ? 0
        : (minutes > AppConstants.maxQuizMinutes
            ? AppConstants.maxQuizMinutes
            : minutes);
    emit(state.copyWith(quiz: state.quiz.copyWith(durationMinutes: clamped)));
  }

  void setOpensAt(DateTime? value) => emit(state.copyWith(
        quiz: state.quiz.copyWith(opensAt: value),
        clearErrors: true,
      ));

  void setClosesAt(DateTime? value) => emit(state.copyWith(
        quiz: state.quiz.copyWith(closesAt: value),
        clearErrors: true,
      ));

  void setCourse(String? value) => emit(state.copyWith(
        quiz: state.quiz.copyWith(course: value ?? ''),
        clearErrors: true,
      ));

  /// Links an ordinary quiz to a course section ('' course = a general quiz).
  void setSection(String course, String section) => emit(state.copyWith(
        quiz: state.quiz.copyWith(course: course, section: section),
        clearErrors: true,
      ));

  void setPublished(bool value) =>
      emit(state.copyWith(quiz: state.quiz.copyWith(published: value)));

  // ── Questions ────────────────────────────────────────────────────────────

  void addQuestion() => _withQuestions(<QuizQuestion>[
        ...state.quiz.questions,
        QuizQuestion.blank(_freshId()),
      ]);

  void removeQuestion(String id) => _withQuestions(state.quiz.questions
      .where((QuizQuestion q) => q.id != id)
      .toList());

  void setQuestionText(String id, String text) =>
      _replace(id, (QuizQuestion q) => q.copyWith(text: text));

  void setQuestionPoints(String id, int points) => _replace(
      id, (QuizQuestion q) => q.copyWith(points: points < 1 ? 1 : points));

  void setOption(String id, int index, String value) => _replace(id, (QuizQuestion q) {
        if (index < 0 || index >= q.options.length) return q;
        final List<String> options = List<String>.of(q.options);
        options[index] = value;
        return q.copyWith(options: options);
      });

  void addOption(String id) => _replace(id, (QuizQuestion q) {
        if (q.options.length >= AppConstants.maxOptions) return q;
        return q.copyWith(options: <String>[...q.options, '']);
      });

  void removeOption(String id, int index) => _replace(id, (QuizQuestion q) {
        if (q.options.length <= AppConstants.minOptions) return q;
        final List<String> options = List<String>.of(q.options)..removeAt(index);
        // The marker moves with the list: removing the option ABOVE the
        // correct one must not silently change which answer is right.
        int correct = q.correctIndex;
        if (correct < 0) {
          // No answer chosen yet (an imported question): stays unchosen.
        } else if (index < correct) {
          correct--;
        } else if (index == correct) {
          correct = 0;
        }
        return q.copyWith(options: options, correctIndex: correct);
      });

  void setCorrect(String id, int index) =>
      _replace(id, (QuizQuestion q) => q.copyWith(correctIndex: index));

  void _replace(String id, QuizQuestion Function(QuizQuestion) edit) =>
      _withQuestions(state.quiz.questions
          .map((QuizQuestion q) => q.id == id ? edit(q) : q)
          .toList());

  void _withQuestions(List<QuizQuestion> questions) => emit(state.copyWith(
        quiz: state.quiz.copyWith(questions: questions),
        clearErrors: true,
      ));

  // ── Import / restore (13/11/2026) ────────────────────────────────────────

  /// Questions read from a file (Import from file). [replace] drops the
  /// current ones; otherwise they are added after them.
  void importQuestions(List<QuizQuestion> imported, {required bool replace, String title = ''}) {
    final Quiz quiz = state.quiz;
    emit(state.copyWith(
      quiz: quiz.copyWith(
        questions: replace ? imported : <QuizQuestion>[...quiz.questions, ...imported],
        title: quiz.title.trim().isEmpty && title.trim().isNotEmpty ? title.trim() : null,
      ),
      clearErrors: true,
    ));
  }

  /// The work kept on this device ("Continue where you stopped?").
  void restore(Quiz draft) => emit(state.copyWith(quiz: draft, clearErrors: true));

  /// True after Save for later (the page says "saved as a draft").
  bool savedAsDraft = false;

  /// SAVE FOR LATER: keeps an unfinished quiz as a Draft members cannot see.
  /// Only the closing-before-opening check applies; a missing title becomes
  /// "Untitled quiz". A quiz that is already published is saved normally
  /// (it must stay complete).
  Future<void> saveForLater() async {
    if (state.isSaving) return;
    if (state.quiz.published) return save();
    if (!state.quiz.hasValidWindow) {
      emit(state.copyWith(status: QuizEditorStatus.editing, formError: QuizFormError.windowBackwards));
      return;
    }
    savedAsDraft = true;
    final Quiz draft = state.quiz.copyWith(
      createdBy: adminUid,
      published: false,
      title: state.quiz.title.trim().isEmpty ? 'Untitled quiz' : null,
    );
    emit(state.copyWith(quiz: draft, status: QuizEditorStatus.saving, clearErrors: true));
    await _write(draft);
  }

  Future<void> _write(Quiz quiz) async {
    void fail(AppFailure failure) => emit(state.copyWith(
          status: QuizEditorStatus.failure,
          failure: failure,
        ));
    if (_isNew) {
      final Either<AppFailure, String> result = await _repository.create(quiz);
      if (isClosed) return;
      result.fold(fail, (String id) {
        _isNew = false;
        emit(state.copyWith(status: QuizEditorStatus.saved, quiz: state.quiz.copyWith(id: id)));
      });
      return;
    }
    final Either<AppFailure, Unit> result = await _repository.update(quiz);
    if (isClosed) return;
    result.fold(fail, (_) => emit(state.copyWith(status: QuizEditorStatus.saved)));
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  QuizFormError? _validate() {
    final Quiz quiz = state.quiz;
    if (quiz.title.trim().isEmpty) return QuizFormError.titleEmpty;
    if (quiz.questions.isEmpty) return QuizFormError.noQuestions;
    if (!quiz.questions.every((QuizQuestion q) => q.isComplete)) {
      return QuizFormError.questionsIncomplete;
    }
    if (!quiz.hasValidWindow) return QuizFormError.windowBackwards;
    if (quiz.certificate && quiz.course.trim().isEmpty) {
      return QuizFormError.courseMissing;
    }
    return null;
  }

  Future<void> save() async {
    if (state.isSaving) return;

    final QuizFormError? error = _validate();
    if (error != null) {
      emit(state.copyWith(
        status: QuizEditorStatus.editing,
        formError: error,
      ));
      return;
    }

    emit(state.copyWith(status: QuizEditorStatus.saving, clearErrors: true));

    final Quiz quiz = state.quiz.copyWith(createdBy: adminUid);

    void fail(AppFailure failure) => emit(state.copyWith(
          status: QuizEditorStatus.failure,
          failure: failure,
        ));

    if (_isNew) {
      final Either<AppFailure, String> result =
          await _repository.create(quiz);
      if (isClosed) return;
      result.fold(fail, (String id) {
        _isNew = false;
        emit(state.copyWith(
          status: QuizEditorStatus.saved,
          quiz: state.quiz.copyWith(id: id),
        ));
      });
      return;
    }

    final Either<AppFailure, Unit> result = await _repository.update(quiz);
    if (isClosed) return;
    result.fold(fail, (_) => emit(state.copyWith(status: QuizEditorStatus.saved)));
  }
}
