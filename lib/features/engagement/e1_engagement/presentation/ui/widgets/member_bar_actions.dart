/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: member_bar_actions.dart
/// Purpose: Declares `MemberBarActions` — what a member sees in the app bar
///          beside the avatar: the bell (notifications from the admin, with
///          the number not read yet) and, once they saved a tip, the
///          bookmark that opens their saved tips. Also the two pages they
///          open: `NotificationsPage` and `SavedTipsPage`.
/// Author: ASEC team
/// Created: 15/10/2026
///
/// "READ" IS PER DEVICE: opening the list stores the time on the device, and
/// everything sent after it counts as new. No write per member per notice.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// When this member last opened the notifications, on this device.
abstract final class NoticeSeen {
  const NoticeSeen._();

  static final GetStorage _box = GetStorage();
  static final ValueNotifier<int> changed = ValueNotifier<int>(0);

  static String _key(String uid) => 'notices_seen_$uid';

  static DateTime at(String uid) => DateTime.fromMillisecondsSinceEpoch(
        _box.read<int>(_key(uid)) ?? 0,
      );

  static void markAll(String uid) {
    _box.write(_key(uid), DateTime.now().millisecondsSinceEpoch);
    changed.value++;
  }

  static int unread(String uid, List<AppNotice> notices) {
    final DateTime seen = at(uid);
    return notices
        .where((AppNotice n) => (n.createdAt ?? DateTime.now()).isAfter(seen))
        .length;
  }
}

class MemberBarActions extends StatefulWidget {
  const MemberBarActions({super.key, required this.user});

  final AppUser user;

  @override
  State<MemberBarActions> createState() => _MemberBarActionsState();
}

class _MemberBarActionsState extends State<MemberBarActions> {
  final EngagementRepository _repository = EngagementRepository();
  late Stream<List<AppNotice>> _notices = _repository.watchNotices();
  late Stream<List<AppTip>> _saved = _repository.watchSavedTips(widget.user.uid);

