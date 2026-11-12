/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_attempt_cubit.dart
/// Purpose: Declares `QuizAttemptCubit` and `QuizAttemptState` — taking a
///          quiz: the countdown, the answers, and submitting.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/quiz/q1_quizzes/data/quiz_integrity_monitor.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_integrity_event.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/enums/quiz_window_state.dart';

enum AttemptStage {
  loading,

  /// The rules of the quiz, and the button that starts the clock.
  intro,

  /// The window is shut, or the quiz was unpublished while they looked at it.
  unavailable,

  /// Answering. [QuizAttemptState.remaining] is counting down.
  running,

  submitting,

  /// Done — [QuizAttemptState.attempt] holds the marked result.
  finished,

  failure,
}

class QuizAttemptState {
  final AttemptStage stage;
  final Quiz quiz;
  final QuizWindowState window;

  /// question id -> chosen option index.
  final Map<String, int> answers;

  final int currentIndex;

  /// Null when nothing bounds this attempt (untimed AND no closing time).
  final Duration? remaining;

  /// The submitted attempt — set once, when the stage becomes `finished`.
  final QuizAttempt? attempt;

  /// True when this result is one they took earlier, not one they just sat.
  final bool wasAlreadyTaken;

  /// Certificate quizzes: their last attempt that did NOT pass, shown on the
  /// intro of a retake ("last try 55% — you need 70%").
  final QuizAttempt? previous;

  final AppFailure? failure;

  const QuizAttemptState({
    this.stage = AttemptStage.loading,
    this.quiz = Quiz.empty,
    this.window = QuizWindowState.open,
    this.answers = const <String, int>{},
    this.currentIndex = 0,
    this.remaining,
    this.attempt,
    this.wasAlreadyTaken = false,
    this.previous,
    this.failure,
  });

  int get answeredCount => answers.length;

  bool get isLastQuestion => currentIndex >= quiz.questionCount - 1;

  /// True in the last minute — the UI turns the clock red.
  bool get isRunningOut =>
      remaining != null && remaining! <= const Duration(minutes: 1);

  QuizAttemptState copyWith({
    AttemptStage? stage,
    Quiz? quiz,
    QuizWindowState? window,
    Map<String, int>? answers,
    int? currentIndex,
    Duration? remaining,
    QuizAttempt? attempt,
    bool? wasAlreadyTaken,
    QuizAttempt? previous,
    AppFailure? failure,
  }) {
    return QuizAttemptState(
      stage: stage ?? this.stage,
      quiz: quiz ?? this.quiz,
      window: window ?? this.window,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      remaining: remaining ?? this.remaining,
      attempt: attempt ?? this.attempt,
      wasAlreadyTaken: wasAlreadyTaken ?? this.wasAlreadyTaken,
      previous: previous ?? this.previous,
      failure: failure ?? this.failure,
    );
  }
}

/// One member, one quiz, one sitting.
///
/// THE CLOCK IS NOT A COUNTER. It is recomputed from `startedAt` and the wall
/// clock on every tick rather than decremented, so a paused app, a dropped
/// frame or a backgrounded phone cannot buy anybody extra time.
class QuizAttemptCubit extends Cubit<QuizAttemptState> {
  QuizAttemptCubit({
    required this.quiz,
    required this.userId,
    required this.userName,
    required this.userEmail,
    QuizBaseRepository? repository,
  })  : _repository = repository ?? QuizRepository(),
        super(QuizAttemptState(quiz: quiz));

  final QuizBaseRepository _repository;
  final Quiz quiz;
  final String userId;
  final String userName;
  final String userEmail;

  Timer? _ticker;
  DateTime? _startedAt;

  /// 13/11/2026: screenshots and leaving the quiz, counted while it runs —
  /// shown to the member live and saved on the attempt for the admin.
  final QuizIntegrityMonitor monitor = QuizIntegrityMonitor();

