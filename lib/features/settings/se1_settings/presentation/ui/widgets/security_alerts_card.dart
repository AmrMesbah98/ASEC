/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: security_alerts_card.dart
/// Purpose: Declares `SecurityAlertsCard` — SUPER ADMIN ONLY: every attempt
///          to pull the lessons out of the app (a download tool asking for a
///          stream, an HTTPS sniffer intercepting the app, too many downloads
///          at once, a probe of the local gateway) — who, when, on which
///          device, and what was found. Tap one for the full detail.
/// Author: ASEC team
/// Created: 26/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/security/security_monitor.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class SecurityAlertsCard extends StatefulWidget {
  const SecurityAlertsCard({super.key});

  @override
  State<SecurityAlertsCard> createState() => _SecurityAlertsCardState();
}

class _SecurityAlertsCardState extends State<SecurityAlertsCard> {
  late final Stream<List<SecurityAlert>> _alerts = SecurityMonitor.watch();

  static const int _preview = 6;
  bool _showAll = false;

  void _toast(String text) {
    if (!mounted) return;
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(content: Text(FormatHelper.capitalize(text))));
  }

  /// A short, human label for each kind of alert.
  String _title(S s, SecurityAlert a) {
    switch (a.kind) {
      case 'mitm':
        return s.alertMitm;
      case 'stream_grab':
      case 'stream_abuse':
      case 'gateway_probe':
        return s.alertStreamGrab;
      case 'download_burst':
        return s.alertDownloadBurst;
      default:
        return s.alertOther;
    }
  }

  Future<void> _clearAll() async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.alertClearQuestion,
      subtitle: s.alertClearBody,
      confirmLabel: s.captureClear,
      cancelLabel: s.cancel,
      onConfirm: () async {
        try {
          await SecurityMonitor.clearAll();
        } catch (_) {
          _toast(s.errUnknown);
        }
      },
    );
  }

  Future<void> _open(SecurityAlert a) async {
    final S s = S.of(context);
    await CustomDialogManager.showContent<void>(
      context: context,
      title: _title(s, a),
      subtitle: '${a.userName} · ${AppDates.day(context, a.at)} ${AppDates.time(context, a.at)}',
      icon: Icons.security_rounded,
      iconColor: AppColors.red,
      width: 640,
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await SecurityMonitor.delete(a.id);
            } catch (_) {
              _toast(s.errUnknown);
            }
          },
          child: Text(FormatHelper.capitalize(s.delete), style: TextStyle(color: AppColors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(FormatHelper.capitalize(s.close)),
        ),
      ],
      child: SingleChildScrollView(
        child: SelectableText(
          <String>[
            a.detail,
            '',
            '${a.userName} <${a.email}> (${a.role})',
            '${MemberAccess.platformLabel(a.platform)} · ${a.deviceName}',
            if (a.page.isNotEmpty || a.course.isNotEmpty)
              <String>[a.page, a.course].where((String x) => x.isNotEmpty).join(' › '),
          ].join('\n'),
          style: StyleText.fontSize13Weight400.copyWith(color: AppColors.text, height: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<SecurityAlert>>(
      stream: _alerts,
      builder: (BuildContext context, AsyncSnapshot<List<SecurityAlert>> snap) {
        final List<SecurityAlert> alerts = snap.data ?? const <SecurityAlert>[];
        final List<SecurityAlert> shown =
            _showAll ? alerts : alerts.take(_preview).toList();
        return AppCard(
          title: s.securityAlertsTitle,
          caption: s.securityAlertsCaption,
          actions: <Widget>[
            if (alerts.isNotEmpty)
              TextButton(
                onPressed: _clearAll,
                child: Text(
                  FormatHelper.capitalize(s.captureClear),
                  style: TextStyle(color: AppColors.red),
                ),
              ),
          ],
          child: snap.hasError
              ? SelectableText(
                  '${s.errUnknown}\n${snap.error}',
                  style: StyleText.fontSize13Weight500.copyWith(color: AppColors.red),
                )
              : alerts.isEmpty
                  ? Text(
                      FormatHelper.capitalize(s.securityAlertsNone),
                      style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final SecurityAlert a in shown)
                          _AlertRow(alert: a, title: _title(s, a), onTap: () => _open(a)),
                        if (alerts.length > _preview)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: () => setState(() => _showAll = !_showAll),
                              child: Text(FormatHelper.capitalize(
                                _showAll ? s.captureShowLess : s.captureShowAll(alerts.length),
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

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.title, required this.onTap});

  final SecurityAlert alert;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SecurityAlert a = alert;
    final String device = a.deviceName.isNotEmpty
        ? a.deviceName
        : MemberAccess.platformLabel(a.platform);
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
              child: Icon(Icons.security_rounded, size: 18, color: AppColors.red),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${a.userName} (${a.role}) · $title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${AppDates.day(context, a.at)} · ${AppDates.time(context, a.at)}',
                    style: StyleText.fontSize12Weight600.copyWith(color: AppColors.red),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    a.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${a.email} · $device',
                    maxLines: 1,
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
