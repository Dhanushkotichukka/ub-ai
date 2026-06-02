import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/owl_button.dart';
import '../../auth/bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) context.go('/onboarding');
        if (state.requiresVerification && state.unverifiedEmail != null) {
          context.go('/auth/verify-otp?email=${Uri.encodeComponent(state.unverifiedEmail!)}');
        }
        if (state.status == AuthStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: AppColors.danger));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: AppBar(
            backgroundColor: AppColors.darkBg,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.go('/auth/login')),
            title: const Text('Create Account', style: TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 20),
                Center(child: Text('Join OwlCoder AI 🦉', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))).animate().fadeIn(),
                const SizedBox(height: 8),
                const Center(child: Text('Start your coding journey today', style: TextStyle(color: AppColors.darkTextSecondary))).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),
                TextFormField(controller: _nameCtrl, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppColors.primary)),
                  validator: (v) => v!.isEmpty ? 'Name required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary)),
                  validator: (v) => v!.isEmpty ? 'Email required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _passCtrl, obscureText: _obscure, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password (min 8 chars)',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.darkTextSecondary), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                  validator: (v) => v!.length < 8 ? 'Min 8 characters' : null),
                const SizedBox(height: 24),
                OwlButton(
                  label: 'Create Account',
                  loading: isLoading,
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(AuthEmailRegisterRequested(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text));
                    }
                  },
                ),
                const SizedBox(height: 20),
                Center(child: TextButton(
                  onPressed: () => context.go('/auth/login'),
                  child: RichText(text: const TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: AppColors.darkTextSecondary),
                    children: [TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))],
                  )),
                )),
              ]),
            ),
          ),
        );
      },
    );
  }
}
