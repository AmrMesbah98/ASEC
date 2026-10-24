/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_player_page.dart
/// Purpose: Declares `VideoPlayerPage` — plays one lesson with the full
///          Chewie player (scrub bar, volume, speed, full screen) and an
///          options bar under it.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 25/9/2026 - Chewie controls, speed chips, loop, restart, mute,
///          keyboard shortcuts and "resume where you stopped".
///
/// RESUME. The position is saved to GetStorage every few seconds under
/// `video_pos_<id>`, and the next open seeks there — unless the lesson was
/// almost finished, in which case it starts again from the top.

import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' show RxInterface, Worker, everAll;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:asec/core/settings/capture_context.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/data/download/video_file.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_link.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_card.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_loading_view.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/settings/app_connectivity.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/settings/app_integrity.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({
    super.key,
    required this.video,
    this.playlist = const <VideoItem>[],
    this.sequential = false,
  });

  /// A member's course: lessons unlock in order, and an unfinished lesson
  /// cannot be skipped through — seeking past the furthest point actually
  /// played jumps back to it.
  final bool sequential;

  final VideoItem video;

  /// The list the lesson was opened from — feeds "Up next" and autoplay.
  final List<VideoItem> playlist;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with WidgetsBindingObserver {
  static const List<double> _speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 2];

  VideoPlayerController? _video;
  Worker? _guard;
  ChewieController? _chewie;
  bool _failed = false;

  /// Playing the copy downloaded inside the app (no internet needed).
  bool _local = false;

  /// The exception text, shown under the message in debug builds only.
  String? _errorText;

  /// Set when the lesson reopened at a saved position — shows a chip.
  Duration? _resumedAt;

  bool _looping = false;
  double _volumeBeforeMute = 1;
  Timer? _saveTimer;

  final FocusNode _focus = FocusNode();

  /// Plays the next lesson when this one ends. Shared by every player page
  /// in this run of the app.
  static bool _autoplay = true;
  bool _advanced = false;

  /// The rest of the playlist, starting after the current lesson.
  List<VideoItem> get _upNext {
    final List<VideoItem> list = widget.playlist;
    final int at = list.indexWhere((VideoItem v) => v.id == widget.video.id);
    if (at < 0) return list.where((VideoItem v) => v.id != widget.video.id).toList();
    if (widget.sequential) return list.sublist(at + 1);
    return <VideoItem>[...list.sublist(at + 1), ...list.sublist(0, at)];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The app is only HIDDEN when it goes offline or the device fails the
    // security check — stop the lesson so it does not play on behind it.
    _guard = everAll(
      <RxInterface<dynamic>>[AppConnectivity.offline, AppIntegrity.issues],
      (_) {
        // A downloaded lesson keeps playing offline — that is its point.
        if ((AppConnectivity.offline.value && !_local) ||
            AppIntegrity.issues.isNotEmpty) {
          _video?.pause();
        }
      },
    );
    _open();
  }

  /// `video_player` has no implementation on Windows and Linux, and a stream
  /// can simply refuse to play. Either way the screen must end up offering
  /// the system player rather than a dead black box — hence the try/catch.
  Future<void> _open() async {
    try {
      // Downloaded inside the app → play that file, with or without internet.
      await VideoDownloads.ensureLoaded();
      final String? localPath = VideoDownloads.localPath(widget.video.id);
      _local = localPath != null;
      final VideoPlayerController video = localPath != null
          ? localVideoController(localPath)
          // A Google Drive share link becomes Drive's direct stream
          // (see VideoLink); every other link plays as it is.
          : VideoPlayerController.networkUrl(
              Uri.parse(VideoLink.playable(widget.video.url)));
      await video.initialize();
      if (!mounted) {
        await video.dispose();
        return;
      }

      // Resume, unless it was (nearly) finished last time.
      final Duration saved =
          VideoWatchStore.position(widget.video.id) ?? Duration.zero;
      final Duration total = video.value.duration;
      if (_on(AppFeature.videoResume) &&
          saved.inSeconds > 3 &&
          saved < total - const Duration(seconds: 5)) {
        await video.seekTo(saved);
        _resumedAt = saved;
      }

      final ChewieController chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: true,
        looping: _looping,
        aspectRatio:
            video.value.aspectRatio == 0 ? 16 / 9 : video.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: _on(AppFeature.videoSpeed),
        playbackSpeeds: _speeds,
        showControlsOnInitialize: true,
        hideControlsTimer: const Duration(seconds: 3),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primary.withOpacity(0.35),
          backgroundColor: Colors.white24,
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primary.withOpacity(0.35),
          backgroundColor: Colors.white24,
        ),
        placeholder: const ColoredBox(color: Colors.black),
        // Mid-lesson stalls get the same rippling button as the first load,
        // not Chewie's spinning circle.
        bufferingBuilder: (BuildContext context) => const VideoBufferingBadge(),
      );

      _saveTimer = Timer.periodic(const Duration(seconds: 3), (_) => _savePosition());
      video.addListener(_onTick);

      setState(() {
        _video = video;
        _chewie = chewie;
      });
      _focus.requestFocus();
    } catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _errorText = '$error';
        });
      }
    }
  }

  void _savePosition() {
    final VideoPlayerController? v = _video;
    if (v == null || !v.value.isInitialized) return;
    VideoWatchStore.save(widget.video.id, v.value.position, v.value.duration);
  }

  /// Ended → save as watched and, with autoplay on, open the next lesson.
  bool get _guardSkips =>
      widget.sequential &&
      AppFeatures.to.isOn(AppFeature.videoBlockSkip) &&
      !VideoWatchStore.isWatched(widget.video.id);

  bool _on(AppFeature f) => AppFeatures.to.isOn(f);
  DateTime _lastSkipWarning = DateTime(0);

  void _onTick() {
    final VideoPlayerController? v = _video;
    if (v == null) return;

    // NO SKIPPING AHEAD in an unfinished course lesson.
    if (_guardSkips && v.value.isInitialized) {
      final Duration pos = v.value.position;
      final Duration max = VideoWatchStore.maxWatched(widget.video.id);
      if (pos > max + const Duration(seconds: 3)) {
        v.seekTo(max);
        _warnNoSkip();
        return;
      }
      VideoWatchStore.raiseMaxWatched(widget.video.id, pos);
    }

    if (_advanced || _looping) return;
    final VideoPlayerValue value = v.value;
    final bool ended = value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 300) &&
        !value.isPlaying;
    if (!ended) return;
    _savePosition();
    if (mounted) setState(() {}); // shows the "Completed" chip
    final List<VideoItem> next = _upNext;
    if (!_autoplay || !_on(AppFeature.videoAutoplay) || next.isEmpty) return;
    _advanced = true;
    _openOther(next.first);
  }

  void _warnNoSkip() {
    final DateTime now = DateTime.now();
    if (now.difference(_lastSkipWarning).inSeconds < 3 || !mounted) return;
    _lastSkipWarning = now;
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(content: Text(FormatHelper.capitalize(S.of(context).noSkipAhead))));
  }

  Set<String> get _lockedIds => widget.sequential
      ? VideoWatchStore.lockedIds(
          <String>[for (final VideoItem v in widget.playlist) v.id])
      : const <String>{};

  void _openOther(VideoItem video) {
    if (_lockedIds.contains(video.id)) {
      AppMessenger.of(context)
        ..hide()
        ..show(
            AppMessage(content: Text(FormatHelper.capitalize(S.of(context).finishThisLessonFirst))));
      return;
    }
    _savePosition();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            VideoPlayerPage(
              video: video,
              playlist: widget.playlist,
              sequential: widget.sequential,
            ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _seekBy(int seconds) {
    final VideoPlayerController? v = _video;
    if (v == null) return;
    final Duration total = v.value.duration;
    Duration target = v.value.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;
    if (_guardSkips) {
      final Duration max = VideoWatchStore.maxWatched(widget.video.id);
      if (target > max) {
        target = max;
        _warnNoSkip();
      }
    }
    v.seekTo(target);
  }

  void _togglePlay() => _chewie?.togglePause();

  void _setSpeed(double speed) {
    _video?.setPlaybackSpeed(speed);
    setState(() {});
  }

  void _toggleMute() {
    final VideoPlayerController? v = _video;
    if (v == null) return;
    if (v.value.volume > 0) {
      _volumeBeforeMute = v.value.volume;
      v.setVolume(0);
    } else {
      v.setVolume(_volumeBeforeMute == 0 ? 1 : _volumeBeforeMute);
    }
    setState(() {});
  }

  void _changeVolume(double delta) {
    final VideoPlayerController? v = _video;
    if (v == null) return;
    v.setVolume((v.value.volume + delta).clamp(0.0, 1.0));
    setState(() {});
  }

  void _toggleLoop() {
    setState(() => _looping = !_looping);
    _video?.setLooping(_looping);
  }

  Future<void> _restart() async {
    await _video?.seekTo(Duration.zero);
    await _video?.play();
    setState(() => _resumedAt = null);
  }

  void _fullScreen() => _chewie?.enterFullScreen();

  Future<void> _openExternally() async {
    final Uri uri = Uri.parse(widget.video.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// The app went to the background, was minimised/hidden, or is closing —
  /// stop the lesson so it never plays on with no screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _savePosition();
      _video?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.pause();
    _savePosition();
    _video?.removeListener(_onTick);
    _saveTimer?.cancel();
    _guard?.dispose();
    _chewie?.dispose();
    _video?.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return CaptureTag(
      page: 'Video player',
      course: <String>[
        if (widget.video.category.isNotEmpty) widget.video.category,
        if (widget.video.subcategory.isNotEmpty) widget.video.subcategory,
      ].join(' › '),
      detail: widget.video.title,
      child: CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.keyK): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _seekBy(-10),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _seekBy(10),
        const SingleActivator(LogicalKeyboardKey.keyJ): () => _seekBy(-10),
        const SingleActivator(LogicalKeyboardKey.keyL): () => _seekBy(10),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _changeVolume(0.1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _changeVolume(-0.1),
        const SingleActivator(LogicalKeyboardKey.keyM): _toggleMute,
        const SingleActivator(LogicalKeyboardKey.keyF): _fullScreen,
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            // Default leading is 56 wide + 16 title spacing, which leaves a
            // big gap after the back arrow. 44 wide centres the 24px icon,
            // leaving exactly 10px before the title.
            leadingWidth: 44,
            titleSpacing: 0,
            title: Text(
              FormatHelper.capitalize(widget.video.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StyleText.fontSize16Weight600,
            ),
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final List<VideoItem> next =
                  _on(AppFeature.videoUpNext) ? _upNext : const <VideoItem>[];
              final bool side = constraints.maxWidth >= 1100 && next.isNotEmpty;
              final Widget main = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _player(context, s),
                    if (!_failed && _on(AppFeature.videoOptionsBar)) ...<Widget>[
                      SizedBox(height: 14.h),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: _OptionsBar(
                        // Null while loading: the bar shows disabled so the
                        // layout doesn't jump when the video is ready.
                        video: _chewie == null ? null : _video,
                        speeds: _on(AppFeature.videoSpeed) ? _speeds : const <double>[],
                        looping: _looping,
                        onSeekBy: _seekBy,
                        onTogglePlay: _togglePlay,
                        onSpeed: _setSpeed,
                        onToggleMute: _toggleMute,
                        onToggleLoop: _toggleLoop,
                        onRestart: _restart,
                        onFullScreen: _fullScreen,
                      ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: _Details(
                        video: widget.video,
                        duration: _video?.value.duration,
                        loading: _chewie == null && !_failed,
                      ),
                    ),
                    if (_chewie != null &&
                        (defaultTargetPlatform == TargetPlatform.macOS ||
                            defaultTargetPlatform == TargetPlatform.windows ||
                            defaultTargetPlatform == TargetPlatform.linux)) ...<Widget>[
                      SizedBox(height: 10.h),
                      Row(
                        children: <Widget>[
                          AppIcon(Icons.keyboard_rounded,
                              size: 16.sp, color: AppColors.secondaryText),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              FormatHelper.capitalize(s.playerShortcuts),
                              style: StyleText.fontSize11Weight400
                                  .copyWith(color: AppColors.secondaryText),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );

              final Widget upNext = _UpNext(
                videos: next,
                lockedIds: _lockedIds,
                numbers: widget.sequential
                    ? <String, int>{
                        for (int i = 0; i < widget.playlist.length; i++)
                          widget.playlist[i].id: i + 1,
                      }
                    : null,
                autoplay: _autoplay,
                showAutoplay: _on(AppFeature.videoAutoplay),
                onAutoplay: (bool v) => setState(() => _autoplay = v),
                onOpen: _openOther,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.h,
                  vertical: 16.h,
                ),
                child: side
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: main),
                          SizedBox(width: 24.w),
                          SizedBox(width: 400, child: upNext),
                        ],
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 960.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              main,
                              if (next.isNotEmpty) ...<Widget>[
                                SizedBox(height: 24.h),
                                upNext,
                              ],
                            ],
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    ),
    );
  }

  Widget _player(BuildContext context, S s) {
    if (_failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppErrorView(message: s.videoFailed),
          if (kDebugMode && _errorText != null) ...<Widget>[
            SizedBox(height: 8.h),
            SelectableText(
              '${widget.video.url}\n$_errorText',
              textAlign: TextAlign.center,
              style: StyleText.fontSize11Weight400
                  .copyWith(color: AppColors.red),
            ),
          ],
          // Opening the video outside the app hands over its link, so only
          // amrmesbah33@gmail.com gets this button.
          if (SessionController.to.current.isSuperAdmin) ...<Widget>[
            SizedBox(height: 12.h),
            AppButton(
              label: s.openExternally,
              icon: Icons.open_in_new_rounded,
              kind: AppButtonKind.subtle,
              onPressed: _openExternally,
            ),
          ],
        ],
      );
    }

    final ChewieController? chewie = _chewie;
    if (chewie == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: AppRadius.containerR,
          child: VideoLoadingView(
            title: widget.video.title,
            label: s.videoLoading,
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: AppRadius.containerR,
          child: AspectRatio(
            aspectRatio: chewie.aspectRatio ?? 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: Chewie(controller: chewie),
            ),
          ),
        ),
        if (_resumedAt != null)
          PositionedDirectional(
            top: 12,
            start: 12,
            child: _ResumeChip(
              text: s.playerResumedAt(_clock(_resumedAt!)),
              action: s.playerStartOver,
              onAction: _restart,
              onClose: () => setState(() => _resumedAt = null),
            ),
          ),
      ],
    );
  }
}

