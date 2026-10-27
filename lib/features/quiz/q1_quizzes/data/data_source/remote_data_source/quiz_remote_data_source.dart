/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_remote_data_source.dart
/// Purpose: Declares `QuizRemoteDataSource` — every read and write against
///          `quizzes` and `attempts`.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/network/cold_start_retry.dart';
import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/quiz/q1_quizzes/data/models/quiz_model.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';

class QuizRemoteDataSource {
  CollectionReference<Map<String, dynamic>> get _quizzes =>
      AppFirebase.db.collection(FirebaseCollections.quizzes);

  CollectionReference<Map<String, dynamic>> get _attempts =>
      AppFirebase.db.collection(FirebaseCollections.attempts);

  // ── Quizzes ──────────────────────────────────────────────────────────────

  /// Sorting happens on the client throughout this data source: an
  /// `orderBy` next to a `where` needs a composite index, and a list this
  /// small is not worth one.
  Stream<List<Quiz>> watchAll() => _quizzes
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) =>
          _newestFirst(snap.docs.map(QuizModel.fromDoc)));

  Stream<List<Quiz>> watchPublished() => retryingSnapshots(() => _quizzes
      .where(FirebaseCollections.publishedField, isEqualTo: true)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) =>
          _newestFirst(snap.docs.map(QuizModel.fromDoc))));

  Stream<Quiz?> watchQuiz(String id) => _quizzes
      .doc(id)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
          doc.exists ? QuizModel.fromDoc(doc) : null);

  Future<String> create(Quiz quiz) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _quizzes.add(QuizModel.toMap(quiz, isCreate: true));
    return ref.id;
  }

  Future<void> update(Quiz quiz) =>
      _quizzes.doc(quiz.id).update(QuizModel.toMap(quiz));

  Future<void> setPublished(String id, bool published) =>
      _quizzes.doc(id).update(<String, dynamic>{
        FirebaseCollections.publishedField: published,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  /// Deletes the quiz and its attempts. The attempts go first: a failure
  /// half-way then leaves a quiz whose results are incomplete, which is
  /// visible, rather than orphan attempts pointing at a quiz that is gone.
  Future<void> delete(String id) async {
    final QuerySnapshot<Map<String, dynamic>> attempts = await _attempts
        .where(FirebaseCollections.quizIdField, isEqualTo: id)
        .get();

    final WriteBatch batch = AppFirebase.db.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in attempts.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_quizzes.doc(id));
    await batch.commit();
  }

  // ── Attempts ─────────────────────────────────────────────────────────────

  Stream<List<QuizAttempt>> watchAttemptsFor(String quizId) => _attempts
      .where(FirebaseCollections.quizIdField, isEqualTo: quizId)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) {
        final List<QuizAttempt> list =
            snap.docs.map(QuizAttemptModel.fromDoc).toList()
              ..sort((QuizAttempt a, QuizAttempt b) =>
                  b.score.compareTo(a.score));
        return list;
      });

  Stream<List<QuizAttempt>> watchMyAttempts(String uid) => retryingSnapshots(() => _attempts
      .where(FirebaseCollections.userIdField, isEqualTo: uid)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) {
        final List<QuizAttempt> list =
            snap.docs.map(QuizAttemptModel.fromDoc).toList()
              ..sort((QuizAttempt a, QuizAttempt b) =>
                  (b.submittedAt ?? DateTime(0))
                      .compareTo(a.submittedAt ?? DateTime(0)));
        return list;
      }));

  Stream<List<QuizAttempt>> watchAllAttempts() => _attempts
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) =>
          snap.docs.map(QuizAttemptModel.fromDoc).toList());

  Future<QuizAttempt?> fetchAttempt(String quizId, String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _attempts
        .doc(FirebaseCollections.attemptId(quizId, uid))
        .get();
    if (!doc.exists) return null;
    return QuizAttemptModel.fromDoc(doc);
  }

  /// `set`, not `add`: the document id is `{quizId}_{uid}`, so a second
  /// submission can only ever overwrite the member's own attempt — and the
  /// rules refuse even that.
  Future<void> submitAttempt(QuizAttempt attempt) => _attempts
      .doc(FirebaseCollections.attemptId(attempt.quizId, attempt.userId))
      .set(QuizAttemptModel.toMap(attempt));

  List<Quiz> _newestFirst(Iterable<Quiz> quizzes) {
    final List<Quiz> list = quizzes.toList()
      ..sort((Quiz a, Quiz b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }
}
