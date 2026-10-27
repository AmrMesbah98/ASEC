/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: sign_in_screen.dart
/// Purpose: Declares `SignInScreen` — one sign-in for the admin and every
///          member.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/login_cubit.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/pages/register_screen.dart';
import 'package:asec/features/tools/t1_unit_converter/presentation/ui/pages/unit_converter_page.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/auth_layout.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:get/get.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginCubit>(
      create: (_) => LoginCubit(),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (LoginState a, LoginState b) => a.status != b.status,
        listener: (BuildContext context, LoginState state) {
          if (state.status == LoginStatus.success && state.user != null) {
            AppRouter.go(context, state.user);
          }
          if (state.status == LoginStatus.resetSent) {
            AppMessenger.of(context).show(
              AppMessage(content: Text(FormatHelper.capitalize(S.of(context).resetEmailSent))),
            );
          }
        },
        child: const AuthLayout(
          illustration: AppAssets.illustrationLogin,
          fitToScreen: true,
          form: _SignInForm(),
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final LoginCubit cubit = context.read<LoginCubit>();

    return BlocBuilder<LoginCubit, LoginState>(
      builder: (BuildContext context, LoginState state) {
        // A failure that belongs under a field is shown there, not twice.
        final String? bannerMessage = state.failure == null ||
                state.failure!.isEmailError ||
                state.failure!.isPasswordError
            ? null
            : state.failure!.message(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(FormatHelper.capitalize(s.welcomeBack), style: StyleText.fontSize25Weight600),
            SizedBox(height: 6.h),
            Text(
              FormatHelper.capitalize(s.signInSubtitle),
              style: StyleText.fontSize14Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
            SizedBox(height: 24.h),
            if (AppFirebase.notConfigured) ...<Widget>[
              InfoBanner.error(s.errNotConfigured),
              SizedBox(height: 16.h),
            ],
            if (bannerMessage != null) ...<Widget>[
              InfoBanner.error(bannerMessage),
              SizedBox(height: 16.h),
            ],
            // TEMPORARY — remove with LoginDiagnostics.
            if (state.diagnostics.isNotEmpty) ...<Widget>[
              _DiagnosticsPanel(report: state.diagnostics),
              SizedBox(height: 16.h),
            ],
            CustomTextField(
              controller: cubit.emailController,
              fillColor: AppColors.card,
              label: s.email,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: state.emailError?.message(context) ??
                  (state.failure != null && state.failure!.isEmailError
                      ? state.failure!.message(context)
                      : null),
              prefixIcon: const AppIcon(Icons.alternate_email_rounded),
            ),
            SizedBox(height: 14.h),
            CustomTextField(
              controller: cubit.passwordController,
              label: s.password,
              fillColor: AppColors.card,
              hint: '••••••',
              obscureText: state.obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => cubit.signIn(),
              errorText: state.passwordError?.message(context) ??
                  (state.failure != null && state.failure!.isPasswordError
                      ? state.failure!.message(context)
                      : null),
              prefixIcon: const AppIcon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: cubit.toggleObscure,
                icon: AppIcon(state.obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: state.isSubmitting ? null : cubit.sendReset,
                child: Text(
                  FormatHelper.capitalize(s.forgotPassword),
                  style: StyleText.fontSize13Weight600
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            AppButton(
              label: s.signIn,
              icon: Icons.login_rounded,
              expand: true,
              loading: state.isSubmitting,
              onPressed: AppFirebase.notConfigured ? null : cubit.signIn,
            ),
            SizedBox(height: 14.h),
            Obx(() => !AppFeatures.to.isOn(AppFeature.registration)
                ? const SizedBox.shrink()
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(
                    FormatHelper.capitalize(s.noAccount),
                    style: StyleText.fontSize13Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ),
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                  child: Text(
                    FormatHelper.capitalize(s.register),
                    style: StyleText.fontSize13Weight600
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            )),
            // No sign-in, no internet needed: the converter is always here.
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UnitConverterPage(standalone: true),
                  ),
                ),
                icon: Icon(Icons.calculate_rounded, color: AppColors.primary, size: 20),
                label: Text(
                  FormatHelper.capitalize(s.openUnitConverter),
                  style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary),
                ),
              ),
            ),
            Text(
              FormatHelper.capitalize(s.signInAsAdminHint),
              textAlign: TextAlign.center,
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
            const AuthFooter(),
          ],
        );
      },
    );
  }
}


/// TEMPORARY: prints the whole sign-in diagnostic so it can be read or
/// copied. Remove together with LoginDiagnostics once the cause is fixed.
class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({required this.report});

  final String report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.containerR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Diagnostic report',
                  style: StyleText.fontSize13Weight500
                      .copyWith(color: AppColors.onChip),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: report));
                  if (context.mounted) {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Report copied')),
                    );
                  }
                },
                icon: Icon(Icons.copy_rounded, size: 16.sp),
                label: const Text('Copy'),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 320.h),
            child: SingleChildScrollView(
              child: SelectableText(
                report,
                style: StyleText.fontSize11Weight400.copyWith(
                  color: AppColors.onChip,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
