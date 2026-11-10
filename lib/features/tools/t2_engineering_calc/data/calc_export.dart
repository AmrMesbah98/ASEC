/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calc_export.dart
/// Purpose: Declares `CalcReport` (one filled-in calculator, ready to
///          print) and `CalcExport` — turns it into a PDF or an Excel
///          (.xlsx) file and saves it where the user chooses.
/// Author: ASEC team
/// Created: 4/10/2026
///
/// PDF  — the `pdf` package, Cairo font (Latin + Arabic, like the
///        certificate).
/// XLSX — written by hand: an .xlsx is a zip of a few XML files, so the
///        `archive` package is all it takes (no spreadsheet package, no
///        version clash). Numbers go in as real numbers so the engineer can
///        keep calculating in Excel.
///
/// Both are SAVED, not shared: the system "Save as" dialog (name + folder,
/// starting in Downloads) — see file_saver.dart.
///
/// Both files are laid out right-to-left when the app is in Arabic.

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:asec/features/tools/t2_engineering_calc/data/file_saver.dart';

/// One line of the report: an input or a result.
class CalcRow {
  const CalcRow({
    required this.label,
    required this.text,
    this.number,
    this.unit = '',
    this.primary = false,
  });

  final String label;

  /// What the screen shows, unit included ("12.5 kW", "DN 100 (4\")").
  final String text;

  /// The bare number for Excel — null for text answers (pipe sizes, choices).
  final double? number;
  final String unit;
  final bool primary;
}

class CalcReport {
  const CalcReport({
    required this.id,
    required this.title,
    required this.discipline,
    required this.arabic,
    required this.inputs,
    required this.results,
    required this.formula,
    required this.note,
    required this.labels,
    this.extraTitle = '',
    this.extraHeaders = const <String>[],
    this.extraRows = const <List<String>>[],
    this.imageAsset,
    this.imageCaption = '',
    this.subtitle = '',
  });

  /// A line under the title (e.g. "Using rule of thumb method").
  final String subtitle;

  /// 09/11/2026: a second table (e.g. FM-200 pipe limits, one column per
  /// section) printed after the results. Empty = none.
  final String extraTitle;
  final List<String> extraHeaders;
  final List<List<String>> extraRows;

  /// A drawing from the app's assets (e.g. the FM-200 nozzle layout),
  /// printed in the PDF with [imageCaption] under it. Not in the Excel file.
  final String? imageAsset;
  final String imageCaption;

  final String id;
  final String title;
  final String discipline;
  final bool arabic;
  final List<CalcRow> inputs;
  final List<CalcRow> results;
  final String formula;
  final String note;

  /// The translated words of the report.
  final CalcReportLabels labels;

  String get _date {
    final DateTime d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String get fileBase => 'ASEC-$id-$_date';
}

class CalcReportLabels {
  const CalcReportLabels({
    required this.inputs,
    required this.results,
    required this.method,
    required this.item,
    required this.value,
    required this.unit,
    required this.date,
    required this.disclaimer,
  });

  final String inputs;
  final String results;
  final String method;
  final String item;
  final String value;
  final String unit;
  final String date;
  final String disclaimer;
}

abstract final class CalcExport {
  // ── PDF ──────────────────────────────────────────────────────────────────

  static const PdfColor _navy = PdfColor.fromInt(0xFF1F2A6B);
  static const PdfColor _blue = PdfColor.fromInt(0xFF3355D6);
  static const PdfColor _ink = PdfColor.fromInt(0xFF2B2F3A);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _zebra = PdfColor.fromInt(0xFFF3F5FB);
  static const PdfColor _highlight = PdfColor.fromInt(0xFFE6ECFF);

  /// Opens the Save dialog. [fileName] — what the name field starts with.
  /// Returns where the file went, or null if the user cancelled.
  static Future<String?> savePdf(CalcReport r,
      {required String fileName, required String dialogTitle}) {
    return saveBytesToDevice(
      build: () => buildPdf(r),
      fileName: fileName,
      extension: 'pdf',
      mimeType: 'application/pdf',
      dialogTitle: dialogTitle,
    );
  }

  /// Fonts for the symbols Cairo lacks (√ Δ ² ÷ ≈ …). Downloaded once and
  /// cached by `printing`; the page is online-only, and if the download
  /// fails the PDF is still made without them.
  static Future<List<pw.Font>> _fallbackFonts() async {
    try {
      return await Future.wait(<Future<pw.Font>>[
        PdfGoogleFonts.notoSansRegular(),
        PdfGoogleFonts.notoSansMathRegular(),
        PdfGoogleFonts.notoSansSymbolsRegular(),
      ]).timeout(const Duration(seconds: 5));
    } catch (_) {
      return <pw.Font>[];
    }
  }

