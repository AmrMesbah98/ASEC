/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_card.dart
/// Purpose: Declares `CvCard` — one CV in the directory.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// The icon of a position (role) — on the directory's tabs and the cards.
IconData cvRoleIcon(String role) {
  switch (role) {
    case 'Site Engineer':
      return Icons.engineering_rounded;
    case 'Technical Office Engineer':
      return Icons.apartment_rounded;
    case 'Design Engineer':
      return Icons.design_services_rounded;
    default:
      return Icons.work_outline_rounded;
  }
}

/// One CV in the directory — SLIM (09/11/2026): one compact row. The photo
/// with a thin brand ring; the name; the position in the brand colour; one
/// line of facts (graduation year · governorate · military status) as small icons
/// and text, all on one baseline; a chevron. No pills, no borders.
class CvCard extends StatefulWidget {
  const CvCard({
    super.key,
    required this.cv,
    this.onTap,
    this.showStatus = false,
  });

  final CvProfile cv;
  final VoidCallback? onTap;

  /// The admin sees the review state on the card; members do not.
  final bool showStatus;

  @override
  State<CvCard> createState() => _CvCardState();
}

class _CvCardState extends State<CvCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final CvProfile cv = widget.cv;
    final List<(IconData, String)> facts = <(IconData, String)>[
      if (cv.graduationYear.isNotEmpty) (Icons.school_outlined, cv.graduationYear),
      if (cv.location.isNotEmpty) (Icons.location_on_outlined, cv.location),
      if (cv.militaryStatus.isNotEmpty) (Icons.verified_user_outlined, cv.militaryStatus),
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsetsDirectional.fromSTEB(12.w, 10.h, 10.w, 10.h),
          decoration: BoxDecoration(
            color: _hover ? AppColors.primary.withOpacity(0.06) : AppColors.card,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.14 : 0.06),
                blurRadius: _hover ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Photo, thin brand ring.
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
                  ),
                ),
                child: CvAvatar(cv: cv, size: 44),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(cv.fullName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize15Weight600
                          .copyWith(color: AppColors.text, height: 1.2),
                    ),
                    if (cv.role.isNotEmpty) ...<Widget>[
                      SizedBox(height: 2.h),
                      Text(
                        FormatHelper.capitalize(cv.role),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize12Weight500
                            .copyWith(color: AppColors.primary, height: 1.2),
                      ),
                    ],
                    if (facts.isNotEmpty) ...<Widget>[
                      SizedBox(height: 6.h),
                      // Spread across the whole line, the last one at the
                      // end (09/11/2026).
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          for (final (IconData icon, String text) in facts)
                            Flexible(child: _Fact(icon: icon, text: text)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (widget.showStatus)
                _Tag(label: cv.status.label(context), strong: true)
              else
                AppIcon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20.sp,
                  color: _hover ? AppColors.primary : AppColors.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One fact on the card's last line: a small icon and its text, aligned on
/// one baseline with the others.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(icon, size: 13.sp, color: AppColors.secondaryText),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              FormatHelper.capitalize(text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StyleText.fontSize11Weight500
                  .copyWith(color: AppColors.secondaryText, height: 1.2),
            ),
          ),
        ],
      );
}

/// The CV's photo, or the app's avatar when there is none.
class CvAvatar extends StatelessWidget {
  const CvAvatar({super.key, required this.cv, this.size = 48});

  final CvProfile cv;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!cv.hasPhoto) return AppAvatar(name: cv.fullName, size: size);

    return Container(
      width: size.r,
      height: size.r,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.chip,
      ),
      child: Image.network(
        cv.photoUrl,
        fit: BoxFit.cover,
        // A photo that will not load must not leave a broken box in a list:
        // the initials avatar is the fallback.
        errorBuilder: (BuildContext context, Object _, StackTrace? __) =>
            AppAvatar(name: cv.fullName, size: size),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.muted = false, this.strong = false});

  final String label;
  final bool muted;

  /// The admin's review state — brand-tinted so it stands out from skills.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final Color color = strong
        ? AppColors.primary
        : (muted ? AppColors.secondaryText : AppColors.onChip);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: strong ? AppColors.primary.withOpacity(0.10) : AppColors.chip,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        FormatHelper.capitalize(label),
        style: StyleText.fontSize10Weight600.copyWith(color: color),
      ),
    );
  }
}
