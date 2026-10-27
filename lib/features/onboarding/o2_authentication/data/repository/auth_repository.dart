/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: auth_repository.dart
/// Purpose: Declares `AuthRepository` and `UsersRepository`.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/network/guard.dart';
import 'package:asec/features/onboarding/o2_authentication/data/data_source/remote_data_source/users_remote_data_source.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/auth_failure_type.dart';

void _log(String message) {}

class AuthRepository implements AuthBaseRepository {
  AuthRepository({UsersRemoteDataSource? remote})
      : _remote = remote ?? UsersRemoteDataSource();

  final UsersRemoteDataSource _remote;

  /// Nothing waits forever: a missing Firestore database looks like a spinner
  /// that never stops unless something puts a limit on it.
  static const Duration _timeout = Duration(seconds: 20);

  @override
  Future<Either<AuthFailureType, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    if (AppFirebase.notConfigured) {
      return const Left(AuthFailureType.notConfigured);
    }

    try {
      final UserCredential credential =
          await _remote.signIn(email, password).timeout(_timeout);
      final User? authUser = credential.user;
      if (authUser == null) return const Left(AuthFailureType.unknown);
      _log('auth OK uid=${authUser.uid}');

      // The profile read is a separate failure domain from the sign-in —
      // folding both into one catch turns "no Firestore database" into a
      // misleading "no connection".
      final AppUser profile;
      try {
        profile = await _remote.fetchOrCreate(authUser).timeout(_timeout);
      } on TimeoutException {
        await _remote.signOut();
        return const Left(AuthFailureType.firestoreUnavailable);
      } on FirebaseException catch (error) {
        _log('profile read failed: ${error.code}');
        await _remote.signOut();
        return Left(error.code == 'permission-denied'
            ? AuthFailureType.rulesDenied
            : AuthFailureType.firestoreUnavailable);
      }

      if (!profile.active) {
        await _remote.signOut();
        return const Left(AuthFailureType.accountInactive);
      }
      return Right(profile);
    } on TimeoutException {
      return const Left(AuthFailureType.network);
    } on FirebaseAuthException catch (error) {
      _log('auth failed: ${error.code}');
      return Left(AuthFailureType.fromCode(error.code));
    } catch (error) {
      _log('unexpected: $error');
      return const Left(AuthFailureType.unknown);
    }
  }

  @override
  Future<Either<AuthFailureType, AppUser>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (AppFirebase.notConfigured) {
      return const Left(AuthFailureType.notConfigured);
    }

    try {
      final AppUser user = await _remote
          .register(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password,
          )
          .timeout(_timeout);
      return Right(user);
    } on TimeoutException {
      return const Left(AuthFailureType.network);
    } on FirebaseAuthException catch (error) {
      _log('register failed: ${error.code}');
      return Left(AuthFailureType.fromCode(error.code));
    } on FirebaseException catch (error) {
      // The Auth account exists but the profile write was refused. Leave the
      // account signed in: the next sign-in repairs the profile through
      // `fetchOrCreate`, so the user is not locked out of an email they have
      // already spent.
      _log('register profile write failed: ${error.code}');
      return Left(error.code == 'permission-denied'
          ? AuthFailureType.rulesDenied
          : AuthFailureType.firestoreUnavailable);
    } catch (error) {
      _log('unexpected: $error');
      return const Left(AuthFailureType.unknown);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (AppFirebase.notConfigured) return null;
    // DESKTOP PERSISTENCE. On Windows / Linux / macOS, Firebase restores the
    // saved login ASYNCHRONOUSLY after start, so `currentUser` is null for a
    // moment right after launch. Reading it immediately made the desktop app
    // ask for a login every single time (and the first queries failed with
    // permission-denied). So if there is no user yet, wait briefly for the
    // saved session to load before giving up. On phones `currentUser` is
    // ready at once, so this returns immediately.
    User? current = _remote.currentUser;
    if (current == null) {
      try {
        current = await AppFirebase.auth
            .authStateChanges()
            .firstWhere((User? u) => u != null)
            .timeout(const Duration(seconds: 3));
      } on TimeoutException {
        current = _remote.currentUser; // genuinely signed out
      } catch (_) {
        current = _remote.currentUser;
      }
    }
    if (current == null) return null;
    try {
      final AppUser profile =
          await _remote.fetchOrCreate(current).timeout(_timeout);
      if (!profile.active) return null;
      return profile;
    } catch (error) {
      _log('restoreSession failed: $error');
      return null;
    }
  }

  @override
  Future<Either<AuthFailureType, Unit>> sendPasswordReset(String email) async {
    if (AppFirebase.notConfigured) {
      return const Left(AuthFailureType.notConfigured);
    }
    try {
      await _remote.sendPasswordReset(email);
      return const Right(unit);
    } on FirebaseAuthException catch (error) {
      return Left(AuthFailureType.fromCode(error.code));
    } catch (_) {
      return const Left(AuthFailureType.unknown);
    }
  }

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<Either<AuthFailureType, Unit>> deleteAccount(String password) async {
    if (AppFirebase.notConfigured) {
      return const Left(AuthFailureType.notConfigured);
    }
    try {
      await _remote.deleteAccount(password).timeout(_timeout);
      return const Right(unit);
    } on TimeoutException {
      return const Left(AuthFailureType.network);
    } on FirebaseAuthException catch (error) {
      _log('delete account failed: ${error.code}');
      return Left(AuthFailureType.fromCode(error.code));
    } on FirebaseException catch (error) {
      _log('delete account data failed: ${error.code}');
      return Left(error.code == 'permission-denied'
          ? AuthFailureType.rulesDenied
          : AuthFailureType.firestoreUnavailable);
    } catch (error) {
      _log('unexpected: $error');
      return const Left(AuthFailureType.unknown);
    }
  }
}

class UsersRepository implements UsersBaseRepository {
  UsersRepository({UsersRemoteDataSource? remote})
      : _remote = remote ?? UsersRemoteDataSource();

  final UsersRemoteDataSource _remote;

  @override
  Stream<List<AppUser>> watchMembers() => _remote.watchMembers();

  @override
  Stream<AppUser?> watchUser(String uid) => _remote.watch(uid);

  @override
  Future<Either<AppFailure, Unit>> updateSelf(AppUser user) =>
      guardUnit(() => _remote.updateSelf(user));

  @override
  Future<Either<AppFailure, Unit>> setActive(String uid, bool active) =>
      guardUnit(() => _remote.setActive(uid, active));

  @override
  Future<Either<AppFailure, Unit>> setCanCreateCv(String uid, bool allowed) =>
      guardUnit(() => _remote.setCanCreateCv(uid, allowed));

  @override
  Future<Either<AppFailure, Unit>> setCanUseCalcs(String uid, bool allowed) =>
      guardUnit(() => _remote.setCanUseCalcs(uid, allowed));

  @override
  Future<Either<AppFailure, Unit>> setAccess(String uid, Map<String, dynamic> access) =>
      guardUnit(() => _remote.setAccess(uid, access));

  @override
  Future<Either<AppFailure, Unit>> pauseAccess(String uid) =>
      guardUnit(() => _remote.pauseAccess(uid));

  @override
  Future<Either<AppFailure, Unit>> resumeAccess(AppUser member) =>
      guardUnit(() => _remote.resumeAccess(member));

  @override
  Future<Either<AppFailure, Unit>> clearDevice(String uid) =>
      guardUnit(() => _remote.clearDevice(uid));
}
