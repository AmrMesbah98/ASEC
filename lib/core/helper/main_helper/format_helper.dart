/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: format_helper.dart
/// Description: Declares `FormatHelper`.
/// Author: Amr Mesbah
/// Created at: 06/10/2026
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.
/// Updated: 16/10/2026 - Brought into ASEC: EVERY Text in the app passes its
///          string through [FormatHelper.capitalize]. Emails and links are
///          left exactly as written.
/// Updated: 23/10/2026 - Units stay exactly as written (kg, not Kg; also
///          mm, m/s, kg/m³, kJ/kg·K …) — see [_isUnit].
/// Updated: 09/11/2026 - THE APP-WIDE CASE RULE:
///          • a TITLE (a short label, up to 5 words, not ending in . ? !)
///            → Every Word Capitalised: "Amr Mesbah".
///          • ANY OTHER TEXT → a capital on the first word of each sentence
///            and the rest small: "Amr mesbah hosny".
///          In a sentence, words that are not ordinary words keep their
///          case: abbreviations (CV, HVAC, ASEC, PDF), anything with a
///          digit (FM-200, CO₂), units, emails and links — see [isSentence].

// Date: 23/10/2024
// Last update: 31/03/2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

List<String> abbreviation = [
  "it",
  "hr",
  'utils ux',
  'log',
  'qa',
  'pr',
  'dev',
  'ceo',
  "grc",
  "mena",
  "ksa",
  "uae",
  "coo",
  "cfo",
  "cdo",
  "cso",
  "cbo",
  "cmo",
  "cto",
  "cno",
  "cco",
  "chro",
  "cxo"
];

/// Unit symbols that [FormatHelper.capitalize] must never touch. Common
/// English words ("in", "bar", "min") are left out on purpose; compound
/// units like "m³/min" are caught by [_isUnit] anyway.
const Set<String> _unitWords = <String>{
  'kg', 'g', 'mg', 't',
  'mm', 'cm', 'm', 'km', 'm²', 'm³', 'mm²', 'cm²', 'cm³', 'cm⁴',
  'l', 'ml', 'lb', 'lbs', 'oz', 'ft', 'ft²', 'ft³', 'in²', 'in³', 'in⁴',
  'kw', 'kj', 'kpa', 'mpa', 'pa', 'mbar', 'psi', 'gpm', 'cfm', 'fpm',
  's', 'h', 'rpm', 'in.wg', 'inwg',
  // 03/11/2026: volume / flow units stay small too — "gal", not "Gal".
  'gal', 'gals', 'gph', 'gpd', 'lpm', 'lps', 'lph', 'cfh', 'scfm',
  'hp', 'kwh', 'mj', 'gj', 'ppm', 'psig', 'psia', 'mph', 'kph',
  'ftwc', 'mwc', 'cu', 'yd', 'yd²', 'yd³',
  // Unit converter symbols (unit_catalog.dart) written in lower case — they
  // stay that way: "0.987 atm", "29.53 inHg", not "Atm" / "InHg".
  'atm', 'inhg', 'mmhg', 'mh₂o', 'mmh₂o', 'fth₂o', 'kcal', 'cal', 'kgf', 'lbf',
  'kip', 'kn', 'tf', 'thm', 'bbl', 'ac', 'ha', 'feddan', 'nmi', 'µm', 'ms',
  'rad', 'grad', 'rev', 'd', 'wk', 'yr', 'mi',
};

/// Units that are also English words ("in", "min", "bar", "hr", "day"):
/// kept small when they are a unit — in brackets "(in)", or the whole text
/// is just that unit (a unit column / suffix).
const Set<String> _wordUnits = <String>{'in', 'min', 'bar', 'hr', 'hrs', 'sec'};

/// Words that are units ONLY right after a number ("2.1 in", "5 min",
/// "3 bar") — elsewhere they are ordinary English and get capitalised.
const Set<String> _unitsAfterNumber = <String>{'in', 'min', 'bar'};

/// Small joining words that stay lower case inside a title (02/11/2026):
/// "Save as PDF", "Flow in l/s", "Tips and Tricks", "Head loss per 100 ft".
/// The first word of a text (or after ":" / "-") is still capitalised.
const Set<String> smallWords = <String>{
  'a', 'an', 'the',
  'and', 'or', 'nor', 'but', 'so', 'yet',
  'as', 'at', 'by', 'for', 'from', 'in', 'into', 'of', 'off', 'on',
  'onto', 'per', 'to', 'up', 'via', 'with', 'vs', 'vs.',
};

/// True when [word] (ignoring wrapping punctuation) is one of [smallWords].
bool isSmallWord(String word) => smallWords.contains(
      word.replaceAll(RegExp(r'''^[(\["']+|[)\],.:;!?"']+$'''), '').toLowerCase(),
    );

/// True when the word at [i] starts a text or a new part of it.
bool startsPart(List<String> words, int i) {
  if (i == 0) return true;
  final String prev = words[i - 1];
  if (prev.isEmpty) return startsPart(words, i - 1);
  return prev == '-' || prev == '—' || prev == '|' || RegExp(r'[:.!?]$').hasMatch(prev);
}

