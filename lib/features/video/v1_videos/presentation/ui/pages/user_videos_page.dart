/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: user_videos_page.dart
/// Purpose: Declares `UserVideosPage` — the lessons a member can watch, laid
///          out like a video site: a search box, filter chips, and a grid of
///          thumbnails with watch progress.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 25/9/2026 - Video-site layout, search and filters.
/// Updated: 1/10/2026 - Categories first (one per Drive sub-folder), then
///          the videos of the category opened. Lesson numbers, locks and
///          progress count within the category.
/// Updated: 15/10/2026 - Chips: Files (the course's folders) / All /
///          Continue watching; the back button stays pinned; per-course
///          "watch in order"; stars; "default" videos for everybody.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/features/video/v1_videos/presentation/ui/widgets/download_all_bar.dart';
import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/core/settings/capture_context.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_device_gate.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_download_button.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_grid.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/section_quizzes.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/course_settings.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/watch_sync.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/course_files_view.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/stars_row.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/features/video/v1_videos/presentation/controller/member_videos.dart';
import 'package:asec/features/video/v1_videos/data/catalog/video_catalog.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/widgets/course_certificate_button.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/network/shared_stream.dart';

/// The chips above a course's lessons. FILES comes first: the folders and
/// files the admin put in this course.
enum _VideoFilter { files, all, continueWatching }

/// The Videos tab opens only on the device that holds this platform's video
/// slot (VideoDeviceGate). Every other tab works on any device.
class UserVideosPage extends StatelessWidget {
  const UserVideosPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const VideoDeviceGate(child: _UserVideosView());
}

class _UserVideosView extends StatefulWidget {
  const _UserVideosView();

  @override
  State<_UserVideosView> createState() => _UserVideosPageState();
}

class _UserVideosPageState extends State<_UserVideosView> {
  // What this member may play (firestore.rules checks it too), and the
  // link-free catalog of EVERY lesson — the courses they were not given
  // show too, locked.
  late final Stream<_Feed> _videos = shared(() => combineLatest<List<VideoItem>, _Feed>(
    <Stream<List<VideoItem>>>[MemberVideos.watch(), VideoCatalog.watch()],
    (List<List<VideoItem>> v) => _Feed(v[0], v[1]),
  ));
  final TextEditingController _search = TextEditingController();

  _VideoFilter _filter = _VideoFilter.all;
  String _query = '';

  /// The category opened; null = the category list.
  String? _category;

  /// The sub-folder opened inside [_category]; null = its sub-folder list.
  String? _subcategory;

  void _openCategory(String? name) => setState(() {
        _category = name;
        _subcategory = null;
        _resetSearch();
        _reportCourse();
      });

  void _openSubcategory(String? name) => setState(() {
        _subcategory = name;
        _resetSearch();
        _reportCourse();
      });

  /// For screen capture alerts: the course / sub-folder open in this tab.
  void _reportCourse() {
    CaptureContext.browsingCourse = <String>[
      if ((_category ?? '').isNotEmpty) _category!,
      if ((_subcategory ?? '').isNotEmpty) _subcategory!,
    ].join(' › ');
  }

  void _resetSearch() {
    _filter = _VideoFilter.all;
    _query = '';
    _search.clear();
  }

