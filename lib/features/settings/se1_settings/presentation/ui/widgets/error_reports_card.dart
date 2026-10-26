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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

class ErrorReportsCard extends StatefulWidget {
  const ErrorReportsCard({super.key});

  @override
  State<ErrorReportsCard> createState() => _ErrorReportsCardState();
}

class _ErrorReportsCardState extends State<ErrorReportsCard> {
  late final Stream<List<ErrorReport>> _reports = ErrorReports.watch();

  /// Rows shown before "Show all".
  static const int _preview = 6;
  bool _showAll = false;

  void _toast(String text) {
    if (!mounted) return;
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(content: Text(FormatHelper.capitalize(text))));
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
