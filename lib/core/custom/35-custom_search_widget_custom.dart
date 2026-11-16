/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 35-custom_search_widget_custom.dart
/// Purpose: Declares `AppSearchTextField` — the ONE search box in the app.
/// Author: Manger Plus team
/// Created: 18/9/2026 — ported from knowticed_plus.
///
/// WHY IT EXISTS
/// -------------
/// Every screen that searches was hand-rolling a [CustomTextField] with its
/// own padding, its own magnifier and its own idea of how tall a search box
/// is. Three screens, three heights. This is the single widget they all use
/// now, so a change to the search box is a change in one file.
///
/// THE RULES IT ENCODES
/// --------------------
///   * NO BORDER. A filled `AppColors.card` rectangle at radius 8, exactly
///     like every other control in a console toolbar.
///   * 38 logical pixels tall — the toolbar control height. Pass [height] as
///     a RAW number; [CustomTextField] applies `.sp` itself, so a value that
///     already carries `.sp` is scaled twice and comes out too tall.
///   * The magnifier is the shared `AppAssets.search` SVG, tinted with the
///     theme's muted grey, never a Material `Icons.search`.
///
/// ```dart
/// AppSearchTextField(
///   controller: _search,
///   expanded: false,
///   width: 280,
///   hintText: S.of(context).search,
///   onChanged: (String v) => setState(() => _query = v),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/haptic_controller.dart';
import 'package:asec/generated/l10n.dart';

class AppSearchTextField extends StatelessWidget {
  const AppSearchTextField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.fillColor,
    this.borderRadius,
    this.suffixIcon,
    this.prefixIcon,
    this.textInputAction,
    this.textAlign,
    this.textDirection,
    this.hintFontSize,
    this.showSearchIcon = true,
    this.expanded = true,
    this.width,
    this.height,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Defaults to `S.of(context).search`.
  final String? hintText;

  final Color? fillColor;
  final BorderRadius? borderRadius;

  /// Trailing widget — normally a "clear" button.
  final Widget? suffixIcon;

  /// Replaces the built-in magnifier. Takes precedence over [showSearchIcon].
  final Widget? prefixIcon;

  final TextInputAction? textInputAction;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final double? hintFontSize;

  /// Draw the built-in magnifier as the prefix. False renders a plain input —
  /// what a chat composer wants.
  final bool showSearchIcon;

  /// Wrap the field in an [Expanded].
  ///
  /// True is what a phone toolbar wants — the field sits in a [Row] beside
  /// filter buttons. It MUST be false when the parent is not a [Flex]; a
  /// console toolbar passes false and a [width] instead, because
  /// [ConsolePage]'s action row sizes its children.
  final bool expanded;

  /// Fixed field width. Ignored when [expanded] is true.
  final double? width;

  /// Fixed field height, as a RAW number — pass 38, never 38.sp.
  final double? height;

  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = prefixIcon ??
        (showSearchIcon
            ? CustomSvgImage(
                assetPath: AppAssets.search,
                width: 16.sp,
                height: 16.sp,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  AppColors.secondaryText,
                  BlendMode.srcIn,
                ),
              )
            : null);

    // 16/11/2026: no fixed height. A 38 box with 13.sp above and below left
    // less than a line for the text — on phones the typed text and the hint
    // were cut off. The field now sizes itself to one line plus 10.sp
    // padding (about 38 on desktop) and is never shorter than its text.
    final Widget field = CustomTextField(
      height: null,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      hint: hintText ?? S.of(context).search,
      maxLines: 1,
      hintFontSize: hintFontSize,
      suffixIcon: suffixIcon,
      prefixIcon: leading,
      textInputAction: textInputAction,
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      fillColor: fillColor ?? AppColors.card,
      borderRadius: borderRadius ?? AppRadius.buttonR,
      // 8.sp vertical against a 38-tall box leaves 22 for a 12-14.sp line,
      // which fits — so the text centres instead of being clipped low.
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppPadding.h,
        vertical: height == null ? 10.sp : ((height! - 20) / 2).clamp(6, 14).sp,
      ),
      hintStyle: StyleText.fontSize13Weight400.copyWith(
        color: AppColors.secondaryText,
      ),
      onTap: HapticController.low,
    );

    if (expanded) return Expanded(child: field);
    if (width != null) return SizedBox(width: width, child: field);
    return field;
  }
}
