/// `DeviceSpecs` — what kind of PC this is (06/11/2026, from ENGX), sent with every
/// error report and with "Online now", so the admins can see WHICH devices
/// have trouble:
///
///   Windows 10 Pro (19045) · Intel(R) Core(TM) i5-2410M · OLD CPU (no BMI2)
///   · 4 cores · 7.9 GB RAM · Intel(R) HD Graphics 3000
///
/// * CPU name and features come straight from the processor (CPUID, native
///   side windows/runner/flutter_window.cpp, method `cpuInfo`). "OLD CPU (no
///   BMI2)" marks the processors Firebase's Windows Firestore code crashes on
///   (0xc000001d); WindowsBootGuard keeps those working.
/// * Windows edition and graphics card: one hidden PowerShell call, once.
///
/// Windows only for now; elsewhere [summary] is ''. Never blocks: read in the
/// background at start, '' until ready.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart';

import 'package:asec/core/theme/app_colors.dart';

abstract final class DeviceSpecs {
  static const MethodChannel _channel = MethodChannel('asec/screen_protection');

  static String _summary = '';
  static bool _oldCpu = false;
  static Future<void>? _loading;

  /// One line describing this PC ('' until loaded / not Windows).
  static String get summary => _summary;

  /// The CPU lacks BMI2 (Intel before 2013, many Pentium / Celeron, older AMD).
  static bool get oldCpu => _oldCpu;

  /// No graphics driver installed (11/11/2026): Windows lists only
  /// "Microsoft Basic Display Adapter" / "Basic Render Driver". The graphics
  /// card cannot decode video then, so lessons are decoded on the CPU.
  static bool get noGraphicsDriver => _noGraphicsDriver;
  static bool _noGraphicsDriver = false;

  /// Starts reading in the background (call once in main()).
  static Future<void> load() {
    if (kIsWeb || !Platform.isWindows) return Future<void>.value();
    return _loading ??= _read();
  }

  /// [summary], waiting up to [max] for it the first time.
  static Future<String> summaryWithin(Duration max) async {
    if (_summary.isNotEmpty || kIsWeb || !Platform.isWindows) return _summary;
    try {
      await load().timeout(max);
    } catch (_) {}
    return _summary;
  }

  static Future<void> _read() async {
    final List<String> parts = <String>[];
    String cpu = '';
    String cpuFlags = '';
    String cores = '';
    String ram = '';
    try {
      final Map<Object?, Object?>? m =
          await _channel.invokeMapMethod<Object?, Object?>('cpuInfo').timeout(const Duration(seconds: 3));
      if (m != null) {
        cpu = '${m['cpu'] ?? ''}'.trim().replaceAll(RegExp(r'\s+'), ' ');
        final bool bmi2 = m['bmi2'] == true;
        final bool avx2 = m['avx2'] == true;
        _oldCpu = !bmi2;
        cpuFlags = bmi2 ? (avx2 ? 'AVX2+BMI2' : 'BMI2') : 'OLD CPU (no BMI2)';
        final Object? c = m['cores'];
        if (c is int && c > 0) cores = '$c cores';
        final Object? r = m['ram_gb'];
        if (r is num && r > 0) ram = '${r.toStringAsFixed(1)} GB RAM';
      }
    } catch (_) {}

    String os = '';
    String gpu = '';
    try {
      const String script = r"$o = Get-CimInstance Win32_OperatingSystem; "
          r"$g = (Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join ' + '; "
          r"$o.Caption + ' (' + $o.BuildNumber + ')'; $g";
      final ProcessResult res = await Process.run(
        'powershell',
        <String>['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-Command', script],
      ).timeout(const Duration(seconds: 15));
      final List<String> lines = '${res.stdout}'
          .split(RegExp(r'\r?\n'))
          .map((String l) => l.trim())
          .where((String l) => l.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) os = lines[0].replaceFirst('Microsoft ', '');
      if (lines.length > 1) gpu = lines[1];
    } catch (_) {}
    _noGraphicsDriver = gpu.isNotEmpty &&
        gpu.split(' + ').every((String g) => RegExp('basic (display|render)', caseSensitive: false).hasMatch(g));

    for (final String p in <String>[os, cpu, cpuFlags, cores, ram, gpu]) {
      if (p.isNotEmpty) parts.add(p);
    }
    _summary = parts.join(' · ');
  }
}

/// How strong a PC is, read from its [DeviceSpecs.summary] (06/11/2026), so
/// the admins see at a glance which devices are likely to have trouble.
///   * LOW  — an OLD CPU (no BMI2: Firebase's crash risk), 2 cores or fewer,
///            or under 4 GB RAM.
///   * OK   — 4–7.9 GB RAM, or 3 cores.
///   * GOOD — newer CPU, 4+ cores and 8+ GB RAM.
enum PcLevel { low, ok, good, unknown }

class PcRating {
  const PcRating(this.level, this.reasons);

  /// Rates [specs]. Works on summaries already saved by older versions too.
  factory PcRating.of(String specs) {
    if (specs.trim().isEmpty) return const PcRating(PcLevel.unknown, <String>[]);
    final List<String> low = <String>[];
    final List<String> ok = <String>[];
    if (specs.contains('OLD CPU')) low.add('old CPU (crash risk)');
    if (RegExp('Basic (Display|Render)').hasMatch(specs)) low.add('no graphics driver');
    final int? cores = int.tryParse(RegExp(r'(\d+) cores').firstMatch(specs)?.group(1) ?? '');
    final double? ram = double.tryParse(RegExp(r'([\d.]+) GB RAM').firstMatch(specs)?.group(1) ?? '');
    if (cores != null) {
      if (cores <= 2) {
        low.add('$cores cores');
      } else if (cores < 4) {
        ok.add('$cores cores');
      }
    }
    if (ram != null) {
      if (ram < 3.8) {
        low.add('${ram.toStringAsFixed(1)} GB RAM');
      } else if (ram < 7.5) {
        ok.add('${ram.toStringAsFixed(1)} GB RAM');
      }
    }
    if (low.isNotEmpty) return PcRating(PcLevel.low, low);
    if (ok.isNotEmpty) return PcRating(PcLevel.ok, ok);
    return const PcRating(PcLevel.good, <String>[]);
  }

  final PcLevel level;
  final List<String> reasons;

  bool get isKnown => level != PcLevel.unknown;

  /// "LOW DEVICE", "OK DEVICE", "GOOD DEVICE".
  String get label => switch (level) {
        PcLevel.low => 'LOW DEVICE',
        PcLevel.ok => 'OK DEVICE',
        PcLevel.good => 'GOOD DEVICE',
        PcLevel.unknown => '',
      };

  /// "LOW DEVICE — old CPU (crash risk), 4 GB RAM".
  String get text => reasons.isEmpty ? label : '$label — ${reasons.join(', ')}';
}

/// LOW = red, OK = orange, GOOD = green.
Color pcRatingColor(PcLevel level) => switch (level) {
      PcLevel.low => AppColors.red,
      PcLevel.ok => AppColors.statusPending,
      PcLevel.good => AppColors.statusApproved,
      PcLevel.unknown => AppColors.secondaryText,
    };
