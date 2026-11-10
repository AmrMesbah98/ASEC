/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: admin_videos_page.dart
/// Purpose: Declares `AdminVideosPage` — every lesson, with the way in to the
///          upload form.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 1/10/2026 - Categories first (one per Drive sub-folder), then
///          the videos of the category opened.
/// Updated: 15/10/2026 - Per course: Videos / Files (folders + files) and
///          the "watch in order" switch; Default / Custom videos; the back
///          button stays pinned.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/58-default_switch_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/course_settings.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/course_files_view.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/data/catalog/video_catalog.dart';
import 'package:asec/features/video/v1_videos/data/seed/drive_lessons.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/data/upload/drive_uploader.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/upload/bulk_upload_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_form_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_grid.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/section_quizzes.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/network/shared_stream.dart';

class AdminVideosPage extends StatefulWidget {
  const AdminVideosPage({super.key, required this.adminUid});

  final String adminUid;

  @override
  State<AdminVideosPage> createState() => _AdminVideosPageState();
}

class _AdminVideosPageState extends State<AdminVideosPage> {
  final VideoBaseRepository _repository = VideoRepository();
  late final Stream<List<VideoItem>> _videos = shared(() => _repository.watchAll());

  /// The category opened; null = the category list.
  String? _category;

  /// The sub-folder opened inside [_category]; null = its sub-folder list.
  String? _subcategory;

  /// The course's "Files" instead of its videos.
  bool _showFiles = false;

  final EngagementRepository _engagement = EngagementRepository();

  bool get _canEdit => SessionController.to.current.canDo(AdminAction.videosEdit);
  bool get _canAccess => SessionController.to.current.canDo(AdminAction.videosAccess);
  bool get _canDelete => SessionController.to.current.canDo(AdminAction.videosDelete);

  Future<void> _setFree(VideoItem video, bool free) async {
    final S s = S.of(context);
    final AppMessenger messenger = AppMessenger.of(context);
    try {
      await _engagement.setVideoFree(video.id, free);
      messenger.show(AppMessage(
        content: Text(FormatHelper.capitalize(free ? s.engVideoDefault : s.engVideoCustom)),
      ));
    } catch (_) {
      messenger.show(AppMessage(content: Text(FormatHelper.capitalize(s.errUnknown))));
    }
  }

