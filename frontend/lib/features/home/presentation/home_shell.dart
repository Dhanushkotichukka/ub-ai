import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _mobileTabs = [
    ('/home', Icons.home_rounded, Icons.home_outlined, 'Home'),
    ('/tracker', Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Tracker'),
    ('/plan', Icons.calendar_today_rounded, Icons.calendar_today_outlined, 'Plan'),
    ('/notes', Icons.edit_note_rounded, Icons.edit_note_outlined, 'Space'),
    ('/profile', Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  bool get _isWide => MediaQuery.of(context).size.width > 800;

  @override
  Widget build(BuildContext context) {
    if (_isWide) return _WebLayout(child: widget.child);
    return _MobileLayout(
      currentIndex: _currentIndex,
      onTabChanged: (i) {
        setState(() => _currentIndex = i);
        context.go(_mobileTabs[i].$1);
      },
      child: widget.child,
    );
  }
}

// ─── Mobile Bottom Nav Layout ─────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onTabChanged;

  const _MobileLayout({required this.child, required this.currentIndex, required this.onTabChanged});

  static const _tabs = [
    ('/home', Icons.home_rounded, Icons.home_outlined, 'Home'),
    ('/tracker', Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Tracker'),
    ('/plan', Icons.calendar_today_rounded, Icons.calendar_today_outlined, 'Plan'),
    ('/notes', Icons.edit_note_rounded, Icons.edit_note_outlined, 'Space'),
    ('/profile', Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final (_, activeIcon, inactiveIcon, label) = _tabs[i];
                final isSelected = currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChanged(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.round),
                          ),
                          child: Icon(isSelected ? activeIcon : inactiveIcon,
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            size: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(label, style: TextStyle(
                          fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        )),
                      ]),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Web Sidebar Layout ───────────────────────────────────────────
class _WebLayout extends StatelessWidget {
  final Widget child;
  const _WebLayout({required this.child});

  static const _items = [
    ('/home', Icons.home_rounded, 'Home'),
    ('/tracker', Icons.bar_chart_rounded, 'Daily Tracker'),
    ('/topics', Icons.topic_rounded, 'Topic Tracker'),
    ('/plan', Icons.calendar_today_rounded, 'Plan / Roadmap'),
    ('/notes', Icons.edit_note_rounded, 'Notes Space'),
    ('/contests', Icons.emoji_events_rounded, 'Contests'),
    ('/placement', Icons.work_rounded, 'Placement Hub'),
    ('/analytics', Icons.analytics_rounded, 'Analytics'),
    ('/ai-coach', Icons.psychology_rounded, 'AI Coach'),
    ('/settings', Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: Row(children: [
        // ─── Sidebar ──────────────────────────────────────────────
        Container(
          width: 220,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            border: Border(right: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200)),
          ),
          child: Column(children: [
            const SizedBox(height: 24),
            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🦉', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Text('OwlCoder AI', style: TextStyle(color: isDark ? Colors.white : AppColors.lightText, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 24),
            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final (path, icon, label) = _items[i];
                  final isSelected = location.startsWith(path) && (path != '/' || location == '/');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      onTap: () => context.go(path),
                      leading: Icon(icon, size: 20, color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      title: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText))),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                  );
                },
              ),
            ),
            // User profile at bottom
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state.user;
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: user?.profilePic.isNotEmpty == true ? NetworkImage(user!.profilePic) : null,
                      backgroundColor: AppColors.primary,
                      child: user?.profilePic.isEmpty != false ? Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 14)) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.name ?? 'User', style: TextStyle(color: isDark ? Colors.white : AppColors.lightText, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Lv.${user?.level ?? 1} • ${user?.xp ?? 0} XP', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10)),
                    ])),
                  ]),
                );
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
        // ─── Content ──────────────────────────────────────────────
        Expanded(child: child),
      ]),
    );
  }
}
