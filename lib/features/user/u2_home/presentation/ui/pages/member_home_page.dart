/// Module: user / u2_home
///
///*************************** FILE INFO ****************************///
/// File Name: member_home_page.dart
/// Purpose: Declares `MemberHomePage` — the first screen a member sees: a
///          greeting with their overall progress, the lesson to resume, quick
///          access to the main sections and their courses at a glance.
/// Author: ASEC team
/// Created: 13/10/2026
/// Updated: 22/10/2026 - Continue watching is one compact row (small lesson
///          screen, title + progress, round play) instead of a tall banner.
///
/// READ-ONLY. Everything here comes from what already exists: the published
/// lessons (the same stream the Videos page reads), the watch progress kept on
/// the device (VideoWatchStore) and the member's own switches. Tapping a tile
/// switches the shell's section (AppShell.open) or opens a "My space" page on
/// top of it.
///
/// LIBRARY (was "Quick access"): the admin's files, "The best" (members
/// ranked by stars) and the certificate. Videos, the converter and quizzes
/// stay one tap away in the menu.
///
/// TIPS & TRICKS from the admin are laid over the page once per launch
/// (TipsLayer): the page fades back behind them.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/app_shell.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_directory_page.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/course_settings.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/watch_sync.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/pages/library_pages.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/partners_orbit.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/stars_row.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/tips_overlay.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_quizzes_page.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/user/u2_home/presentation/ui/widgets/member_projects_section.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/features/video/v1_videos/presentation/controller/member_videos.dart';
import 'package:asec/core/network/shared_stream.dart';

/// Section ids the home page jumps to (see UserShell).
abstract final class MemberSectionIds {
  static const String home = 'home';
  static const String videos = 'videos';
  static const String converter = 'converter';
  static const String quizzes = 'quizzes';
  static const String cvs = 'cvs';
  static const String web = 'web';
  static const String settings = 'settings';
}

class MemberHomePage extends StatefulWidget {
  const MemberHomePage({super.key});

