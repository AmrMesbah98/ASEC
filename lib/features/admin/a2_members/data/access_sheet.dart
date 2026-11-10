/// Module: admin / a2_members
///
///*************************** FILE INFO ****************************///
/// File Name: access_sheet.dart
/// Purpose: Declares `AccessSheet` — reads an Excel (.xlsx) or .csv sheet of
///          member emails and course names for Members → Upload Excel.
/// Author: ASEC team
/// Created: 2/11/2026
///
/// THE SHEET (first sheet of the workbook, or a .csv):
///   Email              | Course 1    | Course 2  | …
///   ahmed@gmail.com    | AutoCAD     | Revit MEP
///   sara@gmail.com     | HVAC Design, Fire Fighting
/// A header row is skipped. Courses one per column, or several in one cell
/// separated by commas / semicolons / new lines. `ALL` = every course. The
/// same email on several rows adds the courses together.
///
/// The .xlsx is read with `archive` (already used for the calculators'
/// Excel export) — a workbook is a zip of XML — so no extra package.

import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// One email and the courses it should get.
class AccessSheetRow {
  const AccessSheetRow({required this.email, required this.courses});

  final String email;
  final List<String> courses;

  bool get allCourses => courses.any(AccessSheet.isAllWord);
}

class AccessSheet {
  const AccessSheet({required this.rows, required this.problems, this.unreadable = false});

  final List<AccessSheetRow> rows;

  /// "7 · ahmed@gmail" — rows that were skipped (not an email / no course).
  final List<String> problems;

  /// The file could not be opened at all.
  final bool unreadable;

  static bool isAllWord(String course) {
    final String k = course.trim().toLowerCase();
    return k == 'all' || k == '*' || k == 'all courses' || k == 'الكل';
  }

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static AccessSheet parse(String fileName, Uint8List bytes) {
    final List<List<String>> cells;
    try {
      cells = fileName.toLowerCase().endsWith('.csv') ? _csv(bytes) : _xlsx(bytes);
    } catch (_) {
      return const AccessSheet(rows: <AccessSheetRow>[], problems: <String>[], unreadable: true);
    }

    final Map<String, List<String>> byEmail = <String, List<String>>{};
    final List<String> problems = <String>[];
    for (int r = 0; r < cells.length; r++) {
      final List<String> row = cells[r].map((String c) => c.trim()).toList();
      if (row.isEmpty || row.every((String c) => c.isEmpty)) continue;
      final String email = row.first.toLowerCase();
      if (!_email.hasMatch(email)) {
        final bool header = r == 0 || email.contains('mail') || email.contains('بريد');
        if (!header) problems.add('${r + 1} · ${row.first}');
        continue;
      }
      final List<String> courses = <String>[
        for (final String cell in row.skip(1))
          for (final String c in cell.split(RegExp(r'[,;\n،]')))
            if (c.trim().isNotEmpty) c.trim(),
      ];
      if (courses.isEmpty) {
        problems.add('${r + 1} · $email');
        continue;
      }
      final List<String> list = byEmail.putIfAbsent(email, () => <String>[]);
      for (final String c in courses) {
        if (!list.any((String x) => x.toLowerCase() == c.toLowerCase())) list.add(c);
      }
    }
    return AccessSheet(
      rows: <AccessSheetRow>[
        for (final MapEntry<String, List<String>> e in byEmail.entries)
          AccessSheetRow(email: e.key, courses: e.value),
      ],
      problems: problems,
    );
  }

  // ── .xlsx ────────────────────────────────────────────────────────────────

  static String _read(Archive zip, String name) {
    final ArchiveFile? f = zip.findFile(name);
    if (f == null) return '';
    return utf8.decode(f.content as List<int>, allowMalformed: true);
  }

