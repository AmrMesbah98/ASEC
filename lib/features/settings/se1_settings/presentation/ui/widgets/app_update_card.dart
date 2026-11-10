/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: app_update_card.dart
/// Purpose: Declares `AppUpdateCard` — the super admin's control for the
///          Android update dialog. Edits Firestore `settings/app_update`,
///          which `AppUpdate` (lib/core/settings/app_update.dart) reads on
///          every app launch:
///
///            latest_build  builds below → optional "New version" dialog
///            min_build     builds below → forced update (can't be closed)
///            notes_en / notes_ar  "What's new" text
///
///          Build number = the part after `+` in pubspec (1.0.1+9 → 9).
/// Author: ASEC team
/// Created: 20/10/2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class AppUpdateCard extends StatefulWidget {
  const AppUpdateCard({super.key});

  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends State<AppUpdateCard> {
  DocumentReference<Map<String, dynamic>> get _doc =>
      AppFirebase.db.collection('settings').doc('app_update');

  final TextEditingController _latest = TextEditingController();
  final TextEditingController _min = TextEditingController();
  final TextEditingController _notesEn = TextEditingController();
  final TextEditingController _notesAr = TextEditingController();

  /// 10/11/2026 (from ENGX): each platform's own versions, by version name
  /// (1.0.31): below "min" → forced, below "latest" → asked. Saved to
  /// `platforms.{android|ios|macos|windows}.{min|latest}`.
  static const List<(String, String)> _platforms = <(String, String)>[
    ('android', 'Android'),
    ('ios', 'iPhone / iPad'),
    ('macos', 'Mac'),
    ('windows', 'Windows'),
  ];
  final Map<String, TextEditingController> _pMin = <String, TextEditingController>{
    for (final (String key, String _) in _platforms) key: TextEditingController(),
  };
  final Map<String, TextEditingController> _pLatest = <String, TextEditingController>{
    for (final (String key, String _) in _platforms) key: TextEditingController(),
  };

  /// Where "Update now" goes on iPhone / Mac (App Store pages). Empty = the
  /// App Store page the app finds for itself.
  final TextEditingController _iosUrl = TextEditingController();
  final TextEditingController _macUrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  int _savedMin = 0;
  String? _thisApp;
  String _thisVersion = '';
  int _thisBuild = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _latest.dispose();
    _min.dispose();
    _notesEn.dispose();
    _notesAr.dispose();
    for (final TextEditingController c in <TextEditingController>[
      ..._pMin.values,
      ..._pLatest.values,
      _iosUrl,
      _macUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final PackageInfo p = await PackageInfo.fromPlatform();
      _thisApp = '${p.version}+${p.buildNumber}';
      _thisVersion = p.version;
      _thisBuild = int.tryParse(p.buildNumber) ?? 0;
    } catch (_) {}
    try {
      final Map<String, dynamic> d = (await _doc.get()).data() ?? {};
      final int latest = (d['latest_build'] as num?)?.toInt() ?? 0;
      _savedMin = (d['min_build'] as num?)?.toInt() ?? 0;
      _latest.text = latest > 0 ? '$latest' : '';
      _min.text = _savedMin > 0 ? '$_savedMin' : '';
      _notesEn.text = (d['notes_en'] as String?) ?? '';
      _notesAr.text = (d['notes_ar'] as String?) ?? '';
      final Object? p = d['platforms'];
      if (p is Map) {
        for (final (String key, String _) in _platforms) {
          final Object? own = p[key];
          if (own is! Map) continue;
          _pMin[key]!.text = '${own['min'] ?? ''}';
          _pLatest[key]!.text = '${own['latest'] ?? ''}';
        }
      }
      _iosUrl.text = (d['ios_url'] as String?) ?? '';
      _macUrl.text = (d['macos_url'] as String?) ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<bool> _save({bool stopForcing = false, bool quiet = false}) async {
    final S s = S.of(context);
    if (stopForcing) _min.text = '';
    setState(() => _saving = true);
    bool ok = false;
    try {
      final int min = _int(_min);
      await _doc.set(<String, dynamic>{
        'latest_build': _int(_latest),
        'min_build': min,
        'notes_en': _notesEn.text.trim(),
        'notes_ar': _notesAr.text.trim(),
        'platforms': <String, dynamic>{
          for (final (String key, String _) in _platforms)
            key: <String, String>{
              'min': _pMin[key]!.text.trim(),
              'latest': _pLatest[key]!.text.trim(),
            },
        },
        'ios_url': _iosUrl.text.trim(),
        'macos_url': _macUrl.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _savedMin = min;
      if (!quiet) _snack(s.updSaved);
      ok = true;
    } catch (_) {
      _snack(s.errUnknown);
    }
    if (mounted) setState(() => _saving = false);
    return ok;
  }

  /// "Use this version": reads the running app's build, lets the admin
  /// correct it, asks optional or forced, then fills the fields and saves.
  Future<void> _useThisVersion() async {
    final S s = S.of(context);
    final ({int build, bool forced})? choice =
        await showDialog<({int build, bool forced})>(
      context: context,
      builder: (BuildContext ctx) => _UseVersionDialog(
        version: _thisVersion,
        build: _thisBuild,
      ),
    );
    if (choice == null || !mounted) return;
    _latest.text = '${choice.build}';
    if (choice.forced) _min.text = '${choice.build}';
    setState(() {});
    if (!await _save(quiet: true)) return;
    if (mounted) {
      _snack(choice.forced
          ? s.updStatusForced('${choice.build}')
          : s.updOptionalSet('${choice.build}'));
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    AppMessenger.of(context).show(
      AppMessage(content: Text(FormatHelper.capitalize(text))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final List<TextInputFormatter> digits = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
    ];

    return AppCard(
      title: s.updCardTitle,
      caption: s.updCardHint,
      actions: <Widget>[
        AppButton(
          label: s.updUseThisVersion,
          icon: Icons.auto_fix_high_rounded,
          dense: true,
          onPressed: (_loading || _saving) ? null : _useThisVersion,
        ),
      ],
      child: _loading
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 8.h),
                _StatusBanner(forcedBelow: _savedMin, thisApp: _thisApp),
                SizedBox(height: 14.h),
                CustomTextField(
                  controller: _latest,
                  label: s.updLatestBuild,
                  helperText: s.updLatestBuildHint,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: _min,
                  label: s.updMinBuild,
                  helperText: s.updMinBuildHint,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: _notesEn,
                  label: s.updNotesEn,
                  maxLines: 4,
                  minLines: 2,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: _notesAr,
                  label: s.updNotesAr,
                  maxLines: 4,
                  minLines: 2,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 18.h),
                // ── Each platform on its own (10/11/2026) ──
                Text(
                  FormatHelper.capitalize('Per platform (version name, e.g. 1.0.31)'),
                  style: StyleText.fontSize14Weight600,
                ),
                SizedBox(height: 4.h),
                Text(
                  FormatHelper.capitalize(
                      'Below "Min" the update is required; below "Latest" the user is asked. '
                      'Empty = not used. iPhone and Mac also check the App Store by themselves.'),
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText, height: 1.5),
                ),
                SizedBox(height: 10.h),
                for (final (String key, String label) in _platforms) ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      SizedBox(
                        width: 110.w,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: Text(FormatHelper.capitalize(label), style: StyleText.fontSize13Weight600),
                        ),
                      ),
                      Expanded(
                        child: CustomTextField(
                          controller: _pMin[key]!,
                          label: 'Min',
                          hint: '1.0.0',
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _pLatest[key]!,
                          label: 'Latest',
                          hint: '1.0.0',
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                ],
                CustomTextField(
                  controller: _iosUrl,
                  label: 'App Store link (iPhone / iPad)',
                  hint: 'https://apps.apple.com/app/id…',
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  controller: _macUrl,
                  label: 'App Store link (Mac)',
                  hint: 'https://apps.apple.com/app/id…',
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: 10.h),
                Text(
                  FormatHelper.capitalize(s.updWarning),
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText, height: 1.5),
                ),
                SizedBox(height: 14.h),
                AppButton(
                  label: s.save,
                  icon: Icons.save_rounded,
                  expand: true,
                  loading: _saving,
                  onPressed: _saving ? null : () => _save(),
                ),
                if (_savedMin > 0) ...<Widget>[
                  SizedBox(height: 8.h),
                  AppButton(
                    label: s.updStopForcing,
                    icon: Icons.lock_open_rounded,
                    kind: AppButtonKind.subtle,
                    expand: true,
                    onPressed: _saving ? null : () => _save(stopForcing: true),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.forcedBelow, required this.thisApp});

  final int forcedBelow;
  final String? thisApp;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool forced = forcedBelow > 0;
    final Color tone = forced ? AppColors.statusPending : AppColors.statusApproved;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: <Widget>[
          AppIcon(
            forced ? Icons.lock_rounded : Icons.check_circle_rounded,
            size: 20.r,
            color: tone,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize(forced
                      ? s.updStatusForced('$forcedBelow')
                      : s.updStatusOff),
                  style: StyleText.fontSize14Weight600,
                ),
                if (thisApp != null)
                  Text(
                    FormatHelper.capitalize(s.updThisApp(thisApp!)),
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the running app's version, lets the admin fix the build number,
/// and returns it with "optional" or "forced". Null = cancelled.
class _UseVersionDialog extends StatefulWidget {
  const _UseVersionDialog({required this.version, required this.build});

  final String version;
  final int build;

  @override
  State<_UseVersionDialog> createState() => _UseVersionDialogState();
}

class _UseVersionDialogState extends State<_UseVersionDialog> {
  late final TextEditingController _build =
      TextEditingController(text: widget.build > 0 ? '${widget.build}' : '');

  @override
  void dispose() {
    _build.dispose();
    super.dispose();
  }

  void _done(bool forced) {
    final int? b = int.tryParse(_build.text.trim());
    if (b == null || b <= 0) {
      AppMessenger.of(context).show(
        AppMessage(content: Text(FormatHelper.capitalize(S.of(context).updEnterBuild))),
      );
      return;
    }
    Navigator.pop(context, (build: b, forced: forced));
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(FormatHelper.capitalize(s.updUseThisVersion),
          style: StyleText.fontSize18Weight600),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              FormatHelper.capitalize(
                  s.updThisApp('${widget.version}+${widget.build}')),
              style: StyleText.fontSize14Weight600,
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: _build,
              label: s.updBuildToUse,
              helperText: s.updBuildToUseHint,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              FormatHelper.capitalize(s.updForceQuestion),
              style: StyleText.fontSize14Weight600,
            ),
            SizedBox(height: 6.h),
            Text(
              FormatHelper.capitalize(s.updWarning),
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText, height: 1.5),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(FormatHelper.capitalize(s.cancel)),
        ),
        TextButton(
          onPressed: () => _done(false),
          child: Text(FormatHelper.capitalize(s.updOptional)),
        ),
        TextButton(
          onPressed: () => _done(true),
          child: Text(
            FormatHelper.capitalize(s.updForced),
            style: TextStyle(color: AppColors.red),
          ),
        ),
      ],
    );
  }
}
