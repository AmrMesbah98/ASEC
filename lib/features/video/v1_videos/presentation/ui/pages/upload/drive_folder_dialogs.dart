/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: drive_folder_dialogs.dart
/// Purpose: The lessons folder tools of "Upload lessons" (ported from ENGX,
///          09/11/2026):
///            * `showNewFolderDialog`   — name a new category folder (or a
///              sub-category inside a category), made on the server;
///            * `pickDriveFolder`       — the folder tree (main folder,
///              categories, sub-categories); returns the one tapped;
///            * `showServerSignInDialog` — the Google "Desktop app" client.
///          ASEC design: filled dialog, customButton, CustomTextField.
/// Author: ASEC team
/// Created: 09/11/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/video/v1_videos/data/upload/drive_uploader.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/upload/upload_kit.dart';

const IconData _folderSvg = Icons.folder_open_rounded;
const IconData _homeSvg = Icons.home_rounded;
const IconData _closeSvg = Icons.close_rounded;
const IconData _chevronSvg = Icons.chevron_right_rounded;
const IconData _plusSvg = Icons.create_new_folder_rounded;
const IconData _warnSvg = Icons.warning_amber_rounded;
const IconData _gearSvg = Icons.settings_rounded;

String _errorText(UpS s, Object e) {
  if (e is DriveSetupMissing) return e.what == 'folder' ? s.upDriveNotSet : s.upDriveOauthMissing;
  return s.upServerError;
}

/// The dialog frame: filled, radius 12, SVG badge, title, close, actions.
class _Shell extends StatelessWidget {
  const _Shell({
    required this.svg,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.width = 460,
  });

  final IconData svg;
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(-3, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(svg, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText)),
                      ],
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AppIcon(_closeSvg, size: 16, color: AppColors.secondaryText),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(child: SingleChildScrollView(child: child)),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 10),
                    actions[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Name a new folder: a course ([inCourse] empty) or a section in [inCourse].
Future<void> showNewFolderDialog(
  BuildContext context, {
  String inCourse = '',
  required VoidCallback onDone,
}) async {
  const UpS s = UpS.of2;
  final TextEditingController name = TextEditingController();
  final String? picked = await showDialog<String>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (BuildContext ctx) => _Shell(
      svg: _plusSvg,
      title: s.fldNew,
      subtitle: inCourse.isEmpty ? s.fldNewTop : s.fldNewIn(inCourse),
      width: 440,
      child: CustomTextField(
        controller: name,
        hint: s.fldName,
        textInputAction: TextInputAction.done,
        onSubmitted: (String v) => Navigator.of(ctx).pop(v.trim()),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: AppIcon(_folderSvg, size: 16, color: AppColors.primary),
        ),
      ),
      actions: <Widget>[
        customButton(
          title: s.cancel,
          function: () => Navigator.of(ctx).pop(),
          color: Colors.transparent,
          textColor: AppColors.primary,
          borderColor: AppColors.primary,
        ),
        customButton(title: s.fldCreate, function: () => Navigator.of(ctx).pop(name.text.trim())),
      ],
    ),
  );
  name.dispose();
  if (picked == null || picked.isEmpty || !context.mounted) return;
  try {
    await DriveUploader.createFolder(picked, inCourse: inCourse);
    if (context.mounted) AppMessenger.of(context).show(AppMessage(content: Text(s.fldCreated(picked))));
    onDone();
  } catch (e) {
    debugPrint('[Folders] create failed: $e');
    if (context.mounted) AppMessenger.of(context).show(AppMessage(content: Text(_errorText(s, e))));
  }
}

/// The lessons folders (main, courses, sections — empty ones too); returns
/// the one tapped. [isCurrent] marks (and disables) one.
Future<DriveFolder?> pickDriveFolder(
  BuildContext context, {
  required String title,
  bool Function(DriveFolder f)? isCurrent,
}) {
  const UpS s = UpS.of2;
  final Future<List<DriveFolder>> load = DriveUploader.folders();
  return showDialog<DriveFolder>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (BuildContext ctx) => _Shell(
      svg: _folderSvg,
      title: title,
      child: FutureBuilder<List<DriveFolder>>(
        future: load,
        builder: (BuildContext context, AsyncSnapshot<List<DriveFolder>> snap) {
          if (snap.hasError) {
            return SizedBox(
              height: 160,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  AppIcon(_warnSvg, size: 28, color: AppColors.red),
                  const SizedBox(height: 10),
                  Text(_errorText(s, snap.error!),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.red)),
                  if (snap.error is DriveSetupMissing) ...<Widget>[
                    const SizedBox(height: 14),
                    customButton(
                      title: 'Set up server sign-in',
                      function: () {
                        Navigator.of(ctx).pop();
                        showServerSignInDialog(context);
                      },
                      wrapContent: true,
                    ),
                  ],
                ]),
              ),
            );
          }
          if (!snap.hasData) {
            return SizedBox(
              height: 160,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(s.fldLoading, style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                ]),
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final DriveFolder f in snap.data!)
                _FolderTile(
                  folder: f,
                  label: f.isRoot ? s.fldRoot : f.name,
                  currentLabel: s.fldCurrent,
                  current: isCurrent?.call(f) ?? false,
                  onTap: () => Navigator.of(ctx).pop(f),
                ),
            ],
          );
        },
      ),
      actions: <Widget>[
        customButton(
          title: s.cancel,
          function: () => Navigator.of(ctx).pop(),
          color: Colors.transparent,
          textColor: AppColors.primary,
          borderColor: AppColors.primary,
        ),
      ],
    ),
  );
}

