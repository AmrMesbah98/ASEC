/// Turns the text of a quiz file into [QuizQuestion]s (pure Dart, no Flutter).
///
/// Two layouts are understood:
///  1. A Google Forms printout (PDF): every question has the line
///     "حدد دائرة واحدة فقط" / "Mark only one oval", the points beside the
///     question ("نقطة واحدة", "2 points") and its options under that line.
///  2. A plain numbered list (PDF or .txt):
///        1. Question text (2 points)
///        A) option
///        B) option ✓
///        Answer: B
///
/// Points: taken from the file when it says them, otherwise 1 point each.
/// Correct answer: taken from the file when it marks one (✓, "(correct)",
/// "Answer: B"…). Otherwise the question is left with no correct answer
/// (correctIndex = -1) so the editor shows it as incomplete until the admin
/// taps the right option.
library;

import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';

class QuizImportResult {
  const QuizImportResult({required this.questions, this.title = ''});

  final List<QuizQuestion> questions;

  /// The quiz name found in the file ('' when none).
  final String title;

  int get missingAnswers => questions.where((QuizQuestion q) => q.correctIndex < 0).length;
}

class QuizImportParser {
  QuizImportParser._();

  /// [lines] are the file's lines in reading order. [newId] makes question ids.
  static QuizImportResult parse(List<String> lines, String Function() newId) {
    final List<String> clean = <String>[
      for (final String l in lines) _normalize(l),
    ].where((String l) => l.isNotEmpty).toList();

    final String title = _findTitle(clean);
    final bool forms = clean.any(_isFormsMarker);
    final List<QuizQuestion> questions =
        forms ? _parseForms(clean, newId) : _parseNumbered(clean, newId);
    return QuizImportResult(questions: questions, title: title);
  }

  // ───────────────────────────── Google Forms ─────────────────────────────

  static List<QuizQuestion> _parseForms(List<String> lines, String Function() newId) {
    final List<QuizQuestion> out = <QuizQuestion>[];
    List<String> pending = <String>[];
    List<String> header = <String>[];
    List<String> options = <String>[];
    bool inOptions = false;

    void finish() {
      if (header.isEmpty || options.length < 2) return;
      final String joined = header.join(' ');
      final _Options parsed = _cleanOptions(options);
      final String text = _cleanQuestion(joined);
      if (text.isEmpty) return;
      out.add(QuizQuestion(
        id: newId(),
        text: text,
        options: parsed.options,
        correctIndex: parsed.correct,
        points: _pointsIn(joined) ?? 1,
      ));
    }

    for (final String line in lines) {
      if (_isFormsFooter(line)) {
        // "This content is neither created nor endorsed by Google." — the end.
        if (inOptions) finish();
        inOptions = false;
        pending = <String>[];
        header = <String>[];
        continue;
      }
      if (_isNoise(line)) continue;
      if (_isFormsMarker(line)) {
        header = pending;
        pending = <String>[];
        options = <String>[];
        inOptions = true;
        continue;
      }
      final bool starts = _isQuestionStart(line);
      if (inOptions) {
        if (starts) {
          finish();
          inOptions = false;
          header = <String>[];
          pending = <String>[line];
        } else {
          options.add(line);
        }
      } else {
        // A new "*" line drops what came before it: the form's title, or a
        // text-answer question (e-mail, full name) that has no options.
        pending = starts ? <String>[line] : <String>[...pending, line];
      }
    }
    if (inOptions) finish();
    return out;
  }

  static bool _isFormsMarker(String l) {
    final String s = l.toLowerCase();
    return l.contains('دائرة واحدة') ||
        l.contains('ضع علامة') ||
        s.contains('mark only one oval') ||
        s.contains('check all that apply');
  }

  static bool _isFormsFooter(String l) =>
      l.contains('لم يتم إنشاء') || l.toLowerCase().contains('neither created nor endorsed');

  /// A question line: it has the required "*", or begins with "12." / "12 .".
  static bool _isQuestionStart(String l) =>
      l.contains('*') || RegExp(r'^\d{1,3}\s?\.(\s|$)').hasMatch(l);

