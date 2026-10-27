/// Module: core/network
///
///*************************** FILE INFO ****************************///
/// File Name: login_diagnostics.dart
/// Purpose: Declares `LoginDiagnostics` — a TEMPORARY tool to find out why
///          the Windows app gets 'permission-denied' on sign-in. It keeps a
///          timeline of every startup / sign-in step and, when the sign-in
///          is refused, checks (BEFORE signing out) what Firebase really
///          sees: is Auth signed in, does the token carry the email, and
///          does Firestore receive the login at all. The sign-in page prints
///          the whole report so it can be copied.
///
///          Remove it (and the panel on the sign-in page) once the cause is
///          fixed.
/// Author: ASEC team
/// Created: 27/10/2026
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';

abstract final class LoginDiagnostics {
  const LoginDiagnostics._();

  static final DateTime _start = DateTime.now();
  static final List<String> _steps = <String>[];

  /// The last report built by [capture]; empty when there is none.
  static String lastReport = '';

  /// Adds one line to the timeline (time since the app started).
  static void log(String step) {
    final double s = DateTime.now().difference(_start).inMilliseconds / 1000;
    _steps.add('+${s.toStringAsFixed(2)}s  $step');
    if (_steps.length > 100) _steps.removeAt(0);
    debugPrint('🟡 [LoginDiag] $step');
  }

  static void clear() => lastReport = '';

  /// Builds the full report. Call it WHILE the user is still signed in.
  static Future<String> capture() async {
    final StringBuffer b = StringBuffer();
    void row(String key, Object? value) => b.writeln('$key: $value');

    b.writeln('===== ASEC LOGIN DIAGNOSTIC =====');
    row('time', DateTime.now().toIso8601String());
    row(
      'platform',
      kIsWeb
          ? 'web'
          : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );
    try {
      final PackageInfo p = await PackageInfo.fromPlatform();
      row('app version', '${p.version}+${p.buildNumber}');
    } catch (e) {
      row('app version', 'unknown ($e)');
    }

    // ── Firebase ──
    b.writeln('');
    b.writeln('--- firebase ---');
    try {
      final FirebaseOptions o = Firebase.app().options;
      row('project', o.projectId);
      row('appId', o.appId);
      row('apps', Firebase.apps.map((FirebaseApp a) => a.name).join(', '));
    } catch (e) {
      row('firebase', 'NOT STARTED ($e)');
    }
    row('AppFirebase ready', AppFirebase.isReady);
    row('startup error',
        AppFirebase.startupError.isEmpty ? '-' : AppFirebase.startupError);

    // ── Auth ──
    b.writeln('');
    b.writeln('--- auth ---');
    final User? user = AppFirebase.auth.currentUser;
    row('currentUser',
        user == null ? 'NULL (not signed in)' : '${user.uid} / ${user.email}');
    String? tokenEmail;
    if (user != null) {
      row('emailVerified', user.emailVerified);
      try {
        final IdTokenResult t = await user
            .getIdTokenResult(true)
            .timeout(const Duration(seconds: 10));
        tokenEmail = t.claims?['email']?.toString();
        row('id token', 'OK (expires ${t.expirationTime?.toIso8601String()})');
        row('token email claim', tokenEmail ?? 'MISSING');
        row('sign-in provider', t.signInProvider);
      } catch (e) {
        row('id token', 'FAILED ($e)');
      }
    }

    // ── Firestore (straight from the server, never the cache) ──
    b.writeln('');
    b.writeln('--- firestore ---');
    String probeA = 'not run';
    String probeB = 'not run';
    if (user != null) {
      // Rule: `allow get: if signedIn()` — refused ONLY if Firestore does
      // not receive the login at all.
      probeA = await _probe(AppFirebase.db
          .collection('blocked_devices')
          .doc('diag-probe-${user.uid}'));
      row('A) blocked_devices/x  (any signed-in user may read)', probeA);
      // The account's own profile — what the sign-in itself reads.
      probeB = await _probe(
        AppFirebase.db.collection(FirebaseCollections.users).doc(user.uid),
        showProfile: true,
      );
      row('B) users/{uid}  (own profile)', probeB);
    }

    b.writeln('');
    b.writeln('VERDICT: ${_verdict(user, tokenEmail, probeA, probeB)}');

    b.writeln('');
    b.writeln('--- timeline ---');
    for (final String s in _steps) {
      b.writeln(s);
    }

    lastReport = b.toString();
    debugPrint('🔴 [LoginDiag]\n$lastReport');
    return lastReport;
  }

  static Future<String> _probe(
    DocumentReference<Map<String, dynamic>> ref, {
    bool showProfile = false,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      if (!snap.exists) return 'ALLOWED (document does not exist)';
      if (!showProfile) return 'ALLOWED';
      final Map<String, dynamic> d = snap.data() ?? <String, dynamic>{};
      return 'ALLOWED  role=${d['role']}  active=${d['active']}  '
          'app_build=${d['app_build']}  paused_at=${d['paused_at']}  '
          'access_until=${d['access_until']}';
    } on FirebaseException catch (e) {
      return 'REFUSED ${e.code}: ${e.message}';
    } catch (e) {
      return 'ERROR $e';
    }
  }

  static String _verdict(
      User? user, String? tokenEmail, String probeA, String probeB) {
    if (user == null) {
      return 'Firebase Auth has NO signed-in user, so the sign-in did not '
          'stick on this device.';
    }
    if (probeA.contains('permission-denied')) {
      return 'Auth IS signed in, but Firestore is NOT receiving the login '
          '(request.auth == null). Every request goes out anonymously. This '
          'is the Windows Auth -> Firestore link problem, not the rules.';
    }
    if (tokenEmail == null) {
      return 'Firestore receives the login, but the token has NO email '
          'claim, so isSuper() and the email rules can never match.';
    }
    if (probeB.contains('permission-denied')) {
      return 'Firestore receives the login, but the rules refuse this '
          "account's own profile. Check the users/{uid} document (active, "
          'paused_at, access dates, app_build) and that the DEPLOYED rules '
          'are the same as firestore.rules.';
    }
    if (probeA.startsWith('ALLOWED') && probeB.startsWith('ALLOWED')) {
      return 'Firestore works NOW. The refusal was a timing problem right '
          'after sign-in (the token reached Firestore too late).';
    }
    return 'Unclear (network / unavailable?). Send this whole report.';
  }
}
