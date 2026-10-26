/// Module: core/network
///
///*************************** FILE INFO ****************************///
/// File Name: app_failure.dart
/// Purpose: Declares `AppFailure` — the Left side of every repository call
///          outside authentication.
/// Author: Manger Plus team
/// Created: 18/9/2026
///
/// wash_application returned `Either<String, T>` with English sentences built
/// in the repository, which is why its error banners stayed English in an
/// Arabic build. Here the repository returns a KIND of failure and the screen
/// turns it into words with its own context.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/settings/error_reports.dart';
import 'package:asec/generated/l10n.dart';

enum AppFailure {
  /// Rules said no — wrong role, a switched-off permission, or rules not
  /// deployed.
  permissionDenied,

  /// Offline or timed out.
  network,

  /// A query needs a composite index that has not been deployed yet.
  needsIndex,

  notFound,

  /// The email is already registered in Firebase Auth.
  emailInUse,

  weakPassword,

  /// The upload was cancelled or failed half-way.
  uploadFailed,

  /// There is no Cloud Storage bucket to write to.
  storageUnavailable,

  notConfigured,
  unknown;

  /// Maps any error thrown by a Firebase SDK onto this set. Logs the raw error
  /// in debug builds — the mapped one is for users, the raw one is for you.
  ///
  /// Every error that comes through here is also saved for the super admin
  /// (ErrorReports) — except sign-in mistakes (wrong password, email taken),
  /// which are the user's typing, not a fault.
  static AppFailure from(Object error, [StackTrace? stack]) {
    if (error is! FirebaseAuthException) {
      ErrorReports.report(error, stack ?? StackTrace.current, source: 'repository');
    }
    return _map(error);
  }

  static AppFailure _map(Object error) {
    if (AppFirebase.notConfigured) return AppFailure.notConfigured;

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return AppFailure.emailInUse;
        case 'weak-password':
          return AppFailure.weakPassword;
        case 'network-request-failed':
          return AppFailure.network;
        default:
          return AppFailure.unknown;
      }
    }
    if (error is FirebaseException) {
      if (error.plugin == 'firebase_storage') {
        switch (error.code) {
          case 'unauthorized':
            return AppFailure.permissionDenied;
          // During an UPLOAD these three mean the bucket itself is not there:
          // Cloud Storage was never enabled for the project, or the app is
          // pointed at a bucket that does not exist. Storage reports it as
          // "No object exists at the desired reference", which reads like a
          // missing file and sends you hunting in the wrong place.
          case 'object-not-found':
          case 'bucket-not-found':
          case 'project-not-found':
            return AppFailure.storageUnavailable;
          case 'retry-limit-exceeded':
            return AppFailure.network;
          default:
            return AppFailure.uploadFailed;
        }
      }
      switch (error.code) {
        case 'permission-denied':
        case 'unauthorized':
          return AppFailure.permissionDenied;
        case 'unavailable':
        case 'deadline-exceeded':
          return AppFailure.network;
        case 'failed-precondition':
          return AppFailure.needsIndex;
        case 'not-found':
        case 'object-not-found':
          return AppFailure.notFound;
        default:
          return AppFailure.unknown;
      }
    }
    return AppFailure.unknown;
  }

  String message(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case AppFailure.permissionDenied:
        return s.failPermission;
      case AppFailure.network:
        return s.errNetwork;
      case AppFailure.needsIndex:
        return s.failIndex;
      case AppFailure.notFound:
        return s.failNotFound;
      case AppFailure.emailInUse:
        return s.errEmailInUse;
      case AppFailure.weakPassword:
        return s.errWeakPassword;
      case AppFailure.uploadFailed:
        return s.failUpload;
      case AppFailure.storageUnavailable:
        return s.failStorageUnavailable;
      case AppFailure.notConfigured:
        return s.errNotConfigured;
      case AppFailure.unknown:
        return s.errUnknown;
    }
  }
}
