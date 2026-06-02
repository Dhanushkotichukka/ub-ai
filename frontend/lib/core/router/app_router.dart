import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/onboarding/onboarding_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/tracker/presentation/tracker_screen.dart';
import '../../features/topics/presentation/topic_tracker_screen.dart';
import '../../features/plan/presentation/plan_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/notes/presentation/note_editor_screen.dart';
import '../../features/contests/presentation/contests_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/ai_coach/presentation/ai_coach_screen.dart';
import '../../features/placement/presentation/placement_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/revision/presentation/revision_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isOnboarding = !(authState.user?.onboardingComplete ?? true);

      final location = state.uri.toString();

      // Allow splash, login, register always
      if (location.startsWith('/splash') || location.startsWith('/auth')) return null;

      if (!isAuthenticated) return '/auth/login';
      if (isOnboarding && !location.startsWith('/onboarding')) return '/onboarding';

      return null;
    },
    routes: [
      // ─── Splash ──────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ─── Auth ─────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ─── Onboarding ───────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (_, state) {
          final step = int.tryParse(state.uri.queryParameters['step'] ?? '0') ?? 0;
          return OnboardingScreen(initialStep: step);
        },
      ),

      // ─── Main App Shell (Bottom Nav / Sidebar) ────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/', redirect: (_, __) => '/home'),
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/tracker', builder: (_, __) => const TrackerScreen()),
          GoRoute(path: '/topics', builder: (_, __) => const TopicTrackerScreen()),
          GoRoute(path: '/plan', builder: (_, __) => const PlanScreen()),
          GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
          GoRoute(
            path: '/notes/editor',
            builder: (_, state) {
              final noteId = state.uri.queryParameters['id'];
              return NoteEditorScreen(noteId: noteId);
            },
          ),
          GoRoute(path: '/contests', builder: (_, __) => const ContestsScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/ai-coach', builder: (_, __) => const AiCoachScreen()),
          GoRoute(path: '/placement', builder: (_, __) => const PlacementScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/revision', builder: (_, __) => const RevisionScreen()),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
