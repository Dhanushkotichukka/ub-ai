import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  UserSettings? get settings => user?.settings;

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    error: error,
  );

  @override List<Object?> get props => [status, user, error];
}

// ─── BLoC ─────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthEmailLoginRequested>(_onEmailLogin);
    on<AuthEmailRegisterRequested>(_onEmailRegister);
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
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repo.loginWithEmail(event.email, event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: _parseError(e)));
    }
  }

  Future<void> _onEmailRegister(AuthEmailRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repo.registerWithEmail(event.name, event.email, event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
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
    final str = e.toString();
    if (str.contains('DioException') || str.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return str.replaceAll('Exception: ', '');
  }
}
