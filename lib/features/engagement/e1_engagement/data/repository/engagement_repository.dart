/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: engagement_repository.dart
/// Purpose: Declares `EngagementRepository` — every read and write behind
///          notifications, tips & tricks, the library, course files, the
///          per-course settings, the "default / custom" video switch and the
///          members' watch progress (stars).
/// Author: ASEC team
/// Created: 15/10/2026
///
/// Collections (see FirebaseCollections and firestore.rules):
///
///   notifications/{id}    title, body, created_at
///   tips/{id}             title, body, active, saved_by[], created_at
///   library/{id}          title, url, storage_path, file_name, size_bytes
///   course_files/{id}     course, kind (folder|file), name, folder_id, file…
///   course_settings/{id}  name (the course), sequential
///   progress/{uid}        name, videos {videoId: 0..1}, updated_at
///
/// Lists are sorted on the device, never with orderBy + where together, so
/// none of them needs a composite index.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/core/helper/upload/picked_upload.dart' as picked;
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';

class EngagementRepository {
  EngagementRepository();

  static FirebaseFirestore get _db => AppFirebase.db;

  CollectionReference<Map<String, dynamic>> get _notices =>
      _db.collection(FirebaseCollections.notifications);
  CollectionReference<Map<String, dynamic>> get _tips =>
      _db.collection(FirebaseCollections.tips);
  CollectionReference<Map<String, dynamic>> get _library =>
      _db.collection(FirebaseCollections.library);
  CollectionReference<Map<String, dynamic>> get _courseFiles =>
      _db.collection(FirebaseCollections.courseFiles);
  CollectionReference<Map<String, dynamic>> get _courseSettings =>
      _db.collection(FirebaseCollections.courseSettings);
  CollectionReference<Map<String, dynamic>> get _progress =>
      _db.collection(FirebaseCollections.progress);
  CollectionReference<Map<String, dynamic>> get _questions =>
      _db.collection(FirebaseCollections.questions);

  static int _newestFirst(DateTime? a, DateTime? b) =>
      (b ?? DateTime(0)).compareTo(a ?? DateTime(0));

  // ── Notifications ─────────────────────────────────────────────────────────

