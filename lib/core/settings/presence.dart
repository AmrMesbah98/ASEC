/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: presence.dart
/// Purpose: Declares `Presence` (who has the app open right now) and
///          `PresenceEntry` (one row of it).
///
///          While a signed-in user has the app OPEN (on screen), it writes
///          `presence/{uid}` once a minute: name, email, role, platform,
///          device, app version, the tab on screen, `online: true` and the
///          server time. Sent to the background, minimised or closed, it
///          writes `online: false` once. Admins with the Members permission
///          read the list (Settings → Online now).
///
///          ONLINE = `online` is true AND the last beat is under 3 minutes
///          old — so an app that was killed without saying goodbye drops off
///          the list by itself.
///
///          It lives in its own collection, not on `users/{uid}`: a beat on
///          the profile would wake every listener of that profile (the
///          member's own app, the admin's Members page) once a minute.
///
///          RULES: firestore.rules → `match /presence/{uid}`. Deploy them:
///          firebase deploy --only firestore:rules
/// Author: ASEC team
/// Created: 27/10/2026
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/settings/capture_context.dart';
import 'package:asec/features/onboarding/o2_authentication/data/device/device_identity.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';

abstract final class Presence {
  const Presence._();

  static const String collection = 'presence';

  /// How often an open app says "still here".
  static const Duration beat = Duration(seconds: 60);

  /// A beat older than this = no longer online.
  static const Duration onlineWindow = Duration(minutes: 3);

  static AppUser? _user;
  static Timer? _timer;
  static _LifecycleWatcher? _watcher;
  static bool _foreground = true;
  static String _version = '';

  /// After sign-in (SessionController.start). Safe to call again.
  static void start(AppUser user) {
    if (user.uid.isEmpty) return;
    _user = user;
    if (_watcher == null) {
      _watcher = _LifecycleWatcher();
      WidgetsBinding.instance.addObserver(_watcher!);
    }
    _foreground = true;
    _send(online: true);
    _timer?.cancel();
    _timer = Timer.periodic(beat, (_) {
      if (_foreground) _send(online: true);
    });
  }

  /// Keeps the name / email current when the live profile changes.
  static void update(AppUser user) {
    if (_user != null && user.uid == _user!.uid) _user = user;
  }

  /// Before sign-out / account delete: says goodbye and stops.
  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    final _LifecycleWatcher? w = _watcher;
    if (w != null) {
      WidgetsBinding.instance.removeObserver(w);
      _watcher = null;
    }
    if (_user != null) {
      await _send(online: false).timeout(const Duration(seconds: 4),
          onTimeout: () {});
    }
    _user = null;
  }

  static void _lifecycle(AppLifecycleState state) {
    if (_user == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _send(online: true);
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_foreground) {
          _foreground = false;
          _send(online: false);
        }
      case AppLifecycleState.inactive:
        // A desktop window that lost focus is still open.
        break;
    }
  }

  static Future<void> _send({required bool online}) async {
    final AppUser? u = _user;
    if (u == null) return;
    try {
      if (_version.isEmpty) {
        try {
          final PackageInfo p = await PackageInfo.fromPlatform();
          _version = '${p.version}+${p.buildNumber}';
        } catch (_) {
          _version = '?';
        }
      }
      await AppFirebase.db.collection(collection).doc(u.uid).set(<String, dynamic>{
        'uid': u.uid,
        'name': u.displayName,
        'email': u.email,
        'role': u.role.key,
        'online': online,
        'platform': MemberAccess.currentPlatform,
        'device_name': DeviceIdentity.name,
        'app_version': _version,
        'page': CaptureContext.tabLabel,
        'last_seen': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Presence is best-effort: never disturb the app over it.
    }
  }

  /// Everybody seen in the last [within], newest first. Admins only.
  static Stream<List<PresenceEntry>> watchRecent({
    Duration within = const Duration(hours: 24),
  }) {
    final Timestamp since = Timestamp.fromDate(DateTime.now().subtract(within));
    return AppFirebase.db
        .collection(collection)
        .where('last_seen', isGreaterThan: since)
        .orderBy('last_seen', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> q) => q.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                PresenceEntry.fromMap(d.id, d.data()))
            .toList());
  }
}

class _LifecycleWatcher with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      Presence._lifecycle(state);
}

/// One user in `presence`.
class PresenceEntry {
  const PresenceEntry({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.online,
    required this.platform,
    required this.deviceName,
    required this.appVersion,
    required this.page,
    required this.lastSeen,
  });

  factory PresenceEntry.fromMap(String id, Map<String, dynamic> d) {
    final Object? seen = d['last_seen'];
    return PresenceEntry(
      uid: id,
      name: '${d['name'] ?? ''}',
      email: '${d['email'] ?? ''}',
      role: '${d['role'] ?? ''}',
      online: d['online'] == true,
      platform: '${d['platform'] ?? ''}',
      deviceName: '${d['device_name'] ?? ''}',
      appVersion: '${d['app_version'] ?? ''}',
      page: '${d['page'] ?? ''}',
      // A beat just written shows null until the server stamps it.
      lastSeen: seen is Timestamp ? seen.toDate() : DateTime.now(),
    );
  }

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool online;
  final String platform;
  final String deviceName;
  final String appVersion;
  final String page;
  final DateTime lastSeen;

  bool get isAdmin => role == 'admin';

  /// Has the app open right now.
  bool get isOnline =>
      online && DateTime.now().difference(lastSeen) < Presence.onlineWindow;

  String get displayName => name.trim().isNotEmpty ? name : email;
}
