/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: bulk_upload_cubit.dart
/// Purpose: Declares `BulkUploadCubit` — many lesson videos at once, uploaded
///          one after another straight into the ASEC Google Drive folder
///          (DriveUploader), with per-file and overall progress, speed, time
///          left, pause / resume / cancel and an internet watch. When the
///          files are up, one Drive sync turns them into lessons and each
///          gets the title typed for it and the publishing chosen.
///          Ported from ENGX (09/11/2026).
/// Author: ASEC team
/// Created: 09/11/2026

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/video/v1_videos/data/cloud/cloud_lessons.dart';
import 'package:asec/features/video/v1_videos/data/models/video_model.dart';
import 'package:asec/features/video/v1_videos/data/seed/drive_lessons.dart';
import 'package:asec/features/video/v1_videos/data/upload/drive_uploader.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/upload/upload_kit.dart';

/// Is the internet there? (A tiny Google "204" page.)
Future<bool> _hasInternet() async {
  if (kIsWeb) return true;
  try {
    final http.Response r = await http
        .head(Uri.parse('https://www.gstatic.com/generate_204'))
        .timeout(const Duration(seconds: 5));
    return r.statusCode == 204 || r.statusCode == 200;
  } catch (_) {
    return false;
  }
}

enum BulkItemStatus { pending, uploading, done, failed }

/// Why the whole upload stopped (not one file).
enum BulkStop { folderMissing, signInMissing, driveFull, noInternet }

class BulkItem {
  const BulkItem({
    required this.key,
    required this.file,
    required this.title,
    this.status = BulkItemStatus.pending,
    this.sent = 0,
    this.fileId,
    this.error,
  });

  final String key;
  final PlatformFile file;
  final String title;
  final BulkItemStatus status;
  final int sent;
  final String? fileId;
  final String? error;

  double get progress => file.size <= 0 ? 0 : (sent / file.size).clamp(0, 1).toDouble();

  BulkItem copyWith({
    String? title,
    BulkItemStatus? status,
    int? sent,
    String? fileId,
    String? error,
    bool clearError = false,
  }) =>
      BulkItem(
        key: key,
        file: file,
        title: title ?? this.title,
        status: status ?? this.status,
        sent: sent ?? this.sent,
        fileId: fileId ?? this.fileId,
        error: clearError ? null : (error ?? this.error),
      );
}

class BulkState {
  const BulkState({
    this.items = const <BulkItem>[],
    this.category = '',
    this.published = true,
    this.running = false,
    this.syncing = false,
    this.finished = false,
    this.paused = false,
    this.offline = false,
    this.speed = 0,
    this.timeLeft,
    this.stop,
    this.rejected = 0,
    this.folderId,
    this.folderLabel = '',
  });

  final List<BulkItem> items;
  final String category;
  final bool published;
  final bool running;

  /// Files are up; the lessons are being written.
  final bool syncing;
  final bool finished;
  final bool paused;
  final bool offline;

  /// Smoothed bytes per second over the whole upload.
  final double speed;
  final Duration? timeLeft;
  final BulkStop? stop;

  /// Files left out of the last pick / drop (not videos, or too big).
  final int rejected;

  /// The Drive folder picked from the tree; null = the [category]'s folder.
  final String? folderId;

  /// "Course › Section" for the picked folder; empty = the main folder.
  final String folderLabel;

  int get totalBytes => items.fold(0, (int a, BulkItem i) => a + i.file.size);
  int get sentBytes => items.fold(0, (int a, BulkItem i) => a + i.sent);
  int get doneCount => items.where((BulkItem i) => i.status == BulkItemStatus.done).length;
  int get failedCount => items.where((BulkItem i) => i.status == BulkItemStatus.failed).length;
  bool get busy => running || syncing;
  double get progress => totalBytes == 0 ? 0 : (sentBytes / totalBytes).clamp(0, 1).toDouble();

  BulkState copyWith({
    List<BulkItem>? items,
    String? category,
    bool? published,
    bool? running,
    bool? syncing,
    bool? finished,
    bool? paused,
    bool? offline,
    double? speed,
    Duration? timeLeft,
    bool clearTimeLeft = false,
    BulkStop? stop,
    bool clearStop = false,
    int? rejected,
    String? folderId,
    String? folderLabel,
  }) =>
      BulkState(
        items: items ?? this.items,
        category: category ?? this.category,
        published: published ?? this.published,
        running: running ?? this.running,
        syncing: syncing ?? this.syncing,
        finished: finished ?? this.finished,
        paused: paused ?? this.paused,
        offline: offline ?? this.offline,
        speed: speed ?? this.speed,
        timeLeft: clearTimeLeft ? null : (timeLeft ?? this.timeLeft),
        stop: clearStop ? null : (stop ?? this.stop),
        rejected: rejected ?? this.rejected,
        folderId: folderId ?? this.folderId,
        folderLabel: folderLabel ?? this.folderLabel,
      );
}

