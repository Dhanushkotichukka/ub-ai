import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/owl_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _isEmailMode = false;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          if (!(state.user?.onboardingComplete ?? true)) {
            context.go('/onboarding');
          } else {
            context.go('/home');
          }
        } else if (state.status == AuthStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: AppColors.danger),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // ─── Logo ──────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: AppShadow.glow,
                            ),
                            child: const Center(child: Text('🦉', style: TextStyle(fontSize: 42))),
                          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 20),
                          Text('OwlCoder AI',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w800,
                            )).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 6),
                          Text('Your Placement Growth OS',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkTextSecondary,
                            )).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    if (!_isEmailMode) ...[
                      // ─── Google Sign In ────────────────────────────
                      _GoogleButton(
                        loading: isLoading,
                        onTap: () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

                      const SizedBox(height: 16),

                      const Row(children: [
                        Expanded(child: Divider(color: AppColors.darkBorder)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or', style: TextStyle(color: AppColors.darkTextSecondary)),
                        ),
                        Expanded(child: Divider(color: AppColors.darkBorder)),
                      ]).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 16),

                      OutlinedButton(
                        onPressed: () => setState(() => _isEmailMode = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.darkBorder),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.email_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Continue with Email'),
                        ]),
                      ).animate().fadeIn(delay: 550.ms),
                    ] else ...[
                      // ─── Email / Password Form ─────────────────────
                      Form(
                        key: _formKey,
                        child: Column(children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                            ),
                            validator: (v) => v!.isEmpty ? 'Email required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.darkTextSecondary),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Password required' : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OwlButton(
                            label: 'Sign In',
                            loading: isLoading,
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  AuthEmailLoginRequested(_emailCtrl.text.trim(), _passCtrl.text),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() => _isEmailMode = false),
                            child: const Text('← Back', style: TextStyle(color: AppColors.darkTextSecondary)),
                          ),
                        ]),
                      ).animate().fadeIn(duration: 300.ms),
                    ],

                    const SizedBox(height: 32),

                    // ─── Register Link ─────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/auth/register'),
                        child: RichText(text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppColors.darkTextSecondary),
                          children: [TextSpan(text: 'Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))],
                        )),
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (loading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else ...[
              const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
              const SizedBox(width: 12),
              const Text('Continue with Google', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ]),
        ),
      ),
    );
  }
}