/// Lower-cases a small word written "As" / "as" — but never "AS" (all caps
/// stays as written) and never a lone capital "A" ("Type A", "Class A").
String lowerSmallWord(String word) {
  final int at = word.indexOf(RegExp(r'[A-Za-z]'));
  if (at < 0) return word;
  final String rest = word.substring(at + 1);
  if (rest.isEmpty && word[at] == 'A') return word;
  if (rest != rest.toLowerCase()) return word;
  return word.substring(0, at) + word[at].toLowerCase() + rest;
}

final RegExp _numberWord = RegExp(r'^[-+]?\d[\d.,]*$');

/// True when [word] is a unit symbol (kg, mm, m/s, kg/m³, kJ/kg·K, 10kg…):
/// written in lower case and either a known symbol, a number with a unit,
/// or a compound unit (contains / · ² ³ ⁴).
bool _isUnit(String word) {
  // Ignore wrapping punctuation: "(kg)", "kg," "kg."
  final String core = word.replaceAll(RegExp(r'^[(\[]+|[)\],.:;]+$'), '');
  if (core.isEmpty) return false;
  final String first = core[0];
  if (first != first.toLowerCase() || first == first.toUpperCase()) {
    // Starts with a capital, a digit or a symbol — a number + unit like
    // "10kg" still counts.
    return RegExp(r'^\d+([.,]\d+)?[a-z]').hasMatch(core);
  }
  if (_unitWords.contains(core.toLowerCase())) return true;
  return RegExp(r'[/·²³⁴]').hasMatch(core);
}

/// Words a text needs before it is read as a sentence rather than a title:
/// a title is at most 5 words.
const int _sentenceWords = 6;

/// True when [input] reads as a SENTENCE (any text that is not a title): it
/// ends with . ? or ! (but is more than one word), or it runs to
/// [_sentenceWords] words or more. Lone punctuation ("—", "·") is not a word.
/// "Tick any two values; the other two are solved." is a sentence;
/// "Flow Rate", "Download CV" and "Load Estimation (Rule of Thumb)" are titles.
bool isSentence(String input) {
  final String text = input.trim();
  final int count = text
      .split(RegExp(r'\s+'))
      .where((String w) => RegExp(r'[A-Za-z0-9\u0600-\u06FF]').hasMatch(w))
      .length;
  if (count >= _sentenceWords) return true;
  return count > 1 && RegExp(r'[.?!؟]$').hasMatch(text);
}

/// A word whose case is part of it, so a sentence never lower-cases it:
/// two or more capitals (CV, HVAC, ASEC, iOS, McDonald), a digit (FM-200,
/// CO₂, 3D), a lone capital ("I", "Type B"), or a known abbreviation (IT, HR, CEO…).
bool _keepsCase(String word) {
  final String core = word.replaceAll(RegExp(r'''^[(\["']+|[)\],.:;!?"']+$'''), '');
  if (core.isEmpty) return true;
  // A lone capital: "I", "Type B" — but "A" mid-sentence is the article.
  if (RegExp(r'^[B-Z]$').hasMatch(core)) return true;
  if (RegExp(r'[0-9₀-₉⁰-⁹²³]').hasMatch(core)) return true;
  if (RegExp(r'[A-Z]').allMatches(core).length >= 2) return true;
  return abbreviation.contains(core.toLowerCase()) && core == core.toUpperCase();
}

abstract class FormatHelper {
  /// Picks the locale-appropriate name, falling back to the English one when
  /// the locale is English or no Arabic value exists.
  /// (Moved here from StringFormatter in the deleted additional_info_content.dart.)
  static String localizedString({
    required String englishName,
    required String? arabicName,
  }) {
    if (Get.locale.toString().contains('en') || arabicName == null) {
      return capitalize(englishName);
    }
    return arabicName;
  }

