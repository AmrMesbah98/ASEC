/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: error_report_pdf.dart
/// Purpose: Settings → Error reports → Export PDF (ported from ENGX
///          v1.0.53 / v1.0.72, 10/11/2026).
///
/// 08/11/2026 — made easy to read:
///   1. In short: how many reports, members and devices, and how many come
///      from an OLD app version (those need the update, not a fix).
///   2. What went wrong: every report sorted into a plain-words problem,
///      with what it means and what to do.
///   3. Members with errors: one line per member (a crash report that only
///      knows the device is matched to the member who used that device),
///      most errors first — how many, the main problem, last time, version.
///   4. Members with no errors: every member account with no report.
///   5. Every report: a plain-words line on top, the technical detail below.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:asec/core/settings/device_specs.dart';
import 'package:asec/core/settings/error_reports.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';

/// One plain-words problem: what it is, what it means, what to do.
class _Problem {
  const _Problem(this.title, this.meaning, this.action);
  final String title;
  final String meaning;
  final String action;
}

/// A member (or an unknown device) and their reports.
class _Person {
  _Person(this.name, this.email);
  String name;
  String email;
  final List<ErrorReport> reports = <ErrorReport>[];
  final Set<String> devices = <String>{};
  final Set<String> versions = <String>{};
}

abstract final class ErrorReportPdf {
  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _date(DateTime? d) => d == null
      ? '—'
      : '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

  /// The PDF font has no arrows: "Task Manager → ASEC" printed as
  /// "Task Manager > ASEC".
  static String _clean(String s) => s.replaceAll('→', '>').replaceAll('←', '<').replaceAll('×', 'x');

  /// The build number of a version like "1.0.71+171" (0 = unknown).
  static int _build(String v) => int.tryParse(v.split('+').last) ?? 0;

  // ── plain words ───────────────────────────────────────────────────────────

  static const _Problem _blocked = _Problem(
    'Lesson blocked by the member\'s network (firewall)',
    'The lesson server was reached, but a firewall answered instead of it (a fake certificate: '
        '"self signed" / "Hostname mismatch"). Usually a company or university network, or the internet provider.',
    'Ask the member to try another connection (mobile hotspot / home internet). '
        'A brand-new domain is often blocked for its first weeks.',
  );
  static const _Problem _dns = _Problem(
    'Lesson server not found on the member\'s internet',
    'The member\'s internet could not find the lesson servers by name (DNS blocked), '
        'and the backup lookup failed too.',
    'Ask the member to try another connection or another DNS (8.8.8.8 / 1.1.1.1) and send a new report.',
  );
  static const _Problem _offline = _Problem(
    'No internet on the member\'s device',
    'Not even Google\'s or Cloudflare\'s DNS answered (network unreachable) — the device was offline or its '
        'connection had dropped when the lesson was opened. Not a problem with the lesson server.',
    'Nothing to fix on our side. If it repeats while the member is online, ask them to try another connection.',
  );
  static const _Problem _decoder = _Problem(
    'Video decoder failed on this PC',
    '"Could not open codec": the graphics card could not decode the lesson — usually no graphics driver '
        '("Microsoft Basic Display Adapter"), a virtual machine or Remote Desktop.',
    'From 1.0.34 the app switches that PC to CPU decoding by itself. Older versions: update. '
        'Best: install the PC\'s graphics driver (Windows Update or the Intel / AMD / NVIDIA site).',
  );
  static const _Problem _softened = _Problem(
    'PC switched to CPU video decoding (no action)',
    'A lesson failed in the graphics card, so the app now decodes lessons on the CPU on this PC.',
    'Nothing to do. If the PC shows "no graphics driver", the member should install it.',
  );
  static const _Problem _noAnswer = _Problem(
    'Lesson server did not answer',
    'The app asked the lesson server and got no answer in time — slow or unstable internet, or a firewall.',
    'Usually the member\'s connection. If many members get it at the same time, check Cloudflare.',
  );
  static const _Problem _slow = _Problem(
    'Lesson started, then froze while loading',
    'The server answered and the first bytes came, then the connection went silent and the player gave up.',
    'The app now picks the stream up again by itself (since 1.0.35). Older versions: update.',
  );
  static const _Problem _intercepted = _Problem(
    'Antivirus / VPN is reading the app\'s secure connections',
    'Something on the PC (antivirus "HTTPS scanning", VPN, proxy) decrypts ASEC\'s traffic, so lessons are refused.',
    'Ask the member to turn off HTTPS / web scanning or add ASEC as an exception.',
  );
  static const _Problem _missing = _Problem(
    'Lesson missing on the server',
    'The server answered, but this lesson file is not there (or not allowed).',
    'Settings > Cloudflare lessons > Copy lessons, then check the lesson.',
  );
  static const _Problem _geolocator = _Problem(
    'App crashed (location plugin)',
    'Windows crash inside geolocator_windows_plugin.dll.',
    'Ask the member to update to the newest version.',
  );
  static const _Problem _openClosed = _Problem(
    'App closed while opening',
    'The app stopped before it finished opening — a crash on start, or it was closed / killed (e.g. by an installer).',
    'If it repeats for the same member, look for a "Windows start check" report from the same device.',
  );
  static const _Problem _lessonClosed = _Problem(
    'App closed during a lesson',
    'The app stopped while a lesson was playing — the video player crashed, or ASEC was ended / the PC lost power.',
    'If it repeats, look for a "Windows start check" report naming the crashed file.',
  );
  static const _Problem _repaired = _Problem(
    'Settings file repaired (no action)',
    'The app found its settings file damaged and restored the last good copy by itself.',
    'Nothing to do.',
  );