/// One folder: main folder and courses as filled rows with a badge, sections
/// indented under their course with a guide line. No hover tint.
class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.label,
    required this.currentLabel,
    required this.current,
    required this.onTap,
  });

  final DriveFolder folder;
  final String label;
  final String currentLabel;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool section = !folder.isRoot && !folder.isCourse;
    final Widget row = MouseRegion(
      cursor: current ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: current ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: section ? 9 : 11),
          decoration: BoxDecoration(
            color: current
                ? AppColors.primary.withOpacity(0.14)
                : section
                    ? Colors.transparent
                    : AppColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              if (section)
                AppIcon(_folderSvg, size: 16, color: AppColors.primary)
              else
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: AppIcon(folder.isRoot ? _homeSvg : _folderSvg, size: 17, color: AppColors.primary),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: section ? 13 : 14,
                    fontWeight: section ? FontWeight.w500 : FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (current)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text(currentLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                )
              else
                AppIcon(_chevronSvg, size: 16, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
    if (!section) return Padding(padding: EdgeInsets.only(top: folder.isRoot ? 0 : 8), child: row);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 2),
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: 12),
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: AppColors.primary.withOpacity(0.35), width: 2)),
        ),
        child: row,
      ),
    );
  }
}


/// Upload lessons → "Server sign-in settings": paste the Google OAuth
/// "Desktop app" client (ID + secret). Saved to `academy_settings/drive`.
Future<void> showServerSignInDialog(BuildContext context) async {
  final (String id0, String secret0) = await DriveUploader.oauthClient().catchError((Object _) => ('', ''));
  if (!context.mounted) return;
  final TextEditingController id = TextEditingController(text: id0);
  final TextEditingController secret = TextEditingController(text: secret0);
  final bool? save = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (BuildContext ctx) => _Shell(
      svg: _gearSvg,
      title: 'Server sign-in',
      subtitle: 'The Google "Desktop app" client the upload signs in with.',
      width: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'console.cloud.google.com → your project:\n'
              '1. APIs & Services → Library → enable "Google Drive API".\n'
              '2. OAuth consent screen → External, app name ASEC → add the Google account that owns '
              'the lessons folder under Test users.\n'
              '3. Credentials → Create credentials → OAuth client ID → Application type "Desktop app" → '
              'copy the Client ID and Client secret here.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.text),
            ),
          ),
          const SizedBox(height: 14),
          CustomTextField(controller: id, hint: 'Client ID (…apps.googleusercontent.com)'),
          const SizedBox(height: 10),
          CustomTextField(controller: secret, hint: 'Client secret (GOCSPX-…)'),
        ],
      ),
      actions: <Widget>[
        customButton(
          title: 'Cancel',
          function: () => Navigator.of(ctx).pop(false),
          color: Colors.transparent,
          textColor: AppColors.primary,
          borderColor: AppColors.primary,
        ),
        customButton(title: 'Save', function: () => Navigator.of(ctx).pop(true)),
      ],
    ),
  );
  final String newId = id.text.trim();
  final String newSecret = secret.text.trim();
  id.dispose();
  secret.dispose();
  if (save != true || !context.mounted) return;
  if (!newId.endsWith('.apps.googleusercontent.com')) {
    AppMessenger.of(context).show(const AppMessage(content: Text('That Client ID does not look right — it ends with .apps.googleusercontent.com')));
    return;
  }
  try {
    await DriveUploader.saveOAuthClient(newId, newSecret);
    if (context.mounted) {
      AppMessenger.of(context).show(const AppMessage(
          content: Text('Saved. Choose a folder — the browser opens once to sign in with Google.')));
    }
  } catch (e) {
    if (context.mounted) AppMessenger.of(context).show(AppMessage(content: Text('Could not save: $e')));
  }
}