  @override
  State<MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<MemberHomePage> {
  // Only what this member may read (firestore.rules checks it too).
  late final Stream<List<VideoItem>> _videos = shared(() => MemberVideos.watch());

  /// Watch progress is written to the device while a lesson plays (from the
  /// Videos tab too), so the page listens and refreshes — at most once a
  /// second, not on every saved position.
  VoidCallback? _unlisten;
  Timer? _debounce;

  /// The watch progress already on this device is sent once per launch, so
  /// the admin's stars include lessons watched before stars existed.
  bool _backfilled = false;

  @override
  void initState() {
    super.initState();
    _unlisten = GetStorage().listen(() {
      if (_debounce?.isActive ?? false) return;
      _debounce = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _unlisten?.call();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _play(VideoItem video, List<VideoItem> playlist) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerPage(
          video: video,
          playlist: playlist,
          // The admin's switch for THIS course.
          sequential: CourseSettings.to.isSequential(video.category),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppFeatures.to.values.length; // a switch flipped live
      CourseSettings.to.sequential.length;
      final AppUser me = SessionController.to.current;
      return Scaffold(
        backgroundColor: AppColors.background,
        // TIPS & TRICKS lie over the page as layers once per launch.
        body: TipsLayer(
          user: me,
          child: StreamBuilder<List<VideoItem>>(
          stream: _videos,
          builder: (BuildContext context, AsyncSnapshot<List<VideoItem>> snap) {
            final bool videosOn = AppFeatures.to.isOn(AppFeature.sectionVideos);
            final List<VideoItem> all = !videosOn || !snap.hasData
                ? const <VideoItem>[]
                : (snap.data!
                    // The member's courses + every "default" video.
                    .where((VideoItem v) =>
                        v.hasFile && (v.free || me.canSeeCourse(v.category)))
                    .toList()
                  ..sort((VideoItem a, VideoItem b) => (b.createdAt ?? DateTime(0))
                      .compareTo(a.createdAt ?? DateTime(0))));
            if (!_backfilled && all.isNotEmpty) {
              _backfilled = true;
              WatchSync.backfill(all);
            }
            return _HomeBody(
              user: me,
              videos: all,
              loading: videosOn && !snap.hasData && !snap.hasError,
              onPlay: _play,
            );
          },
          ),
        ),
      );
    });
  }
}

/// The lesson to resume and the course it belongs to.
class _Resume {
  const _Resume(this.video, this.course, this.started);

  final VideoItem video;

  /// The folder the lesson sits in — its playlist and its numbering.
  final List<VideoItem> course;

  /// True = half-watched (resume); false = the next lesson not yet begun.
  final bool started;

  int get number => course.indexWhere((VideoItem v) => v.id == video.id) + 1;

  /// The first half-watched lesson; failing that, the first one not watched.
  static _Resume? pick(List<VideoItem> all) {
    if (all.isEmpty) return null;
    // Courses in the same order the Videos page shows them.
    final List<List<VideoItem>> courses = <List<VideoItem>>[
      for (final VideoCategory c in VideoCategory.group(all))
        for (final VideoCategory sub in VideoCategory.group(c.videos, bySubcategory: true))
          sub.videos,
    ];
    for (final List<VideoItem> course in courses) {
      for (final VideoItem v in course) {
        final double p = VideoWatchStore.progress(v.id);
        if (p > 0 && p < 1 && !VideoWatchStore.isWatched(v.id)) {
          return _Resume(v, course, true);
        }
      }
    }
    for (final List<VideoItem> course in courses) {
      for (final VideoItem v in course) {
        if (!VideoWatchStore.isWatched(v.id)) return _Resume(v, course, false);
      }
    }
    return null;
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.user,
    required this.videos,
    required this.loading,
    required this.onPlay,
  });

  final AppUser user;
  final List<VideoItem> videos;
  final bool loading;
  final Future<void> Function(VideoItem video, List<VideoItem> playlist) onPlay;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final AppFeatures f = AppFeatures.to;

    final int total = videos.length;
    final int watched =
        videos.where((VideoItem v) => VideoWatchStore.isWatched(v.id)).length;
    final _Resume? resume = _Resume.pick(videos);
    final List<VideoCategory> courses = VideoCategory.group(videos);

    void go(String id, [MemberLink? fallback]) {
      if (!AppShell.open(context, id)) fallback?.open(context);
    }

    // LIBRARY: the admin's files, the leaderboard and the certificate.
    // Titles only (29/10/2026): no hint line under them, so the cards are
    // shorter.
    final List<_Tile> main = <_Tile>[
      _Tile(
        icon: Icons.folder_copy_rounded,
        label: s.engLibraryFiles,
        onTap: () => PushedSectionPage.open(context, const LibraryFilesPage()),
      ),
      // "The Best" = the CVs, same as the admin app's "The Best" tab.
      // Opens the tab when it is in the bar, else the page on top.
      if (f.isOn(AppFeature.sectionCvDirectory))
        _Tile(
          icon: Icons.emoji_events_rounded,
          label: s.cvs,
          onTap: () {
            if (!AppShell.open(context, MemberSectionIds.cvs)) {
              PushedSectionPage.open(context, const CvDirectoryPage());
            }
          },
        ),
      if (f.isOn(AppFeature.sectionVideos))
        _Tile(
          icon: Icons.workspace_premium_rounded,
          label: s.engLibraryCertificate,
          onTap: () => PushedSectionPage.open(
            context,
            CertificateQuizzesPage(user: user),
          ),
        ),
    ];
    // Every course's stars added up (1 per 20% watched, 5 per course).
    final int stars = courses.fold<int>(
      0,
      (int sum, VideoCategory c) => sum + CourseStars.local(c.videos),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 900;

        final Widget hero = _HeroCard(
          user: user,
          watched: watched,
          total: total,
          showProgress: f.isOn(AppFeature.sectionVideos) && total > 0,
          stars: stars,
        );

        final Widget? resumeCard = !f.isOn(AppFeature.sectionVideos) || (total == 0 && !loading)
            ? null
            : _ResumeCard(
                resume: resume,
                loading: loading,
                allDone: total > 0 && watched == total,
                onPlay: onPlay,
                onBrowse: () => go(MemberSectionIds.videos),
              );

        final Widget tiles = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SectionTitle(s.engLibrary),
            SizedBox(height: 10.h),
            _TileGrid(tiles: main, big: true),
          ],
        );

