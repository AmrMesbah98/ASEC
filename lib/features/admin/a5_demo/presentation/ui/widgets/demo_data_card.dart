/// Module: admin / a5_demo
///
///*************************** FILE INFO ****************************///
/// File Name: demo_data_card.dart
/// Purpose: Declares `DemoDataCard` — the admin's Fill / Remove demo buttons.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// Lives in Settings rather than on the dashboard: it is a tool for looking at
/// the app, not part of running it, and the dashboard is the one screen whose
/// numbers the demo data changes most.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a5_demo/data/data_source/remote_data_source/demo_remote_data_source.dart';
import 'package:asec/features/admin/a5_demo/domain/constants/demo_seed.dart';
import 'package:asec/features/admin/a5_demo/presentation/controller/demo_cubit.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class DemoDataCard extends StatelessWidget {
  const DemoDataCard({super.key, required this.adminUid});

  final String adminUid;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DemoCubit>(
      create: (_) => DemoCubit(),
      child: _DemoDataView(adminUid: adminUid),
    );
  }
}

class _DemoDataView extends StatelessWidget {
  const _DemoDataView({required this.adminUid});

  final String adminUid;

  Future<void> _confirmRemove(BuildContext context) async {
    final S s = S.of(context);
    final DemoCubit cubit = context.read<DemoCubit>();

    await CustomDialogManager.showConfirm(
      context: context,
      title: s.removeDemoQuestion,
      subtitle: s.removeDemoBody,
      confirmLabel: s.removeDemo,
      cancelLabel: s.cancel,
      onConfirm: cubit.remove,
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return BlocConsumer<DemoCubit, DemoState>(
      listenWhen: (DemoState a, DemoState b) => a.status != b.status,
      listener: (BuildContext context, DemoState state) {
        final String? message = switch (state.status) {
          DemoStatus.filled => s.demoFilled(DemoSeed.sampleEmail),
          DemoStatus.removed => s.demoRemoved,
          _ => null,
        };
        if (message == null) return;

        AppMessenger.of(context)
          ..hide()
          ..show(AppMessage(content: Text(FormatHelper.capitalize(message))));
      },
      builder: (BuildContext context, DemoState state) {
        final DemoCubit cubit = context.read<DemoCubit>();
        final DemoCounts? counts = state.counts;

        return AppCard(
          title: s.demoTitle,
          caption: s.demoBody(DemoSeed.password),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (state.status == DemoStatus.failure &&
                  state.failure != null) ...<Widget>[
                InfoBanner.error(state.failure!.message(context)),
                SizedBox(height: 12.h),
              ],

              // What the last run actually touched. A count beats "done":
              // "0 results" is the difference between a write that worked and
              // rules that quietly refused half of it.
              if (counts != null && state.status != DemoStatus.failure)
                ...<Widget>[
                  InfoBanner(
                    icon: state.status == DemoStatus.removed
                        ? Icons.delete_sweep_rounded
                        : Icons.check_circle_outline_rounded,
                    color: state.status == DemoStatus.removed
                        ? AppColors.secondaryText
                        : AppColors.green,
                    message: s.demoCounts(
                      '${counts.members}',
                      '${counts.quizzes}',
                      '${counts.certificates}',
                      '${counts.attempts}',
                      '${counts.cvs}',
                      '${counts.inbox}',
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

              // Wrap, not Row: two buttons and a long Arabic label do not fit
              // side by side on a phone.
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: <Widget>[
                  AppButton(
                    label: s.fillDemo,
                    icon: Icons.auto_awesome_rounded,
                    loading: state.status == DemoStatus.filling,
                    onPressed:
                        state.isBusy ? null : () => cubit.fill(adminUid),
                  ),
                  AppButton(
                    label: s.removeDemo,
                    icon: Icons.delete_outline_rounded,
                    kind: AppButtonKind.danger,
                    loading: state.status == DemoStatus.removing,
                    onPressed:
                        state.isBusy ? null : () => _confirmRemove(context),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                FormatHelper.capitalize(s.demoAccountsHint),
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        );
      },
    );
  }
}
