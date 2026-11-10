/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: office_reader.dart
/// Purpose: Declares `OfficeReader` — reads Excel (.xlsx), Word (.docx) and
///          PowerPoint (.pptx) files so the file viewer can show them INSIDE
///          the app. All three are zip files of XML, read with `archive` +
///          `xml` (already used by excel_access.dart) — no new package.
/// Author: ASEC team
/// Created: 08/11/2026
///
/// The old binary formats (.xls, .doc, .ppt) are not read here; they keep
/// the "Save to Downloads / Open with another app" card.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// One sheet of a workbook: its name and its cells, row by row.
class OfficeSheet {
  const OfficeSheet({required this.name, required this.rows, this.truncated = false});

  final String name;
  final List<List<String>> rows;

  /// True when the sheet had more rows / columns than the viewer shows.
  final bool truncated;

  int get columnCount =>
      rows.fold<int>(0, (int m, List<String> r) => r.length > m ? r.length : m);
}

/// One paragraph of a Word document.
class OfficeParagraph {
  const OfficeParagraph({required this.text, this.heading = 0, this.bullet = false});

  final String text;

  /// 0 = body text, 1 = title / heading 1, 2 = heading 2, 3 = smaller.
  final int heading;
  final bool bullet;
}

/// One slide of a presentation: its title and the rest of its text.
class OfficeSlide {
  const OfficeSlide({required this.number, required this.title, required this.lines});

  final int number;
  final String title;
  final List<String> lines;
}

abstract final class OfficeReader {
  const OfficeReader._();

  /// The viewer shows at most this many rows / columns of a sheet.
  static const int maxRows = 1000;
  static const int maxColumns = 60;

