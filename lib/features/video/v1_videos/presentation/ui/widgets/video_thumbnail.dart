/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_thumbnail.dart
/// Purpose: Declares `VideoThumbnail` — a 16:9 poster in the style of a video
///          site: a cover, the duration (or size) badge bottom-right, a "NEW"
///          or "Draft" tag top-left, a red watch-progress bar along the
///          bottom, and a play button that appears on hover.
/// Author: ASEC team
/// Created: 25/9/2026
///
/// THE COVER. A Google Drive video shows Drive's own cover image for it (a
/// frame from the video). Until that image has loaded — or when there is
/// none (not a Drive file, a private file, no network) — the cover is drawn:
/// one of a few gradients picked from the video id (stable — the same lesson
/// always gets the same colours) with the title set large on it.
/// Updated: 1/10/2026 - Drive cover image.

import 'package:flutter/material.dart';
import 'package:asec/core/custom/116-app_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_link.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.video,
    this.hover = false,
    this.compact = false,
    this.nowPlaying = false,
    this.locked = false,
    this.lessonNumber,
    this.lockedBehind,
  });

  /// Covered by a padlock: the previous lesson is not finished yet.
  final bool locked;

  /// "1", "2"… shown top-left in a course. Null hides it.
  final int? lessonNumber;

  /// The lesson that has to be finished first — for the padlock caption.
  final int? lockedBehind;

  final VideoItem video;

  /// Shows the centred play button and lightens the cover.
  final bool hover;

  /// Small "up next" size: smaller title, no tag.
  final bool compact;

  /// Marks the lesson currently open in the player.
  final bool nowPlaying;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF4F46E5), Color(0xFF7C3AED)],
    <Color>[Color(0xFF0EA5E9), Color(0xFF2563EB)],
    <Color>[Color(0xFFF97316), Color(0xFFDC2626)],
    <Color>[Color(0xFF10B981), Color(0xFF047857)],
    <Color>[Color(0xFFEC4899), Color(0xFF9333EA)],
    <Color>[Color(0xFFF59E0B), Color(0xFFB45309)],
    <Color>[Color(0xFF14B8A6), Color(0xFF0E7490)],
    <Color>[Color(0xFF64748B), Color(0xFF1E293B)],
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.engineering_rounded,
    Icons.architecture_rounded,
    Icons.construction_rounded,
    Icons.apartment_rounded,
    Icons.school_rounded,
    Icons.design_services_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final int seed = video.id.codeUnits.fold<int>(0, (int a, int b) => a * 31 + b).abs();
    final List<Color> colors = _palettes[seed % _palettes.length];
    final IconData icon = _icons[seed % _icons.length];

    final Duration? duration = VideoWatchStore.duration(video.id);
    final double progress = VideoWatchStore.progress(video.id);
    final bool isNew = video.createdAt != null &&
        DateTime.now().difference(video.createdAt!).inDays < 7;

    final String? badge = duration != null
        ? videoClock(duration)
        : (video.sizeBytes > 0 ? s.megabytes(video.sizeMb) : null);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 8.r : 12.r),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Cover: Drive's image when it loads, else the drawn poster.
            VideoCoverImage(
              url: video.url,
              width: compact ? 320 : 640,
              placeholder: _drawnPoster(colors, icon),
            ),
            // Hover wash + play button.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: !locked && (hover || nowPlaying) ? 1 : 0,
              child: ColoredBox(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: nowPlaying
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.equalizer_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              FormatHelper.capitalize(s.nowPlaying),
                              style: StyleText.fontSize11Weight700
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        )
                      : Container(
                          width: compact ? 34 : 54,
                          height: compact ? 34 : 54,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: compact ? 22 : 34,
                            color: colors.last,
                          ),
                        ),
                ),
              ),
            ),
            // Top-left: lesson number, then NEW / Draft.
            PositionedDirectional(
              top: compact ? 4 : 8,
              start: compact ? 4 : 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (lessonNumber != null)
                    _Tag(
                      text: compact ? '$lessonNumber' : s.lessonNumber(lessonNumber!),
                      color: Colors.black.withOpacity(0.75),
                    ),
                  if (!compact && (!video.published || (isNew && progress < 1))) ...<Widget>[
                    if (lessonNumber != null) const SizedBox(width: 4),
                    _Tag(
                      text: video.published ? s.videoNewTag : s.draft,
                      color: video.published
                          ? const Color(0xFFE11D48)
                          : AppColors.statusPending,
                    ),
                  ],
                ],
              ),
            ),
            // Watched: a green check badge.
            if (progress >= 1)
              PositionedDirectional(
                top: compact ? 4 : 8,
                end: compact ? 4 : 8,
                child: compact
                    ? const _CheckDot(size: 20)
                    : Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 8, 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              FormatHelper.capitalize(s.watchedBadge),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            // Bottom-right duration / size.
            if (badge != null)
              PositionedDirectional(
                end: compact ? 4 : 8,
                bottom: (progress > 0 ? 4 : 0) + (compact ? 4 : 8),
                child: _Tag(text: badge, color: Colors.black.withOpacity(0.8)),
              ),
            // Locked: padlock over a darkened, desaturated cover.
            if (locked)
              ColoredBox(
                color: Colors.black.withOpacity(0.62),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: compact ? 30 : 48,
                        height: compact ? 30 : 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: compact ? 16 : 24,
                          color: Colors.white,
                        ),
                      ),
                      if (!compact && (lockedBehind != null || !video.hasFile)) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          // No file link = a lesson of a course this member
                          // was not given (VideoCatalog), not an order lock.
                          FormatHelper.capitalize(!video.hasFile
                              ? s.courseLocked
                              : s.finishLessonFirst(lockedBehind!)),
                          textAlign: TextAlign.center,
                          style: StyleText.fontSize12Weight600
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            // Red watch progress.
            if (progress > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ColoredBox(color: Colors.white.withOpacity(0.35)),
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: progress,
                        child: const ColoredBox(color: Color(0xFFFF0033)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The drawn poster: gradient, a large faded glyph and the title.
  Widget _drawnPoster(List<Color> colors, IconData icon) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
            PositionedDirectional(
              end: -12,
              bottom: -18,
              child: Icon(
                icon,
                size: compact ? 70 : 130,
                color: Colors.white.withOpacity(0.13),
              ),
            ),
            // Title set on the poster.
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                compact ? 8 : 14,
                compact ? 8 : 14,
                compact ? 30 : 60,
                compact ? 8 : 14,
              ),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Text(
                  FormatHelper.capitalize(video.title.toUpperCase()),
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? StyleText.fontSize10Weight700
                          : StyleText.fontSize16Weight700)
                      .copyWith(
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: 0.3,
                    shadows: const <Shadow>[
                      Shadow(color: Colors.black38, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({this.text, this.icon, required this.color});

  final String? text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: icon != null
          ? Icon(icon, size: 13, color: Colors.white)
          : Text(
              FormatHelper.capitalize(text!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF16A34A),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_rounded, size: size * 0.7, color: Colors.white),
    );
  }
}

/// Drive's cover image for [url], faded in over [placeholder] once it has
/// loaded; [placeholder] stays when there is no image or it fails.
class VideoCoverImage extends StatelessWidget {
  const VideoCoverImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.width = 640,
    this.shade = true,
  });

  final String url;
  final Widget placeholder;
  final int width;

  /// A soft dark shade along the bottom, so badges stay readable.
  final bool shade;

  @override
  Widget build(BuildContext context) {
    final String? src = VideoLink.thumbnail(url, width: width);
    if (src == null) return placeholder;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        placeholder,
        AppNetworkImage(
          src,
          fit: BoxFit.cover,
          // Drive sends no CORS headers; on the web this shows the image
          // through an <img> element instead of failing.
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          frameBuilder: (BuildContext context, Widget child, int? frame,
              bool wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: child,
            );
          },
          errorBuilder: (BuildContext context, Object e, StackTrace? st) =>
              const SizedBox.shrink(),
        ),
        if (shade)
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black38],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
