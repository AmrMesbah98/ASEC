/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: app_features.dart
/// Purpose: Declares `AppFeature` (every switch the super admin controls from
///          Settings → Control centre) and `AppFeatures`, the live store that
///          reads them from Firestore `settings/app` and tells every screen
///          whether a part of the app is on.
/// Author: ASEC team
/// Created: 25/9/2026
///
/// ONE DOCUMENT, READ LIVE. Flipping a switch reaches every open app within
/// a second — no restart. A missing field means ON (the default below), so an
/// empty or unreadable document leaves the app exactly as it was.
///
/// Updated: 23/10/2026 - `screenshotException`: one account
///          ([kScreenshotExceptionEmail]) may be let through the screenshot
///          block. Features can now default to OFF ([AppFeature.defaultOn]).
///
/// Updated: 23/10/2026 - Calculators group: one switch per calculator
///          (converter, engineering, ducts, pipes, plumbing, fire). Off =
///          hidden from every member; admins still see it ([calcOn]).
///          All ON by default except the Engineering calculator (OFF: only
///          members unlocked on the Members page get it).
///
/// Rules: everybody may READ `settings/app` (the sign-in screen needs the
/// registration switch before anybody is signed in); only the super admin
/// may write it.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

/// The one account the `screenshotException` switch applies to.
const String kScreenshotExceptionEmail = 'amrmesbah33@gmail.com';

enum AppFeatureGroup { sections, videos, calculators, general, dashboard }

enum AppFeature {
  // ── What members see in the side menu ──
  sectionVideos('section_videos', AppFeatureGroup.sections, Icons.video_library_rounded),
  sectionQuizzes('section_quizzes', AppFeatureGroup.sections, Icons.quiz_outlined),
  sectionCvDirectory('section_cv_directory', AppFeatureGroup.sections, Icons.assignment_outlined),
  sectionMyCv('section_my_cv', AppFeatureGroup.sections, Icons.person_outline_rounded),

  // ── Video lessons ──
  videoSequential('video_sequential', AppFeatureGroup.videos, Icons.lock_rounded),
  videoBlockSkip('video_block_skip', AppFeatureGroup.videos, Icons.fast_forward_rounded),
  videoAutoplay('video_autoplay', AppFeatureGroup.videos, Icons.play_circle_outline_rounded),
  videoUpNext('video_up_next', AppFeatureGroup.videos, Icons.playlist_play_rounded),
  videoOptionsBar('video_options_bar', AppFeatureGroup.videos, Icons.tune_rounded),
  videoSpeed('video_speed', AppFeatureGroup.videos, Icons.speed_rounded),
  videoResume('video_resume', AppFeatureGroup.videos, Icons.history_rounded),
  videoSearch('video_search', AppFeatureGroup.videos, Icons.search_rounded),
  videoCourseProgress('video_course_progress', AppFeatureGroup.videos, Icons.stacked_line_chart_rounded),
  /// ON = members can save lessons INSIDE the app (encrypted, this device and
  /// account only) and watch them offline. OFF also erases saved lessons.
  videoDownloads('video_downloads', AppFeatureGroup.videos, Icons.download_for_offline_rounded),
  /// ON = lessons come ONLY from the Cloudflare lesson server (no Google
  /// Drive download limit). Copy the lessons there first (Settings →
  /// Cloudflare lessons). OFF = Google Drive, as before. (07/11/2026)
  videoCloud('video_cloud', AppFeatureGroup.videos, Icons.cloud_rounded, defaultOn: false),
  /// ON = every signed-in member can watch EVERY course, new uploads too —
  /// no course list needed. Blocked / paused / expired accounts and the
  /// platform limits still apply (ported from ENGX v1.0.73, 10/11/2026).
  /// firestore.rules reads the same `open_all_courses` field.
  openAllCourses('open_all_courses', AppFeatureGroup.videos, Icons.lock_open_rounded, defaultOn: false),

  // ── Calculators: ON = every member (with the calculators) can open it ──
  calcConverter('calc_converter', AppFeatureGroup.calculators, Icons.swap_horiz_rounded),
  /// OFF by default: then only members the admin unlocked (can_use_calcs)
  /// get it. ON = every member.
  calcEngineering(
    'calc_engineering',
    AppFeatureGroup.calculators,
    Icons.engineering_rounded,
    defaultOn: false,
  ),
  calcDuct('calc_duct', AppFeatureGroup.calculators, Icons.air_rounded),
  calcPipe('calc_pipe', AppFeatureGroup.calculators, Icons.plumbing_rounded),
  calcPlumbing('calc_plumbing', AppFeatureGroup.calculators, Icons.water_drop_rounded),
  calcFire('calc_fire', AppFeatureGroup.calculators, Icons.local_fire_department_rounded),

