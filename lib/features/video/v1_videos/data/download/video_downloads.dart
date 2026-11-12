/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_downloads.dart
/// Purpose: Declares `VideoDownloads` — lessons a student saved INSIDE the
///          app to watch without internet (like YouTube's offline videos).
/// Author: ASEC team
/// Created: 1/10/2026
///
/// WHAT IS KEPT
/// ------------
///  * the video file, in the app's private folder (see video_file_io.dart) —
///    never the phone's Downloads or Gallery;
///  * the lesson's details (title, description, course, sub-folder…) in
///    GetStorage under `video_downloads_<uid>`, so the Downloads section can
///    list them with no Firestore and no internet.
///
/// Everything is per signed-in account: another student signing in on the
/// same phone sees none of it. Watch progress keeps using VideoWatchStore,
/// so a lesson watched offline counts as watched.
///
/// The UI reads [items] and [active] (Rx) — a download started on a card
/// shows its ring there and in the Downloads section at the same time.

import 'package:asec/features/video/v1_videos/data/cloud/cloud_lessons.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/core/security/security_monitor.dart';
import 'package:asec/features/video/v1_videos/data/download/video_file.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_link.dart';
import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';

abstract final class VideoDownloads {
  const VideoDownloads._();

  /// False on the web — the download buttons and the section are hidden.
  static bool get supported => videoDownloadsSupported;

  /// Supported here AND on in Control centre → Video lessons → "Download
  /// inside the app (offline)" (06/11/2026, from ENGX).
  static bool get enabled =>
      supported && (!Get.isRegistered<AppFeatures>() || AppFeatures.to.isOn(AppFeature.videoDownloads));

  /// "Download all" for a whole folder — needs [enabled] too (12/11/2026).
  static bool get bulkEnabled =>
      enabled && (!Get.isRegistered<AppFeatures>() || AppFeatures.to.isOn(AppFeature.videoDownloadAll));

  static Worker? _switchWorker;

  // ── REMOVED ACCESS ERASES DOWNLOADS (12/11/2026, from ENGX) ──────────────
  //
  // The member's own `users/{uid}` document is followed for the whole
  // session. The moment the SERVER says the account is gone, switched off,
  // paused, not started or ended — or a course was taken away — the saved
  // lessons of what they lost are erased, and their downloads stop. Only
  // server-confirmed data counts: offline / from cache, nothing is touched.

  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _accessSub;
  static Worker? _accessWorker;
  static String _accessUid = '';
  static AppUser? _accessUser;
  static bool _accessKnown = false;

