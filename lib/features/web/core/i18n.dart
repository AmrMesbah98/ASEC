/// Language for the whole website — the public site AND its admin panel —
/// Arabic (right-to-left) or English (left-to-right).
///
/// `L('عربي', 'English').t` picks the side for the current language.
///
/// Content the admin types (titles, texts, lists) is stored twice: the Arabic
/// field (`title`) and its English twin (`title_en`). `Doc.s('title')` returns
/// the right one for the current language and falls back to the Arabic when
/// the English is still empty — see core/doc.dart.
///
/// On the web the choice is remembered in the browser, and a link can force
/// a language with `?lang=en` / `?lang=ar` (see core/lang_store_web.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:asec/features/web/core/lang_store_stub.dart'
    if (dart.library.js_interop) 'package:asec/features/web/core/lang_store_web.dart' as store;

abstract final class AppLang {
  static final ValueNotifier<Locale> locale = _create();

  static ValueNotifier<Locale> _create() {
    final ValueNotifier<Locale> n = ValueNotifier<Locale>(const Locale('ar'));
    n.addListener(_onChange);
    return n;
  }

  static bool get isAr => locale.value.languageCode == 'ar';

  static String get code => isAr ? 'ar' : 'en';

  static void toggle() => set(isAr ? 'en' : 'ar');

  static void set(String code) {
    final Locale next = Locale(code == 'en' ? 'en' : 'ar');
    if (locale.value != next) locale.value = next;
  }

  static TextDirection get direction => isAr ? TextDirection.rtl : TextDirection.ltr;

  /// The website's starting language (web_main.dart): `?lang=` in the link,
  /// else the visitor's last choice, else Arabic. From then on every change
  /// is remembered.
  static void initForWebsite() {
    final String? fromLink = Uri.base.queryParameters['lang'];
    final String? saved = store.readSavedLang();
    final String start = (fromLink == 'en' || fromLink == 'ar') ? fromLink! : (saved ?? 'ar');
    set(start);
    store.applyToDocument(code);
    _persist = true;
  }

  static bool _persist = false;

  static void _onChange() {
    if (_persist) store.saveLang(code);
    store.applyToDocument(code);
    _rebuildAll();
  }

  /// Pages are `const` widgets whose texts are picked while they build, so a
  /// language change must rebuild them. Mark every element dirty — state
  /// (scroll position, typed form fields) is kept.
  /// Re-renders every page (used when late content such as the bundled
  /// English arrives).
  static void rebuildAll() => _rebuildAll();

  static void _rebuildAll() {
    final WidgetsBinding? binding = _binding;
    final Element? root = binding?.rootElement;
    if (binding == null || root == null) return;
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // Changed while a frame is building (e.g. from an initState): next frame.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final Element? r = WidgetsBinding.instance.rootElement;
        if (r != null) mark(r);
      });
    } else {
      mark(root);
    }
  }

  static WidgetsBinding? get _binding {
    try {
      return WidgetsBinding.instance;
    } catch (_) {
      return null; // not initialised yet
    }
  }
}

class L {
  const L(this.ar, this.en);

  final String ar;
  final String en;

  String get t => AppLang.isAr ? ar : en;

  @override
  String toString() => t;
}