  /// Looks for an earlier attempt, then either shows it or offers the intro.
  Future<void> load() async {
    final QuizWindowState window = quiz.windowStateAt(DateTime.now());

    QuizAttempt? previous;
    try {
      previous = await _repository.fetchAttempt(quiz.id, userId);
    } catch (_) {
      // A failed lookup must not block somebody out of a quiz they have not
      // taken; the write itself is refused by the rules if they have.
      previous = null;
    }
    if (isClosed) return;

    // A certificate quiz not passed yet may be sat again: straight to the
    // intro, with the last score shown.
    if (previous != null && quiz.certificate && !previous.passed) {
      emit(state.copyWith(
        stage: window.isOpen && quiz.questionCount > 0
            ? AttemptStage.intro
            : AttemptStage.unavailable,
        window: window,
        previous: previous,
      ));
      return;
    }

    if (previous != null) {
      emit(state.copyWith(
        stage: AttemptStage.finished,
        attempt: previous,
        answers: previous.answers,
        wasAlreadyTaken: true,
        window: window,
      ));
      return;
    }

    emit(state.copyWith(
      stage: window.isOpen && quiz.questionCount > 0
          ? AttemptStage.intro
          : AttemptStage.unavailable,
      window: window,
    ));
  }

  /// Certificate quizzes: after a failed result, back to the intro for
  /// another sitting.
  void retake() {
    if (!quiz.certificate || state.stage != AttemptStage.finished) return;
    final QuizAttempt? last = state.attempt;
    if (last == null || last.passed) return;
    emit(QuizAttemptState(
      stage: AttemptStage.intro,
      quiz: quiz,
      window: quiz.windowStateAt(DateTime.now()),
      previous: last,
    ));
  }

  void start() {
    if (state.stage != AttemptStage.intro) return;
    _startedAt = DateTime.now();
    monitor.start();
    emit(state.copyWith(
      stage: AttemptStage.running,
      currentIndex: 0,
      remaining: quiz.runsForever ? null : _computeRemaining(),
    ));
    if (!quiz.runsForever) {
      _ticker =
          Timer.periodic(const Duration(seconds: 1), (Timer _) => _tick());
    }
  }

  Duration _computeRemaining() =>
      quiz.remainingFor(_startedAt ?? DateTime.now(), DateTime.now());

  void _tick() {
    if (isClosed || state.stage != AttemptStage.running) return;
    final Duration left = _computeRemaining();
    if (left <= Duration.zero) {
      _stopTicker();
      emit(state.copyWith(remaining: Duration.zero));
      submit(auto: true);
      return;
    }
    emit(state.copyWith(remaining: left));
  }

  void answer(String questionId, int optionIndex) {
    if (state.stage != AttemptStage.running) return;
    emit(state.copyWith(
      answers: <String, int>{...state.answers, questionId: optionIndex},
    ));
  }

  void goTo(int index) {
    if (index < 0 || index >= quiz.questionCount) return;
    emit(state.copyWith(currentIndex: index));
  }

  void next() => goTo(state.currentIndex + 1);
  void previous() => goTo(state.currentIndex - 1);

  Future<void> submit({bool auto = false}) async {
    if (state.stage != AttemptStage.running) return;
    _stopTicker();
    monitor.stop();
    emit(state.copyWith(stage: AttemptStage.submitting));

    final QuizAttempt marked = QuizAttempt.marked(
      quiz: quiz,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      answers: state.answers,
      startedAt: _startedAt ?? DateTime.now(),
      submittedAt: DateTime.now(),
      autoSubmitted: auto,
      tries: (state.previous?.tries ?? 0) + 1,
      screenshots: monitor.screenshots,
      recordings: monitor.recordings,
      leftApp: monitor.leftApp,
      awaySeconds: monitor.awaySeconds,
      events: List<QuizIntegrityEvent>.of(monitor.events),
    );

    final Either<AppFailure, Unit> result =
        await _repository.submitAttempt(marked);
    if (isClosed) return;

    result.fold(
      (AppFailure failure) {
        monitor.resume(); // still answering: keep counting
        emit(state.copyWith(
        // Back to answering: their answers are still in memory, so a retry
        // after a dropped connection does not lose the sitting.
        stage: AttemptStage.running,
        failure: failure,
      ));
      },
      (_) => emit(state.copyWith(
        stage: AttemptStage.finished,
        attempt: marked,
      )),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() {
    _stopTicker();
    monitor.dispose();
    return super.close();
  }
}
