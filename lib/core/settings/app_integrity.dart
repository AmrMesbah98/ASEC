/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: app_integrity.dart
/// Purpose: Declares `AppIntegrity` and `IntegrityBlockedView` — a RELEASE
///          build refuses to run on a device that could be used to pull the
///          lessons out of the app: developer options or USB debugging on
///          (Android), a debugger attached (all platforms), root / jailbreak,
///          hooking tools (Frida, Xposed, Substrate), or a re-signed
///          debuggable copy of the app.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// HOW
/// ---
/// The native side answers `asec/screen_protection` → `integrity` with a list
/// of problem codes (MainActivity.kt, AppDelegate.swift,
/// MainFlutterWindow.swift, flutter_window.cpp). The check runs at start, every
/// 10 seconds, and whenever the app comes back to the foreground, so turning
/// developer options on while the app is open closes it too. While anything
/// is found, the whole app is replaced by [IntegrityBlockedView] — every
/// page, and any video playing, is removed.
///
/// DEBUG AND PROFILE BUILDS ARE NEVER BLOCKED, so `flutter run` keeps
/// working on a developer's own device. The web cannot inspect the device,
/// so there it does nothing.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

abstract final class AppIntegrity {
  static const MethodChannel _channel = MethodChannel('asec/screen_protection');

  /// Only a release build on a device enforces.
  static bool get enforced => kReleaseMode && !kIsWeb;

  /// The problems found by the last check (empty = safe).
  static final RxList<String> issues = <String>[].obs;

  /// False until the first check has answered, so nothing of the app is
  /// shown before the device has been looked at.
  static final RxBool checked = (!enforced).obs;

  static Timer? _timer;
  static _ResumeObserver? _observer;

  static void start() {
    if (!enforced) return;
    check();
    _timer ??= Timer.periodic(const Duration(seconds: 10), (_) => check());
    if (_observer == null) {
      _observer = _ResumeObserver();
      WidgetsBinding.instance.addObserver(_observer!);
    }
  }

  static Future<void> check() async {
    if (!enforced) return;
    List<String> found = <String>[];
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        // A TIMEOUT so a native side that never answers can NEVER leave the
        // app stuck on the white gate below: if the check does not come back
        // in two seconds, the app is shown (treated as safe) rather than
        // waiting forever. Old / slow Windows machines were the ones at risk.
        final List<Object?>? raw = await _channel
            .invokeListMethod<Object?>('integrity')
            .timeout(const Duration(seconds: 2));
        found = <String>[for (final Object? r in raw ?? <Object?>[]) '$r'];
        break;
      } on MissingPluginException {
        // The native side may register a moment after Dart starts.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } on TimeoutException {
        // No answer in time → do not block the app on a silent check.
        break;
      } catch (_) {
        break;
      }
    }
    if (!listEquals(found, issues)) issues.assignAll(found);
    checked.value = true;
  }

  /// Wraps the app: the app itself when the device is safe, else the block.
  static Widget gate(Widget child) {
    if (!enforced) return child;
    // The app stays mounted underneath (hidden) for the same reason as the
    // offline screen: customButton needs GetX's navigator context alive.
    return Obx(() {
      final bool blocked = !checked.value || issues.isNotEmpty;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Offstage(
            offstage: blocked,
            child: TickerMode(enabled: !blocked, child: child),
          ),
          if (!checked.value)
            ColoredBox(color: AppColors.background)
          else if (issues.isNotEmpty)
            IntegrityBlockedView(issues: issues.toList()),
        ],
      );
    });
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) AppIntegrity.check();
  }
}

class IntegrityBlockedView extends StatelessWidget {
  const IntegrityBlockedView({super.key, required this.issues});

  final List<String> issues;

  String _label(S s, String code) {
    switch (code) {
      case 'developer_options':
        return s.integrityDeveloperOptions;
      case 'usb_debugging':
        return s.integrityUsbDebugging;
      case 'debugger':
        return s.integrityDebugger;
      case 'debuggable':
        return s.integrityDebuggable;
      case 'root':
        return s.integrityRoot;
      case 'jailbreak':
        return s.integrityJailbreak;
      case 'hooking':
        return s.integrityHooking;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.gpp_bad_rounded, size: 38, color: AppColors.red),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    FormatHelper.capitalize(s.securityBlockedTitle),
                    textAlign: TextAlign.center,
                    style: StyleText.fontSize20Weight600.copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    FormatHelper.capitalize(s.securityBlockedBody),
                    textAlign: TextAlign.center,
                    style: StyleText.fontSize14Weight400
                        .copyWith(color: AppColors.secondaryText, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  for (final String code in issues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.error_outline_rounded, size: 18, color: AppColors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              FormatHelper.capitalize(_label(s, code)),
                              style: StyleText.fontSize14Weight500
                                  .copyWith(color: AppColors.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  customButton(
                    title: s.securityCheckAgain,
                    function: AppIntegrity.check,
                    wrapContent: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
