/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: build_gate.dart
/// Purpose: Declares `BuildGate` — some accounts may only use the app from
///          a given build on. The app writes its build number into the
///          member's profile (`users/{uid}.app_build`) every time it signs in
///          or restores a session; firestore.rules refuses those accounts
///          everything (even their own profile) until that number is high
///          enough. Older builds never write it, so on an older build those
///          accounts cannot sign in at all.
/// Author: ASEC team
/// Created: 26/10/2026
///
/// KEEP IN STEP WITH firestore.rules → `buildLocked()` / `buildOk()`:
/// the same emails and the same minimum build. The rules are what actually
/// enforce it; this file only stamps the build and explains the refusal.
///
/// To lock another account: add its email in BOTH places and deploy the
/// rules (`firebase deploy --only firestore:rules`). To raise the minimum
/// for them later: change [minBuild] and the number in the rules.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';

abstract final class BuildGate {
  const BuildGate._();

  /// The first build these accounts may use: 1.0.7+24.
  static const int minBuild = 24;

  /// Lower-case emails that need at least [minBuild].
  static const Set<String> lockedEmails = <String>{
    'mmasba1988@gmail.com',
    'bassam.edunners@gmail.com',
    'alrmadymr0@gmail.com',
    'hamada6663389@gmail.com',
    'mahmoud5.edunners@gmail.com',
    'abdallahhassan.eduneers@gmail.com',
  };

  static int? _build;

  /// This app's build number (the part after `+` in pubspec `version:`).
  static Future<int> build() async {
    if (_build != null) return _build!;
    try {
      final PackageInfo p = await PackageInfo.fromPlatform();
      _build = int.tryParse(p.buildNumber) ?? 0;
    } catch (_) {
      _build = 0;
    }
    return _build!;
  }

  static bool isLocked(String? email) =>
      lockedEmails.contains((email ?? '').trim().toLowerCase());

  /// Writes this build into [user]'s profile. Done for EVERY account, so an
  /// email added to the list later still works on this build. Never throws:
  /// no profile yet (it is created right after), offline, or refused — the
  /// sign-in carries on and the rules decide.
  static Future<void> stamp(User user) async {
    final int b = await build();
    if (b <= 0) return;
    try {
      await AppFirebase.db
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .update(<String, dynamic>{'app_build': b})
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