  static String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (Match m) => String.fromCharCode(int.parse(m[1]!)))
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (Match m) => String.fromCharCode(int.parse(m[1]!, radix: 16)))
      .replaceAll('&amp;', '&');

  /// Every <t> inside one <si> / <is>, joined (rich text has several runs).
  static String _texts(String xml) => RegExp(r'<t(?:\s[^>]*)?>([\s\S]*?)</t>')
      .allMatches(xml)
      .map((Match m) => _unescape(m[1]!))
      .join();

  static int _column(String ref) {
    int n = 0;
    for (final int c in ref.codeUnits) {
      if (c < 65 || c > 90) break; // stop at the row digits
      n = n * 26 + (c - 64);
    }
    return n - 1;
  }

  static List<List<String>> _xlsx(Uint8List bytes) {
    final Archive zip = ZipDecoder().decodeBytes(bytes);

    final List<String> shared = <String>[
      for (final Match m in RegExp(r'<si>([\s\S]*?)</si>').allMatches(_read(zip, 'xl/sharedStrings.xml')))
        _texts(m[1]!),
    ];

    // The FIRST sheet in the workbook's order (not necessarily sheet1.xml).
    String path = 'xl/worksheets/sheet1.xml';
    final Match? first = RegExp(r'<sheet\s[^>]*r:id="([^"]+)"').firstMatch(_read(zip, 'xl/workbook.xml'));
    if (first != null) {
      final String rels = _read(zip, 'xl/_rels/workbook.xml.rels');
      final Match? target = RegExp('<Relationship\\s[^>]*Id="${RegExp.escape(first[1]!)}"[^>]*Target="([^"]+)"')
              .firstMatch(rels) ??
          RegExp('<Relationship\\s[^>]*Target="([^"]+)"[^>]*Id="${RegExp.escape(first[1]!)}"').firstMatch(rels);
      if (target != null) {
        final String t = target[1]!;
        path = t.startsWith('/') ? t.substring(1) : 'xl/$t';
      }
    }
    final String sheet = _read(zip, path);
    if (sheet.isEmpty) throw const FormatException('no sheet');

    final List<List<String>> rows = <List<String>>[];
    for (final Match row in RegExp(r'<row\b[^>]*>([\s\S]*?)</row>').allMatches(sheet)) {
      final List<String> out = <String>[];
      for (final Match c in RegExp(r'<c\b([^>]*?)(?:/>|>([\s\S]*?)</c>)').allMatches(row[1]!)) {
        final String attrs = c[1]!;
        final String body = c[2] ?? '';
        final String ref = RegExp(r'\br="([A-Z]+)\d+"').firstMatch(attrs)?[1] ?? '';
        final String type = RegExp(r'\bt="([^"]+)"').firstMatch(attrs)?[1] ?? '';
        String value;
        if (type == 'inlineStr') {
          value = _texts(body);
        } else {
          final String v = _unescape(RegExp(r'<v>([\s\S]*?)</v>').firstMatch(body)?[1] ?? '');
          value = type == 's' ? (int.tryParse(v) != null && int.parse(v) < shared.length ? shared[int.parse(v)] : '') : v;
        }
        final int col = ref.isEmpty ? out.length : _column(ref);
        while (out.length < col) {
          out.add('');
        }
        if (out.length == col) {
          out.add(value);
        } else {
          out[col] = value;
        }
      }
      rows.add(out);
    }
    return rows;
  }

  // ── .csv ─────────────────────────────────────────────────────────────────

  static List<List<String>> _csv(Uint8List bytes) {
    String text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    final List<String> lines = text.split(RegExp(r'\r?\n'));
    final String head = lines.firstWhere((String l) => l.trim().isNotEmpty, orElse: () => '');
    final String sep = ';'.allMatches(head).length > ','.allMatches(head).length ? ';' : ',';
    return <List<String>>[for (final String l in lines) _csvLine(l, sep)];
  }

  static List<String> _csvLine(String line, String sep) {
    final List<String> out = <String>[];
    final StringBuffer cell = StringBuffer();
    bool quoted = false;
    for (int i = 0; i < line.length; i++) {
      final String ch = line[i];
      if (ch == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == sep && !quoted) {
        out.add(cell.toString());
        cell.clear();
      } else {
        cell.write(ch);
      }
    }
    out.add(cell.toString());
    return out;
  }
}