  /// The plain-words problem behind [r].
  static _Problem _problemOf(ErrorReport r) {
    final String m = '${r.message}\n${r.stack}';
    if (m.contains('Switched this PC to')) return _softened;
    if (RegExp('could not open codec|decoding frame|initialize a decoder', caseSensitive: false).hasMatch(m)) {
      return _decoder;
    }
    if (m.contains('CERTIFICATE_VERIFY_FAILED') || m.contains('network is blocking ASEC')) return _blocked;
    if (m.contains('checking ASEC\'s secure connections') || m.contains('intercepted')) return _intercepted;
    if (m.contains('offline:') || _looksOffline(m)) return _offline;
    if (m.contains('host lookup') || m.contains('name not found')) return _dns;
    if (m.contains('did not start')) {
      final int bytes = int.tryParse(RegExp(r'bytes received: (\d+)').firstMatch(m)?.group(1) ?? '') ?? 0;
      if (m.contains('not available right now') || m.contains('could not be loaded right now')) return _missing;
      if (bytes > 0 || m.contains('taking too long')) return _slow;
      return _noAnswer;
    }
    if (m.contains('geolocator')) return _geolocator;
    final String module = RegExp(r'In module: ([^\s+]+)').firstMatch(m)?.group(1) ?? '';
    if (module.isNotEmpty) {
      return _Problem(
        'App crashed (in $module)',
        'Windows reported a crash inside $module.',
        'Send this report for fixing — it names the file that crashed.',
      );
    }
    if (m.contains('closed before it finished opening')) return _openClosed;
    if (m.startsWith('Windows start check:')) {
      final String step = RegExp(r'stopped DURING "([^"]+)"').firstMatch(m)?.group(1) ?? '';
      return _Problem(
        step.isEmpty ? 'Windows start check' : 'App did not finish opening (stopped at "$step")',
        'The previous start of the app on this PC stopped before the first screen. The app repairs '
            'itself after repeated failures (settings file, Firebase sign-in).',
        'Nothing to do if it happened once. If it repeats, look at the "WINDOWS SAYS" report from the same device.',
      );
    }
    if (m.contains('WINDOWS SAYS')) {
      final String code = RegExp(r'Exception code: (0x[0-9a-fA-F]+)').firstMatch(m)?.group(1)?.toLowerCase() ?? '';
      final String what = switch (code) {
        '0xc00000fd' => 'stack overflow',
        '0xc0000005' => 'memory access violation',
        '0xc000001d' => 'illegal CPU instruction (old CPU)',
        '0xc0000409' => 'fail-fast / buffer overrun',
        _ => '',
      };
      final String module = RegExp(r'Faulting module name: ([^,\s]+)').firstMatch(m)?.group(1) ?? '';
      return _Problem(
        'App crashed${what.isEmpty ? '' : ' ($what)'}${module.isEmpty ? '' : ' in $module'}${code.isEmpty ? '' : ' [$code]'}',
        'Windows recorded a crash of the app (Event 1000).',
        'Check the PC line (old CPU / no graphics driver) and the app version. If it is an old version: update.',
      );
    }
    final RegExpMatch? during = RegExp(r'closed unexpectedly DURING: (.+?) at \d{4}-').firstMatch(m);
    if (during != null) {
      return _Problem(
        'App closed during "${during.group(1)}"',
        'The app stopped while doing this step — a crash, or it was ended / the PC lost power.',
        'If it repeats on the same device, look for a "WINDOWS SAYS" report from it.',
      );
    }
    if (m.contains('WHILE A LESSON WAS PLAYING')) return _lessonClosed;
    if (m.contains('Repaired') && m.contains('settings file')) return _repaired;
    final String first = _clean(r.message.split('\n').first.trim());
    return _Problem(
      first.length > 90 ? '${first.substring(0, 90)}…' : (first.isEmpty ? r.errorType : first),
      'Kind: ${r.source}${r.errorType.isEmpty ? '' : ' · ${r.errorType}'}${r.code.isEmpty ? '' : ' [${r.code}]'}.',
      'See the full report below.',
    );
  }

