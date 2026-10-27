/// Module: admin / a2_members
///
///*************************** FILE INFO ****************************///
/// File Name: online_users_page.dart
/// Purpose: Declares `OnlineUsersPage` (Settings → Online now → View all),
///          `PresenceRow` (one user in it) and `openPresenceUser` — tapping
///          a member opens Members → Edit access for them: every control
///          (courses, devices, period, pause, block).
///          The data comes from `Presence` (lib/core/settings/presence.dart).
/// Author: ASEC team
/// Created: 27/10/2026

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/shared_stream.dart';
import 'package:asec/core/settings/presence.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a2_members/presentation/ui/pages/member_access_page.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/generated/l10n.dart';

/// "3 min ago", "2 h ago", "just now".
String presenceAgo(S s, DateTime at) {
  final Duration d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return s.onlineJustNow;
  if (d.inMinutes < 60) return s.onlineAgoMinutes(d.inMinutes);
  return s.onlineAgoHours(d.inHours);
}

/// Opens every control of the member behind [e] (Members → Edit access).
Future<void> openPresenceUser(BuildContext context, PresenceEntry e) async {
  final S s = S.of(context);
  void toast(String text) => AppMessenger.of(context)
    ..hide()
    ..show(AppMessage(content: Text(FormatHelper.capitalize(text))));

  if (e.isAdmin) {
    toast(s.onlineAdminAccount);
    return;
  }
  AppUser? member;
  try {
    member = await UsersRepository()
        .watchUser(e.uid)
        .first
        .timeout(const Duration(seconds: 10));
  } catch (_) {}
  if (!context.mounted) return;
  if (member == null) {
    toast(s.onlineMemberGone);
    return;
  }
  final AppUser found = member;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => MemberAccessPage(member: found)),
  );
}

class OnlineUsersPage extends StatefulWidget {
  const OnlineUsersPage({super.key});

  @override
  State<OnlineUsersPage> createState() => _OnlineUsersPageState();
}

class _OnlineUsersPageState extends State<OnlineUsersPage> {
  late final Stream<List<PresenceEntry>> _people =
      shared(() => Presence.watchRecent());

  /// "Online" and "x min ago" change with time, not only with data.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          FormatHelper.capitalize(s.onlineTitle),
          style: StyleText.fontSize18Weight600,
        ),
      ),
      body: StreamBuilder<List<PresenceEntry>>(
        stream: _people,
        builder: (BuildContext context, AsyncSnapshot<List<PresenceEntry>> snap) {
          if (snap.hasError) {
            return AppErrorView(
              message: s.errUnknown,
              error: snap.error,
              stackTrace: snap.stackTrace,
            );
          }
          if (!snap.hasData) return const AppLoading();
          final List<PresenceEntry> all = snap.data!;
          final List<PresenceEntry> online =
              all.where((PresenceEntry e) => e.isOnline).toList();
          final List<PresenceEntry> recent =
              all.where((PresenceEntry e) => !e.isOnline).toList();

          return ListView(
            padding: EdgeInsets.all(16.r),
            children: <Widget>[
              AppCard(
                title: '${FormatHelper.capitalize(s.onlineTitle)} (${online.length})',
                caption: s.onlineCaption,
                child: online.isEmpty
                    ? _Empty(text: s.onlineNone)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final PresenceEntry e in online) PresenceRow(entry: e),
                        ],
                      ),
              ),
              SizedBox(height: 16.h),
              AppCard(
                title: '${FormatHelper.capitalize(s.onlineRecent)} (${recent.length})',
                child: recent.isEmpty
                    ? _Empty(text: s.onlineNoneRecent)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final PresenceEntry e in recent) PresenceRow(entry: e),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        FormatHelper.capitalize(text),
        style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
      );
}

/// One user: green dot when online, name, device, where they are / when.
class PresenceRow extends StatelessWidget {
  const PresenceRow({super.key, required this.entry});

  final PresenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final PresenceEntry e = entry;
    final bool on = e.isOnline;
    final Color dot = on ? AppColors.statusApproved : AppColors.secondaryText;
    final String device = e.deviceName.isNotEmpty
        ? e.deviceName
        : MemberAccess.platformLabel(e.platform);
    final String status = on
        ? <String>[
            s.onlineNow,
            if (e.page.isNotEmpty) s.onlineOnPage(e.page),
          ].join('  ·  ')
        : presenceAgo(s, e.lastSeen);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openPresenceUser(context, e),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dot.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          e.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                        ),
                      ),
                      if (e.isAdmin) ...<Widget>[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            FormatHelper.capitalize(s.onlineAdminTag),
                            style: StyleText.fontSize11Weight500.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize12Weight600.copyWith(
                      color: on ? AppColors.statusApproved : AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    <String>[
                      e.email,
                      device,
                      if (e.appVersion.isNotEmpty) 'v${e.appVersion}',
                    ].join('  ·  '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
            if (!e.isAdmin)
              Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
