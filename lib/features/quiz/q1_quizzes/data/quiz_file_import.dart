/// Quizzes → New quiz → "Import from file": pick a PDF (or .txt) holding the
/// quiz, read its text and turn it into questions with [QuizImportParser].
///
/// PDF text is rebuilt line by line from each character's position, because
/// printed forms (Google Forms → PDF) store the question text, the points and
/// the options in a different order than they appear on the page, and Arabic
/// lines are stored right-to-left.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:asec/features/quiz/q1_quizzes/data/quiz_import_parser.dart';

class QuizFileImport {
  QuizFileImport._();

  static int _seq = 0;

  /// Question ids only need to be unique inside one quiz (same scheme as
  /// QuizEditorCubit).
  static String _newId() => 'q${DateTime.now().millisecondsSinceEpoch}_i${_seq++}';

  /// Lets the admin choose the file. Returns null when they cancel.
  /// Throws a [FormatException] with a readable message when nothing usable is found.
  static Future<QuizImportResult?> pickAndParse() async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf', 'txt'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final PlatformFile file = picked.files.first;
    final Uint8List bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final bool isPdf = (file.extension ?? '').toLowerCase() == 'pdf';

    final List<String> lines = isPdf
        ? await pdfLines(bytes)
        : const LineSplitter().convert(utf8.decode(bytes, allowMalformed: true));

    final QuizImportResult result = QuizImportParser.parse(lines, _newId);
    if (result.questions.isEmpty) {
      throw const FormatException(
        'No questions found in this file. Each question needs at least two options under it.',
      );
    }
    final String fallbackTitle = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '').replaceAll('_', ' ');
    return QuizImportResult(
      questions: result.questions,
      title: result.title.isNotEmpty ? result.title : fallbackTitle,
    );
  }

  /// The PDF's text as lines in reading order (top to bottom, page by page).
  static Future<List<String>> pdfLines(Uint8List bytes) async {
    await pdfrxFlutterInitialize();
    final PdfDocument doc = await PdfDocument.openData(bytes, sourceName: 'quiz-import');
    try {
      final List<String> lines = <String>[];
      for (final PdfPage page in doc.pages) {
        final PdfPageRawText? raw = await page.loadText();
        if (raw == null) continue;
        lines.addAll(_layoutLines(raw));
      }
      return lines;
    } finally {
      await doc.dispose();
    }
  }

  // ───────────────────────────── layout ─────────────────────────────

  static final RegExp _arabic = RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');
  static final RegExp _latinOrDigit = RegExp(r'[A-Za-z0-9]');

  static List<String> _layoutLines(PdfPageRawText raw) {
    // 1. Characters → words, in the order the PDF stores them.
    final List<_Word> words = <_Word>[];
    _Word? current;
    final String text = raw.fullText;
    for (int i = 0; i < text.length && i < raw.charRects.length; i++) {
      final String ch = text[i];
      final PdfRect r = raw.charRects[i];
      final bool blank = ch.trim().isEmpty || r.width <= 0 || r.height <= 0;
      if (blank) {
        if (current != null) words.add(current);
        current = null;
        continue;
      }
      final _Script script = _scriptOf(ch);
      if (current != null &&
          (!current.continuesWith(r) ||
              (script != _Script.neutral && current.script != _Script.neutral && script != current.script))) {
        words.add(current);
        current = null;
      }
      (current ??= _Word()).add(ch, r, script);
    }
    if (current != null) words.add(current);

    // 2. Words → lines: words whose heights overlap share a line (PDF y grows upwards).
    words.sort((_Word a, _Word b) => b.centerY.compareTo(a.centerY));
    final List<List<_Word>> rows = <List<_Word>>[];
    double rowTop = 0, rowBottom = 0;
    for (final _Word w in words) {
      if (rows.isNotEmpty) {
        final double overlap = math.min(rowTop, w.top) - math.max(rowBottom, w.bottom);
        if (overlap > 0.2 * math.min(w.height, rowTop - rowBottom)) {
          rows.last.add(w);
          rowTop = math.max(rowTop, w.top);
          rowBottom = math.min(rowBottom, w.bottom);
          continue;
        }
      }
      rows.add(<_Word>[w]);
      rowTop = w.top;
      rowBottom = w.bottom;
    }

    // 3. Rebuild reading order from the left-to-right layout. A line whose
    // item number ("19.") is on the left is a left-to-right line (Google
    // Forms): keep it, and turn each Arabic stretch back into reading order.
    // A line numbered on the right, or mostly Arabic, is right-to-left: read
    // it from the right, keeping each English stretch in its own order.
    final RegExp itemNumber = RegExp(r'^\d{1,3}\.$');
    final List<String> out = <String>[];
    for (final List<_Word> row in rows) {
      row.sort((_Word a, _Word b) => a.left.compareTo(b.left));
      List<String> t = row.map((_Word w) => w.text).toList();
      final String joined = t.join(' ');
      final bool rtl = itemNumber.hasMatch(t.first)
          ? false
          : itemNumber.hasMatch(t.last)
              ? true
              : _arabic.allMatches(joined).length > _latinOrDigit.allMatches(joined).length;
      final List<_Kind> k = t.map(_kindOf).toList();
      final List<String> ordered = <String>[];
      if (rtl) {
        t = t.reversed.toList();
        List<String> run = <String>[];
        for (final String w in t) {
          final _Kind kind = _kindOf(w);
          if (kind == _Kind.latin || (kind == _Kind.neutral && run.isNotEmpty)) {
            run.add(w);
          } else {
            ordered.addAll(run.reversed);
            run = <String>[];
            ordered.add(w);
          }
        }
        ordered.addAll(run.reversed);
      } else {
        // A number belongs to an Arabic stretch when an Arabic word follows it.
        bool joins(int i) =>
            k[i] == _Kind.arabic ||
            (k[i] == _Kind.neutral && !itemNumber.hasMatch(t[i]) && i + 1 < t.length && k[i + 1] == _Kind.arabic);
        int i = 0;
        while (i < t.length) {
          if (joins(i)) {
            int j = i;
            while (j + 1 < t.length && joins(j + 1)) {
              j++;
            }
            ordered.addAll(t.sublist(i, j + 1).reversed);
            i = j + 1;
          } else {
            ordered.add(t[i]);
            i++;
          }
        }
      }
      out.add(ordered.join(' '));
    }
    return out;
  }
}

