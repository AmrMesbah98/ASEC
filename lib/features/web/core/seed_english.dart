/// Module: web / core
///
///*************************** FILE INFO ****************************///
/// File Name: seed_english.dart
/// Purpose: Declares `SeedEnglish` — the English of the site's starter
///          content (assets/web/seed/site_seed_en.json), used AUTOMATICALLY
///          while the site is in English and a document's `{key}_en` field
///          is still empty. Before, that English reached the site only after
///          an admin pressed Import → "Add English content", so the English
///          site kept showing Arabic (Why Work With Us, Our Work, Our
///          Partners…). An English text typed in the panel always wins.
/// Author: ASEC team
/// Created: 25/10/2026
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:asec/features/web/core/i18n.dart';

abstract final class SeedEnglish {
  /// document id → `{key}_en` → value. Site settings are under 'main'.
  static Map<String, Map<String, dynamic>> _byId = const <String, Map<String, dynamic>>{};
  static bool _started = false;

  /// Reads the bundled English once; the site re-renders when it arrives.
  static Future<void> load() async {
    if (_started) return;
    _started = true;
    try {
      final Object? json =
          jsonDecode(await rootBundle.loadString('assets/web/seed/site_seed_en.json'));
      if (json is! Map) return;
      final Map<String, Map<String, dynamic>> out = <String, Map<String, dynamic>>{};
      final Object? settings = json['settings'];
      if (settings is Map) out['main'] = Map<String, dynamic>.from(settings);
      for (final String coll in <String>['services', 'features', 'projects', 'partners', 'testimonials']) {
        final Object? byId = json[coll];
        if (byId is! Map) continue;
        for (final MapEntry<dynamic, dynamic> e in byId.entries) {
          if (e.value is Map) out['${e.key}'] = Map<String, dynamic>.from(e.value as Map);
        }
      }
      _byId = out;
      if (!AppLang.isAr) AppLang.rebuildAll();
    } catch (_) {
      // Missing asset: the site simply keeps its Arabic fallback.
    }
  }

  /// The bundled English for [key] of document [id], or null.
  static Object? value(String id, String key) {
    final Object? v = _byId[id]?['${key}_en'];
    if (v is String) return v.trim().isEmpty ? null : v;
    if (v is List) {
      final List<String> list = <String>[
        for (final Object? e in v)
          if (e != null && '$e'.trim().isNotEmpty) '$e',
      ];
      return list.isEmpty ? null : list;
    }
    return null;
  }
}
