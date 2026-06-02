import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/di/service_locator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Platform Handles
  final _leetcodeController = TextEditingController();
  final _gfgController = TextEditingController();
  final _codeforcesController = TextEditingController();
  final _codechefController = TextEditingController();
  final _hackerrankController = TextEditingController();
  final _githubController = TextEditingController();

  // Notification toggles
  bool _dailyReminder = true;
  String _dailyReminderTime = '19:00';
  bool _contestReminders = true;
  bool _revisionReminders = true;
  bool _streakWarnings = true;

  // Platform Visibility
  Map<String, bool> _platformVisibility = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _leetcodeController.dispose();
    _gfgController.dispose();
    _codeforcesController.dispose();
    _codechefController.dispose();
    _hackerrankController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final userState = context.read<AuthBloc>().state;
    final user = userState.user;
    if (user != null) {
      _leetcodeController.text = user.platforms.leetcode;
      _gfgController.text = user.platforms.gfg;
      _codeforcesController.text = user.platforms.codeforces;
      _codechefController.text = user.platforms.codechef;
      _hackerrankController.text = user.platforms.hackerrank;
      _githubController.text = user.platforms.github;

      final s = user.settings;
      _dailyReminder = s.notifications.dailyReminder;
      _dailyReminderTime = s.notifications.dailyReminderTime;
      _contestReminders = s.notifications.contestReminders;
      _revisionReminders = s.notifications.revisionReminders;
      _streakWarnings = s.notifications.streakWarnings;

      _platformVisibility = Map<String, bool>.from(s.platformVisibility);
    }
  }

  Future<void> _updateSettings({bool? darkMode}) async {
    setState(() => _saving = true);
    final userState = context.read<AuthBloc>().state;
    final s = userState.user?.settings;

    final settingsData = {
      'darkMode': darkMode ?? s?.darkMode ?? true,
      'notifications': {
        'dailyReminder': _dailyReminder,
        'dailyReminderTime': _dailyReminderTime,
        'contestReminders': _contestReminders,
        'revisionReminders': _revisionReminders,
        'streakWarnings': _streakWarnings,
      },
      'platformVisibility': _platformVisibility,
    };

    try {
      await sl<ApiService>().put('/user/settings', data: settingsData);
      if (mounted) {
        // Refresh AuthBloc user settings
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePlatformHandles() async {
    setState(() => _saving = true);
    final handles = {
      'leetcode': _leetcodeController.text.trim(),
      'gfg': _gfgController.text.trim(),
      'codeforces': _codeforcesController.text.trim(),
      'codechef': _codechefController.text.trim(),
      'hackerrank': _hackerrankController.text.trim(),
      'github': _githubController.text.trim(),
    };

    try {
      context.read<AuthBloc>().add(AuthPlatformsUpdated(handles));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Platform usernames updated! Syncing in progress... ⏳'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update platforms: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppColors.danger)),
        content: const Text(
          'WARNING: This will permanently delete your account, coding streaks, XP, custom notes, and all custom data. This action CANNOT be undone.\n\nAre you absolutely sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _saving = true);
      try {
        await sl<ApiService>().delete('/user/account');
        if (mounted) {
          context.read<AuthBloc>().add(AuthLogoutRequested());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e'), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform Coding Profiles
                _buildSectionHeader('Coding Handles / Profiles'),
                _buildPlatformHandlesCard(isDark),
                const SizedBox(height: 24),

                // Theme & Customization
                _buildSectionHeader('Theme & Visuals'),
                _buildThemeCard(user, isDark),
                const SizedBox(height: 24),

                // Platform Visibility settings
                _buildSectionHeader('Platform Dashboard Visibility'),
                _buildPlatformVisibilityCard(isDark),
                const SizedBox(height: 24),

                // Notification Preferences
                _buildSectionHeader('Notification Preferences'),
                _buildNotificationsCard(isDark),
                const SizedBox(height: 32),

                // Destructive Actions
                _buildLogoutCard(isDark),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPlatformHandlesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildUsernameField('LeetCode', _leetcodeController, const Color(0xFFFFA116)),
            const SizedBox(height: 12),
            _buildUsernameField('GeeksforGeeks', _gfgController, const Color(0xFF2F8D46)),
            const SizedBox(height: 12),
            _buildUsernameField('Codeforces', _codeforcesController, const Color(0xFF1F8ACB)),
            const SizedBox(height: 12),
            _buildUsernameField('CodeChef', _codechefController, const Color(0xFF8B4513)),
            const SizedBox(height: 12),
            _buildUsernameField('HackerRank', _hackerrankController, const Color(0xFF2EC866)),
            const SizedBox(height: 12),
            _buildUsernameField('GitHub', _githubController, const Color(0xFF333333)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePlatformHandles,
                child: const Text('Update Usernames & Sync'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField(String label, TextEditingController controller, Color color) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withValues(alpha: 0.8)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildThemeCard(UserModel user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: const Text('Dark Mode', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: const Text('Enable standard dark interface', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
        value: user.settings.darkMode,
        activeThumbColor: AppColors.primary,
        onChanged: (val) {
          _updateSettings(darkMode: val);
        },
      ),
    );
  }

  Widget _buildPlatformVisibilityCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        children: _platformVisibility.keys.map((platform) {
          final isVisible = _platformVisibility[platform] ?? false;
          return CheckboxListTile(
            title: Text(
              platform.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Show on main dashboard', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
            value: isVisible,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _platformVisibility[platform] = val ?? false;
              });
              _updateSettings();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Daily Study Reminder', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('Get reminded to solve your POTD at $_dailyReminderTime', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
            value: _dailyReminder,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _dailyReminder = val);
              _updateSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Upcoming Contests Alerts', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Get notified 1 hour before registered contests', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
            value: _contestReminders,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _contestReminders = val);
              _updateSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Revision Schedule Due Reminder', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Spaced repetition due problems notifications', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
            value: _revisionReminders,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _revisionReminders = val);
              _updateSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Streak Freeze Alerts', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Get warned at 10 PM if streak is in danger', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
            value: _streakWarnings,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _streakWarnings = val);
              _updateSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            child: const Text('Logout Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _deleteAccount,
            child: const Text('Delete Account & Data', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