  /// Downloads [url] (a signed Cloudflare address or a Firebase URL).
  static Future<Uint8List> download(String url) async {
    debugPrint('🟡 [office] downloading $url');
    final http.Response r = await http.get(Uri.parse(url));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      debugPrint('🔴 [office] HTTP ${r.statusCode}');
      throw Exception('HTTP ${r.statusCode}');
    }
    debugPrint('🟢 [office] ${r.bodyBytes.length} bytes');
    return r.bodyBytes;
  }

  static Future<List<OfficeSheet>> excel(String url) async =>
      compute(_readExcel, await download(url));

  static Future<List<OfficeParagraph>> word(String url) async =>
      compute(_readWord, await download(url));

  static Future<List<OfficeSlide>> slides(String url) async =>
      compute(_readSlides, await download(url));

  // ── zip / xml helpers ─────────────────────────────────────────────────────

  static String _text(Archive zip, String name) {
    for (final ArchiveFile f in zip.files) {
      if (f.name == name) {
        final Uint8List bytes = f.readBytes() ?? Uint8List(0);
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
    return '';
  }

  /// Every element with local name [name], whatever its prefix (w:, a:, …).
  static Iterable<XmlElement> _all(XmlNode node, String name) =>
      node.findAllElements(name, namespace: '*');

  static String _attr(XmlElement e, String local) {
    for (final XmlAttribute a in e.attributes) {
      if (a.name.local == local) return a.value;
    }
    return '';
  }

  // ── Excel ─────────────────────────────────────────────────────────────────

  static int _column(String ref) {
    int n = 0;
    for (final int c in ref.codeUnits) {
      if (c < 65 || c > 90) break; // A–Z only
      n = n * 26 + (c - 64);
    }
    return n - 1;
  }

  static List<OfficeSheet> _readExcel(Uint8List bytes) {
    final Archive zip = ZipDecoder().decodeBytes(bytes);

    final List<String> shared = <String>[];
    final String sst = _text(zip, 'xl/sharedStrings.xml');
    if (sst.isNotEmpty) {
      for (final XmlElement si in _all(XmlDocument.parse(sst), 'si')) {
        shared.add(_all(si, 't').map((XmlElement t) => t.innerText).join());
      }
    }

    // Sheet name → its file, through the workbook's relationships.
    final Map<String, String> targets = <String, String>{};
    final String relsXml = _text(zip, 'xl/_rels/workbook.xml.rels');
    if (relsXml.isNotEmpty) {
      for (final XmlElement r in _all(XmlDocument.parse(relsXml), 'Relationship')) {
        final String t = r.getAttribute('Target') ?? '';
        targets[r.getAttribute('Id') ?? ''] = t.startsWith('/') ? t.substring(1) : 'xl/$t';
      }
    }
    final List<(String, String)> sheets = <(String, String)>[];
    final String wbXml = _text(zip, 'xl/workbook.xml');
    if (wbXml.isNotEmpty) {
      int i = 1;
      for (final XmlElement s in _all(XmlDocument.parse(wbXml), 'sheet')) {
        final String path = targets[_attr(s, 'id')] ?? 'xl/worksheets/sheet$i.xml';
        sheets.add((s.getAttribute('name') ?? 'Sheet $i', path));
        i++;
      }
    }
    if (sheets.isEmpty) sheets.add(('Sheet 1', 'xl/worksheets/sheet1.xml'));

    final List<OfficeSheet> out = <OfficeSheet>[];
    for (final (String name, String path) in sheets) {
      final String xml = _text(zip, path);
      if (xml.isEmpty) continue;
      final List<List<String>> rows = <List<String>>[];
      bool truncated = false;
      for (final XmlElement row in _all(XmlDocument.parse(xml), 'row')) {
        if (rows.length >= maxRows) {
          truncated = true;
          break;
        }
        // Keep blank rows where they are (row r="7" after r="3").
        final int number = int.tryParse(row.getAttribute('r') ?? '') ?? rows.length + 1;
        while (rows.length < number - 1 && rows.length < maxRows) {
          rows.add(<String>[]);
        }
        final List<String> cells = <String>[];
        int next = 0;
        for (final XmlElement c in row.findElements('c', namespace: '*')) {
          final String ref = c.getAttribute('r') ?? '';
          final int col = ref.isEmpty ? next : _column(ref);
          if (col >= maxColumns) {
            truncated = true;
            break;
          }
          while (cells.length < col) {
            cells.add('');
          }
          final String type = c.getAttribute('t') ?? '';
          String value;
          if (type == 'inlineStr') {
            value = _all(c, 't').map((XmlElement t) => t.innerText).join();
          } else {
            final String v = c.findElements('v', namespace: '*').firstOrNull?.innerText ?? '';
            if (type == 's') {
              final int k = int.tryParse(v) ?? -1;
              value = k >= 0 && k < shared.length ? shared[k] : '';
            } else if (type == 'b') {
              value = v == '1' ? 'TRUE' : 'FALSE';
            } else {
              value = _number(v);
            }
          }
          cells.add(value.trim());
          next = cells.length;
        }
        rows.add(cells);
      }
      // Drop trailing empty rows.
      while (rows.isNotEmpty && rows.last.every((String c) => c.isEmpty)) {
        rows.removeLast();
      }
      out.add(OfficeSheet(name: name, rows: rows, truncated: truncated));
    }
    return out;
  }

  /// "3.0000000000000004" → "3", keeps text as it is.
  static String _number(String v) {
    final double? d = double.tryParse(v);
    if (d == null) return v;
    if (d == d.roundToDouble() && d.abs() < 1e15) return d.toInt().toString();
    final String s = d.toStringAsFixed(6);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  // ── Word ──────────────────────────────────────────────────────────────────

  static List<OfficeParagraph> _readWord(Uint8List bytes) {
    final Archive zip = ZipDecoder().decodeBytes(bytes);
    final String xml = _text(zip, 'word/document.xml');
    if (xml.isEmpty) return const <OfficeParagraph>[];
    final List<OfficeParagraph> out = <OfficeParagraph>[];
    for (final XmlElement p in _all(XmlDocument.parse(xml), 'p')) {
      final String text = _all(p, 't').map((XmlElement t) => t.innerText).join();
      final XmlElement? style = _all(p, 'pStyle').firstOrNull;
      final String s = (style == null ? '' : _attr(style, 'val')).toLowerCase();
      int heading = 0;
      if (s.contains('title') || s.endsWith('heading1')) {
        heading = 1;
      } else if (s.contains('heading2')) {
        heading = 2;
      } else if (s.contains('heading')) {
        heading = 3;
      }
      final bool bullet = _all(p, 'numPr').isNotEmpty || s.contains('list');
      out.add(OfficeParagraph(text: text, heading: heading, bullet: bullet));
    }
    // No runs of empty lines.
    final List<OfficeParagraph> clean = <OfficeParagraph>[];
    for (final OfficeParagraph p in out) {
      if (p.text.trim().isEmpty && (clean.isEmpty || clean.last.text.trim().isEmpty)) continue;
      clean.add(p);
    }
    return clean;
  }

  // ── PowerPoint ────────────────────────────────────────────────────────────

  static List<OfficeSlide> _readSlides(Uint8List bytes) {
    final Archive zip = ZipDecoder().decodeBytes(bytes);
    final RegExp slideFile = RegExp(r'^ppt/slides/slide(\d+)\.xml$');
    final List<(int, ArchiveFile)> files = <(int, ArchiveFile)>[
      for (final ArchiveFile f in zip.files)
        if (slideFile.hasMatch(f.name)) (int.parse(slideFile.firstMatch(f.name)!.group(1)!), f),
    ]..sort(((int, ArchiveFile) a, (int, ArchiveFile) b) => a.$1.compareTo(b.$1));

    final List<OfficeSlide> out = <OfficeSlide>[];
    for (final (int n, ArchiveFile f) in files) {
      final XmlDocument doc =
          XmlDocument.parse(utf8.decode(f.readBytes() ?? Uint8List(0), allowMalformed: true));
      String title = '';
      final List<String> lines = <String>[];
      for (final XmlElement sp in _all(doc, 'sp')) {
        final XmlElement? ph = _all(sp, 'ph').firstOrNull;
        final String phType = ph?.getAttribute('type') ?? '';
        final bool isTitle = phType == 'title' || phType == 'ctrTitle';
        for (final XmlElement para in _all(sp, 'p')) {
          final String t = _all(para, 't').map((XmlElement e) => e.innerText).join().trim();
          if (t.isEmpty) continue;
          if (isTitle && title.isEmpty) {
            title = t;
          } else {
            lines.add(t);
          }
        }
      }
      if (title.isEmpty && lines.isNotEmpty) title = lines.removeAt(0);
      out.add(OfficeSlide(number: n, title: title, lines: lines));
    }
    return out;
  }
}
