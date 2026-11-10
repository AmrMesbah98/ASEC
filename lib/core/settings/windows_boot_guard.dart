/// Module: core/settings
///
///*************************** FILE INFO ****************************///
/// File Name: windows_boot_guard.dart
/// Purpose: Declares `WindowsBootGuard` — keeps ASEC opening on Windows
///          after a crash, a force-close or a PC that switched off while the
///          app was open (the "white screen, then it closes" PCs).
/// Author: ASEC team (ported from ENGX)
/// Created: 05/11/2026
///
/// 1. BOOT JOURNAL. Each start step is written to
///    %LOCALAPPDATA%\ASEC\boot.txt BEFORE it runs, with plain file I/O
///    (no plugin, no GetStorage). If a start dies, the next one knows where.
/// 2. NATIVE CRASH. windows/runner/main.cpp writes the exception code and the
///    DLL that crashed to %LOCALAPPDATA%\ASEC\native_crash.txt. It is
///    reported once someone signs in (SessionController), then deleted.
/// 3. SELF-REPAIR, before anything reads it:
///    * GetStorage's file (AppData\<company>\<app>\GetStorage.gs) half-written when the PC
///      lost power is unreadable, and GetStorage.init() then fails on every
///      start. A broken file is set aside; GetStorage's own backup (.bak) or
///      the last good copy (saved after each good start) is put back.
///    * Two failed starts in a row inside Firebase → Firebase's local
///      heartbeat folder (usage counters only) is cleared. Three → the saved
///      Firebase sign-in on this PC is cleared too (sign in again — better
///      than an app that never opens).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

abstract final class WindowsBootGuard {
  const WindowsBootGuard._();

  static bool get active => !kIsWeb && Platform.isWindows;

  static Directory? _dir;
  static String _lastStep = '';
  static int _fails = 0;
  static int? _lastMs;
  static String _nativeCrash = '';
  static final List<String> _repairs = <String>[];

  /// The step the previous start died in ('' = it opened fine).
  static String get previousStep => _lastStep;

  static File? _file(String name) => _dir == null ? null : File('${_dir!.path}\\$name');

  /// FIRST line of main(), before any plugin, GetStorage or Firebase.
  static void begin() {
    if (!active) return;
    try {
      final String base = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'] ?? '';
      if (base.isEmpty) return;
      final Directory dir = Directory('$base\\ASEC');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _dir = dir;
      final File? journal = _file('boot.txt');
      if (journal != null && journal.existsSync()) {
        final List<String> parts = journal.readAsStringSync().trim().split('|');
        final String step = parts.isNotEmpty ? parts[0] : '';
        if (step.isNotEmpty && step != 'up') {
          _lastStep = step;
          _lastMs = parts.length > 1 ? int.tryParse(parts[1]) : null;
          _fails = (parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0) + 1;
        }
      }
      final File? crash = _file('native_crash.txt');
      if (crash != null && crash.existsSync()) {
        // Deleted once reported (report()).
        _nativeCrash = crash.readAsStringSync().trim();
      }
      _clearFirestoreCache();
      step('starting');
    } catch (_) {}
  }

  // ── OLD CPUs: Firestore's local database (06/11/2026) ────────────────────
  //
  // Firebase's Windows code compresses Firestore's local database (LevelDB)
  // with Snappy, which uses a CPU instruction (BMI2 `bzhi`) that Intel CPUs
  // before 2013 (Sandy / Ivy Bridge — e.g. "Intel HD Graphics 3000" laptops)
  // and older AMD CPUs do not have. The FIRST start after installing works
  // (no database yet); every later start reads the database and dies with
  // 0xc000001d (illegal instruction) in the .exe — a white window, then gone.
  // The app does not use that cache on Windows (it needs the internet), so
  // it is deleted at every start, BEFORE Firebase opens it.
  static void _clearFirestoreCache() {
    final String local = Platform.environment['LOCALAPPDATA'] ?? '';
    if (local.isEmpty) return;
    final Directory root = Directory('$local\\firestore');
    if (!root.existsSync()) return;
    void walk(Directory dir, int depth) {
      if (depth > 3) return;
      try {
        for (final FileSystemEntity e in dir.listSync(followLinks: false)) {
          if (e is! Directory) continue;
          final String name = e.path.split(RegExp(r'[\\/]')).last.toLowerCase();
          if (name.contains('asec-a811b')) {
            try {
              e.deleteSync(recursive: true);
            } catch (_) {}
          } else {
            walk(e, depth + 1);
          }
        }
      } catch (_) {}
    }
    walk(root, 0);
  }

  /// Notes the start step about to run.
  static void step(String name) {
    final File? journal = _file('boot.txt');
    if (journal == null) return;
    try {
      journal.writeAsStringSync('$name|${DateTime.now().millisecondsSinceEpoch}|$_fails', flush: true);
    } catch (_) {}
  }

  /// The first frame is on screen: this start worked.
  static Future<void> up() async {
    if (_dir == null) return;
    _fails = 0;
    step('up');
    await _backupStorage();
  }

  // ── GetStorage's file ────────────────────────────────────────────────────

  static Future<File?> _storageFile() async {
    try {
      final Directory d = await getApplicationSupportDirectory();
      return File('${d.path}\\GetStorage.gs');
    } catch (_) {
      return null;
    }
  }

