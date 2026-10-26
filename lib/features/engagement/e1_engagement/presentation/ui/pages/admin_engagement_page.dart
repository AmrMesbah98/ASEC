/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: admin_engagement_page.dart
/// Purpose: Declares `AdminEngagementPage` — the admin's tools for reaching
///          members: send notifications (the bell), write tips & tricks (the
///          home-page pop-up, with how many members saved each), the member
///          Library's files, and every member's stars.
/// Author: ASEC team
/// Created: 15/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/10-custom_tabs.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/58-default_switch_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/pages/library_pages.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/course_files_view.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/member_bar_actions.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/partners_orbit.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class AdminEngagementPage extends StatefulWidget {
  const AdminEngagementPage({super.key});

  @override
  State<AdminEngagementPage> createState() => _AdminEngagementPageState();
}

class _AdminEngagementPageState extends State<AdminEngagementPage> {
  final EngagementRepository _repository = EngagementRepository();
  late final Stream<List<AppNotice>> _notices = _repository.watchNotices();
  late final Stream<List<AppTip>> _tips = _repository.watchTips();

  int _tab = 0;

  /// The tabs this admin may open — one sub-permission each (Engagement →
  /// Notifications / Tips / Library / Stars / Partners).
  List<_EngTab> get _visible => <_EngTab>[
        for (final _EngTab t in _EngTab.values)
          if (SessionController.to.current.canDo(t.action)) t,
      ];

  Future<void> _sendNotice() async {
    final S s = S.of(context);
    final ({String title, String body})? r = await showComposeDialog(
      context: context,
      dialogTitle: s.engSendNotification,
      titleHint: s.engNotifTitleHint,
      bodyHint: s.engNotifBodyHint,
      submitLabel: s.engSend,
      icon: Icons.campaign_rounded,
    );
    if (r == null) return;
    try {
      await _repository.sendNotice(title: r.title, body: r.body);
      if (mounted) showEngagementToast(context, s.engNotifSent);
    } catch (e) {
      if (mounted) showEngagementToast(context, engErrorText(context, e));
    }
  }

  Future<void> _addTip() async {
    final S s = S.of(context);
    final ({String title, String body})? r = await showComposeDialog(
      context: context,
      dialogTitle: s.engAddTip,
      titleHint: s.engTipTitleHint,
      bodyHint: s.engTipBodyHint,
      submitLabel: s.add,
      icon: Icons.lightbulb_rounded,
    );
    if (r == null) return;
    try {
      await _repository.addTip(title: r.title, body: r.body);
      if (mounted) showEngagementToast(context, s.engTipAdded);
    } catch (e) {
      if (mounted) showEngagementToast(context, engErrorText(context, e));
    }
  }

