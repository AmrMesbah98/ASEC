/// Module: admin / a2_members
///
///*************************** FILE INFO ****************************///
/// File Name: device_security.dart
/// Purpose: Declares `DeviceBlocks` and `CaptureEvents`.
///   * DeviceBlocks — the admin BLOCKS a member's device (Members → Edit
///     access → Block device). The device id goes into `blocked_devices`;
///     whoever signs in on that device afterwards sees "This device is
///     blocked" (AccessGate). The member's device slot is freed at the same
///     time, so they can still use the app on another device.
///   * CaptureEvents — a member took a screenshot or started a screen
///     recording inside the app (detected natively, see
///     ScreenProtection). Each one is saved to `security_events` and listed
///     for the admin in Settings → Screen capture alerts.
/// Author: ASEC team
/// Created: 20/10/2026
///
/// Firestore rules: `blocked_devices` and `security_events` in
/// firestore.rules.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/settings/capture_context.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/data/device/device_identity.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/features/video/v1_videos/data/device/video_device_lock.dart';

class BlockedDevice {
  const BlockedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.uid,
    required this.memberName,
    this.blockedAt,
  });

  final String deviceId;
  final String deviceName;
  final String uid;
  final String memberName;
  final DateTime? blockedAt;
}

abstract final class DeviceBlocks {
  static CollectionReference<Map<String, dynamic>> get _col =>
      AppFirebase.db.collection('blocked_devices');

  /// Blocks [member]'s current device and frees their device slot.
  static Future<void> block(AppUser member) async {
    if (!member.hasDevice) return;
    final WriteBatch b = AppFirebase.db.batch();
    b.set(_col.doc(member.deviceId), <String, dynamic>{
      'device_name': member.deviceName,
      'uid': member.uid,
      'member_name': member.displayName,
      'blocked_by': AppFirebase.uid ?? '',
      'blocked_at': FieldValue.serverTimestamp(),
    });
    b.update(AppFirebase.db.collection(FirebaseCollections.users).doc(member.uid), <String, dynamic>{
      UserModel.deviceId: '',
      UserModel.deviceName: '',
      UserModel.deviceBoundAt: null,
      FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
    });
    await b.commit();
  }

  /// Blocks the device holding [member]'s [platform] video slot and frees
  /// that slot, so the next device of that platform can take it.
  static Future<void> blockVideoDevice(
    AppUser member,
    String platform,
    VideoDevice device,
  ) async {
    final WriteBatch b = AppFirebase.db.batch();
    b.set(_col.doc(device.id), <String, dynamic>{
      'device_name': device.name,
      'uid': member.uid,
      'member_name': member.displayName,
      'blocked_by': AppFirebase.uid ?? '',
      'blocked_at': FieldValue.serverTimestamp(),
    });
    b.update(AppFirebase.db.collection(FirebaseCollections.users).doc(member.uid), <String, dynamic>{
      '${VideoDeviceLock.field}.$platform': FieldValue.delete(),
      FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
    });
    await b.commit();
  }

  static Future<void> unblock(String deviceId) => _col.doc(deviceId).delete();

  /// True while THIS device is blocked. The caller treats an error
  /// (offline, rules not deployed) as not blocked, so nobody is shut out by
  /// mistake.
  static Stream<bool> watchThisDevice() => _col
      .doc(DeviceIdentity.id)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> d) => d.exists);

  /// The devices blocked while they belonged to [uid].
  static Stream<List<BlockedDevice>> watchForMember(String uid) => _col
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> q) => <BlockedDevice>[
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs)
              BlockedDevice(
                deviceId: d.id,
                deviceName: '${d.data()['device_name'] ?? ''}',
                uid: '${d.data()['uid'] ?? ''}',
                memberName: '${d.data()['member_name'] ?? ''}',
                blockedAt: (d.data()['blocked_at'] as Timestamp?)?.toDate(),
              ),
          ]);
}

/// 'screenshot' or 'recording'.
class CaptureEvent {
  const CaptureEvent({
    required this.id,
    required this.type,
    required this.uid,
    required this.memberName,
    required this.email,
    required this.platform,
    required this.deviceName,
    this.page = '',
    this.course = '',
    this.detail = '',
    this.at,
  });

  /// Where it happened: the page, the course, the lesson / quiz title.
  final String page;
  final String course;
  final String detail;

  final String id;
  final String type;
  final String uid;
  final String memberName;
  final String email;
  final String platform;
  final String deviceName;
  final DateTime? at;

  bool get isRecording => type == 'recording';
}

abstract final class CaptureEvents {
  static CollectionReference<Map<String, dynamic>> get _col =>
      AppFirebase.db.collection('security_events');

  /// Saves one event for the signed-in MEMBER. Admins are not recorded.
  /// Never throws — a failed write must not disturb the member.
  static Future<void> record(String type, AppUser me) async {
    if (me.isEmpty || me.isAdmin) return;
    if (type != 'screenshot' && type != 'recording') return;
    final CaptureWhere where = CaptureContext.now;
    try {
      await _col.add(<String, dynamic>{
        'type': type,
        'page': where.page,
        'course': where.course,
        'detail': where.detail,
        'uid': me.uid,
        'member_name': me.displayName,
        'email': me.email,
        'platform': MemberAccess.currentPlatform,
        'device_name': DeviceIdentity.name,
        'device_id': DeviceIdentity.id,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Stream<List<CaptureEvent>> watch({int limit = 100}) => _col
      .orderBy('at', descending: true)
      .limit(limit)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> q) => <CaptureEvent>[
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs)
              CaptureEvent(
                id: d.id,
                type: '${d.data()['type'] ?? ''}',
                uid: '${d.data()['uid'] ?? ''}',
                memberName: '${d.data()['member_name'] ?? ''}',
                email: '${d.data()['email'] ?? ''}',
                platform: '${d.data()['platform'] ?? ''}',
                deviceName: '${d.data()['device_name'] ?? ''}',
                page: '${d.data()['page'] ?? ''}',
                course: '${d.data()['course'] ?? ''}',
                detail: '${d.data()['detail'] ?? ''}',
                at: (d.data()['at'] as Timestamp?)?.toDate(),
              ),
          ]);

  static Future<void> delete(String id) => _col.doc(id).delete();

  /// Deletes every event (in batches of 400).
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
