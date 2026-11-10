/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: multi_select_field.dart
/// Purpose: Declares `MultiSelectField` — pick several values from a closed
///          list, shown as chips.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// ENGX used a checkbox dialog per list. This is the same idea in one reusable
/// field: the chips ARE the value, tapping the field opens the list, and the
/// sheet keeps its own copy until Done so a cancel changes nothing.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icon = Icons.rule_rounded,
    this.emptyHint,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final IconData icon;

  /// Shown instead of "Tap to choose" when the list is empty for a reason —
  /// "pick a role first", say.
  final String? emptyHint;

  final bool enabled;

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    if (options.isEmpty) {
      // Nothing to pick yet (e.g. no role chosen): say why instead of
      // silently doing nothing.
      if (emptyHint != null) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(emptyHint!)));
      }
      return;
    }
    final List<String>? picked = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext sheetContext) => _PickerSheet(
        label: label,
        options: options,
        selected: selected,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool empty = selected.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              FormatHelper.capitalize(label),
              style: StyleText.fontSize13Weight600
                  .copyWith(color: AppColors.secondaryText),
            ),
            const Spacer(),
            if (!empty)
              Text(
                FormatHelper.capitalize(s.selectedCount('${selected.length}')),
                style: StyleText.fontSize11Weight600
                    .copyWith(color: AppColors.primary),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        Material(
          color: AppColors.field,
          borderRadius: AppRadius.fieldR,
          child: InkWell(
            borderRadius: AppRadius.fieldR,
            onTap: () => _open(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppIcon(icon, size: 18.sp, color: AppColors.secondaryText),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: empty
                        ? Text(
                            FormatHelper.capitalize(options.isEmpty
                                ? (emptyHint ?? s.noneChosen)
                                : s.pickSome),
                            style: StyleText.fontSize13Weight400
                                .copyWith(color: AppColors.secondaryText),
                          )
                        : Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: <Widget>[
                              for (final String value in selected)
                                _Chip(
                                  label: value,
                                  onRemove: enabled
                                      ? () => onChanged(
                                            selected
                                                .where((String v) => v != value)
                                                .toList(),
                                          )
                                      : null,
                                ),
                            ],
                          ),
                  ),
                  SizedBox(width: 6.w),
                  AppIcon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18.sp,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.buttonR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            FormatHelper.capitalize(label),
            style: StyleText.fontSize11Weight600
                .copyWith(color: AppColors.onChip),
          ),
          if (onRemove != null) ...<Widget>[
            SizedBox(width: 5.w),
            InkWell(
              onTap: onRemove,
              child: AppIcon(
                Icons.close_rounded,
                size: 12.sp,
                color: AppColors.onChip,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The sheet keeps its OWN list and only hands it back on Done — closing it
/// any other way leaves the field exactly as it was.
class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.label,
    required this.options,
    required this.selected,
  });

  final String label;
  final List<String> options;
  final List<String> selected;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late final Set<String> _picked = widget.selected.toSet();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(FormatHelper.capitalize(widget.label),
                      style: StyleText.fontSize16Weight600),
                ),
                Text(
                  FormatHelper.capitalize(s.selectedCount('${_picked.length}')),
                  style: StyleText.fontSize12Weight600
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: <Widget>[
                    for (final String option in widget.options)
                      _Selectable(
                        label: option,
                        selected: _picked.contains(option),
                        onTap: () => setState(() {
                          if (!_picked.remove(option)) _picked.add(option);
                        }),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            AppButton(
              label: s.done,
              icon: Icons.check_rounded,
              expand: true,
              onPressed: () =>
                  Navigator.of(context).pop(_picked.toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Selectable extends StatelessWidget {
  const _Selectable({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.secondaryText;

    return Material(
      color: selected ? AppColors.chip : AppColors.transparent,
      borderRadius: AppRadius.buttonR,
      child: InkWell(
        borderRadius: AppRadius.buttonR,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: AppRadius.buttonR,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderGrey,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 15.sp,
                color: color,
              ),
              SizedBox(width: 7.w),
              Text(
                FormatHelper.capitalize(label),
                style: (selected
                        ? StyleText.fontSize12Weight600
                        : StyleText.fontSize12Weight400)
                    .copyWith(color: selected ? AppColors.primary : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
