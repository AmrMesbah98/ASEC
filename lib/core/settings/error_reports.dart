/// Module: core/settings
///
///*************************** FILE INFO ****************************///
/// File Name: error_reports.dart
/// Purpose: Declares `ErrorReports` — every error any user hits (a red
///          "Something went wrong" screen, a crash in a widget, an uncaught
///          async error) saved to `error_reports` with full details, so the
///          SUPER ADMIN sees it in Settings → Error reports.
/// Author: ASEC team
/// Created: 26/10/2026
///
/// WHAT IS SAVED. Who (uid, name, email, role), where (platform, device,
/// app version, page / course / lesson from CaptureContext), what (the
/// error's type, Firebase code, message and stack trace) and when.
///
/// NEVER DISTURBS THE USER. [report] never throws and never awaits on the
/// caller's side. The same error is saved once per 5 minutes per device, and
/// at most [_maxPerRun] times per app run, so a screen that rebuilds in a
/// loop cannot flood Firestore.
///
/// Firestore rules: `error_reports` — anyone signed in may ADD one about
/// themself; only the super admin reads and deletes them.

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/settings/capture_context.dart';
import 'package:asec/features/onboarding/o2_authentication/data/device/device_identity.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

/// One saved error.
class ErrorReport {
  const ErrorReport({
    required this.id,
    required this.uid,
    required this.userName,
    required this.email,
    required this.role,
    required this.platform,
    required this.deviceName,
    required this.deviceId,
    required this.appVersion,
    required this.source,
    required this.page,
    required this.course,
    required this.detail,
    required this.errorType,
    required this.code,
    required this.message,
    required this.stack,
    this.at,
  });

  final String id;
  final String uid;
  final String userName;
  final String email;
  final String role;
  final String platform;
  final String deviceName;
  final String deviceId;
  final String appVersion;

  /// What caught it: 'screen' (an error view), 'flutter' (a widget / build
  /// error), 'async' (an uncaught error) or a name given by the caller.
  final String source;
  final String page;
  final String course;
  final String detail;
  final String errorType;

  /// Firebase's code ('permission-denied', 'unavailable', …), '' otherwise.
  final String code;
  final String message;
  final String stack;
  final DateTime? at;

  /// Everything, as plain text — what "Copy" puts on the clipboard.
  String get fullText => <String>[
        'When: ${at?.toLocal() ?? '-'}',
        'User: $userName <$email> ($role) uid=$uid',
        'Platform: $platform · Device: $deviceName ($deviceId) · App: $appVersion',
        if (page.isNotEmpty || course.isNotEmpty || detail.isNotEmpty)
          'Where: ${<String>[page, course, detail].where((String x) => x.isNotEmpty).join(' › ')}',
        'Source: $source',
        'Error: $errorType${code.isEmpty ? '' : ' [$code]'}',
        'Message: $message',
        if (stack.isNotEmpty) 'Stack:\n$stack',
      ].join('\n');
}

abstract final class ErrorReports {
  const ErrorReports._();

  static const String collection = 'error_reports';

  static CollectionReference<Map<String, dynamic>> get _col =>
      AppFirebase.db.collection(collection);

  static const int _maxPerRun = 50;
  static const Duration _repeatAfter = Duration(minutes: 5);
  static const int _maxMessage = 2000;
  static const int _maxStack = 6000;

  static int _sent = 0;
  static final Map<String, DateTime> _lastSent = <String, DateTime>{};
  static String? _version;

  // ── Catching ──────────────────────────────────────────────────────────────

  /// Hooks Flutter's and Dart's global error handlers. Call once in main(),
  /// after Firebase starts. The old handlers still run (the console keeps
  /// its red output in debug).
  static void installGlobalHandlers() {
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previous?.call(details);
      report(
        details.exception,
        details.stack,
        source: 'flutter',
        context: details.context?.toDescription() ?? '',
      );
    };

