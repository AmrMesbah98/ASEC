/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 112-powered_by_footer.dart
/// Purpose: Declares `PoweredByFooter` — the "Powered by Amr Mesbah" /
///          copyright line shown on the sign-in screen and at the bottom of
///          every role's settings page.
/// Author: Amr Mesbah
/// Created: 18/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class PoweredByFooter extends StatelessWidget {
  const PoweredByFooter({super.key, this.color});

  /// Text colour; defaults to the secondary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool arabic = Localizations.localeOf(context).languageCode == 'ar';
    final int year = DateTime.now().year;
    final Color c = color ?? AppColors.secondaryText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          FormatHelper.capitalize(arabic ? 'تطوير Amr Mesbah' : 'Powered by Amr Mesbah'),
          textAlign: TextAlign.center,
          style: StyleText.fontSize12Weight600.copyWith(color: c),
        ),
        SizedBox(height: 2.h),
        Text(
          // 12/11/2026: every right belongs to Amr Mesbah.
          arabic ? '© $year Amr Mesbah — جميع الحقوق محفوظة' : '© $year Amr Mesbah. All rights reserved.',
          textAlign: TextAlign.center,
          style: StyleText.fontSize12Weight400.copyWith(color: c),
        ),
      ],
    );
  }
}
