/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: app_update.dart
/// Purpose: Declares `AppUpdate` — keeps the Android app current, two ways:
///
///   1. CODE PUSH (Shorebird). Dart-only fixes shipped with
///      `shorebird patch android` download in the background; the user is
///      told to reopen the app to apply them. No Play review, no new version.
///
///   2. STORE UPDATE (Google Play). When a new version is on Play — or the
///      admin marks the running build as too old — a dialog asks the user to
///      update. "Update now" opens Play's in-app update screen, or the Play
///      Store page if that is not possible.
///
/// THE ADMIN'S SWITCH — Firestore `settings/app_update` (all fields optional):
///
///   min_build     int     builds BELOW this must update (dialog can't be
///                         closed). This is the build number after the `+`
///                         in pubspec `version:` (1.0.0+4 → 4).
///   latest_build  int     builds below this get the optional dialog, even
///                         before Play reports the update.
///   notes_en      string  "What's new" text (English)
///   notes_ar      string  "What's new" text (Arabic)
///
/// Everything here is Android-only and never throws: no Play (debug build,
/// sideloaded APK), no Shorebird (plain `flutter run`) or no network simply
/// means nothing is shown.
/// Author: ASEC team
/// Created: 2/10/2026

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/settings/windows_auto_update.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

abstract final class AppUpdate {
  const AppUpdate._();

  static bool _started = false;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get _isMacOS => !kIsWeb && Platform.isMacOS;

  /// Shorebird code push works on iOS too (App Store builds made with
  /// `shorebird release ios`). Before 25/10/2026 only Android checked for
  /// patches, so iPhone users only got changes through the App Store.
  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// Called once the first real screen is up (see `AppRouter.go`). Runs once
  /// per launch; later calls do nothing.
  ///
  /// NOT from `main`: the splash replaces the whole route stack when it
  /// leaves, and a dialog opened before that would be swept away with it.
  static void checkSoon() {
    if (_started) return;
    // WINDOWS (07/11/2026): the newest published installer is required.
    if (!kIsWeb && Platform.isWindows) {
      _started = true;
      Future<void>.delayed(const Duration(milliseconds: 1500), _checkWindows);
      return;
    }
    if (!(_isAndroid || _isIOS || _isMacOS)) return;
    _started = true;
    Future<void>.delayed(const Duration(milliseconds: 1500), () async {
      // 10/11/2026 (from ENGX): EVERY platform gets the "new version" dialog —
      // Android from Google Play, iPhone and Mac from the App Store.
      final bool storeDialogShown =
          _isAndroid ? await _checkStore() : await _checkApple();
      // A store update replaces the app anyway — no need to talk patches.
      if (!storeDialogShown && !_isMacOS) await _checkPatch();
    });
  }

  // ── Per-platform rules (10/11/2026, from ENGX) ─────────────────────────────
  //
  // Firestore `settings/app_update.platforms` — each platform on its own, by
  // VERSION NAME: { android: {min: '1.0.30', latest: '1.0.31'}, ios: {…},
  // macos: {…}, windows: {…} }. Below `min` → forced; below `latest` → asked.
  // Set from Settings → App update → Per platform.

  /// 'android', 'ios', 'macos', 'windows' — '' elsewhere.
  static String get platformKey {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return '';
  }

  /// (forced, asked) for [version] by this platform's own rule in [data].
  static (bool, bool) _platformRule(Map<String, dynamic> data, String version) {
    final Object? all = data['platforms'];
    if (all is! Map || version.isEmpty) return (false, false);
    final Object? own = all[platformKey];
    if (own is! Map) return (false, false);
    final String min = '${own['min'] ?? ''}'.trim();
    final String latest = '${own['latest'] ?? ''}'.trim();
    return (
      min.isNotEmpty && _compare(version, min) < 0,
      latest.isNotEmpty && _compare(version, latest) < 0,
    );
  }

  static Future<Map<String, dynamic>> _settings() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await AppFirebase.db
          .collection('settings')
          .doc('app_update')
          .get()
          .timeout(const Duration(seconds: 8));
      return snap.data() ?? <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // ── iPhone / Mac: the App Store (10/11/2026) ───────────────────────────────

