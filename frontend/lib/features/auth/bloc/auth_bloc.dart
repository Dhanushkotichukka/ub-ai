import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';
import '../../../shared/models/user_model.dart';

// ─── Events ───────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthEmailLoginRequested extends AuthEvent {
  final String email, password;
  const AuthEmailLoginRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}

class AuthEmailRegisterRequested extends AuthEvent {
  final String name, email, password;
  const AuthEmailRegisterRequested(this.name, this.email, this.password);
  @override List<Object?> get props => [name, email, password];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String email, otp;
  const AuthVerifyOtpRequested(this.email, this.otp);
  @override List<Object?> get props => [email, otp];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested(this.email);
  @override List<Object?> get props => [email];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email, otp, newPassword;
  const AuthResetPasswordRequested(this.email, this.otp, this.newPassword);
  @override List<Object?> get props => [email, otp, newPassword];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdated extends AuthEvent {
  final Map<String, dynamic> data;
  const AuthProfileUpdated(this.data);
  @override List<Object?> get props => [data];
}

class AuthOnboardingStepCompleted extends AuthEvent {
  final int step;
  final bool complete;
  final Map<String, dynamic>? data;
  const AuthOnboardingStepCompleted(this.step, {this.complete = false, this.data});
  @override List<Object?> get props => [step, complete, data];
}

class AuthPlatformsUpdated extends AuthEvent {
  final Map<String, String> platforms;
  const AuthPlatformsUpdated(this.platforms);
  @override List<Object?> get props => [platforms];
}

// ─── States ───────────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool requiresVerification;
  final String? unverifiedEmail;
  final bool otpSent;
  final bool passwordResetSuccess;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.requiresVerification = false,
    this.unverifiedEmail,
    this.otpSent = false,
    this.passwordResetSuccess = false,
  });

  UserSettings? get settings => user?.settings;

  AuthState copyWith({
    AuthStatus? status, 
    UserModel? user, 
    String? error, 
    bool? requiresVerification, 
    String? unverifiedEmail,
    bool? otpSent,
    bool? passwordResetSuccess,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    error: error,
    requiresVerification: requiresVerification ?? this.requiresVerification,
    unverifiedEmail: unverifiedEmail ?? this.unverifiedEmail,
    otpSent: otpSent ?? this.otpSent,
    passwordResetSuccess: passwordResetSuccess ?? this.passwordResetSuccess,
  );

  @override List<Object?> get props => [status, user, error, requiresVerification, unverifiedEmail, otpSent, passwordResetSuccess];
}

// ─── BLoC ─────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: '558989588027-matak7anvgcmfm6a8incnj0kkal1auc9.apps.googleusercontent.com',
  );

  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthEmailLoginRequested>(_onEmailLogin);
    on<AuthEmailRegisterRequested>(_onEmailRegister);
    on<AuthVerifyOtpRequested>(_onVerifyOtp);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdated>(_onProfileUpdated);
    on<AuthOnboardingStepCompleted>(_onOnboardingStep);
    on<AuthPlatformsUpdated>(_onPlatformsUpdated);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.getStoredUser();
      if (user != null) {
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
        // Refresh from API in background
        try {
          final fresh = await _repo.getCurrentUser();
          emit(state.copyWith(user: fresh));
        } catch (_) {}
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onGoogleSignIn(AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');

      final user = await _repo.loginWithGoogle(idToken);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  Future<void> _onEmailLogin(AuthEmailLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null, requiresVerification: false));
    try {
      final user = await _repo.loginWithEmail(event.email, event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      final errorMsg = _parseError(e);
      if (errorMsg == 'requiresVerification') {
        emit(state.copyWith(status: AuthStatus.error, error: 'Please verify your email first', requiresVerification: true, unverifiedEmail: event.email));
      } else {
        emit(state.copyWith(status: AuthStatus.error, error: errorMsg));
      }
    }
  }

  Future<void> _onEmailRegister(AuthEmailRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null, requiresVerification: false));
    try {
      await _repo.registerWithEmail(event.name, event.email, event.password);
      emit(state.copyWith(status: AuthStatus.unauthenticated, requiresVerification: true, unverifiedEmail: event.email));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: _parseError(e)));
    }
  }

  Future<void> _onVerifyOtp(AuthVerifyOtpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    try {
      await _repo.verifyOtp(event.email, event.otp);
      emit(state.copyWith(status: AuthStatus.unauthenticated, requiresVerification: false, error: 'Verified! Please log in.'));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: _parseError(e), requiresVerification: true));
    }
  }

  Future<void> _onForgotPassword(AuthForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null, otpSent: false));
    try {
      await _repo.forgotPassword(event.email);
      emit(state.copyWith(status: AuthStatus.unauthenticated, otpSent: true, unverifiedEmail: event.email));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: _parseError(e)));
    }
  }

  Future<void> _onResetPassword(AuthResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null, passwordResetSuccess: false));
    try {
      await _repo.resetPassword(event.email, event.otp, event.newPassword);
      emit(state.copyWith(status: AuthStatus.unauthenticated, passwordResetSuccess: true, otpSent: false, error: 'Password reset successful!'));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: _parseError(e)));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repo.logout();
    await _googleSignIn.signOut().catchError((_) => null);
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onProfileUpdated(AuthProfileUpdated event, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.updateProfile(event.data);
      emit(state.copyWith(user: user));
    } catch (e) {
      emit(state.copyWith(error: _parseError(e)));
    }
  }

  Future<void> _onOnboardingStep(AuthOnboardingStepCompleted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.updateOnboarding(
        step: event.step,
        complete: event.complete,
        data: event.data,
      );
      emit(state.copyWith(user: user));
    } catch (e) {
      emit(state.copyWith(error: _parseError(e)));
    }
  }

  Future<void> _onPlatformsUpdated(AuthPlatformsUpdated event, Emitter<AuthState> emit) async {
    try {
      await _repo.updatePlatforms(event.platforms);
      final user = await _repo.getCurrentUser();
      emit(state.copyWith(user: user));
    } catch (e) {
      emit(state.copyWith(error: _parseError(e)));
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response?.data != null) {
        dynamic data = e.response?.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map && data.containsKey('message')) {
          if (data['requiresVerification'] == true) {
            return 'requiresVerification';
          }
          return data['message'].toString();
        }
      }
      return 'Network error. Check your connection.';
    }
    
    final str = e.toString();
    if (str.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return str.replaceAll('Exception: ', '');
  }
}
