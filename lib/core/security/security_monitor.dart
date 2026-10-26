/// Module: core/security
///
///*************************** FILE INFO ****************************///
/// File Name: security_monitor.dart
/// Purpose: Declares `SecurityMonitor` — one place every content-protection
///          event is reported to the super admin: a lesson stream grabbed by
///          a download tool, the app's HTTPS to Drive intercepted, too many
///          downloads at once, or a probe of the local gateway. Each is saved
///          to `security_events` (type 'attack'), which the super admin reads
///          in Settings → Security alerts.
/// Author: ASEC team
/// Created: 26/10/2026
///
/// NEVER DISTURBS THE USER. [alert] returns at once and never throws. The
/// same kind of event is saved at most once every few minutes per device, so
/// a repeated attempt cannot flood Firestore. A member who is only
/// mis-detected sees nothing; the app keeps working.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/settings/capture_context.dart';
import 'package:asec/features/onboarding/o2_authentication/data/device/device_identity.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

abstract final class SecurityMonitor {
  const SecurityMonitor._();

  static CollectionReference<Map<String, dynamic>> get _col =>
      AppFirebase.db.collection('security_events');

  static const Duration _repeatAfter = Duration(minutes: 5);
  static final Map<String, DateTime> _lastSent = <String, DateTime>{};

  /// Reports a content-protection event [kind] (a short code) with a
  /// human-readable [detail]. Saved for the super admin.
  static void alert(String kind, String detail) {
    unawaited(_save(kind, detail).catchError((Object _) {}));
  }

  /// The app's connection to Drive was answered by a certificate Google did
  /// not issue — an HTTPS proxy / sniffer is in the way.
  static void intercepted(String host, String issuer) {
    alert('mitm', 'The connection to $host was intercepted (certificate issuer: $issuer). '
        'An HTTPS sniffing tool is likely running.');
  }

  static Future<void> _save(String kind, String detail) async {
    if (AppFirebase.notConfigured) return;
    final DateTime now = DateTime.now();
    final DateTime? last = _lastSent[kind];
    if (last != null && now.difference(last) < _repeatAfter) return;
    _lastSent[kind] = now;

    final AppUser me = SessionController.to.current;
    if (me.isEmpty) return;

    final CaptureWhere where = CaptureContext.now;
    await _col.add(<String, dynamic>{
      'type': 'attack',
      'kind': kind,
      'detail': detail,
      'uid': me.uid,
      'member_name': me.displayName,
      'email': me.email,
      'role': me.isSuperAdmin ? 'super admin' : (me.isAdmin ? 'admin' : 'member'),
      'platform': MemberAccess.currentPlatform,
      'device_name': DeviceIdentity.name,
      'device_id': DeviceIdentity.id,
      'page': where.page,
      'course': where.course,
      'at': FieldValue.serverTimestamp(),
    });
  }

  // ── Reading (super admin) ─────────────────────────────────────────────────

  static Stream<List<SecurityAlert>> watch({int limit = 200}) => _col
      .where('type', isEqualTo: 'attack')
      .orderBy('at', descending: true)
      .limit(limit)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> q) => <SecurityAlert>[
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs)
              SecurityAlert._fromDoc(d),
          ]);

  static Future<void> delete(String id) => _col.doc(id).delete();

  static Future<void> clearAll() async {
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> q =
          await _col.where('type', isEqualTo: 'attack').limit(400).get();
      if (q.docs.isEmpty) return;
      final WriteBatch b = AppFirebase.db.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs) {
        b.delete(d.reference);
      }
      await b.commit();
    }
  }
}

class SecurityAlert {
  const SecurityAlert({
    required this.id,
    required this.kind,
    required this.detail,
    required this.userName,
    required this.email,
    required this.role,
    required this.platform,
    required this.deviceName,
    required this.page,
    required this.course,
    this.at,
  });

  final String id;
  final String kind;
  final String detail;
  final String userName;
  final String email;
  final String role;
  final String platform;
  final String deviceName;
  final String page;
  final String course;
  final DateTime? at;

  factory SecurityAlert._fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data();
    String t(String k) => '${m[k] ?? ''}';
    return SecurityAlert(
      id: d.id,
      kind: t('kind'),
      detail: t('detail'),
      userName: t('member_name'),
      email: t('email'),
      role: t('role'),
      platform: t('platform'),
      deviceName: t('device_name'),
      page: t('page'),
      course: t('course'),
      at: (m['at'] as Timestamp?)?.toDate(),
    );
  }
}