  /// THIS APP'S OWN settings folder on Windows (06/11/2026). GetStorage's
  /// default is Documents\GetStorage.gs — the SAME file for ASEC and
  /// Eduneers (and OneDrive syncs Documents): on a PC with both, each app
  /// overwrote the other's settings. Now each keeps its file in its own
  /// AppData folder; the old file is copied over once. Null = not Windows.
  /// Call BEFORE [repairStorage] and GetStorage.init().
  static Future<String?> storagePath() async {
    if (!active) return null;
    try {
      final Directory d = await getApplicationSupportDirectory();
      if (!d.existsSync()) d.createSync(recursive: true);
      final File own = File('${d.path}\\GetStorage.gs');
      if (!own.existsSync()) {
        final Directory docs = await getApplicationDocumentsDirectory();
        final File old = File('${docs.path}\\GetStorage.gs');
        if (old.existsSync() && _readable(old)) {
          old.copySync(own.path);
          _repairs.add('moved the saved settings to this app\'s own folder');
        }
      }
      return d.path;
    } catch (_) {
      return null;
    }
  }

  static bool _readable(File f) {
    try {
      final String text = f.readAsStringSync();
      if (text.trim().isEmpty) return true; // GetStorage treats empty as "nothing saved"
      if (text.contains('\u0000')) return false;
      return jsonDecode(text) is Map;
    } catch (_) {
      return false;
    }
  }

  /// Before GetStorage.init().
  static Future<void> repairStorage() async {
    if (!active) return;
    final File? f = await _storageFile();
    if (f == null || !f.existsSync() || _readable(f)) return;
    final String stamp = '${DateTime.now().millisecondsSinceEpoch}';
    final File bak = File(f.path.replaceAll(RegExp(r'\.gs$'), '.bak'));
    final File good = File('${f.path}.good');
    try {
      f.renameSync('${f.path}.broken-$stamp');
      if (bak.existsSync() && _readable(bak)) {
        bak.copySync(f.path);
        _repairs.add('saved settings were damaged — restored GetStorage\'s backup');
      } else if (good.existsSync() && _readable(good)) {
        good.copySync(f.path);
        if (bak.existsSync()) bak.renameSync('${bak.path}.broken-$stamp');
        _repairs.add('saved settings were damaged — restored the last good copy');
      } else {
        if (bak.existsSync()) bak.renameSync('${bak.path}.broken-$stamp');
        _repairs.add('saved settings were damaged — started with fresh settings');
      }
    } catch (_) {
      try {
        if (f.existsSync()) f.deleteSync();
        _repairs.add('saved settings were damaged — removed them');
      } catch (_) {}
    }
  }

  static Future<void> _backupStorage() async {
    final File? f = await _storageFile();
    if (f == null || !f.existsSync() || !_readable(f)) return;
    try {
      f.copySync('${f.path}.good');
    } catch (_) {}
  }

  // ── Firebase's local files ───────────────────────────────────────────────

  /// Before Firebase starts: clears what can make it die on every start.
  static Future<void> repairFirebase() async {
    if (!active) return;
    if (_lastStep != 'firebase' || _fails < 2) return;
    final String local = Platform.environment['LOCALAPPDATA'] ?? '';
    if (local.isNotEmpty) {
      try {
        final Directory hb = Directory('$local\\firebase-heartbeat');
        if (hb.existsSync()) {
          hb.deleteSync(recursive: true);
          _repairs.add('cleared Firebase heartbeat files');
        }
      } catch (_) {}
    }
    if (_fails >= 3) {
      // Firebase Auth keeps the signed-in user in Windows Credential Manager.
      try {
        final ProcessResult list = await Process.run('cmdkey', <String>['/list']);
        final List<String> targets = RegExp(r'Target:\s*(?:LegacyGeneric:target=)?(\S*firebase\S*)',
                caseSensitive: false)
            .allMatches('${list.stdout}')
            .map((RegExpMatch m) => m.group(1)!)
            .toList();
        for (final String t in targets) {
          await Process.run('cmdkey', <String>['/delete:$t']);
        }
        if (targets.isNotEmpty) _repairs.add('cleared the saved Firebase sign-in (${targets.length})');
      } catch (_) {}
    }
  }

  // ── what the report says ─────────────────────────────────────────────────

  /// A report for the super admin, or '' when there is nothing to say.
  /// Returns it once.
  static String takeReport() {
    if (_lastStep.isEmpty && _nativeCrash.isEmpty && _repairs.isEmpty) return '';
    final StringBuffer b = StringBuffer('Windows start check:');
    if (_lastStep.isNotEmpty) {
      final String when = _lastMs == null ? '' : ' at ${DateTime.fromMillisecondsSinceEpoch(_lastMs!)}';
      b.write('\n• The last start$when stopped DURING "$_lastStep" '
          '($_fails start${_fails == 1 ? '' : 's'} in a row did not open).');
    }
    if (_nativeCrash.isNotEmpty) b.write('\n• $_nativeCrash');
    for (final String r in _repairs) {
      b.write('\n• Repaired: $r');
    }
    try {
      final File? crash = _file('native_crash.txt');
      if (crash != null && crash.existsSync()) crash.deleteSync();
    } catch (_) {}
    _lastStep = '';
    _nativeCrash = '';
    _repairs.clear();
    return b.toString();
  }
}
