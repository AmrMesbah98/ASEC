/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: device_identity.dart
/// Purpose: Declares `DeviceIdentity` — a random id for THIS copy of the app,
///          for the one-device rule: a member's account is locked to the
///          first device it is used on (`users/{uid}.device_id`), and only
///          the admin can free it (Members → Edit access → Remove device).
/// Author: ASEC team
/// Created: 15/10/2026
///
/// The id is made once and kept on the device (GetStorage).
///
/// SURVIVES A REINSTALL (02/11/2026). Deleting the app used to wipe the id,
/// so signing in again said "opened on another device". [init] now ties it
/// to something the phone keeps:
///   * iPhone / iPad: the Keychain (kept when the app is deleted), seeded
///     with the id the app already had — nobody's device changes.
///   * Android: a fresh install (no saved id) uses a hash of ANDROID_ID,
///     which stays the same for this app on this phone after a reinstall.
///     A member who already has a saved id keeps it.
/// A build without the native side (an over-the-air patch on an older
/// release) simply keeps the old behaviour.

import 'dart:convert' show utf8;
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:get_storage/get_storage.dart';

import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';

abstract final class DeviceIdentity {
  static const String _idKey = 'asec_device_id';

  /// The uid whose account this device was locked to. Lets the app tell
  /// "the admin removed THIS device" (stay out) from "no device yet" (take
  /// the slot). Cleared on every sign-in, which is the member saying "use
  /// this device".
  /// v2: the first version could save this from an unconfirmed write, which
  /// wrongly showed "This device was removed"; those old values are ignored.
  static const String _boundKey = 'asec_device_bound_uid_v2';

  static GetStorage get _box => GetStorage();

  static String? _cached;

  /// The native side (MainActivity.kt / AppDelegate.swift): `stableId`.
  static const MethodChannel _native = MethodChannel('asec/screen_protection');

  static bool _valid(String? v) => v != null && v.length >= 16;

  static String _random() {
    final Random r = Random.secure();
    return List<String>.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// Call once in main(), after GetStorage.init(). Never throws.
  static Future<void> init() async {
    if (kIsWeb) return;
    String? stored;
    try {
      stored = _box.read<String>(_idKey);
    } catch (_) {}
    String? id = _valid(stored) ? stored : null;
    try {
      if (Platform.isIOS) {
        // The Keychain wins: after a reinstall it still holds the old id.
        final String? kept = await _native
            .invokeMethod<String>('stableId', id ?? _random())
            .timeout(const Duration(seconds: 3));
        if (_valid(kept)) id = kept;
      } else if (Platform.isAndroid && id == null) {
        final String? androidId = await _native
            .invokeMethod<String>('stableId')
            .timeout(const Duration(seconds: 3));
        if (androidId != null && androidId.trim().isNotEmpty) {
          id = sha256
              .convert(utf8.encode('asec-device:${androidId.trim()}'))
              .toString()
              .substring(0, 32);
        }
      }
    } catch (_) {
      // Older native build / no channel: the id below, as before.
    }
    if (id == null) return; // `id` makes and saves a random one.
    if (id != stored) {
      try {
        _box.write(_idKey, id);
      } catch (_) {}
    }
    _cached = id;
  }

  /// This device's id — 32 random hex characters, made on first use.
  static String get id {
    final String? cached = _cached;
    if (cached != null) return cached;
    String? stored;
    try {
      stored = _box.read<String>(_idKey);
    } catch (_) {}
    if (stored == null || stored.length < 16) {
      stored = _random();
      try {
        _box.write(_idKey, stored);
      } catch (_) {}
    }
    return _cached = stored;
  }

  /// What the admin sees: "Mac · amrs-macbook-air", "Android", …
  static String get name {
    final String platform = MemberAccess.platformLabel(MemberAccess.currentPlatform);
    if (kIsWeb) return platform;
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final String host = Platform.localHostname.replaceFirst(RegExp(r'\.local$'), '');
        if (host.isNotEmpty) return '$platform · $host';
      }
    } catch (_) {}
    return platform;
  }

  static String? get boundUid {
    try {
      return _box.read<String>(_boundKey);
    } catch (_) {
      return null;
    }
  }

  static void markBound(String uid) {
    if (boundUid == uid) return;
    try {
      _box.write(_boundKey, uid);
    } catch (_) {}
  }

  static void forgetBinding() {
    try {
      _box.remove(_boundKey);
    } catch (_) {}
  }
}