        // DESKTOP / TABLET / iPAD / macOS: everything on one screen, no
        // scrolling, in full-width rows:
        //   welcome card
        //   "continue watching" | library
        //   projects — 5 cards on Mac / Windows / a wide browser, 3 on iPad
        //   partners ring in whatever height is left (hidden if too little)
        // A window too short for that keeps the scrolling layout below.
        final bool fits = MediaQuery.sizeOf(context).shortestSide >= 600 &&
            c.maxWidth >= 700 &&
            c.maxHeight >= 560;
        if (fits) {
          const double gap = 16;
          final bool desktopOs = !kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.linux);
          final int perRow = desktopOs || c.maxWidth >= 1100 ? 5 : 3;
          return Padding(
            padding: EdgeInsets.fromLTRB(AppPadding.h, 16, AppPadding.h, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FadeSlideIn(child: hero),
                const SizedBox(height: gap),
                // LEVEL: both titles on one line, both cards the same height
                // with the same top and bottom.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: resumeCard == null
                      ? tiles
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(flex: 5, child: _SectionTitle(s.homeContinue)),
                                const SizedBox(width: gap),
                                Expanded(flex: 6, child: _SectionTitle(s.engLibrary)),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            SizedBox(
                              height: 136,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(
                                    flex: 5,
                                    child: _ResumeCard(
                                      resume: resume,
                                      loading: loading,
                                      allDone: total > 0 && watched == total,
                                      onPlay: onPlay,
                                      onBrowse: () => go(MemberSectionIds.videos),
                                      titled: false,
                                    ),
                                  ),
                                  const SizedBox(width: gap),
                                  Expanded(flex: 6, child: _TileGrid(tiles: main, big: true, fill: true)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: gap),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: MemberProjectsSection(perRow: perRow),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints p) => p.maxHeight < 150
                        ? const SizedBox.shrink()
                        : const FadeSlideIn(
                            delay: Duration(milliseconds: 200),
                            child: Padding(
                              padding: EdgeInsets.only(top: gap),
                              child: Center(child: PartnersSection(fill: true)),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppPadding.h, 20.h, AppPadding.h, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FadeSlideIn(child: hero),
              SizedBox(height: 20.h),
              if (wide && resumeCard != null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 5, child: resumeCard),
                      SizedBox(width: 20.w),
                      Expanded(flex: 6, child: tiles),
                    ],
                  ),
                )
              else ...<Widget>[
                if (resumeCard != null) ...<Widget>[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: resumeCard,
                  ),
                  SizedBox(height: 20.h),
                ],
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: tiles,
                ),
              ],
              // PROJECTS: the website's projects, a section of their own.
              SizedBox(height: 24.h),
              const FadeSlideIn(
                delay: Duration(milliseconds: 170),
                child: MemberProjectsSection(),
              ),
              // "Your courses" was here — removed; the courses are in Videos.
              // OUR PARTNERS: one row of logos scrolling by itself (PartnersMarquee).
              SizedBox(height: 28.h),
              const FadeSlideIn(
                delay: Duration(milliseconds: 200),
                child: PartnersSection(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.user,
    required this.watched,
    required this.total,
    required this.showProgress,
    this.stars = 0,
  });

  final AppUser user;
  final int watched;
  final int total;
  final bool showProgress;

  /// Every course's stars added up.
  final int stars;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final double ratio = total == 0 ? 0 : watched / total;

    final Widget greeting = Row(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textButton.withOpacity(0.55), width: 2),
          ),
          child: AppAvatar(name: user.displayName, size: 40),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                FormatHelper.capitalize(s.homeGreeting(user.firstName)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize18Weight600.copyWith(color: AppColors.textButton),
              ),
              SizedBox(height: 2.h),
              Text(
                FormatHelper.capitalize(s.homeSub),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.textButton.withOpacity(0.85)),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget progress = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Ring(value: ratio),
        SizedBox(width: 12.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                FormatHelper.capitalize(s.homeProgress),
                style: StyleText.fontSize12Weight600
                    .copyWith(color: AppColors.textButton.withOpacity(0.8)),
              ),
              SizedBox(height: 2.h),
              Text(
                FormatHelper.capitalize(s.courseProgress(watched, total)),
                style: StyleText.fontSize15Weight600.copyWith(color: AppColors.textButton),
              ),
              SizedBox(height: 4.h),
              StarsChip(label: s.engStarsCount(stars), onColor: true),
            ],
          ),
        ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          // Two soft circles — depth without an image to load.
          PositionedDirectional(
            end: -60,
            top: -70,
            child: _Bubble(size: 220, opacity: 0.10),
          ),
          PositionedDirectional(
            end: 120,
            bottom: -90,
            child: _Bubble(size: 180, opacity: 0.07),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 12.r),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                if (!showProgress) return greeting;
                if (c.maxWidth >= 640) {
                  return Row(
                    children: <Widget>[
                      Expanded(child: greeting),
                      SizedBox(width: 20.w),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 300.w),
                        child: progress,
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    greeting,
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
                      decoration: BoxDecoration(
                        color: AppColors.textButton.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: progress,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textButton.withOpacity(opacity),
        ),
      );
}

