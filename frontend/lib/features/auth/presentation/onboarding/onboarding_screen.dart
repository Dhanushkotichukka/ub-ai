import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/owl_button.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../../core/constants/hive_keys.dart';

class OnboardingScreen extends StatefulWidget {
  final int initialStep;
  const OnboardingScreen({super.key, this.initialStep = 0});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _step;
  final _pageCtrl = PageController();

  // Step 2 — Purpose
  String? _purpose;
  // Step 3 — Profile
  final _rollCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  String? _branch, _dreamCompany, _language;
  final _cgpaCtrl = TextEditingController();
  // Step 4 — Platforms
  final _lcCtrl = TextEditingController();
  final _gfgCtrl = TextEditingController();
  final _cfCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _ghCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  void _nextStep() {
    if (_step < 4) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: 400.ms, curve: Curves.easeInOut);
    } else {
      _complete();
    }
  }

  void _complete() {
    context.read<AuthBloc>().add(const AuthOnboardingStepCompleted(4, complete: true));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: [
              // Progress bar
              Row(children: List.generate(5, (i) => Expanded(
                child: Container(
                  height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.primary : AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                ).animate(target: i <= _step ? 1 : 0).custom(builder: (_, v, c) => c),
              ))),
              const SizedBox(height: 8),
              Text('Step ${_step + 1} of 5', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
            ]),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _WelcomeStep(onNext: _nextStep),
              _PurposeStep(selected: _purpose, onSelect: (p) => setState(() => _purpose = p), onNext: _nextStep),
              _ProfileStep(rollCtrl: _rollCtrl, phoneCtrl: _phoneCtrl, collegeCtrl: _collegeCtrl, cgpaCtrl: _cgpaCtrl,
                branch: _branch, dreamCompany: _dreamCompany, language: _language,
                onBranchChanged: (v) => setState(() => _branch = v),
                onDreamChanged: (v) => setState(() => _dreamCompany = v),
                onLangChanged: (v) => setState(() => _language = v),
                onNext: () {
                  context.read<AuthBloc>().add(AuthOnboardingStepCompleted(2, data: {
                    'rollNumber': _rollCtrl.text, 'phone': _phoneCtrl.text,
                    'college': _collegeCtrl.text, 'branch': _branch,
                    'dreamCompany': _dreamCompany, 'preferredLanguage': _language,
                    'cgpa': double.tryParse(_cgpaCtrl.text),
                    'appPurpose': _purpose,
                  }));
                  _nextStep();
                }),
              _PlatformsStep(lcCtrl: _lcCtrl, gfgCtrl: _gfgCtrl, cfCtrl: _cfCtrl, ccCtrl: _ccCtrl, ghCtrl: _ghCtrl,
                onNext: () {
                  context.read<AuthBloc>().add(AuthPlatformsUpdated({
                    'leetcode': _lcCtrl.text, 'gfg': _gfgCtrl.text,
                    'codeforces': _cfCtrl.text, 'codechef': _ccCtrl.text, 'github': _ghCtrl.text,
                  }));
                  _nextStep();
                }),
              _ReadyStep(onComplete: _complete),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Step 1: Welcome ─────────────────────────────────────────────
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 120, height: 120,
          child: Image.asset('assets/images/ub_ai_mascot.png', fit: BoxFit.contain),
        ).animate(onPlay: (c) => c.repeat())
          .moveY(begin: 0, end: -10, duration: 1800.ms, curve: Curves.easeInOut)
          .then()
          .moveY(begin: -10, end: 0, duration: 1800.ms, curve: Curves.easeInOut)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 32),
        Text('Welcome to\nUB AI', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        const Text('Your coding journey starts now.\nTrack DSA, crack placements, and grow every day.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16)).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 48),
        OwlButton(label: 'Get Started →', onTap: onNext).animate().fadeIn(delay: 600.ms),
      ]),
    );
  }
}

// ─── Step 2: Purpose ─────────────────────────────────────────────
class _PurposeStep extends StatelessWidget {
  final String? selected;
  final Function(String) onSelect;
  final VoidCallback onNext;
  const _PurposeStep({required this.selected, required this.onSelect, required this.onNext});

  static const _purposes = [
    ('study_dsa', '📚', 'Study & Learn DSA'),
    ('placement', '🎯', 'Placement Preparation'),
    ('competitive', '🏆', 'Competitive Programming'),
    ('job_switch', '💼', 'Job Switch / Upskilling'),
    ('college', '🎓', 'College Assignments'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What brings you here?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)).animate().fadeIn(),
        const SizedBox(height: 8),
        const Text('This helps us personalize your experience', style: TextStyle(color: AppColors.darkTextSecondary)).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _purposes.length,
            itemBuilder: (_, i) {
              final (id, emoji, label) = _purposes[i];
              final isSelected = selected == id;
              return GestureDetector(
                onTap: () => onSelect(id),
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.darkBorder, width: isSelected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    const Spacer(),
                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                  ]),
                ),
              ).animate(delay: (i * 80).ms).fadeIn().slideX(begin: 0.3);
            },
          ),
        ),
        const SizedBox(height: 16),
        OwlButton(label: 'Continue', onTap: selected != null ? onNext : null),
      ]),
    );
  }
}

