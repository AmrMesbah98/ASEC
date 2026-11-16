/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_form_cubit.dart
/// Purpose: Declares `CvFormCubit`, `CvFormState` and `CvValidators` — the
///          member's own CV: loading it, editing every field, the photo
///          upload, and saving.
/// Author: ASEC team
/// Created: 20/9/2026
/// Updated: 16/11/2026 - The form's LOGIC is ENGX's (CVCubit +
///          CreateCVScreen):
///          * required: full name, email, phone, location, military status,
///            graduation year, specialization, role, at least one language,
///            one soft skill and one professional skill, and "About you";
///          * email must look like an email, phone at least 10 digits, and
///            the optional links must be real links;
///          * a new SPECIALIZATION clears the role and the professional
///            skills; a new ROLE clears the professional skills;
///          * the profile photo is at most 5 MB;
///          * the CV file is a LINK (Google Drive or any cloud link), as in
///            ENGX — no upload.
///          What stays ASEC's: the CV belongs to the ACCOUNT (document id =
///          uid), a new CV is Pending until the admin approves or rejects
///          it, and only members the admin allowed may write one.

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

/// Which upload is running. Only the photo is uploaded now (the CV file is a
/// link); kept as an enum so the form reads the same.
enum CvUploadKind { none, photo, file }

/// ENGX's checks, word for word in what they accept. Each returns null when
/// the value is fine, or what is wrong (English; the form translates).
abstract final class CvValidators {
  const CvValidators._();

  static final RegExp _email =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  static final RegExp _url =
      RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$');

  /// Empty is left to the "required" check.
  static bool emailOk(String email) =>
      email.trim().isEmpty || _email.hasMatch(email.trim());

  static bool phoneOk(String phone) =>
      phone.trim().isEmpty || phone.trim().length >= 10;

  /// Optional links: empty is fine.
  static bool urlOk(String url) =>
      url.trim().isEmpty || _url.hasMatch(url.trim());

  /// Everything ENGX's Save checks.
  static bool isValid(CvProfile cv) =>
      cv.fullName.trim().isNotEmpty &&
      cv.email.trim().isNotEmpty &&
      cv.phone.trim().isNotEmpty &&
      cv.location.isNotEmpty &&
      cv.militaryStatus.isNotEmpty &&
      cv.graduationYear.isNotEmpty &&
      cv.specialization.isNotEmpty &&
      cv.role.isNotEmpty &&
      cv.languages.isNotEmpty &&
      cv.softSkills.isNotEmpty &&
      cv.proSkills.isNotEmpty &&
      cv.bio.trim().isNotEmpty &&
      emailOk(cv.email) &&
      phoneOk(cv.phone) &&
      urlOk(cv.facebookLink) &&
      urlOk(cv.linkedinLink) &&
      urlOk(cv.cvFileUrl) &&
      urlOk(cv.portfolioLink);
}

class CvFormState {
  final CvProfile cv;
  final CvFormStatus status;

  /// True until the first successful save: the screen says "Create" rather
  /// than "Edit", and the save writes `created_at`.
  final bool isNew;

  /// 0..1 while the photo goes up.
  final double progress;

  final CvUploadKind uploading;

  /// Set when Save was pressed with something missing or wrong. The form
  /// then marks every such field at once (ENGX's `submitted`).
  final bool showErrors;

  final AppFailure? failure;

  const CvFormState({
    required this.cv,
    this.status = CvFormStatus.loading,
    this.isNew = true,
    this.progress = 0,
    this.uploading = CvUploadKind.none,
    this.showErrors = false,
    this.failure,
  });

  bool get isBusy =>
      status == CvFormStatus.uploading || status == CvFormStatus.saving;

  /// The professional skills offered for the role that is picked.
  List<String> get availableProSkills => CvOptions.skillsFor(cv.role);

  CvFormState copyWith({
    CvProfile? cv,
    CvFormStatus? status,
    bool? isNew,
    double? progress,
    CvUploadKind? uploading,
    bool? showErrors,
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
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class CvFormCubit extends Cubit<CvFormState> {
  /// ENGX: "Image size must be less than 5MB".
  static const int maxPhotoBytes = 5 * 1024 * 1024;

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
          ),
        ));

  final CvBaseRepository _repository;
  final AppUser user;

  UploadTask? _task;
  StreamSubscription<TaskSnapshot>? _progressSub;