  /// The section(s) whose quizzes belong under the lessons on screen: the
  /// open sub-folder, or — when the course shows no sub-folder screen —
  /// every section it has plus its loose lessons ('').
  static List<String> _sectionsShown(VideoCategory? sub, List<VideoCategory> subs) =>
      sub != null
          ? <String>[sub.name]
          : <String>[
              '',
              for (final VideoCategory c in subs)
                if (c.name.isNotEmpty) c.name,
            ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VideoItem> _apply(List<VideoItem> all) {
    if (_filter == _VideoFilter.files) return const <VideoItem>[];
    final String q = AppFeatures.to.isOn(AppFeature.videoSearch)
        ? _query.trim().toLowerCase()
        : '';
    return all.where((VideoItem v) {
      if (q.isNotEmpty &&
          !v.title.toLowerCase().contains(q) &&
          !v.description.toLowerCase().contains(q)) {
        return false;
      }
      if (_filter == _VideoFilter.continueWatching) {
        final double p = VideoWatchStore.progress(v.id);
        return p > 0 && p < 1;
      }
      return true;
    }).toList();
  }

  Future<void> _open(VideoItem video, List<VideoItem> playlist, bool sequential) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerPage(
          video: video,
          playlist: playlist,
          sequential: sequential,
        ),
      ),
    );
    // Progress bars, stars and "watched" ticks changed while the player
    // was open.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Obx(() {
    AppFeatures.to.values.length; // rebuild when a switch flips
    CourseSettings.to.sequential.length; // and when a course's order switch flips
    SessionController.to.user.value; // and when the admin changes my courses
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<_Feed>(
        stream: _videos,
        builder: (
          BuildContext context,
          AsyncSnapshot<_Feed> snapshot,
        ) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown, error: snapshot.error, stackTrace: snapshot.stackTrace);
          if (!snapshot.hasData) return const AppLoading();

          // The courses the admin opened for this member, plus every
          // "default" video, which everybody sees.
          final AppUser me = SessionController.to.current;
          final List<VideoItem> mine = snapshot.data!.mine
              .where((VideoItem v) =>
                  v.hasFile && (v.free || me.canSeeCourse(v.category)))
              .toList();
          // EVERY OTHER LESSON, LOCKED: listed with its course so the member
          // sees what exists, but it cannot be played or downloaded.
          // The catalog is keyed by hashed ids (it must not carry Drive
          // ids), so the member's own lessons are compared hashed.
          final Set<String> mineIds = <String>{
            for (final VideoItem v in mine) ContentCrypto.hashId(v.id),
          };
          final List<VideoItem> notGiven = snapshot.data!.catalog
              .where((VideoItem v) => !mineIds.contains(v.id))
              .toList();
          final Set<String> notGivenIds = <String>{for (final VideoItem v in notGiven) v.id};
          final List<VideoItem> all = <VideoItem>[...mine, ...notGiven]
            // COURSE ORDER (reversed): the latest upload is lesson 1, since the
            // lessons were uploaded from last to first.
            ..sort((VideoItem a, VideoItem b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));

          if (all.isEmpty) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosUserSub,
              child: AppEmptyView(
                title: s.noVideosTitle,
                subtitle: s.noVideosUserSub,
              ),
            );
          }

          final AppFeatures features = AppFeatures.to;

          // CATEGORIES FIRST. With more than one, the member picks a category
          // and only then sees its videos.
          final List<VideoCategory> categories = VideoCategory.group(all);
          final bool grouped = categories.length > 1;
          VideoCategory? current;
          if (!grouped) {
            current = categories.first;
          } else if (_category != null) {
            for (final VideoCategory c in categories) {
              if (c.name == _category) current = c;
            }
          }

          if (current == null) {
            final int watchedAll = mine
                .where((VideoItem v) => VideoWatchStore.isWatched(v.id))
                .length;
            // Every course's stars added up (the lessons they may play).
            final int starsAll = VideoCategory.group(mine).fold<int>(
              0,
              (int sum, VideoCategory c) => sum + CourseStars.local(c.videos),
            );
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosUserSub,
              child: VideoCategoryGrid(
                categories: categories,
                showStars: true,
                showSubtitles: true,
                lockedIds: notGivenIds,
                onOpen: (VideoCategory c) => _openCategory(c.name),
                header: features.isOn(AppFeature.videoCourseProgress)
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 18.h),
                        child: _CourseProgress(
                          watched: watchedAll,
                          total: mine.length,
                          ratio: CourseStars.localRatio(mine),
                          starsTotal: starsAll,
                        ),
                      )
                    : null,
              ),
            );
          }

          // SUB-FOLDERS NEXT. A category whose Drive folder holds folders
          // (AutoCAD → Introduction-01, Draw and Modify-02) shows them as a
          // second level of folders before any video.
          final VideoCategory category = current;
          final List<VideoCategory> subs =
              VideoCategory.group(category.videos, bySubcategory: true);
          VideoCategory? sub;
          if (subs.length > 1) {
            for (final VideoCategory c in subs) {
              if (c.name == _subcategory) sub = c;
            }
            if (sub == null) {
              return ConsolePage(
                title: s.typeVideos,
                subtitle: s.videosUserSub,
                child: VideoCategoryGrid(
                  categories: subs,
                  lockedIds: notGivenIds,
                  onOpen: (VideoCategory c) => _openSubcategory(c.name),
                  // PINNED: the back button never scrolls away.
                  pinned: grouped
                      ? VideoCategoryHeader(
                          category: category,
                          onBack: () => _openCategory(null),
                        )
                      : null,
                  header: Padding(
                    padding: EdgeInsets.only(bottom: 18.h),
                    child: _CourseFilesEntry(
                      onTap: () => PushedSectionPage.open(
                        context,
                        _CourseFilesPage(course: category),
                      ),
                    ),
                  ),
                ),
              );
            }
            current = sub;
          }

          // From here on "the course" is the folder that is open.
          final List<VideoItem> course = current.videos;
          // The lessons of it this member may play.
          final List<VideoItem> playable = course
              .where((VideoItem v) => !notGivenIds.contains(v.id))
              .toList();
          final List<VideoItem> shown = _apply(course);
          final bool filesMode = _filter == _VideoFilter.files;

          // Locks and numbers come from the WHOLE category, never the
          // filtered view — searching must not unlock anything.
          final Map<String, int> numbers = <String, int>{
            for (int i = 0; i < course.length; i++) course[i].id: i + 1,
          };
          // THE ADMIN DECIDES PER COURSE whether lessons open in order.
          final bool sequential = CourseSettings.to.isSequential(category.name);
          final Set<String> locked = <String>{
            if (sequential)
              ...VideoWatchStore.lockedIds(
                <String>[for (final VideoItem v in playable) v.id],
              ),
            ...notGivenIds,
          };
          final int watched = playable
              .where((VideoItem v) => VideoWatchStore.isWatched(v.id))
              .length;

          // PINNED: always on screen, however far the lessons scroll.
          final Widget? back = sub != null
              ? VideoCategoryHeader(
                  category: sub,
                  backLabel: category.label(s),
                  onBack: () => _openSubcategory(null),
                )
              : grouped
                  ? VideoCategoryHeader(
                      category: current,
                      onBack: () => _openCategory(null),
                    )
                  : null;

          final Widget header = Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (features.isOn(AppFeature.videoCourseProgress)) ...<Widget>[
                  _CourseProgress(
                    watched: watched,
                    total: playable.length,
                    ratio: CourseStars.localRatio(playable),
                  ),
                  SizedBox(height: 16.h),
                ],
                // ALWAYS THERE: the course's certificate — open once earned,
                // otherwise it says what is left to do.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CourseCertificateButton(
                    key: ValueKey<String>('cert_${category.name}'),
                    user: me,
                    course: category.name,
                  ),
                ),
                SizedBox(height: 16.h),
                // The quiz at the end of this section — opens once every
                // lesson of it is watched.
                SectionQuizzes.member(
                  course: category.name,
                  sections: _sectionsShown(sub, subs),
                  user: me,
                  unlocked: playable.isNotEmpty && watched >= playable.length,
                ),
                // DOWNLOAD THE WHOLE FOLDER (12/11/2026) — only lessons this
                // member may open now (not given / "watch in order" locks out).
                if (!filesMode && VideoDownloads.bulkEnabled)
                  DownloadAllBar(
                    key: ValueKey<String>('dl_all_${category.name}_${sub?.name ?? ''}'),
                    folderName: sub?.name ?? category.name,
                    videos: <VideoItem>[
                      for (final VideoItem v in course)
                        if (!locked.contains(v.id)) v,
                    ],
                  ),
                if (features.isOn(AppFeature.videoSearch) && !filesMode) ...<Widget>[
                  _SearchBox(
                    controller: _search,
                    hint: s.searchVideos,
                    onChanged: (String v) => setState(() => _query = v),
                    onClear: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
                  SizedBox(height: 14.h),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final (_VideoFilter f, String label, IconData? icon)
                          in <(_VideoFilter, String, IconData?)>[
                        (_VideoFilter.files, s.engFilesTab, Icons.folder_rounded),
                        (_VideoFilter.all, s.filterAll, null),
                        (_VideoFilter.continueWatching, s.filterContinue, null),
                      ]) ...<Widget>[
                        _FilterChip(
                          label: label,
                          icon: icon,
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ],
                  ),
                ),
                if (filesMode) ...<Widget>[
                  SizedBox(height: 16.h),
                  CourseFilesView(course: category.name),
                ] else if (shown.isEmpty) ...<Widget>[
                  SizedBox(height: 40.h),
                  AppEmptyView(
                    title: s.noLessonsMatch,
                    subtitle: s.noLessonsMatchSub,
                  ),
                ],
              ],
            ),
          );

          return ConsolePage(
            title: s.typeVideos,
            subtitle: s.videosUserSub,
            child: VideoGrid(
              videos: shown,
              pinned: back,
              header: header,
              lockedIds: locked,
              lessonNumbers: numbers,
              // Save inside the app for offline. A locked lesson cannot be
              // downloaded — that would get round the order.
              trailingBuilder: VideoDownloads.enabled
                  ? (VideoItem v) => locked.contains(v.id)
                      ? const SizedBox.shrink()
                      : VideoDownloadButton(video: v)
                  : null,
              onOpen: (VideoItem v) {
                if (notGivenIds.contains(v.id)) {
                  AppMessenger.of(context)
                    ..hide()
                    ..show(AppMessage(
                      content: Row(
                        children: <Widget>[
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(FormatHelper.capitalize(s.courseLockedSnack))),
                        ],
                      ),
                    ));
                  return;
                }
                if (locked.contains(v.id)) {
                  final int n = numbers[v.id]!;
                  AppMessenger.of(context)
                    ..hide()
                    ..show(AppMessage(
                      content: Row(
                        children: <Widget>[
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(FormatHelper.capitalize(s.finishLessonFirst(n - 1)))),
                        ],
                      ),
                    ));
                  return;
                }
                _open(v, playable, sequential);
              },
            ),
          );
        },
      ),
    );
    });
  }
}

