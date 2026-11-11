/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: member_videos.dart
/// Purpose: Declares `MemberVideos.watch()` — the lessons THIS member may
///          read, asked for in a way firestore.rules can allow.
/// Author: ASEC team
/// Created: 16/10/2026
///
/// WHY NOT ONE QUERY. firestore.rules only lets a member read a video of a
/// course the admin opened for them (or a "default" video). A query for
/// every published video would include ones they may not read, so
/// Firestore would refuse the whole query. A member with only some courses
/// therefore asks for exactly what they may read:
///
///   published == true AND category IN [their courses]   (30 per query)
///   published == true AND free == true                  (default videos)
///
/// and the answers are merged. Admins, and members with "every course",
/// keep the single query.
///
/// LIVE. When the admin changes the member's courses, the queries are
/// rebuilt for the new list.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/video/v1_videos/data/models/video_model.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';

abstract final class MemberVideos {
  const MemberVideos._();

  static CollectionReference<Map<String, dynamic>> get _videos =>
      AppFirebase.db.collection(FirebaseCollections.videos);

  /// What decides the queries: rebuilt only when this changes.
  static String _signature(AppUser u) => u.isAdmin || u.hasEveryCourse
      ? 'all'
      : (_openCourses(u)..sort()).join('\u0001');

  /// The member's courses whose own dates (Members → Edit access) are open
  /// now. A course outside its dates is left out of the query: the rules
  /// refuse its videos, and one refused video fails the whole query.
  static List<String> _openCourses(AppUser u) {
    final DateTime now = DateTime.now();
    return <String>[
      for (final String c in u.courses.map((String c) => c.trim()).toSet())
        if (u.courseAccess[c] == null || u.courseAccess[c]!.openAt(now)) c,
    ];
  }

  static Stream<List<VideoItem>> watch() {
    late StreamController<List<VideoItem>> out;
    final List<StreamSubscription<dynamic>> subs = <StreamSubscription<dynamic>>[];
    StreamSubscription<AppUser?>? userSub;
    StreamSubscription<dynamic>? featuresSub;
    String? current;

    // COLD-START RETRY. On the first launch the first query can fire a moment
    // before Firebase has finished confirming the sign-in, and Firestore
    // answers that one query with 'permission-denied' and STOPS the listener
    // for good (it never retries itself) — so the Videos page stayed broken
    // until the app was restarted. These retry a transient refusal a few
    // times, with a growing delay, before giving up. A real block (expired /
    // paused account) still surfaces after the retries.
    int retries = 0;
    const int maxRetries = 6;
    Timer? retryTimer;

    void cancelQueries() {
      for (final StreamSubscription<dynamic> s in subs) {
        s.cancel();
      }
      subs.clear();
    }

    void start(AppUser user) {
      final String sig = _signature(user);
      if (sig == current) return;
      current = sig;
      cancelQueries();

      final List<Query<Map<String, dynamic>>> queries;
      final Query<Map<String, dynamic>> published =
          _videos.where(FirebaseCollections.publishedField, isEqualTo: true);
      if (sig == 'all') {
        queries = <Query<Map<String, dynamic>>>[published];
      } else {
        final List<String> courses = _openCourses(user);
        queries = <Query<Map<String, dynamic>>>[
          // Default videos — everybody sees them.
          published.where(FirebaseCollections.freeField, isEqualTo: true),
          // The member's own courses, 30 names per query (Firestore's limit).
          for (int i = 0; i < courses.length; i += 30)
            published.where(
              VideoModel.category,
              whereIn: courses.sublist(i, i + 30 > courses.length ? courses.length : i + 30),
            ),
        ];
      }

      final List<Map<String, VideoItem>?> latest =
          List<Map<String, VideoItem>?>.filled(queries.length, null);
      void emit() {
        if (latest.any((Map<String, VideoItem>? m) => m == null)) return;
        final Map<String, VideoItem> merged = <String, VideoItem>{
          for (final Map<String, VideoItem>? m in latest) ...m!,
        };
        final List<VideoItem> list = merged.values.toList()
          ..sort((VideoItem a, VideoItem b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));
        if (!out.isClosed) out.add(list);
      }

      for (int i = 0; i < queries.length; i++) {
        subs.add(queries[i].snapshots().listen(
          (QuerySnapshot<Map<String, dynamic>> snap) {
            retries = 0; // a good answer: the session is ready.
            latest[i] = <String, VideoItem>{
              for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs)
                d.id: VideoModel.fromDoc(d),
            };
            emit();
          },
          onError: (Object e) {
            if (out.isClosed) return;
            final bool transient = e is FirebaseException &&
                (e.code == 'permission-denied' ||
                    e.code == 'unavailable' ||
                    e.code == 'deadline-exceeded');
            if (transient && retries < maxRetries) {
              retries++;
              cancelQueries();
              current = null; // force a full rebuild on the next start().
              retryTimer?.cancel();
              retryTimer = Timer(
                Duration(milliseconds: 300 * retries),
                () {
                  if (!out.isClosed) start(SessionController.to.current);
                },
              );
              return;
            }
            out.addError(e);
          },
        ));
      }
    }

    out = StreamController<List<VideoItem>>(
      onListen: () {
        // Resume points kept on the account (another device / reinstall).
        unawaited(VideoWatchStore.pullCloud());
        start(SessionController.to.current);
        userSub = SessionController.to.user.listen((AppUser? u) {
          if (u != null && !u.isEmpty) start(u);
        });
        // "Open every course to all members" reaches open screens live.
        featuresSub = AppFeatures.to.values.listen((_) {
          final AppUser u = SessionController.to.current;
          if (!u.isEmpty) start(u);
        });
      },
      onCancel: () {
        retryTimer?.cancel();
        cancelQueries();
        userSub?.cancel();
        featuresSub?.cancel();
      },
    );
    return out.stream;
  }
}
