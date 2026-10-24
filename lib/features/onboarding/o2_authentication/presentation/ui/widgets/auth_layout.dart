/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: auth_layout.dart
/// Purpose: Declares `AuthLayout` and `AuthLanguageToggle` — the responsive
///          frame the sign-in and register forms sit in.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 24/10/2026 - `compactHeader`: the register screen keeps the small
///          header so its fields are drawn bigger.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/112-powered_by_footer.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/brand_mark.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// One frame, two shapes.
///
/// WIDTH DECIDES, NOT THE PLATFORM. At [splitWidth] and above the screen is a
/// brand panel BESIDE the form; below it the gradient header sits above the
/// form instead. A macOS window dragged down to phone width gets the phone
/// layout, because at 400pt the two-panel layout is two squeezed columns.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.form,
    required this.illustration,
    this.fitToScreen = false,
    this.compactHeader = false,
  });

  /// The card of fields — sign-in or register.
  final Widget form;

  /// The SVG on the brand side (see [AppAssets]).
  final String illustration;

  /// NO SCROLLING. Everything is laid out to fit the visible height: the
  /// header shrinks (and drops its illustration on short screens or while the
  /// keyboard is open) and the form scales down if it still doesn't fit.
  /// Used by sign-in; register is longer and keeps scrolling.
  final bool fitToScreen;

  /// Phone / tablet: always the small header (small logo, no artwork), so a
  /// long form (register) keeps more room and is shrunk less to fit.
  final bool compactHeader;

  /// The brand side: one flat colour from the theme — white in light mode,
  /// the card colour in dark mode — with the theme's text colours on it.
  static Color get _brandBackground => AppColors.card;
  static Color get _brandText => AppColors.text;
  static Color get _brandSubtext => AppColors.secondaryText;

  /// The logo alone — no tile, no name.
  static Widget _logo(double size) =>
      BrandMark(size: size, showName: false);

  /// From this width on, the layout splits in two.
  static const double splitWidth = 900;

  static bool isSplit(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= splitWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isSplit(context)
          ? _split(context)
          : fitToScreen
              ? _stackedFit(context)
              : _stacked(context),
    );
  }

  // ── Desktop / wide window: brand panel | form ────────────────────────────

  Widget _split(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(color: _brandBackground),
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 48.sp,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _logo(110),
                const Spacer(),
                Flexible(
                  flex: 3,
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: 420.w, maxHeight: 340.h),
                      child: CustomSvgImage.natural(assetPath: illustration),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  FormatHelper.capitalize(S.of(context).heroTitle),
                  style: StyleText.fontSize28Weight600
                      .copyWith(color: _brandText),
                ),
                SizedBox(height: 8.h),
                Text(
                  FormatHelper.capitalize(S.of(context).heroSubtitle),
                  style: StyleText.fontSize15Weight400
                      .copyWith(color: _brandSubtext),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Stack(
            children: <Widget>[
              if (fitToScreen)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.h,
                    vertical: 40.sp,
                  ),
                  child: _fittedForm(maxWidth: 420.w),
                )
              else
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppPadding.h,
                      vertical: 40.sp,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 420.w),
                      child: form,
                    ),
                  ),
                ),
              PositionedDirectional(
                top: 20.h,
                end: 20,
                child: const AuthLanguageToggle(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The form at its natural size, scaled DOWN (never up) when the space is
  /// shorter than the form. The width is fixed first so the form's
  /// `CrossAxisAlignment.stretch` has something to stretch to.
  Widget _fittedForm({required double maxWidth, Alignment align = Alignment.center}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double width = math.min(maxWidth, c.maxWidth);
        return Align(
          alignment: align,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: align,
            child: SizedBox(width: width, child: form),
          ),
        );
      },
    );
  }

  // ── Phone / tablet, no scroll: compact header + fitted form ──────────────

  Widget _stackedFit(BuildContext context) {
    // `padding`, not `viewPadding`: with the keyboard open the inset is
    // already taken by the keyboard, so it must read zero here.
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double height = c.maxHeight;
        // Short screen or keyboard up → logo beside the name, no artwork.
        final bool compact = compactHeader || keyboardOpen || height < 680;
        final double illustrationHeight =
            compact ? 0 : math.min(120.h, height * 0.14);

        return Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppPadding.h,
                safe.top + 8.h,
                AppPadding.h,
                compact ? 14.h : 20.h,
              ),
              decoration: BoxDecoration(
                color: _brandBackground,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AuthLanguageToggle(onLight: true),
                  ),
                  _logo(compact ? 64 : 92),
                  if (illustrationHeight > 0) ...<Widget>[
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: illustrationHeight,
                      child: CustomSvgImage.natural(assetPath: illustration),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppPadding.h,
                  16.h,
                  AppPadding.h,
                  safe.bottom + 8.h,
                ),
                child: _fittedForm(
                  maxWidth: 480.w,
                  align: Alignment.topCenter,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Phone / tablet: gradient header over the form ────────────────────────

  Widget _stacked(BuildContext context) {
    // THE LAST LINE HAS TO BE REACHABLE. The system inset is added to the
    // bottom of the scroll padding so the footer can always be scrolled clear
    // of the gesture bar. `viewPadding`, not `padding`: with the keyboard open
    // the Scaffold has already consumed the inset, and `padding` would then
    // read zero.
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 12.h),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding:
                EdgeInsets.fromLTRB(AppPadding.h, 56.h, AppPadding.h, 36.h),
            decoration: BoxDecoration(
              color: _brandBackground,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(36.r)),
            ),
            child: Column(
              children: <Widget>[
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AuthLanguageToggle(onLight: true),
                ),
                _logo(100),
                SizedBox(height: 20.h),
                SizedBox(
                  height: 140.h,
                  child: CustomSvgImage.natural(assetPath: illustration),
                ),
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480.w),
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(AppPadding.h, 24.h, AppPadding.h, 28.h),
                child: form,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EN | ع — switches the whole app's language.
class AuthLanguageToggle extends StatelessWidget {
  const AuthLanguageToggle({super.key, this.onDark = false, this.onLight = false});

  final bool onDark;

  /// On the brand header (kept for call sites; follows the theme).
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.to;
    final Color color = onDark
        ? Colors.white
        : AppColors.text;
    return Obx(
      () => TextButton.icon(
        onPressed: theme.toggleLanguage,
        icon: AppIcon(Icons.translate_rounded, color: color, size: 18.sp),
        label: Text(
          FormatHelper.capitalize(theme.languageCode.value == 'ar' ? 'English' : 'العربية'),
          style: StyleText.fontSize13Weight600.copyWith(color: color),
        ),
      ),
    );
  }
}

/// The "Powered by" line every auth screen ends with.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: const PoweredByFooter(),
      );
}
