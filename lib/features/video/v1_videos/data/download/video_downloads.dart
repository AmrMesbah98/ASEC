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

import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/core/security/security_monitor.dart';
import 'package:asec/features/video/v1_videos/data/download/video_file.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_link.dart';

abstract final class VideoDownloads {
  const VideoDownloads._();

  /// False on the web — the download buttons and the section are hidden.
  static bool get supported => videoDownloadsSupported;

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
    final List<VideoItem> list = <VideoItem>[
      for (final dynamic m in raw)
        if (m is Map) _fromMap(Map<String, dynamic>.from(m)),
    ].where((VideoItem v) =>
        videoFileExists(_path(v.id)) || videoFileExists(legacyVideoPath(_path(v.id)))).toList();
    items.assignAll(list);
    if (list.length != raw.length) _save();
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
    if (!supported || _dir.isEmpty || !isDownloaded(id)) return null;
    final String p = _path(id);
    return videoFileExists(p) ? p : null;
  }

  /// Bytes taken by every downloaded lesson.
  static int get totalBytes =>
      items.fold<int>(0, (int sum, VideoItem v) => sum + v.sizeBytes);

  static Future<void> start(VideoItem video) async {
    if (!supported || !video.hasFile) return;
    await ensureLoaded();
    if (_loadedFor.isEmpty || isDownloaded(video.id) || isDownloading(video.id)) {
      return;
    }
    final String owner = _loadedFor;
    if (!_burstAllowed(video)) {
      failed.add(video.id);
      return;
    }
    failed.remove(video.id);
    _cancelled.remove(video.id);
    _pending[video.id] = video;
    active[video.id] = 0;
    try {
      int size = video.sizeBytes;
      await downloadVideoFile(
        url: VideoLink.playable(video.url),
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