/// The overall progress as a ring with the percentage inside.
class _Ring extends StatelessWidget {
  const _Ring({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final double size = 48.r;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CircularProgressIndicator(
              value: v,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.textButton.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textButton),
            ),
            Center(
              child: Text(
                FormatHelper.capitalize('${(v * 100).round()}%'),
                style: StyleText.fontSize12Weight600.copyWith(color: AppColors.textButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Continue watching ───────────────────────────────────────────────────────

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.resume,
    required this.loading,
    required this.allDone,
    required this.onPlay,
    required this.onBrowse,
    this.titled = true,
  });

  /// False on the wide home page: the title sits above the card, level
  /// with "Library", and the card fills the row's height.
  final bool titled;

  final _Resume? resume;
  final bool loading;
  final bool allDone;
  final Future<void> Function(VideoItem video, List<VideoItem> playlist) onPlay;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final _Resume? r = resume;

    Widget content;
    if (loading) {
      content = SizedBox(height: 72.h, child: const AppLoading());
    } else if (r == null) {
      content = _Message(
        icon: allDone ? Icons.emoji_events_rounded : Icons.play_lesson_rounded,
        title: allDone ? s.homeAllDone : s.homeStart,
        subtitle: allDone ? null : s.homeStartSub,
        action: AppButton(
          label: s.typeVideos,
          icon: Icons.video_library_rounded,
          kind: AppButtonKind.subtle,
          dense: true,
          onPressed: onBrowse,
        ),
      );
    } else {
      final double p = r.started ? VideoWatchStore.progress(r.video.id) : 0;
      final String category = r.video.category.trim().isEmpty
          ? s.videoCategoryGeneral
          : r.video.category.trim();
      // ONE COMPACT ROW (22/10/2026 — was a 16:4.5 banner plus three lines of
      // text and a button): small "screen" | category, title, progress | play.
      // The whole row plays the lesson.
      content = Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => onPlay(r.video, r.course),
          child: Row(
            children: <Widget>[
              _ResumeThumb(
                progress: p,
                badge: s.homeLessonOf(r.number, r.course.length),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize11Weight600
                          .copyWith(color: AppColors.primary),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      r.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize14Weight600
                          .copyWith(color: AppColors.text, height: 1.25),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: p,
                              minHeight: 5,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          r.started
                              ? '${(p * 100).round()}%'
                              : FormatHelper.capitalize(s.homeStart),
                          style: StyleText.fontSize11Weight600
                              .copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Tooltip(
                message: r.started ? s.homeResume : s.homeStart,
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      size: 24.r, color: AppColors.textButton),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _Panel(
      title: titled ? s.homeContinue : null,
      fill: !titled,
      child: content,
    );
  }
}

/// The small lesson "screen" of the Continue watching row: primary gradient,
/// a play glyph, "Lesson 3 of 12" and the watched part along the bottom.
class _ResumeThumb extends StatelessWidget {
  const _ResumeThumb({required this.progress, required this.badge});

  final double progress;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 96.w,
        height: 72.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.primary.withOpacity(0.95),
              AppColors.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 28.r,
                color: AppColors.textButton.withOpacity(0.9),
              ),
            ),
            PositionedDirectional(
              start: 6.w,
              bottom: 8.h,
              end: 6.w,
              child: Text(
                FormatHelper.capitalize(badge),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: StyleText.fontSize10Weight600
                    .copyWith(color: AppColors.textButton),
              ),
            ),
            if (progress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppColors.textButton.withOpacity(0.25),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textButton),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22.r, color: AppColors.primary),
          ),
          SizedBox(height: 8.h),
          Text(
            FormatHelper.capitalize(title),
            textAlign: TextAlign.center,
            style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          if (subtitle != null) ...<Widget>[
            SizedBox(height: 4.h),
            Text(
              FormatHelper.capitalize(subtitle!),
              textAlign: TextAlign.center,
              style: StyleText.fontSize13Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
          ],
          if (action != null) ...<Widget>[
            SizedBox(height: 14.h),
            action!,
          ],
        ],
      ),
    );
  }
}

