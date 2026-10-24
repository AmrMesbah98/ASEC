/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: engagement_widgets.dart
/// Purpose: Pieces the engagement pages share — `showComposeDialog` (title +
///          text, for notifications and tips), `runUpload` (pick a file,
///          upload it with a progress dialog), `FileTile` (one file row) and
///          `openFileUrl`.
/// Author: ASEC team
/// Created: 15/10/2026

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

/// What went wrong, in words the admin can act on. "permission-denied"
/// almost always means the new firestore.rules / storage.rules were not
/// deployed yet.
String engErrorText(BuildContext context, Object? error) {
  final S s = S.of(context);
  if (error is FirebaseException) {
    if (error.code == 'permission-denied' || error.code == 'unauthorized') {
      return s.engRulesMissing;
    }
    return '${s.errUnknown} (${error.code})';
  }
  return s.errUnknown;
}

void showEngagementToast(BuildContext context, String message) {
  AppMessenger.of(context)
    ..hide()
    ..show(AppMessage(content: Text(FormatHelper.capitalize(message))));
}

/// A title and a text. Resolves to null when cancelled or left empty.
Future<({String title, String body})?> showComposeDialog({
  required BuildContext context,
  required String dialogTitle,
  required String titleHint,
  required String bodyHint,
  required String submitLabel,
  IconData icon = Icons.campaign_rounded,
  String initialTitle = '',
  String initialBody = '',
}) {
  return showDialog<({String title, String body})>(
    context: context,
    builder: (_) => _ComposeDialog(
      dialogTitle: dialogTitle,
      titleHint: titleHint,
      bodyHint: bodyHint,
      submitLabel: submitLabel,
      icon: icon,
      initialTitle: initialTitle,
      initialBody: initialBody,
    ),
  );
}

class _ComposeDialog extends StatefulWidget {
  const _ComposeDialog({
    required this.dialogTitle,
    required this.titleHint,
    required this.bodyHint,
    required this.submitLabel,
    required this.icon,
    required this.initialTitle,
    required this.initialBody,
  });