  static bool _isNoise(String l) {
    final String s = l.toLowerCase();
    if (s.contains('docs.google.com') || s.contains('forms.gle')) return true;
    if (RegExp(r'^\d{1,3}\s*/\s*\d{1,3}$').hasMatch(l)) return true; // page 3/19
    if (RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4},?\s+\d{1,2}:\d{2}').hasMatch(l)) return true; // print header
    if (l.contains('تشير إلى') || s.contains('indicates required question')) return true;
    if (l.contains('Google') && (l.contains('نماذج') || s.contains('forms'))) return true;
    if (l.contains('لم يتم إنشاء هذا المحتوى') || s.contains('neither created nor endorsed')) return true;
    if (RegExp(r'^\d{1,3}\s?\.?$').hasMatch(l)) return true; // a lone item number
    return false;
  }

  // ───────────────────────────── numbered list ─────────────────────────────

  static final RegExp _qStart = RegExp(r'^(?:(?:Q|q|س|سؤال)\s*)?(\d{1,3})\s*[.)\-:]\s*(.+)$');
  static final RegExp _optStart = RegExp(r'^\(?([A-Fa-f]|[أابجدهو])\s*[.)\-:]\s*(.+)$');
  static final RegExp _bullet = RegExp(r'^[-•○◯●◉☐☑▢□■]\s*(.+)$');
  static final RegExp _answer =
      RegExp(r'^(?:answer|correct answer|correct|الإجابة|الاجابة|الإجابة الصحيحة|الاجابة الصحيحة|الحل)\s*[:：\-]\s*(.+)$',
          caseSensitive: false);

  static List<QuizQuestion> _parseNumbered(List<String> lines, String Function() newId) {
    final List<QuizQuestion> out = <QuizQuestion>[];
    String? question;
    List<String> options = <String>[];
    String? answer;

    void finish() {
      if (question == null || options.length < 2) return;
      final _Options parsed = _cleanOptions(options);
      int correct = parsed.correct;
      if (answer != null) correct = _answerIndex(answer!, parsed.options);
      final String text = _cleanQuestion(question!);
      if (text.isEmpty) return;
      out.add(QuizQuestion(
        id: newId(),
        text: text,
        options: parsed.options,
        correctIndex: correct,
        points: _pointsIn(question!) ?? 1,
      ));
    }

    for (final String line in lines) {
      if (_isNoise(line) && !_qStart.hasMatch(line)) continue;
      final RegExpMatch? a = _answer.firstMatch(line);
      if (a != null) {
        answer = a.group(1);
        continue;
      }
      final RegExpMatch? o = _optStart.firstMatch(line) ?? _bullet.firstMatch(line);
      if (o != null && question != null) {
        options.add(o.group(o.groupCount)!);
        continue;
      }
      final RegExpMatch? q = _qStart.firstMatch(line);
      if (q != null) {
        finish();
        question = q.group(2);
        options = <String>[];
        answer = null;
        continue;
      }
      // Wrapped text: belongs to the question until its options start.
      if (question != null && options.isEmpty) {
        question = '$question $line';
      } else if (question != null && options.isNotEmpty) {
        options[options.length - 1] = '${options.last} $line';
      }
    }
    finish();
    return out;
  }

  static int _answerIndex(String answer, List<String> options) {
    final String a = answer.trim();
    const String latin = 'abcdef';
    const String arabic = 'أبجدهو';
    if (a.length == 1 || RegExp(r'^\(?[A-Fa-fأابجدهو]\)?\.?$').hasMatch(a)) {
      final String ch = a.replaceAll(RegExp(r'[().]'), '').toLowerCase();
      int i = latin.indexOf(ch);
      if (i < 0) i = arabic.indexOf(ch == 'ا' ? 'أ' : ch);
      if (i >= 0 && i < options.length) return i;
    }
    final int n = int.tryParse(a) ?? 0;
    if (n >= 1 && n <= options.length) return n - 1;
    final String key = _key(a);
    return options.indexWhere((String o) => _key(o) == key);
  }

  // ───────────────────────────── shared helpers ─────────────────────────────

  /// Points written beside a question, or null when the file says none.
  static int? _pointsIn(String s) {
    if (s.contains('نقطة واحدة') || s.contains('درجة واحدة')) return 1;
    if (s.contains('نقطتان') || s.contains('نقطتين') || s.contains('درجتان') || s.contains('درجتين')) {
      return 2;
    }
    // "3 points", "3 نقاط" anywhere; "degree/درجة" only in brackets, since a
    // question may talk about temperature degrees.
    final RegExpMatch? m = RegExp(
      r'(\d{1,3})\s*(?:points?|pts?|marks?|نقاط|نقطة)(?![A-Za-z])',
      caseSensitive: false,
    ).firstMatch(s);
    if (m != null) return int.parse(m.group(1)!).clamp(1, 100);
    final RegExpMatch? m2 = RegExp(
      r'[(\[]\s*(\d{1,3})\s*(?:degrees?|درجات|درجة)\s*[)\]]',
      caseSensitive: false,
    ).firstMatch(s);
    if (m2 != null) return int.parse(m2.group(1)!).clamp(1, 100);
    final RegExpMatch? m3 = RegExp(
      r'(?:points?|marks?|نقاط)\s*[:=]\s*(\d{1,3})',
      caseSensitive: false,
    ).firstMatch(s);
    if (m3 != null) return int.parse(m3.group(1)!).clamp(1, 100);
    return null;
  }

