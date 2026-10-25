/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: member_access.dart
/// Purpose: Declares `MemberAccess` — whether a MEMBER may use the app right
///          now, on this device: the admin's per-member settings (devices,
///          access period, pause) checked against the clock and the
///          platform the app is running on. Which COURSES they see is
///          `AppUser.canSeeCourse`.
/// Author: ASEC team
/// Created: 1/10/2026
/// Updated: 23/10/2026 - Signing in is no longer limited by platform or
///          device: a member may use the app on any number of devices and
///          platforms. The platforms now limit only the courses (videos,
///          video quizzes, certificates) — see `AppUser.canSeeCourse`.

import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/course_access.dart';

/// Why a member is kept out. [none] = they may use the app.
/// [deviceBlocked] is not decided here — AccessGate reads `blocked_devices`.
enum AccessBlock { none, paused, notStarted, expired, platform, otherDevice, deviceRemoved, deviceBlocked }

abstract final class MemberAccess {
  /// The courses (Drive category folders) every member may watch until an
  /// admin sets their access. Any other course stays locked until the admin
  /// ticks it on Members → Edit access. Names must match the Drive folder
  /// names exactly. firestore.rules `hasCourse` holds the same list.
  ///
  /// The Drive folders are "General Notes" and "Tips and Tricks"; the older
  /// spellings stay in the list so a course imported under them still opens.
  static const List<String> defaultCourses = <String>[
    'General Notes',
    'Tips and Tricks',
    'GENERAL NOTES',
    'Reals',
  ];

  /// Every platform key the admin can choose from, in display order.
  static const List<String> allPlatforms = <String>[
    'android',
    'ios',
    'macos',
    'windows',
  ];

  static String platformLabel(String key) {
    switch (key) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iPhone / iPad';
      case 'macos':
        return 'Mac';
      case 'windows':
        return 'Windows';
      case 'web':
        return 'Web';
      default:
        return key;
    }
  }

  /// What a member the admin has not set platforms for may use: Android and
  /// iPhone / iPad only.
  static const List<String> defaultPlatforms = CourseAccess.defaultPlatforms;

  /// The platform this copy of the app is running on.
  static String get currentPlatform => CourseAccess.currentPlatform;

  /// Admins are never blocked; members are checked in this order: paused,
  /// not started, ended.
  ///
  /// NO PLATFORM / DEVICE LIMIT (23/10/2026): any platform, any number of
  /// devices. [thisDevice] / [boundHereUid] are kept for callers but no
  /// longer used. A device the admin blocked is still shut out
  /// (AccessGate, `blocked_devices`).
  static AccessBlock check(
    AppUser user, {
    DateTime? now,
    String? thisDevice,
    String? boundHereUid,
  }) {
    if (user.isEmpty || user.isAdmin) return AccessBlock.none;
    final DateTime t = now ?? DateTime.now();
    if (user.isPaused) return AccessBlock.paused;
    if (user.accessFrom != null && t.isBefore(user.accessFrom!)) {
      return AccessBlock.notStarted;
    }
    if (user.accessUntil != null && t.isAfter(user.accessUntil!)) {
      return AccessBlock.expired;
    }
    return AccessBlock.none;
  }
}
