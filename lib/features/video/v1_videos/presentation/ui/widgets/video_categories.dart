/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_categories.dart
/// Purpose: Declares `VideoCategory` (videos grouped by their Drive
///          sub-folder), `VideoCategoryGrid` (the category cards shown before
///          any video) and `VideoCategoryHeader` (the "← All categories" bar
///          above one category's videos).
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/features/video/v1_videos/data/seed/drive_lessons.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/course_settings.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/watch_sync.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/stars_row.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_thumbnail.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// One category and its videos, in the order they were given.
class VideoCategory {
  const VideoCategory({
    required this.name,
    required this.order,
    required this.videos,
  });

  /// The raw category ('' = no category).
  final String name;
  final int order;
  final List<VideoItem> videos;

  String label(S s) => name.isEmpty ? s.videoCategoryGeneral : name;

  int get watched =>
      videos.where((VideoItem v) => VideoWatchStore.isWatched(v.id)).length;

  /// The Reels course ("Reals" on Drive).
  static bool isReels(String name) {
    final String n = name.trim().toLowerCase();
    return n == 'reals' || n == 'reels';
  }

  /// The Tips course ("Tips and Tricks", or the older "Reals" / "Reels")
  /// — always shown FIRST, before every other course, for admins and
  /// members alike.
  static bool isTips(String name) {
    final String n = name.trim().toLowerCase();
    return isReels(n) || n.contains('tips');
  }