  static String _cleanQuestion(String s) {
    String t = s
        .replaceAll(RegExp(r'\bDropdown\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\bMultiple choice\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'نقطة واحدة|نقطتان|نقطتين|درجة واحدة|درجتان|درجتين'), ' ')
        .replaceAll(
            RegExp(r'[(\[]?\s*\d{1,3}\s*(?:points?|pts?|marks?|نقاط|نقطة)(?![A-Za-z])\s*[)\]]?',
                caseSensitive: false),
            ' ')
        .replaceAll(
            RegExp(r'[(\[]\s*\d{1,3}\s*(?:degrees?|درجات|درجة)\s*[)\]]', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(?:points?|marks?|نقاط)\s*[:=]\s*\d{1,3}', caseSensitive: false), ' ')
        .replaceAll('*', ' ');
    // The form's own numbering ("3.", "12 .") wherever the text layout put it.
    t = t.replaceAll(RegExp(r'(^|\s)\d{1,3}\s?\.(?=\s|$)'), ' ');
    return _fixBrackets(t.replaceAll(RegExp(r'\s+'), ' ').trim());
  }

  /// Right-to-left PDFs scatter brackets: "CAD) ماذا) يرمز" → "(CAD) ماذا يرمز".
  static String _fixBrackets(String s) {
    final int open = '('.allMatches(s).length;
    final int close = ')'.allMatches(s).length;
    final bool ordered = RegExp(r'^[^()]*(\([^()]*\)[^()]*)*$').hasMatch(s);
    if (open == close && ordered) return s;
    final RegExp arabic = RegExp(r'[\u0600-\u06FF]');
    return s.split(' ').map((String w) {
      final String bare = w.replaceAll(RegExp(r'[()]'), '');
      if (bare == w || bare.isEmpty) return w;
      return arabic.hasMatch(bare) ? bare : '($bare)';
    }).join(' ');
  }

  static final RegExp _correctMark =
      RegExp(r'^[✓✔☑●◉]\s*|\s*[✓✔☑]$|\s*\((?:correct|صح|صحيح|الإجابة الصحيحة)\)$', caseSensitive: false);

  static _Options _cleanOptions(List<String> raw) {
    final List<String> options = <String>[];
    int correct = -1;
    for (final String r in raw) {
      String o = r.trim();
      if (_correctMark.hasMatch(o)) {
        correct = options.length;
        o = o.replaceAll(_correctMark, '').trim();
      }
      o = o.replaceFirst(RegExp(r'^[○◯▢□☐\-•]\s*'), '').trim();
      if (o.isNotEmpty) options.add(o);
    }
    // The editor allows 6 options at most.
    if (options.length > 6) options.removeRange(6, options.length);
    if (correct >= options.length) correct = -1;
    return _Options(options, correct);
  }

  static String _findTitle(List<String> lines) {
    for (final String l in lines.take(6)) {
      final RegExpMatch? m =
          RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4},?\s+\d{1,2}:\d{2}\s*(?:AM|PM|ص|م)?\s+(.+)$').firstMatch(l);
      if (m != null) return m.group(1)!.trim();
    }
    return '';
  }

  static String _key(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _normalize(String l) {
    const String indic = '٠١٢٣٤٥٦٧٨٩';
    final StringBuffer b = StringBuffer();
    for (final int c in l.runes) {
      // Bidi control characters some PDFs carry.
      if ((c >= 0x200E && c <= 0x200F) || (c >= 0x202A && c <= 0x202E) || (c >= 0x2066 && c <= 0x2069)) {
        continue;
      }
      final String ch = String.fromCharCode(c);
      final int d = indic.indexOf(ch);
      b.write(d >= 0 ? '$d' : (c == 0xA0 ? ' ' : ch));
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _Options {
  const _Options(this.options, this.correct);
  final List<String> options;
  final int correct;
}