  /// "Upload lessons" (from ENGX, 09/11/2026): many videos at once, straight
  /// into the Drive lessons folder, then one sync makes them lessons. Desktop
  /// only (the Google sign-in needs it); phones keep the single-video form.
  Future<void> _openBulk() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BulkUploadPage(
            adminUid: widget.adminUid,
            category: _category ?? '',
          ),
        ),
      );

  Future<void> _openForm([VideoItem? video]) => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => VideoFormPage(
            video: video,
            adminUid: widget.adminUid,
            // A video added from inside a category lands in that category.
            category: _category ?? '',
          ),
        ),
      );

  /// The lessons come from the shared Google Drive folder by themselves:
  /// this page is built when the admin shell opens (it keeps every section
  /// alive), so every time an admin opens the app the videos are brought in
  /// line with the folder — new files added, removed ones dropped, the old
  /// sample videos cleared. See DriveVideoSync. The list below is a live
  /// Firestore stream, so it updates the moment the sync writes.
  ///
  /// It also runs again when the app comes back to the foreground and every
  /// few minutes while it stays open, so a folder added in Drive shows up
  /// without restarting the app. The sync only writes what changed.
  Timer? _resync;
  AppLifecycleListener? _lifecycle;
  String? _lastShown;

  @override
  void initState() {
    super.initState();
    _sync();
    // Members see every course (the ones they were not given locked) from
    // the link-free catalog — kept in line with the videos from here.
    VideoCatalog.startAdminSync();
    _resync = Timer.periodic(const Duration(minutes: 3), (_) => _sync());
    _lifecycle = AppLifecycleListener(onResume: _sync);
  }

  @override
  void dispose() {
    _resync?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  /// Shows why folders are missing — once per distinct message, so the
  /// periodic sync does not repeat the same snackbar.
  void _sync() {
    // The sync adds, edits and deletes videos, so only an admin who may do
    // all three runs it (the rules would refuse the rest anyway).
    final AppUser me = SessionController.to.current;
    if (!me.canDo(AdminAction.videosAdd) ||
        !me.canDo(AdminAction.videosEdit) ||
        !me.canDo(AdminAction.videosDelete)) {
      return;
    }
    // No snackbar: a sync problem is only logged (debug console), so the
    // admin's screens stay clean.
    DriveVideoSync.run(adminUid: widget.adminUid).then((String? problem) {
      if (problem == null || problem == _lastShown) return;
      _lastShown = problem;
    });
  }

  Future<void> _confirmDelete(VideoItem video) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.deleteQuestion(video.title),
      subtitle: s.deleteVideoBody,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      onConfirm: () async {
        final AppMessenger messenger = AppMessenger.of(context);
        final String deleted = s.deleted;
        await _repository.delete(video);
        messenger.show(AppMessage(content: Text(FormatHelper.capitalize(deleted))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      // Videos → Add / upload.
      floatingActionButton: !SessionController.to.current.canDo(AdminAction.videosAdd)
          ? null
          : FloatingActionButton.extended(
        // THE SHELL KEEPS EVERY SECTION ALIVE (IndexedStack), so this FAB and
        // the quizzes FAB exist in the same route subtree. Flutter gives every
        // FAB the same default hero tag, and two heroes with one tag is an
        // exception on the next page push — hence an explicit tag each.
        heroTag: 'asec_fab_videos',
        onPressed: DriveUploader.supported ? _openBulk : _openForm,
        backgroundColor: AppColors.primary,
        icon: AppIcon(
          DriveUploader.supported ? Icons.rocket_launch_rounded : Icons.cloud_upload_outlined,
          color: AppColors.textButton,
        ),
        label: Text(
          FormatHelper.capitalize(DriveUploader.supported ? 'Upload lessons' : s.addVideo),
          style: StyleText.fontSize14Weight600.copyWith(color: AppColors.textButton),
        ),
      ),
      body: StreamBuilder<List<VideoItem>>(
        stream: _videos,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<VideoItem>> snapshot,
        ) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown, error: snapshot.error, stackTrace: snapshot.stackTrace);
          if (!snapshot.hasData) return const AppLoading();

          final List<VideoItem> all = snapshot.data!.toList()
            // Lesson order (reversed: latest upload first), the same as members see.
            ..sort((VideoItem a, VideoItem b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));
          if (all.isEmpty) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosAdminSub,
              child: AppEmptyView(
                title: s.noVideosTitle,
                subtitle: s.noVideosAdminSub,
              ),
            );
          }

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
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosAdminSub,
              child: VideoCategoryGrid(
                categories: categories,
                showProgress: false,
                showSubtitles: true,
                bottomPadding: 96,
                onOpen: (VideoCategory c) => setState(() {
                  _category = c.name;
                  _subcategory = null;
                  _showFiles = false;
                }),
              ),
            );
          }

          // Sub-folders of the category (AutoCAD → Introduction-01, …).
          final VideoCategory category = current;
          final List<VideoCategory> subs =
              VideoCategory.group(category.videos, bySubcategory: true);

          // THE COURSE BAR: Videos / Files, and the course's own "watch in
          // order" switch. Pinned with the back button.
          final Widget courseBar = _CourseBar(
            course: category.name,
            showFiles: _showFiles,
            onShowFiles: (bool v) => setState(() => _showFiles = v),
          );

          VideoCategory? sub;
          if (subs.length > 1) {
            for (final VideoCategory c in subs) {
              if (c.name == _subcategory) sub = c;
            }
          }

          final Widget? back = sub != null
              ? VideoCategoryHeader(
                  category: sub,
                  backLabel: category.label(s),
                  onBack: () => setState(() => _subcategory = null),
                )
              : grouped
                  ? VideoCategoryHeader(
                      category: category,
                      onBack: () => setState(() {
                        _category = null;
                        _showFiles = false;
                      }),
                    )
                  : null;

          final Widget pinned = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (back != null) back,
              courseBar,
              SizedBox(height: 14.h),
            ],
          );

          // FILES: the course's folders and the files in them.
          if (_showFiles) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosAdminSub,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  pinned,
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 96.h),
                      child: CourseFilesView(course: category.name, admin: true),
                    ),
                  ),
                ],
              ),
            );
          }

          if (subs.length > 1 && sub == null) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosAdminSub,
              child: VideoCategoryGrid(
                categories: subs,
                showProgress: false,
                bottomPadding: 96,
                onOpen: (VideoCategory c) =>
                    setState(() => _subcategory = c.name),
                pinned: pinned,
              ),
            );
          }
          if (sub != null) current = sub;

          final List<VideoItem> videos = current.videos;
          return ConsolePage(
            title: s.typeVideos,
            subtitle: s.videosAdminSub,
            child: VideoGrid(
              videos: videos,
              pinned: pinned,
              // Quizzes of this section: add one, edit the ones there.
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Only admins who may manage quizzes (the rules check
                  // the same 'quizzes' permission when saving).
                  if (SessionController.to.current.can(AdminPermission.quizzes)) ...<Widget>[
                  SectionQuizzes.admin(
                    course: category.name,
                    sections: sub != null
                        ? <String>[sub.name]
                        : <String>[
                            '',
                            for (final VideoCategory c in subs)
                              if (c.name.isNotEmpty) c.name,
                          ],
                    adminUid: widget.adminUid,
                  ),
                  SizedBox(height: 12.h),
                  ],
                ],
              ),
              bottomPadding: 96,
              // DEFAULT = every member sees it; CUSTOM = only members with
              // the course. Never "free" / "paid" — not even for the admin.
              badgeBuilder: (VideoItem video) => _AccessBadge(free: video.free),
              onOpen: (VideoItem video) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      VideoPlayerPage(video: video, playlist: videos),
                ),
              ),
              trailingBuilder: !(_canEdit || _canAccess || _canDelete)
                  ? null
                  : (VideoItem video) => PopupMenuButton<_VideoAction>(
                padding: EdgeInsets.zero,
                icon: AppIcon(Icons.more_vert_rounded, size: 20.sp),
                onSelected: (_VideoAction action) {
                  switch (action) {
                    case _VideoAction.edit:
                      _openForm(video);
                    case _VideoAction.toggleFree:
                      _setFree(video, !video.free);
                    case _VideoAction.delete:
                      _confirmDelete(video);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_VideoAction>>[
                  if (_canEdit)
                  PopupMenuItem<_VideoAction>(
                    value: _VideoAction.edit,
                    child: Text(FormatHelper.capitalize(s.edit)),
                  ),
                  if (_canAccess)
                  PopupMenuItem<_VideoAction>(
                    value: _VideoAction.toggleFree,
                    child: Text(FormatHelper.capitalize(video.free ? s.engMakeCustom : s.engMakeDefault)),
                  ),
                  if (_canDelete)
                  PopupMenuItem<_VideoAction>(
                    value: _VideoAction.delete,
                    child: Text(
                      FormatHelper.capitalize(s.delete),
                      style: StyleText.fontSize14Weight500
                          .copyWith(color: AppColors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _VideoAction { edit, toggleFree, delete }

/// "Default" (every member) or "Custom" (members with the course).
class _AccessBadge extends StatelessWidget {
  const _AccessBadge({required this.free});

  final bool free;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Color color = free ? const Color(0xFF16A34A) : const Color(0xFF6366F1);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            free ? Icons.public_rounded : Icons.tune_rounded,
            size: 12,
            color: Colors.white,
          ),
          SizedBox(width: 4.w),
          Text(
            FormatHelper.capitalize(free ? s.engVideoDefault : s.engVideoCustom),
            style: StyleText.fontSize11Weight600.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Videos / Files for the course opened, and its "watch in order" switch.
class _CourseBar extends StatelessWidget {
  const _CourseBar({
    required this.course,
    required this.showFiles,
    required this.onShowFiles,
  });

  final String course;
  final bool showFiles;
  final ValueChanged<bool> onShowFiles;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Wrap(
      spacing: 12.w,
      runSpacing: 10.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        Wrap(
          runSpacing: 8.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _BarChip(
              label: s.typeVideos,
              icon: Icons.video_library_rounded,
              selected: !showFiles,
              onTap: () => onShowFiles(false),
            ),
            SizedBox(width: 8.w),
            _BarChip(
              label: s.engFilesTab,
              icon: Icons.folder_rounded,
              selected: showFiles,
              onTap: () => onShowFiles(true),
            ),
            // The line under the course's title on the course cards.
            if (SessionController.to.current.canDo(AdminAction.videosEdit)) ...<Widget>[
              SizedBox(width: 8.w),
              _BarChip(
                label: s.courseSubtitleEdit,
                icon: Icons.short_text_rounded,
                selected: false,
                onTap: () => _editSubtitle(context, course),
              ),
            ],
          ],
        ),
        Obx(() {
          final bool on = CourseSettings.to.isSequential(course);
          return Container(
            padding: EdgeInsetsDirectional.fromSTEB(12.w, 6.h, 8.w, 6.h),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon(Icons.lock_clock_rounded,
                    size: 18.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        FormatHelper.capitalize(s.engCourseSequential),
                        style: StyleText.fontSize13Weight600
                            .copyWith(color: AppColors.text),
                      ),
                      Text(
                        FormatHelper.capitalize(s.engCourseSequentialHint),
                        style: StyleText.fontSize11Weight400
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                // Videos → Course access.
                IgnorePointer(
                  ignoring: !SessionController.to.current
                      .canDo(AdminAction.videosAccess),
                  child: DefaultSwitchButton(
                    value: on,
                    onChanged: (bool v) =>
                        CourseSettings.to.setSequential(course, v),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Asks for the line shown under [course]'s title ('' removes it).
Future<void> _editSubtitle(BuildContext context, String course) async {
  final S s = S.of(context);
  final TextEditingController text =
      TextEditingController(text: CourseSettings.to.subtitle(course));
  final String? value = await showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        FormatHelper.capitalize('${s.courseSubtitle} · $course'),
        style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
      ),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: text,
          autofocus: true,
          maxLength: 80,
          style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
          decoration: InputDecoration(hintText: s.courseSubtitleHint),
          onSubmitted: (String v) => Navigator.of(ctx).pop(v),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(FormatHelper.capitalize(s.cancel)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(text.text),
          child: Text(FormatHelper.capitalize(s.save)),
        ),
      ],
    ),
  );
  text.dispose();
  if (value == null) return;
  try {
    await CourseSettings.to.setSubtitle(course, value);
  } catch (_) {
    if (context.mounted) {
      AppMessenger.of(context).show(
        AppMessage(content: Text(FormatHelper.capitalize(s.errUnknown))),
      );
    }
  }
}

class _BarChip extends StatelessWidget {
  const _BarChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

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
              AppIcon(icon,
                  size: 16.sp,
                  color: selected ? AppColors.background : AppColors.primary),
              SizedBox(width: 6.w),
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

