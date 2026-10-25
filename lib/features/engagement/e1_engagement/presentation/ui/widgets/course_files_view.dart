/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: course_files_view.dart
/// Purpose: Declares `CourseFilesView` — a course's "Files": its folders,
///          then the files of the folder opened. The admin creates folders
///          and uploads files into them; members open the files.
/// Author: ASEC team
/// Created: 15/10/2026
///
/// NOT A SCROLL VIEW. It is a plain column, so the Videos page can put it
/// under the course header inside the scroll it already has.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class CourseFilesView extends StatefulWidget {
  const CourseFilesView({
    super.key,
    required this.course,
    this.admin = false,
    this.emptyTitle,
  });

  /// What "no folders yet" says (the Library says it its own way).
  final String? emptyTitle;

  /// The video category the files belong to.
  final String course;

  /// Shows "New folder", "Upload file" and the delete menus.
  final bool admin;

  @override
  State<CourseFilesView> createState() => _CourseFilesViewState();
}

class _CourseFilesViewState extends State<CourseFilesView> {
  // What this admin may do here: the Library follows Engagement → Library,
  // a course's files follow Videos → add / edit / delete.
  bool get _isLibrary => widget.course == EngagementRepository.libraryCourse;
  bool _may(AdminAction videosAction) {
    if (!widget.admin) return false;
    final AppUser me = SessionController.to.current;
    return _isLibrary
        ? me.canDo(AdminAction.engagementLibrary)
        : me.canDo(videosAction);
  }

  bool get _canAdd => _may(AdminAction.videosAdd);
  bool get _canEdit => _may(AdminAction.videosEdit);
  bool get _canDelete => _may(AdminAction.videosDelete);

  final EngagementRepository _repository = EngagementRepository();
  late Stream<List<CourseEntry>> _entries =
      _repository.watchCourseFiles(widget.course);

  /// The folder opened; null = the folder list.
  String? _folderId;

  @override
  void didUpdateWidget(covariant CourseFilesView old) {
    super.didUpdateWidget(old);
    if (old.course != widget.course) {
      _entries = _repository.watchCourseFiles(widget.course);
      _folderId = null;
    }
  }

  Future<void> _newFolder() async {
    final S s = S.of(context);
    final String? name = await CustomDialogManager.showInput(
      context: context,
      title: s.engNewFolder,
      fieldLabel: s.engFolderName,
      hint: s.engFolderName,
      submitLabel: s.add,
      cancelLabel: s.cancel,
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await _repository.addCourseFolder(widget.course, name);
      if (mounted) showEngagementToast(context, s.engFolderCreated);
    } catch (_) {
      if (mounted) showEngagementToast(context, s.errUnknown);
    }
  }

  Future<void> _rename(CourseEntry folder) async {
    final S s = S.of(context);
    final String? name = await CustomDialogManager.showInput(
      context: context,
      title: s.engRename,
      subtitle: folder.name,
      fieldLabel: s.engFolderName,
      hint: folder.name,
      submitLabel: s.save,
      cancelLabel: s.cancel,
    );
    if (name == null || name.trim().isEmpty) return;
    await _repository.renameCourseFolder(folder.id, name);
  }

