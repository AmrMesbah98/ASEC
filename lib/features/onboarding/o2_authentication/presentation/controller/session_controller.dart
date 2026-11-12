/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: session_controller.dart
/// Purpose: Declares `SessionController` — who is signed in, kept live.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Unit;
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:get/get.dart';

import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/core/settings/crash_tracker.dart';
import 'package:asec/core/settings/windows_boot_guard.dart';
import 'package:asec/core/settings/error_reports.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/auth_failure_type.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/settings/presence.dart';

/// The signed-in account, app-wide.
///
/// Registered permanently in `main.dart`, next to the theme controller — both
/// shells need the current user, and threading it through every constructor
/// is how a codebase ends up re-reading the same profile in four cubits.
///
/// LIVE: after sign-in it subscribes to the user's own document, so an admin
/// switching an account off takes effect without a sign-out — [onDeactivated]
/// fires and the shell returns to the sign-in screen.
class SessionController extends GetxController {
  SessionController({
    AuthBaseRepository? auth,
    UsersBaseRepository? users,
  })  : _auth = auth ?? AuthRepository(),
        _users = users ?? UsersRepository();

  static SessionController get to => Get.find<SessionController>();

  final AuthBaseRepository _auth;
  final UsersBaseRepository _users;

  final Rxn<AppUser> user = Rxn<AppUser>();

  /// Called when the live profile says the account was switched off or
  /// deleted. Set by whichever shell is showing.
  void Function()? onDeactivated;

  StreamSubscription<AppUser?>? _sub;

  AppUser get current => user.value ?? AppUser.empty;
  String get uid => current.uid;
  bool get isAdmin => current.isAdmin;

  /// Starts following [signedIn]'s profile document.
  void start(AppUser signedIn) {
    user.value = signedIn;
    AppFeatures.to.listen();
    // "Online now" for the admins (Settings).
    Presence.start(signedIn);
    // Removed access erases the saved lessons (12/11/2026).
    VideoDownloads.watchAccess(signedIn.uid);
    // If the LAST run crashed (e.g. vanished to the desktop on startup), it is
    // reported now — a report needs a signed-in user, and we have one.
    if (CrashTracker.hasPendingCrash) {
      ErrorReports.reportStartupCrash(
        CrashTracker.pendingCrashStage!,
        CrashTracker.pendingCrashVersion,
        CrashTracker.pendingCrashTime,
      );
      CrashTracker.clearPending();
    }
    // Windows (06/11/2026, from ENGX): the step a failed start died in, the
    // DLL that crashed (native crash recorder) and anything repaired — once.
    final String boot = WindowsBootGuard.takeReport();
    if (boot.isNotEmpty) ErrorReports.report(boot, StackTrace.empty, source: 'crash');
    // Windows: what Windows itself recorded about a crash since the last run
    // (the module and exception code) — once per crash.
    unawaited(CrashTracker.windowsCrashReason().then((String why) {
      if (why.isEmpty) return;
      ErrorReports.report(
        'The app crashed on this PC since it was last opened.\n\nWINDOWS SAYS:\n$why',
        StackTrace.empty,
        source: 'crash',
      );
    }));
    _sub?.cancel();
    _sub = _users.watchUser(signedIn.uid).listen(
      (AppUser? live) {
        if (live == null || !live.active) {
          // Switched off / deleted: the saved lessons go too (12/11/2026).
          unawaited(VideoDownloads.removeWhere((_) => true));
          onDeactivated?.call();
          return;
        }
        user.value = live;
        Presence.update(live);
      },
      // A transient read error must not sign anybody out.
      onError: (Object _) {},
    );
  }

  Future<void> signOut() async {
    VideoDownloads.stopAccess();
    // Off the "Online now" list while still allowed to write it.
    await Presence.stop();
    await _sub?.cancel();
    _sub = null;
    // `user` keeps its last value on purpose: clearing it would rebuild every
    // page still on screen during the sign-out transition with an empty user,
    // and each would open queries it is no longer allowed to run.
    onDeactivated = null;
    await _auth.signOut();
  }

  /// Deletes the signed-in account for good.
  ///
  /// The live profile subscription is stopped FIRST: deleting `users/{uid}`
  /// would otherwise fire [onDeactivated] mid-way and race the caller's own
  /// navigation. If the delete fails, the subscription is started again so
  /// the session carries on exactly as before.
  Future<Either<AuthFailureType, Unit>> deleteAccount(String password) async {
    final AppUser before = current;
    final void Function()? deactivated = onDeactivated;
    await Presence.stop();
    await _sub?.cancel();
    _sub = null;
    onDeactivated = null;

    final Either<AuthFailureType, Unit> result =
        await _auth.deleteAccount(password);

    if (result.isLeft() && before.uid.isNotEmpty) {
      onDeactivated = deactivated;
      start(before);
    }
    return result;
  }

  @override
  void onClose() {
    Presence.stop();
    _sub?.cancel();
    super.onClose();
  }
}
