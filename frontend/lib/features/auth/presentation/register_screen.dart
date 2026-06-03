import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _generateStrongPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@\$!%*?&';
    final random = Random.secure();
    
    // Ensure at least one of each required type
    String lower = 'abcdefghijklmnopqrstuvwxyz'[random.nextInt(26)];
    String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[random.nextInt(26)];
    String number = '0123456789'[random.nextInt(10)];
    String special = '@\$!%*?&'[random.nextInt(7)];
    
    // Fill the rest randomly
    String remaining = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    
    // Shuffle the characters
    List<String> passwordChars = (lower + upper + number + special + remaining).split('');
    passwordChars.shuffle(random);
    
    final newPassword = passwordChars.join('');
    
    setState(() {
      _passCtrl.text = newPassword;
      _obscure = false;
    });
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) context.go('/home');
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
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 20),
                Center(child: Text('Join UB AI 🤖', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))).animate().fadeIn(),
                const SizedBox(height: 8),
                const Center(child: Text('Start your coding journey today', style: TextStyle(color: AppColors.darkTextSecondary))).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),
                TextFormField(controller: _nameCtrl, style: const TextStyle(color: Colors.white),
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppColors.primary)),
                  validator: (v) => v!.isEmpty ? 'Name required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary)),
                  validator: (v) => v!.isEmpty ? 'Email required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _passCtrl, obscureText: _obscure, style: const TextStyle(color: Colors.white),
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Password (strong)',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.darkTextSecondary), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(v)) {
                      return 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char';
                    }
                    return null;
                  }),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _generateStrongPassword,
                    icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                    label: const Text('Generate Strong Password', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 16),
                OwlButton(
                  label: 'Create Account',
                  loading: isLoading,
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      TextInput.finishAutofillContext();
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
          ),
        );
      },
    );
  }
}
