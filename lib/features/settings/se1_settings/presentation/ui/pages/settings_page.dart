/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: settings_page.dart
/// Purpose: Declares `SettingsPage` — appearance, language, haptics, the
///          account, the member's "My space" (My CV, certificate quiz,
///          downloads, engineering calculators), the way out, and deleting
///          the account for good.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/custom/112-powered_by_footer.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/61-custom_color_picker.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/haptic_controller.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/admin/a5_demo/presentation/ui/widgets/demo_data_card.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/auth_failure_type.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/widgets/admins_card.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/widgets/control_centre_card.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/widgets/app_update_card.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/widgets/capture_alerts_card.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/widgets/online_users_card.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/widgets/error_reports_card.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/widgets/security_alerts_card.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.user});

  final AppUser user;

  Future<void> _confirmSignOut(BuildContext context) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.signOutQuestion,
      subtitle: s.signOutBody,
      confirmLabel: s.signOut,
      cancelLabel: s.cancel,
      onConfirm: () => AppRouter.signOut(context),
    );
  }

  /// Confirm → password → delete → sign-in screen.
  ///
  /// The password prompt is not ceremony: Firebase only deletes an account
  /// whose sign-in is recent, so re-authenticating here is what makes the
  /// delete work on every platform without a "sign in again" detour.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final S s = S.of(context);

    bool confirmed = false;
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.deleteAccountQuestion,
      subtitle: s.deleteAccountBody,
      confirmLabel: s.deleteAccount,
      cancelLabel: s.cancel,
      lottieAsset: AppAssets.lottieDelete,
      onConfirm: () => confirmed = true,
    );
    if (!confirmed || !context.mounted) return;

    final String? password = await CustomDialogManager.showInput(
      context: context,
      title: s.deleteAccount,
      subtitle: s.deleteAccountPasswordBody,
      fieldLabel: s.password,
      hint: s.enterPassword,
      submitLabel: s.delete,
      cancelLabel: s.cancel,
      obscureText: true,
    );
    if (password == null || password.isEmpty || !context.mounted) return;

    final AuthFailureType? failure =
        await AppRouter.deleteAccount(context, password);
    if (failure == null || !context.mounted) return;

    await CustomDialogManager.showError(
      context: context,
      title: s.deleteAccountFailed,
      subtitle: failure.message(context),
      closeLabel: s.close,
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final ThemeController theme = ThemeController.to;
    final HapticController haptics = Get.find<HapticController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      // FULL WIDTH. On a wide screen the page splits in two: the account
      // and app preferences on the left, the super admin's tools (admins,
      // control centre) on the right. Narrow screens stack them.
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final List<Widget> left = <Widget>[
              // ── Who is signed in (03/11/2026: same radius as the groups
              //    below, a soft accent wash; no border, no shadow) ─────
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: <Color>[
                      Color.lerp(AppColors.card, AppColors.primary, 0.10)!,
                      AppColors.card,
                    ],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    AppAvatar(name: user.displayName, size: 52),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            FormatHelper.capitalize(user.displayName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StyleText.fontSize16Weight700.copyWith(color: AppColors.text),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StyleText.fontSize12Weight400
                                .copyWith(color: AppColors.secondaryText),
                          ),
                          if (user.createdAt != null) ...<Widget>[
                            SizedBox(height: 6.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                AppIcon(Icons.calendar_today_rounded,
                                    size: 14.r, color: AppColors.primary),
                                SizedBox(width: 5.w),
                                Flexible(
                                  child: Text(
                                    FormatHelper.capitalize(s.memberSince(
                                      AppDates.day(context, user.createdAt),
                                    )),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: StyleText.fontSize11Weight400
                                        .copyWith(color: AppColors.secondaryText),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Role pill in the accent colour.
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        FormatHelper.capitalize(user.role.label(context)),
                        style: StyleText.fontSize11Weight600.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ── My space (members): the pages that left the side menu ────
              if (!user.isAdmin)
                Obx(() {
                  AppFeatures.to.values.length; // a switch flipped live
                  final List<MemberLink> links =
                      MemberLinks.forUser(context, user);
                  if (links.isEmpty) return const SizedBox.shrink();
                  // MY SPACE (03/11/2026): two groups, each title above its
                  // own box (no icon beside it), rows with an icon tile,
                  // title, line under it and an arrow.
                  final List<MemberLink> learning = links
                      .where((MemberLink l) => l.group == MemberLinkGroup.learning)
                      .toList();
                  final List<MemberLink> resources = links
                      .where((MemberLink l) => l.group == MemberLinkGroup.resources)
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (learning.isNotEmpty)
                        _MySpaceGroup(title: s.mySpaceLearning, links: learning),
                      if (resources.isNotEmpty)
                        _MySpaceGroup(title: s.mySpaceResources, links: resources),
                    ],
                  );
                }),

              // ── Appearance (03/11/2026: the My space look) ───────────────
              _SettingsGroup(
                title: s.appearance,
                rows: <Widget>[
                  Obx(
                    () => _GroupRow(
                      icon: Icons.dark_mode_rounded,
                      title: s.darkMode,
                      onTap: () => theme.setDarkMode(!theme.isDarkMode.value),
                      trailing: Switch.adaptive(
                        value: theme.isDarkMode.value,
                        activeTrackColor: AppColors.secondaryPrimary,
                        onChanged: theme.setDarkMode,
                      ),
                    ),
                  ),
                  Obx(
                    () => _GroupRow(
                      icon: Icons.translate_rounded,
                      title: s.language,
                      onTap: theme.toggleLanguage,
                      trailing: Text(
                        theme.languageCode.value == 'ar' ? 'العربية' : 'English',
                        style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  Obx(
                    () => _GroupRow(
                      icon: Icons.vibration_rounded,
                      title: s.haptics,
                      onTap: () => haptics.toggleHapticFeedback(!haptics.isHapticEnabled.value),
                      trailing: Switch.adaptive(
                        value: haptics.isHapticEnabled.value,
                        activeTrackColor: AppColors.secondaryPrimary,
                        onChanged: haptics.toggleHapticFeedback,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Branding (admin only — it changes the app for everybody
              //    on THIS device, so it is not hidden behind a rule) ───────
              if (user.isAdmin)
                AppCard(
                  title: s.branding,
                  caption: s.brandingLocalHint,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Tap either colour to change it. Primary paints buttons,
                      // icons and highlights; secondary paints every switch.
                      Obx(
                        () => CustomColorPickerSection(
                          showHeading: false,
                          primaryColor: theme.primaryColor.value,
                          secondaryColor: theme.secondaryColor.value,
                          onPrimaryColorSelected: (Color c) =>
                              theme.setBrandingColors(c, theme.secondaryColor.value),
                          onSecondaryColorSelected: (Color c) =>
                              theme.setBrandingColors(theme.primaryColor.value, c),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: AppButton(
                          label: s.resetColors,
                          icon: Icons.refresh_rounded,
                          kind: AppButtonKind.subtle,
                          dense: true,
                          onPressed: theme.resetBrandingColors,
                        ),
                      ),
                    ],
                  ),
                ),
              if (user.isAdmin) SizedBox(height: 16.h),

              // ── Demo data (admin only) ───────────────────────────────────
              //
              // Here rather than on the dashboard because it is a tool for
              // LOOKING at the app, and the dashboard is the screen its
              // numbers change most — a button that rewrites the chart you are
              // reading does not belong on top of that chart.
              if (user.isSuperAdmin) ...<Widget>[
                DemoDataCard(adminUid: user.uid),
                SizedBox(height: 16.h),
              ],



              // ── Account: sign out and delete (03/11/2026, My space look) ──
              _SettingsGroup(
                title: s.account,
                rows: <Widget>[
                  _GroupRow(
                    icon: Icons.logout_rounded,
                    title: s.signOut,
                    color: AppColors.red,
                    onTap: () => _confirmSignOut(context),
                  ),
                  _GroupRow(
                    icon: Icons.delete_forever_rounded,
                    title: s.deleteAccount,
                    subtitle: s.deleteAccountHint,
                    color: AppColors.red,
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
          ];

          final List<Widget> right = <Widget>[
            // Screenshots / recordings members took — any admin with Members.
            if (user.can(AdminPermission.members)) ...<Widget>[
              // Who has the app open right now — tap one for every control.
              const OnlineUsersCard(),
              SizedBox(height: 16.h),
              const CaptureAlertsCard(),
              SizedBox(height: 16.h),
            ],
            if (user.isSuperAdmin) ...<Widget>[
              // Every attempt to pull the lessons out of the app.
              const SecurityAlertsCard(),
              SizedBox(height: 16.h),
              // Every error any user hit, with full details.
              const ErrorReportsCard(),
              SizedBox(height: 16.h),
              const AdminsCard(),
              SizedBox(height: 16.h),
              const ControlCentreCard(),
              SizedBox(height: 16.h),
              const AppUpdateCard(),
              SizedBox(height: 16.h),
            ],
          ];

          final List<Widget> footerWidgets = <Widget>[
            SizedBox(height: 24.h),
            const PoweredByFooter(),
            SizedBox(height: 16.h),
          ];

          final bool split = right.isNotEmpty && constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 16.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (split)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: left,
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: right,
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[...right, ...left],
                ...footerWidgets,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A Settings group (03/11/2026): the title above, the rows in one box,
/// thin lines between rows starting where the text starts.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 8.h),
            child: Text(
              FormatHelper.capitalize(title),
              style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < rows.length; i++) ...<Widget>[
                    if (i > 0)
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: 64.w, end: 14.w),
                        child: Divider(height: 1, thickness: 1, color: AppColors.text.withOpacity(0.08)),
                      ),
                    rows[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One Settings row: icon square · title (+ line under) · trailing.
/// Without [trailing] it shows the arrow. [color] tints it (red = sign out,
/// delete). [iconWidget] replaces the icon (an SVG).
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
    this.iconWidget,
    this.dimmed = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? iconWidget;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? AppColors.primary;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38.r,
                  height: 38.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: iconWidget ?? AppIcon(icon, size: 20.r, color: accent),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        FormatHelper.capitalize(title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize14Weight600.copyWith(color: color ?? AppColors.text),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                trailing ??
                    AppIcon(Icons.chevron_right_rounded, size: 18.r, color: color ?? AppColors.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One "My space" group.
class _MySpaceGroup extends StatelessWidget {
  const _MySpaceGroup({required this.title, required this.links});

  final String title;
  final List<MemberLink> links;

  @override
  Widget build(BuildContext context) => _SettingsGroup(
        title: title,
        rows: <Widget>[for (final MemberLink l in links) _MySpaceRow(link: l)],
      );
}

class _MySpaceRow extends StatelessWidget {
  const _MySpaceRow({required this.link});

  final MemberLink link;

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.primary;
    return _GroupRow(
      icon: link.icon,
      title: link.label,
      subtitle: link.locked ? (link.lockedHint ?? link.hint) : link.hint,
      dimmed: link.locked,
      iconWidget: link.svg == null
          ? null
          : SvgPicture.asset(
              link.svg!,
              width: 20.r,
              height: 20.r,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
      trailing: link.locked
          ? AppIcon(Icons.lock_outline_rounded, size: 18.r, color: AppColors.secondaryText)
          : null,
      onTap: link.locked
          ? () => AppMessenger.of(context)
            ..hide()
            ..show(AppMessage(content: Text(FormatHelper.capitalize(link.lockedHint ?? ''))))
          : () => link.open(context),
    );
  }
}