  /// Called by SessionController.start for the signed-in account.
  static void watchAccess(String uid) {
    if (!supported || uid.isEmpty) return;
    stopAccess();
    _accessUid = uid;
    _accessSub = AppFirebase.db
        .collection(FirebaseCollections.users)
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
      (DocumentSnapshot<Map<String, dynamic>> doc) {
        if (doc.metadata.isFromCache) return;
        _accessUser = doc.exists ? UserModel.fromDoc(doc) : null;
        _accessKnown = true;
        unawaited(_applyAccess());
      },
      onError: (Object _) {},
    );
    // "Open every course" etc. must come from the server too.
    if (Get.isRegistered<AppFeatures>()) {
      _accessWorker = ever<bool>(AppFeatures.to.fromServer, (_) => unawaited(_applyAccess()));
    }
  }

  /// On sign-out.
  static void stopAccess() {
    _accessSub?.cancel();
    _accessSub = null;
    _accessWorker?.dispose();
    _accessWorker = null;
    _accessUid = '';
    _accessUser = null;
    _accessKnown = false;
  }

  static Future<void> _applyAccess() async {
    if (!_accessKnown || _accessUid.isEmpty) return;
    if (Get.isRegistered<AppFeatures>() && !AppFeatures.to.fromServer.value) return;
    final AppUser? user = _accessUser;
    if (user != null && user.isAdmin) return;
    final bool blocked = user == null || !user.active || MemberAccess.check(user) != AccessBlock.none;
    await ensureLoaded();
    if (_loadedFor != _accessUid) return;
    await removeWhere((VideoItem v) => blocked || user == null || !user.canSeeCourse(v.category));
  }

  /// Erases every saved lesson (and stops every download) [test] says.
  static Future<void> removeWhere(bool Function(VideoItem v) test) async {
    for (final _Job j in List<_Job>.of(_queue)) {
      if (test(j.video)) cancel(j.video.id);
    }
    for (final VideoItem v in _pending.values.toList()) {
      if (test(v)) cancel(v.id);
    }
    await ensureLoaded();
    if (_dir.isEmpty) return;
    final List<VideoItem> gone = items.where(test).toList();
    if (gone.isEmpty) return;
    for (final VideoItem v in gone) {
      items.removeWhere((VideoItem x) => x.id == v.id);
      _savedAt.remove(v.id);
      failed.remove(v.id);
      await deleteVideoFile(_path(v.id));
    }
    _save();
  }

  // ── DOWNLOAD A WHOLE FOLDER (12/11/2026, from ENGX) ──────────────────────
  //
  // "Download all" above a folder's lessons: every lesson not saved yet is
  // queued and downloaded ONE AFTER ANOTHER. The whole folder counts as ONE
  // download for the hourly cap. Each lesson card shows "waiting".

  static final List<_Job> _queue = <_Job>[];
  static final RxSet<String> queued = <String>{}.obs;
  static bool _running = false;

  static bool isQueued(String id) => queued.contains(id);

  /// Lessons of [videos] that "Download all" would still save.
  static List<VideoItem> missing(List<VideoItem> videos) => <VideoItem>[
        for (final VideoItem v in videos)
          if (v.hasFile && !isDownloaded(v.id)) v,
      ];

  /// Queues every lesson of [videos] not saved yet. Returns how many were
  /// queued, 0 = nothing to do, -1 = refused (switched off / hourly cap).
  static Future<int> downloadAll(List<VideoItem> videos) async {
    if (!bulkEnabled) return -1;
    await ensureLoaded();
    if (_loadedFor.isEmpty) return -1;
    final List<VideoItem> todo = <VideoItem>[
      for (final VideoItem v in missing(videos))
        if (!isDownloading(v.id) && !isQueued(v.id)) v,
    ];
    if (todo.isEmpty) return 0;
    if (!_burstAllowed(todo.first)) return -1;
    final String owner = _loadedFor;
    for (final VideoItem v in todo) {
      failed.remove(v.id);
      queued.add(v.id);
      _queue.add(_Job(owner, v));
    }
    unawaited(_runQueue());
    return todo.length;
  }

  /// Stops a folder download: the waiting lessons and the one in progress.
  static void cancelAll(Iterable<String> ids) {
    for (final String id in ids) {
      cancel(id);
    }
  }

  static Future<void> _runQueue() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty) {
        final _Job job = _queue.removeAt(0);
        if (!queued.remove(job.video.id)) continue; // cancelled meanwhile
        if (!enabled || _loadedFor != job.owner) continue;
        await start(job.video, fromQueue: true);
      }
    } finally {
      _running = false;
    }
  }

  static void _clearQueue() {
    _queue.clear();
    queued.clear();
  }

  /// Call once at start-up: the super admin switching downloads OFF erases
  /// the offline lessons on this device (every account). Only an explicit
  /// `false` in the settings document does — never a missing connection.
  static void watchSwitch() {
    if (!supported || _switchWorker != null || !Get.isRegistered<AppFeatures>()) return;
    void check(Map<String, bool> values) {
      if (values[AppFeature.videoDownloads.key] == false) unawaited(wipeDevice());
    }
    _switchWorker = ever<Map<String, bool>>(AppFeatures.to.values, check);
    check(AppFeatures.to.values);
    // Downloads that pass their time go — when the setting changes and
    // while the app stays open.
    ever<int>(AppFeatures.to.downloadExpiryDays, (_) => unawaited(removeExpired()));
    Timer.periodic(const Duration(minutes: 5), (_) => unawaited(removeExpired()));
  }

  // ── EXPIRY (ported from ENGX v1.0.54) ─────────────────────────────────────
  //
  // Control centre → "Downloads expire after": each saved lesson is erased
  // that many days after it was downloaded (0 = never). Works offline: the
  // number is kept on the device, and turning the clock back does not help
  // — the latest time ever seen is used.

  static final Map<String, int> _savedAt = <String, int>{};
  static const String _clockKey = 'asec_vault_clock';

  static int get _expiryDays =>
      Get.isRegistered<AppFeatures>() ? AppFeatures.to.downloadExpiryDays.value : 0;

  /// Now — never earlier than a time this device has already seen.
  static int _now() {
    final int real = DateTime.now().millisecondsSinceEpoch;
    try {
      final int seen = _box.read<int>(_clockKey) ?? 0;
      if (real > seen) {
        _box.write(_clockKey, real);
        return real;
      }
      return seen;
    } catch (_) {
      return real;
    }
  }

  /// When [id] will be erased, or null (never / not downloaded).
  static DateTime? expiresAt(String id) {
    final int? at = _savedAt[id];
    if (_expiryDays <= 0 || at == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(at).add(Duration(days: _expiryDays));
  }

  static bool _expired(String id, int now) {
    final DateTime? end = expiresAt(id);
    return end != null && now >= end.millisecondsSinceEpoch;
  }

  /// Erases every saved lesson past its time.
  static Future<void> removeExpired() async {
    if (_dir.isEmpty || _expiryDays <= 0 || items.isEmpty) return;
    final int now = _now();
    final List<VideoItem> gone = items.where((VideoItem v) => _expired(v.id, now)).toList();
    if (gone.isEmpty) return;
    for (final VideoItem v in gone) {
      items.removeWhere((VideoItem x) => x.id == v.id);
      _savedAt.remove(v.id);
      await deleteVideoFile(_path(v.id));
    }
    _save();
  }

  /// Erases every offline lesson on this device, of every account.
  static Future<void> wipeDevice() async {
    _clearQueue();
    for (final String id in active.keys.toList()) {
      cancel(id);
    }
    items.clear();
    failed.clear();
    try {
      for (final String k in _box.getKeys<Iterable<String>>().where((String k) => k.startsWith('video_downloads_')).toList()) {
        await _box.remove(k);
      }
    } catch (_) {}
    await deleteAllVideoDirs();
    _dir = '';
    _loadedFor = '';
  }

  static final GetStorage _box = GetStorage();

  /// The downloaded lessons of the signed-in account, newest first.
  static final RxList<VideoItem> items = <VideoItem>[].obs;

  /// Downloads in progress: id → 0..1 (0 until the size is known).
  static final RxMap<String, double> active = <String, double>{}.obs;

  /// Lessons whose last download failed (the card offers a retry).
  static final RxSet<String> failed = <String>{}.obs;

  static final Set<String> _cancelled = <String>{};
  static final Map<String, VideoItem> _pending = <String, VideoItem>{};

  static String _loadedFor = '';
  static String _dir = '';

  /// The account downloads belong to. FirebaseAuth keeps the signed-in user
  /// on the device, so this is known offline too.
  static String get _uid => AppFirebase.uid ?? '';

  static String _key(String uid) => 'video_downloads_$uid';

  /// Loads the account's list (and drops entries whose file is gone).
  /// Cheap after the first call; call it before reading [items].
  static Future<void> ensureLoaded() async {
    if (!supported) return;
    final String uid = _uid;
    if (uid.isEmpty) {
      _loadedFor = '';
      items.clear();
      return;
    }
    if (uid == _loadedFor) return;
    _dir = await videoDownloadsDir(uid);
    _loadedFor = uid;
    final List<dynamic> raw = _box.read<List<dynamic>>(_key(uid)) ?? <dynamic>[];
    final int loadedAt = DateTime.now().millisecondsSinceEpoch;
    for (final dynamic m in raw) {
      if (m is! Map) continue;
      final Object? saved = m['saved'];
      // Saved before expiry existed: counted from now.
      _savedAt['${m['id'] ?? ''}'] = saved is num ? saved.toInt() : loadedAt;
    }
    final List<VideoItem> list = <VideoItem>[
      for (final dynamic m in raw)
        if (m is Map) _fromMap(Map<String, dynamic>.from(m)),
    ].where((VideoItem v) =>
        videoFileExists(_path(v.id)) || videoFileExists(legacyVideoPath(_path(v.id)))).toList();
    items.assignAll(list);
    _save(); // also records the download time of older entries
    await removeExpired();
    // Plain `.mp4` files from before encryption: encrypt them now, in the
    // background. Until each is done it streams online like any lesson.
    unawaited(_encryptLegacy(uid, list));
  }

  static Future<void> _encryptLegacy(String uid, List<VideoItem> list) async {
    for (final VideoItem v in list) {
      if (_loadedFor != uid) return;
      final String p = _path(v.id);
      if (videoFileExists(p)) continue;
      try {
        await encryptLegacyVideo(legacyVideoPath(p), p, ContentCrypto.deviceKey(uid));
      } catch (_) {}
    }
  }

  /// `.asv` — encrypted (ContentCrypto); see video_file_io.dart.
  static String _path(String id) => '$_dir/$id.asv';

  /// The key the account's files are encrypted with on this device.
  static Uint8List get fileKey => ContentCrypto.deviceKey(_loadedFor);

  // ── Download burst cap ────────────────────────────────────────────────────
  //
  // Nobody watches ten lessons in an hour. Pulling a whole course down at
  // once is what a scraper does: more than [_burstMax] downloads in an hour
  // are refused, and the super admin is told.
  static const int _burstMax = 10;
  static const String _burstKey = 'video_download_times';

  static bool _burstAllowed(VideoItem video) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<int> times = <int>[
      for (final dynamic t in _box.read<List<dynamic>>(_burstKey) ?? <dynamic>[])
        if (t is int && now - t < const Duration(hours: 1).inMilliseconds) t,
    ];
    if (times.length >= _burstMax) {
      SecurityMonitor.alert(
        'download_burst',
        'Tried to download more than $_burstMax lessons in one hour '
        '(blocked at "${video.title}", ${video.category}).',
      );
      return false;
    }
    times.add(now);
    _box.write(_burstKey, times);
    return true;
  }

  static bool isDownloaded(String id) =>
      items.any((VideoItem v) => v.id == id);

  static bool isDownloading(String id) => active.containsKey(id);

  /// The file to play instead of the internet stream, or null.
  static String? localPath(String id) {
    if (!enabled || _dir.isEmpty || !isDownloaded(id)) return null;
    if (_expired(id, _now())) {
      unawaited(removeExpired());
      return null;
    }
    final String p = _path(id);
    return videoFileExists(p) ? p : null;
  }

  /// Bytes taken by every downloaded lesson.
  static int get totalBytes =>
      items.fold<int>(0, (int sum, VideoItem v) => sum + v.sizeBytes);

  static Future<void> start(VideoItem video, {bool fromQueue = false}) async {
    if (!enabled || !video.hasFile) return;
    await ensureLoaded();
    if (_loadedFor.isEmpty || isDownloaded(video.id) || isDownloading(video.id)) {
      return;
    }
    final String owner = _loadedFor;
    // A folder download was counted once, as a whole, in [downloadAll].
    if (!fromQueue && !_burstAllowed(video)) {
      failed.add(video.id);
      return;
    }
    failed.remove(video.id);
    _cancelled.remove(video.id);
    _pending[video.id] = video;
    active[video.id] = 0;
    try {
      int size = video.sizeBytes;
      if (CloudLessons.signerFor(video.url) != null) await CloudLessons.syncClock();
      await downloadVideoFile(
        url: VideoLink.playable(video.url),
        cloud: CloudLessons.signerFor(video.url),
        path: _path(video.id),
        expectedBytes: video.sizeBytes,
        key: ContentCrypto.deviceKey(owner),
        cancelled: () => _cancelled.contains(video.id) || _loadedFor != owner,
        onProgress: (int received, int total) {
          size = received;
          active[video.id] = total > 0 ? (received / total).clamp(0.0, 1.0) : 0;
        },
      );
      if (_loadedFor == owner) {
        _savedAt[video.id] = _now();
        items.insert(0, video.copyWith(sizeBytes: size));
        _save();
      }
    } catch (e) {
      if (!_cancelled.contains(video.id)) {
        failed.add(video.id);
      }
    } finally {
      active.remove(video.id);
      _pending.remove(video.id);
      _cancelled.remove(video.id);
    }
  }

  static void cancel(String id) {
    if (queued.remove(id)) _queue.removeWhere((_Job j) => j.video.id == id);
    if (isDownloading(id)) _cancelled.add(id);
  }

  static Future<void> remove(String id) async {
    cancel(id);
    await ensureLoaded();
    if (_dir.isEmpty) return;
    items.removeWhere((VideoItem v) => v.id == id);
    failed.remove(id);
    _save();
    await deleteVideoFile(_path(id));
  }

  static Future<void> removeAll() async {
    await ensureLoaded();
    if (_dir.isEmpty) return;
    _clearQueue();
    for (final String id in active.keys.toList()) {
      cancel(id);
    }
    items.clear();
    failed.clear();
    _save();
    await deleteVideoDir(_dir);
    _dir = await videoDownloadsDir(_loadedFor);
  }

  /// The lessons in progress, for the Downloads section.
  static List<VideoItem> get pending => _pending.values.toList();

  static void _save() {
    if (_loadedFor.isEmpty) return;
    _box.write(_key(_loadedFor), <Map<String, dynamic>>[
      for (final VideoItem v in items) _toMap(v),
    ]);
  }

  static Map<String, dynamic> _toMap(VideoItem v) => <String, dynamic>{
        'id': v.id,
        'title': v.title,
        'description': v.description,
        'url': v.url,
        'size': v.sizeBytes,
        'category': v.category,
        'category_order': v.categoryOrder,
        'subcategory': v.subcategory,
        'subcategory_order': v.subcategoryOrder,
        'created': v.createdAt?.millisecondsSinceEpoch,
        'saved': _savedAt[v.id],
      };

  static VideoItem _fromMap(Map<String, dynamic> m) {
    final Object? created = m['created'];
    return VideoItem(
      id: '${m['id'] ?? ''}',
      title: '${m['title'] ?? ''}',
      description: '${m['description'] ?? ''}',
      url: '${m['url'] ?? ''}',
      sizeBytes: (m['size'] as num?)?.toInt() ?? 0,
      category: '${m['category'] ?? ''}',
      categoryOrder: (m['category_order'] as num?)?.toInt() ?? 0,
      subcategory: '${m['subcategory'] ?? ''}',
      subcategoryOrder: (m['subcategory_order'] as num?)?.toInt() ?? 0,
      createdAt: created is num
          ? DateTime.fromMillisecondsSinceEpoch(created.toInt())
          : null,
    );
  }
}

/// One lesson waiting in a folder download.
class _Job {
  const _Job(this.owner, this.video);

  final String owner;
  final VideoItem video;
}