class _Feed {
  const _Feed(this.mine, this.catalog);

  /// What this member may play.
  final List<VideoItem> mine;

  /// Every published lesson, without file links.
  final List<VideoItem> catalog;
}

/// On a course's section list: the way in to the course's "Files".
class _CourseFilesEntry extends StatelessWidget {
  const _CourseFilesEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: _FilterChip(
        label: s.engFilesTab,
        icon: Icons.folder_rounded,
        selected: false,
        onTap: onTap,
      ),
    );
  }
}

/// A course's files on a page of their own (from the section list).
class _CourseFilesPage extends StatelessWidget {
  const _CourseFilesPage({required this.course});

  final VideoCategory course;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return ConsolePage(
      title: '${s.engFilesTab} · ${course.label(s)}',
      scrollable: true,
      child: CourseFilesView(course: course.name),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.card,
            hintText: hint,
            hintStyle: StyleText.fontSize14Weight400
                .copyWith(color: AppColors.secondaryText),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: AppIcon(Icons.search_rounded,
                  size: 20.sp, color: AppColors.secondaryText),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: AppIcon(Icons.close_rounded,
                        size: 18.sp, color: AppColors.secondaryText),
                  ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40.r),
              borderSide: BorderSide(
                  color: AppColors.secondaryText.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40.r),
              borderSide: BorderSide(
                  color: AppColors.secondaryText.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.text : AppColors.chip,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                AppIcon(
                  icon,
                  size: 16.sp,
                  color: selected ? AppColors.background : AppColors.primary,
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                FormatHelper.capitalize(label),
                style: StyleText.fontSize13Weight600.copyWith(
                  color: selected ? AppColors.background : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "3 of 10 lessons watched" with a bar, the percentage and the stars it
/// earned — 1 star for every 20% watched, 5 at most.
class _CourseProgress extends StatelessWidget {
  const _CourseProgress({
    required this.watched,
    required this.total,
    required this.ratio,
    this.starsTotal,
  });

  final int watched;
  final int total;

  /// 0..1 — how much of the lessons was watched, partly watched ones too.
  final double ratio;

  /// On the course list: every course's stars added up, instead of the
  /// five stars of one course.
  final int? starsTotal;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final double p = ratio.clamp(0.0, 1.0);
    final bool done = total > 0 && watched >= total;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: AppColors.chip,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                done ? Icons.emoji_events_rounded : Icons.play_lesson_rounded,
                size: 20.sp,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        FormatHelper.capitalize(done ? s.courseComplete : s.courseProgress(watched, total)),
                        style: StyleText.fontSize14Weight600
                            .copyWith(color: AppColors.text),
                      ),
                    ),
                    Text(
                      FormatHelper.capitalize('${(p * 100).round()}%'),
                      style: StyleText.fontSize13Weight600.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: p),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double v, Widget? _) =>
                        LinearProgressIndicator(
                      value: v,
                      minHeight: 7.h,
                      backgroundColor:
                          AppColors.secondaryText.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done ? const Color(0xFF16A34A) : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: <Widget>[
                    if (starsTotal != null)
                      StarsChip(label: s.engStarsCount(starsTotal!))
                    else
                      StarsRow(stars: CourseStars.fromRatio(p), size: 20),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        FormatHelper.capitalize(s.engStarsHint),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize11Weight500
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
