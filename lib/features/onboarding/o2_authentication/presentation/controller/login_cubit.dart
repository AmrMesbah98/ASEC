/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: login_cubit.dart
/// Purpose: Declares `LoginCubit` and `LoginState` — sign-in and password
///          reset.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/constants/app_keys.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/network/login_diagnostics.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/auth_failure_type.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/auth_field_error.dart';

enum LoginStatus { idle, submitting, success, resetSent, failure }

class LoginState {
  final LoginStatus status;
  final AuthFailureType? failure;
  final AuthFieldError? emailError;
  final AuthFieldError? passwordError;
  final bool obscure;
  final AppUser? user;

  /// TEMPORARY: the full sign-in diagnostic, printed on the page when the
  /// sign-in is refused. Empty otherwise. See LoginDiagnostics.
  final String diagnostics;

  const LoginState({
    this.status = LoginStatus.idle,
    this.failure,
    this.emailError,
    this.passwordError,
    this.obscure = true,
    this.user,
    this.diagnostics = '',
  });

  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    LoginStatus? status,
    AuthFailureType? failure,
    AuthFieldError? emailError,
    AuthFieldError? passwordError,
    bool? obscure,
    AppUser? user,
    String? diagnostics,
    bool clearErrors = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      failure: clearErrors ? null : (failure ?? this.failure),
      emailError: clearErrors ? null : (emailError ?? this.emailError),
      passwordError: clearErrors ? null : (passwordError ?? this.passwordError),
      obscure: obscure ?? this.obscure,
      user: user ?? this.user,
      diagnostics: clearErrors ? '' : (diagnostics ?? this.diagnostics),
    );
  }
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({AuthBaseRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const LoginState()) {
    // The email they last signed in with — the password is never stored.
    emailController.text = _storage.read(AppKeys.savedEmail) ?? '';
  }

  final AuthBaseRepository _repository;
  final GetStorage _storage = GetStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool get firebaseMissing => AppFirebase.notConfigured;

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure));

  void clearErrors() => emit(state.copyWith(clearErrors: true));

  bool _validate({bool withPassword = true}) {
    final AuthFieldError? emailError =
        AuthFieldError.forEmail(emailController.text);
    final AuthFieldError? passwordError = withPassword
        ? (passwordController.text.isEmpty
            ? AuthFieldError.passwordEmpty
            : null)
        : null;

    emit(LoginState(
      status: LoginStatus.idle,
      emailError: emailError,
      passwordError: passwordError,
      obscure: state.obscure,
    ));
    return emailError == null && passwordError == null;
  }

  Future<void> signIn() async {
    if (state.isSubmitting || !_validate()) return;
    emit(state.copyWith(status: LoginStatus.submitting, clearErrors: true));

    final Either<AuthFailureType, AppUser> result = await _repository.signIn(
      email: emailController.text,
      password: passwordController.text,
    );
    if (isClosed) return;
    result.fold(
      (AuthFailureType failure) => emit(
        state.copyWith(
          status: LoginStatus.failure,
          failure: failure,
          diagnostics: LoginDiagnostics.lastReport,
        ),
      ),
      (AppUser user) {
        _storage.write(AppKeys.savedEmail, emailController.text.trim());
        passwordController.clear();
        emit(state.copyWith(status: LoginStatus.success, user: user));
      },
    );
  }

  /// Sends the reset email. Only the email field is validated — somebody who
  /// has forgotten their password has nothing to put in the other one.
  Future<void> sendReset() async {
    if (state.isSubmitting || !_validate(withPassword: false)) return;
    emit(state.copyWith(status: LoginStatus.submitting, clearErrors: true));

    final Either<AuthFailureType, Unit> result =
        await _repository.sendPasswordReset(emailController.text);
    if (isClosed) return;
    result.fold(
      (AuthFailureType f) =>
          emit(state.copyWith(status: LoginStatus.failure, failure: f)),
      (_) => emit(state.copyWith(status: LoginStatus.resetSent)),
    );
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