class BulkUploadCubit extends Cubit<BulkState> {
  BulkUploadCubit({required this.adminUid, String category = ''})
      : super(BulkState(category: category));

  final String adminUid;
  int _seq = 0;

  static int get _maxBytes => kMaxUploadMb * 1024 * 1024;

  // ── The list ─────────────────────────────────────────────────────────────

  static String titleFromName(String name) {
    final int dot = name.lastIndexOf('.');
    return (dot > 0 ? name.substring(0, dot) : name).replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  }

  void _add(List<PlatformFile> files) {
    int rejected = 0;
    final List<BulkItem> added = <BulkItem>[];
    for (final PlatformFile f in files) {
      final String ext = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : '';
      final bool dup = state.items.any((BulkItem i) => i.file.name == f.name && i.file.size == f.size);
      if (!kVideoExtensions.contains(ext) || f.size > _maxBytes || dup) {
        rejected++;
        continue;
      }
      added.add(BulkItem(key: 'f${_seq++}', file: f, title: titleFromName(f.name)));
    }
    debugPrint('🟡 [BulkUpload] added ${added.length} file(s), left out $rejected');
    emit(state.copyWith(
      items: <BulkItem>[...state.items, ...added],
      rejected: rejected,
      finished: false,
      clearStop: true,
    ));
  }

  Future<void> pick() async {
    final FilePickerResult? r = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (r == null || r.files.isEmpty) return;
    _add(r.files);
  }

  /// Files dragged onto the page.
  void drop(List<PlatformFile> files) => _add(files);

  void remove(String key) {
    if (state.running) return;
    emit(state.copyWith(items: state.items.where((BulkItem i) => i.key != key).toList()));
  }

  void clearAll() {
    if (state.busy) return;
    emit(state.copyWith(items: const <BulkItem>[], finished: false, clearStop: true));
  }

  void setTitle(String key, String title) => _update(key, (BulkItem i) => i.copyWith(title: title));

  void setCategory(String v) => emit(state.copyWith(category: v));

  /// The destination picked from the Drive folder tree.
  void setFolder(DriveFolder f) => emit(state.copyWith(
        folderId: f.id,
        folderLabel: f.isRoot ? '' : (f.isCourse ? f.name : '${f.parentName} › ${f.name}'),
        category: f.isRoot ? '' : (f.isCourse ? f.name : f.parentName),
      ));
  void setPublished(bool v) => emit(state.copyWith(published: v));

  void retry(String key) => _update(
        key,
        (BulkItem i) => i.copyWith(status: BulkItemStatus.pending, sent: 0, clearError: true),
      );

  void _update(String key, BulkItem Function(BulkItem) f) => emit(state.copyWith(
        items: <BulkItem>[for (final BulkItem i in state.items) i.key == key ? f(i) : i],
      ));

  // ── Upload ───────────────────────────────────────────────────────────────

  bool _cancel = false;
  Timer? _net;
  DateTime? _lastAt;
  int _lastBytes = 0;

  void _onBytes(String key, int n) {
    if (isClosed) return;
    final List<BulkItem> items = <BulkItem>[
      for (final BulkItem i in state.items) i.key == key ? i.copyWith(sent: i.sent + n) : i,
    ];
    final int sent = items.fold(0, (int a, BulkItem i) => a + i.sent);
    final int total = items.fold(0, (int a, BulkItem i) => a + i.file.size);
    final DateTime now = DateTime.now();
    double speed = state.speed;
    if (_lastAt == null) {
      _lastAt = now;
      _lastBytes = sent;
    } else {
      final double secs = now.difference(_lastAt!).inMilliseconds / 1000;
      if (secs > 0.3) {
        final double instant = (sent - _lastBytes) / secs;
        speed = speed <= 0 ? instant : speed * 0.75 + instant * 0.25;
        _lastAt = now;
        _lastBytes = sent;
      }
    }
    // Only what is still to go (failed files are not retried in this run).
    final int toGo = items
        .where((BulkItem i) =>
            i.status == BulkItemStatus.pending || i.status == BulkItemStatus.uploading)
        .fold(0, (int a, BulkItem i) => a + (i.file.size - i.sent));
    final Duration? left = speed > 1 ? Duration(seconds: (toGo / speed).ceil()) : null;
    emit(state.copyWith(
      items: items,
      speed: speed,
      timeLeft: left,
      clearTimeLeft: left == null,
    ));
    if (total == 0) return;
  }

  Future<void> _gate() async {
    while (!isClosed && (state.paused || state.offline) && !_cancel) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (_cancel || isClosed) throw const DriveUploadCancelled();
  }

