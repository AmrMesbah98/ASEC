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
import 'package:get/get.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
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
              // ── Who is signed in ─────────────────────────────────────────
              AppCard(
                child: Row(
                  children: <Widget>[
                    AppAvatar(name: user.displayName, size: 52),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            FormatHelper.capitalize(user.displayName),
                            style: StyleText.fontSize16Weight600,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            FormatHelper.capitalize(user.email),
                            style: StyleText.fontSize13Weight400
                                .copyWith(color: AppColors.secondaryText),
                          ),
                          if (user.createdAt != null) ...<Widget>[
                            SizedBox(height: 2.h),
                            Text(
                              FormatHelper.capitalize(s.memberSince(
                                AppDates.day(context, user.createdAt),
                              )),
                              style: StyleText.fontSize12Weight400
                                  .copyWith(color: AppColors.secondaryText),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.chip,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        FormatHelper.capitalize(user.role.label(context)),
                        style: StyleText.fontSize11Weight600
                            .copyWith(color: AppColors.onChip),
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
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: AppCard(
                      title: s.settingsMySpace,
                      caption: s.settingsMySpaceHint,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final MemberLink link in links)
                            _SettingsTile(
                              icon: link.icon,
                              title: link.label,
                              onTap: () => link.open(context),
                              trailing: AppIcon(
                                Icons.chevron_right_rounded,
                                color: AppColors.secondaryText,
                                size: 20.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

              // ── Appearance ───────────────────────────────────────────────
              AppCard(
                title: s.appearance,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Each tile gets a transparent Material of its own:
                    // ListTile paints its ink on the nearest Material
                    // ancestor, and the card's coloured box sits in between.
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.dark_mode_rounded,
                        title: s.darkMode,
                        trailing: Switch.adaptive(
                          value: theme.isDarkMode.value,
                          activeTrackColor: AppColors.secondaryPrimary,
                          onChanged: theme.setDarkMode,
                        ),
                      ),
                    ),
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.translate_rounded,
                        title: s.language,
                        onTap: theme.toggleLanguage,
                        trailing: Text(
                          FormatHelper.capitalize(theme.languageCode.value == 'ar'
                              ? 'العربية'
                              : 'English'),
                          style: StyleText.fontSize13Weight600
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.vibration_rounded,
                        title: s.haptics,
                        trailing: Switch.adaptive(
                          value: haptics.isHapticEnabled.value,
                          activeTrackColor: AppColors.secondaryPrimary,
                          onChanged: haptics.toggleHapticFeedback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

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



              AppButton(
                label: s.signOut,
                icon: Icons.logout_rounded,
                kind: AppButtonKind.danger,
                expand: true,
                onPressed: () => _confirmSignOut(context),
              ),
              SizedBox(height: 16.h),

              // ── Delete account — every role, every platform ─────────────
              AppCard(
                title: s.dangerZone,
                caption: s.deleteAccountHint,
                child: _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: s.deleteAccount,
                  color: AppColors.red,
                  onTap: () => _confirmDeleteAccount(context),
                  trailing: AppIcon(
                    Icons.chevron_right_rounded,
                    color: AppColors.red,
                    size: 20.sp,
                  ),
                ),
              ),
          ];

          final List<Widget> right = <Widget>[
            // Screenshots / recordings members took — any admin with Members.
            if (user.can(AdminPermission.members)) ...<Widget>[
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

/// One row in a settings card: icon, label, and whatever control belongs on
/// the end. The Material is not decoration — see the comment at the call site.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  /// Tints the icon and label — red for the destructive row.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: AppIcon(icon, color: color),
        title: Text(
          FormatHelper.capitalize(title),
          style: color == null
              ? StyleText.fontSize14Weight500
              : StyleText.fontSize14Weight500.copyWith(color: color),
        ),
        trailing: trailing,
      ),
    );
  }
}
