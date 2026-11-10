/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_form_cubit.dart
/// Purpose: Declares `CvFormCubit` and `CvFormState` — the member's own CV:
///          loading it, editing every field, the photo upload, and saving.
/// Author: ASEC team
/// Created: 20/9/2026

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/cv/c1_cv/data/repository/cv_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/base_repository/cv_base_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/constants/cv_options.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';

enum CvFormStatus { loading, editing, uploading, saving, saved, failure }

/// Which of the two uploads is running, so the form can put the progress bar
/// under the right control instead of on both.
enum CvUploadKind { none, photo, file }

class CvFormState {
  final CvProfile cv;
  final CvFormStatus status;

  /// True until the first successful save: the screen says "Create" rather
  /// than "Edit", and the save writes `created_at`.
  final bool isNew;

  /// 0..1 while something goes up.
  final double progress;

  /// What that something is.
  final CvUploadKind uploading;

  /// Set when the picked CV file is over the cap. Not an [AppFailure]: it is
  /// the member's file that is wrong, not the network, and it clears as soon
  /// as they pick another.
  final bool fileTooLarge;

  /// Set when Save was pressed with required fields still empty. The form
  /// then marks every empty one at once rather than one per attempt.
  final bool showErrors;

  final AppFailure? failure;

  const CvFormState({
    required this.cv,
    this.status = CvFormStatus.loading,
    this.isNew = true,
    this.progress = 0,
    this.uploading = CvUploadKind.none,
    this.showErrors = false,
    this.fileTooLarge = false,
    this.failure,
  });

  bool get isBusy =>
      status == CvFormStatus.uploading || status == CvFormStatus.saving;

  /// The skills offered for the role that is currently picked.
  /// 09/11/2026: only the fixed professional skills (CvOptions.proSkills).
  List<String> get availableProSkills => CvOptions.skillsFor(cv.role);