// ── Quick access ────────────────────────────────────────────────────────────

class _Tile {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.big, this.fill = false});

  /// Fill the height it is given (wide home page: level with the
  /// Continue watching card).
  final bool fill;

  final List<_Tile> tiles;

  /// The main three: taller, icon on top. The rest: one compact row each.
  final bool big;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double gap = 12.w;
        // The main three always share one row; the rest flow two or three
        // to a row on wider screens, one per row on a phone.
        final int cols = big
            ? tiles.length
            : math.max(1, math.min(tiles.length, (c.maxWidth + gap) ~/ (230 + gap)));
        final double width = (c.maxWidth - gap * (cols - 1)) / cols;
        // THE MAIN ROW: every card as tall as the tallest one.
        if (big && fill && c.hasBoundedHeight) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < tiles.length; i++) ...<Widget>[
                if (i > 0) SizedBox(width: gap),
                Expanded(child: _TileCard(tile: tiles[i], big: true, index: i)),
              ],
            ],
          );
        }
        if (big) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < tiles.length; i++) ...<Widget>[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(child: _TileCard(tile: tiles[i], big: true, index: i)),
                ],
              ],
            ),
          );
        }
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (int i = 0; i < tiles.length; i++)
              SizedBox(
                width: width,
                child: _TileCard(tile: tiles[i], big: big, index: i),
              ),
          ],
        );
      },
    );
  }
}

class _TileCard extends StatefulWidget {
  const _TileCard({required this.tile, required this.big, required this.index});

  final _Tile tile;
  final bool big;
  final int index;

  @override
  State<_TileCard> createState() => _TileCardState();
}

class _TileCardState extends State<_TileCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final _Tile t = widget.tile;
    final Color accent = AppColors.primary;

    final Widget badge = Container(
      // Library cards (big): larger badge and icon (29/10/2026).
      width: (widget.big ? 56 : 40).r,
      height: (widget.big ? 56 : 40).r,
      decoration: BoxDecoration(
        color: accent.withOpacity(_hover ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: AppIcon(t.icon, size: (widget.big ? 30 : 21).sp, color: accent),
    );

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          FormatHelper.capitalize(t.label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (widget.big
                  ? StyleText.fontSize18Weight600
                  : StyleText.fontSize15Weight600)
              .copyWith(color: AppColors.text),
        ),
        if (t.hint != null) ...<Widget>[
          SizedBox(height: 2.h),
          Text(
            FormatHelper.capitalize(t.hint!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryText),
          ),
        ],
      ],
    );

    final Widget body = widget.big
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  badge,
                  const Spacer(),
                  AppIcon(
                    Icons.arrow_forward_rounded,
                    size: 18.sp,
                    color: _hover ? accent : AppColors.secondaryText.withOpacity(0.6),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              text,
            ],
          )
        : Row(
            children: <Widget>[
              badge,
              SizedBox(width: 12.w),
              Expanded(child: text),
              AppIcon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: AppColors.secondaryText.withOpacity(0.7),
              ),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 160),
        offset: Offset(0, _hover ? -0.02 : 0),
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: t.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.all(widget.big ? 16.r : 12.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: _hover
                      ? accent.withOpacity(0.35)
                      : AppColors.secondaryText.withOpacity(0.08),
                ),
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pieces ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        FormatHelper.capitalize(text),
        style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
      );
}

/// A titled card in the house surface.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.fill = false});

  /// Null = no title inside (the title sits above the card instead).
  final String? title;
  final Widget child;

  /// Fill the height it is given, content centred.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.secondaryText.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fill ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            _SectionTitle(title!),
            SizedBox(height: 8.h),
          ],
          // In a fixed height a taller message is clipped, never an overflow.
          if (fill)
            Flexible(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: child,
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}