  /// The device was offline: the lesson host's name was not found and not
  /// even DNS by IP address could be reached (see SecureVideoServer).
  static bool _looksOffline(String m) =>
      (m.contains('DNS over HTTPS failed too') || m.contains('name not found by the device DNS')) &&
      RegExp(r'Network is unreachable|was disallowed because|No route to host').hasMatch(m) &&
      !m.contains('CERTIFICATE_VERIFY_FAILED');

  // ── who ───────────────────────────────────────────────────────────────────

  /// Groups [reports] by member. A report without a member (a crash on
  /// start) goes to the member seen on the same device, else to "Device …".
  static List<_Person> _people(List<ErrorReport> reports, List<AppUser> members) {
    final Map<String, AppUser> byUid = <String, AppUser>{for (final AppUser a in members) a.uid: a};
    final Map<String, String> deviceOwner = <String, String>{};
    for (final ErrorReport r in reports) {
      final String k = _memberKey(r);
      if (k.isNotEmpty && r.deviceId.isNotEmpty) deviceOwner.putIfAbsent(r.deviceId, () => k);
    }
    final Map<String, _Person> out = <String, _Person>{};
    for (final ErrorReport r in reports) {
      String key = _memberKey(r);
      if (key.isEmpty) key = deviceOwner[r.deviceId] ?? '';
      if (key.isEmpty) key = 'device:${r.deviceId.isEmpty ? '?' : r.deviceId}';
      final _Person p = out.putIfAbsent(key, () {
        if (key.startsWith('device:')) {
          final String d = key.substring(7);
          return _Person('Unknown member — device ${d.length > 8 ? d.substring(0, 8) : d}', '');
        }
        final AppUser? a = byUid[r.uid];
        return _Person(a?.displayName ?? '', a?.email ?? '');
      });
      if (p.name.isEmpty && r.userName.isNotEmpty) p.name = r.userName;
      if (p.email.isEmpty && r.email.isNotEmpty) p.email = r.email;
      p.reports.add(r);
      if (r.deviceId.isNotEmpty) p.devices.add(r.deviceId);
      if (r.appVersion.isNotEmpty) p.versions.add(r.appVersion);
    }
    for (final _Person p in out.values) {
      if (p.name.isEmpty) p.name = p.email.isEmpty ? 'Unknown member' : p.email.split('@').first;
    }
    return out.values.toList()..sort((_Person a, _Person b) => b.reports.length.compareTo(a.reports.length));
  }

  static String _memberKey(ErrorReport r) {
    if (r.uid.isNotEmpty) return 'uid:${r.uid}';
    if (r.email.isNotEmpty) return 'email:${r.email.toLowerCase()}';
    return '';
  }

