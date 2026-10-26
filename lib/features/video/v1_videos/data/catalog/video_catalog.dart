/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_catalog.dart
/// Purpose: Declares `VideoCatalog` — every published lesson's title and
///          course WITHOUT its file link (`video_catalog/{videoId}`), so a
///          member sees every course, the ones they were not given locked.
/// Author: ASEC team
/// Created: 20/10/2026
///
/// WHY A SECOND COLLECTION. firestore.rules can only allow or refuse a whole
/// document. A `videos` document carries the file's download link, so a
/// member must not read one of a course they were not given. The catalog
/// holds the same lessons minus the link, and every member may read it.
///
/// WHO KEEPS IT UP TO DATE. The admin app: while an admin with the Videos
/// permission is signed in, [startAdminSync] watches `videos` and writes
/// only what changed (a new lesson, a renamed one, a deleted one). So the
/// Drive sync, the upload form and the edit menu need no changes.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/video/v1_videos/data/models/video_model.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

abstract final class VideoCatalog {
  const VideoCatalog._();

  static CollectionReference<Map<String, dynamic>> get _col =>
      AppFirebase.db.collection(FirebaseCollections.videoCatalog);

  // ── Reading (members) ─────────────────────────────────────────────────────

  /// Every lesson in the catalog. Its [VideoItem.url] is always empty — the
  /// lesson cannot be played from here.
  ///
  /// Starts with an empty list and swallows errors, so a page that combines
  /// it with the member's own videos still opens before the rules are
  /// deployed (it then just shows no locked courses).
  static Stream<List<VideoItem>> watch() async* {
    yield const <VideoItem>[];
    yield* _col
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) => <VideoItem>[
              for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs)
                _fromDoc(d),
            ])
        .handleError((Object _) {});
  }

  static VideoItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.safeData;
    return VideoItem(
      id: d.id,
      title: m.str(VideoModel.title),
      category: m.str(VideoModel.category).trim(),
      categoryOrder: m.integer(VideoModel.categoryOrder),
      subcategory: m.str(VideoModel.subcategory).trim(),
      subcategoryOrder: m.integer(VideoModel.subcategoryOrder),
      sizeBytes: m.integer(VideoModel.sizeBytes),
      free: m.boolean(FirebaseCollections.freeField),
      createdAt: m.date(FirebaseCollections.createdAtField),
    );
  }

  // ── Writing (admin app) ───────────────────────────────────────────────────

  static StreamSubscription<List<VideoItem>>? _videosSub;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _catalogSub;
  static Timer? _debounce;
  static List<VideoItem>? _videos;
  static Map<String, Map<String, dynamic>>? _catalog;
  static bool _writing = false;
  static String? _uid;

  /// Safe to call on every build: it starts once per sign-in.
  static void startAdminSync() {
    final AppUser me = SessionController.to.current;
    if (_uid != null && _uid != me.uid) stopAdminSync(); // another account
    if (!me.isAdmin || !me.can(AdminPermission.videos)) return;
    if (_videosSub != null) return;
    _uid = me.uid;
    try {
      _videosSub = VideoRepository().watchAll().listen((List<VideoItem> v) {
        _videos = v;
        _schedule();
      }, onError: (Object _) {});
      _catalogSub = _col.snapshots().listen((QuerySnapshot<Map<String, dynamic>> s) {
        _catalog = <String, Map<String, dynamic>>{
          for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs) d.id: d.data(),
        };
        _schedule();
      }, onError: (Object _) {});
    } catch (_) {
      // Firebase not configured.
    }
  }

  /// On sign-out, so the next account starts clean.
  static void stopAdminSync() {
    _videosSub?.cancel();
    _catalogSub?.cancel();
    _debounce?.cancel();
    _videosSub = null;
    _catalogSub = null;
    _videos = null;
    _catalog = null;
    _uid = null;
  }

  static void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _reconcile);
  }

  /// What the catalog entry of [v] should hold.
  static Map<String, dynamic> _entry(VideoItem v) => <String, dynamic>{
        VideoModel.title: v.title.trim(),
        VideoModel.category: v.category.trim(),
        VideoModel.categoryOrder: v.categoryOrder,
        VideoModel.subcategory: v.subcategory.trim(),
        VideoModel.subcategoryOrder: v.subcategoryOrder,
        VideoModel.sizeBytes: v.sizeBytes,
        FirebaseCollections.freeField: v.free,
        FirebaseCollections.createdAtField:
            v.createdAt == null ? null : Timestamp.fromDate(v.createdAt!),
      };

  /// Compares two entries field by field; dates by the millisecond.
  static bool _same(Map<String, dynamic> a, Map<String, dynamic> b) {
    for (final String k in a.keys) {
      Object? x = a[k];
      Object? y = b[k];
      if (x is Timestamp) x = x.millisecondsSinceEpoch;
      if (y is Timestamp) y = y.millisecondsSinceEpoch;
      if (x != y) return false;
    }
    return true;
  }

  static Future<void> _reconcile() async {
    final List<VideoItem>? videos = _videos;
    final Map<String, Map<String, dynamic>>? catalog = _catalog;
    if (videos == null || catalog == null || _writing) return;

    final Map<String, Map<String, dynamic>> want = <String, Map<String, dynamic>>{
      for (final VideoItem v in videos)
        // HASHED id: every member reads the catalog, and a video's own id
        // (`drive_<fileId>`) would hand them its Drive link. Old entries
        // under the raw id are not in [want], so they are deleted below.
        if (v.published && v.hasFile) ContentCrypto.hashId(v.id): _entry(v),
    };
    final List<MapEntry<String, Map<String, dynamic>?>> ops =
        <MapEntry<String, Map<String, dynamic>?>>[
      for (final MapEntry<String, Map<String, dynamic>> e in want.entries)
        if (catalog[e.key] == null || !_same(e.value, catalog[e.key]!))
          MapEntry<String, Map<String, dynamic>?>(e.key, e.value),
      for (final String id in catalog.keys)
        if (!want.containsKey(id)) MapEntry<String, Map<String, dynamic>?>(id, null),
    ];
    if (ops.isEmpty) return;

    _writing = true;
    try {
      for (int i = 0; i < ops.length; i += 400) {
        final WriteBatch batch = AppFirebase.db.batch();
        for (final MapEntry<String, Map<String, dynamic>?> op
            in ops.sublist(i, i + 400 > ops.length ? ops.length : i + 400)) {
          if (op.value == null) {
            batch.delete(_col.doc(op.key));
          } else {
            batch.set(_col.doc(op.key), op.value!);
          }
        }
        await batch.commit();
      }
    } catch (_) {
      // Rules not deployed yet, or offline — tried again on the next change.
    } finally {
      _writing = false;
    }
  }
}
