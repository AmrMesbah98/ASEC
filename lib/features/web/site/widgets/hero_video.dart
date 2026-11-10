/// The home page's black video section, drawn like asecbim.com's: the video
/// across the full width on black, a browser-style player bar over its foot
/// (play, time, sound, full screen, speed menu, seek bar) and the red
/// "ابدا رحلتك نحو الابتكار" button centred under it.
///
/// It PLAYS BY ITSELF as soon as the page opens — muted and looping,
/// because a browser only lets a page start a video on its own when it is
/// muted. The sound button in the bar turns the sound on. If a browser still
/// refuses, the video waits at 0:00 with its play button. Every icon is an SVG (AppIcon). The bar
/// is left-to-right like a browser's, even on the Arabic page.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/site/site_nav.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class HeroVideo extends StatefulWidget {
  const HeroVideo({super.key, required this.url, required this.poster, required this.buttonText});

  final String url;
  final String poster;
  final String buttonText;

  @override
  State<HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<HeroVideo> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _failed = false;

  /// True once the visitor pressed play — until then the poster may cover
  /// the first frame.
  bool _started = false;

  /// While the full-screen page shows the video, this one draws the poster:
  /// one video surface at a time (a browser cannot show it twice).
  bool _inFullscreen = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(HeroVideo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _c?.dispose();
      _c = null;
      _ready = false;
      _failed = false;
      _started = false;
      _init();
    }
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) return;
    final VideoPlayerController c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c = c;
    try {
      await c.initialize();
      if (!mounted || _c != c) return;
      await c.setLooping(true);
      await c.setVolume(0); // muted: required for a browser to autoplay
      setState(() {
        _ready = true;
        _started = true;
      });
      try {
        await c.play();
      } catch (_) {
        // Autoplay refused — the bar's play button is there.
      }
    } catch (_) {
      if (mounted && _c == c) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _openFullscreen() async {
    final VideoPlayerController? c = _c;
    if (c == null) return;
    setState(() => _inFullscreen = true);
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, _, _) => _FullscreenPlayer(controller: c, poster: widget.poster),
        transitionsBuilder: (_, Animation<double> a, _, Widget child) => FadeTransition(opacity: a, child: child),
      ),
    );
    if (mounted) setState(() => _inFullscreen = false);
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? c = _c;
    final double side = context.isMobile ? 0 : 20;
    final double ratio = _ready && c != null && c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;

    return Container(
      color: WebColors.black,
      padding: EdgeInsets.fromLTRB(side, 0, side, 20),
      child: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: ratio,
            child: _ready && c != null && !_inFullscreen
                ? _Player(
                    controller: c,
                    poster: _started ? '' : widget.poster,
                    onStarted: () {
                      if (!_started) setState(() => _started = true);
                    },
                    onFullscreen: _openFullscreen,
                  )
                : _Still(poster: widget.poster, loading: !_failed && widget.url.isNotEmpty && !_inFullscreen),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: context.isMobile ? 22 : 30, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => siteGo(context, '/contact'),
            child: Text(FormatHelper.capitalize(widget.buttonText.isEmpty
                ? const L('ابدا رحلتك نحو الابتكار', 'Start your journey to innovation').t
                : widget.buttonText)),
          ),
        ],
      ),
    );
  }
}

/// Before the video can play (or if it cannot): the poster, or black.
class _Still extends StatelessWidget {
  const _Still({required this.poster, required this.loading});

  final String poster;
  final bool loading;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (poster.isEmpty) const ColoredBox(color: WebColors.black) else NetImage(poster),
          if (loading)
            const Center(
              child: SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 2.6, color: WebColors.white)),
            ),
        ],
      );
}

// ── The player ──────────────────────────────────────────────────────────────

class _Player extends StatefulWidget {
  const _Player({
    required this.controller,
    required this.poster,
    required this.onStarted,
    required this.onFullscreen,
    this.fullscreen = false,
  });

  final VideoPlayerController controller;