  /// A CV file UPLOADED before the form took links instead. Removed from
  /// Storage once a save replaces it with a link (or clears it).
  String _uploadedFilePath = '';

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
      _uploadedFilePath = existing.cvFilePath;
      emit(state.copyWith(
        cv: _onlyOffered(existing),
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

  /// A CV saved with the older ASEC lists may hold values the dropdowns no
  /// longer offer. Those are emptied, so the member picks them again
  /// instead of the form failing on a value that is not in its list.
  CvProfile _onlyOffered(CvProfile cv) {
    String keep(String v, List<String> offered) => offered.contains(v) ? v : '';
    List<String> keepAll(List<String> v, List<String> offered) =>
        <String>[for (final String x in v) if (offered.contains(x)) x];

    final String role = keep(cv.role, CvOptions.roles);
    return cv.copyWith(
      location: keep(cv.location, CvOptions.governorates),
      militaryStatus: keep(cv.militaryStatus, CvOptions.militaryStatus),
      graduationYear: keep(cv.graduationYear, CvOptions.graduationYears()),
      specialization: keep(cv.specialization, CvOptions.specializations),
      role: role,
      proSkills: keepAll(cv.proSkills, CvOptions.skillsFor(role)),
      softSkills: keepAll(cv.softSkills, CvOptions.softSkills),
      languages: keepAll(cv.languages, CvOptions.languages),
    );
  }

  // ── Fields ───────────────────────────────────────────────────────────────

  void setFullName(String v) => _edit(state.cv.copyWith(fullName: v));
  void setEmail(String v) => _edit(state.cv.copyWith(email: v));
  void setPhone(String v) => _edit(state.cv.copyWith(phone: v));
  void setBio(String v) => _edit(state.cv.copyWith(bio: v));
  void setFacebook(String v) => _edit(state.cv.copyWith(facebookLink: v));
  void setLinkedin(String v) => _edit(state.cv.copyWith(linkedinLink: v));
  void setPortfolio(String v) => _edit(state.cv.copyWith(portfolioLink: v));

  /// ENGX's "CV file link": a Google Drive (or any cloud) link to the CV.
  void setCvLink(String v) => _edit(state.cv.copyWith(
        cvFileUrl: v,
        cvFilePath: '',
        cvFileName: '',
        cvFileSize: 0,
      ));

  void setLocation(String? v) => _edit(state.cv.copyWith(location: v ?? ''));
  void setMilitaryStatus(String? v) =>
      _edit(state.cv.copyWith(militaryStatus: v ?? ''));
  void setGraduationYear(String? v) =>
      _edit(state.cv.copyWith(graduationYear: v ?? ''));

  /// ENGX: a new specialization resets the role and the skills.
  void setSpecialization(String? v) => _edit(state.cv.copyWith(
        specialization: v ?? '',
        role: '',
        proSkills: const <String>[],
      ));

  /// ENGX: a new role clears the professional skills (they came from the
  /// old role's list).
  void setRole(String? v) => _edit(state.cv.copyWith(
        role: v ?? '',
        proSkills: const <String>[],
      ));

  void setProSkills(List<String> v) => _edit(state.cv.copyWith(proSkills: v));
  void setSoftSkills(List<String> v) => _edit(state.cv.copyWith(softSkills: v));
  void setLanguages(List<String> v) => _edit(state.cv.copyWith(languages: v));

  void _edit(CvProfile cv) => emit(state.copyWith(cv: cv, clearFailure: true));

  // ── Photo ────────────────────────────────────────────────────────────────

  /// Picks and uploads the photo. Returns false when the picked image is
  /// over 5 MB (nothing is uploaded; the form says so).
  Future<bool> pickPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowCompression: true,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return true;

    final PlatformFile file = result.files.first;
    if (file.size > maxPhotoBytes) return false;

    final String previousPath = state.cv.photoPath;
    emit(state.copyWith(
      status: CvFormStatus.uploading,
      uploading: CvUploadKind.photo,
      progress: 0,
      clearFailure: true,
    ));

    try {
      final CvUpload upload =
          _repository.startPhotoUpload(file: file, uid: user.uid);
      _task = upload.task;
      _progressSub = upload.task.snapshotEvents.listen(
        (TaskSnapshot snap) {
          if (isClosed || snap.totalBytes <= 0) return;
          emit(state.copyWith(progress: snap.bytesTransferred / snap.totalBytes));
        },
        onError: (Object _) {},
      );

      final TaskSnapshot done = await upload.task;
      final String url = await done.ref.getDownloadURL();
      await _progressSub?.cancel();
      _progressSub = null;
      _task = null;
      if (isClosed) return true;

      emit(state.copyWith(
        status: CvFormStatus.editing,
        uploading: CvUploadKind.none,
        cv: state.cv.copyWith(photoUrl: url, photoPath: upload.storagePath),
      ));

      // Only now: the new photo is safely up, so losing the old one costs
      // nothing.
      if (previousPath.isNotEmpty && previousPath != upload.storagePath) {
        await _repository.deleteObject(previousPath);
      }
    } catch (error) {
      if (isClosed) return true;
      emit(state.copyWith(
        status: CvFormStatus.editing,
        uploading: CvUploadKind.none,
        failure: error is FirebaseException && error.code == 'canceled'
            ? null
            : AppFailure.from(error),
      ));
    }
    return true;
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

  /// Returns false when something is missing or wrong (the form then shows
  /// ENGX's "Incomplete information" dialog and marks every such field).
  Future<bool> save() async {
    if (state.isBusy) return true;

    if (!CvValidators.isValid(state.cv)) {
      emit(state.copyWith(showErrors: true, status: CvFormStatus.editing));
      return false;
    }

    emit(state.copyWith(
      status: CvFormStatus.saving,
      showErrors: true,
      clearFailure: true,
    ));
    final bool wasNew = state.isNew;

    final Either<AppFailure, Unit> result =
        await _repository.save(state.cv, isNew: wasNew);
    if (isClosed) return true;

    final bool ok = result.isRight();
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

    // The old uploaded CV file was replaced by a link (or cleared).
    if (ok &&
        _uploadedFilePath.isNotEmpty &&
        state.cv.cvFilePath != _uploadedFilePath) {
      final String path = _uploadedFilePath;
      _uploadedFilePath = '';
      await _repository.deleteObject(path);
    }
    return true;
  }

  @override
  Future<void> close() {
    _progressSub?.cancel();
    return super.close();
  }
}