  void _watchNet() {
    _net?.cancel();
    _net = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (isClosed || !state.running) return;
      final bool ok = await _hasInternet();
      if (isClosed || !state.running) return;
      if (!ok && !state.offline) {
        emit(state.copyWith(offline: true, speed: 0, clearTimeLeft: true));
      } else if (ok && state.offline) {
        _lastAt = null;
        emit(state.copyWith(offline: false));
      }
    });
  }

  void togglePause() {
    if (!state.running) return;
    _lastAt = null;
    emit(state.copyWith(paused: !state.paused, speed: 0, clearTimeLeft: true));
  }

  void cancel() {
    _cancel = true;
  }

  Future<void> start() async {
    if (state.busy) return;
    if (!state.items.any((BulkItem i) => i.status == BulkItemStatus.pending)) return;
    if (!await _hasInternet()) {
      if (!isClosed) emit(state.copyWith(stop: BulkStop.noInternet));
      return;
    }
    if (isClosed) return;
    _cancel = false;
    _lastAt = null;
    emit(state.copyWith(
      running: true,
      finished: false,
      paused: false,
      offline: false,
      speed: 0,
      clearTimeLeft: true,
      clearStop: true,
    ));
    _watchNet();

    for (final BulkItem item in List<BulkItem>.of(state.items)) {
      if (isClosed || _cancel) break;
      final BulkItem now = state.items.firstWhere(
        (BulkItem i) => i.key == item.key,
        orElse: () => item,
      );
      if (now.status != BulkItemStatus.pending) continue;
      _update(now.key, (BulkItem i) => i.copyWith(status: BulkItemStatus.uploading, sent: 0, clearError: true));
      try {
        final String id = await DriveUploader.upload(
          file: now.file,
          category: state.category,
          description: '',
          contentType: _contentType(now.file.name),
          onBytes: (int n) => _onBytes(now.key, n),
          gate: _gate,
          folderId: state.folderId,
        );
        _update(now.key, (BulkItem i) => i.copyWith(
              status: BulkItemStatus.done,
              sent: i.file.size,
              fileId: id,
            ));
        // Also into Cloudflare, so members never stream it from Drive's
        // public link. In the background; a failure only means it plays
        // from Drive until it is copied.
        unawaited(CloudLessons.copyNewUpload(id, now.file.path));
      } on DriveUploadCancelled {
        _update(now.key, (BulkItem i) => i.copyWith(status: BulkItemStatus.pending, sent: 0));
        break;
      } on DriveSetupMissing catch (e) {
        _update(now.key, (BulkItem i) => i.copyWith(status: BulkItemStatus.pending, sent: 0));
        emit(state.copyWith(stop: e.what == 'folder' ? BulkStop.folderMissing : BulkStop.signInMissing));
        break;
      } catch (e) {
        debugPrint('🔴 [BulkUpload] ${now.file.name} failed: $e');
        final bool full = '$e'.contains('storageQuotaExceeded') || '$e'.contains('storage quota');
        _update(now.key, (BulkItem i) => i.copyWith(
              status: full ? BulkItemStatus.pending : BulkItemStatus.failed,
              sent: 0,
              error: '$e',
            ));
        if (full) {
          emit(state.copyWith(stop: BulkStop.driveFull));
          break;
        }
      }
    }
    _net?.cancel();
    if (isClosed) return;
    emit(state.copyWith(running: false, paused: false, offline: false, speed: 0, clearTimeLeft: true));

    final List<BulkItem> uploaded = state.items
        .where((BulkItem i) => i.status == BulkItemStatus.done && i.fileId != null)
        .toList();
    if (uploaded.isEmpty) return;
    await _makeLessons(uploaded);
  }

  /// One sync for the whole batch, then each lesson gets its title and the
  /// publishing chosen.
  Future<void> _makeLessons(List<BulkItem> uploaded) async {
    emit(state.copyWith(syncing: true));
    final CollectionReference<Map<String, dynamic>> col =
        AppFirebase.db.collection(FirebaseCollections.videos);
    final Set<String> pending = uploaded.map((BulkItem i) => i.fileId!).toSet();
    for (int attempt = 0; attempt < 4 && pending.isNotEmpty; attempt++) {
      if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 3));
      final String? problem = await DriveVideoSync.run(adminUid: adminUid);
      if (problem != null) debugPrint('🟡 [BulkUpload] sync: $problem');
      for (final BulkItem i in uploaded) {
        final String id = i.fileId!;
        if (!pending.contains(id)) continue;
        // The sync names each lesson `drive_<Drive file id>`.
        final DocumentReference<Map<String, dynamic>> doc = col.doc('drive_$id');
        if (!(await doc.get()).exists) continue;
        // A title that no longer matches the Drive name counts as the
        // admin's own, so later syncs keep it.
        await doc.update(<String, dynamic>{
          VideoModel.title: i.title.trim().isEmpty ? titleFromName(i.file.name) : i.title.trim(),
          FirebaseCollections.publishedField: state.published,
          FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
        });
        pending.remove(id);
      }
      if (isClosed) return;
    }
    if (isClosed) return;
    emit(state.copyWith(syncing: false, finished: true));
  }

  static String _contentType(String name) {
    switch (name.split('.').last.toLowerCase()) {
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'video/mp4';
    }
  }

  @override
  Future<void> close() {
    _cancel = true;
    _net?.cancel();
    return super.close();
  }
}
