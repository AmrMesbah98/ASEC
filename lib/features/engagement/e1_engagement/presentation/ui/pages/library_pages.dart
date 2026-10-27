/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: library_pages.dart
/// Purpose: Declares the member Library's pages — `LibraryFilesPage` (files
///          the admin shared) and `LeaderboardPage` ("The best": members
///          ranked by their stars; the admin's version also shows each
///          member's stars per course).
/// Author: ASEC team
/// Created: 15/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/watch_sync.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/course_files_view.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/stars_row.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/features/video/v1_videos/presentation/controller/member_videos.dart';
import 'package:asec/core/network/shared_stream.dart';

// ── Files ───────────────────────────────────────────────────────────────────

class LibraryFilesPage extends StatelessWidget {
  const LibraryFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return ConsolePage(
      title: s.engLibraryFiles,
      subtitle: s.engLibrarySub,
      scrollable: true,
      child: const LibraryView(),
    );
  }
}

/// The Library's folders, then the files of the folder opened. The admin
/// version adds New folder / Upload file and the delete menus.
///
/// Files uploaded before folders existed (straight into `library`) are
/// listed under them as "Other files", so nothing already shared is lost.
class LibraryView extends StatefulWidget {
  const LibraryView({super.key, this.admin = false});

  final bool admin;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final EngagementRepository _repository = EngagementRepository();
  late final Stream<List<LibraryFile>> _loose = shared(() => _repository.watchLibrary());

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CourseFilesView(
          course: EngagementRepository.libraryCourse,
          admin: widget.admin,
          emptyTitle: s.engLibraryEmpty,
        ),
        StreamBuilder<List<LibraryFile>>(
          stream: _loose,
          builder: (BuildContext context, AsyncSnapshot<List<LibraryFile>> snap) {
            final List<LibraryFile> files = snap.data ?? const <LibraryFile>[];
            if (files.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 24.h, bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    FormatHelper.capitalize(s.engOtherFiles),
                    style: StyleText.fontSize15Weight600
                        .copyWith(color: AppColors.text),
                  ),
                  SizedBox(height: 10.h),
                  for (int i = 0; i < files.length; i++) ...<Widget>[
                    if (i > 0) SizedBox(height: 10.h),
                    FileTile(
                      file: files[i],
                      trailing: widget.admin
                          ? DeleteMenu(
                              onDelete: () => confirmDelete(
                                context,
                                name: files[i].title,
                                action: () =>
                                    _repository.deleteLibraryFile(files[i]),
                              ),
                            )
                          : null,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── The best ────────────────────────────────────────────────────────────────

/// One member's stars, course by course.
class MemberStars {
  const MemberStars({
    required this.uid,
    required this.name,
    required this.perCourse,
  });

  final String uid;
  final String name;

  /// course name → 0..5 stars (only courses with any progress).
  final Map<String, int> perCourse;

  int get total => perCourse.values.fold<int>(0, (int a, int b) => a + b);

  /// Stars for every member who has watched anything, best first.
  static List<MemberStars> rank(
    List<VideoItem> videos,
    List<MemberProgress> progress,
  ) {
    final List<VideoCategory> courses =
        VideoCategory.group(videos.where((VideoItem v) => v.hasFile).toList());
    final List<MemberStars> out = <MemberStars>[];
    for (final MemberProgress p in progress) {
      final Map<String, int> per = <String, int>{};
      for (final VideoCategory c in courses) {
        final double r = CourseStars.ratio(c.videos.map((VideoItem v) => p.of(v.id)));
        if (r > 0) per[c.name] = CourseStars.fromRatio(r);
      }
      if (per.isEmpty) continue;
      out.add(MemberStars(uid: p.uid, name: p.name, perCourse: per));
    }
    out.sort((MemberStars a, MemberStars b) {
      final int c = b.total.compareTo(a.total);
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, this.admin = false, this.framed = true});

  /// The admin also sees each member's stars per course.
  final bool admin;

  /// False = no page title (inside the admin's engagement tabs).
  final bool framed;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late final Stream<(List<VideoItem>, List<MemberProgress>)> _data = shared(() => combineLatest<Object, (List<VideoItem>, List<MemberProgress>)>(
    <Stream<Object>>[
      widget.admin
          ? VideoRepository().watchAll()
          : MemberVideos.watch(),
      EngagementRepository().watchAllProgress(),
    ],
    (List<Object> v) =>
        (v[0] as List<VideoItem>, v[1] as List<MemberProgress>),
  ));

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Widget body = StreamBuilder<(List<VideoItem>, List<MemberProgress>)>(
      stream: _data,
      builder: (BuildContext context,
          AsyncSnapshot<(List<VideoItem>, List<MemberProgress>)> snap) {
        if (snap.hasError) return AppErrorView(message: s.errUnknown, error: snap.error, stackTrace: snap.stackTrace);
        if (!snap.hasData) return const AppLoading();
        final List<VideoItem> videos = snap.data!.$1
            .where((VideoItem v) => v.published)
            .toList();
        final List<MemberStars> ranked = MemberStars.rank(videos, snap.data!.$2);
        if (ranked.isEmpty) {
          return AppEmptyView(
            title: s.engLeaderboardEmpty,
            subtitle: s.engStarsHint,
          );
        }
        final String me = SessionController.to.current.uid;
        return ListView.separated(
          padding: EdgeInsets.only(bottom: 24.h),
          itemCount: ranked.length + 1,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (BuildContext context, int i) {
            if (i == 0) {
              return Text(
                FormatHelper.capitalize(s.engStarsHint),
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.secondaryText),
              );
            }
            final MemberStars m = ranked[i - 1];
            return FadeSlideIn(
              delay: staggerDelay(i, stepMs: 40),
              child: _RankTile(
                rank: i,
                member: m,
                isMe: m.uid == me,
                showCourses: widget.admin,
              ),
            );
          },
        );
      },
    );

    if (!widget.framed) return body;
    return ConsolePage(
      title: s.engLibraryBest,
      subtitle: s.engLeaderboardSub,
      child: body,
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.member,
    required this.isMe,
    required this.showCourses,
  });

  final int rank;
  final MemberStars member;
  final bool isMe;
  final bool showCourses;

  static const List<Color> _medals = <Color>[
    Color(0xFFF5B301),
    Color(0xFF9CA3AF),
    Color(0xFFB45309),
  ];

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final String name = member.name.trim().isEmpty ? s.engMember : member.name;

    final Widget head = Row(
      children: <Widget>[
        SizedBox(
          width: 34.r,
          child: rank <= 3
              ? Icon(Icons.emoji_events_rounded,
                  size: 26.r, color: _medals[rank - 1])
              : Text(
                  FormatHelper.capitalize('#$rank'),
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize14Weight700
                      .copyWith(color: AppColors.secondaryText),
                ),
        ),
        SizedBox(width: 8.w),
        AppAvatar(name: name, size: 38),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            FormatHelper.capitalize(isMe ? '$name · ${s.engYou}' : name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
          ),
        ),
        StarsChip(label: '${member.total}'),
      ],
    );

    // A Material (not a coloured Container) so the ExpansionTile's ink
    // splash and background paint on this card instead of behind it.
    return Material(
      color: isMe ? AppColors.primary.withOpacity(0.08) : AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
      padding: EdgeInsets.all(12.r),
      child: !showCourses
          ? head
          : Theme(
              data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsetsDirectional.only(start: 42.w, bottom: 4.h),
                title: head,
                children: <Widget>[
                  for (final MapEntry<String, int> e in member.perCourse.entries)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              FormatHelper.capitalize(e.key.isEmpty ? s.videoCategoryGeneral : e.key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StyleText.fontSize13Weight500
                                  .copyWith(color: AppColors.text),
                            ),
                          ),
                          StarsRow(stars: e.value, size: 16),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}
