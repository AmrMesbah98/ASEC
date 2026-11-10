/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 8-custom_filter_app.dart
/// Purpose: Declares `StatusChipFilter` and `StatusChipItem`.
/// Author: Manger Plus team
/// Created: 4/9/2026 — ported verbatim in behaviour from knowticed_plus.
///
/// WHY THIS REPLACED THE COLOURED PILL ROW
/// ---------------------------------------
/// The Orders board used to show one pill per status, each in its own hue —
/// red, orange, amber, blue, green. Seven colours across one row, none of them
/// from the brand, and the eye reads the RAINBOW before it reads any of the
/// numbers. This is the knowticed pattern instead: a count box and a plain
/// label, with the SELECTED one filled in brand primary and nothing else
/// coloured at all. One accent, one meaning — "this is the filter you are on".
///
/// Colour is not carrying status here, and it does not need to: the label says
/// the status and the number says how many.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/104-custom_motion.dart';
import 'package:asec/core/extensions/context_extensions.dart';
import 'package:asec/core/helper/main_helper/localized_number.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class StatusChipFilter extends StatelessWidget {
  /// List of chip items to display.
  final List<StatusChipItem> items;

  /// Currently selected key.
  final String selectedKey;

  /// Called when a chip is tapped — returns the tapped item's key.
  final ValueChanged<String> onSelected;

  /// Selected count-box colour — defaults to [AppColors.primary].
  final Color? selectedColor;

  /// Unselected count-box colour — defaults to [AppColors.card].
  final Color? unselectedColor;

  /// Spacing after each chip — defaults to 30.sp.
  final double? chipSpacing;

  /// Spacing between count box and label — defaults to 15.sp.
  final double? innerSpacing;

  /// Size of the count box — defaults to 45.sp (35.sp on a phone).
  final double? chipSize;

  /// COMPACT (09/11/2026, "The Best"): a small round count and smaller
  /// text. Off by default, so every other filter row stays as it was.
  final bool compact;

  const StatusChipFilter({
    super.key,
    required this.items,
    required this.selectedKey,
    required this.onSelected,
    this.selectedColor,
    this.unselectedColor,
    this.chipSpacing,
    this.innerSpacing,
    this.chipSize,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = context.isPhone;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((StatusChipItem item) {
          return _StatusChip(
            item: item,
            isSelected: item.key == selectedKey,
            selectedColor: selectedColor ?? AppColors.primary,
            unselectedColor: unselectedColor ?? AppColors.card,
            chipSpacing: chipSpacing ?? (compact ? 18.sp : 30.sp),
            innerSpacing: innerSpacing ?? (compact ? 8.sp : 15.sp),
            chipSize: chipSize ?? (compact ? 26.sp : (isMobile ? 35.sp : 45.sp)),
            compact: compact,
            onTap: () => onSelected(item.key),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final StatusChipItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final double chipSpacing;
  final double innerSpacing;
  final double chipSize;
  final bool compact;
  final VoidCallback onTap;

  const _StatusChip({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.chipSpacing,
    required this.innerSpacing,
    required this.chipSize,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color labelColor =
        isSelected ? AppColors.text : AppColors.secondaryText;
    final Color countColor =
        isSelected ? AppColors.textButton : AppColors.text;

    // ── No count: a plain pill ──────────────────────────────────────────
    //
    // Without a number there is no count box, and the box is what carried
    // "this is the one you are on". So the FILL moves to the label itself —
    // primary when selected, card otherwise. Same one-accent rule, same
    // height, no second widget.
    if (item.count == null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: chipSpacing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: chipSize,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: AppPadding.h),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : unselectedColor,
                borderRadius: AppRadius.buttonR,
              ),
              child: Text(
                FormatHelper.capitalize(item.label),
                style: StyleText.fontSize14Weight500.copyWith(
                  color: isSelected ? AppColors.textButton : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ── Count box ─────────────────────────────────────────────────
            Container(
              width: chipSize,
              height: chipSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : unselectedColor,
                shape: compact ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: compact ? null : AppRadius.buttonR,
              ),
              child: AnimatedCount(
                // ADDED 8/9/2026: the count travels to its new value instead
                // of blinking, and re-travels whenever the pipeline changes.
                // The formatter is the same one the plain Text used, so the
                // digits are still localised — display only, the count stays
                // an int everywhere else. An Arabic screen otherwise shows
                // "14" next to Arabic-Indic dates.
                value: item.count!,
                format: (num value) =>
                    LocalizedNumber.of(context, value.round()),
                textAlign: TextAlign.center,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                style: (compact ? StyleText.fontSize12Weight600 : StyleText.fontSize20Weight500).copyWith(
                  color: countColor,
                  height: 1.0.h,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ),

            SizedBox(width: innerSpacing),

            // ── Label ─────────────────────────────────────────────────────
            Text(
              FormatHelper.capitalize(item.label),
              style: (compact ? StyleText.fontSize13Weight600 : StyleText.fontSize16Weight600)
                  .copyWith(color: labelColor),
            ),

            SizedBox(width: chipSpacing),
          ],
        ),
      ),
    );
  }
}

/// One chip: a key to match against, a label to show, and a count.
///
/// Deliberately carries NO colour. knowticed's version has an optional
/// `labelColor`; it was the doorway the rainbow came through, so it is not
/// reproduced here.
class StatusChipItem {
  /// Unique identifier — matched against [StatusChipFilter.selectedKey].
  final String key;

  /// Display label shown next to the count box.
  final String label;

  /// Count shown inside the box, or null for a chip that has no number to
  /// show.
  ///
  /// ADDED 18/9/2026. Some filter rows genuinely have a count in hand — how
  /// many students are in a section, how many results are below the pass
  /// mark — and the count box is the whole point of this widget for those.
  /// Others do not: a content-type row filters a list that is still behind a
  /// stream when the chips are built, and a section picker that ACTS on the
  /// chosen section rather than filtering a visible list has nothing to
  /// count. Those rows used to be a second, separate pill widget; now they
  /// are this widget with `count: null`, which is what keeps every filter in
  /// the app one control.
  final int? count;

  const StatusChipItem({
    required this.key,
    required this.label,
    this.count,
  });
}

/// The canonical key of the "everything" chip. Kept a constant so the pages
/// and this file cannot disagree about the spelling.
const String kAllChipKey = 'All';
