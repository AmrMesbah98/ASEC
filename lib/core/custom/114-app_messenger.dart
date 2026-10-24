/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 114-app_messenger.dart
/// Purpose: Declares `AppMessenger` and `AppMessage` — every short message
///          of the app ("Saved", "Locked", an error …) as a small dialog in
///          the middle of the screen that closes by itself. Replaces every
///          SnackBar.
/// Author: ASEC team
/// Created: 24/10/2026
///
/// USE — the same shape the SnackBar code had:
///
/// ```dart
/// AppMessenger.of(context)
///   ..hide()
///   ..show(AppMessage(content: Text('Saved')));
///
/// // Before an `await`, keep the messenger, not the context:
/// final AppMessenger messenger = AppMessenger.of(context);
/// await save();
/// messenger.show(AppMessage(content: Text('Saved')));
/// ```
///
/// WHY AN OVERLAY, NOT A DIALOG ROUTE. The message looks like a dialog but
/// is not a route: it never takes the back button (so "press back again to
/// exit" still works), never pops the wrong page when it closes, and a page
/// that closes right after showing it does not take it along. One message at
/// a time — a new one replaces the one on screen. A tap anywhere closes it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';

/// One message: what to show, how long, and an optional accent colour
/// (the icon's tint; red for an error, green for a success …).
class AppMessage {
  const AppMessage({
    required this.content,
    this.duration = const Duration(seconds: 3),
    this.backgroundColor,
  });

  final Widget content;
  final Duration duration;

  /// The accent: the icon and its soft circle. Null = the brand colour.
  final Color? backgroundColor;
}

/// Shows [AppMessage]s over everything, on the app's root overlay.
class AppMessenger {
  AppMessenger._(this._overlay);

  /// Finds the root overlay now, so it is safe to use after an `await`.
  factory AppMessenger.of(BuildContext context) => AppMessenger._(
        Overlay.maybeOf(context, rootOverlay: true) ??
            Get.key.currentState?.overlay,
      );

  final OverlayState? _overlay;

  /// The message on screen, if any (one for the whole app).
  static _Shown? _current;

  /// Closes the message on screen, if any.
  void hide() => _current?.close();

  void show(AppMessage message) {
    final OverlayState? overlay = _overlay ?? Get.key.currentState?.overlay;
    if (overlay == null || !overlay.mounted) return;
    _current?.remove();
    final _Shown shown = _Shown();
    shown.entry = OverlayEntry(
      builder: (BuildContext context) => _MessageView(
        key: shown.viewKey,
        message: message,
        onTap: shown.close,
        onGone: shown.remove,
      ),
    );
    _current = shown;
    overlay.insert(shown.entry!);
    shown.timer = Timer(message.duration, shown.close);
  }
}

class _Shown {
  OverlayEntry? entry;
  Timer? timer;
  final GlobalKey<_MessageViewState> viewKey = GlobalKey<_MessageViewState>();

  /// Fades out, then leaves the overlay.
  void close() {
    timer?.cancel();
    final _MessageViewState? view = viewKey.currentState;
    if (view == null) {
      remove();
    } else {
      view.fadeOut();
    }
  }

  /// Leaves the overlay at once.
  void remove() {
    timer?.cancel();
    if (AppMessenger._current == this) AppMessenger._current = null;
    final OverlayEntry? e = entry;
    entry = null;
    if (e != null && e.mounted) e.remove();
  }
}

class _MessageView extends StatefulWidget {
  const _MessageView({
    super.key,
    required this.message,
    required this.onTap,
    required this.onGone,
  });

  final AppMessage message;
  final VoidCallback onTap;
  final VoidCallback onGone;

  @override
  State<_MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<_MessageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  )..forward();

  bool _leaving = false;

  void fadeOut() {
    if (_leaving) return;
    _leaving = true;
    _anim.reverse().whenComplete(widget.onGone);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.message.backgroundColor ?? AppColors.primary;
    final CurvedAnimation curve =
        CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    final double width = MediaQuery.sizeOf(context).width;

    return FadeTransition(
      opacity: curve,
      child: Stack(
        children: <Widget>[
          // The dim behind it; a tap anywhere closes the message.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: ColoredBox(color: Colors.black.withOpacity(0.25)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curve),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Material(
                  color: AppColors.card,
                  elevation: 12,
                  shadowColor: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (width - 48).clamp(200.0, 420.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: accent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 14),
                          DefaultTextStyle(
                            style: StyleText.fontSize14Weight500
                                .copyWith(color: AppColors.text, height: 1.5),
                            textAlign: TextAlign.center,
                            child: IconTheme(
                              data: IconThemeData(color: accent, size: 18),
                              child: widget.message.content,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
