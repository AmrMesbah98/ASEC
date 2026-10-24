/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: register_screen.dart
/// Purpose: Declares `RegisterScreen` — anybody can create a member account.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/register_cubit.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/auth_layout.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterCubit>(
      create: (_) => RegisterCubit(),
      child: BlocListener<RegisterCubit, RegisterState>(
        listenWhen: (RegisterState a, RegisterState b) => a.status != b.status,
        listener: (BuildContext context, RegisterState state) {
          if (state.status == RegisterStatus.success && state.user != null) {
            // Straight in: they are already signed in to Firebase Auth.
            AppRouter.go(context, state.user);
          }
        },
        child: const AuthLayout(
          illustration: AppAssets.illustrationLearning,
          // Fits the screen, no scrolling. The small header leaves the five
          // fields more room, so they are shrunk less than under the big one.
          fitToScreen: true,
          compactHeader: true,
          form: _RegisterForm(),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final RegisterCubit cubit = context.read<RegisterCubit>();

    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (BuildContext context, RegisterState state) {
        final String? bannerMessage = state.failure == null ||
                state.failure!.isEmailError ||
                state.failure!.isPasswordError
            ? null
            : state.failure!.message(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AppIcon(Icons.arrow_back_rounded),
                    tooltip: s.backToSignIn,
                  ),
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(s.createYourAccount),
                    style: StyleText.fontSize25Weight600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              FormatHelper.capitalize(s.registerSubtitle),
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
            CustomTextField(
              controller: cubit.nameController,
              label: s.fullName,
              hint: s.fullNameHint,
              fillColor: AppColors.card,
              required: true,
              textInputAction: TextInputAction.next,
              errorText: state.nameError?.message(context),
              prefixIcon: const AppIcon(Icons.person_outline_rounded),
            ),
            SizedBox(height: 14.h),
            CustomTextField(
              controller: cubit.emailController,
              label: s.email,
              hint: 'name@example.com',
              fillColor: AppColors.card,
              required: true,
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
              controller: cubit.phoneController,
              label: s.phone,
              hint: s.phoneHint,
              fillColor: AppColors.card,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefixIcon: const AppIcon(Icons.phone_iphone_rounded),
            ),
            SizedBox(height: 14.h),
            CustomTextField(
              controller: cubit.passwordController,
              label: s.password,
              hint: '••••••',
              fillColor: AppColors.card,
              required: true,
              obscureText: state.obscure,
              textInputAction: TextInputAction.next,
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
            SizedBox(height: 14.h),
            CustomTextField(
              controller: cubit.confirmController,
              label: s.confirmPassword,
              hint: '••••••',
              fillColor: AppColors.card,
              required: true,
              obscureText: state.obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => cubit.submit(),
              errorText: state.confirmError?.message(context),
              prefixIcon: const AppIcon(Icons.lock_outline_rounded),
            ),
            SizedBox(height: 20.h),
            AppButton(
              label: s.register,
              icon: Icons.person_add_alt_1_rounded,
              expand: true,
              loading: state.isSubmitting,
              onPressed: AppFirebase.notConfigured ? null : cubit.submit,
            ),
            SizedBox(height: 12.h),
            Text(
              FormatHelper.capitalize(s.registerHint),
              textAlign: TextAlign.center,
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(
                    FormatHelper.capitalize(s.haveAccount),
                    style: StyleText.fontSize13Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ),
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(
                    FormatHelper.capitalize(s.signIn),
                    style: StyleText.fontSize13Weight600
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const AuthFooter(),
          ],
        );
      },
    );
  }
}
