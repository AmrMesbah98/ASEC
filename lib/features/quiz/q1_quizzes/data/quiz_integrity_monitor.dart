/// Counts, while a member takes a quiz, how many times they
///  * try to take a screenshot (or start a screen recording), and
///  * leave the quiz — minimise the window, switch to another app or window,
///    lock the phone.
/// The member sees the counts live; they are saved with the attempt and the
/// admin sees them in Results.
///
/// How each platform is detected:
///  * Android 14+ and iOS — the system reports every screenshot / recording
///    (ScreenProtection.captures, native side in MainActivity.kt /
///    SceneDelegate.swift).
///  * Windows, macOS, web — the Print Screen key, and on macOS ⌘⇧3 / ⌘⇧4 /
///    ⌘⇧5 when the system lets the app see them. Tools that take focus
///    (Snipping Tool, Win+Shift+S) count as leaving the quiz instead.
///  * Leaving: the app stops being the active window / app.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:asec/core/settings/screen_protection.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_integrity_event.dart';

class QuizIntegrityMonitor extends ChangeNotifier {
  int screenshots = 0;
  int recordings = 0;
  int leftApp = 0;
  int awaySeconds = 0;
  final List<QuizIntegrityEvent> events = <QuizIntegrityEvent>[];

  /// Called on each new event, e.g. to warn the member.
  void Function(QuizIntegrityEvent event)? onEvent;

  StreamSubscription<String>? _captures;
  AppLifecycleListener? _lifecycle;
  bool _keyHandlerOn = false;
  DateTime? _awaySince;
  DateTime? _lastKeyCapture;
  bool _running = false;

  bool get isRunning => _running;
  bool get isAway => _awaySince != null;

  /// Starts counting from zero.
  void start() {
    if (_running) return;
    screenshots = recordings = leftApp = awaySeconds = 0;
    events.clear();
    resume();
  }

  /// Keeps counting on top of the counts so far (e.g. after a failed submit).
  void resume() {
    if (_running) return;
    _running = true;
    _awaySince = null;

    _captures = ScreenProtection.captures.listen(_onCapture);
    _lifecycle = AppLifecycleListener(onStateChange: _onState);
    HardwareKeyboard.instance.addHandler(_onKey);
    _keyHandlerOn = true;
    notifyListeners();
  }

  /// Stops counting. A member who is still away (e.g. time ran out) gets
  /// that time added.
  void stop() {
    if (!_running) return;
    _comeBack();
    _running = false;
    _captures?.cancel();
    _captures = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    if (_keyHandlerOn) HardwareKeyboard.instance.removeHandler(_onKey);
    _keyHandlerOn = false;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  // ───────────────────────────── screenshots ─────────────────────────────

  void _onCapture(String type) {
    if (!_running) return;
    if (type == 'recording') {
      recordings++;
    } else {
      screenshots++;
    }
    _add(QuizIntegrityEvent(type: type, at: DateTime.now()));
  }

  bool _onKey(KeyEvent e) {
    if (!_running || e is KeyRepeatEvent) return false;
    final LogicalKeyboardKey k = e.logicalKey;
    final bool printScreen = k == LogicalKeyboardKey.printScreen;
    final bool macShot = defaultTargetPlatform == TargetPlatform.macOS &&
        e is KeyDownEvent &&
        HardwareKeyboard.instance.isMetaPressed &&
        HardwareKeyboard.instance.isShiftPressed &&
        (k == LogicalKeyboardKey.digit3 || k == LogicalKeyboardKey.digit4 || k == LogicalKeyboardKey.digit5);
    if (!printScreen && !macShot) return false;
    // Windows often sends only the key-up of Print Screen: count one per press.
    final DateTime now = DateTime.now();
    if (_lastKeyCapture != null && now.difference(_lastKeyCapture!) < const Duration(seconds: 1)) {
      return false;
    }
    _lastKeyCapture = now;
    _onCapture('screenshot');
    return false; // never block the key itself
  }

  // ───────────────────────────── leaving ─────────────────────────────

  void _onState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.resumed) {
      _comeBack();
    } else if (_awaySince == null) {
      // inactive (window lost focus / minimised), hidden, paused…
      _awaySince = DateTime.now();
      leftApp++;
      notifyListeners();
    }
  }

  void _comeBack() {
    final DateTime? since = _awaySince;
    if (since == null) return;
    _awaySince = null;
    final int seconds = DateTime.now().difference(since).inSeconds;
    awaySeconds += seconds;
    _add(QuizIntegrityEvent(type: 'left_app', at: since, seconds: seconds));
  }

  void _add(QuizIntegrityEvent e) {
    if (events.length < 100) events.add(e);
    notifyListeners();
    onEvent?.call(e);
  }
}