  Stream<List<AppNotice>> watchNotices() => _notices
      .orderBy(FirebaseCollections.createdAtField, descending: true)
      .limit(100)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) => <AppNotice>[
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs)
              AppNotice(
                id: d.id,
                title: d.data().str('title'),
                body: d.data().str('body'),
                // A just-sent notice has no server time yet — it is "now".
                createdAt: d.data().date(FirebaseCollections.createdAtField) ??
                    DateTime.now(),
              ),
          ]);

  Future<void> sendNotice({required String title, required String body}) =>
      _notices.add(<String, dynamic>{
        'title': title.trim(),
        'body': body.trim(),
        'created_by': AppFirebase.uid ?? '',
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      });

  Future<void> deleteNotice(String id) => _notices.doc(id).delete();

  // ── Questions & answers (03/11/2026) ──────────────────────────────────
  //
  // questions/{id}: uid, user_name, text, answered (bool), answer,
  // answered_by, created_at, answered_at. Members read the ANSWERED ones
  // and their own; the queries say exactly that, so firestore.rules can
  // allow them. Sorted on the device (no composite index).

  static AppQuestion _question(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.safeData;
    return AppQuestion(
      id: d.id,
      uid: m.str('uid'),
      userName: m.str('user_name'),
      text: m.str('text'),
      answer: m.str('answer'),
      answeredBy: m.str('answered_by'),
      createdAt: m.date(FirebaseCollections.createdAtField) ?? DateTime.now(),
      answeredAt: m.date('answered_at'),
    );
  }

  static List<AppQuestion> _byAnswered(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(_question).toList()
        ..sort((AppQuestion a, AppQuestion b) =>
            _newestFirst(a.answeredAt ?? a.createdAt, b.answeredAt ?? b.createdAt));

  /// Every answered question, newest answer first (home page + Questions page).
  Stream<List<AppQuestion>> watchAnsweredQuestions() => _questions
      .where('answered', isEqualTo: true)
      .snapshots()
      .map(_byAnswered);

  /// [uid]'s own questions, answered or not.
  Stream<List<AppQuestion>> watchMyQuestions(String uid) => _questions
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) => s.docs.map(_question).toList()
        ..sort((AppQuestion a, AppQuestion b) => _newestFirst(a.createdAt, b.createdAt)));

  /// Admin: every question, waiting ones first.
  Stream<List<AppQuestion>> watchAllQuestions() => _questions.snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> s) => s.docs.map(_question).toList()
          ..sort((AppQuestion a, AppQuestion b) {
            if (a.answered != b.answered) return a.answered ? 1 : -1;
            return _newestFirst(a.createdAt, b.createdAt);
          }),
      );

  Future<void> askQuestion({required String uid, required String userName, required String text}) =>
      _questions.add(<String, dynamic>{
        'uid': uid,
        'user_name': userName.trim(),
        'text': text.trim(),
        'answered': false,
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      });

  /// Admin: post (or edit) the answer.
  Future<void> answerQuestion(String id, {required String answer, required String by}) =>
      _questions.doc(id).update(<String, dynamic>{
        'answered': answer.trim().isNotEmpty,
        'answer': answer.trim(),
        'answered_by': by.trim(),
        'answered_at': FieldValue.serverTimestamp(),
      });

  Future<void> deleteQuestion(String id) => _questions.doc(id).delete();

  // ── Tips & tricks ─────────────────────────────────────────────────────────

  static AppTip _tip(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.safeData;
    return AppTip(
      id: d.id,
      title: m.str('title'),
      body: m.str('body'),
      active: m.boolean('active', true),
      savedBy: m.stringList('saved_by'),
      seenBy: m.stringList('seen_by'),
      createdAt: m.date(FirebaseCollections.createdAtField) ?? DateTime.now(),
    );
  }

  Stream<List<AppTip>> watchTips() => _tips
      .orderBy(FirebaseCollections.createdAtField, descending: true)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) =>
          s.docs.map(_tip).toList());

  /// The tips [uid] saved, newest first.
  Stream<List<AppTip>> watchSavedTips(String uid) => _tips
      .where('saved_by', arrayContains: uid)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) => s.docs.map(_tip).toList()
        ..sort((AppTip a, AppTip b) => _newestFirst(a.createdAt, b.createdAt)));

  /// What pops up when the app opens: switched-on tips [uid] has neither
  /// saved nor already been shown.
  Future<List<AppTip>> tipsToShow(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> s = await _tips
        .orderBy(FirebaseCollections.createdAtField, descending: true)
        .limit(30)
        .get();
    return s.docs
        .map(_tip)
        .where((AppTip t) =>
            t.active && !t.isSavedBy(uid) && !t.isSeenBy(uid))
        .take(5)
        .toList();
  }

  Future<void> addTip({required String title, required String body}) =>
      _tips.add(<String, dynamic>{
        'title': title.trim(),
        'body': body.trim(),
        'active': true,
        'saved_by': <String>[],
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      });

  Future<void> setTipActive(String id, bool active) =>
      _tips.doc(id).update(<String, dynamic>{'active': active});

  Future<void> deleteTip(String id) => _tips.doc(id).delete();

  /// The member's own save — the rules allow nothing else on a tip.
  Future<void> saveTip(String id, String uid) => _tips.doc(id).update(
        <String, dynamic>{'saved_by': FieldValue.arrayUnion(<String>[uid])},
      );

  /// Remembers in Firestore that these tips popped up for [uid], so they
  /// never pop up again — not after a reinstall, not on another device.
  Future<void> markTipsSeen(Iterable<String> ids, String uid) async {
    final WriteBatch batch = _db.batch();
    for (final String id in ids) {
      batch.update(_tips.doc(id), <String, dynamic>{
        'seen_by': FieldValue.arrayUnion(<String>[uid]),
      });
    }
    await batch.commit();
  }

  Future<void> unsaveTip(String id, String uid) => _tips.doc(id).update(
        <String, dynamic>{'saved_by': FieldValue.arrayRemove(<String>[uid])},
      );

  // ── Files (library + course files) ────────────────────────────────────────

  static LibraryFile _file(String id, Map<String, dynamic> m) => LibraryFile(
        id: id,
        title: m.str('title', m.str('name')),
        url: m.str('url'),
        storagePath: m.str('storage_path'),
        fileName: m.str('file_name'),
        sizeBytes: m.integer('size_bytes'),
        createdAt: m.date(FirebaseCollections.createdAtField) ?? DateTime.now(),
      );

  /// Opens the picker; null when the admin cancels.
  static Future<PlatformFile?> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // The browser has no path, so it needs the bytes.
      withData: kIsWeb,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// `files/{folder}/{timestamp}_{name}` → the file's download URL.
  Future<({String url, String path})> _upload(
    PlatformFile file,
    String folder, {
    void Function(double progress)? onProgress,
  }) async {
    final String safeName = file.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final String path = '${FirebaseCollections.storageFiles}/$folder/'
        '${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final Reference ref = AppFirebase.storage.ref(path);
    final UploadTask task = picked.startUpload(
      ref,
      file,
      SettableMetadata(contentType: contentTypeFor(file.name)),
    );
    final Stream<TaskSnapshot> events = task.snapshotEvents;
    events.listen((TaskSnapshot s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    }, onError: (Object _) {});
    final TaskSnapshot done = await task;
    return (url: await done.ref.getDownloadURL(), path: path);
  }

  static String contentTypeFor(String name) {
    final String ext = name.split('.').last.toLowerCase();
    const Map<String, String> types = <String, String>{
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip': 'application/zip',
      'rar': 'application/vnd.rar',
      'txt': 'text/plain',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'dwg': 'application/acad',
      'dxf': 'application/dxf',
    };
    return types[ext] ?? 'application/octet-stream';
  }

  Future<void> _deleteObject(String path) async {
    if (path.isEmpty) return;
    try {
      await AppFirebase.storage.ref(path).delete();
    } on FirebaseException catch (_) {
      // Already gone — not worth failing the delete over.
    }
  }

  Map<String, dynamic> _fileFields(
    PlatformFile file,
    ({String url, String path}) up,
    String title,
  ) =>
      <String, dynamic>{
        'title': title.trim().isEmpty ? file.name : title.trim(),
        'url': up.url,
        'storage_path': up.path,
        'file_name': file.name,
        'size_bytes': file.size,
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      };

  // Library

  Stream<List<LibraryFile>> watchLibrary() => _library
      .orderBy(FirebaseCollections.createdAtField, descending: true)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) => <LibraryFile>[
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs)
              _file(d.id, d.data()),
          ]);

  Future<void> addLibraryFile(
    PlatformFile file, {
    String title = '',
    void Function(double progress)? onProgress,
  }) async {
    final ({String url, String path}) up =
        await _upload(file, 'library', onProgress: onProgress);
    await _library.add(_fileFields(file, up, title));
  }

  Future<void> deleteLibraryFile(LibraryFile file) async {
    await _library.doc(file.id).delete();
    await _deleteObject(file.storagePath);
  }

  // Course files

  Stream<List<CourseEntry>> watchCourseFiles(String course) => _courseFiles
      .where('course', isEqualTo: course)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) {
        final List<CourseEntry> out = <CourseEntry>[
          for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs)
            _entry(d.id, d.data()),
        ];
        // Folders A→Z; files newest first.
        out.sort((CourseEntry a, CourseEntry b) {
          if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
          if (a.isFolder) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          return _newestFirst(a.createdAt, b.createdAt);
        });
        return out;
      });

  static CourseEntry _entry(String id, Map<String, dynamic> m) {
    final bool folder = m.str('kind') != 'file';
    return CourseEntry(
      id: id,
      course: m.str('course'),
      kind: folder ? CourseEntryKind.folder : CourseEntryKind.file,
      name: m.str('name', m.str('title')),
      folderId: m.str('folder_id'),
      file: folder ? null : _file(id, m),
      createdAt: m.date(FirebaseCollections.createdAtField) ?? DateTime.now(),
    );
  }

  /// The member Library keeps its folders in `course_files` too, under
  /// this reserved "course" name — no video category can be called this.
  static const String libraryCourse = '__library__';

  /// Creates the folder; resolves to its id.
  Future<String> addCourseFolder(String course, String name) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _courseFiles.add(<String, dynamic>{
      'course': course,
      'kind': 'folder',
      'name': name.trim(),
      FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// The folders of [course], A→Z (for the "upload into which folder?"
  /// dialog).
  Future<List<CourseEntry>> courseFolders(String course) async {
    final QuerySnapshot<Map<String, dynamic>> s =
        await _courseFiles.where('course', isEqualTo: course).get();
    return <CourseEntry>[
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs)
        _entry(d.id, d.data()),
    ].where((CourseEntry e) => e.isFolder).toList()
      ..sort((CourseEntry a, CourseEntry b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> renameCourseFolder(String id, String name) =>
      _courseFiles.doc(id).update(<String, dynamic>{'name': name.trim()});

  Future<void> addCourseFile(
    String course,
    String folderId,
    PlatformFile file, {
    String title = '',
    void Function(double progress)? onProgress,
  }) async {
    final ({String url, String path}) up =
        await _upload(file, 'course', onProgress: onProgress);
    final Map<String, dynamic> fields = _fileFields(file, up, title);
    await _courseFiles.add(<String, dynamic>{
      ...fields,
      'course': course,
      'kind': 'file',
      'name': fields['title'],
      'folder_id': folderId,
    });
  }

  Future<void> deleteCourseFile(CourseEntry entry) async {
    await _courseFiles.doc(entry.id).delete();
    await _deleteObject(entry.file?.storagePath ?? '');
  }

  /// The folder and every file in it.
  Future<void> deleteCourseFolder(
    CourseEntry folder,
    List<CourseEntry> all,
  ) async {
    for (final CourseEntry e in all) {
      if (!e.isFolder && e.folderId == folder.id) await deleteCourseFile(e);
    }
    await _courseFiles.doc(folder.id).delete();
  }

  // ── Per-course settings ───────────────────────────────────────────────────

  /// A course name as a document id ('' = the "General" course).
  static String courseDocId(String course) {
    final String c = course.trim();
    if (c.isEmpty) return '_general';
    return c.replaceAll(RegExp(r'[/\\.#$\[\]]'), '_');
  }

  /// course name → sequential (only courses the admin set).
  Stream<Map<String, bool>> watchCourseSequential() => _courseSettings
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) => <String, bool>{
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs)
              if (d.data()['sequential'] is bool)
                d.data().str('name'): d.data()['sequential'] as bool,
          });

  /// course name → the line the admin wrote under its title ('' = none).
  Stream<Map<String, String>> watchCourseSubtitles() => _courseSettings
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) => <String, String>{
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs)
              if (d.data().str('subtitle').trim().isNotEmpty)
                d.data().str('name'): d.data().str('subtitle').trim(),
          });

  Future<void> setCourseSubtitle(String course, String subtitle) =>
      _courseSettings.doc(courseDocId(course)).set(<String, dynamic>{
        'name': course.trim(),
        'subtitle': subtitle.trim(),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> setCourseSequential(String course, bool value) =>
      _courseSettings.doc(courseDocId(course)).set(<String, dynamic>{
        'name': course.trim(),
        'sequential': value,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ── Default (free) / custom videos ────────────────────────────────────────

  Future<void> setVideoFree(String videoId, bool free) => _db
      .collection(FirebaseCollections.videos)
      .doc(videoId)
      .update(<String, dynamic>{
        FirebaseCollections.freeField: free,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  // ── Watch progress (stars) ────────────────────────────────────────────────

  static MemberProgress _progressOf(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.safeData;
    final Map<String, dynamic> raw = m.nested('videos');
    return MemberProgress(
      uid: d.id,
      name: m.str('name'),
      videos: <String, double>{
        for (final MapEntry<String, dynamic> e in raw.entries)
          if (e.value is num) e.key: (e.value as num).toDouble().clamp(0.0, 1.0),
      },
      updatedAt: m.date(FirebaseCollections.updatedAtField),
    );
  }

  Stream<List<MemberProgress>> watchAllProgress() => _progress
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) =>
          s.docs.map(_progressOf).toList());

  /// Merges [videos] into the member's own progress document.
  Future<void> writeProgress({
    required String uid,
    required String name,
    required Map<String, double> videos,
  }) =>
      _progress.doc(uid).set(<String, dynamic>{
        'name': name,
        'videos': videos,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
