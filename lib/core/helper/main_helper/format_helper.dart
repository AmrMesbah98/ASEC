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
  's', 'h', 'rpm', 'in.wg',
};

/// Words that are units ONLY right after a number ("2.1 in", "5 min",
/// "3 bar") — elsewhere they are ordinary English and get capitalised.
const Set<String> _unitsAfterNumber = <String>{'in', 'min', 'bar'};

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
    input.toLowerCase();
    input = applyAbbreviation(input);

    if (input.isEmpty) {
      return "";
    }

    final List<String> words = input.split(" ");
    for (int i = 0; i < words.length; i++) {
      final String word = words[i];
      if (word.isEmpty) continue;
      // An email or a link stays exactly as it is.
      if (word.contains('@') || word.contains('://')) continue;
      // A unit symbol stays exactly as it is: kg, mm, m/s, kg/m³, in.wg.
      if (_isUnit(word)) continue;
      // "2.1 in", "5 min": a unit because a number comes right before it.
      if (i > 0 &&
          _numberWord.hasMatch(words[i - 1]) &&
          _unitsAfterNumber.contains(word)) {
        continue;
      }
      words[i] = word[0].toUpperCase() + word.substring(1);
    }
    return words.join(" ");
  }

  static String applyAbbreviation(String input) {
    for (String abbreviation in abbreviation) {
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