  /// The App Store's own record of this app, looked up by bundle id:
  /// (store version, store page). Null when it is not on the store yet.
  static Future<(String, String)?> _appStore(String bundleId) async {
    for (final String country in <String>['', 'eg', 'sa', 'ae']) {
      try {
        final String c = country.isEmpty ? '' : '&country=$country';
        final http.Response r = await http
            .get(Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId$c&t=${DateTime.now().millisecondsSinceEpoch}'))
            .timeout(const Duration(seconds: 10));
        if (r.statusCode != 200) continue;
        final Object? data = jsonDecode(r.body);
        if (data is! Map || data['resultCount'] is! num || (data['resultCount'] as num) < 1) continue;
        final Object? first = (data['results'] as List).first;
        if (first is! Map) continue;
        final String version = '${first['version'] ?? ''}'.trim();
        final String url = '${first['trackViewUrl'] ?? ''}'.trim();
        if (version.isNotEmpty) return (version, url);
      } catch (_) {}
    }
    return null;
  }

  /// Returns true when the update dialog was shown.
  static Future<bool> _checkApple() async {
    try {
      final PackageInfo package = await PackageInfo.fromPlatform();
      final String version = package.version;
      final int build = int.tryParse(package.buildNumber) ?? 0;
      final Map<String, dynamic> data = await _settings();
      final (bool ownForced, bool ownAsked) = _platformRule(data, version);
      final int minBuild = (data['min_build'] as num?)?.toInt() ?? 0;

      final (String, String)? store = await _appStore(package.packageName);
      final bool storeNewer = store != null && _compare(version, store.$1) < 0;

      final bool forced = ownForced || (build > 0 && build < minBuild);
      if (!forced && !ownAsked && !storeNewer) return false;

      // Where "Update now" goes: the link saved by the admin, else the App
      // Store page the lookup found.
      final String saved = '${data[_isMacOS ? 'macos_url' : 'ios_url'] ?? ''}'.trim();
      // Last fallback: ASEC's App Store record (Apple ID 6814102551 — the same
      // record serves iPhone, iPad and Mac).
      final String link = saved.isNotEmpty
          ? saved
          : ((store?.$2 ?? '').isNotEmpty ? store!.$2 : 'https://apps.apple.com/app/id6814102551');

      final BuildContext? context = Get.overlayContext ?? Get.context;
      if (context == null || !context.mounted) return false;
      final String lang = Localizations.localeOf(context).languageCode;
      final String? notes = (data['notes_$lang'] ?? data['notes_en']) as String?;
      final S s = S.of(context);

      await _UpdateDialog.show(
        context,
        forced: forced,
        icon: Icons.system_update_rounded,
        title: forced ? s.updateRequiredTitle : s.updateTitle,
        message: forced ? s.updateRequiredMessage : s.updateMessage,
        version: s.updateCurrentVersion(version),
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        primaryLabel: s.updateNow,
        primaryIcon: Icons.download_rounded,
        onPrimary: () async {
          if (link.isEmpty) return;
          try {
            await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
          } catch (_) {}
        },
        secondaryLabel: s.updateLater,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── 0. Windows: the newest published installer (07/11/2026) ───────────────

  /// Off: Firestore `settings/app_update.windows_auto_force = false`.
  static Future<void> _checkWindows() async {
    try {
      final PackageInfo package = await PackageInfo.fromPlatform();
      final String version = package.version;
      if (version.isEmpty) return;
      try {
        final DocumentSnapshot<Map<String, dynamic>> snap = await AppFirebase.db
            .collection('settings')
            .doc('app_update')
            .get()
            .timeout(const Duration(seconds: 8));
        if (snap.data()?['windows_auto_force'] == false) return;
      } catch (_) {}
      final (String, String, String)? newest = await WindowsAutoUpdate.latest();
      if (newest == null || _compare(version, newest.$1) >= 0) return;
      final BuildContext? context = Get.overlayContext ?? Get.context;
      if (context == null || !context.mounted) return;
      final S s = S.of(context);
      await _UpdateDialog.show(
        context,
        forced: true,
        icon: Icons.system_update_rounded,
        title: s.updateRequiredTitle,
        message: 'A new version of ASEC (${newest.$1}) is ready. Install it to keep using the app — '
            'it downloads and installs here, then ASEC opens again.',
        version: s.updateCurrentVersion(version),
        primaryLabel: 'Update now',
        primaryIcon: Icons.download_rounded,
        onPrimary: () async {
          final BuildContext? c = Get.overlayContext ?? Get.context;
          if (c != null && c.mounted) await WindowsAutoUpdate.installInApp(c, newest.$2);
        },
        secondaryLabel: '',
      );
    } catch (_) {}
  }

  /// -1 / 0 / 1 for "1.0.9" vs "1.0.15" (numbers; a missing part = 0).
  static int _compare(String a, String b) {
    List<int> parts(String v) => v.split(RegExp(r'[.+\-]')).map((String p) => int.tryParse(p.trim()) ?? 0).toList();
    final List<int> x = parts(a);
    final List<int> y = parts(b);
    for (int i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
      final int p = i < x.length ? x[i] : 0;
      final int q = i < y.length ? y[i] : 0;
      if (p != q) return p < q ? -1 : 1;
    }
    return 0;
  }

  // ── 1. Google Play ───────────────────────────────────────────────────────

  /// Returns true when the update dialog was shown.
  static Future<bool> _checkStore() async {
    try {
      final PackageInfo package = await PackageInfo.fromPlatform();
      final int build = int.tryParse(package.buildNumber) ?? 0;

      // The admin's rule.
      int minBuild = 0;
      int latestBuild = 0;
      Map<String, dynamic> data = <String, dynamic>{};
      try {
        final DocumentSnapshot<Map<String, dynamic>> snap = await AppFirebase
            .db
            .collection('settings')
            .doc('app_update')
            .get()
            .timeout(const Duration(seconds: 8));
        data = snap.data() ?? <String, dynamic>{};
        minBuild = (data['min_build'] as num?)?.toInt() ?? 0;
        latestBuild = (data['latest_build'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // Offline / Firebase not configured — Play alone decides.
      }

      // What Google Play says. Throws when the app was not installed from
      // Play (debug, sideloaded) — then only the admin's rule counts.
      AppUpdateInfo? play;
      try {
        play = await InAppUpdate.checkForUpdate();
      } catch (_) {}
      final bool playHasUpdate =
          play?.updateAvailability == UpdateAvailability.updateAvailable;

      // Android's own version rule (Settings → App update → Per platform).
      final (bool ownForced, bool ownAsked) = _platformRule(data, package.version);
      final bool forced = build < minBuild || ownForced;
      if (!forced && !playHasUpdate && !ownAsked && build >= latestBuild) return false;

      final BuildContext? context = Get.overlayContext ?? Get.context;
      if (context == null || !context.mounted) return false;

      final String lang = Localizations.localeOf(context).languageCode;
      final String? notes =
          (data['notes_$lang'] ?? data['notes_en']) as String?;
      final S s = S.of(context);

      await _UpdateDialog.show(
        context,
        forced: forced,
        icon: Icons.system_update_rounded,
        title: forced ? s.updateRequiredTitle : s.updateTitle,
        message: forced ? s.updateRequiredMessage : s.updateMessage,
        version: s.updateCurrentVersion(package.version),
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        primaryLabel: s.updateNow,
        primaryIcon: Icons.download_rounded,
        onPrimary: () => _openStore(play, package.packageName),
        secondaryLabel: s.updateLater,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Play's own full-screen updater when it can; the Play Store page if not.
  static Future<void> _openStore(AppUpdateInfo? play, String packageId) async {
    if (play != null &&
        play.updateAvailability == UpdateAvailability.updateAvailable &&
        play.immediateUpdateAllowed) {
      try {
        final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
        // On success Play installs and restarts the app by itself.
        if (result == AppUpdateResult.success) return;
        // The user closed Play's screen — respect that. (A required update's
        // dialog is still up, so they can try again.)
        if (result == AppUpdateResult.userDeniedUpdate) return;
      } catch (_) {}
    }
    try {
      final bool opened = await launchUrl(
        Uri.parse('market://details?id=$packageId'),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (_) {}
    try {
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=$packageId'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  // ── 2. Shorebird code push ───────────────────────────────────────────────

  static Future<void> _checkPatch() async {
    try {
      final ShorebirdUpdater updater = ShorebirdUpdater();
      // False for builds not made with `shorebird release`.
      if (!updater.isAvailable) return;

      UpdateStatus status = await updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await updater.update();
        status = await updater.checkForUpdate();
      }
      if (status != UpdateStatus.restartRequired) return;

      final BuildContext? context = Get.overlayContext ?? Get.context;
      if (context == null || !context.mounted) return;
      final S s = S.of(context);

      await _UpdateDialog.show(
        context,
        forced: false,
        icon: Icons.auto_awesome_rounded,
        title: s.patchReadyTitle,
        message: s.patchReadyMessage,
        primaryLabel: s.patchRestart,
        primaryIcon: Icons.restart_alt_rounded,
        // Android / iOS can't relaunch themselves; closing is the honest
        // version. The patch is applied the next time the app opens.
        onPrimary: () => SystemNavigator.pop(),
        secondaryLabel: s.updateLater,
      );
    } catch (_) {
      // UpdateException (network, disk) — the next launch tries again.
    }
  }
}

// ── The dialog ─────────────────────────────────────────────────────────────

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({
    required this.forced,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    this.version,
    this.notes,
  });

  final bool forced;
  final IconData icon;
  final String title;
  final String message;
  final String? version;
  final String? notes;
  final String primaryLabel;
  final IconData primaryIcon;
  final Future<void> Function() onPrimary;
  final String secondaryLabel;

  static Future<void> show(
    BuildContext context, {
    required bool forced,
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required IconData primaryIcon,
    required Future<void> Function() onPrimary,
    required String secondaryLabel,
    String? version,
    String? notes,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: !forced,
      barrierLabel: title,
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => _UpdateDialog(
        forced: forced,
        icon: icon,
        title: title,
        message: message,
        version: version,
        notes: notes,
        primaryLabel: primaryLabel,
        primaryIcon: primaryIcon,
        onPrimary: onPrimary,
        secondaryLabel: secondaryLabel,
      ),
      transitionBuilder: (_, Animation<double> animation, __, Widget child) {
        final Animation<double> curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // A required update can't be backed out of.
      canPop: !forced,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: AppColors.card,
              elevation: 0,
              borderRadius: BorderRadius.circular(24.r),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _header(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 18.h),
                      child: _body(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 128.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Two soft rings for depth.
          PositionedDirectional(
            top: -30.h,
            start: -24.w,
            child: _ring(110.r),
          ),
          PositionedDirectional(
            bottom: -40.h,
            end: -20.w,
            child: _ring(130.r),
          ),
          Center(
            child: Container(
              width: 76.r,
              height: 76.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20.r,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AppIcon(icon, size: 38.r, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.10),
        ),
      );

  Widget _body(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          FormatHelper.capitalize(title),
          textAlign: TextAlign.center,
          style: StyleText.fontSize20Weight600.copyWith(color: AppColors.text),
        ),
        SizedBox(height: 8.h),
        Text(
          FormatHelper.capitalize(message),
          textAlign: TextAlign.center,
          style: StyleText.fontSize14Weight400
              .copyWith(color: AppColors.secondaryText, height: 1.5),
        ),
        if (version != null) ...<Widget>[
          SizedBox(height: 12.h),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                FormatHelper.capitalize(version!),
                style: StyleText.fontSize12Weight600
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
        if (notes != null) ...<Widget>[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AppIcon(Icons.auto_awesome_rounded,
                        size: 16.r, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Text(
                      FormatHelper.capitalize(S.of(context).updateWhatsNew),
                      style: StyleText.fontSize13Weight600
                          .copyWith(color: AppColors.text),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 140.h),
                  child: SingleChildScrollView(
                    child: Text(
                      FormatHelper.capitalize(notes!),
                      style: StyleText.fontSize13Weight400.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 22.h),
        // 11/11/2026: "Later" and "Update now" on ONE row — Later on the
        // left (an outlined button, easy to see and tap), Update on the
        // right. A required update shows only "Update now".
        Row(
          children: <Widget>[
            if (!forced) ...<Widget>[
              Expanded(
                child: AppButton(
                  label: secondaryLabel,
                  kind: AppButtonKind.outlined,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: 10.w),
            ],
            Expanded(
              child: _PrimaryButton(
                label: primaryLabel,
                icon: primaryIcon,
                // A required update keeps the dialog up: if the user backs
                // out of Play, they come back to it.
                onPressed: () async {
                  if (!forced) Navigator.of(context).pop();
                  await onPrimary();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// AppButton with a spinner while Play / the store is opening.
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: widget.label,
      icon: widget.icon,
      expand: true,
      loading: _busy,
      onPressed: () async {
        setState(() => _busy = true);
        try {
          await widget.onPressed();
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
    );
  }
}