  // ── Whole app ──
  animations('animations', AppFeatureGroup.general, Icons.animation_rounded),
  registration('registration', AppFeatureGroup.general, Icons.person_add_alt_1_rounded),
  /// ON = screenshots and screen recordings of the app are blocked
  /// (core/settings/screen_protection.dart → native code on each platform).
  screenProtection('screen_protection', AppFeatureGroup.general, Icons.lock_outline_rounded),
  /// ON = [kScreenshotExceptionEmail] may take screenshots / recordings even
  /// while [screenProtection] blocks everybody else. OFF by default.
  screenshotException(
    'screenshot_exception',
    AppFeatureGroup.general,
    Icons.screenshot_monitor_rounded,
    defaultOn: false,
  ),

  // ── Admin dashboard ──
  dashboardCharts('dashboard_charts', AppFeatureGroup.dashboard, Icons.bar_chart_rounded),
  dashboardTable('dashboard_table', AppFeatureGroup.dashboard, Icons.table_rows_rounded);

  const AppFeature(this.key, this.group, this.icon, {this.defaultOn = true});

  final String key;
  final AppFeatureGroup group;
  final IconData icon;

  /// Value used while the document has no field for this switch.
  final bool defaultOn;
}

class AppFeatures extends GetxController {
  static AppFeatures get to => Get.isRegistered<AppFeatures>()
      ? Get.find<AppFeatures>()
      : Get.put(AppFeatures(), permanent: true);

  static DocumentReference<Map<String, dynamic>> get _doc =>
      AppFirebase.db.collection('settings').doc('app');

  /// key → on/off, straight from the document. Missing = the feature's
  /// [AppFeature.defaultOn] (on for all but a few).
  final RxMap<String, bool> values = <String, bool>{}.obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  /// (Re)subscribes. Safe to call again after sign-in, when the first
  /// attempt may have been refused.
  void listen() {
    _sub?.cancel();
    try {
      _sub = _doc.snapshots().listen(
        (DocumentSnapshot<Map<String, dynamic>> snap) {
          final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
          values.assignAll(<String, bool>{
            for (final MapEntry<String, dynamic> e in data.entries)
              if (e.value is bool) e.key: e.value as bool,
          });
          final Object? days = data[_expiryKey];
          if (days is num) {
            downloadExpiryDays.value = days.toInt();
            // Kept on the device too: offline (when the expiry matters
            // most) the setting can't be read from the server.
            try {
              GetStorage().write(_expiryKey, days.toInt());
            } catch (_) {}
          } else if (!snap.metadata.isFromCache) {
            downloadExpiryDays.value = 0;
          }
        },
        onError: (Object _) {},
      );
    } catch (_) {
      // Firebase not configured — every feature stays on.
    }
  }

  bool isOn(AppFeature f) => values[f.key] ?? f.defaultOn;

  // ── Downloaded lessons expire (ported from ENGX v1.0.54) ─────────────────

  static const String _expiryKey = 'download_expiry_days';

  /// Days a downloaded lesson stays on the device after it was downloaded;
  /// 0 = never expires. Control centre → Video lessons. Starts from the
  /// last value seen online, for an offline start.
  final RxInt downloadExpiryDays = (() {
    try {
      return GetStorage().read<int>(_expiryKey) ?? 0;
    } catch (_) {
      return 0;
    }
  })()
      .obs;

  Future<void> setDownloadExpiryDays(int days) async {
    downloadExpiryDays.value = days; // optimistic
    await _doc.set(<String, dynamic>{_expiryKey: days}, SetOptions(merge: true));
  }

  /// A calculator switch for the signed-in account: admins always see every
  /// calculator; members only the ones switched on.
  bool calcOn(AppFeature f) {
    final AppUser? me =
        Get.isRegistered<SessionController>() ? SessionController.to.current : null;
    if (me != null && me.isAdmin) return true;
    if (isOn(f)) return true;
    // Engineering switched off for everybody: still open to the members the
    // admin unlocked one by one (Members → can use calculators).
    return f == AppFeature.calcEngineering && me != null && me.canUseCalcs;
  }

  /// Reactive read for use inside `Obx`.
  static bool on(AppFeature f) => to.isOn(f);

  Future<void> set(AppFeature f, bool value) async {
    values[f.key] = value; // optimistic
    await _doc.set(<String, dynamic>{f.key: value}, SetOptions(merge: true));
  }

  Future<void> resetAll() async {
    values.clear();
    await _doc.set(<String, dynamic>{
      // Back to the defaults: everything on except the off-by-default
      // switches (the screenshot exception).
      for (final AppFeature f in AppFeature.values) f.key: f.defaultOn,
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
