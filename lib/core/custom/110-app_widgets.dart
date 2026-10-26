/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 110-app_widgets.dart
/// Purpose: Small building blocks every Manger Plus screen shares —
///          `AppButton`, `AppAvatar`, `TypeBadge`, `AppLoading`,
///          `AppErrorView`, `AppEmptyView`, `InfoBanner`, `AppDates`.
/// Author: Manger Plus team
/// Created: 18/9/2026

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:asec/core/custom/89-custom_empty_state.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/settings/error_reports.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

// ── Buttons ─────────────────────────────────────────────────────────────────

enum AppButtonKind { filled, outlined, danger, subtle }

/// The one button. Shows a spinner and ignores taps while [loading].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = AppButtonKind.filled,
    this.loading = false,
    this.expand = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;
  final bool loading;

  /// Full width (forms on mobile).
  final bool expand;

  /// Smaller — table toolbars.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;

    final Color background;
    final Color foreground;
    BorderSide? border;
    switch (kind) {
      case AppButtonKind.filled:
        background = AppColors.primary;
        foreground = AppColors.textButton;
      case AppButtonKind.outlined:
        background = AppColors.transparent;
        foreground = AppColors.text;
        border = BorderSide(color: AppColors.borderGrey);
      case AppButtonKind.danger:
        background = AppColors.chip;
        foreground = AppColors.red;
      case AppButtonKind.subtle:
        background = AppColors.chip;
        foreground = AppColors.onChip;
    }

    final double height = dense ? 38.h : 50.h;
    final TextStyle textStyle = (dense
            ? StyleText.fontSize13Weight600
            : StyleText.fontSize15Weight600)
        .copyWith(color: foreground);

    final Widget content = loading
        ? SizedBox(
            width: 20.r,
            height: 20.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                AppIcon(icon, size: dense ? 16.sp : 20.sp, color: foreground),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(FormatHelper.capitalize(label),
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    final Widget button = Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonR,
          side: border ?? BorderSide.none,
        ),
        child: InkWell(
          borderRadius: AppRadius.buttonR,
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.h),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ── Avatar ──────────────────────────────────────────────────────────────────

/// A round avatar picture — the male or female illustration, never initials.
///
/// Pass [female] when the gender is known. Otherwise it is guessed from the
/// first word of [name] (see [AppAvatar.isFemaleName]); unknown names fall
/// back to the male picture.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = 40, this.female});

  final String name;
  final double size;
  final bool? female;

  static const String maleAsset =
      'assets/icons_assets/main_icons_assets/assets_male.svg';
  static const String femaleAsset =
      'assets/icons_assets/main_icons_assets/female_avatar.png';

  static const Set<String> _femaleNames = <String>{
    // Arabic
    'sara', 'sarah', 'laila', 'layla', 'leila', 'hana', 'hanaa', 'nour',
    'noor', 'mona', 'mouna', 'mariam', 'maryam', 'mariem', 'fatma', 'fatima',
    'aya', 'ayah', 'salma', 'nada', 'rana', 'reem', 'rim', 'dina', 'dalia',
    'yasmin', 'yasmine', 'jasmine', 'heba', 'hoda', 'huda', 'amira', 'ameera',
    'nadia', 'noha', 'nesma', 'nisma', 'shaimaa', 'shaima', 'asmaa', 'asma',
    'esraa', 'israa', 'eman', 'iman', 'aisha', 'aysha', 'khadija', 'zeinab',
    'zainab', 'zeina', 'zaina', 'malak', 'farah', 'rahma', 'rania', 'ranya',
    'hala', 'habiba', 'jana', 'jannah', 'janna', 'lina', 'leena', 'lama',
    'rawan', 'razan', 'ruba', 'samar', 'samah', 'sama', 'soha', 'suha',
    'wafaa', 'walaa', 'yara', 'yomna', 'yumna', 'basma', 'doaa', 'duaa',
    'ghada', 'hagar', 'hajar', 'hind', 'inas', 'enas', 'lamia', 'lamiaa',
    'manal', 'marwa', 'mai', 'may', 'mayar', 'menna', 'mennatallah', 'nahla',
    'naglaa', 'nagwa', 'nermin', 'nermeen', 'rasha', 'sahar', 'samira',
    'shahd', 'shereen', 'sherine', 'sondos', 'tasneem', 'wafa', 'nourhan',
    'alaa', 'amal', 'afaf', 'abeer', 'ola', 'omnia', 'omneya', 'riham',
    'reham', 'sally', 'sohaila', 'suhaila', 'lojain', 'retaj',
    'hanan', 'haya', 'joud', 'lara', 'celine', 'carla',
    // English
    'anna', 'emma', 'olivia', 'sophia', 'mia', 'emily', 'grace', 'lily',
    'chloe', 'julia', 'kate', 'katie', 'lucy', 'maria', 'mary', 'nora',
    'rose', 'sophie', 'zoe', 'jane', 'jessica', 'laura', 'linda', 'lisa',
    'nancy', 'rachel', 'rebecca', 'susan', 'amy', 'ella', 'hannah',
    // Arabic script
    'سارة', 'ساره', 'ليلى', 'ليلي', 'هنا', 'هناء', 'نور', 'منى', 'مني',
    'مريم', 'فاطمة', 'آية', 'اية', 'سلمى', 'ندى', 'رنا', 'ريم', 'دينا',
    'داليا', 'ياسمين', 'هبة', 'هدى', 'أميرة', 'اميرة', 'نادية', 'نهى',
    'إيمان', 'ايمان', 'عائشة', 'خديجة', 'زينب', 'ملك', 'فرح', 'رحمة',
    'رانيا', 'هالة', 'حبيبة', 'جنى', 'لينا', 'روان', 'سمر', 'يارا', 'يمنى',
    'بسمة', 'دعاء', 'غادة', 'هاجر', 'هند', 'منال', 'مروة', 'مي', 'منة',
    'رشا', 'سحر', 'شهد', 'شيرين', 'تسنيم', 'نورهان', 'آلاء', 'الاء', 'أمل',
    'امل', 'عبير', 'علا', 'أمنية', 'امنية', 'ريهام', 'حنان', 'أسماء', 'اسماء',
    'إسراء', 'اسراء', 'شيماء',
  };

  /// Best-effort guess from the first word of a person's name.
  static bool isFemaleName(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return false;
    return _femaleNames.contains(parts.first.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isFemale = female ?? isFemaleName(name);
    final double d = size.r;
    return Container(
      width: d,
      height: d,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.chip,
        shape: BoxShape.circle,
      ),
      child: isFemale
          ? Image.asset(femaleAsset, width: d, height: d, fit: BoxFit.cover)
          : SvgPicture.asset(maleAsset, width: d, height: d, fit: BoxFit.cover),
    );
  }
}