String _clock(Duration d) {
  final String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

// ── Options bar ─────────────────────────────────────────────────────────────

class _OptionsBar extends StatelessWidget {
  const _OptionsBar({
    required this.video,
    required this.speeds,
    required this.looping,
    required this.onSeekBy,
    required this.onTogglePlay,
    required this.onSpeed,
    required this.onToggleMute,
    required this.onToggleLoop,
    required this.onRestart,
    required this.onFullScreen,
  });

  final VideoPlayerController? video;
  final List<double> speeds;
  final bool looping;
  final void Function(int seconds) onSeekBy;
  final VoidCallback onTogglePlay;
  final void Function(double speed) onSpeed;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleLoop;
  final VoidCallback onRestart;
  final VoidCallback onFullScreen;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    // Rebuilt from the controller, so the glyphs and times follow the video
    // even when Chewie's own controls change it.
    final VideoPlayerController? controller = video;
    if (controller == null) {
      // Loading: same layout, greyed out and not tappable.
      return IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: _bar(context, s, VideoPlayerValue(duration: Duration.zero)),
        ),
      );
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (BuildContext context, VideoPlayerValue value, Widget? _) =>
          _bar(context, s, value),
    );
  }

  Widget _bar(BuildContext context, S s, VideoPlayerValue value) {
        final bool muted = value.volume == 0;
        final Duration total = value.duration;
        final Duration pos = value.position;
        final Duration left = total - pos;

        return AppCard(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Row 1 — transport + time.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.w,
                runSpacing: 8.h,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12.w,
                    runSpacing: 6.h,
                    children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _RoundButton(
                        icon: Icons.replay_10_rounded,
                        tooltip: '-10 s',
                        onTap: () => onSeekBy(-10),
                      ),
                      SizedBox(width: 6.w),
                      _RoundButton(
                        icon: value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        tooltip: value.isPlaying ? 'Pause' : 'Play',
                        filled: true,
                        big: true,
                        onTap: onTogglePlay,
                      ),
                      SizedBox(width: 6.w),
                      _RoundButton(
                        icon: Icons.forward_10_rounded,
                        tooltip: '+10 s',
                        onTap: () => onSeekBy(10),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        FormatHelper.capitalize('${_clock(pos)} / ${_clock(total)}'),
                        style: StyleText.fontSize13Weight600
                            .copyWith(color: AppColors.text),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        FormatHelper.capitalize('-${_clock(left.isNegative ? Duration.zero : left)}'),
                        style: StyleText.fontSize12Weight400
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                    ],
                  ),
                  Wrap(
                    spacing: 0,
                    runSpacing: 6.h,
                    children: <Widget>[
                      _ToggleButton(
                        icon: muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        label: s.playerMute,
                        active: muted,
                        onTap: onToggleMute,
                      ),
                      SizedBox(width: 6.w),
                      _ToggleButton(
                        icon: Icons.repeat_rounded,
                        label: s.playerLoop,
                        active: looping,
                        onTap: onToggleLoop,
                      ),
                      SizedBox(width: 6.w),
                      _ToggleButton(
                        icon: Icons.restart_alt_rounded,
                        label: s.playerRestart,
                        active: false,
                        onTap: onRestart,
                      ),
                      SizedBox(width: 6.w),
                      _ToggleButton(
                        icon: Icons.fullscreen_rounded,
                        label: s.playerFullScreen,
                        active: false,
                        onTap: onFullScreen,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Divider(height: 1, color: AppColors.secondaryText.withOpacity(0.15)),
              SizedBox(height: 12.h),

              // Row 2 — speed chips + volume slider.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12.w,
                runSpacing: 10.h,
                children: <Widget>[
                  if (speeds.isNotEmpty)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 6.h,
                    children: <Widget>[
                      AppIcon(Icons.speed_rounded,
                          size: 18.sp, color: AppColors.secondaryText),
                      SizedBox(width: 6.w),
                      Text(
                        FormatHelper.capitalize(s.playerSpeed),
                        style: StyleText.fontSize12Weight600
                            .copyWith(color: AppColors.secondaryText),
                      ),
                      SizedBox(width: 10.w),
                      for (final double speed in speeds) ...<Widget>[
                        _SpeedChip(
                          speed: speed,
                          selected: value.playbackSpeed == speed,
                          onTap: () => onSpeed(speed),
                        ),
                        SizedBox(width: 4.w),
                      ],
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220, minWidth: 140),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppIcon(
                          muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_down_rounded,
                          size: 18.sp,
                          color: AppColors.secondaryText,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: SliderComponentShape.noOverlay,
                              activeTrackColor: AppColors.primary,
                              thumbColor: AppColors.primary,
                              inactiveTrackColor:
                                  AppColors.secondaryText.withOpacity(0.25),
                            ),
                            child: Slider(
                              value: value.volume.clamp(0.0, 1.0),
                              onChanged: (double v) => video?.setVolume(v),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 34.w,
                          child: Text(
                            FormatHelper.capitalize('${(value.volume * 100).round()}%'),
                            textAlign: TextAlign.end,
                            style: StyleText.fontSize11Weight600
                                .copyWith(color: AppColors.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
    this.big = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final double size = big ? 44.r : 36.r;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.primary : AppColors.chip,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AppIcon(
                icon,
                size: big ? 26.sp : 20.sp,
                color: filled ? AppColors.textButton : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.primary : AppColors.secondaryText;
    return Tooltip(
      message: label,
      child: Material(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(8.r),
            child: AppIcon(icon, size: 20.sp, color: color),
          ),
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.speed,
    required this.selected,
    required this.onTap,
  });

  final double speed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label =
        '${speed == speed.roundToDouble() ? speed.toInt() : speed}x';
    return Material(
      color: selected ? AppColors.primary : AppColors.chip,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          child: Text(
            FormatHelper.capitalize(label),
            style: StyleText.fontSize12Weight600.copyWith(
              color: selected ? AppColors.textButton : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumeChip extends StatelessWidget {
  const _ResumeChip({
    required this.text,
    required this.action,
    required this.onAction,
    required this.onClose,
  });

  final String text;
  final String action;
  final VoidCallback onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(start: 12.w, end: 4.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(Icons.history_rounded, size: 16.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            FormatHelper.capitalize(text),
            style: StyleText.fontSize12Weight500.copyWith(color: Colors.white),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              FormatHelper.capitalize(action),
              style: StyleText.fontSize12Weight600
                  .copyWith(color: AppColors.primary),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: AppIcon(Icons.close_rounded, size: 16.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ── Details ─────────────────────────────────────────────────────────────────

class _Details extends StatelessWidget {
  const _Details({
    required this.video,
    required this.duration,
    this.loading = false,
  });

  final VideoItem video;
  // Kept so the call site doesn't change; duration/size are no longer shown.
  final Duration? duration;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool done = VideoWatchStore.isWatched(video.id);
    final bool hasDescription = video.description.trim().isNotEmpty;

    // Title only — the card hugs the name. The "Completed" chip and the
    // description appear only when they exist.
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            FormatHelper.capitalize(video.title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          if (done) ...<Widget>[
            SizedBox(height: 10.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.check_circle_rounded,
                        size: 15, color: Colors.white),
                    SizedBox(width: 5.w),
                    Text(
                      FormatHelper.capitalize(s.lessonCompleted),
                      style: StyleText.fontSize12Weight600
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasDescription) ...<Widget>[
            SizedBox(height: 10.h),
            Text(
              FormatHelper.capitalize(video.description),
              style: StyleText.fontSize14Weight400
                  .copyWith(color: AppColors.secondaryText, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Up next ─────────────────────────────────────────────────────────────────

class _UpNext extends StatelessWidget {
  const _UpNext({
    required this.videos,
    required this.autoplay,
    required this.onAutoplay,
    required this.onOpen,
    this.lockedIds = const <String>{},
    this.numbers,
    this.showAutoplay = true,
  });

  final bool showAutoplay;
  final Set<String> lockedIds;
  final Map<String, int>? numbers;
  final List<VideoItem> videos;
  final bool autoplay;
  final ValueChanged<bool> onAutoplay;
  final void Function(VideoItem video) onOpen;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                FormatHelper.capitalize(s.upNext),
                style: StyleText.fontSize16Weight700
                    .copyWith(color: AppColors.text),
              ),
            ),
            if (showAutoplay) ...<Widget>[
              Text(
                FormatHelper.capitalize(s.autoplay),
                style: StyleText.fontSize12Weight600
                    .copyWith(color: AppColors.secondaryText),
              ),
              SizedBox(width: 6.w),
              Switch.adaptive(
                value: autoplay,
                activeTrackColor: AppColors.secondaryPrimary,
                onChanged: onAutoplay,
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        for (int i = 0; i < videos.length; i++) ...<Widget>[
          FadeSlideIn(
            delay: staggerDelay(i, stepMs: 60),
            offset: const Offset(24, 0),
            child: VideoListTile(
              video: videos[i],
              onTap: () => onOpen(videos[i]),
              locked: lockedIds.contains(videos[i].id),
              lessonNumber: numbers?[videos[i].id],
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ],
    );
  }
}