enum _Script { arabic, latin, neutral }

enum _Kind { arabic, latin, neutral }

_Kind _kindOf(String word) => QuizFileImport._arabic.hasMatch(word)
    ? _Kind.arabic
    : RegExp(r'[A-Za-z]').hasMatch(word)
        ? _Kind.latin
        : _Kind.neutral;

_Script _scriptOf(String ch) => QuizFileImport._arabic.hasMatch(ch)
    ? _Script.arabic
    : QuizFileImport._latinOrDigit.hasMatch(ch)
        ? _Script.latin
        : _Script.neutral;

class _Word {
  final StringBuffer _b = StringBuffer();
  final List<double> _arabicX = <double>[];
  _Script script = _Script.neutral;
  double left = double.infinity, right = -double.infinity;
  double top = -double.infinity, bottom = double.infinity;

  /// Some PDFs store an Arabic word letter by letter left to right (visual
  /// order); those are turned back into reading order.
  String get text {
    final String t = _b.toString();
    final bool visual = _arabicX.length > 1 && _arabicX.first < _arabicX.last;
    return visual ? String.fromCharCodes(t.runes.toList().reversed) : t;
  }

  double get height => top - bottom;
  double get centerY => (top + bottom) / 2;

  void add(String ch, PdfRect r, _Script s) {
    _b.write(ch);
    if (s == _Script.arabic) _arabicX.add((r.left + r.right) / 2);
    if (s != _Script.neutral) script = s;
    left = math.min(left, r.left);
    right = math.max(right, r.right);
    top = math.max(top, r.top);
    bottom = math.min(bottom, r.bottom);
  }

  /// Same line and close by (either side, so right-to-left text works too).
  /// Real word breaks come from the spaces the PDF reader inserts.
  bool continuesWith(PdfRect r) {
    final double h = math.max(height, r.height);
    if (math.min(top, r.top) - math.max(bottom, r.bottom) < -0.1 * h) return false;
    final double gap = math.max(0, math.max(r.left - right, left - r.right));
    return gap <= h;
  }
}
