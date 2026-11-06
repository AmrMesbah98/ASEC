/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 57-custom_dialog_manager.dart
/// Purpose: Declares `CustomDialogManager` — the ONE door to every dialog.
/// Author: Manger Plus team
/// Created: 18/9/2026 — ported in spirit from knowticed_plus.
///
/// WHY A MANAGER RATHER THAN LOOSE FUNCTIONS
/// -----------------------------------------
/// `11-custom_confirm_dialog.dart` already owns the *animated message* family
/// (confirm / success / error / warning / comment) and it stays the place
/// those are drawn. What it never had is the other half a console needs: a
/// dialog that holds a FORM — a filter sheet, an export sheet, a detail
/// panel. Those were being hand-rolled per page out of raw `showDialog` +
/// `Dialog`, which is exactly how five dialogs end up with five different
/// widths, paddings and button orders.
///
/// So this file is the single entry point. Every dialog in the app is opened
/// through `CustomDialogManager.*`:
///
///   * the message family forwards to `11-custom_confirm_dialog`, unchanged,
///     so nothing about those dialogs moves;
///   * the form family ([showContent], [showFilter], [showExport]) is drawn
///     here, on one shell, with one set of rules.
///
/// THE RULES THE FORM SHELL ENCODES
/// --------------------------------
///   * NO BORDERS. `AppColors.card` in light, `AppColors.background` in dark,
///     radius 8, one soft shadow. Same as the message shell.
///   * The title row carries an optional tinted badge and always a close X —
///     a form dialog can be abandoned, so it says so.
///   * Actions sit bottom-RIGHT, cancel first, primary last. `AppButton` does
///     the drawing, so a dialog's buttons are the page's buttons.
///   * A fixed [width], defaulting to 560 — the console runs at ScreenUtil
///     scale 1, so these are real logical pixels.
///
/// ```dart
/// await CustomDialogManager.showFilter(
///   context: context,
///   title: S.of(context).filters,
///   onClear: cubit.clearFilters,
///   child: const _DashboardFilterForm(),
/// );
/// ```
library;

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/custom/83-loading.dart';
import 'package:asec/core/custom/11-custom_confirm_dialog.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class CustomDialogManager {
  const CustomDialogManager._();

  // ───────────────────────────────────────────────────────────────────────
  //  MESSAGE FAMILY — forwarded to 11-custom_confirm_dialog
  // ───────────────────────────────────────────────────────────────────────

  /// "Are you sure?" with a Yes / No pair.
  static Future<void> showConfirm({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String confirmLabel,
    required String cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String? lottieAsset,
  }) =>
      showConfirmDialog(
        context: context,
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        lottieAsset: lottieAsset,
      );

  /// One field and a confirm — e.g. the password re-prompt before deleting
  /// the account. Resolves to the trimmed text, or null if cancelled.
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String subtitle = '',
    String fieldLabel = '',
    String hint = '',
    required String submitLabel,
    required String cancelLabel,
    bool obscureText = false,
  }) =>
      showInputDialog(
        context: context,
        title: title,
        subtitle: subtitle,
        fieldLabel: fieldLabel,
        hint: hint,
        submitLabel: submitLabel,
        cancelLabel: cancelLabel,
        obscureText: obscureText,
      );

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String closeLabel,
    VoidCallback? onClose,
  }) =>
      showSuccessDialog(
        context: context,
        title: title,
        subtitle: subtitle,
        closeLabel: closeLabel,
        onClose: onClose,
      );

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String closeLabel,
    VoidCallback? onClose,
  }) =>
      showErrorDialog(
        context: context,
        title: title,
        subtitle: subtitle,
        closeLabel: closeLabel,
        onClose: onClose,
      );

  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String closeLabel,
    VoidCallback? onClose,
  }) =>
      showWarningDialog(
        context: context,
        title: title,
        subtitle: subtitle,
        closeLabel: closeLabel,
        onClose: onClose,
      );

  static Future<void> showComment({
    required BuildContext context,
    required String title,
    required String fieldLabel,
    required String hint,
    required String submitLabel,
    int maxLength = 500,
    void Function(String comment)? onSubmit,
  }) =>
      showCommentDialog(
        context: context,
        title: title,
        fieldLabel: fieldLabel,
        hint: hint,
        submitLabel: submitLabel,
        maxLength: maxLength,
        onSubmit: onSubmit,
      );

  // ───────────────────────────────────────────────────────────────────────
  //  FORM FAMILY — drawn here
  // ───────────────────────────────────────────────────────────────────────

  /// A dialog holding arbitrary content, with the caller's own action row.
  ///
  /// Returns whatever the caller pops with — `Navigator.of(context).pop(value)`.
  static Future<T?> showContent<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? subtitle,
    List<Widget> actions = const <Widget>[],
    double width = 560,
    IconData? icon,
    Color? iconColor,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.totalBlack.withOpacity(0.4),
      builder: (_) => DialogShell(
        title: title,
        subtitle: subtitle,
        width: width,
        icon: icon,
        iconColor: iconColor,
        actions: actions,
        child: child,
      ),
    );
  }

  /// The filter sheet every list page opens from its toolbar.
  ///
  /// [child] is the caller's own form. Resolves to true when Apply was
  /// pressed, false when Clear was, and null when the dialog was dismissed —
  /// so a page can tell "cleared" from "changed nothing".
  static Future<bool?> showFilter({
    required BuildContext context,
    required String title,
    required Widget child,
    required String applyLabel,
    required String clearLabel,
    VoidCallback? onApply,
    VoidCallback? onClear,
    String? subtitle,
    double width = 480,
  }) {
    return showContent<bool>(
      context: context,
      title: title,
      subtitle: subtitle,
      width: width,
      icon: Icons.filter_alt_outlined,
      child: child,
      actions: <Widget>[
        AppButton(
          label: clearLabel,
          kind: AppButtonKind.subtle,
          onPressed: () {
            onClear?.call();
            Navigator.of(context).pop(false);
          },
        ),
        AppButton(
          label: applyLabel,
          onPressed: () {
            onApply?.call();
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }

  /// Name-the-file-then-write, in knowticed's role-management shape.
  ///
  /// WHY IT OWNS THE WRITE
  /// --------------------
  /// [onExport] runs INSIDE this dialog, with the Discard / Export CSV pair
  /// replaced in place by a spinner while it does. Role management learned
  /// this the hard way: when the write happened after the dialog closed, a
  /// failure was reported on a toast painted under the dialog's own barrier
  /// and the button looked inert. Nothing can be pressed twice here, and the
  /// dialog cannot close on a write that has not finished.
  ///
  /// [onExport] returns true when a file was written, false when the user
  /// backed out of the system save panel — which is a cancel, not a failure,
  /// and gets no message. This resolves to the file name on true, null
  /// otherwise, so the caller knows whether to say anything.
  static Future<String?> showExport({
    required BuildContext context,
    required String title,
    required String fieldLabel,
    required String hint,
    required String exportLabel,
    required String discardLabel,
    required Future<bool> Function(String fileName) onExport,
    String defaultFileName = 'export',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.totalBlack.withOpacity(0.4),
      builder: (_) => _ExportDialog(
        title: title,
        fieldLabel: fieldLabel,
        hint: hint,
        exportLabel: exportLabel,
        discardLabel: discardLabel,
        defaultFileName: defaultFileName,
        onExport: onExport,
      ),
    );
  }
}

/// The export sheet, drawn the way role management draws it: a primary disc
/// carrying the export glyph, one named field, and Discard / Export CSV at
/// opposite ends of a 38-tall row.
class _ExportDialog extends StatefulWidget {
  const _ExportDialog({
    required this.title,
    required this.fieldLabel,
    required this.hint,
    required this.exportLabel,
    required this.discardLabel,
    required this.defaultFileName,
    required this.onExport,
  });

  final String title;
  final String fieldLabel;
  final String hint;
  final String exportLabel;
  final String discardLabel;
  final String defaultFileName;
  final Future<bool> Function(String fileName) onExport;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.defaultFileName);
  bool _busy = false;

  /// How long the spinner stays up at minimum.
  ///
  /// A small CSV is written in a couple of milliseconds, so the spinner would
  /// appear and vanish inside one frame and the dialog would look like it did
  /// nothing — the exact complaint this shape exists to answer. It is a floor,
  /// never a delay added to a slow export.
  static const Duration _minimumSpin = Duration(milliseconds: 700);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_busy) return;
    final String name =
        _name.text.trim().isEmpty ? widget.defaultFileName : _name.text.trim();

    setState(() => _busy = true);
    final Stopwatch clock = Stopwatch()..start();
    bool wrote = false;
    try {
      wrote = await widget.onExport(name);
    } finally {
      final Duration left = _minimumSpin - clock.elapsed;
      if (left > Duration.zero) await Future<void>.delayed(left);
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    // A cancelled save panel leaves the dialog open, so the user can simply
    // press Export again rather than reopening the whole thing.
    if (wrote) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final bool light = Theme.of(context).brightness == Brightness.light;
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 24.h),
      child: Container(
        width: 411.sp,
        decoration: BoxDecoration(
          color: light ? AppColors.card : AppColors.background,
          borderRadius: AppRadius.containerR,
        ),
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 30.sp,
                  height: 30.sp,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Center(
                    child: CustomSvgImage(
                      assetPath: AppAssets.export,
                      width: 16.sp,
                      height: 16.sp,
                      color: AppColors.textButton,
                    ),
                  ),
                ),
                SizedBox(width: 8.sp),
                Text(FormatHelper.capitalize(widget.title), style: StyleText.fontSize16Weight600),
              ],
            ),
            SizedBox(height: 15.sp),
            CustomTextField(
              label: widget.fieldLabel,
              hint: widget.hint,
              controller: _name,
              enabled: !_busy,
              maxLines: 1,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isArabic ? TextAlign.right : TextAlign.start,
            ),
            SizedBox(height: 15.sp),
            SizedBox(
              height: 38.sp,
              child: _busy
                  ? const Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: CircleProgress(),
                      ),
                    )
                  : Row(
                      children: <Widget>[
                        customButton(
                          title: widget.discardLabel,
                          function: () => Navigator.of(context).pop(),
                          color: light
                              ? AppColors.lightGrey
                              : AppColors.darkGrey,
                          textStyle: StyleText.fontSize14Weight400.copyWith(
                            color: light ? AppColors.black : AppColors.white,
                          ),
                        ),
                        const Spacer(),
                        customButton(
                          title: widget.exportLabel,
                          function: _run,
                          color: AppColors.primary,
                          textStyle: StyleText.fontSize14Weight500.copyWith(
                            color: AppColors.textButton,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shell every form dialog is drawn in. Public so a page that needs a
/// bespoke dialog still gets the house frame instead of rolling its own.
class DialogShell extends StatelessWidget {
  const DialogShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.width = 560,
    this.icon,
    this.iconColor,
    this.showClose = true,
    this.spreadActions = false,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// The ✕ in the corner. Off when the actions already have a Cancel.
  final bool showClose;

  /// Actions share the width: the first on the left, the last on the right
  /// (Cancel | Send) instead of both at the end.
  final bool spreadActions;

  /// Title (and subtitle) centred on the icon instead of aligned to its top.
  final bool centerTitle;
  final double width;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bool light = Theme.of(context).brightness == Brightness.light;
    final Color accent = iconColor ?? AppColors.primary;

    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 24.h),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: light ? AppColors.card : AppColors.background,
          borderRadius: AppRadius.containerR,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.totalBlack.withOpacity(0.08),
              blurRadius: 20.sp,
              offset: const Offset(-3, 4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(AppPadding.h, 18.h, AppPadding.h, 18.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Title row ───────────────────────────────────────────────
            Row(
              crossAxisAlignment:
                  centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  TypeBadge(icon: icon!, color: accent, size: 38),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(FormatHelper.capitalize(title), style: StyleText.fontSize18Weight600),
                      if (subtitle != null) ...<Widget>[
                        SizedBox(height: 2.h),
                        Text(
                          FormatHelper.capitalize(subtitle!),
                          style: StyleText.fontSize13Weight400
                              .copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showClose)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: AppIcon(Icons.close_rounded,
                        size: 20.sp, color: AppColors.secondaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Body ────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(child: child),
            ),

            // ── Actions ─────────────────────────────────────────────────
            if (actions.isNotEmpty) ...<Widget>[
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) SizedBox(width: 10.w),
                    if (spreadActions) Expanded(child: actions[i]) else actions[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