  // ── the PDF ───────────────────────────────────────────────────────────────

  /// [members]: every member account — for "Members with no errors" and
  /// for names on reports that only carry the account id.
  static Future<Uint8List> build(List<ErrorReport> reports, {List<AppUser> members = const <AppUser>[]}) async {
    final pw.Font regular = pw.Font.ttf(await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Regular.ttf'));
    final pw.Font bold = pw.Font.ttf(await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Bold.ttf'));
    final pw.ThemeData theme = pw.ThemeData.withFont(base: regular, bold: bold);

    const PdfColor navy = PdfColor.fromInt(0xFF2B4380);
    const PdfColor red = PdfColor.fromInt(0xFFD64545);
    const PdfColor green = PdfColor.fromInt(0xFF2E8B57);
    const PdfColor orange = PdfColor.fromInt(0xFFD9822B);
    const PdfColor grey = PdfColor.fromInt(0xFF5B6675);
    const PdfColor line = PdfColor.fromInt(0xFFD9DEE7);
    const PdfColor soft = PdfColor.fromInt(0xFFF5F7FA);

    // Newest version seen — anything older is "old version, needs update".
    int newest = 0;
    for (final ErrorReport r in reports) {
      final int b = _build(r.appVersion);
      if (b > newest) newest = b;
    }
    bool old(ErrorReport r) => _build(r.appVersion) > 0 && _build(r.appVersion) < newest;
    final String newestName = reports
        .map((ErrorReport r) => r.appVersion)
        .firstWhere((String v) => _build(v) == newest, orElse: () => '');

    // Problems, most reports first.
    final Map<String, _Problem> problems = <String, _Problem>{};
    final Map<String, List<ErrorReport>> byProblem = <String, List<ErrorReport>>{};
    for (final ErrorReport r in reports) {
      final _Problem p = _problemOf(r);
      problems[p.title] = p;
      (byProblem[p.title] ??= <ErrorReport>[]).add(r);
    }
    final List<String> problemOrder = byProblem.keys.toList()
      ..sort((String a, String b) => byProblem[b]!.length.compareTo(byProblem[a]!.length));

    final List<_Person> people = _people(reports, members);
    final Map<ErrorReport, _Person> personOf = <ErrorReport, _Person>{
      for (final _Person p in people)
        for (final ErrorReport r in p.reports) r: p,
    };
    int peopleFor(List<ErrorReport> rs) => rs.map((ErrorReport r) => personOf[r]).toSet().length;

    // Members with no report at all (admins left out).
    final Set<String> reportedUids = <String>{for (final ErrorReport r in reports) if (r.uid.isNotEmpty) r.uid};
    final Set<String> reportedEmails = <String>{
      for (final ErrorReport r in reports)
        if (r.email.isNotEmpty) r.email.toLowerCase(),
      for (final _Person p in people)
        if (p.email.isNotEmpty) p.email.toLowerCase(),
    };
    final List<AppUser> clean = members
        .where((AppUser a) =>
            !a.isAdmin && !reportedUids.contains(a.uid) && !(a.email.isNotEmpty && reportedEmails.contains(a.email)))
        .toList()
      ..sort((AppUser a, AppUser b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    final int oldCount = reports.where(old).length;
    final Set<String> devices = <String>{for (final ErrorReport r in reports) if (r.deviceId.isNotEmpty) r.deviceId};

    pw.Widget cell(String text, {bool head = false, PdfColor? color, bool strong = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: pw.Text(_clean(text),
              style: pw.TextStyle(
                fontSize: head ? 8 : 7.5,
                fontWeight: head || strong ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: head ? PdfColors.white : (color ?? PdfColors.black),
              )),
        );

    pw.Widget title(String t, {String? note}) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(t, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: navy)),
              if (note != null) pw.Text(note, style: const pw.TextStyle(fontSize: 8, color: grey)),
            ],
          ),
        );

    pw.Widget table(Map<int, pw.TableColumnWidth> widths, List<String> head, List<List<pw.Widget>> rows) => pw.Table(
          border: pw.TableBorder.all(color: line, width: 0.5),
          columnWidths: widths,
          children: <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: navy),
              children: <pw.Widget>[for (final String h in head) cell(h, head: true)],
            ),
            for (int i = 0; i < rows.length; i++)
              pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isOdd ? soft : PdfColors.white),
                children: rows[i],
              ),
          ],
        );

    pw.Widget stat(String value, String label, PdfColor color) => pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 6),
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(color: soft),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(value, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: color)),
                pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: grey)),
              ],
            ),
          ),
        );

    String stackTop(String stack) {
      final List<String> lines = stack.split('\n');
      return lines.length <= 25 ? stack : '${lines.take(25).join('\n')}\n… (${lines.length - 25} more lines)';
    }

    String mainProblem(_Person p) {
      final Map<String, int> m = <String, int>{};
      for (final ErrorReport r in p.reports) {
        final String t = _problemOf(r).title;
        m[t] = (m[t] ?? 0) + 1;
      }
      final List<MapEntry<String, int>> e = m.entries.toList()
        ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
      return e.length == 1 ? e.first.key : '${e.first.key} (+${e.length - 1} other kind${e.length == 2 ? '' : 's'})';
    }

    final DateTime now = DateTime.now();
    final pw.Document doc = pw.Document(title: 'ASEC error reports', author: 'ASEC');
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        header: (pw.Context c) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 6),
          margin: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: navy, width: 1.2))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text('ASEC · Error reports', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: navy)),
              pw.Text('Generated ${_date(now)} · page ${c.pageNumber}/${c.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: grey)),
            ],
          ),
        ),
        build: (pw.Context c) => <pw.Widget>[
          // 1 ── In short
          title('1. In short',
              note: reports.isEmpty ? null : 'From ${_date(reports.last.at)} to ${_date(reports.first.at)}.'),
          pw.Row(children: <pw.Widget>[
            stat('${reports.length}', 'error reports', red),
            stat('${people.length}', 'members with errors', orange),
            stat('${clean.length}', 'members with no errors', green),
            stat('${devices.length}', 'devices', navy),
          ]),
          pw.SizedBox(height: 6),
          if (oldCount > 0)
            pw.Text(
              '$oldCount of ${reports.length} reports come from an OLD app version (older than $newestName). '
              'Those members need to update — raise the minimum version in Settings > App update to force it.',
              style: const pw.TextStyle(fontSize: 8.5, color: orange),
            ),
          pw.SizedBox(height: 8),

          // 2 ── What went wrong
          if (reports.isNotEmpty) ...<pw.Widget>[
            title('2. What went wrong', note: 'Each report sorted into one problem — most reports first.'),
            table(
              const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(3),
                1: pw.FixedColumnWidth(34),
                2: pw.FixedColumnWidth(42),
                3: pw.FlexColumnWidth(4),
                4: pw.FlexColumnWidth(4),
              },
              <String>['Problem', 'Reports', 'Members', 'What it means', 'What to do'],
              <List<pw.Widget>>[
                for (final String t in problemOrder)
                  <pw.Widget>[
                    cell(t, strong: true, color: red),
                    cell('${byProblem[t]!.length}'),
                    cell('${peopleFor(byProblem[t]!)}'),
                    cell(problems[t]!.meaning),
                    cell(problems[t]!.action, color: green),
                  ],
              ],
            ),
            pw.SizedBox(height: 10),

            // 3 ── Members with errors
            title('3. Members with errors',
                note: 'Most errors first. "Old version" = the member is not on $newestName yet.'),
            table(
              const <int, pw.TableColumnWidth>{
                0: pw.FixedColumnWidth(18),
                1: pw.FlexColumnWidth(3),
                2: pw.FixedColumnWidth(32),
                3: pw.FlexColumnWidth(4),
                4: pw.FixedColumnWidth(66),
                5: pw.FlexColumnWidth(2),
              },
              <String>['#', 'Member', 'Errors', 'Main problem', 'Last error', 'App version'],
              <List<pw.Widget>>[
                for (int i = 0; i < people.length; i++)
                  <pw.Widget>[
                    cell('${i + 1}'),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: <pw.Widget>[
                          pw.Text(people[i].name, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                          if (people[i].email.isNotEmpty)
                            pw.Text(people[i].email, style: const pw.TextStyle(fontSize: 6.5, color: grey)),
                          if (people[i].devices.length > 1)
                            pw.Text('${people[i].devices.length} devices', style: const pw.TextStyle(fontSize: 6.5, color: grey)),
                        ],
                      ),
                    ),
                    cell('${people[i].reports.length}',
                        strong: true, color: people[i].reports.length > 1 ? red : PdfColors.black),
                    cell(mainProblem(people[i])),
                    cell(_date(people[i].reports.first.at)),
                    cell(
                      '${people[i].versions.join(', ')}${people[i].reports.every(old) ? ' (old version)' : ''}',
                      color: people[i].reports.every(old) ? orange : PdfColors.black,
                    ),
                  ],
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // 4 ── Members with no errors
          title('4. Members with no errors (${clean.length})',
              note: members.isEmpty
                  ? 'The member list could not be read.'
                  : 'Member accounts with no error report in this period.'),
          if (clean.isNotEmpty)
            table(
              const <int, pw.TableColumnWidth>{
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(4),
                3: pw.FixedColumnWidth(50),
              },
              <String>['#', 'Member', 'Email', 'Account'],
              <List<pw.Widget>>[
                for (int i = 0; i < clean.length; i++)
                  <pw.Widget>[
                    cell('${i + 1}'),
                    cell(clean[i].displayName),
                    cell(clean[i].email),
                    cell(clean[i].active ? 'active' : 'blocked', color: clean[i].active ? green : grey),
                  ],
              ],
            ),
          pw.SizedBox(height: 10),

          // 5 ── Every report
          if (reports.isNotEmpty)
            title('5. Every report', note: 'Plain words first (bold), technical detail below (for fixing).'),
          for (int i = 0; i < reports.length; i++)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(7),
              decoration: pw.BoxDecoration(
                color: i.isOdd ? soft : PdfColors.white,
                border: pw.Border.all(color: line, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('#${i + 1}  ·  ${_problemOf(reports[i]).title}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: red)),
                  pw.Text(
                    '${_date(reports[i].at)}  ·  ${personOf[reports[i]]?.name ?? (reports[i].userName.isNotEmpty ? reports[i].userName : reports[i].email)}'
                    '${(personOf[reports[i]]?.email ?? '').isEmpty ? '' : ' · ${personOf[reports[i]]!.email}'}'
                    '  ·  v${reports[i].appVersion}${old(reports[i]) ? ' (old version)' : ''}',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: navy),
                  ),
                  pw.Text('What to do: ${_clean(_problemOf(reports[i]).action)}',
                      style: const pw.TextStyle(fontSize: 7.5, color: green)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Detail · ${reports[i].source} · ${reports[i].errorType}${reports[i].code.isEmpty ? '' : ' [${reports[i].code}]'}'
                    ' · ${reports[i].platform} · device ${reports[i].deviceId}',
                    style: const pw.TextStyle(fontSize: 7, color: grey),
                  ),
                  if (reports[i].specs.isNotEmpty)
                    pw.Text('PC: ${PcRating.of(reports[i].specs).text} — ${reports[i].specs}',
                        style: const pw.TextStyle(fontSize: 7, color: grey)),
                  if (reports[i].page.isNotEmpty)
                    pw.Text('Where: ${reports[i].page}', style: const pw.TextStyle(fontSize: 7, color: grey)),
                  pw.SizedBox(height: 2),
                  pw.Text(_clean(reports[i].message), style: const pw.TextStyle(fontSize: 7.5)),
                  if (reports[i].stack.trim().isNotEmpty) ...<pw.Widget>[
                    pw.SizedBox(height: 3),
                    pw.Text(_clean(stackTop(reports[i].stack)), style: const pw.TextStyle(fontSize: 6.5, color: grey)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  /// Builds it and opens the save / share sheet.
  static Future<void> share(List<ErrorReport> reports, {List<AppUser> members = const <AppUser>[]}) async {
    final Uint8List bytes = await build(reports, members: members);
    final DateTime n = DateTime.now();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'ASEC-error-reports-${n.year}-${_two(n.month)}-${_two(n.day)}.pdf',
    );
  }
}