  CvFormState copyWith({
    CvProfile? cv,
    CvFormStatus? status,
    bool? isNew,
    double? progress,
    CvUploadKind? uploading,
    bool? showErrors,
    bool? fileTooLarge,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return CvFormState(
      cv: cv ?? this.cv,
      status: status ?? this.status,
      isNew: isNew ?? this.isNew,
      progress: progress ?? this.progress,
      uploading: uploading ?? this.uploading,
      showErrors: showErrors ?? this.showErrors,
      fileTooLarge: fileTooLarge ?? this.fileTooLarge,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class CvFormCubit extends Cubit<CvFormState> {
  /// 10 MB. The Storage rules enforce the same number — this one is only so
  /// the member is told before spending the upload rather than after.
  static const int maxCvFileBytes = 10 * 1024 * 1024;
  static const String maxCvFileMb = '10';

  CvFormCubit({required this.user, CvBaseRepository? repository})
      : _repository = repository ?? CvRepository(),
        super(CvFormState(
          // Seeded from the account so the first three fields are already
          // right; the member can still change any of them.
          cv: CvProfile(
            uid: user.uid,
            fullName: user.fullName,
            email: user.email,
            phone: user.phone,
            specialization: CvOptions.defaultSpecialization,
          ),
        ));

  final CvBaseRepository _repository;
  final AppUser user;

  UploadTask? _task;
  StreamSubscription<TaskSnapshot>? _progressSub;

  /// Reads the CV if there is one. A missing CV is not a failure — it is the
  /// normal state of a member who has not written one yet.
  Future<void> load() async {
    try {
      final CvProfile? existing = await _repository.fetch(user.uid);
      if (isClosed) return;
      if (existing == null) {
        emit(state.copyWith(status: CvFormStatus.editing, isNew: true));
        return;
      }
      // A CV saved before the lists were narrowed may hold a specialization
      // or role that is no longer offered: fall back to the default
      // specialization and ask for the role again.
      CvProfile cv = existing;
      if (!CvOptions.specializations.contains(cv.specialization)) {
        cv = cv.copyWith(specialization: CvOptions.defaultSpecialization);
      }
      if (cv.languages.any((String l) => !CvOptions.languages.contains(l))) {
        cv = cv.copyWith(languages: <String>[
          for (final String l in cv.languages)
            if (CvOptions.languages.contains(l)) l,
        ]);
      }
      // 09/11/2026: skills no longer offered are dropped from the form.
      if (cv.proSkills.any((String k) => !CvOptions.proSkills.contains(k)) ||
          cv.softSkills.any((String k) => !CvOptions.softSkills.contains(k))) {
        cv = cv.copyWith(
          proSkills: <String>[
            for (final String k in cv.proSkills)
              if (CvOptions.proSkills.contains(k)) k,
          ],
          softSkills: <String>[
            for (final String k in cv.softSkills)
              if (CvOptions.softSkills.contains(k)) k,
          ],
        );
      }
      if (cv.role.isNotEmpty && !CvOptions.roles.contains(cv.role)) {
        cv = cv.copyWith(role: '');
      }
      emit(state.copyWith(
        cv: cv,
        status: CvFormStatus.editing,
        isNew: false,
      ));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(
        status: CvFormStatus.editing,
        failure: AppFailure.from(error),
      ));
    }
  }

  // ── Fields ───────────────────────────────────────────────────────────────

  void setFullName(String v) => _edit(state.cv.copyWith(fullName: v));
  void setEmail(String v) => _edit(state.cv.copyWith(email: v));
  void setPhone(String v) => _edit(state.cv.copyWith(phone: v));
  void setBio(String v) => _edit(state.cv.copyWith(bio: v));
  void setFacebook(String v) => _edit(state.cv.copyWith(facebookLink: v));
  void setLinkedin(String v) => _edit(state.cv.copyWith(linkedinLink: v));
  void setPortfolio(String v) => _edit(state.cv.copyWith(portfolioLink: v));

  void setLocation(String? v) => _edit(state.cv.copyWith(location: v ?? ''));
  void setMilitaryStatus(String? v) =>
      _edit(state.cv.copyWith(militaryStatus: v ?? ''));
  void setGraduationYear(String? v) =>
      _edit(state.cv.copyWith(graduationYear: v ?? ''));
  void setSpecialization(String? v) =>
      _edit(state.cv.copyWith(specialization: v ?? ''));

  /// A NEW ROLE CLEARS THE PROFESSIONAL SKILLS. They were picked from the old
  /// role's list, and keeping "Site Supervision" on a sales engineer's CV is
  /// worse than making them pick again.
  /// A new role only changes which skills are OFFERED; the skills already
  /// chosen are kept, so nothing the member picked disappears.
  void setRole(String? v) => _edit(state.cv.copyWith(role: v ?? ''));

  void setProSkills(List<String> v) => _edit(state.cv.copyWith(proSkills: v));
  void setSoftSkills(List<String> v) => _edit(state.cv.copyWith(softSkills: v));
  void setLanguages(List<String> v) => _edit(state.cv.copyWith(languages: v));

  void _edit(CvProfile cv) => emit(state.copyWith(cv: cv, clearFailure: true));

  // ── Photo ────────────────────────────────────────────────────────────────

  Future<void> pickPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.first;
    final String previousPath = state.cv.photoPath;

    await _run(
      kind: CvUploadKind.photo,
      start: () => _repository.startPhotoUpload(file: file, uid: user.uid),
      onDone: (CvUpload upload, String url) => state.cv.copyWith(
        photoUrl: url,
        photoPath: upload.storagePath,
      ),
      previousPath: previousPath,
    );
  }

  // ── The CV file ──────────────────────────────────────────────────────────

  /// The CV itself — PDF or Word, UPLOADED. There is deliberately no field to
  /// paste a Drive link into: a link is somebody else's permission setting,
  /// and it stops working without anybody here being told.
  Future<void> pickCvFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf', 'doc', 'docx'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.first;
    if (file.size > maxCvFileBytes) {
      emit(state.copyWith(fileTooLarge: true, clearFailure: true));
      return;
    }

    final String previousPath = state.cv.cvFilePath;
    emit(state.copyWith(fileTooLarge: false));

    await _run(
      kind: CvUploadKind.file,
      start: () => _repository.startFileUpload(file: file, uid: user.uid),
      onDone: (CvUpload upload, String url) => state.cv.copyWith(
        cvFileUrl: url,
        cvFilePath: upload.storagePath,
        cvFileName: upload.fileName,
        cvFileSize: file.size,
      ),
      previousPath: previousPath,
    );
  }

  /// Clears the CV file from the profile and drops the object behind it. The
  /// profile still has to be saved — this changes the form, not the document.
  Future<void> removeCvFile() async {
    final String path = state.cv.cvFilePath;
    emit(state.copyWith(
      fileTooLarge: false,
      cv: state.cv.copyWith(
        cvFileUrl: '',
        cvFilePath: '',
        cvFileName: '',
        cvFileSize: 0,
      ),
    ));
    if (path.isNotEmpty) await _repository.deleteObject(path);
  }

  /// One upload, whichever it is: start it, follow it, read the download URL,
  /// then drop the object it replaced.
  Future<void> _run({
    required CvUploadKind kind,
    required CvUpload Function() start,
    required CvProfile Function(CvUpload upload, String url) onDone,
    required String previousPath,
  }) async {
    emit(state.copyWith(
      status: CvFormStatus.uploading,
      uploading: kind,
      progress: 0,
      clearFailure: true,
    ));

    try {
      final CvUpload upload = start();
      _task = upload.task;
      _progressSub = upload.task.snapshotEvents.listen(
        (TaskSnapshot snap) {
          if (isClosed || snap.totalBytes <= 0) return;
          emit(state.copyWith(
            progress: snap.bytesTransferred / snap.totalBytes,
          ));
        },
        onError: (Object _) {},
      );

      final TaskSnapshot done = await upload.task;
      final String url = await done.ref.getDownloadURL();
      await _progressSub?.cancel();
      _progressSub = null;
      _task = null;
      if (isClosed) return;

      emit(state.copyWith(
        status: CvFormStatus.editing,
        uploading: CvUploadKind.none,
        cv: onDone(upload, url),
      ));

      // Only now: the replacement is safely up, so losing the old one costs
      // nothing. Doing it first would leave the member with neither if the
      // upload failed half way.
      if (previousPath.isNotEmpty && previousPath != upload.storagePath) {
        await _repository.deleteObject(previousPath);
      }
    } catch (error) {
      if (isClosed) return;
      if (error is FirebaseException && error.code == 'canceled') {
        emit(state.copyWith(
          status: CvFormStatus.editing,
          uploading: CvUploadKind.none,
        ));
        return;
      }
      emit(state.copyWith(
        status: CvFormStatus.editing,
        uploading: CvUploadKind.none,
        failure: AppFailure.from(error),
      ));
    }
  }

  Future<void> cancelUpload() async {
    await _task?.cancel();
    await _progressSub?.cancel();
    _task = null;
    _progressSub = null;
    if (isClosed) return;
    emit(state.copyWith(
      status: CvFormStatus.editing,
      uploading: CvUploadKind.none,
      progress: 0,
    ));
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (state.isBusy) return;

    if (!state.cv.isComplete) {
      emit(state.copyWith(showErrors: true, status: CvFormStatus.editing));
      return;
    }

    emit(state.copyWith(status: CvFormStatus.saving, clearFailure: true));
    final bool wasNew = state.isNew;

    final Either<AppFailure, Unit> result =
        await _repository.save(state.cv, isNew: wasNew);
    if (isClosed) return;

    result.fold(
      (AppFailure f) => emit(state.copyWith(
        status: CvFormStatus.failure,
        failure: f,
      )),
      (_) => emit(state.copyWith(
        status: CvFormStatus.saved,
        isNew: false,
        showErrors: false,
      )),
    );
  }

  @override
  Future<void> close() {
    _progressSub?.cancel();
    return super.close();
  }
}
