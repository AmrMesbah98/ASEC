/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: hvac_locked_page.dart
/// Purpose: Declares `HvacLockedPage` — what a member sees behind the HVAC
///          item of the Calculations menu while it is not open to them:
///          the item stays in the menu, locked, until HVAC comes with the
///          paid subscriptions in a coming version (Eng. Ahmed Shuhayb,
///          26/10/2026).
/// Author: ASEC team
/// Created: 26/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';

class HvacLockedPage extends StatelessWidget {
  const HvacLockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    return ConsolePage(
      title: 'HVAC',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.lock_rounded, size: 56, color: AppColors.secondaryText),
              const SizedBox(height: 16),
              Text(
                ar ? 'حسابات التكييف قريبًا' : 'HVAC Calculations — Coming Soon',
                textAlign: TextAlign.center,
                style: StyleText.fontSize16Weight500.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                ar
                    ? 'ستكون متاحة مع الاشتراكات في الإصدار القادم.'
                    : 'They will be available with the subscriptions in the next version.',
                textAlign: TextAlign.center,
                style: StyleText.fontSize14Weight400.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
