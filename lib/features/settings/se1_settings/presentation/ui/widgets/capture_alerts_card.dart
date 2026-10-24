/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: capture_alerts_card.dart
/// Purpose: Declares `CaptureAlertsCard` — for admins with the Members
///          permission: every screenshot or screen recording a member took
///          inside the app (newest first), who, when and on which device.
///          Detected on iPhone / iPad and Android 14+ (recording: Android
///          15+); Mac and Windows cannot report them.
/// Author: ASEC team
/// Created: 20/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a2_members/data/device_security.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class CaptureAlertsCard extends StatefulWidget {
  const CaptureAlertsCard({super.key});

  @override
  State<CaptureAlertsCard> createState() => _CaptureAlertsCardState();
}

class _CaptureAlertsCardState extends State<CaptureAlertsCard> {
  late final Stream<List<CaptureEvent>> _events = CaptureEvents.watch();

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
      title: s.captureClearQuestion,
      subtitle: s.captureClearBody,
      confirmLabel: s.captureClear,
      cancelLabel: s.cancel,
      onConfirm: () async {
        try {
          await CaptureEvents.clearAll();
        } catch (_) {
          _toast(s.errUnknown);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<CaptureEvent>>(
      stream: _events,
      builder: (BuildContext context, AsyncSnapshot<List<CaptureEvent>> snap) {
        final List<CaptureEvent> events = snap.data ?? const <CaptureEvent>[];
        final List<CaptureEvent> shown =
            _showAll ? events : events.take(_preview).toList();
        return AppCard(
          title: s.captureAlertsTitle,
          caption: s.captureAlertsCaption,
          actions: <Widget>[
            if (events.isNotEmpty)
              TextButton(
                onPressed: _clearAll,
                child: Text(
                  FormatHelper.capitalize(s.captureClear),
                  style: TextStyle(color: AppColors.red),
                ),
              ),
          ],
          child: snap.hasError
              ? Text(
                  FormatHelper.capitalize(s.errUnknown),
                  style: StyleText.fontSize13Weight500.copyWith(color: AppColors.red),
                )
              : events.isEmpty
                  ? Text(
                      FormatHelper.capitalize(s.captureNone),
                      style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final CaptureEvent e in shown) _EventRow(event: e),
                        if (events.length > _preview)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: () => setState(() => _showAll = !_showAll),
                              child: Text(FormatHelper.capitalize(
                                _showAll ? s.captureShowLess : s.captureShowAll(events.length),
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

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final CaptureEvent event;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Color accent = event.isRecording ? AppColors.red : AppColors.statusPending;
    final String device = event.deviceName.isNotEmpty
        ? event.deviceName
        : MemberAccess.platformLabel(event.platform);
    final List<String> where = <String>[
      if (event.page.isNotEmpty) '${s.capturePage}: ${event.page}',
      if (event.course.isNotEmpty) '${s.captureCourse}: ${event.course}',
      if (event.detail.isNotEmpty) '${s.captureLesson}: ${event.detail}',
    ];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              event.isRecording ? Icons.videocam_rounded : Icons.screenshot_rounded,
              size: 18,
              color: accent,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize(
                    '${event.memberName} · ${event.isRecording ? s.captureRecording : s.captureScreenshot}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                ),
                SizedBox(height: 3.h),
                // When — date and time.
                Text(
                  '${AppDates.day(context, event.at)} · ${AppDates.time(context, event.at)}',
                  style: StyleText.fontSize12Weight600.copyWith(color: accent),
                ),
                // Where — page, course, lesson / quiz.
                if (where.isNotEmpty) ...<Widget>[
                  SizedBox(height: 2.h),
                  Text(
                    where.join('  ·  '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
                  ),
                ],
                SizedBox(height: 2.h),
                Text(
                  '${event.email} · $device',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
