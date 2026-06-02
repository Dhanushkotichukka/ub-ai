import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          if (!(state.user?.onboardingComplete ?? true)) {
            context.go('/onboarding');
          } else {
            context.go('/home');
          }
        } else if (state.status == AuthStatus.unauthenticated) {
          context.go('/auth/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Owl logo
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppShadow.glow,
                  ),
                  child: const Center(
                    child: Text('🦉', style: TextStyle(fontSize: 52)),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                Text(
                  'OwlCoder AI',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.3),

                const SizedBox(height: 8),

                Text(
                  'Track • Practice • Learn • Plan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 60),

                SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
