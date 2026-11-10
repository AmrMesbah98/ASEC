/// Module: admin / a2_members
///
///*************************** FILE INFO ****************************///
/// File Name: access_import.dart
/// Purpose: Members → "Upload Excel": gives course access to many members
///          at once from a sheet of emails and course names (layout in
///          data/access_sheet.dart). Preview first, then save.
/// Author: ASEC team
/// Created: 2/11/2026
///
/// WHAT IT WRITES — the same fields as Members → Edit access, so the app and
/// firestore.rules (`hasCourse`) need nothing new:
///   * ALL            → courses_all: true (every course), course limits cleared
///   * Replace        → courses_all: false, courses: exactly the sheet's
///   * Add (default)  → courses_all: false, courses: + the sheet's.
///                      A member who already has every course is left alone.
/// General Notes and Tips and Tricks (MemberAccess.defaultCourses) stay open
/// either way. Course names are matched to the real course (Drive folder)
/// names ignoring capital letters, so "autocad" saves as "AutoCAD".
/// Members not in the sheet are not touched. Emails without an account are
/// listed and skipped.

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a2_members/data/access_sheet.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/generated/l10n.dart';

/// Picks the sheet, shows the preview, saves on "Give access".
Future<void> importAccessSheet(BuildContext context, List<AppUser> members) async {
  final S s = S.of(context);
  void toast(String text) => AppMessenger.of(context)
    ..hide()
    ..show(AppMessage(content: Text(FormatHelper.capitalize(text))));

  final FilePickerResult? picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: <String>['xlsx', 'csv'],
    withData: true,
  );
  final PlatformFile? file = picked?.files.firstOrNull;
  final Uint8List? bytes = file?.bytes;
  if (file == null || bytes == null || !context.mounted) return;

  final AccessSheet sheet = AccessSheet.parse(file.name, bytes);
  if (sheet.unreadable) {
    toast(s.accessImportUnreadable);
    return;
  }
  if (sheet.rows.isEmpty) {
    toast(s.accessImportNothing);
    return;
  }

  // The real course names (Drive folders), to match the sheet's spelling.
  List<String> courses = const <String>[];
  try {
    final List<VideoItem> videos = await VideoRepository().watchAll().first.timeout(const Duration(seconds: 10));
    courses = <String>{
      for (final VideoItem v in videos)
        if (v.category.trim().isNotEmpty) v.category.trim(),
    }.toList();
  } catch (_) {}
  if (!context.mounted) return;

  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (_) => _ImportDialog(fileName: file.name, sheet: sheet, members: members, courses: courses),
  );
  if (saved == true && context.mounted) toast(s.accessImportSaved);
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({
    required this.fileName,
    required this.sheet,
    required this.members,
    required this.courses,
  });

  final String fileName;
  final AccessSheet sheet;
  final List<AppUser> members;
  final List<String> courses;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  bool _replace = false;
  bool _saving = false;
  String? _error;

  late final Map<String, AppUser> _byEmail = <String, AppUser>{
    for (final AppUser u in widget.members) u.email.trim().toLowerCase(): u,
  };

  late final Map<String, String> _courseByKey = <String, String>{
    for (final String c in widget.courses) c.toLowerCase(): c,
  };

  /// The real course name for what the sheet says, or null if none.
  String? _real(String typed) => _courseByKey[typed.trim().toLowerCase()];

  List<AccessSheetRow> get _matched =>
      widget.sheet.rows.where((AccessSheetRow r) => _byEmail.containsKey(r.email)).toList();

  List<String> get _noAccount => <String>[
        for (final AccessSheetRow r in widget.sheet.rows)
          if (!_byEmail.containsKey(r.email)) r.email,
      ];

  Set<String> get _unknownCourses => <String>{
        for (final AccessSheetRow r in _matched)
          for (final String c in r.courses)
            if (!AccessSheet.isAllWord(c) && _real(c) == null) c,
      };

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final CollectionReference<Map<String, dynamic>> users =
          AppFirebase.db.collection(FirebaseCollections.users);
      final List<MapEntry<String, Map<String, dynamic>>> writes = <MapEntry<String, Map<String, dynamic>>>[];
      for (final AccessSheetRow r in _matched) {
        final AppUser member = _byEmail[r.email]!;
        final Map<String, dynamic> data;
        if (r.allCourses) {
          data = <String, dynamic>{
            UserModel.coursesAll: true,
            UserModel.courses: <String>[],
            UserModel.closedCourses: <String>[],
            UserModel.courseAccess: <String, dynamic>{},
          };
        } else {
          final List<String> list = <String>[
            for (final String c in r.courses) _real(c) ?? c,
          ];
          if (!_replace && member.allCourses) continue; // already has every course
          data = <String, dynamic>{
            UserModel.coursesAll: false,
            UserModel.courses: _replace ? list : FieldValue.arrayUnion(list),
          };
        }
        data[FirebaseCollections.updatedAtField] = FieldValue.serverTimestamp();
        writes.add(MapEntry<String, Map<String, dynamic>>(member.uid, data));
      }
      for (int i = 0; i < writes.length; i += 400) {
        final WriteBatch batch = AppFirebase.db.batch();
        for (final MapEntry<String, Map<String, dynamic>> w in writes.skip(i).take(400)) {
          batch.update(users.doc(w.key), w.value);
        }
        await batch.commit();
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final List<AccessSheetRow> matched = _matched;
    final List<String> noAccount = _noAccount;
    final Set<String> unknown = _unknownCourses;

    Widget notice(Color color, String title, String body) => Container(
          margin: EdgeInsets.only(top: 10.h),
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(FormatHelper.capitalize(title),
                  style: StyleText.fontSize13Weight600.copyWith(color: color)),
              SizedBox(height: 4.h),
              Text(body, style: StyleText.fontSize12Weight400.copyWith(color: AppColors.text)),
            ],
          ),
        );

    Widget mode(bool value, String title, String sub) => RadioListTile<bool>(
          value: value,
          groupValue: _replace,
          onChanged: _saving ? null : (bool? v) => setState(() => _replace = v ?? false),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          title: Text(FormatHelper.capitalize(title),
              style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text)),
          subtitle: Text(sub, style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText)),
        );

    return DialogShell(
      title: s.accessImportTitle,
      subtitle: widget.fileName,
      icon: Icons.upload_file_rounded,
      width: 620,
      actions: <Widget>[
        AppButton(
          label: s.cancel,
          kind: AppButtonKind.subtle,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: s.accessImportSave,
          icon: Icons.key_rounded,
          loading: _saving,
          onPressed: matched.isEmpty ? null : _save,
        ),
      ],
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${FormatHelper.capitalize(s.accessImportMatched)}: ${matched.length}',
                style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
              ),
              if (noAccount.isNotEmpty) notice(AppColors.red, s.accessImportNoAccount, noAccount.join('\n')),
              if (unknown.isNotEmpty) notice(AppColors.statusPending, s.accessImportUnknownCourse, unknown.join(', ')),
              if (widget.sheet.problems.isNotEmpty)
                notice(AppColors.secondaryText, s.accessImportSkippedRows, widget.sheet.problems.join('\n')),
              SizedBox(height: 12.h),
              for (final AccessSheetRow r in matched.take(200))
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${FormatHelper.capitalize(_byEmail[r.email]!.displayName)} · ${r.email}',
                        style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                      ),
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: <Widget>[
                          for (final String c in r.courses)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: (AccessSheet.isAllWord(c) || _real(c) != null
                                        ? AppColors.primary
                                        : AppColors.statusPending)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                FormatHelper.capitalize(
                                    AccessSheet.isAllWord(c) ? s.accessAllCourses : (_real(c) ?? c)),
                                style: StyleText.fontSize12Weight600.copyWith(color: AppColors.text),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (matched.length > 200) Text('… +${matched.length - 200}'),
              Divider(height: 24.h),
              mode(false, s.accessImportAdd, s.accessImportAddSub),
              mode(true, s.accessImportReplace, s.accessImportReplaceSub),
              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(_error!, style: StyleText.fontSize12Weight400.copyWith(color: AppColors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