  /// Covers the first frame until the first play; '' for none.
  final String poster;
  final VoidCallback onStarted;
  final VoidCallback onFullscreen;
  final bool fullscreen;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> {
  bool _barVisible = true;
  Timer? _hide;

  VideoPlayerController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    // Autoplay: the bar shows for a moment, then gets out of the way.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _poke();
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  /// Shows the bar; while playing, hides it again after a moment of stillness.
  void _poke() {
    _hide?.cancel();
    if (!_barVisible) setState(() => _barVisible = true);
    // Checked when it fires, not now: right after autoplay the video may be
    // a few frames from "playing".
    _hide = Timer(const Duration(milliseconds: 2600), () {
      if (mounted && c.value.isPlaying) setState(() => _barVisible = false);
    });
  }

  Future<void> _togglePlay() async {
    final VideoPlayerValue v = c.value;
    if (v.isPlaying) {
      await c.pause();
    } else {
      if (v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 250)) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
      widget.onStarted();
    }
    _poke();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _poke(),
      onEnter: (_) => _poke(),
      onExit: (_) {
        if (c.value.isPlaying) setState(() => _barVisible = false);
      },
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: c,
        builder: (BuildContext context, VideoPlayerValue v, _) {
          final bool showBar = _barVisible || !v.isPlaying;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                onDoubleTap: widget.onFullscreen,
                child: ColoredBox(
                  color: WebColors.black,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: v.aspectRatio > 0 ? v.aspectRatio : 16 / 9,
                      child: VideoPlayer(c),
                    ),
                  ),
                ),
              ),
              if (widget.poster.isNotEmpty && !v.isPlaying && v.position == Duration.zero)
                IgnorePointer(child: NetImage(widget.poster)),
              // The page's slight darkening, like the WordPress player.
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: v.isPlaying ? 0 : 1,
                  child: ColoredBox(color: WebColors.black.withValues(alpha: 0.28)),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !showBar,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: showBar ? 1 : 0,
                    child: _Bar(
                      controller: c,
                      value: v,
                      fullscreen: widget.fullscreen,
                      onPlay: _togglePlay,
                      onFullscreen: widget.onFullscreen,
                      onActivity: _poke,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The browser-style bar: controls row, then the seek bar under it.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.controller,
    required this.value,
    required this.fullscreen,
    required this.onPlay,
    required this.onFullscreen,
    required this.onActivity,
  });

  final VideoPlayerController controller;
  final VideoPlayerValue value;
  final bool fullscreen;
  final VoidCallback onPlay;
  final VoidCallback onFullscreen;
  final VoidCallback onActivity;

  static const List<double> _speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 2];

  @override
  Widget build(BuildContext context) {
    final bool small = context.isMobile && !fullscreen;
    final double icon = small ? 22 : 28;
    final bool ended = value.duration > Duration.zero && value.position >= value.duration - const Duration(milliseconds: 250);
    final bool muted = value.volume == 0;

    Widget btn(IconData i, String tip, VoidCallback onTap) => IconButton(
          tooltip: tip,
          onPressed: () {
            onTap();
            onActivity();
          },
          padding: EdgeInsets.all(small ? 6 : 10),
          constraints: const BoxConstraints(),
          icon: AppIcon(i, size: icon, color: WebColors.white),
        );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[WebColors.black.withValues(alpha: 0), WebColors.black.withValues(alpha: 0.72)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(small ? 8 : 24, small ? 18 : 40, small ? 8 : 24, small ? 8 : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  btn(
                    value.isPlaying ? Icons.pause : (ended ? Icons.replay : Icons.play_arrow),
                    value.isPlaying ? const L('إيقاف مؤقت', 'Pause').t : const L('تشغيل', 'Play').t,
                    onPlay,
                  ),
                  SizedBox(width: small ? 4 : 10),
                  Text(
                    FormatHelper.capitalize('${_fmt(value.position)} / ${_fmt(value.duration)}'),
                    style: TextStyle(
                      color: WebColors.white,
                      fontSize: small ? 12 : 14,
                      fontFamily: 'Cairo',
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  btn(muted ? Icons.volume_off : Icons.volume_up, muted ? const L('تشغيل الصوت', 'Unmute').t : const L('كتم الصوت', 'Mute').t,
                      () => controller.setVolume(muted ? 1 : 0)),
                  SizedBox(width: small ? 2 : 14),
                  btn(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      fullscreen ? const L('الخروج من ملء الشاشة', 'Exit full screen').t : const L('ملء الشاشة', 'Full screen').t,
                      onFullscreen),
                  SizedBox(width: small ? 2 : 14),
                  PopupMenuButton<double>(
                    tooltip: const L('المزيد', 'More').t,
                    color: const Color(0xFF1F1F1F),
                    position: PopupMenuPosition.over,
                    onOpened: onActivity,
                    onSelected: (double s) {
                      controller.setPlaybackSpeed(s);
                      onActivity();
                    },
                    itemBuilder: (_) => <PopupMenuEntry<double>>[
                      PopupMenuItem<double>(
                        enabled: false,
                        height: 34,
                        child: Row(
                          children: <Widget>[
                            const AppIcon(Icons.speed_rounded, size: 18, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(FormatHelper.capitalize(const L('سرعة التشغيل', 'Playback speed').t),
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      for (final double s in _speeds)
                        PopupMenuItem<double>(
                          value: s,
                          height: 38,
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 22,
                                child: value.playbackSpeed == s
                                    ? const AppIcon(Icons.check, size: 18, color: WebColors.white)
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(FormatHelper.capitalize(s == 1 ? const L('عادي', 'Normal').t : '${s}x'), style: const TextStyle(color: WebColors.white)),
                            ],
                          ),
                        ),
                    ],
                    child: Padding(
                      padding: EdgeInsets.all(small ? 6 : 10),
                      child: AppIcon(Icons.more_vert, size: icon, color: WebColors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: small ? 2 : 6),
              _SeekBar(controller: controller, value: value, onActivity: onActivity),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }
}

/// Played (white) · buffered (light) · rest (faint), with a thumb while the
/// pointer is over it. Tap or drag to seek.
class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.controller, required this.value, required this.onActivity});

  final VideoPlayerController controller;
  final VideoPlayerValue value;
  final VoidCallback onActivity;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _hover = false;

  /// While dragging, the bar follows the finger, not the (lagging) video.
  double? _drag;

  void _seekTo(double dx, double width) {
    final Duration total = widget.value.duration;
    if (total <= Duration.zero || width <= 0) return;
    final double f = (dx / width).clamp(0.0, 1.0);
    setState(() => _drag = f);
    widget.controller.seekTo(total * f);
    widget.onActivity();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerValue v = widget.value;
    final int total = v.duration.inMilliseconds;
    double frac(Duration d) => total <= 0 ? 0 : (d.inMilliseconds / total).clamp(0.0, 1.0);
    final double played = _drag ?? frac(v.position);
    double buffered = 0;
    for (final DurationRange r in v.buffered) {
      final double e = frac(r.end);
      if (e > buffered) buffered = e;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final double w = bc.maxWidth;
        final double track = _hover || _drag != null ? 5 : 4;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails d) => _seekTo(d.localPosition.dx, w),
            onTapUp: (_) => setState(() => _drag = null),
            onHorizontalDragStart: (DragStartDetails d) => _seekTo(d.localPosition.dx, w),
            onHorizontalDragUpdate: (DragUpdateDetails d) => _seekTo(d.localPosition.dx, w),
            onHorizontalDragEnd: (_) => setState(() => _drag = null),
            child: SizedBox(
              height: 18,
              width: w,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: <Widget>[
                  _line(w, track, WebColors.white.withValues(alpha: 0.28)),
                  _line(w * buffered, track, WebColors.white.withValues(alpha: 0.5)),
                  _line(w * played, track, WebColors.white),
                  if (_hover || _drag != null)
                    Positioned(
                      left: (w * played - 7).clamp(-7.0, w - 7),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(color: WebColors.white, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _line(double width, double height, Color color) => Container(
        width: width.clamp(0.0, double.infinity),
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height)),
      );
}

// ── Full screen ─────────────────────────────────────────────────────────────

class _FullscreenPlayer extends StatelessWidget {
  const _FullscreenPlayer({required this.controller, required this.poster});

  final VideoPlayerController controller;
  final String poster;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WebColors.black,
        body: _Player(
          controller: controller,
          poster: '',
          fullscreen: true,
          onStarted: () {},
          onFullscreen: () => Navigator.of(context).maybePop(),
        ),
      );
}