  final String dialogTitle;
  final String titleHint;
  final String bodyHint;
  final String submitLabel;
  final IconData icon;
  final String initialTitle;
  final String initialBody;

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initialTitle);
  late final TextEditingController _body =
      TextEditingController(text: widget.initialBody);
  bool _submitted = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_title.text.trim().isEmpty) return;
    Navigator.of(context).pop((title: _title.text.trim(), body: _body.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return DialogShell(
      title: widget.dialogTitle,
      icon: widget.icon,
      actions: <Widget>[
        AppButton(
          label: s.cancel,
          kind: AppButtonKind.subtle,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: widget.submitLabel,
          icon: Icons.send_rounded,
          onPressed: _submit,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CustomTextField(
            fillColor: AppColors.background,
            controller: _title,
            label: s.title,
            hint: widget.titleHint,
            required: true,
            errorText: _submitted && _title.text.trim().isEmpty
                ? s.engFieldRequired
                : null,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
          SizedBox(height: 14.h),
          CustomTextField(
            fillColor: AppColors.background,
            controller: _body,
            label: s.description,
            hint: widget.bodyHint,
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}

/// Picks a file, then uploads it with a progress dialog. True when a file
/// was uploaded.
Future<bool> runUpload(
  BuildContext context,
  Future<void> Function(
    PlatformFile file,
    String title,
    void Function(double progress) onProgress,
  ) upload,
) async {
  final S s = S.of(context);
  final PlatformFile? file = await EngagementRepository.pickFile();
  if (file == null || !context.mounted) return false;

  // The title is the file's name without its extension.
  final int dot = file.name.lastIndexOf('.');
  final String title = dot > 0 ? file.name.substring(0, dot) : file.name;

  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  // showDialog opens on the root navigator, so the pop must go there too.
  final NavigatorState nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext c) => PopScope(
      canPop: false,
      child: DialogShell(
        title: s.uploadFile,
        subtitle: file.name,
        icon: Icons.cloud_upload_outlined,
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (BuildContext c, double v, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: v <= 0 ? null : v,
                  minHeight: 8.h,
                  backgroundColor: AppColors.secondaryText.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                FormatHelper.capitalize('${(v * 100).round()}%'),
                textAlign: TextAlign.center,
                style: StyleText.fontSize13Weight600
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  bool ok = true;
  bool closed = false;
  Object? failure;
  try {
    await upload(file, title, (double v) {
      if (!closed) progress.value = v;
    });
  } catch (e) {
    ok = false;
    failure = e;
  }
  closed = true;
  nav.pop();
  progress.dispose();
  if (context.mounted) {
    showEngagementToast(
      context,
      ok ? s.engFileUploaded : engErrorText(context, failure),
    );
  }
  return ok;
}

Future<void> openFileUrl(BuildContext context, String url) async {
  final S s = S.of(context);
  final Uri? uri = Uri.tryParse(url);
  bool ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context.mounted) showEngagementToast(context, s.engFileOpenFailed);
}

IconData fileIcon(String extension) {
  switch (extension) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'doc':
    case 'docx':
    case 'txt':
      return Icons.description_rounded;
    case 'xls':
    case 'xlsx':
    case 'csv':
      return Icons.table_chart_rounded;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow_rounded;
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
      return Icons.image_rounded;
    case 'zip':
    case 'rar':
      return Icons.folder_zip_rounded;
    case 'mp4':
    case 'mov':
      return Icons.movie_rounded;
    case 'dwg':
    case 'dxf':
      return Icons.architecture_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

/// One file: icon, title, size · date — tap opens it.
class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.file,
    this.onTap,
    this.trailing,
  });

  final LibraryFile file;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final String meta = <String>[
      if (file.extension.isNotEmpty) file.extension.toUpperCase(),
      if (file.sizeLabel.isNotEmpty) file.sizeLabel,
      if (file.createdAt != null) videoTimeAgo(context, file.createdAt),
    ].join(' · ');

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap ?? () => openFileUrl(context, file.url),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: <Widget>[
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AppIcon(fileIcon(file.extension),
                    size: 22.sp, color: AppColors.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(file.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize14Weight600
                          .copyWith(color: AppColors.text),
                    ),
                    if (meta.isNotEmpty) ...<Widget>[
                      SizedBox(height: 2.h),
                      Text(
                        FormatHelper.capitalize(meta),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize12Weight400
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  AppIcon(Icons.open_in_new_rounded,
                      size: 18.sp, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

/// A ⋮ menu with one red "Delete".
class DeleteMenu extends StatelessWidget {
  const DeleteMenu({
    super.key,
    this.onDelete,
    this.extra = const <(String, VoidCallback)>[],
  });

  /// Null = no "Delete" item (the admin may not delete), only [extra].
  final VoidCallback? onDelete;
  final List<(String, VoidCallback)> extra;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      icon: AppIcon(Icons.more_vert_rounded, size: 20.sp),
      onSelected: (int i) {
        if (i < 0) {
          onDelete?.call();
        } else {
          extra[i].$2();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        for (int i = 0; i < extra.length; i++)
          PopupMenuItem<int>(value: i, child: Text(FormatHelper.capitalize(extra[i].$1))),
        if (onDelete != null)
          PopupMenuItem<int>(
            value: -1,
            child: Text(
              FormatHelper.capitalize(s.delete),
              style: StyleText.fontSize14Weight500.copyWith(color: AppColors.red),
            ),
          ),
      ],
    );
  }
}

/// "Delete X?" then [action].
Future<void> confirmDelete(
  BuildContext context, {
  required String name,
  required Future<void> Function() action,
  String? body,
}) async {
  final S s = S.of(context);
  await CustomDialogManager.showConfirm(
    context: context,
    title: s.deleteQuestion(name),
    subtitle: body ?? s.engDeleteBody,
    confirmLabel: s.delete,
    cancelLabel: s.cancel,
    onConfirm: () async {
      final AppMessenger m = AppMessenger.of(context);
      final String done = s.deleted;
      try {
        await action();
        m.show(AppMessage(content: Text(FormatHelper.capitalize(done))));
      } catch (e) {
        if (context.mounted) {
          m.show(AppMessage(content: Text(FormatHelper.capitalize(engErrorText(context, e)))));
        }
      }
    },
  );
}