// ─── Step 3: Profile ─────────────────────────────────────────────
class _ProfileStep extends StatelessWidget {
  final TextEditingController rollCtrl, phoneCtrl, collegeCtrl, cgpaCtrl;
  final String? branch, dreamCompany, language;
  final Function(String?) onBranchChanged, onDreamChanged, onLangChanged;
  final VoidCallback onNext;

  const _ProfileStep({required this.rollCtrl, required this.phoneCtrl, required this.collegeCtrl, required this.cgpaCtrl,
    this.branch, this.dreamCompany, this.language,
    required this.onBranchChanged, required this.onDreamChanged, required this.onLangChanged, required this.onNext});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white);
    const labelColor = AppColors.primary;

    Widget field(String label, TextEditingController ctrl, {TextInputType? type}) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: TextFormField(controller: ctrl, style: textStyle, keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.edit_outlined, color: labelColor, size: 18))));

    Widget dropdown(String label, List<String> items, String? value, Function(String?) onChange) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: DropdownButtonFormField<String>(
        initialValue: value, onChanged: onChange,
        style: textStyle,
        dropdownColor: AppColors.darkCard,
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.arrow_drop_down, color: labelColor, size: 18)),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: textStyle))).toList(),
      ));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Complete your profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)).animate().fadeIn(),
        const SizedBox(height: 24),
        field('Roll Number (e.g. 23A91A0507)', rollCtrl),
        field('Phone Number', phoneCtrl, type: TextInputType.phone),
        field('College Name', collegeCtrl),
        field('Current CGPA', cgpaCtrl, type: TextInputType.number),
        dropdown('Branch', AppConstants.branches, branch, onBranchChanged),
        dropdown('Dream Company', AppConstants.dreamCompanies, dreamCompany, onDreamChanged),
        dropdown('Preferred Language', AppConstants.languages, language, onLangChanged),
        const SizedBox(height: 8),
        OwlButton(label: 'Continue', onTap: onNext),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: onNext, child: const Text('Skip for now', style: TextStyle(color: AppColors.darkTextSecondary)))),
      ]),
    );
  }
}

// ─── Step 4: Platform Profiles ───────────────────────────────────
class _PlatformsStep extends StatelessWidget {
  final TextEditingController lcCtrl, gfgCtrl, cfCtrl, ccCtrl, ghCtrl;
  final VoidCallback onNext;
  const _PlatformsStep({required this.lcCtrl, required this.gfgCtrl, required this.cfCtrl, required this.ccCtrl, required this.ghCtrl, required this.onNext});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white);
    Widget field(String emoji, String label, TextEditingController ctrl) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(controller: ctrl, style: textStyle,
        decoration: InputDecoration(labelText: label, prefixIcon: Padding(padding: const EdgeInsets.all(12), child: Text(emoji, style: const TextStyle(fontSize: 18))))));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Connect your platforms', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)).animate().fadeIn(),
        const SizedBox(height: 6),
        const Text('We\'ll fetch your stats automatically', style: TextStyle(color: AppColors.darkTextSecondary)).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        field('🟡', 'LeetCode Username', lcCtrl),
        field('🟢', 'GFG Username', gfgCtrl),
        field('🔵', 'Codeforces Handle', cfCtrl),
        field('🟠', 'CodeChef ID', ccCtrl),
        field('⬛', 'GitHub Username', ghCtrl),
        const SizedBox(height: 16),
        OwlButton(label: 'Fetch Stats & Continue', onTap: onNext),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: onNext, child: const Text('Skip for now', style: TextStyle(color: AppColors.darkTextSecondary)))),
      ]),
    );
  }
}

// ─── Step 5: Ready ───────────────────────────────────────────────
class _ReadyStep extends StatelessWidget {
  final VoidCallback onComplete;
  const _ReadyStep({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎉', style: TextStyle(fontSize: 80)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 32),
        Text('You\'re all set!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        const Text('Your UB AI profile is ready.\nStart solving, tracking, and leveling up!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16)).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 48),
        OwlButton(label: 'Let\'s Go! 🚀', onTap: onComplete).animate().fadeIn(delay: 600.ms),
      ]),
    );
  }
}