  /// Groups [videos] by category — categories in folder order (then name),
  /// each keeping the order the videos came in.
  ///
  /// With [bySubcategory], groups ONE category's videos by the Drive folder
  /// inside it (e.g. AutoCAD → "Introduction-01", "Draw and Modify-02").
  static List<VideoCategory> group(
    List<VideoItem> videos, {
    bool bySubcategory = false,
  }) {
    final Map<String, List<VideoItem>> byName = <String, List<VideoItem>>{};
    final Map<String, int> order = <String, int>{};
    for (final VideoItem v in videos) {
      final String key = (bySubcategory ? v.subcategory : v.category).trim();
      final int folderOrder = bySubcategory ? v.subcategoryOrder : v.categoryOrder;
      byName.putIfAbsent(key, () => <VideoItem>[]).add(v);
      // '' (General) first; Drive folders in folder order (1, 2, …); a
      // category typed by an admin (order 0) after them.
      final int o = key.isEmpty ? -1 : (folderOrder > 0 ? folderOrder : 1 << 20);
      order[key] = order.containsKey(key) ? (order[key]! < o ? order[key]! : o) : o;
    }
    final List<VideoCategory> out = <VideoCategory>[
      for (final MapEntry<String, List<VideoItem>> e in byName.entries)
        VideoCategory(name: e.key, order: order[e.key]!, videos: e.value),
    ]..sort((VideoCategory a, VideoCategory b) {
        // TIPS FIRST, always, before every other course.
        if (!bySubcategory) {
          final bool ra = isTips(a.name);
          final bool rb = isTips(b.name);
          if (ra != rb) return ra ? -1 : 1;
        }
        // Sections by the number in their folder name — "Introduction-01",
        // "Draw and Modify-02", "03-Annotation and Layout" … — whichever end
        // it is on. Videos synced before this still carry the old order.
        if (bySubcategory && a.name.isNotEmpty && b.name.isNotEmpty) {
          final int? na = DriveVideoSync.folderNumber(a.name);
          final int? nb = DriveVideoSync.folderNumber(b.name);
          if (na != null && nb != null && na != nb) return na.compareTo(nb);
          if (na != null && nb == null) return -1;
          if (na == null && nb != null) return 1;
        }
        final int c = a.order.compareTo(b.order);
        return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return out;
  }
}

/// The categories as cards; tapping one opens its videos.
class VideoCategoryGrid extends StatelessWidget {
  const VideoCategoryGrid({
    super.key,
    required this.categories,
    required this.onOpen,
    this.header,
    this.showProgress = true,
    this.showStars = false,
    this.bottomPadding = 24,
    this.pinned,
    this.lockedIds = const <String>{},
    this.showSubtitles = false,
  });

  /// Lessons the member was not given. A course made only of these shows
  /// a lock; its progress and stars count the other lessons only.
  final Set<String> lockedIds;

  /// Courses (top level) show the line the admin wrote under the title.
  final bool showSubtitles;

  /// Stays above the grid while it scrolls (the back button).
  final Widget? pinned;

  /// Courses (top level) show the member's stars: 1 per 20% watched.
  final bool showStars;

  final List<VideoCategory> categories;
  final void Function(VideoCategory category) onOpen;
  final Widget? header;

  /// Members see how much of each category they watched; admins do not.
  final bool showProgress;
  final double bottomPadding;

  static const double _minTile = 280;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double gapX = _gap.w;
        final int columns =
            ((width + gapX) / (_minTile + gapX)).floor().clamp(1, 6);
        final double tileWidth = (width - gapX * (columns - 1)) / columns;
        final double tileHeight = tileWidth * 9 / 16 + 12.h + 64.h;

        final Widget scroll = CustomScrollView(
          slivers: <Widget>[
            if (header != null) SliverToBoxAdapter(child: header),
            SliverPadding(
              padding: EdgeInsets.only(bottom: bottomPadding.h),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gapX,
                  mainAxisSpacing: 20.h,
                  mainAxisExtent: tileHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final VideoCategory category = categories[index];
                    return FadeSlideIn(
                      delay: staggerDelay(index, stepMs: 60),
                      child: _CategoryCard(
                        category: category,
                        index: index,
                        showProgress: showProgress,
                        showStars: showStars,
                        lockedIds: lockedIds,
                        showSubtitle: showSubtitles,
                        onTap: () => onOpen(category),
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        );
        if (pinned == null) return scroll;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[pinned!, Expanded(child: scroll)],
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.index,
    required this.showProgress,
    required this.onTap,
    this.showStars = false,
    this.lockedIds = const <String>{},
    this.showSubtitle = false,
  });

  final VideoCategory category;
  final int index;
  final bool showProgress;
  final bool showStars;
  final Set<String> lockedIds;
  final bool showSubtitle;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hover = false;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
    <Color>[Color(0xFF7F1D1D), Color(0xFFDC2626)],
    <Color>[Color(0xFF064E3B), Color(0xFF059669)],
    <Color>[Color(0xFF4C1D95), Color(0xFF7C3AED)],
    <Color>[Color(0xFF78350F), Color(0xFFD97706)],
    <Color>[Color(0xFF134E4A), Color(0xFF0D9488)],
  ];

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final VideoCategory c = widget.category;
    final List<Color> colors = _palettes[widget.index % _palettes.length];
    final int total = c.videos.length;
    // Only the lessons this member may play count for progress and stars.
    final List<VideoItem> open = widget.lockedIds.isEmpty
        ? c.videos
        : c.videos.where((VideoItem v) => !widget.lockedIds.contains(v.id)).toList();
    final bool locked = open.isEmpty && total > 0;
    final int watched = widget.showProgress
        ? open.where((VideoItem v) => VideoWatchStore.isWatched(v.id)).length
        : 0;
    final double p = open.isEmpty ? 0 : watched / open.length;
    VideoItem? cover;
    for (final VideoItem v in c.videos) {
      if (v.hasFile) {
        cover = v;
        break;
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: _hover ? 1.02 : 1,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: <Widget>[
                    // A second sheet behind — reads as "a stack of videos".
                    Positioned.fill(
                      top: 0,
                      left: 10,
                      right: 10,
                      bottom: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.first.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  end: AlignmentDirectional.bottomEnd,
                                  colors: colors,
                                ),
                              ),
                            ),
                            // The first video's cover, darkened so the
                            // category name stays readable on it.
                            if (cover != null)
                              VideoCoverImage(
                                url: cover.url,
                                placeholder: const SizedBox.shrink(),
                                shade: false,
                              ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topEnd,
                                  end: AlignmentDirectional.bottomStart,
                                  colors: <Color>[
                                    colors.first.withOpacity(0.35),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                        padding: EdgeInsets.all(14.r),
                        child: Stack(
                          children: <Widget>[
                            PositionedDirectional(
                              end: -8,
                              bottom: -12,
                              child: Icon(
                                Icons.video_library_rounded,
                                size: 96,
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                            if (widget.showStars && !locked)
                              PositionedDirectional(
                                start: 0,
                                bottom: 0,
                                child: StarsRow(
                                  stars: CourseStars.local(open),
                                  size: 17,
                                  emptyColor: Colors.white.withOpacity(0.55),
                                ),
                              ),
                            if (locked)
                              PositionedDirectional(
                                start: 0,
                                bottom: 0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 4.w),
                                      Text(
                                        FormatHelper.capitalize(s.courseLocked),
                                        style: StyleText.fontSize12Weight600.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    FormatHelper.capitalize(c.label(s)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: StyleText.fontSize22Weight700.copyWith(
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  // The admin's line, right under the title.
                                  if (widget.showSubtitle)
                                    Obx(() {
                                      final String sub = CourseSettings.to.subtitle(c.name);
                                      if (sub.isEmpty) return const SizedBox.shrink();
                                      return Padding(
                                        padding: EdgeInsets.only(top: 4.h),
                                        child: Text(
                                          sub,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: StyleText.fontSize14Weight500.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            PositionedDirectional(
                              end: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(Icons.playlist_play_rounded,
                                        size: 16, color: Colors.white),
                                    SizedBox(width: 4.w),
                                    Text(
                                      FormatHelper.capitalize('$total'),
                                      style: StyleText.fontSize12Weight600
                                          .copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: <Widget>[
                AppIcon(locked ? Icons.lock_rounded : Icons.folder_rounded,
                    size: 20.sp, color: locked ? AppColors.secondaryText : colors.last),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(c.label(s)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize15Weight600
                        .copyWith(color: AppColors.text),
                  ),
                ),
                Text(
                  FormatHelper.capitalize(s.videoCount(total)),
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
            if (widget.showProgress && !locked) ...<Widget>[
              SizedBox(height: 8.h),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: p,
                        minHeight: 5.h,
                        backgroundColor:
                            AppColors.secondaryText.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          p >= 1 ? const Color(0xFF16A34A) : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    FormatHelper.capitalize('$watched/$total'),
                    style: StyleText.fontSize11Weight600
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A folder card that looks exactly like a video folder (the coloured,
/// stacked card with the name on it, the count in the corner, and the name
/// and count under it) — used for the course FILES folders, so both tabs
/// look the same.
class FolderCoverCard extends StatefulWidget {
  const FolderCoverCard({
    super.key,
    required this.title,
    required this.count,
    required this.countLabel,
    required this.index,
    required this.onTap,
    this.icon = Icons.folder_copy_rounded,
    this.badgeIcon = Icons.insert_drive_file_rounded,
    this.trailing,
  });

  final String title;
  final int count;
  final String countLabel;
  final int index;
  final VoidCallback onTap;
  final IconData icon;
  final IconData badgeIcon;

  /// E.g. the rename / delete menu, at the end of the line under the card.
  final Widget? trailing;

  @override
  State<FolderCoverCard> createState() => _FolderCoverCardState();
}

class _FolderCoverCardState extends State<FolderCoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors =
        _CategoryCardState._palettes[widget.index % _CategoryCardState._palettes.length];
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: _hover ? 1.02 : 1,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      top: 0,
                      left: 10,
                      right: 10,
                      bottom: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.first.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: colors,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(14.r),
                            child: Stack(
                              children: <Widget>[
                                PositionedDirectional(
                                  end: -8,
                                  bottom: -12,
                                  child: Icon(widget.icon, size: 96, color: Colors.white.withOpacity(0.14)),
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    FormatHelper.capitalize(widget.title),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: StyleText.fontSize22Weight700.copyWith(color: Colors.white, height: 1.2),
                                  ),
                                ),
                                PositionedDirectional(
                                  end: 0,
                                  top: 0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(widget.badgeIcon, size: 15, color: Colors.white),
                                        SizedBox(width: 4.w),
                                        Text('${widget.count}',
                                            style: StyleText.fontSize12Weight600.copyWith(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: <Widget>[
                AppIcon(Icons.folder_rounded, size: 20.sp, color: colors.last),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(widget.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
                  ),
                ),
                Text(
                  widget.countLabel,
                  style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "← All categories   GENERAL NOTES · 16 videos" above a category's videos.
class VideoCategoryHeader extends StatelessWidget {
  const VideoCategoryHeader({
    super.key,
    required this.category,
    required this.onBack,
    this.backLabel,
  });

  final VideoCategory category;
  final VoidCallback onBack;

  /// What the back button says; defaults to "All categories". Inside a
  /// sub-folder it names the category it goes back to (e.g. "AutoCAD").
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12.w,
        runSpacing: 8.h,
        children: <Widget>[
          customButton(
            title: '${rtl ? '→' : '←'}  ${backLabel ?? s.allCategories}',
            function: onBack,
            wrapContent: true,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(Icons.folder_open_rounded,
                  size: 20.sp, color: AppColors.primary),
              SizedBox(width: 6.w),
              Text(
                FormatHelper.capitalize(category.label(s)),
                style: StyleText.fontSize18Weight600
                    .copyWith(color: AppColors.text),
              ),
              SizedBox(width: 8.w),
              Text(
                FormatHelper.capitalize(s.videoCount(category.videos.length)),
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
