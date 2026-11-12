/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: screen_protection.dart
/// Purpose: Declares `ScreenProtection` — turns the native screenshot /
///          screen-recording block on or off, following the super admin's
///          Control centre switch `AppFeature.screenProtection`.
/// Author: ASEC team
/// Created: 26/9/2026
///
/// ONE CHANNEL, FOUR PLATFORMS: `asec/screen_protection`, method
/// `setEnabled(bool)`, answered by
///   * Android — MainActivity.kt        FLAG_SECURE on / off
///   * iOS     — SceneDelegate.swift    secure layer + recording cover
///   * macOS   — MainFlutterWindow.swift sharingType .none / .readOnly
///   * Windows — flutter_window.cpp     WDA_EXCLUDEFROMCAPTURE / WDA_NONE
/// Every platform STARTS protected, so nothing is captured before the
/// setting has loaded; a switch left off in Firestore lifts it a moment
/// later. The web cannot block screenshots, so there it does nothing.
///
/// EXCEPTION (23/10/2026): with `AppFeature.screenshotException` on, the
/// account [kScreenshotExceptionEmail] is not blocked even while the block
/// is on for everybody else. Re-applied whenever the switches or the
/// signed-in user change.
///
/// ADMIN REMINDER (23/10/2026): while `screenProtection` is OFF (every
/// member may take screenshots), an admin gets a warning in the centre of
/// the screen every minute. The super admin can block again from it.
///
/// VIDEO ONLY (25/10/2026): the block is applied only while a lesson video
/// is on screen. VideoPlayerPage calls [enterVideo] in initState and
/// [leaveVideo] in dispose; the rest of the app can be captured freely.
/// The Control centre switch still decides whether videos are protected.
/// Native code still STARTS protected; the first [apply] (from [start])
/// lifts it at once because no video is open yet.
///
/// SCREEN CAPTURE ALERTS: the native side calls back on the same channel,
/// `captured("screenshot" | "recording")` — iOS (screenshot + recording /
/// mirroring), Android 14+ (screenshot) and 15+ (recording). Each is saved
/// for the admin (CaptureEvents). Mac and Windows cannot detect them.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/11-custom_confirm_dialog.dart';
import 'package:asec/generated/l10n.dart';

import 'package:asec/core/settings/app_features.dart';
import 'package:asec/features/admin/a2_members/data/device_security.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

abstract final class ScreenProtection {
  static const MethodChannel _channel = MethodChannel('asec/screen_protection');

  static bool? _applied;

  /// How many video screens are open (a lesson can open the next one on
  /// top). The block is on only while this is above zero.
  static int _videoScreens = 0;

  static bool get isVideoOpen => _videoScreens > 0;

  static final StreamController<String> _captures = StreamController<String>.broadcast();

  /// 13/11/2026: every screen capture the native side reports
  /// ('screenshot' / 'recording'), lesson or not. A running quiz counts them.
  static Stream<String> get captures => _captures.stream;

  /// A lesson video came on screen: block capture (if the switch is on).
  static void enterVideo() {
    _videoScreens++;
    apply(_shouldBlock());
  }

  /// A lesson video left the screen: lift the block once none are open.
  static void leaveVideo() {
    if (_videoScreens > 0) _videoScreens--;
    apply(_shouldBlock());
  }

  /// Admin reminder: fires every minute while screenshots are allowed.
  static Timer? _reminder;
  static bool _reminderShowing = false;

  /// The last alert of each type, so one capture is not saved twice.
  static final Map<String, DateTime> _lastAlert = <String, DateTime>{};

  /// Applies the switch now and every time `settings/app` changes.
  static void start() {
    if (!kIsWeb) _channel.setMethodCallHandler(_onNative);
    final AppFeatures features = AppFeatures.to;
    apply(_shouldBlock());
    ever(features.values, (_) => apply(_shouldBlock()));
    if (Get.isRegistered<SessionController>()) {
      ever(SessionController.to.user, (_) => apply(_shouldBlock()));
    }
    _reminder?.cancel();
    _reminder = Timer.periodic(const Duration(minutes: 1), (_) => _remindAdmin());
  }

  /// Every minute: an admin is signed in and Block screenshots is OFF →
  /// a warning in the middle of the screen. One at a time, never stacked.
  static Future<void> _remindAdmin() async {
    if (_reminderShowing) return;
    if (AppFeatures.to.isOn(AppFeature.screenProtection)) return;
    if (!Get.isRegistered<SessionController>()) return;
    final AppUser user = SessionController.to.current;
    if (user.isEmpty || !user.isAdmin) return;
    final BuildContext? context = Get.overlayContext ?? Get.context;
    if (context == null || !context.mounted) return;
    final S s = S.of(context);
    _reminderShowing = true;
    try {
      if (user.isSuperAdmin) {
        // The super admin owns the switch: offer to block right here.
        await showConfirmDialog(
          context: context,
          title: s.shotAllowedTitle,
          subtitle: s.shotAllowedBody,
          confirmLabel: s.shotAllowedBlock,
          cancelLabel: s.shotAllowedKeep,
          onConfirm: () {
            AppFeatures.to.set(AppFeature.screenProtection, true).catchError((Object _) {});
          },
        );
      } else {
        await showWarningDialog(
          context: context,
          title: s.shotAllowedTitle,
          subtitle: s.shotAllowedBody,
          closeLabel: s.close,
        );
      }
    } catch (_) {
      // No navigator yet (splash) — try again next minute.
    } finally {
      _reminderShowing = false;
    }
  }

  /// The global block, unless the signed-in account is the allowed one and
  /// its exception switch is on.
  static bool _shouldBlock() {
    if (!isVideoOpen) return false; // video only
    final AppFeatures features = AppFeatures.to;
    if (!features.isOn(AppFeature.screenProtection)) return false;
    if (!features.isOn(AppFeature.screenshotException)) return true;
    if (!Get.isRegistered<SessionController>()) return true;
    final String email = SessionController.to.current.email.trim().toLowerCase();
    return email != kScreenshotExceptionEmail;
  }

  static Future<void> _onNative(MethodCall call) async {
    if (call.method != 'captured') return;
    _captures.add('${call.arguments}' == 'recording' ? 'recording' : 'screenshot');
    // Capture is only blocked on videos, so only alert from there.
    if (!isVideoOpen) return;
    final String type = '${call.arguments}';
    final DateTime now = DateTime.now();
    final DateTime? last = _lastAlert[type];
    if (last != null && now.difference(last) < const Duration(seconds: 5)) return;
    _lastAlert[type] = now;
    if (!Get.isRegistered<SessionController>()) return;
    await CaptureEvents.record(type, SessionController.to.current);
  }

  static Future<void> apply(bool on) async {
    if (kIsWeb || _applied == on) return;
    _applied = on;
    try {
      await _channel.invokeMethod<void>('setEnabled', on);
    } on MissingPluginException {
      // Linux, or a platform without the native side — nothing to do.
    } catch (_) {}
  }
}
