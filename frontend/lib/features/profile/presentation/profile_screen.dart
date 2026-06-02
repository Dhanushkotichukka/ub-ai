import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/hive_keys.dart';
import '../../../shared/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _branchController = TextEditingController();
  final _collegeController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _dreamCompanyController = TextEditingController();
  final _languageController = TextEditingController();

  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _branchController.dispose();
    _collegeController.dispose();
    _cgpaController.dispose();
    _dreamCompanyController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _initFields(UserModel user) {
    _nameController.text = user.name;
    _rollNumberController.text = user.rollNumber;
    _branchController.text = user.branch;
    _collegeController.text = user.college;
    _cgpaController.text = user.cgpa?.toString() ?? '';
    _dreamCompanyController.text = user.dreamCompany;
    _languageController.text = user.preferredLanguage;
  }

  double _getLevelProgress(int level, int xp) {
    if (level >= AppConstants.levelThresholds.length) return 1.0;
    final currentMin = AppConstants.levelThresholds[level - 1];
    final nextMin = AppConstants.levelThresholds[level];
    if (nextMin - currentMin <= 0) return 0.0;
    return ((xp - currentMin) / (nextMin - currentMin)).clamp(0.0, 1.0);
  }

  int _getXpToNextLevel(int level, int xp) {
    if (level >= AppConstants.levelThresholds.length) return 0;
    final nextMin = AppConstants.levelThresholds[level];
    return (nextMin - xp).clamp(0, nextMin);
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updates = {
        'name': _nameController.text.trim(),
        'rollNumber': _rollNumberController.text.trim(),
        'branch': _branchController.text.trim(),
        'college': _collegeController.text.trim(),
        'cgpa': double.tryParse(_cgpaController.text.trim()),
        'dreamCompany': _dreamCompanyController.text.trim(),
        'preferredLanguage': _languageController.text.trim(),
      };

      context.read<AuthBloc>().add(AuthProfileUpdated(updates));
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully! 🎉'), backgroundColor: AppColors.success),
      );
    }
  }

  Map<String, String> _getBadgeDetails(String badgeId) {
    switch (badgeId) {
      case 'onboarding_complete':
        return {'title': 'First Flight', 'emoji': '🥚', 'desc': 'Completed account onboarding'};
      case 'streak_7':
        return {'title': 'Weekly Warrior', 'emoji': '🔥', 'desc': 'Kept a 7-day coding streak'};
      case 'streak_30':
        return {'title': 'Code Master', 'emoji': '🌋', 'desc': 'Kept a 30-day coding streak'};
      case 'solved_50':
        return {'title': 'Solver Elite', 'emoji': '🚀', 'desc': 'Solved 50 total coding problems'};
      case 'solved_200':
        return {'title': 'DSA Champion', 'emoji': '🏆', 'desc': 'Solved 200 total coding problems'};
      default:
        return {'title': badgeId.toUpperCase(), 'emoji': '🏅', 'desc': 'Achievement unlocked!'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState.user != null) {
                _initFields(authState.user!);
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppColors.success),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!_isEditing) {
            _initFields(user);
          }

          final progress = _getLevelProgress(user.level, user.xp);
          final xpNeeded = _getXpToNextLevel(user.level, user.xp);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Header Card
                _buildHeaderCard(user),
                const SizedBox(height: 20),

                // Gamification Section (Level progress, XP, Badges)
                _buildGamificationCard(user, progress, xpNeeded, isDark),
                const SizedBox(height: 24),

                // Form details
                _isEditing ? _buildEditForm(isDark) : _buildProfileDetailsGrid(user, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ).animate().scale(duration: 300.ms),
        const SizedBox(height: 12),
        Text(
          user.name,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          user.email,
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildGamificationCard(UserModel user, double progress, int xpNeeded, bool isDark) {
    final levelName = AppConstants.levelNames[user.level.clamp(1, AppConstants.levelNames.length) - 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🏆 Level ${user.level} — $levelName', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${user.xp} XP', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.round),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          if (xpNeeded > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Solve problems to earn $xpNeeded more XP for Level ${user.level + 1}',
              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat('🔥 Streak', '${user.streak} d'),
              _buildSimpleStat('👑 Longest', '${user.longestStreak} d'),
              _buildSimpleStat('🏆 Badges', '${user.badges.length}'),
            ],
          ),
          const Divider(height: 24),
          const Text('Unlocked Achievements', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (user.badges.isEmpty)
            const Text('No badges unlocked yet. Keep coding!', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12))
          else
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: user.badges.length,
                itemBuilder: (context, index) {
                  final details = _getBadgeDetails(user.badges[index]);
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        Text(details['emoji']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(details['title']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text(details['desc']!, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildProfileDetailsGrid(UserModel user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Information', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildDetailRow('College / University', user.college.isNotEmpty ? user.college : 'Not set'),
          _buildDetailRow('Branch / Specialization', user.branch.isNotEmpty ? user.branch : 'Not set'),
          _buildDetailRow('Roll Number / ID', user.rollNumber.isNotEmpty ? user.rollNumber : 'Not set'),
          _buildDetailRow('Graduation CGPA', user.cgpa != null ? user.cgpa!.toStringAsFixed(2) : 'Not set'),
          _buildDetailRow('Dream Company', user.dreamCompany.isNotEmpty ? user.dreamCompany : 'Not set'),
          _buildDetailRow('Preferred Language', user.preferredLanguage.isNotEmpty ? user.preferredLanguage : 'Not set'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v!.trim().isEmpty ? 'Name cannot be empty' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _collegeController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'College'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _branchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Branch'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rollNumberController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Roll Number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cgpaController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'CGPA'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dreamCompanyController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Dream Company'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _languageController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Preferred Language'),
            ),
          ],
        ),
      ),
    );
  }
}