    final bool Function(Object, StackTrace)? previousAsync =
        PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      report(error, stack, source: 'async');
      // Handled: keep the app running, as it did before.
      return previousAsync?.call(error, stack) ?? true;
    };
  }

  // ── Saving ────────────────────────────────────────────────────────────────

  /// Saves [error] for the super admin. Never throws; returns at once.
  static void report(
    Object? error,
    StackTrace? stack, {
    String source = 'screen',
    String context = '',
  }) {
    if (error == null) return;
    // Always in the debug console too.
    debugPrint('⚠️ [$source] ${error.runtimeType}: $error');

    unawaited(_save(error, stack, source, context).catchError((Object _) {}));
  }

  static Future<void> _save(
    Object error,
    StackTrace? stack,
    String source,
    String context,
  ) async {
    if (AppFirebase.notConfigured) return;
    if (_sent >= _maxPerRun) return;

    String code = '';
    String message = '$error';
    if (error is FirebaseException) {
      code = error.code;
      message = '${error.plugin}/${error.code}: ${error.message ?? ''}';
    }
    if (context.isNotEmpty) message = '$context\n$message';
    if (message.length > _maxMessage) message = message.substring(0, _maxMessage);

    // The same error from the same place: once per few minutes.
    final String key = '$source|${error.runtimeType}|$code|'
        '${message.length > 300 ? message.substring(0, 300) : message}';
    final DateTime now = DateTime.now();
    final DateTime? last = _lastSent[key];
    if (last != null && now.difference(last) < _repeatAfter) return;
    _lastSent[key] = now;

    final AppUser me = SessionController.to.current;
    // The rules only take a report from someone signed in.
    if (me.isEmpty) return;

    String trace = (stack ?? StackTrace.empty).toString();
    if (trace.length > _maxStack) trace = trace.substring(0, _maxStack);

    final CaptureWhere where = CaptureContext.now;
    _sent++;
    await _col.add(<String, dynamic>{
      'uid': me.uid,
      'user_name': me.displayName,
      'email': me.email,
      'role': me.isSuperAdmin ? 'super admin' : (me.isAdmin ? 'admin' : 'member'),
      'platform': MemberAccess.currentPlatform,
      'device_name': DeviceIdentity.name,
      'device_id': DeviceIdentity.id,
      'app_version': await _appVersion(),
      'source': source,
      'page': where.page,
      'course': where.course,
      'detail': where.detail,
      'error_type': '${error.runtimeType}',
      'code': code,
      'message': message,
      'stack': trace,
      'at': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> _appVersion() async {
    if (_version != null) return _version!;
    try {
      final PackageInfo p = await PackageInfo.fromPlatform();
      _version = '${p.version}+${p.buildNumber}';
    } catch (_) {
      _version = '';
    }
    return _version!;
  }

  /// Reports a crash the LAST run left behind (CrashTracker): the app died
  /// at [stage] (a startup step) on version [version]. Saved as source
  /// 'crash', with a clear message so the super admin sees where it died.
  static void reportStartupCrash(String stage, String version, DateTime? when) {
    final String ago = when == null ? '' : ' at ${when.toLocal()}';
    report(
      'The app closed unexpectedly before it finished opening$ago '
      '(last step reached: "$stage"${version.isEmpty ? '' : ', build $version'}). '
      'This is usually a crash to the desktop, a force-close, or the device '
      'running out of memory.',
      StackTrace.empty,
      source: 'crash',
    );
  }

  // ── Reading (super admin) ─────────────────────────────────────────────────

  static Stream<List<ErrorReport>> watch({int limit = 200}) => _col
      .orderBy('at', descending: true)
      .limit(limit)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> q) => <ErrorReport>[
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs)
              _fromDoc(d),
          ]);

  static ErrorReport _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data();
    String t(String k) => '${m[k] ?? ''}';
    return ErrorReport(
      id: d.id,
      uid: t('uid'),
      userName: t('user_name'),
      email: t('email'),
      role: t('role'),
      platform: t('platform'),
      deviceName: t('device_name'),
      deviceId: t('device_id'),
      appVersion: t('app_version'),
      source: t('source'),
      page: t('page'),
      course: t('course'),
      detail: t('detail'),
      errorType: t('error_type'),
      code: t('code'),
      message: t('message'),
      stack: t('stack'),
      at: (m['at'] as Timestamp?)?.toDate(),
    );
  }

  static Future<void> delete(String id) => _col.doc(id).delete();

  /// Deletes every report (in batches of 400).
  static Future<void> clearAll() async {
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> q = await _col.limit(400).get();
      if (q.docs.isEmpty) return;
      final WriteBatch b = AppFirebase.db.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs) {
        b.delete(d.reference);
      }
      await b.commit();
    }
  }
}
