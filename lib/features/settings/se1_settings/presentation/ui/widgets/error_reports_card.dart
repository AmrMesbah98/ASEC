/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: error_reports_card.dart
/// Purpose: Declares `ErrorReportsCard` — SUPER ADMIN ONLY: every error any
///          user hit (newest first) — who, when, on which device and app
///          version, on which page, and the error itself. Tap one for the
///          full details and stack trace, with Copy and Delete.
/// Author: ASEC team
/// Created: 26/10/2026

import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/settings/device_specs.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/settings/error_reports.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/network/shared_stream.dart';

class ErrorReportsCard extends StatefulWidget {
  const ErrorReportsCard({super.key});

  @override
  State<ErrorReportsCard> createState() => _ErrorReportsCardState();
}

class _ErrorReportsCardState extends State<ErrorReportsCard> {
  late final Stream<List<ErrorReport>> _reports = shared(() => ErrorReports.watch());

  /// Rows shown before "Show all".
  static const int _preview = 6;
  bool _showAll = false;

  void _toast(String text) {
    if (!mounted) return;
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(content: Text(FormatHelper.capitalize(text))));
  }

  bool _exporting = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  /// Export all (06/11/2026, from ENGX): every report, with a summary on top,
  /// as ONE text file (saved where the super admin picks) and on the
  /// clipboard — ready to send to the developer in one go.
  Future<void> _exportAll() async {
    setState(() => _exporting = true);
    try {
      final List<ErrorReport> all = await ErrorReports.watch(limit: 100000).first;
      final String text = _exportText(all);
      await Clipboard.setData(ClipboardData(text: text));
      final DateTime n = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final String name = 'ASEC-error-reports-${n.year}-${two(n.month)}-${two(n.day)}_${two(n.hour)}${two(n.minute)}.txt';
      String? saved;
      if (!kIsWeb) {
        try {
          saved = await FilePicker.platform.saveFile(
            dialogTitle: _ar ? 'حفظ تقارير الأخطاء' : 'Save the error reports',
            fileName: name,
            type: FileType.custom,
            allowedExtensions: <String>['txt'],
            bytes: Uint8List.fromList(utf8.encode(text)),
          );
          // Desktop: file_picker only picks the path — write it.
          if (saved != null &&
              !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
            await File(saved).writeAsString(text);
          }
        } catch (_) {}
      }
      _toast(saved == null
          ? (_ar ? 'تم نسخ ${all.length} تقرير — الصقها في رسالتك.' : '${all.length} reports copied — paste them in your message.')
          : (_ar ? 'تم حفظ ونسخ ${all.length} تقرير.' : '${all.length} reports saved and copied — send the file or paste them.'));
    } catch (_) {
      _toast(S.of(context).errUnknown);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Summary (by kind, version, platform, device rating) + every report.
  static String _exportText(List<ErrorReport> all) {
    Map<String, int> count(String Function(ErrorReport) key) {
      final Map<String, int> m = <String, int>{};
      for (final ErrorReport r in all) {
        final String k = key(r).trim().isEmpty ? '(none)' : key(r).trim();
        m[k] = (m[k] ?? 0) + 1;
      }
      final List<MapEntry<String, int>> e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return Map<String, int>.fromEntries(e);
    }

    String block(String title, Map<String, int> m) =>
        '$title\n${m.entries.map((MapEntry<String, int> e) => '  ${e.value.toString().padLeft(4)}  ${e.key}').join('\n')}';

    final StringBuffer b = StringBuffer()
      ..writeln('ASEC — error reports export (${DateTime.now()})')
      ..writeln('${all.length} reports')
      ..writeln()
      ..writeln(block('By source:', count((ErrorReport r) => r.source)))
      ..writeln()
      ..writeln(block('By app version:', count((ErrorReport r) => r.appVersion)))
      ..writeln()
      ..writeln(block('By platform:', count((ErrorReport r) => r.platform)))
      ..writeln()
      ..writeln(block('By PC:', count((ErrorReport r) => PcRating.of(r.specs).label)))
      ..writeln()
      ..writeln(block('Most common (first line):', count((ErrorReport r) {
        final String first = r.message.split('\n').first;
        return first
            .replaceAll(RegExp(r'\d{4}-\d\d-\d\d[ T][\d:.]+'), '<time>')
            .replaceAll(RegExp(r'\d+(\.\d+)?'), '#');
      })))
      ..writeln()
      ..writeln('=' * 72);
    int i = 0;
    for (final ErrorReport r in all) {
      i++;
      b
        ..writeln()
        ..writeln('#$i')
        ..writeln(r.fullText)
        ..writeln('-' * 72);
    }
    return b.toString();
  }

  Future<void> _clearAll() async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.errorReportsClearQuestion,
      subtitle: s.errorReportsClearBody,
      confirmLabel: s.captureClear,
      cancelLabel: s.cancel,
      onConfirm: () async {
        try {
          await ErrorReports.clearAll();
        } catch (_) {
          _toast(s.errUnknown);
        }
      },
    );
  }

  Future<void> _open(ErrorReport r) async {
    final S s = S.of(context);
    await CustomDialogManager.showContent<void>(
      context: context,
      title: '${r.errorType}${r.code.isEmpty ? '' : ' · ${r.code}'}',
      subtitle: '${r.userName} · ${AppDates.day(context, r.at)} ${AppDates.time(context, r.at)}',
      icon: Icons.bug_report_rounded,
      iconColor: AppColors.red,
      width: 720,
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await ErrorReports.delete(r.id);
            } catch (_) {
              _toast(s.errUnknown);
            }
          },
          child: Text(FormatHelper.capitalize(s.delete), style: TextStyle(color: AppColors.red)),
        ),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: r.fullText));
            _toast(s.errorReportsCopied);
          },
          child: Text(FormatHelper.capitalize(s.errorReportsCopy)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(FormatHelper.capitalize(s.close)),
        ),
      ],
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.6.sh),
        child: SingleChildScrollView(
          child: SelectableText(
            r.fullText,
            style: StyleText.fontSize12Weight400.copyWith(
              color: AppColors.text,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<ErrorReport>>(
      stream: _reports,
      builder: (BuildContext context, AsyncSnapshot<List<ErrorReport>> snap) {
        final List<ErrorReport> reports = snap.data ?? const <ErrorReport>[];
        final List<ErrorReport> shown =
            _showAll ? reports : reports.take(_preview).toList();
        return AppCard(
          title: s.errorReportsTitle,
          caption: s.errorReportsCaption,
          actions: <Widget>[
            if (reports.isNotEmpty)
              TextButton.icon(
                onPressed: _exporting ? null : _exportAll,
                icon: Icon(Icons.ios_share_rounded, size: 18, color: AppColors.primary),
                label: Text(
                  _exporting ? (_ar ? 'جارٍ التصدير…' : 'Exporting…') : (_ar ? 'تصدير الكل' : 'Export all'),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            if (reports.isNotEmpty)
              TextButton(
                onPressed: _clearAll,
                child: Text(
                  FormatHelper.capitalize(s.captureClear),
                  style: TextStyle(color: AppColors.red),
                ),
              ),
          ],
          child: snap.hasError
              // Most likely the rules are not deployed yet — show why.
              ? SelectableText(
                  '${s.errUnknown}\n${snap.error}',
                  style: StyleText.fontSize13Weight500.copyWith(color: AppColors.red),
                )
              : reports.isEmpty
                  ? Text(
                      FormatHelper.capitalize(s.errorReportsNone),
                      style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final ErrorReport r in shown)
                          _ReportRow(report: r, onTap: () => _open(r)),
                        if (reports.length > _preview)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: () => setState(() => _showAll = !_showAll),
                              child: Text(FormatHelper.capitalize(
                                _showAll ? s.captureShowLess : s.captureShowAll(reports.length),
                              )),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onTap});

  final ErrorReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ErrorReport r = report;
    final String device = r.deviceName.isNotEmpty
        ? r.deviceName
        : MemberAccess.platformLabel(r.platform);
    final String where = <String>[r.page, r.course, r.detail]
        .where((String x) => x.isNotEmpty)
        .join(' › ');
    final String firstLine = r.message.split('\n').firstWhere(
          (String l) => l.trim().isNotEmpty,
          orElse: () => r.message,
        );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.bug_report_rounded, size: 18, color: AppColors.red),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${r.userName} (${r.role}) · ${r.errorType}${r.code.isEmpty ? '' : ' · ${r.code}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${AppDates.day(context, r.at)} · ${AppDates.time(context, r.at)}',
                    style: StyleText.fontSize12Weight600.copyWith(color: AppColors.red),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    firstLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    <String>[
                      if (where.isNotEmpty) where,
                      r.email,
                      device,
                      if (r.appVersion.isNotEmpty) 'v${r.appVersion}',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                  ),
                  // LOW / OK / GOOD device (DeviceSpecs) — which PCs may have trouble.
                  if (PcRating.of(r.specs).isKnown)
                    Text(
                      PcRating.of(r.specs).text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize12Weight600.copyWith(color: pcRatingColor(PcRating.of(r.specs).level)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
