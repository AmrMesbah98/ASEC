/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_device_lock.dart
/// Purpose: Declares `VideoDevice` and `VideoDeviceLock` — ONE VIDEO DEVICE
///          PER PLATFORM. A member signs in on any number of devices, but
///          the videos play on one device per platform (one Android, one
///          iPhone / iPad, one Windows, one Mac, one Web). The first device
///          that opens Videos on a platform takes that platform's slot;
///          the admin frees it from Members → Edit access → Video devices.
/// Author: ASEC team
/// Created: 25/10/2026
///
/// Stored on the member's profile:
///   users/{uid}.video_devices = {
///     'windows': {'id': <DeviceIdentity.id>, 'name': 'Windows · PC-1', 'at': ts},
///     ...
///   }
/// firestore.rules lets the member ADD a platform that has no device yet,
/// never change or remove one; only an admin with Members → Reset device
/// can free a slot.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/data/device/device_identity.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';

class VideoDevice {
  const VideoDevice({required this.id, required this.name, this.at});

  final String id;
  final String name;
  final DateTime? at;

  /// THIS device (07/11/2026, from ENGX): its current id, this PC's
  /// MachineGuid id (an install made before it was used), or — a slot saved
  /// by an older install on this very computer — the same computer name
  /// ("Windows · DESKTOP-4KQ2"), which an uninstall / reinstall never changes.
  ///
  /// UPDATES NEVER LOCK A MEMBER OUT (11/11/2026): a slot this install has
  /// already played with (its id kept in the app's storage, which an update
  /// never removes) is still this device, even if an update reads this
  /// device's id differently.
  bool get isThisDevice {
    final bool mine = _matches;
    if (mine) VideoDeviceLock._hold(id);
    return mine;
  }

  bool get _matches {
    if (id == DeviceIdentity.id) return true;
    final String? machine = DeviceIdentity.machineId;
    if (machine != null && id == machine) return true;
    if (VideoDeviceLock._heldIds().contains(id)) return true;
    final String me = DeviceIdentity.name;
    return me.contains(' · ') && name == me;
  }
}

abstract final class VideoDeviceLock {
  static const String field = 'video_devices';

  /// Every platform that has its own slot, in display order.
  static const List<String> platforms = <String>[
    'android',
    'ios',
    'windows',
    'macos',
    'web',
  ];

  static DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      AppFirebase.db.collection(FirebaseCollections.users).doc(uid);

  /// platform → device, from a user document's data.
  static Map<String, VideoDevice> parse(Map<String, dynamic>? data) {
    final Object? raw = data?[field];
    if (raw is! Map) return const <String, VideoDevice>{};
    final Map<String, VideoDevice> out = <String, VideoDevice>{};
    raw.forEach((Object? k, Object? v) {
      if (k is! String || v is! Map) return;
      final String id = '${v['id'] ?? ''}';
      if (id.isEmpty) return;
      final Object? at = v['at'];
      out[k] = VideoDevice(
        id: id,
        name: '${v['name'] ?? ''}',
        at: at is Timestamp ? at.toDate() : null,
      );
    });
    return out;
  }

  static Stream<Map<String, VideoDevice>> watch(String uid) => _doc(uid)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> d) => parse(d.data()));

  /// Takes THIS platform's slot for THIS device. The rules refuse it when
  /// the slot is already taken, so two devices can never both win.
  static Future<void> claim(String uid) => _doc(uid).update(<String, dynamic>{
        '$field.${MemberAccess.currentPlatform}': <String, dynamic>{
          'id': DeviceIdentity.id,
          'name': DeviceIdentity.name,
          'at': FieldValue.serverTimestamp(),
        },
      });

  /// Admin: frees [platform]'s slot — the next device of that platform that
  /// opens Videos takes it.
  static Future<void> release(String uid, String platform) =>
      _doc(uid).update(<String, dynamic>{
        '$field.$platform': FieldValue.delete(),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  // ── Offline memory ───────────────────────────────────────────────────────
  //
  // Downloaded lessons play without internet. When the profile cannot be
  // read, the last confirmed answer for this device decides.

  static String _key(String uid) => 'asec_video_slot_${uid}_${MemberAccess.currentPlatform}';

  // ── Slot ids this install played with (11/11/2026) ─────────────────────

  static const String _heldKey = 'asec_video_device_ids';
  static Set<String>? _held;

  static Set<String> _heldIds() {
    if (_held != null) return _held!;
    try {
      final List<dynamic> raw = GetStorage().read<List<dynamic>>(_heldKey) ?? const <dynamic>[];
      _held = <String>{for (final dynamic v in raw) if ('$v'.trim().isNotEmpty) '$v'.trim()};
    } catch (_) {
      _held = <String>{};
    }
    return _held!;
  }

  static void _hold(String id) {
    final Set<String> held = _heldIds();
    if (id.trim().isEmpty || held.contains(id)) return;
    held.add(id);
    while (held.length > 10) {
      held.remove(held.first);
    }
    try {
      GetStorage().write(_heldKey, held.toList());
    } catch (_) {}
  }

  static bool rememberedOwner(String uid) {
    try {
      return GetStorage().read<bool>(_key(uid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static void remember(String uid, bool owner) {
    try {
      if (rememberedOwner(uid) != owner) GetStorage().write(_key(uid), owner);
    } catch (_) {}
  }
}