  Future<void> _upload(String folderId) => runUpload(
        context,
        (file, title, onProgress) => _repository.addCourseFile(
          widget.course,
          folderId,
          file,
          title: title,
          onProgress: onProgress,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<CourseEntry>>(
      stream: _entries,
      builder: (BuildContext context, AsyncSnapshot<List<CourseEntry>> snap) {
        if (snap.hasError) {
          // Refused = the member has not been given this course (or it is
          // outside its dates). Say so, instead of "something went wrong".
          final Object? e = snap.error;
          if (e is FirebaseException && e.code == 'permission-denied') {
            return SizedBox(
              height: _emptyHeight(context),
              child: AppEmptyView(title: s.courseFilesLocked, subtitle: s.courseFilesLockedSub),
            );
          }
          return SizedBox(height: 200.h, child: AppErrorView(message: s.errUnknown));
        }
        if (!snap.hasData) return SizedBox(height: 160.h, child: const AppLoading());
        final List<CourseEntry> all = snap.data!;
        final List<CourseEntry> folders =
            all.where((CourseEntry e) => e.isFolder).toList();

        CourseEntry? open;
        for (final CourseEntry f in folders) {
          if (f.id == _folderId) open = f;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: open == null
              ? _folderList(context, all, folders)
              : _folderFiles(context, all, open),
        );
      },
    );
  }

  Widget _folderList(
    BuildContext context,
    List<CourseEntry> all,
    List<CourseEntry> folders,
  ) {
    final S s = S.of(context);
    return Column(
      key: const ValueKey<String>('folders'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_canAdd) ...<Widget>[
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: <Widget>[
              AppButton(
                label: s.engNewFolder,
                icon: Icons.create_new_folder_rounded,
                kind: AppButtonKind.subtle,
                dense: true,
                onPressed: _newFolder,
              ),
              // Asks which folder first (or makes one), then the file.
              AppButton(
                label: s.uploadFile,
                icon: Icons.upload_file_rounded,
                dense: true,
                onPressed: () => uploadIntoFolder(context, widget.course),
              ),
            ],
          ),
          SizedBox(height: 14.h),
        ],
        if (folders.isEmpty)
          // CENTRED in the free space below the header, not stuck at the top.
          SizedBox(
            height: _emptyHeight(context),
            child: AppEmptyView(
              title: widget.emptyTitle ?? s.engCourseFilesEmpty,
              subtitle: widget.admin ? s.engCourseFilesEmptyAdmin : null,
              size: 120,
            ),
          )
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double gap = 12.w;
              final int cols = ((c.maxWidth + gap) / (260 + gap)).floor().clamp(1, 5);
              final double width = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  for (int i = 0; i < folders.length; i++)
                    SizedBox(
                      width: width,
                      child: FadeSlideIn(
                        delay: staggerDelay(i, stepMs: 40),
                        child: _FolderCard(
                          folder: folders[i],
                          count: all
                              .where((CourseEntry e) =>
                                  !e.isFolder && e.folderId == folders[i].id)
                              .length,
                          onTap: () => setState(() => _folderId = folders[i].id),
                          trailing: (_canEdit || _canDelete)
                              ? DeleteMenu(
                                  extra: <(String, VoidCallback)>[
                                    if (_canEdit)
                                      (s.engRename, () => _rename(folders[i])),
                                  ],
                                  onDelete: !_canDelete ? null : () => confirmDelete(
                                    context,
                                    name: folders[i].name,
                                    body: s.engDeleteFolderBody,
                                    action: () => _repository.deleteCourseFolder(
                                        folders[i], all),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _folderFiles(
    BuildContext context,
    List<CourseEntry> all,
    CourseEntry folder,
  ) {
    final S s = S.of(context);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final List<CourseEntry> files = all
        .where((CourseEntry e) => !e.isFolder && e.folderId == folder.id)
        .toList();

    return Column(
      key: ValueKey<String>('folder_${folder.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12.w,
          runSpacing: 8.h,
          children: <Widget>[
            AppButton(
              label: '${rtl ? '→' : '←'}  ${s.engAllFolders}',
              kind: AppButtonKind.subtle,
              dense: true,
              onPressed: () => setState(() => _folderId = null),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon(Icons.folder_open_rounded,
                    size: 20.sp, color: AppColors.primary),
                SizedBox(width: 6.w),
                Text(
                  FormatHelper.capitalize(folder.name),
                  style: StyleText.fontSize16Weight600
                      .copyWith(color: AppColors.text),
                ),
              ],
            ),
            if (_canAdd)
              AppButton(
                label: s.uploadFile,
                icon: Icons.upload_file_rounded,
                dense: true,
                onPressed: () => _upload(folder.id),
              ),
          ],
        ),
        SizedBox(height: 14.h),
        if (files.isEmpty)
          SizedBox(
            height: _emptyHeight(context),
            child: AppEmptyView(title: s.engFolderEmpty, size: 120),
          )
        else
          for (int i = 0; i < files.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: 10.h),
            FadeSlideIn(
              delay: staggerDelay(i, stepMs: 40),
              child: FileTile(
                file: files[i].file!,
                trailing: _canDelete
                    ? DeleteMenu(
                        onDelete: () => confirmDelete(
                          context,
                          name: files[i].name,
                          action: () => _repository.deleteCourseFile(files[i]),
                        ),
                      )
                    : null,
              ),
            ),
          ],
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.count,
    required this.onTap,
    this.trailing,
  });

  final CourseEntry folder;
  final int count;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
          child: Row(
            children: <Widget>[
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AppIcon(Icons.folder_rounded,
                    size: 24.sp, color: const Color(0xFFF59E0B)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(folder.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize15Weight600
                          .copyWith(color: AppColors.text),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      FormatHelper.capitalize(s.engFileCount(count)),
                      style: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 10.w),
                    child: AppIcon(Icons.chevron_right_rounded,
                        size: 20.sp, color: AppColors.secondaryText),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── "Upload into which folder?" ─────────────────────────────────────────────

/// UPLOAD = FOLDER FIRST. Asks which folder of [course] the file goes into
/// — or makes a new folder right there — and only then opens the file
/// picker and uploads into it.
Future<void> uploadIntoFolder(BuildContext context, String course) async {
  final EngagementRepository repository = EngagementRepository();
  List<CourseEntry> folders;
  try {
    folders = await repository.courseFolders(course);
  } catch (e) {
    if (context.mounted) showEngagementToast(context, engErrorText(context, e));
    return;
  }
  if (!context.mounted) return;

  final String? folderId = await showDialog<String>(
    context: context,
    builder: (_) => _FolderPickerDialog(course: course, folders: folders),
  );
  if (folderId == null || !context.mounted) return;

  await runUpload(
    context,
    (file, title, onProgress) => repository.addCourseFile(
      course,
      folderId,
      file,
      title: title,
      onProgress: onProgress,
    ),
  );
}

class _FolderPickerDialog extends StatefulWidget {
  const _FolderPickerDialog({required this.course, required this.folders});

  final String course;
  final List<CourseEntry> folders;

  @override
  State<_FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<_FolderPickerDialog> {
  final TextEditingController _name = TextEditingController();
  bool _creating = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final String id =
          await EngagementRepository().addCourseFolder(widget.course, name);
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showEngagementToast(context, engErrorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return DialogShell(
      title: s.engChooseFolder,
      subtitle: s.engChooseFolderSub,
      icon: Icons.folder_open_rounded,
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final CourseEntry f in widget.folders) ...<Widget>[
            Material(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: _busy ? null : () => Navigator.of(context).pop(f.id),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  child: Row(
                    children: <Widget>[
                      AppIcon(Icons.folder_rounded,
                          size: 22.sp, color: const Color(0xFFF59E0B)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          FormatHelper.capitalize(f.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize14Weight600
                              .copyWith(color: AppColors.text),
                        ),
                      ),
                      AppIcon(Icons.chevron_right_rounded,
                          size: 20.sp, color: AppColors.secondaryText),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
          if (widget.folders.isEmpty) ...<Widget>[
            Text(
              FormatHelper.capitalize(s.engNoFoldersYet),
              style: StyleText.fontSize13Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
            SizedBox(height: 12.h),
          ],
          // A NEW FOLDER, made here and picked straight away.
          if (!_creating && widget.folders.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: s.engNewFolder,
                icon: Icons.create_new_folder_rounded,
                kind: AppButtonKind.subtle,
                dense: true,
                onPressed: () => setState(() => _creating = true),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: CustomTextField(
                    fillColor: AppColors.background,
                    controller: _name,
                    label: s.engNewFolder,
                    hint: s.engFolderName,
                    onSubmitted: (_) => _create(),
                  ),
                ),
                SizedBox(width: 10.w),
                AppButton(
                  label: s.add,
                  icon: Icons.check_rounded,
                  dense: true,
                  loading: _busy,
                  onPressed: _create,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Height for an empty state inside a scrolling page: most of the window,
/// so the animation sits in the middle of the screen rather than at the top.
double _emptyHeight(BuildContext context) =>
    (MediaQuery.sizeOf(context).height * 0.6).clamp(280.0, 720.0);