  /// Folder first: which Library folder (or a new one), then the file.
  Future<void> _uploadLibrary() =>
      uploadIntoFolder(context, EngagementRepository.libraryCourse);

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final List<_EngTab> visible = _visible;
    if (visible.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ConsolePage(
          title: s.engEngagement,
          subtitle: s.engEngagementSub,
          child: AppEmptyView(title: s.noPermissions),
        ),
      );
    }
    if (_tab >= visible.length) _tab = 0;
    final _EngTab current = visible[_tab];

    final List<String> tabs = <String>[
      for (final _EngTab t in visible)
        (switch (t) {
          _EngTab.notifications => s.engNotifications,
          _EngTab.tips => s.engTipsTricks,
          _EngTab.library => s.engLibrary,
          _EngTab.stars => s.engStarsTab,
          // The website's partners — the same list the home page's ring shows.
          _EngTab.partners => s.engPartners,
        }),
    ];

    final Widget action = switch (current) {
      _EngTab.notifications => AppButton(
          label: s.engSendNotification,
          icon: Icons.send_rounded,
          dense: true,
          onPressed: _sendNotice,
        ),
      _EngTab.tips => AppButton(
          label: s.engAddTip,
          icon: Icons.add_rounded,
          dense: true,
          onPressed: _addTip,
        ),
      _EngTab.partners => AppButton(
          label: s.engPartnerAdd,
          icon: Icons.add_business_rounded,
          dense: true,
          onPressed: () => PartnersAdminTab.add(context),
        ),
      _EngTab.library => AppButton(
          label: s.uploadFile,
          icon: Icons.upload_file_rounded,
          dense: true,
          onPressed: _uploadLibrary,
        ),
      _EngTab.stars => const SizedBox.shrink(),
    };

    final String caption = switch (current) {
      _EngTab.notifications => s.engNotifAdminSub,
      _EngTab.tips => s.engTipsAdminSub,
      _EngTab.library => s.engLibraryAdminSub,
      _EngTab.stars => s.engStarsAdminSub,
      _EngTab.partners => s.engPartnersAdminSub,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ConsolePage(
        title: s.engEngagement,
        subtitle: s.engEngagementSub,
        actions: <Widget>[if (current != _EngTab.stars) action],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CustomTabs(
              tabs: tabs,
              selectedValue: _tab,
              spacing: 24.w,
              textStyle: StyleText.fontSize16Weight500
                  .copyWith(color: AppColors.secondaryText),
              onChanged: (int v) => setState(() => _tab = v),
            ),
            SizedBox(height: 10.h),
            Text(
              FormatHelper.capitalize(caption),
              style: StyleText.fontSize13Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: <Widget>[
                  for (final _EngTab t in visible)
                    (switch (t) {
                      _EngTab.notifications => _noticesTab(s),
                      _EngTab.tips => _tipsTab(s),
                      _EngTab.library => _libraryTab(s),
                      _EngTab.stars =>
                        const LeaderboardPage(admin: true, framed: false),
                      _EngTab.partners => const PartnersAdminTab(),
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list<T>(
    Stream<List<T>> stream,
    String emptyTitle,
    Widget Function(T item) tile,
  ) {
    final S s = S.of(context);
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<List<T>> snap) {
        if (snap.hasError) {
          return AppErrorView(message: engErrorText(context, snap.error), error: snap.error, stackTrace: snap.stackTrace);
        }
        if (!snap.hasData) return const AppLoading();
        final List<T> list = snap.data!;
        if (list.isEmpty) return AppEmptyView(title: emptyTitle);
        return ListView.separated(
          padding: EdgeInsets.only(bottom: 24.h),
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (BuildContext context, int i) => FadeSlideIn(
            delay: staggerDelay(i, stepMs: 30),
            child: tile(list[i]),
          ),
        );
      },
    );
  }

  Widget _noticesTab(S s) => _list<AppNotice>(
        _notices,
        s.engNotificationsEmpty,
        (AppNotice n) => NoticeCard(
          notice: n,
          trailing: DeleteMenu(
            onDelete: () => confirmDelete(
              context,
              name: n.title,
              action: () => _repository.deleteNotice(n.id),
            ),
          ),
        ),
      );

  Widget _tipsTab(S s) => _list<AppTip>(
        _tips,
        s.engTipsEmpty,
        (AppTip t) => TipCard(
          tip: t,
          footer: Wrap(
            spacing: 14.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // How many members saved it — the admin's count.
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppIcon(Icons.bookmark_rounded,
                        size: 15.sp, color: AppColors.primary),
                    SizedBox(width: 4.w),
                    Text(
                      FormatHelper.capitalize(s.engTipSavedCount(t.saveCount)),
                      style: StyleText.fontSize12Weight600
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    FormatHelper.capitalize(s.engTipActive),
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: AppColors.secondaryText),
                  ),
                  SizedBox(width: 6.w),
                  DefaultSwitchButton(
                    value: t.active,
                    onChanged: (bool v) => _repository.setTipActive(t.id, v),
                  ),
                ],
              ),
            ],
          ),
          trailing: DeleteMenu(
            onDelete: () => confirmDelete(
              context,
              name: t.title,
              action: () => _repository.deleteTip(t.id),
            ),
          ),
        ),
      );

  Widget _libraryTab(S s) => SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 24.h),
        child: const LibraryView(admin: true),
      );
}

enum _EngTab {
  notifications(AdminAction.engagementNotifications),
  tips(AdminAction.engagementTips),
  library(AdminAction.engagementLibrary),
  stars(AdminAction.engagementStars),
  partners(AdminAction.engagementPartners);

  const _EngTab(this.action);

  final AdminAction action;
}
