/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: users_remote_data_source.dart
/// Purpose: Declares `UsersRemoteDataSource` — every read and write against
///          `users` and Firebase Auth.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:asec/features/onboarding/o2_authentication/data/device/device_identity.dart';
import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/network/login_diagnostics.dart';
import 'package:asec/core/settings/build_gate.dart';
import 'package:asec/features/cv/c1_cv/data/data_source/remote_data_source/cv_remote_data_source.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';

class UsersRemoteDataSource {
  CollectionReference<Map<String, dynamic>> get _users =>
      AppFirebase.db.collection(FirebaseCollections.users);

  // ── Desktop token race ───────────────────────────────────────────────────
  //
  // On Windows / Linux / macOS Firebase runs on the C++ SDK. Right after
  // `signInWithEmailAndPassword` returns, Firestore has NOT received the new
  // ID token yet, so the first reads/writes go out with `request.auth == null`
  // and the rules answer 'permission-denied' — for every account, the super
  // admin included. Phones hand the token over at once, so they never see it.
  // Here a refusal on desktop forces a fresh token and tries again a few
  // times (about 6 s in total) before it is treated as a real refusal.

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<T> _afterAuthReady<T>(User authUser, Future<T> Function() run) async {
    const int maxTries = 6;
    for (int attempt = 1; ; attempt++) {
      try {
        final T result = await run();
        LoginDiagnostics.log('firestore attempt $attempt OK');
        return result;
      } on FirebaseException catch (error) {
        LoginDiagnostics.log(
            'firestore attempt $attempt refused: ${error.code}');
        if (error.code != 'permission-denied' ||
            !_isDesktop ||
            attempt >= maxTries) {
          rethrow;
        }
        try {
          await authUser.getIdToken(true);
        } catch (_) {}
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<UserCredential> signIn(String email, String password) async {
    final UserCredential credential = await AppFirebase.auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Signing in is the member choosing THIS device: if the admin freed the
    // account's device slot, this device may take it now.
    DeviceIdentity.forgetBinding();
    return credential;
  }

  Future<void> signOut() => AppFirebase.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      AppFirebase.auth.sendPasswordResetEmail(email: email.trim());

  User? get currentUser => AppFirebase.auth.currentUser;

  /// Deletes the signed-in account for good: the CV (and its files), the
  /// `users/{uid}` profile, then the Auth account itself.
  ///
  /// Re-authenticates with [password] FIRST. Firebase refuses `User.delete`
  /// on a session that is not fresh (`requires-recent-login`), and asking for
  /// the password is also the honest confirmation for something that cannot
  /// be undone.
  ///
  /// The Auth account goes LAST: if anything before it fails, the member can
  /// still sign in, and `fetchOrCreate` repairs a missing profile.
  Future<void> deleteAccount(String password) async {
    final User? authUser = AppFirebase.auth.currentUser;
    if (authUser == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    final AuthCredential credential = EmailAuthProvider.credential(
      email: authUser.email ?? '',
      password: password,
    );
    await authUser.reauthenticateWithCredential(credential);

    // The CV lives at `cvs/{uid}` and is visible to every member, so it must
    // not outlive its owner.
    final CvRemoteDataSource cvs = CvRemoteDataSource();
    final CvProfile? cv = await cvs.fetch(authUser.uid);
    if (cv != null) await cvs.delete(cv);

    await _users.doc(authUser.uid).delete();
    await authUser.delete();
  }

  /// Registers on the DEFAULT app, so the new account is left signed in —
  /// which is exactly what someone who just registered expects.
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final UserCredential credential =
        await AppFirebase.auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User authUser = credential.user!;
    await authUser.updateDisplayName(fullName.trim());

    final AppUser user = AppUser(
      uid: authUser.uid,
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      // THE EMAIL DECIDES, NOT THE FORM.
      role: UserRole.forEmail(email),
    );
    await _afterAuthReady(
      authUser,
      () => _users.doc(user.uid).set(UserModel.toMap(user, isCreate: true)),
    );
    // Some accounts are refused on older builds — see BuildGate.
    await BuildGate.stamp(authUser);
    return user;
  }

  // ── Profiles ─────────────────────────────────────────────────────────────

  Future<AppUser?> fetch(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// The profile for [authUser], creating it if the document is missing.
  ///
  /// A missing profile is not a dead end here the way it is in an
  /// admin-provisioned app: the Auth account exists, we know the email, and
  /// the email is what decides the role — so the honest repair is to write
  /// the document rather than to refuse the sign-in. It happens when the
  /// Firestore write failed right after `createUserWithEmailAndPassword`, or
  /// when the account was made in the Firebase console.
  Future<AppUser> fetchOrCreate(User authUser) async {
    // FIRST stamp this build: for some accounts the rules refuse even the
    // profile read until it is there (see BuildGate).
    // Both inside the desktop retry: on Windows the first try is often sent
    // before Firestore has the new sign-in token.
    final AppUser? existing = await _afterAuthReady(authUser, () async {
      await BuildGate.stamp(authUser);
      return fetch(authUser.uid);
    });
    if (existing != null) return existing;

    final String email = (authUser.email ?? '').toLowerCase();
    final AppUser repaired = AppUser(
      uid: authUser.uid,
      email: email,
      fullName: authUser.displayName ?? '',
      role: UserRole.forEmail(email),
    );
    await _afterAuthReady(
      authUser,
      () => _users
          .doc(repaired.uid)
          .set(UserModel.toMap(repaired, isCreate: true)),
    );
    await BuildGate.stamp(authUser);
    return repaired;
  }

  Stream<AppUser?> watch(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
          doc.exists ? UserModel.fromDoc(doc) : null);

  /// Every member account. Sorted on the client so the query needs no
  /// composite index.
  Stream<List<AppUser>> watchMembers() => _users
      .where(FirebaseCollections.roleField, isEqualTo: UserRole.user.key)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) {
        final List<AppUser> users =
            snap.docs.map(UserModel.fromDoc).toList(growable: false).toList()
              ..sort((AppUser a, AppUser b) => a.displayName
                  .toLowerCase()
                  .compareTo(b.displayName.toLowerCase()));
        return users;
      });

  Future<void> updateSelf(AppUser user) =>
      _users.doc(user.uid).update(UserModel.toSelfUpdateMap(user));

  Future<void> setCanCreateCv(String uid, bool allowed) =>
      _users.doc(uid).update(<String, dynamic>{
        FirebaseCollections.canCreateCvField: allowed,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  Future<void> setCanUseCalcs(String uid, bool allowed) =>
      _users.doc(uid).update(<String, dynamic>{
        FirebaseCollections.canUseCalcsField: allowed,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  Future<void> setAccess(String uid, Map<String, dynamic> access) =>
      _users.doc(uid).update(access);

  /// Freezes the member's access from now.
  Future<void> pauseAccess(String uid) => _users.doc(uid).update(<String, dynamic>{
        UserModel.pausedAt: FieldValue.serverTimestamp(),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  /// Ends the pause. The time spent paused is added to the end date, so a
  /// paused member loses no days.
  Future<void> resumeAccess(AppUser member) {
    final DateTime now = DateTime.now();
    final DateTime? until = member.accessUntil;
    final DateTime? paused = member.pausedAt;
    final DateTime? newUntil = (until != null && paused != null)
        ? until.add(now.difference(paused))
        : until;
    return _users.doc(member.uid).update(<String, dynamic>{
      UserModel.pausedAt: null,
      if (newUntil != null) UserModel.accessUntil: Timestamp.fromDate(newUntil),
      FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
    });
  }

  /// Locks the member's account to THIS device. The rules allow it only
  /// while no device is set, so two devices can never both win.
  Future<void> bindDevice(String uid) async {
    await _users.doc(uid).update(<String, dynamic>{
      UserModel.deviceId: DeviceIdentity.id,
      UserModel.deviceName: DeviceIdentity.name,
      UserModel.deviceBoundAt: FieldValue.serverTimestamp(),
    });
    DeviceIdentity.markBound(uid);
  }

  /// The admin frees the member's device: the old one is shut out at once,
  /// and the next device the member signs in on takes the slot.
  Future<void> clearDevice(String uid) => _users.doc(uid).update(<String, dynamic>{
        UserModel.deviceId: '',
        UserModel.deviceName: '',
        UserModel.deviceBoundAt: null,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  Future<void> setActive(String uid, bool active) =>
      _users.doc(uid).update(<String, dynamic>{
        FirebaseCollections.activeField: active,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });
}
