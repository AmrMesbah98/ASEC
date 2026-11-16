/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_remote_data_source.dart
/// Purpose: Declares `CvRemoteDataSource` — `cvs` in Firestore and the photos
///          behind it in Cloud Storage.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:asec/core/constants/firebase_collections.dart';
// Prefixed: this class has an upload method of its own.
import 'package:asec/core/helper/upload/picked_upload.dart' as picked;
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/cv/c1_cv/data/models/cv_model.dart';
import 'package:asec/features/cv/c1_cv/domain/base_repository/cv_base_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/domain/enums/cv_status.dart';

class CvRemoteDataSource {
  CollectionReference<Map<String, dynamic>> get _cvs =>
      AppFirebase.db.collection(FirebaseCollections.cvs);

  /// Sorted on the client, newest first — see the other data sources: an
  /// `orderBy` beside a `where` would need a composite index.
  Stream<List<CvProfile>> watchAll() => _cvs.snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> snap) {
          final List<CvProfile> list =
              snap.docs.map(CvModel.fromDoc).toList()
                ..sort((CvProfile a, CvProfile b) =>
                    (b.updatedAt ?? b.createdAt ?? DateTime(0))
                        .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(0)));
          return list;
        },
      );

  Stream<CvProfile?> watchCv(String uid) => _cvs.doc(uid).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> doc) =>
            doc.exists ? CvModel.fromDoc(doc) : null,
      );

  Future<CvProfile?> fetch(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _cvs.doc(uid).get();
    if (!doc.exists) return null;
    return CvModel.fromDoc(doc);
  }

  /// `set` with the uid as the id: one CV per account, and a second save
  /// updates rather than adding a duplicate.
  Future<void> save(CvProfile cv, {required bool isNew}) => _cvs
      .doc(cv.uid)
      .set(CvModel.toMap(cv, isCreate: isNew), SetOptions(merge: !isNew));

  Future<void> setStatus(String uid, CvStatus status) =>
      _cvs.doc(uid).update(CvModel.toStatusMap(status));

  /// Every CV made before Approve / Reject arrived (16/11/2026) is approved
  /// once, the first time an admin who reviews CVs opens the app. CVs made
  /// after [_reviewStart] stay Pending until the admin taps Approve or Reject.
  /// Safe to run again: once done, nothing matches any more.
  static final DateTime _reviewStart = DateTime.utc(2026, 11, 16, 9, 30);
  static bool _approvedOld = false;

  Future<void> approveExistingOnce() async {
    if (_approvedOld) return;
    _approvedOld = true;
    try {
      final QuerySnapshot<Map<String, dynamic>> all = await _cvs.get();
      WriteBatch batch = AppFirebase.db.batch();
      int n = 0;
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in all.docs) {
        final CvStatus st = CvStatus.fromKey(d.data()[CvModel.status] as String?);
        if (st != CvStatus.pending) continue; // already Approved / Rejected
        final Object? made = d.data()[FirebaseCollections.createdAtField];
        final DateTime? at = made is Timestamp ? made.toDate().toUtc() : null;
        if (at != null && !at.isBefore(_reviewStart)) continue; // a new CV: the admin decides
        batch.update(d.reference, CvModel.toStatusMap(CvStatus.approved));
        if (++n % 400 == 0) {
          await batch.commit();
          batch = AppFirebase.db.batch();
        }
      }
      if (n % 400 != 0) await batch.commit();
    } catch (_) {
      _approvedOld = false; // try again next start
    }
  }

  Future<void> delete(CvProfile cv) async {
    await _cvs.doc(cv.uid).delete();
    // Both objects, not just the photo: a deleted CV that leaves its PDF in
    // the bucket is a file nobody can reach and everybody keeps paying for.
    await deleteObject(cv.photoPath);
    await deleteObject(cv.cvFilePath);
  }

  /// Removes one Storage object. An object that is already gone is not an
  /// error worth failing the surrounding operation over.
  Future<void> deleteObject(String path) async {
    if (path.isEmpty) return;
    try {
      await AppFirebase.storage.ref(path).delete();
    } on FirebaseException catch (_) {
      // object-not-found, or a file written by an older build.
    }
  }

  /// `cvs/{uid}/{timestamp}_{name}` — the uid in the path is what the Storage
  /// rules match on.
  CvUpload startPhotoUpload({
    required PlatformFile file,
    required String uid,
  }) =>
      _start(
        file: file,
        path: '${FirebaseCollections.storageCvs}/$uid/${_stampedName(file)}',
        contentType: _imageTypeFor(file.name),
      );

  /// `cvs/{uid}/doc/{timestamp}_{name}` — the CV document itself.
  ///
  /// A FOLDER OF ITS OWN, because the Storage rules are what actually decide
  /// what may be written: `cvs/{uid}/{file}` accepts images only, and a PDF
  /// written there would be refused. The `doc/` segment is a different rule
  /// with a different content type and a different size cap.
  CvUpload startFileUpload({
    required PlatformFile file,
    required String uid,
  }) =>
      _start(
        file: file,
        path:
            '${FirebaseCollections.storageCvs}/$uid/${FirebaseCollections.storageCvDocs}/${_stampedName(file)}',
        contentType: _documentTypeFor(file.name),
      );

  CvUpload _start({
    required PlatformFile file,
    required String path,
    required String contentType,
  }) {
    final Reference ref = AppFirebase.storage.ref(path);
    final UploadTask task = picked.startUpload(
      ref,
      file,
      SettableMetadata(
        contentType: contentType,
        // So a browser offers to save it under the name the member chose
        // rather than the timestamped object name.
        contentDisposition: 'attachment; filename="${file.name}"',
      ),
    );
    return CvUpload(task: task, storagePath: path, fileName: file.name);
  }

  /// A timestamp keeps a replacement from overwriting the old object before
  /// the new one has finished going up.
  static String _stampedName(PlatformFile file) {
    final String safeName = file.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    return '${DateTime.now().millisecondsSinceEpoch}_$safeName';
  }

  static String _imageTypeFor(String name) {
    switch (name.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        // The picker was opened with FileType.image, and the Storage rules
        // only accept `image/*`.
        return 'image/jpeg';
    }
  }

  static String _documentTypeFor(String name) {
    switch (name.split('.').last.toLowerCase()) {
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument'
            '.wordprocessingml.document';
      default:
        return 'application/pdf';
    }
  }
}