  static String capitalize(String input) {
    // Decided on the text as written. In a sentence "it" is the pronoun, not
    // the IT department, so it is not upper-cased there.
    final bool sentence = isSentence(input);
    input = applyAbbreviation(input, skip: sentence ? const <String>{'it'} : const <String>{});

    if (input.isEmpty) {
      return "";
    }

    final List<String> words = input.split(" ");

    // A sentence: capital at the start of each sentence, every other
    // ordinary word small — "Amr mesbah hosny" (09/11/2026).
    if (sentence) {
      bool atStart = true;
      for (int i = 0; i < words.length; i++) {
        final String word = words[i];
        if (word.isEmpty) continue;
        final bool keep = word.contains('@') ||
            word.contains('://') ||
            _isUnit(word) ||
            _keepsCase(word);
        final int at = word.indexOf(RegExp(r'[A-Za-z]'));
        if (!keep && at >= 0) {
          words[i] = word.substring(0, at) +
              (atStart ? word[at].toUpperCase() : word[at].toLowerCase()) +
              word.substring(at + 1);
        }
        // The next word starts a new sentence after . ? ! — but not after a
        // number ("2.5") or a short abbreviation ("Eng.", "e.g.").
        atStart = RegExp(r'[?!؟]$').hasMatch(word) ||
            (RegExp(r'[a-z]{3,}\.$').hasMatch(word.toLowerCase()) &&
                !RegExp(r'^(eng|etc|approx)\.$').hasMatch(word.toLowerCase()));
      }
      return words.join(" ");
    }

    for (int i = 0; i < words.length; i++) {
      final String word = words[i];
      if (word.isEmpty) continue;
      // An email or a link stays exactly as it is.
      if (word.contains('@') || word.contains('://')) continue;
      // A web address stays small too: asecbim.com, www.asecbim.com.
      if (RegExp(r'^(www\.)?[a-z0-9-]+(\.[a-z0-9-]+)*\.(com|net|org|io|app|eg|sa|ae|co|edu|gov|info)(/\S*)?[.,]?$').hasMatch(word)) continue;
      // A unit symbol stays exactly as it is: kg, mm, m/s, kg/m³, in.wg.
      if (_isUnit(word)) continue;
      // "(in)", "(min)", or a text that IS the unit ("gal", "in"): small.
      final String bare = word.replaceAll(RegExp(r'^[(\[]+|[)\],.:;]+$'), '').toLowerCase();
      if (_wordUnits.contains(bare) &&
          (word.startsWith('(') || words.where((String w) => w.isNotEmpty).length == 1)) {
        words[i] = word.toLowerCase();
        continue;
      }
      // "2.1 in", "5 min": a unit because a number comes right before it.
      if (i > 0 &&
          _numberWord.hasMatch(words[i - 1]) &&
          _unitsAfterNumber.contains(word)) {
        continue;
      }
      // Small joining words stay small inside a title: "Save as PDF".
      if (isSmallWord(word) && !startsPart(words, i)) {
        words[i] = lowerSmallWord(word);
        continue;
      }
      // The first LETTER, so "(rule" becomes "(Rule".
      final int at = word.indexOf(RegExp(r'[A-Za-z]'));
      words[i] = at < 0
          ? word
          : word.substring(0, at) + word[at].toUpperCase() + word.substring(at + 1);
    }
    // Names that keep a small word on purpose (01/11/2026): the course is
    // "Tips and Tricks", not "Tips And Tricks".
    return words.join(" ").replaceAllMapped(
          RegExp(r'\bTips And Tricks\b', caseSensitive: false),
          (_) => 'Tips and Tricks',
        );
  }

  static String applyAbbreviation(String input, {Set<String> skip = const <String>{}}) {
    for (String abbreviation in abbreviation) {
      if (skip.contains(abbreviation)) continue;
      RegExp regex =
      RegExp(r'\b' + abbreviation + r'\b', caseSensitive: false);
      if (regex.hasMatch(input)) {
        input = input.replaceAllMapped(
            regex, (match) => abbreviation.toUpperCase());
      }
    }
    return input;
  }

  /// Turns an email (or a raw user id) into something readable:
  ///
  ///   amr.mesbah@knowticed.com  -> Amr Mesbah
  ///   hr_team@knowticed.com     -> HR Team
  ///   sara-ali99@x.com          -> Sara Ali
  ///
  /// Used as the fallback when an employee lookup fails and all we have is the
  /// address the record was created with. The domain is dropped, separators
  /// (. _ - +) become spaces, trailing digits are stripped, and the result runs
  /// through [capitalize] so known abbreviations (IT, HR, GRC, CEO…) stay
  /// upper-case. Returns '' for null/empty input so callers can fall back.
  static String formatEmailToName(String? email) {
    final String raw = (email ?? '').trim();
    if (raw.isEmpty) return '';

    final String local = raw.contains('@') ? raw.split('@').first : raw;

    final String spaced = local
        .replaceAll(RegExp(r'[._\-+]+'), ' ')
        .replaceAll(RegExp(r'\d+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Nothing left to show (e.g. "123@x.com") — fall back to the local part.
    if (spaced.isEmpty) return capitalize(local);

    return capitalize(spaced);
  }

  /// ✅ Formats a date as "31 Mar 2026"
  /// Supports: DateTime, Firestore Timestamp, ISO String, milliseconds
  static String formatDate(dynamic rawDate, String locale) {
    if (rawDate == null) return '-';

    DateTime? date;

    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      if (rawDate.isEmpty || rawDate == 'null') return '-';
      date = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is Map) {
      // Handle Firestore Timestamp as map: {_seconds: ..., _nanoseconds: ...}
      final seconds = rawDate['_seconds'] ?? rawDate['seconds'];
      if (seconds != null && seconds is int) {
        date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    if (date == null) return '-';

    // ✅ Output: "31 Mar 2026" (English) or "31 مار 2026" (Arabic)
    return DateFormat('dd MMM yyyy', locale).format(date);
  }
}