  @override
  void didUpdateWidget(covariant MemberBarActions old) {
    super.didUpdateWidget(old);
    if (old.user.uid != widget.user.uid) {
      _notices = _repository.watchNotices();
      _saved = _repository.watchSavedTips(widget.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final String uid = widget.user.uid;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Saved tips — only once there is something saved.
        StreamBuilder<List<AppTip>>(
          stream: _saved,
          builder: (BuildContext context, AsyncSnapshot<List<AppTip>> snap) {
            if ((snap.data ?? const <AppTip>[]).isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: s.engSavedTips,
              onPressed: () => PushedSectionPage.open(
                context,
                SavedTipsPage(user: widget.user),
              ),
              icon: AppIcon(Icons.bookmark_rounded,
                  size: 22.sp, color: AppColors.primary),
            );
          },
        ),
        StreamBuilder<List<AppNotice>>(
          stream: _notices,
          builder: (BuildContext context, AsyncSnapshot<List<AppNotice>> snap) {
            final List<AppNotice> list = snap.data ?? const <AppNotice>[];
            return ValueListenableBuilder<int>(
              valueListenable: NoticeSeen.changed,
              builder: (BuildContext context, int _, Widget? __) {
                final int unread = NoticeSeen.unread(uid, list);
                return IconButton(
                  tooltip: s.engNotifications,
                  onPressed: () => PushedSectionPage.open(
                    context,
                    NotificationsPage(user: widget.user),
                  ),
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    backgroundColor: AppColors.red,
                    label: Text(
                      FormatHelper.capitalize(unread > 99 ? '99+' : '$unread'),
                      style: StyleText.fontSize10Weight700
                          .copyWith(color: Colors.white),
                    ),
                    child: AppIcon(
                      unread > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 23.sp,
                      color: AppColors.text,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ── Notifications page ──────────────────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.user});

  final AppUser user;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final EngagementRepository _repository = EngagementRepository();
  late final Stream<List<AppNotice>> _notices = _repository.watchNotices();

  /// What was "new" when the page opened stays highlighted while it is open.
  late final DateTime _seenBefore;

  @override
  void initState() {
    super.initState();
    _seenBefore = NoticeSeen.at(widget.user.uid);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NoticeSeen.markAll(widget.user.uid),
    );
  }

  @override
  void dispose() {
    // Anything that arrived while the page was open has been seen too.
    // After this frame: the bell must not rebuild while the tree is locked.
    final String uid = widget.user.uid;
    Future<void>.microtask(() => NoticeSeen.markAll(uid));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return ConsolePage(
      title: s.engNotifications,
      subtitle: s.engNotificationsSub,
      child: StreamBuilder<List<AppNotice>>(
        stream: _notices,
        builder: (BuildContext context, AsyncSnapshot<List<AppNotice>> snap) {
          if (snap.hasError) {
            return AppErrorView(message: engErrorText(context, snap.error), error: snap.error, stackTrace: snap.stackTrace);
          }
          if (!snap.hasData) return const AppLoading();
          final List<AppNotice> list = snap.data!;
          if (list.isEmpty) {
            return AppEmptyView(
              title: s.engNotificationsEmpty,
              subtitle: s.engNotificationsEmptySub,
            );
          }
          return ListView.separated(
            padding: EdgeInsets.only(bottom: 24.h),
            itemCount: list.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (BuildContext context, int i) => FadeSlideIn(
              delay: staggerDelay(i, stepMs: 40),
              child: NoticeCard(
                notice: list[i],
                fresh: (list[i].createdAt ?? DateTime.now()).isAfter(_seenBefore),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.notice,
    this.fresh = false,
    this.trailing,
  });

  final AppNotice notice;
  final bool fresh;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: fresh ? AppColors.primary.withOpacity(0.07) : AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: AppIcon(Icons.campaign_rounded,
                size: 20.sp, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        FormatHelper.capitalize(notice.title),
                        style: StyleText.fontSize15Weight600
                            .copyWith(color: AppColors.text),
                      ),
                    ),
                    if (fresh)
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (notice.body.isNotEmpty) ...<Widget>[
                  SizedBox(height: 4.h),
                  Text(
                    FormatHelper.capitalize(notice.body),
                    style: StyleText.fontSize14Weight400
                        .copyWith(color: AppColors.text, height: 1.45),
                  ),
                ],
                SizedBox(height: 6.h),
                Text(
                  FormatHelper.capitalize(videoTimeAgo(context, notice.createdAt)),
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Saved tips page ─────────────────────────────────────────────────────────

class SavedTipsPage extends StatefulWidget {
  const SavedTipsPage({super.key, required this.user});

  final AppUser user;

  @override
  State<SavedTipsPage> createState() => _SavedTipsPageState();
}

class _SavedTipsPageState extends State<SavedTipsPage> {
  final EngagementRepository _repository = EngagementRepository();
  late final Stream<List<AppTip>> _saved =
      _repository.watchSavedTips(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return ConsolePage(
      title: s.engSavedTips,
      subtitle: s.engSavedTipsSub,
      child: StreamBuilder<List<AppTip>>(
        stream: _saved,
        builder: (BuildContext context, AsyncSnapshot<List<AppTip>> snap) {
          if (snap.hasError) {
            return AppErrorView(message: engErrorText(context, snap.error), error: snap.error, stackTrace: snap.stackTrace);
          }
          if (!snap.hasData) return const AppLoading();
          final List<AppTip> list = snap.data!;
          if (list.isEmpty) {
            return AppEmptyView(title: s.engSavedTipsEmpty);
          }
          return ListView.separated(
            padding: EdgeInsets.only(bottom: 24.h),
            itemCount: list.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (BuildContext context, int i) => FadeSlideIn(
              delay: staggerDelay(i, stepMs: 40),
              child: TipCard(
                tip: list[i],
                trailing: IconButton(
                  tooltip: s.engTipUnsave,
                  onPressed: () =>
                      _repository.unsaveTip(list[i].id, widget.user.uid),
                  icon: AppIcon(Icons.bookmark_remove_rounded,
                      size: 20.sp, color: AppColors.secondaryText),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip, this.trailing, this.footer});

  final AppTip tip;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: const Color(0xFFF5B301).withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: AppIcon(Icons.lightbulb_rounded,
                size: 20.sp, color: const Color(0xFFF5B301)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize(tip.title),
                  style: StyleText.fontSize15Weight600
                      .copyWith(color: AppColors.text),
                ),
                if (tip.body.isNotEmpty) ...<Widget>[
                  SizedBox(height: 4.h),
                  Text(
                    FormatHelper.capitalize(tip.body),
                    style: StyleText.fontSize14Weight400
                        .copyWith(color: AppColors.text, height: 1.45),
                  ),
                ],
                if (footer != null) ...<Widget>[
                  SizedBox(height: 8.h),
                  footer!,
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
