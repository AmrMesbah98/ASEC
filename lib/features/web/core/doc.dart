/// `Doc` — a Firestore document with forgiving typed getters.
///
/// The site renders whatever the admin saved. A missing field, a number
/// saved as text or a list saved as null must never break a page, so every
/// getter falls back instead of throwing.
///
/// LANGUAGE: text fields have an English twin, `{key}_en`. While the site is
/// in English, `s()` / `l()` return the twin when it is filled, else the
/// Arabic value (so nothing disappears before it is translated). In Arabic
/// they behave exactly as before. Keys that have no twin (URLs, ids, phone
/// numbers) are unaffected.
///
/// `txt(key, L(ar, en))` is for texts that have a built-in default (section
/// titles, button labels): in English an untranslated field shows the
/// built-in English default rather than the Arabic.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart' show TextDirection;

import 'package:asec/features/web/core/builtin_en.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/seed_english.dart';

class Doc {
  const Doc(this.id, this.data);

  factory Doc.of(DocumentSnapshot<Map<String, dynamic>> snap) =>
      Doc(snap.id, snap.data() ?? <String, dynamic>{});

  static const Doc empty = Doc('', <String, dynamic>{});

  final String id;
  final Map<String, dynamic> data;

  bool get exists => id.isNotEmpty;

  /// The built-in English of a starter document (builtin_en.dart), found by
  /// its id, its slug or its Arabic title.
  Map<String, Object>? get _builtInEnglish {
    final Map<String, Object>? byId = kBuiltInEnglish[id] ?? kBuiltInEnglish[raw('slug')];
    if (byId != null) return byId;
    final String title = raw('title').trim();
    return kBuiltInEnglish[kBuiltInEnglishByArabicTitle[title] ?? ''];
  }

  /// The bundled English of this starter document: by its id, else by its
  /// title (a copy saved under another id).
  Object? _seed(String key) =>
      SeedEnglish.value(id, key) ?? SeedEnglish.byTitle(raw('title'), key);

  String s(String key, [String fallback = '']) {
    if (!AppLang.isAr) {
      final String en = raw('${key}_en');
      if (en.trim().isNotEmpty) return en;
      // Starter content the admin has not translated yet.
      final Object? seed = _seed(key);
      if (seed is String) return seed;
      final Object? built = _builtInEnglish?[key];
      if (built is String) return built;
    }
    String out = raw(key);
    // Imported titles hold both languages ("برج المختار El-Moktar Tower");
    // the Arabic site shows only the Arabic part, the English site only the
    // English part.
    if (key == 'title') out = AppLang.isAr ? _arabicOnly(out) : _englishOnly(out);
    return out.isEmpty ? fallback : out;
  }

  /// "برج المختار El-Moktar Tower" → "El-Moktar Tower". Unchanged when there
  /// is no English part.
  static String _englishOnly(String text) {
    if (!_arabic.hasMatch(text)) return text;
    final RegExpMatch? m = _latinTail.firstMatch(text);
    final String en = m?.group(0)?.trim() ?? '';
    return en.length >= 3 ? en : text;
  }

  static final RegExp _latinTail = RegExp(r"\s+[A-Za-z][A-Za-z0-9 .,&'()\-]*$");

  static String _arabicOnly(String text) {
    if (!_arabic.hasMatch(text)) return text;
    final String cut = text.replaceFirst(_latinTail, '').trim();
    return _arabic.hasMatch(cut) ? cut : text;
  }

  /// ENGLISH ONLY: the `_en` twin, else the built-in English of starter
  /// content, else ''. Never falls back to the Arabic, and an `_en` field
  /// that still holds Arabic letters counts as empty.
  String en(String key) {
    String out = raw('${key}_en').trim();
    if (out.isEmpty) {
      final Object? seed = _seed(key);
      if (seed is String) out = seed.trim();
    }
    if (out.isEmpty) {
      final Object? built = _builtInEnglish?[key];
      if (built is String) out = built.trim();
    }
    return _arabic.hasMatch(out) ? '' : out;
  }

  static final RegExp _arabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');

  /// A text with a built-in default in both languages. Arabic: the field,
  /// else `def.ar`. English: the `_en` field, else `def.en`.
  String txt(String key, L def) {
    if (AppLang.isAr) {
      final String out = raw(key);
      return out.isEmpty ? def.ar : out;
    }
    final String en = raw('${key}_en');
    if (en.trim().isNotEmpty) return en;
    final Object? seed = _seed(key);
    return seed is String ? seed : def.en;
  }

  /// The stored value exactly, whatever the language.
  String raw(String key) {
    final Object? v = data[key];
    return v == null ? '' : v.toString();
  }

  /// Is there an English version of [key]? (Used to pick the text direction
  /// of long content such as an article body.)
  bool hasEn(String key) {
    if (_seed(key) != null) return true;
    final Object? v = data['${key}_en'];
    if (v is List) return v.isNotEmpty;
    return v != null && v.toString().trim().isNotEmpty;
  }

  /// The direction of [key]'s text in the current language: English content
  /// reads left-to-right, Arabic (or not yet translated) right-to-left.
  TextDirection dirOf(String key) =>
      !AppLang.isAr && hasEn(key) ? TextDirection.ltr : TextDirection.rtl;

  bool b(String key, [bool fallback = true]) {
    final Object? v = data[key];
    return v is bool ? v : fallback;
  }

  int i(String key, [int fallback = 0]) {
    final Object? v = data[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  List<String> l(String key) {
    if (!AppLang.isAr) {
      final List<String> en = _list('${key}_en');
      if (en.isNotEmpty) return en;
      final Object? seed = _seed(key);
      if (seed is List<String>) return seed;
      final Object? built = _builtInEnglish?[key];
      if (built is List<String>) return built;
    }
    return _list(key);
  }

  List<String> _list(String key) {
    final Object? v = data[key];
    if (v is! List) return const <String>[];
    return <String>[
      for (final Object? e in v)
        if (e != null && '$e'.trim().isNotEmpty) '$e',
    ];
  }

  List<Map<String, dynamic>> maps(String key) {
    final Object? v = data[key];
    if (v is! List) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final Object? e in v)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  DateTime? t(String key) {
    final Object? v = data[key];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