// ── Type badge ──────────────────────────────────────────────────────────────

/// An icon on a soft square of its own colour — content types, stat tiles.
class TypeBadge extends StatelessWidget {
  const TypeBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.solid = false,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// Kept for API compatibility; badges no longer draw a background.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    // No background any more: just the glyph, in its colour, centred in the
    // same box so layouts that were built around the badge do not move.
    return SizedBox(
      width: size.r,
      height: size.r,
      child: Center(
        child: AppIcon(icon, color: color, size: (size * 0.7).r),
      ),
    );
  }
}

// ── States ──────────────────────────────────────────────────────────────────

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 24.r),
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

/// The "Something went wrong" screen. Pass the [error] (and [stackTrace])
/// that caused it: it is saved for the super admin (ErrorReports), and when
/// the super admin is the one looking, the full details show right here
/// under the message, with a Copy button.
class AppErrorView extends StatefulWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.error,
    this.stackTrace,
  });

  final String message;
  final VoidCallback? onRetry;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  @override
  void initState() {
    super.initState();
    _report();
  }

  @override
  void didUpdateWidget(AppErrorView old) {
    super.didUpdateWidget(old);
    if (!identical(old.error, widget.error)) _report();
  }

  void _report() {
    // No error object: still worth knowing which screen failed.
    ErrorReports.report(
      widget.error ?? 'AppErrorView shown without an error: ${widget.message}',
      widget.stackTrace ?? (widget.error == null ? StackTrace.current : null),
      source: 'screen',
    );
  }

  bool get _isSuper {
    try {
      return SessionController.to.current.isSuperAdmin;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Object? error = widget.error;
    final String details = error == null
        ? ''
        : <String>[
            '${error.runtimeType}',
            if (error is FirebaseException) '[${error.plugin}/${error.code}] ${error.message ?? ''}' else '$error',
          ].join('\n');

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(Icons.cloud_off_rounded, size: 48.sp, color: AppColors.secondaryText),
            SizedBox(height: 12.h),
            Text(
              FormatHelper.capitalize(widget.message),
              textAlign: TextAlign.center,
              style: StyleText.fontSize14Weight500
                  .copyWith(color: AppColors.secondaryText),
            ),
            // SUPER ADMIN ONLY: the real error, selectable and copyable.
            if (_isSuper && details.isNotEmpty) ...<Widget>[
              SizedBox(height: 12.h),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SelectableText(
                        details,
                        style: StyleText.fontSize12Weight400.copyWith(color: AppColors.red),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: () => Clipboard.setData(ClipboardData(
                            text: '$details\n\n${widget.stackTrace ?? ''}',
                          )),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(FormatHelper.capitalize(S.of(context).errorReportsCopy)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.onRetry != null) ...<Widget>[
              SizedBox(height: 16.h),
              AppButton(
                label: S.of(context).retry,
                icon: Icons.refresh_rounded,
                kind: AppButtonKind.subtle,
                onPressed: widget.onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, required this.title, this.subtitle, this.size = 160});

  final String title;
  final String? subtitle;
  final double size;

  /// From this window width on, the animation is drawn twice as big — on a
  /// desktop window the phone size looks like a stray icon.
  static const double desktopWidth = 900;

  @override
  Widget build(BuildContext context) {
    final bool desktop = MediaQuery.sizeOf(context).width >= desktopWidth;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CustomEmptyState(size: desktop ? size * 2 : size, verticalPadding: 8),
            Text(FormatHelper.capitalize(title),
                textAlign: TextAlign.center, style: StyleText.fontSize16Weight600),
            if (subtitle != null) ...<Widget>[
              SizedBox(height: 6.h),
              Text(
                FormatHelper.capitalize(subtitle!),
                textAlign: TextAlign.center,
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A coloured strip with an icon — errors, hints, "Firebase is not
/// configured".
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.color,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final Color? color;
  final IconData icon;

  factory InfoBanner.error(String message) => InfoBanner(
        message: message,
        color: AppColors.red,
        icon: Icons.error_outline_rounded,
      );

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 12.r),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.containerR,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(icon, color: c, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(FormatHelper.capitalize(message),
                style: StyleText.fontSize13Weight500.copyWith(color: AppColors.onChip)),
          ),
        ],
      ),
    );
  }
}

/// A rounded surface — the card every list row and panel sits on.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = AppRadius.container,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius.r),
        onTap: onTap,
        child: Padding(padding: padding ?? EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 16.r), child: child),
      ),
    );
  }
}

// ── Dates ───────────────────────────────────────────────────────────────────

/// Date formatting in the reader's language.
abstract final class AppDates {
  const AppDates._();

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// "18 Sep 2026"
  static String day(BuildContext context, DateTime? date) =>
      date == null ? '—' : DateFormat('d MMM y', _locale(context)).format(date);

  /// "Thu, 18 Sep"
  static String weekday(BuildContext context, DateTime date) =>
      DateFormat('EEE, d MMM', _locale(context)).format(date);

  /// "18 Sep, 14:05"
  static String dateTime(BuildContext context, DateTime? date) => date == null
      ? '—'
      : DateFormat('d MMM, HH:mm', _locale(context)).format(date);

  /// "14:05"
  static String time(BuildContext context, DateTime? date) =>
      date == null ? '' : DateFormat('HH:mm', _locale(context)).format(date);
}
