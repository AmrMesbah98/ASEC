/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: crash_tracker.dart
/// Purpose: Declares `CrashTracker` — catches the crashes a normal error
///          handler cannot: the app vanishing to the desktop, a native crash,
///          a kill during startup. It writes a breadcrumb (the startup step it
///          is on) to local storage before each step; if the app dies, the
///          breadcrumb stays behind. The NEXT time the app opens it sees the
///          app never finished last time, and reports to the super admin
///          (ErrorReports) which step it died on — who, device, version, when.
/// Author: ASEC team
/// Created: 26/10/2026
///
/// HOW IT READS. A clean run ends with [markClean] (after the first frame is
/// on screen), which clears the breadcrumb. So on the next launch:
///   * no breadcrumb  → last run was fine.
///   * a breadcrumb   → last run died at that step; report it once the member
///                      is signed in (the only time the rules accept a report).
///
/// The report is sent from [reportPreviousCrashIfPending], called when a
/// session is restored (SessionController), because a report needs a signed-in
/// user. A crash that happens before anyone signs in is reported on the first
/// launch that does reach sign-in.

import 'dart:io' show Platform, Process, ProcessResult;

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/settings/windows_boot_guard.dart';

abstract final class CrashTracker {
  const CrashTracker._();

  static const String _stageKey = 'crash_stage';
  static const String _versionKey = 'crash_stage_version';
  static const String _timeKey = 'crash_stage_time';
  static const String _cleanStage = 'running';
  static const String _runStartKey = 'crash_run_start';
  static const String _lastEventKey = 'crash_last_windows_event';

  /// When the previous run started (ms) — the Windows check looks from here.
  static int? previousRunStart;

  static GetStorage get _box => GetStorage();

  /// The step the LAST run died on, read once at startup and kept here so the
  /// session can report it when someone signs in. Null = last run was clean.
  static String? pendingCrashStage;
  static String pendingCrashVersion = '';
  static DateTime? pendingCrashTime;

  /// Call once, right after GetStorage.init(): reads whether the previous run
  /// finished, then starts a fresh breadcrumb.
  static void startRun() {
    try {
      previousRunStart = _box.read<int>(_runStartKey);
      _box.write(_runStartKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
    try {
      final String? last = _box.read<String>(_stageKey);
      if (last != null && last.isNotEmpty && last != _cleanStage) {
        pendingCrashStage = last;
        pendingCrashVersion = _box.read<String>(_versionKey) ?? '';
        final int? ms = _box.read<int>(_timeKey);
        pendingCrashTime = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {}
  }

  /// Marks the step the app is about to attempt. If the app dies here, this is
  /// what the next run finds.
  static void stage(String name) {
    // Also to the plain-file boot journal (Windows), which survives a broken
    // GetStorage file.
    WindowsBootGuard.step(name);
    try {
      _box.write(_stageKey, name);
      _box.write(_timeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Records the running version, so a crash report can name the build.
  static void setVersion(String version) {
    try {
      _box.write(_versionKey, version);
    } catch (_) {}
  }

  /// The app came up: the first frame is on screen. Clears the breadcrumb, so
  /// a clean run leaves nothing behind.
  static void markClean() {
    try {
      _box.write(_stageKey, _cleanStage);
    } catch (_) {}
  }

  /// True while the last run is known to have crashed and not yet reported.
  static bool get hasPendingCrash => pendingCrashStage != null;

  /// WINDOWS (05/11/2026, from ENGX): a native crash kills the app before any
  /// Dart code runs, but Windows writes it to its Event Log — which module
  /// crashed (libmpv-2.dll = the video player, ASEC.exe = Firebase's
  /// built-in code, …) and the exception code. Returns the newest
  /// "Application Error" / "Application Hang" for ASEC.exe since the
  /// previous run started, once; '' when none or not on Windows.
  static Future<String> windowsCrashReason() async {
    if (kIsWeb || !Platform.isWindows) return '';
    try {
      final DateTime since = previousRunStart == null
          ? DateTime.now().subtract(const Duration(days: 2))
          : DateTime.fromMillisecondsSinceEpoch(previousRunStart!).subtract(const Duration(minutes: 1));
      final String start = since.toIso8601String().split('.').first;
      final String script = "\$e = Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1002; "
          "StartTime=[datetime]'$start'} -MaxEvents 50 -ErrorAction SilentlyContinue | "
          "Where-Object { \$_.Message -match 'ASEC\\.exe' } | Select-Object -First 1; "
          "if (\$e) { 'Event ' + \$e.Id + ' at ' + \$e.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'); \$e.Message }";
      final ProcessResult r = await Process.run(
        'powershell',
        <String>['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-Command', script],
      ).timeout(const Duration(seconds: 12));
      final String out = '${r.stdout}'.trim();
      if (out.isEmpty) return '';
      final List<String> keep = <String>[
        for (final String line in out.split(RegExp(r'\r?\n')))
          if (line.trim().isNotEmpty &&
              RegExp(r'^(Event |Faulting|Exception|Fault offset|Report Id|The program|Hang type)', caseSensitive: false)
                  .hasMatch(line.trim()))
            line.trim(),
      ];
      final String text = keep.isEmpty ? out : keep.join('\n');
      // Each Windows event is reported once.
      final String id = RegExp(r'Report Id:\s*(\S+)').firstMatch(text)?.group(1) ?? text.hashCode.toString();
      if (_box.read<String>(_lastEventKey) == id) return '';
      _box.write(_lastEventKey, id);
      return text.length > 1500 ? text.substring(0, 1500) : text;
    } catch (_) {
      return '';
    }
  }

  static void clearPending() {
    pendingCrashStage = null;
    pendingCrashVersion = '';
    pendingCrashTime = null;
  }
}