  static Future<Uint8List> buildPdf(CalcReport r) async {
    final pw.Font regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Regular.ttf'));
    final pw.Font bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Bold.ttf'));
    final pw.MemoryImage logo = pw.MemoryImage(
        (await rootBundle.load('assets/certificate/asec_logo.png')).buffer.asUint8List());
    final List<pw.Font> fallback = await _fallbackFonts();
    pw.MemoryImage? figure;
    if (r.imageAsset != null) {
      try {
        figure = pw.MemoryImage((await rootBundle.load(r.imageAsset!)).buffer.asUint8List());
      } catch (_) {
        figure = null;
      }
    }

    final pw.TextDirection dir = r.arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final pw.Document doc = pw.Document(
      title: 'ASEC — ${r.title}',
      author: 'ASEC',
      theme: pw.ThemeData.withFont(base: regular, bold: bold, fontFallback: fallback),
    );

    pw.Widget text(String s,
            {double size = 10,
            PdfColor color = _ink,
            bool isBold = false,
            pw.TextDirection? direction}) =>
        pw.Text(
          s,
          textDirection: direction ?? dir,
          style: pw.TextStyle(
            fontSize: size,
            color: color,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        );

    pw.Widget sectionTitle(String s) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: text(s, size: 13, color: _navy, isBold: true),
        );

    pw.Widget cell(pw.Widget child, {bool alignEnd = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Align(
            alignment: alignEnd ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: child,
          ),
        );

    // pw.Table does not mirror itself for RTL, so the columns are swapped
    // by hand: label on the reading side, value on the other.
    pw.Widget table(List<CalcRow> rows) {
      final List<pw.TableRow> out = <pw.TableRow>[];
      for (int i = 0; i < rows.length; i++) {
        final CalcRow row = rows[i];
        final PdfColor? bg = row.primary ? _highlight : (i.isOdd ? _zebra : null);
        final pw.Widget label = cell(
          text(row.label, isBold: row.primary),
          alignEnd: r.arabic,
        );
        final pw.Widget value = cell(
          text(row.text,
              isBold: row.primary,
              color: row.primary ? _blue : _ink,
              direction: pw.TextDirection.ltr),
          alignEnd: !r.arabic,
        );
        out.add(pw.TableRow(
          decoration: bg == null ? null : pw.BoxDecoration(color: bg),
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: r.arabic ? <pw.Widget>[value, label] : <pw.Widget>[label, value],
        ));
      }
      return pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E6EF), width: 0.5),
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E6EF), width: 0.5),
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E6EF), width: 0.5),
        ),
        columnWidths: r.arabic
            ? const <int, pw.TableColumnWidth>{0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(3)}
            : const <int, pw.TableColumnWidth>{0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
        children: out,
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        textDirection: dir,
        header: (pw.Context c) => c.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: text(r.title, size: 9, color: _muted),
              ),
        footer: (pw.Context c) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            text('ASEC · asecbim.com', size: 8, color: _muted, direction: pw.TextDirection.ltr),
            text('${c.pageNumber} / ${c.pagesCount}',
                size: 8, color: _muted, direction: pw.TextDirection.ltr),
          ],
        ),
        build: (pw.Context c) => <pw.Widget>[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: <pw.Widget>[
              pw.Image(logo, height: 44),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    text(r.title, size: 18, color: _navy, isBold: true),
                    if (r.subtitle.isNotEmpty) text(r.subtitle, size: 11, color: _blue),
                    text('${r.discipline}  ·  ${r.labels.date}: ${r._date}',
                        size: 10, color: _muted),
                  ],
                ),
              ),
            ],
          ),
          pw.Container(
            height: 2,
            color: _blue,
            margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
          ),
          // A report that is only a table (e.g. quiz results) has no
          // inputs / results rows: those sections are left out.
          if (r.inputs.isNotEmpty) ...<pw.Widget>[
            sectionTitle(r.labels.inputs),
            table(r.inputs),
          ],
          if (r.results.isNotEmpty) ...<pw.Widget>[
            sectionTitle(r.labels.results),
            table(r.results),
          ],
          if (r.extraRows.isNotEmpty) ...<pw.Widget>[
            sectionTitle(r.extraTitle),
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E6EF), width: 0.5),
                top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E6EF), width: 0.5),
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E6EF), width: 0.5),
              ),
              children: <pw.TableRow>[
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _navy),
                  children: <pw.Widget>[
                    for (final String h in (r.arabic ? r.extraHeaders.reversed : r.extraHeaders))
                      cell(text(h, isBold: true, color: PdfColors.white)),
                  ],
                ),
                for (int i = 0; i < r.extraRows.length; i++)
                  pw.TableRow(
                    decoration: i.isOdd ? const pw.BoxDecoration(color: _zebra) : null,
                    children: <pw.Widget>[
                      for (final String v in (r.arabic ? r.extraRows[i].reversed : r.extraRows[i]))
                        cell(text(v, direction: pw.TextDirection.ltr)),
                    ],
                  ),
              ],
            ),
          ],
          if (figure != null) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            pw.Center(child: pw.Image(figure, height: 260, fit: pw.BoxFit.contain)),
            if (r.imageCaption.isNotEmpty)
              pw.Center(child: text(r.imageCaption, size: 9, color: _muted)),
          ],
          if (r.formula.isNotEmpty) ...<pw.Widget>[
          sectionTitle(r.labels.method),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: _zebra,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: text(r.formula, size: 10, color: _navy, direction: pw.TextDirection.ltr),
          ),
          ],
          if (r.note.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            text(r.note, size: 10),
          ],
          pw.SizedBox(height: 10),
          text(r.labels.disclaimer, size: 8.5, color: _muted),
        ],
      ),
    );

    return doc.save();
  }

  // ── Excel (.xlsx) ────────────────────────────────────────────────────────

  static const String _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static Future<String?> saveExcel(CalcReport r,
      {required String fileName, required String dialogTitle}) {
    return saveBytesToDevice(
      build: () async => buildXlsx(r),
      fileName: fileName,
      extension: 'xlsx',
      mimeType: _xlsxMime,
      dialogTitle: dialogTitle,
    );
  }

  // Cell styles (index into cellXfs of styles.xml below).
  static const int _sNormal = 0;
  static const int _sBold = 1;
  static const int _sTitle = 2;
  static const int _sHeader = 3;
  static const int _sWrap = 4;
  static const int _sPrimary = 5;
  static const int _sMuted = 6;

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      // Control characters other than tab / newline are not allowed in XML.
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  static Uint8List buildXlsx(CalcReport r) {
    final StringBuffer rows = StringBuffer();
    int n = 0;
    final List<String> merges = <String>[];

    String strCell(String col, String v, int style) =>
        '<c r="$col$n" t="inlineStr" s="$style"><is><t xml:space="preserve">${_esc(v)}</t></is></c>';
    String numCell(String col, double v, int style) =>
        '<c r="$col$n" s="$style"><v>$v</v></c>';

    // Every cell helper reads n, so a row's number is bumped before its
    // cells are written.
    void textRow(String v, int style, {bool merge = false, double? height}) {
      n++;
      final String ht = height == null ? '' : ' ht="$height" customHeight="1"';
      rows.write('<row r="$n"$ht>${strCell('A', v, style)}</row>');
      if (merge) merges.add('A$n:C$n');
    }

    void blank() {
      n++;
      rows.write('<row r="$n"/>');
    }

    void tableRows(List<CalcRow> list) {
      n++;
      rows.write('<row r="$n">'
          '${strCell('A', r.labels.item, _sHeader)}'
          '${strCell('B', r.labels.value, _sHeader)}'
          '${strCell('C', r.labels.unit, _sHeader)}'
          '</row>');
      for (final CalcRow c in list) {
        n++;
        final int style = c.primary ? _sPrimary : _sNormal;
        final double? v = c.number;
        rows.write('<row r="$n">');
        rows.write(strCell('A', c.label, style));
        if (v != null && v.isFinite) {
          rows.write(numCell('B', v, style));
          rows.write(strCell('C', c.unit, style));
        } else {
          rows.write(strCell('B', c.text, style));
          rows.write(strCell('C', '', style));
        }
        rows.write('</row>');
      }
    }

    textRow('ASEC — ${r.title}', _sTitle, merge: true, height: 24);
    if (r.subtitle.isNotEmpty) textRow(r.subtitle, _sBold, merge: true);
    textRow('${r.discipline}  ·  ${r.labels.date}: ${r._date}', _sMuted, merge: true);
    if (r.inputs.isNotEmpty) {
      blank();
      textRow(r.labels.inputs, _sBold);
      tableRows(r.inputs);
    }
    if (r.results.isNotEmpty) {
      blank();
      textRow(r.labels.results, _sBold);
      tableRows(r.results);
    }
    if (r.extraRows.isNotEmpty) {
      blank();
      textRow(r.extraTitle, _sBold);
      const String cols = 'ABCDEFGHIJ';
      n++;
      rows.write('<row r="$n">');
      for (int i = 0; i < r.extraHeaders.length && i < cols.length; i++) {
        rows.write(strCell(cols[i], r.extraHeaders[i], _sHeader));
      }
      rows.write('</row>');
      for (final List<String> line in r.extraRows) {
        n++;
        rows.write('<row r="$n">');
        for (int i = 0; i < line.length && i < cols.length; i++) {
          final double? v = double.tryParse(line[i]);
          rows.write(v != null && i > 0 ? numCell(cols[i], v, _sNormal) : strCell(cols[i], line[i], _sNormal));
        }
        rows.write('</row>');
      }
    }
    if (r.formula.isNotEmpty) {
      blank();
      textRow(r.labels.method, _sBold);
      for (final String line in r.formula.split('\n')) {
        textRow(line, _sNormal, merge: true);
      }
    }
    if (r.note.isNotEmpty) {
      blank();
      textRow(r.note, _sWrap, merge: true, height: 60);
    }
    blank();
    textRow(r.labels.disclaimer, _sWrap, merge: true, height: 30);

    final String mergeXml = merges.isEmpty
        ? ''
        : '<mergeCells count="${merges.length}">'
            '${merges.map((String m) => '<mergeCell ref="$m"/>').join()}'
            '</mergeCells>';

    final String sheet = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheetViews><sheetView workbookViewId="0"${r.arabic ? ' rightToLeft="1"' : ''}/></sheetViews>'
        '<sheetFormatPr defaultRowHeight="16"/>'
        '<cols>'
        '<col min="1" max="1" width="52" customWidth="1"/>'
        '<col min="2" max="2" width="20" customWidth="1"/>'
        '<col min="3" max="3" width="16" customWidth="1"/>'
        '</cols>'
        '<sheetData>$rows</sheetData>'
        '$mergeXml'
        '<pageMargins left="0.6" right="0.6" top="0.7" bottom="0.7" header="0.3" footer="0.3"/>'
        '</worksheet>';

    const String styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="6">'
        '<font><sz val="11"/><color rgb="FF2B2F3A"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><color rgb="FF1F2A6B"/><name val="Calibri"/></font>'
        '<font><b/><sz val="15"/><color rgb="FF1F2A6B"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><color rgb="FF3355D6"/><name val="Calibri"/></font>'
        '<font><sz val="9"/><color rgb="FF6B7280"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>'
        '</fonts>'
        '<fills count="4">'
        '<fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFE6ECFF"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF1F2A6B"/><bgColor indexed="64"/></patternFill></fill>'
        '</fills>'
        '<borders count="2">'
        '<border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border><left/><right/><top/><bottom style="thin"><color rgb="FFE2E6EF"/></bottom><diagonal/></border>'
        '</borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="7">'
        // 0 normal
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"/>'
        // 1 bold section title
        '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
        // 2 report title
        '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
        // 3 table header (white on navy)
        '<xf numFmtId="0" fontId="5" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
        // 4 wrapped paragraph
        '<xf numFmtId="0" fontId="4" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
        // 5 primary result
        '<xf numFmtId="0" fontId="3" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>'
        // 6 muted line
        '<xf numFmtId="0" fontId="4" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
        '</cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>';

    const String contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '</Types>';

    const String rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>';

    final String workbook = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<bookViews><workbookView/></bookViews>'
        '<sheets><sheet name="${_esc(_sheetName(r.title))}" sheetId="1" r:id="rId1"/></sheets>'
        '</workbook>';

    const String workbookRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>';

    final Archive zip = Archive();
    void add(String name, String xml) => zip.addFile(ArchiveFile.bytes(name, utf8.encode(xml)));
    add('[Content_Types].xml', contentTypes);
    add('_rels/.rels', rootRels);
    add('xl/workbook.xml', workbook);
    add('xl/_rels/workbook.xml.rels', workbookRels);
    add('xl/styles.xml', styles);
    add('xl/worksheets/sheet1.xml', sheet);
    return ZipEncoder().encodeBytes(zip);
  }

  /// Excel sheet names: max 31 characters, none of : \ / ? * [ ]
  static String _sheetName(String title) {
    final String clean = title.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();
    return clean.length <= 31 ? clean : clean.substring(0, 31);
  }
}
